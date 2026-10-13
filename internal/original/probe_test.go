package original

import (
	"fmt"
	"image"
	"image/png"
	"os"
	"testing"

	"montezuma-remake/internal/coleco"
)

func TestProbeBottom(t *testing.T) {
	g := start(t)
	g.Poke(0x71B2, 0x53) // torch, to see
	g.LoadRoom(90)
	g.SetRoomColours(true)
	g.PlaceJoe(124, 120)
	last := ""
	shot := func(name string) {
		img := image.NewRGBA(image.Rect(0, 0, 256, 192))
		g.VDP.Render(img)
		f, _ := os.Create("../../build/tmp/bottom-" + name + ".png")
		png.Encode(f, img)
		f.Close()
	}
	for f := 0; f < 900; f++ {
		g.Step(coleco.Joystick{})
		j := g.Joe()
		k := fmt.Sprintf("room=%d row=%d col=%d 705F=%02X st=%d level=%d inv=% X", g.Room(), g.Peek(0x71A7), g.Peek(0x71A8), g.Peek(0x705F), j.State, g.Peek(0x71A6), g.Bytes(0x71B2, 3))
		if k != last {
			t.Logf("f%d x=%d y=%d 70AC=%d %s", f, j.X, j.Y, g.Peek(0x70AC), k)
			last = k
			shot(fmt.Sprintf("%03d", f))
		}
	}
	shot("end")
}
