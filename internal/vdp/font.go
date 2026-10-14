package vdp

import (
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"
)

// Font stands in for the BIOS font that LOAD_ASCII copies into the
// pattern table, at the ASCII codes. It squeezes Go's 7x13 basic font
// into 8x8 cells by keeping the capital-letter rows and dropping one near
// the bottom; the game only prints capitals and digits.
var Font = func() (font [128][8]byte) {
	f := basicfont.Face7x13
	const capTop, skip = 2, 9 // first row of a capital; row dropped to fit 9 into 8
	for r := rune(0x20); r < 0x7F; r++ {
		dr, mask, mp, _, ok := f.Glyph(fixed.P(0, f.Ascent), r)
		if !ok {
			continue
		}
		for row := 0; row < 8; row++ {
			y := capTop + row
			if y >= skip {
				y++
			}
			var bits byte
			for x := 0; x < 8; x++ {
				px, py := x-dr.Min.X, y-dr.Min.Y
				if px < 0 || py < 0 || px >= dr.Dx() || py >= dr.Dy() {
					continue
				}
				if _, _, _, a := mask.At(mp.X+px, mp.Y+py).RGBA(); a > 0x8000 {
					bits |= 0x80 >> x
				}
			}
			font[r][row] = bits
		}
	}
	return font
}()

// Enlarge doubles a pattern into a 16x16 block of four, as the BIOS's
// ENLARGE does, in sprite order: top-left, bottom-left, top-right,
// bottom-right.
func Enlarge(p [8]byte) (out [4][8]byte) {
	var big [16]uint16
	for row, b := range p {
		var w uint16
		for bit := 0; bit < 8; bit++ {
			if b&(0x80>>bit) != 0 {
				w |= 0xC000 >> (bit * 2)
			}
		}
		big[row*2], big[row*2+1] = w, w
	}
	for q := range out {
		for row := range 8 {
			w := big[(q%2)*8+row]
			out[q][row] = byte(w >> 8)
			if q >= 2 {
				out[q][row] = byte(w)
			}
		}
	}
	return out
}
