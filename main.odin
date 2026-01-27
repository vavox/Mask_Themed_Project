// Project entry point
package game

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
  rl.InitWindow(1280, 720, "Game Header")

  for !rl.WindowShouldClose() { }

  rl.CloseWindow()
}
