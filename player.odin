package main

import "vendor:raylib"
import "core:math"

// The flying leaf the player controls.
Player :: struct {
	pos:          raylib.Vector2,
	vel:          raylib.Vector2,
	angle:        f32,          // leaf visual rotation (radians)
	target_angle: f32,
	radius:       f32,
	color:        raylib.Color,
	boost:        bool,
}

// Input state shared between input and player systems.
PlayerInput :: struct {
	dx:    f32,
	dy:    f32,
	boost: bool,
}

player_init :: proc(p: ^Player) {
	p.pos = raylib.Vector2{ 100, cast(f32) SCREEN_HEIGHT * 0.5 }
	p.vel = raylib.Vector2{ 0, 0 }
	p.angle = 0
	p.target_angle = 0
	p.radius = PLAYER_RADIUS
	p.color = COLOR_LEAF
	p.boost = false
}

player_update :: proc(p: ^Player, input: PlayerInput, dt: f32) {
	// Desired acceleration direction from input.
	accel: f32 = PLAYER_ACCEL
	if input.boost {
		accel *= 1.5
	}

	ax := input.dx * accel
	ay := input.dy * accel

	p.vel[0] += ax * dt
	p.vel[1] += ay * dt

	// Friction / air resistance (drifting feel).
	p.vel[0] *= PLAYER_FRICTION
	p.vel[1] *= PLAYER_FRICTION

	// Clamp speed.
	max_speed: f32 = PLAYER_MAX_SPEED
	if input.boost {
		max_speed = PLAYER_BOOST_SPEED
	}
	p.vel = vec2_clamp_len(p.vel, max_speed)

	p.pos = vec2_add(p.pos, vec2_mul(p.vel, dt))

	// Leaf rotates toward direction of travel.
	if vec2_len(p.vel) > 10.0 {
		p.target_angle = math.atan2(p.vel[1], p.vel[0])
	}
	// Smoothly rotate the leaf sprite toward the movement direction.
	diff := p.target_angle - p.angle
	// Normalize to [-pi, pi].
	for diff > math.PI { diff -= 2 * math.PI }
	for diff < -math.PI { diff += 2 * math.PI }
	p.angle += diff * PLAYER_ROT_SPEED * dt

	p.boost = input.boost
}

// player_draw renders the leaf with rotation and a little stem/trail.
player_draw :: proc(p: ^Player, cam: raylib.Camera2D) {
	screen_pos := raylib.GetWorldToScreen2D(p.pos, cam)

	// Leaf body: a rotated leaf shape drawn as two triangles.
	leaf_len: f32 = 24.0
	leaf_wid: f32 = 14.0
	if p.boost {
		leaf_len = 30.0
		leaf_wid = 10.0
	}

	// Direction of travel.
	dir_x := math.cos(p.angle)
	dir_y := math.sin(p.angle)
	perp_x := -dir_y
	perp_y := dir_x

	tip_x := screen_pos[0] + dir_x * leaf_len * 0.5
	tip_y := screen_pos[1] + dir_y * leaf_len * 0.5
	base_x := screen_pos[0] - dir_x * leaf_len * 0.4
	base_y := screen_pos[1] - dir_y * leaf_len * 0.4
	l_wing_x := screen_pos[0] + perp_x * leaf_wid * 0.5
	l_wing_y := screen_pos[1] + perp_y * leaf_wid * 0.5
	r_wing_x := screen_pos[0] - perp_x * leaf_wid * 0.5
	r_wing_y := screen_pos[1] - perp_y * leaf_wid * 0.5

	raylib.DrawTriangle(raylib.Vector2{ tip_x, tip_y },
	                    raylib.Vector2{ l_wing_x, l_wing_y },
	                    raylib.Vector2{ r_wing_x, r_wing_y }, p.color)
	raylib.DrawTriangle(raylib.Vector2{ base_x, base_y },
	                    raylib.Vector2{ l_wing_x, l_wing_y },
	                    raylib.Vector2{ r_wing_x, r_wing_y }, COLOR_LEAF_STEM)

	// Small glow at the tip.
	raylib.DrawCircleV(raylib.Vector2{ tip_x, tip_y }, 4.0, raylib.Color{ 255, 255, 220, 200 })

	// Movement "wind trail" behind the leaf.
	trail_len := vec2_len(p.vel) * 0.15
	if trail_len > 6.0 {
		tx := screen_pos[0] - dir_x * trail_len
		ty := screen_pos[1] - dir_y * trail_len
		raylib.DrawLineV(screen_pos, raylib.Vector2{ tx, ty },
		                 raylib.Color{ 200, 240, 255, 160 })
	}
}
