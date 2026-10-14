# Montezuma's Revenge remake

A Go remake of the 1984 ColecoVision Montezuma's Revenge, built from the
compilable disassembly in
[tony-cruise/colecovision-games-source](https://github.com/tony-cruise/colecovision-games-source/tree/main/games/Montezuma%27s%20Revenge)
(GPL-3.0, copied into `original/`).

## Requirements

- Go 1.27+
- Ebitengine's Linux libraries: `sudo apt install libgl1-mesa-dev xorg-dev libasound2-dev`
- [sjasmplus](https://github.com/z00m128/sjasmplus) on `PATH` (or `make SJASMPLUS=/path/to/sjasmplus`)

## Usage

```bash
make rom       # assemble original/ into build/montezuma.rom
make extract   # write tiles.png, sprites.png and loader-calls.txt to assets/
make rooms     # capture all rooms of levels 1-3 to assets/rooms/
make run       # play the remake: 1-3 pick the level, arrows move, space/Z/X jump, Esc resets
make original  # play the original ROM on the built-in emulator
make test
```

`make original` keys: arrows = joystick, Z/X = left/right fire, 0-9 = keypad
(press 1, 2 or 3 on the title screen to pick a level).

In the remake, Esc is the console's reset button, back to the title
screen, and PageUp/PageDown jump rooms for testing. `go run ./cmd/game
-level N` skips the title and starts level N, `-room N` starts in room N;
`-screenshot out.png` saves an early frame and exits. A game starts as
the original does, with Joe walked from the entrance hall into the
pyramid. Jumping to a room
(PageUp/PageDown or `-room`) stands Joe on a floor spot away from its
enemies, and he respawns there.

The first 8 KB of the assembled ROM matches MAME's checksum for the original
cartridge; the last 4 KB can't be checked that way.

## Layout

| Path | Contents |
|---|---|
| `original/` | The disassembly (tniASM syntax; the Makefile adapts it for sjasmplus) |
| `internal/rom` | Loads the ROM; decodes the game's inline VRAM loader calls (`SUB_AE00`) |
| `internal/vdp` | TMS9918A tables and palette; draws tiles and sprites |
| `internal/gfx` | Replays the game's boot-time VRAM loads; the animated tile tables; the title screen |
| `cmd/extract` | Writes the boot graphics as PNGs |
| `internal/coleco` | Minimal ColecoVision emulator: Z80, RAM, TMS9918A, Go stand-ins for the BIOS calls the game uses |
| `cmd/original` | Runs the original ROM in a window, or headless with scripted input |
| `internal/pyramid` | Room layout of the pyramid and the game's room arithmetic |
| `cmd/rooms` | Loads every room through the original game and saves tile maps, sprites and exits |
| `cmd/dis` | Disassembles ROM ranges the disassembly left as raw bytes |
| `internal/roomdata` | The `rooms.json` format shared by `cmd/rooms` and `cmd/game` |
| `internal/original` | Drives the original on the emulator: start a game, load a room, read or place Joe |
| `internal/joe` | Joe's movement, translated from the original and tested against it frame by frame |
| `internal/enemy` | The rooms' enemies and the contact check, translated from the original and tested against it |
| `internal/items` | Items, doors and static creatures (tiles), the inventory, and restoring rooms on revisits |
| `internal/sound` | The SN76489A sound chip, and the game's sound-effect player translated from the original |
| `internal/play` | The game: state and one frame of play in the original's order, with the HUD; tested against the original |
| `cmd/game` | Shows `internal/play` in a window and feeds it the keyboard |

## Notes

### Emulator

- The BIOS ROM isn't included; `internal/coleco/bios.go` reimplements the 14
  BIOS routines the game calls. `LOAD_ASCII` uses a stand-in font squeezed
  from Go's 7x13 basic font.
- The Z80 core (koron-go/z80) doesn't count cycles, so frames are paced at a
  fixed number of instructions.
- Writes to the sound port (`$E0-$FF`) and `TURN_OFF_SOUND` go to
  `internal/sound`'s SN76489A, which both `make original` and `make run`
  play.
- `Machine.Call` runs one of the game's subroutines to completion, which is
  how `cmd/rooms` loads rooms.

### Rooms

- 100 rooms: room 0 is the entrance hall, and rooms 1-99 form a pyramid of
  nine rows (3, 5, ... 19 rooms) centred on column 10. Each level starts in
  the entrance hall; Joe slides down a pole into room 2, the middle of the
  top row. See `internal/pyramid`.
- The game keeps the row in `$71A7` and the column in `$71A8`; the room
  number is the column plus a per-row offset (table at `$A4C5`). Left/right
  changes the column, up/down the row. Columns aren't bounds-checked, so side
  exits at the end of a row wrap into the next room by number (left from
  room 4 leads to room 3). Leaving the bottom row downwards starts the next
  level.
- `$A067` loads the room at the current row and column; the layout comes from
  the address table at `$9477`. `make rooms` calls it on the emulator for
  every room and saves the tile map, video tables, enemy state (object list,
  contact list, sprite table, frame counter) and exits (`rooms.json`), a
  PNG per room and `map.png` of the whole pyramid.
- Exits are worked out from edge tiles: two open tile rows at a side, or a
  ladder or rope (`$88/$89`, `$10/$11`, `$90`) at the top or bottom. 13 side
  openings and room 13's ladder up into room 7 have no matching opening on
  the far side; the game still moves Joe there.
- The levels share the layouts except rooms 6, 7, 9 and 72.
- Tile classes: floors Joe can stand on (`$93FF`), conveyors (`$9412`,
  the first three push left, the rest right), walls that stop sideways
  moves (`$943C`, enemies too) and tiles that kill him (`$A00E`).

### Joe

- Joe is two sprites: his body (red) and, 3 lines lower, his hat, face and
  legs (yellow). His state is at `$7079`, velocity at `$7076/$7077`; the
  state machine dispatches at `$8901` through a table at `$8913`.
- Each frame the game reads the 3x2 tiles around his feet (`$9156`), runs
  the state's handler, applies the velocity unless a wall (`$943C`) is in
  the way, then checks the screen edges. `internal/joe` follows the same
  steps with the same 8-bit variables.
- Measured: walking 2 px/frame, falling 4 px/frame, the jump arc from the
  table at `$93AE` (Joe can't land until the frame after his stored
  velocity stops rising, `$8A79`), falls of 28+ px kill, conveyors (`$9412`) push 1 px
  every other frame, ladders 1 px/frame with a stutter when stepping down
  onto one.
- Ropes (`$90`, state 4): grab one from above with down on its top tile
  (`$C4`; Joe drops 12 or 4 px, a quirk of the original), or with a running
  jump past its first 3 frames. Down slides 1 px/frame, up climbs at half
  speed, fire with left/right jumps off, and dropping off the bottom never
  hurts. Poles (`$95`, state 5) are caught the same way and slid down at
  4 px/frame.
- `internal/joe`'s comparison test runs 21 scenarios on both games and
  checks Joe's position and state every frame. Dying by touching enemies
  is in `internal/play` (see Enemies).
- After a room change the original pauses while it draws the new room:
  the main loop runs none of its tasks, and the frame interrupt does
  nothing. On the emulator that takes 3-10 frames depending on the room
  (its timing is approximate: it paces frames by instruction count, and
  the BIOS stand-ins take no time); the remake uses 5.
- Rooms built by mirroring another (`$AB29`; rooms 3, 24, 30, 42, 44, 52,
  83 and 89) pause 8 frames more. The mirroring copies each row through a
  buffer at `$7200`, which overlaps the main loop's frame-sync byte
  (`$7207`), leaving a brick (`$08`) there; the main loop then waits for
  the frame interrupt to count it down, running no tasks meanwhile.
  `cmd/rooms` records the value as `syncDelay`.

### Enemies

- Each room's enemies are 2-byte objects at `$7086` (flags with the sprite
  slot, and a counter), moved every frame by `$A7A1` with the same tile
  reader as Joe. Kinds: rollers (skulls; flag `$08`), bouncers that follow
  the arc at `$ABB3` and turn at the screen edges (`$10`), and walkers that
  climb ladders on certain frames (`$40`; spiders and snakes). They turn at
  walls, at the end of their floor and near the screen edges; the name table
  is read as one strip, so one column past the right edge is the next row's
  first column.
- The contact check (`$91E5`) runs in the main loop: an enemy kills Joe when
  their sprites are less than 13 lines and 8 pixels apart, unless his amulet
  is active or he has the sword, which kills the enemy instead (see Items).
  On the emulator it runs every other frame, on positions from the end of
  the previous frame. The enemy that killed him is gone after the respawn,
  until the room is reloaded.
- `internal/enemy`'s tests move every room's enemies in both games for 300
  frames, and run Joe and the enemies together through a death, comparing
  every frame.

### Items

- Items, doors and static creatures are tiles. A room's contact list gives
  each one's top-left position; a per-room bitmap (`$70C0`, one bit per
  entry) remembers what's been collected, opened or removed, so revisited
  rooms load without them (items gone, doors open, enemies and creatures
  that killed Joe removed).
- The main loop's task table (`$A8A1`) runs the contact check every 2
  frames, the item task (`$8F5F`) every 4, and movement every frame. The
  item task opens a door beside Joe if he has its key (3 colours, 300
  points), kills him on a creature tile (`$A0-$A7`) unless the amulet is on,
  or picks up the item at his body: keys (50), sword (50), torch (3000),
  jewel (1000, not kept), amulet (100; protects for 160 contact checks).
- The inventory (`$71B2`) holds 5 items; its sixth byte must stay empty
  (`$A56C` relies on it). The sword is used up killing an enemy (2000 for
  white ones, 3000 others).
- HUD: inventory icons from the table at `$9FD2`, spare lives as hats, the
  level and a 6-digit score in big digits.
- `internal/play`'s tests run 9 item scenarios against the original,
  comparing the whole screen, Joe, the inventory, the score and the enemies
  every frame, and check revisited rooms load the same.
- Dark rooms: rows at least 9 minus the level are dark without the torch
  (the room-entry routine at `$8EB0` blanks colour entries).
- Passing a multiple of 10,000 points (`$AF70`) earns a spare life; from
  level 5 on, only if the hundreds digit is then even (the game tests bit 0
  of the score's middle BCD byte). `$7049` counts Joe's own life too, and
  drops when he dies rather than when he respawns.
- The amulet has no border flash: the contact task greys the creatures
  (`$A0-$A7`, colour entry 20, via `$91D9`) while it protects Joe, and
  when it runs out sets them dark green (`$C0`), not their usual medium
  green (`$20`). The usual colour comes back when the frame interrupt
  runs `$8EB0`, which first reloads the boot colours (`$8308`). That
  happens after any pickup (`$903A`), and after a room entry once the main
  loop runs again and saves Joe for respawning (`$8E7E`).

### Level start

- Every level starts in the entrance hall (row 0, column 8) with `$705F`
  bit 2 set, and the game walks Joe into the pyramid itself: each frame
  the movement task overwrites the joystick (`$88E6`) with down and
  towards the middle of the screen, and the jump check (`$90E3`) counts a
  brick beside his feet as a press, except on a rope. So he slides down
  the pole, walks to the middle, jumps up the steps, grabs the rope and
  slides down it into the starting room (going down with the bit set adds
  2 to the column, `$8F13`). Landing in column 10 clears the bit and saves
  Joe for respawning (`$8ABA`), as he was before landing.
- A new game (`$A59D`) starts Joe at the top of the left pole, where the
  cartridge's sprite table has him from boot. The main loop first waits
  for the frame interrupt to count down the sync byte (`$A5CA`, 14 frames
  on the emulator), and all four task counters start at 2, so its first
  pass runs nothing. The next level keeps Joe's X, so he comes down the
  right pole from the treasure room's right-hand column; that room load
  pauses a frame longer than a room change.
- With the bit set, the loader leaves out the HUD in the entrance hall
  (`$A1EE`), so the poles run to the top of the screen; `cmd/rooms`
  captures those rows as `bare`.
- Tests run the descent on level 1 and from the treasure room into
  level 2 in both games, every frame.

### Title screen, dying and game over

- The cartridge boots straight into the title screen (`$8116`): the BIOS
  font, the capitals enlarged to 2x2 tiles from `$80` (BIOS `ENLARGE`) in
  yellow, and text from the ROM. It waits for keypad 1, 2 or 3 (`$817C`;
  fire held with it doesn't count), then starts that level (`$A59D`).
  `internal/gfx` builds the screen from the ROM, with the stand-in font
  `internal/vdp` shares with the emulator; a test compares it with the
  original's.
- Dying sets `$70A9` to `$70`; the movement task counts it down and acts
  once it goes negative (`$8B8E`), the frame after it reaches 0. Joe then
  respawns as he entered the room, and the room is drawn again: a pause of
  4 frames on the emulator, 5 for a mirrored room, which then also waits
  out its sync delay. The HUD is redrawn at the end of the pause.
- With no lives left (`$7049` is 0), `$8B95` writes GAME OVER (`$9409`,
  ASCII) over the room, hides Joe, turns the sound off and puts the lives
  back to 6. The main loop then waits for fire with no direction held, so
  only the frame interrupt runs. Then it sets `$705F` bit 0 and waits for
  the level to be 1: on level 1 the game continues, the score back to 0,
  Joe respawning. Nothing clears that bit, so a second game over waits for
  fire forever, as does any game over past level 1: only the console's
  reset gets back to the title.
- Tests compare respawns (in a plain room and a mirrored one) and game
  over on levels 1 and 2 against the original, every frame.

### Treasure room and next level

- Room 90's floor has a gap: falling through it, below the pyramid, enters
  the treasure room and empties the inventory. Column 10 is a shaft of
  screens; while its timer runs (240 contact checks) each screen gets 25
  chains and a line of jewels placed by reading ROM bytes at a pointer
  that moves every frame (`$7047`). Other columns have a wall and a pole
  down one side. Once time is up, jumping off a chain is fast and redraws
  the screen.
- Leaving the bottom while sliding down a pole starts the next level:
  harder (up to 9), every room reset, and Joe comes down the entrance
  hall's pole on the side he left by (see Level start). Levels past 3 use
  level 3's room data.
- Setting up a new screen as Joe moves (leaving an edge, or the fast
  jump) runs the main loop past the end of the frame: the barrier task,
  last in the task table, runs at the start of the next frame, just
  before that frame's own run.
- Tests compare falling through the treasure room (several screens),
  the fast jump off a chain once time is up, and catching a side pole
  into the next level against the original.

### Sound

- The game plays one sound effect at a time with its own player: `$AC1A`
  starts effect A, and the frame interrupt runs `$AC6D`, which writes the
  sound port directly. It doesn't run while the game is paused drawing a
  room, and loading a room (`$A06A`, the frame after Joe leaves the old
  one) calls `TURN_OFF_SOUND`, so an effect playing then runs on silently. There is no music.
- The 10 effects (pointer table at `$AD0B`, data to `$ADFF`): 0 extra life,
  1 leaving the bottom row (into the treasure room or the next level),
  2 item picked up, 3 sword kill, 4 landing, 5 death (burnt, zapped or
  caught; falls only make the landing sound), 6 catching a pole, 7 jump,
  8 door opened, 9 footsteps. A lower number takes over from a higher one
  that's playing; the same effect starts over, except 1 and 9.
- An effect is a header (frames per step; a control byte whose bits 0-1
  give how many tone channels it uses and bit 2 selects white noise), then
  volumes for the first step (two channels to a byte), then a byte per tone
  channel per step, channel 2 first: the tone period over 4. A zero ends
  it. The noise always follows channel 2's tone.
- Footsteps: `$70AA` counts 7 down to 0, a step every other frame Joe
  holds a direction while walking or up/down while climbing (`$8C3F`,
  `$91BD`). The movement task starts (`$92DC`) by playing effect 9 if Joe is
  walking and the count is 2 or more. (The original also takes the walking
  sprite from this count; the remake's walk animation was measured
  instead.)
- `internal/sound`'s chip queues each frame's writes and plays them 1/60 s
  apart, a few frames behind the game (Ebitengine reads audio 50 ms at a
  time, which otherwise merges short effects' steps). Channels output 0 or
  their volume, with the DC filtered out; tones above 14 kHz (period 4,
  which the effects use between notes) are heard as their average. The
  noise register follows MAME's SN76489A: 17 bits, white noise fed back
  from bits 2 and 3.
- Tests compare the player's RAM and the chip's registers every frame in
  all of `internal/play`'s scenarios, and the effects Joe starts in all of
  `internal/joe`'s.

### Graphics

- `SUB_AE00` takes 4-byte records inline after its `CALL` (source address,
  item index, item count) and passes each to BIOS `PUT_VRAM`; the preceding
  `LD A,n` selects the table. `assets/loader-calls.txt` lists every call site.
- Some tiles (the BIOS font loaded by `LOAD_ASCII`) come from the console BIOS
  ROM, which is not included, so those slots are blank.
- Tile animation never touches the screen. At boot (`$81DC`) the game fills
  four tile pattern tables (`$0000`, `$0800`, `$1000`, `$2800`), each with
  the main tileset (`$83A1`), its own frame of fire, conveyors and a few
  others (`$8262`, `$81E5`, `$8206`, `$8233`) and their mirror images
  (`$8314`). The frame interrupt (`$A9F3`) points VDP register 4 at the next
  one, but only after the item task has run (it clears bit 7 of `$7011`),
  so a step every 4 frames, and none while Joe lies dead from a fall. Each
  step also rewrites the barrier (`$E0`) and disappearing floor (`$E8`)
  patterns in all four tables (`$A92F`) from `$7096`, which the contact
  task steps every other run (`$92D1`). The tables are the same in every
  room; `internal/gfx` builds them from the ROM.
- Barriers and disappearing floors blink through colour entries 28 and 29
  (`$40` shown, `$00` hidden), from a main-loop task run every frame
  (`$A8D6`): of each 96 frames the floors are gone for 24 and the barriers
  off for 48, flagged in `$7000` bits 6 and 5. Joe's zap check (`$8D9B`)
  ignores barriers that are off, and the floor check (`$9122`) only counts
  `$E8` while it's shown. Room loads don't touch these entries, and the
  counters run on from boot.
- Sprite colours are set at run time, so sprites are drawn in white.
- The extracted graphics are the original game's assets: fine for personal
  use, not for redistribution.
