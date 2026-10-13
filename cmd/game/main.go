// Command game is the Montezuma's Revenge remake. It draws the original's
// 100 rooms (from rooms.json, see cmd/rooms) and lets Panama Joe walk,
// fall and climb between them. Movement is still a placeholder, not yet
// matched to the original; items and enemies are drawn but don't move.
//
// Keys: arrows move and climb. PageUp/PageDown jump to the previous or
// next room, for testing.
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

	"montezuma-remake/internal/gfx"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
	"montezuma-remake/internal/vdp"
)

const (
	screenW, screenH = 256, 192 // TMS9918A resolution
	cols, rows       = screenW / 8, screenH / 8
	windowScale      = 3
)

// Tiles with special meaning. Floors come from the ROM (floorList).
const (
	tileLadder      = 0x88 // left half; 0x89 is the right half
	tileLadderFloor = 0x10 // ladder top set into a floor; 0x11 right half
	tileRope        = 0x90
)

// hudTiles draw the lives and inventory boxes; Joe can't pass them.
var hudTiles = []byte{0x09, 0x0A, 0x0B, 0x0C, 0x6F}

const (
	floorList = 0x93FF // tiles Joe can stand on
	floorLen  = 10
)

// Sprite numbers in the boot sprite set (see assets/sprites.png).
var (
	walkFrames  = []int{13, 19, 27, 19} // facing right; mirrored for left
	climbFrames = []int{21, 25}
)

// Joe is drawn in one colour until his two-sprite frames are worked out.
const joeColour = 6 // red

// Joe lands here in the starting room after sliding down the entrance pole.
const startX, startY = 120, 9*8 - 16

type game struct {
	rooms   []roomdata.Room
	gfx     map[int]*roomGfx
	joeImgs [64]*ebiten.Image
	solid   map[byte]bool

	room     int
	row, col int // the game's row and column; see internal/pyramid
	joe      player

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

// roomGfx is a room's pre-rendered background and sprite images.
type roomGfx struct {
	background *ebiten.Image
	sprites    [64]*ebiten.Image // indexed by pattern/4, white; tinted when drawn
}

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
	boot, err := gfx.Boot(r)
	if err != nil {
		log.Fatal(err)
	}
	floors, err := r.Slice(floorList, floorLen)
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

	g := newGame(rooms, floors)
	g.screenshot = *screenshot
	for s := range g.joeImgs {
		img := image.NewRGBA(image.Rect(0, 0, 16, 16))
		boot.DrawSprite16(img, s*4, 0, 0, vdp.Palette[joeColour])
		g.joeImgs[s] = ebiten.NewImageFromImage(img)
	}
	g.enter(*startRoom)

	ebiten.SetWindowSize(screenW*windowScale, screenH*windowScale)
	if err := ebiten.RunGame(g); err != nil {
		log.Fatal(err)
	}
}

func newGame(rooms []roomdata.Room, floors []byte) *game {
	g := &game{
		rooms: rooms,
		gfx:   map[int]*roomGfx{},
		solid: map[byte]bool{},
		joe:   player{x: startX, y: startY},
	}
	for _, t := range append(append([]byte(nil), floors...), hudTiles...) {
		g.solid[t] = true
	}
	return g
}

// enter switches to room at its own place in the pyramid.
func (g *game) enter(room int) {
	g.row, g.col = pyramid.Position(room)
	g.show(room)
}

// show switches to room, keeping the current row and column.
func (g *game) show(room int) {
	g.room = room
	ebiten.SetWindowTitle(fmt.Sprintf("Montezuma's Revenge - room %d (row %d, column %d)", room, g.row, g.col))
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

func (g *game) tileAt(px, py int) byte {
	x, y := px/8, py/8
	if px < 0 || x >= cols || py < 0 || y >= rows {
		return 0 // off screen: open, so Joe can leave the room
	}
	return g.rooms[g.room].Tiles[y][x]
}

func (g *game) solidAt(px, py int) bool { return g.solid[g.tileAt(px, py)] }

func ladder(t byte) bool {
	return t == tileLadder || t == tileLadder+1 || t == tileLadderFloor || t == tileLadderFloor+1
}

func climbable(t byte) bool { return ladder(t) || t == tileRope }

// climbX returns where Joe hangs on the ladder or rope at pixel column px.
func climbX(t byte, px int) int {
	c := px / 8
	switch t {
	case tileLadder + 1, tileLadderFloor + 1:
		c-- // right half of a two-tile ladder
	case tileRope:
		return c*8 - 4
	}
	return c * 8
}

func (g *game) Update() error {
	g.frame++
	if g.screenshot != "" && g.frame > screenshotFrame {
		return ebiten.Termination
	}
	switch {
	case inpututil.IsKeyJustPressed(ebiten.KeyPageDown):
		g.enter((g.room + 1) % len(g.rooms))
	case inpututil.IsKeyJustPressed(ebiten.KeyPageUp):
		g.enter((g.room + len(g.rooms) - 1) % len(g.rooms))
	}
	g.move(input{
		left:  ebiten.IsKeyPressed(ebiten.KeyArrowLeft),
		right: ebiten.IsKeyPressed(ebiten.KeyArrowRight),
		up:    ebiten.IsKeyPressed(ebiten.KeyArrowUp),
		down:  ebiten.IsKeyPressed(ebiten.KeyArrowDown),
	})
	g.leaveRoom()
	return nil
}

type input struct{ left, right, up, down bool }

// move is placeholder movement: walking, falling and climbing.
func (g *game) move(in input) {
	j := &g.joe
	left, right, up, down := in.left, in.right, in.up, in.down

	cx := j.x + 8
	standing := g.solidAt(j.x+4, j.y+16) || g.solidAt(j.x+11, j.y+16)
	moved := false

	// Start or continue climbing on a ladder or rope.
	if t := g.tileAt(cx, j.y+15); up && climbable(t) {
		j.climbing, j.x = true, climbX(t, cx)
	} else if t := g.tileAt(cx, j.y+16); down && climbable(t) {
		j.climbing, j.x = true, climbX(t, cx)
	}
	if j.climbing {
		switch {
		case up && climbable(g.tileAt(j.x+8, j.y+15)):
			j.y--
			moved = true
		case down && climbable(g.tileAt(j.x+8, j.y+16)):
			j.y++
			moved = true
		}
		// Let go once nothing to climb is behind or under Joe, or when he
		// steps sideways while his feet are on a floor.
		if !climbable(g.tileAt(j.x+8, j.y+15)) && !climbable(g.tileAt(j.x+8, j.y+16)) {
			j.climbing = false
		}
		if (left || right) && standing {
			j.climbing = false
		}
	}

	if !j.climbing {
		switch {
		case left && !g.solidAt(j.x+3, j.y+8) && !g.solidAt(j.x+3, j.y+15):
			j.x--
			j.left, moved = true, true
		case right && !g.solidAt(j.x+12, j.y+8) && !g.solidAt(j.x+12, j.y+15):
			j.x++
			j.left, moved = false, true
		}
		if !standing {
			j.y += 2
			for g.solidAt(j.x+4, j.y+15) || g.solidAt(j.x+11, j.y+15) {
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
}

// leaveRoom moves to the next room when Joe goes off an edge, using the
// game's row and column arithmetic.
func (g *game) leaveRoom() {
	j := &g.joe
	row, col := g.row, g.col
	dx, dy := 0, 0
	switch {
	case j.x < -8:
		col, dx = col-1, screenW
	case j.x > screenW-8:
		col, dx = col+1, -screenW
	case j.y < -8:
		row, dy = row-1, screenH
	case j.y > screenH-8:
		row, dy = row+1, -screenH
	default:
		return
	}

	// The entrance hall's pole leads to the starting room and back.
	next := pyramid.Room(row, col)
	switch {
	case g.room == pyramid.Entrance && dy < 0:
		row, col = pyramid.Position(pyramid.Start)
		next = pyramid.Start
	case g.room == pyramid.Start && dy > 0:
		row, col = pyramid.Position(pyramid.Entrance)
		next = pyramid.Entrance
	}
	if next < 0 { // off the top, or below the bottom row (next level: not yet)
		j.x = min(max(j.x, -8), screenW-8)
		j.y = min(max(j.y, -8), screenH-8)
		return
	}
	g.row, g.col = row, col
	j.x += dx
	j.y += dy
	g.show(next)
}

func (g *game) Draw(screen *ebiten.Image) {
	rg := g.roomGfx(g.room)
	screen.DrawImage(rg.background, nil)

	// Items and enemies as the room loaded; sprite 0 is drawn last, on top.
	sprites := g.rooms[g.room].Sprites
	for i := len(sprites) - 1; i >= 0; i-- {
		s := sprites[i]
		op := &ebiten.DrawImageOptions{}
		op.GeoM.Translate(float64(s.X), float64(s.Y))
		c := vdp.Palette[s.Colour]
		op.ColorScale.Scale(float32(c.R)/255, float32(c.G)/255, float32(c.B)/255, 1)
		screen.DrawImage(rg.sprites[s.Pattern/4], op)
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
	screen.DrawImage(g.joeImgs[frames[j.animFrame%len(frames)]], op)

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
