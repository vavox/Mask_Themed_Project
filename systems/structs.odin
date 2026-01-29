package systems

import rl "vendor:raylib"

EntityKindData :: union {
  PlayerData,
  EnemyData,
  ButtonData,
  SpiritTrapData,
  TileData,
}

Entity :: struct {
  position: rl.Vector2,
  collision: b32,
  collision_rect: rl.Rectangle,
  kind_data: EntityKindData,
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

PlayerData :: struct {
  state: PlayerState,
  velocity: rl.Vector2,
  sprite: Sprite,
}

EnemyData :: struct {
  velocity: rl.Vector2,
  sprite: Sprite,
  trapped: b32,
}

ButtonData :: struct {
  sprite: StaticSprite,
  pressed: b32,
}

SpiritTrapData :: struct {
  sprite: StaticSprite,
}

TileData :: struct {
  type: TileType,
  sprite: StaticSprite,
  grid_x: i32,
  grid_y: i32,
}

TileGrid :: struct {
  tiles: [dynamic]i32,
  width: i32,
  height: i32,
}

CollisionResult :: struct {
  a: ^Entity,
  b: ^Entity,
  penetration: rl.Vector2
}

Scene :: struct {
  entities: [dynamic]Entity,
  width: i32,
  height: i32,
  tile_grid: TileGrid,
  camera: Camera,
  player_id: i32,
  other_world: b32,
  collisions: [dynamic]CollisionResult,
  current_level: Level,
  player_texture: rl.Texture,
  environment_texture: rl.Texture,
  npc_texture: rl.Texture
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
  other_world_data: cstring,
  entities_data: cstring,
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
  other_world_data = "GGGGGGGGGGGGGGGGGGGG" +
                     "GGGGGGGGGGGGGGGGGGGG" +
                     "GGSSGGGGWWWGGGSGGGGG" +
                     "GGSSGGSSWWWSSSSGGGGG" +
                     "GGGGGGSGGGGGGGGGGGGG" +
                     "GGGGGGSSSSSGGGGGGGGG" +
                     "GGGGGGGGGGSGGGGGGGGG" +
                     "GGGGGGGGGGSGGGGGGGGG" +
                     "GGGGGGWWGGGGGGGGGGGG" +
                     "GGGGGGWWGGGGGGGGGGGG" +
                     "GGGGGGWWGGGGGGGGGGGG" +
                     "GGGGGGWWGGGGGGGGGGGG" +
                     "WWWWWWWWWWWWWWWWWWWW" +
                     "WWWWWWWWWWWWWWWWWWWW" +
                     "WWWWWWWWWWWWWWWWWWWW",
  // P=Player, S=Spirit, T=Trap, I-Interactable
  entities_data = "--------------------" +
                  "--------------------" +
                  "-S--------------S---" +
                  "--------------------" +
                  "--------------------" +
                  "---I----------------" +
                  "--------------------" +
                  "---P------------TT--" +
                  "----------------T---" +
                  "-----I--------------" +
                  "--------------------" +
                  "--------------------" +
                  "--------------------" +
                  "-----------------S--" +
                  "--------------------",
}

