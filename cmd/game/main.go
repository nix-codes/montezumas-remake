// Command game is the Montezuma's Revenge remake. For now it is a sandbox:
// a hand-built test room drawn with the ROM's tiles, with Panama Joe
// walking, falling and climbing. Movement is placeholder, not yet matched
// to the original.
package main

import (
	"flag"
	"image"
	"image/png"
	"log"
	"os"

	"github.com/hajimehoshi/ebiten/v2"

	"montezuma-remake/internal/gfx"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/vdp"
)

const (
	screenW, screenH = 256, 192 // TMS9918A resolution
	cols, rows       = screenW / 8, screenH / 8
	windowScale      = 3
)

// Tile numbers in the boot tileset (see assets/tiles.png, row*16+col).
const (
	tileEmpty       = 0x00
	tileFloor       = 0x11 // gold bricks
	tileLadderFloor = 0x10 // ladder through gold bricks
	tileLadder      = 0x88
	tileWall        = 0xB0
)

// Sprite numbers (see assets/sprites.png, row*8+col).
var (
	walkFrames  = []int{13, 19, 27, 19} // facing right; mirrored for left
	climbFrames = []int{21, 25}
)

type game struct {
	tiles   [256]*ebiten.Image
	sprites [64]*ebiten.Image
	room    [rows][cols]byte
	joe     player

	frame      int
	screenshot string // if set, save frame screenshotFrame here and quit
}

const screenshotFrame = 30

type player struct {
	x, y      int // top-left of the 16x16 sprite
	left      bool
	climbing  bool
	animTick  int
	animFrame int
}

func main() {
	romPath := flag.String("rom", "build/montezuma.rom", "assembled ROM")
	screenshot := flag.String("screenshot", "", "save a PNG of an early frame to this path and exit")
	flag.Parse()

	r, err := rom.Load(*romPath)
	if err != nil {
		log.Fatal(err)
	}
	v, err := gfx.Boot(r)
	if err != nil {
		log.Fatal(err)
	}

	g := &game{joe: player{x: 40, y: 23*8 - 16}, screenshot: *screenshot}
	g.loadImages(v)
	g.buildTestRoom()

	ebiten.SetWindowSize(screenW*windowScale, screenH*windowScale)
	ebiten.SetWindowTitle("Montezuma's Revenge")
	if err := ebiten.RunGame(g); err != nil {
		log.Fatal(err)
	}
}

func (g *game) loadImages(v *vdp.VRAM) {
	for n := range g.tiles {
		img := image.NewRGBA(image.Rect(0, 0, 8, 8))
		v.DrawTile(img, n, 0, 0, gfx.Backdrop)
		g.tiles[n] = ebiten.NewImageFromImage(img)
	}
	for s := range g.sprites {
		img := image.NewRGBA(image.Rect(0, 0, 16, 16))
		// Sprite colours are set at run time by code not yet traced; use white.
		v.DrawSprite16(img, s*4, 0, 0, vdp.Palette[15])
		g.sprites[s] = ebiten.NewImageFromImage(img)
	}
}

// buildTestRoom lays out a floor, walls, a platform and a ladder between them.
func (g *game) buildTestRoom() {
	for y := 0; y < rows; y++ {
		g.room[y][0], g.room[y][cols-1] = tileWall, tileWall
	}
	for x := 1; x < cols-1; x++ {
		g.room[rows-1][x] = tileFloor
	}
	for x := 4; x <= 20; x++ {
		g.room[14][x] = tileFloor
	}
	g.room[14][16] = tileLadderFloor
	for y := 15; y < rows-1; y++ {
		g.room[y][16] = tileLadder
	}
}

func (g *game) tileAt(px, py int) byte {
	x, y := px/8, py/8
	if x < 0 || x >= cols || y < 0 || y >= rows {
		return tileWall
	}
	return g.room[y][x]
}

func solid(t byte) bool {
	return t == tileFloor || t == tileLadderFloor || t == tileWall
}

func ladder(t byte) bool {
	return t == tileLadder || t == tileLadderFloor
}

func (g *game) Update() error {
	g.frame++
	if g.screenshot != "" && g.frame > screenshotFrame {
		return ebiten.Termination
	}
	j := &g.joe
	left := ebiten.IsKeyPressed(ebiten.KeyArrowLeft)
	right := ebiten.IsKeyPressed(ebiten.KeyArrowRight)
	up := ebiten.IsKeyPressed(ebiten.KeyArrowUp)
	down := ebiten.IsKeyPressed(ebiten.KeyArrowDown)

	cx := j.x + 8
	standing := solid(g.tileAt(j.x+4, j.y+16)) || solid(g.tileAt(j.x+11, j.y+16))
	moved := false

	// Start or continue climbing when on a ladder column.
	if (up && ladder(g.tileAt(cx, j.y+15))) || (down && ladder(g.tileAt(cx, j.y+16))) {
		j.climbing = true
		j.x = cx/8*8 - 4 // centre on the ladder
	}
	if j.climbing {
		switch {
		case up && ladder(g.tileAt(j.x+8, j.y+15)):
			j.y--
			moved = true
		case down && ladder(g.tileAt(j.x+8, j.y+16)):
			j.y++
			moved = true
		}
		// Leave the ladder once it no longer runs behind or under Joe.
		if !ladder(g.tileAt(j.x+8, j.y+15)) && !ladder(g.tileAt(j.x+8, j.y+16)) {
			j.climbing = false
		}
		// Step off sideways at the top or bottom.
		if (left || right) && standing && !ladder(g.tileAt(j.x+8, j.y+8)) {
			j.climbing = false
		}
	}

	if !j.climbing {
		switch {
		case left && !solid(g.tileAt(j.x+3, j.y+8)):
			j.x--
			j.left, moved = true, true
		case right && !solid(g.tileAt(j.x+12, j.y+8)):
			j.x++
			j.left, moved = false, true
		}
		if !standing {
			j.y += 2
			for solid(g.tileAt(j.x+4, j.y+15)) || solid(g.tileAt(j.x+11, j.y+15)) {
				j.y-- // landed inside the floor; back out
			}
		}
	}

	if moved {
		j.animTick++
		if j.animTick%6 == 0 {
			j.animFrame++
		}
	}
	return nil
}

func (g *game) Draw(screen *ebiten.Image) {
	for y := range g.room {
		for x, t := range g.room[y] {
			op := &ebiten.DrawImageOptions{}
			op.GeoM.Translate(float64(x*8), float64(y*8))
			screen.DrawImage(g.tiles[t], op)
		}
	}

	j := &g.joe
	frames := walkFrames
	if j.climbing {
		frames = climbFrames
	}
	op := &ebiten.DrawImageOptions{}
	if j.left && !j.climbing {
		op.GeoM.Scale(-1, 1)
		op.GeoM.Translate(16, 0)
	}
	op.GeoM.Translate(float64(j.x), float64(j.y))
	screen.DrawImage(g.sprites[frames[j.animFrame%len(frames)]], op)

	if g.screenshot != "" && g.frame == screenshotFrame {
		if err := saveScreenshot(screen, g.screenshot); err != nil {
			log.Fatal(err)
		}
	}
}

func saveScreenshot(screen *ebiten.Image, path string) error {
	img := image.NewRGBA(screen.Bounds())
	screen.ReadPixels(img.Pix)
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return png.Encode(f, img)
}

func (g *game) Layout(int, int) (int, int) {
	return screenW, screenH
}
