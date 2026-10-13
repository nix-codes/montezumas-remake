package coleco

import (
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"
)

// asciiFont stands in for the BIOS font that LOAD_ASCII copies into the
// pattern table. It squeezes Go's 7x13 basic font into 8x8 cells by
// keeping the capital-letter rows and dropping one near the bottom; the game
// only prints capitals and digits.
var asciiFont = func() (font [128][8]byte) {
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

// loadASCII copies the font into the pattern table at the ASCII codes.
func (m *Machine) loadASCII() {
	base := m.VDP.patternBase()
	for c := 0x20; c < 0x7F; c++ {
		copy(m.VDP.VRAM[base+c*8:], asciiFont[c][:])
	}
}
