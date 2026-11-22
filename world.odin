package main

import "vendor:raylib"
import "core:math"

// Deterministic 64-bit hash of a grid cell coordinate.
hash_cell :: proc(cell_x, cell_y: int) -> u64 {
	x := cast(u64) cell_x
	y := cast(u64) cell_y
	h := x * 0x9E3779B97F4A7C15 + y * 0xBF58476D1CE4E5B9
	h = h * 0xBF58476D1CE4E5B9 + (h >> 30)
	h = h * 0x94D049BB133111EB + (h >> 27)
	h = h + (h >> 31)
	return h
}

hash_next :: proc(h: ^u64) -> f32 {
	h^ = h^ * 0x9E3779B97F4A7C15 + 0xBF58476D1CE4E5B9
	v := h^
	v = v * 0xBF58476D1CE4E5B9 + (v >> 30)
	v = v * 0x94D049BB133111EB + (v >> 27)
	v = v + (v >> 31)
	return cast(f32)(cast(u32) v % 10000) / 10000.0
}

hash_range :: proc(h: ^u64, min_v, max_v: f32) -> f32 {
	return min_v + hash_next(h) * (max_v - min_v)
}

hash_range_int :: proc(h: ^u64, min_v, max_v: int) -> int {
	return min_v + cast(int) (hash_next(h) * cast(f32)(max_v - min_v + 1))
}

World :: struct {
	entities:        [WORLD_MAX_ENTITIES]Entity,
	entity_count:    int,
	collected_ids:   [2048]u64,
	collected_count: int,
	seeds_collected: int,
	generated_keys:  [4096]u64,
	generated_count: int,
}

world_init :: proc(w: ^World) {
	w.entity_count = 0
	w.collected_count = 0
	w.seeds_collected = 0
	w.generated_count = 0
}

world_mark_generated :: proc(w: ^World, key: u64) {
	if w.generated_count < len(w.generated_keys) {
		w.generated_keys[w.generated_count] = key
		w.generated_count += 1
	}
}

world_is_generated :: proc(w: ^World, key: u64) -> bool {
	for i in 0 ..< w.generated_count {
		if w.generated_keys[i] == key {
			return true
		}
	}
	return false
}

world_is_collected :: proc(w: ^World, id: u64) -> bool {
	for i in 0 ..< w.collected_count {
		if w.collected_ids[i] == id {
			return true
		}
	}
	return false
}

world_mark_collected :: proc(w: ^World, id: u64) {
	if world_is_collected(w, id) {
		return
	}
	if w.collected_count < len(w.collected_ids) {
		w.collected_ids[w.collected_count] = id
		w.collected_count += 1
	}
	w.seeds_collected += 1
}

world_cell_origin :: proc(cell_x, cell_y: int) -> raylib.Vector2 {
	return raylib.Vector2{
		cast(f32) cell_x * WORLD_CELL_SIZE,
		cast(f32) cell_y * WORLD_CELL_SIZE,
	}
}

world_to_cell :: proc(pos: raylib.Vector2) -> (int, int) {
	return cast(int) pos[0] / cast(int) WORLD_CELL_SIZE,
	       cast(int) pos[1] / cast(int) WORLD_CELL_SIZE
}

// Find a free entity slot (inactive or past end), enabling recycle.
world_find_slot :: proc(w: ^World) -> int {
	for i in 0 ..< w.entity_count {
		if !w.entities[i].active {
			return i
		}
	}
	if w.entity_count < WORLD_MAX_ENTITIES {
		slot := w.entity_count
		w.entity_count += 1
		return slot
	}
	return -1
}

world_spawn_entity :: proc(w: ^World, kind: EntityKind, pos: raylib.Vector2,
	                       radius: f32, color: raylib.Color, id: u64) -> bool {
	slot := world_find_slot(w)
	if slot < 0 {
		return false
	}
	e := Entity{}
	e.kind = kind
	e.pos = pos
	e.active = true
	e.radius = radius
	e.angle = 0
	e.scale = depth_scale_from_y(pos[1])
	e.color = color
	e.id = id
	w.entities[slot] = e
	return true
}

world_generate_cell :: proc(w: ^World, cell_x, cell_y: int) {
	key := hash_cell(cell_x, cell_y)
	if world_is_generated(w, key) {
		return
	}
	world_mark_generated(w, key)

	origin := world_cell_origin(cell_x, cell_y)
	h := key

	// Varied density: some cells sparse, some denser clusters.
	obstacle_count := hash_range_int(&h, 0, 3)
	seed_count := hash_range_int(&h, 1, 4)

	for i in 0 ..< obstacle_count {
		ox := origin[0] + hash_range(&h, 24.0, WORLD_CELL_SIZE - 24.0)
		oy := origin[1] + hash_range(&h, 24.0, WORLD_CELL_SIZE - 24.0)
		kind := cast(EntityKind) hash_range_int(&h, int(EntityKind.KIND_OBSTACLE_BRANCH), int(EntityKind.KIND_OBSTACLE_DEBRIS))
		radius: f32 = OBSTACLE_RADIUS_DEBRIS
		color := COLOR_DEBRIS
		#partial switch kind {
		case EntityKind.KIND_OBSTACLE_BRANCH:
			radius = OBSTACLE_RADIUS_BRANCH
			color = COLOR_BRANCH
		case EntityKind.KIND_OBSTACLE_ROCK:
			radius = OBSTACLE_RADIUS_ROCK
			color = COLOR_ROCK
		case EntityKind.KIND_OBSTACLE_DEBRIS:
			radius = OBSTACLE_RADIUS_DEBRIS
			color = COLOR_DEBRIS
		case:
			radius = OBSTACLE_RADIUS_DEBRIS
			color = COLOR_DEBRIS
		}
		eid := key + cast(u64)(i * 131 + 7)
		world_spawn_entity(w, kind, raylib.Vector2{ ox, oy }, radius, color, eid)
	}

	for i in 0 ..< seed_count {
		sx := origin[0] + hash_range(&h, 30.0, WORLD_CELL_SIZE - 30.0)
		sy := origin[1] + hash_range(&h, 30.0, WORLD_CELL_SIZE - 30.0)
		eid := key + cast(u64)(i * 131 + 1000)
		if world_is_collected(w, eid) {
			continue
		}
		world_spawn_entity(w, EntityKind.KIND_COLLECTIBLE_SEED, raylib.Vector2{ sx, sy }, SEED_RADIUS, COLOR_SEED, eid)
	}
}

// Recycle entities that drifted far from the camera to free pool slots.
world_recycle_distant :: proc(w: ^World, cam_pos: raylib.Vector2) {
	limit_sq := WORLD_RECYCLE_DIST * WORLD_RECYCLE_DIST
	for i in 0 ..< w.entity_count {
		if !w.entities[i].active {
			continue
		}
		// Keep collected tracking; only deactivate far obstacles/seeds for reuse.
		if vec2_dist_sq(w.entities[i].pos, cam_pos) > limit_sq {
			w.entities[i].active = false
		}
	}
}

world_update :: proc(w: ^World, cam_pos: raylib.Vector2, dt: f32) {
	left   := cast(int) ((cam_pos[0] - cast(f32) SCREEN_WIDTH * 0.5 - WORLD_SPAWN_PAD) / WORLD_CELL_SIZE)
	right  := cast(int) ((cam_pos[0] + cast(f32) SCREEN_WIDTH * 0.5 + WORLD_SPAWN_PAD) / WORLD_CELL_SIZE)
	top    := cast(int) ((cam_pos[1] - cast(f32) SCREEN_HEIGHT * 0.5 - WORLD_SPAWN_PAD) / WORLD_CELL_SIZE)
	bottom := cast(int) ((cam_pos[1] + cast(f32) SCREEN_HEIGHT * 0.5 + WORLD_SPAWN_PAD) / WORLD_CELL_SIZE)

	for cx in left ..< right + 1 {
		for cy in top ..< bottom + 1 {
			world_generate_cell(w, cx, cy)
		}
	}

	world_recycle_distant(w, cam_pos)

	for i in 0 ..< w.entity_count {
		if !w.entities[i].active {
			continue
		}
		w.entities[i].angle += dt * 2.2
		w.entities[i].scale = depth_scale_from_y(w.entities[i].pos[1])
		if w.entities[i].kind == EntityKind.KIND_COLLECTIBLE_SEED {
			// Bob + pulse.
			w.entities[i].scale *= 1.0 + 0.12 * math.sin(w.entities[i].angle * 2.0)
		} else if w.entities[i].kind == EntityKind.KIND_OBSTACLE_DEBRIS {
			// Slow spin drift.
			w.entities[i].pos[0] += math.sin(w.entities[i].angle) * 8.0 * dt
			w.entities[i].pos[1] += math.cos(w.entities[i].angle * 0.7) * 5.0 * dt
		}
	}
}
