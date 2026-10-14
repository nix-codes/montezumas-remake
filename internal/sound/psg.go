// Package sound is the ColecoVision's sound: its SN76489A chip, and the
// game's own sound-effect player, translated from the original ($AC1A,
// $AC6D).
package sound

import (
	"encoding/binary"
	"math"
	"sync"
)

// Clock is the chip's input clock; it steps its counters at a 16th of it.
const Clock = 3579545

// FrameRate is how often the game runs a frame, and so writes the chip.
const FrameRate = 60

// Chip is anything taking the bytes the game writes to the sound port.
type Chip interface {
	Out(b byte)
}

// TurnOff silences all four channels, as the BIOS's TURN_OFF_SOUND does.
func TurnOff(c Chip) {
	for _, b := range []byte{0x9F, 0xBF, 0xDF, 0xFF} {
		c.Out(b)
	}
}

// Registers is the chip's state as the game sets it.
type Registers struct {
	Period [3]uint16 // tone periods (10 bits), in units of 16 clocks
	Volume [4]byte   // attenuation in 2 dB steps (15 is off); [3] is noise
	Noise  byte      // bit 2: white noise; bits 0-1: rate (3 follows tone 2)
}

// PSG is an SN76489A. The game writes it a frame at a time, calling
// EndFrame after each; an audio player reads its output on another
// goroutine through Stream, which plays each frame's writes 1/60 s apart,
// a few frames behind, however the player batches its reads.
type PSG struct {
	mu     sync.Mutex
	game   chip     // as the game has written it
	writes []byte   // this frame's writes
	frames [][]byte // finished frames' writes, not yet heard
	heard  chip     // as the listener hears it

	frameLeft int  // samples left of the frame being heard
	buffering bool // waiting for frames to queue up
	phase     float64
	dcIn      float64 // DC blocker state
	dcOut     float64
}

// Frames of writes the output keeps queued: it starts playing once
// startFrames are waiting, plays frames 5% short while more than
// keepFrames are, so the sound doesn't lag, and skips ahead past
// maxFrames. (Ebitengine reads 3 frames' worth at a time.)
const (
	startFrames = 4
	keepFrames  = 3
	maxFrames   = 12
)

// NewPSG returns a chip with every channel off.
func NewPSG() *PSG {
	p := &PSG{buffering: true}
	p.game.reset()
	p.heard.reset()
	return p
}

// Out writes a byte to the chip's port.
func (p *PSG) Out(b byte) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.game.out(b)
	p.writes = append(p.writes, b)
}

// EndFrame marks the end of a frame's writes.
func (p *PSG) EndFrame() {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.frames = append(p.frames, p.writes)
	p.writes = nil
	for len(p.frames) > maxFrames {
		p.nextFrame()
	}
}

// nextFrame makes the next queued frame's writes heard.
func (p *PSG) nextFrame() {
	for _, b := range p.frames[0] {
		p.heard.out(b)
	}
	p.frames = p.frames[1:]
}

// Set writes r to the chip.
func (p *PSG) Set(r Registers) {
	for ch, v := range r.Volume {
		p.Out(0x90 | byte(ch)<<5 | v)
	}
	for ch, period := range r.Period {
		p.Out(0x80 | byte(ch)<<5 | byte(period&0x0F))
		p.Out(byte(period >> 4))
	}
	p.Out(0xE0 | r.Noise)
}

// Registers returns the chip's registers as the game has set them.
func (p *PSG) Registers() Registers {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.game.regs
}

// Stream reads a chip's output as 16-bit little-endian stereo samples at
// Rate Hz, without end, for an audio player.
type Stream struct {
	PSG  *PSG
	Rate int
}

func (s Stream) Read(buf []byte) (int, error) {
	n := len(buf) &^ 3
	s.PSG.generate(buf[:n], s.Rate)
	return n, nil
}

// generate fills buf with samples at rate Hz, each the average of the
// chip's output over its duration, with the DC taken out as the TV's
// audio input would.
func (p *PSG) generate(buf []byte, rate int) {
	p.mu.Lock()
	defer p.mu.Unlock()
	steps := float64(Clock) / 16 / float64(rate)
	for i := 0; i+4 <= len(buf); i += 4 {
		if p.frameLeft == 0 {
			if p.buffering && len(p.frames) >= startFrames {
				p.buffering = false
			}
			if !p.buffering && len(p.frames) == 0 {
				p.buffering = true // the game fell behind: hold the sound
			}
			if !p.buffering {
				p.nextFrame()
				p.frameLeft = rate / FrameRate
				if len(p.frames) > keepFrames {
					p.frameLeft -= p.frameLeft / 20
				}
			}
		}
		if p.frameLeft > 0 {
			p.frameLeft--
		}

		p.phase += steps
		n := int(p.phase)
		p.phase -= float64(n)
		var sum float64
		for range n {
			sum += p.heard.step()
		}
		if n > 0 {
			sum /= float64(n)
		}
		// A one-pole high-pass filter at about 20 Hz.
		out := sum - p.dcIn + 0.9974*p.dcOut
		p.dcIn, p.dcOut = sum, out
		s := uint16(int16(math.Max(-1, math.Min(1, out)) * 32767))
		binary.LittleEndian.PutUint16(buf[i:], s)
		binary.LittleEndian.PutUint16(buf[i+2:], s)
	}
}

// volume is each attenuation step's amplitude, 2 dB apart, scaled so the
// four channels together stay in range.
var volume = func() (v [16]float64) {
	for i := range 15 {
		v[i] = 0.25 * math.Pow(10, -float64(i)*2/20)
	}
	return v
}()

// chip is the SN76489A's registers and counters.
type chip struct {
	regs    Registers
	latched int // register the last latch byte chose (0-7)
	counter [4]int
	output  [4]bool
	lfsr    uint32
}

// The noise shift register, as MAME has the SN76489A: 17 bits, fed back
// from bits 2 and 3 for white noise, bit 0 for periodic noise. Its output
// is bit 0.
const (
	lfsrReset = 0x10000
	whiteTaps = 0x0C
)

func (c *chip) reset() {
	*c = chip{lfsr: lfsrReset}
	c.regs.Volume = [4]byte{15, 15, 15, 15}
}

// out writes a byte to the chip. A latch byte (bit 7 set) picks a
// register (bits 4-6) and sets its low 4 bits; a data byte sets a tone
// period's high 6 bits. Writing the noise register resets the noise.
func (c *chip) out(b byte) {
	r := &c.regs
	if b&0x80 != 0 {
		c.latched = int(b>>4) & 7
	}
	reg, data := c.latched, b&0x0F
	switch {
	case reg&1 == 1:
		r.Volume[reg/2] = data
	case reg == 6:
		r.Noise = b & 7
		c.lfsr = lfsrReset
	case b&0x80 != 0:
		r.Period[reg/2] = r.Period[reg/2]&0x3F0 | uint16(data)
	default:
		r.Period[reg/2] = r.Period[reg/2]&0x00F | uint16(b&0x3F)<<4
	}
}

// step advances the chip by one count (16 clocks) and returns its output:
// each channel gives its volume while high, nothing while low.
func (c *chip) step() float64 {
	r := &c.regs
	var out float64
	for ch := range 4 {
		var period int
		if ch < 3 {
			period = int(r.Period[ch])
		} else if rate := r.Noise & 3; rate == 3 {
			period = int(r.Period[2])
		} else {
			period = 0x10 << rate
		}
		if period == 0 {
			period = 0x400
		}
		if c.counter[ch]--; c.counter[ch] <= 0 {
			c.counter[ch] = period
			c.output[ch] = !c.output[ch]
			if ch == 3 && c.output[ch] {
				c.shiftNoise()
			}
		}
		v := volume[r.Volume[ch]]
		switch {
		case ch == 3:
			if c.lfsr&1 != 0 {
				out += v
			}
		case period < 8:
			// Above 14 kHz: inaudible, heard as its average. (The game
			// uses period 4 between notes.)
			out += v / 2
		case c.output[ch]:
			out += v
		}
	}
	return out
}

func (c *chip) shiftNoise() {
	fb := c.lfsr & 1
	if c.regs.Noise&4 != 0 {
		fb = 0
		if c.lfsr&whiteTaps == 0x04 || c.lfsr&whiteTaps == 0x08 {
			fb = 1
		}
	}
	c.lfsr >>= 1
	if fb != 0 {
		c.lfsr |= lfsrReset
	}
}
