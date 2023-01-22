#include "VSOC.h"
#include "verilated.h"

#include <iostream>
#include <SDL2/SDL.h>
#include <cstdio>

#define SCREEN_WIDTH 1024
#define SCREEN_HEIGHT 768

using namespace std;

Uint16 *pixels = new Uint16[SCREEN_WIDTH * SCREEN_HEIGHT];
void veri(int argc, char** argv);

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
  uint64_t buffer;

  // SDL window
  memset(pixels, 0, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(Uint16));

  while (!contextp->gotFinish()) { 
    top->clk = !top->clk; 
    top->eval(); // 0
    top->clk = !top->clk;
    top->eval(); // 1
    if (top->isIO && top->pulse) {
      switch (top->port) {
        case 0 ... (0xC0000 - 1): {
          if (top->pulse == READ)
            top->data = pixels[top->port];
          else
            pixels[top->port] = top->data;

          break;
        }
        case 0xC0000: { // SD data
          if (top->pulse == READ){
            buffer = 0;

            if (fread(&buffer, top->size, 1, disk) != 1)
              cout << "Error while reading size " << (int) top->size << " at " << ftell(disk) << endl;

            top->data = buffer;
            cout << "read of size " << (int) top->size << " at " << ftell(disk) << " = " << buffer << endl;
          } else {
            fwrite(&top->data, top->size, 1, disk);
            cout << "write of size " << (int) top->size << " at " << ftell(disk) << " = " << top->data << endl;
          }

          break;
        }
        case 0xC0001: { // SD addr
          if (top->pulse == READ) {
            top->data = ftell(disk);
          } else {
            fseek(disk, top->data, SEEK_SET);
            std::cout << "seek " << top->data << std::endl;
          }

          break;
        }
        case 0xC0002: { // SD status + command
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
        case 0xC0003: { // UART
          if (top->pulse == READ)
            top->data = 0;
          else {
            std::cout << (char) top->data;
          }

          break;
        }
        default: {
          std::cout << "Unhandled IO " << top->port << std::endl;
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
