package original

import (
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/pyramid"
)

const romPath = "../../build/montezuma.rom"

func start(t *testing.T) *Game {
	t.Helper()
	g, err := Start(romPath, 1)
	if err != nil {
		t.Skip(err)
	}
	return g
}

// TestWalkOff checks the pyramid package's side exits against the original
// game, including the wrap from the end of one row into the next.
func TestWalkOff(t *testing.T) {
	for _, c := range []struct {
		room int
		d    pyramid.Direction
	}{
		{2, pyramid.Left}, {2, pyramid.Right},
		{4, pyramid.Left},  // wraps to the end of row 0
		{8, pyramid.Right}, // wraps to the start of row 2
		{26, pyramid.Left}, // room 25's right edge is solid, but the game still moves
	} {
		g := start(t)
		if err := g.LoadRoom(c.room); err != nil {
			t.Fatal(err)
		}
		x := 8
		if c.d == pyramid.Right {
			x = 232
		}
		g.PlaceJoe(x, 9*8-16) // feet on tile row 9, in the top corridor
		for f := 0; f < 120; f++ {
			if err := g.Step(coleco.Joystick{Left: c.d == pyramid.Left, Right: c.d == pyramid.Right}); err != nil {
				t.Fatal(err)
			}
		}
		if got, want := g.Room(), pyramid.Neighbour(c.room, c.d); got != want {
			t.Errorf("room %d, walking %v: game moved to room %d, pyramid.Neighbour says %d", c.room, c.d, got, want)
		}
	}
}

// TestJoeWalksAndFalls pins down the basics measured from the original:
// walking is 2 pixels a frame, falling 4, and the fall off the starting
// ledge onto the conveyor kills him.
func TestJoeWalksAndFalls(t *testing.T) {
	g := start(t)
	j := g.Joe()
	if j.State != Standing {
		t.Fatalf("state %d after landing, want standing", j.State)
	}
	x0 := j.X
	for f := 0; f < 4; f++ {
		g.Step(coleco.Joystick{Right: true})
	}
	if j = g.Joe(); j.X != x0+8 || j.State != Walking {
		t.Errorf("after 4 frames walking right: x %d (want %d), state %d", j.X, x0+8, j.State)
	}
	for f := 0; f < 60; f++ {
		g.Step(coleco.Joystick{Right: true})
	}
	if j = g.Joe(); j.State != Dead {
		t.Errorf("state %d after walking off the ledge, want dead", j.State)
	}
}
