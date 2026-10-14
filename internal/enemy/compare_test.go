package enemy_test

import (
	"fmt"
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/enemy"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
)

const romPath = "../../build/montezuma.rom"

const amulet = 0x704A // Joe's amulet timer

func rules(t *testing.T) *enemy.Rules {
	t.Helper()
	r, err := rom.Load(romPath)
	if err != nil {
		t.Skip(err)
	}
	rules, err := enemy.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	return rules
}

// stateFrom copies the original's enemy state.
func stateFrom(g *original.Game, r *enemy.Rules) *enemy.State {
	s := &enemy.State{Counter: g.Peek(original.FrameCounter), Rules: r}
	for a := uint16(original.ObjectList); g.Peek(a) != 0xFF; a += 2 {
		s.Objects = append(s.Objects, [2]byte{g.Peek(a), g.Peek(a + 1)})
	}
	for i := range s.Sprites {
		b := g.Bytes(uint16(original.SpriteTable+4*i), 4)
		s.Sprites[i] = &enemy.Sprite{Y: b[0], X: b[1], Pattern: b[2], Colour: b[3]}
	}
	return s
}

type frozen []byte

func (f frozen) Tile(col, row int) byte { return f[row*32+col] }

// TestMatchesOriginal moves the enemies of every room, on levels 1 and 4,
// in both games for 300 frames, with Joe protected by his amulet, and
// compares their sprites every frame. It stops early in a room where Joe
// dies (he starts mid-air in some), since the original then reloads the
// room.
func TestMatchesOriginal(t *testing.T) {
	r := rules(t)
	var short []string
	defer func() {
		if len(short) > 0 {
			t.Logf("rooms where Joe died (level:room@frame), compared up to the frame shown: %v", short)
		}
	}()
	// Level 4 adds enemies to many rooms.
	for _, level := range []int{1, 4} {
		for room := 0; room < pyramid.Rooms; room++ {
			g, err := original.Start(romPath, min(level, 3))
			if err != nil {
				t.Skip(err)
			}
			g.SetLevel(level)
			if err := g.LoadRoom(room); err != nil {
				t.Fatal(err)
			}
			placeOnFloor(g)
			// Let the original finish settling into the room; it pauses for a
			// few frames after loading one.
			for f := 0; f < 10; f++ {
				g.Poke(amulet, 0xFF)
				if err := g.Step(coleco.Joystick{}); err != nil {
					t.Fatal(err)
				}
			}
			g.Poke(amulet, 0xFF)
			s := stateFrom(g, r)
			if len(s.Objects) == 0 {
				continue
			}
			for f := 0; f < 300; f++ {
				tiles := make([]byte, 768)
				copy(tiles, g.VDP.NameTable())
				parity := (g.Peek(0x70AB) - 1) & 3
				if err := g.Step(coleco.Joystick{}); err != nil {
					t.Fatal(err)
				}
				g.Poke(amulet, 0xFF)
				if g.Joe().State >= 8 {
					short = append(short, fmt.Sprintf("%d:%d@%d", level, room, f))
					break
				}
				s.Counter++ // the frame interrupt's tick
				s.Update(frozen(tiles), parity, true)
				for _, o := range s.Objects {
					slot := int(o[0] & 7)
					got := *s.Sprites[slot]
					b := g.Bytes(uint16(original.SpriteTable+4*slot), 4)
					want := enemy.Sprite{Y: b[0], X: b[1], Pattern: b[2], Colour: b[3]}
					if got != want {
						t.Errorf("level %d room %d frame %d slot %d: remake %s, original %s", level, room, f, slot, show(got), show(want))
						f = 300
						break
					}
				}
			}
		}
	}
}

// placeOnFloor stands Joe on the first floor tile (scanning down from the
// top of the play area) with open space above, so he doesn't fall to his
// death, which would make the original reload the room.
func placeOnFloor(g *original.Game) {
	names := g.VDP.NameTable()
	floors := g.Bytes(0x93FF, 10)
	isFloor := func(t byte) bool {
		for _, f := range floors {
			if f == t {
				return true
			}
		}
		return false
	}
	for row := 7; row < 23; row++ {
		for col := 2; col < 30; col++ {
			if isFloor(names[row*32+col]) && names[(row-1)*32+col] == 0 && names[(row-2)*32+col] == 0 {
				g.PlaceJoe(col*8-5, row*8-19)
				return
			}
		}
	}
}

func show(s enemy.Sprite) string {
	return fmt.Sprintf("y=%d x=%d pattern=%02X colour=%X", s.Y, s.X, s.Pattern, s.Colour)
}
