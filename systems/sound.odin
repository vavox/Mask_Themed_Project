package systems

import rl "vendor:raylib"

LoadSounds :: proc() -> Sounds {
    sounds: Sounds
    
    rl.InitAudioDevice()
    sounds.world_switch = rl.LoadSound("res/sounds/world_switch.wav")
    sounds.button_press = rl.LoadSound("res/sounds/button_press.wav")
    sounds.trap_trigger = rl.LoadSound("res/sounds/trap_trigger.wav")
    sounds.player_move = rl.LoadSound("res/sounds/player_move.wav")
    sounds.other_world_music = rl.LoadMusicStream("res/sounds/other_world_music.mp3")
    sounds.normal_world_music = rl.LoadMusicStream("res/sounds/normal_world_music.mp3")
    
    rl.SetMusicVolume(sounds.other_world_music, 0.45)
    rl.SetMusicVolume(sounds.normal_world_music, 0.45)
    return sounds
}

UnloadSounds :: proc(sounds: Sounds) {
    rl.UnloadSound(sounds.world_switch)
    rl.UnloadSound(sounds.button_press)
    rl.UnloadSound(sounds.trap_trigger)
    rl.UnloadSound(sounds.player_move)
    rl.UnloadMusicStream(sounds.normal_world_music)
    rl.UnloadMusicStream(sounds.other_world_music)

    rl.CloseAudioDevice()
}