package sound

import (
	"encoding/binary"
	"math"
	"testing"

	"montezuma-remake/internal/rom"
)

const rate = 48000

// samples renders n samples of p's output.
func samples(p *PSG, n int) []int16 {
	buf := make([]byte, 4*n)
	if _, err := (Stream{p, rate}).Read(buf); err != nil {
		panic(err)
	}
	out := make([]int16, n)
	for i := range out {
		out[i] = int16(binary.LittleEndian.Uint16(buf[4*i:]))
	}
	return out
}

// TestTonePitch plays channel 1 at period 254 (440 Hz: the clock / 32 /
// 254) and counts the wave's upward crossings over a second.
func TestTonePitch(t *testing.T) {
	p := NewPSG()
	p.Out(0xA0 | 254&0x0F) // channel 1 period, low bits
	p.Out(254 >> 4)        // high bits
	p.Out(0xB0)            // channel 1 at full volume
	for range startFrames {
		p.EndFrame()
	}
	s := samples(p, rate)
	cycles := 0
	for i := 1; i < len(s); i++ {
		if s[i-1] < 0 && s[i] >= 0 {
			cycles++
		}
	}
	want := float64(Clock) / 32 / 254
	if math.Abs(float64(cycles)-want) > 2 {
		t.Errorf("%d cycles in a second, want %.0f", cycles, want)
	}
}

// TestEffects plays each effect to its end, which every one reaches,
// checking it makes a sound and leaves the chip silent.
func TestEffects(t *testing.T) {
	r, err := rom.Load("../../build/montezuma.rom")
	if err != nil {
		t.Skip(err)
	}
	e, err := EffectsFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	for id := byte(0); id < 10; id++ {
		var pl Player
		pl.Effects = e
		p := NewPSG()
		pl.Play(id)
		loudest, frames := 0.0, 0
		for ; frames < 600 && (pl.Active || frames < 2*startFrames); frames++ {
			pl.Tick(p)
			p.EndFrame()
			for _, s := range samples(p, rate/FrameRate) {
				loudest = max(loudest, math.Abs(float64(s)))
			}
		}
		if pl.Active {
			t.Errorf("effect %d still playing after %d frames", id, frames)
		}
		if loudest < 1000 {
			t.Errorf("effect %d: loudest sample %.0f", id, loudest)
		}
		if v := p.Registers().Volume; v != [4]byte{15, 15, 15, 15} {
			t.Errorf("effect %d left volumes %v", id, v)
		}
		t.Logf("effect %d: %d frames", id, frames)
	}
}

// TestFrameTiming turns channel 0 on and off on alternate frames while the
// output is read 50 ms at a time, as Ebitengine reads it, and checks each
// frame is heard in turn for 1/60 s (up to 5% less while catching up).
func TestFrameTiming(t *testing.T) {
	p := NewPSG()
	p.Out(0x80 | 8) // channel 0: period 8, 14 kHz
	p.Out(0)
	var heard []int16
	for f := range 120 {
		p.Out(0x90 | byte(f%2)*15) // on, off, on, ...
		p.EndFrame()
		if f%3 == 2 {
			heard = append(heard, samples(p, rate/20)...)
		}
	}
	// The tone swings sample to sample; the DC filter's slow tail after
	// it stops doesn't. Measure the stretches with and without it.
	// A sample is in the tone if it swung within the last 16.
	const window = 16
	var runs []int
	on, n, last := false, 0, -window
	for i := 1; i < len(heard); i++ {
		if math.Abs(float64(heard[i])-float64(heard[i-1])) > 2000 {
			last = i
		}
		if swing := i-last < window; swing != on {
			if n > 0 {
				runs = append(runs, n)
			}
			on, n = swing, 0
		}
		n++
	}
	perFrame := rate / FrameRate
	// Skip the silence before the first frame, and the filter settling.
	runs = runs[1:]
	for len(runs) > 0 && runs[0] < perFrame/2 {
		runs = runs[1:]
	}
	for i, n := range runs {
		if n < perFrame-perFrame/20-window || n > perFrame+window {
			t.Fatalf("stretch %d is %d samples, want about %d: %v", i, n, perFrame, runs)
		}
	}
	if len(runs) < 80 {
		t.Errorf("only %d frames heard", len(runs))
	}
}
