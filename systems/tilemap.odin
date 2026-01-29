package systems
import rl "vendor:raylib"

DEFAULT_TILE_HEIGHT :: 16
DEFAULT_TILE_WIDTH :: 16

PositionFromGrid :: proc(scene: ^Scene, grid_x: i32, grid_y: i32) -> rl.Vector2 {
  // AlNov: @TODO Remove hardcoded tile_size
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
      
      // Update collision
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

LoadEntities::proc(scene: ^Scene, level: Level) {
  // Constants
  LEGS_OFFSET :: 4
  SHADOW_OFFSET :: 2
  WIDTH_OFFSET :: 4
  SPRITE_DIM :: rl.Vector2{16, 22}
  ENV_DIM :: rl.Vector2{16, 16}
  
  // Pre-allocate spirit positions array with reasonable capacity
  spirit_positions := make([dynamic]rl.Vector2, 0, 16)
  defer delete(spirit_positions)
  
  player_grid_pos := rl.Vector2{0, 0}
  data_ptr : [^]u8
  data_ptr = cast([^]u8)level.entities_data
  
  // Single pass through entity data
  for y in 0..<level.height {
      for x in 0..<level.width {
          data_index := y * level.width + x
          char := data_ptr[data_index]
          
          switch char {
          case 'P':
              player_grid_pos = rl.Vector2{f32(x), f32(y)}
              
          case 'S':
              append(&spirit_positions, rl.Vector2{f32(x), f32(y)})
              
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
              })
              
          case 'I':
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
                  },
              })
          }
      }
  }
  
  // Collision rect calculation
  collision_y := SPRITE_DIM.y - LEGS_OFFSET - SHADOW_OFFSET
  collision_rect := rl.Rectangle{
      x = 0,
      y = collision_y,
      width = SPRITE_DIM.x - WIDTH_OFFSET,
      height = LEGS_OFFSET,
  }
  
  // Add enemies
  for pos in spirit_positions {
      AddEnemy(scene, Entity{
          position = PositionFromGrid(scene, i32(pos.x), i32(pos.y)),
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
      })
  }
  
  // Add player
  scene.player_id = AddPlayer(scene, Entity{
      position = PositionFromGrid(scene, i32(player_grid_pos.x), i32(player_grid_pos.y)),
      collision = true,
      collision_rect = collision_rect,
      kind_data = PlayerData{
          velocity = {0, 0},
          sprite = Sprite{
              texture = scene.player_texture,
              dimension = SPRITE_DIM,
              current_frame = 0,
              frames_count = 4,
              frame_duration = 0.2,
          },
      },
  })
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
  
  // Reset camera to player position
  if scene.player_id < i32(len(scene.entities)) {
      player := scene.entities[scene.player_id]
      scene.camera.position = player.position
  }
}

