package gfx

import (
	"fmt"

	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/vdp"
)

// The title screen ($8116): the BIOS font (LOAD_ASCII), the capitals
// enlarged into 2x2 blocks of tiles from $80 (ENLARGE), the room colours
// with the big letters' groups yellow, then "PARKER BROTHERS PRESENTS" and
// "MONTEZUMA'S" through the loader, and "REVENGE" and the level choice
// through the tile writer ($AEA7).
const (
	titleNames   = 0x813A // loader call: the first four rows of text
	tileColours  = 0x830A // loader call: the room colours
	bigLetters   = 0x80   // tile of the enlarged A
	bigColour    = 0xA0   // yellow
	bigFirstSet  = 16     // colour entries $10-$1D ($2010, 14 bytes)
	bigLastSet   = 29
	capitalA     = 0x41
	capitalCount = 26
)

// titleRows are the tile writer's rows: source, name table index, length.
var titleRows = []struct {
	src   uint16
	index int
	n     int
}{
	{0x82C2, 0x12A, 13}, // REVENGE, top half
	{0x82D0, 0x14A, 13}, // bottom half
	{0x8293, 0x1E5, 23}, // SELECT LEVEL   1, 2, 3.
}

// Title returns the video tables of the title screen.
func Title(r *rom.ROM) (*vdp.VRAM, error) {
	v := &vdp.VRAM{}
	for c := 0x20; c < 0x7F; c++ {
		copy(v.TilePatterns[c*8:], vdp.Font[c][:])
	}
	for i := range capitalCount {
		var p [8]byte
		copy(p[:], v.TilePatterns[(capitalA+i)*8:])
		for q, b := range vdp.Enlarge(p) {
			copy(v.TilePatterns[(bigLetters+i*4+q)*8:], b[:])
		}
	}

	m := &memory{rom: r}
	for _, addr := range []uint16{tileColours, titleNames} {
		c, ok := r.LoaderCallAt(addr)
		if !ok {
			return nil, fmt.Errorf("no loader call at $%04X", addr)
		}
		if err := apply(v, m, c); err != nil {
			return nil, fmt.Errorf("loader call $%04X: %w", addr, err)
		}
	}
	for e := bigFirstSet; e <= bigLastSet; e++ {
		v.Colours[e] = bigColour
	}
	for _, row := range titleRows {
		src, err := r.Slice(row.src, row.n)
		if err != nil {
			return nil, err
		}
		copy(v.Names[row.index:], src)
	}
	return v, nil
}
