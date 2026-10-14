package sound

import "montezuma-remake/internal/rom"

// The sound effects, by what starts them. A lower number takes over from
// a higher one that's playing.
const (
	ExtraLife = 0 // score passed a multiple of 10,000 ($AFC4)
	Below     = 1 // left the bottom row downwards ($8E16)
	Pickup    = 2 // an item went into the inventory ($9025)
	SwordKill = 3 // the sword killed an enemy ($9275)
	Land      = 4 // landed from a fall or jump ($8AB0)
	Death     = 5 // burnt, zapped or caught ($8A93, $8DAB)
	Pole      = 6 // caught a pole ($8B66)
	Jump      = 7 // jumped ($89DE)
	Door      = 8 // opened a door ($8FC2)
	Walk      = 9 // footsteps: Joe is walking ($92F2)
)

// Effects is the original's sound data: a table of 10 pointers ($AD0B)
// and the effects they point to, which run to $ADFF.
type Effects struct {
	data []byte // from tableAddr
}

const (
	tableAddr = 0xAD0B
	dataEnd   = 0xAE00
)

// EffectsFromROM reads the sound data from the cartridge.
func EffectsFromROM(r *rom.ROM) (*Effects, error) {
	b, err := r.Slice(tableAddr, dataEnd-tableAddr)
	if err != nil {
		return nil, err
	}
	return &Effects{data: b}, nil
}

// at reads the byte at a CPU address, or 0 outside the sound data.
func (e *Effects) at(addr uint16) byte {
	if i := int(addr) - tableAddr; i >= 0 && i < len(e.data) {
		return e.data[i]
	}
	return 0
}

// Player plays one effect at a time, named after the game's variables.
// An effect starts with a header: the frames per step, then a control
// byte (bits 0-1: how many tone channels it uses; bit 2: white noise).
// Its first step sets the volumes, two channels to a byte, and the noise;
// every step then gives each tone channel a period, a byte each (the
// period over 4), starting with channel 2. A zero ends the effect.
type Player struct {
	Effects *Effects

	Active   bool   // $702C bit 7
	Starting bool   // bit 5: the next step sets the volumes
	ID       byte   // $702D
	Pointer  uint16 // $702E
	Duration byte   // $7030: frames per step
	Channels byte   // $7031
	Frame    byte   // $7032
	Channel  byte   // $7033: channels set this step
	Control  byte   // $7035
}

// Play starts effect id ($AC1A), unless one with a lower number is
// playing. The same effect starts over, except Below and Walk.
func (p *Player) Play(id byte) {
	if p.Active && (id > p.ID || id == p.ID && (id == Below || id == Walk)) {
		return
	}
	p.ID = id
	p.Active, p.Starting = true, true
	at := tableAddr + 2*uint16(id)
	ptr := uint16(p.Effects.at(at)) | uint16(p.Effects.at(at+1))<<8
	p.Duration = p.Effects.at(ptr)
	p.Frame = p.Duration - 1
	p.Control = p.Effects.at(ptr + 1)
	p.Channels = p.Control & 3
	p.Pointer = ptr + 2
	p.Channel = 0
}

// Tick runs the player for a frame ($AC6D), writing to c: every Duration
// frames it takes the next step of the effect.
func (p *Player) Tick(c Chip) {
	if !p.Active {
		return
	}
	if p.Frame++; p.Frame != p.Duration {
		return
	}
	p.Frame = 0
	if p.Starting {
		p.Starting = false
		b := p.Effects.at(p.Pointer)
		c.Out(0xD0 | b&0x0F) // channel 2
		c.Out(0xF0 | b>>4)   // noise
		b = p.Effects.at(p.Pointer + 1)
		c.Out(0x90 | b&0x0F) // channel 0
		c.Out(0xB0 | b>>4)   // channel 1
		p.Pointer += 2
		c.Out(0xE3 | p.Control)
	}
	for ; p.Channel != p.Channels; p.Pointer++ {
		p.Channel++
		b := p.Effects.at(p.Pointer)
		if b == 0 {
			p.stop(c)
			return
		}
		// Channels 2, 1, 0: latch the low bits, then the high ones.
		reg := (p.Channel ^ 7) << 5 & 0xE0
		c.Out(reg | (b&3)<<2)
		c.Out(b >> 2)
	}
	p.Channel = 0
}

func (p *Player) stop(c Chip) {
	p.Active = false
	TurnOff(c)
}
