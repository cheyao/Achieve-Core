SOC_SOURCES := $(wildcard SOC/*.v)
C_SOURCES := $(wildcard prog/src/*.c)
ASM_SOURCES := $(wildcard prog/src/*.S)
OBJ := $(subst prog/src/,build/,$(C_SOURCES:.c=.o)) $(subst prog/src/,build/,$(ASM_SOURCES:.S=.o) )

IVERILOG := /usr/local/bin/iverilog
CC := /usr/local/bin/riscv64-unknown-elf-gcc
CFLAGS := -march=rv64id -c
AS := /usr/local/bin/riscv64-unknown-elf-as
ASFLAGS := -march=rv64id -c
LD := /usr/local/bin/riscv64-unknown-elf-ld
LDFLAGS := -T prog/link.ld -m elf64lriscv -nostdlib
HEXTOTEXT := /usr/local/bin/hextotext # Special util to convert risc-v elf to hex

all: build/bench

build/bench: $(SOC_SOURCES)
	mkdir -pv build
	$(IVERILOG) -o $@ SOC/bench.v

build/prog.hex: $(OBJ)
	@echo "Sources: $^"
	mkdir -pv build
	$(LD) $(LDFLAGS) -o build/prog.elf $^
	$(HEXTOTEXT) build/prog.elf -out out.hex -ram 6144 -max_addr 6144 -out $@

build/%.o: prog/src/%.S
	mkdir -pv build
	$(AS) $(ASFLAGS) -o $@ $<

build/%.o: prog/src/%.c
	mkdir -pv build
	$(CC) $(CFLAGS) -o $@ $<
