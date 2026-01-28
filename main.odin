// Project entry point
package game

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
  rl.InitWindow(640, 360, "Game Header")

  for !rl.WindowShouldClose() { }

  rl.CloseWindow()
}
