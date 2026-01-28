package systems

AnimateSprite :: proc(sprite: ^Sprite, dt: f32) {
  sprite.animation_time += dt

  if sprite.animation_time >= sprite.frame_duration {
    sprite.current_frame = (sprite.current_frame + 1) % sprite.frames_count
    sprite.animation_time = 0
  }

  sprite.offset[0] += sprite.current_frame*i32(sprite.dimension.x)
}
