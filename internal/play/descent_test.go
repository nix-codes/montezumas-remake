package play_test

import (
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/play"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

// TestDescent starts a game in both, from the moment the level begins:
// the game walks Joe down the entrance hall's pole, across it and down the
// rope into the starting room, ignoring the joystick, which is held left
// and up throughout. The games are compared every frame until a while after
// he has landed and the player has control.
func TestDescent(t *testing.T) {
	r, err := rom.Load(romPath)
	if err != nil {
		t.Skip(err)
	}
	rules, err := play.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	rooms, err := roomdata.Load(roomsPath)
	if err != nil {
		t.Skip(err)
	}
	o, err := original.Boot(romPath, 1)
	if err != nil {
		t.Skip(err)
	}
	g := play.New(rooms, rules, 1, pyramid.Entrance)
	sync(g, o)
	// Until the barriers first blink, the original leaves colour entries
	// 28 and 29 as the title screen had them. Neither room has barriers or
	// disappearing floors, so give it the remake's.
	colours := int(o.VDP.Reg[3]) << 6
	c := g.Colours()
	o.VDP.VRAM[colours+28], o.VDP.VRAM[colours+29] = c[28], c[29]

	landed := -1
	for f := 0; f < 400; f++ {
		in := joe.Input{Left: true, Up: true}
		if err := o.Step(coleco.Joystick{Left: in.Left, Up: in.Up}); err != nil {
			t.Fatal(err)
		}
		frozen := g.Joe.Frozen
		g.Step(in)
		if msg := compare(g, o, frozen == 0 && g.Joe.Frozen == 0); msg != "" {
			t.Fatalf("frame %d (room %d): %s", f, g.Room, msg)
		}
		if descent := o.Peek(0x705F)&0x04 != 0; descent != g.Descent {
			t.Fatalf("frame %d: descent: remake %v, original %v", f, g.Descent, descent)
		}
		if !g.Descent && landed < 0 {
			landed = f
		}
		if landed >= 0 && f > landed+30 {
			break
		}
	}
	if landed < 0 || g.Room != pyramid.Start || g.Joe.X >= play.StartX {
		t.Errorf("Joe didn't land in the starting room and walk left: room %d, x %d", g.Room, g.Joe.X)
	}
}
