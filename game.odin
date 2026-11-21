package main

import "vendor:raylib"

// Game is the top-level state holder. It keeps the small foundation's
// responsibilities separated: player, world, camera, input and mode.
Game :: struct {
	mode:     GameMode,
	player:   Player,
	input:    PlayerInput,
	world:    World,
	camera:   Camera,
}

game_init :: proc(g: ^Game) {
	g.mode = GameMode.MODE_PLAYING
	player_init(&g.player)
	camera_init(&g.camera, SCREEN_WIDTH, SCREEN_HEIGHT)
	world_init(&g.world)
	// Start the camera right on the player.
	g.camera.pos = g.player.pos
	camera_update(&g.camera, g.player.pos, 0)
}

// game_check_collisions tests the player against every active entity.
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
			                         player_radius, e.radius, COLLISION_MARGIN) {
				g.mode = GameMode.MODE_GAMEOVER
			}
		case EntityKind.KIND_COLLECTIBLE_SEED:
			if !world_is_collected(&g.world, e.id) &&
			   collide_circle_circle(g.player.pos, e.pos,
			                         player_radius, e.radius, COLLISION_MARGIN) {
				world_mark_collected(&g.world, e.id)
				e.active = false
			}
		case: // default: unknown kind, ignore
		}
	}
}

game_update :: proc(g: ^Game, dt: f32) {
	// Input actions.
	if raylib.IsKeyPressed(cast(raylib.KeyboardKey) KEY_P) {
		#partial switch g.mode {
		case GameMode.MODE_PLAYING: g.mode = GameMode.MODE_PAUSED
		case GameMode.MODE_PAUSED:  g.mode = GameMode.MODE_PLAYING
		case: // MODE_GAMEOVER: ignore pause key
		}
	}
	if raylib.IsKeyPressed(cast(raylib.KeyboardKey) KEY_R) {
		game_init(g)
		g.mode = GameMode.MODE_PLAYING
	}

	if g.mode != GameMode.MODE_PLAYING {
		return
	}

	player_update(&g.player, g.input, dt)
	camera_update(&g.camera, g.player.pos, dt)
	world_update(&g.world, g.camera.pos, dt)
	game_check_collisions(g)
}

game_render :: proc(g: ^Game) {
	raylib.BeginDrawing()
	render_sky()
	render_parallax(&g.camera)

	camera_begin(&g.camera)
	render_ground(&g.camera)
	render_entities(&g.world, &g.camera)
	player_draw(&g.player, g.camera.rl)
	camera_end()

	render_ui(g.world.seeds_collected, g.mode)
	raylib.EndDrawing()
}

main :: proc() {
	raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, GAME_TITLE)
	raylib.SetTargetFPS(TARGET_FPS)

	g := Game{}
	game_init(&g)

	for !raylib.WindowShouldClose() {
		dt := raylib.GetFrameTime()
		// Guard against a "spiral of death" if the window is dragged/resized.
		if dt > 0.25 { dt = 0.25 }

		g.input = input_read()
		game_update(&g, dt)
		game_render(&g)
	}

	raylib.CloseWindow()
}
