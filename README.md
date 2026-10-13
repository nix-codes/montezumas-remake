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
make run       # play the remake: arrows move, space/Z/X jump, PageUp/PageDown jump rooms
make original  # play the original ROM on the built-in emulator
make test
```

`make original` keys: arrows = joystick, Z/X = left/right fire, 0-9 = keypad
(press 1, 2 or 3 on the title screen to pick a level).

`go run ./cmd/game -room N` starts in room N; `-screenshot out.png` saves an
early frame and exits.

The first 8 KB of the assembled ROM matches MAME's checksum for the original
cartridge; the last 4 KB can't be checked that way.

## Layout

| Path | Contents |
|---|---|
| `original/` | The disassembly (tniASM syntax; the Makefile adapts it for sjasmplus) |
| `internal/rom` | Loads the ROM; decodes the game's inline VRAM loader calls (`SUB_AE00`) |
| `internal/vdp` | TMS9918A tables and palette; draws tiles and sprites |
| `internal/gfx` | Replays the game's boot-time VRAM loads |
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
| `internal/play` | The game: state and one frame of play in the original's order, with the HUD; tested against the original |
| `cmd/game` | Shows `internal/play` in a window and feeds it the keyboard |

## Notes

### Emulator

- The BIOS ROM isn't included; `internal/coleco/bios.go` reimplements the 14
  BIOS routines the game calls. `LOAD_ASCII` uses a stand-in font squeezed
  from Go's 7x13 basic font.
- The Z80 core (koron-go/z80) doesn't count cycles, so frames are paced at a
  fixed number of instructions. Sound isn't emulated.
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
- Floor tiles Joe can stand on are listed at `$93FF`; other tile classes
  are at `$9412`, `$943C` and `$A00E` (not yet identified).

### Joe

- Joe is two sprites: his body (red) and, 3 lines lower, his hat, face and
  legs (yellow). His state is at `$7079`, velocity at `$7076/$7077`; the
  state machine dispatches at `$8901` through a table at `$8913`.
- Each frame the game reads the 3x2 tiles around his feet (`$9156`), runs
  the state's handler, applies the velocity unless a wall (`$943C`) is in
  the way, then checks the screen edges. `internal/joe` follows the same
  steps with the same 8-bit variables.
- Measured: walking 2 px/frame, falling 4 px/frame, the jump arc from the
  table at `$93AE`, falls of 28+ px kill, conveyors (`$9412`) push 1 px
  every other frame, ladders 1 px/frame with a stutter when stepping down
  onto one.
- Ropes (`$90`, state 4): grab one from above with down on its top tile
  (`$C4`; Joe drops 12 or 4 px, a quirk of the original), or with a running
  jump past its first 3 frames. Down slides 1 px/frame, up climbs at half
  speed, fire with left/right jumps off, and dropping off the bottom never
  hurts. Poles (`$95`, state 5) are caught the same way and slid down at
  4 px/frame.
- `internal/joe`'s comparison test runs 21 scenarios on both games and
  checks Joe's position and state every frame. Not translated yet: dying
  by touching enemies.
- After a room change the original pauses Joe while it draws the new room
  (5-6 frames on the emulator, depending on the room); the remake uses 5.

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
  is active (or, not done yet, he has the sword). On the emulator it runs
  every other frame, on positions from the end of the previous frame. The
  enemy that killed him is gone after the respawn, until the room is
  reloaded.
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
- Not done: the torch lighting dark rooms (its effect hasn't been traced),
  and the amulet's border flash.

### Graphics

- `SUB_AE00` takes 4-byte records inline after its `CALL` (source address,
  item index, item count) and passes each to BIOS `PUT_VRAM`; the preceding
  `LD A,n` selects the table. `assets/loader-calls.txt` lists every call site.
- Some tiles (the BIOS font loaded by `LOAD_ASCII`) come from the console BIOS
  ROM, which is not included, so those slots are blank.
- Sprite colours are set at run time, so sprites are drawn in white.
- The extracted graphics are the original game's assets: fine for personal
  use, not for redistribution.
