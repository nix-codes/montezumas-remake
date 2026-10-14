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
	"montezuma-remake/internal/sound"
)

// StartLives is how many spare lives a game starts with (the hats in the
// HUD); losing one more ends it.
const StartLives = 5

// Joe lands here in the starting room after sliding down the entrance pole.
const StartX, StartY = 124, 53

// A new game finds Joe at the top of the entrance hall's left pole, where
// the cartridge's sprite table starts him.
const entranceX, entranceY = 12, 25

// Main-loop task periods ($A8A1): the contact check runs every 2 frames,
// the item task every 4.
const (
	contactPeriod = 2
	itemPeriod    = 4
)

// Rules are the original's tables, its animated tile patterns, its sound
// effects, and the ROM itself, which the treasure room reads for random
// numbers.
type Rules struct {
	Joe   *joe.Rules
	Enemy *enemy.Rules
	Items *items.Rules
	Anim  *gfx.Animation
	Sound *sound.Effects
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
	s, err := sound.EffectsFromROM(r)
	if err != nil {
		return nil, err
	}
	return &Rules{Joe: j, Enemy: e, Items: i, Anim: a, Sound: s, ROM: r}, nil
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
	// CreatureColour is the creatures' colour entry (20) as the amulet
	// last set it: grey while it protects Joe, then dark green. 0 for the
	// room's own colour, which the frame interrupt puts back ($8EB0) when
	// recolour is set: when Joe picks something up, or once the main loop
	// runs again after he enters a room (entered) and saves him ($8E7E).
	CreatureColour byte
	recolour       bool
	entered        bool
	Done      [pyramid.Rooms]uint16 // per room, one bit per contact entry: collected, opened, removed

	Enemies  *enemy.State
	Contacts []byte

	// The treasure room ($705F bit 5) and its timer ($70AC), and the
	// pointer it reads random numbers from ($7047), which moves every
	// frame.
	Treasure      bool
	TreasureTimer int
	Random        uint16

	// Descent is set while the game walks Joe from the entrance hall
	// into the starting room at the start of a level ($705F bit 2).
	Descent bool

	setupPending bool // draw a new treasure screen on the next frame
	silence      bool // turn the sound off on the next frame, as a room loads
	syncWait     int  // the last frames of Joe's pause, waiting out a mirrored room's sync delay
	// TreasureScreens counts treasure screens drawn. (The original takes
	// two frames to draw one; the tests skip comparing that frame.)
	TreasureScreens int

	// LevelRooms, if set, gives the rooms for each level, for when a new
	// level starts.
	LevelRooms func(level int) []roomdata.Room

	// Main-loop task countdowns: a task runs when its count is 1. Moving
	// Joe and the enemies ($88D1) and blinking the barriers ($A8D6) run
	// every frame, but like the others start a new game at 2 ($7068,
	// $7074), so the first pass of the main loop runs nothing.
	ContactTimer, ItemTimer int
	MoveTimer, BlinkTimer   int

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

	// The sound chip, and the player the frame interrupt runs on it.
	PSG   *sound.PSG
	Sound sound.Player

	// GameOver is set once Joe has died with no spare lives left: the
	// game stands still with GAME OVER on screen, Joe hidden. On level 1,
	// fire continues it, once per game ($705F bit 0, Continued); otherwise
	// only the console's reset button gets out.
	GameOver  bool
	Continued bool
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

// New starts a game on level (1-3) in room; in the entrance hall, it
// starts as the original does, with Joe walked into the pyramid.
func New(rooms []roomdata.Room, rules *Rules, level, room int) *Game {
	g := &Game{Rules: rules, Rooms: rooms, Level: level, PSG: sound.NewPSG()}
	g.Sound.Effects = rules.Sound
	g.Restart(room)
	return g
}

// Restart starts a new game in room, or in the entrance hall as the
// original does (see enterLevel).
func (g *Game) Restart(room int) {
	g.Lives = StartLives
	g.Score = 0
	g.Treasure = false
	g.Inventory = items.NewInventory()
	g.Amulet = 0
	g.CreatureColour, g.recolour, g.entered = 0, false, false
	g.Done = [pyramid.Rooms]uint16{}
	g.ContactTimer, g.ItemTimer = contactPeriod, itemPeriod
	g.MoveTimer, g.BlinkTimer = 1, 1
	if room == pyramid.Entrance {
		g.ContactTimer, g.ItemTimer, g.MoveTimer, g.BlinkTimer = 2, 2, 2, 2
		g.Joe.Place(entranceX, entranceY)
		g.enterLevel()
		g.Joe.State = joe.Pole
		g.Joe.Frozen = startFreeze
		g.syncWait = startFreeze
		return
	}
	g.Joe.Place(StartX, StartY)
	g.Enter(room)
}

// startFreeze is how long a new game stands still before its main loop
// starts: the original waits for the frame interrupt to count down its
// sync byte ($A5CA) first.
const startFreeze = 14

// enterLevel starts a level in the entrance hall, the way both a new game
// ($A59D) and the next level ($8E20) do. Until Joe lands in the starting
// room, the game drives him itself (Descent): down his pole, across the
// hall towards its middle, jumping up the steps, and down the rope into
// the pyramid.
func (g *Game) enterLevel() {
	g.Descent = true
	g.Enter(pyramid.Entrance)
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
	g.Descent = false
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
	g.entered = true
	g.load()
	// The original loads the room on the frame after Joe leaves the old
	// one, and the loader turns the sound off ($A06A); an effect that's
	// playing runs on silently.
	g.silence = true
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
	if g.Descent && r.Bare != nil {
		// The entrance hall at the start of a level: no HUD ($A1EE).
		for y, row := range r.Bare {
			g.Tiles.T[y] = row
		}
		return
	}
	g.RedrawHUD()
}

func (g *Game) itemRoom() *items.Room {
	return &items.Room{Number: g.Room, Contacts: g.Contacts, Tiles: &g.Tiles}
}

// Step runs one frame, in the original's order: the main loop's contact
// and item tasks, then the enemies and Joe.
func (g *Game) Step(in joe.Input) {
	defer g.PSG.EndFrame()
	if g.silence {
		g.silence = false
		sound.TurnOff(g.PSG)
	}
	if g.GameOver {
		g.stepGameOver(in)
		return
	}
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
		if g.recolour {
			g.recolour = false
			g.CreatureColour = 0
		}
		g.Random++
		g.stepAnimation()
		g.Sound.Tick(g.PSG)
	}
	moves, blinks := true, true
	if !frozen {
		if g.entered {
			g.entered = false
			g.recolour = true
		}
		if g.tick(&g.ContactTimer, contactPeriod) {
			g.contactTask()
		}
		if g.tick(&g.ItemTimer, itemPeriod) {
			g.itemTask()
		}
		moves = g.tick(&g.MoveTimer, 1)
		blinks = g.tick(&g.BlinkTimer, 1)
	}
	if frozen || moves {
		g.movementTask(in, frozen, drawing)
	}
	if !frozen && blinks {
		g.barrierTask()
	}

	if g.Joe.Respawn() {
		if g.Lives == 0 {
			g.gameOver()
			return
		}
		g.Lives--
		g.respawn()
	}
}

// movementTask moves Joe and the enemies ($88D1). While Joe is frozen
// after a room change only his pause counts down.
func (g *Game) movementTask(in joe.Input, frozen, drawing bool) {
	before := g.Joe
	if g.Descent {
		in = descentInput(g.Joe.X)
	}
	g.Joe.Treasure, g.Joe.TimeUp = g.Treasure, g.TreasureTimer == 1
	g.Joe.BarriersOff, g.Joe.FloorsGone = g.BarriersOff, g.FloorsGone
	g.Joe.Autopilot = g.Descent
	exit := g.Joe.Step(in, &g.Tiles, g.Rules.Joe)
	if g.Descent && g.Col == pyramid.Centre && g.Joe.Sounds&(1<<sound.Land) != 0 {
		// Landing in the starting room ends the descent ($8ABA). The game
		// remembers Joe for respawning as he was before landing: it does
		// so in the middle of handling it.
		g.Descent = false
		g.Entry = before
		g.recolour = true
	}
	g.playJoeSounds()
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
}

// descentInput is the joystick the game holds for Joe during the descent
// ($88E6): down, and towards the middle of the screen.
func descentInput(x byte) joe.Input {
	return joe.Input{Down: true, Right: x < 0x80, Left: x >= 0x80}
}

// respawnFreeze is how long the original stands still after a respawn
// while it redraws the room, measured on the emulator like a room
// change's pause: 4 frames, a frame more for a mirrored room, which also
// leaves it waiting out its sync delay.
const respawnFreeze = 4

// respawn puts Joe back as he entered the room, and reloads it.
func (g *Game) respawn() {
	sound.TurnOff(g.PSG) // $A06A
	g.Joe = g.Entry
	g.load()
	g.syncWait = int(g.Rooms[g.Room].SyncDelay)
	g.Joe.Frozen = respawnFreeze + g.syncWait
	if g.syncWait > 0 {
		g.Joe.Frozen++
	}
}

// Game over ($8B95).
const (
	gameOverText = 0x9409 // "GAME OVER", a space as tile 0
	gameOverLen  = 9
	gameOverCol  = 12
	gameOverRow  = 11
)

// gameOver ends the game as Joe would respawn: GAME OVER over the room,
// Joe hidden and the sound off.
func (g *Game) gameOver() {
	g.GameOver = true
	sound.TurnOff(g.PSG)
	text, err := g.Rules.ROM.Slice(gameOverText, gameOverLen)
	if err != nil {
		panic(err)
	}
	for i, t := range text {
		g.Tiles.SetTile(gameOverCol+i, gameOverRow, t)
	}
}

// stepGameOver is a frame of game over. The main loop waits for fire
// with no direction held ($8BBE), so only the frame interrupt runs. On
// level 1, the first time, the game then continues: the score starts
// again from 0, the lives are back, and Joe respawns. Anywhere else the
// original waits for the level to be 1 ($8BD1), forever.
func (g *Game) stepGameOver(in joe.Input) {
	g.Random++
	g.stepAnimation()
	g.Sound.Tick(g.PSG)
	g.Enemies.Counter++
	if !in.Fire || in.Left || in.Right || in.Up || in.Down || g.Continued {
		return
	}
	g.Continued = true
	if g.Level != 1 {
		return
	}
	g.GameOver = false
	g.Score = 0
	g.Lives = StartLives
	g.respawn()
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
	switch {
	case g.Amulet > 1:
		g.Amulet--
		g.CreatureColour = creaturesProtected
	case g.Amulet == 1:
		g.Amulet = 0
		g.CreatureColour = creaturesAfter
		if g.Inventory.Remove(items.Amulet) {
			g.RedrawHUD()
		}
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
		g.Sound.Play(sound.SwordKill)
		spr := g.Enemies.Sprites[slot]
		if spr.Colour == 0x0F {
			g.addScore(items.PointsSkull)
		} else {
			g.addScore(items.PointsEnemy)
		}
		spr.Colour = 0
		g.RedrawHUD()
		return
	}
	g.Joe.Kill()
	g.playJoeSounds()
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
	switch {
	case res.Opened:
		g.Sound.Play(sound.Door)
	case res.Picked != 0:
		g.Sound.Play(sound.Pickup)
		g.recolour = true
	}
	g.addScore(res.Points)
	for _, e := range res.Done {
		g.Done[g.Room] |= 1 << e
	}
	if res.Amulet {
		g.Amulet = items.AmuletTime
	}
	if res.KillJoe {
		g.Joe.Kill()
		g.playJoeSounds()
	}
	if res.Picked != 0 || res.Opened {
		g.RedrawHUD()
	}
}

// playJoeSounds plays the sound effects Joe started, lowest number last
// so it wins as it would have in the original.
func (g *Game) playJoeSounds() {
	for id := 15; id >= 0; id-- {
		if g.Joe.Sounds&(1<<id) != 0 {
			g.Sound.Play(byte(id))
		}
	}
	g.Joe.Sounds = 0
}

// addScore adds points to the score ($AF70). Passing a multiple of 10,000
// earns a spare life, though from level 5 on only when the hundreds digit
// is then even (the game tests bit 0 of the score's middle BCD byte).
func (g *Game) addScore(points int) {
	before := g.Score
	g.Score += points
	if g.Score/10000 == before/10000 {
		return
	}
	if g.Score/100%2 == 0 || g.Level < 5 {
		g.Lives++
	}
	g.RedrawHUD()
	g.Sound.Play(sound.ExtraLife)
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
