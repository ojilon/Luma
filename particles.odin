package main

import "vendor:raylib"
import "core:math"

ParticleSystem :: struct {
	particles: [PARTICLE_MAX]Particle,
	count:     int, // high-water for iteration; slots reuse via active flag
}

particle_init :: proc(ps: ^ParticleSystem) {
	ps.count = 0
	for i in 0 ..< PARTICLE_MAX {
		ps.particles[i].active = false
	}
}

particle_spawn :: proc(ps: ^ParticleSystem, pos, vel: raylib.Vector2, life, size: f32, color: raylib.Color) {
	// Reuse inactive slot.
	for i in 0 ..< PARTICLE_MAX {
		if !ps.particles[i].active {
			ps.particles[i] = Particle{
				pos = pos,
				vel = vel,
				life = life,
				max_life = life,
				size = size,
				color = color,
				active = true,
			}
			if i >= ps.count {
				ps.count = i + 1
			}
			return
		}
	}
}

particle_burst :: proc(ps: ^ParticleSystem, origin: raylib.Vector2, n: int, base_color: raylib.Color) {
	for i in 0 ..< n {
		ang := cast(f32) i / cast(f32) n * math.PI * 2.0 + cast(f32)(i % 3) * 0.3
		spd: f32 = 60.0 + cast(f32)(i % 5) * 25.0
		vx := math.cos(ang) * spd
		vy := math.sin(ang) * spd - 40.0
		sz: f32 = 2.5 + cast(f32)(i % 4)
		particle_spawn(ps, origin, raylib.Vector2{ vx, vy }, 0.5 + cast(f32)(i % 4) * 0.08, sz, base_color)
	}
}

particle_update :: proc(ps: ^ParticleSystem, dt: f32) {
	for i in 0 ..< ps.count {
		p := &ps.particles[i]
		if !p.active {
			continue
		}
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		p.pos[0] += p.vel[0] * dt
		p.pos[1] += p.vel[1] * dt
		// Slight drag.
		p.vel[0] *= 0.96
		p.vel[1] *= 0.96
		p.vel[1] += 25.0 * dt // gentle settle
	}
}

particle_draw :: proc(ps: ^ParticleSystem, cam: raylib.Camera2D) {
	sw := cast(f32) raylib.GetScreenWidth()
	sh := cast(f32) raylib.GetScreenHeight()
	for i in 0 ..< ps.count {
		p := &ps.particles[i]
		if !p.active {
			continue
		}
		screen := raylib.GetWorldToScreen2D(p.pos, cam)
		if screen[0] < -20 || screen[0] > sw + 20 || screen[1] < -20 || screen[1] > sh + 20 {
			continue
		}
		t := p.life / p.max_life
		a := cast(u8)(cast(f32) p.color.a * t)
		col := raylib.Color{ p.color.r, p.color.g, p.color.b, a }
		raylib.DrawCircleV(screen, p.size * (0.5 + t * 0.5), col)
	}
}
