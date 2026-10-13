package coleco

import (
	"os"
	"testing"
)

func bootROM(t *testing.T) *Machine {
	t.Helper()
	cart, err := os.ReadFile("../../build/montezuma.rom")
	if err != nil {
		t.Skip("build/montezuma.rom missing; run make rom")
	}
	return New(cart)
}

// TestReachesFirstRoom presses 1 on the title screen and expects the game
// to display a pyramid room.
func TestReachesFirstRoom(t *testing.T) {
	m := bootROM(t)
	for f := 0; f < 400; f++ {
		m.Input = Joystick{Key: -1}
		if f >= 160 && f <= 170 {
			m.Input.Key = 1
		}
		if err := m.RunFrame(); err != nil {
			t.Fatal(err)
		}
	}
	if room := m.Peek(0x71A8) / 2; room < 4 {
		t.Errorf("room = %d after selecting level 1, want a pyramid room (>= 4)", room)
	}
	if m.VDP.Reg[1]&0x40 == 0 {
		t.Error("display is blanked")
	}
}
