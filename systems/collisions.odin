package systems

import "core:fmt"
import rl "vendor:raylib"

CollisionDetection :: proc(scene: ^Scene){
  for a_iter := 0; a_iter < len(scene.entities) - 1; a_iter += 1 {
    a := &scene.entities[a_iter]
    _, a_is_tile  := a.kind_data.(TileData)

    // Skip collision detection if entity a world and current world mismatch
    a_valid := a.drawing_world == scene.active_world || a.drawing_world == .Both
    if !a_valid && !a_is_tile do continue

    for b_iter := a_iter + 1; b_iter < len(scene.entities); b_iter += 1 {
      b := &scene.entities[b_iter]
      _, b_is_tile  := b.kind_data.(TileData)
    
      // Skip collision detection if entity b world and current world mismatch
      b_valid := b.drawing_world == scene.active_world || b.drawing_world == .Both
      if !b_valid && !b_is_tile do continue

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

SolvePlayerDoorCollision :: proc(player, door: ^Entity, penetration: rl.Vector2, scene: ^Scene) {
  if door_data, ok := &door.kind_data.(DoorData); ok {
    if door_data.is_open {
      RestartLevel(scene, scene.current_level)  // Restart for completion for now
    } else {
      player.position += penetration
    }
  }
}

SolvePlayerButtonCollision :: proc(player, button: ^Entity, sounds: Sounds) {
  if button_data, result := &button.kind_data.(ButtonData); result {
  button_data.pressed = true
        // if !rl.IsSoundPlaying(scene.sounds.button_press) {
          // rl.PlaySound(sounds.button_press)
        // }
  }
}

SolvePlayerBoxCollision :: proc(box, player: ^Entity, penetration: rl.Vector2) {
  box.position += penetration
  player.position -= penetration
}

SolveBoxTileCollision :: proc(box, tile: ^Entity, penetration: rl.Vector2) {
  box.position += penetration
}

SolveBoxDoorCollision :: proc(box, door: ^Entity, penetration: rl.Vector2) {
  box.position += penetration
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

          case DoorData: {
            SolvePlayerDoorCollision(collision.a, collision.b, collision.penetration, scene)
          }

          case ButtonData: {
            SolvePlayerButtonCollision(collision.a, collision.b, scene.sounds)
          }

          case BoxData: {
            SolvePlayerBoxCollision(collision.b, collision.a, collision.penetration)
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

          case BoxData: {
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

      case BoxData: {
        #partial switch &b_kind in collision.b.kind_data {
          case PlayerData: {
            SolvePlayerBoxCollision(collision.a, collision.b, collision.penetration)
          }

          case ButtonData: {
            SolvePlayerButtonCollision(collision.a, collision.b, scene.sounds)
          }

          case TileData: {
            SolveBoxTileCollision(collision.a, collision.b, collision.penetration)
          }

          case DoorData: {
            SolveBoxDoorCollision(collision.a, collision.b, collision.penetration)
          }
        }
      }

      case TileData: {
        #partial switch &b_kind in collision.b.kind_data {
          case PlayerData: {
            SolvePlayerTileCollision(collision.b, collision.a, -collision.penetration)
          }

          case BoxData: {
            SolveBoxTileCollision(collision.b, collision.a, -collision.penetration)
          }
        }
      }

      case DoorData: {
        #partial switch &b_kind in collision.b.kind_data {
          case PlayerData: {
            SolvePlayerDoorCollision(collision.b, collision.a, -collision.penetration, scene)
          }

          case BoxData: {
            SolveBoxDoorCollision(collision.b, collision.a, -collision.penetration)
          }
        }
      }
    }
  }
}