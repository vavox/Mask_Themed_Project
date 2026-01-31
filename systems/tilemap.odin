package systems
import rl "vendor:raylib"
import "core:fmt"

DEFAULT_TILE_HEIGHT :: 16
DEFAULT_TILE_WIDTH :: 16

PositionFromGrid :: proc(scene: ^Scene, grid_x: i32, grid_y: i32) -> rl.Vector2 {
  result: rl.Vector2
  result.x = f32(grid_x*DEFAULT_TILE_HEIGHT)
  result.y = f32(grid_y*DEFAULT_TILE_WIDTH)
  return result
}

ChangeTile :: proc(scene: ^Scene, grid_x: i32, grid_y: i32, type: TileType) {
  entity_id := scene.tile_grid.tiles[scene.tile_grid.width*grid_y + grid_x]
  entity := &scene.entities[entity_id]
  
  if tile, result := &entity.kind_data.(TileData); result {
      tile.type = type
      offset := TileSpriteOffset[type]
      tile.sprite.draw_rect.x = f32(offset[0])
      tile.sprite.draw_rect.y = f32(offset[1])
      
      should_collide := (type == .Stone || type == .Water)
      
      entity.collision = b32(should_collide)
      
      if should_collide {
          entity.collision_rect = GetTileCollision(tile.sprite)
      }
  }
}

GetTileCollision :: proc(sprite: StaticSprite) -> rl.Rectangle {
  return rl.Rectangle {
    x = 0,
    y = 0,
    width = sprite.dimension.x,
    height = sprite.dimension.y,
  }
}

AddTile :: proc(scene: ^Scene, tile: Entity) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, tile)
  return id
}

LoadLevel :: proc(scene: ^Scene, level: Level) {
  data_ptr := cast([^]u8)level.data
  data_index := 0
  for y in 0..<level.height {
    for x in 0..<level.width {
      tile_type: TileType
      
      char := data_ptr[data_index]
      switch char {
        case 'G': tile_type = .Grass
        case 'W': tile_type = .Water
        case 'S': tile_type = .Stone
        case 'N': tile_type = .None
        case: tile_type = .Grass
      }
      data_index += 1
      
      id := AddTile(scene, Entity{
        position = PositionFromGrid(scene, x, y),
        kind_data = TileData{
          sprite = StaticSprite{
            texture = scene.environment_texture,
            dimension = rl.Vector2{DEFAULT_TILE_HEIGHT, DEFAULT_TILE_WIDTH},
            draw_rect = rl.Rectangle{
              x = 0,
              y = 0,
              width = DEFAULT_TILE_HEIGHT,
              height = DEFAULT_TILE_WIDTH
            },
          },
          grid_x = x,
          grid_y = y,
        },
      })
      
      entity := &scene.entities[id]
      if tile, result := &entity.kind_data.(TileData); result {
        tile.type = tile_type
        offset := TileSpriteOffset[tile_type]
        tile.sprite.draw_rect.x = f32(offset[0])
        tile.sprite.draw_rect.y = f32(offset[1])
        
        if tile_type == .Stone || tile_type == .Water {
          entity.collision = true
          entity.collision_rect = GetTileCollision(tile.sprite)
        }
      }
      
      append(&scene.tile_grid.tiles, id)
    }
  }
}

// Get button ID for a specific position from level data
GetButtonIDForPosition :: proc(level: Level, grid_x: i32, grid_y: i32) -> i32 {
  for mapping in level.button_ids {
    if mapping.grid_x == grid_x && mapping.grid_y == grid_y {
      return mapping.button_id
    }
  }
  return -1  // No ID assigned
}

// Get door connection info for a specific position from level data
GetDoorConnectionForPosition :: proc(level: Level, grid_x: i32, grid_y: i32) -> ([]i32, bool) {
  for mapping in level.door_connections {
    if mapping.grid_x == grid_x && mapping.grid_y == grid_y {
      return mapping.required_button_ids, true
    }
  }
  return nil, false
}

// Get world to draw in
GetDrawingWorld :: proc(level: Level, grid_x: i32, grid_y: i32) -> World {
  for mapping in level.drawing_world_specifics {
    if mapping.grid_x == grid_x && mapping.grid_y == grid_y {
      return mapping.world
    }
  }
  return .Both
}

LoadEntities :: proc(scene: ^Scene, level: Level) {
  LEGS_OFFSET :: 4
  SHADOW_OFFSET :: 2
  WIDTH_OFFSET :: 4
  SPRITE_DIM :: rl.Vector2{16, 22}
  ENV_DIM :: rl.Vector2{16, 16}
  
  data_ptr : [^]u8
  data_ptr = cast([^]u8)level.entities_data
    
  // Collision rect calculation
  collision_y := SPRITE_DIM.y - LEGS_OFFSET - SHADOW_OFFSET
  collision_rect := rl.Rectangle{
      x = 0,
      y = collision_y,
      width = SPRITE_DIM.x - WIDTH_OFFSET,
      height = LEGS_OFFSET,
  }

  // Single pass through entity data
  for y in 0..<level.height {
      for x in 0..<level.width {
          data_index := y * level.width + x
          char := data_ptr[data_index]
          
        switch char {
          case 'P':
            // Add player
            interaction_zone_id := AddEntity(scene, Entity{
              collision = true,
              collision_rect = rl.Rectangle{
                x = 0,
                y = 0,
                width = DEFAULT_TILE_HEIGHT,
                height = DEFAULT_TILE_WIDTH,
              },
              kind_data = InteractionZoneData{},
              drawing_world = GetDrawingWorld(level, x, y)
            })
            scene.player_id = AddPlayer(scene, Entity{
                position = PositionFromGrid(scene, x, y),
                collision = true,
                collision_rect = collision_rect,
                kind_data = PlayerData{
                    velocity = {0, 0},
                    state = .Idle,
                    direction = .Down,
                    sprite = Sprite{
                        texture = scene.player_texture,
                        dimension = SPRITE_DIM,
                        current_frame = 0,
                        frames_count = 4,
                        frame_duration = 0.2,
                    },
                    interaction_zone = &scene.entities[interaction_zone_id],
                },
                drawing_world = GetDrawingWorld(level, x, y)
            })
              
          case 'S':
            // Add enemies
            AddEnemy(scene, Entity{
                position = PositionFromGrid(scene, x, y),
                collision = true,
                collision_rect = collision_rect,
                kind_data = EnemyData{
                    sprite = Sprite{
                        texture = scene.npc_texture,
                        dimension = {16, 27},
                        current_frame = 0,
                        frames_count = 4,
                        frame_duration = 0.2,
                    },
                },
                drawing_world = GetDrawingWorld(level, x, y)
            })

          case 'T':
              AddEntity(scene, Entity{
                  position = PositionFromGrid(scene, x, y),
                  collision = true,
                  collision_rect = {0, 0, 16, 16},
                  kind_data = SpiritTrapData{
                      sprite = StaticSprite{
                          texture = scene.environment_texture,
                          dimension = ENV_DIM,
                          draw_rect = {0, 0, 16, 16},
                      },
                  },
                  drawing_world = GetDrawingWorld(level, x, y)
              })

          case 'B':
              AddEntity(scene, Entity{
                  position = PositionFromGrid(scene, x, y),
                  collision = true,
                  collision_rect = {0, 0, 16, 16},
                  kind_data = BoxData{
                    sprite = StaticSprite{
                        texture = scene.environment_texture,
                        dimension = ENV_DIM,
                        draw_rect = {0, 0, 16, 16},
                    },
                  },
                  drawing_world = GetDrawingWorld(level, x, y)
              })
              
          case 'I':
              // Get the button ID from the level's button_ids mapping
              button_id := GetButtonIDForPosition(level, x, y)
              
              AddEntity(scene, Entity{
                  position = PositionFromGrid(scene, x, y),
                  collision = true,
                  collision_rect = {0, 0, 16, 16},
                  kind_data = ButtonData{
                      sprite = StaticSprite{
                          texture = scene.environment_texture,
                          dimension = ENV_DIM,
                          draw_rect = {0, 0, 16, 16},
                      },
                      button_id = button_id
                  },
                  drawing_world = GetDrawingWorld(level, x, y)
              })

          case 'D':
              // Get the door connection info from the level's door_connections mapping
              required_ids, has_connection := GetDoorConnectionForPosition(level, x, y)
              
              door_required_ids := make([dynamic]i32)
              if has_connection {
                  for req_id in required_ids {
                      append(&door_required_ids, req_id)
                  }
              }
              
              AddEntity(scene, Entity{
                  position = PositionFromGrid(scene, x, y),
                  collision = true,
                  collision_rect = {0, 0, 16, 16},
                  kind_data = DoorData{
                      sprite = StaticSprite{
                          texture = scene.environment_texture,
                          dimension = ENV_DIM,
                          draw_rect = {0, 0, 16, 16},
                      },
                      grid_x = x,
                      grid_y = y,
                      is_open = false,
                      required_button_ids = door_required_ids,
                  },
                  drawing_world = GetDrawingWorld(level, x, y)
              })
          }
      }
  }
}

// Check if all required buttons for a door are pressed
CheckDoorRequirements :: proc(scene: ^Scene, door: ^DoorData) -> b32 {
  if len(door.required_button_ids) == 0 {
    return true  // No requirements means always open
  }
  
  // Check if all required buttons are pressed
  for required_id in door.required_button_ids {
    button_found:b32 = false
    button_pressed:b32 = false
    
    for &entity in scene.entities {
      if button_data, ok := &entity.kind_data.(ButtonData); ok {
        if button_data.button_id == required_id {
          button_found = true
          button_pressed = button_data.active
          break
        }
      }
    }
    
    if !button_found || !button_pressed {
      return false
    }
  }
  
  return true
}

// Update door states based on button presses
UpdateDoors :: proc(scene: ^Scene) {
  for &entity in scene.entities {
    if door_data, ok := &entity.kind_data.(DoorData); ok {
      all_buttons_pressed:b32 = CheckDoorRequirements(scene, door_data)
      
      was_open := door_data.is_open
      if !door_data.is_open {
        door_data.is_open = all_buttons_pressed
      }
      
      if !was_open && door_data.is_open {
        fmt.println("Door at", door_data.grid_x, door_data.grid_y, "opened!")
      } 
    }
  }
}

SwitchWorld :: proc(scene: ^Scene, level: Level, to_other_world: b32) {
    data_to_use := to_other_world ? level.other_world_data : level.data
    data_ptr := cast([^]u8)data_to_use
    
    for y in 0..<level.height {
        for x in 0..<level.width {
            data_index := y * level.width + x
            char := data_ptr[data_index]
            
            tile_type: TileType
            switch char {
                case 'G': tile_type = .Grass
                case 'W': tile_type = .Water
                case 'S': tile_type = .Stone
                case 'N': tile_type = .None
                case: tile_type = .None
            }
            ChangeTile(scene, x, y, tile_type)
        }
    }
}

RestartLevel :: proc(scene: ^Scene, level: Level) {
  // Clean up door data before clearing
  for &entity in scene.entities {
    if door_data, ok := &entity.kind_data.(DoorData); ok {
      delete(door_data.required_button_ids)
    }
  }
  
  // Clear existing data
  clear(&scene.entities)
  clear(&scene.tile_grid.tiles)
  clear(&scene.collisions)
  
  // Reset scene state
  scene.other_world = false
  scene.player_id = 0
  
  // Reset grid dimensions
  scene.width = level.width * 16
  scene.height = level.height * 16
  scene.tile_grid.width = level.width
  scene.tile_grid.height = level.height
  
  // Reload everything from scratch
  LoadLevel(scene, level)
  LoadEntities(scene, level)
  SortEntities(scene)
  
  scene.active_world = .Real
  // Reset camera to player position
  if scene.player_id < i32(len(scene.entities)) {
      player := scene.entities[scene.player_id]
      scene.camera.position = player.position
  }
}
