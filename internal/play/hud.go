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
