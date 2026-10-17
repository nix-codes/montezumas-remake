; =============================================================================
; MONTEZUMA'S REVENGE (1984) ColecoVision disassembly
; =============================================================================
;
; Modified 2026-10-15 for montezuma-remake: the room loader ($A067-$A547),
; room data and tile tables ($943C-$A066) relabelled, recommented and
; turned back into code where left as bytes; legend and RAM notes corrected.
; Modified 2026-10-17: the rest of the ROM likewise: code left as bytes
; turned back into code, data laid out as tables and graphics, every
; routine named and its comments rewritten from what the code does.
; Assembles to the same bytes.
;
; CONTENTS
;
;   $8000  cartridge header; CART_ENTRY ($8021): JP NMI
;   $8025  START: boot
;   $8116  TITLE_SCREEN, then a new game
;   $81DC  BUILD_TILE_TABLES: the four animated pattern tables
;   $8293  title text, tile lists, LOAD_TILE_COLOURS ($8308),
;          MIRROR_TILES ($8314), MIRROR_SPRITES ($8352), LOAD_TILESET ($8392)
;   $841E  GRAPHICS: boot colours, tile and sprite patterns
;   $88D1  MOVE_TASK: Joe, every frame; JOE_STATES ($8913) and the handlers
;   $8D80  APPLY_VELOCITY, JOE_MOVE ($8DE8), CHANGE_ROOM ($8E0C),
;          SAVE_JOE ($8E7E), ROOM_COLOURS ($8EB0)
;   $8F5F  ITEM_TASK: doors, creatures, pickups
;   $90E3  JUMP_PRESSED, IS_FLOOR ($9122), JOE_TILES ($9156),
;          LOAD_ROOM_NOW ($919A)
;   $91E5  CONTACT_TASK: the amulet, and enemies touching Joe
;   $92DC  JOE_SPRITES; Joe's frames ($9378), JUMP_ARC ($93AE),
;          ROW_COLOURS ($93C0), tile tables ($93FF-$9443)
;   $9444  ROOM DATA: CMD_GROUPS, ROOM_LISTS ($9477), TILE_GROUPS ($9FD1)
;   $A067  LOAD_ROOM: draw a room from its command list
;   $A548  DRAW_INVENTORY, ADD_ITEM ($A56C)
;   $A59D  NEW_GAME, MAIN_LOOP ($A5CA), TASKS ($A8A1)
;   $A60B  TREASURE_SCREEN
;   $A69F  MOVE_ENEMIES ($A7A1), MOVE_CLIMBER ($A6B3)
;   $A8B7  VRAM_LOCK, BARRIER_TASK ($A8D6), BARRIER_PATTERNS ($A92F)
;   $A9B3  NMI: the frame interrupt
;   $AA5D  DRAW_HUD_BOXES, DRAW_LIVES ($AABB), MIRROR_ROOM ($AB29),
;          BOUNCE_ARC ($ABB3)
;   $AC1A  SOUND: PLAY_SOUND, SOUND_TICK ($AC6D), SOUND_EFFECTS ($AD0B)
;   $AE00  LOADER: inline records to video memory; VRAM helpers,
;          TILE_ROWS ($AEA7), DRAW_SCORE ($AEFE), ADD_SCORE ($AF70),
;          TILE_AT ($AFE3)
;
; The main loop runs four tasks from TASKS: CONTACT_TASK every 2 frames,
; ITEM_TASK every 4, MOVE_TASK and BARRIER_TASK every frame. The frame
; interrupt loads rooms, animates the tiles and plays the sound.
;
; RAM
;
;   $7000  flags: bit 0 set by LOAD_ROOM_NOW (never tested); bits 2 and 4
;          TILE_ROWS's modes; bit 3 tells MARK_GONE a creature killed Joe;
;          bit 5 barriers off; bit 6 disappearing floors gone
;   $7002  MIRROR_ROOM's row count        $7011  tile animation step (bit 7:
;   $7012  ITEM_TASK countdown                   wait for ITEM_TASK)
;   $7013  REFLECT_LIST's mode            $7015  room number
;   $7017  score, 3 BCD bytes             $702C  sound player (PLAY_SOUND)
;   $7047  the treasure room's random pointer, moved every frame
;   $7049  lives, Joe's own included      $704A  amulet timer
;   $704B  Joe's sprites as he entered the room (8 bytes)
;   $7057  tiles around a sprite's feet (READ_TILES): 3 at its body, 3 at
;          its feet
;   $705F  flags: bit 0 game over continued once; bit 1 VRAM busy
;          (VRAM_LOCK); bit 2 walking Joe into the pyramid; bit 3 set up a
;          treasure screen; bit 5 in the treasure room; bit 6 Joe not moving
;   $7068  MOVE_TASK countdown            $7072  Joe's jump counter
;   $7073  CONTACT_TASK countdown         $7074  BARRIER_TASK countdown
;   $7075  fire button latch              $7076  Joe's DX, DY ($7077)
;   $7078  Joe's facing (last DX)         $7079  Joe's state (JOE_STATES)
;   $707A  enemies in the room            $707C  Y where a fall began
;   $707D  Joe's DY, DX, state, facing, fire latch as he entered the room
;   $7084  scratch (READ_TILES's Y and X, and others)
;   $7086  enemy objects: 2 bytes each, up to $FF (MOVE_ENEMIES)
;   $7096  barrier frame, 3-0             $7097  frame counter
;   $7098  STEP_BARRIER's toggle          $70A8  BARRIER_TASK's counter
;   $70A9  death timer                    $70AA  step count, 7-0
;   $70AB  frame count, 3-0               $70AC  treasure room timer
;   $70AD  frames to the next step        $70AF  VRAM_LOCK depth
;   $70B1  frame interrupt flags: bit 0 DRAW_DIGITS's non-zero digit; bit 3
;          load a room; bit 4 recolour it; bit 7 inside the interrupt
;   $70B2  Joe's climb-down-onto-a-ladder counter
;   $70B3  DISPLAY_OFF depth              $70BD  points to add (BCD)
;   $70C0  "gone" bitmap: 2 bytes per room, a bit per thing
;   $7190  LOAD_ROOM's state, to $71B1; $71B0/$71B1 also the tile position
;          READ_TILES found
;   $71A6  level, 1-9                     $71A7  row ($71A8 column)
;   $71B2  inventory: 6 item codes, $FF free (the last always free)
;   $7200  MIRROR_ROOM's row buffers, to $729F (at boot, the checkered
;          sprite copies)
;   $7207  the main loop's frame-sync byte
;   $72C0  contact list: from $72C2 an entry per thing (its name table
;          position, or an enemy's sprite offset and $FF), up to $FE $FE
;   $72E0  sprite order table             $7300  local sprite table:
;   $73BF  the stack, growing down               Joe's 2 sprites, enemies'
;   BIOS:  $73C7 MUX_SPRITES, $73EE joystick (the right button merged in by
;          READ_CONTROLLERS), $73F0 keypad, $73F9 the pattern table the
;          BIOS writes to
; =============================================================================

BOOT_UP:                 EQU $0000
BIOS_NMI:                EQU $0066
NUMBER_TABLE:            EQU $006C
PLAY_SONGS:              EQU $1F61
ACTIVATEP:               EQU $1F64
REFLECT_VERTICAL:        EQU $1F6A
REFLECT_HORIZONTAL:      EQU $1F6D
ROTATE_90:               EQU $1F70
ENLARGE:                 EQU $1F73
CONTROLLER_SCAN:         EQU $1F76
DECODER:                 EQU $1F79
GAME_OPT:                EQU $1F7C
LOAD_ASCII:              EQU $1F7F
FILL_VRAM:               EQU $1F82
MODE_1:                  EQU $1F85
UPDATE_SPINNER:          EQU $1F88
INIT_TABLEP:             EQU $1F8B
PUT_VRAMP:               EQU $1F91
INIT_SPR_ORDERP:         EQU $1F94
INIT_TIMERP:             EQU $1F9A
REQUEST_SIGNALP:         EQU $1FA0
TEST_SIGNALP:            EQU $1FA3
WRITE_REGISTERP:         EQU $1FA6
INIT_WRITERP:            EQU $1FAF
SOUND_INITP:             EQU $1FB2
PLAY_ITP:                EQU $1FB5
INIT_TABLE:              EQU $1FB8
GET_VRAM:                EQU $1FBB
PUT_VRAM:                EQU $1FBE
INIT_SPR_NM_TBL:         EQU $1FC1
WR_SPR_NM_TBL:           EQU $1FC4
INIT_TIMER:              EQU $1FC7
FREE_SIGNAL:             EQU $1FCA
REQUEST_SIGNAL:          EQU $1FCD
TEST_SIGNAL:             EQU $1FD0
TIME_MGR:                EQU $1FD3
TURN_OFF_SOUND:          EQU $1FD6
WRITE_REGISTER:          EQU $1FD9
READ_REGISTER:           EQU $1FDC
WRITE_VRAM:              EQU $1FDF
READ_VRAM:               EQU $1FE2
INIT_WRITER:             EQU $1FE5
WRITER:                  EQU $1FE8
POLLER:                  EQU $1FEB
SOUND_INIT:              EQU $1FEE
PLAY_IT:                 EQU $1FF1
SOUND_MAN:               EQU $1FF4
ACTIVATE:                EQU $1FF7
PUTOBJ:                  EQU $1FFA
RAND_GEN:                EQU $1FFD

; I/O PORT DEFINITIONS **********************

KEYBOARD_PORT:           EQU $0080
DATA_PORT:               EQU $00BE
CTRL_PORT:               EQU $00BF
JOY_PORT:                EQU $00C0
CONTROLLER_02:           EQU $00F5
CONTROLLER_01:           EQU $00FC
SOUND_PORT:              EQU $00FF

FNAME "output\MONTEZUMA-S-REVENGE-1984-NEW.ROM"
CPU Z80

    ORG     $8000

; =============================================================================
; CARTRIDGE HEADER
; $55,$AA (rather than $AA,$55) makes the BIOS skip its title screen and
; start the game at once. The words after it tell the BIOS where the game
; keeps its sprite tables, work buffer and controller map in RAM.
; =============================================================================
    DW      $AA55                           ; bytes $55, $AA: no BIOS title screen
    DW      $7300                           ; local sprite table: Joe's two sprites, then the enemies'
    DW      $72E0                           ; sprite order table (INIT_SPR_NM_TBL, WR_SPR_NM_TBL)
    DW      $7210                           ; BIOS work buffer (unused)
    DW      $7005                           ; controller map for the BIOS POLLER (unused)
    DW      START                           ; start address
    DB      $C9, $00, $00                   ; RST $08-$30: unused, each a RET
    DB      $C9, $00, $00
    DB      $C9, $00, $00
    DB      $C9, $00, $00
    DB      $C9, $00, $00
    DB      $C9, $00, $00
    RETI                                    ; maskable interrupt (unused)
    DB      $00

; NMI vector: the frame interrupt, at every vertical blank.
CART_ENTRY:
    JP      NMI
    DB      $0B                             ; the game's name for the BIOS title screen would start here
; =============================================================================
; START ($8025): the BIOS jumps here at power-on. Clear the RAM, set up the
; video chip (Graphics I: patterns $0000, names $1800, colours $2000, sprite
; attributes $1B00, sprite patterns $3800), place Joe's sprites and load the
; sprite patterns, then fall into the title screen.
; =============================================================================
START:
    LD      HL, $7000                       ; clear $7000-$73FF
    LD      BC, $03FF
    LD      (HL), $00
    PUSH    HL
    POP     DE
    INC     DE
    LDIR
    LD      SP, $73C0                       ; the stack grows down from $73BF
    LD      BC, $0100                       ; register 1 = 0: display off
    CALL    WRITE_REGISTER
    CALL    CLEAR_VRAM                      ; clear all 16 KB of VRAM
    CALL    MODE_1
    LD      BC, $0701                       ; register 7 = $01: black backdrop
    CALL    WRITE_REGISTER
    CALL    LOAD_ASCII                      ; the BIOS font into the pattern table

; Joe's two sprites, at the top of the entrance hall's left pole, into
; the local sprite table: with BIOS MUX_SPRITES set, sprite attribute
; writes go there.
    LD      HL, $73C7                       ; MUX_SPRITES
    LD      (HL), $01
    LD      HL, JOE_START_SPRITES
    LD      DE, $0000
    LD      IY, $0002
    LD      A, $00                          ; table 0: sprite attributes
    CALL    PUT_VRAM
    LD      HL, $73C7
    LD      (HL), $00
    LD      A, $08                          ; sprite order 0-7...
    CALL    INIT_SPR_NM_TBL
    LD      A, $08                          ; ...and write the 8 sprites to VRAM
    CALL    WR_SPR_NM_TBL
    LD      DE, $7200                       ; checkered copies of Joe's legs...
    LD      HL, GFX_JOE_LEGS
    CALL    DITHER_COPY
    LD      DE, $7220                       ; ...and body, for the zapped frames
    LD      HL, GFX_JOE_BODY
    CALL    DITHER_COPY
    LD      A, $01                          ; table 1: sprite patterns, Joe's and the enemies'
    CALL    LOADER
    DW      GFX_JOE_BODY                    ; Joe's body: standing right (and walking)
    DB      $34, 4
    DW      GFX_JOE_BODY                    ; copies no frame uses
    DB      $38, 4
    DW      GFX_JOE_BODY
    DB      $3C, 4
    DW      GFX_JOE_BODY                    ; jumping right: the standing body...
    DB      $4C, 4
    DW      $8710                           ; ...its lower left quarter
    DB      $4D, 1
    DW      $8718                           ; ...its lower right quarter
    DB      $4F, 1
    DW      GFX_JOE_CLIMB                   ; on a ladder
    DB      $54, 4
    DW      GFX_JOE_CLIMB                   ; on a rope: the ladder body...
    DB      $5C, 4
    DW      $8780                           ; ...lower left quarter
    DB      $5D, 1
    DW      $8788                           ; ...lower right quarter
    DB      $5F, 1
    DW      GFX_JOE_CLIMB                   ; on a pole: the ladder body
    DB      $64, 4
    DW      GFX_JOE_DEAD                    ; lying dead from a fall
    DB      $68, 4
    DW      GFX_JOE_BODY                    ; walking right: the standing body...
    DB      $6C, 4
    DW      GFX_JOE_WALK                    ; ...lower left quarter
    DB      $6D, 1
    DW      $86F0                           ; ...lower right quarter
    DB      $6F, 1
    DW      GFX_JOE_BURNT                   ; burnt (his ghost, a single sprite)
    DB      $78, 4
    DW      GFX_JOE_LEGS                    ; Joe's hat, face and legs: standing right
    DB      $98, 4
    DW      GFX_JOE_LEGS                    ; walking right: the standing legs...
    DB      $9C, 4
    DW      $8622                           ; ...lower left quarter
    DB      $9D, 1
    DW      $86F8                           ; ...lower right quarter
    DB      $9F, 1
    DW      GFX_JOE_LEGS                    ; walking right, another frame...
    DB      $A0, 4
    DW      $8700                           ; ...lower left quarter
    DB      $A1, 1
    DW      $8708                           ; ...lower right quarter
    DB      $A3, 1
    DW      GFX_JOE_JUMP                    ; jumping right
    DB      $B0, 4
    DW      GFX_JOE_LADDER_LEGS             ; ladder
    DB      $B8, 4
    DW      GFX_JOE_ROPE_LEGS               ; rope
    DB      $C0, 4
    DW      GFX_JOE_POLE_LEGS               ; pole
    DB      $C8, 4
    DW      GFX_JOE_DEAD_LEGS               ; lying dead from a fall, two frames: the first
    DB      $CC, 4
    DW      GFX_JOE_DEAD_LEGS               ; the second: the first...
    DB      $D0, 4
    DW      $8808                           ; ...its upper left quarter
    DB      $D0, 1
    DW      $8810                           ; ...upper right quarter
    DB      $D2, 1
    DW      $7200                           ; zapped: the checkered legs and body
    DB      $D4, 8
    DW      GFX_SKULL                       ; skull
    DB      $0C, 4
    DW      GFX_SKULL_ROLL                  ; rolling skull, 45 degrees
    DB      $10, 4
    DW      GFX_SKULL_ROLL_2                ; rolling skull, 90 degrees
    DB      $14, 4
    DW      GFX_SPIDER                      ; spider
    DB      $2C, 4
    DB      $00, $00                        ; end

; =============================================================================
; TITLE SCREEN ($8116): PARKER BROTHERS PRESENTS / MONTEZUMA'S REVENGE in
; letters enlarged from the BIOS font, and SELECT LEVEL 1, 2, 3. Wait for
; keypad 1, 2 or 3, build the game's tile tables and start a new game.
; =============================================================================
TITLE_SCREEN:
    CALL    TURN_OFF_SOUND                  ; sound off
    CALL    LOAD_ASCII                      ; the BIOS font, again
    LD      DE, $0041                       ; enlarge the 26 capitals of the font
    LD      HL, $0080                       ; ($41-$5A) into 2x2 tiles from $80
    LD      BC, $001A
    LD      A, $03
    CALL    ENLARGE
    CALL    LOAD_TILE_COLOURS               ; the boot tile colours
    LD      A, $A0                          ; tiles $80-$EF yellow: colour entries 16-29
    LD      HL, $2010
    LD      DE, $000E
    CALL    FILL_VRAM
    LD      A, $02                          ; table 2: names
    CALL    LOADER
    DW      TITLE_PARKER                    ; "PARKER BROTHERS ", row 2 column 8
    DB      $48, 16
    DW      TITLE_PRESENTS                  ; "PRESENTS", row 4 column 12
    DB      $8C, 8
    DW      TITLE_MONTEZUMAS                ; "MONTEZUMA'S", big letters, top halves: row 6
    DB      $C6, 21
    DW      TITLE_MONTEZUMAS_2              ; bottom halves: row 7
    DB      $E6, 21
    DB      $00, $00                        ; end

; "REVENGE": 13 of the 14 tiles in each half (the last E's right half
; is left out).
    LD      HL, TITLE_REVENGE               ; top halves: row 9 column 10
    LD      DE, $012A
    LD      BC, $010D
    CALL    TILE_ROWS
    LD      HL, TITLE_REVENGE_2             ; bottom halves: row 10
    LD      DE, $014A
    LD      BC, $010D
    CALL    TILE_ROWS
    LD      HL, TITLE_TEXT                  ; "SELECT LEVEL   1, 2, 3.", row 15 column 5
    LD      DE, $01E5
    LD      BC, $0117
    CALL    TILE_ROWS
    LD      BC, $01C0                       ; register 1 = $C0: display on, no frame interrupt
    CALL    WRITE_REGISTER

TITLE_WAIT_KEY:
    CALL    CONTROLLER_SCAN                 ; read the controllers
    LD      A, ($73F0)                      ; BIOS keypad 1 code ($80 + key code)
    CP      $82                             ; key 1
    JR      NZ, LOC_8187
    LD      A, $01
    JR      TITLE_LEVEL

LOC_8187:
    CP      $88                             ; key 2
    JR      NZ, LOC_818F
    LD      A, $02
    JR      TITLE_LEVEL

LOC_818F:
    CP      $83                             ; key 3
    JR      NZ, TITLE_WAIT_KEY
    LD      A, $03

TITLE_LEVEL:
    LD      ($71A6), A                      ; the level
    LD      BC, $0180                       ; display off
    CALL    WRITE_REGISTER
    XOR     A                               ; clear the enlarged letters (tiles $80-$F5)...
    LD      HL, $0400
    LD      DE, $03AC
    CALL    FILL_VRAM
    XOR     A                               ; ...and the screen
    LD      HL, $1800
    LD      DE, $0300
    CALL    FILL_VRAM
    CALL    BUILD_TILE_TABLES               ; the four tile pattern tables
    LD      A, $02                          ; the main loop's four task counters: each task
    LD      ($7073), A                      ; first runs on its second pass
    LD      ($7074), A
    LD      ($7012), A
    LD      ($7068), A
    LD      HL, FLIP_SPRITES                ; sprite patterns flipped upside down (rolling skulls)
    CALL    REFLECT_LIST
    CALL    MIRROR_SPRITES                  ; and mirrored (facing left)
    XOR     A                               ; no sound effect playing
    LD      ($702C), A
    LD      ($7036), A
    LD      BC, $01E2                       ; register 1 = $E2: display and frame interrupt on, 16x16 sprites
    CALL    WRITE_REGISTER
    JP      NEW_GAME                        ; a new game

; =============================================================================
; BUILD_TILE_TABLES ($81DC): fill the four tile pattern tables the frame
; interrupt cycles through to animate tiles ($A9F3): each gets the BIOS font
; and the main tileset ($8392), its own frame of the animated tiles (fire
; $D2-$D5, conveyors $04-$06, the torch's flame $D0, the creatures' $A0 and
; $A3, and tile $38), and the mirror images of some tiles ($8314). The table
; at $0000 also gets the boot tile colours ($8308), and is left current.
; =============================================================================
BUILD_TILE_TABLES:
    LD      C, $01                          ; pattern table 1 ($0800)
    LD      A, $08
    CALL    LOAD_TILESET
    LD      A, $03                          ; table 3: tile patterns
    CALL    LOADER
    DW      GFX_FIRE                        ; fire
    DB      $D2, 4
    DW      GFX_TORCH                       ; the torch's flame
    DB      $D0, 1
    DW      GFX_FLAMES                      ; the fire pit's flames
    DB      $38, 1
    DW      GFX_CONVEYOR                    ; conveyor
    DB      $04, 3
    DB      $00, $00                        ; end
    CALL    MIRROR_TILES
    LD      C, $02                          ; pattern table 2 ($1000)
    LD      A, $10
    CALL    LOAD_TILESET
    LD      A, $03
    CALL    LOADER
    DW      $8518                           ; fire, turned one pattern on
    DB      $D2, 3
    DW      GFX_FIRE
    DB      $D5, 1
    DW      GFX_TORCH_2                     ; the torch's flame
    DB      $D0, 1
    DW      GFX_FLAMES_2                    ; the fire pit's flames
    DB      $38, 1
    DW      GFX_CONVEYOR_2                  ; conveyor
    DB      $04, 3
    DW      GFX_CREATURE_2                  ; the creature's other frame
    DB      $A0, 1
    DW      $8678
    DB      $A3, 1
    DB      $00, $00                        ; end
    CALL    MIRROR_TILES
    LD      C, $05                          ; pattern table 5 ($2800)
    LD      A, $28
    CALL    LOAD_TILESET
    LD      A, $03
    CALL    LOADER
    DW      $8520                           ; fire, turned two patterns on
    DB      $D2, 2
    DW      GFX_FIRE
    DB      $D4, 2
    DW      GFX_TORCH                       ; the torch's flame
    DB      $D0, 1
    DW      GFX_FLAMES_3                    ; the fire pit's flames
    DB      $38, 1
    DW      GFX_CONVEYOR_3                  ; conveyor
    DB      $04, 3
    DW      GFX_CREATURE_2                  ; the creature's other frame
    DB      $A0, 1
    DW      $8678
    DB      $A3, 1
    DB      $00, $00                        ; end
    CALL    MIRROR_TILES
    LD      C, $00                          ; pattern table 0 ($0000), with the boot colours
    XOR     A
    CALL    LOAD_TILESET
    CALL    LOAD_TILE_COLOURS
    LD      A, $03
    CALL    LOADER
    DW      $8528                           ; fire, turned three patterns on
    DB      $D2, 1
    DW      GFX_FIRE
    DB      $D3, 3
    DW      GFX_TORCH_3                     ; the torch's flame
    DB      $D0, 1
    DW      GFX_FLAMES_3                    ; the fire pit's flames
    DB      $38, 1
    DW      GFX_CONVEYOR_4                  ; conveyor
    DB      $04, 3
    DB      $00, $00                        ; end
    CALL    MIRROR_TILES
    RET

; DITHER_COPY ($827F): copy 16 byte pairs from HL to DE, keeping the odd
; pixels of the first byte of each pair and the even pixels of the second:
; a checkered copy of a 16x16 sprite.
DITHER_COPY:
    LD      B, $10

LOC_8281:
    PUSH    BC
    LD      BC, $AA55
    LD      A, (HL)
    AND     B
    LD      (DE), A
    INC     DE
    INC     HL
    LD      A, (HL)
    AND     C
    LD      (DE), A
    INC     DE
    INC     HL
    POP     BC
    DJNZ    LOC_8281
    RET

; Title screen text: ASCII, and tile numbers of the big letters (letter n of
; the alphabet is the 2x2 block from $80 + 4n: top left, bottom left, top
; right, bottom right).
TITLE_TEXT:
    DB      "SELECT LEVEL   1, 2, 3."       ; row 15

TITLE_PARKER:
    DB      "PARKER BROTHERS "              ; row 2

TITLE_PRESENTS:
    DB      "PRESENTS"                      ; row 4

TITLE_REVENGE:
    DB      $C4, $C6, $90, $92, $D4, $D6, $90 ; REVENGE, top halves
    DB      $92, $B4, $B6, $98, $9A, $90, $92

TITLE_REVENGE_2:
    DB      $C5, $C7, $91, $93, $D5, $D7, $91 ; bottom halves
    DB      $93, $B5, $B7, $99, $9B, $91, $93

TITLE_MONTEZUMAS:
    DB      $B0, $B2, $B8, $BA, $B4, $B6, $CC, $CE, $90, $92, $E4 ; MONTEZUMA'S, top halves ($27: the apostrophe)
    DB      $E6, $D0, $D2, $B0, $B2, $80, $82, $27, $C8, $CA

TITLE_MONTEZUMAS_2:
    DB      $B1, $B3, $B9, $BB, $B5, $B7, $CD, $CF, $91, $93, $E5 ; bottom halves
    DB      $E7, $D1, $D3, $B1, $B3, $81, $83, $00, $C9, $CB

; LOAD_TILE_COLOURS ($8308): the boot tile colours. Frames and rooms change
; some of them later ($8EB0, $A8D6).
LOAD_TILE_COLOURS:
    LD      A, $04                          ; table 4: tile colours
    CALL    LOADER
    DW      BOOT_COLOURS                    ; entries 0-27 (tiles $00-$DF)
    DB      $00, 28
    DB      $00, $00                        ; end
    RET

; MIRROR_TILES ($8314): mirror tiles of the current pattern table into
; their facing-the-other-way twins (list at $837D).
MIRROR_TILES:
    LD      HL, MIRROR_TILE_LIST
    JP      REFLECT_LIST

; Lists for REFLECT_LIST ($AE3B): a mode (0: upside down, 1: left-right),
; a PUT_VRAM table, then (from, to) pattern pairs up to $FF.
;
; The rolling skull's upside-down frames: sprite $18 is $10 upside down,
; $1C is $0C (the top and bottom quarters swap too).
FLIP_SPRITES:
    DB      $00, $01                        ; upside down, sprite patterns
    DB      $10, $19, $11, $18, $12, $1B, $13, $1A
    DB      $0C, $1D, $0D, $1C, $0E, $1F, $0F, $1E
    DB      $FF                             ; end

; MIRROR_SPRITES ($8352) list: (sprite, right half of its mirror image)
; pairs up to $FF; the sprite's left half mirrors into the right half of
; the new one and its right half into the left. Joe facing left, the
; rolling skull's other frames and the spider's second frame.
MIRROR_SPRITE_LIST:
    DB      $D4, $DE                        ; Joe zapped: legs $D4 -> $DC,
    DB      $D8, $E2                        ; body $D8 -> $E0
    DB      $18, $22                        ; rolling skull: $18 -> $20,
    DB      $14, $26                        ; $14 -> $24,
    DB      $10, $2A                        ; $10 -> $28
    DB      $2C, $32                        ; spider: $2C -> $30
    DB      $34, $42                        ; Joe's body: standing $34 -> $40,
    DB      $4C, $52                        ; jumping $4C -> $50,
    DB      $54, $5A                        ; ladder $54 -> $58,
    DB      $5C, $62                        ; rope $5C -> $60
    DB      $98, $A6                        ; legs: standing $98 -> $A4
    DB      $6C, $7E                        ; body: walking $6C -> $7C
    DB      $9C, $AA                        ; legs: walking $9C -> $A8,
    DB      $A0, $AE                        ; $A0 -> $AC,
    DB      $A0, $AE                        ; (again)
    DB      $B0, $B6                        ; jumping $B0 -> $B4,
    DB      $B8, $BE                        ; ladder $B8 -> $BC,
    DB      $C0, $C6                        ; rope $C0 -> $C4
    DB      $FF                             ; end

; MIRROR_SPRITES ($8352): mirror 16x16 sprite patterns across a vertical
; axis, from the list at $832D.
MIRROR_SPRITES:
    LD      HL, MIRROR_SPRITE_LIST

MIRROR_SPRITES_LOOP:
    LD      A, (HL)
    CP      $FF
    RET     Z
    LD      D, $00                          ; DE: the sprite
    LD      BC, $0002
    LD      E, A
    INC     HL
    PUSH    HL
    LD      A, (HL)                         ; HL: its mirror image's right half
    LD      L, A
    LD      H, $00
    LD      A, $01                          ; table 1: sprite patterns
    PUSH    DE
    PUSH    HL
    PUSH    BC
    PUSH    AF
    CALL    REFLECT_VERTICAL                ; its left column into the right one
    POP     AF
    POP     BC
    POP     HL
    POP     DE
    INC     DE
    INC     DE
    DEC     HL
    DEC     HL
    CALL    REFLECT_VERTICAL                ; its right column into the left one
    POP     HL
    INC     HL
    JR      MIRROR_SPRITES_LOOP

; MIRROR_TILES list: the creature facing the other way ($A0-$A3 ->
; $A4-$A7), the conveyor pushing the other way ($04-$06 -> $BA-$B8), and
; the right halves of the torch ($62 -> $63, $D0 -> $D1).
MIRROR_TILE_LIST:
    DB      $01, $03                        ; left-right, tile patterns
    DB      $A0, $A4                        ; creature
    DB      $A1, $A5
    DB      $A2, $A6
    DB      $A3, $A7
    DB      $04, $BA                        ; conveyor
    DB      $05, $B9
    DB      $06, $B8
    DB      $62, $63                        ; torch
    DB      $D0, $D1
    DB      $FF                             ; end

; LOAD_TILESET ($8392): point the video chip at pattern table C (A: its
; address's high byte, kept in $73F9) and load the BIOS font and the main
; tileset into it.
LOAD_TILESET:
    PUSH    AF
    LD      B, $04                          ; register 4: the pattern table
    CALL    WRITE_REGISTER
    POP     AF
    LD      ($73F9), A                      ; the table the BIOS writes patterns to
    CALL    LOAD_ASCII
    LD      A, $03                          ; table 3: tile patterns
    CALL    LOADER
    DW      GFX_BRICK                       ; brick, and the HUD boxes' edges ($09-$0C)
    DB      $08, 5
    DW      GFX_ROPE                        ; rope; $91-$94 (a key, unused); $95 (replaced
    DB      $90, 8                          ; below); the sword's top half ($96-$97)
    DW      GFX_AMULET                      ; amulet's left half (HUD icon); torch base
    DB      $60, 3
    DW      GFX_HAT                         ; a hat (spare life)
    DB      $6F, 1
    DW      GFX_SWORD_BOTTOM                ; the sword's bottom half (HUD icon)
    DB      $6C, 2
    DW      GFX_SWORD_TOP                   ; the sword's top half (HUD icon)
    DB      $74, 2
    DW      GFX_JEWEL                       ; the jewel's left half; the sword's bottom half
    DB      $98, 4
    DW      GFX_KEY                         ; keys: blue,
    DB      $68, 4
    DW      GFX_KEY                         ; red,
    DB      $70, 4
    DW      GFX_KEY                         ; gold
    DB      $78, 4
    DW      GFX_CREATURE                    ; creature
    DB      $A0, 4
    DW      GFX_AMULET                      ; the amulet's left half; $AA (unused)
    DB      $A8, 3
    DW      GFX_DOOR                        ; red door: closed, open (top, the rest); $C4: a
    DB      $C0, 6                          ; rope's top; $C5 (unused)
    DW      GFX_DOOR                        ; red door's bottom
    DB      $C7, 1
    DW      GFX_DOOR                        ; pole: the doors' bar
    DB      $95, 1
    DW      GFX_DOOR                        ; gold door, as the red one
    DB      $B0, 5
    DW      GFX_DOOR                        ; gold door's bottom
    DB      $B7, 1
    DW      GFX_DOOR                        ; blue door
    DB      $BB, 5
    DW      GFX_DOOR                        ; blue door's bottom
    DB      $9C, 1
    DW      GFX_LADDER                      ; a ladder's top, set into a floor
    DB      $10, 2
    DW      GFX_LADDER                      ; ladder
    DB      $88, 2
    DW      GFX_DIGITS_TOP                  ; big digits: top halves
    DB      $18, 10
    DW      GFX_DIGITS_BOTTOM               ; bottom halves
    DB      $28, 10
    DW      GFX_BARRIER                     ; barrier (redrawn as it crackles, $A92F)
    DB      $E0, 1
    DW      GFX_DISAPPEARING                ; disappearing floor (the same)
    DB      $E8, 1
    DB      $00, $00                        ; end
    RET

; CLEAR_RAM ($840B): clear BC + 1 bytes from HL.
CLEAR_RAM:
    LD      (HL), $00
    PUSH    HL
    POP     DE
    INC     DE
    LDIR
    RET

; CLEAR_VRAM ($8413): clear all 16 KB of video memory.
CLEAR_VRAM:
    LD      HL, $0000
    LD      DE, $4000
    XOR     A
    CALL    FILL_VRAM
    RET

; =============================================================================
; GRAPHICS
; Tile and sprite patterns, 8 bytes each, as the loader calls at $8081 (sprite
; patterns), $81DC (animated tiles) and $8392 (main tileset) copy them. A 16x16
; sprite is four patterns: top left, bottom left, top right, bottom right.
; Some blocks overlap, and some patterns serve as both tiles and sprites.
; =============================================================================
;
; Boot tile colours, one byte per 8 tiles (foreground colour in the high
; nibble, background in the low): entries 0-27, loaded by $8308.
BOOT_COLOURS:
    DB      $90, $A7, $4A, $8B, $B1, $F0, $F0, $F0 ; tiles $00-$3F
    DB      $F0, $F0, $F0, $F0, $20, $90, $E0, $40 ; tiles $40-$7F
    DB      $40, $40, $E0, $90, $20, $20, $40, $90 ; tiles $80-$BF
    DB      $E0, $4A, $90, $60              ; tiles $C0-$DF
    DB      $40, $40, $00, $00, $00, $00    ; not loaded: the barrier task sets entries 28 and 29

GFX_BRICK:
    DB      $FB, $FB, $FB, $00, $7F, $7F, $7F, $00 ; $08 brick
    DB      $FB, $FB, $FB, $00, $00, $00, $00, $00 ; $09-$0C the HUD boxes' top, left, right and bottom edges
    DB      $F0, $F0, $F0, $00, $F0, $F0, $F0, $00
    DB      $0B, $0B, $0B, $00, $0F, $0F, $0F, $00
    DB      $00, $00, $00, $00, $7F, $7F, $7F, $00

GFX_DIGITS_TOP:
    DB      $38, $7C, $FE, $FE, $EE, $C6, $C6, $C6 ; $18-$21 big digits 0-9, top halves
    DB      $38, $78, $F8, $F8, $F8, $F8, $38, $38
    DB      $38, $7C, $FE, $FE, $EE, $C6, $C6, $0E
    DB      $38, $7C, $FE, $FE, $FE, $C6, $06, $1C
    DB      $1C, $3C, $3C, $7C, $7C, $EC, $EC, $CC
    DB      $FE, $FE, $FE, $FE, $C6, $E0, $F8, $3E
    DB      $38, $7C, $FE, $FE, $EE, $C0, $F8, $FC
    DB      $FE, $FE, $FE, $FE, $FE, $0E, $0E, $1E
    DB      $38, $7C, $FE, $FE, $EE, $C6, $EE, $7C
    DB      $38, $7C, $FE, $FE, $EE, $C6, $EE, $7E

GFX_DIGITS_BOTTOM:
    DB      $EE, $FE, $FE, $FE, $FE, $FE, $7C, $38 ; $28-$31 bottom halves
    DB      $38, $38, $38, $38, $FE, $FE, $FE, $FE
    DB      $1E, $3C, $78, $70, $FE, $FE, $FE, $FE
    DB      $1C, $06, $C6, $EE, $FE, $FE, $7C, $38
    DB      $CC, $FE, $FE, $FE, $FE, $FE, $18, $18
    DB      $0E, $C6, $C6, $EE, $FE, $FE, $7C, $38
    DB      $EE, $C6, $EE, $FE, $FE, $FE, $7C, $38
    DB      $1E, $1C, $3C, $38, $78, $78, $70, $70
    DB      $EE, $C6, $EE, $FE, $FE, $FE, $7C, $38
    DB      $3E, $06, $C6, $EE, $FE, $FE, $7C, $38

GFX_HAT:
    DB      $00, $00, $3C, $3C, $7E, $7E, $00, $00 ; $6F a hat: a spare life in the HUD

; Fire's flame tops: $D2-$D5 in each pattern table, the four patterns turned
; one place further each time, so the flames move.
GFX_FIRE:
    DB      $08, $06, $07, $07, $0F, $1F, $7F, $FF
    DB      $00, $00, $24, $33, $71, $FD, $FF, $FF
    DB      $00, $00, $01, $81, $F1, $F9, $FB, $FF
    DB      $00, $80, $00, $81, $C2, $E6, $EF, $FF

; Conveyor frames, $04-$06 in each pattern table (mirrored into $B8-$BA):
; four blocks of 24 bytes, the second and fourth starting on the previous
; one's last 2 bytes.
GFX_CONVEYOR:
    DB      $C0, $C0, $3F, $3F, $3F, $3F, $03, $03 ; table 1
    DB      $C0, $C0, $FF, $FF, $FF, $FF, $03, $03
    DB      $C0, $C0, $FC, $FC, $FC, $FC

GFX_CONVEYOR_2:
    DB      $03, $03, $3F, $FF, $FF, $3F, $00, $00 ; table 2
    DB      $03, $03, $FF, $FF, $FF, $FF, $C0, $C0
    DB      $00, $00, $FC, $FF, $FF, $FC, $C0, $C0

GFX_CONVEYOR_3:
    DB      $0C, $0C, $3F, $3F, $3F, $3F, $C0, $C0 ; table 5
    DB      $0C, $0C, $FF, $FF, $FF, $FF, $30, $30
    DB      $03, $03, $FC, $FC, $FC, $FC

GFX_CONVEYOR_4:
    DB      $30, $30, $3F, $3F, $3F, $3F, $0C, $0C ; table 0
    DB      $30, $30, $FF, $FF, $FF, $FF, $0C, $0C
    DB      $30, $30, $FC, $FC, $FC, $FC, $0C, $0C

GFX_JEWEL:
    DB      $00, $7E, $81, $BD, $BD, $BD, $BD, $BD ; $98-$99 jewel: left half (the right half, $D8-$D9, is blank)
    DB      $BD, $BD, $BD, $81, $7E, $00, $00, $00

GFX_SWORD_BOTTOM:
    DB      $03, $03, $0F, $0F, $03, $03, $03, $00 ; $9A-$9B sword: bottom half; also its HUD icon's ($6C-$6D)
    DB      $80, $80, $E0, $E0, $80, $80, $80, $00

GFX_LADDER:
    DB      $30, $30, $30, $30, $3F, $30, $30, $30 ; $88-$89 ladder; also $10-$11, its top set into a floor
    DB      $0C, $0C, $0C, $0C, $FC, $0C, $0C, $0C

; Barrier ($E0): an 8-byte window into these 14 bytes, 2 bytes further on
; each frame of $7096, so the gap in the beam moves ($A97A).
GFX_BARRIER:
    DB      $7C, $6C, $6C, $6C, $6C, $7C, $10
    DB      $10, $7C, $6C, $6C, $6C, $6C, $7C

; Disappearing floor ($E8): one of these two patterns by frame parity.
GFX_DISAPPEARING:
    DB      $FF, $66, $C3, $66, $FF, $00, $00, $00
    DB      $FF, $66, $18, $66, $FF, $00, $00, $00

GFX_SPIDER:
    DB      $00, $00, $00, $00, $00, $00, $00, $08 ; sprite $2C spider (mirrored into $30)
    DB      $14, $23, $09, $17, $23, $0B, $17, $21
    DB      $00, $00, $00, $00, $00, $10, $28, $44
    DB      $90, $A8, $C4, $D0, $E8, $C4, $C0, $80

GFX_ROPE:
    DB      $18, $18, $18, $18, $0C, $0C, $0C, $0C ; $90 rope

GFX_KEY:
    DB      $07, $0F, $1C, $1C, $0F, $03, $03, $01 ; $68-$6B, $70-$73, $78-$7B keys; $91-$94 (unused)
    DB      $E0, $F0, $38, $38, $F0, $C0, $C0, $80
    DB      $01, $01, $03, $01, $03, $01, $00, $00
    DB      $80, $80, $80, $80, $80, $80, $00, $00
    DB      $3C, $1C, $00, $00, $00, $38, $3C, $3C ; sprite $9D: Joe's walking legs; $95 (replaced)

GFX_SWORD_TOP:
    DB      $02, $03, $03, $03, $03, $03, $03, $03 ; $96-$97 sword: top half; its HUD icon's ($74-$75)
    DB      $00, $00, $80, $80, $80, $80, $80, $80

GFX_AMULET:
    DB      $00, $2D, $3F, $3F, $2D, $0C, $0C, $0C ; $A8-$A9 amulet: left half (the right half, $AE-$AF,
    DB      $0C, $0C, $0C, $0C, $0C, $00, $00, $00 ; is blank); its HUD icon's ($60-$61)
    DB      $1F, $0F, $03, $03, $03, $01    ; $62 torch base, left half (mirrored into $63); $AA

GFX_CREATURE:
    DB      $00, $00, $00, $03, $0C, $0F, $00, $00 ; (unused); from here $A0-$A3 creature (mirrored into $A4-$A7)
    DB      $00, $00, $00, $C0, $E0, $F0, $30, $F0
    DB      $07, $1E, $18, $18, $18, $0C, $06, $03
    DB      $C0, $00, $00, $00, $01, $03, $0E, $FC

GFX_CREATURE_2:
    DB      $00, $00, $00, $03, $0C, $3F, $00, $00 ; its other frame: $A0 and $A3 in pattern tables 2 and 5
    DB      $C0, $00, $00, $00, $04, $0C, $0C, $FC

; Doors, and a pole: the same bar. Each door is $B0/$BB/$C0 (closed), its
; open top (+1, +2) and open rest (+3), then $C4 a rope's top and $C5
; (unused); the bottom tiles $B7/$9C/$C7 and the pole $95 are the bar.
GFX_DOOR:
    DB      $7E, $7E, $7E, $7E, $7E, $7E, $7E, $7E
    DB      $00, $07, $0F, $09, $29, $6F, $E9, $E9
    DB      $00, $E0, $E0, $28, $2C, $EE, $2F, $2F
    DB      $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF
    DB      $FF, $FF, $7E, $7E, $3C, $3C, $3C, $3C

GFX_JOE_BODY:
    DB      $07, $07, $1F, $3F, $38, $08, $00, $1F ; (overlapping $C5) sprite $34 Joe's body, standing
    DB      $3F, $0F, $07, $03, $33, $3F, $3C, $38
    DB      $C0, $C0, $F8, $F8, $80, $00, $00, $E0
    DB      $C0, $C0, $C0, $C0, $E0, $E0, $E0, $E0

GFX_JOE_LEGS:
    DB      $00, $07, $07, $07, $00, $00, $30, $38 ; sprite $98 Joe's hat, face and legs, standing
    DB      $3C, $1C, $00, $00, $00, $38, $3C, $1C
    DB      $00, $60, $E0, $C0, $00, $B0, $30, $BC
    DB      $3C, $80, $00, $00, $00, $E0, $F0, $F0

GFX_JOE_WALK:
    DB      $3F, $0F, $07, $03, $33, $3F, $07, $07 ; walking body: lower quarters ($6D, $6F)
    DB      $C0, $C0, $C0, $C0, $E0, $E0, $00, $00
    DB      $3C, $80, $00, $00, $18, $F8, $E0, $00 ; walking legs: $9F,
    DB      $3C, $1C, $00, $00, $00, $07, $07, $07 ; $A1, $A3
    DB      $3C, $80, $00, $00, $00, $00, $80, $80
    DB      $07, $0F, $0F, $3F, $3F, $1F, $0F, $0F ; jumping body: lower quarters ($4D, $4F)
    DB      $C0, $C0, $C0, $E0, $E0, $F0, $70, $70

GFX_JOE_JUMP:
    DB      $00, $07, $07, $27, $70, $78, $70, $30 ; sprite $B0 jumping legs
    DB      $00, $00, $00, $00, $00, $0F, $0F, $0F
    DB      $00, $60, $E0, $C0, $0C, $3C, $3C, $B8
    DB      $00, $86, $0E, $0E, $0C, $00, $80, $80

GFX_JOE_CLIMB:
    DB      $03, $03, $1F, $1F, $0F, $03, $02, $01 ; sprite $54 body on a ladder, rope or pole
    DB      $39, $3F, $3F, $0F, $0F, $0F, $0F, $0F
    DB      $C0, $C0, $F8, $F8, $F0, $C0, $40, $80
    DB      $98, $FC, $FC, $F0, $F0, $F0, $F0, $F0

GFX_JOE_LADDER_LEGS:
    DB      $00, $00, $30, $39, $36, $06, $01, $00 ; sprite $B8 legs on a ladder
    DB      $00, $00, $00, $00, $00, $0E, $00, $00
    DB      $00, $00, $00, $80, $60, $60, $80, $00
    DB      $0C, $0C, $00, $00, $00, $60, $70, $70
    DB      $1A, $1F, $1F, $0F, $0F, $07, $01, $00 ; body on a rope: lower quarters ($5D, $5F)
    DB      $40, $FC, $FC, $FC, $FC, $FC, $F0, $F0

GFX_JOE_ROPE_LEGS:
    DB      $00, $00, $00, $01, $1A, $01, $00, $00 ; sprite $C0 legs on a rope
    DB      $00, $00, $00, $06, $03, $03, $00, $00
    DB      $00, $00, $00, $80, $40, $98, $00, $00
    DB      $00, $00, $00, $00, $00, $60, $E0, $80

GFX_JOE_POLE_LEGS:
    DB      $00, $00, $00, $01, $06, $06, $01, $00 ; sprite $C8 legs on a pole
    DB      $00, $00, $00, $00, $34, $3E, $1E, $0C
    DB      $00, $00, $00, $80, $60, $60, $80, $00
    DB      $00, $00, $00, $00, $2C, $7C, $78, $30

; The fire pit's flames ($38), a pattern for each pattern table (1, 2, then
; 5 and 0).
GFX_FLAMES:
    DB      $00, $10, $08, $20, $14, $22, $08, $42

GFX_FLAMES_2:
    DB      $00, $00, $24, $10, $28, $08, $10, $2C

GFX_FLAMES_3:
    DB      $00, $10, $2C, $30, $3C, $2A, $18, $6E

GFX_JOE_DEAD_LEGS:
    DB      $00, $0C, $3C, $78, $70, $60, $60, $7E ; sprite $CC (and $D0) Joe lying dead: legs
    DB      $00, $00, $00, $03, $04, $0B, $10, $1F
    DB      $00, $00, $00, $78, $78, $60, $60, $60
    DB      $60, $00, $00, $00, $80, $40, $20, $F8
    DB      $78, $78, $78, $18, $18, $18, $1E, $06 ; the other frame: upper quarters ($D0, $D2)
    DB      $00, $00, $00, $00, $1C, $1C, $7C, $60

GFX_SKULL_ROLL:
    DB      $00, $0F, $1F, $3F, $7E, $7E, $7F, $73 ; sprite $10 rolling skull, 45 degrees
    DB      $37, $1F, $0F, $03, $00, $00, $00, $00
    DB      $00, $00, $80, $C0, $60, $E0, $F0, $F0
    DB      $CC, $CC, $3C, $3C, $F8, $F0

GFX_SKULL_ROLL_2:
    DB      $00, $00, $00, $00, $1E, $3B, $73, $F3 ; (overlapping) sprite $14 rolling skull, 90 degrees
    DB      $FF, $FF, $F3, $73, $3B, $1E, $00, $00
    DB      $00, $00, $00, $00, $00, $00, $B8, $18
    DB      $B8, $B8, $18, $B8

GFX_JOE_DEAD:
    DB      $00, $00, $00, $00              ; (overlapping) sprite $68 Joe lying dead: body
    DB      $00, $0E, $1F, $1F, $3C, $3B, $34, $2F
    DB      $00, $3C, $3F, $07, $00, $00, $00, $00
    DB      $00, $00, $C0, $F8, $F8, $78, $A0, $D8
    DB      $00, $F8, $F8, $E0

GFX_JOE_BURNT:
    DB      $07, $1F, $7F, $FF, $FF, $7F, $3F, $FF ; sprite $78 Joe burnt: his ghost
    DB      $FF, $7F, $3E, $3C, $18, $00, $00, $00
    DB      $E0, $F8, $FC, $FF, $FF, $FE, $FF, $FF
    DB      $FE, $64, $30, $30, $60, $C0, $C0, $60

GFX_SKULL:
    DB      $00, $03, $07, $0F, $1F, $19, $11, $1F ; sprite $0C skull
    DB      $0F, $0F, $05, $00, $05, $07, $07, $00
    DB      $00, $C0, $E0, $F0, $F8, $98, $88, $F8
    DB      $F0, $F0, $A0, $00, $A0, $E0, $E0

; The torch's flame ($D0, mirrored into $D1): pattern tables 1 and 5, 2,
; and 0; the first overlaps the skull's last byte.
GFX_TORCH:
    DB      $00, $01, $01, $03, $07, $0F, $0F, $1F

GFX_TORCH_2:
    DB      $00, $00, $00, $03, $07, $07, $0F, $1F

GFX_TORCH_3:
    DB      $00, $04, $03, $07, $07, $0F, $1F, $1F

; Joe's two sprites at boot (Y, X, pattern, colour): the top of the
; entrance hall's left pole.
JOE_START_SPRITES:
    DB      $18, $0C, $04, $06              ; body: red
    DB      $1B, $0C, $08, $0B              ; hat, face and legs: yellow

; =============================================================================
; MOVE_TASK ($88D1): main-loop task, every frame (table at $A8A1). Set Joe's
; sprite patterns, move the enemies, read the joystick, then run Joe's state
; handler and apply his velocity (JOE_MOVE).
;
; Joe's RAM: $7300-$7307 his two sprites (body; hat, face and legs 3 lines
; lower), $7079 state, $7076/$7077 velocity (DX, DY), $7078 facing (the last
; non-zero DX), $7072 jump counter, $707C where a fall or jump began (Y),
; $70B2 the climb-down-onto-a-ladder counter, $7075 fire button latch, $70AB a
; 3-2-1-0 frame counter, $70A9 the death timer. JOE_TILES reads the tiles
; around his legs sprite into $7057-$705C: the row at his body (left, middle,
; right), then the row at his feet.
; =============================================================================
MOVE_TASK:
    CALL    JOE_SPRITES                     ; his sprite patterns, and footsteps
    LD      A, ($70AB)                      ; count $70AB 3, 2, 1, 0, 3, ...
    DEC     A
    JP      P, LOC_88DD
    LD      A, $03

LOC_88DD:
    LD      ($70AB), A
    CALL    MOVE_ENEMIES                    ; the enemies
    CALL    READ_CONTROLLERS
    LD      A, ($705F)                      ; walking into the pyramid at the start of a level:
    BIT     2, A                            ; hold the joystick down, and right or left towards
    JR      Z, MOVE_TASK_STATE
    LD      A, ($7301)                      ; the middle of the screen
    CP      $80
    LD      A, $86                          ; bit 7 + down + right
    JR      C, LOC_88F8
    LD      A, $8C                          ; bit 7 + down + left

LOC_88F8:
    LD      ($73EE), A

MOVE_TASK_STATE:
    CALL    JOE_TILES                       ; the tiles around him
    LD      HL, JOE_STATES                  ; run the handler for his state
    LD      A, ($7079)
    SLA     A
    CALL    TABLE_BYTE
    LD      E, (HL)
    INC     HL
    LD      D, (HL)
    EX      DE, HL
    CALL    CALL_HL
    JP      JOE_MOVE                        ; apply the velocity, leave the room

; Joe's state handlers, by $7079.
JOE_STATES:
    DW      JOE_STANDING                    ; 0 standing
    DW      JOE_STANDING                    ; 1 walking
    DW      JOE_JUMPING                     ; 2 jumping
    DW      JOE_LADDER                      ; 3 on a ladder
    DW      JOE_ROPE                        ; 4 on a rope
    DW      JOE_FALLING                     ; 5 sliding down a pole
    DW      JOE_FALLING                     ; 6 falling
    DW      JOE_LET_GO                      ; 7 (unused) letting go
    DW      JOE_ZAPPED                      ; 8 zapped: touched a barrier, an enemy or a creature
    DW      JOE_DEAD                        ; 9 dead from a fall
    DW      JOE_BURNT                       ; 10 burnt

; JOE_STANDING ($8929): states 0 and 1. Climb onto a ladder or rope, jump,
; walk, or fall off the edge.
JOE_STANDING:
    LD      A, ($705B)                      ; bricks at his feet and his body: shove him out
    CP      $08
    JR      NZ, JOE_STANDING_FIRE
    LD      A, ($7058)
    CP      $08
    JR      NZ, JOE_STANDING_FIRE
    LD      BC, $F800                       ; 8 pixels left if the tile left of his body is
    LD      A, ($7057)                      ; empty, else right
    CP      $00
    JR      Z, LOC_8943
    LD      B, $08

LOC_8943:
    JP      MOVE_JOE                        ; move him by B, C

JOE_STANDING_FIRE:
    LD      A, ($7057)                      ; fire beside him: burnt
    CALL    IS_HAZARD
    JR      NZ, JOE_STANDING_MOVE
    JP      JOE_BURN

JOE_STANDING_MOVE:
    LD      A, ($73EE)                      ; count steps while he moves
    AND     $0F
    CALL    STEP_IF_MOVING
    XOR     A
    LD      ($7077), A
    LD      BC, $0000
    LD      A, ($73EE)                      ; up, and a ladder at his body: climb
    AND     $01
    JR      Z, JOE_STANDING_DOWN
    LD      HL, $7058
    LD      A, (HL)
    INC     HL
    CP      $88
    JR      NZ, JOE_STANDING_DOWN
    LD      A, (HL)
    CP      $89
    JR      NZ, JOE_STANDING_DOWN
    CALL    ALIGN_LADDER                    ; snap onto the ladder
    LD      C, $FC                          ; DY -4
    JR      JOE_TO_LADDER

JOE_LADDER_DOWN:
    CALL    ALIGN_LADDER                    ; down onto the ladder below: snap onto it
    LD      C, $02                          ; DY 2, and the climb-down sequence
    LD      A, $08
    LD      ($70B2), A

JOE_TO_LADDER:
    LD      A, $03                          ; state 3

; Set state A, velocity B (DX), C (DY); B also becomes his facing if
; it isn't 0. A conveyor under his feet pushes him every other frame.
JOE_COMMIT:
    PUSH    AF
    LD      A, B
    CP      $00
    JR      Z, LOC_8991
    LD      ($7078), A

LOC_8991:
    POP     AF

JOE_SET_STATE:
    LD      ($7079), A
    CP      $02                             ; not while jumping
    JR      Z, LOC_89A3
    LD      A, ($70AB)                      ; every other frame
    AND     $01
    CP      $01
    CALL    NZ, CONVEYOR

LOC_89A3:
    LD      HL, $7076
    LD      (HL), B
    INC     HL
    LD      (HL), C
    RET

JOE_STANDING_DOWN:
    LD      A, ($73EE)                      ; down: onto a ladder's top in the floor below,
    AND     $04
    JR      Z, JOE_STANDING_LEFT
    LD      HL, $705B                       ; the middle foot tile, or the right one beside it
    LD      A, (HL)
    INC     HL
    CP      $10
    JR      NZ, LOC_89BF
    LD      A, (HL)
    CP      $11
    JR      Z, JOE_LADDER_DOWN

LOC_89BF:
    CP      $C4                             ; or the top of a rope
    JR      NZ, JOE_STANDING_LEFT
    CALL    ALIGN_ROPE                      ; snap onto the rope; C (4 or 12) is left as his DY,
    CALL    JOE_NOT_MOVING                  ; so he drops a little onto it
    LD      A, $04                          ; state 4
    JR      LOC_89F3

JOE_STANDING_LEFT:
    LD      A, ($73EE)                      ; left: DX -2
    AND     $08
    JR      Z, JOE_STANDING_RIGHT
    LD      BC, $FE00
    CALL    JUMP_PRESSED
    JR      NC, JOE_WALK

; Jump: DX B, DY -1 to start, and 18 frames of the arc at $93AE.
JOE_JUMP:
    LD      A, $07                          ; sound effect 7: jump
    CALL    PLAY_SOUND
    LD      A, ($7300)                      ; where the jump began
    LD      ($707C), A
    LD      A, $12                          ; frames of the arc
    LD      ($7072), A
    LD      HL, JUMP_ARC                    ; (unused)
    LD      C, $FF
    LD      A, $02                          ; state 2

LOC_89F3:
    JP      JOE_COMMIT

JOE_WALK:
    PUSH    BC                              ; a floor under his feet: state 1, walking
    CALL    JOE_ON_FLOOR
    POP     BC
    JR      C, JOE_FALL
    LD      A, $01

LOC_89FF:
    JR      LOC_89F3

; Start falling from where he is.
JOE_FALL:
    LD      A, ($7300)
    LD      ($707C), A
    LD      A, $06                          ; state 6
    JR      LOC_89FF

JOE_STANDING_RIGHT:
    LD      A, ($73EE)                      ; right: DX 2
    AND     $02
    JR      Z, JOE_STANDING_STILL
    LD      BC, $0200
    CALL    JUMP_PRESSED
    JR      C, JOE_JUMP
    JR      JOE_WALK

JOE_STANDING_STILL:
    LD      BC, $0000                       ; neither: jump, stand or fall
    CALL    JUMP_PRESSED
    JR      C, JOE_JUMP
    PUSH    BC
    CALL    JOE_ON_FLOOR
    POP     BC
    JP      NC, JOE_STAND                   ; state 0
    JP      JOE_FALL

; JOE_JUMPING ($8A2F): state 2. DY from the arc, read backwards by the jump
; counter, then 4 once it runs out. Catch a rope or pole he jumps into;
; land once his last DY wasn't upwards.
JOE_JUMPING:
    LD      D, $04
    LD      HL, $7072
    LD      A, (HL)
    CP      $00
    JR      Z, LOC_8A42
    DEC     (HL)
    LD      A, (HL)
    LD      HL, JUMP_ARC
    CALL    TABLE_BYTE
    LD      D, (HL)

LOC_8A42:
    LD      A, ($7076)                      ; DX as before (his facing, if not 0)
    CP      $00
    JR      Z, LOC_8A4C
    LD      ($7078), A

LOC_8A4C:
    LD      B, A
    LD      C, D
    LD      A, ($7058)                      ; a rope at his body
    CP      $90
    JP      Z, JOE_GRAB_ROPE
    CP      $95                             ; a pole at his body, unless he stands on a brick
    JR      NZ, JOE_JUMPING_WALL
    LD      A, ($705B)
    CP      $08
    JR      Z, JOE_JUMPING_WALL
    JP      JOE_GRAB_POLE

; A brick at his body on the side he isn't going: DX 0. (No effect: the
; state is committed with B.)
JOE_JUMPING_WALL:
    LD      A, ($7076)
    BIT     7, A
    LD      A, ($7059)
    JR      NZ, LOC_8A71
    LD      A, ($7057)

LOC_8A71:
    CP      $08
    JR      NZ, JOE_JUMPING_RISING
    XOR     A
    LD      ($7076), A

JOE_JUMPING_RISING:
    LD      A, ($7077)                      ; still rising as of last frame: keep jumping
    BIT     7, A
    JP      NZ, JOE_KEEP_STATE
    JR      JOE_FALLING_FLOOR               ; then as falling

; JOE_FALLING ($8A83): states 5 and 6, and a jump coming down. Land on a
; floor (snapped to it), or die there: on fire, or from a fall of 28 lines
; or more (not from a pole). In the air, catch a rope or pole.
JOE_FALLING:
    LD      BC, $0004                       ; DY 4

JOE_FALLING_FLOOR:
    PUSH    BC
    CALL    JOE_ON_FLOOR                    ; no floor under his feet
    POP     BC
    JR      C, JOE_IN_AIR
    CP      $D2                             ; fire
    JR      NZ, JOE_LAND

JOE_BURN:
    LD      A, $05                          ; sound effect 5: death
    CALL    PLAY_SOUND
    LD      A, $0A                          ; state 10
    JR      JOE_DIE

JOE_LAND:
    LD      C, $00                          ; snap: DY up to where his Y is 4 or 12 (mod 16)
    LD      A, ($7300)

LOC_8A9F:
    AND     $0F
    CP      $04
    JR      Z, LOC_8AAD
    CP      $0C
    JR      Z, LOC_8AAD
    DEC     A
    DEC     C
    JR      LOC_8A9F

LOC_8AAD:
    PUSH    BC
    LD      A, $04                          ; sound effect 4: landing
    CALL    PLAY_SOUND
    LD      A, ($71A8)                      ; landing in column 10 ends the walk into the
    CP      $0A
    JR      NZ, JOE_LAND_HEIGHT             ; pyramid
    LD      A, ($705F)
    BIT     2, A
    JR      Z, JOE_LAND_HEIGHT
    RES     2, A
    LD      ($705F), A
    CALL    SAVE_JOE                        ; he respawns from here

JOE_LAND_HEIGHT:
    LD      A, ($707C)                      ; how far he fell
    LD      B, A
    LD      A, ($7300)
    CP      B
    JR      C, JOE_LANDED_UP
    SUB     B
    POP     BC
    CP      $1C                             ; less than 28 lines
    JR      C, JOE_LANDED
    LD      A, ($7079)                      ; or off a pole: he's fine
    CP      $05
    JR      Z, JOE_LANDED
    LD      A, ($7300)                      ; the death pose: swap his two sprites' rows
    LD      B, A
    LD      A, ($7304)
    LD      ($7300), A
    LD      A, B
    LD      ($7304), A
    LD      A, $09                          ; state 9

; Die: state A, a life gone, the death timer $70.
JOE_DIE:
    PUSH    AF
    CALL    LOSE_LIFE
    LD      A, $70
    LD      ($70A9), A
    POP     AF
    LD      BC, $0000
    JP      JOE_COMMIT

JOE_LANDED_UP:
    POP     BC                              ; below where he started

JOE_LANDED:
    LD      A, $01                          ; state 1, DY the snap
    JP      JOE_SET_STATE

JOE_IN_AIR:
    LD      A, ($705B)                      ; a rope at his feet
    CP      $90
    JP      NZ, JOE_IN_AIR_POLE

JOE_GRAB_ROPE:
    CALL    CAN_GRAB                        ; only on a sideways jump past its first 3 frames
    PUSH    BC
    CALL    ALIGN_ROPE                      ; snap onto it
    POP     BC
    LD      A, ($705B)
    JR      NC, JOE_IN_AIR_POLE             ; (always carries)
    LD      A, $04                          ; state 4, still
    JP      LOC_8C31

; ALIGN_LADDER ($8B20), ALIGN_ROPE ($8B27): snap Joe's X onto a ladder
; (to 7 or 15, mod 16) or a rope or pole (4 or 12). The offset is left in C.
ALIGN_LADDER:
    PUSH    HL
    LD      C, $0F
    LD      E, $07
    JR      ALIGN_JOE

ALIGN_ROPE:
    PUSH    HL
    LD      C, $0C
    LD      E, $04

ALIGN_JOE:
    LD      HL, $7301
    LD      A, (HL)
    AND     $0F
    CP      $08
    JR      NC, LOC_8B37
    LD      C, E

LOC_8B37:
    LD      A, (HL)
    AND     $F0
    ADD     A, C
    LD      (HL), A
    INC     HL
    INC     HL
    INC     HL
    INC     HL
    LD      (HL), A
    POP     HL
    SCF
    RET

; CAN_GRAB ($8B44): return if Joe is jumping sideways past the arc's first 3
; frames; otherwise drop the caller and carry on in the same state.
CAN_GRAB:
    LD      A, ($7076)
    CP      $00
    JR      Z, CAN_GRAB_NOT
    LD      A, ($7072)
    CP      $0F
    JR      NC, CAN_GRAB_NOT
    RET

CAN_GRAB_NOT:
    POP     AF

JOE_KEEP_STATE_JP:
    JP      JOE_KEEP_STATE

JOE_IN_AIR_POLE:
    CP      $95                             ; a pole at his feet?
    JR      NZ, JOE_KEEP_STATE_JP

JOE_GRAB_POLE:
    CALL    CAN_GRAB
    CALL    ALIGN_ROPE
    LD      BC, $0004                       ; DY 4
    LD      A, $06                          ; sound effect 6: pole
    CALL    PLAY_SOUND
    LD      A, $05                          ; state 5
    JP      LOC_8C3C

; JOE_BURNT ($8B6E): state 10. His ghost rises: one grey sprite.
JOE_BURNT:
    LD      HL, $7300                       ; Y - 1
    DEC     (HL)
    INC     HL
    INC     HL
    LD      (HL), $78                       ; the ghost, grey
    INC     HL
    LD      (HL), $0E
    XOR     A                               ; hide the second sprite
    LD      ($7307), A
    JR      JOE_DEAD

; JOE_ZAPPED ($8B7F): state 8. Flash, following the death timer.
JOE_ZAPPED:
    LD      A, ($70A9)
    BIT     2, A
    JR      NZ, JOE_DEAD
    AND     $03
    LD      HL, JOE_ZAPPED_FRAMES
    CALL    SET_JOE_FRAME

; JOE_DEAD ($8B8E): count the death timer down. When it goes negative,
; game over if no life is left; otherwise respawn as he entered the room,
; and have the frame interrupt reload the room.
JOE_DEAD:
    LD      HL, $70A9
    DEC     (HL)
    JP      P, JOE_STILL                    ; not yet
    LD      HL, $7049                       ; lives (his own included)
    LD      A, (HL)
    CP      $00
    JR      NZ, JOE_RESPAWN

GAME_OVER:
    LD      (HL), $06                       ; back to 6
    XOR     A                               ; hide Joe
    LD      ($7303), A
    LD      ($7307), A
    CALL    TURN_OFF_SOUND
    LD      HL, $0000                       ; no points to add
    LD      ($70BD), HL
    LD      ($70BE), HL
    LD      BC, $0109                       ; GAME OVER: row 11 column 12
    LD      HL, GAME_OVER_TEXT
    LD      DE, $016C
    CALL    TILE_ROWS

GAME_OVER_WAIT:
    CALL    READ_CONTROLLERS                ; wait for fire, with no direction held
    LD      A, ($73EE)
    CP      $C0
    JR      NZ, GAME_OVER_WAIT

; Once per game ($705F bit 0); after that only the console's reset
; gets out.
    LD      HL, $705F
    BIT     0, (HL)
    JR      NZ, GAME_OVER_WAIT
    SET     0, (HL)

GAME_OVER_LEVEL_1:
    LD      A, ($71A6)                      ; and only on level 1: elsewhere, forever
    CP      $01
    JR      NZ, GAME_OVER_LEVEL_1
    LD      HL, $0000                       ; the score back to 0
    LD      ($7017), HL
    LD      ($7018), HL

JOE_RESPAWN:
    LD      HL, $7303                       ; his colours: red, yellow
    LD      (HL), $06
    LD      L, $07
    LD      (HL), $0B
    LD      HL, $707D                       ; his state as he entered the room ($8E7E)
    LD      A, (HL)
    LD      ($7077), A
    INC     HL
    LD      A, (HL)
    LD      ($7076), A
    INC     HL
    LD      A, (HL)
    LD      ($7079), A
    INC     HL
    LD      A, (HL)
    LD      ($7078), A
    INC     HL
    LD      A, (HL)
    LD      ($7075), A
    LD      DE, $7300                       ; and his sprites
    LD      HL, $704B
    LD      BC, $0008
    LDIR
    CALL    JOE_TILES

; Have the frame interrupt load the room (LOAD_ROOM_NOW), and wait.
RELOAD_ROOM:
    PUSH    HL
    LD      HL, $70B1
    SET     3, (HL)

RELOAD_ROOM_WAIT:
    BIT     3, (HL)
    JR      NZ, RELOAD_ROOM_WAIT
    POP     HL
    RET

; READ_CONTROLLERS ($8C1F): the joystick into $73EE, with the right fire
; button merged in: bits 0-3 up, right, down, left; bit 6 fire; bit 7 set.
READ_CONTROLLERS:
    CALL    CONTROLLER_SCAN
    LD      HL, $73F0                       ; keypad 1: the right button is bit 6
    LD      A, (HL)
    AND     $C0
    DEC     HL
    DEC     HL
    OR      (HL)
    LD      ($73EE), A
    RET

JOE_STAND:
    LD      A, $00                          ; state 0, still

LOC_8C31:
    LD      BC, $0000
    JR      LOC_8C3C

JOE_STILL:
    LD      BC, $0000                       ; still, same state

JOE_KEEP_STATE:
    LD      A, ($7079)                      ; same state, velocity B, C

LOC_8C3C:
    JP      JOE_SET_STATE

; STEP_IF_CLIMBING ($8C3F), STEP_IF_MOVING ($8C44): count Joe's steps (for
; footsteps and the walking frames) while up or down (A: the joystick's
; bits) is held. $705F bit 6 is set while he isn't moving, so the climbing
; frame stays.
STEP_IF_CLIMBING:
    LD      A, ($73EE)
    AND     $05

STEP_IF_MOVING:
    CP      $00
    JR      Z, JOE_NOT_MOVING
    PUSH    BC
    CALL    STEP_COUNT
    POP     BC
    LD      HL, $705F
    RES     6, (HL)
    RET

JOE_NOT_MOVING:
    LD      HL, $705F
    SET     6, (HL)
    RET

; JOE_LADDER ($8C59): state 3. Climb up or down; let go onto a floor.
; Stepping down onto the ladder from above ($70B2 counting down from 8):
; a pause, a pause, 2 lines down, 2 lines down, a pause, ...
JOE_LADDER:
    LD      A, ($70B2)
    LD      B, A
    AND     $0F
    CP      $00
    JR      Z, JOE_LADDER_CLIMB
    DEC     B
    LD      A, B
    LD      ($70B2), A
    BIT     1, B                            ; pause
    JR      NZ, JOE_STILL
    LD      BC, $0002                       ; down 2...
    BIT     7, A                            ; (up 2 if bit 7)
    JR      Z, JOE_LADDER_COMMIT
    LD      BC, $00FE

JOE_LADDER_COMMIT:
    JP      JOE_KEEP_STATE

JOE_LADDER_CLIMB:
    BIT     7, B
    LD      BC, $0000
    JP      NZ, JOE_FALL
    CALL    STEP_IF_CLIMBING
    LD      A, ($7059)                      ; (unused)

JOE_CLIMB_FLOOR:
    LD      A, ($705B)                      ; a floor at his feet: let go, and land
    CALL    IS_FLOOR
    JP      NC, JOE_FALL
    LD      A, ($73EE)                      ; down: DY 1
    AND     $04
    JR      Z, JOE_CLIMB_UP
    LD      BC, $0001
    JR      JOE_LADDER_COMMIT

; On a rope, above its top: in the treasure room up holds on, anything
; else carries on below; elsewhere up lets go.
JOE_ROPE_ABOVE:
    LD      A, ($705F)
    BIT     5, A
    JR      Z, LOC_8CAD
    LD      A, ($73EE)
    AND     $01
    JR      NZ, JOE_HOLD
    JP      JOE_ROPE_BOTTOM

LOC_8CAD:
    LD      A, ($73EE)
    AND     $01
    JR      Z, JOE_CLIMB_UP
    JR      JOE_LET_GO

; Unreachable.
    LD      A, ($73EE)
    AND     $01
    JR      Z, JOE_CLIMB_UP
    LD      A, $84
    LD      ($70B2), A

JOE_HOLD:
    JP      JOE_STILL

; State 7, and letting go of a rope: fall.
JOE_LET_GO:
    LD      BC, $0000
    LD      A, ($7300)
    LD      ($707C), A
    JP      JOE_FALL

JOE_CLIMB_UP:
    LD      A, ($73EE)                      ; up: DY -1,
    AND     $01
    JR      Z, JOE_CLIMB_DOWN
    LD      BC, $00FF
    LD      A, ($7079)                      ; on a rope every other frame
    CP      $04
    JR      NZ, JOE_CLIMB_COMMIT
    LD      A, ($70AB)
    AND     $01
    CP      $00
    JR      NZ, JOE_CLIMB_COMMIT
    LD      C, $00

JOE_CLIMB_COMMIT:
    JP      JOE_KEEP_STATE

JOE_CLIMB_DOWN:
    LD      A, ($73EE)                      ; down: DY 1 if there's a floor to go down to
    AND     $04
    LD      BC, $0001
    JR      Z, JOE_HOLD
    CALL    JOE_ON_FLOOR
    JR      NC, JOE_CLIMB_COMMIT
    JP      JOE_FALL

; JOE_ROPE ($8D02): state 4. Jump off sideways with fire; climb up (half
; speed) or slide down; let go at the bottom, or at a floor.
JOE_ROPE:
    CALL    STEP_IF_CLIMBING
    CALL    JUMP_PRESSED
    JR      NC, JOE_ROPE_HOLD
    LD      A, ($73EE)                      ; fire with left: DX -2
    AND     $08
    JR      Z, JOE_ROPE_RIGHT
    LD      BC, $FE00

; In the treasure room once its time is up: jump at DX +-4, and set up
; a new screen ($705F bit 3).
JOE_ROPE_JUMP:
    LD      A, ($705F)
    BIT     5, A
    JR      Z, JOE_ROPE_JUMP_GO
    LD      A, ($70AC)
    CP      $01
    JR      NZ, JOE_ROPE_JUMP_GO
    LD      HL, $705F
    SET     3, (HL)
    BIT     7, B
    LD      B, $04
    JR      Z, JOE_ROPE_JUMP_GO
    LD      B, $FC

JOE_ROPE_JUMP_GO:
    JP      JOE_JUMP

JOE_ROPE_RIGHT:
    LD      A, ($73EE)                      ; fire with right: DX 2
    AND     $02
    JR      Z, JOE_ROPE_HOLD
    LD      BC, $0200
    JR      JOE_ROPE_JUMP

; The treasure room has no dropping off: up climbs at DY -2.
JOE_ROPE_TREASURE:
    LD      A, ($73EE)
    AND     $01
    JR      Z, JOE_ROPE_COMMIT
    LD      C, $FE

JOE_ROPE_COMMIT:
    JP      JOE_KEEP_STATE

JOE_ROPE_HOLD:
    LD      BC, $0000
    LD      A, ($7058)                      ; nothing at his body: above the rope's top
    CP      $00
    JP      Z, JOE_ROPE_ABOVE

; Nothing to hold below him (empty, or a jewel in the treasure room):
; off the bottom. Else as on a ladder.
JOE_ROPE_BOTTOM:
    LD      A, ($705B)
    CP      $D8
    JR      Z, JOE_ROPE_DROP
    CP      $98
    JR      Z, JOE_ROPE_DROP
    CP      $00
    JP      NZ, JOE_CLIMB_FLOOR

JOE_ROPE_DROP:
    LD      A, ($705F)
    BIT     5, A
    JP      NZ, JOE_ROPE_TREASURE
    LD      BC, $0000
    LD      A, $A0                          ; drop off; the fall start makes it harmless
    LD      ($707C), A
    LD      A, ($71A5)                      ; (the flags are still BIT 5's: never taken)
    JP      NZ, JOE_FALL
    LD      A, $06                          ; state 6
    JP      JOE_COMMIT

; APPLY_VELOCITY ($8D80): move Joe by B (DX, after any conveyor push) and
; C (DY), with E = DX as stored. A wall at body height in the direction
; he's going stops him sideways: this frame, and for good unless he's
; rising. A lit barrier at his body zaps him.
APPLY_VELOCITY:
    LD      A, ($7057)                      ; the tile ahead: left...
    BIT     7, B
    JR      NZ, LOC_8D8F
    LD      HL, $71B0                       ; ...or right
    INC     (HL)
    INC     (HL)
    LD      A, ($7059)

LOC_8D8F:
    CALL    IS_WALL                         ; a wall?
    JR      Z, JOE_AT_WALL
    LD      A, ($7058)                      ; a barrier, lit
    CP      $E0
    JR      NZ, JOE_MOVE_E
    LD      A, ($7000)
    BIT     5, A
    JR      NZ, JOE_MOVE_E

; Zap Joe, unless he's zapped already (a fall death or burning doesn't
; count: they can be zapped again). C, E: his velocity.
JOE_ZAP:
    LD      A, ($7079)
    CP      $08
    JR      Z, JOE_MOVE_E
    LD      A, $05                          ; sound effect 5: death
    CALL    PLAY_SOUND
    LD      A, $08                          ; state 8
    LD      ($7079), A
    LD      A, $70                          ; the death timer
    LD      ($70A9), A
    LD      A, $D4                          ; the zapped legs pattern
    LD      ($7306), A
    CALL    LOSE_LIFE
    JR      JOE_MOVE_E

; LOSE_LIFE ($8DC2): a life gone, as each death happens.
LOSE_LIFE:
    PUSH    HL
    LD      HL, $7049
    DEC     (HL)
    POP     HL
    RET

JOE_AT_WALL:
    BIT     7, C                            ; not rising: DX 0 for good
    JR      NZ, LOC_8DD1
    XOR     A
    LD      ($7076), A

LOC_8DD1:
    LD      E, $00                          ; no X move this frame

JOE_MOVE_E:
    LD      B, E

; MOVE_JOE ($8DD4): move both of Joe's sprites by B (X), C (Y).
MOVE_JOE:
    LD      HL, $7300
    LD      A, (HL)
    ADD     A, C
    LD      (HL), A
    INC     HL
    LD      A, (HL)
    ADD     A, B
    LD      (HL), A
    LD      L, $04
    LD      A, (HL)
    ADD     A, C
    LD      (HL), A
    INC     HL
    LD      A, (HL)
    ADD     A, B
    LD      (HL), A
    RET

; =============================================================================
; JOE_MOVE ($8DE8): after Joe's state handler, apply his velocity, then see
; whether he has left the screen: sideways by X, up or down by his legs
; sprite's Y. Leaving moves him to the opposite edge and changes the room
; ($71A7 row, $71A8 column).
; =============================================================================
JOE_MOVE:
    LD      HL, $7076
    LD      E, (HL)
    INC     HL
    LD      C, (HL)
    CALL    APPLY_VELOCITY                  ; A: his new X
    CP      $04
    JR      C, LOC_8DFA
    CP      $F0
    JP      C, JOE_EXIT_VERTICAL            ; not at a side: up or down?

LOC_8DFA:
    LD      HL, $71A8                       ; a side: column + 1,
    INC     (HL)
    BIT     7, B                            ; or - 1 going left
    JR      Z, JOE_EXIT_RIGHT
    DEC     (HL)
    DEC     (HL)
    LD      BC, $EC00                       ; X - 20
    JR      CHANGE_ROOM

JOE_EXIT_RIGHT:
    LD      BC, $1600                       ; X + 22

; CHANGE_ROOM ($8E0C): Joe has left the screen; B, C move him to where he
; comes in. Below the pyramid's bottom row (row 9 and down), sliding down a
; pole starts the next level; anything else is the treasure room. Otherwise
; the frame interrupt loads the new room.
CHANGE_ROOM:
    PUSH    AF
    LD      A, ($71A7)
    CP      $09
    JR      C, CHANGE_ROOM_LOAD
    LD      A, $01                          ; sound effect 1: leaving the bottom row
    CALL    PLAY_SOUND
    LD      A, ($7079)                      ; on a pole: the next level
    CP      $05
    JR      NZ, ENTER_TREASURE
    XOR     A                               ; the entrance hall: row 0, column 8
    LD      ($71A7), A
    LD      A, $08
    LD      ($71A8), A
    LD      A, ($705F)                      ; walk Joe into the pyramid (bit 2), and not in
    RES     3, A                            ; the treasure room (bits 3, 5)
    RES     5, A
    SET     2, A
    LD      ($705F), A
    PUSH    BC
    PUSH    HL
    PUSH    DE
    LD      HL, $71A6                       ; the level, up to 9
    LD      A, (HL)
    CP      $09
    JR      NC, NEXT_LEVEL_RESET
    INC     (HL)

NEXT_LEVEL_RESET:
    LD      HL, $70C0                       ; every room as new: clear the "gone" bitmap
    LD      BC, $00C6                       ; ($70C0-$7186: room 99's second byte is missed)
    CALL    CLEAR_RAM
    CALL    VRAM_LOCK
    LD      BC, $0700                       ; register 7 = 0: black backdrop
    CALL    WRITE_REGISTER
    CALL    VRAM_UNLOCK
    POP     DE
    POP     HL
    POP     BC
    JR      CHANGE_ROOM_LOAD

ENTER_TREASURE:
    LD      A, ($705F)                      ; the treasure room: set up a new screen
    BIT     5, A
    SET     3, A                            ; ($705F bit 3)
    SET     5, A
    LD      ($705F), A
    JR      NZ, ENTER_TREASURE_MOVE         ; already in it?
    LD      A, $F0                          ; no: start its timer (240 contact checks)
    LD      ($70AC), A
    CALL    EMPTY_INVENTORY                 ; and empty the inventory

ENTER_TREASURE_MOVE:
    POP     AF
    CALL    MOVE_JOE
    JR      SAVE_JOE

CHANGE_ROOM_LOAD:
    POP     AF
    CALL    MOVE_JOE
    CALL    RELOAD_ROOM                     ; load the room

; SAVE_JOE ($8E7E): remember Joe as he is, to respawn him there: his
; velocity, state, facing and fire latch at $707D-$7081, his sprites at
; $704B-$7052. Then have the frame interrupt recolour the room (RECOLOUR).
SAVE_JOE:
    LD      HL, $707D
    LD      A, ($7077)
    LD      (HL), A
    INC     HL
    LD      A, ($7076)
    LD      (HL), A
    INC     HL
    LD      A, ($7079)
    LD      (HL), A
    INC     HL
    LD      A, ($7078)
    LD      (HL), A
    LD      A, ($7075)
    INC     HL
    LD      (HL), A
    LD      HL, $7300                       ; a fall starts here too
    LD      A, (HL)
    LD      ($707C), A
    LD      DE, $704B
    LD      BC, $0008
    LDIR

RECOLOUR:
    PUSH    HL                              ; run ROOM_COLOURS on the next frame interrupt
    LD      HL, $70B1
    SET     4, (HL)
    POP     HL
    RET

; ROOM_COLOURS ($8EB0): the boot colours, then the room's row's colours for
; entries 1-7 (bricks, ladder tops in floors, the HUD digits, the fire pit's
; flames). Deep in the pyramid (row 9 minus the level or lower) without the
; torch, outside the treasure room, the room is dark: entries 0-2 and 16-24,
; but 20 (the creatures), go black.
ROOM_COLOURS:
    CALL    LOAD_TILE_COLOURS
    LD      A, ($71A7)                      ; row, at most 8
    CP      $08
    JR      C, ROOM_COLOURS_ROW
    LD      A, $08

ROOM_COLOURS_ROW:
    LD      B, $06                          ; times 7
    LD      C, A

LOC_8EBF:
    ADD     A, C
    DJNZ    LOC_8EBF
    LD      HL, ROW_COLOURS                 ; the row's entry in ROW_COLOURS
    CALL    TABLE_BYTE
    LD      DE, $0001                       ; entries 1-7
    LD      IY, $0007
    LD      A, $04
    CALL    PUT_VRAM_LOCKED
    LD      A, ($71A6)                      ; 9 - level
    NEG
    ADD     A, $09
    LD      B, A
    LD      A, ($71A7)
    CP      B
    JR      C, ROOM_COLOURS_DONE
    LD      A, $53                          ; the torch?
    CALL    HAS_ITEM
    JR      C, ROOM_COLOURS_DONE
    LD      A, ($705F)
    BIT     5, A
    JR      NZ, ROOM_COLOURS_DONE
    LD      A, $04                          ; table 4: tile colours, black
    CALL    LOADER
    DW      BLACK                           ; entries 0-2: tiles $00-$17
    DB      $00, 3
    DW      BLACK                           ; entries 16-19: tiles $80-$9F
    DB      $10, 4
    DW      BLACK                           ; entries 21-24: tiles $A8-$C7
    DB      $15, 4
    DB      $00, $00                        ; end

ROOM_COLOURS_DONE:
    RET

; EXIT_UP ($8F04), EXIT_DOWN ($8F13): the row above or below. In the treasure
; room going up stays in the same row; during the walk into the pyramid
; going down adds 2 to the column instead (the entrance hall's pole leads to
; room 2).
EXIT_UP:
    LD      HL, $71A7
    LD      A, ($705F)
    BIT     5, A
    JP      NZ, CHANGE_ROOM
    DEC     (HL)
    JP      CHANGE_ROOM

EXIT_DOWN:
    LD      HL, $71A7
    LD      A, ($705F)
    BIT     2, A
    JR      Z, EXIT_DOWN_ROW
    INC     HL
    INC     (HL)

EXIT_DOWN_ROW:
    INC     (HL)
    JP      CHANGE_ROOM

; Up or down? By the legs sprite's Y.
JOE_EXIT_VERTICAL:
    LD      BC, $0000
    DEC     HL
    LD      A, (HL)
    CP      $08
    JR      NC, JOE_EXIT_BOTTOM
    LD      C, $A4                          ; Y + $A4
    JR      EXIT_UP

JOE_EXIT_BOTTOM:
    CP      $AC
    RET     C
    LD      C, $5C                          ; Y + $5C
    JR      EXIT_DOWN

; CONVEYOR ($8F37): a conveyor under Joe's feet adds 1 to B (DX), or takes 1
; away for the first three of the list. The search runs 7 bytes: one into
; the next table.
CONVEYOR:
    LD      A, ($7079)
    CP      $08
    RET     NC
    LD      A, ($705B)
    PUSH    HL
    PUSH    DE
    PUSH    BC
    LD      HL, CONVEYOR_TILES
    LD      BC, $0007
    CPIR
    JR      NZ, CONVEYOR_DONE
    LD      A, C
    LD      E, $01
    CP      $04
    JR      C, CONVEYOR_PUSH
    LD      E, $FF

CONVEYOR_PUSH:
    POP     BC
    LD      A, B
    ADD     A, E
    LD      B, A
    PUSH    BC

CONVEYOR_DONE:
    POP     BC
    POP     DE
    POP     HL
    RET

; =============================================================================
; ITEM_TASK ($8F5F): main-loop task, every 4 frames. Unless Joe lies dead
; from a fall, let the frame interrupt take its next animation step; then
; open a door beside him if he carries its key, or die on a creature, or
; pick up the item at his body. Things dealt with are marked in the room's
; "gone" bitmap.
; =============================================================================
ITEM_TASK:
    LD      A, ($7079)
    CP      $09
    RET     Z
    LD      HL, $7011                       ; $7011 bit 7: the animation may step ($A9F3)
    LD      A, (HL)
    XOR     $80
    LD      (HL), A
    CALL    JOE_TILES                       ; the tiles around him; $71B0: the top left one
    LD      A, ($7057)                      ; the tile beside his body, on the side he faces
    LD      HL, $7078
    BIT     7, (HL)
    JR      NZ, LOC_8F81
    LD      HL, $71B0
    INC     (HL)
    INC     (HL)
    LD      A, ($7059)

LOC_8F81:
    CP      $9C                             ; a door's bottom: blue (its open drawing $70, key $5D),
    JR      NZ, LOC_8F8B
    LD      D, $70
    LD      A, $5D
    JR      OPEN_DOOR

LOC_8F8B:
    CP      $B7                             ; gold,
    JR      NZ, LOC_8F95
    LD      D, $69
    LD      A, $58
    JR      OPEN_DOOR

LOC_8F95:
    CP      $C7                             ; red
    JR      NZ, ITEM_TASK_BODY
    LD      A, $62
    LD      D, $77

OPEN_DOOR:
    LD      HL, $7084
    LD      (HL), D
    CALL    HAS_ITEM                        ; the key?
    JR      NZ, ITEM_TASK_BODY
    CALL    REMOVE_ITEM                     ; used up
    LD      HL, ($71B0)                     ; the door's top, 3 rows up
    LD      BC, $0060
    SCF
    CCF
    SBC     HL, BC
    LD      ($71B0), HL
    CALL    FIND_CONTACT                    ; mark it gone
    LD      A, ($7084)                      ; draw it open
    CALL    DRAW_OPEN_DOOR_AT
    PUSH    AF
    LD      A, $08                          ; sound effect 8: door
    CALL    PLAY_SOUND
    POP     AF
    LD      HL, $0300                       ; 300 points
    CALL    ADD_POINTS
    RET

ITEM_TASK_BODY:
    CALL    JOE_TILES                       ; the tile at his body, in the middle
    LD      HL, $71B0
    INC     (HL)
    LD      A, ($7058)
    LD      BC, $0008                       ; a creature?
    LD      HL, CREATURE_TILES
    CPIR
    JR      NZ, ITEM_TASK_KEY
    LD      A, ($704A)                      ; the amulet protects him
    CP      $00
    RET     NZ

; Mark the creature gone ($7000 bit 3 tells MARK_GONE it's a creature),
; and zap him. MARK_GONE toggles the bit, and this runs again every time
; while he lies zapped on the creature, an odd number of times in all, so
; it ends up gone (on levels 1-3).
    LD      HL, $7000
    SET     3, (HL)
    PUSH    HL
    CALL    MARK_THING
    POP     HL
    RES     3, (HL)
    LD      C, $00
    LD      E, $00
    JP      JOE_ZAP

ITEM_TASK_KEY:
    LD      BC, $000C                       ; a key? 50 points
    LD      HL, KEY_TILES
    CPIR
    JR      NZ, ITEM_TASK_OTHER
    CALL    POINTS_50
    DEC     HL                              ; its colour by the tile
    LD      A, (HL)
    AND     $F8
    CP      $78
    JR      NZ, ITEM_TASK_KEY_RED
    LD      A, $58
    JR      PICK_UP

ITEM_TASK_KEY_RED:
    CP      $68
    LD      A, $62
    JR      NZ, PICK_UP
    LD      A, $5D

; Pick up item A: into the inventory (a jewel only scores), then
; blank it out and recolour the room.
PICK_UP:
    PUSH    BC
    LD      C, A
    CALL    ADD_ITEM                        ; inventory full?
    JR      C, PICK_UP_DONE
    PUSH    AF
    LD      A, $02                          ; sound effect 2: pickup
    CALL    PLAY_SOUND
    POP     AF
    CALL    VRAM_LOCK
    POP     BC
    PUSH    BC
    CALL    MARK_THING                      ; mark it gone; $71B0: its top left tile
    LD      A, $0B                          ; blank 2x2 tiles
    LD      DE, ($71B0)
    CALL    DRAW_ICON
    CALL    RECOLOUR                        ; the torch may light the room
    CALL    VRAM_UNLOCK

PICK_UP_DONE:
    POP     BC
    RET

; Sword, torch, jewel or amulet? By what CPIR leaves in C.
ITEM_TASK_OTHER:
    LD      BC, $0010
    LD      HL, PICKUP_TILES
    CPIR
    RET     NZ
    LD      A, C
    CP      $04
    JR      NC, ITEM_TASK_JEWEL
    CALL    POINTS_100                      ; the amulet: 100 points; it protects him for
    LD      A, $A0                          ; 160 contact checks
    LD      ($704A), A
    LD      A, $8C
    JR      ITEM_TASK_PICK

ITEM_TASK_JEWEL:
    CP      $08
    JR      NC, ITEM_TASK_TORCH
    LD      A, $44                          ; the jewel (1000 points, at $A56C)
    CALL    POINTS_50
    JR      ITEM_TASK_PICK

; The points to add, into $70BD (BCD): 50, 100, 3000.
POINTS_50:
    PUSH    HL
    LD      HL, $0050
    JR      SET_POINTS

POINTS_100:
    PUSH    HL
    LD      HL, $0100
    JR      SET_POINTS

POINTS_3000:
    PUSH    HL
    LD      HL, $3000

SET_POINTS:
    LD      ($70BD), HL
    POP     HL
    RET

ITEM_TASK_TORCH:
    CP      $0C                             ; the torch: 3000 points
    JR      NC, ITEM_TASK_SWORD
    CALL    POINTS_3000
    LD      A, $53
    JR      ITEM_TASK_PICK

ITEM_TASK_SWORD:
    LD      A, $91                          ; the sword: 50 points
    CALL    POINTS_50

ITEM_TASK_PICK:
    JP      PICK_UP

; HAS_ITEM ($908F): Z and carry set if the inventory holds item A; HL, BC are
; left where CPIR stopped, for REMOVE_ITEM.
HAS_ITEM:
    LD      HL, $71B2
    LD      BC, $0006
    CPIR
    SCF
    RET     Z
    SCF
    CCF
    RET

; REMOVE_ITEM ($909C): after HAS_ITEM, close the gap the item leaves and
; redraw the HUD.
REMOVE_ITEM:
    PUSH    HL
    POP     DE
    DEC     DE
    LDIR
    CALL    DRAW_INVENTORY
    RET

; MARK_THING ($90A5): the thing whose tile CPIR found (C: what it left) is
; gone. C mod 4 gives the tile's corner of the 2x2 thing; $71B0 moves to its
; top left tile. Then find the thing's contact entry by its position
; (searching from the end, 24 entries) and mark it gone. Once a low byte
; matches but its high byte doesn't, the search compares the entries' low
; bytes with the position's high byte. Not found, it runs on into
; JUMP_PRESSED, harmlessly.
MARK_THING:
    LD      A, C
    ADD     A, $04

MARK_THING_MOD4:
    SUB     $04
    CP      $04
    JR      NC, MARK_THING_MOD4
    LD      E, A                            ; corner: bit 0 right, bit 1 bottom
    XOR     A
    LD      B, A
    BIT     0, E
    JR      Z, MARK_THING_ROW
    ADD     A, $01

MARK_THING_ROW:
    BIT     1, E
    JR      Z, MARK_THING_TOP_LEFT
    ADD     A, $20

MARK_THING_TOP_LEFT:
    LD      HL, ($71B0)
    LD      C, A
    SCF
    CCF
    SBC     HL, BC
    LD      ($71B0), HL

FIND_CONTACT:
    LD      DE, $72F2
    LD      HL, $71B0
    LD      B, $18

FIND_CONTACT_NEXT:
    DEC     DE

FIND_CONTACT_LO:
    DEC     DE
    LD      A, (DE)
    CP      (HL)
    JR      NZ, FIND_CONTACT_LOOP
    INC     HL
    INC     DE
    LD      A, (DE)
    CP      (HL)
    JR      NZ, FIND_CONTACT_LO
    PUSH    DE
    POP     HL
    JP      MARK_GONE

FIND_CONTACT_LOOP:
    DJNZ    FIND_CONTACT_NEXT

; JUMP_PRESSED ($90E3): carry set on a new press of a fire button. During
; the walk into the pyramid a brick beside him counts as one (but not on a
; rope). $7075 latches the button: $80 released, $C0 held, 0 just pressed.
JUMP_PRESSED:
    LD      A, ($7057)
    CP      $08
    JR      Z, JUMP_PRESSED_AUTO
    LD      A, ($7059)
    CP      $08
    JR      NZ, JUMP_PRESSED_FIRE

JUMP_PRESSED_AUTO:
    LD      A, ($7079)
    CP      $04
    JR      Z, JUMP_PRESSED_FIRE
    LD      A, ($705F)
    BIT     2, A
    JR      NZ, JUMP_PRESSED_YES

JUMP_PRESSED_FIRE:
    LD      A, ($73EE)
    AND     $C0
    PUSH    AF
    CP      $C0
    JR      NZ, JUMP_PRESSED_NO
    LD      A, ($7075)
    CP      $80
    JR      NZ, JUMP_PRESSED_NO
    POP     AF
    XOR     A
    LD      ($7075), A

JUMP_PRESSED_YES:
    SCF
    RET

JUMP_PRESSED_NO:
    POP     AF
    LD      ($7075), A
    SCF
    CCF
    RET

; IS_FLOOR ($9122), JOE_ON_FLOOR ($911E, the tile at his feet): carry clear if
; Joe can stand on tile A: a floor, a disappearing floor while it's shown,
; or a tile that kills him (then A = $D2, fire).
JOE_ON_FLOOR:
    LD      HL, $705B
    LD      A, (HL)

IS_FLOOR:
    PUSH    HL
    PUSH    BC
    LD      HL, FLOOR_TILES
    LD      BC, $000A
    CPIR
    POP     BC
    POP     HL
    JR      Z, IS_FLOOR_YES
    CP      $E8
    JR      Z, IS_FLOOR_DISAPPEARING
    CALL    IS_HAZARD
    JR      Z, IS_FLOOR_FIRE
    SCF
    RET

; IS_HAZARD ($913B): Z if tile A kills Joe.
IS_HAZARD:
    PUSH    HL
    PUSH    BC
    LD      HL, HAZARD_TILES
    LD      BC, $0005
    CPIR
    POP     BC
    POP     HL
    RET

IS_FLOOR_DISAPPEARING:
    LD      A, ($7000)
    BIT     6, A
    SCF
    RET     NZ

IS_FLOOR_YES:
    SCF
    CCF
    RET

IS_FLOOR_FIRE:
    LD      A, $D2
    JR      IS_FLOOR_YES

; JOE_TILES ($9156): read the 3x2 tiles around Joe's legs sprite into
; $7057-$705C. READ_TILES ($9159, HL: a sprite's entry) does it for any
; sprite: the tile at X+1, Y+18 (rounded up to tiles), one column left and
; one row up, is the top left of the block; its name table position goes
; into $71B0.
JOE_TILES:
    LD      HL, $7304

READ_TILES:
    LD      A, (HL)
    LD      ($7084), A
    INC     HL
    LD      A, (HL)
    LD      ($7085), A
    LD      BC, $1202                       ; B: Y + 18, C: X + 1 (with the -1 below)
    LD      HL, $7057
    CALL    READ_TILES_AT
    RET

; READ_TILES_AT ($916C): the tile at X + C - 1, Y + B, one row up and
; one column left, into $71B0; read 2 rows of 3 from there into HL.
READ_TILES_AT:
    PUSH    HL
    LD      A, ($7084)
    ADD     A, B
    LD      B, A
    LD      A, ($7085)
    ADD     A, $FF
    ADD     A, C
    CALL    TILE_AT
    LD      BC, $FFDF
    ADD     HL, BC
    EX      DE, HL
    LD      ($71B0), DE
    LD      HL, $7000                       ; TILE_ROWS: read (bit 4), rows 32 apart (bit 2)
    SET     4, (HL)
    SET     2, (HL)
    POP     HL
    LD      BC, $0203                       ; 2 rows of 3
    CALL    TILE_ROWS
    LD      HL, $7000
    RES     4, (HL)
    RES     2, (HL)
    RET

; LOAD_ROOM_NOW ($919A): the frame interrupt's room load ($70B1 bit 3):
; clear the enemy sprites, then LOAD_ROOM.
LOAD_ROOM_NOW:
    LD      HL, $7000                       ; $7000 bit 0 (never tested)
    SET     0, (HL)
    XOR     A                               ; no enemies
    LD      ($707A), A
    LD      HL, $7308                       ; their sprites, $7308-$7328
    LD      BC, $0020
    CALL    CLEAR_RAM
    CALL    LOAD_ROOM
    RET

; STEP_ANIM_FRAME ($91B0): $7096 counts 3, 2, 1, 0, 3, ...: the barrier's and
; disappearing floor's frame, and the dead Joe's legs.
STEP_ANIM_FRAME:
    LD      A, ($7096)
    DEC     A
    JP      P, STEP_ANIM_FRAME_SET
    LD      A, $03

STEP_ANIM_FRAME_SET:
    LD      ($7096), A
    RET

; STEP_COUNT ($91BD): a step every other call: $70AA counts 7 down to 0.
STEP_COUNT:
    LD      HL, $70AD
    DEC     (HL)
    RET     NZ
    LD      (HL), $02
    LD      A, ($70AA)
    DEC     A
    JP      P, STEP_COUNT_SET
    LD      A, $07

STEP_COUNT_SET:
    LD      ($70AA), A
    RET

; NEAR ($91D1): carry set if A and (HL) are less than B apart.
NEAR:
    SUB     (HL)
    JP      P, NEAR_CP
    NEG

NEAR_CP:
    CP      B
    RET

; SET_CREATURE_COLOUR ($91D9): colour entry 20 (the creatures, $A0-$A7) = A.
SET_CREATURE_COLOUR:
    PUSH    AF
    POP     AF
    LD      HL, $2014
    LD      DE, $0001
    CALL    FILL_VRAM_LOCKED
    RET

; =============================================================================
; CONTACT_TASK ($91E5): main-loop task, every 2 frames. Count down the
; treasure room's timer and the amulet's; step the barrier frame. Unless the
; amulet protects him, see whether Joe touches an enemy: less than 13 lines
; and 8 pixels apart, and visible. With the sword he kills it; without, it
; kills him. On levels 1-4 the enemy is then gone for good.
; =============================================================================
CONTACT_TASK:
    LD      A, ($70AC)                      ; the treasure room's timer, down to 1
    DEC     A
    CP      $00
    JR      NZ, LOC_91EF
    LD      A, $01

LOC_91EF:
    LD      ($70AC), A
    LD      A, ($7079)                      ; Joe dead: nothing more
    CP      $08
    RET     NC
    LD      HL, $704A                       ; the amulet's timer
    LD      A, (HL)
    CP      $00
    JR      Z, AMULET_DROP
    DEC     (HL)
    CP      $01
    JR      Z, AMULET_OFF
    LD      A, $E0                          ; creatures grey while it protects him
    CALL    SET_CREATURE_COLOUR
    JR      CONTACT_CHECK

AMULET_OFF:
    LD      A, $C0                          ; then dark green
    CALL    SET_CREATURE_COLOUR
    XOR     A
    LD      ($704A), A

AMULET_DROP:
    LD      A, $8C                          ; out of the inventory once it's off
    CALL    HAS_ITEM
    JR      NZ, CONTACT_CHECK
    CALL    REMOVE_ITEM

CONTACT_CHECK:
    CALL    STEP_BARRIER
    LD      A, ($704A)                      ; protected
    CP      $00
    RET     NZ
    LD      HL, $7300                       ; Joe's Y and X
    LD      A, (HL)
    LD      ($7084), A
    INC     HL
    LD      A, (HL)
    LD      ($7085), A
    LD      HL, $72C1                       ; the contact list: (offset, $FF) for an enemy
    PUSH    HL

CONTACT_NEXT:
    POP     HL

CONTACT_SCAN:
    INC     HL
    LD      C, (HL)
    INC     HL
    LD      A, (HL)
    CP      $FE
    RET     Z
    CP      $FF
    JR      NZ, CONTACT_SCAN
    PUSH    HL                              ; its sprite, offset bytes after $7304
    LD      HL, $7304
    LD      B, $00
    ADD     HL, BC
    LD      A, ($7084)                      ; Y less than 13 apart
    LD      B, $0D
    CALL    NEAR
    JR      NC, CONTACT_NEXT
    INC     HL
    LD      A, ($7085)                      ; X less than 8 apart
    LD      B, $08
    CALL    NEAR
    JR      NC, CONTACT_NEXT
    INC     HL                              ; visible
    INC     HL
    LD      A, (HL)
    CP      $00
    JR      Z, CONTACT_NEXT
    PUSH    HL                              ; the sword?
    LD      A, $91
    CALL    HAS_ITEM
    JR      NZ, ENEMY_KILLS
    CALL    REMOVE_ITEM                     ; used up
    PUSH    AF
    LD      A, $03                          ; sound effect 3: sword kill
    CALL    PLAY_SOUND
    POP     AF
    POP     HL
    LD      A, (HL)                         ; hide the enemy
    LD      (HL), $00
    LD      HL, $2000                       ; 2000 points for a white one, 3000 others
    CP      $0F
    JR      Z, SWORD_POINTS
    LD      HL, $3000

SWORD_POINTS:
    CALL    ADD_POINTS
    POP     HL
    CALL    MARK_GONE                       ; gone for good
    RET

ENEMY_KILLS:
    POP     HL
    POP     HL
    LD      A, ($71A6)                      ; on levels 1-4 it's gone for good
    CP      $05
    JR      NC, ENEMY_ZAP
    CALL    MARK_GONE

ENEMY_ZAP:
    LD      C, $00
    LD      E, $00
    JP      JOE_ZAP

; MARK_GONE ($92A2): mark the thing whose contact entry ends at HL gone, in
; the room's 2 bytes of the "gone" bitmap at $70C0. From level 4 on, a
; creature that killed Joe stays ($7000 bit 3).
MARK_GONE:
    LD      A, ($71A6)
    CP      $04
    JR      C, MARK_GONE_ENTRY
    LD      A, ($7000)
    BIT     3, A
    RET     NZ

MARK_GONE_ENTRY:
    LD      A, $C0                          ; the entry's number
    DEC     HL
    SUB     L
    NEG
    SRA     A
    CALL    TOGGLE_GONE
    LD      C, $00
    LD      E, C
    RET

; Toggle thing A - 1's bit (NEXT_THING_GONE counts it up again).
TOGGLE_GONE:
    DEC     A
    LD      ($71A2), A
    CALL    ROOM_NUMBER
    SLA     A
    LD      ($71A1), A
    CALL    NEXT_THING_GONE
    LD      A, (HL)
    XOR     D
    LD      (HL), A
    RET

; STEP_BARRIER ($92D1): step the barrier frame every other call.
STEP_BARRIER:
    LD      HL, $7098
    LD      A, $80
    XOR     (HL)
    LD      (HL), A
    CALL    Z, STEP_ANIM_FRAME
    RET

; =============================================================================
; JOE_SPRITES ($92DC): set Joe's two sprite patterns for his state, from
; JOE_FRAMES (the walking and climbing frames by the step count $70AA), and
; play footsteps while he walks.
; =============================================================================
JOE_SPRITES:
    LD      A, ($7079)
    CP      $01
    JR      NZ, JOE_SPRITES_JUMP
    LD      A, ($70AA)                      ; the walking frame
    SRA     A

JOE_SPRITES_WALK:
    LD      HL, JOE_WALK_LEFT               ; facing left
    PUSH    AF
    CP      $00
    JR      Z, JOE_SPRITES_SIDE
    LD      A, $09                          ; sound effect 9: footsteps
    CALL    PLAY_SOUND

JOE_SPRITES_SIDE:
    POP     AF
    CALL    FACING_RIGHT
    JR      NC, SET_JOE_FRAME
    LD      HL, JOE_FRAMES                  ; facing right
    JR      SET_JOE_FRAME

JOE_SPRITES_STEP:
    LD      A, ($70AA)
    SRA     A

; SET_JOE_FRAME ($9305): Joe's patterns from frame A of the table at HL.
SET_JOE_FRAME:
    SLA     A
    CALL    TABLE_BYTE
    LD      DE, $7302
    LD      (DE), A
    LD      DE, $7306
    INC     HL
    LD      A, (HL)
    LD      (DE), A
    RET

JOE_SPRITES_JUMP:
    CP      $02                             ; jumping
    JR      NZ, JOE_SPRITES_LADDER
    LD      HL, JOE_JUMP_RIGHT
    CALL    FACING_RIGHT
    JR      C, JOE_SPRITES_FIRST
    LD      HL, JOE_JUMP_LEFT

JOE_SPRITES_FIRST:
    XOR     A
    JR      SET_JOE_FRAME

JOE_SPRITES_LADDER:
    CP      $03                             ; on a ladder: the frame stays while he stands still
    JR      NZ, JOE_SPRITES_ROPE
    LD      HL, $705F
    BIT     6, (HL)
    JR      Z, JOE_SPRITES_LADDER_STEP
    RES     6, (HL)
    RET

JOE_SPRITES_LADDER_STEP:
    LD      HL, JOE_CLIMB
    JR      JOE_SPRITES_STEP

JOE_SPRITES_ROPE:
    CP      $04
    JR      NZ, JOE_SPRITES_POLE
    LD      HL, JOE_SWING
    JR      JOE_SPRITES_STEP

JOE_SPRITES_POLE:
    CP      $05
    JR      NZ, JOE_SPRITES_DEAD
    LD      HL, JOE_POLE
    XOR     A
    JR      SET_JOE_FRAME

JOE_SPRITES_DEAD:
    CP      $09                             ; dead from a fall: the legs twitch with $7096
    JR      NZ, JOE_SPRITES_OTHER
    LD      HL, JOE_LYING
    LD      A, ($7096)
    JR      SET_JOE_FRAME

JOE_SPRITES_OTHER:
    CP      $08                             ; zapped and burnt: set by their handlers
    RET     Z
    CP      $0A
    RET     Z
    XOR     A                               ; standing, falling, letting go: standing
    JP      JOE_SPRITES_WALK

; Unreachable.
    PUSH    AF
    LD      A, ($7076)
    JR      LOC_936D

; FACING_RIGHT ($9369): carry set if Joe faces right.
FACING_RIGHT:
    PUSH    AF
    LD      A, ($7078)

LOC_936D:
    BIT     7, A
    JR      NZ, FACING_LEFT
    POP     AF
    SCF
    RET

FACING_LEFT:
    POP     AF
    SCF
    CCF
    RET

; Joe's frames: patterns of his body and of his hat, face and legs.
JOE_FRAMES:
    DB      $34, $98, $6C, $A0, $34, $98, $34, $9C ; walking right (by $70AA / 2), and standing

JOE_WALK_LEFT:
    DB      $40, $A4, $7C, $AC, $40, $A4, $40, $A8 ; walking left

JOE_JUMP_RIGHT:
    DB      $4C, $B0                        ; jumping right

JOE_JUMP_LEFT:
    DB      $50, $B4                        ; jumping left

JOE_POLE:
    DB      $64, $C8                        ; pole

JOE_CLIMB:
    DB      $54, $B8, $58, $BC, $54, $B8, $58, $BC ; ladder

JOE_SWING:
    DB      $5C, $C0, $60, $C4, $5C, $C0, $60, $C4 ; rope

JOE_LYING:
    DB      $68, $CC, $68, $D0, $68, $CC, $68, $D0 ; dead from a fall (by $7096)

JOE_ZAPPED_FRAMES:
    DB      $D8, $D4, $D8, $D4, $E0, $DC, $E0, $DC ; zapped (by the death timer)

; JUMP_ARC ($93AE): DY for each frame of a jump, read from the end.
JUMP_ARC:
    DB      $04, $03, $03, $01, $01, $01, $01, $00, $00
    DB      $00, $00, $00, $FF, $FF, $FF, $FF, $FB, $FB

; ROW_COLOURS ($93C0): colour entries 1-7 for each row of the pyramid (rows 8
; and down share the last): bricks, ladder tops in floors, the HUD digits
; (two entries each half) and the fire pit's flames.
ROW_COLOURS:
    DB      $F8, $4F, $F0, $F0, $80, $80, $F9 ; row 0
    DB      $AF, $4A, $A0, $A0, $F0, $F0, $A9 ; row 1
    DB      $B5, $4B, $B0, $B0, $50, $50, $B9 ; row 2
    DB      $BC, $4B, $B0, $B0, $C0, $C0, $B9 ; row 3
    DB      $BD, $4B, $B0, $B0, $E0, $E0, $B9 ; row 4
    DB      $EC, $4E, $E0, $E0, $C0, $C0, $E9 ; row 5
    DB      $ED, $4E, $E0, $E0, $D0, $D0, $E9 ; row 6
    DB      $A7, $4A, $A0, $A0, $70, $70, $A9 ; row 7
    DB      $E7, $4E, $E0, $E0, $70, $70, $E9 ; row 8 and down

FLOOR_TILES:
    DB      $08, $10, $11, $05, $04, $06, $B9, $B8, $BA, $C4 ; what Joe stands on: brick, ladder tops, conveyors, a rope's top

GAME_OVER_TEXT:
    DB      $47, $41, $4D, $45, $00, $4F, $56, $45, $52 ; "GAME OVER", tile 0 for the space

CONVEYOR_TILES:
    DB      $04, $05, $06, $B9, $B8, $BA    ; pushing left: $04-$06; right: $B9, $B8, $BA

; Item tiles, searched with CPIR: what's left in C gives the item and the
; tile's corner.
PICKUP_TILES:
    DB      $9B, $9A, $97, $96              ; sword
    DB      $63, $62, $D1, $D0              ; torch
    DB      $D9, $99, $D8, $98              ; jewel
    DB      $AF, $A9, $AE, $A8              ; amulet

CREATURE_TILES:
    DB      $A3, $A2, $A1, $A0              ; creature, both ways
    DB      $A6, $A7, $A4, $A5

KEY_TILES:
    DB      $6B, $6A, $69, $68              ; blue key
    DB      $7B, $7A, $79, $78              ; gold key
    DB      $73, $72, $71, $70              ; red key
; -----------------------------------------------------------------------------
; Tiles that stop Joe and the enemies moving sideways.
; -----------------------------------------------------------------------------
WALL_TILES:

    DB      $08, $B0, $BB, $C0, $B7, $9C, $C7, $0B ; brick; closed doors and their bottoms; the HUD box's right edge

; -----------------------------------------------------------------------------
; ROOM DATA
;
; Each room is a list of commands, run by LOAD_ROOM ($A067). A command's
; first byte: bits 0-5 are the command, bits 6-7 bits 8-9 of its name table
; position, whose low 8 bits are the next byte. CMD_GROUPS gives each
; command its tile group, an offset into TILE_GROUPS.
;
;   $00-$03  block: tile, then size (hi nibble wide, lo high), or for odd
;            commands wide and high in two bytes
;   $04-$07  slope: square of one tile, then steps of another carved in;
;   $14-$17  bit 4: steps 2 rows high, bit 0: steps right-aligned
;   $08-$0A  column of the group's tiles, then the height
;   $18-$1B  the same, with the group's next tiles on top
;   $0B      barrier, 4 high (2-byte command)
;   $0C-$0F  row: end tile, middle tiles, end tile, then the width
;   $10/$11  1-byte command: end the list (or included list) below level
;            (bits 6-7) + 2 / + 6
;   $1C-$1F  row of the group's tiles, repeated; or, for a group whose
;            count is $FF, that many tiles of its run
;   $20-$28  item or creature, 2x2 tiles   } 2-byte commands, skipped
;   $29-$2F  door, 1x4 tiles               } inside an included room; each
;   $30-$32  enemy; the second byte is the } is a "thing": bit n of the
;            start position (lo nibble Y,  } room's 2 bytes at $70C0 set
;            hi nibble X), bit 6 fast      } means thing n is gone
;   $3E/$3F  draw another room's shapes (its number follows), then for $3F
;            mirror the screen; the room's own commands draw over it
; -----------------------------------------------------------------------------
CMD_GROUPS:                                 ; tile group of each command

    DB      $00                             ; $00
    DB      $00                             ; $01
    DB      $02                             ; $02
    DB      $02                             ; $03
    DB      $02                             ; $04
    DB      $00                             ; $05
    DB      $00                             ; $06
    DB      $02                             ; $07
    DB      $06                             ; $08
    DB      $10                             ; $09
    DB      $13                             ; $0A
    DB      $15                             ; $0B
    DB      $0B                             ; $0C
    DB      $1B                             ; $0D
    DB      $17                             ; $0E
    DB      $FF                             ; $0F (unused)
    DB      $FF                             ; $10 (level check)
    DB      $FF                             ; $11 (level check)
    DB      $FF                             ; $12 (unused)
    DB      $FF                             ; $13 (unused)
    DB      $02                             ; $14
    DB      $00                             ; $15
    DB      $00                             ; $16
    DB      $02                             ; $17
    DB      $06                             ; $18
    DB      $10                             ; $19
    DB      $FF                             ; $1A (unused)
    DB      $FF                             ; $1B (unused)
    DB      $1F                             ; $1C
    DB      $21                             ; $1D
    DB      $24                             ; $1E
    DB      $42                             ; $1F
    DB      $44                             ; $20
    DB      $49                             ; $21
    DB      $4E                             ; $22
    DB      $53                             ; $23
    DB      $58                             ; $24
    DB      $5D                             ; $25
    DB      $62                             ; $26
    DB      $7C                             ; $27
    DB      $81                             ; $28
    DB      $67                             ; $29
    DB      $6E                             ; $2A
    DB      $75                             ; $2B
    DB      $FF                             ; $2C (unused)
    DB      $FF                             ; $2D (unused)
    DB      $FF                             ; $2E (unused)
    DB      $FF                             ; $2F (unused)
    DB      $86                             ; $30
    DB      $8A                             ; $31
    DB      $88                             ; $32

ROOM_LISTS:                                 ; where each room's list starts; the next one's start ends it
    DW      ROOM_LIST_00                    ; room 0
    DW      ROOM_LIST_01                    ; room 1
    DW      ROOM_LIST_02                    ; room 2
    DW      ROOM_LIST_03                    ; room 3
    DW      ROOM_LIST_04                    ; room 4
    DW      ROOM_LIST_05                    ; room 5
    DW      ROOM_LIST_06                    ; room 6
    DW      ROOM_LIST_07                    ; room 7
    DW      ROOM_LIST_08                    ; room 8
    DW      ROOM_LIST_09                    ; room 9
    DW      ROOM_LIST_10                    ; room 10
    DW      ROOM_LIST_11                    ; room 11
    DW      ROOM_LIST_12                    ; room 12
    DW      ROOM_LIST_13                    ; room 13
    DW      ROOM_LIST_14                    ; room 14
    DW      ROOM_LIST_15                    ; room 15
    DW      ROOM_LIST_16                    ; room 16
    DW      ROOM_LIST_17                    ; room 17
    DW      ROOM_LIST_18                    ; room 18
    DW      ROOM_LIST_19                    ; room 19
    DW      ROOM_LIST_20                    ; room 20
    DW      ROOM_LIST_21                    ; room 21
    DW      ROOM_LIST_22                    ; room 22
    DW      ROOM_LIST_23                    ; room 23
    DW      ROOM_LIST_24                    ; room 24
    DW      ROOM_LIST_25                    ; room 25
    DW      ROOM_LIST_26                    ; room 26
    DW      ROOM_LIST_27                    ; room 27
    DW      ROOM_LIST_28                    ; room 28
    DW      ROOM_LIST_29                    ; room 29
    DW      ROOM_LIST_30                    ; room 30
    DW      ROOM_LIST_31                    ; room 31
    DW      ROOM_LIST_32                    ; room 32
    DW      ROOM_LIST_33                    ; room 33
    DW      ROOM_LIST_34                    ; room 34
    DW      ROOM_LIST_35                    ; room 35
    DW      ROOM_LIST_36                    ; room 36
    DW      ROOM_LIST_37                    ; room 37
    DW      ROOM_LIST_38                    ; room 38
    DW      ROOM_LIST_39                    ; room 39
    DW      ROOM_LIST_40                    ; room 40
    DW      ROOM_LIST_41                    ; room 41
    DW      ROOM_LIST_42                    ; room 42
    DW      ROOM_LIST_43                    ; room 43
    DW      ROOM_LIST_44                    ; room 44
    DW      ROOM_LIST_45                    ; room 45
    DW      ROOM_LIST_46                    ; room 46
    DW      ROOM_LIST_47                    ; room 47
    DW      ROOM_LIST_48                    ; room 48
    DW      ROOM_LIST_49                    ; room 49
    DW      ROOM_LIST_50                    ; room 50
    DW      ROOM_LIST_51                    ; room 51
    DW      ROOM_LIST_52                    ; room 52
    DW      ROOM_LIST_53                    ; room 53
    DW      ROOM_LIST_54                    ; room 54
    DW      ROOM_LIST_55                    ; room 55
    DW      ROOM_LIST_56                    ; room 56
    DW      ROOM_LIST_57                    ; room 57
    DW      ROOM_LIST_58                    ; room 58
    DW      ROOM_LIST_59                    ; room 59
    DW      ROOM_LIST_60                    ; room 60
    DW      ROOM_LIST_61                    ; room 61
    DW      ROOM_LIST_62                    ; room 62
    DW      ROOM_LIST_63                    ; room 63
    DW      ROOM_LIST_64                    ; room 64
    DW      ROOM_LIST_65                    ; room 65
    DW      ROOM_LIST_66                    ; room 66
    DW      ROOM_LIST_67                    ; room 67
    DW      ROOM_LIST_68                    ; room 68
    DW      ROOM_LIST_69                    ; room 69
    DW      ROOM_LIST_70                    ; room 70
    DW      ROOM_LIST_71                    ; room 71
    DW      ROOM_LIST_72                    ; room 72
    DW      ROOM_LIST_73                    ; room 73
    DW      ROOM_LIST_74                    ; room 74
    DW      ROOM_LIST_75                    ; room 75
    DW      ROOM_LIST_76                    ; room 76
    DW      ROOM_LIST_77                    ; room 77
    DW      ROOM_LIST_78                    ; room 78
    DW      ROOM_LIST_79                    ; room 79
    DW      ROOM_LIST_80                    ; room 80
    DW      ROOM_LIST_81                    ; room 81
    DW      ROOM_LIST_82                    ; room 82
    DW      ROOM_LIST_83                    ; room 83
    DW      ROOM_LIST_84                    ; room 84
    DW      ROOM_LIST_85                    ; room 85
    DW      ROOM_LIST_86                    ; room 86
    DW      ROOM_LIST_87                    ; room 87
    DW      ROOM_LIST_88                    ; room 88
    DW      ROOM_LIST_89                    ; room 89
    DW      ROOM_LIST_90                    ; room 90
    DW      ROOM_LIST_91                    ; room 91
    DW      ROOM_LIST_92                    ; room 92
    DW      ROOM_LIST_93                    ; room 93
    DW      ROOM_LIST_94                    ; room 94
    DW      ROOM_LIST_95                    ; room 95
    DW      ROOM_LIST_96                    ; room 96
    DW      ROOM_LIST_97                    ; room 97
    DW      ROOM_LIST_98                    ; room 98
    DW      ROOM_LIST_99                    ; room 99
    DW      ROOM_LISTS_END                  ; end of room 99

ROOM_LIST_00:
    DB      $01, $00, $20, $0F              ; block of $00 blank, row 0 col 0, 32 wide x 15 high
    DB      $96, $49, $03                   ; slope, row 18 col 9: $08 brick 3 wide x 6 high, then 2 steps of $00 blank 2 high, left-aligned
    DB      $95, $54, $03                   ; slope, row 18 col 20: $08 brick 3 wide x 6 high, then 2 steps of $00 blank 2 high, right-aligned
    DB      $82, $4C, $86                   ; block of $08 brick, row 18 col 12, 8 wide x 6 high
    DB      $03, $00, $01, $18              ; block of $08 brick, row 0 col 0, 1 wide x 24 high
    DB      $83, $E0, $20, $01              ; block of $08 brick, row 23 col 0, 32 wide x 1 high
    DB      $0A, $02, $17                   ; pole column ($95), row 0 col 2, 23 high
    DB      $0A, $1D, $17                   ; pole column ($95), row 0 col 29, 23 high
    DB      $03, $1F, $01, $18              ; block of $08 brick, row 0 col 31, 1 wide x 24 high
    DB      $03, $00, $01, $18              ; block of $08 brick, row 0 col 0, 1 wide x 24 high
    DB      $80, $6F, $35                   ; block of $00 blank, row 19 col 15, 3 wide x 5 high
    DB      $99, $50, $06                   ; rope column ($90), row 18 col 16, 6 high, top row $C4

ROOM_LIST_01:
    DB      $02, $A0, $D4                   ; block of $08 brick, row 5 col 0, 13 wide x 4 high
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $21, $B9                        ; amulet, row 5 col 25 (thing 0)
    DB      $27, $F5                        ; creature, row 7 col 21 (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $31, $70                        ; roller (flags $08), x $70 y $39 (thing 2)

ROOM_LIST_02:
    DB      $04, $2C, $04                   ; slope, row 1 col 12: $00 blank 4 wide x 4 high, then 3 steps of $08 brick 1 high, left-aligned
    DB      $07, $31, $04                   ; slope, row 1 col 17: $00 blank 4 wide x 4 high, then 3 steps of $08 brick 1 high, right-aligned
    DB      $09, $10, $05                   ; rope column ($90), row 0 col 16, 5 high
    DB      $2B, $A3                        ; red door, row 5 col 3 (thing 0)
    DB      $2B, $BC                        ; red door, row 5 col 28 (thing 1)
    DB      $42, $20, $C1                   ; block of $08 brick, row 9 col 0, 12 wide x 1 high
    DB      $42, $40, $B8                   ; block of $08 brick, row 10 col 0, 11 wide x 8 high
    DB      $40, $61, $64                   ; block of $00 blank, row 11 col 1, 6 wide x 4 high
    DB      $85, $00, $03                   ; slope, row 16 col 0: $08 brick 3 wide x 3 high, then 2 steps of $00 blank 1 high, right-aligned
    DB      $58, $E3, $08                   ; ladder column ($88 $89), row 15 col 3, 8 high, top row $10 $11
    DB      $44, $A7, $05                   ; slope, row 13 col 7: $00 blank 5 wide x 5 high, then 4 steps of $08 brick 1 high, left-aligned
    DB      $82, $40, $36                   ; block of $08 brick, row 18 col 0, 3 wide x 6 high
    DB      $82, $E3, $71                   ; block of $08 brick, row 23 col 3, 7 wide x 1 high
    DB      $86, $88, $03                   ; slope, row 20 col 8: $08 brick 3 wide x 3 high, then 2 steps of $00 blank 1 high, left-aligned
    DB      $82, $AB, $11                   ; block of $08 brick, row 21 col 11, 1 wide x 1 high
    DB      $82, $98, $84                   ; block of $08 brick, row 20 col 24, 8 wide x 4 high
    DB      $87, $96, $04                   ; slope, row 20 col 22: $00 blank 4 wide x 4 high, then 3 steps of $08 brick 1 high, right-aligned
    DB      $83, $8B, $0E, $01              ; block of $08 brick, row 20 col 11, 14 wide x 1 high
    DB      $42, $3D, $3B                   ; block of $08 brick, row 9 col 29, 3 wide x 11 high
    DB      $42, $34, $91                   ; block of $08 brick, row 9 col 20, 9 wide x 1 high
    DB      $42, $56, $21                   ; block of $08 brick, row 10 col 22, 2 wide x 1 high
    DB      $42, $77, $16                   ; block of $08 brick, row 11 col 23, 1 wide x 6 high
    DB      $42, $2E, $41                   ; block of $08 brick, row 9 col 14, 4 wide x 1 high
    DB      $9E, $CE, $09                   ; hazard row, row 22 col 14: the first 9 tiles of the run at +$24
    DB      $9E, $ED, $0B                   ; hazard row, row 23 col 13: the first 11 tiles of the run at +$24
    DB      $9F, $EE, $09                   ; hazard row ($38) x 9, row 23 col 14
    DB      $58, $2F, $08                   ; ladder column ($88 $89), row 9 col 15, 8 high, top row $10 $11
    DB      $58, $3A, $0B                   ; ladder column ($88 $89), row 9 col 26, 11 high, top row $10 $11
    DB      $8E, $2C, $08                   ; conveyor (pushes left) row, row 17 col 12, 8 wide: $04, $05s, $06
    DB      $66, $65                        ; red key, row 11 col 5 (thing 2)
    DB      $31, $67                        ; roller (flags $08), x $60 y $91 (thing 3)
    DB      $90                             ; rest of the list only from level 4
    DB      $31, $20                        ; roller (flags $08), x $20 y $39 (thing 4)
    DB      $31, $D0                        ; roller (flags $08), x $D0 y $39 (thing 5)

ROOM_LIST_03:
    DB      $3F, $0E                        ; draw room 14's shapes first, then mirror the screen
    DB      $60, $56                        ; jewel, row 10 col 22 (thing 0)
    DB      $60, $4B                        ; jewel, row 10 col 11 (thing 1)
    DB      $60, $4E                        ; jewel, row 10 col 14 (thing 2)
    DB      $28, $EA                        ; creature, row 7 col 10 (thing 3)
    DB      $02, $0F, $25                   ; block of $08 brick, row 0 col 15, 2 wide x 5 high
    DB      $00, $AF, $24                   ; block of $00 blank, row 5 col 15, 2 wide x 4 high

ROOM_LIST_04:
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $02, $AA, $14                   ; block of $08 brick, row 5 col 10, 1 wide x 4 high
    DB      $20, $B7                        ; jewel, row 5 col 23 (thing 0)
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $30, $80                        ; climber (flags $48), x $80 y $37 (thing 1)

ROOM_LIST_05:
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $8D, $4B, $0D                   ; conveyor (pushes right) row, row 18 col 11, 13 wide: $B8, $B9s, $BA
    DB      $42, $20, $BA                   ; block of $08 brick, row 9 col 0, 11 wide x 10 high
    DB      $40, $A1, $31                   ; block of $00 blank, row 13 col 1, 3 wide x 1 high
    DB      $40, $45, $29                   ; block of $00 blank, row 10 col 5, 2 wide x 9 high
    DB      $40, $48, $27                   ; block of $00 blank, row 10 col 8, 2 wide x 7 high
    DB      $82, $60, $24                   ; block of $08 brick, row 19 col 0, 2 wide x 4 high
    DB      $42, $8B, $37                   ; block of $08 brick, row 12 col 11, 3 wide x 7 high
    DB      $42, $AE, $91                   ; block of $08 brick, row 13 col 14, 9 wide x 1 high
    DB      $42, $8E, $81                   ; block of $08 brick, row 12 col 14, 8 wide x 1 high
    DB      $82, $4E, $21                   ; block of $08 brick, row 18 col 14, 2 wide x 1 high
    DB      $42, $2E, $31                   ; block of $08 brick, row 9 col 14, 3 wide x 1 high
    DB      $42, $39, $71                   ; block of $08 brick, row 9 col 25, 7 wide x 1 high
    DB      $42, $5F, $1D                   ; block of $08 brick, row 10 col 31, 1 wide x 13 high
    DB      $83, $E0, $20, $01              ; block of $08 brick, row 23 col 0, 32 wide x 1 high
    DB      $5C, $41, $03                   ; vanishing floor row ($E8) x 3, row 10 col 1
    DB      $5C, $61, $03                   ; vanishing floor row ($E8) x 3, row 11 col 1
    DB      $5C, $81, $03                   ; vanishing floor row ($E8) x 3, row 12 col 1
    DB      $5C, $C1, $03                   ; vanishing floor row ($E8) x 3, row 14 col 1
    DB      $5C, $E1, $03                   ; vanishing floor row ($E8) x 3, row 15 col 1
    DB      $9C, $01, $03                   ; vanishing floor row ($E8) x 3, row 16 col 1
    DB      $9C, $21, $03                   ; vanishing floor row ($E8) x 3, row 17 col 1
    DB      $9C, $62, $02                   ; vanishing floor row ($E8) x 2, row 19 col 2
    DB      $9C, $82, $02                   ; vanishing floor row ($E8) x 2, row 20 col 2
    DB      $9C, $A2, $02                   ; vanishing floor row ($E8) x 2, row 21 col 2
    DB      $9C, $C2, $02                   ; vanishing floor row ($E8) x 2, row 22 col 2
    DB      $5C, $25, $02                   ; vanishing floor row ($E8) x 2, row 9 col 5
    DB      $5C, $28, $02                   ; vanishing floor row ($E8) x 2, row 9 col 8
    DB      $5E, $4C, $04                   ; hazard row, row 10 col 12: the first 4 tiles of the run at +$24
    DB      $5E, $53, $02                   ; hazard row, row 10 col 19: the first 2 tiles of the run at +$24
    DB      $5E, $6B, $0B                   ; hazard row, row 11 col 11: the first 11 tiles of the run at +$24
    DB      $5E, $96, $01                   ; hazard row, row 12 col 22: the first 1 tiles of the run at +$24
    DB      $5F, $6C, $04                   ; hazard row ($38) x 4, row 11 col 12
    DB      $5F, $73, $02                   ; hazard row ($38) x 2, row 11 col 19
    DB      $5F, $90, $03                   ; hazard row ($38) x 3, row 12 col 16
    DB      $5F, $95, $01                   ; hazard row ($38) x 1, row 12 col 21
    DB      $5F, $E8, $02                   ; hazard row ($38) x 2, row 15 col 8
    DB      $9F, $08, $02                   ; hazard row ($38) x 2, row 16 col 8
    DB      $5E, $C8, $02                   ; hazard row, row 14 col 8: the first 2 tiles of the run at +$24
    DB      $9E, $C5, $02                   ; hazard row, row 22 col 5: the first 2 tiles of the run at +$24
    DB      $42, $DC, $31                   ; block of $08 brick, row 14 col 28, 3 wide x 1 high
    DB      $A0, $6A                        ; jewel, row 19 col 10 (thing 0)
    DB      $A0, $6E                        ; jewel, row 19 col 14 (thing 1)
    DB      $62, $A5                        ; sword, row 13 col 5 (thing 2)
    DB      $62, $CE                        ; sword, row 14 col 14 (thing 3)
    DB      $64, $D0                        ; gold key, row 14 col 16 (thing 4)
    DB      $65, $D2                        ; blue key, row 14 col 18 (thing 5)
    DB      $69, $D5                        ; gold door, row 14 col 21 (thing 6)
    DB      $8B, $6C                        ; barrier ($E0 barrier), row 19 col 12, 4 high
    DB      $59, $3A, $0B                   ; rope column ($90), row 9 col 26, 11 high, top row $C4
    DB      $A7, $BD                        ; creature, row 21 col 29 (thing 7)
    DB      $31, $95                        ; roller (flags $08), x $90 y $81 (thing 8)
    DB      $31, $F2                        ; roller (flags $08), x $F0 y $61 (thing 9)
    DB      $31, $39                        ; roller (flags $08), x $30 y $A9 (thing 10)
    DB      $90                             ; rest of the list only from level 4
    DB      $28, $FC                        ; creature, row 7 col 28 (thing 11)
    DB      $0B, $A4                        ; barrier ($E0 barrier), row 5 col 4, 4 high

ROOM_LIST_06:
    DB      $02, $BD, $14                   ; block of $08 brick, row 5 col 29, 1 wide x 4 high
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $27, $E6                        ; creature, row 7 col 6 (thing 0)
    DB      $27, $F7                        ; creature, row 7 col 23 (thing 1)
    DB      $10                             ; rest of the list only from level 2
    DB      $25, $BB                        ; blue key, row 5 col 27 (thing 2)
    DB      $00, $BD, $14                   ; block of $00 blank, row 5 col 29, 1 wide x 4 high
    DB      $11                             ; rest of the list only from level 6
    DB      $02, $BD, $14                   ; block of $08 brick, row 5 col 29, 1 wide x 4 high

ROOM_LIST_07:
    DB      $08, $0F, $0B                   ; ladder column ($88 $89), row 0 col 15, 11 high
    DB      $42, $20, $4F                   ; block of $08 brick, row 9 col 0, 4 wide x 15 high
    DB      $55, $24, $07                   ; slope, row 9 col 4: $08 brick 7 wide x 14 high, then 6 steps of $00 blank 2 high, right-aligned
    DB      $56, $35, $07                   ; slope, row 9 col 21: $08 brick 7 wide x 14 high, then 6 steps of $00 blank 2 high, left-aligned
    DB      $42, $3C, $4F                   ; block of $08 brick, row 9 col 28, 4 wide x 15 high
    DB      $57, $29, $04                   ; slope, row 9 col 9: $00 blank 4 wide x 8 high, then 3 steps of $08 brick 2 high, right-aligned
    DB      $42, $CD, $63                   ; block of $08 brick, row 14 col 13, 6 wide x 3 high
    DB      $54, $33, $04                   ; slope, row 9 col 19: $00 blank 4 wide x 8 high, then 3 steps of $08 brick 2 high, left-aligned
    DB      $02, $BE, $14                   ; block of $08 brick, row 5 col 30, 1 wide x 4 high
    DB      $83, $E0, $1E, $01              ; block of $08 brick, row 23 col 0, 30 wide x 1 high
    DB      $9E, $CB, $0A                   ; hazard row, row 22 col 11: the first 10 tiles of the run at +$24
    DB      $9F, $EB, $0A                   ; hazard row ($38) x 10, row 23 col 11
    DB      $82, $AE, $43                   ; block of $08 brick, row 21 col 14, 4 wide x 3 high
    DB      $5E, $AD, $06                   ; hazard row, row 13 col 13: the first 6 tiles of the run at +$24
    DB      $5F, $CD, $06                   ; hazard row ($38) x 6, row 14 col 13
    DB      $42, $6F, $25                   ; block of $08 brick, row 11 col 15, 2 wide x 5 high
    DB      $80, $59, $44                   ; block of $00 blank, row 18 col 25, 4 wide x 4 high
    DB      $58, $3C, $0D                   ; ladder column ($88 $89), row 9 col 28, 13 high, top row $10 $11
    DB      $A5, $59                        ; blue key, row 18 col 25 (thing 0)
    DB      $A6, $2F                        ; red key, row 17 col 15 (thing 1)
    DB      $10                             ; rest of the list only from level 2
    DB      $80, $59, $22                   ; block of $00 blank, row 18 col 25, 2 wide x 2 high
    DB      $98, $AF, $03                   ; ladder column ($88 $89), row 21 col 15, 3 high, top row $10 $11
    DB      $A6, $59                        ; red key, row 18 col 25 (thing 2)
    DB      $20, $A4                        ; jewel, row 5 col 4 (thing 3)
    DB      $00, $BE, $14                   ; block of $00 blank, row 5 col 30, 1 wide x 4 high
    DB      $02, $A2, $14                   ; block of $08 brick, row 5 col 2, 1 wide x 4 high
    DB      $50                             ; rest of the list only from level 3
    DB      $00, $A2, $14                   ; block of $00 blank, row 5 col 2, 1 wide x 4 high
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $BB                        ; barrier ($E0 barrier), row 5 col 27, 4 high

ROOM_LIST_08:
    DB      $3E, $06                        ; draw room 6's shapes first
    DB      $30, $20                        ; climber (flags $48), x $20 y $37 (thing 0)
    DB      $30, $D0                        ; climber (flags $48), x $D0 y $37 (thing 1)
    DB      $10                             ; rest of the list only from level 2
    DB      $02, $BD, $14                   ; block of $08 brick, row 5 col 29, 1 wide x 4 high

ROOM_LIST_09:
    DB      $43, $27, $19, $09              ; block of $08 brick, row 9 col 7, 25 wide x 9 high
    DB      $47, $47, $08                   ; slope, row 10 col 7: $00 blank 8 wide x 8 high, then 7 steps of $08 brick 1 high, right-aligned
    DB      $82, $32, $E6                   ; block of $08 brick, row 17 col 18, 14 wide x 6 high
    DB      $83, $C0, $20, $02              ; block of $08 brick, row 22 col 0, 32 wide x 2 high
    DB      $03, $80, $01, $12              ; block of $08 brick, row 4 col 0, 1 wide x 18 high
    DB      $59, $23, $0C                   ; rope column ($90), row 9 col 3, 12 high, top row $C4
    DB      $26, $AC                        ; red key, row 5 col 12 (thing 0)
    DB      $2A, $A9                        ; blue door, row 5 col 9 (thing 1)
    DB      $2A, $B1                        ; blue door, row 5 col 17 (thing 2)
    DB      $29, $B8                        ; gold door, row 5 col 24 (thing 3)
    DB      $29, $BB                        ; gold door, row 5 col 27 (thing 4)
    DB      $82, $CE, $41                   ; block of $08 brick, row 22 col 14, 4 wide x 1 high
    DB      $98, $CF, $02                   ; ladder column ($88 $89), row 22 col 15, 2 high, top row $10 $11
    DB      $10                             ; rest of the list only from level 2
    DB      $00, $AC, $22                   ; block of $00 blank, row 5 col 12, 2 wide x 2 high
    DB      $26, $A6                        ; red key, row 5 col 6 (thing 5)
    DB      $82, $CF, $22                   ; block of $08 brick, row 22 col 15, 2 wide x 2 high
    DB      $50                             ; rest of the list only from level 3
    DB      $98, $CF, $02                   ; ladder column ($88 $89), row 22 col 15, 2 high, top row $10 $11

ROOM_LIST_10:
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $0B, $B7                        ; barrier ($E0 barrier), row 5 col 23, 4 high
    DB      $22, $B1                        ; sword, row 5 col 17 (thing 0)
    DB      $71, $30                        ; roller (flags $08), x $30 y $39, fast (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $A7                        ; barrier ($E0 barrier), row 5 col 7, 4 high

ROOM_LIST_11:
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $28, $F5                        ; creature, row 7 col 21 (thing 0)
    DB      $20, $B9                        ; jewel, row 5 col 25 (thing 1)
    DB      $20, $A6                        ; jewel, row 5 col 6 (thing 2)
    DB      $32, $30                        ; bouncer (flags $10), x $30 y $39 (thing 3)

ROOM_LIST_12:
    DB      $8D, $E6, $14                   ; conveyor (pushes right) row, row 23 col 6, 20 wide: $B8, $B9s, $BA
    DB      $4E, $95, $04                   ; conveyor (pushes left) row, row 12 col 21, 4 wide: $04, $05s, $06
    DB      $8D, $33, $04                   ; conveyor (pushes right) row, row 17 col 19, 4 wide: $B8, $B9s, $BA
    DB      $4D, $DA, $06                   ; conveyor (pushes right) row, row 14 col 26, 6 wide: $B8, $B9s, $BA
    DB      $4E, $F1, $07                   ; conveyor (pushes left) row, row 15 col 17, 7 wide: $04, $05s, $06
    DB      $8E, $75, $04                   ; conveyor (pushes left) row, row 19 col 21, 4 wide: $04, $05s, $06
    DB      $00, $4C, $84                   ; block of $00 blank, row 2 col 12, 8 wide x 4 high
    DB      $08, $0F, $06                   ; ladder column ($88 $89), row 0 col 15, 6 high
    DB      $44, $20, $05                   ; slope, row 9 col 0: $00 blank 5 wide x 5 high, then 4 steps of $08 brick 1 high, left-aligned
    DB      $42, $A0, $1B                   ; block of $08 brick, row 13 col 0, 1 wide x 11 high
    DB      $82, $E1, $61                   ; block of $08 brick, row 23 col 1, 6 wide x 1 high
    DB      $82, $F9, $61                   ; block of $08 brick, row 23 col 25, 6 wide x 1 high
    DB      $07, $FC, $04                   ; slope, row 7 col 28: $00 blank 4 wide x 4 high, then 3 steps of $08 brick 1 high, right-aligned
    DB      $03, $CD, $13, $01              ; block of $08 brick, row 6 col 13, 19 wide x 1 high
    DB      $02, $ED, $16                   ; block of $08 brick, row 7 col 13, 1 wide x 6 high
    DB      $42, $6E, $51                   ; block of $08 brick, row 11 col 14, 5 wide x 1 high
    DB      $42, $90, $17                   ; block of $08 brick, row 12 col 16, 1 wide x 7 high
    DB      $82, $4D, $31                   ; block of $08 brick, row 18 col 13, 3 wide x 1 high
    DB      $42, $FB, $41                   ; block of $08 brick, row 15 col 27, 4 wide x 1 high
    DB      $02, $A9, $1C                   ; block of $08 brick, row 5 col 9, 1 wide x 12 high
    DB      $82, $06, $32                   ; block of $08 brick, row 16 col 6, 3 wide x 2 high
    DB      $82, $25, $41                   ; block of $08 brick, row 17 col 5, 4 wide x 1 high
    DB      $02, $B4, $C2                   ; block of $08 brick, row 5 col 20, 12 wide x 2 high
    DB      $4A, $62, $0C                   ; pole column ($95), row 11 col 2, 12 high
    DB      $0A, $A7, $0B                   ; pole column ($95), row 5 col 7, 11 high
    DB      $58, $6E, $07                   ; ladder column ($88 $89), row 11 col 14, 7 high, top row $10 $11
    DB      $98, $7C, $04                   ; ladder column ($88 $89), row 19 col 28, 4 high, top row $10 $11
    DB      $59, $0B, $09                   ; rope column ($90), row 8 col 11, 9 high, top row $C4
    DB      $0B, $F2                        ; barrier ($E0 barrier), row 7 col 18, 4 high
    DB      $8B, $1B                        ; barrier ($E0 barrier), row 16 col 27, 4 high
    DB      $82, $7B, $41                   ; block of $08 brick, row 19 col 27, 4 wide x 1 high
    DB      $42, $5F, $1E                   ; block of $08 brick, row 10 col 31, 1 wide x 14 high
    DB      $24, $4D                        ; gold key, row 2 col 13 (thing 0)
    DB      $64, $15                        ; gold key, row 8 col 21 (thing 1)
    DB      $71, $34                        ; roller (flags $08), x $30 y $71, fast (thing 2)
    DB      $71, $29                        ; roller (flags $08), x $20 y $A9, fast (thing 3)
    DB      $90                             ; rest of the list only from level 4
    DB      $31, $93                        ; roller (flags $08), x $90 y $69 (thing 4)

ROOM_LIST_13:
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $02, $A0, $55                   ; block of $08 brick, row 5 col 0, 5 wide x 5 high
    DB      $02, $BB, $55                   ; block of $08 brick, row 5 col 27, 5 wide x 5 high
    DB      $04, $A5, $03                   ; slope, row 5 col 5: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, left-aligned
    DB      $07, $B8, $03                   ; slope, row 5 col 24: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, right-aligned
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $20, $A9                        ; jewel, row 5 col 9 (thing 0)
    DB      $20, $B6                        ; jewel, row 5 col 22 (thing 1)
    DB      $71, $60                        ; roller (flags $08), x $60 y $39, fast (thing 2)

ROOM_LIST_14:
    DB      $02, $A0, $71                   ; block of $08 brick, row 5 col 0, 7 wide x 1 high
    DB      $02, $C0, $41                   ; block of $08 brick, row 6 col 0, 4 wide x 1 high
    DB      $02, $E0, $2A                   ; block of $08 brick, row 7 col 0, 2 wide x 10 high
    DB      $45, $82, $02                   ; slope, row 12 col 2: $08 brick 2 wide x 2 high, then 1 steps of $00 blank 1 high, right-aligned
    DB      $43, $C0, $19, $01              ; block of $08 brick, row 14 col 0, 25 wide x 1 high
    DB      $44, $E2, $02                   ; slope, row 15 col 2: $00 blank 2 wide x 2 high, then 1 steps of $08 brick 1 high, left-aligned
    DB      $82, $01, $11                   ; block of $08 brick, row 16 col 1, 1 wide x 1 high
    DB      $82, $20, $13                   ; block of $08 brick, row 17 col 0, 1 wide x 3 high
    DB      $83, $80, $20, $04              ; block of $08 brick, row 20 col 0, 32 wide x 4 high
    DB      $43, $2A, $16, $01              ; block of $08 brick, row 9 col 10, 22 wide x 1 high
    DB      $47, $5B, $02                   ; slope, row 10 col 27: $00 blank 2 wide x 2 high, then 1 steps of $08 brick 1 high, right-aligned
    DB      $42, $5D, $39                   ; block of $08 brick, row 10 col 29, 3 wide x 9 high
    DB      $82, $7C, $41                   ; block of $08 brick, row 19 col 28, 4 wide x 1 high
    DB      $58, $2C, $05                   ; ladder column ($88 $89), row 9 col 12, 5 high, top row $10 $11
    DB      $58, $D6, $06                   ; ladder column ($88 $89), row 14 col 22, 6 high, top row $10 $11
    DB      $98, $8F, $04                   ; ladder column ($88 $89), row 20 col 15, 4 high, top row $10 $11
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $42                        ; climber (flags $48), x $40 y $5F (thing 0)

ROOM_LIST_15:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $02, $BE, $14                   ; block of $08 brick, row 5 col 30, 1 wide x 4 high
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $30, $20                        ; climber (flags $48), x $20 y $37 (thing 0)
    DB      $30, $30                        ; climber (flags $48), x $30 y $37 (thing 1)

ROOM_LIST_16:
    DB      $04, $A0, $05                   ; slope, row 5 col 0: $00 blank 5 wide x 5 high, then 4 steps of $08 brick 1 high, left-aligned
    DB      $42, $20, $1D                   ; block of $08 brick, row 9 col 0, 1 wide x 13 high
    DB      $42, $C1, $21                   ; block of $08 brick, row 14 col 1, 2 wide x 1 high
    DB      $83, $C0, $20, $02              ; block of $08 brick, row 22 col 0, 32 wide x 2 high
    DB      $82, $77, $13                   ; block of $08 brick, row 19 col 23, 1 wide x 3 high
    DB      $82, $9A, $12                   ; block of $08 brick, row 20 col 26, 1 wide x 2 high
    DB      $82, $9D, $32                   ; block of $08 brick, row 20 col 29, 3 wide x 2 high
    DB      $42, $3F, $1B                   ; block of $08 brick, row 9 col 31, 1 wide x 11 high
    DB      $44, $4A, $02                   ; slope, row 10 col 10: $00 blank 2 wide x 2 high, then 1 steps of $08 brick 1 high, left-aligned
    DB      $46, $68, $02                   ; slope, row 11 col 8: $08 brick 2 wide x 2 high, then 1 steps of $00 blank 1 high, left-aligned
    DB      $42, $8C, $36                   ; block of $08 brick, row 12 col 12, 3 wide x 6 high
    DB      $42, $C1, $21                   ; block of $08 brick, row 14 col 1, 2 wide x 1 high
    DB      $45, $C3, $02                   ; slope, row 14 col 3: $08 brick 2 wide x 2 high, then 1 steps of $00 blank 1 high, right-aligned
    DB      $87, $04, $02                   ; slope, row 16 col 4: $00 blank 2 wide x 2 high, then 1 steps of $08 brick 1 high, right-aligned
    DB      $82, $26, $81                   ; block of $08 brick, row 17 col 6, 8 wide x 1 high
    DB      $42, $4E, $14                   ; block of $08 brick, row 10 col 14, 1 wide x 4 high
    DB      $42, $4A, $22                   ; block of $08 brick, row 10 col 10, 2 wide x 2 high
    DB      $42, $CF, $81                   ; block of $08 brick, row 14 col 15, 8 wide x 1 high
    DB      $47, $3C, $03                   ; slope, row 9 col 28: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, right-aligned
    DB      $4E, $35, $08                   ; conveyor (pushes left) row, row 9 col 21, 8 wide: $04, $05s, $06
    DB      $42, $2B, $B1                   ; block of $08 brick, row 9 col 11, 11 wide x 1 high
    DB      $58, $32, $05                   ; ladder column ($88 $89), row 9 col 18, 5 high, top row $10 $11
    DB      $58, $C1, $06                   ; ladder column ($88 $89), row 14 col 1, 6 high, top row $10 $11
    DB      $5E, $8C, $02                   ; hazard row, row 12 col 12: the first 2 tiles of the run at +$24
    DB      $5E, $AB, $01                   ; hazard row, row 13 col 11: the first 1 tiles of the run at +$24
    DB      $5E, $C4, $07                   ; hazard row, row 14 col 4: the first 7 tiles of the run at +$24
    DB      $5F, $AC, $02                   ; hazard row ($38) x 2, row 13 col 12
    DB      $5F, $CB, $03                   ; hazard row ($38) x 3, row 14 col 11
    DB      $5F, $E5, $08                   ; hazard row ($38) x 8, row 15 col 5
    DB      $9F, $06, $06                   ; hazard row ($38) x 6, row 16 col 6
    DB      $98, $CF, $02                   ; ladder column ($88 $89), row 22 col 15, 2 high, top row $10 $11
    DB      $8D, $91, $03                   ; conveyor (pushes right) row, row 20 col 17, 3 wide: $B8, $B9s, $BA
    DB      $9F, $D5, $02                   ; hazard row ($38) x 2, row 22 col 21
    DB      $9F, $D8, $02                   ; hazard row ($38) x 2, row 22 col 24
    DB      $9F, $BB, $02                   ; hazard row ($38) x 2, row 21 col 27
    DB      $9E, $B5, $02                   ; hazard row, row 21 col 21: the first 2 tiles of the run at +$24
    DB      $9E, $B8, $02                   ; hazard row, row 21 col 24: the first 2 tiles of the run at +$24
    DB      $9E, $9B, $02                   ; hazard row, row 20 col 27: the first 2 tiles of the run at +$24
    DB      $9C, $98, $02                   ; vanishing floor row ($E8) x 2, row 20 col 24
    DB      $59, $FB, $03                   ; rope column ($90), row 15 col 27, 3 high, top row $C4
    DB      $59, $B9, $03                   ; rope column ($90), row 13 col 25, 3 high, top row $C4
    DB      $31, $80                        ; roller (flags $08), x $80 y $39 (thing 0)
    DB      $31, $82                        ; roller (flags $08), x $80 y $61 (thing 1)
    DB      $31, $28                        ; roller (flags $08), x $20 y $A1 (thing 2)
    DB      $60, $59                        ; jewel, row 10 col 25 (thing 3)
    DB      $60, $9B                        ; jewel, row 12 col 27 (thing 4)
    DB      $90                             ; rest of the list only from level 4
    DB      $02, $AE, $14                   ; block of $08 brick, row 5 col 14, 1 wide x 4 high

ROOM_LIST_17:
    DB      $3E, $07                        ; draw room 7's shapes first
    DB      $A0, $2F                        ; jewel, row 17 col 15 (thing 0)
    DB      $A0, $59                        ; jewel, row 18 col 25 (thing 1)
    DB      $00, $BE, $14                   ; block of $00 blank, row 5 col 30, 1 wide x 4 high
    DB      $00, $A2, $14                   ; block of $00 blank, row 5 col 2, 1 wide x 4 high
    DB      $10                             ; rest of the list only from level 2
    DB      $82, $AF, $23                   ; block of $08 brick, row 21 col 15, 2 wide x 3 high
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $BB                        ; barrier ($E0 barrier), row 5 col 27, 4 high

ROOM_LIST_18:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $71, $80                        ; roller (flags $08), x $80 y $39, fast (thing 0)

ROOM_LIST_19:
    DB      $5F, $A0, $60                   ; hazard row ($38) x 96, row 13 col 0
    DB      $9F, $00, $C0                   ; hazard row ($38) x 192, row 16 col 0
    DB      $42, $20, $61                   ; block of $08 brick, row 9 col 0, 6 wide x 1 high
    DB      $42, $40, $36                   ; block of $08 brick, row 10 col 0, 3 wide x 6 high
    DB      $82, $00, $52                   ; block of $08 brick, row 16 col 0, 5 wide x 2 high
    DB      $82, $40, $81                   ; block of $08 brick, row 18 col 0, 8 wide x 1 high
    DB      $82, $60, $B1                   ; block of $08 brick, row 19 col 0, 11 wide x 1 high
    DB      $82, $80, $D1                   ; block of $08 brick, row 20 col 0, 13 wide x 1 high
    DB      $82, $A0, $F1                   ; block of $08 brick, row 21 col 0, 15 wide x 1 high
    DB      $82, $B1, $F1                   ; block of $08 brick, row 21 col 17, 15 wide x 1 high
    DB      $82, $93, $D1                   ; block of $08 brick, row 20 col 19, 13 wide x 1 high
    DB      $82, $75, $B1                   ; block of $08 brick, row 19 col 21, 11 wide x 1 high
    DB      $82, $58, $81                   ; block of $08 brick, row 18 col 24, 8 wide x 1 high
    DB      $82, $1B, $52                   ; block of $08 brick, row 16 col 27, 5 wide x 2 high
    DB      $42, $5D, $36                   ; block of $08 brick, row 10 col 29, 3 wide x 6 high
    DB      $42, $3A, $61                   ; block of $08 brick, row 9 col 26, 6 wide x 1 high
    DB      $83, $C0, $20, $02              ; block of $08 brick, row 22 col 0, 32 wide x 2 high
    DB      $42, $CF, $51                   ; block of $08 brick, row 14 col 15, 5 wide x 1 high
    DB      $42, $F1, $11                   ; block of $08 brick, row 15 col 17, 1 wide x 1 high
    DB      $82, $0C, $31                   ; block of $08 brick, row 16 col 12, 3 wide x 1 high
    DB      $82, $13, $21                   ; block of $08 brick, row 16 col 19, 2 wide x 1 high
    DB      $82, $4D, $31                   ; block of $08 brick, row 18 col 13, 3 wide x 1 high
    DB      $82, $51, $21                   ; block of $08 brick, row 18 col 17, 2 wide x 1 high
    DB      $82, $8F, $11                   ; block of $08 brick, row 20 col 15, 1 wide x 1 high
    DB      $5E, $83, $1A                   ; hazard row, row 12 col 3: the first 26 tiles of the run at +$24
    DB      $5C, $26, $14                   ; vanishing floor row ($E8) x 20, row 9 col 6
    DB      $27, $E4                        ; creature, row 7 col 4 (thing 0)
    DB      $90                             ; rest of the list only from level 4
    DB      $28, $FA                        ; creature, row 7 col 26 (thing 1)

ROOM_LIST_20:
    DB      $3E, $0F                        ; draw room 15's shapes first
    DB      $31, $A0                        ; roller (flags $08), x $A0 y $39 (thing 0)
    DB      $24, $A5                        ; gold key, row 5 col 5 (thing 1)
    DB      $21, $A7                        ; amulet, row 5 col 7 (thing 2)
    DB      $0B, $AB                        ; barrier ($E0 barrier), row 5 col 11, 4 high
    DB      $20, $B0                        ; jewel, row 5 col 16 (thing 3)
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11

ROOM_LIST_21:
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $03, $A0, $01, $13              ; block of $08 brick, row 5 col 0, 1 wide x 19 high
    DB      $42, $21, $21                   ; block of $08 brick, row 9 col 1, 2 wide x 1 high
    DB      $42, $C1, $21                   ; block of $08 brick, row 14 col 1, 2 wide x 1 high
    DB      $82, $61, $21                   ; block of $08 brick, row 19 col 1, 2 wide x 1 high
    DB      $82, $81, $14                   ; block of $08 brick, row 20 col 1, 1 wide x 4 high
    DB      $82, $C2, $22                   ; block of $08 brick, row 22 col 2, 2 wide x 2 high
    DB      $83, $E4, $1C, $01              ; block of $08 brick, row 23 col 4, 28 wide x 1 high
    DB      $82, $DC, $41                   ; block of $08 brick, row 22 col 28, 4 wide x 1 high
    DB      $82, $9E, $22                   ; block of $08 brick, row 20 col 30, 2 wide x 2 high
    DB      $82, $7D, $31                   ; block of $08 brick, row 19 col 29, 3 wide x 1 high
    DB      $02, $BF, $1E                   ; block of $08 brick, row 5 col 31, 1 wide x 14 high
    DB      $00, $BF, $14                   ; block of $00 blank, row 5 col 31, 1 wide x 4 high
    DB      $42, $3D, $21                   ; block of $08 brick, row 9 col 29, 2 wide x 1 high
    DB      $42, $DD, $21                   ; block of $08 brick, row 14 col 29, 2 wide x 1 high
    DB      $4E, $23, $05                   ; conveyor (pushes left) row, row 9 col 3, 5 wide: $04, $05s, $06
    DB      $4E, $C3, $05                   ; conveyor (pushes left) row, row 14 col 3, 5 wide: $04, $05s, $06
    DB      $8E, $63, $05                   ; conveyor (pushes left) row, row 19 col 3, 5 wide: $04, $05s, $06
    DB      $4D, $2A, $05                   ; conveyor (pushes right) row, row 9 col 10, 5 wide: $B8, $B9s, $BA
    DB      $4D, $CA, $05                   ; conveyor (pushes right) row, row 14 col 10, 5 wide: $B8, $B9s, $BA
    DB      $8D, $6A, $05                   ; conveyor (pushes right) row, row 19 col 10, 5 wide: $B8, $B9s, $BA
    DB      $4E, $31, $05                   ; conveyor (pushes left) row, row 9 col 17, 5 wide: $04, $05s, $06
    DB      $4E, $D1, $05                   ; conveyor (pushes left) row, row 14 col 17, 5 wide: $04, $05s, $06
    DB      $8E, $71, $05                   ; conveyor (pushes left) row, row 19 col 17, 5 wide: $04, $05s, $06
    DB      $4D, $38, $05                   ; conveyor (pushes right) row, row 9 col 24, 5 wide: $B8, $B9s, $BA
    DB      $4D, $D8, $05                   ; conveyor (pushes right) row, row 14 col 24, 5 wide: $B8, $B9s, $BA
    DB      $8D, $78, $05                   ; conveyor (pushes right) row, row 19 col 24, 5 wide: $B8, $B9s, $BA
    DB      $5C, $68, $02                   ; vanishing floor row ($E8) x 2, row 11 col 8
    DB      $5C, $88, $02                   ; vanishing floor row ($E8) x 2, row 12 col 8
    DB      $9C, $08, $02                   ; vanishing floor row ($E8) x 2, row 16 col 8
    DB      $9C, $28, $02                   ; vanishing floor row ($E8) x 2, row 17 col 8
    DB      $5C, $76, $02                   ; vanishing floor row ($E8) x 2, row 11 col 22
    DB      $5C, $96, $02                   ; vanishing floor row ($E8) x 2, row 12 col 22
    DB      $9C, $16, $02                   ; vanishing floor row ($E8) x 2, row 16 col 22
    DB      $9C, $36, $02                   ; vanishing floor row ($E8) x 2, row 17 col 22
    DB      $5C, $2F, $02                   ; vanishing floor row ($E8) x 2, row 9 col 15
    DB      $5C, $CF, $02                   ; vanishing floor row ($E8) x 2, row 14 col 15
    DB      $9C, $6F, $02                   ; vanishing floor row ($E8) x 2, row 19 col 15
    DB      $9E, $83, $1A                   ; hazard row, row 20 col 3: the first 26 tiles of the run at +$24
    DB      $9E, $A2, $1C                   ; hazard row, row 21 col 2: the first 28 tiles of the run at +$24
    DB      $9F, $A3, $1A                   ; hazard row ($38) x 26, row 21 col 3
    DB      $9F, $C4, $18                   ; hazard row ($38) x 24, row 22 col 4
    DB      $A5, $05                        ; blue key, row 16 col 5 (thing 0)
    DB      $60, $6C                        ; jewel, row 11 col 12 (thing 1)
    DB      $60, $73                        ; jewel, row 11 col 19 (thing 2)
    DB      $A4, $19                        ; gold key, row 16 col 25 (thing 3)
    DB      $50                             ; rest of the list only from level 3
    DB      $71, $50                        ; roller (flags $08), x $50 y $39, fast (thing 4)
    DB      $90                             ; rest of the list only from level 4
    DB      $31, $E0                        ; roller (flags $08), x $D0 y $39 (thing 5)

ROOM_LIST_22:
    DB      $04, $4C, $03                   ; slope, row 2 col 12: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, left-aligned
    DB      $07, $51, $03                   ; slope, row 2 col 17: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, right-aligned
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $42, $27, $B1                   ; block of $08 brick, row 9 col 7, 11 wide x 1 high
    DB      $44, $20, $04                   ; slope, row 9 col 0: $00 blank 4 wide x 4 high, then 3 steps of $08 brick 1 high, left-aligned
    DB      $42, $60, $1C                   ; block of $08 brick, row 11 col 0, 1 wide x 12 high
    DB      $83, $E0, $20, $01              ; block of $08 brick, row 23 col 0, 32 wide x 1 high
    DB      $98, $4F, $06                   ; ladder column ($88 $89), row 18 col 15, 6 high, top row $10 $11
    DB      $82, $43, $35                   ; block of $08 brick, row 18 col 3, 3 wide x 5 high
    DB      $42, $CD, $2A                   ; block of $08 brick, row 14 col 13, 2 wide x 10 high
    DB      $82, $2A, $26                   ; block of $08 brick, row 17 col 10, 2 wide x 6 high
    DB      $42, $AA, $B1                   ; block of $08 brick, row 13 col 10, 11 wide x 1 high
    DB      $82, $51, $51                   ; block of $08 brick, row 18 col 17, 5 wide x 1 high
    DB      $82, $71, $24                   ; block of $08 brick, row 19 col 17, 2 wide x 4 high
    DB      $42, $5F, $1D                   ; block of $08 brick, row 10 col 31, 1 wide x 13 high
    DB      $42, $39, $71                   ; block of $08 brick, row 9 col 25, 7 wide x 1 high
    DB      $9E, $61, $02                   ; hazard row, row 19 col 1: the first 2 tiles of the run at +$24
    DB      $9F, $81, $02                   ; hazard row ($38) x 2, row 20 col 1
    DB      $9F, $A1, $02                   ; hazard row ($38) x 2, row 21 col 1
    DB      $9F, $C1, $02                   ; hazard row ($38) x 2, row 22 col 1
    DB      $9E, $4B, $02                   ; hazard row, row 18 col 11: the first 2 tiles of the run at +$24
    DB      $9F, $6B, $02                   ; hazard row ($38) x 2, row 19 col 11
    DB      $9F, $8B, $02                   ; hazard row ($38) x 2, row 20 col 11
    DB      $9F, $AB, $02                   ; hazard row ($38) x 2, row 21 col 11
    DB      $9F, $CB, $02                   ; hazard row ($38) x 2, row 22 col 11
    DB      $9F, $D3, $0C                   ; hazard row ($38) x 12, row 22 col 19
    DB      $9E, $B3, $0C                   ; hazard row, row 21 col 19: the first 12 tiles of the run at +$24
    DB      $69, $D4                        ; gold door, row 14 col 20 (thing 0)
    DB      $6A, $D1                        ; blue door, row 14 col 17 (thing 1)
    DB      $5C, $E7, $02                   ; vanishing floor row ($E8) x 2, row 15 col 7
    DB      $22, $A1                        ; sword, row 5 col 1 (thing 2)
    DB      $62, $DB                        ; sword, row 14 col 27 (thing 3)
    DB      $60, $4B                        ; jewel, row 10 col 11 (thing 4)
    DB      $60, $4E                        ; jewel, row 10 col 14 (thing 5)
    DB      $59, $3A, $0A                   ; rope column ($90), row 9 col 26, 10 high, top row $C4
    DB      $59, $3D, $09                   ; rope column ($90), row 9 col 29, 9 high, top row $C4
    DB      $0A, $A4, $0D                   ; pole column ($95), row 5 col 4, 13 high
    DB      $31, $71                        ; roller (flags $08), x $70 y $59 (thing 6)
    DB      $71, $70                        ; roller (flags $08), x $70 y $39, fast (thing 7)
    DB      $30, $95                        ; climber (flags $48), x $90 y $7F (thing 8)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $E0                        ; climber (flags $48), x $D0 y $37 (thing 9)

ROOM_LIST_23:
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $42, $20, $11                   ; block of $08 brick, row 9 col 0, 1 wide x 1 high
    DB      $43, $3F, $02, $0F              ; block of $08 brick, row 9 col 31, 2 wide x 15 high
    DB      $83, $E0, $20, $01              ; block of $08 brick, row 23 col 0, 32 wide x 1 high
    DB      $83, $61, $1E, $01              ; block of $08 brick, row 19 col 1, 30 wide x 1 high
    DB      $43, $21, $1E, $01              ; block of $08 brick, row 9 col 1, 30 wide x 1 high
    DB      $42, $C1, $91                   ; block of $08 brick, row 14 col 1, 9 wide x 1 high
    DB      $42, $D2, $D1                   ; block of $08 brick, row 14 col 18, 13 wide x 1 high
    DB      $85, $A1, $02                   ; slope, row 21 col 1: $08 brick 2 wide x 2 high, then 1 steps of $00 blank 1 high, right-aligned
    DB      $86, $8C, $03                   ; slope, row 20 col 12: $08 brick 3 wide x 3 high, then 2 steps of $00 blank 1 high, left-aligned
    DB      $85, $91, $03                   ; slope, row 20 col 17: $08 brick 3 wide x 3 high, then 2 steps of $00 blank 1 high, right-aligned
    DB      $86, $BD, $02                   ; slope, row 21 col 29: $08 brick 2 wide x 2 high, then 1 steps of $00 blank 1 high, left-aligned
    DB      $9F, $C3, $09                   ; hazard row ($38) x 9, row 22 col 3
    DB      $9F, $D4, $09                   ; hazard row ($38) x 9, row 22 col 20
    DB      $9E, $A2, $0B                   ; hazard row, row 21 col 2: the first 11 tiles of the run at +$24
    DB      $9E, $B3, $0B                   ; hazard row, row 21 col 19: the first 11 tiles of the run at +$24
    DB      $58, $25, $05                   ; ladder column ($88 $89), row 9 col 5, 5 high, top row $10 $11
    DB      $58, $39, $05                   ; ladder column ($88 $89), row 9 col 25, 5 high, top row $10 $11
    DB      $98, $6F, $05                   ; ladder column ($88 $89), row 19 col 15, 5 high, top row $10 $11
    DB      $59, $6E, $07                   ; rope column ($90), row 11 col 14, 7 high, top row $C4
    DB      $70, $66                        ; climber (flags $48), x $60 y $87, fast (thing 0)
    DB      $90                             ; rest of the list only from level 4
    DB      $70, $60                        ; climber (flags $48), x $60 y $37, fast (thing 1)

ROOM_LIST_24:
    DB      $3E, $03                        ; draw room 3's shapes first
    DB      $67, $90                        ; creature, row 12 col 16 (thing 0)
    DB      $A7, $4B                        ; creature, row 18 col 11 (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $A2                        ; climber (flags $48), x $A0 y $5F (thing 2)

ROOM_LIST_25:
    DB      $03, $80, $20, $14              ; block of $08 brick, row 4 col 0, 32 wide x 20 high
    DB      $00, $AD, $64                   ; block of $00 blank, row 5 col 13, 6 wide x 4 high
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $22, $AD                        ; sword, row 5 col 13 (thing 0)
    DB      $22, $AF                        ; sword, row 5 col 15 (thing 1)
    DB      $22, $B1                        ; sword, row 5 col 17 (thing 2)
    DB      $31, $80                        ; roller (flags $08), x $80 y $39 (thing 3)

ROOM_LIST_26:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $02, $AA, $15                   ; block of $08 brick, row 5 col 10, 1 wide x 5 high
    DB      $02, $B5, $15                   ; block of $08 brick, row 5 col 21, 1 wide x 5 high

ROOM_LIST_27:
    DB      $9F, $A0, $20                   ; hazard row ($38) x 32, row 21 col 0
    DB      $9F, $C0, $20                   ; hazard row ($38) x 32, row 22 col 0
    DB      $9E, $80, $20                   ; hazard row, row 20 col 0: the first 32 tiles of the run at +$24
    DB      $42, $2F, $21                   ; block of $08 brick, row 9 col 15, 2 wide x 1 high
    DB      $03, $A0, $01, $12              ; block of $08 brick, row 5 col 0, 1 wide x 18 high
    DB      $83, $E0, $20, $01              ; block of $08 brick, row 23 col 0, 32 wide x 1 high
    DB      $82, $61, $24                   ; block of $08 brick, row 19 col 1, 2 wide x 4 high
    DB      $85, $A3, $02                   ; slope, row 21 col 3: $08 brick 2 wide x 2 high, then 1 steps of $00 blank 1 high, right-aligned
    DB      $82, $85, $13                   ; block of $08 brick, row 20 col 5, 1 wide x 3 high
    DB      $82, $88, $13                   ; block of $08 brick, row 20 col 8, 1 wide x 3 high
    DB      $82, $8B, $13                   ; block of $08 brick, row 20 col 11, 1 wide x 3 high
    DB      $86, $AC, $02                   ; slope, row 21 col 12: $08 brick 2 wide x 2 high, then 1 steps of $00 blank 1 high, left-aligned
    DB      $82, $6E, $44                   ; block of $08 brick, row 19 col 14, 4 wide x 4 high
    DB      $82, $D2, $31                   ; block of $08 brick, row 22 col 18, 3 wide x 1 high
    DB      $82, $75, $14                   ; block of $08 brick, row 19 col 21, 1 wide x 4 high
    DB      $82, $78, $24                   ; block of $08 brick, row 19 col 24, 2 wide x 4 high
    DB      $82, $BA, $11                   ; block of $08 brick, row 21 col 26, 1 wide x 1 high
    DB      $82, $DA, $31                   ; block of $08 brick, row 22 col 26, 3 wide x 1 high
    DB      $82, $7D, $24                   ; block of $08 brick, row 19 col 29, 2 wide x 4 high
    DB      $42, $3F, $1E                   ; block of $08 brick, row 9 col 31, 1 wide x 14 high
    DB      $42, $21, $31                   ; block of $08 brick, row 9 col 1, 3 wide x 1 high
    DB      $42, $44, $11                   ; block of $08 brick, row 10 col 4, 1 wide x 1 high
    DB      $82, $41, $11                   ; block of $08 brick, row 18 col 1, 1 wide x 1 high
    DB      $82, $3B, $21                   ; block of $08 brick, row 17 col 27, 2 wide x 1 high
    DB      $42, $BD, $11                   ; block of $08 brick, row 13 col 29, 1 wide x 1 high
    DB      $42, $84, $11                   ; block of $08 brick, row 12 col 4, 1 wide x 1 high
    DB      $42, $C5, $21                   ; block of $08 brick, row 14 col 5, 2 wide x 1 high
    DB      $82, $02, $21                   ; block of $08 brick, row 16 col 2, 2 wide x 1 high
    DB      $42, $89, $21                   ; block of $08 brick, row 12 col 9, 2 wide x 1 high
    DB      $42, $CB, $11                   ; block of $08 brick, row 14 col 11, 1 wide x 1 high
    DB      $82, $2A, $11                   ; block of $08 brick, row 17 col 10, 1 wide x 1 high
    DB      $42, $EE, $11                   ; block of $08 brick, row 15 col 14, 1 wide x 1 high
    DB      $42, $72, $21                   ; block of $08 brick, row 11 col 18, 2 wide x 1 high
    DB      $42, $D4, $21                   ; block of $08 brick, row 14 col 20, 2 wide x 1 high
    DB      $42, $56, $21                   ; block of $08 brick, row 10 col 22, 2 wide x 1 high
    DB      $42, $99, $11                   ; block of $08 brick, row 12 col 25, 1 wide x 1 high
    DB      $82, $19, $11                   ; block of $08 brick, row 16 col 25, 1 wide x 1 high
    DB      $42, $FB, $21                   ; block of $08 brick, row 15 col 27, 2 wide x 1 high
    DB      $42, $3C, $31                   ; block of $08 brick, row 9 col 28, 3 wide x 1 high
    DB      $98, $6F, $05                   ; ladder column ($88 $89), row 19 col 15, 5 high, top row $10 $11
    DB      $9F, $A4, $01                   ; hazard row ($38) x 1, row 21 col 4
    DB      $9F, $AC, $01                   ; hazard row ($38) x 1, row 21 col 12
    DB      $23, $A2                        ; torch, row 5 col 2 (thing 0)
    DB      $D1                             ; rest of the list only from level 9
    DB      $0C, $A2, $02                   ; blank row, row 5 col 2, 2 wide: $00, $00s, $00

ROOM_LIST_28:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $0B, $B9                        ; barrier ($E0 barrier), row 5 col 25, 4 high
    DB      $21, $BB                        ; amulet, row 5 col 27 (thing 0)
    DB      $31, $70                        ; roller (flags $08), x $70 y $39 (thing 1)

ROOM_LIST_29:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $0B, $A8                        ; barrier ($E0 barrier), row 5 col 8, 4 high
    DB      $0B, $AF                        ; barrier ($E0 barrier), row 5 col 15, 4 high
    DB      $0B, $B6                        ; barrier ($E0 barrier), row 5 col 22, 4 high
    DB      $20, $B1                        ; jewel, row 5 col 17 (thing 0)
    DB      $20, $AD                        ; jewel, row 5 col 13 (thing 1)
    DB      $32, $20                        ; bouncer (flags $10), x $20 y $39 (thing 2)
    DB      $32, $30                        ; bouncer (flags $10), x $30 y $39 (thing 3)

ROOM_LIST_30:
    DB      $3F, $16                        ; draw room 22's shapes first, then mirror the screen
    DB      $62, $C3                        ; sword, row 14 col 3 (thing 0)
    DB      $60, $4F                        ; jewel, row 10 col 15 (thing 1)
    DB      $60, $51                        ; jewel, row 10 col 17 (thing 2)
    DB      $69, $CB                        ; gold door, row 14 col 11 (thing 3)
    DB      $5C, $27, $07                   ; vanishing floor row ($E8) x 7, row 9 col 7
    DB      $30, $65                        ; climber (flags $48), x $60 y $7F (thing 4)
    DB      $31, $61                        ; roller (flags $08), x $60 y $59 (thing 5)
    DB      $90                             ; rest of the list only from level 4
    DB      $71, $10                        ; roller (flags $08), x $10 y $39, fast (thing 6)
    DB      $30, $10                        ; climber (flags $48), x $10 y $37 (thing 7)

ROOM_LIST_31:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $02, $8A, $15                   ; block of $08 brick, row 4 col 10, 1 wide x 5 high
    DB      $02, $95, $15                   ; block of $08 brick, row 4 col 21, 1 wide x 5 high
    DB      $23, $AF                        ; torch, row 5 col 15 (thing 0)
    DB      $11                             ; rest of the list only from level 6
    DB      $00, $AA, $14                   ; block of $00 blank, row 5 col 10, 1 wide x 4 high
    DB      $11                             ; rest of the list only from level 6
    DB      $0C, $AF, $02                   ; blank row, row 5 col 15, 2 wide: $00, $00s, $00

ROOM_LIST_32:
    DB      $3E, $1B                        ; draw room 27's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $20, $A2                        ; jewel, row 5 col 2 (thing 0)
    DB      $20, $A5                        ; jewel, row 5 col 5 (thing 1)
    DB      $22, $BB                        ; sword, row 5 col 27 (thing 2)
    DB      $22, $BD                        ; sword, row 5 col 29 (thing 3)
    DB      $02, $BF, $14                   ; block of $08 brick, row 5 col 31, 1 wide x 4 high

ROOM_LIST_33:
    DB      $3E, $0E                        ; draw room 14's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $30, $90                        ; climber (flags $48), x $90 y $37 (thing 0)
    DB      $31, $52                        ; roller (flags $08), x $50 y $61 (thing 1)

ROOM_LIST_34:
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $4E, $EB, $0A                   ; conveyor (pushes left) row, row 15 col 11, 10 wide: $04, $05s, $06
    DB      $43, $20, $20, $01              ; block of $08 brick, row 9 col 0, 32 wide x 1 high
    DB      $42, $40, $1A                   ; block of $08 brick, row 10 col 0, 1 wide x 10 high
    DB      $82, $80, $33                   ; block of $08 brick, row 20 col 0, 3 wide x 3 high
    DB      $82, $A3, $22                   ; block of $08 brick, row 21 col 3, 2 wide x 2 high
    DB      $83, $E0, $20, $01              ; block of $08 brick, row 23 col 0, 32 wide x 1 high
    DB      $83, $47, $12, $01              ; block of $08 brick, row 18 col 7, 18 wide x 1 high
    DB      $82, $9D, $33                   ; block of $08 brick, row 20 col 29, 3 wide x 3 high
    DB      $82, $BB, $22                   ; block of $08 brick, row 21 col 27, 2 wide x 2 high
    DB      $42, $5F, $1A                   ; block of $08 brick, row 10 col 31, 1 wide x 10 high
    DB      $42, $E9, $31                   ; block of $08 brick, row 15 col 9, 3 wide x 1 high
    DB      $42, $F4, $31                   ; block of $08 brick, row 15 col 20, 3 wide x 1 high
    DB      $A9, $6A                        ; gold door, row 19 col 10 (thing 0)
    DB      $A9, $75                        ; gold door, row 19 col 21 (thing 1)
    DB      $64, $6D                        ; gold key, row 11 col 13 (thing 2)
    DB      $64, $71                        ; gold key, row 11 col 17 (thing 3)
    DB      $9C, $41, $05                   ; vanishing floor row ($E8) x 5, row 18 col 1
    DB      $9C, $5A, $05                   ; vanishing floor row ($E8) x 5, row 18 col 26
    DB      $58, $29, $06                   ; ladder column ($88 $89), row 9 col 9, 6 high, top row $10 $11
    DB      $58, $35, $06                   ; ladder column ($88 $89), row 9 col 21, 6 high, top row $10 $11
    DB      $58, $EF, $03                   ; ladder column ($88 $89), row 15 col 15, 3 high, top row $10 $11
    DB      $98, $EF, $01                   ; ladder column ($88 $89), row 23 col 15, 1 high, top row $10 $11
    DB      $31, $50                        ; roller (flags $08), x $50 y $39 (thing 4)

ROOM_LIST_35:
    DB      $3E, $0F                        ; draw room 15's shapes first

ROOM_LIST_36:
    DB      $3E, $19                        ; draw room 25's shapes first
    DB      $20, $AE                        ; jewel, row 5 col 14 (thing 0)
    DB      $20, $B1                        ; jewel, row 5 col 17 (thing 1)
    DB      $30, $80                        ; climber (flags $48), x $80 y $37 (thing 2)

ROOM_LIST_37:
    DB      $03, $A0, $20, $13              ; block of $08 brick, row 5 col 0, 32 wide x 19 high
    DB      $01, $A4, $18, $04              ; block of $00 blank, row 5 col 4, 24 wide x 4 high
    DB      $41, $41, $1E, $04              ; block of $00 blank, row 10 col 1, 30 wide x 4 high
    DB      $41, $E1, $1E, $04              ; block of $00 blank, row 15 col 1, 30 wide x 4 high
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $58, $26, $05                   ; ladder column ($88 $89), row 9 col 6, 5 high, top row $10 $11
    DB      $58, $D5, $05                   ; ladder column ($88 $89), row 14 col 21, 5 high, top row $10 $11
    DB      $98, $6F, $05                   ; ladder column ($88 $89), row 19 col 15, 5 high, top row $10 $11
    DB      $60, $4C                        ; jewel, row 10 col 12 (thing 0)
    DB      $27, $EB                        ; creature, row 7 col 11 (thing 1)
    DB      $67, $89                        ; creature, row 12 col 9 (thing 2)
    DB      $A7, $33                        ; creature, row 17 col 19 (thing 3)
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $AD                        ; barrier ($E0 barrier), row 5 col 13, 4 high
    DB      $0B, $B2                        ; barrier ($E0 barrier), row 5 col 18, 4 high

ROOM_LIST_38:
    DB      $3E, $17                        ; draw room 23's shapes first
    DB      $02, $9F, $25                   ; block of $08 brick, row 4 col 31, 2 wide x 5 high
    DB      $32, $80                        ; bouncer (flags $10), x $80 y $39 (thing 0)
    DB      $32, $86                        ; bouncer (flags $10), x $80 y $89 (thing 1)
    DB      $32, $D6                        ; bouncer (flags $10), x $D0 y $89 (thing 2)

ROOM_LIST_39:
    DB      $3E, $17                        ; draw room 23's shapes first
    DB      $02, $A0, $14                   ; block of $08 brick, row 5 col 0, 1 wide x 4 high
    DB      $71, $80                        ; roller (flags $08), x $80 y $39, fast (thing 0)
    DB      $71, $86                        ; roller (flags $08), x $80 y $89, fast (thing 1)
    DB      $71, $12                        ; roller (flags $08), x $10 y $61, fast (thing 2)
    DB      $71, $D2                        ; roller (flags $08), x $D0 y $61, fast (thing 3)

ROOM_LIST_40:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $30, $20                        ; climber (flags $48), x $20 y $37 (thing 0)
    DB      $30, $C0                        ; climber (flags $48), x $C0 y $37 (thing 1)

ROOM_LIST_41:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $32, $10                        ; bouncer (flags $10), x $10 y $39 (thing 0)
    DB      $32, $80                        ; bouncer (flags $10), x $80 y $39 (thing 1)

ROOM_LIST_42:
    DB      $3F, $10                        ; draw room 16's shapes first, then mirror the screen
    DB      $18, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high, top row $10 $11
    DB      $60, $84                        ; jewel, row 12 col 4 (thing 0)
    DB      $60, $46                        ; jewel, row 10 col 6 (thing 1)
    DB      $31, $70                        ; roller (flags $08), x $70 y $39 (thing 2)
    DB      $30, $72                        ; climber (flags $48), x $70 y $5F (thing 3)
    DB      $30, $88                        ; climber (flags $48), x $80 y $9F (thing 4)

ROOM_LIST_43:
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $02, $A0, $14                   ; block of $08 brick, row 5 col 0, 1 wide x 4 high
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $31, $50                        ; roller (flags $08), x $50 y $39 (thing 0)
    DB      $32, $D0                        ; bouncer (flags $10), x $D0 y $39 (thing 1)

ROOM_LIST_44:
    DB      $3F, $2B                        ; draw room 43's shapes first, then mirror the screen
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $31, $10                        ; roller (flags $08), x $10 y $39 (thing 0)
    DB      $27, $E5                        ; creature, row 7 col 5 (thing 1)

ROOM_LIST_45:
    DB      $04, $4C, $03                   ; slope, row 2 col 12: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, left-aligned
    DB      $07, $51, $03                   ; slope, row 2 col 17: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, right-aligned
    DB      $03, $94, $0C, $14              ; block of $08 brick, row 4 col 20, 12 wide x 20 high
    DB      $42, $13, $15                   ; block of $08 brick, row 8 col 19, 1 wide x 5 high
    DB      $42, $2D, $61                   ; block of $08 brick, row 9 col 13, 6 wide x 1 high
    DB      $42, $AA, $A1                   ; block of $08 brick, row 13 col 10, 10 wide x 1 high
    DB      $42, $D1, $3A                   ; block of $08 brick, row 14 col 17, 3 wide x 10 high
    DB      $82, $49, $61                   ; block of $08 brick, row 18 col 9, 6 wide x 1 high
    DB      $82, $6D, $45                   ; block of $08 brick, row 19 col 13, 4 wide x 5 high
    DB      $82, $E1, $C1                   ; block of $08 brick, row 23 col 1, 12 wide x 1 high
    DB      $02, $80, $C1                   ; block of $08 brick, row 4 col 0, 12 wide x 1 high
    DB      $42, $21, $61                   ; block of $08 brick, row 9 col 1, 6 wide x 1 high
    DB      $03, $A0, $01, $12              ; block of $08 brick, row 5 col 0, 1 wide x 18 high
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $98, $4F, $06                   ; ladder column ($88 $89), row 18 col 15, 6 high, top row $10 $11
    DB      $59, $23, $0A                   ; rope column ($90), row 9 col 3, 10 high, top row $C4
    DB      $59, $25, $0B                   ; rope column ($90), row 9 col 5, 11 high, top row $C4
    DB      $9E, $A1, $0C                   ; hazard row, row 21 col 1: the first 12 tiles of the run at +$24
    DB      $9F, $C1, $0C                   ; hazard row ($38) x 12, row 22 col 1
    DB      $30, $10                        ; climber (flags $48), x $10 y $37 (thing 0)
    DB      $31, $65                        ; roller (flags $08), x $60 y $81 (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $31, $51                        ; roller (flags $08), x $50 y $59 (thing 2)

ROOM_LIST_46:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $02, $A0, $84                   ; block of $08 brick, row 5 col 0, 8 wide x 4 high
    DB      $29, $AB                        ; gold door, row 5 col 11 (thing 0)
    DB      $29, $B4                        ; gold door, row 5 col 20 (thing 1)
    DB      $A9, $6C                        ; gold door, row 19 col 12 (thing 2)
    DB      $A9, $73                        ; gold door, row 19 col 19 (thing 3)
    DB      $65, $6D                        ; blue key, row 11 col 13 (thing 4)
    DB      $65, $71                        ; blue key, row 11 col 17 (thing 5)
    DB      $71, $53                        ; roller (flags $08), x $50 y $69, fast (thing 6)
    DB      $98, $EF, $01                   ; ladder column ($88 $89), row 23 col 15, 1 high, top row $10 $11

ROOM_LIST_47:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $2A, $AB                        ; blue door, row 5 col 11 (thing 0)
    DB      $2A, $B4                        ; blue door, row 5 col 20 (thing 1)
    DB      $AA, $6C                        ; blue door, row 19 col 12 (thing 2)
    DB      $AA, $73                        ; blue door, row 19 col 19 (thing 3)
    DB      $64, $6D                        ; gold key, row 11 col 13 (thing 4)
    DB      $64, $71                        ; gold key, row 11 col 17 (thing 5)
    DB      $98, $EF, $01                   ; ladder column ($88 $89), row 23 col 15, 1 high, top row $10 $11
    DB      $31, $20                        ; roller (flags $08), x $20 y $39 (thing 6)
    DB      $31, $79                        ; roller (flags $08), x $70 y $A9 (thing 7)

ROOM_LIST_48:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $02, $94, $C5                   ; block of $08 brick, row 4 col 20, 12 wide x 5 high
    DB      $22, $AD                        ; sword, row 5 col 13 (thing 0)
    DB      $20, $B0                        ; jewel, row 5 col 16 (thing 1)
    DB      $71, $20                        ; roller (flags $08), x $20 y $39, fast (thing 2)

ROOM_LIST_49:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $02, $A0, $14                   ; block of $08 brick, row 5 col 0, 1 wide x 4 high
    DB      $2A, $B9                        ; blue door, row 5 col 25 (thing 0)
    DB      $58, $2F, $0F                   ; ladder column ($88 $89), row 9 col 15, 15 high, top row $10 $11
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $40                        ; climber (flags $48), x $40 y $37 (thing 1)

ROOM_LIST_50:
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $40, $4A, $B5                   ; block of $00 blank, row 10 col 10, 11 wide x 5 high
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $70, $50                        ; climber (flags $48), x $50 y $37, fast (thing 0)
    DB      $58, $2A, $06                   ; ladder column ($88 $89), row 9 col 10, 6 high, top row $10 $11
    DB      $58, $34, $06                   ; ladder column ($88 $89), row 9 col 20, 6 high, top row $10 $11
    DB      $58, $EF, $09                   ; ladder column ($88 $89), row 15 col 15, 9 high, top row $10 $11

ROOM_LIST_51:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $66, $6F                        ; red key, row 11 col 15 (thing 0)
    DB      $31, $75                        ; roller (flags $08), x $70 y $81 (thing 1)
    DB      $71, $73                        ; roller (flags $08), x $70 y $69, fast (thing 2)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $49                        ; climber (flags $48), x $40 y $A7 (thing 3)

ROOM_LIST_52:
    DB      $3F, $16                        ; draw room 22's shapes first, then mirror the screen
    DB      $03, $B2, $0E, $12              ; block of $08 brick, row 5 col 18, 14 wide x 18 high
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $10                        ; climber (flags $48), x $10 y $37 (thing 0)

ROOM_LIST_53:
    DB      $3E, $10                        ; draw room 16's shapes first
    DB      $18, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high, top row $10 $11
    DB      $60, $50                        ; jewel, row 10 col 16 (thing 0)
    DB      $31, $70                        ; roller (flags $08), x $70 y $39 (thing 1)
    DB      $31, $92                        ; roller (flags $08), x $90 y $61 (thing 2)
    DB      $31, $18                        ; roller (flags $08), x $10 y $A1 (thing 3)

ROOM_LIST_54:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $30, $30                        ; climber (flags $48), x $30 y $37 (thing 0)

ROOM_LIST_55:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $58, $2F, $10                   ; ladder column ($88 $89), row 9 col 15, 16 high, top row $10 $11
    DB      $31, $80                        ; roller (flags $08), x $80 y $39 (thing 0)
    DB      $31, $70                        ; roller (flags $08), x $70 y $39 (thing 1)

ROOM_LIST_56:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $00, $BF, $14                   ; block of $00 blank, row 5 col 31, 1 wide x 4 high
    DB      $02, $B8, $14                   ; block of $08 brick, row 5 col 24, 1 wide x 4 high
    DB      $30, $40                        ; climber (flags $48), x $40 y $37 (thing 0)
    DB      $70, $80                        ; climber (flags $48), x $80 y $37, fast (thing 1)

ROOM_LIST_57:
    DB      $3E, $31                        ; draw room 49's shapes first
    DB      $70, $40                        ; climber (flags $48), x $40 y $37, fast (thing 0)

ROOM_LIST_58:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $30, $40                        ; climber (flags $48), x $40 y $37 (thing 0)

ROOM_LIST_59:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $A9, $67                        ; gold door, row 19 col 7 (thing 0)
    DB      $A9, $77                        ; gold door, row 19 col 23 (thing 1)
    DB      $64, $6D                        ; gold key, row 11 col 13 (thing 2)
    DB      $64, $71                        ; gold key, row 11 col 17 (thing 3)
    DB      $31, $49                        ; roller (flags $08), x $40 y $A9 (thing 4)

ROOM_LIST_60:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $29, $AB                        ; gold door, row 5 col 11 (thing 0)
    DB      $29, $B4                        ; gold door, row 5 col 20 (thing 1)
    DB      $25, $AD                        ; blue key, row 5 col 13 (thing 2)
    DB      $25, $B1                        ; blue key, row 5 col 17 (thing 3)
    DB      $A5, $6D                        ; blue key, row 19 col 13 (thing 4)
    DB      $A5, $71                        ; blue key, row 19 col 17 (thing 5)
    DB      $65, $6C                        ; blue key, row 11 col 12 (thing 6)
    DB      $65, $72                        ; blue key, row 11 col 18 (thing 7)
    DB      $31, $99                        ; roller (flags $08), x $90 y $A9 (thing 8)
    DB      $31, $83                        ; roller (flags $08), x $80 y $69 (thing 9)
    DB      $31, $85                        ; roller (flags $08), x $80 y $81 (thing 10)
    DB      $31, $C0                        ; roller (flags $08), x $C0 y $39 (thing 11)

ROOM_LIST_61:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $2A, $AB                        ; blue door, row 5 col 11 (thing 0)
    DB      $2A, $B4                        ; blue door, row 5 col 20 (thing 1)
    DB      $AA, $67                        ; blue door, row 19 col 7 (thing 2)
    DB      $AA, $78                        ; blue door, row 19 col 24 (thing 3)
    DB      $64, $6C                        ; gold key, row 11 col 12 (thing 4)
    DB      $64, $72                        ; gold key, row 11 col 18 (thing 5)
    DB      $71, $83                        ; roller (flags $08), x $80 y $69, fast (thing 6)
    DB      $31, $49                        ; roller (flags $08), x $40 y $A9 (thing 7)

ROOM_LIST_62:
    DB      $3E, $32                        ; draw room 50's shapes first
    DB      $27, $F6                        ; creature, row 7 col 22 (thing 0)
    DB      $02, $0F, $29                   ; block of $08 brick, row 0 col 15, 2 wide x 9 high
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $20                        ; climber (flags $48), x $20 y $37 (thing 1)

ROOM_LIST_63:
    DB      $3E, $23                        ; draw room 35's shapes first
    DB      $90                             ; rest of the list only from level 4
    DB      $27, $E7                        ; creature, row 7 col 7 (thing 0)
    DB      $0B, $A6                        ; barrier ($E0 barrier), row 5 col 6, 4 high
    DB      $0B, $A9                        ; barrier ($E0 barrier), row 5 col 9, 4 high
    DB      $30, $90                        ; climber (flags $48), x $90 y $37 (thing 1)

ROOM_LIST_64:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $02, $A0, $24                   ; block of $08 brick, row 5 col 0, 2 wide x 4 high
    DB      $23, $A3                        ; torch, row 5 col 3 (thing 0)
    DB      $21, $BB                        ; amulet, row 5 col 27 (thing 1)
    DB      $21, $A5                        ; amulet, row 5 col 5 (thing 2)
    DB      $31, $90                        ; roller (flags $08), x $90 y $39 (thing 3)
    DB      $32, $90                        ; bouncer (flags $10), x $90 y $39 (thing 4)
    DB      $51                             ; rest of the list only from level 7
    DB      $23, $A3                        ; torch, row 5 col 3 (thing 5)

ROOM_LIST_65:
    DB      $3E, $27                        ; draw room 39's shapes first
    DB      $00, $A0, $14                   ; block of $00 blank, row 5 col 0, 1 wide x 4 high
    DB      $02, $BF, $14                   ; block of $08 brick, row 5 col 31, 1 wide x 4 high
    DB      $71, $30                        ; roller (flags $08), x $30 y $39, fast (thing 0)
    DB      $71, $12                        ; roller (flags $08), x $10 y $61, fast (thing 1)
    DB      $71, $B2                        ; roller (flags $08), x $B0 y $61, fast (thing 2)
    DB      $71, $36                        ; roller (flags $08), x $30 y $89, fast (thing 3)

ROOM_LIST_66:
    DB      $3E, $16                        ; draw room 22's shapes first
    DB      $62, $DB                        ; sword, row 14 col 27 (thing 0)
    DB      $60, $4A                        ; jewel, row 10 col 10 (thing 1)
    DB      $60, $4E                        ; jewel, row 10 col 14 (thing 2)
    DB      $71, $70                        ; roller (flags $08), x $70 y $39, fast (thing 3)
    DB      $31, $71                        ; roller (flags $08), x $70 y $59 (thing 4)
    DB      $30, $85                        ; climber (flags $48), x $80 y $7F (thing 5)

ROOM_LIST_67:
    DB      $3E, $05                        ; draw room 5's shapes first
    DB      $80, $6C, $14                   ; block of $00 blank, row 19 col 12, 1 wide x 4 high
    DB      $82, $53, $31                   ; block of $08 brick, row 18 col 19, 3 wide x 1 high
    DB      $8B, $73                        ; barrier ($E0 barrier), row 19 col 19, 4 high
    DB      $8B, $74                        ; barrier ($E0 barrier), row 19 col 20, 4 high
    DB      $8B, $75                        ; barrier ($E0 barrier), row 19 col 21, 4 high
    DB      $65, $CE                        ; blue key, row 14 col 14 (thing 0)
    DB      $A0, $77                        ; jewel, row 19 col 23 (thing 1)
    DB      $31, $F2                        ; roller (flags $08), x $F0 y $61 (thing 2)
    DB      $31, $10                        ; roller (flags $08), x $10 y $39 (thing 3)
    DB      $30, $99                        ; climber (flags $48), x $90 y $A7 (thing 4)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $D0                        ; climber (flags $48), x $D0 y $37 (thing 5)

ROOM_LIST_68:
    DB      $3E, $17                        ; draw room 23's shapes first
    DB      $71, $10                        ; roller (flags $08), x $10 y $39, fast (thing 0)
    DB      $90                             ; rest of the list only from level 4
    DB      $31, $32                        ; roller (flags $08), x $30 y $61 (thing 1)
    DB      $31, $D2                        ; roller (flags $08), x $D0 y $61 (thing 2)
    DB      $71, $A6                        ; roller (flags $08), x $A0 y $89, fast (thing 3)

ROOM_LIST_69:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $0B, $A8                        ; barrier ($E0 barrier), row 5 col 8, 4 high
    DB      $0B, $AC                        ; barrier ($E0 barrier), row 5 col 12, 4 high
    DB      $30, $20                        ; climber (flags $48), x $20 y $37 (thing 0)
    DB      $30, $30                        ; climber (flags $48), x $30 y $37 (thing 1)

ROOM_LIST_70:
    DB      $3E, $37                        ; draw room 55's shapes first
    DB      $72, $20                        ; bouncer (flags $10), x $20 y $39, fast (thing 0)
    DB      $32, $30                        ; bouncer (flags $10), x $30 y $39 (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $02, $A0, $14                   ; block of $08 brick, row 5 col 0, 1 wide x 4 high

ROOM_LIST_71:
    DB      $3E, $02                        ; draw room 2's shapes first
    DB      $18, $0F, $06                   ; ladder column ($88 $89), row 0 col 15, 6 high, top row $10 $11
    DB      $66, $62                        ; red key, row 11 col 2 (thing 0)
    DB      $30, $20                        ; climber (flags $48), x $20 y $37 (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $A0                        ; climber (flags $48), x $A0 y $37 (thing 2)

ROOM_LIST_72:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $31, $50                        ; roller (flags $08), x $50 y $39 (thing 0)
    DB      $70, $30                        ; climber (flags $48), x $30 y $37, fast (thing 1)
    DB      $02, $BE, $24                   ; block of $08 brick, row 5 col 30, 2 wide x 4 high
    DB      $20, $B2                        ; jewel, row 5 col 18 (thing 2)
    DB      $20, $B6                        ; jewel, row 5 col 22 (thing 3)
    DB      $20, $BA                        ; jewel, row 5 col 26 (thing 4)
    DB      $10                             ; rest of the list only from level 2
    DB      $23, $AF                        ; torch, row 5 col 15 (thing 5)
    DB      $00, $B2, $E4                   ; block of $00 blank, row 5 col 18, 14 wide x 4 high
    DB      $02, $A0, $24                   ; block of $08 brick, row 5 col 0, 2 wide x 4 high
    DB      $20, $A4                        ; jewel, row 5 col 4 (thing 6)
    DB      $20, $A8                        ; jewel, row 5 col 8 (thing 7)
    DB      $20, $AC                        ; jewel, row 5 col 12 (thing 8)
    DB      $50                             ; rest of the list only from level 3
    DB      $00, $A3, $A4                   ; block of $00 blank, row 5 col 3, 10 wide x 4 high
    DB      $11                             ; rest of the list only from level 6
    DB      $0C, $AF, $02                   ; blank row, row 5 col 15, 2 wide: $00, $00s, $00
    DB      $91                             ; rest of the list only from level 8
    DB      $00, $A0, $34                   ; block of $00 blank, row 5 col 0, 3 wide x 4 high

ROOM_LIST_73:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $43, $E2, $1D, $08              ; block of $08 brick, row 15 col 2, 29 wide x 8 high
    DB      $5C, $23, $1A                   ; vanishing floor row ($E8) x 26, row 9 col 3
    DB      $42, $2E, $46                   ; block of $08 brick, row 9 col 14, 4 wide x 6 high
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $5F, $D2, $02                   ; hazard row ($38) x 2, row 14 col 18
    DB      $31, $30                        ; roller (flags $08), x $30 y $39 (thing 0)
    DB      $31, $A0                        ; roller (flags $08), x $A0 y $39 (thing 1)

ROOM_LIST_74:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $32, $30                        ; bouncer (flags $10), x $30 y $39 (thing 0)
    DB      $32, $A0                        ; bouncer (flags $10), x $A0 y $39 (thing 1)

ROOM_LIST_75:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $27, $EC                        ; creature, row 7 col 12 (thing 0)
    DB      $27, $F1                        ; creature, row 7 col 17 (thing 1)

ROOM_LIST_76:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $29, $AB                        ; gold door, row 5 col 11 (thing 0)
    DB      $29, $B4                        ; gold door, row 5 col 20 (thing 1)
    DB      $66, $6C                        ; red key, row 11 col 12 (thing 2)
    DB      $64, $72                        ; gold key, row 11 col 18 (thing 3)
    DB      $82, $EF, $21                   ; block of $08 brick, row 23 col 15, 2 wide x 1 high
    DB      $71, $43                        ; roller (flags $08), x $40 y $69, fast (thing 4)

ROOM_LIST_77:
    DB      $3E, $22                        ; draw room 34's shapes first
    DB      $29, $AB                        ; gold door, row 5 col 11 (thing 0)
    DB      $29, $B4                        ; gold door, row 5 col 20 (thing 1)
    DB      $AA, $67                        ; blue door, row 19 col 7 (thing 2)
    DB      $AA, $77                        ; blue door, row 19 col 23 (thing 3)
    DB      $64, $6C                        ; gold key, row 11 col 12 (thing 4)
    DB      $65, $72                        ; blue key, row 11 col 18 (thing 5)
    DB      $31, $20                        ; roller (flags $08), x $20 y $39 (thing 6)
    DB      $71, $43                        ; roller (flags $08), x $40 y $69, fast (thing 7)

ROOM_LIST_78:
    DB      $3E, $45                        ; draw room 69's shapes first
    DB      $30, $40                        ; climber (flags $48), x $40 y $37 (thing 0)
    DB      $30, $20                        ; climber (flags $48), x $20 y $37 (thing 1)

ROOM_LIST_79:
    DB      $3E, $32                        ; draw room 50's shapes first
    DB      $70, $40                        ; climber (flags $48), x $40 y $37, fast (thing 0)
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $A9                        ; barrier ($E0 barrier), row 5 col 9, 4 high

ROOM_LIST_80:
    DB      $3E, $0F                        ; draw room 15's shapes first

ROOM_LIST_81:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $02, $A0, $24                   ; block of $08 brick, row 5 col 0, 2 wide x 4 high
    DB      $20, $A3                        ; jewel, row 5 col 3 (thing 0)
    DB      $20, $A5                        ; jewel, row 5 col 5 (thing 1)
    DB      $20, $A7                        ; jewel, row 5 col 7 (thing 2)
    DB      $31, $20                        ; roller (flags $08), x $20 y $39 (thing 3)
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $A7                        ; barrier ($E0 barrier), row 5 col 7, 4 high
    DB      $0B, $A9                        ; barrier ($E0 barrier), row 5 col 9, 4 high
    DB      $0B, $AB                        ; barrier ($E0 barrier), row 5 col 11, 4 high

ROOM_LIST_82:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $30, $70                        ; climber (flags $48), x $70 y $37 (thing 0)
    DB      $27, $F5                        ; creature, row 7 col 21 (thing 1)

ROOM_LIST_83:
    DB      $3E, $2A                        ; draw room 42's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $00, $B1, $14                   ; block of $00 blank, row 5 col 17, 1 wide x 4 high
    DB      $A0, $52                        ; jewel, row 18 col 18 (thing 0)
    DB      $A2, $55                        ; sword, row 18 col 21 (thing 1)
    DB      $82, $CF, $22                   ; block of $08 brick, row 22 col 15, 2 wide x 2 high
    DB      $30, $98                        ; climber (flags $48), x $90 y $9F (thing 2)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $62                        ; climber (flags $48), x $60 y $5F (thing 3)

ROOM_LIST_84:
    DB      $3E, $2B                        ; draw room 43's shapes first
    DB      $31, $20                        ; roller (flags $08), x $20 y $39 (thing 0)
    DB      $31, $30                        ; roller (flags $08), x $30 y $39 (thing 1)

ROOM_LIST_85:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $27, $F8                        ; creature, row 7 col 24 (thing 0)
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $AF                        ; barrier ($E0 barrier), row 5 col 15, 4 high
    DB      $27, $E5                        ; creature, row 7 col 5 (thing 1)

ROOM_LIST_86:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $71, $30                        ; roller (flags $08), x $30 y $39, fast (thing 0)

ROOM_LIST_87:
    DB      $0B, $A4                        ; barrier ($E0 barrier), row 5 col 4, 4 high
    DB      $0B, $A5                        ; barrier ($E0 barrier), row 5 col 5, 4 high
    DB      $0B, $A6                        ; barrier ($E0 barrier), row 5 col 6, 4 high
    DB      $0B, $A7                        ; barrier ($E0 barrier), row 5 col 7, 4 high
    DB      $0B, $AB                        ; barrier ($E0 barrier), row 5 col 11, 4 high
    DB      $0B, $AC                        ; barrier ($E0 barrier), row 5 col 12, 4 high
    DB      $0B, $AD                        ; barrier ($E0 barrier), row 5 col 13, 4 high
    DB      $0B, $AE                        ; barrier ($E0 barrier), row 5 col 14, 4 high
    DB      $0B, $AF                        ; barrier ($E0 barrier), row 5 col 15, 4 high
    DB      $0B, $B0                        ; barrier ($E0 barrier), row 5 col 16, 4 high
    DB      $0B, $B1                        ; barrier ($E0 barrier), row 5 col 17, 4 high
    DB      $0B, $B2                        ; barrier ($E0 barrier), row 5 col 18, 4 high
    DB      $0B, $B3                        ; barrier ($E0 barrier), row 5 col 19, 4 high
    DB      $0B, $B7                        ; barrier ($E0 barrier), row 5 col 23, 4 high
    DB      $0B, $B8                        ; barrier ($E0 barrier), row 5 col 24, 4 high
    DB      $0B, $B9                        ; barrier ($E0 barrier), row 5 col 25, 4 high
    DB      $0B, $BA                        ; barrier ($E0 barrier), row 5 col 26, 4 high
    DB      $43, $20, $20, $0F              ; block of $08 brick, row 9 col 0, 32 wide x 15 high
    DB      $90                             ; rest of the list only from level 4
    DB      $31, $50                        ; roller (flags $08), x $50 y $39 (thing 0)

ROOM_LIST_88:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $2B, $AC                        ; red door, row 5 col 12 (thing 0)
    DB      $2B, $B4                        ; red door, row 5 col 20 (thing 1)

ROOM_LIST_89:
    DB      $3F, $5B                        ; draw room 91's shapes first, then mirror the screen
    DB      $66, $F5                        ; red key, row 15 col 21 (thing 0)
    DB      $2B, $BB                        ; red door, row 5 col 27 (thing 1)
    DB      $6B, $5B                        ; red door, row 10 col 27 (thing 2)
    DB      $50                             ; rest of the list only from level 3
    DB      $31, $10                        ; roller (flags $08), x $10 y $39 (thing 3)
    DB      $31, $36                        ; roller (flags $08), x $30 y $89 (thing 4)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $A2                        ; climber (flags $48), x $A0 y $5F (thing 5)

ROOM_LIST_90:
    DB      $07, $A9, $07                   ; slope, row 5 col 9: $00 blank 7 wide x 7 high, then 6 steps of $08 brick 1 high, right-aligned
    DB      $04, $B0, $06                   ; slope, row 5 col 16: $00 blank 6 wide x 6 high, then 5 steps of $08 brick 1 high, left-aligned
    DB      $42, $20, $41                   ; block of $08 brick, row 9 col 0, 4 wide x 1 high
    DB      $42, $C0, $71                   ; block of $08 brick, row 14 col 0, 7 wide x 1 high
    DB      $82, $60, $91                   ; block of $08 brick, row 19 col 0, 9 wide x 1 high
    DB      $42, $3B, $51                   ; block of $08 brick, row 9 col 27, 5 wide x 1 high
    DB      $42, $D8, $81                   ; block of $08 brick, row 14 col 24, 8 wide x 1 high
    DB      $82, $76, $A1                   ; block of $08 brick, row 19 col 22, 10 wide x 1 high
    DB      $9E, $80, $09                   ; hazard row, row 20 col 0: the first 9 tiles of the run at +$24
    DB      $9E, $A9, $01                   ; hazard row, row 21 col 9: the first 1 tiles of the run at +$24
    DB      $9E, $CA, $01                   ; hazard row, row 22 col 10: the first 1 tiles of the run at +$24
    DB      $9E, $EB, $01                   ; hazard row, row 23 col 11: the first 1 tiles of the run at +$24
    DB      $9E, $96, $0A                   ; hazard row, row 20 col 22: the first 10 tiles of the run at +$24
    DB      $9E, $B5, $01                   ; hazard row, row 21 col 21: the first 1 tiles of the run at +$24
    DB      $9E, $D4, $01                   ; hazard row, row 22 col 20: the first 1 tiles of the run at +$24
    DB      $9E, $F3, $01                   ; hazard row, row 23 col 19: the first 1 tiles of the run at +$24
    DB      $9F, $A0, $09                   ; hazard row ($38) x 9, row 21 col 0
    DB      $9F, $C0, $0A                   ; hazard row ($38) x 10, row 22 col 0
    DB      $9F, $E0, $0B                   ; hazard row ($38) x 11, row 23 col 0
    DB      $9F, $B6, $0B                   ; hazard row ($38) x 11, row 21 col 22
    DB      $9F, $D5, $0C                   ; hazard row ($38) x 12, row 22 col 21
    DB      $9F, $F4, $0D                   ; hazard row ($38) x 13, row 23 col 20
    DB      $60, $8F                        ; jewel, row 12 col 15 (thing 0)
    DB      $60, $CF                        ; jewel, row 14 col 15 (thing 1)
    DB      $A0, $0F                        ; jewel, row 16 col 15 (thing 2)
    DB      $A0, $4F                        ; jewel, row 18 col 15 (thing 3)
    DB      $A0, $8F                        ; jewel, row 20 col 15 (thing 4)
    DB      $60, $CB                        ; jewel, row 14 col 11 (thing 5)
    DB      $60, $D3                        ; jewel, row 14 col 19 (thing 6)
    DB      $A0, $0C                        ; jewel, row 16 col 12 (thing 7)
    DB      $A0, $12                        ; jewel, row 16 col 18 (thing 8)
    DB      $A0, $4D                        ; jewel, row 18 col 13 (thing 9)
    DB      $A0, $51                        ; jewel, row 18 col 17 (thing 10)

ROOM_LIST_91:
    DB      $66, $E9                        ; red key, row 15 col 9 (thing 0)
    DB      $2B, $A3                        ; red door, row 5 col 3 (thing 1)
    DB      $2A, $B6                        ; blue door, row 5 col 22 (thing 2)
    DB      $29, $BA                        ; gold door, row 5 col 26 (thing 3)
    DB      $6B, $43                        ; red door, row 10 col 3 (thing 4)
    DB      $4B, $F1                        ; barrier ($E0 barrier), row 15 col 17, 4 high
    DB      $42, $E0, $34                   ; block of $08 brick, row 15 col 0, 3 wide x 4 high
    DB      $43, $20, $20, $01              ; block of $08 brick, row 9 col 0, 32 wide x 1 high
    DB      $43, $C0, $20, $01              ; block of $08 brick, row 14 col 0, 32 wide x 1 high
    DB      $83, $60, $20, $01              ; block of $08 brick, row 19 col 0, 32 wide x 1 high
    DB      $83, $E0, $20, $01              ; block of $08 brick, row 23 col 0, 32 wide x 1 high
    DB      $47, $5B, $02                   ; slope, row 10 col 27: $00 blank 2 wide x 2 high, then 1 steps of $08 brick 1 high, right-aligned
    DB      $42, $5D, $34                   ; block of $08 brick, row 10 col 29, 3 wide x 4 high
    DB      $47, $FA, $02                   ; slope, row 15 col 26: $00 blank 2 wide x 2 high, then 1 steps of $08 brick 1 high, right-aligned
    DB      $42, $FC, $44                   ; block of $08 brick, row 15 col 28, 4 wide x 4 high
    DB      $87, $98, $03                   ; slope, row 20 col 24: $00 blank 3 wide x 3 high, then 2 steps of $08 brick 1 high, right-aligned
    DB      $82, $9B, $54                   ; block of $08 brick, row 20 col 27, 5 wide x 4 high
    DB      $9F, $C0, $1B                   ; hazard row ($38) x 27, row 22 col 0
    DB      $9E, $A0, $1A                   ; hazard row, row 21 col 0: the first 26 tiles of the run at +$24
    DB      $58, $26, $05                   ; ladder column ($88 $89), row 9 col 6, 5 high, top row $10 $11
    DB      $58, $D6, $05                   ; ladder column ($88 $89), row 14 col 22, 5 high, top row $10 $11
    DB      $9C, $65, $0C                   ; vanishing floor row ($E8) x 12, row 19 col 5
    DB      $50                             ; rest of the list only from level 3
    DB      $30, $50                        ; climber (flags $48), x $50 y $37 (thing 5)

ROOM_LIST_92:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $27, $F0                        ; creature, row 7 col 16 (thing 0)
    DB      $90                             ; rest of the list only from level 4
    DB      $70, $30                        ; climber (flags $48), x $30 y $37, fast (thing 1)

ROOM_LIST_93:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $27, $EF                        ; creature, row 7 col 15 (thing 0)
    DB      $20, $AE                        ; jewel, row 5 col 14 (thing 1)
    DB      $20, $B0                        ; jewel, row 5 col 16 (thing 2)
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $A0                        ; climber (flags $48), x $A0 y $37 (thing 3)

ROOM_LIST_94:
    DB      $3E, $57                        ; draw room 87's shapes first
    DB      $90                             ; rest of the list only from level 4
    DB      $30, $50                        ; climber (flags $48), x $50 y $37 (thing 0)

ROOM_LIST_95:
    DB      $3E, $0A                        ; draw room 10's shapes first
    DB      $2B, $AB                        ; red door, row 5 col 11 (thing 0)
    DB      $2B, $B3                        ; red door, row 5 col 19 (thing 1)

ROOM_LIST_96:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $31, $40                        ; roller (flags $08), x $40 y $39 (thing 0)

ROOM_LIST_97:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $03, $B3, $0D, $13              ; block of $08 brick, row 5 col 19, 13 wide x 19 high
    DB      $31, $60                        ; roller (flags $08), x $60 y $39 (thing 0)
    DB      $31, $40                        ; roller (flags $08), x $40 y $39 (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $AA                        ; barrier ($E0 barrier), row 5 col 10, 4 high

ROOM_LIST_98:
    DB      $3E, $13                        ; draw room 19's shapes first
    DB      $08, $0F, $09                   ; ladder column ($88 $89), row 0 col 15, 9 high
    DB      $03, $A0, $0D, $13              ; block of $08 brick, row 5 col 0, 13 wide x 19 high
    DB      $30, $80                        ; climber (flags $48), x $80 y $37 (thing 0)
    DB      $30, $A0                        ; climber (flags $48), x $A0 y $37 (thing 1)
    DB      $90                             ; rest of the list only from level 4
    DB      $0B, $B4                        ; barrier ($E0 barrier), row 5 col 20, 4 high

ROOM_LIST_99:
    DB      $3E, $0B                        ; draw room 11's shapes first
    DB      $02, $BF, $14                   ; block of $08 brick, row 5 col 31, 1 wide x 4 high
    DB      $22, $B1                        ; sword, row 5 col 17 (thing 0)
    DB      $22, $B3                        ; sword, row 5 col 19 (thing 1)
    DB      $22, $B5                        ; sword, row 5 col 21 (thing 2)
    DB      $20, $B7                        ; jewel, row 5 col 23 (thing 3)
    DB      $20, $B9                        ; jewel, row 5 col 25 (thing 4)
    DB      $20, $BB                        ; jewel, row 5 col 27 (thing 5)

ROOM_LISTS_END:

; -----------------------------------------------------------------------------
; TILE GROUPS: the tiles room commands draw with, at the offset CMD_GROUPS
; gives. What a command reads at its offset depends on the command (see the
; ROOM DATA notes), so groups overlap. The HUD's inventory icons (item code
; = offset, 2x2 tiles at +1, $A378) and Joe's hazard tiles are in here too.
; -----------------------------------------------------------------------------
TILE_GROUPS:
; +$00 commands $00 $01: blocks (tile at +1)
;      commands $05 $06 $15 $16: slopes (steps +1, square +3)
    DB      $01, $00
; +$02 commands $02 $03: blocks (tile at +1)
;      commands $04 $07 $14 $17: slopes (steps +1, square +3)
    DB      $01, $08, $01, $00
; +$06 command $08: columns (count, tiles)
;      command $18: columns with a top (count, tiles, top tiles)
    DB      $02, $88, $89, $10, $11
; +$0B command $0C: rows (right end, middle, left end)
;      HUD icon: empty slot
    DB      $02, $00, $00, $00, $00
; +$10 command $09: columns (count, tiles)
;      command $19: columns with a top (count, tiles, top tiles)
    DB      $01, $90, $C4
; +$13 command $0A: columns (count, tiles)
    DB      $01, $95
; +$15 command $0B: barrier (count, tile)
    DB      $01, $E0
; +$17 command $0E: rows (right end, middle, left end)
    DB      $01, $06, $05, $04
; +$1B command $0D: rows (right end, middle, left end)
    DB      $01, $BA, $B9, $B8
; +$1F command $1C: rows (count or $FF, tiles)
    DB      $01, $E8
; +$21 command $1D: rows (count or $FF, tiles)
    DB      $02, $08, $08
; +$24 command $1E: rows (count or $FF, tiles)
    DB      $FF, $D2, $D3, $D4, $D5, $D2, $D3, $D4
    DB      $D5, $D2, $D3, $D4, $D5, $D2, $D3, $D4
    DB      $D5, $D2, $D3, $D4, $D5, $D2, $D3, $D4
    DB      $D5
HAZARD_TILES:                               ; tiles that kill Joe (IS_HAZARD)
    DB      $D2, $D3, $D4, $D5, $38
; +$42 command $1F: rows (count or $FF, tiles)
    DB      $01, $38
; +$44 command $20: jewel (2x2 tiles at +1)
;      HUD icon: jewel
    DB      $02, $98, $D8, $99, $D9
; +$49 command $21: amulet (2x2 tiles at +1)
    DB      $02, $A8, $AE, $A9, $AF
; +$4E command $22: sword (2x2 tiles at +1)
    DB      $02, $96, $97, $9A, $9B
; +$53 command $23: torch (2x2 tiles at +1)
;      HUD icon: torch
    DB      $02, $D0, $D1, $62, $63
; +$58 command $24: gold key (2x2 tiles at +1)
;      HUD icon: gold key
    DB      $02, $78, $79, $7A, $7B
; +$5D command $25: blue key (2x2 tiles at +1)
;      HUD icon: blue key
    DB      $02, $68, $69, $6A, $6B
; +$62 command $26: red key (2x2 tiles at +1)
;      HUD icon: red key
    DB      $02, $70, $71, $72, $73
; +$67 command $29: gold door (column +1, bottom +2; open: top +3 +4, then 3 rows of +5 +6)
    DB      $02, $B0, $B7, $B1, $B2, $B3, $B3
; +$6E command $2A: blue door (column +1, bottom +2; open: top +3 +4, then 3 rows of +5 +6)
    DB      $02, $BB, $9C, $BC, $BD, $BE, $BE
; +$75 command $2B: red door (column +1, bottom +2; open: top +3 +4, then 3 rows of +5 +6)
    DB      $02, $C0, $C7, $C1, $C2, $C3, $C3
; +$7C command $27: creature (2x2 tiles at +1)
    DB      $02, $A0, $A1, $A2, $A3
; +$81 command $28: creature (2x2 tiles at +1)
    DB      $02, $A5, $A4, $A7, $A6
; +$86 command $30: enemy (colour, pattern)
    DB      $0C, $2C
; +$88 command $32: enemy (colour, pattern)
    DB      $0F, $0C
; +$8A command $31: enemy (colour, pattern)
    DB      $0F, $0C
; +$8C HUD icon: amulet
    DB      $02, $60, $AE, $61, $AF
; +$91 HUD icon: sword
    DB      $02, $74, $75, $6C, $6D

; =============================================================================
; LOAD_ROOM ($A067): draw the room at row $71A7, column $71A8 and set up its
; items, doors and enemies, by running the room's command list (ROOM DATA
; above).
;
; RAM it uses:
;   $7190/$7191  the next command      $7192/$7193  the end of the list
;   $7194        include depth          $7195        mirror the included room
;   $7196-$7199  the current command    $719A        its tile group offset
;   $719B        the tile a block or slope draws with
;   $719D/$719E  a block's width and height
;   $71A0        the block command's length (3 or 4)
;   $71A1        the room's first byte in the "gone" bitmap at $70C0
;   $71A2        things (items, doors, enemies) so far
;   $71A5        room whose list is running   $71B0/$71B1  name table position
; It clears and refills the enemy objects ($7086), the contact list ($72C0)
; and the enemy sprites from $7308; $707A counts the enemies.
; =============================================================================
LOAD_ROOM:
    CALL    DISPLAY_OFF                     ; display off
    CALL    TURN_OFF_SOUND
    LD      HL, $7086                       ; enemy objects: 7 x 2 bytes, all $FF (free)
    PUSH    HL
    POP     DE
    LD      BC, $000E
    LD      (HL), $FF
    INC     DE
    LDIR
    LD      BC, $001E                       ; contact list: 15 x 2 bytes of 0...
    LD      HL, $72C0
    PUSH    HL
    POP     DE
    LD      (HL), $00
    INC     DE
    LDIR
    LD      A, $FE                          ; ...ended by $FE $FE
    LD      (DE), A
    DEC     DE
    LD      (DE), A
    CALL    CLEAR_ROOM_SCREEN
    CALL    ROOM_NUMBER
    LD      ($7015), A                      ; the room number
    CALL    SET_ROOM_LIST
    XOR     A
    LD      ($71A2), A                      ; no things yet
    LD      A, ($71A5)
    SLA     A
    LD      ($71A1), A                      ; the room's 2 bytes in the bitmap at $70C0

; Run commands until the pointer reaches the end of the list: in effect
; "pointer != end", though it compares a byte at a time.
ROOM_CMD_LOOP:
    LD      A, ($7190)
    LD      HL, $7192
    CP      (HL)
    JR      Z, ROOM_CMD_CHECK_HI
    JR      C, ROOM_CMD

ROOM_CMD_CHECK_HI:
    LD      A, ($7191)
    INC     HL
    CP      (HL)
    JR      NZ, ROOM_CMD

; End of a list: the room's own (finish), or an included room's (go back to
; the including list, mirroring the screen first for $3F).
ROOM_LIST_DONE:
    LD      A, ($7194)
    CP      $00
    JR      Z, ROOM_END
    DEC     A
    LD      ($7194), A
    LD      A, ($7195)
    CP      $00
    JR      Z, ROOM_INCLUDE_RETURN
    CALL    MIRROR_ROOM                     ; mirror the screen (rows 5-22)

ROOM_INCLUDE_RETURN:
    POP     AF                              ; restore $7195 and $7190-$7193,
    LD      ($7195), A                      ; pushed by ROOM_CMD_INCLUDE
    LD      B, $04
    LD      HL, $7193

ROOM_INCLUDE_POP:
    POP     AF
    LD      (HL), A
    DEC     HL
    DJNZ    ROOM_INCLUDE_POP

ROOM_CMD_NEXT2:
    LD      A, $02                          ; skip a 2-byte command

ROOM_CMD_NEXT:
    LD      C, A                            ; skip A bytes, then the next command
    LD      B, $00
    LD      HL, ($7190)
    ADD     HL, BC
    LD      ($7190), HL
    JR      ROOM_CMD_LOOP

; The room is drawn. Draw the inventory, except while Joe descends into the
; pyramid at the start of a level ($705F bit 2) outside column 10.
ROOM_END:
    LD      A, ($705F)
    BIT     2, A
    JR      Z, ROOM_END_HUD
    LD      A, ($71A8)
    CP      $0A
    JR      NZ, ROOM_END_SPRITES

ROOM_END_HUD:
    CALL    DRAW_INVENTORY                  ; draw the inventory

; Clear the sprite table from the first sprite after the room's enemies:
; $80 - 4 x enemies bytes from $1B08 + 4 x enemies (8 bytes past the
; table's end).
ROOM_END_SPRITES:
    LD      A, ($707A)
    SLA     A
    SLA     A
    LD      C, A
    LD      A, $80
    SUB     C
    LD      H, $00
    LD      L, A
    LD      B, $00
    EX      DE, HL
    LD      HL, $1B08
    ADD     HL, BC
    XOR     A
    CALL    FILL_VRAM
    CALL    DISPLAY_ON                      ; display on
    RET

; One command: copy it to $7196-$7199 and look up its tile group.
ROOM_CMD:
    LD      HL, ($7190)
    LD      A, (HL)
    LD      ($7196), A
    AND     $3E
    CP      $3E
    JR      Z, ROOM_CMD_INCLUDE             ; $3E/$3F (whatever bits 6-7)
    LD      BC, $0003
    INC     HL
    LD      DE, $7197
    LDIR
    CALL    CMD_GROUP
    LD      A, ($7196)
    AND     $3F
    LD      B, $02
    CP      $10
    JP      Z, ROOM_CMD_LEVEL2
    CP      $11
    JP      Z, ROOM_CMD_LEVEL6
    CP      $0B
    JP      Z, ROOM_CMD_BARRIER
    CP      $20
    JR      C, ROOM_CMD_SHAPE
    CP      $29
    JR      C, ROOM_CMD_ITEM
    CP      $30
    JR      C, ROOM_CMD_DOOR
    LD      A, ($7194)                      ; $30-$32: an enemy, unless in
    CP      $00                             ; an included room
    JR      NZ, ROOM_CMD_NEXT2
    CALL    PLACE_ENEMY

ROOM_CMD_NEXT2_JP:
    JP      ROOM_CMD_NEXT2

ROOM_CMD_ITEM:
    LD      A, ($7194)                      ; $20-$28: an item or creature,
    CP      $00                             ; unless in an included room
    JR      NZ, ROOM_CMD_NEXT2_JP
    CALL    DRAW_ITEM
    JR      ROOM_CMD_NEXT2_JP

ROOM_CMD_DOOR:
    LD      A, ($7194)                      ; $29-$2F: a door, unless in an
    CP      $00                             ; included room
    JR      NZ, ROOM_CMD_NEXT2_JP
    CALL    DRAW_DOOR
    JR      ROOM_CMD_NEXT2_JP

; $00-$1F: a shape. Bits 2-4 pick the handler, which returns the command's
; length in A.
ROOM_CMD_SHAPE:
    LD      HL, SHAPE_HANDLERS
    LD      A, ($7196)
    SRL     A
    SRL     A
    AND     $07
    SLA     A
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      E, (HL)
    INC     HL
    LD      D, (HL)
    EX      DE, HL
    CALL    CALL_HL                         ; JP (HL)
    JP      ROOM_CMD_NEXT

; $3E/$3F, room: run that room's list first, then carry on with this one.
; Saves the list pointers and the mirror flag on the stack. The room number
; is read at pointer + 1 + the current mirror flag, which is off in every
; room that includes another, so it's the command's second byte.
ROOM_CMD_INCLUDE:
    LD      B, $04
    LD      HL, $7190

ROOM_INCLUDE_PUSH:
    LD      A, (HL)
    INC     HL
    PUSH    AF
    DJNZ    ROOM_INCLUDE_PUSH
    LD      A, ($7195)
    PUSH    AF
    LD      HL, ($7190)
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    INC     HL
    LD      A, (HL)                         ; the room to include
    PUSH    AF
    LD      A, ($7196)
    AND     $01
    LD      ($7195), A                      ; $3F: mirror it
    LD      HL, $7194
    INC     (HL)
    POP     AF
    CALL    SET_ROOM_LIST
    JP      ROOM_CMD_LOOP

; $10/$11: below level (bits 6-7) + 2 (or + 6 for $11), end the list; else
; skip this 1-byte command. Things after it get the next "gone" bits only
; on the levels that reach them.
ROOM_CMD_LEVEL6:
    LD      B, $06

ROOM_CMD_LEVEL2:
    LD      A, ($7196)
    AND     $C0
    SRL     A
    SRL     A
    SRL     A
    SRL     A
    SRL     A
    SRL     A
    ADD     A, B
    LD      B, A
    LD      A, ($71A6)                      ; the level, from 1
    CP      B
    JR      C, ROOM_LEVEL_STOP
    LD      A, $01
    JP      ROOM_CMD_NEXT

ROOM_LEVEL_STOP:
    JP      ROOM_LIST_DONE

; Blank rows 5-23 of the name table, then, unless Joe is descending into
; the pyramid outside column 10, fill rows 0-4 with brick and draw the HUD's
; frames.
CLEAR_ROOM_SCREEN:
    LD      B, $03                          ; unused
    LD      DE, $0003                       ; unused
    LD      HL, $18A0
    LD      DE, $0260
    XOR     A
    CALL    FILL_VRAM
    LD      A, ($705F)
    BIT     2, A
    JR      Z, CLEAR_ROOM_TOP
    LD      A, ($71A8)
    CP      $0A
    RET     NZ

CLEAR_ROOM_TOP:
    LD      HL, $1800
    LD      DE, $00A0
    LD      A, $08
    CALL    FILL_VRAM
    CALL    DRAW_HUD_BOXES                  ; the HUD's frames
    RET

; Shape handlers, by bits 2-4 of the command.
SHAPE_HANDLERS:
    DW      DRAW_BLOCK                      ; $00-$03
    DW      DRAW_SLOPE                      ; $04-$07
    DW      DRAW_COLUMN                     ; $08-$0B ($0B: ROOM_CMD_BARRIER)
    DW      DRAW_ENDS_ROW                   ; $0C-$0F
    DW      DRAW_BLOCK                      ; $10-$13 ($10/$11: level checks)
    DW      DRAW_SLOPE                      ; $14-$17
    DW      DRAW_COLUMN_TOP                 ; $18-$1B
    DW      DRAW_ROW                        ; $1C-$1F

; Block: the group's tile, D wide and E high. Even commands give the size
; in one byte (hi nibble wide, lo nibble high), odd ones in two.
DRAW_BLOCK:
    CALL    CMD_POSITION
    LD      A, ($719A)
    LD      HL, $9FD2
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    LD      ($719B), A
    LD      A, ($7196)
    AND     $01
    CP      $00
    JR      Z, DRAW_BLOCK_NIBBLES
    LD      HL, $7198
    LD      D, (HL)
    INC     HL
    LD      E, (HL)
    LD      A, $04
    LD      ($71A0), A
    JR      FILL_BLOCK

DRAW_BLOCK_NIBBLES:
    LD      A, ($7198)
    LD      E, A
    SRL     A
    SRL     A
    SRL     A
    SRL     A
    LD      D, A
    LD      A, E
    AND     $0F
    LD      E, A
    LD      A, $03
    LD      ($71A0), A

; Fill D x E tiles of $719B from $71B0, leaving $71B0 on the row below.
; Returns $71A0.
FILL_BLOCK:
    LD      HL, $719D
    LD      (HL), D
    INC     HL
    LD      (HL), E
    LD      A, ($719E)
    LD      B, A

FILL_BLOCK_ROW:
    PUSH    BC
    LD      A, ($719D)
    LD      B, A
    LD      C, $01
    LD      DE, ($71B0)
    LD      HL, $719B
    CALL    TILE_ROWS                       ; a row of D tiles
    CALL    NEXT_ROW
    POP     BC
    LD      A, ($71A0)
    DJNZ    FILL_BLOCK_ROW
    RET

; Slope, n = the third byte: a block of the tile at group + 3, n wide and n
; high (2n with bit 4), then, from the same corner, steps of the tile at
; group + 1, n-1 wide down to 1, each 1 row high (2 with bit 4). With bit
; 0 each step starts a column further right, so they line up on the right.
DRAW_SLOPE:
    CALL    CMD_POSITION
    LD      A, ($719A)
    LD      HL, $9FD4
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    LD      ($719B), A
    LD      A, ($7198)
    LD      D, A
    LD      E, A
    LD      A, ($7196)
    AND     $10
    CP      $00
    JR      Z, DRAW_SLOPE_SQUARE
    SLA     E

DRAW_SLOPE_SQUARE:
    CALL    FILL_BLOCK
    CALL    CMD_POSITION                    ; back to the top
    LD      A, ($719A)
    LD      HL, $9FD2
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    LD      ($719B), A
    CALL    SLOPE_SHIFT

DRAW_SLOPE_STEP:
    LD      HL, $7198
    DEC     (HL)
    JR      Z, DRAW_SLOPE_DONE
    LD      D, (HL)
    LD      A, ($7196)
    AND     $10
    SRL     A
    SRL     A
    SRL     A
    SRL     A
    INC     A
    LD      E, A
    CALL    FILL_BLOCK
    CALL    SLOPE_SHIFT
    JR      DRAW_SLOPE_STEP

DRAW_SLOPE_DONE:
    LD      A, $03
    RET

SLOPE_SHIFT:
    LD      A, ($7196)
    AND     $01
    RET     Z
    LD      HL, ($71B0)
    INC     HL
    LD      ($71B0), HL
    RET

; $0B: a barrier, the group's tile in a column 4 high. A 2-byte command.
ROOM_CMD_BARRIER:
    LD      A, $04
    LD      ($7198), A
    CALL    DRAW_COLUMN
    LD      A, $02
    JP      ROOM_CMD_NEXT

; Column: the group's count tiles side by side, repeated down $7198 rows.
; Leaves HL on the tiles and C = the count.
DRAW_COLUMN:
    CALL    CMD_POSITION
    LD      A, ($719A)
    LD      HL, $9FD1
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    LD      C, A
    INC     HL
    LD      A, ($7198)
    LD      B, A

PUT_DOWN_AT_CMD:
    LD      DE, ($71B0)

; Write C tiles from HL at DE, B times down the screen. Returns A = 3.
PUT_DOWN:
    CALL    TILE_COLUMNS
    LD      A, $03
    RET

; Column with a top: the group's next count tiles over its first row.
DRAW_COLUMN_TOP:
    CALL    DRAW_COLUMN
    LD      B, $00
    ADD     HL, BC
    LD      B, $01
    JR      PUT_DOWN

; Row with ends, n wide: n of group + 1, then n-1 of group + 2 and one of
; group + 3 over its start, so + 3 is the left end and + 1 the right.
DRAW_ENDS_ROW:
    CALL    CMD_POSITION
    LD      A, ($719A)
    LD      HL, $9FD2
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      DE, ($71B0)
    LD      C, $01
    LD      A, ($7198)
    LD      B, A
    CALL    TILE_ROWS
    INC     HL
    DEC     B
    CALL    TILE_ROWS
    INC     HL
    LD      B, $01
    CALL    TILE_ROWS
    LD      A, $03
    RET

; Row: the group's count tiles, n times; or, for a count of $FF, the first
; n tiles after it.
DRAW_ROW:
    CALL    CMD_POSITION
    LD      A, ($719A)
    LD      HL, $9FD1
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    CP      $FF
    JR      NZ, DRAW_ROW_REPEAT
    LD      A, ($7198)
    LD      C, A
    LD      B, $01
    JR      DRAW_ROW_PUT

DRAW_ROW_REPEAT:
    LD      C, A
    LD      A, ($7198)
    LD      B, A

DRAW_ROW_PUT:
    INC     HL
    LD      DE, ($71B0)
    CALL    TILE_ROWS
    LD      A, $03
    RET

; $20-$28: an item or creature, the group's 2x2 tiles, unless gone. Its
; position goes in the contact list.
DRAW_ITEM:
    CALL    NEXT_THING_GONE
    JR      C, THING_DONE
    CALL    CMD_POSITION
    CALL    SAVE_CONTACT
    LD      A, ($719A)

; Draw the 2x2 tiles at $9FD2 + A at DE (also the HUD's inventory icons).
DRAW_ICON:
    LD      HL, $9FD2
    CALL    TABLE_BYTE                      ; HL = $9FD2 + A
    LD      BC, $0102
    CALL    TILE_ROWS
    INC     HL
    INC     HL
    PUSH    BC
    LD      BC, $0020
    EX      DE, HL
    ADD     HL, BC
    EX      DE, HL
    POP     BC
    CALL    TILE_ROWS

THING_DONE:
    LD      A, $02
    RET

; HL = the contact list entry for the thing just counted ($72C0 + 2 x
; things).
CONTACT_ENTRY:
    LD      A, ($71A2)
    SLA     A
    LD      HL, $72C0
    CALL    TABLE_BYTE
    RET

SAVE_CONTACT:
    CALL    CONTACT_ENTRY
    LD      DE, ($71B0)
    LD      (HL), E
    INC     HL
    LD      (HL), D
    RET

; $29-$2F: a door: 3 of the group's first tile down, its second below.
; Once opened (gone), the open door instead: 2 tiles, then 3 rows of 2.
DRAW_DOOR:
    CALL    NEXT_THING_GONE
    JR      C, DRAW_OPEN_DOOR
    CALL    CMD_POSITION
    CALL    SAVE_CONTACT
    LD      A, ($719A)
    LD      HL, $9FD2
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      BC, $0301
    CALL    PUT_DOWN_AT_CMD
    INC     HL
    LD      BC, $0060
    EX      DE, HL
    ADD     HL, BC
    EX      DE, HL
    LD      BC, $0101
    CALL    TILE_ROWS
    JR      THING_DONE_JP

; Write the 2 tiles at $9FD2 + A at $71B0.
PUT_PAIR:
    LD      HL, $9FD2
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      BC, $0102
    LD      DE, ($71B0)
    CALL    TILE_ROWS

THING_DONE_JP:
    JP      THING_DONE

DRAW_OPEN_DOOR:
    CALL    CMD_POSITION
    LD      A, ($719A)
    ADD     A, $02

; An open door from its drawing at $9FD2 + A, at $71B0 (also ITEM_TASK's).
DRAW_OPEN_DOOR_AT:
    CALL    PUT_PAIR
    INC     HL
    INC     HL
    PUSH    BC
    LD      BC, $0020
    EX      DE, HL
    ADD     HL, BC
    EX      DE, HL
    POP     BC
    LD      B, $03
    CALL    PUT_DOWN
    JR      THING_DONE_JP

; $30-$32: an enemy, unless gone (killed). The second byte is its start:
; lo nibble ENEMY_Y, hi nibble ENEMY_X. Its sprite (from $7308) gets the
; group's pattern and colour, its object at $7086 the kind's flags plus
; its sprite number, and $80 in the second byte (fast) with bit 6. Its
; contact list entry is its sprite table offset and $FF.
PLACE_ENEMY:
    CALL    NEXT_THING_GONE
    JR      C, THING_DONE_JP
    LD      HL, $707A                       ; one more enemy
    INC     (HL)
    LD      A, (HL)
    SLA     A
    SLA     A
    LD      B, $00
    LD      C, A
    CALL    CONTACT_ENTRY
    LD      (HL), C
    INC     HL
    LD      (HL), $FF
    LD      HL, $7304                       ; its sprite: $7304 + 4 x enemies
    ADD     HL, BC
    PUSH    HL
    LD      A, ($7197)
    AND     $0F
    LD      HL, ENEMY_Y
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    POP     HL
    LD      (HL), A                         ; Y
    INC     HL
    PUSH    HL
    LD      A, ($7197)
    SRL     A
    SRL     A
    SRL     A
    SRL     A
    AND     $0F
    LD      HL, ENEMY_X
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    POP     HL
    LD      (HL), A                         ; X
    INC     HL
    PUSH    HL
    LD      A, ($719A)
    LD      E, $48                          ; $30 (group $86): climber, 2 lines higher
    CP      $86
    JR      NZ, PLACE_ENEMY_KIND
    DEC     HL
    DEC     HL
    DEC     (HL)
    DEC     (HL)
    INC     HL
    INC     HL
    JR      PLACE_ENEMY_OBJECT

PLACE_ENEMY_KIND:
    LD      E, $10                          ; $32 (group $88): bouncer
    CP      $88
    JR      Z, PLACE_ENEMY_OBJECT
    LD      E, $08                          ; $31: roller

PLACE_ENEMY_OBJECT:
    LD      HL, $7086

FIND_FREE_OBJECT:
    LD      A, (HL)
    CP      $FF
    JR      Z, PLACE_ENEMY_STORE
    INC     HL
    INC     HL
    JR      FIND_FREE_OBJECT

PLACE_ENEMY_STORE:
    LD      A, ($707A)
    INC     A                               ; sprite number: enemies + 1
    ADD     A, E
    LD      (HL), A
    INC     HL
    LD      A, ($7196)
    BIT     6, A
    LD      A, $00
    JR      Z, PLACE_ENEMY_SPRITE
    LD      A, $80

PLACE_ENEMY_SPRITE:
    LD      (HL), A
    LD      A, ($719A)
    LD      B, $00
    LD      HL, $9FD1
    LD      C, A
    ADD     HL, BC
    LD      D, (HL)                         ; colour
    INC     HL
    LD      A, (HL)                         ; pattern
    POP     HL
    LD      (HL), A
    INC     HL
    LD      (HL), D
    RET

ENEMY_Y:                                    ; sprite Y by the start's lo nibble (0-10)
    DB      $39, $59, $61, $69, $71, $81, $89, $91
    DB      $A1, $A9, $B1, $00, $00, $00, $00
ENEMY_X:                                    ; sprite X by the hi nibble; 14 gives $D0, not $E0
    DB      $00, $10, $20, $30, $40, $50, $60, $70
    DB      $80, $90, $A0, $B0, $C0, $D0, $D0, $F0

; A = the room number at row $71A7, column $71A8.
ROOM_NUMBER:
    LD      A, ($71A7)
    LD      HL, ROW_FIRST_ROOM
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      C, (HL)
    LD      A, ($71A8)
    ADD     A, C
    RET

ROW_FIRST_ROOM:                             ; room number - column, by row
    DB      $F8, $FC, $02, $0A, $14, $20, $2E, $3E
    DB      $50

; Point $7190-$7193 at room A's list, and its end ($71A5 = A).
SET_ROOM_LIST:
    LD      ($71A5), A
    SLA     A
    LD      HL, ROOM_LISTS
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      BC, $0004
    LD      DE, $7190
    LDIR
    RET

; $71B0/$71B1 = the command's name table position: bits 6-7 of its first
; byte, then its second byte.
CMD_POSITION:
    LD      A, ($7196)
    RL      A
    RL      A
    RL      A
    AND     $03
    LD      HL, $71B1
    LD      (HL), A
    DEC     HL
    LD      A, ($7197)
    LD      (HL), A
    RET

; $719A = the command's tile group offset (CMD_GROUPS).
CMD_GROUP:
    LD      A, ($7196)
    AND     $3F
    LD      HL, CMD_GROUPS
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    LD      ($719A), A
    RET

; $71B0 += one row.
NEXT_ROW:
    LD      BC, $0020
    LD      HL, ($71B0)
    ADD     HL, BC
    LD      ($71B0), HL
    RET

; Count the next thing (n = $71A2, then $71A2 + 1); carry if it's gone:
; bit n mod 8 of $70C0 + $71A1 + n / 8.
NEXT_THING_GONE:
    LD      A, ($71A1)
    LD      C, A
    LD      A, ($71A2)
    LD      D, $01
    SCF
    CCF

NEXT_THING_BIT:
    DEC     A
    JP      M, NEXT_THING_TEST
    RL      D
    JR      NC, NEXT_THING_BIT
    INC     C                               ; past bit 7: next byte, bit 0
    RL      D
    JR      NC, NEXT_THING_BIT

NEXT_THING_TEST:
    LD      HL, $71A2
    INC     (HL)
    SCF
    LD      HL, $70C0
    LD      B, $00
    ADD     HL, BC
    LD      A, D
    AND     (HL)
    JR      NZ, NEXT_THING_IS_GONE
    SCF
    CCF
    RET

NEXT_THING_IS_GONE:
    SCF
    RET

; A = (HL + A), and HL = HL + A.
TABLE_BYTE:
    PUSH    BC
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    POP     BC
    RET

; DRAW_INVENTORY ($A548): redraw the HUD: the score and level, the
; inventory's 10 x 3 background (zeros at $85D7) at row 1 column 1, the icon
; of each item in $71B2 (up to $FF) 2 columns apart (DRAW_ICON), then the
; spare lives.
DRAW_INVENTORY:
    CALL    DRAW_SCORE                      ; score and level
    LD      DE, $0021
    LD      HL, $85D7
    LD      BC, $030A
    CALL    PUT_DOWN
    LD      HL, $71B2                       ; the inventory

DRAW_INVENTORY_ITEM:
    LD      A, (HL)
    CP      $FF
    JP      Z, DRAW_LIVES                   ; then the lives
    PUSH    HL
    PUSH    DE
    CALL    DRAW_ICON                       ; the item's 2x2 icon
    POP     DE
    INC     DE
    INC     DE
    POP     HL
    INC     HL
    JR      DRAW_INVENTORY_ITEM

; ADD_ITEM ($A56C): put item C in the inventory and score its points
; ($70BD). Carry set, and nothing done, if the first free slot is the last
; one: Joe carries at most 5 items. The jewel isn't kept: it scores 1000.
ADD_ITEM:
    LD      HL, $71B1

ADD_ITEM_FREE:
    INC     HL
    LD      A, (HL)
    CP      $FF
    JR      NZ, ADD_ITEM_FREE
    LD      A, L                            ; the sixth slot?
    CP      $B7
    SCF
    RET     Z
    LD      A, C                            ; the jewel
    CP      $44
    JR      NZ, ADD_ITEM_KEEP
    LD      HL, $1000
    LD      ($70BD), HL
    JR      ADD_ITEM_SCORE

; ADD_POINTS ($A587): add HL (BCD) to the score and redraw it.
ADD_POINTS:
    CALL    ADD_SCORE
    CALL    DRAW_SCORE
    RET

ADD_ITEM_KEEP:
    LD      (HL), C

ADD_ITEM_SCORE:
    CALL    DRAW_INVENTORY                  ; redraw the HUD
    PUSH    HL
    LD      HL, ($70BD)
    CALL    ADD_POINTS
    POP     HL
    SCF
    CCF
    RET

; =============================================================================
; NEW_GAME ($A59D): 6 lives (Joe's own included), an empty inventory, and
; Joe in the entrance hall (row 0, column 8) at the top of the left pole,
; where the boot left his sprites, about to walk into the pyramid.
; =============================================================================
NEW_GAME:
    LD      A, $06
    LD      ($7049), A
    LD      HL, $705F                       ; walk him into the pyramid
    SET     2, (HL)
    CALL    EMPTY_INVENTORY
    LD      A, $FF                          ; no death timer running
    LD      ($70A9), A
    LD      A, $01                          ; the first footstep at once
    LD      ($70AD), A
    LD      HL, $0001                       ; sprite order: his hat, face and legs in front of his
    LD      ($72E0), HL                     ; body
    LD      A, $08                          ; column 8
    LD      ($71A8), A
    CALL    LOAD_ROOM
    CALL    SAVE_JOE                        ; he respawns from here
    LD      A, $05                          ; state 5: on a pole
    LD      ($7079), A

; =============================================================================
; MAIN_LOOP ($A5CA): once a frame (when the frame interrupt has counted the
; sync byte $7207 below 0), run the tasks in the table at $A8A1. Each task
; has a countdown: it runs when the count is 1, and the count goes back to
; the task's period at 0. A count of $FE stops the task. While a treasure
; screen is set up ($705F bit 3) the loop waits.
; =============================================================================
MAIN_LOOP:
    LD      A, ($7207)
    BIT     7, A
    JR      Z, MAIN_LOOP
    XOR     A
    LD      ($7207), A                      ; next frame
    LD      HL, TASKS                       ; the task table

MAIN_LOOP_TASK:
    LD      E, (HL)                         ; its countdown's address
    LD      A, ($705F)                      ; (wait while a treasure screen is set up)
    BIT     3, A
    JR      NZ, MAIN_LOOP_TASK
    INC     HL
    LD      D, (HL)
    LD      A, D
    CP      $FF                             ; end of the table
    JR      Z, MAIN_LOOP
    INC     HL
    LD      C, (HL)                         ; its routine
    INC     HL
    LD      B, (HL)
    PUSH    HL
    PUSH    BC
    POP     HL
    LD      A, (DE)                         ; the count
    CP      $FE
    JR      Z, MAIN_LOOP_NEXT
    CP      $01
    JR      NZ, MAIN_LOOP_COUNT
    PUSH    DE
    PUSH    HL
    CALL    CALL_HL                         ; run it: CALL (HL)
    POP     HL
    POP     DE

MAIN_LOOP_COUNT:
    LD      A, (DE)
    DEC     A

MAIN_LOOP_NEXT:
    POP     HL
    INC     HL
    CP      $00
    JR      NZ, MAIN_LOOP_STORE
    LD      A, (HL)                         ; back to the period

MAIN_LOOP_STORE:
    LD      (DE), A
    INC     HL
    JR      MAIN_LOOP_TASK

; =============================================================================
; TREASURE_SCREEN ($A60B): the frame interrupt sets up a screen of the
; treasure room ($705F bit 3). Display off, a blue backdrop, an empty screen.
; While the room's time runs, 25 chains and a diagonal line of jewels,
; placed by reading the ROM at the pointer $7047 (which the frame interrupt
; moves every frame) for random numbers. Columns 9 and 11 get a wall and a
; pole down one side. Then the score, and the display back on.
; =============================================================================
TREASURE_SCREEN:
    LD      HL, $705F
    RES     3, (HL)
    LD      BC, $0182                       ; display off
    CALL    WRITE_REGISTER
    LD      BC, $0705                       ; register 7 = $05: dark blue backdrop
    CALL    WRITE_REGISTER
    XOR     A                               ; clear the screen
    LD      DE, $0300
    LD      HL, $1800
    CALL    FILL_VRAM
    LD      A, ($70AC)                      ; time up: no chains or jewels
    CP      $01
    JR      Z, TREASURE_SIDE
    LD      HL, ($7047)                     ; the pointer, kept within $8000-$AFFF
    LD      B, $19
    LD      A, H
    AND     $AE
    SET     7, A
    LD      H, A

TREASURE_CHAIN:
    PUSH    BC
    LD      A, (HL)                         ; a chain 2, 3, 6 or 7 tiles long, at name
    AND     $07
    SET     1, A
    LD      B, A
    LD      C, $01
    INC     HL
    LD      D, $01                          ; position $100 (row 8) + the third byte
    INC     HL
    LD      E, (HL)
    INC     HL
    PUSH    HL
    PUSH    BC
    POP     BC
    LD      HL, TREASURE_TILES              ; the chain tile, rows 32 apart
    CALL    TILE_COLUMNS
    POP     HL
    POP     BC
    DJNZ    TREASURE_CHAIN
    LD      A, ($71A6)                      ; jewels: 8 + level / 2 of them
    SRA     A
    ADD     A, $08
    LD      B, A
    LD      A, ($7047)                      ; from row 8, a random column
    AND     $1F
    LD      D, $01
    LD      E, A

TREASURE_JEWEL:
    PUSH    BC
    LD      ($71B0), DE
    LD      A, $44                          ; the jewel's icon
    PUSH    DE
    CALL    DRAW_ICON
    POP     HL
    LD      BC, $0027                       ; down a row, 7 columns right
    ADD     HL, BC
    EX      DE, HL
    POP     BC
    DJNZ    TREASURE_JEWEL

TREASURE_SIDE:
    LD      A, ($71A8)                      ; column 10, the shaft: no wall
    CP      $0A
    JR      Z, TREASURE_DONE
    LD      DE, $0000                       ; column 9: brick, gap, pole on the left
    LD      HL, TREASURE_LEFT_WALL
    CP      $0B                             ; column 11: pole, gap, brick on the right
    JR      NZ, TREASURE_WALL
    LD      HL, TREASURE_RIGHT_WALL
    LD      DE, $001D

TREASURE_WALL:
    LD      BC, $1803                       ; 24 rows of 3
    CALL    TILE_COLUMNS

TREASURE_DONE:
    CALL    DRAW_SCORE
    LD      BC, $01E2                       ; display on
    CALL    WRITE_REGISTER
    RET

; CLIMBER_TICK ($A69F): count the frame counter on (it's shared with the
; frame interrupt); carry set when ($7097 AND $11) is 0. The climbers use it
; as a coin toss.
CLIMBER_TICK:
    PUSH    HL
    LD      HL, $7097
    INC     (HL)
    POP     HL
    LD      A, ($7097)
    AND     $11
    CP      $00
    JR      NZ, CLIMBER_TICK_NO
    SCF
    RET

CLIMBER_TICK_NO:
    SCF
    CCF
    RET

; MOVE_CLIMBER ($A6B3): an enemy that walks and climbs ladders (flag $40;
; the spider). Its counter's low 7 bits animate it every 6th frame
; (pattern XOR $1C: the mirror image), green, or grey while the amulet
; protects Joe. On the stack: the object, then its sprite entry. Flags:
; $20 on a ladder, $80 moving left (on a ladder: down).
MOVE_CLIMBER:
    POP     DE
    PUSH    DE
    INC     DE                              ; the counter: 5, 4, ... 0, keeping the fast bit
    LD      A, (DE)
    AND     $80
    LD      B, A
    LD      A, (DE)
    AND     $7F
    DEC     A
    JP      P, LOC_A6C3
    LD      A, $05

LOC_A6C3:
    ADD     A, B
    LD      (DE), A
    AND     $7F
    CP      $00
    JR      NZ, CLIMBER_LADDER_TOP
    POP     DE                              ; animation step: the colour, if it's shown,
    POP     HL
    PUSH    HL
    PUSH    DE
    INC     HL
    INC     HL
    INC     HL
    LD      A, (HL)
    CP      $00
    JR      Z, CLIMBER_FRAME
    LD      A, ($704A)                      ; green or grey
    CP      $00
    LD      A, $0C
    JR      Z, CLIMBER_COLOUR
    LD      A, $0E

CLIMBER_COLOUR:
    LD      (HL), A

CLIMBER_FRAME:
    DEC     HL                              ; and the other frame
    LD      A, (HL)
    XOR     $1C
    LD      (HL), A

CLIMBER_LADDER_TOP:
    LD      HL, $705A                       ; the top of a ladder at its feet?
    LD      A, (HL)
    INC     HL
    CP      $10
    JR      NZ, CLIMBER_LADDER_UP
    LD      A, (HL)
    CP      $11
    JR      NZ, CLIMBER_LADDER_UP
    POP     HL                              ; on the ladder already?
    LD      A, (HL)
    BIT     5, A
    JR      NZ, CLIMBER_AT_TOP
    CALL    CLIMBER_TICK                    ; no: unless CLIMBER_TICK carries, and only when
    PUSH    HL
    JR      C, CLIMBER_LADDER_UP
    LD      A, ($70AB)                      ; $70AB is 2, step down onto it
    CP      $02
    JR      NZ, CLIMBER_LADDER_UP
    POP     HL
    CALL    ALIGN_ENEMY                     ; snap onto the ladder
    EX      (SP), HL
    LD      A, (HL)                         ; 2 lines down
    ADD     A, $02
    LD      (HL), A
    POP     HL
    SET     5, (HL)                         ; on the ladder, going down
    SET     7, (HL)
    JP      ENEMY_NEXT

CLIMBER_AT_TOP:
    BIT     7, A                            ; climbing up: off the ladder at the top, sideways:
    JR      NZ, CLIMBER_DOWN
    RES     5, (HL)                         ; 8 pixels right, or 2 left (turning round)
    CALL    CLIMBER_TICK
    LD      A, $08
    JR      C, CLIMBER_SHIFT
    LD      A, (HL)
    XOR     $80
    LD      (HL), A
    LD      A, $FE

CLIMBER_SHIFT:
    EX      (SP), HL                        ; X + A, Y - 7
    INC     HL
    ADD     A, (HL)
    LD      (HL), A
    DEC     HL
    LD      A, (HL)
    ADD     A, $F9
    LD      (HL), A
    POP     HL
    JP      ENEMY_NEXT

; Climbing down: off the ladder at the floor (a brick or a
; disappearing floor), going right or left; else 1 line down.
CLIMBER_DOWN:
    LD      C, $FF                          ; Y + 1
    LD      A, ($705B)
    CP      $E8
    JR      Z, LOC_A747
    CP      $08
    JR      NZ, CLIMBER_MOVE_Y

LOC_A747:
    CALL    CLIMBER_TICK                    ; off at the bottom: CLIMBER_TICK picks the way,
    JR      C, CLIMBER_OFF_RIGHT
    SET     7, (HL)                         ; left (2 pixels),
    LD      B, $FE
    JR      CLIMBER_OFF

CLIMBER_OFF_RIGHT:
    RES     7, (HL)                         ; or right (8 pixels)
    LD      B, $08

CLIMBER_OFF:
    LD      C, $00
    RES     5, (HL)
    JR      CLIMBER_MOVE

CLIMBER_MOVE_Y:
    LD      B, $00

CLIMBER_MOVE:
    EX      (SP), HL
    JP      ENEMY_SHIFT

CLIMBER_LADDER_UP:
    LD      HL, $7057                       ; a ladder going up from its body?
    LD      A, (HL)
    INC     HL
    CP      $88
    JR      NZ, CLIMBER_WALK
    LD      A, (HL)
    CP      $89
    JR      NZ, CLIMBER_WALK
    LD      A, ($70AB)                      ; and $70AB is 2
    CP      $02
    JR      NZ, CLIMBER_WALK
    POP     HL
    BIT     5, (HL)                         ; not on it yet: take it unless CLIMBER_TICK carries
    JR      NZ, CLIMBER_ON_LADDER
    CALL    CLIMBER_TICK
    PUSH    HL
    JR      C, CLIMBER_WALK
    POP     HL
    CALL    ALIGN_ENEMY                     ; snap onto it, going up
    RES     7, (HL)
    SET     5, (HL)
    LD      A, $00                          ; Y - 7
    JR      CLIMBER_SHIFT

CLIMBER_ON_LADDER:
    BIT     7, (HL)                         ; on a ladder: down, or 1 line up
    JR      NZ, CLIMBER_DOWN
    LD      C, $01
    JR      CLIMBER_MOVE_Y

CLIMBER_WALK:
    POP     HL                              ; not at a ladder: carry on climbing, or walk
    LD      BC, $0000
    BIT     5, (HL)
    JR      NZ, CLIMBER_ON_LADDER
    JP      ENEMY_EDGE

; =============================================================================
; MOVE_ENEMIES ($A7A1): move every enemy one frame. An object at $7086 is 2
; bytes, up to $FF: flags with its sprite slot in bits 0-2, and a counter
; (bit 7: fast). Flags: $08 rolls (the skulls' frames; climbers have it too,
; which keeps them off the bounce arc), $10 bounces between the screen's
; sides, $40 climbs ladders ($20: on one), $80 moving left. Each reads the
; tiles around its feet like Joe (READ_TILES), turns near the top and
; bottom of the screen, at a wall or the end of its floor (or, bouncing, at
; the sides), and turns again within 8 pixels of the left edge.
; =============================================================================
MOVE_ENEMIES:
    LD      HL, $7086

MOVE_ENEMIES_NEXT:
    LD      A, (HL)
    CP      $FF
    RET     Z
    PUSH    HL
    AND     $07                             ; its sprite entry
    SLA     A
    SLA     A
    LD      HL, $7300
    CALL    TABLE_BYTE
    PUSH    HL
    CALL    READ_TILES                      ; the tiles around its feet
    POP     HL
    LD      A, (HL)
    EX      (SP), HL
    CP      $15                             ; Y outside $15-$B7: turn round
    JR      C, ENEMY_TURN_Y
    CP      $B8
    JR      C, ENEMY_KIND

ENEMY_TURN_Y:
    LD      A, (HL)
    XOR     $80
    LD      (HL), A

ENEMY_KIND:
    LD      A, (HL)
    BIT     6, A                            ; a climber
    PUSH    HL
    JP      NZ, MOVE_CLIMBER
    POP     HL
    POP     DE
    PUSH    DE
    PUSH    AF
    INC     DE                              ; white, or grey while the amulet protects Joe,
    INC     DE
    INC     DE
    EX      DE, HL
    LD      A, (HL)                         ; if it's shown
    CP      $00
    JR      Z, ENEMY_ROLL
    LD      A, ($704A)
    CP      $00
    LD      A, $0F
    JR      Z, ENEMY_COLOUR
    LD      A, $0E

ENEMY_COLOUR:
    LD      (HL), A

ENEMY_ROLL:
    EX      DE, HL
    POP     AF
    BIT     3, A                            ; rolling: every 4th frame the next pattern
    JR      Z, ENEMY_WALK
    INC     HL
    LD      A, (HL)
    INC     A
    LD      (HL), A
    DEC     HL
    AND     $0F
    CP      $04
    JR      NZ, ENEMY_WALK
    INC     HL                              ; the counter back to 0, keeping the fast bit
    LD      A, (HL)
    AND     $80
    LD      (HL), A
    DEC     HL
    LD      A, (HL)                         ; a frame back (-4) going right, on (+4) going left
    BIT     7, A
    LD      C, $FC
    JR      Z, ENEMY_ROLL_STEP
    LD      C, $04

ENEMY_ROLL_STEP:
    EX      (SP), HL
    PUSH    HL
    INC     HL
    INC     HL
    LD      A, (HL)
    ADD     A, C
    CP      $2C                             ; $0C-$28, round and round
    JR      NZ, ENEMY_ROLL_WRAP
    LD      A, $0C

ENEMY_ROLL_WRAP:
    CP      $08
    JR      NZ, ENEMY_ROLL_SET
    LD      A, $28

ENEMY_ROLL_SET:
    LD      (HL), A
    POP     HL
    EX      (SP), HL

ENEMY_WALK:
    LD      A, (HL)                         ; bouncing between the sides: turn at X < 8 or
    BIT     4, A
    JR      Z, ENEMY_EDGE
    LD      A, ($7085)                      ; X >= $F5
    CP      $08
    JR      C, ENEMY_TURN
    CP      $F5
    JR      NC, ENEMY_TURN
    JR      ENEMY_STEP

ENEMY_EDGE:
    LD      A, ($705B)                      ; nothing under its feet, or a wall ahead: turn
    CP      $00
    JR      Z, ENEMY_TURN
    LD      A, (HL)
    BIT     7, A
    LD      A, ($7057)
    JR      NZ, ENEMY_WALL
    LD      A, ($7059)

ENEMY_WALL:
    CALL    IS_WALL
    JR      NZ, ENEMY_STEP

ENEMY_TURN:
    LD      A, (HL)
    XOR     $80
    LD      (HL), A

ENEMY_STEP:
    LD      A, (HL)                         ; not rolling: it bounces, DY from the arc at $ABB3
    BIT     3, A
    LD      C, $00
    JR      NZ, ENEMY_DX
    PUSH    HL                              ; (read backwards; the counter loses its fast bit)
    INC     HL
    LD      A, (HL)
    AND     $80
    LD      B, A
    LD      A, (HL)
    AND     $7F
    DEC     A
    JP      P, ENEMY_ARC
    LD      A, $39

ENEMY_ARC:
    LD      (HL), A
    LD      HL, BOUNCE_ARC
    CALL    TABLE_BYTE
    LD      C, (HL)
    POP     HL

ENEMY_DX:
    LD      A, (HL)                         ; DX 1, or -1 going left; twice that if fast
    EX      (SP), HL
    LD      B, $01
    BIT     7, A
    JR      Z, ENEMY_FAST
    LD      B, $FF

ENEMY_FAST:
    EX      (SP), HL
    INC     HL
    LD      A, (HL)
    DEC     HL
    EX      (SP), HL
    BIT     7, A
    JR      Z, ENEMY_SHIFT
    LD      A, B
    ADD     A, B
    LD      B, A

ENEMY_SHIFT:
    LD      A, (HL)                         ; Y - C, X + B
    SUB     C
    LD      (HL), A
    INC     HL
    LD      A, (HL)
    ADD     A, B
    LD      (HL), A
    POP     HL
    CP      $08                             ; within 8 pixels of the left edge: turn
    JR      NC, ENEMY_NEXT
    LD      A, (HL)
    XOR     $80
    LD      (HL), A

ENEMY_NEXT:
    INC     HL
    INC     HL
    JP      MOVE_ENEMIES_NEXT

; IS_WALL ($A894): Z if tile A stops Joe and the enemies moving sideways.
IS_WALL:
    PUSH    HL
    PUSH    BC
    LD      HL, WALL_TILES
    LD      BC, $0008
    CPIR
    POP     BC
    POP     HL
    RET

; The main loop's tasks: the countdown's address, the routine, the period
; in frames. Each countdown starts at 2 ($81B5).
TASKS:
    DW      $7073                           ; CONTACT_TASK, every 2 frames
    DW      CONTACT_TASK
    DB      $02
    DW      $7012                           ; ITEM_TASK, every 4
    DW      ITEM_TASK
    DB      $04
    DW      $7068                           ; MOVE_TASK, every frame
    DW      MOVE_TASK
    DB      $01
    DW      $7074                           ; BARRIER_TASK, every frame
    DW      BARRIER_TASK
    DB      $01
    DB      $FF, $FF                        ; end

; VRAM_LOCK ($A8B7), VRAM_UNLOCK ($A8C3): nest around writes to video memory.
; While locked ($705F bit 1) the frame interrupt does nothing but
; acknowledge the video chip.
VRAM_LOCK:
    PUSH    HL
    LD      HL, $705F
    SET     1, (HL)
    LD      HL, $70AF
    INC     (HL)
    POP     HL
    RET

VRAM_UNLOCK:
    PUSH    HL
    PUSH    AF
    LD      HL, $70AF
    DEC     (HL)
    LD      A, (HL)
    CP      $00
    JR      NZ, VRAM_UNLOCK_DONE
    LD      HL, $705F
    RES     1, (HL)

VRAM_UNLOCK_DONE:
    POP     AF
    POP     HL
    RET

; =============================================================================
; BARRIER_TASK ($A8D6): main-loop task, every frame. $70A8 counts 96 frames
; ($60 down to 1): at $60 the disappearing floors go (colour entry 29 black,
; $7000 bit 6) and the barriers go off (entry 28 black, bit 5); at $48 the
; floors come back, at $30 the barriers ($40: dark blue).
; =============================================================================
BARRIER_TASK:
    LD      A, ($70A8)
    DEC     A
    JR      NZ, BARRIER_COUNT
    LD      A, $60

BARRIER_COUNT:
    LD      ($70A8), A
    CP      $60
    JR      NZ, BARRIER_FLOORS
    LD      HL, $7000                       ; floors gone
    SET     6, (HL)
    LD      HL, BLACK                       ; black

SET_FLOOR_COLOUR:
    LD      DE, $001D
    CALL    SET_COLOUR

BARRIER_CHECK:
    LD      A, ($70A8)
    CP      $60
    JR      NZ, BARRIER_ON
    LD      HL, $7000                       ; barriers off
    SET     5, (HL)
    LD      HL, BLACK

SET_BARRIER_COLOUR:
    LD      DE, $001C

SET_COLOUR:
    PUSH    DE                              ; (swaps nothing)
    PUSH    HL
    POP     HL
    POP     DE
    LD      IY, $0001                       ; colour entry DE = (HL)
    LD      A, $04
    CALL    PUT_VRAM_LOCKED
    RET

BARRIER_FLOORS:
    CP      $48
    JR      NZ, BARRIER_CHECK
    LD      HL, $7000                       ; floors back
    RES     6, (HL)
    LD      HL, SHOWN_COLOUR
    JR      SET_FLOOR_COLOUR

BARRIER_ON:
    CP      $30
    RET     NZ
    LD      HL, $7000                       ; barriers on
    RES     5, (HL)
    LD      HL, SHOWN_COLOUR
    JR      SET_BARRIER_COLOUR

SHOWN_COLOUR:
    DB      $40                             ; dark blue

; BARRIER_PATTERNS ($A92F): redraw the barrier ($E0) and disappearing floor
; ($E8) patterns in all four pattern tables for frame $7096, then point the
; video chip back at the table $73F9 names.
BARRIER_PATTERNS:
    CALL    VRAM_LOCK
    LD      A, ($73F9)                      ; the table to show
    LD      ($7085), A
    LD      C, $00
    XOR     A
    CALL    FRAME_PATTERNS
    LD      C, $01
    LD      A, $08
    CALL    FRAME_PATTERNS
    LD      C, $02
    LD      A, $10
    CALL    FRAME_PATTERNS
    LD      C, $05
    LD      A, $28
    CALL    FRAME_PATTERNS
    LD      A, ($7085)
    CP      $00
    JR      NZ, BARRIER_PATTERNS_1
    LD      C, $00

BARRIER_PATTERNS_1:
    CP      $08
    JR      NZ, BARRIER_PATTERNS_2
    LD      C, $01

BARRIER_PATTERNS_2:
    CP      $10
    JR      NZ, BARRIER_PATTERNS_5
    LD      C, $02

BARRIER_PATTERNS_5:
    CP      $28
    JR      NZ, BARRIER_PATTERNS_SHOW
    LD      C, $05

BARRIER_PATTERNS_SHOW:
    LD      ($73F9), A
    LD      B, $04                          ; register 4
    CALL    WRITE_REGISTER
    CALL    VRAM_UNLOCK
    RET

; Pattern table C (high byte A): the barrier's 8 bytes from 2 x $7096
; into GFX_BARRIER, the floor's from 8 x ($7096 AND 1) into
; GFX_DISAPPEARING.
FRAME_PATTERNS:
    LD      ($73F9), A
    LD      B, $04
    CALL    WRITE_REGISTER
    LD      A, ($7096)
    PUSH    AF
    SLA     A
    LD      HL, GFX_BARRIER
    LD      DE, $00E0
    CALL    PUT_PATTERN
    LD      HL, GFX_DISAPPEARING
    LD      DE, $00E8
    POP     AF
    AND     $01
    SLA     A
    SLA     A
    SLA     A

; PUT_PATTERN ($A9A0): tile pattern DE from HL + A.
PUT_PATTERN:
    CALL    TABLE_BYTE
    LD      IY, $0001
    LD      A, $03
    CALL    PUT_VRAM_LOCKED
    RET

; Treasure room tiles: the chain, then a wall's three columns, left of the
; screen and (overlapping) right.
TREASURE_TILES:
    DB      $90                             ; a chain

TREASURE_LEFT_WALL:
    DB      $08, $00                        ; brick, nothing,

TREASURE_RIGHT_WALL:
    DB      $95, $00, $08                   ; pole (left wall); pole, nothing, brick (right wall)

; =============================================================================
; NMI ($A9B3): the frame interrupt, at every vertical blank. Unless it
; interrupts itself ($70B1 bit 7): load a room ($70B1 bit 3,
; LOAD_ROOM_NOW); then, unless it interrupts a write to video memory ($705F
; bit 1): set up a treasure screen ($705F bit 3), recolour the room ($70B1
; bit 4, ROOM_COLOURS); count the
; frame counter $7097 and the treasure room's pointer $7047; take the next
; tile animation step if the item task has allowed it ($7011 bit 7 clear):
; pattern tables 0, 1, 2, 5 in turn, with the barrier patterns redrawn;
; count down the main loop's sync byte $7207; copy the sprites to the video
; chip; and play the sound effect. Then acknowledge the video chip.
; =============================================================================
NMI:
    PUSH    AF
    PUSH    BC
    PUSH    DE
    PUSH    HL
    PUSH    IX
    PUSH    IY
    EX      AF, AF'
    EXX
    PUSH    AF
    PUSH    BC
    PUSH    DE
    PUSH    HL
    LD      HL, $70B1                       ; interrupting itself: just return
    BIT     7, (HL)
    JP      NZ, NMI_RETURN
    SET     7, (HL)                         ; busy
    BIT     3, (HL)                         ; load a room?
    RES     3, (HL)
    CALL    NZ, LOAD_ROOM_NOW
    LD      A, ($705F)                      ; a video memory write in progress?
    BIT     1, A
    JR      NZ, NMI_ACK
    BIT     3, A                            ; a treasure screen?
    CALL    NZ, TREASURE_SCREEN
    LD      HL, $70B1                       ; recolour?
    BIT     4, (HL)
    RES     4, (HL)
    CALL    NZ, ROOM_COLOURS
    LD      HL, $7097                       ; the frame counter
    INC     (HL)
    LD      HL, ($7047)                     ; the treasure room's random pointer
    INC     HL
    LD      ($7047), HL
    LD      A, ($7011)                      ; the animation step, unless the item task hasn't
    INC     A
    BIT     7, A                            ; cleared bit 7 since the last
    JR      NZ, NMI_SPRITES
    LD      ($7011), A
    CP      $01                             ; step 1: table 0 ($0000) (B, C: unused)
    JR      NZ, ANIM_STEP_2
    LD      BC, $0400
    XOR     A
    JR      ANIM_STEP

ANIM_STEP_2:
    CP      $02                             ; step 2: table 1 ($0800)
    JR      NZ, ANIM_STEP_3
    LD      BC, $0401
    LD      A, $08
    JR      ANIM_STEP

ANIM_STEP_3:
    CP      $03                             ; step 3: table 2 ($1000)
    JR      NZ, ANIM_STEP_4
    LD      BC, $0402
    LD      A, $10
    JR      ANIM_STEP

ANIM_STEP_4:
    CP      $04                             ; step 4: table 5 ($2800), and round again
    JR      NZ, NMI_SPRITES
    LD      HL, $7011
    LD      (HL), $00
    LD      BC, $0405
    LD      A, $28

ANIM_STEP:
    LD      ($73F9), A                      ; the table to show
    CALL    BARRIER_PATTERNS                ; barrier patterns, and the table
    LD      HL, $7011                       ; bit 7: wait for the item task
    LD      A, (HL)
    XOR     $80
    LD      (HL), A

NMI_SPRITES:
    LD      HL, $7207                       ; the main loop's sync byte
    DEC     (HL)
    LD      A, $08                          ; the 8 sprites to the video chip
    CALL    WR_SPR_NM_TBL
    CALL    SOUND_TICK                      ; the sound effect

NMI_ACK:
    CALL    READ_REGISTER                   ; acknowledge the interrupt
    LD      HL, $70B1
    RES     7, (HL)

NMI_RETURN:
    POP     HL
    POP     DE
    POP     BC
    POP     AF
    EX      AF, AF'
    EXX
    POP     IY
    POP     IX
    POP     HL
    POP     DE
    POP     BC
    POP     AF
    RETN

; DRAW_HUD_BOXES ($AA5D): the boxes for the inventory (columns 0-11) and the
; lives (22-31) in rows 0-4. TILE_ROWS with C = 1 draws a run of B tiles.
DRAW_HUD_BOXES:
    LD      DE, $0001                       ; top and bottom edges: columns 1-10,
    LD      BC, $0A01
    CALL    HUD_BOX_EDGE
    LD      BC, $0801                       ; columns 23-30
    LD      DE, $0017
    CALL    HUD_BOX_EDGE
    LD      HL, HUD_BOX_ROWS                ; the sides, rows 1-3: columns 0-11 (the inside is
    LD      BC, $030C                       ; drawn over by the inventory),
    LD      DE, $0020
    CALL    TILE_COLUMNS
    LD      DE, $0036                       ; columns 22-31
    LD      HL, HUD_BOX_ROW_RIGHT
    LD      BC, $030A
    CALL    TILE_COLUMNS
    RET

; The boxes' sides: the left box's row is 12 tiles from here, the right
; box's 10 from the next.
HUD_BOX_ROWS:
    DB      $0A                             ; left edge

HUD_BOX_ROW_RIGHT:
    DB      $0A, $00, $00, $00, $00, $00, $00, $00 ; left edge, inside, right edge
    DB      $00, $0B, $0B

HUD_BOX_TOP:
    DB      $09                             ; top edge

HUD_BOX_BOTTOM:
    DB      $0C                             ; bottom edge

; TILE_COLUMNS ($AA96): TILE_ROWS with rows 32 apart (B rows of C tiles from
; HL at name position DE).
TILE_COLUMNS:
    PUSH    HL
    LD      HL, $7000
    SET     2, (HL)
    POP     HL
    CALL    TILE_ROWS
    PUSH    HL
    LD      HL, $7000
    RES     2, (HL)
    POP     HL
    RET

; HUD_BOX_EDGE ($AAA8): B tiles of the top edge at DE, of the bottom edge 4
; rows below.
HUD_BOX_EDGE:
    LD      HL, HUD_BOX_TOP
    CALL    TILE_ROWS
    EX      DE, HL
    LD      DE, $0080
    ADD     HL, DE
    EX      DE, HL
    LD      HL, HUD_BOX_BOTTOM
    CALL    TILE_ROWS
    RET

; DRAW_LIVES ($AABB): a hat for each spare life: up to 10 at row 3 column 1,
; up to 8 more at column 23. Not in the treasure room.
DRAW_LIVES:
    LD      A, ($705F)
    BIT     5, A
    RET     NZ
    CALL    VRAM_LOCK
    LD      HL, $1861                       ; clear both rows
    LD      DE, $0008
    XOR     A
    CALL    FILL_VRAM_LOCKED
    LD      HL, $1877
    LD      DE, $0008
    XOR     A
    CALL    FILL_VRAM_LOCKED
    LD      A, ($7049)                      ; lives, his own included
    PUSH    AF
    CP      $01
    JR      Z, DRAW_LIVES_DONE
    DEC     A
    LD      HL, $1861
    LD      E, A
    CP      $0B                             ; more than 10 spare
    JR      C, DRAW_LIVES_ROW
    LD      DE, $000A
    LD      A, $6F                          ; the hat
    CALL    FILL_VRAM_LOCKED
    POP     AF
    DEC     A
    PUSH    AF
    SUB     $0A                             ; the rest, up to 8
    LD      HL, $1877
    LD      E, $08
    CP      $09
    JR      NC, DRAW_LIVES_ROW
    LD      E, A

DRAW_LIVES_ROW:
    LD      D, $00
    LD      A, $6F
    CALL    FILL_VRAM_LOCKED

DRAW_LIVES_DONE:
    POP     AF
    CALL    VRAM_UNLOCK
    RET

; Tiles that change when a room is mirrored (MIRROR_ROOM): (tile, mirror
; image) pairs up to $FF. The halves of ladders and their tops swap, and
; conveyors turn round.
MIRROR_PAIRS:
    DB      $10, $11, $11, $10              ; ladder tops in floors
    DB      $88, $89, $89, $88              ; ladder
    DB      $04, $BA, $06, $B8              ; conveyor ends
    DB      $B8, $06, $BA, $04              ; the same, the other way
    DB      $05, $B9, $B9, $05              ; middles
    DB      $FF                             ; end

MIRROR_TILE:
    PUSH    AF                              ; the tile's mirror image
    INC     HL
    LD      A, (HL)
    LD      (DE), A
    POP     AF
    DEC     HL
    JR      MIRROR_ROOM_NEXT

; MIRROR_ROOM ($AB29): mirror the screen left to right, rows 5-22 (row 23 is
; read but not written back), a row at a time through the buffer at $7200:
; tiles swapped for their mirror images (MIRROR_PAIRS), then the row
; reversed into $7280. The buffer runs over the main loop's sync byte $7207,
; leaving the room's tile there, which it then waits out ($A5CA).
MIRROR_ROOM:
    PUSH    HL
    PUSH    DE
    PUSH    BC
    PUSH    AF
    CALL    VRAM_LOCK
    LD      A, $13                          ; 19 rows
    LD      ($7002), A
    LD      HL, $7200                       ; from row 5
    LD      DE, $00A0
    LD      IY, $0020
    LD      A, $02

MIRROR_ROOM_ROW:
    PUSH    HL                              ; the row into $7200
    PUSH    IY
    PUSH    AF
    PUSH    DE
    CALL    GET_VRAM
    POP     DE
    PUSH    DE
    PUSH    HL
    PUSH    DE
    PUSH    BC
    LD      DE, $7200
    LD      B, $20

MIRROR_ROOM_TILE:
    LD      HL, MIRROR_PAIRS

MIRROR_ROOM_PAIR:
    LD      A, (HL)
    CP      $FF
    JR      Z, MIRROR_ROOM_NEXT
    LD      A, (DE)                         ; bricks and empty tiles stay
    CP      $08
    JR      Z, MIRROR_ROOM_NEXT
    CP      $00
    JR      Z, MIRROR_ROOM_NEXT
    CP      (HL)
    JR      Z, MIRROR_TILE
    INC     HL
    INC     HL
    JR      MIRROR_ROOM_PAIR

MIRROR_ROOM_NEXT:
    INC     DE
    DJNZ    MIRROR_ROOM_TILE
    POP     BC
    POP     DE
    POP     HL
    LD      A, ($7002)                      ; the last row isn't written
    DEC     A
    LD      ($7002), A
    CP      $00
    JR      Z, MIRROR_ROOM_DONE
    LD      BC, $2001                       ; reversed into $7280
    LD      HL, $7200
    PUSH    DE
    LD      B, $20
    EX      DE, HL
    LD      HL, $729F

MIRROR_ROOM_REVERSE:
    LD      A, (DE)
    LD      (HL), A
    DEC     HL
    INC     DE
    DJNZ    MIRROR_ROOM_REVERSE
    POP     DE
    LD      BC, $0120                       ; and back to the screen
    LD      HL, $7280
    CALL    TILE_ROWS
    POP     HL                              ; the next row
    LD      BC, $0020
    ADD     HL, BC
    PUSH    HL
    POP     DE
    POP     AF
    POP     IY
    POP     HL
    JR      MIRROR_ROOM_ROW

MIRROR_ROOM_DONE:
    POP     DE
    POP     AF
    POP     IY
    POP     HL
    POP     AF
    POP     BC
    POP     DE
    POP     HL
    CALL    VRAM_UNLOCK
    RET

; BOUNCE_ARC ($ABB3): Y steps of a bouncing enemy (taken off its Y: positive
; is up), read backwards by its counter, 58 frames. The zeros at $ABCD
; double as black for the colour table.
BOUNCE_ARC:
    DB      $FD, $FE, $FE, $FE, $FE, $FE, $FE, $FF
    DB      $FF, $FF, $FF, $FF, $FF, $FF, $00, $FF
    DB      $00, $FF, $00, $FF, $00, $FF, $00, $FF
    DB      $00, $FF

BLACK:
    DB      $00, $00, $00, $00, $00, $00, $01, $00 ; 6 zeros
    DB      $01, $00, $01, $00, $01, $00, $01, $00
    DB      $01, $00, $01, $01, $01, $01, $01, $01
    DB      $01, $02, $02, $02, $02, $02, $02, $03

; ALIGN_ENEMY ($ABED): snap an enemy's X onto a ladder (0 or 8, mod 16); its
; sprite entry is under the return address.
ALIGN_ENEMY:
    LD      C, $08
    POP     IX
    EX      (SP), HL
    INC     HL
    LD      A, (HL)
    AND     $0F
    CP      $08
    JR      NC, ALIGN_ENEMY_SET
    LD      C, $00

ALIGN_ENEMY_SET:
    LD      A, (HL)
    AND     $F0
    ADD     A, C
    LD      (HL), A
    DEC     HL
    EX      (SP), HL
    PUSH    IX
    RET

; EMPTY_INVENTORY ($AC06): $71B2-$71B8 all $FF.
EMPTY_INVENTORY:
    PUSH    HL
    PUSH    DE
    PUSH    BC
    LD      HL, $71B2
    PUSH    HL
    POP     DE
    INC     DE
    LD      (HL), $FF
    LD      BC, $0006
    LDIR
    POP     BC
    POP     DE
    POP     HL
    RET

; =============================================================================
; SOUND
; One sound effect plays at a time. PLAY_SOUND ($AC1A) starts effect A
; unless one with a lower number is playing (the same one starts over, but
; for 1 and 9); the frame interrupt runs SOUND_TICK ($AC6D), which writes
; the sound chip (port $FF) itself.
;
; RAM: $702C flags (bit 7 playing, bit 5 the next step is the first; bit 6,
; a stop request, is never set), $702D the effect, $702E the data pointer,
; $7030 frames per step, $7031 tone channels, $7032 the frame count, $7033
; the channel count, $7034 scratch, $7035 the control byte.
; =============================================================================
PLAY_SOUND:
    PUSH    AF
    PUSH    HL
    PUSH    DE
    PUSH    BC
    LD      B, A
    LD      HL, $702C
    BIT     7, (HL)
    JR      NZ, PLAY_SOUND_BUSY

PLAY_SOUND_START:
    LD      ($702D), A
    SET     7, (HL)
    SET     5, (HL)
    RES     6, (HL)                         ; (never set)
    ADD     A, A                            ; its header: frames per step,
    LD      HL, SOUND_EFFECTS
    LD      E, A
    LD      D, $00
    ADD     HL, DE
    LD      E, (HL)
    INC     HL
    LD      D, (HL)
    EX      DE, HL
    LD      A, (HL)
    LD      ($7030), A
    DEC     A
    LD      ($7032), A
    INC     HL                              ; the control byte: bits 0-1 tone channels
    LD      A, (HL)
    LD      ($7035), A
    AND     $03
    LD      ($7031), A
    INC     HL
    LD      ($702E), HL
    XOR     A
    LD      ($7033), A

PLAY_SOUND_DONE:
    POP     BC
    POP     DE
    POP     HL
    POP     AF
    RET

PLAY_SOUND_BUSY:
    LD      A, ($702D)                      ; a lower number is playing
    CP      B
    JR      C, PLAY_SOUND_DONE
    JR      NZ, PLAY_SOUND_AGAIN
    CP      $09                             ; the same one: 9 and 1 play on
    JR      Z, PLAY_SOUND_DONE
    CP      $01
    JR      Z, PLAY_SOUND_DONE

PLAY_SOUND_AGAIN:
    LD      A, B
    JR      PLAY_SOUND_START

; SOUND_TICK ($AC6D): every $7030 frames, the effect's next step.
SOUND_TICK:
    LD      HL, $702C
    BIT     7, (HL)
    RET     Z
    BIT     6, (HL)
    JR      Z, SOUND_STEP

SOUND_STOP:
    LD      HL, $702C
    RES     6, (HL)
    RES     7, (HL)
    CALL    TURN_OFF_SOUND                  ; silence
    RET

SOUND_STEP:
    LD      HL, $7032                       ; every $7030 frames
    INC     (HL)
    LD      A, (HL)
    LD      HL, $7030
    CP      (HL)
    RET     NZ
    XOR     A
    LD      ($7032), A
    LD      HL, $702C
    BIT     5, (HL)                         ; the first step: volumes
    JR      Z, SOUND_CHANNEL
    RES     5, (HL)
    LD      HL, ($702E)
    LD      A, (HL)                         ; channel 2 (low nibble), noise (high)
    AND     $0F
    OR      $D0
    OUT     ($FF), A
    LD      A, (HL)
    AND     $F0
    RRCA
    RRCA
    RRCA
    RRCA
    OR      $F0
    OUT     ($FF), A
    INC     HL
    LD      A, (HL)                         ; channel 0 (low nibble), channel 1 (high)
    AND     $0F
    OR      $90
    OUT     ($FF), A
    LD      A, (HL)
    AND     $F0
    RRCA
    RRCA
    RRCA
    RRCA
    OR      $B0
    OUT     ($FF), A
    INC     HL
    LD      ($702E), HL
    LD      A, $E3                          ; noise: following channel 2's tone; white if
    LD      HL, $7035                       ; control bit 2
    OR      (HL)
    OUT     ($FF), A

SOUND_CHANNEL:
    LD      A, ($7033)                      ; a byte for each tone channel: 2, then 1, 0
    LD      HL, $7031
    CP      (HL)
    JR      Z, SOUND_STEP_DONE
    LD      HL, $7033
    INC     (HL)
    LD      HL, ($702E)
    LD      A, (HL)
    CP      $00                             ; 0 ends the effect
    JR      Z, SOUND_STOP
    AND     $FC                             ; the period over 4: its high 6 bits...
    RRCA
    RRCA
    LD      ($7034), A
    LD      A, (HL)                         ; ...and its low 2, into the latch byte
    AND     $03
    RLCA
    RLCA
    LD      B, A
    LD      A, ($7033)
    XOR     $07
    RRCA
    RRCA
    RRCA
    OR      B
    INC     HL
    LD      ($702E), HL
    OUT     ($FF), A
    LD      A, ($7034)
    OUT     ($FF), A
    JP      SOUND_CHANNEL

SOUND_STEP_DONE:
    XOR     A
    LD      ($7033), A
    RET

; The sound effects: frames per step; the control byte (bits 0-1: tone
; channels, bit 2: white noise); volumes for the first step (attenuation:
; channel 2 and noise, then channel 0 and channel 1, low nibble first);
; then a byte per tone channel per step (the tone's period over 4), up to 0.
SOUND_EFFECTS:
    DW      SOUND_EXTRA_LIFE                ; 0 extra life
    DW      SOUND_BELOW                     ; 1 leaving the bottom row
    DW      SOUND_PICKUP                    ; 2 item picked up
    DW      SOUND_SWORD                     ; 3 sword kill
    DW      SOUND_LAND                      ; 4 landing
    DW      SOUND_DEATH                     ; 5 death
    DW      SOUND_POLE                      ; 6 catching a pole
    DW      SOUND_JUMP                      ; 7 jump
    DW      SOUND_DOOR                      ; 8 door opened
    DW      SOUND_FOOTSTEP                  ; 9 footsteps

SOUND_PICKUP:
    DB      $04, $02, $F1, $1F              ; 4 frames a step, tones on channels 2 and 1
    DB      $3C, $60, $01, $01, $3C, $60, $01, $01
    DB      $3C, $60, $01, $01, $2D, $48, $01, $01
    DB      $01, $01, $01, $01, $24, $3C, $00

SOUND_BELOW:
    DB      $08, $02, $F0, $0F              ; 8 frames a step, tones on channels 2 and 1
    DB      $04, $AB, $2B, $72, $02, $55, $39, $87
    DB      $22, $55, $1D, $44, $33, $AB, $2B, $72
    DB      $22, $55, $39, $87, $22, $55, $1D, $44
    DB      $2B, $72, $1D, $55, $15, $39, $39, $87
    DB      $22, $55, $2D, $44, $2B, $72, $1D, $55
    DB      $1A, $39, $18, $40, $15, $44, $00

SOUND_EXTRA_LIFE:
    DB      $05, $02, $F1, $1F              ; 5 frames a step, tones on channels 2 and 1
    DB      $30, $39, $30, $39, $2B, $36, $30, $39
    DB      $30, $39, $2B, $36, $30, $39, $01, $01
    DB      $01, $01, $1D, $24, $01, $01, $01, $01
    DB      $24, $39, $00

SOUND_SWORD:
    DB      $01, $01, $F1, $FF              ; every frame, a tone on channel 2
    DB      $9F, $3C, $42, $4F, $53, $56, $5F, $67
    DB      $71, $78, $86, $00

SOUND_POLE:
    DB      $01, $01, $F2, $FF              ; every frame, a tone on channel 2
    DB      $5A, $5D, $5E, $5F, $61, $63, $65, $67
    DB      $68, $69, $6B, $6D, $6F, $72, $74, $75
    DB      $77, $7A, $7B, $7D, $80, $82, $84, $86
    DB      $88, $8A, $8B, $8D, $00

SOUND_FOOTSTEP:
    DB      $01, $05, $2F, $FF              ; every frame, white noise pitched by channel 2
    DB      $C0, $FE, $01, $00

SOUND_DEATH:
    DB      $03, $05, $0F, $FF              ; 3 frames a step, white noise pitched by channel 2
    DB      $87, $F8, $89, $94, $84, $75, $10, $80
    DB      $00

SOUND_JUMP:
    DB      $01, $01, $F2, $FF              ; every frame, a tone on channel 2
    DB      $73, $6E, $69, $64, $5F, $5A, $55, $50
    DB      $4B, $00

SOUND_LAND:
    DB      $01, $05, $0F, $FF              ; every frame, white noise pitched by channel 2
    DB      $C0, $C0, $01, $C0, $C0, $01, $00

SOUND_DOOR:
    DB      $01, $01, $F1, $FF              ; every frame, a tone on channel 2
    DB      $9F, $01, $01, $01, $10, $10, $C0, $10
    DB      $10, $01, $01, $01, $01, $01, $01, $10
    DB      $00

; =============================================================================
; LOADER ($AE00): copy blocks to video memory, from records inline after the
; CALL: a source address (DW), a first item and a count (DB), up to a
; source with a zero high byte. A: the PUT_VRAM table (0 sprite attributes,
; 1 sprite patterns, 2 names, 3 tile patterns, 4 colours). Returns past the
; records.
; =============================================================================
LOADER:
    POP     HL                              ; the records

LOADER_RECORD:
    PUSH    AF
    LD      C, (HL)                         ; the source's low byte...
    INC     HL
    LD      A, (HL)                         ; ...and high byte
    CP      $00
    JR      Z, LOADER_DONE                  ; zero: the end
    LD      B, A
    POP     AF
    PUSH    BC
    INC     HL
    LD      E, (HL)                         ; the first item
    LD      D, $00
    LD      B, $00
    INC     HL
    LD      C, (HL)                         ; the count
    PUSH    BC
    POP     IY
    EX      (SP), HL                        ; HL: the source
    PUSH    AF
    CALL    PUT_VRAM_LOCKED
    POP     AF
    POP     HL
    INC     HL
    JR      LOADER_RECORD

LOADER_DONE:
    POP     AF
    INC     HL                              ; past the last byte
    PUSH    HL
    RET

; FILL_VRAM_LOCKED ($AE25), PUT_VRAM_LOCKED ($AE2E): the BIOS's FILL_VRAM
; (A into DE bytes at HL) and PUT_VRAM (IY items of table A from HL at item
; DE), inside VRAM_LOCK.
FILL_VRAM_LOCKED:
    CALL    VRAM_LOCK
    CALL    FILL_VRAM
    JR      VRAM_CALL_DONE
    RET                                     ; (unreachable)

PUT_VRAM_LOCKED:
    CALL    VRAM_LOCK
    CALL    PUT_VRAM

VRAM_CALL_DONE:
    CALL    VRAM_UNLOCK
    RET

CALL_IX:
    JP      (IX)                            ; (unused)

; CALL_HL ($AE3A): CALL it to call (HL).
CALL_HL:
    JP      (HL)

; REFLECT_LIST ($AE3B): reflect patterns from a list at HL: the mode (0:
; upside down, REFLECT_HORIZONTAL; else left-right, REFLECT_VERTICAL), the
; PUT_VRAM table, then (from, to) pairs up to $FF.
REFLECT_LIST:
    LD      A, (HL)
    LD      ($7013), A
    INC     HL
    LD      A, (HL)
    PUSH    AF
    INC     HL
    PUSH    HL
    POP     IX

REFLECT_LIST_PAIR:
    LD      H, $00
    LD      L, (IX+1)
    LD      D, H
    LD      E, (IX+0)
    LD      A, E
    CP      $FF
    JR      Z, REFLECT_LIST_DONE
    LD      BC, $0001
    POP     AF
    PUSH    AF
    EX      AF, AF'
    PUSH    IX
    LD      A, ($7013)
    CP      $00
    JR      NZ, REFLECT_LIST_MIRROR
    EX      AF, AF'
    CALL    REFLECT_HORIZONTAL
    JR      REFLECT_LIST_NEXT

REFLECT_LIST_MIRROR:
    EX      AF, AF'
    CALL    REFLECT_VERTICAL

REFLECT_LIST_NEXT:
    POP     IX
    INC     IX
    INC     IX
    JR      REFLECT_LIST_PAIR

REFLECT_LIST_DONE:
    POP     AF
    RET

; DISPLAY_OFF ($AE77), DISPLAY_ON ($AE83): nest around drawing a screen;
; register 1 = $82 (display and frame interrupt off), back to $E2.
DISPLAY_OFF:
    CALL    VRAM_LOCK
    LD      HL, $70B3
    INC     (HL)
    LD      BC, $0182
    JR      WRITE_REGISTER_JP

DISPLAY_ON:
    CALL    VRAM_UNLOCK
    LD      HL, $70B3
    DEC     (HL)
    LD      A, (HL)
    CP      $00
    RET     NZ
    LD      BC, $01E2

WRITE_REGISTER_JP:
    JP      WRITE_REGISTER

; Unused: a delay.
DELAY:
    PUSH    BC
    PUSH    DE
    PUSH    AF
    LD      B, $FF

DELAY_OUTER:
    LD      DE, $00FF

DELAY_INNER:
    DEC     DE
    LD      A, D
    OR      E
    JR      NZ, DELAY_INNER
    DJNZ    DELAY_OUTER
    POP     AF
    POP     DE
    POP     BC
    RET

; TILE_ROWS ($AEA7): write B rows of C tiles at name position DE, each row
; the same C tiles from HL. Rows are C apart, or 32 with $7000 bit 2. With
; $7000 bit 4 it reads instead, on into the buffer at HL (the BIOS leaves HL
; past what it read). With bit 3 (never set while it runs) each row would
; start a tile further on in HL and 2 columns further left.
TILE_ROWS:
    PUSH    IX
    PUSH    BC
    PUSH    HL
    PUSH    DE
    PUSH    BC
    CALL    VRAM_LOCK
    LD      B, $00
    PUSH    BC
    POP     IY
    POP     BC
    LD      C, $00

TILE_ROWS_ROW:
    LD      A, $02                          ; table 2: names
    PUSH    BC
    PUSH    HL
    PUSH    DE
    PUSH    IY
    PUSH    AF
    LD      A, ($7000)
    BIT     4, A
    JR      Z, TILE_ROWS_WRITE
    POP     AF
    CALL    GET_VRAM
    JR      TILE_ROWS_NEXT

TILE_ROWS_WRITE:
    POP     AF
    CALL    PUT_VRAM_LOCKED

TILE_ROWS_NEXT:
    POP     BC
    POP     DE
    PUSH    BC
    LD      A, ($7000)
    BIT     2, A
    JR      Z, TILE_ROWS_DOWN
    LD      BC, $0020

TILE_ROWS_DOWN:
    EX      DE, HL
    ADD     HL, BC
    EX      DE, HL
    POP     IY
    BIT     4, A
    JR      Z, TILE_ROWS_SOURCE
    POP     BC
    JR      TILE_ROWS_LOOP

TILE_ROWS_SOURCE:
    POP     HL
    BIT     3, A
    JR      Z, TILE_ROWS_LOOP
    INC     HL
    DEC     DE
    DEC     DE

TILE_ROWS_LOOP:
    POP     BC
    DJNZ    TILE_ROWS_ROW
    POP     DE
    POP     HL
    POP     BC
    POP     IX
    CALL    VRAM_UNLOCK
    RET

; DRAW_SCORE ($AEFE): the score's six BCD digits in big digits at row 1
; column 24 (top halves, $18 + digit) and row 2 (bottom halves, $28 +
; digit), leading zeros blank; the level at column 20.
DRAW_SCORE:
    PUSH    HL
    PUSH    BC
    PUSH    DE
    PUSH    AF
    CALL    VRAM_LOCK
    LD      HL, $1838
    LD      C, $18
    CALL    DRAW_DIGITS
    LD      HL, $1858
    LD      C, $28
    CALL    DRAW_DIGITS
    LD      HL, $1834                       ; the level
    LD      A, ($71A6)
    PUSH    AF
    ADD     A, $18
    CALL    PUT_TILE
    POP     AF
    LD      HL, $1854
    ADD     A, $28
    CALL    PUT_TILE
    CALL    VRAM_UNLOCK
    POP     AF
    POP     DE
    POP     BC
    POP     HL
    RET

; The score's digits, tiles C + digit; $70B1 bit 0: a digit other than 0
; has been drawn.
DRAW_DIGITS:
    LD      B, $03
    LD      DE, $7017

DRAW_DIGITS_BYTE:
    PUSH    BC
    LD      A, (DE)                         ; the high digit,
    SRA     A
    SRA     A
    SRA     A
    SRA     A
    PUSH    BC
    CALL    DRAW_DIGIT
    POP     BC
    LD      A, (DE)                         ; the low one
    CALL    DRAW_DIGIT
    INC     DE
    POP     BC
    DJNZ    DRAW_DIGITS_BYTE
    LD      HL, $70B1
    RES     0, (HL)
    RET

DRAW_DIGIT:
    PUSH    HL
    LD      HL, $70B1
    AND     $0F                             ; a leading 0: blank
    CP      $00
    JR      NZ, DRAW_DIGIT_TILE
    BIT     0, (HL)
    JR      Z, DRAW_DIGIT_PUT

DRAW_DIGIT_TILE:
    ADD     A, C
    SET     0, (HL)

DRAW_DIGIT_PUT:
    POP     HL

; PUT_TILE ($AF66): tile A at name position HL; HL + 1.
PUT_TILE:
    PUSH    DE
    LD      DE, $0001
    CALL    FILL_VRAM_LOCKED
    INC     HL
    POP     DE
    RET

; ADD_SCORE ($AF70): add HL (BCD: H hundreds and thousands, L ones and tens)
; to the score at $7017-$7019 (BCD, highest digits first). Passing a
; multiple of 10,000 earns a life, but from level 5 on only if the
; hundreds digit is then even.
ADD_SCORE:
    PUSH    IX
    PUSH    IY
    PUSH    AF
    PUSH    HL
    LD      IY, $7017
    LD      A, L
    CALL    ADD_SCORE_LOW
    LD      A, H
    CALL    ADD_SCORE_MIDDLE
    POP     HL
    POP     AF
    POP     IY
    POP     IX
    RET

ADD_SCORE_LOW:
    SCF
    CCF
    ADC     A, (IY+2)
    DAA
    LD      (IY+2), A
    JR      NC, ADD_SCORE_DONE
    LD      A, $01

ADD_SCORE_MIDDLE:
    SCF
    CCF
    ADC     A, (IY+1)
    DAA
    LD      (IY+1), A
    JR      NC, ADD_SCORE_DONE
    PUSH    HL
    PUSH    AF
    BIT     0, A                            ; the hundreds digit odd,
    JR      Z, EXTRA_LIFE
    LD      A, ($71A6)                      ; and level 5 or later: no life
    CP      $05
    JR      NC, ADD_SCORE_HIGH

EXTRA_LIFE:
    LD      HL, $7049
    INC     (HL)

ADD_SCORE_HIGH:
    POP     AF
    POP     HL
    LD      A, $01
    SCF
    CCF
    ADC     A, (IY+0)
    DAA
    LD      (IY+0), A
    CALL    DRAW_LIVES                      ; the lives in the HUD
    LD      A, $00                          ; sound effect 0: extra life
    CALL    PLAY_SOUND

ADD_SCORE_DONE:
    RET

; TILE_CEIL ($AFC8): A / 8, rounded up, AND $1F.
TILE_CEIL:
    RRC     A
    RES     1, H
    JR      NC, TILE_CEIL_2
    SET     1, H

TILE_CEIL_2:
    RRC     A
    JR      NC, TILE_CEIL_3
    SET     1, H

TILE_CEIL_3:
    RRC     A
    JR      NC, TILE_CEIL_ROUND
    SET     1, H

TILE_CEIL_ROUND:
    AND     $1F
    BIT     1, H
    RET     Z
    INC     A
    RET

; TILE_AT ($AFE3): the name table position (HL) of the tile at pixel X = A,
; Y = B, rounded up: (ceil(Y / 8) - 1) * 32 + ceil(X / 8).
TILE_AT:
    CALL    TILE_CEIL
    LD      C, A
    LD      A, B
    CALL    TILE_CEIL
    AND     $1F
    LD      B, $00
    LD      HL, $0000
    LD      DE, $0020

TILE_AT_ROW:
    DEC     A
    CP      $00
    JR      Z, TILE_AT_DONE
    ADD     HL, DE
    JR      TILE_AT_ROW

TILE_AT_DONE:
    ADD     HL, BC
    RET
    DB      $FB                             ; unused

