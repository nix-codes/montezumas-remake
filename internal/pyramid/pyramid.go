// Package pyramid describes how the game's rooms are arranged: room 0 is
// the entrance hall, beside the top row, and rooms 1-99 form a pyramid of
// nine rows of 3, 5, ... 19 rooms, centred on column 10.
//
// The game keeps the row in $71A7 and the column in $71A8. Moving left or
// right changes the column by one; moving up or down changes the row and
// keeps the column. The room number is the column plus a per-row offset
// (table at $A4C5), and indexes the layout table at $9477.
//
// The game never checks a column against its row, so walking off the end of
// a row wraps into the next room by number: left from room 4, the first
// room of row 1, leads to room 3, the last room of row 0. The row and column
// then no longer match the room's own position, and later moves up or down
// follow the game's arithmetic, not the room's place in the pyramid. A
// faithful remake should track row and column the same way; Room does the
// arithmetic. Leaving the bottom row downwards starts the next level.
package pyramid

// Rows is the number of rows; row 0 is the top.
const Rows = 9

// Rooms is the number of rooms, including the entrance hall.
const Rooms = 100

// Entrance is the entrance hall, where every level starts. Joe leaves it by
// sliding down a pole into Start.
const Entrance = 0

// Start is the room Joe lands in: the middle of the top row.
const Start = 2

// Centre is the column of the middle room of every row.
const Centre = 10

// entranceColumn is the entrance hall's column, left of row 0.
const entranceColumn = 8

// rowOffset is the table at $A4C5: room = column + rowOffset[row].
var rowOffset = [Rows]int{-8, -4, 2, 10, 20, 32, 46, 62, 80}

// ColumnRange returns the first and last column of row, not counting the
// entrance hall.
func ColumnRange(row int) (first, last int) {
	return Centre - 1 - row, Centre + 1 + row
}

// Room returns the room the game shows at row and column, using its
// arithmetic, or -1 if that isn't a room.
func Room(row, col int) int {
	if row < 0 || row >= Rows {
		return -1
	}
	if n := col + rowOffset[row]; n >= 0 && n < Rooms {
		return n
	}
	return -1
}

// Position returns the row and column of room's place in the pyramid.
func Position(room int) (row, col int) {
	if room == Entrance {
		return 0, entranceColumn
	}
	if room < 0 || room >= Rooms {
		return -1, -1
	}
	for r := Rows - 1; r >= 0; r-- {
		first, _ := ColumnRange(r)
		if room >= first+rowOffset[r] {
			return r, room - rowOffset[r]
		}
	}
	return -1, -1
}

// Direction is a way out of a room.
type Direction int

const (
	Left Direction = iota
	Right
	Up
	Down
)

func (d Direction) String() string {
	return [...]string{"left", "right", "up", "down"}[d]
}

// Neighbour returns the room the game moves to when Joe leaves room in
// direction d, starting from room's place in the pyramid, or -1 if there is
// none. The entrance hall's pole connects it to Start, below and to the
// right.
func Neighbour(room int, d Direction) int {
	switch {
	case room == Entrance && d == Down:
		return Start
	case room == Start && d == Up:
		return Entrance
	}
	row, col := Position(room)
	switch d {
	case Left:
		return Room(row, col-1)
	case Right:
		return Room(row, col+1)
	case Up:
		return Room(row-1, col)
	default:
		return Room(row+1, col)
	}
}
