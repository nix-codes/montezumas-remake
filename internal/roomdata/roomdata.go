// Package roomdata is the format of rooms.json, written by cmd/rooms from
// the original game and read by the remake.
package roomdata

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
)

// Room is one room as the original game draws it.
type Room struct {
	Number int
	Row    int
	Column int
	Exits  Exits

	// Tiles is the screen: 24 rows of 32 tile numbers.
	Tiles [24][32]byte

	// The video tables in force in this room: tile patterns (8 bytes per
	// tile), tile colours (one byte per 8 tiles: foreground in the high
	// nibble) as lit, with the torch, sprite patterns, and the backdrop
	// colour.
	TilePatterns   []byte
	TileColours    []byte
	SpritePatterns []byte
	Backdrop       int

	// The game's enemy state right after the room loads: the object list
	// ($7086, 2 bytes per enemy, ending at $FF), the list the contact check
	// walks ($72C1, ending at $FE), the local sprite table ($7300, 8
	// entries of Y, X, pattern, colour) and the shared frame counter
	// ($7097). See internal/enemy.
	Objects      []byte
	Contacts     []byte
	SpriteTable  []byte
	FrameCounter byte

	// SyncDelay is how many frames the game stands still after drawing
	// this room, beyond the drawing itself. Rooms built by mirroring
	// another ($AB29) leave a tile in the main loop's frame-sync byte
	// ($7207), which overlaps the row buffer at $7200; the main loop then
	// waits for the frame interrupt to count it down. 0 for other rooms.
	SyncDelay byte

	// Bare is set for the entrance hall only: its top rows as drawn at the
	// start of a level ($705F bit 2), when the loader leaves out the HUD
	// ($A1EE) and the poles reach the top of the screen.
	Bare *[HUDRows][32]byte
}

// HUDRows is how many rows at the top of the screen the HUD takes.
const HUDRows = 5

// Exits lists, per side, the neighbouring room (-1 if none) and where the
// openings are: tile rows for left and right, tile columns for up and down.
// Drop marks gaps in the bottom edge that Joe can fall through.
type Exits struct {
	Left, Right, Up, Down int
	LeftRows, RightRows   []int `json:",omitempty"`
	UpColumns             []int `json:",omitempty"`
	DownColumns           []int `json:",omitempty"`
	DropColumns           []int `json:",omitempty"`
}

// room is a Room as rooms.json stores it: byte tables as hex strings, one
// row of the table per string, so a room's tiles read as a map of it.
type room struct {
	Number int   `json:"number"`
	Row    int   `json:"row"`
	Column int   `json:"column"`
	Exits  Exits `json:"exits"`

	Tiles          []string `json:"tiles"`
	TilePatterns   []string `json:"tilePatterns"` // one tile per string
	TileColours    string   `json:"tileColours"`
	SpritePatterns []string `json:"spritePatterns"` // one 16x16 sprite per string
	Backdrop       int      `json:"backdrop"`

	Objects      string   `json:"objects"`
	Contacts     string   `json:"contacts"`
	SpriteTable  []string `json:"spriteTable"` // one entry per string
	FrameCounter byte     `json:"frameCounter"`

	SyncDelay byte     `json:"syncDelay"`
	Bare      []string `json:"bare,omitempty"`
}

// Row widths of the tables, in bytes.
const (
	tilePatternRow   = 8
	spritePatternRow = 32
	spriteTableRow   = 4
)

func (r Room) MarshalJSON() ([]byte, error) {
	j := room{
		Number:         r.Number,
		Row:            r.Row,
		Column:         r.Column,
		Exits:          r.Exits,
		Tiles:          gridRows(r.Tiles[:]),
		TilePatterns:   hexRows(r.TilePatterns, tilePatternRow),
		TileColours:    hex.EncodeToString(r.TileColours),
		SpritePatterns: hexRows(r.SpritePatterns, spritePatternRow),
		Backdrop:       r.Backdrop,
		Objects:        hex.EncodeToString(r.Objects),
		Contacts:       hex.EncodeToString(r.Contacts),
		SpriteTable:    hexRows(r.SpriteTable, spriteTableRow),
		FrameCounter:   r.FrameCounter,
		SyncDelay:      r.SyncDelay,
	}
	if r.Bare != nil {
		j.Bare = gridRows(r.Bare[:])
	}
	return json.Marshal(j)
}

func (r *Room) UnmarshalJSON(b []byte) error {
	var j room
	if err := json.Unmarshal(b, &j); err != nil {
		return err
	}
	*r = Room{
		Number:       j.Number,
		Row:          j.Row,
		Column:       j.Column,
		Exits:        j.Exits,
		Backdrop:     j.Backdrop,
		FrameCounter: j.FrameCounter,
		SyncDelay:    j.SyncDelay,
	}
	var err error
	field := func(name string, f func() error) {
		if err == nil {
			if e := f(); e != nil {
				err = fmt.Errorf("room %d: %s: %w", j.Number, name, e)
			}
		}
	}
	field("tiles", func() error { return gridFrom(r.Tiles[:], j.Tiles) })
	field("tilePatterns", func() (e error) { r.TilePatterns, e = unhexRows(j.TilePatterns, tilePatternRow); return })
	field("tileColours", func() (e error) { r.TileColours, e = hex.DecodeString(j.TileColours); return })
	field("spritePatterns", func() (e error) { r.SpritePatterns, e = unhexRows(j.SpritePatterns, spritePatternRow); return })
	field("objects", func() (e error) { r.Objects, e = hex.DecodeString(j.Objects); return })
	field("contacts", func() (e error) { r.Contacts, e = hex.DecodeString(j.Contacts); return })
	field("spriteTable", func() (e error) { r.SpriteTable, e = unhexRows(j.SpriteTable, spriteTableRow); return })
	if j.Bare != nil {
		r.Bare = new([HUDRows][32]byte)
		field("bare", func() error { return gridFrom(r.Bare[:], j.Bare) })
	}
	return err
}

// hexRows splits b into hex strings of width bytes each.
func hexRows(b []byte, width int) []string {
	rows := make([]string, 0, (len(b)+width-1)/width)
	for len(b) > 0 {
		n := min(width, len(b))
		rows = append(rows, hex.EncodeToString(b[:n]))
		b = b[n:]
	}
	return rows
}

// unhexRows joins hex strings of width bytes each back into one table.
func unhexRows(rows []string, width int) ([]byte, error) {
	b := make([]byte, 0, len(rows)*width)
	for i, s := range rows {
		row, err := hex.DecodeString(s)
		if err != nil {
			return nil, fmt.Errorf("row %d: %w", i, err)
		}
		if len(row) != width {
			return nil, fmt.Errorf("row %d is %d bytes, not %d", i, len(row), width)
		}
		b = append(b, row...)
	}
	return b, nil
}

// gridRows writes a tile grid as one hex string per row.
func gridRows(g [][32]byte) []string {
	rows := make([]string, len(g))
	for y := range g {
		rows[y] = hex.EncodeToString(g[y][:])
	}
	return rows
}

// gridFrom reads a tile grid back from one hex string per row.
func gridFrom(g [][32]byte, rows []string) error {
	if len(rows) != len(g) {
		return fmt.Errorf("%d rows, not %d", len(rows), len(g))
	}
	b, err := unhexRows(rows, 32)
	if err != nil {
		return err
	}
	for y := range g {
		copy(g[y][:], b[y*32:])
	}
	return nil
}

// Load reads a rooms.json file.
func Load(path string) ([]Room, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("%w (run make rooms)", err)
	}
	var rooms []Room
	if err := json.Unmarshal(b, &rooms); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	for i, r := range rooms {
		if r.Number != i {
			return nil, fmt.Errorf("%s: room %d is at position %d", path, r.Number, i)
		}
		if len(r.TilePatterns) != 256*8 || len(r.TileColours) != 32 || len(r.SpritePatterns) != 256*8 ||
			len(r.SpriteTable) != 32 || len(r.Objects) == 0 {
			return nil, fmt.Errorf("%s: room %d is missing data (rerun make rooms)", path, i)
		}
		if i == 0 && r.Bare == nil {
			return nil, fmt.Errorf("%s: the entrance hall is missing data (rerun make rooms)", path)
		}
	}
	return rooms, nil
}
