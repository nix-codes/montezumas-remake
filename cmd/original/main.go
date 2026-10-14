// Command original runs the original cartridge on the emulator in
// internal/coleco, as a reference for the remake.
//
// Keys: arrows = joystick, Z = left fire, X = right fire, 0-9 = keypad.
//
// With -headless it runs without a window: -script presses inputs on given
// frames and -screenshot saves the last frame.
package main

import (
	"flag"
	"fmt"
	"image"
	"image/png"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/audio"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/sound"
)

const windowScale = 3

func main() {
	romPath := flag.String("rom", "build/montezuma.rom", "assembled ROM")
	headless := flag.Bool("headless", false, "run without a window")
	frames := flag.Int("frames", 300, "frames to run in headless mode")
	script := flag.String("script", "", `headless inputs, e.g. "100-110:key1,200-260:right"`)
	screenshot := flag.String("screenshot", "", "headless: save the last frame as PNG")
	flag.Parse()

	if _, err := rom.Load(*romPath); err != nil {
		log.Fatal(err)
	}
	cart, err := os.ReadFile(*romPath)
	if err != nil {
		log.Fatal(err)
	}
	m := coleco.New(cart)

	if *headless {
		steps, err := parseScript(*script)
		if err != nil {
			log.Fatal(err)
		}
		if err := runHeadless(m, *frames, steps, *screenshot); err != nil {
			log.Fatal(err)
		}
		return
	}

	if err := playSound(m.PSG); err != nil {
		log.Fatal(err)
	}
	ebiten.SetWindowSize(256*windowScale, 192*windowScale)
	ebiten.SetWindowTitle("Montezuma's Revenge (original ROM)")
	if err := ebiten.RunGame(&viewer{m: m, screen: image.NewRGBA(image.Rect(0, 0, 256, 192))}); err != nil {
		log.Fatal(err)
	}
}

type viewer struct {
	m      *coleco.Machine
	screen *image.RGBA
}

var keypadKeys = []ebiten.Key{
	ebiten.Key0, ebiten.Key1, ebiten.Key2, ebiten.Key3, ebiten.Key4,
	ebiten.Key5, ebiten.Key6, ebiten.Key7, ebiten.Key8, ebiten.Key9,
}

func (v *viewer) Update() error {
	in := coleco.Joystick{
		Up:        ebiten.IsKeyPressed(ebiten.KeyArrowUp),
		Down:      ebiten.IsKeyPressed(ebiten.KeyArrowDown),
		Left:      ebiten.IsKeyPressed(ebiten.KeyArrowLeft),
		Right:     ebiten.IsKeyPressed(ebiten.KeyArrowRight),
		FireLeft:  ebiten.IsKeyPressed(ebiten.KeyZ),
		FireRight: ebiten.IsKeyPressed(ebiten.KeyX),
		Key:       -1,
	}
	for n, k := range keypadKeys {
		if ebiten.IsKeyPressed(k) {
			in.Key = n
		}
	}
	v.m.Input = in
	return v.m.RunFrame()
}

func (v *viewer) Draw(screen *ebiten.Image) {
	v.m.VDP.Render(v.screen)
	screen.WritePixels(v.screen.Pix)
}

func (v *viewer) Layout(int, int) (int, int) { return 256, 192 }

// step holds an input from frame from to frame to, inclusive.
type step struct {
	from, to int
	input    string
}

func parseScript(s string) ([]step, error) {
	var steps []step
	for _, part := range strings.Split(s, ",") {
		if part = strings.TrimSpace(part); part == "" {
			continue
		}
		frames, input, ok := strings.Cut(part, ":")
		if !ok {
			return nil, fmt.Errorf("script step %q: want frames:input", part)
		}
		from, to, isRange := strings.Cut(frames, "-")
		if !isRange {
			to = from
		}
		a, err1 := strconv.Atoi(from)
		b, err2 := strconv.Atoi(to)
		if err1 != nil || err2 != nil {
			return nil, fmt.Errorf("script step %q: bad frame numbers", part)
		}
		steps = append(steps, step{a, b, input})
	}
	return steps, nil
}

func applyInput(in *coleco.Joystick, name string) error {
	switch name {
	case "up":
		in.Up = true
	case "down":
		in.Down = true
	case "left":
		in.Left = true
	case "right":
		in.Right = true
	case "fire", "fireleft":
		in.FireLeft = true
	case "fireright":
		in.FireRight = true
	default:
		k, ok := strings.CutPrefix(name, "key")
		n, err := strconv.Atoi(k)
		if !ok || err != nil || n < 0 || n > 9 {
			return fmt.Errorf("unknown input %q", name)
		}
		in.Key = n
	}
	return nil
}

func runHeadless(m *coleco.Machine, frames int, steps []step, screenshot string) error {
	for f := 0; f < frames; f++ {
		in := coleco.Joystick{Key: -1}
		for _, s := range steps {
			if f >= s.from && f <= s.to {
				if err := applyInput(&in, s.input); err != nil {
					return err
				}
			}
		}
		m.Input = in
		if err := m.RunFrame(); err != nil {
			return err
		}
	}
	if screenshot == "" {
		return nil
	}
	img := image.NewRGBA(image.Rect(0, 0, 256, 192))
	m.VDP.Render(img)
	f, err := os.Create(screenshot)
	if err != nil {
		return err
	}
	defer f.Close()
	return png.Encode(f, img)
}

// sampleRate is the audio output rate.
const sampleRate = 48000

// playSound plays the sound chip's output until the program ends.
func playSound(psg *sound.PSG) error {
	p, err := audio.NewContext(sampleRate).NewPlayer(sound.Stream{PSG: psg, Rate: sampleRate})
	if err != nil {
		return err
	}
	p.SetBufferSize(50 * time.Millisecond)
	p.Play()
	return nil
}
