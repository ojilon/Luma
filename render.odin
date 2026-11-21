package main

import "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:c"

// render_sky draws the gradient sky background (screen space, no camera).
render_sky :: proc() {
	raylib.DrawRectangleGradientV(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT,
	                              COLOR_SKY_TOP, COLOR_SKY_BOTTOM)

	// Sun / golden light in the upper right.
	raylib.DrawCircleGradient(raylib.Vector2{ cast(f32) SCREEN_WIDTH - 160, 120 }, 140,
	                          raylib.Color{ 255, 220, 140, 60 },
	                          raylib.Color{ 255, 200, 100, 0 })
}

// render_parallax draws distant background layers that move slower than the
// camera, creating the 2.5D depth illusion.
render_parallax :: proc(cam: ^Camera) {
	// Far layer: soft atmospheric clouds/haze (parallax 0.2).
	far_x := -cam.pos[0] * 0.2
	for i in 0 ..< 6 {
		x := cast(f32) i * 420.0 + far_x
		for x < -200 { x += 2520.0 }
		for x > cast(f32) SCREEN_WIDTH + 200 { x -= 2520.0 }
		y := 100.0 + cast(f32) (i % 3) * 90.0
		raylib.DrawCircleGradient(raylib.Vector2{ x, y }, 90.0,
		                          raylib.Color{ 255, 255, 255, 28 },
		                          raylib.Color{ 255, 255, 255, 0 })
	}

	// Mid layer: distant floating islands (parallax 0.5).
	mid_x := -cam.pos[0] * 0.5
	for i in 0 ..< 8 {
		x := cast(f32) i * 300.0 + mid_x
		for x < -150 { x += 2400.0 }
		for x > cast(f32) SCREEN_WIDTH + 150 { x -= 2400.0 }
		y := 300.0 + cast(f32) (i % 4) * 110.0
		size := 40.0 + cast(f32)(i % 3) * 20.0
		raylib.DrawCircleV(raylib.Vector2{ x, y }, size, COLOR_GRASS_DARK)
		raylib.DrawCircleV(raylib.Vector2{ x, y - size * 0.4 }, size * 0.6, COLOR_GRASS)
	}
}

// render_ground draws the organic terrain layer inside the 2D camera.
render_ground :: proc(cam: ^Camera) {
	sw := cast(f32) raylib.GetScreenWidth()
	sh := cast(f32) raylib.GetScreenHeight()
	left := cam.pos[0] - sw * 0.5 - 100
	right := cam.pos[0] + sw * 0.5 + 100
	bottom := cam.pos[1] + sh * 0.5 + 100

	// Cyan stream snaking through the world (deterministic sine).
	raylib.DrawLineBezier(raylib.Vector2{ left, 420 + math.sin(left * 0.003) * 60 },
	                      raylib.Vector2{ right, 420 + math.sin(right * 0.003) * 60 },
	                      26.0, COLOR_STREAM)
	raylib.DrawLineBezier(raylib.Vector2{ left, 420 + math.sin(left * 0.003) * 60 + 8 },
	                      raylib.Vector2{ right, 420 + math.sin(right * 0.003) * 60 + 8 },
	                      14.0, raylib.Color{ 120, 220, 245, 200 })

	// Emerald grass patches along the bottom.
	patch_w: f32 = 140.0
	// Align the first patch to a grid so the grass doesn't shimmer as the
	// camera moves. Integer division truncates toward zero, so adjust for
	// negative coordinates.
	start_i := cast(int) left / cast(int) patch_w
	if left < 0 && cast(f32)(start_i * cast(int) patch_w) != left {
		start_i -= 1
	}
	start_x := cast(f32) start_i * patch_w
	patch_count := cast(int) ((right - start_x) / patch_w) + 2
	for i in 0 ..< patch_count {
		x := start_x + cast(f32) i * patch_w
		if x > right { break }
		h := 60.0 + math.sin(x * 0.01) * 20.0
		raylib.DrawRectangleGradientV(cast(c.int) x, cast(c.int)(bottom - h),
		                              cast(c.int) patch_w, cast(c.int) h,
		                              COLOR_GRASS, COLOR_GRASS_DARK)
		// Flowers on grass.
		if i % 3 == 0 {
			raylib.DrawCircleV(raylib.Vector2{ x + 40, bottom - h - 10 }, 7, COLOR_FLOWER)
			raylib.DrawCircleV(raylib.Vector2{ x + 90, bottom - h - 14 }, 6, COLOR_FLOWER2)
		}
	}
}

// render_entity draws a single world entity.
render_entity :: proc(e: ^Entity, screen: raylib.Vector2) {
	#partial switch e.kind {
	case EntityKind.KIND_OBSTACLE_BRANCH:
		// Branch: angled brown bar with a smaller twig.
		raylib.DrawLineEx(raylib.Vector2{ screen[0] - e.radius, screen[1] - e.radius * 0.4 },
		                  raylib.Vector2{ screen[0] + e.radius, screen[1] + e.radius * 0.4 },
		                  7.0, COLOR_BRANCH)
		raylib.DrawLineEx(raylib.Vector2{ screen[0], screen[1] },
		                  raylib.Vector2{ screen[0] + e.radius * 0.6, screen[1] - e.radius * 0.8 },
		                  4.0, COLOR_BRANCH)
	case EntityKind.KIND_OBSTACLE_ROCK:
		raylib.DrawCircleV(screen, e.radius, COLOR_ROCK)
		raylib.DrawCircleLinesV(screen, e.radius, raylib.Color{ 100, 100, 110, 255 })
		raylib.DrawCircleV(raylib.Vector2{ screen[0] - e.radius*0.35, screen[1] - e.radius*0.35 },
		                  e.radius * 0.3, raylib.Color{ 220, 220, 230, 120 })
	case EntityKind.KIND_OBSTACLE_DEBRIS:
		raylib.DrawRectangleRec(raylib.Rectangle{ screen[0] - e.radius, screen[1] - e.radius*0.5,
		                                       e.radius * 2, e.radius },
		                     COLOR_DEBRIS)
	case EntityKind.KIND_COLLECTIBLE_SEED:
		raylib.DrawCircleGradient(screen, e.radius * SEED_GLOW / SEED_RADIUS,
		                          raylib.Color{ 255, 240, 120, 90 },
		                          raylib.Color{ 255, 220, 80, 0 })
		raylib.DrawCircleV(screen, e.radius, COLOR_SEED)
		raylib.DrawCircleLinesV(screen, e.radius, COLOR_GOLD)
	case: // default: unknown kind, draw nothing
	}
}

// render_entities draws all active entities inside the camera.
render_entities :: proc(w: ^World, cam: ^Camera) {
	sw := cast(f32) raylib.GetScreenWidth()
	sh := cast(f32) raylib.GetScreenHeight()
	for i in 0 ..< w.entity_count {
		if !w.entities[i].active {
			continue
		}
		screen := raylib.GetWorldToScreen2D(w.entities[i].pos, cam.rl)
		// Cheap culling: skip entities far outside the screen.
		if screen[0] < -100 || screen[0] > sw + 100 ||
		   screen[1] < -100 || screen[1] > sh + 100 {
			continue
		}
		render_entity(&w.entities[i], screen)
	}
}

// render_ui draws the HUD, pause screen and game-over overlay (screen space).
render_ui :: proc(seeds: int, mode: GameMode) {
	// Score panel.
	panel_w: f32 = 240.0
	panel_h: f32 = 54.0
	raylib.DrawRectangleRounded(raylib.Rectangle{ 16, 16, panel_w, panel_h },
	                            0.25, 8, COLOR_UI_PANEL)
	raylib.DrawRectangleRoundedLinesEx(raylib.Rectangle{ 16, 16, panel_w, panel_h },
	                                   0.25, 8, 2.0, raylib.Color{ 120, 160, 140, 200 })

	score_text := fmt.ctprintf("Seeds: %d", seeds)
	raylib.DrawText(score_text, 34, 30, 24, COLOR_UI_TEXT)

	hint := fmt.ctprintf("WASD/Arrows: fly   Shift: boost   P: pause   R: restart")
	raylib.DrawText(hint, 34, SCREEN_HEIGHT - 30, 18, raylib.Color{ 80, 100, 110, 220 })

	if mode == GameMode.MODE_PAUSED {
		render_overlay("PAUSED", "Press P to resume   |   R to restart")
	}
	if mode == GameMode.MODE_GAMEOVER {
		render_overlay("LEAF WILTED", fmt.ctprintf("Seeds collected: %d   |   R to restart", seeds))
	}

	dbg := fmt.ctprintf("FPS: %d   Seeds: %d", raylib.GetFPS(), seeds)
	raylib.DrawText(dbg, SCREEN_WIDTH - 170, 10, 16, COLOR_DEBUG)
}

// render_overlay draws a centered fullscreen message.
render_overlay :: proc(title: cstring, subtitle: cstring) {
	raylib.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, raylib.Color{ 0, 0, 0, 140 })
	tw := raylib.MeasureText(title, 40)
	raylib.DrawText(title, (SCREEN_WIDTH - tw) / 2, SCREEN_HEIGHT / 2 - 60, 40,
	                 raylib.Color{ 255, 255, 255, 255 })
	sw := raylib.MeasureText(subtitle, 22)
	raylib.DrawText(subtitle, (SCREEN_WIDTH - sw) / 2, SCREEN_HEIGHT / 2 + 10, 22,
	                 raylib.Color{ 220, 220, 220, 255 })
}
