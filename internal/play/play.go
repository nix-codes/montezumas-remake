// Package play is the game: its state and one frame of play, in the
// original's order. cmd/game draws it; the tests run it against the
// original.
package play

import (
	"montezuma-remake/internal/enemy"
	"montezuma-remake/internal/gfx"
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

// Rules are the original's tables, its animated tile patterns, and the ROM
// itself, which the treasure room reads for random numbers.
type Rules struct {
	Joe   *joe.Rules
	Enemy *enemy.Rules
	Items *items.Rules
	Anim  *gfx.Animation
	ROM   *rom.ROM
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
	a, err := gfx.NewAnimation(r)
	if err != nil {
		return nil, err
	}
	return &Rules{Joe: j, Enemy: e, Items: i, Anim: a, ROM: r}, nil
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

	// The treasure room ($705F bit 5) and its timer ($70AC), and the
	// pointer it reads random numbers from ($7047), which moves every
	// frame.
	Treasure      bool
	TreasureTimer int
	Random        uint16

	setupPending bool // draw a new treasure screen on the next frame
	syncWait     int  // the last frames of Joe's pause, waiting out a mirrored room's sync delay
	// TreasureScreens counts treasure screens drawn. (The original takes
	// two frames to draw one; the tests skip comparing that frame.)
	TreasureScreens int

	// LevelRooms, if set, gives the rooms for each level, for when a new
	// level starts.
	LevelRooms func(level int) []roomdata.Room

	// Main-loop task countdowns: a task runs when its count is 1.
	ContactTimer, ItemTimer int

	// Tile animation; these run on from boot, never reset. The frame
	// interrupt steps through the pattern tables ($7011: 1-3 and 0, bit 7
	// set after a step until the item task clears it); the barrier and
	// disappearing floor patterns follow a frame counter ($7096, 3 down to
	// 0) the contact task steps every other run ($7098), as it stood at
	// the last table step. The barrier task ($A8D6) counts BarrierTimer
	// ($70A8) down from $60 and blinks the barriers and floors.
	AnimStep     byte
	ChainFrame   byte
	ChainToggle  byte
	ChainShown   byte
	BarrierTimer byte
	BarriersOff  bool // $7000 bit 5: hidden and harmless
	FloorsGone   bool // $7000 bit 6
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
	g.Treasure = false
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

// Teleport enters room for testing, standing Joe on the floor spot
// farthest from its enemies (see SafeSpot), where he also respawns. With
// no such spot, he keeps his place on screen.
func (g *Game) Teleport(room int) {
	g.Joe.Place(int(g.Joe.X), g.Joe.ScreenY())
	g.Enter(room)
	if x, y, ok := g.SafeSpot(); ok {
		g.Joe.Place(x, y)
		g.Entry = g.Joe
	}
}

// SafeSpot finds where Joe can stand in the current room, as far as
// possible from every enemy, preferring floors the enemies aren't on: on
// three tiles of plain floor (no edge, conveyor, disappearing floor or
// fire) under three empty rows, or failing that on any floor under his
// feet with two empty rows above. It returns his position for Place.
func (g *Game) SafeSpot() (x, y int, ok bool) {
	if x, y, ok = g.safeSpot(true); !ok {
		x, y, ok = g.safeSpot(false)
	}
	return x, y, ok
}

func (g *Game) safeSpot(strict bool) (x, y int, ok bool) {
	r := g.Rules.Joe
	plain := func(t byte) bool {
		if !contains(r.Floors, t) {
			return false
		}
		return !strict || !contains(r.Conveyors, t)
	}
	width, height := 1, 3
	if !strict {
		width, height = 0, 2
	}
	best := -1
	for row := 8; row < 24; row++ {
		// Columns 1 and 30 are past where Joe leaves the room.
		for col := 2; col < 30; col++ {
			fits := true
			for c := col - width; c <= col+width && fits; c++ {
				fits = plain(g.Tiles.T[row][c])
				for above := row - height; above < row && fits; above++ {
					fits = g.Tiles.T[above][c] == 0
				}
			}
			if !fits {
				continue
			}
			// Joe's body sprite stands 19 lines above the floor.
			px, py := col*8-5, row*8-19
			dist := 1 << 20
			for _, o := range g.Enemies.Objects {
				s := g.Enemies.Sprites[o[0]&7]
				// An enemy on another floor takes much longer to reach
				// him than one on his.
				dx, dy := px-int(s.X), 4*(py-int(s.Y)-1)
				dist = min(dist, dx*dx+dy*dy)
			}
			if dist > best {
				best, x, y, ok = dist, px, py, true
			}
		}
	}
	return x, y, ok
}

func contains(list []byte, t byte) bool {
	for _, b := range list {
		if b == t {
			return true
		}
	}
	return false
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
	g.RedrawHUD()
}

func (g *Game) itemRoom() *items.Room {
	return &items.Room{Number: g.Room, Contacts: g.Contacts, Tiles: &g.Tiles}
}

// Step runs one frame, in the original's order: the main loop's contact
// and item tasks, then the enemies and Joe.
func (g *Game) Step(in joe.Input) {
	// The frame interrupt: set up a pending treasure screen, then move the
	// random pointer. Drawing chains and jewels takes the whole frame: the
	// pointer doesn't move, and the main loop's tasks, Joe included, don't
	// run. An empty screen (time up) is quick.
	if g.setupPending {
		g.setupPending = false
		g.treasureScreen()
		if g.TreasureTimer != 1 {
			return
		}
	}
	// After Joe leaves a room the original stands still: while it draws
	// the new room nothing runs, not even the frame interrupt; while it
	// then waits out a mirrored room's sync delay, only the interrupt does.
	frozen := g.Joe.Frozen > 0
	drawing := g.Joe.Frozen > g.syncWait
	if !drawing {
		g.Random++
		g.stepAnimation()
	}
	if !frozen {
		if g.tick(&g.ContactTimer, contactPeriod) {
			g.contactTask()
		}
		if g.tick(&g.ItemTimer, itemPeriod) {
			g.itemTask()
		}
	}

	before := g.Joe
	g.Joe.Treasure, g.Joe.TimeUp = g.Treasure, g.TreasureTimer == 1
	g.Joe.BarriersOff, g.Joe.FloorsGone = g.BarriersOff, g.FloorsGone
	exit := g.Joe.Step(in, &g.Tiles, g.Rules.Joe)
	if g.Joe.Redraw {
		g.Joe.Redraw = false
		g.setupPending = true
	}
	g.syncWait = min(g.syncWait, g.Joe.Frozen)
	if exit != 0 {
		g.changeRoom(exit, before)
	} else if !frozen {
		g.Enemies.Counter++
		g.Enemies.Update(&g.Tiles, g.Joe.Parity, g.Amulet > 0)
	} else if !drawing {
		g.Enemies.Counter++ // ticked by the frame interrupt ($A9E8)
	}
	if !frozen {
		g.barrierTask()
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
	if g.TreasureTimer > 1 {
		g.TreasureTimer--
	}
	if g.Joe.State >= joe.Zapped {
		return
	}
	if g.Amulet > 0 {
		g.Amulet--
	}
	if g.Amulet == 0 && g.Inventory.Remove(items.Amulet) {
		g.RedrawHUD()
	}
	// Step the barrier pattern every other run ($92D1).
	if g.ChainToggle ^= 0x80; g.ChainToggle == 0 {
		g.ChainFrame = (g.ChainFrame - 1) & 3
	}
	if g.Amulet > 0 {
		return
	}

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
		g.RedrawHUD()
		return
	}
	g.Joe.Kill()
}

// itemTask is the original's $8F5F: doors, creatures and pickups. It
// also lets the frame interrupt take the next animation step, unless Joe
// has fallen to his death.
func (g *Game) itemTask() {
	if g.Joe.State == joe.Dead {
		return
	}
	g.AnimStep ^= 0x80
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
	if res.Picked != 0 || res.Opened {
		g.RedrawHUD()
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
	if row >= pyramid.Rows {
		g.enterBelow(row, col)
		return
	}
	g.Treasure = false
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
	// A mirrored room leaves the original waiting a few frames more.
	g.syncWait = int(g.Rooms[next].SyncDelay)
	g.Joe.Frozen += g.syncWait
}

// stepAnimation is the frame interrupt's animation step ($A9F3): show the
// next pattern table, unless the item task hasn't run since the last step,
// and redraw the barrier and floor patterns ($A92F).
func (g *Game) stepAnimation() {
	a := g.AnimStep + 1
	if a&0x80 != 0 {
		return
	}
	if a == 4 {
		a = 0
	}
	g.AnimStep = a ^ 0x80
	g.ChainShown = g.ChainFrame
}

// barrierTask is the original's $A8D6, run every frame: of each 96, the
// disappearing floors are gone for 24 and the barriers off for 48.
func (g *Game) barrierTask() {
	if g.BarrierTimer--; g.BarrierTimer == 0 {
		g.BarrierTimer = 0x60
	}
	switch g.BarrierTimer {
	case 0x60:
		g.FloorsGone, g.BarriersOff = true, true
	case 0x48:
		g.FloorsGone = false
	case 0x30:
		g.BarriersOff = false
	}
}

// Patterns returns the tile patterns the screen shows now: the pattern
// table the animation has reached, with the barrier and floor frame.
func (g *Game) Patterns() [256 * 8]byte {
	table := int(g.AnimStep&0x7F+3) % 4
	return g.Rules.Anim.Patterns(g.Rooms[g.Room].TilePatterns, table, g.ChainShown)
}
