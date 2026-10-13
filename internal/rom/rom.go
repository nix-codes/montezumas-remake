// Package rom reads the assembled ColecoVision cartridge image.
package rom

import (
	"fmt"
	"os"
)

// Base is the CPU address the cartridge is mapped at.
const Base = 0x8000

// ROM is a cartridge image addressed by CPU address.
type ROM struct {
	data []byte
}

// Load reads a cartridge image and checks its header.
func Load(path string) (*ROM, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(data) < 2 || data[0] != 0x55 || data[1] != 0xAA {
		return nil, fmt.Errorf("%s: missing $AA55 cartridge header", path)
	}
	return &ROM{data: data}, nil
}

// Slice returns n bytes starting at CPU address addr.
func (r *ROM) Slice(addr uint16, n int) ([]byte, error) {
	off := int(addr) - Base
	if off < 0 || off+n > len(r.data) {
		return nil, fmt.Errorf("range $%04X+%d outside ROM", addr, n)
	}
	return r.data[off : off+n], nil
}
