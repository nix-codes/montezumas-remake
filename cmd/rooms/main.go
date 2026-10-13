// Command rooms loads each of the 100 rooms through the original game's own
// room loader (running on the emulator), and saves its tile map, sprites and
// exits as rooms.json, plus a PNG per room and a map of the whole pyramid.
//
// It also cross-checks exits: every exit should lead to a room with a
// matching opening on the opposite side.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"log"
	"os"
	"path/filepath"

	"montezuma-remake/internal/original"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

// Tiles Joe can stand on.
const (
	floorList = 0x93FF
	floorLen  = 10
)

// Tiles.
const (
	tileEmpty       = 0x00
	tileBrick       = 0x08
	tileLadder      = 0x88 // and 0x89, the right half
	tileLadderFloor = 0x10 // ladder top set into a floor; and 0x11
	tileRope        = 0x90
)

// The top five tile rows hold the lives and inventory boxes at the sides;
// only the middle columns there belong to the room.
const (
	hudRows                   = 5
	hudLeftEnd, hudRightStart = 12, 22
)

type (
	Room  = roomdata.Room
	Exits = roomdata.Exits
)

func main() {
	romPath := flag.String("rom", "build/montezuma.rom", "assembled ROM")
	level := flag.Int("level", 1, "level to select on the title screen (1-3)")
	outDir := flag.String("out", "assets/rooms", "output directory")
	flag.Parse()

	r, err := rom.Load(*romPath)
	if err != nil {
		log.Fatal(err)
	}
	floors, err := r.Slice(floorList, floorLen)
	if err != nil {
		log.Fatal(err)
	}
	dir := filepath.Join(*outDir, fmt.Sprintf("level%d", *level))
	if err := os.MkdirAll(dir, 0o755); err != nil {
		log.Fatal(err)
	}

	rooms := make([]Room, pyramid.Rooms)
	shots := make([]*image.RGBA, pyramid.Rooms)
	for n := range rooms {
		// Start each room from a fresh game, so one room's state (Joe
		// falling or dying, say) can't affect the next.
		g, err := original.Start(*romPath, *level)
		if err != nil {
			log.Fatal(err)
		}
		if err := g.LoadRoom(n); err != nil {
			log.Fatal(err)
		}
		m := g.Machine
		row, col := pyramid.Position(n)
		room := Room{
			Number:         n,
			Row:            row,
			Column:         col,
			TilePatterns:   m.VDP.TilePatterns(),
			TileColours:    m.VDP.TileColours(),
			SpritePatterns: m.VDP.SpritePatterns(),
			Backdrop:       int(m.VDP.Reg[7] & 0x0F),
			Objects:        g.Until(original.ObjectList, 0xFF, 16),
			Contacts:       g.Until(original.ContactList, 0xFE, 32),
			SpriteTable:    g.Bytes(original.SpriteTable, 32),
			FrameCounter:   g.Peek(original.FrameCounter),
		}
		names := m.VDP.NameTable()
		for y := range room.Tiles {
			copy(room.Tiles[y][:], names[y*32:])
		}
		room.Exits = findExits(&room, floors)
		rooms[n] = room

		shots[n] = image.NewRGBA(image.Rect(0, 0, 256, 192))
		m.VDP.Render(shots[n])
		writePNG(filepath.Join(dir, fmt.Sprintf("room-%02d.png", n)), shots[n])
	}

	out, err := json.MarshalIndent(rooms, "", "  ")
	if err != nil {
		log.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "rooms.json"), out, 0o644); err != nil {
		log.Fatal(err)
	}
	writePNG(filepath.Join(dir, "map.png"), pyramidMap(shots))
	fmt.Printf("saved %d rooms to %s\n", len(rooms), dir)
	report(rooms)
}

func findExits(r *Room, floors []byte) Exits {
	solid := map[byte]bool{tileBrick: true}
	for _, t := range floors {
		solid[t] = true
	}
	// At the top and bottom edges, a ladder may pass through a floor.
	climbable := func(t byte) bool {
		return t == tileLadder || t == tileLadder+1 || t == tileRope ||
			t == tileLadderFloor || t == tileLadderFloor+1
	}

	e := Exits{
		Left:  pyramid.Neighbour(r.Number, pyramid.Left),
		Right: pyramid.Neighbour(r.Number, pyramid.Right),
		Up:    pyramid.Neighbour(r.Number, pyramid.Up),
		Down:  pyramid.Neighbour(r.Number, pyramid.Down),
	}
	// Joe is two tiles tall, so a side opening needs two open rows.
	sideRows := func(col int) []int {
		var rows []int
		for y := hudRows; y < 24; y++ {
			if !solid[r.Tiles[y][col]] && y+1 < 24 && !solid[r.Tiles[y+1][col]] {
				rows = append(rows, y)
			}
		}
		return rows
	}
	e.LeftRows, e.RightRows = sideRows(0), sideRows(31)
	for x := hudLeftEnd; x < hudRightStart; x++ {
		if climbable(r.Tiles[0][x]) {
			e.UpColumns = append(e.UpColumns, x)
		}
	}
	for x := 0; x < 32; x++ {
		switch t := r.Tiles[23][x]; {
		case climbable(t):
			e.DownColumns = append(e.DownColumns, x)
		case !solid[t]:
			e.DropColumns = append(e.DropColumns, x)
		}
	}
	if len(e.LeftRows) == 0 {
		e.Left = -1
	}
	if len(e.RightRows) == 0 {
		e.Right = -1
	}
	if len(e.UpColumns) == 0 {
		e.Up = -1
	}
	if len(e.DownColumns) == 0 && len(e.DropColumns) == 0 {
		e.Down = -1
	}
	return e
}

// report prints exit statistics and any exit whose far side doesn't match.
func report(rooms []Room) {
	opening := func(e Exits, d pyramid.Direction) bool {
		switch d {
		case pyramid.Left:
			return len(e.LeftRows) > 0
		case pyramid.Right:
			return len(e.RightRows) > 0
		case pyramid.Up:
			return len(e.UpColumns) > 0
		default:
			return len(e.DownColumns) > 0
		}
	}
	opposite := [...]pyramid.Direction{pyramid.Right, pyramid.Left, pyramid.Down, pyramid.Up}

	exits, outside, mismatched, drops := 0, 0, 0, 0
	for _, r := range rooms {
		if len(r.Exits.DownColumns) == 0 && len(r.Exits.DropColumns) > 0 {
			drops++
		}
		for d := pyramid.Left; d <= pyramid.Down; d++ {
			if !opening(r.Exits, d) {
				continue
			}
			exits++
			n := pyramid.Neighbour(r.Number, d)
			switch {
			case n < 0:
				outside++
				fmt.Printf("room %2d: %s opening leads outside the pyramid\n", r.Number, d)
			case !opening(rooms[n].Exits, opposite[d]):
				mismatched++
				fmt.Printf("room %2d: %s opening, but room %d has no %s opening\n", r.Number, d, n, opposite[d])
			}
		}
	}
	fmt.Printf("%d openings: %d lead outside, %d don't match their neighbour\n", exits, outside, mismatched)
	fmt.Printf("%d rooms have gaps in the floor edge but no ladder or rope down\n", drops)
}

// pyramidMap lays the rooms out as the pyramid, at half size.
func pyramidMap(shots []*image.RGBA) image.Image {
	const w, h = 128, 96
	cols := 2*pyramid.Centre + 1 // columns 0-20; the pyramid uses 1-19
	img := image.NewRGBA(image.Rect(0, 0, cols*w, pyramid.Rows*h))
	for n, shot := range shots {
		row, col := pyramid.Position(n)
		at := image.Pt(col*w, row*h)
		for y := 0; y < h; y++ {
			for x := 0; x < w; x++ {
				img.Set(at.X+x, at.Y+y, shot.At(x*2, y*2))
			}
		}
		draw.Draw(img, image.Rect(at.X, at.Y, at.X+w, at.Y+1), image.White, image.Point{}, draw.Src)
		draw.Draw(img, image.Rect(at.X, at.Y, at.X+1, at.Y+h), image.White, image.Point{}, draw.Src)
	}
	return img
}

func writePNG(path string, img image.Image) {
	f, err := os.Create(path)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	if err := png.Encode(f, img); err != nil {
		log.Fatal(err)
	}
}
