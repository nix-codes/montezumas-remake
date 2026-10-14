package gfx

import (
	"fmt"
	"math/bits"

	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/vdp"
)

// The game animates tiles without touching the screen: at boot ($81DC) it
// fills four tile pattern tables in VRAM, each with the main tileset, its
// own frame of the animated tiles (fire, conveyors, ...) and their mirror
// images, and the frame interrupt then points VDP register 4 at each in
// turn ($A9F3). On every step it also rewrites the barrier ($E0) and
// disappearing floor ($E8) patterns in all four ($A92F), from a counter
// the contact task steps.

// tableLoads are the loader calls that give each table its frames, in the
// order the frame interrupt shows them: $0000, $0800, $1000, $2800.
var tableLoads = []uint16{0x8262, 0x81E5, 0x8206, 0x8233}

const (
	mainTileset   = 0x83A1 // loader call for the main tileset, into each table
	mirrorList    = 0x837D // $8314's list: mode, table code, then (from, to) pairs up to $FF
	chainPatterns = 0x85BC // barrier: an 8-byte window, 2 bytes on per frame
	floorPatterns = 0x85CA // disappearing floor: two patterns, by frame parity

	tileBarrier   = 0xE0
	tileDisappear = 0xE8
)

// Animation holds the four tile pattern tables, for the tiles the ROM
// loads into them; the rest come from the patterns captured with a room.
type Animation struct {
	tables [4][256 * 8]byte
	loaded [256]bool
	chain  []byte
	floor  []byte
}

// NewAnimation builds the four tables from the ROM, as the boot does.
func NewAnimation(r *rom.ROM) (*Animation, error) {
	a := &Animation{}
	m := &memory{rom: r}
	main, ok := r.LoaderCallAt(mainTileset)
	if !ok {
		return nil, fmt.Errorf("no loader call at $%04X", mainTileset)
	}
	list, err := r.Slice(mirrorList, 2)
	if err != nil {
		return nil, err
	}
	var mirrors [][2]byte
	for addr := uint16(mirrorList + 2); ; addr += 2 {
		p, err := r.Slice(addr, 2)
		if err != nil {
			return nil, err
		}
		if p[0] == 0xFF {
			break
		}
		mirrors = append(mirrors, [2]byte{p[0], p[1]})
	}
	if list[0] != 1 || list[1] != vdp.TilePattern {
		return nil, fmt.Errorf("mirror list at $%04X: unexpected mode %d, table %d", mirrorList, list[0], list[1])
	}

	for i, addr := range tableLoads {
		frames, ok := r.LoaderCallAt(addr)
		if !ok {
			return nil, fmt.Errorf("no loader call at $%04X", addr)
		}
		v := &vdp.VRAM{}
		for _, c := range []rom.LoaderCall{main, frames} {
			if err := apply(v, m, c); err != nil {
				return nil, fmt.Errorf("loader call $%04X: %w", c.Addr, err)
			}
			for _, rec := range c.Records {
				for t := rec.Index; t < rec.Index+rec.Count; t++ {
					a.loaded[t] = true
				}
			}
		}
		// REFLECT_VERTICAL: mirror left to right.
		for _, p := range mirrors {
			for y := range 8 {
				v.TilePatterns[int(p[1])*8+y] = bits.Reverse8(v.TilePatterns[int(p[0])*8+y])
			}
			a.loaded[p[1]] = true
		}
		a.tables[i] = v.TilePatterns
	}

	if a.chain, err = r.Slice(chainPatterns, 6+8); err != nil {
		return nil, err
	}
	if a.floor, err = r.Slice(floorPatterns, 16); err != nil {
		return nil, err
	}
	return a, nil
}

// Tables is how many pattern tables the game cycles through.
func (a *Animation) Tables() int { return len(a.tables) }

// Patterns returns the tile patterns of table (0-3, in the order shown)
// with the barrier and disappearing floor at frame (0-3, $7096), filling
// the tiles the ROM doesn't load from base.
func (a *Animation) Patterns(base []byte, table int, frame byte) [256 * 8]byte {
	var p [256 * 8]byte
	copy(p[:], base)
	for t, ok := range a.loaded {
		if ok {
			copy(p[t*8:t*8+8], a.tables[table][t*8:t*8+8])
		}
	}
	f := int(frame & 3)
	copy(p[tileBarrier*8:], a.chain[2*f:2*f+8])
	copy(p[tileDisappear*8:], a.floor[8*(f&1):8*(f&1)+8])
	return p
}
