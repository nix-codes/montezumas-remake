package enemy_test

import (
	"fmt"
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/enemy"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/rom"
)

// TestKilledByEnemy jumps onto the pole in room 12, where an enemy reaches
// Joe at the bottom, and runs Joe and the enemies in both games, comparing
// them every frame through his death. The original checks for contact in
// its main loop ($91E5), which on the emulator gets round to it every other
// frame, using positions from the end of the previous frame; the remake
// checks on the frames the original did.
func TestKilledByEnemy(t *testing.T) {
	er := rules(t)
	r, err := rom.Load(romPath)
	if err != nil {
		t.Skip(err)
	}
	jr, err := joe.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	g, err := original.Start(romPath, 1)
	if err != nil {
		t.Skip(err)
	}
	if err := g.LoadRoom(12); err != nil {
		t.Fatal(err)
	}
	g.PlaceJoe(12, 53)

	var j joe.Joe
	j.Place(12, 53)
	j.Parity = g.Peek(0x70AB)
	j.FireLatch = g.Peek(0x7075)
	s := stateFrom(g, er)
	contacts := g.Until(original.ContactList, 0xFE, 32)

	checks := 0
	g.Trap = func(pc uint16) bool {
		if pc == 0x91E5 {
			checks++
		}
		return false
	}
	died := -1
	for f := 0; f < 100; f++ {
		before := checks
		in := joe.Input{Right: f < 30, Fire: f == 2}
		tiles := make([]byte, 768)
		copy(tiles, g.VDP.NameTable())
		if err := g.Step(coleco.Joystick{Right: in.Right, FireLeft: in.Fire}); err != nil {
			t.Fatal(err)
		}

		// The check sees where everyone was at the end of the last frame,
		// and takes effect before Joe moves.
		if checks > before && j.State < joe.Zapped {
			if slot, _ := s.Touching(j.X, j.RawY, contacts); slot >= 0 {
				j.Kill()
			}
		}
		j.Step(in, frozen(tiles), jr)
		s.Counter++
		s.Update(frozen(tiles), j.Parity, false)

		o := g.Joe()
		got := fmt.Sprintf("x=%d y=%d state=%d", j.X, j.ScreenY(), j.State)
		want := fmt.Sprintf("x=%d y=%d state=%d", o.X, o.Y, o.State)
		if got != want {
			t.Fatalf("frame %d: Joe: remake %s, original %s", f, got, want)
		}
		for _, ob := range s.Objects {
			slot := int(ob[0] & 7)
			b := g.Bytes(uint16(original.SpriteTable+4*slot), 4)
			if want := (enemy.Sprite{Y: b[0], X: b[1], Pattern: b[2], Colour: b[3]}); *s.Sprites[slot] != want {
				t.Fatalf("frame %d slot %d: remake %s, original %s", f, slot, show(*s.Sprites[slot]), show(want))
			}
		}
		if died < 0 && o.State == joe.Zapped {
			died = f
		}
	}
	if died < 0 {
		t.Fatal("Joe never died; the scenario no longer reaches the enemy")
	}
	t.Logf("killed on frame %d in both games", died)
}
