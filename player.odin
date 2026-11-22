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
	bob_phase:    f32,          // idle float phase
	wilt:         f32,          // 0..1 wilt amount after collision
	trail_accum:  f32,          // particle spawn accumulator
}

// Input state shared between input and player systems.
PlayerInput :: struct {
	dx:    f32,
	dy:    f32,
	boost: bool,
}

player_init :: proc(p: ^Player) {
	p.pos = raylib.Vector2{ 120, cast(f32) SCREEN_HEIGHT * 0.48 }
	p.vel = raylib.Vector2{ 0, 0 }
	p.angle = 0
	p.target_angle = 0
	p.radius = PLAYER_RADIUS
	p.color = COLOR_LEAF
	p.boost = false
	p.bob_phase = 0
	p.wilt = 0
	p.trail_accum = 0
}

player_update :: proc(p: ^Player, input: PlayerInput, dt: f32, particles: ^ParticleSystem) {
	// Desired acceleration direction from input.
	accel: f32 = PLAYER_ACCEL
	if input.boost {
		accel *= PLAYER_BOOST_ACCEL
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

	// Idle bob when nearly still.
	speed := vec2_len(p.vel)
	p.bob_phase += dt * 2.8
	if speed < 40.0 {
		p.pos[1] += math.sin(p.bob_phase) * PLAYER_IDLE_BOB * dt
	}

	// Leaf rotates toward direction of travel.
	if speed > 12.0 {
		p.target_angle = math.atan2(p.vel[1], p.vel[0])
	}
	diff := p.target_angle - p.angle
	for diff > math.PI { diff -= 2 * math.PI }
	for diff < -math.PI { diff += 2 * math.PI }
	p.angle += diff * PLAYER_ROT_SPEED * dt

	p.boost = input.boost

	// Wilt recovery when alive (game over sets wilt high).
	if p.wilt > 0 && p.wilt < 0.99 {
		p.wilt = math.max(0.0, p.wilt - dt * 0.35)
	}

	// Wind-trail particles while moving.
	if speed > 30.0 {
		p.trail_accum += PARTICLE_TRAIL_RATE * dt * (speed / PLAYER_MAX_SPEED)
		for p.trail_accum >= 1.0 {
			p.trail_accum -= 1.0
			dir_x := math.cos(p.angle)
			dir_y := math.sin(p.angle)
			px := p.pos[0] - dir_x * 18.0
			py := p.pos[1] - dir_y * 18.0
			particle_spawn(particles,
				raylib.Vector2{ px, py },
				raylib.Vector2{ -dir_x * 20.0 + (speed * 0.02), -dir_y * 20.0 },
				0.45 + speed * 0.0004,
				3.0 + speed * 0.008,
				raylib.Color{ 190, 235, 255, 160 })
		}
	}
}

// player_draw renders the leaf with rotation, soft shadow, vein and glow.
player_draw :: proc(p: ^Player, cam: raylib.Camera2D) {
	screen_pos := raylib.GetWorldToScreen2D(p.pos, cam)
	dscale := depth_scale_from_y(p.pos[1])

	leaf_len: f32 = 28.0 * dscale
	leaf_wid: f32 = 16.0 * dscale
	if p.boost {
		leaf_len = 34.0 * dscale
		leaf_wid = 12.0 * dscale
	}
	// Wilt shrinks and browns the leaf.
	if p.wilt > 0 {
		leaf_len *= 1.0 - p.wilt * 0.35
		leaf_wid *= 1.0 - p.wilt * 0.25
	}

	dir_x := math.cos(p.angle)
	dir_y := math.sin(p.angle)
	perp_x := -dir_y
	perp_y := dir_x

	// Soft shadow slightly below/behind the leaf.
	shadow_off: f32 = 10.0 * dscale
	raylib.DrawEllipse(cast(i32)(screen_pos[0] + 4), cast(i32)(screen_pos[1] + shadow_off),
	                   leaf_len * 0.45, leaf_wid * 0.28, COLOR_SHADOW)

	tip_x := screen_pos[0] + dir_x * leaf_len * 0.55
	tip_y := screen_pos[1] + dir_y * leaf_len * 0.55
	base_x := screen_pos[0] - dir_x * leaf_len * 0.42
	base_y := screen_pos[1] - dir_y * leaf_len * 0.42
	l_wing_x := screen_pos[0] + perp_x * leaf_wid * 0.55
	l_wing_y := screen_pos[1] + perp_y * leaf_wid * 0.55
	r_wing_x := screen_pos[0] - perp_x * leaf_wid * 0.55
	r_wing_y := screen_pos[1] - perp_y * leaf_wid * 0.55

	body := p.color
	stem := COLOR_LEAF_STEM
	if p.wilt > 0.2 {
		// Blend toward brown when wilted.
		t := p.wilt
		body = raylib.Color{
			cast(u8)(cast(f32) body.r * (1 - t) + 120 * t),
			cast(u8)(cast(f32) body.g * (1 - t) + 90 * t),
			cast(u8)(cast(f32) body.b * (1 - t) + 50 * t),
			255,
		}
		stem = body
	}

	// Outer leaf (darker edge).
	raylib.DrawTriangle(raylib.Vector2{ tip_x, tip_y },
	                    raylib.Vector2{ l_wing_x, l_wing_y },
	                    raylib.Vector2{ r_wing_x, r_wing_y }, COLOR_LEAF_DARK)
	// Inner leaf body.
	ix := screen_pos[0] + dir_x * leaf_len * 0.08
	iy := screen_pos[1] + dir_y * leaf_len * 0.08
	raylib.DrawTriangle(raylib.Vector2{ tip_x * 0.92 + ix * 0.08, tip_y * 0.92 + iy * 0.08 },
	                    raylib.Vector2{ l_wing_x * 0.85 + ix * 0.15, l_wing_y * 0.85 + iy * 0.15 },
	                    raylib.Vector2{ r_wing_x * 0.85 + ix * 0.15, r_wing_y * 0.85 + iy * 0.15 }, body)
	// Stem triangle at base.
	raylib.DrawTriangle(raylib.Vector2{ base_x, base_y },
	                    raylib.Vector2{ l_wing_x * 0.5 + base_x * 0.5, l_wing_y * 0.5 + base_y * 0.5 },
	                    raylib.Vector2{ r_wing_x * 0.5 + base_x * 0.5, r_wing_y * 0.5 + base_y * 0.5 }, stem)

	// Central vein.
	raylib.DrawLineEx(raylib.Vector2{ base_x, base_y }, raylib.Vector2{ tip_x, tip_y }, 1.6, COLOR_LEAF_VEIN)

	// Tip glow (dimmer when wilted).
	glow_a: u8 = cast(u8)(200.0 * (1.0 - p.wilt * 0.8))
	raylib.DrawCircleV(raylib.Vector2{ tip_x, tip_y }, 4.5 * dscale, raylib.Color{ 255, 255, 210, glow_a })

	// Boost aura.
	if p.boost && p.wilt < 0.1 {
		raylib.DrawCircleLinesV(screen_pos, leaf_len * 0.7, raylib.Color{ 180, 255, 200, 90 })
	}
}
