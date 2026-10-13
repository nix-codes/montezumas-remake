package coleco

import (
	"image"

	"montezuma-remake/internal/vdp"
)

// VDP emulates the parts of the TMS9918A the game uses: VRAM access through
// the I/O ports, registers, the frame interrupt flag, and Graphics I mode
// rendering with sprites.
type VDP struct {
	VRAM    [0x4000]byte
	Reg     [8]byte
	status  byte
	addr    uint16
	latch   bool
	latched byte
	readBuf byte

	// nmi is called when the interrupt line goes active.
	nmi func()
}

const (
	statusFrame     = 0x80
	statusCollision = 0x20
)

// Table base addresses in Graphics I mode.
func (v *VDP) nameBase() int       { return int(v.Reg[2]&0x0F) << 10 }
func (v *VDP) colourBase() int     { return int(v.Reg[3]) << 6 }
func (v *VDP) patternBase() int    { return int(v.Reg[4]&0x07) << 11 }
func (v *VDP) spriteAttrBase() int { return int(v.Reg[5]&0x7F) << 7 }
func (v *VDP) spriteGenBase() int  { return int(v.Reg[6]&0x07) << 11 }

// TilePatterns returns a copy of the tile pattern table.
func (v *VDP) TilePatterns() []byte {
	return append([]byte(nil), v.VRAM[v.patternBase():v.patternBase()+256*8]...)
}

// TileColours returns a copy of the Graphics I colour table.
func (v *VDP) TileColours() []byte {
	return append([]byte(nil), v.VRAM[v.colourBase():v.colourBase()+32]...)
}

// SpritePatterns returns a copy of the sprite pattern table.
func (v *VDP) SpritePatterns() []byte {
	return append([]byte(nil), v.VRAM[v.spriteGenBase():v.spriteGenBase()+256*8]...)
}

// NameTable returns a copy of the name table: 24 rows of 32 tile numbers.
func (v *VDP) NameTable() []byte {
	return append([]byte(nil), v.VRAM[v.nameBase():v.nameBase()+768]...)
}

func (v *VDP) interruptsEnabled() bool { return v.Reg[1]&0x20 != 0 }

// WriteData handles a write to the data port.
func (v *VDP) WriteData(b byte) {
	v.latch = false
	v.VRAM[v.addr] = b
	v.readBuf = b
	v.addr = (v.addr + 1) & 0x3FFF
}

// ReadData handles a read from the data port.
func (v *VDP) ReadData() byte {
	v.latch = false
	b := v.readBuf
	v.readBuf = v.VRAM[v.addr]
	v.addr = (v.addr + 1) & 0x3FFF
	return b
}

// WriteControl handles a write to the control port: two bytes set either
// the VRAM address or a register.
func (v *VDP) WriteControl(b byte) {
	if !v.latch {
		v.latched, v.latch = b, true
		return
	}
	v.latch = false
	switch {
	case b&0x80 != 0:
		v.SetRegister(int(b&7), v.latched)
	case b&0x40 != 0: // write setup
		v.addr = (uint16(b&0x3F)<<8 | uint16(v.latched))
	default: // read setup prefetches
		v.addr = (uint16(b&0x3F)<<8 | uint16(v.latched))
		v.readBuf = v.VRAM[v.addr]
		v.addr = (v.addr + 1) & 0x3FFF
	}
}

// ReadStatus returns the status register and clears its flags.
func (v *VDP) ReadStatus() byte {
	v.latch = false
	s := v.status
	v.status &^= statusFrame | statusCollision
	return s
}

// SetRegister writes a register. Enabling interrupts while the frame flag
// is set raises the interrupt line.
func (v *VDP) SetRegister(r int, b byte) {
	was := v.interruptsEnabled()
	v.Reg[r&7] = b
	if !was && v.interruptsEnabled() && v.status&statusFrame != 0 && v.nmi != nil {
		v.nmi()
	}
}

// EndFrame sets the frame flag, raising the interrupt line if enabled, and
// updates the sprite collision flag.
func (v *VDP) EndFrame() {
	if v.spritesCollide() {
		v.status |= statusCollision
	}
	v.status |= statusFrame
	if v.interruptsEnabled() && v.nmi != nil {
		v.nmi()
	}
}

// Sprite is one active sprite: screen position of its top-left corner,
// pattern number and colour.
type Sprite struct {
	X, Y, Pattern int
	Colour        byte
}

// Sprites returns the active sprites in priority order.
func (v *VDP) Sprites() []Sprite {
	var out []Sprite
	base := v.spriteAttrBase()
	for i := 0; i < 32; i++ {
		a := v.VRAM[base+i*4 : base+i*4+4]
		if a[0] == 0xD0 {
			break
		}
		out = append(out, v.DecodeSprite(a))
	}
	return out
}

// DecodeSprite decodes a 4-byte sprite attribute entry (Y, X, pattern,
// colour) as the chip would display it.
func (v *VDP) DecodeSprite(a []byte) Sprite {
	y := int(a[0]) + 1
	if y > 0xE0 {
		y -= 256 // partly off the top
	}
	x := int(a[1])
	if a[3]&0x80 != 0 { // early clock
		x -= 32
	}
	p := int(a[2])
	if v.Reg[1]&0x02 != 0 { // 16x16: pattern number ignores low bits
		p &^= 3
	}
	return Sprite{X: x, Y: y, Pattern: p, Colour: a[3] & 0x0F}
}

func (v *VDP) spriteSize() int {
	if v.Reg[1]&0x02 != 0 {
		return 16
	}
	return 8
}

// spritePixel reports whether pixel (px, py) inside sprite s is set.
func (v *VDP) spritePixel(s Sprite, px, py int) bool {
	if v.Reg[1]&0x01 != 0 { // magnified
		px, py = px/2, py/2
	}
	n := s.Pattern + (px/8)*2 + py/8
	if v.spriteSize() == 8 {
		n = s.Pattern
	}
	b := v.VRAM[v.spriteGenBase()+n*8+py%8]
	return b&(0x80>>(px%8)) != 0
}

func (v *VDP) spriteExtent() int {
	n := v.spriteSize()
	if v.Reg[1]&0x01 != 0 {
		n *= 2
	}
	return n
}

// spritesCollide reports whether any two sprites have overlapping pixels
// on screen. Transparent sprites still collide, as on the real chip.
func (v *VDP) spritesCollide() bool {
	var seen [192][256]bool
	ext := v.spriteExtent()
	for _, s := range v.Sprites() {
		for py := 0; py < ext; py++ {
			for px := 0; px < ext; px++ {
				x, y := s.X+px, s.Y+py
				if x < 0 || x >= 256 || y < 0 || y >= 192 || !v.spritePixel(s, px, py) {
					continue
				}
				if seen[y][x] {
					return true
				}
				seen[y][x] = true
			}
		}
	}
	return false
}

// Render draws the screen in Graphics I mode.
func (v *VDP) Render(img *image.RGBA) {
	backdrop := vdp.Palette[v.Reg[7]&0x0F]
	backdrop.A = 0xFF
	if v.Reg[1]&0x40 == 0 { // display blanked
		for i := 0; i < len(img.Pix); i += 4 {
			img.Pix[i], img.Pix[i+1], img.Pix[i+2], img.Pix[i+3] = backdrop.R, backdrop.G, backdrop.B, 0xFF
		}
		return
	}
	colour := func(c byte) [4]byte {
		if c == 0 {
			return [4]byte{backdrop.R, backdrop.G, backdrop.B, 0xFF}
		}
		p := vdp.Palette[c]
		return [4]byte{p.R, p.G, p.B, 0xFF}
	}

	names, colours, patterns := v.nameBase(), v.colourBase(), v.patternBase()
	for ty := 0; ty < 24; ty++ {
		for tx := 0; tx < 32; tx++ {
			n := int(v.VRAM[names+ty*32+tx])
			c := v.VRAM[colours+n/8]
			fg, bg := colour(c>>4), colour(c&0x0F)
			for row := 0; row < 8; row++ {
				bits := v.VRAM[patterns+n*8+row]
				o := img.PixOffset(tx*8, ty*8+row)
				for col := 0; col < 8; col++ {
					px := bg
					if bits&(0x80>>col) != 0 {
						px = fg
					}
					copy(img.Pix[o+col*4:], px[:])
				}
			}
		}
	}

	// Draw lowest priority first so sprite 0 ends up on top.
	ss := v.Sprites()
	ext := v.spriteExtent()
	for i := len(ss) - 1; i >= 0; i-- {
		s := ss[i]
		if s.Colour == 0 {
			continue
		}
		px := colour(s.Colour)
		for y := 0; y < ext; y++ {
			for x := 0; x < ext; x++ {
				sx, sy := s.X+x, s.Y+y
				if sx < 0 || sx >= 256 || sy < 0 || sy >= 192 || !v.spritePixel(s, x, y) {
					continue
				}
				copy(img.Pix[img.PixOffset(sx, sy):], px[:])
			}
		}
	}
}
