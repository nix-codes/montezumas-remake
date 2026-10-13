package play

import "montezuma-remake/internal/items"

// HUD tiles.
const (
	tileLife     = 0x6F // one hat per spare life
	tileDigitTop = 0x18 // big digits: top half 0x18+d, bottom 0x28+d
	tileDigitBot = 0x28
)

// Display returns the screen: the room's tiles with the HUD drawn over them
// as the original draws it: the inventory in the left box ($A548), spare
// lives below it ($AABB), the level and the score on the right ($AEFE).
func (g *Game) Display() [24][32]byte {
	s := g.Tiles.T
	for row := 1; row <= 2; row++ {
		for col := 1; col <= 10; col++ {
			s[row][col] = 0
		}
	}
	for col := 1; col <= 8; col++ {
		s[3][col] = 0
	}
	for i, code := range g.Inventory {
		if code == items.Empty {
			break
		}
		t := g.Rules.Items.Icon(code)
		col := 1 + 2*i
		if col+1 >= 32 {
			break
		}
		s[1][col], s[1][col+1], s[2][col], s[2][col+1] = t[0], t[1], t[2], t[3]
	}
	for i := 0; i < g.Lives && i < 8; i++ {
		s[3][1+i] = tileLife
	}

	s[1][20] = tileDigitTop + byte(g.Level)
	s[2][20] = tileDigitBot + byte(g.Level)
	score := g.Score % 1000000
	digits := [6]int{}
	for i := 5; i >= 0; i-- {
		digits[i] = score % 10
		score /= 10
	}
	leading := true
	for i, d := range digits {
		top, bot := byte(0), byte(0)
		if d != 0 || !leading {
			leading = false
			top, bot = tileDigitTop+byte(d), tileDigitBot+byte(d)
		}
		s[1][24+i], s[2][24+i] = top, bot
	}
	return s
}

// darkEntries are the colour table entries the original blacks out in
// dark rooms ($8EF5): tiles $00-$17 (bricks, floors, conveyors), $80-$9F
// (ladders, ropes, items) and $A8-$C7 (doors, creatures).
var darkEntries = []int{0, 1, 2, 16, 17, 18, 19, 21, 22, 23, 24}

// Dark reports whether the room is dark: deep in the pyramid (its row, as
// the game keeps it, at least 9 minus the level) and Joe has no torch
// ($8ED8).
func (g *Game) Dark() bool {
	return g.Row >= 9-g.Level && !g.Inventory.Has(items.Torch)
}

// Colours returns the room's tile colour table, darkened if it's dark.
func (g *Game) Colours() [32]byte {
	var c [32]byte
	copy(c[:], g.Rooms[g.Room].TileColours)
	if g.Dark() {
		for _, e := range darkEntries {
			c[e] = 0
		}
	}
	return c
}
