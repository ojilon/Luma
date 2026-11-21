# Development Notes — Luma: The Wandering Leaf

Important Odin implementation decisions and how the main systems interact.
This reflects the code actually created, not an imagined future implementation.

## Environment

- Odin compiler: `D:\Dev\Odin\odin.exe` (dev-2026-11)
- Bindings used: `vendor:raylib` (raylib v6.2, prebuilt Windows libs in `vendor/raylib/windows`)
- Target: Windows x64, debug build

## Language specifics encountered

### 1. Distinct types require explicit casts
`raylib.Color`, `raylib.Vector2`, `raylib.KeyboardKey` and `raylib.ConfigFlags` are all
distinct types. You cannot pass an `i32`/`f64`/untyped literal where one is expected.
All key codes were defined as `cast(c.int) <value>` in `config.odin` and then cast to
`raylib.KeyboardKey` at each call site:

```odin
cast(raylib.KeyboardKey) KEY_A
```

### 2. Float literals default to `f64`
Odin untyped float literals are `f64`, but raylib uses `f32`. Any float used in a
raylib call or stored in an `f32` field must be typed explicitly:

```odin
max_speed: f32 = PLAYER_MAX_SPEED
leaf_len: f32 = 24.0
```

### 3. `switch` syntax
Odin's switch uses `case:` for the default (catch-all) branch and `#partial switch`
to opt out of exhaustiveness checking:

```odin
#partial switch e.kind {
case EntityKind.KIND_OBSTACLE_BRANCH: ...
case EntityKind.KIND_COLLECTIBLE_SEED: ...
case: // default
}
```

Enum members must be qualified with their type name: `EntityKind.KIND_OBSTACLE_BRANCH`.

### 4. `^` is dereference only (no XOR)
The `^` operator dereferences pointers; it is not bitwise XOR. Deterministic entity IDs
were built with addition instead of XOR:

```odin
eid := key + cast(u64)(i * 131 + 7)
```

### 5. `var x: T = init` vs `:=`
Use `x := value` short declarations. `var x: T = init` form is not accepted in this
Odin version for local variables in the positions used.

### 6. Ranges
Ranges use `..<` (exclusive upper bound), not `..`.

### 7. No `#partial switch` attribute
Despite appearing in an error-suggestion message, `#partial switch` is not a recognized
attribute in this compiler version. All switches handle every enum case explicitly or use
`case:` as default.

### 8. Vector2 is `[2]f32`
`raylib.Vector2` is a fixed array `[2]f32`, indexed with `[0]`/`[1]`. Component access
like `.x`/`.y` is not available.

### 9. `c.int` vs `int`
raylib procedures take `c.int` (`i32`). `SCREEN_WIDTH`/`SCREEN_HEIGHT` are untyped
integer constants and must be cast where needed:

```odin
camera_init(&g.camera, SCREEN_WIDTH, SCREEN_HEIGHT)  // both are c.int-compatible
```

The `Camera` wrapper stores its own `rl: raylib.Camera2D` fields set field-by-field
rather than via a struct literal, because the nested literal triggered parse errors in
this version.

### 10. Audio omitted
`vendor:raylib` lacks `GenWaveForm` / `LoadWaveFromMemory` helpers needed to synthesize
sounds without asset files, and building mini-audio from source was out of scope. Audio
is a documented limitation.

## How the systems interact

```
main (game.odin)
  ├─ InitWindow, SetTargetFPS
  ├─ game_init: player_init, camera_init, world_init
  ├─ per frame:
  │   ├─ input_read        -> PlayerInput (WASD/arrows + shift + normalization)
  │   ├─ game_update:
  │   │   ├─ P key  -> toggle PLAYING <-> PAUSED
  │   │   ├─ R key  -> game_init (restart)
  │   │   ├─ player_update (accel, friction, clamp, rotate toward velocity)
  │   │   ├─ camera_update (smooth follow with deadzone)
  │   │   ├─ world_update (spawn cells near camera, animate entities)
  │   │   └─ game_check_collisions (obstacle -> GAMEOVER; seed -> collect)
  │   └─ game_render:
  │       ├─ render_sky (gradient + sun)
  │       ├─ render_parallax (far clouds 0.2x, mid islands 0.5x)
  │       ├─ camera_begin / render_ground / render_entities / player_draw / camera_end
  │       └─ render_ui (score panel, hint, pause/game-over overlays, FPS)
  └─ CloseWindow
```

### World generation (deterministic / continuous)

Each grid cell is identified by integer `(cell_x, cell_y)`. A 64-bit hash of the cell
coordinate (`hash_cell`) seeds a stream of deterministic pseudo-random floats
(`hash_next`). The same cell always produces the same obstacles and seeds, so the world
feels continuous without storing every entity.

Cells are (re)generated only when they first come within `WORLD_SPAWN_PAD` pixels of the
camera. Generated cell keys are recorded so a cell is never populated twice.

### Entity pool

Entities live in a fixed-size array `[WORLD_MAX_ENTITIES]Entity` with an `active` flag.
Collected seeds are marked inactive and their IDs recorded in `collected_ids` so they
stay collected if the cell is revisited. Entities are not recycled once they leave the
view, so very long sessions will eventually fill the pool (a known limitation).

### Collision

Circle-circle with a `COLLISION_MARGIN` forgiveness radius. Obstacle collision sets
`GameMode.MODE_GAMEOVER`; collectible collision marks the seed collected and removes it.

## Build command

```
D:\Dev\Odin\odin.exe build . -debug
```

or via the convenience script:

```
build.bat
```

## Files changed / created

- `config.odin` — constants, colors, key codes, vector helpers
- `player.odin` — leaf movement, rotation, drawing
- `world.odin` — deterministic world, entity pool, seed tracking
- `camera.odin` — smooth-follow 2D camera
- `collision.odin` — circle-circle collision
- `input.odin` — keyboard polling
- `render.odin` — sky, parallax, ground, entities, HUD, overlays
- `game.odin` — entry point, game state, update/render loop
- `build.bat` — Windows build script
- `README.md` — user documentation
- `DEVELOPMENT_NOTES.md` — this file
