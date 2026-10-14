package coleco

import "montezuma-remake/internal/sound"

// Go stand-ins for the ColecoVision BIOS (OS7) routines the game calls,
// keyed by their jump-table address.
var biosCalls = map[uint16]func(m *Machine){
	// OS7 names reflections by their axis: REFLECT_VERTICAL mirrors across
	// a vertical axis (left-right), REFLECT_HORIZONTAL across a horizontal
	// one (upside down). The game relies on this; e.g. it builds rolling
	// skull frames by swapping a sprite's top and bottom quarters itself.
	0x1F6A: func(m *Machine) { m.transform(mirrorLeftRight) }, // REFLECT_VERTICAL
	0x1F6D: func(m *Machine) { m.transform(flipUpsideDown) },  // REFLECT_HORIZONTAL
	0x1F73: (*Machine).enlarge,                                // ENLARGE
	0x1F76: (*Machine).controllerScan,                         // CONTROLLER_SCAN
	0x1F7F: (*Machine).loadASCII,                              // LOAD_ASCII
	0x1F82: (*Machine).fillVRAM,                               // FILL_VRAM
	0x1F85: (*Machine).mode1,                                  // MODE_1
	0x1FBB: func(m *Machine) { m.copyVRAM(false) },            // GET_VRAM
	0x1FBE: func(m *Machine) { m.copyVRAM(true) },             // PUT_VRAM
	0x1FC1: (*Machine).initSpriteOrder,                        // INIT_SPR_NM_TBL
	0x1FC4: (*Machine).writeSpriteTable,                       // WR_SPR_NM_TBL
	0x1FD6: func(m *Machine) { sound.TurnOff(m.PSG) },         // TURN_OFF_SOUND
	0x1FD9: (*Machine).writeRegister,                          // WRITE_REGISTER
	0x1FDC: (*Machine).readRegister,                           // READ_REGISTER
}

// BIOS RAM variables and cartridge header pointers.
const (
	muxSprites    = 0x73C7 // non-zero: sprite attributes go to the local table
	joystickP1    = 0x73EE
	joystickP2    = 0x73EF
	keypadP1      = 0x73F0
	keypadP2      = 0x73F1
	localSprTable = 0x8002 // header word: RAM copy of the sprite attributes
	spriteOrder   = 0x8004 // header word: order to write them to VRAM in
)

// tableBase returns the VRAM address and item size of a PUT_VRAM table.
func (m *Machine) tableBase(table byte) (int, int) {
	v := &m.VDP
	switch table {
	case 0:
		return v.spriteAttrBase(), 4
	case 1:
		return v.spriteGenBase(), 8
	case 2:
		return v.nameBase(), 1
	case 3:
		return v.patternBase(), 8
	default:
		return v.colourBase(), 1
	}
}

// copyVRAM implements PUT_VRAM and GET_VRAM: A = table, DE = first item,
// HL = buffer, IY = item count. Like the BIOS, it leaves HL just past the
// buffer; the game's tile reader (SUB_AEA7) relies on that.
func (m *Machine) copyVRAM(put bool) {
	table := m.CPU.AF.Hi
	index, buf, count := int(m.CPU.DE.U16()), m.CPU.HL.U16(), int(m.CPU.IY)
	base, size := m.tableBase(table)
	n := count * size
	defer m.CPU.HL.SetU16(buf + uint16(n))

	if table == 0 && m.Peek(muxSprites) != 0 {
		local := m.word(localSprTable) + uint16(index*4)
		for i := 0; i < n; i++ {
			if put {
				m.Poke(local+uint16(i), m.Peek(buf+uint16(i)))
			} else {
				m.Poke(buf+uint16(i), m.Peek(local+uint16(i)))
			}
		}
		return
	}
	for i := 0; i < n; i++ {
		a := (base + index*size + i) & 0x3FFF
		if put {
			m.VDP.VRAM[a] = m.Peek(buf + uint16(i))
		} else {
			m.Poke(buf+uint16(i), m.VDP.VRAM[a])
		}
	}
}

// fillVRAM: HL = address, DE = count, A = value.
func (m *Machine) fillVRAM() {
	a, n, b := int(m.CPU.HL.U16()), int(m.CPU.DE.U16()), m.CPU.AF.Hi
	for i := 0; i < n; i++ {
		m.VDP.VRAM[(a+i)&0x3FFF] = b
	}
}

// mode1 sets Graphics I mode with the BIOS's standard table addresses.
func (m *Machine) mode1() {
	for r, b := range []byte{0x00, 0x80, 0x06, 0x80, 0x00, 0x36, 0x07} {
		m.VDP.SetRegister(r, b)
	}
}

// writeRegister: B = register, C = value.
func (m *Machine) writeRegister() {
	m.VDP.SetRegister(int(m.CPU.BC.Hi), m.CPU.BC.Lo)
}

// readRegister returns the VDP status in A.
func (m *Machine) readRegister() {
	m.CPU.AF.Hi = m.VDP.ReadStatus()
}

// initSpriteOrder: A = sprite count; sets the write order to 0..A-1.
func (m *Machine) initSpriteOrder() {
	order := m.word(spriteOrder)
	for i := 0; i < int(m.CPU.AF.Hi); i++ {
		m.Poke(order+uint16(i), byte(i))
	}
}

// writeSpriteTable: A = sprite count; copies the local sprite attributes to
// VRAM in the order given by the sprite order table.
func (m *Machine) writeSpriteTable() {
	local, order := m.word(localSprTable), m.word(spriteOrder)
	base := m.VDP.spriteAttrBase()
	for i := 0; i < int(m.CPU.AF.Hi); i++ {
		src := local + uint16(m.Peek(order+uint16(i)))*4
		for j := 0; j < 4; j++ {
			m.VDP.VRAM[base+i*4+j] = m.Peek(src + uint16(j))
		}
	}
}

// controllerScan stores both controllers' joystick and keypad state,
// inverted from the active-low port values, as the BIOS does.
func (m *Machine) controllerScan() {
	in := m.Input
	joy := byte(0x80)
	for _, b := range []struct {
		on  bool
		bit byte
	}{{in.Up, 0x01}, {in.Right, 0x02}, {in.Down, 0x04}, {in.Left, 0x08}, {in.FireLeft, 0x40}} {
		if b.on {
			joy |= b.bit
		}
	}
	key := byte(0x80)
	if in.Key >= 0 && in.Key <= 9 {
		key |= keypadCodes[in.Key]
	}
	if in.FireRight {
		key |= 0x40
	}
	m.Poke(joystickP1, joy)
	m.Poke(joystickP2, 0x80)
	m.Poke(keypadP1, key)
	m.Poke(keypadP2, 0x80)
}

// keypadCodes are the inverted keypad codes for keys 0-9.
var keypadCodes = [10]byte{0x5, 0x2, 0x8, 0x3, 0xD, 0xC, 0x1, 0xA, 0xE, 0x4}

type patternFunc func(src [8]byte) [8]byte

func flipUpsideDown(p [8]byte) (out [8]byte) {
	for i := range p {
		out[i] = p[7-i]
	}
	return out
}

func mirrorLeftRight(p [8]byte) (out [8]byte) {
	for i, b := range p {
		var r byte
		for bit := 0; bit < 8; bit++ {
			if b&(1<<bit) != 0 {
				r |= 0x80 >> bit
			}
		}
		out[i] = r
	}
	return out
}

// transform applies f to BC patterns: A = table, DE = source, HL = dest.
func (m *Machine) transform(f patternFunc) {
	base, _ := m.tableBase(m.CPU.AF.Hi)
	src, dst, n := int(m.CPU.DE.U16()), int(m.CPU.HL.U16()), int(m.CPU.BC.U16())
	for i := 0; i < n; i++ {
		var p [8]byte
		copy(p[:], m.VDP.VRAM[base+(src+i)*8:])
		out := f(p)
		copy(m.VDP.VRAM[base+(dst+i)*8:], out[:])
	}
}

// enlarge doubles BC patterns into 16x16 blocks of four: A = table,
// DE = source, HL = dest.
func (m *Machine) enlarge() {
	base, _ := m.tableBase(m.CPU.AF.Hi)
	src, dst, n := int(m.CPU.DE.U16()), int(m.CPU.HL.U16()), int(m.CPU.BC.U16())
	for i := 0; i < n; i++ {
		var p [8]byte
		copy(p[:], m.VDP.VRAM[base+(src+i)*8:])
		var big [16]uint16
		for row, b := range p {
			var w uint16
			for bit := 0; bit < 8; bit++ {
				if b&(0x80>>bit) != 0 {
					w |= 0xC000 >> (bit * 2)
				}
			}
			big[row*2], big[row*2+1] = w, w
		}
		// Quadrants in sprite order: top-left, bottom-left, top-right, bottom-right.
		for q := 0; q < 4; q++ {
			for row := 0; row < 8; row++ {
				w := big[(q%2)*8+row]
				b := byte(w >> 8)
				if q >= 2 {
					b = byte(w)
				}
				m.VDP.VRAM[base+(dst+i*4+q)*8+row] = b
			}
		}
	}
}
