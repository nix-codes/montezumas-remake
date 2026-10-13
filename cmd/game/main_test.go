package main

import (
	"testing"

	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

func testGame(t *testing.T) *game {
	t.Helper()
	rooms, err := roomdata.Load("../../assets/rooms/level1/rooms.json")
	if err != nil {
		t.Skip(err)
	}
	r, err := rom.Load("../../build/montezuma.rom")
	if err != nil {
		t.Skip(err)
	}
	floors, err := r.Slice(floorList, floorLen)
	if err != nil {
		t.Fatal(err)
	}
	return newGame(rooms, floors)
}

func TestLeaveRoom(t *testing.T) {
	for _, c := range []struct {
		name         string
		from         int
		x, y         int
		want         int
		wantX, wantY int
	}{
		{"left", pyramid.Start, -9, 56, 1, 247, 56},
		{"right", pyramid.Start, 249, 56, 3, -7, 56},
		{"down", pyramid.Start, 100, 185, 6, 100, -7},
		{"wrap left into the row above", 4, -9, 56, 3, 247, 56},
		{"wrap right into the row below", 8, 249, 56, 9, -7, 56},
		{"entrance pole down", pyramid.Entrance, 100, 185, pyramid.Start, 100, -7},
		{"start pole up", pyramid.Start, 120, -9, pyramid.Entrance, 120, 183},
		{"bottom row: next level not implemented", 90, 100, 185, 90, 100, 184},
	} {
		g := testGame(t)
		g.enter(c.from)
		g.joe.x, g.joe.y = c.x, c.y
		g.leaveRoom()
		if g.room != c.want || g.joe.x != c.wantX || g.joe.y != c.wantY {
			t.Errorf("%s: room %d at (%d, %d), want room %d at (%d, %d)",
				c.name, g.room, g.joe.x, g.joe.y, c.want, c.wantX, c.wantY)
		}
	}
}

// TestClimbDownStartRoom climbs down the ladder Joe lands on in the
// starting room, steps off to the right and expects him to be standing on
// the conveyor belt below (tile row 17).
func TestClimbDownStartRoom(t *testing.T) {
	g := testGame(t)
	g.enter(pyramid.Start)
	for i := 0; i < 200; i++ {
		g.move(input{down: true})
		g.leaveRoom()
	}
	for i := 0; i < 10; i++ { // step off the ladder
		g.move(input{right: true})
	}
	if g.room != pyramid.Start || g.joe.climbing || g.joe.y != 17*8-16 {
		t.Errorf("room %d at (%d, %d), climbing %v; want standing on row 17 of the starting room",
			g.room, g.joe.x, g.joe.y, g.joe.climbing)
	}
}
