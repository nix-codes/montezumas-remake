package play

import (
	"fmt"
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
)

// TestPoleToNextLevel puts both games in the treasure room's right-hand
// column with Joe jumping towards its pole: he catches it, slides off the
// bottom of the screen, and the next level starts. The games are compared
// every frame until the original changes level.
func TestPoleToNextLevel(t *testing.T) {
	g := testGame(t, 90, 200, 60)
	o, err := original.Start("../../build/montezuma.rom", 1)
	if err != nil {
		t.Skip(err)
	}
	if err := o.LoadRoom(90); err != nil {
		t.Fatal(err)
	}

	// Treasure mode, row 9, column 11, a screen to set up, time up (so
	// there are no chains to catch first).
	o.Poke(0x705F, o.Peek(0x705F)|0x28)
	o.Poke(0x71A7, 9)
	o.Poke(0x71A8, 11)
	o.Poke(0x70AC, 1)
	g.Treasure, g.TreasureTimer, g.Row, g.Col = true, 1, 9, 11
	g.setupPending = true

	// Joe on the way down from a jump, moving right.
	o.ResetJoe(200, 60)
	o.Poke(0x7079, joe.Jumping)
	o.Poke(0x7076, 2)
	o.Poke(0x7072, 8)
	g.Joe.Place(200, 60)
	g.Joe.State, g.Joe.DX, g.Joe.JumpCounter = joe.Jumping, 2, 8
	g.Joe.FallStart = o.Peek(0x707C)
	g.Joe.Parity = o.Peek(0x70AB)
	g.Joe.FireLatch = o.Peek(0x7075)
	g.ContactTimer, g.ItemTimer = int(o.Peek(0x7073)), int(o.Peek(0x7012))
	g.Random = uint16(o.Peek(0x7047)) | uint16(o.Peek(0x7048))<<8

	sawPole := false
	for f := 0; f < 300; f++ {
		if err := o.Step(coleco.Joystick{}); err != nil {
			t.Fatal(err)
		}
		g.Step(joe.Input{})
		if o.Peek(0x71A6) != 1 {
			if g.Level != 2 || g.Treasure || g.Room != 2 {
				t.Errorf("frame %d: original started level 2; remake level %d, treasure %v, room %d",
					f, g.Level, g.Treasure, g.Room)
			}
			if !sawPole {
				t.Error("Joe never slid down the pole")
			}
			return
		}
		oj := o.Joe()
		got := fmt.Sprintf("x=%d y=%d state=%d", g.Joe.X, g.Joe.ScreenY(), g.Joe.State)
		want := fmt.Sprintf("x=%d y=%d state=%d", oj.X, oj.Y, oj.State)
		if got != want {
			t.Fatalf("frame %d: Joe: remake %s, original %s", f, got, want)
		}
		if oj.State == joe.Pole {
			sawPole = true
		}
	}
	t.Fatal("the original never started the next level")
}
