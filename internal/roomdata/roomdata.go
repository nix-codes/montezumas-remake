// Package roomdata is the format of rooms.json, written by cmd/rooms from
// the original game and read by the remake.
package roomdata

import (
	"encoding/json"
	"fmt"
	"os"
)

// Room is one room as the original game draws it.
type Room struct {
	Number int   `json:"number"`
	Row    int   `json:"row"`
	Column int   `json:"column"`
	Exits  Exits `json:"exits"`

	// Tiles is the screen: 24 rows of 32 tile numbers.
	Tiles [24][32]byte `json:"tiles"`

	// The video tables in force in this room: tile patterns (8 bytes per
	// tile), tile colours (one byte per 8 tiles: foreground in the high
	// nibble), sprite patterns, and the backdrop colour.
	TilePatterns   []byte `json:"tilePatterns"`
	TileColours    []byte `json:"tileColours"`
	SpritePatterns []byte `json:"spritePatterns"`
	Backdrop       int    `json:"backdrop"`

	// The game's enemy state right after the room loads: the object list
	// ($7086, 2 bytes per enemy, ending at $FF), the list the contact check
	// walks ($72C1, ending at $FE), the local sprite table ($7300, 8
	// entries of Y, X, pattern, colour) and the shared frame counter
	// ($7097). See internal/enemy.
	Objects      []byte `json:"objects"`
	Contacts     []byte `json:"contacts"`
	SpriteTable  []byte `json:"spriteTable"`
	FrameCounter byte   `json:"frameCounter"`
}

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
	}
	return rooms, nil
}
