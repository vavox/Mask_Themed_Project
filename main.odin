// Project entry point
package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Sprite :: struct {
  texture: rl.Texture,
  dimension: rl.Vector2,
  current_frame: i32,
  frames_count: i32,
  frame_duration: f32,
  animation_time: f32,
  offset: [2]i32,
}

StaticSprite :: struct {
  texture: rl.Texture,
  dimension: rl.Vector2,
  draw_rect: rl.Rectangle,
}

Entity :: union {
  Player,
  Enemy,
  Tile,
}

PlayerState :: enum {
  Idle,
  MoveUp,
  MoveDown,
  MoveRight,
  MoveLeft,
}
PlayerStateSpriteOffset: [PlayerState][2]i32 = {
  .Idle = {1,6},
  .MoveUp = {0,68},
  .MoveDown = {1,6},
  .MoveRight = {1,38},
  .MoveLeft = {1,102},
}

Player :: struct {
  state: PlayerState,
  position: rl.Vector2,
  velocity: rl.Vector2,
  sprite: Sprite
}

Enemy :: struct {
  position: rl.Vector2,
  velocity: rl.Vector2,
}

TileType :: enum {
  None,
  Grass,
  Water,
  Stone,
}

TileSpriteOffset: [TileType][2]i32 = {
  .None  = {0, 0},
  .Grass = {0, 0},
  .Water = {0, 16},
  .Stone = {128, 80},
}

Tile :: struct {
  type: TileType,
  sprite: StaticSprite,
  grid_x: i32,
  grid_y: i32,
  collision: b32,
}

TileGrid :: struct {
  tiles: [dynamic]i32,
  width: i32,
  height: i32,
}

Scene :: struct {
  entities: [dynamic]Entity,
  width: i32,
  height: i32,
  tile_grid: TileGrid,
  player_id: i32,
  other_world: b32,
}

InitScene :: proc(scene: ^Scene, width: i32, height: i32, tile_size: i32, player_texture: rl.Texture, environment_texture: rl.Texture) {
  grid_width := i32(math.ceil(f32(width)/f32(tile_size)))
  grid_height := i32(math.ceil(f32(height)/f32(tile_size)))

  scene.width = width
  scene.height = height
  scene.tile_grid.width = grid_width;
  scene.tile_grid.height = grid_height;

  for row in 0..<grid_height {
    for column in 0..<grid_width {
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
        grid_x = i32(column),
        grid_y = i32(row),
      })
      append(&scene.tile_grid.tiles, id)
    }
  }

  scene.player_id = AddPlayer(scene, Player{
    position = rl.Vector2{100, 100},
    velocity = rl.Vector2{0, 0},
    sprite = Sprite{
      texture = player_texture,
      dimension = rl.Vector2{15, 22},
      current_frame = 0,
      frames_count = 4,
      frame_duration = 0.2
    },
  })

  AddEnemy(scene, Enemy{position = {240, 20}})
}

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

main :: proc() {
  rl.InitWindow(1280, 720, "Game Header")

  target_width: i32 = 320
  target_height: i32 = 180 
  target_texture := rl.LoadRenderTexture(target_width, target_height)

  player_texture := rl.LoadTexture("res/images/character.png")
  environment_texture := rl.LoadTexture("res/images/Overworld.png")

  scene: Scene
  InitScene(&scene, 320, 180, 16, player_texture, environment_texture)

  ChangeTile(&scene, 2, 2, .Water)
  ChangeTile(&scene, 2, 3, .Stone)

  for !rl.WindowShouldClose() {
    dt := rl.GetFrameTime()
    HandleInput(&scene)

    UpdateScene(&scene, dt)
    
    rl.BeginTextureMode(target_texture)
      rl.ClearBackground(rl.WHITE)
        DrawScene(scene)
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

  rl.CloseWindow()
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

AddTile :: proc(scene: ^Scene, tile: Tile) -> i32 {
  id := i32(len(scene.entities))
  append(&scene.entities, tile)
  return id
}

UpdateScene :: proc(scene: ^Scene, dt: f32) {
  for &entity in scene.entities {
    switch &e in entity {
      case Player: {
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
        e.velocity = rl.Vector2Normalize(movement_direction)*100

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
          if player, result := entity.(Player); result {
            e.velocity = 50*rl.Vector2Normalize(player.position - e.position)
            e.position += e.velocity*dt
          }
        }
      }

      case Tile: {
      }
    }
  }
}

DrawScene :: proc(scene: Scene) {
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

      case Tile: {
        position := rl.Vector2{f32(16*e.grid_x), f32(16*e.grid_y)}
        rl.DrawTextureRec(e.sprite.texture, e.sprite.draw_rect, position, rl.WHITE)
      }

      case Enemy: {
        rl.DrawCircleV(e.position, 10, rl.RED)
      }
    }
  }
}

AnimateSprite :: proc(sprite: ^Sprite, dt: f32) {
  sprite.animation_time += dt

  if sprite.animation_time >= sprite.frame_duration {
    sprite.current_frame = (sprite.current_frame + 1) % sprite.frames_count
    sprite.animation_time = 0
  }

  sprite.offset[0] += sprite.current_frame*i32(sprite.dimension.x)
}

HandleInput :: proc(scene: ^Scene) {
}
