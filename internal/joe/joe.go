// Package joe moves Panama Joe the way the original game does. It is a
// translation of the game's state machine (dispatch at $8901, handlers in
// $8929-$8DE7) and keeps the game's own 8-bit coordinates and variables, so
// it can be checked frame by frame against the original on the emulator.
//
// Not yet translated: dying by touching enemies.
package joe

// States, as in $7079.
const (
	Standing = 0
	Walking  = 1
	Jumping  = 2
	Ladder   = 3
	Rope     = 4
	Pole     = 5
	Falling  = 6
	Zapped   = 8 // touched a $E0 tile
	Dead     = 9 // fell too far
	Burnt    = 10
)

// exitFreeze is how many frames Joe stays still after changing room, while
// the original draws the new one. Measured on the emulator, whose CPU
// timing is approximate.
const exitFreeze = 5

// Tiles with special meaning to Joe.
const (
	tileEmpty       = 0x00
	tileBrick       = 0x08
	tileLadder      = 0x88 // left half; 0x89 right
	tileLadderFloor = 0x10 // ladder top set into a floor; 0x11 right
	tileFire        = 0xD2
	tileRope        = 0x90
	tilePole        = 0x95
	tileRopeTop     = 0xC4
	tileZap         = 0xE0
	tileRopeEnd1    = 0x98 // with tileEmpty: nothing to hold below a rope
	tileRopeEnd2    = 0xD8
)

// safeFallStart is the fall start the game sets when Joe drops off the
// bottom of a rope, so the drop can't hurt him ($8D70).
const safeFallStart = 0xA0

// Rules holds the tile tables and the jump arc from the ROM.
type Rules struct {
	Floors    []byte // $93FF: tiles Joe stands on
	Hazards   []byte // $A00E: tiles that kill him
	Conveyors []byte // $9412: first three push left, the rest right
	Walls     []byte // $943C: tiles that stop him moving sideways
	JumpArc   []int8 // $93AE: dy per frame, read backwards by the jump counter
}

// Tiles is the screen Joe moves in: 24 rows of 32 tiles.
type Tiles interface {
	Tile(col, row int) byte
}

// Input is the joystick for one frame.
type Input struct {
	Up, Down, Left, Right, Fire bool
}

// Joe is Panama Joe's state, named after the game's RAM variables.
type Joe struct {
	X    byte // $7301: left edge of his body sprite
	RawY byte // $7300: sprite Y as the video chip takes it (screen Y - 1)

	State  int  // $7079
	DX, DY int8 // $7076/$7077: velocity
	Facing int8 // $7078: last non-zero DX

	JumpCounter   int  // $7072: frames left in the jump arc
	FallStart     byte // $707C: RawY where the current fall or jump began
	LadderCounter byte // $70B2: steps of the climb-down-onto-a-ladder sequence
	FireLatch     byte // $7075: fire button state, for detecting new presses
	Parity        byte // $70AB: counts down 3..0 each frame; the conveyor moves Joe when bit 0 is clear
	DeathTimer    int  // $70A9: frames left before he respawns
	Frozen        int  // frames left of the pause after changing room
	AnimTick      int  // frames he has moved, for walking and climbing animation
}

// ScreenY returns the top of Joe's body sprite on screen.
func (j *Joe) ScreenY() int { return (int(j.RawY) + 1) & 0xFF }

// Place puts Joe standing with the top of his body at screen (x, y).
func (j *Joe) Place(x, y int) {
	*j = Joe{X: byte(x), RawY: byte(y - 1), FireLatch: 0x80}
}

// buffer holds the 3x2 tiles around Joe's feet, as the game reads them
// into $7057-$705C at the start of each frame ($9156): the row above his
// feet, then the row at his feet, each left, middle, right.
type buffer [6]byte

func (j *Joe) read(t Tiles) buffer {
	// $9156: the legs sprite (3 lines below the body) plus (2, 18), turned
	// into a tile by rounding up ($AFE3), then one row up and one column left.
	x := int(j.X) + 2 - 1
	y := (int(j.RawY) + 3 + 18) & 0xFF
	col := ceil8(x) - 1
	row := ceil8(y) - 2
	var b buffer
	for r := 0; r < 2; r++ {
		for c := 0; c < 3; c++ {
			b[r*3+c] = tileAt(t, col+c, row+r)
		}
	}
	return b
}

func ceil8(v int) int { return ((v + 7) / 8) & 0x1F }

func tileAt(t Tiles, col, row int) byte {
	if col < 0 || col >= 32 || row < 0 || row >= 24 {
		return tileEmpty
	}
	return t.Tile(col, row)
}

// Exit directions returned by Step.
const (
	ExitLeft  = -1
	ExitRight = 1
	ExitUp    = -2
	ExitDown  = 2
)

// Step moves Joe one frame. It returns the direction he left the screen
// in, or 0; his position is then already where he enters the next room.
func (j *Joe) Step(in Input, t Tiles, r *Rules) (exit int) {
	if j.Frozen > 0 {
		j.Frozen--
		return 0
	}
	b := j.read(t)
	j.Parity = (j.Parity - 1) & 3
	switch j.State {
	case Standing, Walking:
		j.standing(in, b, r)
	case Jumping:
		j.jumping(b, r)
	case Ladder:
		j.ladder(in, b, r)
	case Rope:
		j.rope(in, b, r)
	case Falling, Pole:
		j.falling(0, 4, b, r)
	case Burnt:
		j.RawY-- // his ghost rises ($8B6E)
		j.dead()
	case Zapped, Dead:
		j.dead()
	}
	j.move(b, r)
	if exit = j.exit(); exit != 0 {
		j.Frozen = exitFreeze
	}
	return exit
}

// move applies this frame's velocity ($8D80-$8DE7). A wall at body height
// in the direction he's going stops him sideways for this frame, and for
// good unless he's rising. Touching a $E0 tile kills him.
func (j *Joe) move(b buffer, r *Rules) {
	if j.DX != 0 || j.DY != 0 {
		j.AnimTick++
	}
	dx := j.DX
	ahead := b[2]
	if dx < 0 {
		ahead = b[0]
	}
	if contains(r.Walls, ahead) {
		if j.DY >= 0 {
			j.DX = 0
		}
		dx = 0
	} else if b[1] == tileZap && j.State < Zapped {
		j.die(Zapped)
	}
	j.X += byte(dx)
	j.RawY += byte(j.DY)
}

func contains(list []byte, t byte) bool {
	for _, x := range list {
		if x == t {
			return true
		}
	}
	return false
}

// exit checks Joe's position after he moves ($8DE8) and, when he has left
// the screen, moves him to the opposite edge. Sideways exits use X; the
// room side follows the direction he's moving. Vertical exits use his legs
// sprite, 3 lines below his body.
func (j *Joe) exit() int {
	if j.State >= Zapped {
		return 0
	}
	switch legs := j.RawY + 3; {
	case j.X < 4 || j.X >= 0xF0:
		if j.DX < 0 {
			j.X += 0xEC
			return ExitLeft
		}
		j.X += 0x16
		return ExitRight
	case legs < 8:
		j.RawY += 0xA4
		return ExitUp
	case legs >= 0xAC:
		j.RawY += 0x5C
		return ExitDown
	}
	return 0
}

// commit stores the new state and velocity ($8988/$8992), letting a
// conveyor under Joe push him every other frame ($8F37).
func (j *Joe) commit(state int, dx, dy int8, b buffer, r *Rules) {
	if dx != 0 {
		j.Facing = dx
	}
	j.State = state
	if state != Jumping && j.Parity&1 == 0 && state < 8 {
		for i, c := range r.Conveyors {
			if c == b[4] {
				if len(r.Conveyors)-1-i >= 4 {
					dx--
				} else {
					dx++
				}
				break
			}
		}
	}
	j.DX, j.DY = dx, dy
}

// floor reports whether Joe can stand on t ($9122), and whether it burns.
func floor(t byte, r *Rules) (ok, fire bool) {
	for _, f := range r.Floors {
		if f == t {
			return true, false
		}
	}
	for _, h := range r.Hazards {
		if h == t {
			return true, true
		}
	}
	return false, false
}

func isHazard(t byte, r *Rules) bool { return contains(r.Hazards, t) }

// jumpPressed reports a new press of a fire button ($90E3).
func (j *Joe) jumpPressed(in Input) bool {
	if !in.Fire {
		j.FireLatch = 0x80
		return false
	}
	if j.FireLatch != 0x80 {
		j.FireLatch = 0xC0 // held
		return false
	}
	j.FireLatch = 0
	return true
}

// alignLadder snaps Joe onto a ladder ($8B20).
func (j *Joe) alignLadder() { j.align(0x0F, 0x07) }

// alignRope snaps Joe onto a rope or pole ($8B27). It returns the offset it
// used, which the game leaves in a register that one caller then uses as
// Joe's vertical speed.
func (j *Joe) alignRope() int8 { return j.align(0x0C, 0x04) }

func (j *Joe) align(high, low byte) int8 {
	c := high
	if j.X&0x0F < 8 {
		c = low
	}
	j.X = j.X&0xF0 + c
	return int8(c)
}

// standing handles states 0 and 1 ($8929).
func (j *Joe) standing(in Input, b buffer, r *Rules) {
	if b[4] == tileBrick && b[1] == tileBrick {
		// Inside a wall: shove him out ($8937).
		if b[0] != tileEmpty {
			j.X += 8
		} else {
			j.X -= 8
		}
		j.DX, j.DY = 0, 0
		return
	}
	if isHazard(b[0], r) {
		j.die(Burnt)
		return
	}
	switch {
	case in.Up && b[1] == tileLadder && b[2] == tileLadder+1:
		j.alignLadder()
		j.commit(Ladder, 0, -4, b, r)
		return
	case in.Down && b[4] == tileLadderFloor && b[5] == tileLadderFloor+1:
		j.alignLadder()
		j.LadderCounter = 8
		j.commit(Ladder, 0, 2, b, r)
		return
	case in.Down && ropeTop(b):
		// Grabbing a rope from above drops him by the alignment offset,
		// 12 or 4 pixels: the game reuses the register ($89C3).
		j.commit(Rope, 0, j.alignRope(), b, r)
		return
	}

	var dx int8
	switch {
	case in.Left:
		dx = -2
	case in.Right:
		dx = 2
	}
	if j.jumpPressed(in) {
		j.jump(dx, b, r)
		return
	}
	if ok, _ := floor(b[4], r); !ok {
		j.FallStart = j.RawY
		j.commit(Falling, dx, 0, b, r)
		return
	}
	if dx == 0 {
		j.commit(Standing, 0, 0, b, r)
	} else {
		j.commit(Walking, dx, 0, b, r)
	}
}

// jump starts a jump ($89DC).
func (j *Joe) jump(dx int8, b buffer, r *Rules) {
	j.FallStart = j.RawY
	j.JumpCounter = len(r.JumpArc)
	j.commit(Jumping, dx, -1, b, r)
}

// ropeTop reports the tile test at $89B1: the middle foot tile, or the
// right one when the middle is a ladder top, is the top of a rope.
func ropeTop(b buffer) bool {
	t := b[4]
	if t == tileLadderFloor {
		t = b[5]
	}
	return t == tileRopeTop
}

// jumping handles state 2 ($8A2F).
func (j *Joe) jumping(b buffer, r *Rules) {
	dy := int8(4)
	if j.JumpCounter > 0 {
		j.JumpCounter--
		dy = r.JumpArc[j.JumpCounter]
	}
	dx := j.DX
	if j.grab(b[1], b, r) {
		return
	}
	if dy < 0 {
		j.commit(Jumping, dx, dy, b, r)
		return
	}
	j.falling(dx, dy, b, r)
}

// grab catches a rope or pole at tile t, if Joe is jumping sideways and
// past the first 3 frames of the jump ($8B0E, $8B5B).
func (j *Joe) grab(t byte, b buffer, r *Rules) bool {
	canGrab := j.DX != 0 && j.JumpCounter < 15 // $8B44
	switch {
	case t == tileRope && canGrab:
		j.alignRope()
		j.commit(Rope, 0, 0, b, r)
		return true
	case t == tilePole && b[4] != tileBrick && canGrab:
		j.alignRope()
		j.commit(Pole, 0, 4, b, r)
		return true
	}
	return false
}

// falling handles states 5 and 6 ($8A83), and the falling half of a jump.
func (j *Joe) falling(dx, dy int8, b buffer, r *Rules) {
	ok, fire := floor(b[4], r)
	if !ok {
		if !j.grab(b[4], b, r) {
			j.commit(j.State, dx, dy, b, r)
		}
		return
	}
	if fire || b[4] == tileFire {
		j.die(Burnt)
		return
	}
	// Land: snap up so RawY is 4 more than a multiple of 8 ($8A9A).
	snap := int8(0)
	for y := j.RawY & 0x0F; y != 4 && y != 12; y-- {
		snap--
	}
	if j.RawY >= j.FallStart && j.RawY-j.FallStart >= 28 && j.State != Pole {
		// The game swaps the rows of his two sprites for the death pose,
		// so the body ends up 3 lines lower ($8AE0).
		j.RawY += 3
		j.die(Dead)
		return
	}
	j.commit(Walking, dx, snap, b, r)
}

// ladder handles state 3 ($8C59).
func (j *Joe) ladder(in Input, b buffer, r *Rules) {
	if c := j.LadderCounter; c&0x0F != 0 {
		// Stepping down onto the ladder: pause, pause, 2, 2, pause, ...
		c--
		j.LadderCounter = c
		switch {
		case c&0x02 != 0:
			j.commit(Ladder, 0, 0, b, r)
		case c&0x80 != 0:
			j.commit(Ladder, 0, -2, b, r)
		default:
			j.commit(Ladder, 0, 2, b, r)
		}
		return
	} else if c&0x80 != 0 {
		j.fall(b, r)
		return
	}
	if ok, _ := floor(b[4], r); ok {
		j.fall(b, r) // reached a floor: let go and land
		return
	}
	switch {
	case in.Down:
		j.commit(Ladder, 0, 1, b, r)
	case in.Up:
		j.commit(Ladder, 0, -1, b, r)
	default:
		j.commit(Ladder, 0, 0, b, r)
	}
}

// rope handles state 4 ($8D02).
func (j *Joe) rope(in Input, b buffer, r *Rules) {
	if j.jumpPressed(in) {
		switch {
		case in.Left:
			j.jump(-2, b, r)
			return
		case in.Right:
			j.jump(2, b, r)
			return
		}
	}
	if b[1] == tileEmpty {
		// Above the top of the rope ($8C9C).
		switch {
		case in.Up:
			j.fall(b, r) // let go ($8CC5)
		case in.Down:
			if ok, _ := floor(b[4], r); ok {
				j.commit(Rope, 0, 1, b, r)
			} else {
				j.fall(b, r)
			}
		default:
			j.commit(Rope, 0, 0, b, r)
		}
		return
	}
	switch t := b[4]; {
	case t == tileEmpty || t == tileRopeEnd1 || t == tileRopeEnd2:
		// Off the bottom of the rope: drop, harmlessly ($8D65).
		j.FallStart = safeFallStart
		j.commit(Falling, 0, 0, b, r)
		return
	default:
		if ok, _ := floor(t, r); ok {
			j.fall(b, r) // feet on a floor: let go and land
			return
		}
	}
	switch {
	case in.Down:
		j.commit(Rope, 0, 1, b, r)
	case in.Up && j.Parity&1 == 1:
		j.commit(Rope, 0, -1, b, r) // half speed going up ($8CE2)
	default:
		j.commit(Rope, 0, 0, b, r)
	}
}

// fall starts falling from where Joe is ($8A01).
func (j *Joe) fall(b buffer, r *Rules) {
	j.FallStart = j.RawY
	j.commit(Falling, 0, 0, b, r)
}

// die kills Joe ($8AE0 for falls, $8A91 for fire and hazards).
func (j *Joe) die(state int) {
	j.State = state
	j.DX, j.DY = 0, 0
	j.DeathTimer = 0x70
}

// dead counts down the death animation ($8B8E). The caller respawns Joe
// when Respawn reports true.
func (j *Joe) dead() {
	j.DX, j.DY = 0, 0
	if j.DeathTimer > 0 {
		j.DeathTimer--
	}
}

// Respawn reports whether Joe's death animation has finished.
func (j *Joe) Respawn() bool {
	return j.State >= Zapped && j.DeathTimer == 0
}
