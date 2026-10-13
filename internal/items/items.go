// Package items is the original's items, doors and static creatures
// (main-loop task at $8F5F): picking things up into the inventory, opening
// doors with keys, and the tile creatures that kill Joe on touch.
//
// Items, doors and creatures are tiles, not sprites. A room's contact list
// ($72C1) gives the name-table position of each one's top-left tile; a
// per-room bitmap ($70C0, one bit per contact entry) remembers which have
// been collected, opened or removed, for the rest of the game.
package items

import (
	"fmt"

	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/rom"
)

// Item codes, as kept in the inventory ($71B2). The code is also the
// offset of the item's four HUD tiles in the table at $9FD2.
const (
	Empty     = 0xFF
	Jewel     = 0x44 // scored, never kept
	Torch     = 0x53
	KeyGold   = 0x58
	KeyBlue   = 0x5D
	KeyRed    = 0x62
	Amulet    = 0x8C
	Sword     = 0x91
	blankCode = 0x0B // four blank tiles
)

// InventorySize is the inventory's size in the original ($71B2-$71B7).
// The last slot is always empty: the game stops adding items when the
// first empty slot is the last one ($A575), so Joe carries at most
// Capacity items.
const (
	InventorySize = 6
	Capacity      = InventorySize - 1
)

// AmuletTime is how many contact checks (one every two frames) the amulet
// protects Joe for.
const AmuletTime = 0xA0

// Points, as the original adds them (BCD in the game, plain numbers here).
const (
	PointsKey     = 50
	PointsSword   = 50
	PointsTorch   = 3000
	PointsJewel   = 1000
	PointsAmulet  = 100
	PointsDoor    = 300
	PointsSkull   = 2000 // white enemies killed with the sword
	PointsEnemy   = 3000 // other enemies killed with the sword
	pointsDefault = 50
)

// Rules holds the item tables from the ROM.
type Rules struct {
	pickups   map[byte]pickup // room tile -> item
	creatures map[byte]int    // creature tile -> its corner (0-3)
	icons     map[byte][4]byte
	doors     map[byte]door // a door's bottom tile -> door
}

// pickup is one tile of an item in a room: which item, and which corner of
// its 2x2 block (0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right).
type pickup struct {
	code   byte
	points int
	corner int
}

// door is a kind of door: the key that opens it and the tiles it's drawn
// with once open (two columns: top tiles, then three rows of the rest).
type door struct {
	key      byte
	openTop  [2]byte
	openRest [2]byte
}

// RulesFromROM reads the item tables from the cartridge.
func RulesFromROM(r *rom.ROM) (*Rules, error) {
	slice := func(addr uint16, n int) ([]byte, error) { return r.Slice(addr, n) }
	keys, err := slice(0x9430, 12)
	if err != nil {
		return nil, err
	}
	others, err := slice(0x9418, 16)
	if err != nil {
		return nil, err
	}
	creatures, err := slice(0x9428, 8)
	if err != nil {
		return nil, err
	}
	rules := &Rules{
		pickups:   map[byte]pickup{},
		creatures: map[byte]int{},
		icons:     map[byte][4]byte{},
		doors:     map[byte]door{},
	}
	// The lists are searched with CPIR; the count left over gives the
	// tile's corner (its low two bits) and, for $9418, the kind of item.
	for i, t := range keys {
		left := len(keys) - 1 - i
		code := map[byte]byte{0x78: KeyGold, 0x68: KeyBlue, 0x70: KeyRed}[t&0xF8]
		rules.pickups[t] = pickup{code: code, points: PointsKey, corner: left & 3}
	}
	for i, t := range others {
		left := len(others) - 1 - i
		p := pickup{corner: left & 3}
		switch {
		case left < 4:
			p.code, p.points = Amulet, PointsAmulet
		case left < 8:
			p.code, p.points = Jewel, PointsJewel
		case left < 12:
			p.code, p.points = Torch, PointsTorch
		default:
			p.code, p.points = Sword, PointsSword
		}
		rules.pickups[t] = p
	}
	for i, t := range creatures {
		rules.creatures[t] = (len(creatures) - 1 - i) & 3
	}
	for _, code := range []byte{Jewel, Torch, KeyGold, KeyBlue, KeyRed, Amulet, Sword, blankCode} {
		b, err := slice(0x9FD2+uint16(code), 4)
		if err != nil {
			return nil, err
		}
		rules.icons[code] = [4]byte(b)
	}
	// Doors ($8F81): bottom tile -> key, and the open-door drawing at
	// $9FD2 + the code the game passes ($A3F1).
	for _, d := range []struct {
		bottom, key, drawing byte
	}{{0x9C, KeyBlue, 0x70}, {0xB7, KeyGold, 0x69}, {0xC7, KeyRed, 0x77}} {
		b, err := slice(0x9FD2+uint16(d.drawing), 4)
		if err != nil {
			return nil, err
		}
		rules.doors[d.bottom] = door{key: d.key, openTop: [2]byte{b[0], b[1]}, openRest: [2]byte{b[2], b[3]}}
	}
	if len(rules.pickups) != 28 {
		return nil, fmt.Errorf("item tables: %d pickup tiles, want 28", len(rules.pickups))
	}
	return rules, nil
}

// Icon returns the four tiles (top row, then bottom row) that show item
// code in the HUD.
func (r *Rules) Icon(code byte) [4]byte { return r.icons[code] }

// Tiles is a room's screen that items can change.
type Tiles interface {
	Tile(col, row int) byte
	SetTile(col, row int, t byte)
}

// Room is the item side of the current room.
type Room struct {
	Number   int
	Contacts []byte // $72C1: entries of the room's contact list
	Tiles    Tiles
}

// entries walks the contact list's item and door entries (not enemies,
// not removed ones), calling f with each entry's index and name-table
// position.
func (r *Room) entries(f func(i, pos int) bool) {
	for i, n := 1, 0; i+1 < len(r.Contacts); i, n = i+2, n+1 {
		lo, hi := r.Contacts[i], r.Contacts[i+1]
		if hi == 0xFE {
			return
		}
		if hi == 0xFF || lo == 0 && hi == 0 {
			continue
		}
		if !f(n, int(hi)<<8|int(lo)) {
			return
		}
	}
}

// entryAt returns the contact entry at name-table position pos, or -1.
func (r *Room) entryAt(pos int) int {
	found := -1
	r.entries(func(i, p int) bool {
		if p == pos {
			found = i
			return false
		}
		return true
	})
	return found
}

// remove clears contact entry i, as the game does once it's done with it.
func (r *Room) remove(i int) {
	r.Contacts[1+2*i] = 0
	r.Contacts[2+2*i] = 0
}

// Inventory is what Joe carries ($71B2): item codes, Empty when unused.
type Inventory [InventorySize]byte

// NewInventory returns an empty inventory.
func NewInventory() Inventory {
	var inv Inventory
	for i := range inv {
		inv[i] = Empty
	}
	return inv
}

// Has reports whether Joe carries code.
func (inv *Inventory) Has(code byte) bool {
	for _, c := range inv {
		if c == code {
			return true
		}
	}
	return false
}

// Remove takes the first code out, moving the rest up ($909C).
func (inv *Inventory) Remove(code byte) bool {
	for i, c := range inv {
		if c == code {
			copy(inv[i:], inv[i+1:])
			inv[len(inv)-1] = Empty
			return true
		}
	}
	return false
}

// add puts code in the first free slot; it fails when Joe already carries
// Capacity items ($A56C).
func (inv *Inventory) add(code byte) bool {
	if inv.full() {
		return false
	}
	for i, c := range inv {
		if c == Empty {
			inv[i] = code
			return true
		}
	}
	return false
}

// full reports whether Joe carries as many items as he can.
func (inv *Inventory) full() bool {
	for _, c := range inv[:Capacity] {
		if c == Empty {
			return false
		}
	}
	return true
}

// Restore redraws a room's collected items (blank) and opened doors (open)
// as the room loader does, and clears their contact entries. done holds
// one bit per contact entry.
func (r *Rules) Restore(room *Room, done uint16) {
	var gone []int
	room.entries(func(i, pos int) bool {
		if done&(1<<i) == 0 {
			return true
		}
		col, row := pos%32, pos/32
		if d, ok := r.doors[joe.TileAt(room.Tiles, col, row+3)]; ok {
			r.drawOpenDoor(room, d, col, row)
		} else {
			r.drawIcon(room, blankCode, col, row)
		}
		gone = append(gone, i)
		return true
	})
	for _, i := range gone {
		room.remove(i)
	}
}

func (r *Rules) drawIcon(room *Room, code byte, col, row int) {
	t := r.icons[code]
	room.Tiles.SetTile(col, row, t[0])
	room.Tiles.SetTile(col+1, row, t[1])
	room.Tiles.SetTile(col, row+1, t[2])
	room.Tiles.SetTile(col+1, row+1, t[3])
}

func (r *Rules) drawOpenDoor(room *Room, d door, col, row int) {
	room.Tiles.SetTile(col, row, d.openTop[0])
	room.Tiles.SetTile(col+1, row, d.openTop[1])
	for y := row + 1; y < row+4; y++ {
		room.Tiles.SetTile(col, y, d.openRest[0])
		room.Tiles.SetTile(col+1, y, d.openRest[1])
	}
}

// Joe is what the item task needs to know about Panama Joe.
type Joe struct {
	X, RawY    byte
	FacingLeft bool
	Dead       bool // fell to his death (state 9): the task does nothing
}

// Result is what one run of the item task did.
type Result struct {
	Points   int
	KillJoe  bool  // he touched a creature without the amulet
	Done     []int // contact entries now collected, opened or removed
	Amulet   bool  // he picked up the amulet: start its timer
	Picked   byte  // item picked up, or 0
	Opened   bool  // he opened a door
	Creature bool  // the creature that killed him (marked in Done)
}

// Task runs the main-loop task at $8F5F (every 4 frames): open a door Joe
// faces if he has its key, else die on a creature, else pick up an item.
// It changes room's tiles and inv.
func (r *Rules) Task(room *Room, j Joe, inv *Inventory, amulet bool) Result {
	var res Result
	if j.Dead {
		return res
	}
	// The same tiles Joe's movement reads: his legs sprite is 3 lines
	// below his body.
	col, row := joe.TilesOrigin(j.X, j.RawY+3)
	tile := func(c, r int) byte { return joe.TileAt(room.Tiles, c, r) }

	// The tile beside him at body height, on the side he faces.
	side := col + 2
	if j.FacingLeft {
		side = col
	}
	if d, ok := r.doors[tile(side, row)]; ok && inv.Has(d.key) {
		inv.Remove(d.key)
		top := row - 3
		if e := room.entryAt(top*32 + side); e >= 0 {
			res.Done = append(res.Done, e)
		}
		r.drawOpenDoor(room, d, side, top)
		res.Points, res.Opened = PointsDoor, true
		return res
	}
	// The tile at his body, in the middle.
	mid := col + 1
	t := tile(mid, row)
	if corner, ok := r.creatures[t]; ok {
		if amulet {
			return res
		}
		tc, tr := mid-corner&1, row-corner>>1
		if e := room.entryAt(tr*32 + tc); e >= 0 {
			res.Done = append(res.Done, e)
		}
		res.KillJoe, res.Creature = true, true
		return res
	}
	p, ok := r.pickups[t]
	if !ok || inv.full() {
		return res
	}
	if p.code != Jewel {
		inv.add(p.code)
	}
	tc, tr := mid-p.corner&1, row-p.corner>>1
	if e := room.entryAt(tr*32 + tc); e >= 0 {
		res.Done = append(res.Done, e)
	}
	r.drawIcon(room, blankCode, tc, tr)
	res.Points, res.Picked, res.Amulet = p.points, p.code, p.code == Amulet
	return res
}
