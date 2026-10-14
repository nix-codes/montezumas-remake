package play_test

import (
	"testing"

	"montezuma-remake/internal/items"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/play"
)

// TestAmuletRunsOut climbs out of room 5 with the amulet's last few
// contact checks left: the creatures turn grey, then dark green as it
// runs out, until entering room 1 puts their own colour back.
func TestAmuletRunsOut(t *testing.T) {
	sc := scenario{
		name: "room 5", room: 5, x: 119, y: 53, carry: []byte{items.Amulet}, frames: 120,
		input: hold(joe.Input{Up: true}),
		expect: expect(func(g *play.Game) bool {
			return g.Room == 1 && g.Amulet == 0 && g.Inventory[0] == items.Empty &&
				g.CreatureColour == 0 && g.Joe.State < joe.Zapped
		}),
	}
	run(t, sc, func(g *play.Game, o *original.Game) {
		o.Poke(0x704A, 8)
		g.Amulet = 8
	})
}
