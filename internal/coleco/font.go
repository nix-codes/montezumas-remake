package coleco

import "montezuma-remake/internal/vdp"

// loadASCII copies the stand-in font into the pattern table at the ASCII
// codes.
func (m *Machine) loadASCII() {
	base := m.VDP.patternBase()
	for c := 0x20; c < 0x7F; c++ {
		copy(m.VDP.VRAM[base+c*8:], vdp.Font[c][:])
	}
}
