// Package coleco emulates enough of a ColecoVision to run the original game:
// a Z80, 1 KB of RAM, the cartridge, the video and sound chips, and Go
// stand-ins for the BIOS routines the game calls (the BIOS ROM itself is
// not included).
package coleco

import (
	"fmt"

	"github.com/koron-go/z80"

	"montezuma-remake/internal/sound"
)

// Memory map.
const (
	biosEnd  = 0x2000
	ramStart = 0x6000 // 1 KB of RAM, mirrored up to $7FFF
	ramEnd   = 0x8000
	cartBase = 0x8000
)

// The Z80 runs at 3.58 MHz, about 59,700 cycles per 60 Hz frame. The CPU
// core doesn't count cycles, so frames are paced by instruction count,
// assuming an average of about 9 cycles per instruction.
var instructionsPerFrame = 6600

// Joystick holds the controller state for one frame.
type Joystick struct {
	Up, Down, Left, Right bool
	FireLeft, FireRight   bool
	Key                   int // keypad key 0-9, or -1 for none
}

// Machine is a ColecoVision with a cartridge inserted.
type Machine struct {
	CPU  z80.CPU
	VDP  VDP
	PSG  *sound.PSG
	RAM  [0x400]byte
	cart []byte
	bios [biosEnd]byte

	Input  Joystick
	Frames int

	// Trap, if set, is called before each instruction; returning true
	// stops the current frame early.
	Trap func(pc uint16) bool
	// OnRead, if set, is called for every memory read, including
	// instruction fetches.
	OnRead func(addr uint16)
	// OnWrite, if set, is called for every memory write.
	OnWrite func(addr uint16, v byte)

	returned bool // set when the CPU reaches callReturn
}

// callReturn is an unused BIOS address that Call uses as a return address.
const callReturn = 0x1000

// New returns a machine that will start the cartridge at its entry point,
// as the BIOS does after its title screen.
func New(cart []byte) *Machine {
	m := &Machine{cart: cart, PSG: sound.NewPSG(), Input: Joystick{Key: -1}}
	m.CPU.Memory = (*memory)(m)
	m.CPU.IO = (*ports)(m)
	m.VDP.nmi = func() { m.CPU.Interrupt = z80.NMIInterrupt() }

	// The BIOS sends NMI and RST n through jumps into the cartridge header.
	jp := func(at, to uint16) {
		m.bios[at], m.bios[at+1], m.bios[at+2] = 0xC3, byte(to), byte(to>>8)
	}
	jp(0x0066, 0x8021)
	for n := uint16(1); n <= 7; n++ {
		jp(n*8, 0x800C+(n-1)*3)
	}

	m.CPU.SP = 0x73B9
	m.CPU.PC = m.word(0x800A)
	return m
}

func (m *Machine) word(addr uint16) uint16 {
	return uint16(m.read(addr)) | uint16(m.read(addr+1))<<8
}

// RunFrame runs the CPU for one frame, then signals the end of the frame
// to the video chip, which raises the NMI the game runs on.
func (m *Machine) RunFrame() error {
	for i := 0; i < instructionsPerFrame; i++ {
		pc := m.CPU.PC
		if m.Trap != nil && m.Trap(pc) {
			break
		}
		if pc == callReturn && m.CPU.Interrupt == nil {
			m.returned = true
			break
		}
		if pc < biosEnd && m.CPU.Interrupt == nil {
			if call, ok := biosCalls[pc]; ok {
				call(m)
				m.ret()
				continue
			}
			if !m.inBIOSStub(pc) {
				return fmt.Errorf("frame %d: unhandled BIOS call $%04X", m.Frames, pc)
			}
		}
		m.CPU.Step()
	}
	m.VDP.EndFrame()
	m.PSG.EndFrame()
	m.Frames++
	return nil
}

// Call runs the game subroutine at addr until it returns, letting frames
// (and the game's NMI handler) run meanwhile. It fails if the routine hasn't
// returned after maxFrames frames.
func (m *Machine) Call(addr uint16, maxFrames int) error {
	pc := m.CPU.PC
	m.CPU.SP -= 2
	m.Poke(m.CPU.SP, callReturn&0xFF)
	m.Poke(m.CPU.SP+1, callReturn>>8)
	m.CPU.PC = addr
	m.returned = false
	for f := 0; f < maxFrames; f++ {
		if err := m.RunFrame(); err != nil {
			return err
		}
		if m.returned {
			m.CPU.PC = pc
			return nil
		}
	}
	return fmt.Errorf("call $%04X didn't return within %d frames", addr, maxFrames)
}

// inBIOSStub reports whether pc is inside one of the jumps set up in New.
func (m *Machine) inBIOSStub(pc uint16) bool {
	return m.bios[pc] == 0xC3 || (pc > 0 && m.bios[pc-1] == 0xC3) || (pc > 1 && m.bios[pc-2] == 0xC3)
}

// ret returns from a BIOS stand-in to its caller.
func (m *Machine) ret() {
	m.CPU.PC = m.word(m.CPU.SP)
	m.CPU.SP += 2
}

// Peek reads memory without side effects.
func (m *Machine) Peek(addr uint16) byte { return m.read(addr) }

// Poke writes RAM.
func (m *Machine) Poke(addr uint16, b byte) { (*memory)(m).Set(addr, b) }

type memory Machine

func (mem *memory) Get(addr uint16) uint8 {
	if mem.OnRead != nil {
		mem.OnRead(addr)
	}
	return (*Machine)(mem).read(addr)
}

func (m *Machine) read(addr uint16) uint8 {
	switch {
	case addr < biosEnd:
		return m.bios[addr]
	case addr >= ramStart && addr < ramEnd:
		return m.RAM[addr&0x3FF]
	case addr >= cartBase && int(addr-cartBase) < len(m.cart):
		return m.cart[addr-cartBase]
	}
	return 0xFF
}

func (mem *memory) Set(addr uint16, v uint8) {
	if mem.OnWrite != nil {
		mem.OnWrite(addr, v)
	}
	if addr >= ramStart && addr < ramEnd {
		mem.RAM[addr&0x3FF] = v
	}
}

type ports Machine

func (p *ports) In(port uint8) uint8 {
	switch port & 0xE0 {
	case 0xA0:
		if port&1 == 0 {
			return p.VDP.ReadData()
		}
		return p.VDP.ReadStatus()
	case 0xE0:
		return 0xFF // controllers, read through the CONTROLLER_SCAN stand-in
	}
	return 0xFF
}

func (p *ports) Out(port uint8, v uint8) {
	switch port & 0xE0 {
	case 0xA0:
		if port&1 == 0 {
			p.VDP.WriteData(v)
		} else {
			p.VDP.WriteControl(v)
		}
	case 0xE0:
		p.PSG.Out(v)
	}
}
