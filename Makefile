SJASMPLUS ?= sjasmplus
ASM       := original/montezumas-revenge.asm
ROM       := build/montezuma.rom

.PHONY: all rom extract rooms run original test clean

all: extract

# The disassembly targets tniASM. Swap its two tniASM-only directives
# (FNAME, CPU) for sjasmplus equivalents and assemble.
$(ROM): $(ASM)
	@mkdir -p build
	sed -e 's|^FNAME .*|    OUTPUT "montezuma.rom"|' -e 's|^CPU Z80|; CPU Z80|' $(ASM) > build/montezuma.asm
	cd build && $(SJASMPLUS) --nologo montezuma.asm

rom: $(ROM)

extract: $(ROM)
	go run ./cmd/extract -rom $(ROM) -out assets

rooms: $(ROM)
	for l in 1 2 3; do go run ./cmd/rooms -rom $(ROM) -level $$l; done

run: $(ROM)
	go run ./cmd/game -rom $(ROM)

original: $(ROM)
	go run ./cmd/original -rom $(ROM)

test: $(ROM)
	# stdmethods: cmd/dis must name a method ReadByte to satisfy remogatto/z80.
	go vet -stdmethods=false ./...
	go test ./...

clean:
	rm -rf build assets
