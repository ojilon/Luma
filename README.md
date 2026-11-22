# Luma: The Wandering Leaf

A small, playable 2D/2.5D-feeling exploration game prototype written in **Odin** using **raylib**.

You control a small flying leaf gliding through a colorful, continuous world. Collect glowing seeds, avoid tree branches and rocks, and drift through emerald forests, cyan streams, golden light and floating islands.

## Project structure

```
Luma/
├── build.bat              # Windows build script (build / run / clean)
├── game.odin              # Application entry point and top-level Game state
├── config.odin            # Constants, colors, key codes, vector helpers
├── player.odin            # Player / leaf logic (movement, rotation, drawing)
├── world.odin             # Deterministic procedural world & entity generation
├── camera.odin            # Smooth-following 2D camera with look-ahead & shake
├── collision.odin         # Circle-circle collision detection
├── input.odin             # Keyboard input polling
├── particles.odin         # Wind trails and collect / hit particle bursts
├── render.odin            # Sky, parallax, ground, entities and HUD drawing
├── README.md              # This file
└── DEVELOPMENT_NOTES.md   # Odin implementation decisions
```

## Libraries used

- **Odin** — primary language
- **vendor:raylib** — windowing, input, rendering
- No external art assets; all graphics are raylib primitives and procedural shapes

## Build & run

Requires the Odin compiler. Set `ODIN` in `build.bat` if it is not on your PATH.

```
build.bat           # Build debug executable (build\Luma.exe)
build.bat run       # Build and run the game
build.bat clean     # Remove build output
```

Raw compiler command:

```
odin build . -debug -out:build/Luma.exe
```

## Controls

| Key | Action |
|-----|--------|
| Enter / Space | Start from title screen |
| WASD / Arrow keys | Fly the leaf |
| Hold Shift | Boost speed |
| P | Pause / resume |
| R | Restart |
| Esc / Close window | Exit |

## Current features

- Title screen with decorative leaf and prompt
- Controllable flying leaf with smooth acceleration, deceleration and drifting
- Idle float bob when nearly still; boost stretches the leaf
- Leaf rotates toward travel direction with vein, dual-tone body and tip glow
- Soft contact shadows under the leaf and world entities
- Wind-trail particles while moving; sparkle burst on seed collect; dust on hit
- Camera with deadzone, velocity look-ahead and screen shake on collision
- Continuous deterministic procedural world (no level files)
- Obstacles: tree branches, rocks, drifting debris
- Collectible glowing seeds with bobbing / pulse
- Depth scale from vertical position (subtle 2.5D)
- Entity pool with recycle of far-off entities
- Score counter, pause, restart, wilted leaf on game over
- Layered sky, sun, pollen motes, parallax clouds / mountains / floating islands
- Cyan stream, emerald grass, flowers

## Known limitations

- No audio (kept out of scope to avoid native library work)
- Generated-cell key list is fixed size; very long sessions may stop generating new cells
- Fixed 1280x720 window
- Collision is circle-based only
- Not compiled in this redesign environment (no Odin toolchain here) — build on a machine with Odin + raylib vendor

## Tiny game foundation

| Responsibility | Module |
|----------------|--------|
| Application / loop | `game.odin` |
| Config / types | `config.odin` |
| Player | `player.odin` |
| World / entities | `world.odin` |
| Particles | `particles.odin` |
| Camera | `camera.odin` |
| Collision | `collision.odin` |
| Input | `input.odin` |
| Rendering / UI | `render.odin` |

## Next steps

1. Procedural audio via `vendor:miniaudio` or raylib sound helpers
2. More particle variety (pollen that reacts to leaf motion)
3. raygui menu and high-score panel
4. Window resize + optional camera zoom
5. Biome tint shifts as the player travels farther
