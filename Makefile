VERILATOR ?= verilator
CXXFLAGS := -I build -MMD -I/usr/local/Cellar/verilator/5.004/share/verilator/include -I/usr/local/Cellar/verilator/5.004/share/verilator/include/vltstd \
			-DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fbracket-depth=4096 -fcf-protection=none -Qunused-arguments \
			-Wno-bool-operation -Wno-tautological-bitwise-compare -Wno-parentheses-equality -Wno-sign-compare -Wno-uninitialized -Wno-unused-parameter -Wno-unused-variable \
			-Wno-shadow -std=gnu++14
CXX ?= g++
MAKE ?= make

.PHONY: all st clang-tidy ct clean run SDcontents

all: build/VSOC Achieve-BIOS/AchieveBIOS.hex SDcontents.bin

run: all
	./build/VSOC

build/VSOC: bench.cpp $(wildcard src/*.sv)
	$(VERILATOR) src/SOC.sv --cc --top-module SOC -Mdir build --build -j 0 -Wall bench.cpp -DBENCH -O3
	$(CXX) $(CXXFLAGS) -O2 -c -o build/bench.o bench.cpp -O2
	$(CXX) build/bench.o build/verilated.o build/verilated_threads.o build/VSOC__ALL.o -pthread -lpthread -o build/ACE -std=c++20 -L/usr/local/lib -lSDL2

Achieve-BIOS/AchieveBIOS.hex: $(wildcard Achieve-BIOS/src/*.c)
	$(MAKE) -C Achieve-BIOS

SDcontents.bin: SDcontents
	dd if=/dev/zero of=SDcontents.bin bs=1048576 count=128
	-@rm -rf $(wildcard **/.DS_Store)
	-@rm -rf **/.DS_Store
	mke2fs -b 4096 -t ext2 -d SDcontents SDcontents.bin

SDcontents:
	@mkdir -p SDcontents/System/Library/Kernel
	@mkdir -p SDcontents/usr/local/bin
	@mkdir -p SDcontents/usr/local/lib
	@mkdir -p SDcontents/usr/local/opt
	@$(MAKE) -C AchieveOS
	@mv AchieveOS/kernel SDcontents/System/Library/Kernel/kernel

ct: clang-tidy
clang-tidy:
	-@$(MAKE) -C AchieveOS clang-tidy
	-@$(MAKE) -C Achieve-BIOS clang-tidy

clean:
	@$(MAKE) -C AchieveOS clean
	@$(MAKE) -C Achieve-BIOS clean
	rm -rf SDcontents.bin
