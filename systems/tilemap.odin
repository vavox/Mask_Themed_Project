package systems
import rl "vendor:raylib"


ChangeTile :: proc(scene: ^Scene, grid_x: i32, grid_y: i32, type: TileType) {
  entity_id := scene.tile_grid.tiles[scene.tile_grid.width*grid_y + grid_x]
  entity := &scene.entities[entity_id]

  if tile, result := &entity.(Tile); result {
    offset := TileSpriteOffset[type]
    tile.sprite.draw_rect.x = f32(offset[0])
    tile.sprite.draw_rect.y = f32(offset[1])

    if type == .Stone {
      tile.collision = true
    }
  }
}

AddTile :: proc(scene: ^Scene, tile: Tile) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, tile)
  return id
}

LoadLevel :: proc(scene: ^Scene, level: Level, environment_texture: rl.Texture) {
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
      
      id := AddTile(scene, Tile{
        sprite = StaticSprite{
          texture = environment_texture,
          dimension = rl.Vector2{16, 16},
          draw_rect = rl.Rectangle{
            x = 0,
            y = 0,
            width = 16,
            height = 16
          },
        },
        grid_x = x,
        grid_y = y,
      })
      
      if tile, result := &scene.entities[id].(Tile); result {
        tile.type = tile_type
        offset := TileSpriteOffset[tile_type]
        tile.sprite.draw_rect.x = f32(offset[0])
        tile.sprite.draw_rect.y = f32(offset[1])
        
        if tile_type == .Stone || tile_type == .Water {
          tile.collision = true
        }
      }
      
      append(&scene.tile_grid.tiles, id)
    }
  }
}