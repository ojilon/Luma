package main

import "vendor:raylib"
import "core:math"
import "core:c"

// Luma: The Wandering Leaf — configuration and shared constants.
// All magic numbers live here so the game can be tuned in one place.

SCREEN_WIDTH  :: 1280
SCREEN_HEIGHT :: 720
GAME_TITLE    :: "Luma: The Wandering Leaf"

TARGET_FPS    :: 60

// --- Player / leaf ---
PLAYER_RADIUS      :: 12.0
PLAYER_ACCEL       :: 600.0      // pixels / sec^2
PLAYER_MAX_SPEED   :: 360.0      // pixels / sec
PLAYER_FRICTION    :: 0.88       // per-frame velocity multiplier (damping)
PLAYER_ROT_SPEED   :: 6.0        // rotation smoothing factor
PLAYER_BOOST_SPEED :: 560.0      // speed when shift held

// --- Camera ---
CAMERA_SMOOTH    :: 0.15         // follow smoothing (0..1)
CAMERA_ZOOM      :: 1.0
CAMERA_DEADZONE  :: 60.0

// --- World ---
WORLD_CELL_SIZE   :: 240.0       // grid cell size in world units
WORLD_SPAWN_PAD   :: 500.0       // spawn cells this far beyond camera view
WORLD_MAX_ENTITIES :: 4000       // entity pool size

// --- Obstacle radii ---
OBSTACLE_RADIUS_BRANCH :: 26.0
OBSTACLE_RADIUS_ROCK   :: 20.0
OBSTACLE_RADIUS_DEBRIS :: 14.0

// --- Collectible ---
SEED_RADIUS :: 10.0
SEED_GLOW   :: 18.0

// --- Collision ---
COLLISION_MARGIN :: 4.0          // extra forgiveness radius

// --- Colors (vibrant, whimsical palette) ---
COLOR_SKY_TOP     :: raylib.Color{ 60, 90, 160, 255 }   // deep sky blue
COLOR_SKY_BOTTOM  :: raylib.Color{ 140, 210, 255, 255 } // light cyan sky
COLOR_GRASS       :: raylib.Color{ 76, 175, 80, 255 }   // emerald green
COLOR_GRASS_DARK  :: raylib.Color{ 56, 130, 60, 255 }
COLOR_STREAM      :: raylib.Color{ 80, 200, 230, 255 }  // cyan stream
COLOR_GOLD        :: raylib.Color{ 255, 215, 90, 255 }  // golden light
COLOR_FLOWER      :: raylib.Color{ 220, 120, 230, 255 } // purple-pink flower
COLOR_FLOWER2     :: raylib.Color{ 255, 110, 180, 255 }
COLOR_LEAF        :: raylib.Color{ 120, 200, 90, 255 }  // leaf green
COLOR_LEAF_STEM   :: raylib.Color{ 140, 180, 110, 255 }
COLOR_BRANCH      :: raylib.Color{ 110, 70, 40, 255 }   // brown branch
COLOR_ROCK        :: raylib.Color{ 150, 150, 160, 255 } // grey rock
COLOR_DEBRIS      :: raylib.Color{ 190, 160, 100, 255 } // floating debris
COLOR_SEED        :: raylib.Color{ 255, 240, 120, 255 } // glowing seed
COLOR_UI_TEXT     :: raylib.Color{ 30, 40, 50, 255 }
COLOR_UI_PANEL    :: raylib.Color{ 255, 255, 255, 230 }
COLOR_DEBUG       :: raylib.Color{ 255, 80, 80, 255 }

// --- Keyboard key codes (raylib KeyboardKey enum values) ---
KEY_A             :: cast(c.int) 65
KEY_D             :: cast(c.int) 68
KEY_W             :: cast(c.int) 87
KEY_S             :: cast(c.int) 83
KEY_LEFT          :: cast(c.int) 263
KEY_RIGHT         :: cast(c.int) 262
KEY_UP            :: cast(c.int) 265
KEY_DOWN          :: cast(c.int) 264
KEY_LEFT_SHIFT    :: cast(c.int) 340
KEY_RIGHT_SHIFT   :: cast(c.int) 344
KEY_P             :: cast(c.int) 80
KEY_R             :: cast(c.int) 82
KEY_ESCAPE        :: cast(c.int) 256

// --- Entity kinds ---
EntityKind :: enum {
	KIND_NONE,
	KIND_OBSTACLE_BRANCH,
	KIND_OBSTACLE_ROCK,
	KIND_OBSTACLE_DEBRIS,
	KIND_COLLECTIBLE_SEED,
}

// An entity placed in the world (obstacle or collectible).
Entity :: struct {
	kind:    EntityKind,
	pos:     raylib.Vector2,
	active:  bool,
	radius:  f32,
	angle:   f32,       // visual rotation / bob phase
	scale:   f32,       // depth illusion scale (1.0 = normal)
	color:   raylib.Color,
	id:      u64,       // deterministic id so collected collectibles stay collected
}

// --- Game state ---
GameMode :: enum {
	MODE_PLAYING,
	MODE_PAUSED,
	MODE_GAMEOVER,
}

// --- Vector helpers ---
vec2 :: proc(x, y: f32) -> raylib.Vector2 { return raylib.Vector2{ x, y } }

vec2_add :: proc(a, b: raylib.Vector2) -> raylib.Vector2 {
	return raylib.Vector2{ a[0] + b[0], a[1] + b[1] }
}

vec2_sub :: proc(a, b: raylib.Vector2) -> raylib.Vector2 {
	return raylib.Vector2{ a[0] - b[0], a[1] - b[1] }
}

vec2_mul :: proc(v: raylib.Vector2, s: f32) -> raylib.Vector2 {
	return raylib.Vector2{ v[0] * s, v[1] * s }
}

vec2_len :: proc(v: raylib.Vector2) -> f32 {
	return math.sqrt(v[0]*v[0] + v[1]*v[1])
}

vec2_dist_sq :: proc(a, b: raylib.Vector2) -> f32 {
	dx := a[0] - b[0]
	dy := a[1] - b[1]
	return dx*dx + dy*dy
}

vec2_clamp_len :: proc(v: raylib.Vector2, max_len: f32) -> raylib.Vector2 {
	l := vec2_len(v)
	if l > max_len && l > 0 {
		s := max_len / l
		return raylib.Vector2{ v[0] * s, v[1] * s }
	}
	return v
}
