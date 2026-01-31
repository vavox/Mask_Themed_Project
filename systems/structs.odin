package systems

import rl "vendor:raylib"

World :: enum {
  Real,
  Other,
  Both
}

EntityKindData :: union {
  PlayerData,
  EnemyData,
  ButtonData,
  SpiritTrapData,
  BoxData,
  TileData,
  InteractionZoneData,
  DoorData,
}

Entity :: struct {
  position: rl.Vector2,
  collision: b32,
  collision_rect: rl.Rectangle,
  kind_data: EntityKindData,
  drawing_world: World
}

PlayerState :: enum {
  Idle,
  Move,
}

PlayerDirection :: enum {
  Up,
  Down,
  Left,
  Right,
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
  direction: PlayerDirection,
  velocity: rl.Vector2,
  sprite: Sprite,
  interaction_zone: ^Entity,
}

EnemyData :: struct {
  velocity: rl.Vector2,
  sprite: Sprite,
  trapped: b32,
}

ButtonData :: struct {
  sprite: StaticSprite,
  pressed: b32,
  active: b32,
  button_id: i32,  // Assigned based on position from level data
}

SpiritTrapData :: struct {
  sprite: StaticSprite,
}

BoxData :: struct {
  sprite: StaticSprite,
}

TileData :: struct {
  type: TileType,
  sprite: StaticSprite,
  grid_x: i32,
  grid_y: i32,
}

DoorData :: struct {
  sprite: StaticSprite,
  grid_x: i32,
  grid_y: i32,
  is_open: b32,
  required_button_ids: [dynamic]i32,
}

InteractionZoneData :: struct {
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

// Position-based button ID definition
ButtonIDMapping :: struct {
  grid_x: i32,
  grid_y: i32,
  button_id: i32,
}

// Position-based door connection definition
DoorConnectionMapping :: struct {
  grid_x: i32,
  grid_y: i32,
  required_button_ids: []i32,
}

// Position based drawing world definition
DrawingWorldSpecifics :: struct {
  grid_x: i32,
  grid_y: i32,
  world: World,
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
  npc_texture: rl.Texture,
  sounds: Sounds,
  active_world: World,
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

Sounds :: struct {
  world_switch: rl.Sound,
  button_press: rl.Sound,
  trap_trigger: rl.Sound,
  player_move: rl.Sound,
  normal_world_music: rl.Music,
  other_world_music: rl.Music
}

Level :: struct {
  name: cstring,
  width: i32,
  height: i32,
  data: cstring,
  other_world_data: cstring,
  entities_data: cstring,
  
  button_ids: []ButtonIDMapping,
  door_connections: []DoorConnectionMapping,
  drawing_world_specifics: []DrawingWorldSpecifics,
}

PlayerIdleSpriteOffset: [PlayerDirection][2]i32 = {
  .Up = {0,68},
  .Down = {1,6},
  .Right = {1,38},
  .Left = {1,102},
}

PlayerMoveSpriteOffset: [PlayerDirection][2]i32 = {
  .Up = {0,68},
  .Down = {1,6},
  .Right = {1,38},
  .Left = {1,102},
}

TileSpriteOffset: [TileType][2]i32 = {
  .None  = {0, 0},
  .Grass = {0, 0},
  .Water = {0, 16},
  .Stone = {128, 80},
}

LevelOne :: Level {
  // --AlNov: @NOTE Simple level to show movement
  name = "First Steps",
  width = 10,
  height = 10,
  data = ""+
    "WWWWWWWWWW" +
    "WWWWWWWWWW" +
    "WWWWWWWWWW" +
    "WGGGGGGGGW" +
    "WGGGGGGGGW" +
    "WGGGGGGGGW" +
    "WGGGGGGGGW" +
    "WWWWWWWWWW" +
    "WWWWWWWWWW" +
    "WWWWWWWWWW",
  other_world_data = ""+
    "WWWWWWWWWW" +
    "WWWWWWWWWW" +
    "WWWWWWWWWW" +
    "WGGGGGGGGW" +
    "WGGGGGGGGW" +
    "WGGGGGGGGW" +
    "WGGGGGGGGW" +
    "WWWWWWWWWW" +
    "WWWWWWWWWW" +
    "WWWWWWWWWW",
  entities_data = 
    "----------" +
    "----------" +
    "----------" +
    "----------" +
    "-P------D-" +
    "----------" +
    "----------" +
    "----------" +
    "----------" +
    "----------",
}

// G=Grass, W=Water, S=Stone, N=None
// P=Player, S=Spirit, T=Trap, I=Button, B=Box, D=Door
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
                     
  entities_data = "--------------------" +
                  "--------------------" +
                  "-S--------------S---" +
                  "--------------------" +
                  "--------------------" +
                  "---I----------------" +  // Button at (3, 5)
                  "--------------------" +
                  "---P--B---------TT--" +
                  "----------------T---" +
                  "-----I--------------" +  // Button at (5, 9)
                  "---D----------------" +  // Door at (3, 10)
                  "--------------------" +
                  "--------------------" +
                  "-----------------S--" +
                  "--------------------",
  
  // Define which button is which ID by position
  button_ids = {
    {grid_x = 3, grid_y = 5, button_id = 0},  // First button gets ID 0
    {grid_x = 5, grid_y = 9, button_id = 1},  // Second button gets ID 1
  },
  
  // Define which doors need which buttons by position
  door_connections = {
    {grid_x = 3, grid_y = 10, required_button_ids = {0, 1}},  // Door at (3,10) needs buttons 0 and 1
  },

  // World drawing separation. If entity has no specifics level mappings at "drawing_world_specifics" than entity presented in both worlds
  drawing_world_specifics = {
    {grid_x = 3, grid_y = 10, world = .Other}
  }
}
