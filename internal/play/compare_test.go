package play_test

import (
	"fmt"
	"testing"

	"montezuma-remake/internal/coleco"
	"montezuma-remake/internal/items"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/original"
	"montezuma-remake/internal/play"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

const (
	romPath   = "../../build/montezuma.rom"
	roomsPath = "../../assets/rooms/level1/rooms.json"
)

// Original RAM.
const (
	inventory    = 0x71B2
	score        = 0x7017 // 3 BCD bytes
	contactTimer = 0x7073
	itemTimer    = 0x7012
	parity       = 0x70AB
	fireLatch    = 0x7075
)

type scenario struct {
	name   string
	room   int
	x, y   int
	carry  []byte // inventory to start with
	frames int
	input  func(f int) joe.Input
	// expect checks the scenario did what it's meant to, so a match with
	// the original isn't just both games doing nothing.
	expect func(g *play.Game) string
}

func hold(in joe.Input) func(int) joe.Input { return func(int) joe.Input { return in } }

var scenarios = []scenario{
	{"pick up the key", 2, 37, 101, nil, 40, func(f int) joe.Input { return joe.Input{Fire: f == 1} },
		expect(func(g *play.Game) bool { return g.Inventory[0] == items.KeyRed && g.Score == 50 })},
	{"open the door with the key", 2, 44, 53, []byte{items.KeyRed}, 14, hold(joe.Input{Left: true}),
		expect(func(g *play.Game) bool { return g.Inventory[0] == items.Empty && g.Score == 300 && g.Done[2]&1 != 0 })},
	{"no key: the door stays shut", 2, 44, 53, nil, 14, hold(joe.Input{Left: true}),
		expect(func(g *play.Game) bool { return g.Score == 0 && g.Tiles.T[8][3] == 0xC7 })},
	{"kill the skull with the sword", 2, 120, 141, []byte{items.Sword}, 200, hold(joe.Input{}),
		expect(func(g *play.Game) bool {
			return g.Inventory[0] == items.Empty && g.Score == 2000 && g.Joe.State < joe.Zapped
		})},
	{"walk into a creature", 6, 20, 53, nil, 60, hold(joe.Input{Right: true}),
		expect(func(g *play.Game) bool { return g.Joe.State == joe.Zapped && g.Done[6] != 0 })},
	{"amulet, then through a creature", 1, 196, 53, nil, 90,
		func(f int) joe.Input { return joe.Input{Fire: f == 1, Left: f >= 30} },
		expect(func(g *play.Game) bool {
			return g.Inventory[0] == items.Amulet && g.Score == 100 && g.Joe.State < joe.Zapped && g.Joe.X < 150
		})},
	{"pick up a jewel", 3, 84, 93, nil, 30, func(f int) joe.Input { return joe.Input{Fire: f == 1} },
		expect(func(g *play.Game) bool { return g.Inventory[0] == items.Empty && g.Score == 1000 })},
	{"pick up the torch", 31, 116, 53, nil, 30, func(f int) joe.Input { return joe.Input{Fire: f == 1} },
		expect(func(g *play.Game) bool { return g.Inventory[0] == items.Torch && g.Score == 3000 })},
	{"inventory full: the key stays", 2, 37, 101,
		[]byte{items.Sword, items.Sword, items.Sword, items.Sword, items.Sword}, 40,
		func(f int) joe.Input { return joe.Input{Fire: f == 1} },
		expect(func(g *play.Game) bool { return g.Score == 0 && g.Tiles.T[11][5] == 0x70 })},
}

func expect(ok func(g *play.Game) bool) func(g *play.Game) string {
	return func(g *play.Game) string {
		if ok(g) {
			return ""
		}
		return fmt.Sprintf("didn't happen: inventory % X, score %d, Joe state %d, done %016b",
			g.Inventory[:], g.Score, g.Joe.State, g.Done[g.Room])
	}
}

func TestMatchesOriginal(t *testing.T) {
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
	for _, sc := range scenarios {
		t.Run(sc.name, func(t *testing.T) {
			o, err := original.Start(romPath, 1)
			if err != nil {
				t.Skip(err)
			}
			if err := o.LoadRoom(sc.room); err != nil {
				t.Fatal(err)
			}
			o.PlaceJoe(sc.x, sc.y)
			for i, c := range sc.carry {
				o.Poke(inventory+uint16(i), c)
			}
			if len(sc.carry) > 0 {
				if err := o.Call(0xA548, 10); err != nil { // redraw the HUD's inventory
					t.Fatal(err)
				}
			}
			// Let the original finish setting the room up: its main loop
			// waits a few frames after a room loads.
			for f := 0; f < 10; f++ {
				if err := o.Step(coleco.Joystick{}); err != nil {
					t.Fatal(err)
				}
			}

			g := play.New(rooms, rules, 1, sc.room)
			g.Joe.Place(sc.x, sc.y)
			g.Entry = g.Joe
			for i, c := range sc.carry {
				g.Inventory[i] = c
			}
			sync(g, o)

			for f := 0; f < sc.frames; f++ {
				in := sc.input(f)
				if err := o.Step(coleco.Joystick{Up: in.Up, Down: in.Down, Left: in.Left, Right: in.Right, FireLeft: in.Fire}); err != nil {
					t.Fatal(err)
				}
				g.Step(in)
				if msg := compare(g, o); msg != "" {
					t.Fatalf("frame %d: %s", f, msg)
				}
			}
			if msg := sc.expect(g); msg != "" {
				t.Error(msg)
			}
		})
	}
}

// sync copies the original's frame counters, which depend on how long it
// has been running, and its enemies (which moved while it settled) into
// the remake.
func sync(g *play.Game, o *original.Game) {
	g.Enemies.Objects = nil
	for a := uint16(original.ObjectList); o.Peek(a) != 0xFF; a += 2 {
		g.Enemies.Objects = append(g.Enemies.Objects, [2]byte{o.Peek(a), o.Peek(a + 1)})
	}
	g.Joe.Parity = o.Peek(parity)
	g.Joe.FireLatch = o.Peek(fireLatch)
	g.ContactTimer = int(o.Peek(contactTimer))
	g.ItemTimer = int(o.Peek(itemTimer))
	g.Enemies.Counter = o.Peek(original.FrameCounter)
	for i := range g.Enemies.Sprites {
		b := o.Bytes(uint16(original.SpriteTable+4*i), 4)
		*g.Enemies.Sprites[i] = struct{ Y, X, Pattern, Colour byte }{b[0], b[1], b[2], b[3]}
	}
}

func compare(g *play.Game, o *original.Game) string {
	j := o.Joe()
	if got, want := fmt.Sprintf("x=%d y=%d state=%d", g.Joe.X, g.Joe.ScreenY(), g.Joe.State),
		fmt.Sprintf("x=%d y=%d state=%d", j.X, j.Y, j.State); got != want {
		return fmt.Sprintf("Joe: remake %s, original %s", got, want)
	}
	if got, want := fmt.Sprintf("% X", g.Inventory[:]), fmt.Sprintf("% X", o.Bytes(inventory, 6)); got != want {
		return fmt.Sprintf("inventory: remake %s, original %s", got, want)
	}
	if got, want := g.Score, bcd(o.Bytes(score, 3)); got != want {
		return fmt.Sprintf("score: remake %d, original %d", got, want)
	}
	screen := g.Display()
	names := o.VDP.NameTable()
	for i, want := range names {
		if got := screen[i/32][i%32]; got != want {
			return fmt.Sprintf("tile at row %d col %d: remake %02X, original %02X", i/32, i%32, got, want)
		}
	}
	for _, ob := range g.Enemies.Objects {
		slot := int(ob[0] & 7)
		b := o.Bytes(uint16(original.SpriteTable+4*slot), 4)
		s := g.Enemies.Sprites[slot]
		if s.Y != b[0] || s.X != b[1] || s.Pattern != b[2] || s.Colour != b[3] {
			return fmt.Sprintf("enemy slot %d: remake % X, original % X", slot, []byte{s.Y, s.X, s.Pattern, s.Colour}, b)
		}
	}
	return ""
}

func bcd(b []byte) int {
	n := 0
	for _, x := range b {
		n = n*100 + int(x>>4)*10 + int(x&0x0F)
	}
	return n
}

// TestRevisit marks every item, door and enemy of a room as dealt with, as
// the room bitmap ($70C0) records them, and checks the room then loads the
// same in both games: items gone, doors open, enemies removed.
func TestRevisit(t *testing.T) {
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
	for _, room := range []int{1, 2, 5, 9, 12, 20, 22, 25, 64} {
		o, err := original.Start(romPath, 1)
		if err != nil {
			t.Skip(err)
		}
		o.Poke(uint16(0x70C0+2*room), 0xFF)
		o.Poke(uint16(0x70C1+2*room), 0xFF)
		if err := o.LoadRoom(room); err != nil {
			t.Fatal(err)
		}
		g := play.New(rooms, rules, 1, 2)
		g.Done[room] = 0xFFFF
		g.Enter(room)

		names := o.VDP.NameTable()
		for i := 5 * 32; i < len(names); i++ {
			if got, want := g.Tiles.T[i/32][i%32], names[i]; got != want {
				t.Errorf("room %d row %d col %d: remake %02X, original %02X", room, i/32, i%32, got, want)
				break
			}
		}
		var objects []byte
		for _, ob := range g.Enemies.Objects {
			objects = append(objects, ob[0]&7)
		}
		var want []byte
		for a := uint16(original.ObjectList); o.Peek(a) != 0xFF; a += 2 {
			want = append(want, o.Peek(a)&7)
		}
		if len(objects) != len(want) {
			t.Errorf("room %d: remake keeps enemies in slots %v, original %v", room, objects, want)
		}
	}
}

// TestColours checks each room's colours, lit or dark, against the
// original's room-entry colour routine: rooms from every row, on levels 1
// and 3 (deeper rows are dark on harder levels), with and without the
// torch.
func TestColours(t *testing.T) {
	r, err := rom.Load(romPath)
	if err != nil {
		t.Skip(err)
	}
	rules, err := play.RulesFromROM(r)
	if err != nil {
		t.Fatal(err)
	}
	dark := 0
	for _, level := range []int{1, 3} {
		rooms, err := roomdata.Load(fmt.Sprintf("../../assets/rooms/level%d/rooms.json", level))
		if err != nil {
			t.Skip(err)
		}
		for _, room := range []int{0, 2, 6, 12, 20, 30, 50, 60, 70, 85, 90, 99} {
			for _, torch := range []bool{false, true} {
				o, err := original.Start(romPath, level)
				if err != nil {
					t.Skip(err)
				}
				if err := o.LoadRoom(room); err != nil {
					t.Fatal(err)
				}
				if torch {
					o.Poke(inventory, items.Torch)
				}
				if err := o.SetRoomColours(false); err != nil {
					t.Fatal(err)
				}
				g := play.New(rooms, rules, level, room)
				if torch {
					g.Inventory[0] = items.Torch
				}
				if g.Dark() {
					dark++
				}
				got, want := g.Colours(), o.VDP.TileColours()
				if fmt.Sprintf("% X", got[:]) != fmt.Sprintf("% X", want) {
					t.Errorf("level %d room %d torch %v: remake % X, original % X", level, room, torch, got[:], want)
				}
			}
		}
	}
	if dark == 0 {
		t.Error("no dark rooms were tested")
	}
}
