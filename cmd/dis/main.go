// Command dis disassembles a range of the assembled ROM, for reading the
// parts of the disassembly that were left as raw DB bytes.
package main

import (
	"flag"
	"fmt"
	"log"
	"strconv"

	"github.com/remogatto/z80"

	"montezuma-remake/internal/rom"
)

type reader struct{ r *rom.ROM }

func (m reader) ReadByte(addr uint16) byte {
	b, err := m.r.Slice(addr, 1)
	if err != nil {
		return 0xFF
	}
	return b[0]
}

func main() {
	romPath := flag.String("rom", "build/montezuma.rom", "assembled ROM")
	from := flag.String("from", "8000", "start address (hex)")
	to := flag.String("to", "", "end address (hex, exclusive); default from+$40")
	flag.Parse()

	start, err := strconv.ParseUint(*from, 16, 16)
	if err != nil {
		log.Fatal(err)
	}
	end := start + 0x40
	if *to != "" {
		if end, err = strconv.ParseUint(*to, 16, 16); err != nil {
			log.Fatal(err)
		}
	}
	r, err := rom.Load(*romPath)
	if err != nil {
		log.Fatal(err)
	}

	mem := reader{r}
	for addr := uint16(start); uint64(addr) < end; {
		var text string
		next, shift := addr, 0
		for {
			text, next, shift = z80.Disassemble(mem, next, shift)
			if shift == 0 {
				break
			}
		}
		var hex string
		for a := addr; a != next; a++ {
			hex += fmt.Sprintf("%02X ", mem.ReadByte(a))
		}
		fmt.Printf("%04X  %-12s %s\n", addr, hex, text)
		addr = next
	}
}
