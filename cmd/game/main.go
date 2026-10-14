// Command game is the Montezuma's Revenge remake: it shows internal/play's
// game in a window and feeds it the keyboard.
//
// Keys: arrows move and climb; space, Z or X jump. PageUp/PageDown jump to
// the previous or next room, for testing.
package main

import (
	"flag"
	"fmt"
	"image"
	"image/png"
	"log"
	"os"
	"path/filepath"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/play"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
	"montezuma-remake/internal/vdp"
)

const (
	screenW, screenH = 256, 192 // TMS9918A resolution
	windowScale      = 3
	screenshotFrame  = 30
)

type window struct {
	g *play.Game

	gfx        map[int]*roomGfx
	background *ebiten.Image
	pixels     *image.RGBA
	drawn      [24][32]byte // the screen the background shows
	drawnRoom  int
	drawnCols  [32]byte
	drawnPats  [256 * 8]byte
	title      string

	frame      int
	screenshot string // if set, save frame screenshotFrame here and quit
}

// roomGfx is a room's tile set and sprite images.
type roomGfx struct {
	vram    vdp.VRAM
	sprites [64]*ebiten.Image // indexed by pattern/4, white; tinted when drawn
}

func main() {
	romPath := flag.String("rom", "build/montezuma.rom", "assembled ROM")
	roomsDir := flag.String("rooms", "assets/rooms", "directory of per-level rooms.json from cmd/rooms")
	startRoom := flag.Int("room", pyramid.Start, "room to start in")
	screenshot := flag.String("screenshot", "", "save a PNG of an early frame to this path and exit")
	flag.Parse()

	r, err := rom.Load(*romPath)
	if err != nil {
		log.Fatal(err)
	}
	rules, err := play.RulesFromROM(r)
	if err != nil {
		log.Fatal(err)
	}
	// Rooms for each level; levels past 3 use level 3's (the original's
	// rooms differ between levels only in a few details).
	levels := map[int][]roomdata.Room{}
	levelRooms := func(level int) []roomdata.Room {
		level = min(level, 3)
		if levels[level] == nil {
			rooms, err := roomdata.Load(filepath.Join(*roomsDir, fmt.Sprintf("level%d", level), "rooms.json"))
			if err != nil {
				log.Fatal(err)
			}
			levels[level] = rooms
		}
		return levels[level]
	}
	rooms := levelRooms(1)
	if *startRoom < 0 || *startRoom >= len(rooms) {
		log.Fatalf("no room %d", *startRoom)
	}

	g := play.New(rooms, rules, 1, *startRoom)
	g.LevelRooms = levelRooms
	w := &window{
		g:          g,
		gfx:        map[int]*roomGfx{},
		background: ebiten.NewImage(screenW, screenH),
		pixels:     image.NewRGBA(image.Rect(0, 0, screenW, screenH)),
		drawnRoom:  -1,
		screenshot: *screenshot,
	}
	ebiten.SetWindowSize(screenW*windowScale, screenH*windowScale)
	if err := ebiten.RunGame(w); err != nil {
		log.Fatal(err)
	}
}

// roomGfx loads a room's graphics the first time it's shown.
func (w *window) roomGfx(n int) *roomGfx {
	if rg, ok := w.gfx[n]; ok {
		return rg
	}
	r := &w.g.Rooms[n]
	rg := &roomGfx{}
	copy(rg.vram.TilePatterns[:], r.TilePatterns)
	copy(rg.vram.Colours[:], r.TileColours)
	copy(rg.vram.SpritePatterns[:], r.SpritePatterns)
	for s := range rg.sprites {
		img := image.NewRGBA(image.Rect(0, 0, 16, 16))
		rg.vram.DrawSprite16(img, s*4, 0, 0, vdp.Palette[15])
		rg.sprites[s] = ebiten.NewImageFromImage(img)
	}
	w.gfx[n] = rg
	return rg
}

func (w *window) Update() error {
	w.frame++
	if w.screenshot != "" && w.frame > screenshotFrame {
		return ebiten.Termination
	}
	g := w.g
	switch {
	case inpututil.IsKeyJustPressed(ebiten.KeyPageDown):
		w.teleport((g.Room + 1) % len(g.Rooms))
	case inpututil.IsKeyJustPressed(ebiten.KeyPageUp):
		w.teleport((g.Room + len(g.Rooms) - 1) % len(g.Rooms))
	}
	g.Step(joe.Input{
		Left:  ebiten.IsKeyPressed(ebiten.KeyArrowLeft),
		Right: ebiten.IsKeyPressed(ebiten.KeyArrowRight),
		Up:    ebiten.IsKeyPressed(ebiten.KeyArrowUp),
		Down:  ebiten.IsKeyPressed(ebiten.KeyArrowDown),
		Fire: ebiten.IsKeyPressed(ebiten.KeySpace) || ebiten.IsKeyPressed(ebiten.KeyZ) ||
			ebiten.IsKeyPressed(ebiten.KeyX),
	})
	if t := fmt.Sprintf("Montezuma's Revenge - level %d - room %d (row %d, column %d) - lives %d - score %d",
		g.Level, g.Room, g.Row, g.Col, g.Lives, g.Score); t != w.title {
		ebiten.SetWindowTitle(t)
		w.title = t
	}
	return nil
}

// teleport moves to room for testing, with Joe standing where he was.
func (w *window) teleport(room int) {
	x, y := w.g.Joe.X, w.g.Joe.ScreenY()
	w.g.Joe.Place(int(x), y)
	w.g.Enter(room)
}

func (w *window) Draw(screen *ebiten.Image) {
	g := w.g
	rg := w.roomGfx(g.Room)
	s, c, p := g.Display(), g.Colours(), g.Patterns()
	if s != w.drawn || g.Room != w.drawnRoom || c != w.drawnCols || p != w.drawnPats {
		backdrop := g.Backdrop()
		rg.vram.Colours, rg.vram.TilePatterns = c, p
		for y := range s {
			for x, t := range s[y] {
				rg.vram.DrawTile(w.pixels, int(t), x*8, y*8, backdrop)
			}
		}
		w.background.WritePixels(w.pixels.Pix)
		w.drawn, w.drawnRoom, w.drawnCols, w.drawnPats = s, g.Room, c, p
	}
	screen.DrawImage(w.background, nil)

	// Enemies and other sprites (entries 2-7 of the sprite table); lower
	// entries have priority, so they're drawn last.
	for i := len(g.Enemies.Sprites) - 1; i >= 2; i-- {
		s := g.Enemies.Sprites[i]
		if s.Colour == 0 || s.Y == 0xD0 {
			continue
		}
		drawSprite(screen, rg.sprites[s.Pattern/4], int(s.X), int(s.Y)+1, s.Colour)
	}

	// Joe: his hat and legs, then his body on top.
	body, legs, legsDY := g.Joe.Sprites()
	x, y := int(g.Joe.X), g.Joe.ScreenY()
	if legs < 0 {
		drawSprite(screen, rg.sprites[body], x, y, joe.GhostColour)
	} else {
		drawSprite(screen, rg.sprites[legs], x, y+legsDY, joe.LegsColour)
		drawSprite(screen, rg.sprites[body], x, y, joe.BodyColour)
	}

	if w.screenshot != "" && w.frame == screenshotFrame {
		if err := saveScreenshot(screen, w.screenshot); err != nil {
			log.Fatal(err)
		}
	}
}

func drawSprite(screen, img *ebiten.Image, x, y int, colour byte) {
	if y > screenH {
		y -= 256 // partly off the top, as the video chip wraps
	}
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(x), float64(y))
	c := vdp.Palette[colour]
	op.ColorScale.Scale(float32(c.R)/255, float32(c.G)/255, float32(c.B)/255, 1)
	screen.DrawImage(img, op)
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

func (w *window) Layout(int, int) (int, int) {
	return screenW, screenH
}
