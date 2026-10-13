// Package original drives the original game on the emulator: starting a
// game, loading rooms and reading or placing Panama Joe. The remake uses it
// as its reference.
package original

import (
	"fmt"
	"os"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/pyramid"
)

// Game addresses.
const (
	loadRoom = 0xA067 // loads the room at the current row and column
	rowVar   = 0x71A7
	colVar   = 0x71A8
	roomVar  = 0x7015 // room number computed by the loader
	flagsVar = 0x705F // bit 2 is set while Joe descends the entrance pole

	// The game's local sprite table (address in the cartridge header). Joe
	// is the first two entries: his body, and his hat and legs 3 pixels
	// lower. Each entry is Y, X, pattern, colour, as the video chip takes
	// them.
	spriteTable = 0x7300
	joeDX       = 0x7076 // signed pixels per frame
	joeDY       = 0x7077
	joeState    = 0x7079
)

// Joe's states in $7079.
const (
	Standing = 0
	Walking  = 1
	Falling  = 6
	Dead     = 9
)

// Game is a running original game.
type Game struct {
	*coleco.Machine
}

// Start boots the cartridge, selects a level (1-3) and returns once Joe has
// slid down the entrance pole and is standing in the starting room.
func Start(romPath string, level int) (*Game, error) {
	cart, err := os.ReadFile(romPath)
	if err != nil {
		return nil, err
	}
	m := coleco.New(cart)
	for f := 0; f < 2000; f++ {
		m.Input = coleco.Joystick{Key: -1}
		if f >= 160 && f <= 170 {
			m.Input.Key = level
		}
		if err := m.RunFrame(); err != nil {
			return nil, err
		}
		if f > 200 && m.Peek(flagsVar)&0x04 == 0 {
			for i := 0; i < 10; i++ { // let the landing settle
				if err := m.RunFrame(); err != nil {
					return nil, err
				}
			}
			return &Game{m}, nil
		}
	}
	return nil, fmt.Errorf("game didn't start")
}

// LoadRoom loads room through the game's own loader, at the room's place in
// the pyramid.
func (g *Game) LoadRoom(room int) error {
	row, col := pyramid.Position(room)
	g.Poke(rowVar, byte(row))
	g.Poke(colVar, byte(col))
	if err := g.Call(loadRoom, 300); err != nil {
		return err
	}
	if got := g.Room(); got != room {
		return fmt.Errorf("row %d column %d: game loaded room %d, expected %d", row, col, got, room)
	}
	return nil
}

// Room returns the current room number.
func (g *Game) Room() int { return int(g.Peek(roomVar)) }

// Joe is Panama Joe's state.
type Joe struct {
	X, Y   int // top-left of his body sprite on screen
	DX, DY int // velocity, pixels per frame
	State  int
	Body   int // sprite numbers (pattern / 4) of his two sprites
	Legs   int
}

// Joe returns Joe's current state.
func (g *Game) Joe() Joe {
	return Joe{
		X:     int(g.Peek(spriteTable + 1)),
		Y:     int(g.Peek(spriteTable)) + 1,
		DX:    int(int8(g.Peek(joeDX))),
		DY:    int(int8(g.Peek(joeDY))),
		State: int(g.Peek(joeState)),
		Body:  int(g.Peek(spriteTable+2)) / 4,
		Legs:  int(g.Peek(spriteTable+6)) / 4,
	}
}

// PlaceJoe moves Joe so the top-left of his body is at (x, y).
func (g *Game) PlaceJoe(x, y int) {
	g.Poke(spriteTable, byte(y-1))
	g.Poke(spriteTable+1, byte(x))
	g.Poke(spriteTable+4, byte(y+2))
	g.Poke(spriteTable+5, byte(x))
}

// Step runs one frame with the given input.
func (g *Game) Step(in coleco.Joystick) error {
	in.Key = -1
	g.Input = in
	return g.RunFrame()
}
