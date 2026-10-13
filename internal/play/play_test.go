package play

import (
	"testing"

	"montezuma-remake/internal/items"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

func testGame(t *testing.T, room, x, y int) *Game {
	t.Helper()
	rooms, err := roomdata.Load("../../assets/rooms/level1/rooms.json")
	if err != nil {
		t.Skip(err)
	}
	r, err := rom.Load("../../build/montezuma.rom")
	if err != nil {
		t.Skip(err)
	}
	rules, err := RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	g := New(rooms, rules, 1, room)
	g.Joe.Place(x, y)
	g.Entry = g.Joe
	return g
}

func run(g *Game, frames int, in joe.Input) {
	for i := 0; i < frames; i++ {
		g.Step(in)
	}
}

func TestWalkIntoNextRoom(t *testing.T) {
	g := testGame(t, pyramid.Start, 20, 53)
	run(g, 20, joe.Input{Left: true})
	if g.Room != 1 {
		t.Errorf("room %d after walking left, want 1", g.Room)
	}
	if g.Entry.X != 238 {
		t.Errorf("entered room 1 at x=%d, want 238", g.Entry.X)
	}
}

func TestWrapAtRowEnd(t *testing.T) {
	g := testGame(t, 4, 20, 53) // first room of row 1
	run(g, 20, joe.Input{Left: true})
	if g.Room != 3 {
		t.Errorf("room %d after walking left from room 4, want 3", g.Room)
	}
}

// TestClimbUpIntoRoom checks Joe steps off the top of room 3's ladder onto
// the floor, as the original does. Reaching the top at y 148, landing must
// snap him up to 141; snapping without keeping to 4 bits put him back on
// the ladder, over and over.
func TestClimbUpIntoRoom(t *testing.T) {
	g := testGame(t, 7, 115, 69)
	run(g, 140, joe.Input{Up: true})
	run(g, 60, joe.Input{})
	if g.Room != 3 || g.Joe.State != joe.Standing || g.Joe.ScreenY() != 141 {
		t.Errorf("room %d, state %d, y %d; want standing in room 3 at y 141",
			g.Room, g.Joe.State, g.Joe.ScreenY())
	}
}

func TestClimbDownToConveyor(t *testing.T) {
	g := testGame(t, pyramid.Start, 116, 53)
	run(g, 100, joe.Input{Down: true})
	if g.Room != pyramid.Start || g.Joe.State != joe.Standing || g.Joe.ScreenY() != 117 {
		t.Errorf("room %d, state %d, y %d; want standing on the conveyor (y 117)",
			g.Room, g.Joe.State, g.Joe.ScreenY())
	}
}

func TestFallDeathRespawns(t *testing.T) {
	g := testGame(t, pyramid.Start, 124, 53)
	run(g, 60, joe.Input{Right: true}) // off the ledge onto the conveyor: fatal
	if g.Joe.State != joe.Dead {
		t.Fatalf("state %d after the fall, want dead", g.Joe.State)
	}
	run(g, 200, joe.Input{})
	if g.Lives != StartLives-1 || g.Joe.X != 124 || g.Joe.ScreenY() != 53 {
		t.Errorf("lives %d, Joe at (%d, %d); want %d lives and Joe back at (124, 53)",
			g.Lives, g.Joe.X, g.Joe.ScreenY(), StartLives-1)
	}
}

func TestBlockedAtPyramidTop(t *testing.T) {
	g := testGame(t, 1, 100, 53)
	g.Joe.RawY = 2 // as if climbing off the top of the screen
	g.Joe.State, g.Joe.DY = joe.Ladder, -1
	before := g.Joe
	g.changeRoom(joe.ExitUp, before)
	if g.Room != 1 || g.Joe.RawY != 2 {
		t.Errorf("room %d, RawY %d; want to stay in room 1 at RawY 2", g.Room, g.Joe.RawY)
	}
}

// TestKilledByEnemy jumps onto the pole in room 12; an enemy reaches Joe at
// the bottom. After the respawn that enemy is gone, and stays gone.
func TestKilledByEnemy(t *testing.T) {
	g := testGame(t, 12, 12, 53)
	enemies := len(g.Enemies.Objects)
	for f := 0; f < 40; f++ {
		g.Step(joe.Input{Right: f < 30, Fire: f == 2})
	}
	if g.Joe.State != joe.Zapped {
		t.Fatalf("state %d, want killed by an enemy", g.Joe.State)
	}
	run(g, 200, joe.Input{})
	if g.Lives != StartLives-1 || len(g.Enemies.Objects) != enemies-1 {
		t.Errorf("lives %d, %d enemies; want %d lives and %d enemies",
			g.Lives, len(g.Enemies.Objects), StartLives-1, enemies-1)
	}
	g.Enter(12)
	if len(g.Enemies.Objects) != enemies-1 {
		t.Errorf("%d enemies on coming back, want %d", len(g.Enemies.Objects), enemies-1)
	}
}

// TestKeyStaysCollected picks up the key in the starting room, leaves and
// comes back: the key is gone and still in the inventory.
func TestKeyStaysCollected(t *testing.T) {
	g := testGame(t, pyramid.Start, 37, 101)
	for f := 0; f < 40; f++ {
		g.Step(joe.Input{Fire: f == 1})
	}
	if g.Inventory[0] != items.KeyRed {
		t.Fatalf("inventory % X, want the key", g.Inventory)
	}
	g.Enter(1)
	g.Enter(pyramid.Start)
	if g.Tiles.T[11][5] != 0 || g.Inventory[0] != items.KeyRed {
		t.Errorf("key tile %02X, inventory % X; want the key gone from the room and still carried",
			g.Tiles.T[11][5], g.Inventory)
	}
}
