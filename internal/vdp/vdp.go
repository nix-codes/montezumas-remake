// Package vdp models the TMS9918A video tables the game writes to, in
// Graphics I mode, closely enough to render its tiles and sprites.
package vdp

import (
	"fmt"
	"image"
	"image/color"
)

// PUT_VRAM table codes used by the ColecoVision BIOS.
const (
	SpriteAttr    = 0
	SpritePattern = 1
	NameTable     = 2
	TilePattern   = 3
	ColourTable   = 4
)

// Palette is the TMS9918A palette. Index 0 is transparent.
var Palette = [16]color.RGBA{
	{0, 0, 0, 0},
	{0x00, 0x00, 0x00, 0xFF}, {0x21, 0xC8, 0x42, 0xFF}, {0x5E, 0xDC, 0x78, 0xFF},
	{0x54, 0x55, 0xED, 0xFF}, {0x7D, 0x76, 0xFC, 0xFF}, {0xD4, 0x52, 0x4D, 0xFF},
	{0x42, 0xEB, 0xF5, 0xFF}, {0xFC, 0x55, 0x54, 0xFF}, {0xFF, 0x79, 0x78, 0xFF},
	{0xD4, 0xC1, 0x54, 0xFF}, {0xE6, 0xCE, 0x80, 0xFF}, {0x21, 0xB0, 0x3B, 0xFF},
	{0xC9, 0x5B, 0xBA, 0xFF}, {0xCC, 0xCC, 0xCC, 0xFF}, {0xFF, 0xFF, 0xFF, 0xFF},
}

// VRAM holds the video tables in Graphics I mode.
type VRAM struct {
	SpriteAttrs    [32 * 4]byte
	SpritePatterns [256 * 8]byte
	Names          [32 * 24]byte
	TilePatterns   [256 * 8]byte
	Colours        [32]byte // one fg/bg byte per group of 8 tiles
}

// Put copies count items from src into table at index, like BIOS PUT_VRAM.
func (v *VRAM) Put(table, index, count int, src []byte) error {
	dst, size := v.table(table)
	if dst == nil {
		return fmt.Errorf("unknown table %d", table)
	}
	start, n := index*size, count*size
	if start+n > len(dst) || n > len(src) {
		return fmt.Errorf("table %d: %d items at %d out of range", table, count, index)
	}
	copy(dst[start:start+n], src[:n])
	return nil
}

// ItemSize returns the size in bytes of one item of table.
func ItemSize(table int) int {
	_, size := (&VRAM{}).table(table)
	return size
}

func (v *VRAM) table(t int) ([]byte, int) {
	switch t {
	case SpriteAttr:
		return v.SpriteAttrs[:], 4
	case SpritePattern:
		return v.SpritePatterns[:], 8
	case NameTable:
		return v.Names[:], 1
	case TilePattern:
		return v.TilePatterns[:], 8
	case ColourTable:
		return v.Colours[:], 1
	}
	return nil, 0
}

// DrawTile draws tile n in its colours with its top-left corner at (x, y).
// Transparent pixels show the backdrop colour.
func (v *VRAM) DrawTile(img *image.RGBA, n, x, y int, backdrop int) {
	c := v.Colours[n/8]
	fg, bg := opaque(c>>4, backdrop), opaque(c&0x0F, backdrop)
	for row := 0; row < 8; row++ {
		bits := v.TilePatterns[n*8+row]
		for col := 0; col < 8; col++ {
			if bits&(0x80>>col) != 0 {
				img.SetRGBA(x+col, y+row, fg)
			} else {
				img.SetRGBA(x+col, y+row, bg)
			}
		}
	}
}

// DrawSprite16 draws the 16x16 sprite made of patterns n..n+3 (top-left,
// bottom-left, top-right, bottom-right) at (x, y) in colour c.
func (v *VRAM) DrawSprite16(img *image.RGBA, n, x, y int, c color.RGBA) {
	for q := 0; q < 4; q++ {
		qx, qy := x+(q/2)*8, y+(q%2)*8
		for row := 0; row < 8; row++ {
			bits := v.SpritePatterns[(n+q)*8+row]
			for col := 0; col < 8; col++ {
				if bits&(0x80>>col) != 0 {
					img.SetRGBA(qx+col, qy+row, c)
				}
			}
		}
	}
}

func opaque(c byte, backdrop int) color.RGBA {
	if c == 0 {
		return Palette[backdrop]
	}
	return Palette[c]
}
