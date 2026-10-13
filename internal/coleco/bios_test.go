package coleco

import "testing"

// TestReflectDirections pins down OS7's naming: REFLECT_VERTICAL ($1F6A)
// mirrors left-right and REFLECT_HORIZONTAL ($1F6D) flips upside down.
// Getting these backwards scrambles the rolling skull and climbing frames.
func TestReflectDirections(t *testing.T) {
	m := New(nil)
	m.mode1()
	base := m.VDP.spriteGenBase()
	src := [8]byte{0x80, 0, 0, 0, 0, 0, 0, 0} // one pixel, top-left
	copy(m.VDP.VRAM[base:], src[:])

	call := func(addr uint16) [8]byte {
		m.CPU.AF.Hi = 1 // sprite generator table
		m.CPU.DE.SetU16(0)
		m.CPU.HL.SetU16(1)
		m.CPU.BC.SetU16(1)
		biosCalls[addr](m)
		var out [8]byte
		copy(out[:], m.VDP.VRAM[base+8:])
		return out
	}
	if got := call(0x1F6A); got != [8]byte{0x01} {
		t.Errorf("REFLECT_VERTICAL = % X, want the pixel top-right", got)
	}
	if got := call(0x1F6D); got != [8]byte{7: 0x80} {
		t.Errorf("REFLECT_HORIZONTAL = % X, want the pixel bottom-left", got)
	}
}
