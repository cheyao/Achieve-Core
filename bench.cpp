#include "VSOC.h"
#include "verilated.h"

#include <iostream>
#include <SDL2/SDL.h>
#include <cstdio>

using namespace std;

#ifdef DEBUG
#define DPRINT(str) do { std::cout << str << std::endl; } while( false )
#else
#define DPRINT(str) do { } while ( false )
#endif

#define SCREEN_WIDTH 1024
#define SCREEN_HEIGHT 768

uint16_t *pixels = new uint16_t[SCREEN_WIDTH * SCREEN_HEIGHT];
uint64_t *sdbuffer = new uint64_t[512];
void veri(int argc, char** argv);
bool finish;

int main(int argc, char** argv) {
  SDL_Init(SDL_INIT_VIDEO);
  SDL_Window *window = SDL_CreateWindow("Achieve OS", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
  SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED); 
  SDL_Texture *texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB565, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);

  thread thread(veri, argc, argv);

  SDL_Event event;
  while (1) {
    if (SDL_PollEvent(&event) && event.type == SDL_QUIT)
      break;

    SDL_UpdateTexture(texture, NULL, pixels, SCREEN_WIDTH * sizeof(Uint16));
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);
    SDL_Delay(100);
  }

  finish = true;
  thread.join();
  SDL_DestroyTexture(texture);
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
  delete[] pixels;

  return 0;
}

#define READ  1
#define WRITE 2

void veri(int argc, char** argv) {
  // Verilator Initialization
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  VSOC* top = new VSOC{contextp};
  top->clk = 1;
  top->eval(); // 0

  // Disk
  FILE* disk = fopen("SDcontents.bin", "r+b");
  if (disk == NULL) {
    fprintf(stderr, "bench.cpp:55: PANIC! Disk image \"SDcontents.bin\" not found!\nAbborting\n");
    exit(1);
  }

  // SDL window
  memset(pixels, 0, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(Uint16));

  while (!contextp->gotFinish() && !finish) { 
    top->clk = !top->clk; 
    top->eval(); // 0
    top->clk = !top->clk;
    top->eval(); // 1
    if (top->isIO && top->pulse) {
      switch (top->port) {
        case 0x00000 ... 0xBFFFF: {
          if (top->pulse == READ)
            top->data = pixels[top->port];
          else
            pixels[top->port] = top->data;

          break;
        }
        case 0xC0000 ... 0xC0FFF: { // SD data
          if (top->pulse == READ) {
            uint64_t data64 = sdbuffer[(top->port & 0xFFF) >> 3];
            uint64_t data32 = top->port & 4 ? data64 >> 32 : data64 & 0xFFFFFFFF;
            uint64_t data16 = top->port & 2 ? data32 >> 16 : data32 & 0xFFFF;
            uint64_t data8  = top->port & 1 ? data16 >> 8 : data16 & 0xFF;
            switch(top->size) {
              case 1:
                top->data = data8;
                break;
              case 3:
                top->data = data16;
                break;
              case 7:
                top->data = data32;
                break;
              case 15:
                top->data = data64;
                break;
            }
            DPRINT("read of size " << hex << (int) top->size << " at " << hex << (top->port & 0xFFF) << " = " << top->data << " aka " << sdbuffer[(top->port & 0xFFF) >> 3]);
          } else {
            // fwrite(&top->data, top->size / 2 + 1, 1, disk);
            DPRINT("write of size " << hex << (int) (top->size / 2 + 1) << " = " << top->data);
          }

          break;
        }
        case 0xC1000: { // SD addr
          if (top->pulse == READ) {
            top->data = ftell(disk);
          } else {
            fseek(disk, top->data * 4096, SEEK_SET);
            DPRINT("seek " << hex << top->data * 4096);
            if (fread(sdbuffer, sizeof(uint64_t), 512, disk) != 512)
              std::cout << "Error while reading at " << hex << ftell(disk) - (top->size / 2 + 1) << std::endl;
          }

          break;
        }
        case 0xC1001: { // SD status + command
          if (top->pulse == READ)
            top->data = 0x3;
          else {
            switch (top->data) {
              case 0: // Restart
                break; 
            }
          }

          break;
        }
        case 0xC1002: { // UART
          if (top->pulse == READ)
            top->data = 0;
          else {
            cout << (char) top->data;
          }

          break;
        }
        case 0xEFFFF: { // DEBUG
          cout << top->data << flush;

          break;
        }
        default: {
          DPRINT("Unhandled IO " << hex << top->port);
          break;
        }
      }
    }
  }

  fclose(disk);
  // Verilator cleanup
  delete top;
  delete contextp;
}
