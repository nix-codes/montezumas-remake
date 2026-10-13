// Package enemy moves the rooms' enemies and checks whether Joe touches
// one, translated from the original (enemy update at $A7A1, contact check
// at $91E5). Like internal/joe it keeps the game's own bytes: the object
// list, the local sprite table and the shared frame counter.
package enemy

import (
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/rom"
)

// Object flag bits (first byte of each object; the low 3 bits are its
// sprite slot).
const (
	flagRolls   = 0x08 // animates through rolling frames instead of bouncing
	flagBounded = 0x10 // turns at the screen edges, ignoring floors and walls
	flagLadder  = 0x20 // climber: on a ladder
	flagClimber = 0x40 // walks and climbs ladders; green
	flagLeft    = 0x80 // moving left (climbers on a ladder: moving down)
)

// counterFast in an object's second byte doubles its speed.
const counterFast = 0x80

// Tiles with special meaning to enemies.
const (
	tileLadder      = 0x88 // and 0x89
	tileLadderFloor = 0x10 // and 0x11
	tileBrick       = 0x08
	tileDisappear   = 0xE8
)

// Sprite colours.
const (
	colourWhite = 0x0F
	colourGreen = 0x0C
	colourGrey  = 0x0E // while Joe's amulet protects him
)

// Rules holds the tables enemies use from the ROM.
type Rules struct {
	Walls  []byte // $943C
	Bounce []int8 // $ABB3: dy per frame for bouncers, read backwards
}

// RulesFromROM reads the enemy tables from the cartridge.
func RulesFromROM(r *rom.ROM) (*Rules, error) {
	walls, err := r.Slice(0x943C, 8)
	if err != nil {
		return nil, err
	}
	bounce, err := r.Slice(0xABB3, 0x3A)
	if err != nil {
		return nil, err
	}
	rules := &Rules{Walls: walls}
	for _, b := range bounce {
		rules.Bounce = append(rules.Bounce, int8(b))
	}
	return rules, nil
}

// Sprite is one entry of the local sprite table: Y, X, pattern, colour.
type Sprite struct{ Y, X, Pattern, Colour byte }

// State is the enemies in the current room.
type State struct {
	Objects [][2]byte  // $7086: flags (and slot), counter
	Sprites [8]*Sprite // the local sprite table; entries 0 and 1 are Joe's
	Counter byte       // $7097: frame counter, also ticked by climbers
	Rules   *Rules
}

// tick advances the shared frame counter and reports whether it hit a
// multiple of the climbers' rhythm ($A69F).
func (s *State) tick() bool {
	s.Counter++
	return s.Counter&0x11 == 0
}

// Update moves every enemy one frame ($A7A1). parity is the game's
// 3-2-1-0 frame counter after this frame's decrement (Joe's Parity);
// amulet is whether Joe's amulet is protecting him.
func (s *State) Update(t joe.Tiles, parity byte, amulet bool) {
	for i := range s.Objects {
		o := &s.Objects[i]
		spr := s.Sprites[o[0]&7]
		if spr == nil {
			continue
		}
		b := joe.TilesAround(t, spr.X, spr.Y)
		x := spr.X // the X the bounded check uses, read with the tiles
		if spr.Y < 0x15 || spr.Y >= 0xB8 {
			o[0] ^= flagLeft
		}
		if o[0]&flagClimber != 0 {
			s.climber(o, spr, b, x, parity, amulet)
			continue
		}
		if spr.Colour != 0 {
			spr.Colour = colourWhite
			if amulet {
				spr.Colour = colourGrey
			}
		}
		if o[0]&flagRolls != 0 {
			o[1]++
			if o[1]&0x0F == 4 {
				o[1] &= counterFast
				step := byte(0xFC) // -4
				if o[0]&flagLeft != 0 {
					step = 4
				}
				p := spr.Pattern + step
				switch p {
				case 0x2C:
					p = 0x0C
				case 0x08:
					p = 0x28
				}
				spr.Pattern = p
			}
		}
		s.walk(o, spr, b, x)
	}
}

// walk turns an enemy at the end of its floor, at walls or (bounded ones)
// at the screen edges, then moves it ($A81D-$A88E).
func (s *State) walk(o *[2]byte, spr *Sprite, b [6]byte, x byte) {
	if o[0]&flagBounded != 0 {
		if x < 8 || x >= 0xF5 {
			o[0] ^= flagLeft
		}
	} else {
		ahead := b[2]
		if o[0]&flagLeft != 0 {
			ahead = b[0]
		}
		if b[4] == 0 || contains(s.Rules.Walls, ahead) {
			o[0] ^= flagLeft
		}
	}
	var dy int8
	if o[0]&flagRolls == 0 {
		// Bouncers follow the arc table; the counter loses its fast bit.
		a := int(o[1]&0x7F) - 1
		if a < 0 {
			a = len(s.Rules.Bounce) - 1
		}
		o[1] = byte(a)
		dy = s.Rules.Bounce[a]
	}
	s.move(o, spr, dy)
}

// move applies dy (subtracted, as the game does) and the horizontal step,
// and turns the enemy round near the left edge ($A869-$A88E).
func (s *State) move(o *[2]byte, spr *Sprite, dy int8) {
	dx := byte(1)
	if o[0]&flagLeft != 0 {
		dx = 0xFF
	}
	if o[1]&counterFast != 0 {
		dx *= 2
	}
	s.shift(o, spr, dy, dx)
}

// shift moves the sprite by -dy and +dx and turns it round if it ends up
// within 8 pixels of the left edge ($A87F).
func (s *State) shift(o *[2]byte, spr *Sprite, dy int8, dx byte) {
	spr.Y -= byte(dy)
	spr.X += dx
	if spr.X < 8 {
		o[0] ^= flagLeft
	}
}

// climber handles enemies that walk and use ladders ($A6B3-$A79E).
func (s *State) climber(o *[2]byte, spr *Sprite, b [6]byte, x, parity byte, amulet bool) {
	// Animate every sixth frame.
	a := int(o[1]&0x7F) - 1
	if a < 0 {
		a = 5
	}
	o[1] = byte(a) | o[1]&counterFast
	if a == 0 {
		if spr.Colour != 0 {
			spr.Colour = colourGreen
			if amulet {
				spr.Colour = colourGrey
			}
		}
		spr.Pattern ^= 0x1C
	}

	if b[3] == tileLadderFloor && b[4] == tileLadderFloor+1 {
		// Standing on the top of a ladder.
		if o[0]&flagLadder == 0 {
			if !s.tick() && parity == 2 {
				// Step down onto the ladder.
				alignX(spr)
				spr.Y += 2
				o[0] |= flagLadder | flagLeft
				return
			}
		} else if o[0]&flagLeft == 0 {
			// Climbed to the top: step off, sideways.
			o[0] &^= flagLadder
			dx := byte(8)
			if !s.tick() {
				o[0] ^= flagLeft
				dx = 0xFE
			}
			spr.X += dx
			spr.Y += 0xF9
			return
		} else {
			s.climbDown(o, spr, b)
			return
		}
	}

	if b[0] == tileLadder && b[1] == tileLadder+1 && parity == 2 {
		// A ladder going up from here.
		if o[0]&flagLadder == 0 {
			if !s.tick() {
				alignX(spr)
				o[0] &^= flagLeft
				o[0] |= flagLadder
				spr.Y += 0xF9
				return
			}
		} else {
			s.onLadder(o, spr, b)
			return
		}
	}
	if o[0]&flagLadder != 0 {
		s.onLadder(o, spr, b)
		return
	}
	s.walk(o, spr, b, x)
}

// onLadder keeps a climber going: up one pixel, or down ($A78E).
func (s *State) onLadder(o *[2]byte, spr *Sprite, b [6]byte) {
	if o[0]&flagLeft != 0 {
		s.climbDown(o, spr, b)
		return
	}
	s.shift(o, spr, 1, 0)
}

// climbDown moves a climber down its ladder, and off it at the bottom,
// sideways in a direction chosen by the frame counter ($A73A).
func (s *State) climbDown(o *[2]byte, spr *Sprite, b [6]byte) {
	if t := b[4]; t == tileDisappear || t == tileBrick {
		dx := byte(8)
		if s.tick() {
			o[0] &^= flagLeft
		} else {
			o[0] |= flagLeft
			dx = 0xFE
		}
		o[0] &^= flagLadder
		s.shift(o, spr, 0, dx)
		return
	}
	s.shift(o, spr, -1, 0)
}

// alignX snaps a climber onto a ladder ($ABED).
func alignX(spr *Sprite) {
	c := byte(8)
	if spr.X&0x0F < 8 {
		c = 0
	}
	spr.X = spr.X&0xF0 + c
}

func contains(list []byte, t byte) bool {
	for _, x := range list {
		if x == t {
			return true
		}
	}
	return false
}

// Touching reports the sprite slot of the first enemy Joe is touching, or
// -1 ($9228-$9265). joeX and joeY are his body sprite's X and attribute Y.
// contacts is the room's contact list ($72C1): after its first byte, pairs
// of (offset, kind) ending in kind $FE; kind $FF is an enemy whose sprite
// is offset bytes after Joe's second sprite entry. Enemies touch Joe when
// they are visible, less than 13 lines apart and less than 8 pixels apart.
func (s *State) Touching(joeX, joeY byte, contacts []byte) int {
	for i := 1; i+1 < len(contacts); i += 2 {
		offset, kind := contacts[i], contacts[i+1]
		if kind == 0xFE {
			break
		}
		if kind != 0xFF {
			continue
		}
		slot := (int(offset) + 4) / 4
		if slot >= len(s.Sprites) || s.Sprites[slot] == nil {
			continue
		}
		spr := s.Sprites[slot]
		if absDiff(joeY, spr.Y) < 13 && absDiff(joeX, spr.X) < 8 && spr.Colour != 0 {
			return slot
		}
	}
	return -1
}

func absDiff(a, b byte) byte {
	d := a - b
	if int8(d) < 0 {
		return -d
	}
	return d
}
