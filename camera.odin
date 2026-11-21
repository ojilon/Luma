package main

import "vendor:raylib"
import "core:math"

// Camera wraps raylib's Camera2D and adds smooth following.
Camera :: struct {
	pos:    raylib.Vector2,
	target: raylib.Vector2,
	zoom:   f32,
	rl:     raylib.Camera2D,
}

camera_init :: proc(cam: ^Camera, w, h: int) {
	cam.pos = raylib.Vector2{ cast(f32) w * 0.5, cast(f32) h * 0.5 }
	cam.target = cam.pos
	cam.zoom = CAMERA_ZOOM
	cam.rl.offset = raylib.Vector2{ cast(f32) w * 0.5, cast(f32) h * 0.5 }
	cam.rl.target = cam.pos
	cam.rl.rotation = 0
	cam.rl.zoom = cam.zoom
}

camera_update :: proc(cam: ^Camera, target: raylib.Vector2, dt: f32) {
	cam.target = target

	// Smooth follow with optional deadzone so small movements don't nudge the cam.
	dx := cam.target[0] - cam.pos[0]
	dy := cam.target[1] - cam.pos[1]
	if math.abs(dx) > CAMERA_DEADZONE {
		cam.pos[0] += dx * CAMERA_SMOOTH
	}
	if math.abs(dy) > CAMERA_DEADZONE {
		cam.pos[1] += dy * CAMERA_SMOOTH
	}

	cam.rl.target = cam.pos
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
