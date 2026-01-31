package systems

import "core:fmt"
import rl "vendor:raylib"

// Player sprite center offset (16x22 sprite)
PLAYER_SPRITE_CENTER_X :: 8
PLAYER_SPRITE_CENTER_Y :: 11

InitCamera :: proc(world_width: i32, world_height: i32, view_width: i32, view_height: i32) -> Camera {
  return Camera{
    position = rl.Vector2{f32(world_width) / 2, f32(world_height) / 2},
    target = rl.Vector2{f32(world_width) / 2, f32(world_height) / 2},
    zoom = 1.0,
    world_width = world_width,
    world_height = world_height,
    view_width = view_width,
    view_height = view_height
  }
}

ReloadCameraRect :: proc(camera: ^Camera, scene: ^Scene) {
  camera.view_width = scene.width
  camera.view_height = scene.height
  camera.world_width = scene.current_level.width * 16
  camera.world_height = scene.current_level.height * 16
  camera.position = rl.Vector2{f32(scene.width) / 2, f32(scene.height) / 2}
  camera.target = rl.Vector2{f32(scene.width) / 2, f32(scene.height) / 2}
}

UpdateCamera :: proc(camera: ^Camera, player_position: rl.Vector2, dt: f32) {
  player_center := player_position + rl.Vector2{f32(PLAYER_SPRITE_CENTER_X), f32(PLAYER_SPRITE_CENTER_Y)}
  camera.target = player_center

  if camera.world_width <= camera.view_width && camera.world_height <= camera.view_height { return }
  camera.position += (camera.target - camera.position)

  half_view_width := f32(camera.view_width) / (2.0 * camera.zoom)
  half_view_height := f32(camera.view_height) / (2.0 * camera.zoom)

  if camera.position.x < half_view_width {
    camera.position.x = half_view_width
  }
  if camera.position.x > f32(camera.world_width) - half_view_width {
    camera.position.x = f32(camera.world_width) - half_view_width
  }

  if camera.position.y < half_view_height {
    camera.position.y = half_view_height
  }
  if camera.position.y > f32(camera.world_height) - half_view_height {
    camera.position.y = f32(camera.world_height) - half_view_height
  }
}

GetVisibleTiles :: proc(camera: Camera, tile_size: i32) -> (min_x: i32, min_y: i32, max_x: i32, max_y: i32) {
  half_view_width := f32(camera.view_width) / (2.0 * camera.zoom)
  half_view_height := f32(camera.view_height) / (2.0 * camera.zoom)

  min_x = i32((camera.position.x - half_view_width) / f32(tile_size))
  min_y = i32((camera.position.y - half_view_height) / f32(tile_size))
  max_x = i32((camera.position.x + half_view_width) / f32(tile_size)) + 1
  max_y = i32((camera.position.y + half_view_height) / f32(tile_size)) + 1

  if min_x < 0 { min_x = 0 }
  if min_y < 0 { min_y = 0 }

  return
}
