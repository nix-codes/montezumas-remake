package rom

import "bytes"

// The game loads graphics through LOADER, which takes its arguments
// inline after the CALL:
//
//	LD   A, table        ; BIOS PUT_VRAM table code
//	CALL LOADER
//	DW   src : DB index, count   ; repeated
//	DB   xx, $00                 ; terminator (src high byte = 0)
//
// Each record is passed to the BIOS PUT_VRAM routine.

// LoaderAddr is the address of LOADER.
const LoaderAddr = 0xAE00

// Record copies Count table items from Src into the table at Index.
type Record struct {
	Src   uint16
	Index int
	Count int
}

// LoaderCall is one CALL LOADER site and its inline records.
type LoaderCall struct {
	Addr    uint16 // address of the CALL instruction
	Table   int    // PUT_VRAM table code from the preceding LD A,n; -1 if none
	Records []Record
}

// LoaderCalls finds every CALL LOADER in the ROM and decodes its records.
func (r *ROM) LoaderCalls() []LoaderCall {
	call := []byte{0xCD, LoaderAddr & 0xFF, LoaderAddr >> 8}
	var calls []LoaderCall
	for i := 0; ; i += len(call) {
		n := bytes.Index(r.data[i:], call)
		if n < 0 {
			return calls
		}
		i += n
		c := LoaderCall{Addr: uint16(Base + i), Table: -1}
		if i >= 2 && r.data[i-2] == 0x3E { // LD A,n
			c.Table = int(r.data[i-1])
		}
		for p := i + len(call); p+3 < len(r.data) && r.data[p+1] != 0; p += 4 {
			c.Records = append(c.Records, Record{
				Src:   uint16(r.data[p]) | uint16(r.data[p+1])<<8,
				Index: int(r.data[p+2]),
				Count: int(r.data[p+3]),
			})
		}
		calls = append(calls, c)
	}
}

// LoaderCallAt returns the loader call at addr.
func (r *ROM) LoaderCallAt(addr uint16) (LoaderCall, bool) {
	for _, c := range r.LoaderCalls() {
		if c.Addr == addr {
			return c, true
		}
	}
	return LoaderCall{}, false
}
