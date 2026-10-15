package roomdata

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"
)

func testRoom() Room {
	r := Room{
		Number:         7,
		Row:            1,
		Column:         3,
		Exits:          Exits{Left: 6, Right: -1, Up: -1, Down: 15, LeftRows: []int{20}},
		TilePatterns:   make([]byte, 256*8),
		TileColours:    make([]byte, 32),
		SpritePatterns: make([]byte, 256*8),
		Backdrop:       1,
		Objects:        []byte{0x12, 0x34, 0xFF},
		Contacts:       []byte{0xFE},
		SpriteTable:    make([]byte, 32),
		FrameCounter:   9,
		SyncDelay:      2,
		Bare:           new([HUDRows][32]byte),
	}
	for i := range r.TilePatterns {
		r.TilePatterns[i] = byte(i)
		r.SpritePatterns[i] = byte(i * 7)
	}
	for y := range r.Tiles {
		for x := range r.Tiles[y] {
			r.Tiles[y][x] = byte(y*32 + x)
		}
	}
	r.Bare[4][31] = 0x90
	r.SpriteTable[5] = 0xAB
	return r
}

func TestRoundTrip(t *testing.T) {
	want := testRoom()
	b, err := json.Marshal(want)
	if err != nil {
		t.Fatal(err)
	}
	var got Room
	if err := json.Unmarshal(b, &got); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("round trip changed the room:\n got %+v\nwant %+v", got, want)
	}

	// The tile grid is stored as one hex row per screen row.
	var j room
	if err := json.Unmarshal(b, &j); err != nil {
		t.Fatal(err)
	}
	if len(j.Tiles) != 24 || j.Tiles[1][:4] != "2021" || len(j.TilePatterns) != 256 || len(j.SpritePatterns) != 64 {
		t.Errorf("unexpected layout: %d tile rows starting %q, %d tile patterns, %d sprite patterns",
			len(j.Tiles), j.Tiles[1], len(j.TilePatterns), len(j.SpritePatterns))
	}

	// A room without Bare leaves it out.
	r := testRoom()
	r.Bare = nil
	b, _ = json.Marshal(r)
	if strings.Contains(string(b), `"bare"`) {
		t.Errorf("bare written for a room without it")
	}
}

func TestBadRows(t *testing.T) {
	b, _ := json.Marshal(testRoom())
	for _, c := range []struct{ name, from, to string }{
		{"short tile row", `"0001`, `"01`},
		{"not hex", `"0001`, `"zz01`},
	} {
		bad := strings.Replace(string(b), c.from, c.to, 1)
		var r Room
		if err := json.Unmarshal([]byte(bad), &r); err == nil {
			t.Errorf("%s: no error", c.name)
		}
	}
}
