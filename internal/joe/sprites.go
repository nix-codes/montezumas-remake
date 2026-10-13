package joe

import "montezuma-remake/internal/rom"

// RulesFromROM reads Joe's tile tables and jump arc from the cartridge.
func RulesFromROM(r *rom.ROM) (*Rules, error) {
	var rules Rules
	for _, t := range []struct {
		addr uint16
		n    int
		dst  *[]byte
	}{
		{0x93FF, 10, &rules.Floors},
		{0xA00E, 5, &rules.Hazards},
		{0x9412, 7, &rules.Conveyors},
		{0x943C, 8, &rules.Walls},
	} {
		b, err := r.Slice(t.addr, t.n)
		if err != nil {
			return nil, err
		}
		*t.dst = b
	}
	arc, err := r.Slice(0x93AE, 18)
	if err != nil {
		return nil, err
	}
	for _, b := range arc {
		rules.JumpArc = append(rules.JumpArc, int8(b))
	}
	return &rules, nil
}

// Sprite colours.
const (
	BodyColour  = 6  // red
	LegsColour  = 11 // yellow
	GhostColour = 14 // grey: burnt Joe, a single sprite
)

// walkRight and walkLeft are the walking cycles, one frame every 4 steps:
// body and legs sprite numbers.
var (
	walkRight = [][2]int{{13, 38}, {13, 39}, {13, 38}, {27, 40}}
	walkLeft  = [][2]int{{16, 41}, {16, 42}, {16, 41}, {31, 43}}
)

// Sprites returns the sprite numbers (pattern / 4) of Joe's body and of his
// hat and legs, and where the legs sprite goes relative to the body: 3
// lines below, or above in the death pose. Burnt, he is one grey sprite and
// legs is -1. Measured from the original.
func (j *Joe) Sprites() (body, legs, legsDY int) {
	frame := j.AnimTick / 4
	left := j.Facing < 0
	switch j.State {
	case Jumping:
		if left {
			return 20, 45, 3
		}
		return 19, 44, 3
	case Ladder:
		if frame%2 == 0 {
			return 21, 46, 3
		}
		return 22, 47, 3
	case Rope:
		if frame%2 == 0 {
			return 23, 48, 3
		}
		return 24, 49, 3
	case Pole:
		return 25, 50, 3
	case Dead:
		return 26, 52, -3
	case Zapped:
		// Flashes two frames in eight, following the death timer ($8B7F).
		if j.DeathTimer&6 == 2 {
			return 56, 55, 3
		}
		return 54, 53, 3
	case Burnt:
		return 30, -1, 0
	case Walking:
		cycle := walkRight
		if left {
			cycle = walkLeft
		}
		f := cycle[frame%len(cycle)]
		return f[0], f[1], 3
	}
	if left {
		return 16, 41, 3
	}
	return 13, 38, 3
}
