// Package gfx rebuilds the game's video memory from the ROM by replaying
// the graphics loads it makes at boot.
package gfx

import (
	"fmt"

	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/vdp"
)

// Backdrop is the colour shown through transparent pixels; the game sets
// VDP register 7 to black at boot.
const Backdrop = 1

// Loader calls made while the game boots, in the order it makes them.
// Other call sites swap in animation frames or screens at run time.
var bootLoads = []uint16{
	0x8081, // sprite patterns
	0x830A, // tile colours
	0x83A1, // main tileset
}

// Boot returns the video tables as they stand after the game's boot loads.
func Boot(r *rom.ROM) (*vdp.VRAM, error) {
	m := &memory{rom: r}
	// Boot copies two dithered sprite bitmaps into RAM (DELAY_LOOP_827F),
	// which the sprite loader then reads from.
	for _, c := range []struct{ dst, src uint16 }{{0x7200, 0x86C8}, {0x7220, 0x86A8}} {
		if err := m.ditherCopy(c.dst, c.src); err != nil {
			return nil, err
		}
	}

	v := &vdp.VRAM{}
	for _, addr := range bootLoads {
		c, ok := r.LoaderCallAt(addr)
		if !ok {
			return nil, fmt.Errorf("no loader call at $%04X", addr)
		}
		if err := apply(v, m, c); err != nil {
			return nil, fmt.Errorf("loader call $%04X: %w", addr, err)
		}
	}
	return v, nil
}

// memory is the CPU address space the loader reads from: 1 KB of RAM at
// $7000 and the cartridge from $8000.
type memory struct {
	rom *rom.ROM
	ram [0x400]byte
}

const ramBase = 0x7000

func (m *memory) slice(addr uint16, n int) ([]byte, error) {
	if addr >= ramBase && int(addr)+n <= ramBase+len(m.ram) {
		return m.ram[addr-ramBase : int(addr-ramBase)+n], nil
	}
	return m.rom.Slice(addr, n)
}

// ditherCopy copies 16 byte pairs from ROM to RAM, keeping odd pixels of the
// first byte and even pixels of the second, like DELAY_LOOP_827F.
func (m *memory) ditherCopy(dst, src uint16) error {
	in, err := m.rom.Slice(src, 32)
	if err != nil {
		return err
	}
	out, err := m.slice(dst, 32)
	if err != nil {
		return err
	}
	for i := 0; i < 32; i += 2 {
		out[i] = in[i] & 0xAA
		out[i+1] = in[i+1] & 0x55
	}
	return nil
}

func apply(v *vdp.VRAM, m *memory, c rom.LoaderCall) error {
	size := vdp.ItemSize(c.Table)
	if size == 0 {
		return fmt.Errorf("unknown table %d", c.Table)
	}
	for _, rec := range c.Records {
		src, err := m.slice(rec.Src, rec.Count*size)
		if err != nil {
			return err
		}
		if err := v.Put(c.Table, rec.Index, rec.Count, src); err != nil {
			return err
		}
	}
	return nil
}
