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

  scene.player_texture = player_texture
  scene.environment_texture = environment_texture
  scene.npc_texture = npc_texture

  LoadLevel(scene, level)
  scene.current_level = level
  scene.camera = InitCamera(scene.width, scene.height, 320, 180)
  LoadEntities(scene, level)
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

        entity.position += kind_data.velocity*dt
        entity.position = rl.Vector2Clamp(entity.position, rl.Vector2{0,0}, rl.Vector2{f32(scene.width) - kind_data.sprite.dimension.x, f32(scene.height) - kind_data.sprite.dimension.y})

        kind_data.sprite.offset = PlayerStateSpriteOffset[kind_data.state]

        if kind_data.state != .Idle {
          AnimateSprite(&kind_data.sprite, dt)
          // if !rl.IsSoundPlaying(scene.sounds.player_move) {
            // rl.PlaySound(scene.sounds.player_move)
          // }
        }

        if rl.IsKeyPressed(.V) {
          scene.other_world = !scene.other_world
          SwitchWorld(scene, scene.current_level, scene.other_world)
          // rl.PlaySound(scene.sounds.world_switch)
        }

        // Test purposes
        if rl.IsKeyPressed(.R) {
          RestartLevel(scene, TEST_LEVEL)
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

      case TileData: {
      }
    }
  }
}

CollisionDetection :: proc(scene: ^Scene){
  for a_iter := 0; a_iter < len(scene.entities) - 1; a_iter += 1 {
    for b_iter := a_iter + 1; b_iter < len(scene.entities); b_iter += 1 {
      a := &scene.entities[a_iter]
      b := &scene.entities[b_iter]

      if (!a.collision || !b.collision) do continue

      a_rect := a.collision_rect
      a_rect.x += a.position.x
      a_rect.y += a.position.y

      b_rect := b.collision_rect
      b_rect.x += b.position.x
      b_rect.y += b.position.y
      
      if rl.CheckCollisionRecs(a_rect, b_rect) {
        collision_result: CollisionResult

        collision_result.a = a
        collision_result.b = b

        overlap_left := (a_rect.x + a_rect.width) - b_rect.x
        overlap_right := (b_rect.x + b_rect.width) - a_rect.x
        overlap_top := (a_rect.y + a_rect.height) - b_rect.y
        overlap_bottom := (b_rect.y + b_rect.height) - a_rect.y
        
        resolve_x := min(overlap_left, overlap_right)
        resolve_y := min(overlap_top, overlap_bottom)

        if resolve_x < resolve_y {  // horizontal collision
          if overlap_left < overlap_right {
            collision_result.penetration.x = -overlap_left
          }
          else {
            collision_result.penetration.x = overlap_right
          }
        }
        else { // vertical collision
          if overlap_top < overlap_bottom {
            collision_result.penetration.y = -overlap_top
          }
          else {
            collision_result.penetration.y = overlap_bottom
          }
        }

        append(&scene.collisions, collision_result)
      }
    }
  }
}

SolvePlayerTileCollision :: proc(player, tile: ^Entity, penetration: rl.Vector2) {
  player.position += penetration
}

SolvePlayerButtonCollision :: proc(player, button: ^Entity, sounds: Sounds) {
  if button_data, result := &button.kind_data.(ButtonData); result {
  button_data.pressed = true
        // if !rl.IsSoundPlaying(scene.sounds.button_press) {
          // rl.PlaySound(sounds.button_press)
        // }
  }
}

SolveSpiritTrapCollision :: proc(spirit, trap: ^Entity, sounds: Sounds) {
  if spirit_data, result := &spirit.kind_data.(EnemyData); result {
    if !spirit_data.trapped {
        spirit_data.trapped = true
        // if !rl.IsSoundPlaying(scene.sounds.trap_trigger) {
          // rl.PlaySound(sounds.trap_trigger)
        // }
    }
  }
}

SolveCollision :: proc(scene: ^Scene) {
  for &collision, iter in scene.collisions {
    #partial switch &a_kind in collision.a.kind_data {
      case PlayerData: {
        #partial switch &b_kind in collision.b.kind_data {
          case TileData: {
            SolvePlayerTileCollision(collision.a, collision.b, collision.penetration)
          }

          case ButtonData: {
            SolvePlayerButtonCollision(collision.a, collision.b, scene.sounds)
          }
        }
      }

      case EnemyData: {
        #partial switch &b_kind in collision.b.kind_data {
          case SpiritTrapData: {
            SolveSpiritTrapCollision(collision.a, collision.b, scene.sounds)
          }
        }
      }

      case ButtonData: {
        #partial switch &b_kind in collision.b.kind_data {
          case PlayerData: {
            SolvePlayerButtonCollision(collision.b, collision.a, scene.sounds)
          }
        }
      }

      case SpiritTrapData: {
        #partial switch &b_kind in collision.b.kind_data {
          case EnemyData: {
            SolveSpiritTrapCollision(collision.b, collision.a, scene.sounds)
          }
        }
      }

      case TileData: {
        #partial switch &b_kind in collision.b.kind_data {
          case PlayerData: {
            SolvePlayerTileCollision(collision.b, collision.a, -collision.penetration)
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
    }
  }
  
  rl.EndMode2D()
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
