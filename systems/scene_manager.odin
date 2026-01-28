package systems

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

import "../entities"

InitScene :: proc(scene: ^Scene, width: i32, height: i32, tile_size: i32, player_texture: rl.Texture, environment_texture: rl.Texture, npc_texture: rl.Texture, level: Level = TEST_LEVEL) {
  grid_width := i32(math.ceil(f32(width)/f32(tile_size)))
  grid_height := i32(math.ceil(f32(height)/f32(tile_size)))

  scene.width = level.width * 16
  scene.height = level.height * 16
  scene.tile_grid.width = level.width
  scene.tile_grid.height = level.height

  LoadLevel(scene, level, environment_texture)

  scene.camera = InitCamera(scene.width, scene.height, 320, 180)
  
  scene.player_id = AddPlayer(scene, Player{
    position = rl.Vector2{100, 100},
    velocity = rl.Vector2{0, 0},
    sprite = Sprite{
      texture = player_texture,
      dimension = rl.Vector2{16, 22},
      current_frame = 0,
      frames_count = 4,
      frame_duration = 0.2
    },
  })

  AddEnemy(scene, Enemy{
    position = {240, 20},
    sprite = Sprite {
      texture = npc_texture,
      dimension = rl.Vector2{16, 27},
      current_frame = 0,
      frames_count = 4,
      frame_duration = 0.2
    }
  })
}


UpdateScene :: proc(scene: ^Scene, dt: f32) {
  for &entity in scene.entities {
    switch &e in entity {
      case Player: {
        UpdateCamera(&scene.camera, e.position, dt)
        e.state = .Idle
        movement_direction := rl.Vector2{0, 0}
        if rl.IsKeyDown(.W) {
          e.state = .MoveUp
          movement_direction.y = -1
        }
        if rl.IsKeyDown(.S) {
          e.state = .MoveDown
          movement_direction.y = 1
        }
        if rl.IsKeyDown(.A) {
          e.state = .MoveLeft
          movement_direction.x = -1
        }
        if rl.IsKeyDown(.D) {
          e.state = .MoveRight
          movement_direction.x = 1
        }
        movement_speed:f32 = 55
        e.velocity = rl.Vector2Normalize(movement_direction) * movement_speed

        CollisionDetection(scene, &e.position)
        e.position += e.velocity*dt
        e.position = rl.Vector2Clamp(e.position, rl.Vector2{0,0}, rl.Vector2{f32(scene.width) - e.sprite.dimension.x, f32(scene.height) - e.sprite.dimension.y})

        e.sprite.offset = PlayerStateSpriteOffset[e.state]

        if e.state != .Idle {
          AnimateSprite(&e.sprite, dt)
        }

        if rl.IsKeyPressed(.V) {
          scene.other_world = !scene.other_world
        }
      }

      case Enemy: {
        if scene.other_world {
          entity := scene.entities[scene.player_id]
          movement_speed:f32 = 55
          if player, result := entity.(Player); result {
            e.velocity = movement_speed  *rl.Vector2Normalize(player.position - e.position)
            e.position += e.velocity*dt
          }
        }
      }

      case Tile: {
      }
    }
  }
}

CollisionDetection :: proc(scene: ^Scene, position: ^[2]f32){
  player := scene.entities[scene.player_id].(Player)
  legs_offset:f32 = 4
  shadow_offset:f32 = 2
  width_offset:f32 = 4
  player_rect := rl.Rectangle {
    x = position.x,
    y = position.y + player.sprite.dimension.y - legs_offset - shadow_offset,
    width = player.sprite.dimension.x - width_offset,
    height = legs_offset,
  }

  for &entity in scene.entities {
    switch &e in entity{
      case Player: { }
      case Enemy: { }
      case Tile: {
        if !e.collision do continue
        
        tile_rect := rl.Rectangle {
          x = f32(e.grid_x * 16),
          y = f32(e.grid_y * 16),
          width = e.sprite.dimension.x,
          height = e.sprite.dimension.y,
        }
        
        if rl.CheckCollisionRecs(player_rect, tile_rect) {
          overlap_left := (player_rect.x + player_rect.width) - tile_rect.x
          overlap_right := (tile_rect.x + tile_rect.width) - player_rect.x
          overlap_top := (player_rect.y + player_rect.height) - tile_rect.y
          overlap_bottom := (tile_rect.y + tile_rect.height) - player_rect.y
          
          resolve_x := min(overlap_left, overlap_right)
          resolve_y := min(overlap_top, overlap_bottom)
          
          if resolve_x < resolve_y {  // horizontal collision
            if overlap_left < overlap_right {
              position.x = tile_rect.x - player_rect.width
            }
            else {
              position.x = tile_rect.x + tile_rect.width
            }
          }
          else { // vertical collision
            if overlap_top < overlap_bottom {
              position.y = tile_rect.y - tile_rect.height - player_rect.height
            }
            else {
              position.y = tile_rect.y
            }
          }
        }
      }
    }
  }
  
}



DrawScene :: proc(scene: Scene) {
  camera := rl.Camera2D{
    target = scene.camera.position,
    offset = rl.Vector2{f32(scene.camera.view_width) / 2.0, f32(scene.camera.view_height) / 2.0},
    rotation = 0,
    zoom = scene.camera.zoom,
  }
  
  rl.BeginMode2D(camera)
  
  min_x, min_y, max_x, max_y := GetVisibleTiles(scene.camera, 16)
  max_x = min(max_x, scene.tile_grid.width)
  max_y = min(max_y, scene.tile_grid.height)

  for y in min_y..<max_y {
    for x in min_x..<max_x {
      tile_index := y * scene.tile_grid.width + x
      if tile_index >= 0 && tile_index < i32(len(scene.tile_grid.tiles)) {
        entity_id := scene.tile_grid.tiles[tile_index]
        if entity_id < i32(len(scene.entities)) {
          entity := scene.entities[entity_id]
          if tile, result := entity.(Tile); result {
            position := rl.Vector2{f32(16*tile.grid_x), f32(16*tile.grid_y)}
            rl.DrawTextureRec(tile.sprite.texture, tile.sprite.draw_rect, position, rl.WHITE)
          }
        }
      }
    }
  }

  for entity in scene.entities {
    switch &e in entity {
      case Player: {
        draw_rect := rl.Rectangle{
          x = f32(e.sprite.offset.x),
          y = f32(e.sprite.offset.y),
          width = e.sprite.dimension.x,
          height = e.sprite.dimension.y,
        }
        rl.DrawTextureRec(e.sprite.texture, draw_rect, e.position, rl.WHITE)
      }

      case Enemy: {
        draw_rect := rl.Rectangle{
          x = f32(e.sprite.offset.x),
          y = f32(e.sprite.offset.y),
          width = e.sprite.dimension.x,
          height = e.sprite.dimension.y,
        }
        rl.DrawTextureRec(e.sprite.texture, draw_rect, e.position, rl.RED)
      }

      case Tile: {
      }
    }
  }
  
  rl.EndMode2D()
}

AddPlayer :: proc(scene: ^Scene, player: Player) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, player)
  return id
}

AddEnemy :: proc(scene: ^Scene, enemy: Enemy) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, enemy)
  return id
}