// Command extract pulls graphics out of the assembled Montezuma's Revenge
// ROM by replaying the game's own VRAM loads into a model of the VDP.
package main

import (
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"log"
	"os"
	"path/filepath"
	"strings"

	"montezuma-remake/internal/gfx"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/vdp"
)

const (
	scale = 4
	gap   = 1
)

var background = color.RGBA{0x30, 0x30, 0x38, 0xFF}

func main() {
	romPath := flag.String("rom", "build/montezuma.rom", "assembled ROM")
	outDir := flag.String("out", "assets", "output directory")
	flag.Parse()

	r, err := rom.Load(*romPath)
	if err != nil {
		log.Fatal(err)
	}
	if err := os.MkdirAll(*outDir, 0o755); err != nil {
		log.Fatal(err)
	}

	v, err := gfx.Boot(r)
	if err != nil {
		log.Fatal(err)
	}

	write(filepath.Join(*outDir, "tiles.png"), tileSheet(v))
	write(filepath.Join(*outDir, "sprites.png"), spriteSheet(v))
	report := filepath.Join(*outDir, "loader-calls.txt")
	if err := os.WriteFile(report, []byte(describe(r.LoaderCalls())), 0o644); err != nil {
		log.Fatal(err)
	}
	fmt.Println("wrote", report)
}

// tileSheet lays out all 256 tiles in a 16x16 grid, tile n at row n/16.
func tileSheet(v *vdp.VRAM) image.Image {
	const cell = 8 + gap
	img := image.NewRGBA(image.Rect(0, 0, 16*cell+gap, 16*cell+gap))
	draw.Draw(img, img.Bounds(), &image.Uniform{background}, image.Point{}, draw.Src)
	for n := 0; n < 256; n++ {
		v.DrawTile(img, n, gap+(n%16)*cell, gap+(n/16)*cell, gfx.Backdrop)
	}
	return upscale(img)
}

// spriteSheet lays out the 64 16x16 sprites in an 8x8 grid, in white since
// sprite colours are set at run time.
func spriteSheet(v *vdp.VRAM) image.Image {
	const cell = 16 + gap
	img := image.NewRGBA(image.Rect(0, 0, 8*cell+gap, 8*cell+gap))
	draw.Draw(img, img.Bounds(), &image.Uniform{background}, image.Point{}, draw.Src)
	for s := 0; s < 64; s++ {
		v.DrawSprite16(img, s*4, gap+(s%8)*cell, gap+(s/8)*cell, vdp.Palette[15])
	}
	return upscale(img)
}

func upscale(src *image.RGBA) image.Image {
	b := src.Bounds()
	dst := image.NewRGBA(image.Rect(0, 0, b.Dx()*scale, b.Dy()*scale))
	for y := 0; y < dst.Bounds().Dy(); y++ {
		for x := 0; x < dst.Bounds().Dx(); x++ {
			dst.SetRGBA(x, y, src.RGBAAt(x/scale, y/scale))
		}
	}
	return dst
}

func write(path string, img image.Image) {
	f, err := os.Create(path)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	if err := png.Encode(f, img); err != nil {
		log.Fatal(err)
	}
	fmt.Println("wrote", path)
}

var tableNames = map[int]string{
	vdp.SpriteAttr:    "sprite attributes",
	vdp.SpritePattern: "sprite patterns",
	vdp.NameTable:     "name table",
	vdp.TilePattern:   "tile patterns",
	vdp.ColourTable:   "tile colours",
}

func describe(calls []rom.LoaderCall) string {
	var b strings.Builder
	for _, c := range calls {
		name := tableNames[c.Table]
		if name == "" {
			name = "unknown"
		}
		fmt.Fprintf(&b, "CALL SUB_AE00 at $%04X  table %d (%s)  %d records\n", c.Addr, c.Table, name, len(c.Records))
		for _, rec := range c.Records {
			fmt.Fprintf(&b, "    src $%04X -> index %3d, count %3d\n", rec.Src, rec.Index, rec.Count)
		}
	}
	return b.String()
}
