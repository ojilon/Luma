package main

import "vendor:raylib"
import "core:math"

// Game is the top-level state holder.
Game :: struct {
	mode:      GameMode,
	player:    Player,
	input:     PlayerInput,
	world:     World,
	camera:    Camera,
	particles: ParticleSystem,
	time:      f32,
}

game_init :: proc(g: ^Game) {
	g.mode = GameMode.MODE_TITLE
	player_init(&g.player)
	camera_init(&g.camera, SCREEN_WIDTH, SCREEN_HEIGHT)
	world_init(&g.world)
	particle_init(&g.particles)
	g.camera.pos = g.player.pos
	camera_update(&g.camera, g.player.pos, g.player.vel, 0)
	g.time = 0
}

game_start_play :: proc(g: ^Game) {
	player_init(&g.player)
	camera_init(&g.camera, SCREEN_WIDTH, SCREEN_HEIGHT)
	world_init(&g.world)
	particle_init(&g.particles)
	g.camera.pos = g.player.pos
	camera_update(&g.camera, g.player.pos, g.player.vel, 0)
	g.mode = GameMode.MODE_PLAYING
}

game_check_collisions :: proc(g: ^Game) {
	player_radius := g.player.radius + COLLISION_MARGIN
	for i in 0 ..< g.world.entity_count {
		if !g.world.entities[i].active {
			continue
		}
		e := &g.world.entities[i]
		#partial switch e.kind {
		case EntityKind.KIND_OBSTACLE_BRANCH, EntityKind.KIND_OBSTACLE_ROCK, EntityKind.KIND_OBSTACLE_DEBRIS:
			if collide_circle_circle(g.player.pos, e.pos,
			                         player_radius, e.radius * e.scale, COLLISION_MARGIN) {
				g.mode = GameMode.MODE_GAMEOVER
				g.player.wilt = 1.0
				camera_shake(&g.camera, SHAKE_MAGNITUDE, SHAKE_DURATION)
				particle_burst(&g.particles, g.player.pos, 10,
				               raylib.Color{ 160, 120, 60, 200 })
			}
		case EntityKind.KIND_COLLECTIBLE_SEED:
			if !world_is_collected(&g.world, e.id) &&
			   collide_circle_circle(g.player.pos, e.pos,
			                         player_radius, e.radius * e.scale, COLLISION_MARGIN) {
				world_mark_collected(&g.world, e.id)
				e.active = false
				particle_burst(&g.particles, e.pos, PARTICLE_SEED_BURST, COLOR_SEED)
			}
		case:
		}
	}
}

game_update :: proc(g: ^Game, dt: f32) {
	g.time += dt

	if g.mode == GameMode.MODE_TITLE {
		if raylib.IsKeyPressed(cast(raylib.KeyboardKey) KEY_ENTER) ||
		   raylib.IsKeyPressed(cast(raylib.KeyboardKey) KEY_SPACE) {
			game_start_play(g)
		}
		return
	}

	if raylib.IsKeyPressed(cast(raylib.KeyboardKey) KEY_P) {
		#partial switch g.mode {
		case GameMode.MODE_PLAYING: g.mode = GameMode.MODE_PAUSED
		case GameMode.MODE_PAUSED:  g.mode = GameMode.MODE_PLAYING
		case:
		}
	}
	if raylib.IsKeyPressed(cast(raylib.KeyboardKey) KEY_R) {
		game_start_play(g)
		return
	}

	if g.mode != GameMode.MODE_PLAYING {
		particle_update(&g.particles, dt)
		return
	}

	player_update(&g.player, g.input, dt, &g.particles)
	camera_update(&g.camera, g.player.pos, g.player.vel, dt)
	world_update(&g.world, g.camera.pos, dt)
	particle_update(&g.particles, dt)
	game_check_collisions(g)
}

game_render :: proc(g: ^Game) {
	raylib.BeginDrawing()
	render_sky(g.time)
	render_parallax(&g.camera, g.time)

	if g.mode != GameMode.MODE_TITLE {
		camera_begin(&g.camera)
		render_ground(&g.camera)
		render_entities(&g.world, &g.camera)
		particle_draw(&g.particles, g.camera.rl)
		player_draw(&g.player, g.camera.rl)
		camera_end()
	} else {
		// Decorative leaf on the title screen (screen-space).
		deco := Player{}
		player_init(&deco)
		deco.pos = raylib.Vector2{ cast(f32) SCREEN_WIDTH * 0.5, cast(f32) SCREEN_HEIGHT * 0.36 }
		deco.angle = math.sin(g.time * 1.2) * 0.4
		id_cam := raylib.Camera2D{}
		id_cam.zoom = 1
		player_draw(&deco, id_cam)
	}

	render_ui(g.world.seeds_collected, g.mode, g.time)
	raylib.EndDrawing()
}

main :: proc() {
	raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, GAME_TITLE)
	raylib.SetTargetFPS(TARGET_FPS)
	raylib.SetExitKey(cast(raylib.KeyboardKey) KEY_ESCAPE)

	g := Game{}
	game_init(&g)

	for !raylib.WindowShouldClose() {
		dt := raylib.GetFrameTime()
		if dt > 0.25 { dt = 0.25 }

		g.input = input_read()
		game_update(&g, dt)
		game_render(&g)
	}

	raylib.CloseWindow()
}
