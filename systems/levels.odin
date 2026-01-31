package systems

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

LevelTwo :: Level {
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
    "--------S-" +
    "-------S--" +
    "-P-----SD-" +
    "---------" +
    "----------" +
    "----------" +
    "----------" +
    "----------",
}

LevelThree :: Level {
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
    "----I-----" +
    "----------" +
    "----------" +
    "----------" +
    "----------",
    
    button_ids = {
        {grid_x = 4, grid_y = 5, button_id = 0},
    },

    // Define which doors need which buttons by position
    door_connections = {
        {grid_x = 8, grid_y = 4, required_button_ids = {0}},  // Door at (3,10) needs buttons 0 and 1
    },
}

LevelFour :: Level {
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
    "-P--B--ID-" +
    "----I-----" +
    "----------" +
    "----------" +
    "----------" +
    "----------",
    
    button_ids = {
        {grid_x = 4, grid_y = 5, button_id = 0},
        {grid_x = 7, grid_y = 4, button_id = 1},
    },

    // Define which doors need which buttons by position
    door_connections = {
        {grid_x = 8, grid_y = 4, required_button_ids = {0, 1}},  // Door at (3,10) needs buttons 0 and 1
    },
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
