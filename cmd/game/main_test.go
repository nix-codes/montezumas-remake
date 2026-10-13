package main

import (
	"testing"

	"montezuma-remake/internal/enemy"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

func testGame(t *testing.T, room, x, y int) *game {
	t.Helper()
	rooms, err := roomdata.Load("../../assets/rooms/level1/rooms.json")
	if err != nil {
		t.Skip(err)
	}
	r, err := rom.Load("../../build/montezuma.rom")
	if err != nil {
		t.Skip(err)
	}
	rules, err := joe.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	enemyRules, err := enemy.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	g := newGame(rooms, rules, enemyRules, room)
	g.joe.Place(x, y)
	g.entry = g.joe
	return g
}

func run(g *game, frames int, in joe.Input) {
	for i := 0; i < frames; i++ {
		g.step(in)
	}
}

func TestWalkIntoNextRoom(t *testing.T) {
	g := testGame(t, pyramid.Start, 20, 53)
	run(g, 20, joe.Input{Left: true})
	if g.room != 1 {
		t.Errorf("room %d after walking left, want 1", g.room)
	}
	if g.entry.X != 238 {
		t.Errorf("entered room 1 at x=%d, want 238", g.entry.X)
	}
}

func TestWrapAtRowEnd(t *testing.T) {
	g := testGame(t, 4, 20, 53) // first room of row 1
	run(g, 20, joe.Input{Left: true})
	if g.room != 3 {
		t.Errorf("room %d after walking left from room 4, want 3", g.room)
	}
}

func TestClimbDownToConveyor(t *testing.T) {
	g := testGame(t, pyramid.Start, 116, 53)
	run(g, 100, joe.Input{Down: true})
	if g.room != pyramid.Start || g.joe.State != joe.Standing || g.joe.ScreenY() != 117 {
		t.Errorf("room %d, state %d, y %d; want standing on the conveyor (y 117)",
			g.room, g.joe.State, g.joe.ScreenY())
	}
}

func TestFallDeathRespawns(t *testing.T) {
	g := testGame(t, pyramid.Start, 124, 53)
	run(g, 60, joe.Input{Right: true}) // off the ledge onto the conveyor: fatal
	if g.joe.State != joe.Dead {
		t.Fatalf("state %d after the fall, want dead", g.joe.State)
	}
	run(g, 200, joe.Input{})
	if g.lives != startLives-1 || g.joe.X != 124 || g.joe.ScreenY() != 53 {
		t.Errorf("lives %d, Joe at (%d, %d); want %d lives and Joe back at (124, 53)",
			g.lives, g.joe.X, g.joe.ScreenY(), startLives-1)
	}
}

func TestBlockedAtPyramidTop(t *testing.T) {
	g := testGame(t, 1, 100, 53)
	g.joe.RawY = 2 // as if climbing off the top of the screen
	g.joe.State, g.joe.DY = joe.Ladder, -1
	before := g.joe
	g.changeRoom(joe.ExitUp, before)
	if g.room != 1 || g.joe.RawY != 2 {
		t.Errorf("room %d, RawY %d; want to stay in room 1 at RawY 2", g.room, g.joe.RawY)
	}
}

// TestKilledByEnemy jumps onto the pole in room 12; an enemy reaches Joe at
// the bottom. After the respawn that enemy is gone.
func TestKilledByEnemy(t *testing.T) {
	g := testGame(t, 12, 12, 53)
	enemies := len(g.enemies.Objects)
	for f := 0; f < 40; f++ {
		g.step(joe.Input{Right: f < 30, Fire: f == 2})
	}
	if g.joe.State != joe.Zapped {
		t.Fatalf("state %d, want killed by an enemy", g.joe.State)
	}
	run(g, 200, joe.Input{})
	if g.lives != startLives-1 || len(g.enemies.Objects) != enemies-1 {
		t.Errorf("lives %d, %d enemies; want %d lives and %d enemies",
			g.lives, len(g.enemies.Objects), startLives-1, enemies-1)
	}
}
