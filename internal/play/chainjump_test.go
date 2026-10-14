package play_test

import (
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/play"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

// TestChainJumpAtTimeUp falls through room 90 into the treasure room,
// hangs Joe on one of the first screen's chains in both games and runs
// the timer out; then he jumps off to the right. Time being up, the jump
// is twice as fast and draws a new, empty screen ($8D1B). The games are
// compared every frame.
func TestChainJumpAtTimeUp(t *testing.T) {
	r, err := rom.Load(romPath)
	if err != nil {
		t.Skip(err)
	}
	rules, err := play.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	rooms, err := roomdata.Load(roomsPath)
	if err != nil {
		t.Skip(err)
	}
	o, err := original.Start(romPath, 1)
	if err != nil {
		t.Skip(err)
	}
	if err := o.LoadRoom(90); err != nil {
		t.Fatal(err)
	}
	placeOnFloor(o)
	for f := 0; f < 10; f++ {
		if err := o.Step(coleco.Joystick{}); err != nil {
			t.Fatal(err)
		}
	}
	o.ResetJoe(124, 120)
	g := play.New(rooms, rules, 1, 90)
	g.Joe.Place(124, 120)
	g.Entry = g.Joe
	g.RedrawHUD()
	sync(g, o)

	step := func(f int, in joe.Input) {
		t.Helper()
		if err := o.Step(coleco.Joystick{Right: in.Right, FireLeft: in.Fire}); err != nil {
			t.Fatal(err)
		}
		drawn, frozen := g.TreasureScreens, g.Joe.Frozen
		g.Step(in)
		if msg := compare(g, o, g.TreasureScreens == drawn && frozen == 0 && g.Joe.Frozen == 0); msg != "" {
			t.Fatalf("frame %d: %s", f, msg)
		}
	}

	// Into the treasure room, and let the first screen settle.
	f := 0
	for ; !g.Treasure || g.TreasureScreens == 0; f++ {
		if f == 300 {
			t.Fatal("Joe never reached the treasure room")
		}
		step(f, joe.Input{})
	}
	for end := f + 3; f < end; f++ {
		step(f, joe.Input{})
	}

	// Hang Joe on a chain at least 4 tiles long, his legs on its second
	// tile, lined up as grabbing it does.
	col, top := -1, 0
	for c := 2; c < 30 && col < 0; c++ {
		for row := 8; row+4 <= 22; row++ {
			ok := true
			for k := range 4 {
				ok = ok && g.Tiles.T[row+k][c] == 0x90
			}
			if ok {
				col, top = c, row
				break
			}
		}
	}
	if col < 0 {
		t.Fatal("no chain to hang Joe on")
	}
	x, y := 8*col-4, 8*top+3
	o.ResetJoe(x, y)
	o.Poke(0x7079, joe.Rope)
	o.Poke(0x7076, 0)
	o.Poke(0x7077, 0)
	g.Joe.Place(x, y)
	g.Joe.State = joe.Rope
	g.Joe.Parity, g.Joe.FireLatch = o.Peek(parity), o.Peek(fireLatch)
	g.Joe.StepCounter, g.Joe.StepDelay = o.Peek(0x70AA), o.Peek(0x70AD)
	g.Joe.FallStart = o.Peek(0x707C)
	g.Entry = g.Joe
	const timer = 0x70AC
	o.Poke(timer, 3)
	g.TreasureTimer = 3

	// Wait for time up, then jump right.
	screens, jumped := 0, false
	for end := f + 80; f < end; f++ {
		in := joe.Input{}
		if g.TreasureTimer == 1 {
			if !jumped && g.Joe.State != joe.Rope {
				t.Fatalf("frame %d: Joe let go of the chain before time was up (state %d)", f, g.Joe.State)
			}
			in = joe.Input{Right: true, Fire: true}
		}
		step(f, in)
		if !jumped && g.Joe.State == joe.Jumping {
			jumped, screens = true, g.TreasureScreens
			if g.Joe.DX != 4 {
				t.Errorf("frame %d: jumped off at %d px a frame, want 4", f, int8(g.Joe.DX))
			}
		}
	}
	if !jumped {
		t.Fatal("Joe never jumped off the chain")
	}
	if g.TreasureScreens == screens {
		t.Error("the jump didn't draw a new screen")
	}
}
