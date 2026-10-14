package gfx_test

import (
	"bytes"
	"os"
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/gfx"
	"montezuma-remake/internal/rom"
)

const romPath = "../../build/montezuma.rom"

// TestTitleMatchesOriginal compares the title screen with the original's,
// once it's waiting for a level: the screen, its colours, and the
// patterns of every tile on it.
func TestTitleMatchesOriginal(t *testing.T) {
	cart, err := os.ReadFile(romPath)
	if err != nil {
		t.Skip(err)
	}
	r, err := rom.Load(romPath)
	if err != nil {
		t.Fatal(err)
	}
	m := coleco.New(cart)
	for range 30 {
		m.Input = coleco.Joystick{Key: -1}
		if err := m.RunFrame(); err != nil {
			t.Fatal(err)
		}
	}
	v, err := gfx.Title(r)
	if err != nil {
		t.Fatal(err)
	}

	names := m.VDP.NameTable()
	for i, n := range v.Names {
		if names[i] != n {
			t.Fatalf("name table row %d column %d: remake $%02X, original $%02X", i/32, i%32, n, names[i])
		}
	}
	if got, want := v.Colours[:], m.VDP.TileColours(); !bytes.Equal(got, want) {
		t.Errorf("colours:\nremake   % X\noriginal % X", got, want)
	}
	pats := m.VDP.TilePatterns()
	for _, n := range v.Names {
		if got, want := v.TilePatterns[int(n)*8:int(n)*8+8], pats[int(n)*8:int(n)*8+8]; !bytes.Equal(got, want) {
			t.Errorf("tile $%02X: remake % X, original % X", n, got, want)
		}
	}
	if got := m.VDP.Reg[7] & 0x0F; got != gfx.Backdrop {
		t.Errorf("backdrop %d, want %d", got, gfx.Backdrop)
	}
	if t.Failed() || bytes.Count(names, []byte{0}) == len(names) {
		t.Fatal("the original isn't showing the title screen")
	}
}
