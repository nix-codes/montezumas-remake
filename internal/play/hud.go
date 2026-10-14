package play

import "montezuma-remake/internal/items"

// HUD tiles.
const (
	tileLife     = 0x6F // one hat per spare life
	tileDigitTop = 0x18 // big digits: top half 0x18+d, bottom 0x28+d
	tileDigitBot = 0x28
)

// Display returns the screen. The HUD is part of it, drawn the way and at
// the moments the original draws it.
func (g *Game) Display() [24][32]byte { return g.Tiles.T }

// RedrawHUD redraws the whole HUD into the screen, as the original does when
// a room loads and when the inventory changes ($A548): the score and
// level, the inventory box, and the spare lives (not in the treasure room).
func (g *Game) RedrawHUD() {
	g.drawScore()
	for row := 1; row <= 3; row++ {
		for col := 1; col <= 10; col++ {
			g.Tiles.SetTile(col, row, 0)
		}
	}
	for i, code := range g.Inventory {
		if code == items.Empty {
			break
		}
		t := g.Rules.Items.Icon(code)
		col := 1 + 2*i
		g.Tiles.SetTile(col, 1, t[0])
		g.Tiles.SetTile(col+1, 1, t[1])
		g.Tiles.SetTile(col, 2, t[2])
		g.Tiles.SetTile(col+1, 2, t[3])
	}
	if g.Treasure {
		return
	}
	// Spare lives ($AABB): up to 10 hats on the left, more on the right.
	for col := 1; col <= 8; col++ {
		g.Tiles.SetTile(col, 3, 0)
		g.Tiles.SetTile(22+col, 3, 0)
	}
	for i := 0; i < int(g.Lives) && i < 10; i++ {
		g.Tiles.SetTile(1+i, 3, tileLife)
	}
	for i := 10; i < int(g.Lives) && i < 18; i++ {
		g.Tiles.SetTile(23+i-10, 3, tileLife)
	}
}

// drawScore redraws the level and the 6-digit score, leading zeros blank
// ($AEFE).
func (g *Game) drawScore() {
	g.Tiles.SetTile(20, 1, tileDigitTop+byte(g.Level))
	g.Tiles.SetTile(20, 2, tileDigitBot+byte(g.Level))
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
		g.Tiles.SetTile(24+i, 1, top)
		g.Tiles.SetTile(24+i, 2, bot)
	}
}

// darkEntries are the colour table entries the original blacks out in
// dark rooms ($8EF5): tiles $00-$17 (bricks, floors, conveyors), $80-$9F
// (ladders, ropes, items) and $A8-$C7 (doors, creatures).
var darkEntries = []int{0, 1, 2, 16, 17, 18, 19, 21, 22, 23, 24}

// Dark reports whether the room is dark: deep in the pyramid (its row, as
// the game keeps it, at least 9 minus the level) and Joe has no torch
// ($8ED8). The treasure room is never dark.
func (g *Game) Dark() bool {
	return !g.Treasure && g.Row >= 9-g.Level && !g.Inventory.Has(items.Torch)
}

// Colour entries the barrier task sets ($A8D6): barriers ($E0-$E7) and
// disappearing floors ($E8-$EF), dark blue when shown.
const (
	barrierEntry = 28
	floorEntry   = 29
	barrierShown = 0x40

	// The amulet sets the creatures' entry ($91D9): grey while it
	// protects Joe, then dark green, not the room's medium green.
	creatureEntry      = 20
	creaturesProtected = 0xE0
	creaturesAfter     = 0xC0
)

// Colours returns the room's tile colour table, darkened if it's dark,
// with the barriers and disappearing floors as they blink and the
// creatures as the amulet left them.
func (g *Game) Colours() [32]byte {
	var c [32]byte
	copy(c[:], g.Rooms[g.Room].TileColours)
	if g.CreatureColour != 0 {
		c[creatureEntry] = g.CreatureColour
	}
	c[barrierEntry], c[floorEntry] = barrierShown, barrierShown
	if g.BarriersOff {
		c[barrierEntry] = 0
	}
	if g.FloorsGone {
		c[floorEntry] = 0
	}
	if g.Dark() {
		for _, e := range darkEntries {
			c[e] = 0
		}
	}
	return c
}
