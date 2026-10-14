; =============================================================================
; MONTEZUMA'S REVENGE (1984) ColecoVision disassembly
; =============================================================================
;
; Modified 2026-10-15 for montezuma-remake: the room loader ($A067-$A547),
; room data and tile tables ($943C-$A066) relabelled, recommented and
; turned back into code where left as bytes; legend and RAM notes corrected.
; Assembles to the same bytes.
;
; LEGEND
;
; --- ROM LAYOUT (12 KB: $8000-$AFFF) ---
;
;   $8021  CART_ENTRY: JP NMI             line   236
;   $8025  START -- boot entry            line   255
;   ~$8DA2 LOC_8DA2 -- game state mach.  line   853
;   ~$8EB0 DELAY_LOOP_8EB0 -- frame body line   934
;   ~$AA00 NMI handler                   line  4008
;   ~$AE00 SUB_AE00 -- VRAM data writer  line  4505
;
; --- BOOT / INIT SEQUENCE ($8025) ---
;
;   START ($8025)             line   255  zero $7000-$73FF, SP=$73C0
;   SUB_8413 ($8413)          line   529  FILL_VRAM at $0000, length $4000
;   DELAY_LOOP_827F ($827F)   line   445  copy 16 bitmap pairs to RAM
;
; --- NMI HANDLER (~$AA00) ---
;
;   CART_ENTRY ($8021)        line   236  JP NMI (all interrupts -> NMI)
;   NMI (~$AA00)              line  4008  saves AF,BC,DE,HL,IX,IY + alts
;                                         $70B1 bit 7: re-entry guard
;                                         $70B1 bit 3: SUB_919A (room change)
;                                         $70B1 bit 4: DELAY_LOOP_8EB0 (frame)
;                                         $705F bit 3: SUB_A60B (room render)
;
; --- FRAME GAME BODY ($8EB0) ---
;
;   DELAY_LOOP_8EB0 ($8EB0)   line   934  per-frame body (from NMI bit 4)
;   SUB_8308 ($8308)          line   480  render room tiles to VRAM
;   TABLE_BYTE ($A540)        line  3673  A = (HL + A); here the table at $93C0
;   SUB_908F ($908F)          line  1031  item pickup: CPIR $71B2 table
;
; --- GAME STATE / ROOM TRANSITIONS ---
;
;   LOC_8DA2 ($8DA2)          line   853  game state dispatch ($7079)
;   SUB_8DC2 ($8DC2)          line   868  DEC $7049 (life counter)
;   LOC_8DD3 ($8DD3)          line   877  update $7300/$7304 player tile X/Y
;   LOC_929B ($929B)          line  1204  inner-loop end: JP LOC_8DA2
;
; --- ROOM RENDERER / ENEMY PLACEMENT ---
;
;   SUB_A60B ($A60B)          line  3732  room setup (from NMI bit 3 of $705F)
;   SUB_919A ($919A)          line  1082  room change: clear enemy sprites, LOAD_ROOM
;
; --- ROOM LOADER ($A067) ---
;
;   LOAD_ROOM ($A067)         line  2865  draw a room by running its command list
;   ROOM_LISTS ($9477)        line  1383  each room's command list (ROOM DATA notes)
;   CMD_GROUPS ($9444)        line  1329  tile group of each command
;   TILE_GROUPS ($9FD1)       line  2770  tiles the commands draw; HUD icons
;   PLACE_ENEMY ($A405)       line  3464  enemy object + sprite from a command
;   NEXT_THING_GONE ($A514)   line  3637  test the room's "gone" bitmap ($70C0)
;   SUB_92BE ($92BE)          line  1231  mark a thing gone (picked up, killed)
;   DRAW_INVENTORY ($A548)    line  3685  HUD inventory: background + icons
;
; --- VRAM DATA WRITER ---
;
;   SUB_AE00 ($AE00)          line  4505  POP HL: return addr = data ptr
;   SUB_AE2E ($AE2E)          line  4546  set VRAM write addr + PUT_VRAM
;   SUB_AE25 ($AE25)          line  4540  set VRAM write addr + FILL_VRAM
;   SUB_AEA7 ($AEA7)          line  4588  write C tiles from HL at DE, B times
;   SUB_A8B7 ($A8B7)          line  3883  VRAM-lock enter: SET $705F bit 1
;   SUB_A8C3 ($A8C3)          line  3892  VRAM-lock exit: DEC $70AF
;
; --- SOUND SYSTEM ---
;
;   SUB_AC6D ($AC6D)          line  4376  sound sequencer: OUT $FF SN76489A
;   SUB_A92F ($A92F)          line  3920  SN76489A byte writer (4-frame cycle)
;   SUB_AC1A ($AC1A)          line  4317  sound trigger with priority ($702C)
;   SUB_AF70 ($AF70)          line  4731  BCD score add (IY=$7017 digits)
;   SUB_AEFE ($AEFE)          line  4656  score row renderer
;   SUB_AF54 ($AF54)          line  4707  display lives count
;
; --- KEY RAM ---
;
;   $7000  WORK_BUFFER flags (bit 0=active  bit 1=VRAM-busy)
;   $7005  JOYSTICK_BUFFER (BIOS POLLER output)
;   $7011  NMI sub-frame counter (1-4, SN76489A sound cycle)
;   $7047  room data cursor pointer (INC each NMI)
;   $7049  life counter
;   $702C  sound channel flags (bit 7=active  bit 5=seq  bit 6=repeat)
;   $705F  game flags (bit 1=VRAM-busy  bit 3=room-setup  bit 5=tile-skip)
;   $7079  Joe's state (state machine at $8901)
;   $70AF  VRAM-lock nesting counter
;   $70B1  NMI flags (bit 7=re-entry  bit 3=score  bit 4=game-body)
;   $7097  frame counter
;   $71B2  inventory (6 bytes CPIR)     $7207  main loop frame-sync byte
;   $7300  sprite table: Joe's 2 sprites, then the enemies' from $7308
;   $7015  room number       $71A6  level, from 1
;   $71A7  pyramid row       $71A8  pyramid column
;   $7086  enemy objects (2 bytes each, $FF free)
;   $70C0  "gone" bitmap: 2 bytes per room, a bit per thing (NEXT_THING_GONE)
;   $72C0  contact list: a thing's position, or an enemy's sprite offset
;   $7190-$71B1  room loader state (see LOAD_ROOM)
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
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

; RAM DEFINITIONS ***************************

WORK_BUFFER:             EQU $7000
JOYSTICK_BUFFER:         EQU $7005
CONTROLLER_BUFFER:       EQU $702B
STACKTOP:                EQU $73B9

FNAME "output\MONTEZUMA-S-REVENGE-1984-NEW.ROM"
CPU Z80

    ORG     $8000

    DW      $AA55                           ; cart magic
    DB      $00, $73                        ; cart header: NMI vector lo byte ($73=hi, $00=lo -> $7300)
    DB      $E0, $72                        ; cart header: RST $30 vector lo/hi ($72E0)
    DB      $10, $72                        ; cart header: RST $38 vector lo/hi ($7210)
    DW      JOYSTICK_BUFFER                 ; BIOS POLLER writes controller state here
    DW      START                           ; start address
    DB      $C9, $00, $00, $C9, $00, $00, $C9, $00 ; cart header: RST vectors -- $C9 RET pads (entries 0-2)
    DB      $00, $C9, $00, $00, $C9, $00, $00, $C9 ; cart header: RST vectors -- $C9 RET pads (entries 3-5)
    DB      $00, $00, $ED, $4D, $00         ; cart header: RST tail -- RETN opcode + padding

; =============================================================================
; NMI ENTRY VECTOR -- CART_ENTRY ($8021)
; Cart header points $8021 as the NMI vector.  The handler here is simply:
;   JP NMI
;   DB $0B  (padding byte)
; The real NMI handler is at label NMI (~$AA00).  On every VSYNC the BIOS
; jumps here, which redirects to NMI where all registers are saved and the
; frame game logic runs.
; =============================================================================
CART_ENTRY:
    JP      NMI                             ; JP NMI  -- all VSYNC interrupts routed here
    DB      $0B                             ; CART_ENTRY padding byte ($0B)

; =============================================================================
; BOOT ENTRY -- START ($8025)
; ColecoVision BIOS jumps here after power-on.
;   LD HL,WORK_BUFFER / LD BC,$03FF / LD (HL),$00 / LDIR
;     -> zero-fills $7000-$73FF (RAM workspace)
;   LD SP,$73C0          set stack pointer
;   LD BC,$0100 / CALL WRITE_REGISTER  VDP register 1 = $00 (display off)
;   CALL SUB_8413        FILL_VRAM $4000 bytes at $0000 (clear VRAM)
;   CALL MODE_1          set TMS9918 mode 1
;   LD BC,$0701 / CALL WRITE_REGISTER  VDP register 7 = $01 (border color)
;   CALL LOAD_ASCII      load BIOS font to VRAM
;   CALL DELAY_LOOP_827F (x2) copy sprite bitmaps from ROM to $7200/$7220
;   CALL SUB_AE00        VRAM data writer (POP HL trick -- inline data follows)
;     -> loads all tile patterns, sprite data, room layout to VRAM
; =============================================================================
START:
    LD      HL, WORK_BUFFER                 ; HL = $7000 (WORK_BUFFER -- start of RAM workspace)
    LD      BC, $03FF                       ; BC = $03FF (1023 bytes to zero-fill)
    LD      (HL), $00                       ; (HL) = $00 (seed byte for LDIR)
    PUSH    HL                              ; PUSH HL
    POP     DE                              ; POP DE  -> DE = $7001 (destination = next byte)
    INC     DE                              ; INC DE (DE now points one past HL)
    LDIR                                    ; LDIR: zero-fill $7000-$73FF (1024 bytes)
    LD      SP, $73C0                       ; SP = $73C0 (game stack pointer)
    LD      BC, $0100                       ; BC = $0100 (VDP reg 1, value $00)
    CALL    WRITE_REGISTER                  ; CALL WRITE_REGISTER: disable VDP display
    CALL    SUB_8413                        ; CALL SUB_8413: FILL_VRAM $4000 bytes at $0000 (clear all VRAM)
    CALL    MODE_1                          ; CALL MODE_1: set TMS9918 graphics mode 1
    LD      BC, $0701                       ; BC = $0701 (VDP reg 7, border colour $01)
    CALL    WRITE_REGISTER                  ; CALL WRITE_REGISTER: set border colour
    CALL    LOAD_ASCII                      ; CALL LOAD_ASCII: load BIOS font to VRAM
    LD      HL, $73C7                       ; RAM $73C7
    LD      (HL), $01                       ; LD (HL),$01: set PUT_VRAM active flag at $73C7
    LD      HL, $88C9                       ; LD HL,$88C9: source address for PUT_VRAM
    LD      DE, BOOT_UP                     ; LD DE,BOOT_UP: VRAM dest = $0000 (BOOT_UP)
    LD      IY, $0002                       ; LD IY,$0002: byte count = 2 for PUT_VRAM
    LD      A, $00                          ; LD A,$00: A = $00 (PUT_VRAM mode)
    CALL    PUT_VRAM                        ; CALL PUT_VRAM: write 2 bytes to VRAM $0000
    LD      HL, $73C7                       ; RAM $73C7
    LD      (HL), $00                       ; LD (HL),$00: clear PUT_VRAM active flag
    LD      A, $08                          ; LD A,$08: A = $08 (8 sprites)
    CALL    INIT_SPR_NM_TBL                 ; CALL INIT_SPR_NM_TBL: init 8-slot sprite name table
    LD      A, $08                          ; LD A,$08: A = $08 (8 sprite entries)
    CALL    WR_SPR_NM_TBL                   ; CALL WR_SPR_NM_TBL: write sprite name table to VRAM
    LD      DE, $7200                       ; DE = $7200 (sprite bitmap RAM destination, first set)
    LD      HL, $86C8                       ; HL = $86C8 (ROM source: first sprite bitmap block)
    CALL    DELAY_LOOP_827F                 ; CALL DELAY_LOOP_827F: copy 16 pairs AND $AA55 -> $7200
    LD      DE, $7220                       ; DE = $7220 (sprite bitmap RAM destination, second set)
    LD      HL, $86A8                       ; HL = $86A8 (ROM source: second sprite bitmap block)
    CALL    DELAY_LOOP_827F                 ; CALL DELAY_LOOP_827F: copy 16 pairs AND $AA55 -> $7220
    LD      A, $01                          ; A = $01 (block selector for inline VRAM data)
    CALL    SUB_AE00                        ; CALL SUB_AE00 ($01): POP HL trick -- inline data follows (bulk VRAM init)
    XOR     B                               ; inline data: SUB_AE00 $01 VRAM block 1 byte 0
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 1 byte 1
    INC     (HL)                            ; inline data: SUB_AE00 $01 VRAM block 1 byte 2
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 1 byte 3
    XOR     B                               ; inline data: SUB_AE00 $01 VRAM block 1 byte 4
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 1 byte 5
    JR      C, LOC_8090                     ; inline data: SUB_AE00 $01 VRAM block 1 byte 6
    XOR     B                               ; inline data: SUB_AE00 $01 VRAM block 1 byte 7
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 2 byte 2
    INC     A                               ; inline data: SUB_AE00 $01 VRAM block 2 byte 0
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 2 byte 3

LOC_8090:
    XOR     B                               ; inline data: SUB_AE00 $01 VRAM block 3 byte 0
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 3 byte 1

LOC_8092:
    LD      C, H                            ; inline data: SUB_AE00 $01 VRAM block 3 byte 2
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 4 byte 0
    DJNZ    LOC_801D                        ; inline data: SUB_AE00 $01 VRAM block 4 byte 1
    LD      C, L                            ; inline data: SUB_AE00 $01 VRAM block 4 byte 2
    LD      BC, $8718                       ; inline data: SUB_AE00 $01 VRAM block 4 byte 3
    LD      C, A                            ; inline data: SUB_AE00 $01 VRAM block 4 byte 4
    LD      BC, $8740                       ; inline data: SUB_AE00 $01 VRAM block 4 byte 5
    LD      D, H                            ; inline data: SUB_AE00 $01 VRAM block 4 byte 6
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 4 byte 7
    LD      B, B                            ; inline data: SUB_AE00 $01 VRAM block 5 byte 0
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 5 byte 1
    LD      E, H                            ; inline data: SUB_AE00 $01 VRAM block 5 byte 2
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 5 byte 3
    ADD     A, B                            ; inline data: SUB_AE00 $01 VRAM block 5 byte 4
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 5 byte 5
    LD      E, L                            ; inline data: SUB_AE00 $01 VRAM block 5 byte 6
    LD      BC, $8788                       ; inline data: SUB_AE00 $01 VRAM block 5 byte 7
    LD      E, A                            ; inline data: SUB_AE00 $01 VRAM block 6 byte 0
    LD      BC, $8740                       ; inline data: SUB_AE00 $01 VRAM block 6 byte 1
    LD      H, H                            ; inline data: SUB_AE00 $01 VRAM block 6 byte 2
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 6 byte 3
    LD      D, D                            ; inline data: SUB_AE00 $01 VRAM block 6 byte 4
    ADC     A, B                            ; inline data: SUB_AE00 $01 VRAM block 6 byte 5
    LD      L, B                            ; inline data: SUB_AE00 $01 VRAM block 6 byte 6
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 6 byte 7
    XOR     B                               ; inline data: SUB_AE00 $01 VRAM block 7 byte 0
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 7 byte 1
    LD      L, H                            ; inline data: SUB_AE00 $01 VRAM block 7 byte 2
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 7 byte 3
    RET     PE                              ; inline data: SUB_AE00 $01 VRAM block 7 byte 4
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 7 byte 5
    LD      L, L                            ; inline data: SUB_AE00 $01 VRAM block 8 byte 0
    LD      BC, $86F0                       ; inline data: SUB_AE00 $01 VRAM block 8 byte 1
    LD      L, A                            ; inline data: SUB_AE00 $01 VRAM block 8 byte 2
    LD      BC, $8872                       ; inline data: SUB_AE00 $01 VRAM block 8 byte 3
    LD      A, B                            ; inline data: SUB_AE00 $01 VRAM block 8 byte 4
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 8 byte 5
    RET     Z                               ; inline data: SUB_AE00 $01 VRAM block 8 byte 6
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 8 byte 7
    SBC     A, B                            ; inline data: SUB_AE00 $01 VRAM block 9 byte 0
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 9 byte 1
    RET     Z                               ; inline data: SUB_AE00 $01 VRAM block 9 byte 2
    ADD     A, (HL)                         ; inline data: SUB_AE00 $01 VRAM block 9 byte 3
    SBC     A, H                            ; inline data: SUB_AE00 $01 VRAM block 9 byte 4
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 9 byte 5
    LD      ($9D86), HL                     ; inline data: SUB_AE00 $01 VRAM block 10 byte 0
    LD      BC, $86F8                       ; inline data: SUB_AE00 $01 VRAM block 10 byte 1
    SBC     A, A                            ; inline data: SUB_AE00 $01 VRAM block 10 byte 2
    LD      BC, $86C8                       ; inline data: SUB_AE00 $01 VRAM block 10 byte 3
    AND     B                               ; inline data: SUB_AE00 $01 VRAM block 10 byte 4
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 10 byte 5
    NOP                                     ; inline data: SUB_AE00 $01 VRAM block 11 byte 0
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 11 byte 1
    AND     C                               ; inline data: SUB_AE00 $01 VRAM block 11 byte 2
    LD      BC, $8708                       ; inline data: SUB_AE00 $01 VRAM block 11 byte 3
    AND     E                               ; inline data: SUB_AE00 $01 VRAM block 11 byte 4
    LD      BC, $8720                       ; inline data: SUB_AE00 $01 VRAM block 11 byte 5
    OR      B                               ; inline data: SUB_AE00 $01 VRAM block 12 byte 0
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 12 byte 1
    LD      H, B                            ; inline data: SUB_AE00 $01 VRAM block 12 byte 2
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 12 byte 3
    CP      B                               ; inline data: SUB_AE00 $01 VRAM block 12 byte 4
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 12 byte 5
    SUB     B                               ; inline data: SUB_AE00 $01 VRAM block 12 byte 6
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 12 byte 7
    RET     NZ                              ; inline data: SUB_AE00 $01 VRAM block 13 byte 0
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 13 byte 1
    OR      B                               ; inline data: SUB_AE00 $01 VRAM block 13 byte 2
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 13 byte 3
    RET     Z                               ; inline data: SUB_AE00 $01 VRAM block 13 byte 4
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 13 byte 5
    RET     PE                              ; inline data: SUB_AE00 $01 VRAM block 13 byte 6
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 13 byte 7
    CALL    Z, $E804                        ; inline data: SUB_AE00 $01 VRAM block 14 byte 0
    ADD     A, A                            ; inline data: SUB_AE00 $01 VRAM block 14 byte 1
    RET     NC                              ; inline data: SUB_AE00 $01 VRAM block 14 byte 2
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 14 byte 3
    EX      AF, AF'                         ; inline data: SUB_AE00 $01 VRAM block 14 byte 4
    ADC     A, B                            ; inline data: SUB_AE00 $01 VRAM block 14 byte 5
    RET     NC                              ; inline data: SUB_AE00 $01 VRAM block 14 byte 6
    LD      BC, $8810                       ; inline data: SUB_AE00 $01 VRAM block 14 byte 7
    JP      NC, $0001                       ; inline data: SUB_AE00 $01 VRAM block 15 byte 0
    LD      (HL), D                         ; inline data: SUB_AE00 $01 VRAM block 15 byte 1
    CALL    NC, SUB_9208                    ; inline data: SUB_AE00 $01 VRAM block 15 byte 2
    ADC     A, B                            ; inline data: SUB_AE00 $01 VRAM block 15 byte 3
    INC     C                               ; inline data: SUB_AE00 $01 VRAM block 15 byte 4
    INC     B                               ; inline data: SUB_AE00 $01 VRAM block 15 byte 5
    JR      LOC_8092                        ; inline data: SUB_AE00 $01 VRAM block 15 end
    DB      $10, $04, $36, $88, $14, $04, $DA, $85 ; SUB_AE00 $01 tbl: entry [C=$10,cnt=4,vram=$88,str=$36]
    DB      $2C, $04, $00, $00, $CD, $D6, $1F, $CD ; SUB_AE00 $01 tbl: [C=$2C,cnt=4,END] terminator + inline Z80
    DB      $7F, $1F, $11, $41, $00, $21, $80, $00 ; SUB_AE00 $01 inline Z80: LD HL,$1F7F / LD DE,$0041 ...
    DB      $01, $1A, $00, $3E, $03, $CD, $73, $1F ; SUB_AE00 $01 inline Z80: LD HL,$0080 / LD BC,$001A ...
    DB      $CD, $08, $83, $3E, $A0, $21, $10, $20 ; SUB_AE00 $01 inline Z80: LD A,$03 / CALL $1F73 ...
    DB      $11, $0E, $00, $CD, $82, $1F, $3E, $02 ; SUB_AE00 $01 inline Z80: CALL $8308 / LD A,$A0 ...
    DB      $CD, $00, $AE, $AA, $82, $48, $10, $BA ; SUB_AE00 $01 inline Z80: LD HL,$2010 / LD DE,$000E ...
    DB      $82, $8C, $08, $DE, $82, $C6, $15, $F3 ; SUB_AE00 $01 inline Z80: CALL $1F82 / LD A,$02 ...
    DB      $82, $E6, $15, $00, $00, $21, $C2, $82 ; SUB_AE00 $01 inline Z80: CALL $AE00 -- nested VRAM write
    DB      $11, $2A, $01, $01, $0D, $01, $CD, $A7 ; SUB_AE00 $01 inline Z80: nested block entries (4 entries)
    DB      $AE, $21, $D0, $82, $11, $4A, $01, $01 ; SUB_AE00 $01 inline Z80: nested entries continued
    DB      $0D, $01, $CD, $A7, $AE, $21, $93, $82 ; SUB_AE00 $01 inline Z80: nested entries continued
    DB      $11, $E5, $01, $01, $17, $01, $CD, $A7 ; SUB_AE00 $01 inline Z80: LD HL,$82C2 / LD DE,$012A ...
    DB      $AE, $01, $C0, $01, $CD, $D9, $1F, $CD ; SUB_AE00 $01 inline Z80: CALL $AEA7 room-tile write block 1
    DB      $76, $1F, $3A, $F0, $73, $FE, $82, $20 ; SUB_AE00 $01 inline Z80: CALL $AEA7 room-tile write block 2
    DB      $04, $3E, $01, $18, $0E, $FE, $88, $20 ; SUB_AE00 $01 inline Z80: CALL $AEA7 room-tile write block 3
    DB      $04, $3E, $02, $18, $06, $FE, $83, $20 ; SUB_AE00 $01 inline Z80: CALL $AEA7 room-tile write block 4
    DB      $E6, $3E, $03, $32, $A6, $71, $01, $80 ; SUB_AE00 $01 inline Z80: CALL $81DC / LD A,$02 ...
    DB      $01, $CD, $D9, $1F, $AF, $21, $00, $04 ; SUB_AE00 $01 inline Z80: LD ($7073)/$7074/$7012/$7068 ...
    DB      $11, $AC, $03, $CD, $82, $1F, $AF, $21 ; SUB_AE00 $01 inline Z80: CALL $AE3B / CALL $8352 ...
    DB      $00, $18, $11, $00, $03, $CD, $82, $1F ; SUB_AE00 $01 inline Z80: clear $702C/$7036 / CALL $81DC
    DB      $CD, $DC, $81, $3E, $02, $32, $73, $70 ; SUB_AE00 $01 inline Z80: CALL $81DC / JP $A59D ...
    DB      $32, $74, $70, $32, $12, $70, $32, $68 ; SUB_AE00 $01 inline Z80: LD C,$01 / LD A,$08 / CALL $8392
    DB      $70, $21, $1A, $83, $CD, $3B, $AE, $CD ; SUB_AE00 $01 inline Z80: LD A,$03 / CALL $AE00 level-1 blk
    DB      $52, $83, $AF, $32, $2C, $70, $32, $36 ; SUB_AE00 $01 inline Z80: level-1 SUB_AE00 entries row 1
    DB      $70, $01, $E2, $01, $CD, $D9, $1F, $C3 ; SUB_AE00 $01 inline Z80: level-1 entries + terminator
    DB      $9D, $A5, $0E, $01, $3E, $08, $CD, $92 ; SUB_AE00 $01 inline Z80: CALL $8314 / LD C,$02 ...
    DB      $83, $3E, $03, $CD, $00, $AE, $10, $85 ; SUB_AE00 $01 inline Z80: LD A,$10 / CALL $8392 level-2
    DB      $D2, $04, $B1, $88, $D0, $01, $D0, $87 ; SUB_AE00 $01 inline Z80: LD A,$03 / CALL $AE00 level-2 blk
    DB      $38, $01, $30, $85, $04, $03, $00, $00 ; SUB_AE00 $01 inline Z80: level-2 SUB_AE00 entries row 1
    DB      $CD, $14, $83, $0E, $02, $3E, $10, $CD ; SUB_AE00 $01 inline Z80: level-2 entries continued
    DB      $92, $83, $3E, $03, $CD, $00, $AE, $18 ; SUB_AE00 $01 inline Z80: level-2 entries + terminator
    DB      $85, $D2, $03, $10, $85, $D5, $01, $B9 ; SUB_AE00 $01 inline Z80: CALL $8314 / LD C,$05 ...
    DB      $88, $D0, $01, $D8, $87, $38, $01, $46 ; SUB_AE00 $01 inline Z80: LD A,$28 / CALL $8392 level-3
    DB      $85, $04, $03, $70, $86, $A0, $01, $78 ; SUB_AE00 $01 inline Z80: LD A,$03 / CALL $AE00 level-3 blk
    DB      $86, $A3, $01, $00, $00, $CD, $14, $83 ; SUB_AE00 $01 inline Z80: level-3 SUB_AE00 entries row 1
    DB      $0E, $05, $3E, $28, $CD, $92, $83, $3E ; SUB_AE00 $01 inline Z80: level-3 entries continued
    DB      $03, $CD, $00, $AE, $20, $85, $D2, $02 ; SUB_AE00 $01 inline Z80: level-3 entries + terminator
    DB      $10, $85, $D4, $02, $B1, $88, $D0, $01 ; SUB_AE00 $01 inline Z80: CALL $8314 / LD C,$00 ...
    DB      $E0, $87, $38, $01, $5E, $85, $04, $03 ; SUB_AE00 $01 inline Z80: LD A,$03 / CALL $AE00 level-4 blk
    DB      $70, $86, $A0, $01, $78, $86, $A3, $01 ; SUB_AE00 $01 inline Z80: level-4 SUB_AE00 entries row 1
    DB      $00, $00, $CD, $14, $83, $0E, $00, $AF ; SUB_AE00 $01 inline Z80: level-4 entries continued
    DB      $CD, $92, $83, $CD, $08, $83, $3E, $03 ; SUB_AE00 $01 inline Z80: level-4 terminator + RET ($C9)
    DB      $CD, $00, $AE, $28, $85, $D2, $01, $10 ; SUB_AE00 $01 inline Z80: terminator + CALL $8314 tail
    DB      $85, $D3, $03, $C1, $88, $D0, $01, $E0 ; SUB_AE00 $01 inline Z80: level-4 entries continued
    DB      $87, $38, $01, $74, $85, $04, $03, $00 ; SUB_AE00 $01 inline Z80: level-4 terminator $00,$00 ...
    DB      $00, $CD, $14, $83, $C9         ; SUB_AE00 $01 inline Z80: CALL $8314 / RET $C9 (end)

DELAY_LOOP_827F:
    LD      B, $10                          ; B = 16 (loop 16 pairs)

LOC_8281:
    PUSH    BC                              ; save loop counter B
    LD      BC, $AA55                       ; BC = $AA55 (bitmask pair for sprite demultiplexing)
    LD      A, (HL)                         ; A = byte from ROM source
    AND     B                               ; AND B ($AA): keep odd-column bits
    LD      (DE), A                         ; store masked byte to RAM (first of pair)
    INC     DE                              ; INC DE: advance dest past first masked byte
    INC     HL                              ; advance ROM source pointer
    LD      A, (HL)                         ; A = next ROM byte
    AND     C                               ; AND C ($55): keep even-column bits
    LD      (DE), A                         ; store second masked byte to RAM
    INC     DE                              ; INC DE: advance dest past second masked byte
    INC     HL                              ; advance ROM source
    POP     BC                              ; restore loop counter B
    DJNZ    LOC_8281                        ; DJNZ LOC_8281: loop 16 times
    RET                                     ; RET
    DB      $53, $45, $4C, $45, $43, $54, $20, $4C ; "SELECT L"
    DB      $45, $56, $45, $4C, $20, $20, $20, $31 ; "EVEL   1"
    DB      $2C, $20, $32, $2C, $20, $33, $2E, $50 ; ", 2, 3.P"
    DB      $41, $52, $4B, $45, $52, $20, $42, $52 ; "ARKER BR"
    DB      $4F, $54, $48, $45, $52, $53, $20, $50 ; "OTHERS P"
    DB      $52, $45, $53, $45, $4E, $54, $53, $C4 ; inline text (post-RET): "PRESENTS" partial + tile IDs
    DB      $C6, $90, $92, $D4, $D6, $90, $92, $B4 ; inline tile IDs: title screen sprite tile indices row 1
    DB      $B6, $98, $9A, $90, $92, $C5, $C7, $91 ; inline tile IDs: title screen sprite tile indices row 2
    DB      $93, $D5, $D7, $91, $93, $B5, $B7, $99 ; inline tile IDs: title screen sprite tile indices row 3
    DB      $9B, $91, $93, $B0, $B2, $B8, $BA, $B4 ; inline tile IDs: title screen sprite tile indices row 4
    DB      $B6, $CC, $CE, $90, $92, $E4, $E6, $D0 ; inline tile IDs: title screen sprite tile indices row 5
    DB      $D2, $B0, $B2, $80, $82, $27, $C8, $CA ; inline tile IDs: title screen sprite tile indices row 6
    DB      $B1, $B3, $B9, $BB, $B5, $B7, $CD, $CF ; inline tile IDs: title screen sprite tile indices row 7
    DB      $91, $93, $E5, $E7, $D1, $D3, $B1, $B3 ; inline tile IDs: title screen sprite tile indices row 8
    DB      $81, $83, $00, $C9, $CB         ; inline tile IDs: terminator $00 + RET $C9 + extra byte

SUB_8308:
    LD      A, $04                          ; A = $04 (block selector for room tile data)
    CALL    SUB_AE00                        ; CALL SUB_AE00 ($04): POP HL trick -- write current room tiles to VRAM
    LD      E, $84                          ; inline data: SUB_AE00 $04 VRAM block byte 0
    NOP                                     ; inline data: SUB_AE00 $04 VRAM block byte 1
    INC     E                               ; inline data: SUB_AE00 $04 VRAM block byte 2
    NOP                                     ; inline data: SUB_AE00 $04 VRAM block byte 3
    NOP                                     ; inline data: SUB_AE00 $04 VRAM block byte 4
    RET                                     ; inline data: SUB_AE00 $04 VRAM block end (RET opcode)
    DB      $21, $7D, $83, $C3, $3B, $AE, $00, $01 ; SUB_AE00 $04 inline Z80: LD HL,$837D / JP $AE3B ...
    DB      $10, $19, $11, $18, $12, $1B, $13, $1A ; room tile index table: tile pairs rows 0-1
    DB      $0C, $1D, $0D, $1C, $0E, $1F, $0F, $1E ; room tile index table: tile pairs rows 2-3
    DB      $FF, $D4, $DE, $D8, $E2, $18, $22, $14 ; room tile index table: tile pairs rows 4-5 + sentinel $FF
    DB      $26, $10, $2A, $2C, $32, $34, $42, $4C ; room tile index table: LD HL,$832D / LD A,(HL) ...
    DB      $52, $54, $5A, $5C, $62, $98, $A6, $6C ; room tile index inline Z80: LD D,$00 / LD BC,$0002 ...
    DB      $7E, $9C, $AA, $A0, $AE, $A0, $AE, $B0 ; room tile index inline Z80: LD A,E / PUSH DE+HL+BC+AF ...
    DB      $B6, $B8, $BE, $C0, $C6, $FF, $21, $2D ; room tile index inline Z80: CALL $1F6A / POP AF+BC+HL+DE
    DB      $83, $7E, $FE, $FF, $C8, $16, $00, $01 ; room tile index inline Z80: INC DE (x2) / DEC HL (x2) ...
    DB      $02, $00, $5F, $23, $E5, $7E, $6F, $26 ; room tile index inline Z80: CALL $1F6A / POP HL / JR $18
    DB      $00, $3E, $01, $D5, $E5, $C5, $F5, $CD ; SUB_AE00 $03 block: [BC=$0103,A0,A4,A1,A5,A2,A6,A3,A7]
    DB      $6A, $1F, $F1, $C1, $E1, $D1, $13, $13 ; SUB_AE00 $03 block: [B8,$62,$63,D0,D1] + sentinel $FF ...
    DB      $2B, $2B, $CD, $6A, $1F, $E1, $23, $18 ; inline Z80: PUSH AF / LD B,$04 / CALL $1FD9 ...
    DB      $D8, $01, $03, $A0, $A4, $A1, $A5, $A2 ; inline Z80: CALL $1F7F / LD A,$03 / CALL $AE00
    DB      $A6, $A3, $A7, $04, $BA, $05, $B9, $06 ; SUB_AE00 $03 entries: [$40,$84,$08,$05] [$FA,$85,$90,$08]
    DB      $B8, $62, $63, $D0, $D1, $FF, $F5, $06 ; SUB_AE00 $03 entries: [$3A,$86,$60,$03] [$08,$85,$6F,$01]
    DB      $04, $CD, $D9, $1F, $F1, $32, $F9, $73 ; SUB_AE00 $03 entries: [$9C,$85,$6C,$02] [$2A,$86,$74,$02]
    DB      $CD, $7F, $1F, $3E, $03, $CD, $00, $AE ; SUB_AE00 $03 entries: [$8C,$85,$98,$04] [$02,$86,$68,$04]
    DB      $40, $84, $08, $05, $FA, $85, $90, $08 ; SUB_AE00 $03 entries: [$02,$86,$70,$04] [$02,$86,$78,$04]
    DB      $3A, $86, $60, $03, $08, $85, $6F, $01 ; SUB_AE00 $03 entries: [$50,$86,$A0,$04] [$3A,$86,$A8,$03]
    DB      $9C, $85, $6C, $02, $2A, $86, $74, $02 ; SUB_AE00 $03 entries: [$80,$86,$C0,$06] [$80,$86,$C7,$01]
    DB      $8C, $85, $98, $04, $02, $86, $68, $04 ; SUB_AE00 $03 entries: [$80,$86,$95,$01] [$80,$86,$B0,$05]
    DB      $02, $86, $70, $04, $02, $86, $78, $04 ; SUB_AE00 $03 entries: [$80,$86,$B7,$01] [$80,$86,$BB,$05]
    DB      $50, $86, $A0, $04, $3A, $86, $A8, $03 ; SUB_AE00 $03 entries: [$80,$86,$9C,$01] [$AC,$85,$10,$02]
    DB      $80, $86, $C0, $06, $80, $86, $C7, $01 ; SUB_AE00 $03 entries: [$AC,$85,$88,$02] [$68,$84,$18,$0A]
    DB      $80, $86, $95, $01, $80, $86, $B0, $05 ; SUB_AE00 $03 entries: [$B8,$84,$28,$0A] [$BC,$85,$E0,$01]
    DB      $80, $86, $B7, $01, $80, $86, $BB, $05 ; SUB_AE00 $03 entries: [$CA,$85,$E8,$01] terminator+RET $C9
    DB      $80, $86, $9C, $01, $AC, $85, $10, $02 ; SUB_AE00 $03 entries: terminator $00,$00 / RET $C9
    DB      $AC, $85, $88, $02, $68, $84, $18, $0A ; SUB_AE00 $03: inline Z80 continued after terminator
    DB      $B8, $84, $28, $0A, $BC, $85, $E0, $01 ; SUB_AE00 $03: inline Z80 continued
    DB      $CA, $85, $E8, $01, $00, $00, $C9 ; SUB_AE00 $03: inline Z80 tail bytes

SUB_840B:
    LD      (HL), $00                       ; (HL) = $00 (seed first byte)
    PUSH    HL                              ; PUSH HL (save base pointer)
    POP     DE                              ; POP DE (DE = HL -- copy source addr)
    INC     DE                              ; INC DE (DE = HL+1, destination one byte ahead)
    LDIR                                    ; LDIR: fill BC bytes with $00 by propagating the seed
    RET                                     ; RET: return from SUB_840B

SUB_8413:
    LD      HL, BOOT_UP                     ; HL = $0000 (BOOT_UP = VRAM start address)
    LD      DE, $4000                       ; DE = $4000 (length: entire 16 KB VRAM)
    XOR     A                               ; A = $00 (fill value: blank)
    CALL    FILL_VRAM                       ; CALL FILL_VRAM: clear all VRAM
    RET                                     ; RET: return from SUB_8413
    DB      $90, $A7, $4A, $8B, $B1, $F0, $F0, $F0 ; sprite bitmap data: player/enemy tiles, row 0-7 (start)
    DB      $F0, $F0, $F0, $F0, $20, $90, $E0, $40 ; sprite bitmap data: continued row 8-15
    DB      $40, $40, $E0, $90, $20, $20, $40, $90 ; sprite bitmap data: continued row 16-23
    DB      $E0, $4A, $90, $60, $40, $40, $00, $00 ; sprite bitmap data: continued row 24-31
    DB      $00, $00, $FB, $FB, $FB, $00, $7F, $7F ; sprite bitmap data: continued row 32-39
    DB      $7F, $00, $FB, $FB, $FB, $00, $00, $00 ; sprite bitmap data: continued row 40-47
    DB      $00, $00, $F0, $F0, $F0, $00, $F0, $F0 ; sprite bitmap data: continued row 48-55
    DB      $F0, $00, $0B, $0B, $0B, $00, $0F, $0F ; sprite bitmap data: continued row 56-63
    DB      $0F, $00, $00, $00, $00, $00, $7F, $7F ; sprite bitmap data: continued row 64-71
    DB      $7F, $00, $38, $7C, $FE, $FE, $EE, $C6 ; sprite bitmap data: continued row 72-79
    DB      $C6, $C6, $38, $78, $F8, $F8, $F8, $F8 ; sprite bitmap data: continued row 80-87
    DB      $38, $38, $38, $7C, $FE, $FE, $EE, $C6 ; sprite bitmap data: continued row 88-95
    DB      $C6, $0E, $38, $7C, $FE, $FE, $FE, $C6 ; sprite bitmap data: continued row 96-103
    DB      $06, $1C, $1C, $3C, $3C, $7C, $7C, $EC ; sprite bitmap data: continued row 104-111
    DB      $EC, $CC, $FE, $FE, $FE, $FE, $C6, $E0 ; sprite bitmap data: continued row 112-119
    DB      $F8, $3E, $38, $7C, $FE, $FE, $EE, $C0 ; sprite bitmap data: continued row 120-127
    DB      $F8, $FC, $FE, $FE, $FE, $FE, $FE, $0E ; sprite bitmap data: continued row 128-135
    DB      $0E, $1E, $38, $7C, $FE, $FE, $EE, $C6 ; sprite bitmap data: continued row 136-143
    DB      $EE, $7C, $38, $7C, $FE, $FE, $EE, $C6 ; sprite bitmap data: continued row 144-151
    DB      $EE, $7E, $EE, $FE, $FE, $FE, $FE, $FE ; sprite bitmap data: continued row 152-159
    DB      $7C, $38, $38, $38, $38, $38, $FE, $FE ; sprite bitmap data: continued row 160-167
    DB      $FE, $FE, $1E, $3C, $78, $70, $FE, $FE ; sprite bitmap data: continued row 168-175
    DB      $FE, $FE, $1C, $06, $C6, $EE, $FE, $FE ; sprite bitmap data: continued row 176-183
    DB      $7C, $38, $CC, $FE, $FE, $FE, $FE, $FE ; sprite bitmap data: continued row 184-191
    DB      $18, $18, $0E, $C6, $C6, $EE, $FE, $FE ; sprite bitmap data: continued row 192-199
    DB      $7C, $38, $EE, $C6, $EE, $FE, $FE, $FE ; sprite bitmap data: continued row 200-207
    DB      $7C, $38, $1E, $1C, $3C, $38, $78, $78 ; sprite bitmap data: continued row 208-215
    DB      $70, $70, $EE, $C6, $EE, $FE, $FE, $FE ; sprite bitmap data: continued row 216-223
    DB      $7C, $38, $3E, $06, $C6, $EE, $FE, $FE ; sprite bitmap data: continued row 224-231
    DB      $7C, $38, $00, $00, $3C, $3C, $7E, $7E ; sprite bitmap data: continued row 232-239
    DB      $00, $00, $08, $06, $07, $07, $0F, $1F ; sprite bitmap data: continued row 240-247
    DB      $7F, $FF, $00, $00, $24, $33, $71, $FD ; sprite bitmap data: continued row 248-255
    DB      $FF, $FF, $00, $00, $01, $81, $F1, $F9 ; sprite bitmap data: continued row 256-263
    DB      $FB, $FF, $00, $80, $00, $81, $C2, $E6 ; sprite bitmap data: continued row 264-271
    DB      $EF, $FF, $C0, $C0, $3F, $3F, $3F, $3F ; sprite bitmap data: continued row 272-279
    DB      $03, $03, $C0, $C0, $FF, $FF, $FF, $FF ; sprite bitmap data: continued row 280-287
    DB      $03, $03, $C0, $C0, $FC, $FC, $FC, $FC ; sprite bitmap data: continued row 288-295
    DB      $03, $03, $3F, $FF, $FF, $3F, $00, $00 ; sprite bitmap data: continued row 296-303
    DB      $03, $03, $FF, $FF, $FF, $FF, $C0, $C0 ; sprite bitmap data: continued row 304-311
    DB      $00, $00, $FC, $FF, $FF, $FC, $C0, $C0 ; sprite bitmap data: continued row 312-319
    DB      $0C, $0C, $3F, $3F, $3F, $3F, $C0, $C0 ; sprite bitmap data: continued row 320-327
    DB      $0C, $0C, $FF, $FF, $FF, $FF, $30, $30 ; sprite bitmap data: continued row 328-335
    DB      $03, $03, $FC, $FC, $FC, $FC, $30, $30 ; sprite bitmap data: continued row 336-343
    DB      $3F, $3F, $3F, $3F, $0C, $0C, $30, $30 ; sprite bitmap data: continued row 344-351
    DB      $FF, $FF, $FF, $FF, $0C, $0C, $30, $30 ; sprite bitmap data: continued row 352-359
    DB      $FC, $FC, $FC, $FC, $0C, $0C, $00, $7E ; sprite bitmap data: continued row 360-367
    DB      $81, $BD, $BD, $BD, $BD, $BD, $BD, $BD ; sprite bitmap data: continued row 368-375
    DB      $BD, $81, $7E, $00, $00, $00, $03, $03 ; sprite bitmap data: continued row 376-383
    DB      $0F, $0F, $03, $03, $03, $00, $80, $80 ; sprite bitmap data: continued row 384-391
    DB      $E0, $E0, $80, $80, $80, $00, $30, $30 ; sprite bitmap data: continued row 392-399
    DB      $30, $30, $3F, $30, $30, $30, $0C, $0C ; sprite bitmap data: continued row 400-407
    DB      $0C, $0C, $FC, $0C, $0C, $0C, $7C, $6C ; sprite bitmap data: continued row 408-415
    DB      $6C, $6C, $6C, $7C, $10, $10, $7C, $6C ; sprite bitmap data: continued row 416-423
    DB      $6C, $6C, $6C, $7C, $FF, $66, $C3, $66 ; sprite bitmap data: continued row 424-431
    DB      $FF, $00, $00, $00, $FF, $66, $18, $66 ; sprite bitmap data: continued row 432-439
    DB      $FF, $00, $00, $00, $00, $00, $00, $00 ; sprite bitmap data: continued row 440-447
    DB      $00, $00, $00, $08, $14, $23, $09, $17 ; sprite bitmap data: continued row 448-455
    DB      $23, $0B, $17, $21, $00, $00, $00, $00 ; sprite bitmap data: continued row 456-463
    DB      $00, $10, $28, $44, $90, $A8, $C4, $D0 ; sprite bitmap data: continued row 464-471
    DB      $E8, $C4, $C0, $80, $18, $18, $18, $18 ; sprite bitmap data: continued row 472-479
    DB      $0C, $0C, $0C, $0C, $07, $0F, $1C, $1C ; sprite bitmap data: continued row 480-487
    DB      $0F, $03, $03, $01, $E0, $F0, $38, $38 ; sprite bitmap data: continued row 488-495
    DB      $F0, $C0, $C0, $80, $01, $01, $03, $01 ; sprite bitmap data: continued row 496-503
    DB      $03, $01, $00, $00, $80, $80, $80, $80 ; sprite bitmap data: continued row 504-511
    DB      $80, $80, $00, $00, $3C, $1C, $00, $00 ; sprite bitmap data: continued row 512-519
    DB      $00, $38, $3C, $3C, $02, $03, $03, $03 ; sprite bitmap data: continued row 520-527
    DB      $03, $03, $03, $03, $00, $00, $80, $80 ; sprite bitmap data: continued row 528-535
    DB      $80, $80, $80, $80, $00, $2D, $3F, $3F ; sprite bitmap data: continued row 536-543
    DB      $2D, $0C, $0C, $0C, $0C, $0C, $0C, $0C ; sprite bitmap data: continued row 544-551
    DB      $0C, $00, $00, $00, $1F, $0F, $03, $03 ; sprite bitmap data: continued row 552-559
    DB      $03, $01, $00, $00, $00, $03, $0C, $0F ; sprite bitmap data: continued row 560-567
    DB      $00, $00, $00, $00, $00, $C0, $E0, $F0 ; sprite bitmap data: continued row 568-575
    DB      $30, $F0, $07, $1E, $18, $18, $18, $0C ; sprite bitmap data: continued row 576-583
    DB      $06, $03, $C0, $00, $00, $00, $01, $03 ; sprite bitmap data: continued row 584-591
    DB      $0E, $FC, $00, $00, $00, $03, $0C, $3F ; sprite bitmap data: continued row 592-599
    DB      $00, $00, $C0, $00, $00, $00, $04, $0C ; sprite bitmap data: continued row 600-607
    DB      $0C, $FC, $7E, $7E, $7E, $7E, $7E, $7E ; sprite bitmap data: continued row 608-615
    DB      $7E, $7E, $00, $07, $0F, $09, $29, $6F ; sprite bitmap data: continued row 616-623
    DB      $E9, $E9, $00, $E0, $E0, $28, $2C, $EE ; sprite bitmap data: continued row 624-631
    DB      $2F, $2F, $EF, $EF, $EF, $EF, $EF, $EF ; sprite bitmap data: continued row 632-639
    DB      $EF, $EF, $FF, $FF, $7E, $7E, $3C, $3C ; sprite bitmap data: continued row 640-647
    DB      $3C, $3C, $07, $07, $1F, $3F, $38, $08 ; sprite bitmap data: continued row 648-655
    DB      $00, $1F, $3F, $0F, $07, $03, $33, $3F ; sprite bitmap data: continued row 656-663
    DB      $3C, $38, $C0, $C0, $F8, $F8, $80, $00 ; sprite bitmap data: continued row 664-671
    DB      $00, $E0, $C0, $C0, $C0, $C0, $E0, $E0 ; sprite bitmap data: continued row 672-679
    DB      $E0, $E0, $00, $07, $07, $07, $00, $00 ; sprite bitmap data: continued row 680-687
    DB      $30, $38, $3C, $1C, $00, $00, $00, $38 ; sprite bitmap data: continued row 688-695
    DB      $3C, $1C, $00, $60, $E0, $C0, $00, $B0 ; sprite bitmap data: continued row 696-703
    DB      $30, $BC, $3C, $80, $00, $00, $00, $E0 ; sprite bitmap data: continued row 704-711
    DB      $F0, $F0, $3F, $0F, $07, $03, $33, $3F ; sprite bitmap data: continued row 712-719
    DB      $07, $07, $C0, $C0, $C0, $C0, $E0, $E0 ; sprite bitmap data: continued row 720-727
    DB      $00, $00, $3C, $80, $00, $00, $18, $F8 ; sprite bitmap data: continued row 728-735
    DB      $E0, $00, $3C, $1C, $00, $00, $00, $07 ; sprite bitmap data: continued row 736-743
    DB      $07, $07, $3C, $80, $00, $00, $00, $00 ; sprite bitmap data: continued row 744-751
    DB      $80, $80, $07, $0F, $0F, $3F, $3F, $1F ; sprite bitmap data: continued row 752-759
    DB      $0F, $0F, $C0, $C0, $C0, $E0, $E0, $F0 ; sprite bitmap data: continued row 760-767
    DB      $70, $70, $00, $07, $07, $27, $70, $78 ; sprite bitmap data: continued row 768-775
    DB      $70, $30, $00, $00, $00, $00, $00, $0F ; sprite bitmap data: continued row 776-783
    DB      $0F, $0F, $00, $60, $E0, $C0, $0C, $3C ; sprite bitmap data: continued row 784-791
    DB      $3C, $B8, $00, $86, $0E, $0E, $0C, $00 ; sprite bitmap data: continued row 792-799
    DB      $80, $80, $03, $03, $1F, $1F, $0F, $03 ; sprite bitmap data: continued row 800-807
    DB      $02, $01, $39, $3F, $3F, $0F, $0F, $0F ; sprite bitmap data: continued row 808-815
    DB      $0F, $0F, $C0, $C0, $F8, $F8, $F0, $C0 ; sprite bitmap data: continued row 816-823
    DB      $40, $80, $98, $FC, $FC, $F0, $F0, $F0 ; sprite bitmap data: continued row 824-831
    DB      $F0, $F0, $00, $00, $30, $39, $36, $06 ; sprite bitmap data: continued row 832-839
    DB      $01, $00, $00, $00, $00, $00, $00, $0E ; sprite bitmap data: continued row 840-847
    DB      $00, $00, $00, $00, $00, $80, $60, $60 ; sprite bitmap data: continued row 848-855
    DB      $80, $00, $0C, $0C, $00, $00, $00, $60 ; sprite bitmap data: continued row 856-863
    DB      $70, $70, $1A, $1F, $1F, $0F, $0F, $07 ; sprite bitmap data: continued row 864-871
    DB      $01, $00, $40, $FC, $FC, $FC, $FC, $FC ; sprite bitmap data: continued row 872-879
    DB      $F0, $F0, $00, $00, $00, $01, $1A, $01 ; sprite bitmap data: continued row 880-887
    DB      $00, $00, $00, $00, $00, $06, $03, $03 ; sprite bitmap data: continued row 888-895
    DB      $00, $00, $00, $00, $00, $80, $40, $98 ; sprite bitmap data: continued row 896-903
    DB      $00, $00, $00, $00, $00, $00, $00, $60 ; sprite bitmap data: continued row 904-911
    DB      $E0, $80, $00, $00, $00, $01, $06, $06 ; sprite bitmap data: continued row 912-919
    DB      $01, $00, $00, $00, $00, $00, $34, $3E ; sprite bitmap data: continued row 920-927
    DB      $1E, $0C, $00, $00, $00, $80, $60, $60 ; sprite bitmap data: continued row 928-935
    DB      $80, $00, $00, $00, $00, $00, $2C, $7C ; sprite bitmap data: continued row 936-943
    DB      $78, $30, $00, $10, $08, $20, $14, $22 ; sprite bitmap data: continued row 944-951
    DB      $08, $42, $00, $00, $24, $10, $28, $08 ; sprite bitmap data: continued row 952-959
    DB      $10, $2C, $00, $10, $2C, $30, $3C, $2A ; sprite bitmap data: continued row 960-967
    DB      $18, $6E, $00, $0C, $3C, $78, $70, $60 ; sprite bitmap data: continued row 968-975
    DB      $60, $7E, $00, $00, $00, $03, $04, $0B ; sprite bitmap data: continued row 976-983
    DB      $10, $1F, $00, $00, $00, $78, $78, $60 ; sprite bitmap data: continued row 984-991
    DB      $60, $60, $60, $00, $00, $00, $80, $40 ; sprite bitmap data: continued row 992-999
    DB      $20, $F8, $78, $78, $78, $18, $18, $18 ; sprite bitmap data: continued row 1000-1007
    DB      $1E, $06, $00, $00, $00, $00, $1C, $1C ; sprite bitmap data: continued row 1008-1015
    DB      $7C, $60, $00, $0F, $1F, $3F, $7E, $7E ; sprite bitmap data: continued row 1016-1023
    DB      $7F, $73, $37, $1F, $0F, $03, $00, $00 ; sprite bitmap data: continued row 1024-1031
    DB      $00, $00, $00, $00, $80, $C0, $60, $E0 ; sprite bitmap data: continued row 1032-1039
    DB      $F0, $F0, $CC, $CC, $3C, $3C, $F8, $F0 ; sprite bitmap data: continued row 1040-1047
    DB      $00, $00, $00, $00, $1E, $3B, $73, $F3 ; sprite bitmap data: continued row 1048-1055
    DB      $FF, $FF, $F3, $73, $3B, $1E, $00, $00 ; sprite bitmap data: continued row 1056-1063
    DB      $00, $00, $00, $00, $00, $00, $B8, $18 ; sprite bitmap data: continued row 1064-1071
    DB      $B8, $B8, $18, $B8, $00, $00, $00, $00 ; sprite bitmap data: continued row 1072-1079
    DB      $00, $0E, $1F, $1F, $3C, $3B, $34, $2F ; sprite bitmap data: continued row 1080-1087
    DB      $00, $3C, $3F, $07, $00, $00, $00, $00 ; sprite bitmap data: continued row 1088-1095
    DB      $00, $00, $C0, $F8, $F8, $78, $A0, $D8 ; sprite bitmap data: continued row 1096-1103
    DB      $00, $F8, $F8, $E0, $07, $1F, $7F, $FF ; sprite bitmap data: continued row 1104-1111
    DB      $FF, $7F, $3F, $FF, $FF, $7F, $3E, $3C ; sprite bitmap data: continued row 1112-1119
    DB      $18, $00, $00, $00, $E0, $F8, $FC, $FF ; sprite bitmap data: continued row 1120-1127
    DB      $FF, $FE, $FF, $FF, $FE, $64, $30, $30 ; sprite bitmap data: continued row 1128-1135
    DB      $60, $C0, $C0, $60, $00, $03, $07, $0F ; sprite bitmap data: continued row 1136-1143
    DB      $1F, $19, $11, $1F, $0F, $0F, $05, $00 ; sprite bitmap data: continued row 1144-1151
    DB      $05, $07, $07, $00, $00, $C0, $E0, $F0 ; sprite bitmap data: continued row 1152-1159
    DB      $F8, $98, $88, $F8, $F0, $F0, $A0, $00 ; sprite bitmap data: last rows + game logic Z80 start
    DB      $A0, $E0, $E0, $00, $01, $01, $03, $07 ; inline Z80: game main loop start / CALL $92DC ...
    DB      $0F, $0F, $1F, $00, $00, $00, $03, $07 ; inline Z80: LD A,$03 / LD ($70AB) / CALL $A7A1 ...
    DB      $07, $0F, $1F, $00, $04, $03, $07, $07 ; inline Z80: CALL $8C1F / LD A,($705F) ...
    DB      $0F, $1F, $1F, $18, $0C, $04, $06, $1B ; inline Z80: BIT 0,($705F) / JR Z / LD A,($7301) ...
    DB      $0C, $08, $0B, $CD, $DC, $92, $3A, $AB ; inline Z80: CALL $918C / LD HL,$8913 ...
    DB      $70, $3D, $F2, $DD, $88, $3E, $03, $32 ; inline Z80: LD A,($7079) / RLCA / CALL $405A ...
    DB      $AB, $70, $CD, $A1, $A7, $CD, $1F, $8C ; inline Z80: LD HL,$8921 / LD A,($7079) / RLCA ...
    DB      $3A, $5F, $70, $CB, $57, $28, $0E, $3A ; inline Z80: CALL $A540 / LD E,(HL) / LD D,H / CALL $AE3A
    DB      $01, $73, $FE, $80, $3E, $86, $38, $02 ; inline Z80: JP $8DE8 -- tail to main game loop
    DB      $3E, $8C, $32, $EE, $73, $CD, $56, $91 ; game object handler table: entries $88 (lo/hi pairs)
    DB      $21, $13, $89, $3A, $79, $70, $CB, $27 ; game object handler table: entries continued
    DB      $CD, $40, $A5, $5E, $23, $56, $EB, $CD ; inline Z80: LD A,($705B) / CP $08 / JR NZ ...
    DB      $3A, $AE, $C3, $E8, $8D, $29, $89, $29 ; inline Z80: LD A,($7058) / CP $08 / JR NZ ...
    DB      $89, $2F, $8A, $59, $8C, $02, $8D, $83 ; inline Z80: LD BC,$F800 / LD A,($7057) ...
    DB      $8A, $83, $8A, $C5, $8C, $7F, $8B, $8E ; inline Z80: JR NZ / LD B,$08 / JP $8DD4 ...
    DB      $8B, $6E, $8B, $3A, $5B, $70, $FE, $08 ; inline Z80: LD A,($7057) / CALL $913B ...
    DB      $20, $16, $3A, $58, $70, $FE, $08, $20 ; inline Z80: JP $8A91 / LD A,($7373) / AND $0F ...
    DB      $0F, $01, $00, $F8, $3A, $57, $70, $FE ; inline Z80: CALL $8C44 / XOR A / LD ($7077) ...
    DB      $00, $28, $02, $06, $08, $C3, $D4, $8D ; inline Z80: AND $01 / JR Z / LD HL,($7058) ...
    DB      $3A, $57, $70, $CD, $3B, $91, $20, $03 ; inline Z80: JR NZ / LD A,(HL) / CP $88 ...
    DB      $C3, $91, $8A, $3A, $EE, $73, $E6, $0F ; inline Z80: JR NZ / CALL $8B20 / LD C,$FC / JR ...
    DB      $CD, $44, $8C, $AF, $32, $77, $70, $01 ; inline Z80: CALL $8B20 / LD C,$02 / LD A,$08 ...
    DB      $00, $00, $3A, $EE, $73, $E6, $01, $28 ; inline Z80: LD A,$03 / PUSH AF / LD A,B ...
    DB      $43, $21, $58, $70, $7E, $23, $FE, $88 ; inline Z80: LD ($7078) / POP AF / LD ($7079) ...
    DB      $20, $3A, $7E, $FE, $89, $20, $35, $CD ; inline Z80: LD A,($7079) / CP $02 / JR NZ ...
    DB      $20, $8B, $0E, $FC, $18, $0A, $CD, $20 ; inline Z80: LD A,($70AB) / AND $01 / CP $01 ...
    DB      $8B, $0E, $02, $3E, $08, $32, $B2, $70 ; inline Z80: CALL $8F37 / LD HL,($7076) / LD (HL),B ...
    DB      $3E, $03, $F5, $78, $FE, $00, $28, $03 ; inline Z80: RET / LD A,($7373) / AND $04 ...
    DB      $32, $78, $70, $F1, $32, $79, $70, $FE ; inline Z80: JR NZ / LD HL,($705B) ...
    DB      $02, $28, $0A, $3A, $AB, $70, $E6, $01 ; inline Z80: CP $11 / JR Z / CP $C4 / JR NZ ...
    DB      $FE, $01, $C4, $37, $8F, $21, $76, $70 ; inline Z80: CALL $8B27 / CALL $8C53 ...
    DB      $70, $23, $71, $C9, $3A, $EE, $73, $E6 ; inline Z80: CALL $8C53 / LD A,$04 / JR ...
    DB      $04, $28, $1C, $21, $5B, $70, $7E, $23 ; inline Z80: AND $08 / JR Z / LD BC,$00FE ...
    DB      $FE, $10, $20, $05, $7E, $FE, $11, $28 ; inline Z80: CALL $90E3 / JR NC / LD A,$07 ...
    DB      $BD, $FE, $C4, $20, $0A, $CD, $27, $8B ; inline Z80: CALL $AC1A / LD A,($7300) ...
    DB      $CD, $53, $8C, $3E, $04, $18, $26, $3A ; inline Z80: LD A,$12 / LD ($7072) / LD HL,$93AE ...
    DB      $EE, $73, $E6, $08, $28, $37, $01, $00 ; inline Z80: LD C,$FF / LD A,$02 / JP $8988 ...
    DB      $FE, $CD, $E3, $90, $30, $1A, $3E, $07 ; inline Z80: PUSH BC / CALL $911E / POP BC / JR C ...
    DB      $CD, $1A, $AC, $3A, $00, $73, $32, $7C ; inline Z80: JR $8A91 / LD A,($7300) ...
    DB      $70, $3E, $12, $32, $72, $70, $21, $AE ; inline Z80: LD A,$06 / JR ...
    DB      $93, $0E, $FF, $3E, $02, $C3, $88, $89 ; inline Z80: AND $02 / JR Z / LD BC,$0200 ...
    DB      $C5, $CD, $1E, $91, $C1, $38, $04, $3E ; inline Z80: CALL $90E3 / JR NC / PUSH BC ...
    DB      $01, $18, $F2, $3A, $00, $73, $32, $7C ; inline Z80: CALL $911E / POP BC / JP NC ...
    DB      $70, $3E, $06, $18, $F4, $3A, $EE, $73 ; inline Z80: JP $8A01 / LD D,$04 ...
    DB      $E6, $02, $28, $0A, $01, $00, $02, $CD ; inline Z80: LD A,($7072) / CP $00 / JR Z ...
    DB      $E3, $90, $38, $C2, $18, $DA, $01, $00 ; inline Z80: DEC (HL) / LD A,(HL) / LD HL,$93AE ...
    DB      $00, $CD, $E3, $90, $38, $B8, $C5, $CD ; inline Z80: CALL $A540 / LD A,($7076) / CP $90 ...
    DB      $1E, $91, $C1, $D2, $2F, $8C, $C3, $01 ; inline Z80: CP $95 / JR NZ / LD A,($705B) ...
    DB      $8A, $16, $04, $21, $72, $70, $7E, $FE ; inline Z80: CP $08 / JR Z / CP $08 ...
    DB      $00, $28, $09, $35, $7E, $21, $AE, $93 ; inline Z80: CB $7F / LD A,($7059) / JR NZ ...
    DB      $CD, $40, $A5, $56, $3A, $76, $70, $FE ; inline Z80: LD A,($7076) / CB $7F / LD A,($7077) ...
    DB      $00, $28, $03, $32, $78, $70, $47, $4A ; inline Z80: AND $08 / RES ...
    DB      $3A, $58, $70, $FE, $90, $CA, $0E, $8B ; inline Z80: LD C,$FF / XOR A / LD ($7076) ...
    DB      $FE, $95, $20, $0A, $3A, $5B, $70, $FE ; inline Z80: CB $7F / JP NZ / LD BC,$0000 ...
    DB      $08, $28, $03, $C3, $5B, $8B, $3A, $76 ; inline Z80: CALL $911E / POP BC / JR NC ...
    DB      $70, $CB, $7F, $3A, $59, $70, $20, $03 ; inline Z80: CP $D2 / JR NZ / LD A,$05 ...
    DB      $3A, $57, $70, $FE, $08, $20, $04, $AF ; inline Z80: CALL $AC1A / LD A,$0A / JR ...
    DB      $32, $76, $70, $3A, $77, $70, $CB, $7F ; inline Z80: LD C,$00 / LD A,($7300) ...
    DB      $C2, $39, $8C, $18, $03, $01, $04, $00 ; inline Z80: AND $0F / CP $04 / JR Z / CP $0C ...
    DB      $C5, $CD, $1E, $91, $C1, $38, $79, $FE ; inline Z80: DEC A / DEC C / JR / PUSH BC ...
    DB      $D2, $20, $09, $3E, $05, $CD, $1A, $AC ; inline Z80: CALL $AC1A / LD A,($71A8) ...
    DB      $3E, $0A, $18, $56, $0E, $00, $3A, $00 ; inline Z80: CP $0A / JR NZ / LD A,($705F) ...
    DB      $73, $E6, $0F, $FE, $04, $28, $08, $FE ; inline Z80: BIT 0 / JR Z / RES 2 / LD ($705F) ...
    DB      $0C, $28, $04, $3D, $0D, $18, $F2, $C5 ; inline Z80: LD A,($707C) / LD B,A / LD A,($7300) ...
    DB      $3E, $04, $CD, $1A, $AC, $3A, $A8, $71 ; inline Z80: JR NC / NEG / POP BC / CP $1C ...
    DB      $FE, $0A, $20, $0F, $3A, $5F, $70, $CB ; inline Z80: JR Z / LD A,($7079) / CP $05 / JR Z ...
    DB      $57, $28, $08, $CB, $97, $32, $5F, $70 ; inline Z80: LD B,A / LD A,($7304) / LD ($7300) ...
    DB      $CD, $7E, $8E, $3A, $7C, $70, $47, $3A ; inline Z80: LD ($7304) / LD A,$09 / PUSH AF ...
    DB      $00, $73, $B8, $38, $2D, $90, $C1, $FE ; inline Z80: CALL $8DC2 / LD A,$70 / LD ($70A9) ...
    DB      $1C, $38, $28, $3A, $79, $70, $FE, $05 ; inline Z80: LD BC,$0000 / JP $8988 ...
    DB      $28, $21, $3A, $00, $73, $47, $3A, $04 ; inline Z80: LD A,$01 / JP $8992 ...
    DB      $73, $32, $00, $73, $78, $32, $04, $73 ; inline Z80: LD A,($705B) / CP $90 / JP NZ ...
    DB      $3E, $09, $F5, $CD, $C2, $8D, $3E, $70 ; inline Z80: CALL $8B44 / PUSH BC / CALL $8B27 ...
    DB      $32, $A9, $70, $F1, $01, $00, $00, $C3 ; inline Z80: LD A,($705B) / JR NC / LD A,$04 ...
    DB      $88, $89, $C1, $3E, $01, $C3, $92, $89 ; inline Z80: JP $8C31 / PUSH HL / LD C,$0F ...
    DB      $3A, $5B, $70, $FE, $90, $C2, $57, $8B ; inline Z80: LD E,$07 / JR / PUSH HL / LD C,$0C ...
    DB      $CD, $44, $8B, $C5, $CD, $27, $8B, $C1 ; inline Z80: LD HL,($7301) / AND $0F / CP $08 ...
    DB      $3A, $5B, $70, $30, $3C, $3E, $04, $C3 ; inline Z80: LD C,A / AND $F0 / ADD A,B / LD (HL) ...
    DB      $31, $8C, $E5, $0E, $0F, $1E, $07, $18 ; inline Z80: INC HL (x4) / LD (HL),A / POP HL ...
    DB      $05, $E5, $0E, $0C, $1E, $04, $21, $01 ; inline Z80: LD A,($7076) / CP $00 / JR Z ...
    DB      $73, $7E, $E6, $0F, $FE, $08, $30, $01 ; inline Z80: CP $0F / JR NC / POP AF / JP $8C39 ...
    DB      $4B, $7E, $E6, $F0, $81, $77, $23, $23 ; inline Z80: CP $95 / JR NZ / CALL $8B44 ...
    DB      $23, $23, $77, $E1, $37, $C9, $3A, $76 ; inline Z80: CALL $8B27 / LD BC,$0400 / LD A,$06 ...
    DB      $70, $FE, $00, $28, $08, $3A, $72, $70 ; inline Z80: CALL $AC1A / LD A,$05 / JP $8C3C ...
    DB      $FE, $0F, $30, $01, $C9, $F1, $C3, $39 ; inline Z80: LD HL,$7300 / DEC (HL) / INC HL ...
    DB      $8C, $FE, $95, $20, $F9, $CD, $44, $8B ; inline Z80: INC HL / LD (HL),$0E / XOR A ...
    DB      $CD, $27, $8B, $01, $04, $00, $3E, $06 ; inline Z80: LD A,($70A9) / BIT 0 / JR NZ ...
    DB      $CD, $1A, $AC, $3E, $05, $C3, $3C, $8C ; inline Z80: AND $03 / LD HL,$93A6 / CALL $9305 ...
    DB      $21, $00, $73, $35, $23, $23, $36, $78 ; inline Z80: LD HL,($70A9) / DEC (HL) ...
    DB      $23, $36, $0E, $AF, $32, $07, $73, $18 ; inline Z80: LD HL,($7049) / CP $00 / JR NZ ...
    DB      $0F, $3A, $A9, $70, $CB, $57, $20, $08 ; inline Z80: LD ($7003) / XOR A / LD ($7303) ...
    DB      $E6, $03, $21, $A6, $93, $CD, $05, $93 ; inline Z80: CALL $1FD6 / LD HL,$0000 / LD ($70BD) ...
    DB      $21, $A9, $70, $35, $F2, $36, $8C, $21 ; inline Z80: LD ($70BE) / LD BC,$0109 / LD HL,$9409 ...
    DB      $49, $70, $7E, $FE, $00, $20, $44, $36 ; inline Z80: LD DE,$016C / CALL $AEA7 ...
    DB      $06, $AF, $32, $03, $73, $32, $07, $73 ; inline Z80: CALL $8C1F / LD A,($7373) / CP $C0 ...
    DB      $CD, $D6, $1F, $21, $00, $00, $22, $BD ; inline Z80: JR NZ / LD HL,($705F) / BIT 0 ...
    DB      $70, $22, $BE, $70, $01, $09, $01, $21 ; inline Z80: JR NZ / SET 6 / LD A,($71A6) ...
    DB      $09, $94, $11, $6C, $01, $CD, $A7, $AE ; inline Z80: CP $01 / JR NZ / LD HL,$0000 ...
    DB      $CD, $1F, $8C, $3A, $EE, $73, $FE, $C0 ; inline Z80: LD ($7017) / LD ($7018) / LD HL,($7303) ...
    DB      $20, $F6, $21, $5F, $70, $CB, $46, $20 ; inline Z80: LD ($7307) / LD (HL),$06 ...
    DB      $EF, $CB, $C6, $3A, $A6, $71, $FE, $01 ; inline Z80: LD HL,($707D) / LD ($7077) ...
    DB      $20, $F9, $21, $00, $00, $22, $17, $70 ; inline Z80: continued -- LD ($7079) ...
    DB      $22, $18, $70, $21, $03, $73, $36, $06 ; inline Z80: LD HL,($707B) / LD ($7075) / LD DE,$7300 ...
    DB      $2E, $07, $36, $0B, $21, $7D, $70, $7E ; inline Z80: LD HL,($704B) / LD BC,$0008 / LDIR ...
    DB      $32, $77, $70, $23, $7E, $32, $76, $70 ; "2wp#~2vp"
    DB      $23, $7E, $32, $79, $70, $23, $7E, $32 ; "#~2yp#~2"
    DB      $78, $70, $23, $7E, $32, $75, $70, $11 ; inline Z80: CALL $911E / PUSH HL / CB $DE ...
    DB      $00, $73, $21, $4B, $70, $01, $08, $00 ; inline Z80: CB $5E / JR NZ / POP HL / RET ...
    DB      $ED, $B0, $CD, $56, $91, $E5, $21, $B1 ; inline Z80: LD A,$00 / LD BC,$0000 / JR ...
    DB      $70, $CB, $DE, $CB, $5E, $20, $FC, $E1 ; inline Z80: LD BC,$0000 / LD A,($7079) ...
    DB      $C9, $CD, $76, $1F, $21, $F0, $73, $7E ; inline Z80: JP $8992 / LD A,($7373) / AND $05 ...
    DB      $E6, $C0, $2B, $2B, $B6, $32, $EE, $73 ; inline Z80: JR Z / PUSH BC / CALL $91BD ...
    DB      $C9, $3E, $00, $01, $00, $00, $18, $06 ; inline Z80: POP BC / LD HL,($705F) / RES 6 ...
    DB      $01, $00, $00, $3A, $79, $70, $C3, $92 ; inline Z80: CB $F6 / RET ...
    DB      $89, $3A, $EE, $73, $E6, $05, $FE, $00 ; inline Z80: LD A,($70B2) / LD B,A / AND $0F ...
    DB      $28, $0B, $C5, $CD, $BD, $91, $C1, $21 ; inline Z80: JR Z (x2) / DEC B / LD ($70B2) / BIT 1 ...
    DB      $5F, $70, $CB, $B6, $C9, $21, $5F, $70 ; inline Z80: LD BC,$0200 / CB $7F / JR Z ...
    DB      $CB, $F6, $C9, $3A, $B2, $70, $47, $E6 ; inline Z80: JP $8C39 / CB $78 / LD BC,$0000 ...
    DB      $0F, $FE, $00, $28, $16, $05, $78, $32 ; inline Z80: JP NZ $8A01 / CALL $8C3F ...
    DB      $B2, $70, $CB, $48, $20, $CA, $01, $02 ; inline Z80: LD A,($705B) / LD A,($705B) / CALL $9122 ...
    DB      $00, $CB, $7F, $28, $03, $01, $FE, $00 ; inline Z80: JP NC $8A01 / LD A,($7373) / AND $04 ...
    DB      $C3, $39, $8C, $CB, $78, $01, $00, $00 ; inline Z80: JR Z / LD BC,$0001 / JR ...
    DB      $C2, $01, $8A, $CD, $3F, $8C, $3A, $59 ; inline Z80: LD A,($705F) / BIT 5 / JR Z ...
    DB      $70, $3A, $5B, $70, $CD, $22, $91, $D2 ; inline Z80: LD A,($7373) / AND $01 / JR NZ ...
    DB      $01, $8A, $3A, $EE, $73, $E6, $04, $28 ; inline Z80: AND $01 / JR Z / JR ...
    DB      $3A, $01, $01, $00, $18, $DA, $3A, $5F ; inline Z80: AND $01 / JR Z / LD A,$84 ...
    DB      $70, $CB, $6F, $28, $0A, $3A, $EE, $73 ; inline Z80: LD ($70B2) / JP $8C36 ...
    DB      $E6, $01, $20, $18, $C3, $55, $8D, $3A ; inline Z80: LD BC,$0000 / LD A,($7300) ...
    DB      $EE, $73, $E6, $01, $28, $1D, $18, $0F ; inline Z80: JP $8A01 / LD A,($7373) / AND $01 ...
    DB      $3A, $EE, $73, $E6, $01, $28, $14, $3E ; inline Z80: JR Z / LD BC,$FF00 / LD A,($7079) ...
    DB      $84, $32, $B2, $70, $C3, $36, $8C, $01 ; inline Z80: CP $04 / JR NZ / LD A,($70AB) ...
    DB      $00, $00, $3A, $00, $73, $32, $7C, $70 ; inline Z80: AND $01 / CP $00 / JR NZ / LD C,$00 ...
    DB      $C3, $01, $8A, $3A, $EE, $73, $E6, $01 ; inline Z80: JP $8C39 / LD A,($7373) / AND $04 ...
    DB      $28, $18, $01, $FF, $00, $3A, $79, $70 ; inline Z80: LD BC,$0100 / JR Z / CALL $911E ...
    DB      $FE, $04, $20, $0B, $3A, $AB, $70, $E6 ; inline Z80: JP NC / JP $8A01 / CALL $8C3F ...
    DB      $01, $FE, $00, $20, $02, $0E, $00, $C3 ; inline Z80: CALL $90E3 / JR NC / LD A,($7373) ...
    DB      $39, $8C, $3A, $EE, $73, $E6, $04, $01 ; inline Z80: AND $08 / JR Z / LD BC,$00FE ...
    DB      $01, $00, $28, $C8, $CD, $1E, $91, $30 ; inline Z80: BIT 5 / JR Z / LD A,($70AC) ...
    DB      $EE, $C3, $01, $8A, $CD, $3F, $8C, $CD ; inline Z80: CP $01 / JR NZ / LD HL,($705F) ...
    DB      $E3, $90, $30, $40, $3A, $EE, $73, $E6 ; inline Z80: CB $DE / CB $78 / LD B,$04 ...
    DB      $08, $28, $21, $01, $00, $FE, $3A, $5F ; inline Z80: JP Z / JP $89DC ...
    DB      $70, $CB, $6F, $28, $14, $3A, $AC, $70 ; inline Z80: AND $02 / JR Z / LD BC,$0002 ...
    DB      $FE, $01, $20, $0D, $21, $5F, $70, $CB ; inline Z80: AND $01 / JR Z / LD C,$FE ...
    DB      $DE, $CB, $78, $06, $04, $28, $02, $06 ; inline Z80: JP $8C39 / LD BC,$0000 / LD A,($7058) ...
    DB      $FC, $C3, $DC, $89, $3A, $EE, $73, $E6 ; inline Z80: JP Z $8C9C / LD A,($705B) ...
    DB      $02, $28, $11, $01, $00, $02, $18, $D6 ; inline Z80: CP $D8 / JR Z / CP $98 ...
    DB      $3A, $EE, $73, $E6, $01, $28, $02, $0E ; inline Z80: CP $00 / JP NZ $8C87 ...
    DB      $FE, $C3, $39, $8C, $01, $00, $00, $3A ; inline Z80: BIT 5 / JP NZ / LD BC,$0000 ...
    DB      $58, $70, $FE, $00, $CA, $9C, $8C, $3A ; inline Z80: LD A,$A0 / LD ($707C) / LD A,($71A5) ...
    DB      $5B, $70, $FE, $D8, $28, $09, $FE, $98 ; inline Z80: JP NZ $8A01 / LD A,$06 / JP $8988 ...
    DB      $28, $05, $FE, $00, $C2, $87, $8C, $3A ; inline Z80: LD A,($7057) / BIT 3 / JR NZ ...
    DB      $5F, $70, $CB, $6F, $C2, $3E, $8D, $01 ; inline Z80: INC (HL) / INC (HL) / LD A,($7059) ...
    DB      $00, $00, $3E, $A0, $32, $7C, $70, $3A ; inline Z80: CALL $A894 / JR Z / LD A,($7058) ...
    DB      $A5, $71, $C2, $01, $8A, $3E, $06, $C3 ; inline Z80: CP $E0 / JR NZ / LD A,($7000) ...
    DB      $88, $89, $3A, $57, $70, $CB, $78, $20 ; inline Z80: BIT 5 / JR NZ (tail end)
    DB      $08, $21, $B0, $71, $34, $34, $3A, $59 ; inline Z80: LD B,$34 / LD (IY+$34),A ...
    DB      $70, $CD, $94, $A8, $28, $35, $3A, $58 ; inline Z80: LD A,($7059) / CALL $A894 ...
    DB      $70, $FE, $E0, $20, $38, $3A, $00, $70 ; inline Z80: RET Z / LD A,($7058) ...
    DB      $CB, $6F, $20, $31              ; inline Z80: BIT 5,($7000) / JR NZ (end of block)

; =============================================================================
; GAME STATE / ROOM TRANSITION -- LOC_8DA2 ($8DA2)
; Central state handler called at end of each action frame.  Dispatches based
; on $7079 (game state):
;   $7079 != $08: CALL SUB_AC1A (state $05) -- trigger room transition
;                 LD $7079=$08, $70A9=$70, $7306=$D4
;                 CALL SUB_8DC2 (decrement $7049 life counter)
; Continues to LOC_8DD3 which updates $7300/$7304 (player tile X/Y positions)
; by adding carry values from C/B registers.
; Also handles: door open/close, key pickup, skull/enemy collision decrement.
; LOC_929B (line 1018) -> JP LOC_8DA2 is the inner loop re-entry point.
; =============================================================================
LOC_8DA2:
    LD      A, ($7079)                      ; A = ($7079) game state ($08 = normal play)
    CP      $08                             ; CP $08: check normal play state
    JR      Z, LOC_8DD3                     ; JR Z, LOC_8DD3: normal play -- skip room-transition logic
    LD      A, $05                          ; A = $05 (sound effect: room-exit chime)
    CALL    SUB_AC1A                        ; CALL SUB_AC1A: trigger sound effect $05
    LD      A, $08                          ; A = $08
    LD      ($7079), A                      ; ($7079) = $08: set state back to normal play
    LD      A, $70                          ; A = $70
    LD      ($70A9), A                      ; ($70A9) = $70: reset scroll position
    LD      A, $D4                          ; A = $D4
    LD      ($7306), A                      ; ($7306) = $D4: set room-transition column marker
    CALL    SUB_8DC2                        ; CALL SUB_8DC2: DEC life counter ($7049)
    JR      LOC_8DD3                        ; JR LOC_8DD3: fall through to player position update

SUB_8DC2:
    PUSH    HL                              ; PUSH HL
    LD      HL, $7049                       ; HL = $7049 (life counter)
    DEC     (HL)                            ; DEC (HL): player loses one life
    POP     HL                              ; POP HL
    RET                                     ; RET
    DB      $CB, $79, $20, $04, $AF, $32, $76, $70 ; inline data (post-RET): BIT 3 A / JR NZ ...
    DB      $1E, $00                        ; inline data (post-RET): LD E,$00 (tail)

LOC_8DD3:
    LD      B, E                            ; B = E (secondary delta)
    LD      HL, $7300                       ; HL = $7300 (player tile X lo)
    LD      A, (HL)                         ; A = ($7300) current X
    ADD     A, C                            ; ADD A, C: X += C (delta)
    LD      (HL), A                         ; ($7300) = A: store new X
    INC     HL                              ; INC HL -> $7301
    LD      A, (HL)                         ; A = ($7301) X hi byte
    ADD     A, B                            ; ADD A, B: X hi += B
    LD      (HL), A                         ; ($7301) = A: store new X hi
    LD      L, $04                          ; LD L,$04 -> HL = $7304 (secondary X)
    LD      A, (HL)                         ; A = ($7304) secondary X
    ADD     A, C                            ; ADD A, C: += C
    LD      (HL), A                         ; ($7304) = A: store new secondary X
    INC     HL                              ; INC HL -> $7305
    LD      A, (HL)                         ; A = ($7305)
    ADD     A, B                            ; ADD A, B
    LD      (HL), A                         ; ($7305) = A: store new secondary X hi
    RET                                     ; RET
    DB      $21, $76, $70, $5E, $23, $4E, $CD, $80 ; inline Z80: LD HL,$7076 / LD E,(HL) / INC HL / LD C,(HL)
    DB      $8D, $FE, $04, $38, $05, $FE, $F0, $DA ; inline Z80: CALL $8D80 / CP $04 / JR C / CP $F0 ...
    DB      $23, $8F, $21, $A8, $71, $34, $CB, $78 ; inline Z80: JP $8F23 / LD HL,($71A8) / INC (HL) ...
    DB      $28, $07, $35, $35, $01, $00, $EC, $18 ; inline Z80: BIT 3 / JR Z (x2) / LD BC,$00EC ...
    DB      $03, $01, $00, $16, $F5, $3A, $A7, $71 ; inline Z80: LD BC,$0016 / PUSH AF / LD A,($71A7) ...
    DB      $FE, $09, $38, $63, $3E, $01, $CD, $1A ; inline Z80: CP $09 / JR NC / LD A,$01 / CALL $AC1A ...
    DB      $AC, $3A, $79, $70, $FE, $05, $20, $3B ; inline Z80: LD A,($7079) / CP $05 / JR NZ ...
    DB      $AF, $32, $A7, $71, $3E, $08, $32, $A8 ; inline Z80: XOR A / LD ($71A7) / LD A,$08 / LD ($71A8)
    DB      $71, $3A, $5F, $70, $CB, $9F, $CB, $AF ; inline Z80: LD A,($705F) / BIT 1 / JR Z ...
    DB      $CB, $D7, $32, $5F, $70, $C5, $E5, $D5 ; inline Z80: PUSH HL,BC / LD HL,$70C6 ...
    DB      $21, $A6, $71, $7E, $FE, $09, $30, $01 ; inline Z80: CALL $840B / CALL $A8B7 / LD BC,$0700 ...
    DB      $34, $21, $C0, $70, $01, $C6, $00, $CD ; inline Z80: CALL $1FD9 / CALL $A8C3 / POP DE+HL+BC ...
    DB      $0B, $84, $CD, $B7, $A8, $01, $00, $07 ; inline Z80: JR / LD A,($705F) / BIT 5 ...
    DB      $CD, $D9, $1F, $CD, $C3, $A8, $D1, $E1 ; inline Z80: JR NZ / LD A,$F0 / LD ($70AC) ...
    DB      $C1, $18, $1C, $3A, $5F, $70, $CB, $6F ; inline Z80: CALL $AC06 / POP AF / CALL $8DD4 ...
    DB      $CB, $DF, $CB, $EF, $32, $5F, $70, $20 ; inline Z80: LD HL,$7077 / LD (HL),A ...
    DB      $08, $3E, $F0, $32, $AC, $70, $CD, $06 ; inline Z80: LD ($7076) ...
    DB      $AC, $F1, $CD, $D4, $8D, $18, $07, $F1 ; inline Z80: LD ($7078) / LD ($7075) ...
    DB      $CD, $D4, $8D, $CD, $13, $8C, $21, $7D ; inline Z80: LD HL,$7300 / LD A,(HL) / LD ($707C) ...
    DB      $70, $3A, $77, $70, $77, $23, $3A, $76 ; "p:wpw#:v"
    DB      $70, $77, $23, $3A, $79, $70, $77, $23 ; "pw#:ypw#"
    DB      $3A, $78, $70, $77, $3A, $75, $70, $23 ; ":xpw:up#"
    DB      $77, $21, $00, $73, $7E, $32, $7C, $70 ; inline Z80: LD ($7077) / LD HL,$7300 / LD A,(HL) ...
    DB      $11, $4B, $70, $01, $08, $00, $ED, $B0 ; inline Z80: LD DE,($704B) / LD BC,$0008 / LDIR ...
    DB      $E5, $21, $B1, $70, $CB, $E6, $E1, $C9 ; inline Z80: PUSH HL / SET 6,(HL) / POP HL / RET

; =============================================================================
; FRAME GAME BODY -- DELAY_LOOP_8EB0 ($8EB0)
; Called from NMI each frame (when $70B1 bit 4 is set).  Runs all per-frame
; game subsystems:
;   CALL SUB_8308        render current room tiles to VRAM (calls SUB_AE00 $04)
;   load $71A7 (player speed) -> compute animation frame count (B=6..8 x speed)
;   CALL TABLE_BYTE  read the table at $93C0
;   LD DE,$0001 / LD IY,$0007 / CALL SUB_AE2E  write sprite attribute block
;   $71A6 (room difficulty) -> B: cap player max speed
;   $71A7 (current speed) vs B: CALL SUB_908F ($53) -- item pickup check
;   if bit 5 of $705F clear: CALL SUB_AE00 $04 (re-render room tiles)
; =============================================================================
DELAY_LOOP_8EB0:
    CALL    SUB_8308                        ; CALL SUB_8308: render current room tiles to VRAM
    LD      A, ($71A7)                      ; A = ($71A7) player speed (0-8)
    CP      $08                             ; CP $08: is speed at maximum?
    JR      C, LOC_8EBC                     ; JR C, LOC_8EBC: if below max, skip clamp
    LD      A, $08                          ; A = $08 (clamp speed to 8)

LOC_8EBC:
    LD      B, $06                          ; B = $06 (6 animation frames per speed unit)
    LD      C, A                            ; C = A (save clamped speed)

LOC_8EBF:
    ADD     A, C                            ; ADD A, C: accumulate speed -> animation frame count
    DJNZ    LOC_8EBF                        ; DJNZ LOC_8EBF: sum speed * 6 times
    LD      HL, $93C0                       ; HL = $93C0 (tile collision lookup table)
    CALL    TABLE_BYTE                      ; A = byte A of the table at $93C0
    LD      DE, $0001                       ; DE = $0001 (sprite attribute write flag)
    LD      IY, $0007                       ; IY = $0007 (sprite stride / attribute selector)
    LD      A, $04                          ; A = $04 (VRAM block selector)
    CALL    SUB_AE2E                        ; CALL SUB_AE2E: write sprite attribute block to VRAM
    LD      A, ($71A6)                      ; A = ($71A6) room difficulty (0-5)
    NEG                                     ; NEG: negate difficulty
    ADD     A, $09                          ; ADD A,$09: max speed = 9 - difficulty
    LD      B, A                            ; B = A (player speed cap for this room)
    LD      A, ($71A7)                      ; A = ($71A7) current speed
    CP      B                               ; CP B: speed vs cap
    JR      C, LOC_8F03                     ; JR C, LOC_8F03: below cap -- no item-pickup check
    LD      A, $53                          ; A = $53 (item type code)
    CALL    SUB_908F                        ; CALL SUB_908F: CPIR item pickup table $71B2 (6 bytes)
    JR      C, LOC_8F03                     ; JR C, LOC_8F03: no pickup found
    LD      A, ($705F)                      ; A = ($705F) game mode flags
    BIT     5, A                            ; BIT 5, A: tile-skip flag
    JR      NZ, LOC_8F03                    ; JR NZ, LOC_8F03: tile-skip set -- skip re-render
    LD      A, $04                          ; A = $04
    CALL    SUB_AE00                        ; CALL SUB_AE00 ($04): re-render room tiles after pickup
    CALL    $00AB                           ; inline data: SUB_AE00 $04 VRAM block byte 0
    INC     BC                              ; inline data: SUB_AE00 $04 VRAM block byte 1
    CALL    $10AB                           ; inline data: SUB_AE00 $04 VRAM block byte 2
    INC     B                               ; inline data: SUB_AE00 $04 VRAM block byte 3
    CALL    $15AB                           ; inline data: SUB_AE00 $04 VRAM block byte 4
    INC     B                               ; inline data: SUB_AE00 $04 VRAM block byte 5
    NOP                                     ; inline data: SUB_AE00 $04 VRAM block byte 6
    NOP                                     ; inline data: SUB_AE00 $04 VRAM block byte 7

LOC_8F03:
    RET                                     ; RET: return from subroutine (LOC_8F03)
    DB      $21, $A7, $71, $3A, $5F, $70, $CB, $6F ; inline Z80: LD HL,($71A7) / LD A,($705F) / BIT 5 ...
    DB      $C2, $0C, $8E, $35, $C3, $0C, $8E, $21 ; inline Z80: JP NZ $8E0C / DEC (HL) / JP $8E0C ...
    DB      $A7, $71, $3A, $5F, $70, $CB, $57, $28 ; inline Z80: LD HL,($71A7) / LD A,($705F) / BIT 2 ...
    DB      $02, $23, $34, $34, $C3, $0C, $8E, $01 ; inline Z80: JR Z / INC HL / INC (HL) / INC (HL) ...
    DB      $00, $00, $2B, $7E, $FE, $08, $30, $04 ; inline Z80: JP $8E0C / LD BC,$0000 / DEC HL ...
    DB      $0E, $A4, $18, $D4, $FE, $AC, $D8, $0E ; inline Z80: CP $08 / JR NC / LD C,$A4 / JR ...
    DB      $5C, $18, $DC, $3A, $79, $70, $FE, $08 ; inline Z80: LD C,$5C / JR / LD A,($7079) ...
    DB      $D0, $3A, $5B, $70, $E5, $D5, $C5, $21 ; inline Z80: JP NC / LD A,($705B) / PUSH HL+DE+BC ...
    DB      $12, $94, $01, $07, $00, $ED, $B1, $20 ; inline Z80: LD HL,$9412 / LD BC,$0007 / CPIR ...
    DB      $0E, $79, $1E, $01, $FE, $04, $38, $02 ; inline Z80: JR NZ / LD C,A / LD A,$04 / JR C ...
    DB      $1E, $FF, $C1, $78, $83, $47, $C5, $C1 ; inline Z80: LD C,$FF / POP BC / ADD A,B / LD B,A ...
    DB      $D1, $E1, $C9, $3A, $79, $70, $FE, $09 ; inline Z80: CALL $9208 / JR NC / LD HL,($71B0) ...
    DB      $C8, $21, $11, $70, $7E, $EE, $80, $77 ; inline Z80: INC (HL) / INC (HL) / LD A,($7059) ...
    DB      $CD, $56, $91, $3A, $57, $70, $21, $78 ; inline Z80: CP $9C / JR NZ / LD D,$70 / LD A,$5D ...
    DB      $70, $CB, $7E, $20, $08, $21, $B0, $71 ; inline Z80: CP $B7 / JR NZ / LD D,$69 / LD A,$58 ...
    DB      $34, $34, $3A, $59, $70, $FE, $9C, $20 ; inline Z80: CP $C7 / JR NZ / LD A,$62 / LD D,$77 ...
    DB      $06, $16, $70, $3E, $5D, $18, $12, $FE ; inline Z80: LD HL,$7084 / LD (HL),D / CALL $908F ...
    DB      $B7, $20, $06, $16, $69, $3E, $58, $18 ; inline Z80: JR NZ / CALL $909C / LD HL,($70B0) ...
    DB      $08, $FE, $C7, $20, $34, $3E, $62, $16 ; inline Z80: LD BC,$0060 / SCF+CCF / SBC HL,BC ...
    DB      $77, $21, $84, $70, $72, $CD, $8F, $90 ; inline Z80: LD ($70B0) / CALL $90C8 / LD A,($7084) ...
    DB      $20, $27, $CD, $9C, $90, $2A, $B0, $71 ; inline Z80: CALL $A3F1 / PUSH AF / LD A,$08 ...
    DB      $01, $60, $00, $37, $3F, $ED, $42, $22 ; inline Z80: CALL $AC1A / POP AF / LD HL,$0300 ...
    DB      $B0, $71, $CD, $C8, $90, $3A, $84, $70 ; inline Z80: CALL $A587 / RET ...
    DB      $CD, $F1, $A3, $F5, $3E, $08, $CD, $1A ; inline Z80: CALL $56A1 / LD HL,($71B0) / INC (HL) ...
    DB      $AC, $F1, $21, $00, $03, $CD, $87, $A5 ; inline Z80: CP $00 / CALL NZ / LD HL,$0070 / CB $DE ...
    DB      $C9, $CD, $56, $91, $21, $B0, $71, $34 ; inline Z80: PUSH HL / CALL $90A5 / POP HL / CB $9E ...
    DB      $3A, $58, $70, $01, $08, $00, $21, $28 ; inline Z80: LD C,$00 / LD E,$00 / JP $92A2 ...
    DB      $94, $ED, $B1, $20, $19, $3A, $4A, $70 ; inline Z80: LD BC,$000C / LD HL,$9430 / CPIR ...
    DB      $FE, $00, $C0, $21, $00, $70, $CB, $DE ; inline Z80: CALL $9067 / DEC HL / AND $F8 ...
    DB      $E5, $CD, $A5, $90, $E1, $CB, $9E, $0E ; inline Z80: CP $78 / JR NZ / LD A,$58 / JR ...
    DB      $00, $1E, $00, $C3, $A2, $8D, $01, $0C ; inline Z80: CP $68 / LD A,$62 / JR NZ / LD A,$5D ...
    DB      $00, $21, $30, $94, $ED, $B1, $20, $3E ; inline Z80: PUSH BC / LD C,A / CALL $A56C ...
    DB      $CD, $67, $90, $2B, $7E, $E6, $F8, $FE ; inline Z80: JR NC / PUSH AF / LD A,$02 / CALL $AC1A
    DB      $78, $20, $04, $3E, $58, $18, $08, $FE ; inline Z80: POP AF / CALL $A8B7 / POP BC ...
    DB      $68, $3E, $62, $20, $02, $3E, $5D, $C5 ; inline Z80: CALL $8EA8 / CALL $A8C3 / POP BC ...
    DB      $4F, $CD, $6C, $A5, $38, $1E, $F5, $3E ; inline Z80: LD BC,$0010 / LD HL,$9418 / CPIR ...
    DB      $02, $CD, $1A, $AC, $F1, $CD, $B7, $A8 ; inline Z80: CALL NZ / LD A,C / CP $04 / JR NC ...
    DB      $C1, $C5, $CD, $A5, $90, $3E, $0B, $ED ; inline Z80: CALL $906D / LD A,$A0 / LD ($704A) ...
    DB      $5B, $B0, $71, $CD, $78, $A3, $CD, $A8 ; inline Z80: CP $08 / JR NC / LD A,$44 / JR ...
    DB      $8E, $CD, $C3, $A8, $C1, $C9, $01, $10 ; inline Z80: CP $08 / JR NC / LD A,$44 / CALL $9067 ...
    DB      $00, $21, $18, $94, $ED, $B1, $C0, $79 ; inline Z80: JR / PUSH HL / LD HL,$5000 / JR ...
    DB      $FE, $04, $30, $0C, $CD, $6D, $90, $3E ; inline Z80: PUSH HL / LD HL,$0100 / JR ...
    DB      $A0, $32, $4A, $70, $3E, $8C, $18, $30 ; inline Z80: PUSH HL / LD HL,$3000 / LD ($70BD) ...
    DB      $FE, $08, $30, $1C, $3E, $44, $CD, $67 ; inline Z80: POP HL / RET / CP $0C / JR NC ...
    DB      $90, $18, $25, $E5, $21, $50, $00, $18 ; inline Z80: CALL $9073 / LD A,$53 / JR ...
    DB      $0A, $E5, $21, $00, $01, $18, $04, $E5 ; inline Z80: LD A,$91 / CALL $9067 / JP $901B ...
    DB      $21, $00, $30, $22, $BD, $70, $E1, $C9 ; inline Z80: continued (tail bytes of block)
    DB      $FE, $0C, $30, $07, $CD, $73, $90, $3E ; inline Z80: continued
    DB      $53, $18, $05, $3E, $91, $CD, $67, $90 ; inline Z80: continued
    DB      $C3, $1B, $90                   ; inline Z80: end of LOC_8F03 inline data

SUB_908F:
    LD      HL, $71B2                       ; HL = $71B2 (item pickup table, 6 entries)
    LD      BC, $0006                       ; BC = $0006 (scan 6 bytes)
    CPIR                                    ; CPIR: search for A in [$71B2..$71B7]
    SCF                                     ; SCF: set carry (found)
    RET     Z                               ; RET Z: return carry set if match found
    SCF                                     ; SCF
    CCF                                     ; CCF: clear carry (not found)
    RET                                     ; RET

SUB_909C:
    PUSH    HL                              ; PUSH HL
    POP     DE                              ; POP DE (DE = HL -- source address)
    DEC     DE                              ; DEC DE (DE = HL-1 -- dest one slot before source)
    LDIR                                    ; LDIR: shift item table left by one slot (remove collected item)
    CALL    DRAW_INVENTORY                  ; redraw the inventory
    RET                                     ; RET: return from SUB_909C
    DB      $79, $C6, $04, $D6, $04, $FE, $04, $30 ; inline Z80: LD A,C / ADD A,$04 / SUB $04 ...
    DB      $FA, $5F, $AF, $47, $CB, $43, $28, $02 ; inline Z80: CP $04 / JR NC / LD E,A ...
    DB      $C6, $01, $CB, $4B, $28, $02, $C6, $20 ; inline Z80: XOR A / LD B,A / BIT 0 / JR Z ...
    DB      $2A, $B0, $71, $4F, $37, $3F, $ED, $42 ; inline Z80: ADD A,$01 / BIT 1 / JR Z / ADD A,$20 ...
    DB      $22, $B0, $71, $11, $F2, $72, $21, $B0 ; inline Z80: LD HL,($70B0) / LD C,A / SCF+CCF / SBC HL,BC
    DB      $71, $06, $18, $1B, $1B, $1A, $BE, $20 ; inline Z80: LD ($70B0) / LD DE,$72F2 / LD HL,($70B0) ...
    DB      $0B, $23, $13, $1A, $BE, $20, $F5, $D5 ; inline Z80: LD B,$06 / DEC DE (x2) / DEC DE / CP (HL) ...
    DB      $E1, $C3, $A2, $92, $10, $ED, $3A, $57 ; inline Z80: JR NZ / INC HL / INC DE / CP (HL) / JR NZ ...
    DB      $70, $FE, $08, $28, $07, $3A, $59, $70 ; inline Z80: PUSH DE / POP HL / JP $92A2 ...
    DB      $FE, $08, $20, $0E, $3A, $79, $70, $FE ; inline Z80: DJNZ / LD D,A / LD A,($7057) ...
    DB      $04, $28, $07, $3A, $5F, $70, $CB, $57 ; inline Z80: CP $08 / JR Z / LD A,($7059) ...
    DB      $20, $16, $3A, $EE, $73, $E6, $C0, $F5 ; inline Z80: CP $08 / JR NZ / LD A,($7079) ...
    DB      $FE, $C0, $20, $0E, $3A, $75, $70, $FE ; inline Z80: CP $04 / JR Z / LD A,($705F) / BIT 2 ...
    DB      $80, $20, $07, $F1, $AF, $32, $75, $70 ; inline Z80: JR NZ / LD A,($7373) / AND $C0 ...
    DB      $37, $C9, $F1, $32, $75, $70, $37, $3F ; inline Z80: CALL $913B / JR Z / CP $E8 / JR Z ...
    DB      $C9, $21, $5B, $70, $7E, $E5, $C5, $21 ; inline Z80: CALL $913B / JR Z / LD HL,$A00E ...
    DB      $FF, $93, $01, $0A, $00, $ED, $B1, $C1 ; inline Z80: LD BC,$0005 / CPIR / POP BC / POP HL ...
    DB      $E1, $28, $1F, $FE, $E8, $28, $14, $CD ; inline Z80: LD A,($7000) / BIT 7 / SCF+NC / RET ...
    DB      $3B, $91, $28, $19, $37, $C9, $E5, $C5 ; inline Z80: LD A,$D2 / JR ...
    DB      $21, $0E, $A0, $01, $05, $00, $ED, $B1 ; inline Z80: LD HL,$7304 / LD A,(HL) / LD ($7084) ...
    DB      $C1, $E1, $C9, $3A, $00, $70, $CB, $77 ; inline Z80: INC HL / LD A,(HL) / LD ($7085) / LD BC,$1202
    DB      $37, $C0, $37, $3F, $C9, $3E, $D2, $18 ; inline Z80: LD HL,$7057 / CALL $916C / RET ...
    DB      $F9, $21, $04, $73, $7E, $32, $84, $70 ; inline Z80: PUSH HL / LD A,($7084) / ADD A,B ...
    DB      $23, $7E, $32, $85, $70, $01, $02, $12 ; inline Z80: ADD A,C / LD HL,$E3AF / LD BC,$01DF ...
    DB      $21, $57, $70, $CD, $6C, $91, $C9, $E5 ; inline Z80: ADD HL,BC / LD ($53,$ED) / LD HL,$0070 ...
    DB      $3A, $84, $70, $80, $47, $3A, $85, $70 ; inline Z80: CB $E6 / CB $D6 / POP HL / LD BC,$0203 ...
    DB      $C6, $FF, $81, $CD, $E3, $AF, $01, $DF ; inline Z80: CALL $AEA7 / LD HL,$0070 / CB $A6 ...
    DB      $FF, $09, $EB, $ED, $53, $B0, $71, $21 ; inline Z80: CB $96 / RET
    DB      $00, $70, $CB, $E6, $CB, $D6, $E1, $01 ; inline Z80: CB $96 / RET (tail)
    DB      $03, $02, $CD, $A7, $AE, $21, $00, $70 ; inline Z80: tail end bytes
    DB      $CB, $A6, $CB, $96, $C9         ; inline Z80: end of SUB_909C inline data

; Change room: no enemies, their sprites cleared, then load the room at
; the current row and column.
SUB_919A:
    LD      HL, WORK_BUFFER
    SET     0, (HL)
    XOR     A
    LD      ($707A), A                      ; no enemies
    LD      HL, $7308                       ; clear the enemies' 8 sprites
    LD      BC, $0020
    CALL    SUB_840B
    CALL    LOAD_ROOM
    RET

SUB_91B0:
    LD      A, ($7096)                      ; A = ($7096) direction/state counter
    DEC     A                               ; DEC A
    JP      P, LOC_91B9                     ; JP P, LOC_91B9: if still >= 0, keep value
    LD      A, $03                          ; A = $03 (wrap back to 3)

LOC_91B9:                                   ; LOC_91B9:
    LD      ($7096), A                      ; ($7096) = A: store wrapped counter
    RET                                     ; RET: return with wrapped direction counter
    DB      $21, $AD, $70, $35, $C0, $36, $02, $3A ; inline Z80: LD HL,$70AD / DEC (HL) / RET NZ ...
    DB      $AA, $70, $3D, $F2, $CD, $91, $3E, $07 ; inline Z80: LD ($70AA) / DEC A / JP P / LD A,$07 ...
    DB      $32, $AA, $70, $C9              ; inline Z80: LD ($70AA) / RET

SUB_91D1:
    SUB     (HL)                            ; SUB (HL): A -= (HL) (compute signed delta)
    JP      P, LOC_91D7                     ; JP P, LOC_91D7: if positive, skip NEG
    NEG                                     ; NEG: make positive (absolute value)

LOC_91D7:                                   ; LOC_91D7:
    CP      B                               ; CP B: |delta| vs threshold B
    RET                                     ; RET (flags: C if within threshold)
    DB      $F5, $F1, $21, $14, $20, $11, $01, $00 ; inline Z80: PUSH AF / POP AF / LD HL,$2014 ...
    DB      $CD, $25, $AE, $C9, $3A, $AC, $70, $3D ; inline Z80: LD DE,$0001 / CALL $AE25 / RET ...
    DB      $FE, $00, $20, $02, $3E, $01, $32, $AC ; inline Z80: LD A,($70AC) / DEC A / CP $00 / JR NZ ...
    DB      $70, $3A, $79, $70, $FE, $08, $D0, $21 ; inline Z80: LD A,$01 / LD ($70AC) / LD A,($7079) ...
    DB      $4A, $70, $7E, $FE, $00, $28, $15, $35 ; inline Z80: JP NC / LD HL,($704A) ...
    DB      $FE, $01, $28, $07, $3E, $E0, $CD ; inline Z80: CP $00 / JR Z / DEC (HL) / CP $01 ...

SUB_9208:
    EXX                                     ; EXX: swap to alternate BC/DE/HL register set
    SUB     C                               ; SUB C: A -= C (apply delta from alternate C)
    JR      LOC_921F                        ; JR LOC_921F: jump to main collision loop
    DB      $3E, $C0, $CD, $D9, $91, $AF, $32, $4A ; inline Z80: LD A,$C0 / CALL $91D9 / XOR A / LD ($704A)
    DB      $70, $3E, $8C, $CD, $8F, $90, $20, $03 ; inline Z80: LD A,$8C / CALL $908F / JR NZ ...
    DB      $CD, $9C, $90                   ; inline Z80: CALL $909C (tail)

LOC_921F:
    CALL    SUB_92D1                        ; CALL SUB_92D1: toggle $7098 flip-flag (XOR $80), CALL SUB_91B0 if zero
    LD      A, ($704A)                      ; A = ($704A) collision state flag
    CP      $00                             ; CP $00
    RET     NZ                              ; RET NZ: non-zero collision state -- exit loop
    LD      HL, $7300                       ; HL = $7300 (player tile X)
    LD      A, (HL)                         ; A = ($7300) player X lo
    LD      ($7084), A                      ; ($7084) = A: cache player X lo
    INC     HL                              ; INC HL -> $7301
    LD      A, (HL)                         ; A = ($7301) player X hi
    LD      ($7085), A                      ; ($7085) = A: cache player X hi
    LD      HL, $72C1                       ; HL = $72C1 (room tile/collision data start)
    PUSH    HL                              ; PUSH HL: save scan pointer for LOC_9238 loop

LOC_9238:
    POP     HL                              ; POP HL: restore scan pointer

LOC_9239:                                   ; LOC_9239: -- tile scan loop body
    INC     HL                              ; INC HL: advance to next tile entry (skip type byte)
    LD      C, (HL)                         ; C = (HL): read tile column
    INC     HL                              ; INC HL
    LD      A, (HL)                         ; A = (HL): read tile row
    CP      $FE                             ; CP $FE: end-of-data sentinel?
    RET     Z                               ; RET Z: done -- no collision found
    CP      $FF                             ; CP $FF: enemy entry separator?
    JR      NZ, LOC_9239                    ; JR NZ, LOC_9239: not separator -- keep scanning
    PUSH    HL                              ; PUSH HL: save pointer for this entry
    LD      HL, $7304                       ; HL = $7304 (player secondary X)
    LD      B, $00                          ; B = $00
    ADD     HL, BC                          ; ADD HL, BC: index to players tile column slot
    LD      A, ($7084)                      ; A = ($7084) player X lo
    LD      B, $0D                          ; B = $0D (half-tile threshold = 13 pixels)
    CALL    SUB_91D1                        ; CALL SUB_91D1: |player X - tile X| vs 13
    JR      NC, LOC_9238                    ; JR NC, LOC_9238: outside X range -- skip this entry
    INC     HL                              ; INC HL: advance to row comparison
    LD      A, ($7085)                      ; A = ($7085) player X hi
    LD      B, $08                          ; B = $08 (row threshold = 8)
    CALL    SUB_91D1                        ; CALL SUB_91D1: |player row - tile row| vs 8
    JR      NC, LOC_9238                    ; JR NC, LOC_9238: outside Y range -- skip
    INC     HL                              ; INC HL
    INC     HL                              ; INC HL: skip to tile type byte
    LD      A, (HL)                         ; A = (HL): read tile action type
    CP      $00                             ; CP $00: empty?
    JR      Z, LOC_9238                     ; JR Z, LOC_9238: empty tile -- skip
    PUSH    HL                              ; PUSH HL: save tile type pointer
    LD      A, $91                          ; A = $91
    CALL    SUB_908F                        ; CALL SUB_908F: CPIR $91 in item table
    JR      NZ, LOC_928F                    ; JR NZ, LOC_928F: not $91 -- try enemy collision
    CALL    SUB_909C                        ; CALL SUB_909C: shift item table (collect item)
    PUSH    AF                              ; PUSH AF
    LD      A, $03                          ; A = $03
    CALL    SUB_AC1A                        ; CALL SUB_AC1A: trigger sound effect $03 (pickup chime)
    POP     AF                              ; POP AF
    POP     HL                              ; POP HL: restore tile type pointer
    LD      A, (HL)                         ; A = (HL): re-read tile type
    LD      (HL), $00                       ; (HL) = $00: clear tile (remove from room)
    LD      HL, $2000                       ; HL = $2000 (score delta: medium gem)
    CP      $0F                             ; CP $0F: check tile type for gem variant
    JR      Z, LOC_9287                     ; JR Z, LOC_9287: type $0F -> medium gem ($2000)
    LD      HL, $3000                       ; HL = $3000 (score delta: large gem)

LOC_9287:
    CALL    SUB_A587                        ; CALL SUB_A587: add score (calls SUB_AF70 + SUB_AEFE)
    POP     HL                              ; POP HL: restore scan pointer
    CALL    SUB_92A2                        ; CALL SUB_92A2: enemy distance check / collision reaction
    RET                                     ; RET

LOC_928F:
    POP     HL                              ; POP HL: discard tile pointer
    POP     HL                              ; POP HL: discard scan pointer
    LD      A, ($71A6)                      ; A = ($71A6) room difficulty
    CP      $05                             ; CP $05
    JR      NC, LOC_929B                    ; JR NC, LOC_929B: difficulty >= 5 -> no reaction
    CALL    SUB_92A2                        ; CALL SUB_92A2: process enemy distance reaction

LOC_929B:
    LD      C, $00                          ; C = $00
    LD      E, $00                          ; E = $00 (clear collision deltas)
    JP      LOC_8DA2                        ; JP LOC_8DA2: back to game state dispatch

SUB_92A2:
    LD      A, ($71A6)                      ; A = ($71A6) room difficulty
    CP      $04                             ; CP $04
    JR      C, LOC_92AF                     ; JR C, LOC_92AF: difficulty < 4 -- always react
    LD      A, (WORK_BUFFER)                ; A = (WORK_BUFFER) check bit 3 (enemy-present flag)
    BIT     3, A                            ; BIT 3, A
    RET     NZ                              ; RET NZ: enemy present -- no reaction (suppress double-hit)

LOC_92AF:
    LD      A, $C0                          ; A = $C0
    DEC     HL                              ; DEC HL: point at tile entry
    SUB     L                               ; SUB L: A = $C0 - L (distance from centre)
    NEG                                     ; NEG: make positive
    SRA     A                               ; SRA A: halve the distance
    CALL    SUB_92BE                        ; mark the contact's thing gone
    LD      C, $00                          ; LD C,$00: C = 0 (clear speed component)
    LD      E, C                            ; LD E,C: E = 0 (clear second speed component)
    RET                                     ; RET: return with C=E=0 (no reaction)

; Toggle thing A-1's bit in the room's "gone" bitmap ($70C0): the item
; picked up, door opened or enemy killed stays gone when the room is
; reloaded (see NEXT_THING_GONE).
SUB_92BE:
    DEC     A
    LD      ($71A2), A                      ; thing A-1
    CALL    ROOM_NUMBER
    SLA     A
    LD      ($71A1), A                      ; the room's bitmap bytes
    CALL    NEXT_THING_GONE                 ; HL = its byte, D = its bit
    LD      A, (HL)
    XOR     D
    LD      (HL), A
    RET

SUB_92D1:
    LD      HL, $7098                       ; HL = $7098 (movement flip-flag)
    LD      A, $80                          ; A = $80
    XOR     (HL)                            ; XOR (HL): toggle bit 7
    LD      (HL), A                         ; (HL) = A: store new flag
    CALL    Z, SUB_91B0                     ; CALL Z, SUB_91B0: if result=0, DEC+wrap $7096 direction counter
    RET                                     ; RET: return after direction flip
    DB      $3A, $79, $70, $FE, $01, $20, $32, $3A ; inline Z80 (post-RET): LD A,($7079) / CP $01 ...
    DB      $AA, $70, $CB, $2F, $21, $80, $93, $F5 ; inline Z80: LD A,($70AA) / RRCA / LD HL,$9380 ...
    DB      $FE, $00, $28, $05, $3E, $09, $CD, $1A ; inline Z80: CP $00 / JR Z / LD A,$09 / CALL $AC1A ...
    DB      $AC, $F1, $CD, $69, $93, $30, $0A, $21 ; inline Z80: POP AF / CALL $9369 / JR NC / LD HL,$9378 ...
    DB      $78, $93, $18, $05, $3A, $AA, $70, $CB ; inline Z80: JR / LD A,($70AA) / RRCA / RLCA ...
    DB      $2F, $CB, $27, $CD, $40, $A5, $11, $02 ; inline Z80: CALL $A540 / LD DE,$7302 / LD (DE),A ...
    DB      $73, $12, $11, $06, $73, $23, $7E, $12 ; inline Z80: LD DE,$7306 / INC HL / LD A,(HL) ...
    DB      $C9, $FE, $02, $20, $0E, $21, $88, $93 ; inline Z80: RET / CP $02 / JR NZ / LD HL,$9388 ...
    DB      $CD, $69, $93, $38, $03, $21, $8A, $93 ; inline Z80: CALL $9369 / JR C / LD HL,$938A ...
    DB      $AF, $18, $DE, $FE, $03, $20, $0F, $21 ; inline Z80: XOR A / JR / CP $03 / JR NZ ...
    DB      $5F, $70, $CB, $76, $28, $03, $CB, $B6 ; inline Z80: BIT 6,($705F) / JR Z / RES 6 / RET ...
    DB      $C9, $21, $8E, $93, $18, $C6, $FE, $04 ; inline Z80: LD HL,$938E / JR / CP $09 / JR NZ ...
    DB      $20, $05, $21, $96, $93, $18, $BD, $FE ; inline Z80: LD HL,$939E / LD A,($7096) / JR ...
    DB      $05, $20, $06, $21, $8C, $93, $AF, $18 ; inline Z80: CP $04 / JR NZ / PUSH AF / LD A,($7076) ...
    DB      $B8, $FE, $09, $20, $08, $21, $9E, $93 ; inline Z80: BIT 7 / JR NZ / POP AF / SCF / RET ...
    DB      $3A, $96, $70, $18, $AC, $FE, $08, $C8 ; tile coord table: [row,col] pairs for tile placement (start)
    DB      $FE, $0A, $C8, $AF, $C3, $E8, $92, $F5 ; tile coord table: continued pairs
    DB      $3A, $76, $70, $18, $04, $F5, $3A, $78 ; tile coord table: continued pairs
    DB      $70, $CB, $7F, $20, $03, $F1, $37, $C9 ; tile coord table: continued pairs
    DB      $F1, $37, $3F, $C9, $34, $98, $6C, $A0 ; tile coord table: continued pairs
    DB      $34, $98, $34, $9C, $40, $A4, $7C, $AC ; tile coord table: continued pairs
    DB      $40, $A4, $40, $A8, $4C, $B0, $50, $B4 ; tile coord table: continued pairs
    DB      $64, $C8, $54, $B8, $58, $BC, $54, $B8 ; tile speed/count table: speed level data (start)
    DB      $58, $BC, $5C, $C0, $60, $C4, $5C, $C0 ; tile speed/count table: sentinel $FF + flags
    DB      $60, $C4, $68, $CC, $68, $D0, $68, $CC ; tile speed/count table: flag bytes continued
    DB      $68, $D0, $D8, $D4, $D8, $D4, $E0, $DC ; tile speed/count table: continued
    DB      $E0, $DC, $04, $03, $03, $01, $01, $01 ; tile speed/count table: continued
    DB      $01, $00, $00, $00, $00, $00, $FF, $FF ; tile speed/count table: continued
    DB      $FF, $FF, $FB, $FB, $F8, $4F, $F0, $F0 ; tile speed/count table: continued
    DB      $80, $80, $F9, $AF, $4A, $A0, $A0, $F0 ; tile speed/count table: continued
    DB      $F0, $A9, $B5, $4B, $B0, $B0, $50, $50 ; tile speed/count table: continued
    DB      $B9, $BC, $4B, $B0, $B0, $C0, $C0, $B9 ; tile speed/count table: continued
    DB      $BD, $4B, $B0, $B0, $E0, $E0, $B9, $EC ; tile speed/count table: end + "GAME" ASCII text + IDs
    DB      $4E, $E0, $E0, $C0, $C0, $E9, $ED, $4E ; inline text: "GAME" ($47$41$4D$45) + $00 + "OVER"
    DB      $E0, $E0, $D0, $D0, $E9, $A7, $4A, $A0 ; inline text: "OVER" ($4F$56$45$52) + tile IDs for HUD
    DB      $A0, $70, $70, $A9, $E7, $4E, $E0, $E0 ; HUD tile ID table: score/lives icon tile indices
    DB      $70, $70, $E9, $08, $10, $11, $05, $04 ; HUD tile ID table: continued (gems, torches, skull)
    DB      $06, $B9, $B8, $BA, $C4, $47, $41, $4D ; HUD tile ID table: continued (rope, ladder, boot)
    DB      $45, $00, $4F, $56, $45, $52, $04, $05 ; HUD tile ID table: continued (torch, special tiles)
    DB      $06, $B9, $B8, $BA, $9B, $9A, $97, $96 ; HUD tile ID table: last row of tile IDs
    DB      $63, $62, $D1, $D0, $D9, $99, $D8, $98 ; HUD tile ID table: continued
    DB      $AF, $A9, $AE, $A8, $A3, $A2, $A1, $A0 ; HUD tile ID table: continued
    DB      $A6, $A7, $A4, $A5, $6B, $6A, $69, $68 ; HUD tile ID table: end sentinel bytes
    DB      $7B, $7A, $79, $78, $73, $72, $71, $70 ; "{zyxsrqp"
; -----------------------------------------------------------------------------
; Tiles that stop Joe and the enemies moving sideways.
; -----------------------------------------------------------------------------
WALL_TILES:

    DB      $08, $B0, $BB, $C0, $B7, $9C, $C7, $0B; brick, doors, walls

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
HAZARD_TILES:                               ; tiles that kill Joe ($9156)
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
    CALL    SUB_AE77                        ; display off
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
    CALL    SUB_AB29                        ; mirror rows 5-23

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
    CALL    DRAW_INVENTORY                ; draw the inventory

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
    CALL    SUB_AE83                        ; display on
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
    CALL    SUB_AE3A                        ; JP (HL)
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
    CALL    SUB_AA5D                        ; the HUD's frames
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
    CALL    SUB_AEA7                        ; write C tiles from HL at DE, B times
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
    CALL    SUB_AA96
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
    CALL    SUB_AEA7
    INC     HL
    DEC     B
    CALL    SUB_AEA7
    INC     HL
    LD      B, $01
    CALL    SUB_AEA7
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
    CALL    SUB_AEA7
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
    CALL    SUB_AEA7
    INC     HL
    INC     HL
    PUSH    BC
    LD      BC, $0020
    EX      DE, HL
    ADD     HL, BC
    EX      DE, HL
    POP     BC
    CALL    SUB_AEA7

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
    CALL    SUB_AEA7
    JR      THING_DONE_JP

; Write the 2 tiles at $9FD2 + A at $71B0.
PUT_PAIR:
    LD      HL, $9FD2
    LD      B, $00
    LD      C, A
    ADD     HL, BC
    LD      BC, $0102
    LD      DE, ($71B0)
    CALL    SUB_AEA7

THING_DONE_JP:
    JP      THING_DONE

DRAW_OPEN_DOOR:
    CALL    CMD_POSITION
    LD      A, ($719A)
    ADD     A, $02
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

; Draw the inventory in the HUD: its 10 x 3 background ($85D7) at row 1,
; column 1, then the icon of each item in $71B2 (up to $FF), 2 columns
; apart (DRAW_ICON).
DRAW_INVENTORY:
    CALL    SUB_AEFE
    LD      DE, $0021
    LD      HL, $85D7
    LD      BC, $030A
    CALL    PUT_DOWN
    LD      HL, $71B2                       ; the inventory

LOC_A55A:                                   ; LOC_A55A:
    LD      A, (HL)                         ; A = (HL): read item table entry
    CP      $FF                             ; CP $FF: end-of-table sentinel?
    JP      Z, LOC_AABB                     ; JP Z, LOC_AABB: done -> update lives/score display
    PUSH    HL                              ; PUSH HL (save table pointer)
    PUSH    DE                              ; PUSH DE (save stride)
    CALL    DRAW_ICON                       ; the item's 2x2 icon
    POP     DE                              ; POP DE
    INC     DE                              ; INC DE: advance stride by 2
    INC     DE                              ; INC DE
    POP     HL                              ; POP HL
    INC     HL                              ; INC HL: next table entry
    JR      LOC_A55A                        ; JR LOC_A55A: loop until sentinel
    DB      $21, $B1, $71, $23, $7E, $FE, $FF, $20 ; inline Z80: LD HL,$71B1 / INC HL / LD A,(HL) ...
    DB      $FA, $7D, $FE, $B7, $37, $C8, $79, $FE ; inline Z80: CP $FF / JR NZ / LD A,L ...
    DB      $44, $20, $0F, $21, $00, $10, $22, $BD ; inline Z80: CP $B7 / SCF / RET Z / LD A,C ...
    DB      $70, $18, $08                   ; inline Z80: CP $44 / JR NZ / LD HL,$1000 ...

SUB_A587:
    CALL    SUB_AF70                        ; CALL SUB_AF70: BCD score add (IY=$7017 -> $7015/$7016/$7017)
    CALL    SUB_AEFE                        ; CALL SUB_AEFE: refresh score row on VRAM
    RET                                     ; RET: return from SUB_A587
    DB      $71, $CD, $48, $A5, $E5, $2A, $BD, $70 ; inline Z80: LD A,C / CALL $A548 / PUSH HL ...
    DB      $CD, $87, $A5, $E1, $37, $3F, $C9, $3E ; inline Z80: CALL $A587 / POP HL / SCF+CCF / RET ...
    DB      $06, $32, $49, $70, $21, $5F, $70, $CB ; inline Z80: LD A,$06 / LD ($7049) / LD HL,$705F ...
    DB      $D6, $CD, $06, $AC, $3E, $FF, $32, $A9 ; inline Z80: CB $D6 / CALL $AC06 / LD A,$FF ...
    DB      $70, $3E, $01, $32, $AD, $70, $21, $01 ; inline Z80: LD ($70A9) / LD A,$01 / LD ($70AD) ...
    DB      $00, $22, $E0, $72, $3E, $08, $32, $A8 ; inline Z80: LD HL,$0001 / LD ($72E0) / LD A,$08 ...
    DB      $71, $CD, $67, $A0, $CD, $7E, $8E, $3E ; inline Z80: LD ($71A8) / CALL $A067 / CALL $8E7E ...
    DB      $05, $32, $79, $70, $3A, $07, $72, $CB ; inline Z80: LD A,$05 / LD ($7079) / LD A,($7207) ...
    DB      $7F, $28, $F9, $AF, $32, $07, $72, $21 ; inline Z80: BIT 7 / JR Z / XOR A / LD ($7207) ...
    DB      $A1, $A8, $5E, $3A, $5F, $70, $CB, $5F ; inline Z80: LD HL,$A8A1 / LD E,(HL) / LD A,($705F)
    DB      $20, $F8, $23, $56, $7A, $FE, $FF, $28 ; inline Z80: BIT 3 / JR NZ / INC HL / LD E,(HL) ...
    DB      $E3, $23, $4E, $23, $46, $E5, $C5, $E1 ; inline Z80: LD D,A / CALL $AE3A / JR ...
    DB      $1A, $FE, $FE, $28, $0D, $FE, $01, $20 ; inline Z80: tail continued
    DB      $07, $D5, $E5, $CD, $3A, $AE, $E1, $D1 ; inline Z80: continued
    DB      $1A, $3D, $E1, $23, $FE, $00, $20, $01 ; inline Z80: continued
    DB      $7E, $12, $23, $18, $CD         ; inline Z80: end of SUB_A587 inline data

SUB_A60B:
    LD      HL, $705F                       ; HL = $705F (game mode flags)
    RES     3, (HL)                         ; RES 3, (HL): clear bit 3 = room-setup-needed
    LD      BC, $0182                       ; BC = $0182 (VDP reg 1, value $82 -- display enable)
    CALL    WRITE_REGISTER                  ; CALL WRITE_REGISTER: enable VDP display
    LD      BC, $0705                       ; BC = $0705 (VDP reg 7, value $05 -- border/palette)
    CALL    WRITE_REGISTER                  ; CALL WRITE_REGISTER: set border colour
    XOR     A                               ; A = $00 (fill value)
    LD      DE, $0300                       ; DE = $0300 (length: one name table row block)
    LD      HL, $1800                       ; HL = $1800 (VRAM name table base)
    CALL    FILL_VRAM                       ; CALL FILL_VRAM: blank $0300 bytes of name table
    LD      A, ($70AC)                      ; A = ($70AC) room entry mode
    CP      $01                             ; CP $01
    JR      Z, LOC_A678                     ; JR Z, LOC_A678: mode $01 = fast path (no enemy placement)
    LD      HL, ($7047)                     ; HL = ($7047) room data cursor pointer
    LD      B, $19                          ; B = $19 (25 enemy entries to process)
    LD      A, H                            ; A = H
    AND     $AE                             ; AND $AE: mask to enemy-data bank
    SET     7, A                            ; SET 7, A: set high bit (enemy data at $8000+)
    LD      H, A                            ; H = A (HL now points into enemy data bank)

LOC_A638:                                   ; LOC_A638: enemy placement loop
    PUSH    BC                              ; PUSH BC (save loop counter)
    LD      A, (HL)                         ; A = (HL): read enemy type byte
    AND     $07                             ; AND $07: isolate 3-bit type
    SET     1, A                            ; SET 1, A: set used flag
    LD      B, A                            ; B = A (tile number)
    LD      C, $01                          ; C = $01 (attribute flag)
    INC     HL                              ; INC HL
    LD      D, $01                          ; D = $01
    INC     HL                              ; INC HL
    LD      E, (HL)                         ; E = (HL): load enemy Y position
    INC     HL                              ; INC HL
    PUSH    HL                              ; PUSH HL (save room data pointer)
    PUSH    BC                              ; PUSH BC / POP BC (reload BC = tile/attr)
    POP     BC                              ; POP BC
    LD      HL, $A9AD                       ; HL = $A9AD (enemy sprite tile table)
    CALL    SUB_AA96                        ; CALL SUB_AA96: SET bit 2 WORK_BUFFER -> write enemy sprite to VRAM
    POP     HL                              ; POP HL (restore room data pointer)
    POP     BC                              ; POP BC (restore loop counter)
    DJNZ    LOC_A638                        ; DJNZ LOC_A638: process all 25 enemy entries
    LD      A, ($71A6)                      ; A = ($71A6) room difficulty
    SRA     A                               ; SRA A: difficulty / 2
    ADD     A, $08                          ; ADD A, $08: base count = 8 + difficulty/2
    LD      B, A                            ; B = A (number of item entries to place)
    LD      A, ($7047)                      ; A = ($7047) room data ptr lo
    AND     $1F                             ; AND $1F: item index (5 bits)
    LD      D, $01                          ; D = $01
    LD      E, A                            ; E = A (item data)

LOC_A664:                                   ; LOC_A664: item placement loop
    PUSH    BC                              ; PUSH BC (save loop counter)
    LD      ($71B0), DE                     ; ($71B0) = DE: store current item data
    LD      A, $44                          ; A = $44 (item tile number)
    PUSH    DE                              ; PUSH DE
    CALL    DRAW_ICON                       ; the item's 2x2 icon
    POP     HL                              ; POP HL
    LD      BC, $0027                       ; BC = $0027 (39 bytes per item slot)
    ADD     HL, BC                          ; ADD HL, BC: advance item pointer
    DB      $EB                             ; DB $EB: EX DE,HL
    POP     BC                              ; POP BC (restore loop counter)
    DJNZ    LOC_A664                        ; DJNZ LOC_A664: place all items

LOC_A678:
    LD      A, ($71A8)                      ; A = ($71A8) room type
    CP      $0A                             ; CP $0A: outdoor room?
    JR      Z, LOC_A695                     ; JR Z, LOC_A695: outdoor -> skip door sprites
    LD      DE, BOOT_UP                     ; DE = BOOT_UP ($0000 -- door tile offset base)
    LD      HL, $A9AE                       ; HL = $A9AE (door sprite tile table)
    CP      $0B                             ; CP $0B: check for special room type $0B
    JR      NZ, LOC_A68F                    ; JR NZ, LOC_A68F: not $0B -> use default door table
    LD      HL, $A9B0                       ; HL = $A9B0 (special door tile table)
    LD      DE, $001D                       ; DE = $001D (door stride)

LOC_A68F:                                   ; LOC_A68F:
    LD      BC, $1803                       ; BC = $1803 (VRAM name table addr $1803)
    CALL    SUB_AA96                        ; CALL SUB_AA96: write door sprites to VRAM name table

LOC_A695:                                   ; LOC_A695:
    CALL    SUB_AEFE                        ; CALL SUB_AEFE: VDP address setup (flush score row)
    LD      BC, $01E2                       ; BC = $01E2 (VDP reg 1, value $E2 -- enable display + sprites)
    CALL    WRITE_REGISTER                  ; CALL WRITE_REGISTER: enable VDP display with sprites
    RET                                     ; RET: return after WRITE_REGISTER
    DB      $E5, $21, $97, $70, $34, $E1, $3A, $97 ; enemy movement inline Z80: PUSH HL / LD HL,$7097 ...
    DB      $70, $E6, $11, $FE, $00, $20, $02, $37 ; enemy movement inline Z80: LD A,($7070) / AND $11 ...
    DB      $C9, $37, $3F, $C9, $D1, $D5, $13, $1A ; enemy movement inline Z80: CP $80 / JR Z / INC HL ...
    DB      $E6, $80, $47, $1A, $E6, $7F, $3D, $F2 ; enemy movement inline Z80: CP $80 / LD A,A ...
    DB      $C3, $A6, $3E, $05, $80, $12, $E6, $7F ; enemy movement inline Z80: continued ...
    DB      $FE, $00, $20, $1D, $D1, $E1, $E5, $D5 ; enemy movement inline Z80: JR NZ / LD HL,($7057) ...
    DB      $23, $23, $23, $7E, $FE, $00, $28, $0C ; enemy movement inline Z80: LD A,($704A) / CP $00 ...
    DB      $3A, $4A, $70, $FE, $00, $3E, $0C, $28 ; enemy movement inline Z80: CALL $A69F / PUSH HL ...
    DB      $02, $3E, $0E, $77, $2B, $7E, $EE, $1C ; enemy movement inline Z80: JR NC / LD A,($70AB) ...
    DB      $77, $21, $5A, $70, $7E, $23, $FE, $10 ; enemy movement inline Z80: JR NZ / CALL $ABEC ...
    DB      $20, $71, $7E, $FE, $11, $20, $6C, $E1 ; enemy movement inline Z80: CALL $ABCE / CB $BE ...
    DB      $7E, $CB, $6F, $20, $1E, $CD, $9F, $A6 ; enemy movement inline Z80: CB $EE / JP $A88F ...
    DB      $E5, $38, $60, $3A, $AB, $70, $FE, $02 ; enemy movement inline Z80: CB $AE / CALL $A69F ...
    DB      $20, $59, $E1, $CD, $ED, $AB, $E3, $7E ; enemy movement inline Z80: LD A,$08 / JR NC ...
    DB      $C6, $02, $77, $E1, $CB, $EE, $CB, $FE ; enemy movement inline Z80: LD A,$FE / EX AF ...
    DB      $C3, $8F, $A8, $CB, $7F, $20, $1C, $CB ; enemy movement inline Z80: LD C,$FF / LD A,($705B)
    DB      $AE, $CD, $9F, $A6, $3E, $08, $38, $06 ; enemy movement inline Z80: CP $E8 / JR Z / CP $08 ...
    DB      $7E, $EE, $80, $77, $3E, $FE, $E3, $23 ; enemy movement inline Z80: CALL $A69F / JR NC ...
    DB      $86, $77, $2B, $7E, $C6, $F9, $77, $E1 ; enemy movement inline Z80: CB $FE / LD B,$FE ...
    DB      $C3, $8F, $A8, $0E, $FF, $3A, $5B, $70 ; enemy movement inline Z80: LD C,$00 / CB $AE ...
    DB      $FE, $E8, $28, $04, $FE, $08, $20, $15 ; enemy movement inline Z80: JP $A87F / LD HL,$7057 ...
    DB      $CD, $9F, $A6, $38, $06, $CB, $FE, $06 ; enemy movement inline Z80: CP $88 / JR NZ / CP $89 ...
    DB      $FE, $18, $04, $CB, $BE, $06, $08, $0E ; enemy movement inline Z80: JR NZ / LD A,($70AB) ...
    DB      $00, $CB, $AE, $18, $02, $06, $00, $E3 ; enemy movement inline Z80: CALL NZ / CB $6E ...
    DB      $C3, $7F, $A8, $21, $57, $70, $7E, $23 ; enemy movement inline Z80: CALL $A69F / PUSH HL ...
    DB      $FE, $88, $20, $2B, $7E, $FE, $89, $20 ; enemy movement inline Z80: CB $BE / CB $EE / LD A,$00
    DB      $26, $3A, $AB, $70, $FE, $02, $20, $1F ; enemy movement inline Z80: JR / CB $7E / JR NZ ...
    DB      $E1, $CB, $6E, $20, $12, $CD, $9F, $A6 ; enemy movement inline Z80: LD BC,$0000 / CB $6E ...
    DB      $E5, $38, $14, $E1, $CD, $ED, $AB, $CB ; enemy movement inline Z80: JP $A82F / LD HL,$7086 ...
    DB      $BE, $CB, $EE, $3E, $00, $18, $9F, $CB ; enemy movement inline Z80: CALL NZ / AND $07 ...
    DB      $7E, $20, $A8, $0E, $01, $18, $C6, $E1 ; enemy movement inline Z80: CALL $A540 / PUSH HL ...
    DB      $01, $00, $00, $CB, $6E, $20, $F0, $C3 ; enemy movement inline Z80: CALL $5991 / POP HL ...
    DB      $2F, $A8, $21, $86, $70, $7E, $FE, $FF ; enemy movement inline Z80: CP $15 / JR C ...
    DB      $C8, $E5, $E6, $07, $CB, $27, $CB, $27 ; enemy movement inline Z80: CB $77 / PUSH HL ...
    DB      $21, $00, $73, $CD, $40, $A5, $E5, $CD ; enemy movement inline Z80: JR NZ / POP DE ...
    DB      $59, $91, $E1, $7E, $E3, $FE, $15, $38 ; enemy movement inline Z80: CP $00 / JR Z ...
    DB      $04, $FE, $B8, $38, $04, $7E, $EE, $80 ; enemy movement inline Z80: CP $0F / JR Z ...
    DB      $77, $7E, $CB, $77, $E5, $C2, $B3, $A6 ; enemy movement inline Z80: CB $5F / JR NZ ...
    DB      $E1, $D1, $D5, $F5, $13, $13, $13, $EB ; enemy movement inline Z80: INC HL / LD A,(HL) ...
    DB      $7E, $FE, $00, $28, $0C, $3A, $4A, $70 ; enemy movement inline Z80: LD (HL),A / LD A,(HL) ...
    DB      $FE, $00, $3E, $0F, $28, $02, $3E, $0E ; enemy movement inline Z80: CB $7F / LD C,$FC ...
    DB      $77, $EB, $F1, $CB, $5F, $28, $2F, $23 ; enemy movement inline Z80: LD C,$04 / EX (SP),HL ...
    DB      $7E, $3C, $77, $2B, $E6, $0F, $FE, $04 ; enemy movement inline Z80: CP $2C / JR NZ / LD A,$0C
    DB      $20, $24, $23, $7E, $E6, $80, $77, $2B ; enemy movement inline Z80: CP $08 / JR NZ / LD A,$28 ...
    DB      $7E, $CB, $7F, $0E, $FC, $28, $02, $0E ; enemy movement inline Z80: BIT 0 / JR Z / LD A,($7085)
    DB      $04, $E3, $E5, $23, $23, $7E, $81, $FE ; enemy movement inline Z80: CP $08 / JR C / CP $F5 ...
    DB      $2C, $20, $02, $3E, $0C, $FE, $08, $20 ; enemy movement inline Z80: LD A,($705B) / CP $00 ...
    DB      $02, $3E, $28, $77, $E1, $E3, $7E, $CB ; enemy movement inline Z80: LD A,(HL) / BIT 7 ...
    DB      $67, $28, $0D, $3A, $85, $70, $FE, $08 ; enemy movement inline Z80: JR NZ / LD A,(HL) / BIT 7
    DB      $38, $1D, $FE, $F5, $30, $19, $18, $1B ; enemy movement inline Z80: LD C,$00 / JR NZ ...
    DB      $3A, $5B, $70, $FE, $00, $28, $10, $7E ; enemy movement inline Z80: INC HL / LD A,(HL) ...
    DB      $CB, $7F, $3A, $57, $70, $20, $03, $3A ; enemy movement inline Z80: LD D,A / LD A,E / AND $7F
    DB      $59, $70, $CD, $94, $A8, $20, $04, $7E ; enemy movement inline Z80: LD A,$39 / LD (HL),A ...
    DB      $EE, $80, $77, $7E, $CB, $5F, $0E, $00 ; enemy movement inline Z80: PUSH HL,DE / PUSH HL ...
    DB      $20, $18, $E5, $23, $7E, $E6, $80, $47 ; enemy movement inline Z80: LD B,$01 / CB $7F ...
    DB      $7E, $E6, $7F, $3D, $F2, $60, $A8, $3E ; enemy movement inline Z80: CB $7F / JR Z / LD B,A ...
    DB      $39, $77, $21, $B3, $AB, $CD, $40, $A5 ; enemy movement inline Z80: LD A,(HL) / SUB B ...
    DB      $4E, $E1, $7E, $E3, $06, $01, $CB, $7F ; enemy movement inline Z80: ADD A,(HL) / LD (HL),A ...
    DB      $28, $02, $06, $FF, $E3, $23, $7E, $2B ; enemy movement inline Z80: INC HL (x2) / JP $A7A4 ...
    DB      $E3, $CB, $7F, $28, $03, $78, $80, $47 ; enemy movement inline Z80: CPIR / POP BC / POP HL ...
    DB      $7E, $91, $77, $23, $7E, $80, $77, $E1 ; enemy movement inline Z80: LD A,($7370) / LD ($705F) ...
    DB      $FE, $08, $30, $04, $7E, $EE, $80, $77 ; enemy movement inline Z80: LD A,($7001) / LD B,$FF ...
    DB      $23, $23, $C3, $A4, $A7, $E5, $C5, $21 ; enemy movement inline Z80: LD A,$FF / LD A,$FF (end)
    DB      $3C, $94, $01, $08, $00, $ED, $B1, $C1 ; enemy movement inline Z80: tail continued
    DB      $E1, $C9, $73, $70, $E5, $91, $02, $12 ; enemy movement inline Z80: continued
    DB      $70, $5F, $8F, $04, $68, $70, $D1, $88 ; enemy movement inline Z80: continued
    DB      $01, $74, $70, $D6, $A8, $01, $FF, $FF ; enemy movement inline Z80: end of enemy movement data

SUB_A8B7:
    PUSH    HL                              ; PUSH HL
    LD      HL, $705F                       ; HL = $705F (game mode flags)
    SET     1, (HL)                         ; SET 1, (HL): set bit 1 = VRAM-write-in-progress (pause game logic)
    LD      HL, $70AF                       ; HL = $70AF (VRAM nesting counter)
    INC     (HL)                            ; INC (HL): increment VRAM nesting counter
    POP     HL                              ; POP HL
    RET                                     ; RET: return from VRAM-lock enter

SUB_A8C3:
    PUSH    HL                              ; PUSH HL
    PUSH    AF                              ; PUSH AF
    LD      HL, $70AF                       ; HL = $70AF (VRAM nesting counter)
    DEC     (HL)                            ; DEC (HL): decrement nesting counter
    LD      A, (HL)                         ; A = (HL)
    CP      $00                             ; CP $00: fully exited?
    JR      NZ, LOC_A8D3                    ; JR NZ, LOC_A8D3: still nested -> keep game paused
    LD      HL, $705F                       ; HL = $705F
    RES     1, (HL)                         ; RES 1, (HL): clear bit 1 = game logic can resume

LOC_A8D3:
    POP     AF                              ; POP AF: restore AF
    POP     HL                              ; POP HL: restore HL
    RET                                     ; RET: return from SUB_A8C3
    DB      $3A, $A8, $70, $3D, $20, $02, $3E, $60 ; inline Z80: LD A,($70A8) / DEC A / JR NZ / LD A,$60
    DB      $32, $A8, $70, $FE, $60, $20, $2E, $21 ; inline Z80: LD ($70A8) / CP $60 / JR NZ / LD HL,$7000
    DB      $00, $70, $CB, $F6, $21, $CD, $AB, $11 ; inline Z80: SET 6,(HL) / LD HL,$ABCD / LD DE,$001D ...
    DB      $1D, $00, $CD, $05, $A9, $3A, $A8, $70 ; inline Z80: CALL $A905 / LD A,($70A8) ...
    DB      $FE, $60, $20, $27, $21, $00, $70, $CB ; inline Z80: CP $60 / JR NZ / LD HL,$7000 / CB $EE ...
    DB      $EE, $21, $CD, $AB, $11, $1C, $00, $D5 ; inline Z80: LD HL,$ABCD / LD DE,$001C ...
    DB      $E5, $E1, $D1, $FD, $21, $01, $00, $3E ; inline Z80: PUSH DE / PUSH HL / POP HL / POP DE ...
    DB      $04, $CD, $2E, $AE, $C9, $FE, $48, $20 ; inline Z80: LD IY,$0001 / LD A,$04 / CALL $AE2E ...
    DB      $DC, $21, $00, $70, $CB, $B6, $21, $2E ; inline Z80: RET / CP $48 / JR NZ / LD HL,$7000 ...
    DB      $A9, $18, $CC, $FE, $30, $C0, $21, $00 ; inline Z80: CB $B6 / LD HL,$A92E / JR ...
    DB      $70, $CB, $AE, $21, $2E, $A9, $18, $D4 ; inline Z80: CP $30 / RET NZ / LD HL,$7000 ...
    DB      $40                             ; inline Z80: CB $AE / LD HL,$A92E / JR / DB $40

SUB_A92F:
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: VRAM-lock enter
    LD      A, ($73F9)                      ; A = ($73F9) SN76489A frequency byte to write
    LD      ($7085), A                      ; ($7085) = A: cache frequency byte
    LD      C, $00                          ; C = $00 (frame 0)
    XOR     A                               ; A = $00 (offset 0)
    CALL    SUB_A97A                        ; CALL SUB_A97A: write SN76489A frame 0 ($73F9=$00)
    LD      C, $01                          ; C = $01 (frame 1)
    LD      A, $08                          ; A = $08
    CALL    SUB_A97A                        ; CALL SUB_A97A: write SN76489A frame 1 ($73F9=$08)
    LD      C, $02                          ; C = $02 (frame 2)
    LD      A, $10                          ; A = $10
    CALL    SUB_A97A                        ; CALL SUB_A97A: write SN76489A frame 2 ($73F9=$10)
    LD      C, $05                          ; C = $05 (frame 3)
    LD      A, $28                          ; A = $28
    CALL    SUB_A97A                        ; CALL SUB_A97A: write SN76489A frame 3 ($73F9=$28)
    LD      A, ($7085)                      ; A = ($7085) cached frequency byte
    CP      $00                             ; CP $00
    JR      NZ, LOC_A95C                    ; JR NZ, LOC_A95C: nonzero -> check frame 1
    LD      C, $00                          ; C = $00: frame selector = 0

LOC_A95C:                                   ; LOC_A95C:
    CP      $08                             ; CP $08
    JR      NZ, LOC_A962                    ; JR NZ, LOC_A962
    LD      C, $01                          ; C = $01: frame selector = 1

LOC_A962:                                   ; LOC_A962:
    CP      $10                             ; CP $10
    JR      NZ, LOC_A968                    ; JR NZ, LOC_A968
    LD      C, $02                          ; C = $02: frame selector = 2

LOC_A968:                                   ; LOC_A968:
    CP      $28                             ; CP $28
    JR      NZ, LOC_A96E                    ; JR NZ, LOC_A96E
    LD      C, $05                          ; C = $05: frame selector = 3

LOC_A96E:                                   ; LOC_A96E:
    LD      ($73F9), A                      ; ($73F9) = A: store final frequency byte
    LD      B, $04                          ; B = $04 (VDP register 4)
    CALL    WRITE_REGISTER                  ; CALL WRITE_REGISTER: write VDP register 4 with C value
    CALL    SUB_A8C3                        ; CALL SUB_A8C3: VRAM-lock exit
    RET                                     ; RET: return from LOC_A96E

SUB_A97A:
    LD      ($73F9), A                      ; RAM $73F9
    LD      B, $04                          ; LD B,$04: B = $04 (VDP register 4)
    CALL    WRITE_REGISTER                  ; CALL WRITE_REGISTER: write pattern table reg
    LD      A, ($7096)                      ; RAM $7096
    PUSH    AF                              ; PUSH AF: save direction index
    SLA     A                               ; SLA A: index * 2 for pattern offset
    LD      HL, $85BC                       ; LD HL,$85BC: HL = $85BC (tile pattern data)
    LD      DE, $00E0                       ; LD DE,$00E0: DE = $00E0 (VRAM dest pattern)
    CALL    SUB_A9A0                        ; CALL SUB_A9A0: write first pattern block
    LD      HL, $85CA                       ; LD HL,$85CA: HL = $85CA (second pattern data)
    LD      DE, $00E8                       ; LD DE,$00E8: DE = $00E8 (VRAM dest second)
    POP     AF                              ; POP AF: restore direction index
    AND     $01                             ; AND $01: keep bit 0 (even/odd direction)
    SLA     A                               ; SLA A: shift for sub-pattern offset
    SLA     A                               ; SLA A: shift again
    SLA     A                               ; SLA A: A = sub-pattern offset * 8

SUB_A9A0:
    CALL    TABLE_BYTE                      ; A = (HL + A)
    LD      IY, $0001                       ; LD IY,$0001: IY = 1 (byte count for PUT_VRAM)
    LD      A, $03                          ; LD A,$03: A = $03 (PUT_VRAM mode)
    CALL    SUB_AE2E                        ; CALL SUB_AE2E: write tile pattern via PUT_VRAM
    RET                                     ; RET: return from SUB_A9A0
    DB      $90, $08, $00, $95, $00, $08    ; SUB_A9A0 post-RET: tile VRAM-write params table

; =============================================================================
; NMI HANDLER -- NMI (~$AA00)
; Reached via CART_ENTRY JP.  Saves every register (AF, BC, DE, HL, IX, IY
; and all alternates) before any game work.
;   $70B1 bit 7: re-entry guard (SET on entry, RES on exit)
;   $70B1 bit 3: CALL NZ, SUB_919A -- score / game-bit update
;   $705F bit 1: skip game logic (pause / attract mode)
;   $705F bit 3: CALL NZ, SUB_A60B -- room renderer + enemy placement
;   $70B1 bit 4: CALL NZ, DELAY_LOOP_8EB0 -- full per-frame game body
;   INC ($7097)    frame counter
;   INC ($7047)    pointer advance (room data cursor)
;   $7011 (sub-frame counter 1-4): cycle through 4 SN76489A sound frames
;     via SUB_A92F (write next sound byte to SOUND_PORT)
;   DEC ($7207)    sprite flicker counter
;   CALL WR_SPR_NM_TBL  flush sprite name table ($08 sprites)
;   CALL SUB_AC6D  sound channel sequencer (drives $702C/$702E music data)
;   LOC_AA45: CALL READ_REGISTER (read VDP status, clear interrupt flag)
;   RES 7, ($70B1) / RETN
; =============================================================================
NMI:
    PUSH    AF                              ; PUSH AF: save main register set
    PUSH    BC                              ; PUSH BC
    PUSH    DE                              ; PUSH DE
    PUSH    HL                              ; PUSH HL
    PUSH    IX                              ; PUSH IX
    PUSH    IY                              ; PUSH IY
    EX      AF, AF'                         ; EX AF, AF: swap to alternate A/F
    EXX                                     ; EXX: swap to alternate BC/DE/HL
    PUSH    AF                              ; PUSH AF: save alternate AF
    PUSH    BC                              ; PUSH BC: save alternate BC
    PUSH    DE                              ; PUSH DE: save alternate DE
    PUSH    HL                              ; PUSH HL: save alternate HL
    LD      HL, $70B1                       ; HL = $70B1 (NMI flag byte)
    BIT     7, (HL)                         ; BIT 7, (HL): re-entry guard
    JP      NZ, LOC_AA4D                    ; JP NZ, LOC_AA4D: already in NMI -> skip to exit (prevents re-entry)
    SET     7, (HL)                         ; SET 7, (HL): mark NMI in-progress
    BIT     3, (HL)                         ; BIT 3, (HL): score-update pending?
    RES     3, (HL)                         ; RES 3, (HL): clear score-update flag
    CALL    NZ, SUB_919A                    ; CALL NZ, SUB_919A: score update (SET WORK_BUFFER bit 0, clear room data)
    LD      A, ($705F)                      ; A = ($705F) game mode flags
    BIT     1, A                            ; BIT 1, A: pause flag
    JR      NZ, LOC_AA45                    ; JR NZ, LOC_AA45: paused -> skip all game logic
    BIT     3, A                            ; BIT 3, A: room-setup needed?
    CALL    NZ, SUB_A60B                    ; CALL NZ, SUB_A60B: yes -> room renderer + enemy placement
    LD      HL, $70B1                       ; HL = $70B1
    BIT     4, (HL)                         ; BIT 4, (HL): frame-body pending?
    RES     4, (HL)                         ; RES 4, (HL): clear frame-body flag
    CALL    NZ, DELAY_LOOP_8EB0             ; CALL NZ, DELAY_LOOP_8EB0: run full per-frame game body
    LD      HL, $7097                       ; HL = $7097 (frame counter)
    INC     (HL)                            ; INC (HL): increment frame counter each NMI
    LD      HL, ($7047)                     ; HL = ($7047) room data cursor
    INC     HL                              ; INC HL: advance room data cursor
    LD      ($7047), HL                     ; ($7047) = HL: store updated cursor
    LD      A, ($7011)                      ; A = ($7011) sub-frame counter (1-4)
    INC     A                               ; INC A
    BIT     7, A                            ; BIT 7, A: wrapped past 4?
    JR      NZ, LOC_AA39                    ; JR NZ, LOC_AA39: counter wrapped -> reset + final sound frame
    LD      ($7011), A                      ; ($7011) = A: store incremented sub-frame counter
    CP      $01                             ; CP $01
    JR      NZ, LOC_AA08                    ; JR NZ, LOC_AA08: not frame 1
    LD      BC, $0400                       ; BC = $0400 (sound frame 0 params)
    XOR     A                               ; A = $00 (sound frequency sub-byte 0)
    JR      LOC_AA2C                        ; JR LOC_AA2C

LOC_AA08:                                   ; LOC_AA08:
    CP      $02                             ; CP $02
    JR      NZ, LOC_AA13                    ; JR NZ, LOC_AA13: not frame 2
    LD      BC, $0401                       ; BC = $0401 (sound frame 1)
    LD      A, $08                          ; A = $08
    JR      LOC_AA2C                        ; JR LOC_AA2C

LOC_AA13:                                   ; LOC_AA13:
    CP      $03                             ; CP $03
    JR      NZ, LOC_AA1E                    ; JR NZ, LOC_AA1E: not frame 3
    LD      BC, $0402                       ; BC = $0402 (sound frame 2)
    LD      A, $10                          ; A = $10
    JR      LOC_AA2C                        ; JR LOC_AA2C

LOC_AA1E:                                   ; LOC_AA1E:
    CP      $04                             ; CP $04
    JR      NZ, LOC_AA39                    ; JR NZ, LOC_AA39: not frame 4 -> skip
    LD      HL, $7011                       ; HL = $7011
    LD      (HL), $00                       ; (HL) = $00: reset sub-frame counter
    LD      BC, $0405                       ; BC = $0405 (sound frame 3 params)
    LD      A, $28                          ; A = $28 (sound frequency sub-byte 3)

LOC_AA2C:                                   ; LOC_AA2C:
    LD      ($73F9), A                      ; ($73F9) = A: store SN76489A frequency byte
    CALL    SUB_A92F                        ; CALL SUB_A92F: write SN76489A sound frame (4-frame cycle)
    LD      HL, $7011                       ; HL = $7011
    LD      A, (HL)                         ; A = (HL) sub-frame counter
    XOR     $80                             ; XOR $80: toggle bit 7 (mark frame written)
    LD      (HL), A                         ; (HL) = A

LOC_AA39:                                   ; LOC_AA39:
    LD      HL, $7207                       ; HL = $7207 (sprite flicker counter)
    DEC     (HL)                            ; DEC (HL): decrement flicker counter
    LD      A, $08                          ; A = $08 (8 sprites)
    CALL    WR_SPR_NM_TBL                   ; CALL WR_SPR_NM_TBL: write sprite name table to VRAM
    CALL    SUB_AC6D                        ; CALL SUB_AC6D: sound channel sequencer

LOC_AA45:                                   ; LOC_AA45:
    CALL    READ_REGISTER                   ; CALL READ_REGISTER: read VDP status (clears interrupt latch)
    LD      HL, $70B1                       ; HL = $70B1
    RES     7, (HL)                         ; RES 7, (HL): clear re-entry guard (NMI done)

LOC_AA4D:                                   ; LOC_AA4D:
    POP     HL                              ; POP HL: restore alternate HL
    POP     DE                              ; POP DE
    POP     BC                              ; POP BC
    POP     AF                              ; POP AF: restore alternate register set
    EX      AF, AF'                         ; EX AF, AF: restore main AF
    EXX                                     ; EXX: restore main BC/DE/HL
    POP     IY                              ; POP IY
    POP     IX                              ; POP IX
    POP     HL                              ; POP HL
    POP     DE                              ; POP DE
    POP     BC                              ; POP BC
    POP     AF                              ; POP AF: all registers restored
    RETN                                    ; RETN: return from NMI

SUB_AA5D:
    LD      DE, $0001                       ; DE = $0001 (sprite attribute stride)
    LD      BC, $0A01                       ; BC = $0A01 (B=10 rows, C=$01 tile attribute)
    CALL    SUB_AAA8                        ; CALL SUB_AAA8: render 10 enemy sprite rows
    LD      BC, $0801                       ; BC = $0801 (B=8 rows, C=$01)
    LD      DE, $0017                       ; DE = $0017 (second sprite block offset)
    CALL    SUB_AAA8                        ; CALL SUB_AAA8: render 8 more enemy sprite rows
    LD      HL, $AA88                       ; HL = $AA88 (sprite tile table)
    LD      BC, $030C                       ; BC = $030C (B=3, C=$0C stride)
    LD      DE, $0020                       ; DE = $0020 (sprite attribute offset)
    CALL    SUB_AA96                        ; CALL SUB_AA96: SET WORK_BUFFER bit 2 + call SUB_AEA7
    LD      DE, $0036                       ; DE = $0036 (next sprite block offset)
    LD      HL, $AA89                       ; HL = $AA89
    LD      BC, $030A                       ; BC = $030A
    CALL    SUB_AA96                        ; CALL SUB_AA96: render second set
    RET                                     ; RET: return from sprite setup
    DB      $0A, $0A, $00, $00, $00, $00, $00, $00 ; sprite tile table: extra tile IDs row (post-RET start)
    DB      $00, $00, $0B, $0B, $09, $0C    ; sprite tile table: continued + extra IDs

SUB_AA96:
    PUSH    HL                              ; PUSH HL
    LD      HL, WORK_BUFFER                 ; HL = WORK_BUFFER ($7000)
    SET     2, (HL)                         ; SET 2, (HL): set bit 2 = VRAM-write-in-progress
    POP     HL                              ; POP HL
    CALL    SUB_AEA7                        ; CALL SUB_AEA7: inner VRAM tile write loop
    PUSH    HL                              ; PUSH HL
    LD      HL, WORK_BUFFER                 ; HL = WORK_BUFFER
    RES     2, (HL)                         ; RES 2, (HL): clear VRAM-write flag
    POP     HL                              ; POP HL
    RET                                     ; RET

SUB_AAA8:
    LD      HL, $AA94                       ; HL = $AA94 (sprite tile data)
    CALL    SUB_AEA7                        ; CALL SUB_AEA7: write first block to VRAM
    DB      $EB                             ; DB $EB: EX DE,HL
    LD      DE, $0080                       ; DE = $0080 (half-tile stride offset)
    ADD     HL, DE                          ; ADD HL, DE: advance DE by $80
    DB      $EB                             ; DB $EB: EX DE,HL (restore)
    LD      HL, $AA95                       ; HL = $AA95 (second sprite tile data)
    CALL    SUB_AEA7                        ; CALL SUB_AEA7: write second block to VRAM (offset by $80)
    RET                                     ; RET: return from SUB_AAA8

LOC_AABB:
    LD      A, ($705F)                      ; A = ($705F) game mode flags
    BIT     5, A                            ; BIT 5, A: tile-skip flag
    RET     NZ                              ; RET NZ: tile-skip set -> suppress lives display
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: INC $70AF + SET bit 1 $705F (VRAM-lock enter)
    LD      HL, $1861                       ; HL = $1861 (VRAM lives display area)
    LD      DE, $0008                       ; DE = $0008 (clear 8 tiles)
    XOR     A                               ; A = $00 (fill with blank tile $00)
    CALL    SUB_AE25                        ; CALL SUB_AE25: clear lives area in VRAM
    LD      HL, $1877                       ; HL = $1877 (VRAM score display area)
    LD      DE, $0008                       ; DE = $0008
    XOR     A                               ; A = $00
    CALL    SUB_AE25                        ; CALL SUB_AE25: clear score area in VRAM
    LD      A, ($7049)                      ; A = ($7049) life counter
    PUSH    AF                              ; PUSH AF: save life count for later
    CP      $01                             ; CP $01: only 1 life?
    JR      Z, LOC_AB07                     ; JR Z, LOC_AB07: 1 life -> skip icon rendering
    DEC     A                               ; DEC A: lives-1 = number of extra life icons
    LD      HL, $1861                       ; HL = $1861 (lives display row)
    LD      E, A                            ; E = A (number of icons)
    CP      $0B                             ; CP $0B: > 11 icons?
    JR      C, LOC_AB00                     ; JR C, LOC_AB00: fits in first row
    LD      DE, $000A                       ; DE = $000A (cap at 10 first-row icons)
    LD      A, $6F                          ; A = $6F (life-icon tile number)
    CALL    SUB_AE25                        ; CALL SUB_AE25: fill 10 life-icon tiles in row 1
    POP     AF                              ; POP AF
    DEC     A                               ; DEC A
    PUSH    AF                              ; PUSH AF
    SUB     $0A                             ; SUB $0A: remainder for row 2
    LD      HL, $1877                       ; HL = $1877 (second lives row)
    LD      E, $08                          ; E = $08 (cap at 8 for row 2)
    CP      $09                             ; CP $09
    JR      NC, LOC_AB00                    ; JR NC, LOC_AB00: overflow -> use cap
    LD      E, A                            ; E = A (actual remainder count)

LOC_AB00:                                   ; LOC_AB00:
    LD      D, $00                          ; D = $00
    LD      A, $6F                          ; A = $6F (life-icon tile)
    CALL    SUB_AE25                        ; CALL SUB_AE25: render life icons in second row

LOC_AB07:                                   ; LOC_AB07:
    POP     AF                              ; POP AF
    CALL    SUB_A8C3                        ; CALL SUB_A8C3: DEC $70AF, RES bit 1 $705F if zero (VRAM-lock exit)
    RET                                     ; RET: return from lives/score display
    DB      $10, $11, $11, $10, $88, $89, $89, $88 ; lives/score tile table: tile IDs for display icons
    DB      $04, $BA, $06, $B8, $B8, $06, $BA, $04 ; lives/score tile table: continued icon IDs
    DB      $05, $B9, $B9, $05, $FF         ; lives/score tile table: sentinel $FF

LOC_AB21:
    PUSH    AF                              ; PUSH AF: save matched tile byte
    INC     HL                              ; INC HL: advance to replacement tile byte
    LD      A, (HL)                         ; LD A,(HL): A = replacement tile byte
    LD      (DE), A                         ; LD (DE),A: store replacement to sprite RAM
    POP     AF                              ; POP AF: restore original tile byte
    DEC     HL                              ; DEC HL: restore HL to match entry
    JR      LOC_AB6B                        ; JR LOC_AB6B: advance to next sprite byte

SUB_AB29:
    PUSH    HL                              ; PUSH HL: save sprite table pointer
    PUSH    DE                              ; PUSH DE: save dest pointer
    PUSH    BC                              ; PUSH BC: save loop params
    PUSH    AF                              ; PUSH AF: save caller AF
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: VRAM-lock enter
    LD      A, $13                          ; LD A,$13: A = $13 (19 sprite rows)
    LD      ($7002), A                      ; RAM $7002
    LD      HL, $7200                       ; RAM $7200
    LD      DE, $00A0                       ; LD DE,$00A0: DE = $00A0 (sprite stride)
    LD      IY, $0020                       ; LD IY,$0020: IY = $20 (sprite row width)
    LD      A, $02                          ; LD A,$02: A = $02 (initial row counter)

LOC_AB41:
    PUSH    HL                              ; PUSH HL: save current sprite row pointer
    PUSH    IY                              ; PUSH IY: save row width
    PUSH    AF                              ; PUSH AF: save row counter
    PUSH    DE                              ; PUSH DE: save stride
    CALL    GET_VRAM                        ; CALL GET_VRAM: read tile bytes from VRAM
    POP     DE                              ; POP DE: restore stride after GET_VRAM
    PUSH    DE                              ; PUSH DE: re-save stride
    PUSH    HL                              ; PUSH HL: save VRAM read result
    PUSH    DE                              ; PUSH DE: save stride second time
    PUSH    BC                              ; PUSH BC: save outer loop BC
    LD      DE, $7200                       ; RAM $7200
    LD      B, $20                          ; LD B,$20: B = $20 (32 bytes per sprite row)

LOC_AB53:
    LD      HL, $AB0C                       ; LD HL,$AB0C: HL = match table base

LOC_AB56:
    LD      A, (HL)                         ; LD A,(HL): A = match table entry byte
    CP      $FF                             ; CP $FF: end of match table?
    JR      Z, LOC_AB6B                     ; JR Z,LOC_AB6B: yes -> no match, next byte
    LD      A, (DE)                         ; LD A,(DE): A = sprite data byte
    CP      $08                             ; CP $08: sprite byte = $08 (blank)?
    JR      Z, LOC_AB6B                     ; JR Z,LOC_AB6B: blank -> skip
    CP      $00                             ; CP $00: sprite byte = $00 (empty)?
    JR      Z, LOC_AB6B                     ; JR Z,LOC_AB6B: empty -> skip
    CP      (HL)                            ; CP (HL): sprite byte matches table entry?
    JR      Z, LOC_AB21                     ; JR Z,LOC_AB21: match -> do replacement
    INC     HL                              ; INC HL: advance match table pointer
    INC     HL                              ; INC HL: skip replacement byte too
    JR      LOC_AB56                        ; JR LOC_AB56: check next table entry

LOC_AB6B:
    INC     DE                              ; INC DE: advance sprite data pointer
    DJNZ    LOC_AB53                        ; DJNZ LOC_AB53: loop 32 bytes per row
    POP     BC                              ; POP BC: restore outer loop BC
    POP     DE                              ; POP DE: restore stride
    POP     HL                              ; POP HL: restore sprite row pointer
    LD      A, ($7002)                      ; RAM $7002
    DEC     A                               ; DEC A: decrement row counter
    LD      ($7002), A                      ; RAM $7002
    CP      $00                             ; CP $00: all rows done?
    JR      Z, LOC_ABA6                     ; JR Z,LOC_ABA6: yes -> finish
    LD      BC, $2001                       ; LD BC,$2001: BC = $2001 (stride params)
    LD      HL, $7200                       ; RAM $7200
    PUSH    DE                              ; PUSH DE: save stride
    LD      B, $20                          ; LD B,$20: B = $20 (32 bytes per copy)
    DB      $EB                             ; DB $EB: EX DE,HL opcode (mid-routine literal byte)
    LD      HL, $729F                       ; RAM $729F

LOC_AB89:
    LD      A, (DE)                         ; LD A,(DE): A = sprite byte
    LD      (HL), A                         ; LD (HL),A: store to reversed buffer at $729F
    DEC     HL                              ; DEC HL: step backwards in dest buffer
    INC     DE                              ; INC DE: advance source pointer
    DJNZ    LOC_AB89                        ; DJNZ LOC_AB89: copy 32 bytes reversed
    POP     DE                              ; POP DE: restore stride
    LD      BC, $0120                       ; LD BC,$0120: BC = 1 row, $20 = 32 cols
    LD      HL, $7280                       ; RAM $7280
    CALL    SUB_AEA7                        ; CALL SUB_AEA7: write reversed sprite row
    POP     HL                              ; POP HL: restore sprite row pointer
    LD      BC, $0020                       ; LD BC,$0020: BC = $0020 (row advance)
    ADD     HL, BC                          ; ADD HL,BC: advance HL by one sprite row
    PUSH    HL                              ; PUSH HL: save advanced pointer
    POP     DE                              ; POP DE: DE = advanced pointer
    POP     AF                              ; POP AF: restore row counter
    POP     IY                              ; POP IY: restore row width
    POP     HL                              ; POP HL: restore sprite pointer
    JR      LOC_AB41                        ; JR LOC_AB41: loop for next sprite row

LOC_ABA6:
    POP     DE                              ; POP DE: restore DE from inner loop
    POP     AF                              ; POP AF: restore AF from inner loop
    POP     IY                              ; POP IY: restore IY from inner loop
    POP     HL                              ; POP HL: restore HL from inner loop
    POP     AF                              ; POP AF: restore original caller AF
    POP     BC                              ; POP BC: restore original BC
    POP     DE                              ; POP DE: restore original DE
    POP     HL                              ; POP HL: restore original HL
    CALL    SUB_A8C3                        ; CALL SUB_A8C3: VRAM-lock exit
    RET                                     ; RET: return from SUB_AB29
    DB      $FD, $FE, $FE, $FE, $FE, $FE, $FE, $FF ; sprite transform table: input match bytes (start)
    DB      $FF, $FF, $FF, $FF, $FF, $FF, $00, $FF ; sprite transform table: match/replace pairs
    DB      $00, $FF, $00, $FF, $00, $FF, $00, $FF ; sprite transform table: sentinel $00 + replace pairs
    DB      $00, $FF, $00, $00, $00, $00, $00, $00 ; sprite transform: inline Z80 POP IY / LD A,A ...
    DB      $01, $00, $01, $00, $01, $00, $01, $00 ; sprite transform: inline Z80 LD A,(HL) / AND $0F ...
    DB      $01, $00, $01, $00, $01, $01, $01, $01 ; sprite transform: inline Z80 continued ...
    DB      $01, $01, $01, $02, $02, $02, $02, $02 ; sprite transform: inline Z80 PUSH DE+HL / LD HL,$71B2
    DB      $02, $03, $0E, $08, $DD, $E1, $E3, $23 ; sprite transform: inline Z80 PUSH HL / POP DE ...
    DB      $7E, $E6, $0F, $FE, $08, $30, $02, $0E ; sprite transform: inline Z80 LD BC,$0600 / LDIR ...
    DB      $00, $7E, $E6, $F0, $81, $77, $2B, $E3 ; sprite transform: inline Z80 tail POP+RET
    DB      $DD, $E5, $C9, $E5, $D5, $C5, $21, $B2 ; sprite transform: inline Z80 tail continued
    DB      $71, $E5, $D1, $13, $36, $FF, $01, $06 ; sprite transform: inline Z80 continued
    DB      $00, $ED, $B0, $C1, $D1, $E1, $C9 ; sprite transform: end of sprite transform inline data

SUB_AC1A:
    PUSH    AF                              ; PUSH AF
    PUSH    HL                              ; PUSH HL
    PUSH    DE                              ; PUSH DE
    PUSH    BC                              ; PUSH BC
    LD      B, A                            ; B = A (save requested sound ID)
    LD      HL, $702C                       ; HL = $702C (sound channel flags)
    BIT     7, (HL)                         ; BIT 7, (HL): is channel active?
    JR      NZ, LOC_AC5A                    ; JR NZ, LOC_AC5A: active -> priority check before override

LOC_AC26:                                   ; LOC_AC26:
    LD      ($702D), A                      ; ($702D) = A: store sound ID
    SET     7, (HL)                         ; SET 7, (HL): mark channel active (bit 7)
    SET     5, (HL)                         ; SET 5, (HL): mark sequence-in-progress (bit 5)
    RES     6, (HL)                         ; RES 6, (HL): clear repeat flag (bit 6)
    ADD     A, A                            ; ADD A, A: * 2 (2 bytes per sound table entry)
    LD      HL, $AD0B                       ; HL = $AD0B (sound sequence table)
    LD      E, A                            ; E = A (index lo)
    LD      D, $00                          ; D = $00
    ADD     HL, DE                          ; ADD HL, DE: point to sound sequence entry
    LD      E, (HL)                         ; E = (HL): load lo byte of sequence pointer
    INC     HL                              ; INC HL
    LD      D, (HL)                         ; D = (HL): load hi byte (DE = sequence data pointer)
    DB      $EB                             ; DB $EB: EX DE,HL (HL = sequence data pointer)
    LD      A, (HL)                         ; A = (HL): read sequence header: note duration
    LD      ($7030), A                      ; ($7030) = A: store note duration
    DEC     A                               ; DEC A
    LD      ($7032), A                      ; ($7032) = A: store frame-counter target (duration - 1)
    INC     HL                              ; INC HL
    LD      A, (HL)                         ; A = (HL): read loop/speed byte
    LD      ($7035), A                      ; ($7035) = A: store loop control byte
    AND     $03                             ; AND $03: isolate channel count
    LD      ($7031), A                      ; ($7031) = A: store channel count
    INC     HL                              ; INC HL
    LD      ($702E), HL                     ; ($702E) = HL: store pointer to start of note data
    XOR     A                               ; A = $00
    LD      ($7033), A                      ; ($7033) = $00: clear note index

LOC_AC55:
    POP     BC                              ; POP BC: restore BC (sound driver)
    POP     DE                              ; POP DE: restore DE
    POP     HL                              ; POP HL: restore HL
    POP     AF                              ; POP AF: restore AF
    RET                                     ; RET: return from sound init routine

LOC_AC5A:
    LD      A, ($702D)                      ; A = ($702D) currently playing sound ID
    CP      B                               ; CP B: is requested ID > current?
    JR      C, LOC_AC55                     ; JR C, LOC_AC55: requested < current -> lower priority, ignore
    JR      NZ, LOC_AC6A                    ; JR NZ, LOC_AC6A: different ID -> override
    CP      $09                             ; CP $09: ID == 9 (special: non-interruptible)?
    JR      Z, LOC_AC55                     ; JR Z, LOC_AC55: ID 9 -> dont interrupt
    CP      $01                             ; CP $01: ID == 1?
    JR      Z, LOC_AC55                     ; JR Z, LOC_AC55: ID 1 -> dont interrupt

LOC_AC6A:                                   ; LOC_AC6A:
    LD      A, B                            ; A = B (use new sound ID)
    JR      LOC_AC26                        ; JR LOC_AC26: override with new sound

SUB_AC6D:
    LD      HL, $702C                       ; HL = $702C (sound channel flags)
    BIT     7, (HL)                         ; BIT 7, (HL): channel active?
    RET     Z                               ; RET Z: inactive -> nothing to do
    BIT     6, (HL)                         ; BIT 6, (HL): repeat/stop flag
    JR      Z, LOC_AC82                     ; JR Z, LOC_AC82: not stopping -> advance sequence

LOC_AC77:                                   ; LOC_AC77:
    LD      HL, $702C                       ; HL = $702C
    RES     6, (HL)                         ; RES 6, (HL): clear repeat flag
    RES     7, (HL)                         ; RES 7, (HL): clear active flag (stop channel)
    CALL    TURN_OFF_SOUND                  ; CALL TURN_OFF_SOUND: silence SN76489A
    RET                                     ; RET

LOC_AC82:                                   ; LOC_AC82:
    LD      HL, $7032                       ; HL = $7032 (frame counter)
    INC     (HL)                            ; INC (HL): tick frame counter
    LD      A, (HL)                         ; A = (HL)
    LD      HL, $7030                       ; HL = $7030 (note duration)
    CP      (HL)                            ; CP (HL): frame count reached duration?
    RET     NZ                              ; RET NZ: not yet -> wait
    XOR     A                               ; A = $00
    LD      ($7032), A                      ; ($7032) = $00: reset frame counter
    LD      HL, $702C                       ; HL = $702C
    BIT     5, (HL)                         ; BIT 5, (HL): sequence-in-progress?
    JR      Z, LOC_ACCD                     ; JR Z, LOC_ACCD: bit 5 clear -> advance note index only
    RES     5, (HL)                         ; RES 5, (HL): clear sequence flag
    LD      HL, ($702E)                     ; HL = ($702E) (note data pointer)
    LD      A, (HL)                         ; A = (HL): read channel 1 lo nibble
    AND     $0F                             ; AND $0F
    OR      $D0                             ; OR $D0: SN76489A channel 1 tone latch command
    OUT     ($FF), A                        ; OUT ($FF), A: write tone latch to SOUND_PORT
    LD      A, (HL)                         ; A = (HL): re-read byte
    AND     $F0                             ; AND $F0
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA: shift hi nibble to lo
    OR      $F0                             ; OR $F0: SN76489A channel 1 attenuation command
    OUT     ($FF), A                        ; OUT ($FF), A: write attenuation to SOUND_PORT
    INC     HL                              ; INC HL
    LD      A, (HL)                         ; A = (HL): read channel 2 byte
    AND     $0F                             ; AND $0F
    OR      $90                             ; OR $90: SN76489A channel 2 tone latch command
    OUT     ($FF), A                        ; OUT ($FF), A: write channel 2 tone to SOUND_PORT
    LD      A, (HL)                         ; A = (HL)
    AND     $F0                             ; AND $F0
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA: shift hi nibble
    OR      $B0                             ; OR $B0: SN76489A channel 2 attenuation command
    OUT     ($FF), A                        ; OUT ($FF), A: write channel 2 attenuation to SOUND_PORT
    INC     HL                              ; INC HL
    LD      ($702E), HL                     ; ($702E) = HL: advance note data pointer by 2 bytes
    LD      A, $E3                          ; A = $E3: SN76489A noise channel mute command
    LD      HL, $7035                       ; HL = $7035 (loop/speed control byte)
    OR      (HL)                            ; OR (HL): merge loop byte
    OUT     ($FF), A                        ; OUT ($FF), A: write noise control to SOUND_PORT

LOC_ACCD:                                   ; LOC_ACCD:
    LD      A, ($7033)                      ; A = ($7033) note index
    LD      HL, $7031                       ; HL = $7031 (channel count)
    CP      (HL)                            ; CP (HL): reached last channel?
    JR      Z, LOC_AD06                     ; JR Z, LOC_AD06: yes -> clear note index
    LD      HL, $7033                       ; HL = $7033
    INC     (HL)                            ; INC (HL): advance note index
    LD      HL, ($702E)                     ; HL = ($702E): load next note data address
    LD      A, (HL)                         ; A = (HL)
    CP      $00                             ; CP $00
    JR      Z, LOC_AC77                     ; JR Z, LOC_AC77: zero = sequence end -> stop channel
    AND     $FC                             ; AND $FC
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA: hi 6 bits = note duration value
    LD      ($7034), A                      ; ($7034) = A: store note duration
    LD      A, (HL)                         ; A = (HL): re-read byte
    AND     $03                             ; AND $03: lo 2 bits = channel flags
    RLCA                                    ; RLCA
    RLCA                                    ; RLCA: shift flags to bits 3:2
    LD      B, A                            ; B = A (flags)
    LD      A, ($7033)                      ; A = ($7033) note index
    XOR     $07                             ; XOR $07: toggle 3-bit counter
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA
    RRCA                                    ; RRCA: rotate to get note nibble position
    OR      B                               ; OR B: merge flags
    INC     HL                              ; INC HL
    LD      ($702E), HL                     ; ($702E) = HL: advance note pointer
    OUT     ($FF), A                        ; OUT ($FF), A: write note command to SOUND_PORT
    LD      A, ($7034)                      ; A = ($7034) note duration
    OUT     ($FF), A                        ; OUT ($FF), A: write duration to SOUND_PORT
    JP      LOC_ACCD                        ; JP LOC_ACCD: loop to next note

LOC_AD06:
    XOR     A                               ; A = $00
    LD      ($7033), A                      ; ($7033) = $00: clear note index (sequence complete)
    RET                                     ; RET
    DB      $6D, $AD, $3A, $AD, $1F, $AD, $8C, $AD ; sound sequence ptr table: lo/hi ptrs into $AD__ data
    DB      $E0, $AD, $C5, $AD, $9C, $AD, $D2, $AD ; sound sequence ptr table: continued
    DB      $EB, $AD, $BD, $AD, $04, $02, $F1, $1F ; sound sequence ptr table: end + sound data header
    DB      $3C, $60, $01, $01, $3C, $60, $01, $01 ; sound data: note sequence 0 (start) freq+dur pairs
    DB      $3C, $60, $01, $01, $2D, $48, $01, $01 ; sound data: note sequence 0 continued
    DB      $01, $01, $01, $01, $24, $3C, $00, $08 ; sound data: note sequence 0 continued
    DB      $02, $F0, $0F, $04, $AB, $2B, $72, $02 ; sound data: note sequence 0 continued
    DB      $55, $39, $87, $22, $55, $1D, $44, $33 ; sound data: note sequence 0 end + seq 1 header
    DB      $AB, $2B, $72, $22, $55, $39, $87, $22 ; sound data: note sequence 1 (title / attract theme)
    DB      $55, $1D, $44, $2B, $72, $1D, $55, $15 ; sound data: note sequence 1 continued
    DB      $39, $39, $87, $22, $55, $2D, $44, $2B ; sound data: note sequence 1 continued
    DB      $72, $1D, $55, $1A, $39, $18, $40, $15 ; sound data: note sequence 1 end + seq 2 header
    DB      $44, $00, $05, $02, $F1, $1F, $30, $39 ; sound data: note sequence 2 (frequency ramp up)
    DB      $30, $39, $2B, $36, $30, $39, $30, $39 ; "09+60909"
    DB      $2B, $36, $30, $39, $01, $01, $01, $01 ; sound data: note seq 2 ramp continued
    DB      $1D, $24, $01, $01, $01, $01, $24, $39 ; sound data: note seq 2 ramp continued
    DB      $00, $01, $01, $F1, $FF, $9F, $3C, $42 ; sound data: note seq 2 end + seq 3 header
    DB      $4F, $53, $56, $5F, $67, $71, $78, $86 ; sound data: note seq 3 (pickup / coin SFX)
    DB      $00, $01, $01, $F2, $FF, $5A, $5D, $5E ; sound data: note seq 3 continued
    DB      $5F, $61, $63, $65, $67, $68, $69, $6B ; "_aceghik"
    DB      $6D, $6F, $72, $74, $75, $77, $7A, $7B ; "mortuwz{"
    DB      $7D, $80, $82, $84, $86, $88, $8A, $8B ; sound data: note seq 3 continued
    DB      $8D, $00, $01, $05, $2F, $FF, $C0, $FE ; sound data: note seq 3 end + seq 4 header
    DB      $01, $00, $03, $05, $0F, $FF, $87, $F8 ; sound data: note seq 4 (death / fall SFX)
    DB      $89, $94, $84, $75, $10, $80, $00, $01 ; sound data: note seq 4 continued
    DB      $01, $F2, $FF, $73, $6E, $69, $64, $5F ; sound data: note seq 4 continued
    DB      $5A, $55, $50, $4B, $00, $01, $05, $0F ; sound data: note seq 5 header
    DB      $FF, $C0, $C0, $01, $C0, $C0, $01, $00 ; sound data: note seq 5 (door open SFX) continued
    DB      $01, $01, $F1, $FF, $9F, $01, $01, $01 ; sound data: note seq 5 continued
    DB      $10, $10, $C0, $10, $10, $01, $01, $01 ; sound data: note seq 5 continued
    DB      $01, $01, $01, $10, $00         ; sound data: note seq 5 end

SUB_AE00:
    POP     HL                              ; POP HL: return address -> HL (inline data pointer)

LOC_AE01:                                   ; LOC_AE01: -- data block processing loop
    PUSH    AF                              ; PUSH AF: save block selector
    LD      C, (HL)                         ; C = (HL): read bank/page selector
    INC     HL                              ; INC HL
    LD      A, (HL)                         ; A = (HL): read block count
    CP      $00                             ; CP $00: end-of-list?
    JR      Z, LOC_AE21                     ; JR Z, LOC_AE21: count=0 -> done, return past inline data
    LD      B, A                            ; B = A (block count)
    POP     AF                              ; POP AF: restore block selector
    PUSH    BC                              ; PUSH BC: save count/bank
    INC     HL                              ; INC HL
    LD      E, (HL)                         ; E = (HL): read VRAM address lo
    LD      D, $00                          ; D = $00
    LD      B, $00                          ; B = $00
    INC     HL                              ; INC HL
    LD      C, (HL)                         ; C = (HL): read stride (IY = stride)
    PUSH    BC                              ; PUSH BC / POP IY: IY = stride value
    POP     IY                              ; POP IY
    DB      $E3                             ; DB $E3: EX (SP),HL -- swap HL with stacked data ptr (save/restore)
    PUSH    AF                              ; PUSH AF: re-save block selector
    CALL    SUB_AE2E                        ; CALL SUB_AE2E: set VRAM addr + PUT_VRAM for this block
    POP     AF                              ; POP AF
    POP     HL                              ; POP HL: restore inline data pointer
    INC     HL                              ; INC HL: skip to next block entry
    JR      LOC_AE01                        ; JR LOC_AE01: process next block

LOC_AE21:
    POP     AF                              ; POP AF
    INC     HL                              ; INC HL: skip past end-of-list byte
    PUSH    HL                              ; PUSH HL: push return address (past inline data)
    RET                                     ; RET: jump to instruction after inline data block

SUB_AE25:
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: SET bit 1 $705F + INC $70AF (VRAM-lock enter)
    CALL    FILL_VRAM                       ; CALL FILL_VRAM: fill DE bytes at VRAM address HL with A
    JR      LOC_AE34                        ; JR LOC_AE34
    DB      $C9                             ; DB $C9: RET opcode trailing SUB_AE25 (pad/align)

SUB_AE2E:
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: SET bit 1 $705F + INC $70AF (VRAM-lock enter)
    CALL    PUT_VRAM                        ; CALL PUT_VRAM: copy IY bytes from HL to VRAM at DE

LOC_AE34:
    CALL    SUB_A8C3                        ; CALL SUB_A8C3: VRAM-lock exit
    RET                                     ; RET: return from LOC_AE34
    DB      $DD, $E9                        ; DB $DD,$E9: indirect jump pad after SUB_AE2E

SUB_AE3A:
    JP      (HL)                            ; JP (HL): indirect jump to object handler
    DB      $7E, $32, $13, $70, $23, $7E, $F5, $23 ; JP (HL): indirect jump via HL
    DB      $E5, $DD, $E1, $26, $00, $DD, $6E, $01 ; inline Z80: LD A,(HL) / LD ($7013) / INC HL ...
    DB      $54, $DD, $5E, $00, $7B, $FE, $FF, $28 ; inline Z80: PUSH AF / PUSH IX / POP HL / LD H,$00 ...
    DB      $21, $01, $01, $00, $F1, $F5, $08, $DD ; inline Z80: LD L,(IX+1) / LD D,H / LD E,(IX+0) ...
    DB      $E5, $3A, $13, $70, $FE, $00, $20, $06 ; inline Z80: LD A,C / CP $FF / JR Z / LD BC,$0001 ...
    DB      $08, $CD, $6D, $1F, $18, $04, $08, $CD ; inline Z80: POP AF / PUSH AF / EX AF / PUSH IX ...
    DB      $6A, $1F, $DD, $E1, $DD, $23, $DD, $23 ; inline Z80: LD A,($7013) / CP $00 / JR NZ / EX AF ...
    DB      $18, $D1, $F1, $C9              ; inline Z80: CALL $1F6D / JR / EX AF / CALL $1F6A ...

SUB_AE77:
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: VRAM-lock enter
    LD      HL, $70B3                       ; INC ($70B3): increment blank-display nesting counter
    INC     (HL)                            ; CALL WRITE_REGISTER ($0182): disable VDP display
    LD      BC, $0182                       ; LD BC,$0182: BC = $0182 (VDP reg 1, blank)
    JR      LOC_AE91                        ; JR LOC_AE91: jump to WRITE_REGISTER tail

SUB_AE83:
    CALL    SUB_A8C3                        ; CALL SUB_A8C3: VRAM-lock exit (DEC $70AF)
    LD      HL, $70B3                       ; DEC ($70B3): decrement blank-display nesting counter
    DEC     (HL)                            ; JR NZ: still nested -> keep display off
    LD      A, (HL)                         ; CALL WRITE_REGISTER ($01E2): re-enable VDP display + sprites
    CP      $00                             ; CP $00: blank nesting count = 0?
    RET     NZ                              ; RET NZ: still nested -> keep display off
    LD      BC, $01E2                       ; LD BC,$01E2: BC = $01E2 (VDP reg 1, enable)

LOC_AE91:
    JP      WRITE_REGISTER                  ; JP WRITE_REGISTER: tail-call to VDP write
    DB      $C5, $D5, $F5, $06, $FF, $11, $FF, $00 ; inline Z80: PUSH BC+DE+AF / LD B,$FF / LD DE,$00FF
    DB      $1B, $7A, $B3, $20, $FB, $10, $F6, $F1 ; inline Z80: DEC DE / LD A,D / OR E / JR NZ ...
    DB      $D1, $C1, $C9                   ; inline Z80: DJNZ / POP AF+DE+BC / RET

SUB_AEA7:
    PUSH    IX                              ; PUSH IX
    PUSH    BC                              ; PUSH BC
    PUSH    HL                              ; PUSH HL
    PUSH    DE                              ; PUSH DE
    PUSH    BC                              ; PUSH BC
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: VRAM-lock enter
    LD      B, $00                          ; LD IY from BC: IY = stride (via register rename)
    PUSH    BC                              ; LOC_AEB8: -- tile write loop
    POP     IY                              ; POP IY: IY = stride from BC
    POP     BC                              ; POP BC: BC = original tile block params
    LD      C, $00                          ; LD C,$00: C = $00 (row column counter)

LOC_AEB8:
    LD      A, $02                          ; LD A,$02: A = $02 (mode for AE2E/GET_VRAM)
    PUSH    BC                              ; PUSH BC: save tile block params
    PUSH    HL                              ; PUSH HL: save VRAM dest
    PUSH    DE                              ; PUSH DE: save source pointer
    PUSH    IY                              ; PUSH IY: save stride
    PUSH    AF                              ; PUSH AF: save mode byte
    LD      A, (WORK_BUFFER)                ; WORK_BUFFER
    BIT     4, A                            ; BIT 4,A: WORK_BUFFER bit 4 = read-back mode?
    JR      Z, LOC_AECD                     ; JR Z, LOC_AECD: bit 4 of WORK_BUFFER clear -> write mode
    POP     AF                              ; POP AF: restore mode (read-back branch)
    CALL    GET_VRAM                        ; CALL GET_VRAM: read tile from VRAM (read mode)
    JR      LOC_AED1                        ; JR LOC_AED1: skip write, go to advance

LOC_AECD:                                   ; LOC_AECD:
    POP     AF                              ; POP AF: restore mode (write branch)
    CALL    SUB_AE2E                        ; CALL SUB_AE2E: write tile block to VRAM (write mode)

LOC_AED1:
    POP     BC                              ; POP BC: restore tile params
    POP     DE                              ; POP DE: restore source pointer
    PUSH    BC                              ; PUSH BC: re-save for stride add below
    LD      A, (WORK_BUFFER)                ; WORK_BUFFER
    BIT     2, A                            ; BIT 2, A: stride-double flag (WORK_BUFFER bit 2)?
    JR      Z, LOC_AEDE                     ; JR Z, LOC_AEDE: single stride
    LD      BC, $0020                       ; BC = $0020 (double stride = 32 bytes)

LOC_AEDE:
    DB      $EB                             ; DB $EB: EX DE,HL opcode (mid-routine literal byte)
    ADD     HL, BC                          ; ADD HL, BC: advance HL by stride
    DB      $EB                             ; DB $EB: EX DE,HL opcode (mid-routine literal byte)
    POP     IY                              ; POP IY: pop IY stride
    BIT     4, A                            ; BIT 4,A: read-back mode flag in A?
    JR      Z, LOC_AEEA                     ; JR Z,LOC_AEEA: no -> source advance branch
    POP     BC                              ; POP BC: pop BC (read-back path)
    JR      LOC_AEF2                        ; JR LOC_AEF2: skip source advance

LOC_AEEA:
    POP     HL                              ; POP HL: pop HL (source pointer)
    BIT     3, A                            ; BIT 3,A: WORK_BUFFER bit 3 = reverse mode?
    JR      Z, LOC_AEF2                     ; JR Z,LOC_AEF2: no -> skip reverse adjust
    INC     HL                              ; INC HL: advance source for reverse mode
    DEC     DE                              ; DEC DE: decrement DE for reverse mode
    DEC     DE                              ; DEC DE: decrement DE second step

LOC_AEF2:
    POP     BC                              ; POP BC: restore outer BC counter
    DJNZ    LOC_AEB8                        ; DJNZ LOC_AEB8: loop B times
    POP     DE                              ; POP DE: restore outer DE
    POP     HL                              ; POP HL
    POP     BC                              ; POP BC
    POP     IX                              ; POP IX
    CALL    SUB_A8C3                        ; CALL SUB_A8C3: VRAM-lock exit
    RET                                     ; RET: return from SUB_AEA7

SUB_AEFE:
    PUSH    HL                              ; PUSH HL
    PUSH    BC                              ; PUSH BC
    PUSH    DE                              ; PUSH DE
    PUSH    AF                              ; PUSH AF
    CALL    SUB_A8B7                        ; CALL SUB_A8B7: VRAM-lock enter
    LD      HL, $1838                       ; HL = $1838 (VRAM score row 1 address)
    LD      C, $18                          ; C = $18 (write length)
    CALL    DELAY_LOOP_AF32                 ; CALL DELAY_LOOP_AF32: render score row 1
    LD      HL, $1858                       ; HL = $1858 (VRAM score row 2 address)
    LD      C, $28                          ; C = $28 (write length)
    CALL    DELAY_LOOP_AF32                 ; CALL DELAY_LOOP_AF32: render score row 2
    LD      HL, $1834                       ; HL = $1834 (score digit area base)
    LD      A, ($71A6)                      ; A = ($71A6) room difficulty
    PUSH    AF                              ; PUSH AF
    ADD     A, $18                          ; ADD A, $18: offset into score digit table
    CALL    SUB_AF66                        ; CALL SUB_AF66: write score digit block
    POP     AF                              ; POP AF
    LD      HL, $1854                       ; HL = $1854 (second score digit area)
    ADD     A, $28                          ; ADD A, $28
    CALL    SUB_AF66                        ; CALL SUB_AF66: write second score digit block
    CALL    SUB_A8C3                        ; CALL SUB_A8C3: VRAM-lock exit
    POP     AF                              ; POP AF: restore AF
    POP     DE                              ; POP DE: restore DE
    POP     BC                              ; POP BC: restore BC
    POP     HL                              ; POP HL: restore HL
    RET                                     ; RET: return from SUB_AEFE

DELAY_LOOP_AF32:
    LD      B, $03                          ; B = $03 (3 BCD bytes per row)
    LD      DE, $7017                       ; DE = $7017 (BCD score data buffer at $7015-$7017)

LOC_AF37:                                   ; LOC_AF37: -- BCD digit render loop
    PUSH    BC                              ; PUSH BC: save outer counter
    LD      A, (DE)                         ; A = (DE): read BCD byte
    SRA     A                               ; SRA A
    SRA     A                               ; SRA A
    SRA     A                               ; SRA A
    SRA     A                               ; SRA A: shift hi nibble to lo (upper digit)
    PUSH    BC                              ; PUSH BC
    CALL    SUB_AF54                        ; CALL SUB_AF54: render upper BCD digit tile
    POP     BC                              ; POP BC
    LD      A, (DE)                         ; A = (DE): re-read same BCD byte
    CALL    SUB_AF54                        ; CALL SUB_AF54: render lower BCD digit tile (lo nibble)
    INC     DE                              ; INC DE: advance to next BCD byte
    POP     BC                              ; POP BC
    DJNZ    LOC_AF37                        ; DJNZ LOC_AF37: loop 3 times (all BCD digits)
    LD      HL, $70B1                       ; HL = $70B1 (NMI flags)
    RES     0, (HL)                         ; RES 0, (HL): clear bit 0 (score-render done)
    RET                                     ; RET

SUB_AF54:
    PUSH    HL                              ; PUSH HL
    LD      HL, $70B1                       ; HL = $70B1 (NMI flags)
    AND     $0F                             ; AND $0F: isolate lo nibble (BCD digit 0-9)
    CP      $00                             ; CP $00: zero digit?
    JR      NZ, LOC_AF62                    ; JR NZ, LOC_AF62: nonzero -> render digit
    BIT     0, (HL)                         ; BIT 0, (HL): leading-zero suppress flag
    JR      Z, LOC_AF65                     ; JR Z, LOC_AF65: suppress -> skip (blank tile)

LOC_AF62:                                   ; ADD A, C: digit + base tile offset
    ADD     A, C                            ; SET 0, (HL): clear leading-zero flag (digit rendered)
    SET     0, (HL)                         ; SET 0,(HL): set leading-zero suppress flag

LOC_AF65:
    POP     HL                              ; POP HL: restore HL after digit write

SUB_AF66:
    PUSH    DE                              ; PUSH DE
    LD      DE, $0001                       ; DE = $0001 (one tile per write)
    CALL    SUB_AE25                        ; CALL SUB_AE25: write one score tile to VRAM
    INC     HL                              ; INC HL: advance VRAM address
    POP     DE                              ; POP DE
    RET                                     ; RET: return from SUB_AF66

SUB_AF70:
    PUSH    IX                              ; PUSH IX
    PUSH    IY                              ; PUSH IY
    PUSH    AF                              ; PUSH AF
    PUSH    HL                              ; PUSH HL
    LD      IY, $7017                       ; IY = $7017 (BCD score digits lo -> $7015/$7016/$7017)
    LD      A, L                            ; A = L (lo byte of score increment)
    CALL    SUB_AF89                        ; CALL SUB_AF89: add A to $7017 (BCD units)
    LD      A, H                            ; A = H (hi byte of score increment)
    CALL    SUB_AF96                        ; CALL SUB_AF96: add H to $7016 (BCD tens/hundreds)
    POP     HL                              ; POP HL: restore HL
    POP     AF                              ; POP AF: restore AF
    POP     IY                              ; POP IY: restore IY
    POP     IX                              ; POP IX: restore IX
    RET                                     ; RET: return from SUB_AF70

SUB_AF89:
    SCF                                     ; SCF
    CCF                                     ; CCF: clear carry for clean ADC
    ADC     A, (IY+2)                       ; ADC A, (IY+2): BCD add to score digit [IY+2] (units)
    DAA                                     ; DAA: decimal-adjust result
    LD      (IY+2), A                       ; (IY+2) = A: store adjusted units
    JR      NC, LOC_AFC7                    ; JR NC, LOC_AFC7: no carry -> done
    LD      A, $01                          ; A = $01 (carry into tens)

SUB_AF96:
    SCF                                     ; SCF
    CCF                                     ; CCF: clear carry
    ADC     A, (IY+1)                       ; ADC A, (IY+1): BCD add to score digit [IY+1] (tens)
    DAA                                     ; DAA: decimal-adjust
    LD      (IY+1), A                       ; (IY+1) = A: store adjusted tens
    JR      NC, LOC_AFC7                    ; JR NC, LOC_AFC7: no carry -> done
    PUSH    HL                              ; PUSH HL
    PUSH    AF                              ; PUSH AF
    BIT     0, A                            ; BIT 0, A: odd carry?
    JR      Z, LOC_AFAE                     ; JR Z, LOC_AFAE: even -> INC life counter
    LD      A, ($71A6)                      ; A = ($71A6) room difficulty
    CP      $05                             ; CP $05
    JR      NC, LOC_AFB2                    ; JR NC, LOC_AFB2: difficulty >= 5 -> skip extra life

LOC_AFAE:                                   ; LOC_AFAE:
    LD      HL, $7049                       ; HL = $7049 (life counter)
    INC     (HL)                            ; INC (HL): award extra life (score rollover bonus)

LOC_AFB2:                                   ; LOC_AFB2:
    POP     AF                              ; POP AF
    POP     HL                              ; POP HL
    LD      A, $01                          ; A = $01 (carry into hundreds)
    SCF                                     ; SCF
    CCF                                     ; CCF
    ADC     A, (IY+0)                       ; ADC A, (IY+0): BCD add to score digit [IY+0] (hundreds)
    DAA                                     ; DAA
    LD      (IY+0), A                       ; (IY+0) = A: store adjusted hundreds
    CALL    LOC_AABB                        ; CALL LOC_AABB: refresh lives/score display
    LD      A, $00                          ; A = $00
    CALL    SUB_AC1A                        ; CALL SUB_AC1A: trigger score-chime sound ($00)

LOC_AFC7:
    RET                                     ; RET: return from extra-life routine
    DB      $CB, $0F, $CB, $8C, $30, $02, $CB, $CC ; inline Z80: RRC A / RES 1,(IY+0) / JR NC ...
    DB      $CB, $0F, $30, $02, $CB, $CC, $CB, $0F ; inline Z80: RRC A / JR NC (x2) / RES 1,(IY+0) ...
    DB      $30, $02, $CB, $CC, $E6, $1F, $CB, $4C ; inline Z80: AND $1F / BIT 1,(IY+0) / RET Z / INC A ...
    DB      $C8, $3C, $C9, $CD, $C8, $AF, $4F, $78 ; inline Z80: RET / CALL $AFC8 / LD C,A / LD A,B ...
    DB      $CD, $C8, $AF, $E6, $1F, $06, $00, $21 ; inline Z80: CALL $AFC8 / AND $1F / LD B,$00 ...
    DB      $00, $00, $11, $20, $00, $3D, $FE, $00 ; inline Z80: LD HL,$0000 / LD DE,$0020 / DEC A ...
    DB      $28, $03, $19, $18, $F8, $09, $C9, $FB ; inline Z80: CP $00 / JR Z / ADD HL,DE / JR ...

; ---- mid-instruction label aliases (EQU) ----
LOC_801D:        EQU $801D
