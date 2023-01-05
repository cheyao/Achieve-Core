#include "VSOC.h"
#include "verilated.h"

#include <iostream>
#include <SDL2/SDL.h>
#include <cstdio>

#define SCREEN_WIDTH 1024
#define SCREEN_HEIGHT 768

int main(int argc, char** argv) {
  // Verilator Initialization
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  VSOC* top = new VSOC{contextp};
  top->clk = 0;

  // SDL window
  SDL_Event event;
  SDL_Renderer *renderer;
  SDL_Window *window;
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(SCREEN_WIDTH, SCREEN_HEIGHT, 0, &window, &renderer);
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
  SDL_RenderClear(renderer);
  uint16_t x = 0, y = 0, color = 0;

  while (!contextp->gotFinish()) { 
    top->clk = !top->clk;
    top->eval();
    if (top->IOenable) {
      switch (top->port) {
        case 0: {
          std::cout << "Got screen write. x: " << x << " y: " << y << " color: " << (((top->data >> 11 & 0x1F) * 527 + 23) >> 6) << " " << (((top->data >> 5 & 0x3F) * 259 + 33) >> 6) << " " << (((top->data & 0x1F) * 527 + 23) >> 6) << std::endl;
          SDL_SetRenderDrawColor(renderer, ((top->data >> 11 & 0x1F) * 527 + 23) >> 6, ((top->data >> 5 & 0x3F) * 259 + 33) >> 6, ((top->data & 0x1F) * 527 + 23) >> 6, 0);
          SDL_RenderDrawPoint(renderer, x, y);
          SDL_RenderPresent(renderer);
        }
        case 1: {
          x = top->data;
          printf("X: %d\n", top->data);
        }
        case 2: {
          y = top->data;
          printf("Y: %d\n", top->data);
        }
      }
    }
    top->clk = !top->clk;
    top->eval();
  }

  while (1) { // Poll untill we exit
    if (SDL_PollEvent(&event) && event.type == SDL_QUIT)
      break;
  }

  // Verilator cleanup
  delete top;
  delete contextp;
  // SDL cleanup
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
  return 0;
}
