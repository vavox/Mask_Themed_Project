package systems

import "core:fmt"
import "core:math"
import "core:slice"
import rl "vendor:raylib"

InitScene :: proc(scene: ^Scene, width: i32, height: i32, tile_size: i32, player_texture: rl.Texture, environment_texture: rl.Texture, npc_texture: rl.Texture, levels: []Level) -> b32 {
  grid_width := i32(math.ceil(f32(width)/f32(tile_size)))
  grid_height := i32(math.ceil(f32(height)/f32(tile_size)))

  if len(levels) == 0 || levels == nil {
    fmt.printf("ERROR! InitScene levels list is empty!\nFurther loading aborted!")
    return false
  }
  
  scene.current_level_idx = 0
  scene.current_level = levels[scene.current_level_idx]
  scene.level_list = levels

  scene.width = width //scene.current_level.width * 16
  scene.height = height //scene.current_level.height * 16
  scene.tile_grid.width = scene.current_level.width
  scene.tile_grid.height = scene.current_level.height

  scene.player_texture = player_texture
  scene.environment_texture = environment_texture
  scene.npc_texture = npc_texture

  LoadLevel(scene, scene.current_level)
  scene.camera = InitCamera(scene.current_level.width * 16, scene.current_level.height * 16, width, height)
  LoadEntities(scene, scene.current_level)

  SortEntities(scene)
  scene.active_world = .Real

  return true
}

UpdateMusic :: proc(scene: ^Scene) {
  if scene.other_world {
      rl.UpdateMusicStream(scene.sounds.other_world_music)
      if !rl.IsMusicStreamPlaying(scene.sounds.other_world_music) {
          rl.PlayMusicStream(scene.sounds.other_world_music)
      }
      rl.StopMusicStream(scene.sounds.normal_world_music)
  } else {
      rl.UpdateMusicStream(scene.sounds.normal_world_music)
      if !rl.IsMusicStreamPlaying(scene.sounds.normal_world_music) {
          rl.PlayMusicStream(scene.sounds.normal_world_music)
      }
      rl.StopMusicStream(scene.sounds.other_world_music)
  }
}

UpdateScene :: proc(scene: ^Scene, dt: f32) {
  clear(&scene.collisions)

  CollisionDetection(scene)
  SolveCollision(scene)

  for &entity in scene.entities {
    switch &kind_data in entity.kind_data {
      case PlayerData: {
        UpdateCamera(&scene.camera, entity.position, dt)
        kind_data.state = .Idle
        movement_direction := rl.Vector2{0, 0}
        if rl.IsKeyDown(.W) {
          kind_data.state = .Move
          kind_data.direction = .Up
          movement_direction.y = -1
        }
        if rl.IsKeyDown(.S) {
          kind_data.state = .Move
          kind_data.direction = .Down
          movement_direction.y = 1
        }
        if rl.IsKeyDown(.A) {
          kind_data.state = .Move
          kind_data.direction = .Left
          movement_direction.x = -1
        }
        if rl.IsKeyDown(.D) {
          kind_data.state = .Move
          kind_data.direction = .Right
          movement_direction.x = 1
        }
        
        movement_speed:f32 = 55
        kind_data.velocity = rl.Vector2Normalize(movement_direction) * movement_speed

        entity.position += kind_data.velocity*dt
        entity.position = rl.Vector2Clamp(entity.position, rl.Vector2{0,0}, rl.Vector2{f32(scene.width) - kind_data.sprite.dimension.x, f32(scene.height) - kind_data.sprite.dimension.y})

        switch kind_data.state {
          case .Idle: {
            kind_data.sprite.offset = PlayerIdleSpriteOffset[kind_data.direction]
          }
          
          case .Move: {
            kind_data.sprite.offset = PlayerMoveSpriteOffset[kind_data.direction]
          }
        }

        if kind_data.state != .Idle {
          AnimateSprite(&kind_data.sprite, dt)
          // if !rl.IsSoundPlaying(scene.sounds.player_move) {
            // rl.PlaySound(scene.sounds.player_move)
          // }
        }

        if rl.IsKeyPressed(.V) {
          scene.other_world = !scene.other_world
          scene.active_world = .Other if scene.other_world else .Real
          SwitchWorld(scene, scene.current_level, scene.other_world)
          // rl.PlaySound(scene.sounds.world_switch)
        }

        // Test purposes
        if rl.IsKeyPressed(.R) {
          ReloadLevel(scene, scene.current_level)
        }

        if kind_data.interaction_zone != nil {
          switch kind_data.direction {
            case .Up: {
              kind_data.interaction_zone.position = entity.position
            }

            case .Down: {
              kind_data.interaction_zone.position = entity.position + rl.Vector2{0, 23}
            }

            case .Left: {
              kind_data.interaction_zone.position = entity.position + rl.Vector2{-16, 8}
            }

            case .Right: {
              kind_data.interaction_zone.position = entity.position + rl.Vector2{16, 8}
            }
          }

        }
      }

      case EnemyData: {
        if scene.other_world && !kind_data.trapped {
          player := scene.entities[scene.player_id]
          movement_speed:f32 = 55
          if player_data, result := player.kind_data.(PlayerData); result {
            kind_data.velocity = movement_speed  *rl.Vector2Normalize(player.position - entity.position)
            entity.position += kind_data.velocity*dt
          }
        }
      }

      case ButtonData: {
        entered := kind_data.active && !kind_data.pressed
        leaved := !kind_data.active && kind_data.pressed
        if entered {
          fmt.println("ButtonExit")
          kind_data.active = false
        }

        if leaved {
          fmt.println("ButtonEnter")
          kind_data.active = true
        }

        kind_data.pressed = false
      }

      case SpiritTrapData: {
      }

      case BoxData: {
      }

      case TileData: {
      }

      case InteractionZoneData: {
      }

      case DoorData: {
        UpdateDoors(scene)
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
          if tile, result := entity.kind_data.(TileData); result {
            position := rl.Vector2{f32(16*tile.grid_x), f32(16*tile.grid_y)}
            rl.DrawTextureRec(tile.sprite.texture, tile.sprite.draw_rect, position, rl.WHITE)
          }
        }
      }
    }
  }

  for entity in scene.entities {
    // Skip entity drawing if entity world and current world mismatch
    if entity.drawing_world != scene.active_world && entity.drawing_world != .Both {
      continue
    }

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
        if kind.pressed {
          rl.DrawRectangleV(entity.position, kind.sprite.dimension, rl.VIOLET)
        }
        else {
          rl.DrawRectangleV(entity.position, kind.sprite.dimension, rl.YELLOW)
        }
      }

      case SpiritTrapData: {
        rl.DrawRectangleV(entity.position, kind.sprite.dimension, rl.ORANGE)
      }

      case TileData: {
      }

      case BoxData: {
        rl.DrawRectangleV(entity.position, kind.sprite.dimension, rl.GRAY)
      }

      case DoorData: {
        if kind.is_open {
          rl.DrawRectangleV(entity.position, kind.sprite.dimension, rl.GREEN)
        } else {
          rl.DrawRectangleV(entity.position, kind.sprite.dimension, rl.RED)
        }
      }

      case InteractionZoneData: {
        // rl.DrawRectangleLines(i32(entity.position.x), i32(entity.position.y), i32(entity.collision_rect.width), i32(entity.collision_rect.height), rl.BLUE)
      }
    }
  }

  rl.EndMode2D()
}

SortEntities :: proc(scene: ^Scene) {
  slice.sort_by(scene.entities[:], proc(a, b: Entity) -> bool {
    return GetDrawPriority(a) < GetDrawPriority(b)
  })

  player_idx := -1
  zone_idx   := -1

  for entity, i in scene.entities {
      #partial switch _ in entity.kind_data {
      case PlayerData:          player_idx = i
      case InteractionZoneData: zone_idx   = i
      }
  }

  if player_idx != -1 && zone_idx != -1 {
    scene.player_id = i32(player_idx)
    
    p_data := &scene.entities[player_idx].kind_data.(PlayerData)
    
    p_data.interaction_zone = &scene.entities[zone_idx]
  }
}


// Drawing order priority
GetDrawPriority :: proc(entity: Entity) -> int {
  switch _ in entity.kind_data {
    case TileData:           return 0
    case ButtonData:         return 1
    case SpiritTrapData:     return 2
    case BoxData:            return 3
    case DoorData:           return 4
    case PlayerData:         return 5
    case EnemyData:          return 6
    case InteractionZoneData: return 7
    case:                    return 99
  }
}

AddEntity :: proc(scene: ^Scene, entity: Entity) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, entity)
  return id
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
