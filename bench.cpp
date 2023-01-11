#include "VSOC.h"
#include "verilated.h"

#include <iostream>
#include <SDL2/SDL.h>
#include <cstdio>

#define SCREEN_WIDTH 1024
#define SCREEN_HEIGHT 768

Uint16 *pixels = new Uint16[SCREEN_WIDTH * SCREEN_HEIGHT];
void veri(int argc, char** argv);

int main(int argc, char** argv) {
  SDL_Init(SDL_INIT_VIDEO);
  SDL_Window *window = SDL_CreateWindow("Achieve OS", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
  SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED); 
  SDL_Texture *texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB565, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);

  std::thread screen_thread(veri, argc, argv);

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

  screen_thread.join();
  SDL_DestroyTexture(texture);
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
  delete[] pixels;

  return 0;
}

void veri(int argc, char** argv) {
  // Verilator Initialization
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  VSOC* top = new VSOC{contextp};
  top->clk = 0;

  // SDL window
  memset(pixels, 0, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(Uint16));

  while (!contextp->gotFinish()) { 
    top->clk = !top->clk; 
    top->eval(); // 1
    top->clk = !top->clk;
    top->eval(); // 0
    if (top->IOenable) {
      switch (top->port) {
        case 0 ... SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(Uint16): {
          pixels[top->port] = top->data;
        }
        default: {
          std::cout << "Unhandled IO " << top->port << std::endl;
        }
      }
    }
  }

  // Verilator cleanup
  delete top;
  delete contextp;
}
