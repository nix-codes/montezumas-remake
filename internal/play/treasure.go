package play

import (
	"montezuma-remake/internal/items"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/sound"
)

// The treasure room lies below the bottom row of the pyramid: falling
// through the gap in room 90's floor leads into a shaft of screens (column
// 10) hung with chains and jewels, for as long as its timer runs. The
// columns beside the shaft have a pole down one side; leaving the bottom of
// the screen while sliding down a pole starts the next level.
const (
	treasureRoom     = 90  // its tile set and colours are used
	treasureTime     = 240 // contact checks ($70AC), counting down to 1
	treasureShaft    = 10
	treasureBackdrop = 5 // blue
	treasureChains   = 25
	maxLevel         = 9
)

// Tiles of the treasure room ($A9AD).
const (
	tileChain = 0x90
	tileBrick = 0x08
	tilePole  = 0x95
)

// enterBelow handles leaving the bottom row ($8E0C): the next level if Joe
// is on a pole, otherwise the treasure room.
func (g *Game) enterBelow(row, col int) {
	g.Sound.Play(sound.Below)
	if g.Joe.State == joe.Pole {
		g.nextLevel()
		return
	}
	if !g.Treasure {
		// First time in: the timer starts and the inventory is emptied
		// ($8E69).
		g.Treasure = true
		g.TreasureTimer = treasureTime
		g.Inventory = items.NewInventory()
	}
	g.Row, g.Col = row, col
	g.Room = treasureRoom
	g.Entry = g.Joe
	// No room is loaded: the pause is the single frame the new screen
	// takes to set up.
	g.Joe.Frozen = 0
	g.setupPending = true
}

// treasureScreen draws a screen of the treasure room ($A60B). The original
// does it in the frame interrupt after the change is asked for ($705F bit
// 3), so it comes a frame later. While the
// timer runs, the shaft gets 25 chains and a line of jewels, placed by
// reading the ROM at a pointer that moves every frame ($7047); columns
// other than the shaft get a wall and a pole down one side.
func (g *Game) treasureScreen() {
	g.TreasureScreens++
	g.Tiles.T = [24][32]byte{}
	g.Tiles.Version++
	set := func(i int, t byte) {
		if i >= 0 && i < 24*32 {
			g.Tiles.T[i/32][i%32] = t
		}
	}
	if g.TreasureTimer != 1 {
		p := g.Random&0xFF | uint16(byte(g.Random>>8)&0xAE|0x80)<<8
		for i := 0; i < treasureChains; i++ {
			length := int(g.romByte(p)&7 | 2)
			top := 0x100 + int(g.romByte(p+2))
			for k := 0; k < length; k++ {
				set(top+32*k, tileChain)
			}
			p += 3
		}
		icon := g.Rules.Items.Icon(items.Jewel)
		at := 0x100 + int(g.Random&0x1F)
		for i := 0; i < 8+g.Level/2; i++ {
			set(at, icon[0])
			set(at+1, icon[1])
			set(at+32, icon[2])
			set(at+33, icon[3])
			at += 0x27
		}
	}
	if g.Col != treasureShaft {
		side, cols := 0, [3]byte{tileBrick, 0, tilePole}
		if g.Col == treasureShaft+1 {
			side, cols = 29, [3]byte{tilePole, 0, tileBrick}
		}
		for row := 0; row < 24; row++ {
			for c, t := range cols {
				g.Tiles.T[row][side+c] = t
			}
		}
	}
	// No enemies or room objects down here.
	g.Contacts = []byte{0, 0, 0xFE}
	for _, s := range g.Enemies.Sprites[2:] {
		s.Colour = 0
	}
	g.Enemies.Objects = nil
	g.drawScore()
}

// romByte reads the cartridge, as the treasure room uses it for random
// numbers.
func (g *Game) romByte(addr uint16) byte {
	b, err := g.Rules.ROM.Slice(addr, 1)
	if err != nil {
		return 0
	}
	return b[0]
}

// nextLevel starts the next level ($8E20): harder, every room reset, back
// in the entrance hall. Joe comes down the pole on the side he took out of
// the treasure room.
func (g *Game) nextLevel() {
	if g.Level < maxLevel {
		g.Level++
	}
	if g.LevelRooms != nil {
		g.Rooms = g.LevelRooms(g.Level)
	}
	g.Treasure = false
	g.Done = [pyramid.Rooms]uint16{}
	g.enterLevel()
	// Resetting every room on top of drawing the hall makes the pause a
	// frame longer than a room change's (on the emulator).
	g.Joe.Frozen++
}

// Backdrop returns the screen's backdrop colour.
func (g *Game) Backdrop() int {
	if g.Treasure {
		return treasureBackdrop
	}
	return g.Rooms[g.Room].Backdrop
}
