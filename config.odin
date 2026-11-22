package main

import "vendor:raylib"
import "core:math"
import "core:c"

// Luma: The Wandering Leaf - configuration and shared constants.
// All magic numbers live here so the game can be tuned in one place.

SCREEN_WIDTH  :: 1280
SCREEN_HEIGHT :: 720
GAME_TITLE    :: "Luma: The Wandering Leaf"

TARGET_FPS    :: 60

// --- Player / leaf ---
PLAYER_RADIUS      :: 14.0
PLAYER_ACCEL       :: 520.0      // pixels / sec^2
PLAYER_MAX_SPEED   :: 340.0      // pixels / sec
PLAYER_FRICTION    :: 0.90       // per-frame velocity multiplier (drifting feel)
PLAYER_ROT_SPEED   :: 5.5        // rotation smoothing factor
PLAYER_BOOST_SPEED :: 540.0      // speed when shift held
PLAYER_BOOST_ACCEL :: 1.65       // accel multiplier while boosting
PLAYER_IDLE_BOB    :: 6.0        // gentle float when nearly still

// --- Camera ---
CAMERA_SMOOTH    :: 0.12         // follow smoothing (0..1)
CAMERA_ZOOM      :: 1.0
CAMERA_DEADZONE  :: 40.0
CAMERA_LOOKAHEAD :: 0.18         // fraction of velocity added as look-ahead

// --- World ---
WORLD_CELL_SIZE    :: 280.0      // grid cell size in world units
WORLD_SPAWN_PAD    :: 560.0      // spawn cells this far beyond camera view
WORLD_MAX_ENTITIES :: 4000       // entity pool size
WORLD_RECYCLE_DIST :: 1400.0     // recycle entities this far from camera

// --- Obstacle radii ---
OBSTACLE_RADIUS_BRANCH :: 28.0
OBSTACLE_RADIUS_ROCK   :: 22.0
OBSTACLE_RADIUS_DEBRIS :: 15.0

// --- Collectible ---
SEED_RADIUS :: 11.0
SEED_GLOW   :: 22.0

// --- Particles ---
PARTICLE_MAX       :: 256
PARTICLE_TRAIL_RATE :: 28.0      // particles per second while moving
PARTICLE_SEED_BURST :: 12        // sparkles on collect

// --- Collision ---
COLLISION_MARGIN :: 3.0          // extra forgiveness radius

// --- Screen shake ---
SHAKE_DURATION :: 0.45
SHAKE_MAGNITUDE :: 10.0

// --- Colors (vibrant, whimsical palette) ---
COLOR_SKY_TOP     :: raylib.Color{ 55, 85, 155, 255 }   // deep sky blue
COLOR_SKY_MID     :: raylib.Color{ 100, 160, 220, 255 }
COLOR_SKY_BOTTOM  :: raylib.Color{ 165, 225, 255, 255 } // light cyan sky
COLOR_GRASS       :: raylib.Color{ 70, 175, 85, 255 }   // emerald green
COLOR_GRASS_DARK  :: raylib.Color{ 48, 125, 58, 255 }
COLOR_STREAM      :: raylib.Color{ 70, 195, 225, 255 }  // cyan stream
COLOR_STREAM_HI   :: raylib.Color{ 150, 235, 250, 180 }
COLOR_GOLD        :: raylib.Color{ 255, 215, 90, 255 }  // golden light
COLOR_FLOWER      :: raylib.Color{ 220, 120, 230, 255 } // purple-pink flower
COLOR_FLOWER2     :: raylib.Color{ 255, 110, 180, 255 }
COLOR_LEAF        :: raylib.Color{ 110, 195, 85, 255 }  // leaf green
COLOR_LEAF_DARK   :: raylib.Color{ 75, 145, 55, 255 }
COLOR_LEAF_STEM   :: raylib.Color{ 130, 165, 95, 255 }
COLOR_LEAF_VEIN   :: raylib.Color{ 90, 150, 60, 220 }
COLOR_BRANCH      :: raylib.Color{ 105, 65, 38, 255 }   // brown branch
COLOR_ROCK        :: raylib.Color{ 145, 148, 158, 255 } // grey rock
COLOR_DEBRIS      :: raylib.Color{ 185, 155, 95, 255 }  // floating debris
COLOR_SEED        :: raylib.Color{ 255, 235, 110, 255 } // glowing seed
COLOR_SHADOW      :: raylib.Color{ 30, 50, 40, 55 }
COLOR_UI_TEXT     :: raylib.Color{ 28, 38, 48, 255 }
COLOR_UI_PANEL    :: raylib.Color{ 255, 255, 255, 235 }
COLOR_DEBUG       :: raylib.Color{ 255, 90, 90, 200 }
COLOR_TITLE_GLOW  :: raylib.Color{ 255, 240, 160, 255 }

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
KEY_ENTER         :: cast(c.int) 257
KEY_SPACE         :: cast(c.int) 32
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

// Lightweight particle for trails and collect bursts.
Particle :: struct {
	pos:      raylib.Vector2,
	vel:      raylib.Vector2,
	life:     f32,
	max_life: f32,
	size:     f32,
	color:    raylib.Color,
	active:   bool,
}

// --- Game state ---
GameMode :: enum {
	MODE_TITLE,
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

// Soft depth scale from vertical world position (slight 2.5D illusion).
depth_scale_from_y :: proc(y: f32) -> f32 {
	// Higher on screen (smaller y) appears slightly smaller / farther.
	t := math.clamp((y - 100.0) / 600.0, 0.0, 1.0)
	return 0.82 + t * 0.28
}
