VERILATOR ?= verilator
CXXFLAGS := -I build -MMD -I/usr/local/Cellar/verilator/5.004/share/verilator/include -I/usr/local/Cellar/verilator/5.004/share/verilator/include/vltstd \
			-DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fbracket-depth=4096 -fcf-protection=none -Qunused-arguments \
			-Wno-bool-operation -Wno-tautological-bitwise-compare -Wno-parentheses-equality -Wno-sign-compare -Wno-uninitialized -Wno-unused-parameter -Wno-unused-variable \
			-Wno-shadow -std=gnu++14
CXX ?= clang++
MAKE ?= make

all: build/bench Achieve-BIOS/AchieveBIOS.hex

build/bench: $(SOC_SOURCES) bench.cpp
	$(VERILATOR) SOC/SOC.v --cc --top-module SOC -Mdir build --build -j 0 -Wall bench.cpp -DBENCH
	$(CXX) $(CXXFLAGS) -O2 -c -o build/bench.o bench.cpp
	$(CXX) build/bench.o build/verilated.o build/verilated_threads.o build/VSOC__ALL.o -pthread -lpthread -o build/VSOC -std=c++20 -L/usr/local/lib -lSDL2
# -O3 --x-assign fast --x-initial fast --noassert 

Achieve-BIOS/AchieveBIOS.hex: $(wildcard Achieve-BIOS/*) $(wildcard Achieve-BIOS/**/*) $(wildcard Achieve-BIOS/**/**/*) $(wildcard Achieve-BIOS/**/**/**/*)
	$(MAKE) -C Achieve-BIOS
