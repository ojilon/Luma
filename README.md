# Luma: The Wandering Leaf

A small, playable 2D/2.5D-feeling exploration game prototype written in **Odin** using **raylib**.

You control a small flying leaf gliding through a colorful, continuous world. Collect glowing seeds, avoid tree branches and rocks, and drift through emerald forests, cyan streams, golden light and floating islands.

## Project structure

```
D:\projects\Luma\
├── build.bat              # Windows build script (build / run / clean)
├── game.odin              # Application entry point and top-level Game state
├── config.odin            # Constants, colors, key codes, vector helpers
├── player.odin            # Player / leaf logic (movement, rotation, drawing)
├── world.odin             # Deterministic procedural world & entity generation
├── camera.odin            # Smooth-following 2D camera
├── collision.odin         # Circle-circle collision detection
├── input.odin             # Keyboard input polling
├── render.odin            # Sky, parallax, ground, entities and HUD drawing
├── Luma.exe               # Built executable (debug)
├── README.md              # This file
└── DEVELOPMENT_NOTES.md   # Odin implementation decisions
```

## Libraries used

- **Odin** (dev-2026-11) — primary language
- **vendor:raylib** (raylib v6.2 bindings + raygui available) — windowing, input, rendering, audio device
- No external assets downloaded; all graphics are generated with raylib primitives

## Build & run

Requires the Odin compiler. Set `ODIN` in `build.bat` if it's not on your PATH.

From the project directory:

```
build.bat           # Build debug executable (build\Luma.exe)
build.bat run       # Build and run the game
build.bat clean     # Remove build output
```

Raw compiler command:

```
odin build . -debug
```

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow keys | Fly the leaf |
| Hold Shift | Boost speed |
| P | Pause / resume |
| R | Restart |
| Esc / Close window | Exit |

## Current features

- Controllable flying leaf with smooth acceleration, deceleration and drifting
- WASD + arrow keys; diagonal movement normalized
- Boost (hold Shift) increases acceleration and top speed
- Leaf rotates toward direction of travel with smooth interpolation
- Smooth-following 2D camera with deadzone
- Continuous, deterministic, procedural world (no level files)
- Obstacles: tree branches, rocks, floating debris
- Collectible glowing seeds with bobbing animation
- Circle-circle collision with forgiveness margin
- Score counter (seeds collected)
- Pause system and restart mechanism
- Gradient sky, cyan stream, emerald grass, flowers, floating islands, golden sun
- Movement wind-trail and leaf glow effects
- HUD with seed count, FPS and controls hint
- Pause and game-over overlays

## Known limitations

- No audio: raylib's `mini-audio`-style sound generation (`GenWaveForm`) is not present in the bundled bindings, so audio was omitted to avoid building native libraries from source
- The world is deterministic but infinite only in the positive/negative directions as far as the 64-bit cell hash allows; entities are pooled (max 4000) and not recycled once off-screen
- No persistent high score or saved state
- Fixed 1280x720 window (not resizable)
- Collision is circle-based only
- Debug drawing is minimal (FPS counter only)

## Tiny game foundation organization

Responsibilities are separated across single-purpose modules:

- **Application / game loop** — `game.odin` (`main`, `game_update`, `game_render`)
- **Game state** — `Game` struct holding `mode`, `player`, `input`, `world`, `camera`
- **Player / leaf** — `player.odin` (movement physics, rotation, drawing)
- **World** — `world.odin` (deterministic cell-hash generation, entity pool, collected-seed tracking)
- **Obstacles / entities** — `Entity` struct + `EntityKind` enum in `config.odin`
- **Collision** — `collision.odin` (circle-circle, point-in-circle)
- **Camera** — `camera.odin` (smooth-follow `Camera2D` wrapper)
- **Rendering** — `render.odin` (sky, parallax layers, ground, entities, HUD, overlays)
- **Input** — `input.odin` (keyboard polling into `PlayerInput`)
- **UI** — `render.odin` (`render_ui`, `render_overlay`)
- **Configuration / constants** — `config.odin` (tunable magic numbers, colors, key codes)
- **Debugging** — FPS counter in HUD; no separate debug UI yet

## Next development steps

1. Add audio using `vendor:miniaudio` or simple procedural beeps via raylib
2. Add particle effects (dust, sparkles when collecting seeds)
3. Add a start/menu screen and game-over restart prompt via raygui
4. Add screen shake on collision and a "leaf wilted" visual state
5. Add parallax layer variety (more distant islands, fog)
6. Add a high-score / session summary
7. Allow window resizing and camera zoom
8. Recycle off-screen entities to remove the entity pool cap
