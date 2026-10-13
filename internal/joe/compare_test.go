package joe_test

import (
	"fmt"
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/rom"
)

const romPath = "../../build/montezuma.rom"

func rules(t *testing.T) *joe.Rules {
	t.Helper()
	r, err := rom.Load(romPath)
	if err != nil {
		t.Skip(err)
	}
	rules, err := joe.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	return rules
}

type scenario struct {
	name   string
	room   int
	x, y   int // screen position of Joe's body
	frames int
	input  func(f int) joe.Input
}

func hold(in joe.Input) func(int) joe.Input { return func(int) joe.Input { return in } }

var scenarios = []scenario{
	{"stand", 2, 124, 53, 30, hold(joe.Input{})},
	{"walk right off the ledge and die", 2, 124, 53, 60, hold(joe.Input{Right: true})},
	{"walk left off the ledge and die", 2, 124, 53, 60, hold(joe.Input{Left: true})},
	{"standing jump", 2, 124, 53, 40, func(f int) joe.Input { return joe.Input{Fire: f < 3} }},
	{"jump twice holding fire", 2, 124, 53, 60, hold(joe.Input{Fire: true})},
	{"running jump", 6, 60, 53, 40, func(f int) joe.Input { return joe.Input{Right: true, Fire: f >= 6 && f < 9} }},
	{"jump into the wall", 6, 200, 53, 60, func(f int) joe.Input { return joe.Input{Right: true, Fire: f >= 4 && f < 6} }},
	{"ladder down onto the conveyor", 2, 116, 53, 120, hold(joe.Input{Down: true})},
	{"ladder up from the conveyor", 2, 118, 117, 90, hold(joe.Input{Up: true})},
	{"ladder down and back up", 2, 116, 53, 120, func(f int) joe.Input { return joe.Input{Down: f < 30, Up: f >= 30} }},
	{"exit left", 2, 20, 53, 40, hold(joe.Input{Left: true})},
	{"exit right", 2, 220, 53, 40, hold(joe.Input{Right: true})},
	{"grab a rope and slide off the bottom", 5, 200, 53, 100, hold(joe.Input{Down: true})},
	{"rope down then up", 5, 200, 53, 80, func(f int) joe.Input { return joe.Input{Down: f < 30, Up: f >= 30} }},
	{"climb a rope back to the top", 5, 200, 53, 100, func(f int) joe.Input { return joe.Input{Down: f < 20, Up: f >= 20} }},
	{"jump left off a rope", 5, 200, 53, 70, func(f int) joe.Input { return joe.Input{Down: f < 30, Left: f >= 35, Fire: f == 36} }},
	{"fire on a rope without a direction", 5, 200, 53, 60, func(f int) joe.Input { return joe.Input{Down: f < 30, Up: f >= 35, Fire: f == 36} }},
	{"running jump onto a rope", 23, 56, 93, 60, func(f int) joe.Input { return joe.Input{Right: true, Fire: f == 6} }},
	{"rope to the far platform", 23, 56, 93, 100, func(f int) joe.Input { return joe.Input{Right: true, Fire: f == 6 || f == 50} }},
	// Ends before an enemy reaches Joe at the foot of the pole; touching
	// enemies isn't translated yet.
	{"jump onto a pole", 12, 12, 53, 34, func(f int) joe.Input { return joe.Input{Right: true, Fire: f == 2} }},
	// Ends at the room change: on the first frame after a downward one the
	// original reads tiles from the half-drawn new room, which depends on
	// drawing time the emulator only approximates.
	{"exit down a ladder", 6, 116, 53, 120, hold(joe.Input{Down: true})},
}

func TestMatchesOriginal(t *testing.T) {
	r := rules(t)
	for _, sc := range scenarios {
		t.Run(sc.name, func(t *testing.T) {
			g, err := original.Start(romPath, 1)
			if err != nil {
				t.Skip(err)
			}
			if sc.room != 2 {
				if err := g.LoadRoom(sc.room); err != nil {
					t.Fatal(err)
				}
			}
			g.PlaceJoe(sc.x, sc.y)

			var j joe.Joe
			j.Place(sc.x, sc.y)
			j.Parity = g.Peek(0x70AB)
			j.FireLatch = g.Peek(0x7075)

			// After a room change the original pauses while it draws the
			// new room, for a time that depends on the room; the remake uses
			// a fixed pause. Here the remake waits exactly as long as the
			// original, whose frame counter at $70AB stops meanwhile.
			changingRoom := false
			for f := 0; f < sc.frames; f++ {
				in := sc.input(f)
				// Both see the screen as it is at the start of the frame.
				tiles := make([]byte, 768)
				copy(tiles, g.VDP.NameTable())
				counter := g.Peek(0x70AB)
				if err := g.Step(coleco.Joystick{Up: in.Up, Down: in.Down, Left: in.Left, Right: in.Right, FireLeft: in.Fire}); err != nil {
					t.Fatal(err)
				}
				if changingRoom && g.Peek(0x70AB) == counter {
					continue
				}
				changingRoom = false
				if j.Step(in, frozen(tiles), r) != 0 {
					changingRoom = true
					j.Frozen = 0
				}
				o := g.Joe()

				got := fmt.Sprintf("x=%d y=%d state=%d", j.X, j.ScreenY(), j.State)
				want := fmt.Sprintf("x=%d y=%d state=%d", o.X, o.Y, o.State)
				if got != want {
					t.Fatalf("frame %d: remake %s, original %s", f, got, want)
				}
			}
		})
	}
}

// frozen is a copy of the original's screen, so the remake sees the same
// tiles even when the original changes them (doors, items, room changes).
type frozen []byte

func (f frozen) Tile(col, row int) byte { return f[row*32+col] }
