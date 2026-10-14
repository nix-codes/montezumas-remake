package play_test

import (
	"fmt"
	"testing"

	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/play"
)

// TestGameOver loses the last life walking into a creature with 1,200
// points, waits on GAME OVER, then presses fire: on level 1 the game
// continues with the score back to 0; on level 2 it stays over.
func TestGameOver(t *testing.T) {
	for _, level := range []int{1, 2} {
		sc := scenario{
			name: fmt.Sprintf("level %d", level), room: 6, x: 20, y: 53, frames: 320,
			input: func(f int) joe.Input {
				// Holding a direction with fire doesn't count.
				return joe.Input{Right: f < 60 || f == 250, Fire: f >= 250 && f < 255}
			},
		}
		if level == 1 {
			sc.expect = expect(func(g *play.Game) bool {
				return !g.GameOver && g.Continued && g.Score == 0 && g.Lives == play.StartLives &&
					g.Joe.State < joe.Zapped
			})
		} else {
			sc.expect = expect(func(g *play.Game) bool {
				return g.GameOver && g.Score == 1200 && g.Tiles.T[11][12] == 'G'
			})
		}
		t.Run(sc.name, func(t *testing.T) {
			run(t, sc, func(g *play.Game, o *original.Game) {
				o.Poke(lives, 1)
				o.Poke(level1, byte(level))
				o.Poke(score+1, 0x12)
				if err := o.Call(0xAEFE, 10); err != nil { // redraw the score
					t.Fatal(err)
				}
				g.Level, g.Score = level, 1200
				g.RedrawHUD()
				g.Lives = 0 // the hats stay until the HUD is next drawn

			})
		})
	}
}

// TestRespawn walks into an enemy and follows the respawn: Joe back where
// he came in, the room redrawn over a pause (longer in room 3, which is
// mirrored), a life fewer.
func TestRespawn(t *testing.T) {
	for _, sc := range []scenario{
		{name: "room 6", room: 6, x: 20, y: 53, frames: 200, input: hold(joe.Input{Right: true})},
		{name: "room 3, mirrored", room: 3, x: 124, y: 53, frames: 200, input: hold(joe.Input{Left: true})},
	} {
		in := sc.input
		sc.input = func(f int) joe.Input {
			if f < 60 {
				return in(f)
			}
			return joe.Input{}
		}
		sc.expect = expect(func(g *play.Game) bool {
			return g.Lives == 1 && g.Joe.State < joe.Zapped && g.Joe.X == byte(sc.x)
		})
		t.Run(sc.name, func(t *testing.T) {
			run(t, sc, func(g *play.Game, o *original.Game) {
				o.Poke(lives, 3)
				g.Lives = 2
			})
		})
	}
}
