// Package play is the game: its state and one frame of play, in the
// original's order. cmd/game draws it; the tests run it against the
// original.
package play

import (
	"montezuma-remake/internal/enemy"
	"montezuma-remake/internal/items"
	"montezuma-remake/internal/joe"
	"montezuma-remake/internal/pyramid"
	"montezuma-remake/internal/rom"
	"montezuma-remake/internal/roomdata"
)

// StartLives is how many spare lives a game starts with (the hats in the
// HUD); losing one more ends it.
const StartLives = 5

// Joe lands here in the starting room after sliding down the entrance pole.
const StartX, StartY = 124, 53

// Main-loop task periods ($A8A1): the contact check runs every 2 frames,
// the item task every 4.
const (
	contactPeriod = 2
	itemPeriod    = 4
)

// Rules are the original's tables.
type Rules struct {
	Joe   *joe.Rules
	Enemy *enemy.Rules
	Items *items.Rules
}

// RulesFromROM reads every table from the cartridge.
func RulesFromROM(r *rom.ROM) (*Rules, error) {
	j, err := joe.RulesFromROM(r)
	if err != nil {
		return nil, err
	}
	e, err := enemy.RulesFromROM(r)
	if err != nil {
		return nil, err
	}
	i, err := items.RulesFromROM(r)
	if err != nil {
		return nil, err
	}
	return &Rules{Joe: j, Enemy: e, Items: i}, nil
}

// Game is a game in progress.
type Game struct {
	Rules *Rules
	Rooms []roomdata.Room
	Level int

	Room     int
	Row, Col int // the game's row and column; see internal/pyramid
	Tiles    Screen

	Joe   joe.Joe
	Entry joe.Joe // Joe as he entered the room, to respawn him there
	Lives int
	Score int

	Inventory items.Inventory
	Amulet    int                   // contact checks left of the amulet's protection
	Done      [pyramid.Rooms]uint16 // per room, one bit per contact entry: collected, opened, removed

	Enemies  *enemy.State
	Contacts []byte

	// Main-loop task countdowns: a task runs when its count is 1.
	ContactTimer, ItemTimer int
}

// Screen is the current room's tiles as items change them. Version goes up
// with every change, for redrawing.
type Screen struct {
	T       [24][32]byte
	Version int
}

// Tile implements joe.Tiles.
func (s *Screen) Tile(col, row int) byte { return s.T[row][col] }

// SetTile implements items.Tiles.
func (s *Screen) SetTile(col, row int, t byte) {
	if col < 0 || col >= 32 || row < 0 || row >= 24 || s.T[row][col] == t {
		return
	}
	s.T[row][col] = t
	s.Version++
}

// New starts a game on level (1-3) in room.
func New(rooms []roomdata.Room, rules *Rules, level, room int) *Game {
	g := &Game{Rules: rules, Rooms: rooms, Level: level}
	g.Restart(room)
	return g
}

// Restart starts a new game in room.
func (g *Game) Restart(room int) {
	g.Lives = StartLives
	g.Score = 0
	g.Inventory = items.NewInventory()
	g.Amulet = 0
	g.Done = [pyramid.Rooms]uint16{}
	g.ContactTimer, g.ItemTimer = contactPeriod, itemPeriod
	g.Joe.Place(StartX, StartY)
	g.Enter(room)
}

// Enter switches to room at its own place in the pyramid.
func (g *Game) Enter(room int) {
	g.Row, g.Col = pyramid.Position(room)
	g.show(room)
}

// show switches to room, keeping the current row and column, and remembers
// Joe as he comes in, as the original does for respawning.
func (g *Game) show(room int) {
	g.Room = room
	g.Entry = g.Joe
	g.load()
}

// load sets the room up as the original's loader does: tiles, items and
// doors already dealt with, and the enemies still there.
func (g *Game) load() {
	r := &g.Rooms[g.Room]
	g.Tiles.T = r.Tiles
	g.Tiles.Version++
	g.Contacts = append([]byte(nil), r.Contacts...)
	done := g.Done[g.Room]

	s := &enemy.State{Counter: r.FrameCounter, Rules: g.Rules.Enemy}
	for i := range s.Sprites {
		b := r.SpriteTable[i*4 : i*4+4]
		s.Sprites[i] = &enemy.Sprite{Y: b[0], X: b[1], Pattern: b[2], Colour: b[3]}
	}
	gone := map[int]bool{} // sprite slots of removed enemies
	for i, n := 1, 0; i+1 < len(g.Contacts) && g.Contacts[i+1] != 0xFE; i, n = i+2, n+1 {
		if g.Contacts[i+1] == 0xFF && done&(1<<n) != 0 {
			gone[(int(g.Contacts[i])+4)/4] = true
			g.Contacts[i], g.Contacts[i+1] = 0, 0
		}
	}
	for i := 0; i+1 < len(r.Objects) && r.Objects[i] != 0xFF; i += 2 {
		o := [2]byte{r.Objects[i], r.Objects[i+1]}
		if slot := int(o[0] & 7); gone[slot] {
			s.Sprites[slot].Colour = 0
			continue
		}
		s.Objects = append(s.Objects, o)
	}
	g.Enemies = s
	g.Rules.Items.Restore(g.itemRoom(), done)
}

func (g *Game) itemRoom() *items.Room {
	return &items.Room{Number: g.Room, Contacts: g.Contacts, Tiles: &g.Tiles}
}

// Step runs one frame, in the original's order: the main loop's contact
// and item tasks, then the enemies and Joe.
func (g *Game) Step(in joe.Input) {
	if g.tick(&g.ContactTimer, contactPeriod) {
		g.contactTask()
	}
	if g.tick(&g.ItemTimer, itemPeriod) {
		g.itemTask()
	}

	frozen := g.Joe.Frozen > 0 // the pause while a new room is drawn
	before := g.Joe
	if exit := g.Joe.Step(in, &g.Tiles, g.Rules.Joe); exit != 0 {
		g.changeRoom(exit, before)
	} else if !frozen {
		g.Enemies.Counter++
		g.Enemies.Update(&g.Tiles, g.Joe.Parity, g.Amulet > 0)
	}

	if g.Joe.Respawn() {
		g.Lives--
		if g.Lives < 0 {
			g.Restart(pyramid.Start)
			return
		}
		g.Joe = g.Entry
		g.load()
	}
}

// tick counts a main-loop task down and reports whether it runs ($A5EE).
func (g *Game) tick(count *int, period int) bool {
	run := *count == 1
	if *count--; *count == 0 {
		*count = period
	}
	return run
}

// contactTask is the original's $91E5: the amulet's countdown, then
// whether an enemy touches Joe. With the sword he kills it; without, it
// kills him. Either way it's gone for good.
func (g *Game) contactTask() {
	if g.Joe.State >= joe.Zapped {
		return
	}
	if g.Amulet > 0 {
		if g.Amulet--; g.Amulet > 0 {
			return
		}
	}
	g.Inventory.Remove(items.Amulet)

	slot, entry := g.Enemies.Touching(g.Joe.X, g.Joe.RawY, g.Contacts)
	if slot < 0 {
		return
	}
	g.Done[g.Room] |= 1 << entry
	if g.Inventory.Remove(items.Sword) {
		spr := g.Enemies.Sprites[slot]
		if spr.Colour == 0x0F {
			g.Score += items.PointsSkull
		} else {
			g.Score += items.PointsEnemy
		}
		spr.Colour = 0
		return
	}
	g.Joe.Kill()
}

// itemTask is the original's $8F5F: doors, creatures and pickups.
func (g *Game) itemTask() {
	res := g.Rules.Items.Task(g.itemRoom(), items.Joe{
		X:          g.Joe.X,
		RawY:       g.Joe.RawY,
		FacingLeft: g.Joe.Facing < 0,
		Dead:       g.Joe.State == joe.Dead,
	}, &g.Inventory, g.Amulet > 0)
	g.Score += res.Points
	for _, e := range res.Done {
		g.Done[g.Room] |= 1 << e
	}
	if res.Amulet {
		g.Amulet = items.AmuletTime
	}
	if res.KillJoe {
		g.Joe.Kill()
	}
}

// changeRoom follows Joe out of the room, using the game's row and column
// arithmetic. Where the original would leave the pyramid (or, at the
// bottom, start the next level, which isn't done yet), Joe stays put.
func (g *Game) changeRoom(exit int, before joe.Joe) {
	row, col := g.Row, g.Col
	switch exit {
	case joe.ExitLeft:
		col--
	case joe.ExitRight:
		col++
	case joe.ExitUp:
		row--
	case joe.ExitDown:
		row++
	}
	next := pyramid.Room(row, col)
	// The entrance hall's pole leads to the starting room and back.
	switch {
	case g.Room == pyramid.Entrance && exit == joe.ExitDown:
		next = pyramid.Start
		row, col = pyramid.Position(next)
	case g.Room == pyramid.Start && exit == joe.ExitUp:
		next = pyramid.Entrance
		row, col = pyramid.Position(next)
	}
	if next < 0 {
		g.Joe = before
		g.Joe.DX, g.Joe.DY = 0, 0
		return
	}
	g.Row, g.Col = row, col
	g.show(next)
}
