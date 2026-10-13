package pyramid

import (
	"os"
	"testing"

	"montezuma-remake/internal/rom"
)

func TestRowOffsetsMatchROM(t *testing.T) {
	if _, err := os.Stat("../../build/montezuma.rom"); err != nil {
		t.Skip("build/montezuma.rom missing; run make rom")
	}
	r, err := rom.Load("../../build/montezuma.rom")
	if err != nil {
		t.Fatal(err)
	}
	b, err := r.Slice(0xA4C5, Rows)
	if err != nil {
		t.Fatal(err)
	}
	for i, v := range b {
		if int(int8(v)) != rowOffset[i] {
			t.Errorf("row %d offset = %d, ROM has %d", i, rowOffset[i], int8(v))
		}
	}
}

func TestRoomsAreContiguous(t *testing.T) {
	if r, c := Position(Entrance); Room(r, c) != Entrance {
		t.Fatalf("entrance hall doesn't round-trip")
	}
	next := Entrance + 1
	for row := 0; row < Rows; row++ {
		first, last := ColumnRange(row)
		for col := first; col <= last; col++ {
			if got := Room(row, col); got != next {
				t.Fatalf("Room(%d, %d) = %d, want %d", row, col, got, next)
			}
			if r, c := Position(next); r != row || c != col {
				t.Fatalf("Position(%d) = %d, %d, want %d, %d", next, r, c, row, col)
			}
			next++
		}
	}
	if next != Rooms {
		t.Errorf("%d rooms, want %d", next, Rooms)
	}
}

func TestNeighbours(t *testing.T) {
	// The starting room is in the middle of the top row.
	for _, c := range []struct {
		d    Direction
		want int
	}{{Left, 1}, {Right, 3}, {Up, Entrance}, {Down, 6}} {
		if got := Neighbour(Start, c.d); got != c.want {
			t.Errorf("Neighbour(Start, %v) = %d, want %d", c.d, got, c.want)
		}
	}
	// Side exits wrap into the neighbouring row, as in the game.
	if got := Neighbour(4, Left); got != 3 {
		t.Errorf("Neighbour(4, Left) = %d, want 3", got)
	}
	if got := Neighbour(8, Right); got != 9 {
		t.Errorf("Neighbour(8, Right) = %d, want 9", got)
	}
	if got := Neighbour(81, Down); got != -1 {
		t.Errorf("Neighbour(81, Down) = %d, want -1 (next level)", got)
	}
	if got := Neighbour(Entrance, Down); got != Start {
		t.Errorf("Neighbour(Entrance, Down) = %d, want Start", got)
	}
	// The bottom row runs from room 81 to room 99.
	if first, last := ColumnRange(Rows - 1); Room(Rows-1, first) != 81 || Room(Rows-1, last) != 99 {
		t.Errorf("bottom row = %d..%d, want 81..99", Room(Rows-1, first), Room(Rows-1, last))
	}
}
