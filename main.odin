// Project entry point
package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

import "systems"

main :: proc() {
  rl.InitWindow(1280, 720, "Game Header")

  target_width: i32 = 320
  target_height: i32 = 180 
  target_texture := rl.LoadRenderTexture(target_width, target_height)

  player_texture := rl.LoadTexture("res/images/character.png")
  environment_texture := rl.LoadTexture("res/images/Overworld.png")
  npc_texture := rl.LoadTexture("res/images/NPC_test.png")

  scene: systems.Scene
  systems.InitScene(&scene, 320, 180, 16, player_texture, environment_texture, npc_texture)
  
  // scene.sounds = systems.LoadSounds()
  for !rl.WindowShouldClose() {
    dt := rl.GetFrameTime()
    HandleInput(&scene)

    systems.UpdateScene(&scene, dt)
    // systems.UpdateMusic(&scene)
    
    rl.BeginTextureMode(target_texture)
      rl.ClearBackground(rl.WHITE)
      systems.DrawScene(scene)
      rl.EndTextureMode()

    rl.BeginDrawing()
      source_rect := rl.Rectangle{0.0, 0.0, f32(target_texture.texture.width), f32(-target_texture.texture.height)}
      dest_rect := rl.Rectangle{0.0, 0.0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
      tint_color: rl.Color
      if (scene.other_world) {
        tint_color = rl.Color{113, 78, 67, 120}
      }
      else {
        tint_color = rl.WHITE
      }
      rl.DrawTexturePro(target_texture.texture, source_rect, dest_rect, rl.Vector2{0.0, 0.0}, 0, tint_color)
    rl.EndDrawing()
  }
  // systems.UnloadSounds(scene.sounds)
  rl.CloseWindow()
}

HandleInput :: proc(scene: ^systems.Scene) {
}
