package main

import "vendor:raylib"
import "core:math"

// Camera wraps raylib's Camera2D and adds smooth following + look-ahead.
Camera :: struct {
	pos:    raylib.Vector2,
	target: raylib.Vector2,
	zoom:   f32,
	rl:     raylib.Camera2D,
	shake_t: f32,
	shake_mag: f32,
}

camera_init :: proc(cam: ^Camera, w, h: int) {
	cam.pos = raylib.Vector2{ cast(f32) w * 0.5, cast(f32) h * 0.5 }
	cam.target = cam.pos
	cam.zoom = CAMERA_ZOOM
	cam.rl.offset = raylib.Vector2{ cast(f32) w * 0.5, cast(f32) h * 0.5 }
	cam.rl.target = cam.pos
	cam.rl.rotation = 0
	cam.rl.zoom = cam.zoom
	cam.shake_t = 0
	cam.shake_mag = 0
}

camera_shake :: proc(cam: ^Camera, magnitude, duration: f32) {
	cam.shake_mag = magnitude
	cam.shake_t = duration
}

camera_update :: proc(cam: ^Camera, target: raylib.Vector2, vel: raylib.Vector2, dt: f32) {
	// Look-ahead in the direction of travel.
	look := vec2_mul(vel, CAMERA_LOOKAHEAD)
	cam.target = vec2_add(target, look)

	dx := cam.target[0] - cam.pos[0]
	dy := cam.target[1] - cam.pos[1]
	if math.abs(dx) > CAMERA_DEADZONE {
		cam.pos[0] += dx * CAMERA_SMOOTH
	}
	if math.abs(dy) > CAMERA_DEADZONE {
		cam.pos[1] += dy * CAMERA_SMOOTH
	}

	// Screen shake decay.
	shake_x: f32 = 0
	shake_y: f32 = 0
	if cam.shake_t > 0 {
		cam.shake_t -= dt
		falloff := cam.shake_t / SHAKE_DURATION
		if falloff < 0 { falloff = 0 }
		// Cheap pseudo-random offset from time.
		t := cam.shake_t * 40.0
		shake_x = math.sin(t * 1.7) * cam.shake_mag * falloff
		shake_y = math.cos(t * 2.3) * cam.shake_mag * falloff * 0.8
	}

	cam.rl.target = raylib.Vector2{ cam.pos[0] + shake_x, cam.pos[1] + shake_y }
	cam.rl.zoom = cam.zoom
	cam.rl.offset = raylib.Vector2{ cast(f32) raylib.GetScreenWidth() * 0.5,
	                                cast(f32) raylib.GetScreenHeight() * 0.5 }
}

camera_begin :: proc(cam: ^Camera) {
	raylib.BeginMode2D(cam.rl)
}

camera_end :: proc() {
	raylib.EndMode2D()
}
