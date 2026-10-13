// Command game is the Montezuma's Revenge remake. It draws the original's
// 100 rooms (from rooms.json, see cmd/rooms) and moves Panama Joe through
// them the way the original does (internal/joe). Items and enemies are
// drawn but don't move or interact yet.
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

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
	"montezuma-remake/internal/vdp"
)

const (
	screenW, screenH = 256, 192 // TMS9918A resolution
	windowScale      = 3
	startLives       = 5
)

// Joe lands here in the starting room after sliding down the entrance pole.
const startX, startY = 124, 53

type game struct {
	rooms []roomdata.Room
	gfx   map[int]*roomGfx
	rules *joe.Rules

	room     int
	row, col int     // the game's row and column; see internal/pyramid
	joe      joe.Joe // Panama Joe
	entry    joe.Joe // Joe as he entered the room, to respawn him there
	lives    int

	frame      int
	screenshot string // if set, save frame screenshotFrame here and quit
}

const screenshotFrame = 30

// roomGfx is a room's pre-rendered background and sprite images.
type roomGfx struct {
	background *ebiten.Image
	sprites    [64]*ebiten.Image // indexed by pattern/4, white; tinted when drawn
}

// roomTiles lets Joe read a room's tile map.
type roomTiles struct{ r *roomdata.Room }

func (t roomTiles) Tile(col, row int) byte { return t.r.Tiles[row][col] }

func main() {
	romPath := flag.String("rom", "build/montezuma.rom", "assembled ROM")
	roomsPath := flag.String("rooms", "assets/rooms/level1/rooms.json", "rooms from cmd/rooms")
	startRoom := flag.Int("room", pyramid.Start, "room to start in")
	screenshot := flag.String("screenshot", "", "save a PNG of an early frame to this path and exit")
	flag.Parse()

	r, err := rom.Load(*romPath)
	if err != nil {
		log.Fatal(err)
	}
	rules, err := joe.RulesFromROM(r)
	if err != nil {
		log.Fatal(err)
	}
	rooms, err := roomdata.Load(*roomsPath)
	if err != nil {
		log.Fatal(err)
	}
	if *startRoom < 0 || *startRoom >= len(rooms) {
		log.Fatalf("no room %d", *startRoom)
	}

	g := newGame(rooms, rules, *startRoom)
	g.screenshot = *screenshot
	ebiten.SetWindowSize(screenW*windowScale, screenH*windowScale)
	if err := ebiten.RunGame(g); err != nil {
		log.Fatal(err)
	}
}

func newGame(rooms []roomdata.Room, rules *joe.Rules, room int) *game {
	g := &game{rooms: rooms, gfx: map[int]*roomGfx{}, rules: rules}
	g.restart(room)
	return g
}

// restart starts a new game in room.
func (g *game) restart(room int) {
	g.lives = startLives
	g.joe.Place(startX, startY)
	g.enter(room)
}

// enter switches to room at its own place in the pyramid.
func (g *game) enter(room int) {
	g.row, g.col = pyramid.Position(room)
	g.show(room)
}

// show switches to room, keeping the current row and column, and remembers
// Joe as he comes in, as the original does for respawning.
func (g *game) show(room int) {
	g.room = room
	g.entry = g.joe
	g.title()
}

func (g *game) title() {
	ebiten.SetWindowTitle(fmt.Sprintf("Montezuma's Revenge - room %d (row %d, column %d) - lives %d",
		g.room, g.row, g.col, g.lives))
}

// roomGfx renders a room's graphics the first time it's shown.
func (g *game) roomGfx(n int) *roomGfx {
	if rg, ok := g.gfx[n]; ok {
		return rg
	}
	r := &g.rooms[n]
	var v vdp.VRAM
	copy(v.TilePatterns[:], r.TilePatterns)
	copy(v.Colours[:], r.TileColours)
	copy(v.SpritePatterns[:], r.SpritePatterns)

	bg := image.NewRGBA(image.Rect(0, 0, screenW, screenH))
	for y := range r.Tiles {
		for x, t := range r.Tiles[y] {
			v.DrawTile(bg, int(t), x*8, y*8, r.Backdrop)
		}
	}
	rg := &roomGfx{background: ebiten.NewImageFromImage(bg)}
	for s := range rg.sprites {
		img := image.NewRGBA(image.Rect(0, 0, 16, 16))
		v.DrawSprite16(img, s*4, 0, 0, vdp.Palette[15])
		rg.sprites[s] = ebiten.NewImageFromImage(img)
	}
	g.gfx[n] = rg
	return rg
}

func (g *game) Update() error {
	g.frame++
	if g.screenshot != "" && g.frame > screenshotFrame {
		return ebiten.Termination
	}
	switch {
	case inpututil.IsKeyJustPressed(ebiten.KeyPageDown):
		g.teleport((g.room + 1) % len(g.rooms))
	case inpututil.IsKeyJustPressed(ebiten.KeyPageUp):
		g.teleport((g.room + len(g.rooms) - 1) % len(g.rooms))
	}
	g.step(joe.Input{
		Left:  ebiten.IsKeyPressed(ebiten.KeyArrowLeft),
		Right: ebiten.IsKeyPressed(ebiten.KeyArrowRight),
		Up:    ebiten.IsKeyPressed(ebiten.KeyArrowUp),
		Down:  ebiten.IsKeyPressed(ebiten.KeyArrowDown),
		Fire: ebiten.IsKeyPressed(ebiten.KeySpace) || ebiten.IsKeyPressed(ebiten.KeyZ) ||
			ebiten.IsKeyPressed(ebiten.KeyX),
	})
	return nil
}

// teleport moves to room for testing, with Joe standing where he was.
func (g *game) teleport(room int) {
	x, y := g.joe.X, g.joe.ScreenY()
	g.joe.Place(int(x), y)
	g.enter(room)
}

// step runs one frame of Joe.
func (g *game) step(in joe.Input) {
	before := g.joe
	exit := g.joe.Step(in, roomTiles{&g.rooms[g.room]}, g.rules)
	if exit != 0 {
		g.changeRoom(exit, before)
	}
	if g.joe.Respawn() {
		g.lives--
		if g.lives < 0 {
			g.restart(pyramid.Start)
			return
		}
		g.joe = g.entry
		g.title()
	}
}

// changeRoom follows Joe out of the room, using the game's row and column
// arithmetic. Where the original would leave the pyramid (or, at the
// bottom, start the next level, which isn't done yet), Joe stays put.
func (g *game) changeRoom(exit int, before joe.Joe) {
	row, col := g.row, g.col
	switch exit {
	case joe.ExitLeft:
		col--
	case joe.ExitRight:
		col++
	case joe.ExitUp:
		row--
	case joe.ExitDown:
		row++
	}
	next := pyramid.Room(row, col)
	// The entrance hall's pole leads to the starting room and back.
	switch {
	case g.room == pyramid.Entrance && exit == joe.ExitDown:
		next = pyramid.Start
		row, col = pyramid.Position(next)
	case g.room == pyramid.Start && exit == joe.ExitUp:
		next = pyramid.Entrance
		row, col = pyramid.Position(next)
	}
	if next < 0 {
		g.joe = before
		g.joe.DX, g.joe.DY = 0, 0
		return
	}
	g.row, g.col = row, col
	g.show(next)
}

func (g *game) Draw(screen *ebiten.Image) {
	rg := g.roomGfx(g.room)
	screen.DrawImage(rg.background, nil)

	// Items and enemies as the room loaded; sprite 0 is drawn last, on top.
	sprites := g.rooms[g.room].Sprites
	for i := len(sprites) - 1; i >= 0; i-- {
		s := sprites[i]
		drawSprite(screen, rg.sprites[s.Pattern/4], s.X, s.Y, s.Colour)
	}

	// Joe: his hat and legs, then his body on top.
	body, legs, legsDY := g.joe.Sprites()
	x, y := int(g.joe.X), g.joe.ScreenY()
	drawSprite(screen, rg.sprites[legs], x, y+legsDY, joe.LegsColour)
	drawSprite(screen, rg.sprites[body], x, y, joe.BodyColour)

	if g.screenshot != "" && g.frame == screenshotFrame {
		if err := saveScreenshot(screen, g.screenshot); err != nil {
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

func (g *game) Layout(int, int) (int, int) {
	return screenW, screenH
}
