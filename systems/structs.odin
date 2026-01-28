package systems

import rl "vendor:raylib"

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

TileType :: enum {
  None,
  Grass,
  Water,
  Stone,
}

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

Player :: struct {
  state: PlayerState,
  position: rl.Vector2,
  velocity: rl.Vector2,
  sprite: Sprite
}

Enemy :: struct {
  position: rl.Vector2,
  velocity: rl.Vector2,
  sprite: Sprite
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
  camera: Camera,
  player_id: i32,
  other_world: b32,
}

Camera :: struct {
  position: rl.Vector2,
  target: rl.Vector2,
  zoom: f32,
  world_width: i32,
  world_height: i32,
  view_width: i32,
  view_height: i32,
  follow_speed: f32,
}

Level :: struct {
  name: cstring,
  width: i32,
  height: i32,
  data: cstring,
}

PlayerStateSpriteOffset: [PlayerState][2]i32 = {
  .Idle = {1,6},
  .MoveUp = {0,68},
  .MoveDown = {1,6},
  .MoveRight = {1,38},
  .MoveLeft = {1,102},
}

TileSpriteOffset: [TileType][2]i32 = {
  .None  = {0, 0},
  .Grass = {0, 0},
  .Water = {0, 16},
  .Stone = {128, 80},
}

// G=Grass, W=Water, S=Stone, N=None
TEST_LEVEL :: Level{
  name = "Testland",
  width = 20,
  height = 15,
  data = "GGGGGGGGGGGGGGGGGGGG" +
         "GGGGGGGGGGGGGGGGGGGG" +
         "GGSSGGGGWWWGGGSGGGGG" +
         "GGSSGGGGWWWGGGSGGGGG" +
         "GGGGGGGGGGGGGGGGGGGG" +
         "GGGGGGGGGGGGGGGGGGGG" +
         "GGGGGGGGGGGGGGGGGGGG" +
         "GGGGGGGGGGGGGGGGGGGG" +
         "GGGGGGWWGGGGGGGGGGGG" +
         "GGGGGGWWGGGGGGGGGGGG" +
         "GGGGGGWWGGGGGGGGGGGG" +
         "GGGGGGWWGGGGGGGGGGGG" +
         "WWWWWWWWWWWWWWWWWWWW" +
         "WWWWWWWWWWWWWWWWWWWW" +
         "WWWWWWWWWWWWWWWWWWWW",
}