package play_test

import (
	"fmt"
	"testing"

	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/play"
)

// TestFallIntoBarrier jumps off the platform in room 12 onto the floor
// below, far enough to die, with Joe's body in the barrier. The game's zap
// check ($8DA5) only spares Joe if he's already zapped, so lying dead from
// the fall he's zapped too as the barrier lights, the same frame or later,
// and loses a second life. On his last life that takes the count past 0,
// and he plays on with 255.
func TestFallIntoBarrier(t *testing.T) {
	for _, tc := range []struct {
		name  string
		x     int  // where Joe stands on the conveyor
		wait  int  // frames before he jumps
		reset bool // run the barrier timer out first, to start a new cycle
		lives byte // spare lives
		want  byte
	}{
		{"barrier lit as he lands", 150, 0, false, play.StartLives, play.StartLives - 2},
		{"barrier lights after he lands", 156, 8, true, play.StartLives, play.StartLives - 2},
		{"last life: 255 lives", 150, 0, false, 0, 0xFE},
	} {
		sc := scenario{
			name: tc.name, room: 12, x: tc.x, y: 101, frames: 260,
			input: func(f int) joe.Input {
				jump := f >= tc.wait && f < tc.wait+3
				return joe.Input{Right: jump, Fire: jump}
			},
			expect: func(g *play.Game) string {
				if !g.GameOver && g.Lives == tc.want && g.Joe.State < joe.Zapped {
					return ""
				}
				return fmt.Sprintf("game over %v, lives %d (want %d), Joe state %d at x %d",
					g.GameOver, g.Lives, tc.want, g.Joe.State, g.Joe.X)
			},
		}
		t.Run(tc.name, func(t *testing.T) {
			run(t, sc, func(g *play.Game, o *original.Game) {
				if g.BarrierTimer != 0x41 || !g.BarriersOff {
					t.Fatalf("barrier timer %#x, off %v: the jump is timed for $41, off", g.BarrierTimer, g.BarriersOff)
				}
				if tc.reset {
					o.Poke(barrierTimer, 1)
					g.BarrierTimer = 1
				}
				o.Poke(lives, tc.lives+1)
				g.Lives = tc.lives
			})
		})
	}
}
