package main

import (
	"os"
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/pyramid"
)

// walkOff loads room, puts Joe beside the given edge with his feet on tile
// row feetRow, holds the joystick towards the edge and returns the room the
// game is in afterwards.
func walkOff(t *testing.T, room int, d pyramid.Direction, feetRow int) int {
	cart, err := os.ReadFile("../../build/montezuma.rom")
	if err != nil {
		t.Skip("build/montezuma.rom missing; run make rom")
	}
	m, err := startGame(cart, 1)
	if err != nil {
		t.Fatal(err)
	}
	row, col := pyramid.Position(room)
	m.Poke(rowVar, byte(row))
	m.Poke(colVar, byte(col))
	if err := m.Call(loadRoom, 300); err != nil {
		t.Fatal(err)
	}
	x := byte(8)
	if d == pyramid.Right {
		x = 232
	}
	y := byte(feetRow*8 - 17) // sprite Y is one less than the top line
	for _, a := range []uint16{0x7300, 0x7304} {
		m.Poke(a, y)
		m.Poke(a+1, x)
	}
	for f := 0; f < 120; f++ {
		m.Input = coleco.Joystick{Key: -1, Left: d == pyramid.Left, Right: d == pyramid.Right}
		if err := m.RunFrame(); err != nil {
			t.Fatal(err)
		}
	}
	return int(m.Peek(roomVar))
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
		want := pyramid.Neighbour(c.room, c.d)
		if got := walkOff(t, c.room, c.d, 9); got != want {
			t.Errorf("room %d, walking %v: game moved to room %d, pyramid.Neighbour says %d", c.room, c.d, got, want)
		}
	}
}
