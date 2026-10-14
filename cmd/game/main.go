// Command game is the Montezuma's Revenge remake: it shows internal/play's
// game in a window and feeds it the keyboard.
//
// It starts on the title screen, where 1, 2 or 3 picks the level. Keys:
// arrows move and climb; space, Z or X jump; Esc is the console's reset
// button, back to the title. PageUp/PageDown jump to the previous or next
// room, for testing, standing Joe somewhere safe.
package main

import (
	"flag"
	"fmt"
	"image"
	"image/png"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/audio"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"montezuma-remake/internal/gfx"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/play"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
	"montezuma-remake/internal/sound"
	"montezuma-remake/internal/vdp"
)

const (
	screenW, screenH = 256, 192 // TMS9918A resolution
	windowScale      = 3
	screenshotFrame  = 30
)

type window struct {
	g          *play.Game // nil on the title screen
	rules      *play.Rules
	levelRooms func(level int) []roomdata.Room
	titleVRAM  *vdp.VRAM
	psg        *sound.PSG // every game plays on the same chip

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
	startRoom := flag.Int("room", -1, "skip the title and start in this room")
	startLevel := flag.Int("level", 0, "skip the title and start this level")
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
	// Rooms for each level (the original's rooms differ between levels
	// only in a few details).
	levels := map[int][]roomdata.Room{}
	levelRooms := func(level int) []roomdata.Room {
		if levels[level] == nil {
			rooms, err := roomdata.Load(filepath.Join(*roomsDir, fmt.Sprintf("level%d", level), "rooms.json"))
			if err != nil {
				log.Fatal(err)
			}
			levels[level] = rooms
		}
		return levels[level]
	}
	title, err := gfx.Title(r)
	if err != nil {
		log.Fatal(err)
	}

	w := &window{
		rules:      rules,
		levelRooms: levelRooms,
		titleVRAM:  title,
		psg:        sound.NewPSG(),
		background: ebiten.NewImage(screenW, screenH),
		pixels:     image.NewRGBA(image.Rect(0, 0, screenW, screenH)),
		screenshot: *screenshot,
	}
	if *startRoom >= 0 || *startLevel > 0 {
		w.start(max(*startLevel, 1))
		if *startRoom >= len(w.g.Rooms) {
			log.Fatalf("no room %d", *startRoom)
		}
		if *startRoom >= 0 {
			w.g.Teleport(*startRoom)
		}
	}
	if *screenshot == "" {
		if err := playSound(w.psg); err != nil {
			log.Fatal(err)
		}
	}
	ebiten.SetWindowSize(screenW*windowScale, screenH*windowScale)
	if err := ebiten.RunGame(w); err != nil {
		log.Fatal(err)
	}
}

// start starts a game on level, as the title screen does.
func (w *window) start(level int) {
	g := play.New(w.levelRooms(level), w.rules, level, pyramid.Entrance)
	g.LevelRooms = w.levelRooms
	g.PSG = w.psg
	w.g = g
	w.gfx = map[int]*roomGfx{}
	w.drawnRoom = -1
}

// levelKeys pick the level on the title screen, on the keyboard's top row
// or its keypad.
var levelKeys = map[int][]ebiten.Key{
	1: {ebiten.Key1, ebiten.KeyNumpad1},
	2: {ebiten.Key2, ebiten.KeyNumpad2},
	3: {ebiten.Key3, ebiten.KeyNumpad3},
}

// updateTitle waits on the title screen for a level to be picked.
func (w *window) updateTitle() {
	defer w.psg.EndFrame()
	for level, keys := range levelKeys {
		for _, k := range keys {
			if ebiten.IsKeyPressed(k) {
				w.start(level)
				return
			}
		}
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
	if inpututil.IsKeyJustPressed(ebiten.KeyEscape) {
		w.g = nil
		sound.TurnOff(w.psg)
		w.drawnRoom = -1
	}
	if w.g == nil {
		w.setTitle("Montezuma's Revenge")
		w.updateTitle()
		return nil
	}
	g := w.g
	switch {
	case inpututil.IsKeyJustPressed(ebiten.KeyPageDown):
		g.Teleport((g.Room + 1) % len(g.Rooms))
	case inpututil.IsKeyJustPressed(ebiten.KeyPageUp):
		g.Teleport((g.Room + len(g.Rooms) - 1) % len(g.Rooms))
	}
	g.Step(joe.Input{
		Left:  ebiten.IsKeyPressed(ebiten.KeyArrowLeft),
		Right: ebiten.IsKeyPressed(ebiten.KeyArrowRight),
		Up:    ebiten.IsKeyPressed(ebiten.KeyArrowUp),
		Down:  ebiten.IsKeyPressed(ebiten.KeyArrowDown),
		Fire: ebiten.IsKeyPressed(ebiten.KeySpace) || ebiten.IsKeyPressed(ebiten.KeyZ) ||
			ebiten.IsKeyPressed(ebiten.KeyX),
	})
	t := fmt.Sprintf("Montezuma's Revenge - level %d - room %d (row %d, column %d) - lives %d - score %d",
		g.Level, g.Room, g.Row, g.Col, g.Lives, g.Score)
	if g.GameOver {
		t = "Montezuma's Revenge - game over - Esc for the title screen"
		if g.Level == 1 && !g.Continued {
			t = "Montezuma's Revenge - game over - fire to continue, Esc for the title screen"
		}
	}
	w.setTitle(t)
	return nil
}

func (w *window) setTitle(t string) {
	if t != w.title {
		ebiten.SetWindowTitle(t)
		w.title = t
	}
}

func (w *window) Draw(screen *ebiten.Image) {
	if w.g == nil {
		w.drawTitle(screen)
		return
	}
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

	// Joe: his hat and legs, then his body on top. Game over hides him.
	body, legs, legsDY := g.Joe.Sprites()
	x, y := int(g.Joe.X), g.Joe.ScreenY()
	switch {
	case g.GameOver:
	case legs < 0:
		drawSprite(screen, rg.sprites[body], x, y, joe.GhostColour)
	default:
		drawSprite(screen, rg.sprites[legs], x, y+legsDY, joe.LegsColour)
		drawSprite(screen, rg.sprites[body], x, y, joe.BodyColour)
	}
	w.maybeScreenshot(screen)
}

// drawTitle draws the title screen.
func (w *window) drawTitle(screen *ebiten.Image) {
	if w.drawnRoom != titleDrawn {
		v := w.titleVRAM
		for i, t := range v.Names {
			v.DrawTile(w.pixels, int(t), i%32*8, i/32*8, gfx.Backdrop)
		}
		w.background.WritePixels(w.pixels.Pix)
		w.drawnRoom = titleDrawn
	}
	screen.DrawImage(w.background, nil)
	w.maybeScreenshot(screen)
}

// titleDrawn is drawnRoom while the background shows the title screen.
const titleDrawn = -2

func (w *window) maybeScreenshot(screen *ebiten.Image) {
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
