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
  
  legs_offset:f32 = 4
  shadow_offset:f32 = 2
  width_offset:f32 = 4
  sprite_dimension := rl.Vector2{16, 22}

  scene.player_id = AddPlayer(scene, Entity{
    position = rl.Vector2{100, 100},
    collision = true,
    collision_rect = rl.Rectangle {
      x = 0,
      y = sprite_dimension.y - legs_offset - shadow_offset,
      width = sprite_dimension.x - width_offset,
      height = legs_offset,
    },
    kind_data = PlayerData{
      velocity = rl.Vector2{0, 0},
      sprite = Sprite{
        texture = player_texture,
        dimension = sprite_dimension,
        current_frame = 0,
        frames_count = 4,
        frame_duration = 0.2
      },
    },
  })

  AddEnemy(scene, Entity{
    position = {240, 20},
    collision = false,
    kind_data = EnemyData{
      sprite = Sprite {
        texture = npc_texture,
        dimension = rl.Vector2{16, 27},
        current_frame = 0,
        frames_count = 4,
        frame_duration = 0.2
      }
    },
  })
}


UpdateScene :: proc(scene: ^Scene, dt: f32) {
  for &entity in scene.entities {
    switch &kind_data in entity.kind_data {
      case PlayerData: {
        UpdateCamera(&scene.camera, entity.position, dt)
        kind_data.state = .Idle
        movement_direction := rl.Vector2{0, 0}
        if rl.IsKeyDown(.W) {
          kind_data.state = .MoveUp
          movement_direction.y = -1
        }
        if rl.IsKeyDown(.S) {
          kind_data.state = .MoveDown
          movement_direction.y = 1
        }
        if rl.IsKeyDown(.A) {
          kind_data.state = .MoveLeft
          movement_direction.x = -1
        }
        if rl.IsKeyDown(.D) {
          kind_data.state = .MoveRight
          movement_direction.x = 1
        }
        movement_speed:f32 = 55
        kind_data.velocity = rl.Vector2Normalize(movement_direction) * movement_speed

        CollisionDetection(scene)
        entity.position += kind_data.velocity*dt
        entity.position = rl.Vector2Clamp(entity.position, rl.Vector2{0,0}, rl.Vector2{f32(scene.width) - kind_data.sprite.dimension.x, f32(scene.height) - kind_data.sprite.dimension.y})

        kind_data.sprite.offset = PlayerStateSpriteOffset[kind_data.state]

        if kind_data.state != .Idle {
          AnimateSprite(&kind_data.sprite, dt)
        }

        if rl.IsKeyPressed(.V) {
          scene.other_world = !scene.other_world
        }
      }

      case EnemyData: {
        if scene.other_world {
          player := scene.entities[scene.player_id]
          movement_speed:f32 = 55
          if player_data, result := player.kind_data.(PlayerData); result {
            kind_data.velocity = movement_speed  *rl.Vector2Normalize(player.position - entity.position)
            entity.position += kind_data.velocity*dt
          }
        }
      }

      case ButtonData: {
      }

      case TileData: {
      }
    }
  }
}

CollisionDetection :: proc(scene: ^Scene){
  player := &scene.entities[scene.player_id]
  player_data := &player.kind_data.(PlayerData)
  legs_offset:f32 = 4
  shadow_offset:f32 = 2
  width_offset:f32 = 4
  player_rect := rl.Rectangle {
    x = player.position.x,
    y = player.position.y + player_data.sprite.dimension.y - legs_offset - shadow_offset,
    width = player_data.sprite.dimension.x - width_offset,
    height = legs_offset,
  }

  for &entity in scene.entities {
    switch &kind in entity.kind_data{
      case PlayerData: { }
      case EnemyData: { }
      case ButtonData: { }
      case TileData: {
        if !entity.collision do continue
        
        tile_rect := rl.Rectangle {
          x = f32(kind.grid_x * 16),
          y = f32(kind.grid_y * 16),
          width = kind.sprite.dimension.x,
          height = kind.sprite.dimension.y,
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
              player.position.x = tile_rect.x - player_rect.width
            }
            else {
              player.position.x = tile_rect.x + tile_rect.width
            }
          }
          else { // vertical collision
            if overlap_top < overlap_bottom {
              player.position.y = tile_rect.y - tile_rect.height - player_rect.height
            }
            else {
              player.position.y = tile_rect.y
            }
          }
        }
      }
    }
  }
}

SolveCollision :: proc(scene: ^Scene) {
  for collision in scene.collisions {
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
          if tile, result := entity.kind_data.(TileData); result {
            position := rl.Vector2{f32(16*tile.grid_x), f32(16*tile.grid_y)}
            rl.DrawTextureRec(tile.sprite.texture, tile.sprite.draw_rect, position, rl.WHITE)
          }
        }
      }
    }
  }

  for entity in scene.entities {
    switch &kind in entity.kind_data {
      case PlayerData: {
        draw_rect := rl.Rectangle{
          x = f32(kind.sprite.offset.x),
          y = f32(kind.sprite.offset.y),
          width = kind.sprite.dimension.x,
          height = kind.sprite.dimension.y,
        }
        rl.DrawTextureRec(kind.sprite.texture, draw_rect, entity.position, rl.WHITE)
      }

      case EnemyData: {
        draw_rect := rl.Rectangle{
          x = f32(kind.sprite.offset.x),
          y = f32(kind.sprite.offset.y),
          width = kind.sprite.dimension.x,
          height = kind.sprite.dimension.y,
        }
        rl.DrawTextureRec(kind.sprite.texture, draw_rect, entity.position, rl.RED)
      }

      case ButtonData: {
      }

      case TileData: {
      }
    }
  }
  
  rl.EndMode2D()
}

AddPlayer :: proc(scene: ^Scene, player: Entity) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, player)
  return id
}

AddEnemy :: proc(scene: ^Scene, enemy: Entity) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, enemy)
  return id
}
