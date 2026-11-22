package main

import "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:c"

// Ambient pollen / dust positions (screen-relative, rebuilt each frame cheaply).
render_sky :: proc(time: f32) {
	// Three-band sky gradient approximation.
	raylib.DrawRectangleGradientV(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT / 2,
	                              COLOR_SKY_TOP, COLOR_SKY_MID)
	raylib.DrawRectangleGradientV(0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, SCREEN_HEIGHT / 2,
	                              COLOR_SKY_MID, COLOR_SKY_BOTTOM)

	// Sun / golden light upper-right with soft corona.
	sx: f32 = cast(f32) SCREEN_WIDTH - 150
	sy: f32 = 110
	raylib.DrawCircleGradient(raylib.Vector2{ sx, sy }, 160,
	                          raylib.Color{ 255, 230, 150, 55 },
	                          raylib.Color{ 255, 200, 100, 0 })
	raylib.DrawCircleV(raylib.Vector2{ sx, sy }, 36, raylib.Color{ 255, 240, 180, 220 })
	raylib.DrawCircleV(raylib.Vector2{ sx, sy }, 22, raylib.Color{ 255, 250, 220, 255 })

	// Floating pollen motes (screen space, slow drift).
	for i in 0 ..< 18 {
		px := math.mod(cast(f32)(i * 97) * 13.0 + time * (8.0 + cast(f32)(i % 5)), cast(f32) SCREEN_WIDTH + 40) - 20
		py := math.mod(cast(f32)(i * 53) * 11.0 + time * (4.0 + cast(f32)(i % 3)), cast(f32) SCREEN_HEIGHT + 40) - 20
		a: u8 = cast(u8)(40 + (i % 5) * 18)
		raylib.DrawCircleV(raylib.Vector2{ px, py }, 1.5 + cast(f32)(i % 3), raylib.Color{ 255, 250, 200, a })
	}
}

render_parallax :: proc(cam: ^Camera, time: f32) {
	// Far haze clouds (parallax 0.15).
	far_x := -cam.pos[0] * 0.15
	for i in 0 ..< 7 {
		x := cast(f32) i * 400.0 + far_x + math.sin(time * 0.15 + cast(f32) i) * 20
		for x < -220 { x += 2800.0 }
		for x > cast(f32) SCREEN_WIDTH + 220 { x -= 2800.0 }
		y := 80.0 + cast(f32) (i % 3) * 85.0
		raylib.DrawCircleGradient(raylib.Vector2{ x, y }, 100.0,
		                          raylib.Color{ 255, 255, 255, 32 },
		                          raylib.Color{ 255, 255, 255, 0 })
	}

	// Distant mountain silhouettes (parallax 0.28).
	mt_x := -cam.pos[0] * 0.28
	for i in 0 ..< 10 {
		x := cast(f32) i * 260.0 + mt_x
		for x < -200 { x += 2600.0 }
		for x > cast(f32) SCREEN_WIDTH + 200 { x -= 2600.0 }
		base_y: f32 = 380 + cast(f32)(i % 3) * 20
		h: f32 = 70 + cast(f32)(i % 4) * 25
		raylib.DrawTriangle(
			raylib.Vector2{ x, base_y - h },
			raylib.Vector2{ x - 80, base_y },
			raylib.Vector2{ x + 90, base_y },
			raylib.Color{ 90, 130, 110, 90 })
	}

	// Mid floating islands (parallax 0.5).
	mid_x := -cam.pos[0] * 0.5
	for i in 0 ..< 9 {
		x := cast(f32) i * 290.0 + mid_x
		for x < -160 { x += 2610.0 }
		for x > cast(f32) SCREEN_WIDTH + 160 { x -= 2610.0 }
		y := 280.0 + cast(f32) (i % 4) * 100.0 + math.sin(time * 0.4 + cast(f32) i) * 6
		size := 36.0 + cast(f32)(i % 3) * 18.0
		// Soft shadow under island.
		raylib.DrawEllipse(cast(i32) x, cast(i32)(y + size * 0.55), size * 0.9, size * 0.25, COLOR_SHADOW)
		raylib.DrawCircleV(raylib.Vector2{ x, y }, size, COLOR_GRASS_DARK)
		raylib.DrawCircleV(raylib.Vector2{ x, y - size * 0.35 }, size * 0.55, COLOR_GRASS)
		// Tiny flower on some islands.
		if i % 2 == 0 {
			raylib.DrawCircleV(raylib.Vector2{ x + size * 0.2, y - size * 0.55 }, 4, COLOR_FLOWER)
		}
	}
}

render_ground :: proc(cam: ^Camera) {
	sw := cast(f32) raylib.GetScreenWidth()
	sh := cast(f32) raylib.GetScreenHeight()
	left := cam.pos[0] - sw * 0.5 - 120
	right := cam.pos[0] + sw * 0.5 + 120
	bottom := cam.pos[1] + sh * 0.5 + 120

	// Cyan stream (world-space wavy ribbon).
	stream_y: f32 = 430
	steps := 24
	prev := raylib.Vector2{ left, stream_y + math.sin(left * 0.003) * 55 }
	for s in 1 ..= steps {
		t := cast(f32) s / cast(f32) steps
		x := left + (right - left) * t
		y := stream_y + math.sin(x * 0.003) * 55
		cur := raylib.Vector2{ x, y }
		raylib.DrawLineEx(prev, cur, 28.0, COLOR_STREAM)
		raylib.DrawLineEx(raylib.Vector2{ prev[0], prev[1] + 6 }, raylib.Vector2{ cur[0], cur[1] + 6 }, 12.0, COLOR_STREAM_HI)
		prev = cur
	}

	// Emerald grass patches.
	patch_w: f32 = 130.0
	start_i := cast(int) left / cast(int) patch_w
	if left < 0 && cast(f32)(start_i * cast(int) patch_w) != left {
		start_i -= 1
	}
	start_x := cast(f32) start_i * patch_w
	patch_count := cast(int) ((right - start_x) / patch_w) + 2
	for i in 0 ..< patch_count {
		x := start_x + cast(f32) i * patch_w
		if x > right { break }
		h := 55.0 + math.sin(x * 0.01) * 22.0
		raylib.DrawRectangleGradientV(cast(c.int) x, cast(c.int)(bottom - h),
		                              cast(c.int) patch_w, cast(c.int) h,
		                              COLOR_GRASS, COLOR_GRASS_DARK)
		if i % 3 == 0 {
			raylib.DrawCircleV(raylib.Vector2{ x + 35, bottom - h - 8 }, 6.5, COLOR_FLOWER)
			raylib.DrawCircleV(raylib.Vector2{ x + 35, bottom - h - 8 }, 2.5, COLOR_GOLD)
		}
		if i % 4 == 1 {
			raylib.DrawCircleV(raylib.Vector2{ x + 85, bottom - h - 12 }, 5.5, COLOR_FLOWER2)
		}
	}
}

render_entity :: proc(e: ^Entity, screen: raylib.Vector2) {
	r := e.radius * e.scale
	// Soft contact shadow.
	raylib.DrawEllipse(cast(i32)(screen[0] + 2), cast(i32)(screen[1] + r * 0.85),
	                   r * 0.85, r * 0.28, COLOR_SHADOW)

	#partial switch e.kind {
	case EntityKind.KIND_OBSTACLE_BRANCH:
		raylib.DrawLineEx(raylib.Vector2{ screen[0] - r, screen[1] - r * 0.35 },
		                  raylib.Vector2{ screen[0] + r, screen[1] + r * 0.35 },
		                  8.0, COLOR_BRANCH)
		raylib.DrawLineEx(raylib.Vector2{ screen[0], screen[1] },
		                  raylib.Vector2{ screen[0] + r * 0.55, screen[1] - r * 0.75 },
		                  4.5, COLOR_BRANCH)
		// Leaf tuft at tip.
		raylib.DrawCircleV(raylib.Vector2{ screen[0] + r * 0.55, screen[1] - r * 0.75 }, 5, COLOR_GRASS)
	case EntityKind.KIND_OBSTACLE_ROCK:
		raylib.DrawCircleV(screen, r, COLOR_ROCK)
		raylib.DrawCircleLinesV(screen, r, raylib.Color{ 100, 100, 110, 255 })
		raylib.DrawCircleV(raylib.Vector2{ screen[0] - r * 0.3, screen[1] - r * 0.3 },
		                  r * 0.28, raylib.Color{ 220, 220, 230, 130 })
	case EntityKind.KIND_OBSTACLE_DEBRIS:
		// Rotated diamond-ish debris via two triangles.
		ang := e.angle
		c := math.cos(ang)
		s := math.sin(ang)
		p0 := raylib.Vector2{ screen[0] + c * r, screen[1] + s * r }
		p1 := raylib.Vector2{ screen[0] - s * r * 0.6, screen[1] + c * r * 0.6 }
		p2 := raylib.Vector2{ screen[0] - c * r, screen[1] - s * r }
		p3 := raylib.Vector2{ screen[0] + s * r * 0.6, screen[1] - c * r * 0.6 }
		raylib.DrawTriangle(p0, p1, p2, COLOR_DEBRIS)
		raylib.DrawTriangle(p0, p2, p3, raylib.Color{ 200, 170, 110, 255 })
	case EntityKind.KIND_COLLECTIBLE_SEED:
		glow_r := r * (SEED_GLOW / SEED_RADIUS)
		raylib.DrawCircleGradient(screen, glow_r,
		                          raylib.Color{ 255, 240, 120, 100 },
		                          raylib.Color{ 255, 220, 80, 0 })
		raylib.DrawCircleV(screen, r, COLOR_SEED)
		raylib.DrawCircleLinesV(screen, r, COLOR_GOLD)
		raylib.DrawCircleV(raylib.Vector2{ screen[0] - r * 0.25, screen[1] - r * 0.25 },
		                  r * 0.25, raylib.Color{ 255, 255, 230, 200 })
	case:
	}
}

render_entities :: proc(w: ^World, cam: ^Camera) {
	sw := cast(f32) raylib.GetScreenWidth()
	sh := cast(f32) raylib.GetScreenHeight()
	for i in 0 ..< w.entity_count {
		if !w.entities[i].active {
			continue
		}
		screen := raylib.GetWorldToScreen2D(w.entities[i].pos, cam.rl)
		if screen[0] < -120 || screen[0] > sw + 120 ||
		   screen[1] < -120 || screen[1] > sh + 120 {
			continue
		}
		render_entity(&w.entities[i], screen)
	}
}

render_title :: proc(time: f32) {
	raylib.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, raylib.Color{ 20, 40, 55, 120 })

	title := "Luma"
	subtitle := "The Wandering Leaf"
	tw := raylib.MeasureText(title, 64)
	raylib.DrawText(title, (SCREEN_WIDTH - tw) / 2 + 2, SCREEN_HEIGHT / 2 - 100 + 2, 64,
	                 raylib.Color{ 40, 80, 50, 180 })
	raylib.DrawText(title, (SCREEN_WIDTH - tw) / 2, SCREEN_HEIGHT / 2 - 100, 64, COLOR_TITLE_GLOW)

	sw := raylib.MeasureText(subtitle, 28)
	raylib.DrawText(subtitle, (SCREEN_WIDTH - sw) / 2, SCREEN_HEIGHT / 2 - 28, 28,
	                 raylib.Color{ 230, 245, 255, 230 })

	pulse := 0.6 + 0.4 * math.sin(time * 3.0)
	hint_a: u8 = cast(u8)(180.0 * pulse + 40)
	prompt := "Press ENTER or SPACE to begin"
	pw := raylib.MeasureText(prompt, 22)
	raylib.DrawText(prompt, (SCREEN_WIDTH - pw) / 2, SCREEN_HEIGHT / 2 + 50, 22,
	                 raylib.Color{ 255, 255, 255, hint_a })

	ctrl := "WASD / Arrows  |  Shift boost  |  P pause  |  R restart"
	cw := raylib.MeasureText(ctrl, 16)
	raylib.DrawText(ctrl, (SCREEN_WIDTH - cw) / 2, SCREEN_HEIGHT - 48, 16,
	                 raylib.Color{ 200, 220, 230, 180 })
}

render_ui :: proc(seeds: int, mode: GameMode, time: f32) {
	if mode == GameMode.MODE_TITLE {
		render_title(time)
		return
	}

	panel_w: f32 = 250.0
	panel_h: f32 = 56.0
	raylib.DrawRectangleRounded(raylib.Rectangle{ 16, 16, panel_w, panel_h },
	                            0.25, 8, COLOR_UI_PANEL)
	raylib.DrawRectangleRoundedLinesEx(raylib.Rectangle{ 16, 16, panel_w, panel_h },
	                                   0.25, 8, 2.0, raylib.Color{ 120, 160, 140, 200 })

	score_text := fmt.ctprintf("Seeds: %d", seeds)
	raylib.DrawText(score_text, 34, 32, 24, COLOR_UI_TEXT)

	hint := fmt.ctprintf("WASD/Arrows fly  |  Shift boost  |  P pause  |  R restart")
	raylib.DrawText(hint, 34, SCREEN_HEIGHT - 28, 16, raylib.Color{ 70, 95, 105, 210 })

	if mode == GameMode.MODE_PAUSED {
		render_overlay("PAUSED", "Press P to resume  |  R to restart")
	}
	if mode == GameMode.MODE_GAMEOVER {
		render_overlay("LEAF WILTED", fmt.ctprintf("Seeds collected: %d  |  R to restart", seeds))
	}

	dbg := fmt.ctprintf("FPS: %d", raylib.GetFPS())
	raylib.DrawText(dbg, SCREEN_WIDTH - 100, 12, 16, COLOR_DEBUG)
}

render_overlay :: proc(title: cstring, subtitle: cstring) {
	raylib.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, raylib.Color{ 0, 0, 0, 150 })
	tw := raylib.MeasureText(title, 42)
	raylib.DrawText(title, (SCREEN_WIDTH - tw) / 2, SCREEN_HEIGHT / 2 - 58, 42,
	                 raylib.Color{ 255, 255, 255, 255 })
	sw := raylib.MeasureText(subtitle, 22)
	raylib.DrawText(subtitle, (SCREEN_WIDTH - sw) / 2, SCREEN_HEIGHT / 2 + 12, 22,
	                 raylib.Color{ 220, 220, 220, 255 })
}
