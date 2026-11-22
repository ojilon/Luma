# Development Notes — Luma: The Wandering Leaf (redesign)

Reflects the code on branch `redesign/wandering-leaf-v2` and `main`.

## Redesign goals vs original prototype

The first pass delivered a compiling foundation (movement, camera, deterministic world, collectibles, pause). This redesign tightens alignment with the original brief:

- Stronger 2.5D: depth scale from Y, soft shadows, multi-layer parallax (haze, mountains, islands)
- More organic leaf: dual-tone body, vein, idle bob, wilt state, boost silhouette
- Particles: wind trail, seed burst, hit dust
- Title screen and clearer game-over feedback (shake + wilt)
- Entity recycle so the pool is less likely to fill during exploration
- Camera look-ahead along velocity

## Environment note

This redesign was authored without a local Odin compiler in the agent sandbox. Compile on Windows with your existing Odin + `vendor:raylib` setup:

```
odin build . -debug -out:build/Luma.exe
```

or `build.bat`.

## Language patterns carried over

- Distinct raylib types need explicit casts (`KeyboardKey`, `Color`, `c.int`)
- Prefer typed `f32` locals for raylib calls (untyped floats are `f64`)
- `#partial switch` for non-exhaustive entity/mode switches
- `Vector2` is `[2]f32` — use `[0]` / `[1]`
- `^` is pointer dereference only

## System flow

```
main
  game_init → MODE_TITLE
  loop:
    input_read
    game_update
      TITLE: Enter/Space → game_start_play
      PLAYING: player → camera → world → particles → collisions
      PAUSED / GAMEOVER: R restarts; P toggles pause
    game_render
      sky + parallax (always)
      world entities + particles + player (not on title)
      HUD / title / overlays
```

### World

Cell hash → deterministic obstacle/seed placement. Far entities deactivate so slots can be reused. Collected seed IDs stay recorded so revisiting a cell does not respawn taken seeds.

### Particles

Fixed pool (`PARTICLE_MAX`). Spawn finds the first inactive slot. Trails emit from the leaf while speed is high; bursts fire on collect and on fatal collision.

### Camera

Smooth follow with deadzone, plus a fraction of velocity as look-ahead. Shake uses decaying sine/cosine offsets applied to `Camera2D.target`.

## Files

| File | Role |
|------|------|
| `config.odin` | Constants, colors, entity types, vector helpers |
| `game.odin` | Loop, modes, collision orchestration |
| `player.odin` | Physics, trail emission, leaf draw |
| `world.odin` | Hash world, spawn, recycle |
| `particles.odin` | Particle pool |
| `camera.odin` | Follow, look-ahead, shake |
| `render.odin` | Sky, parallax, ground, entities, UI |
| `collision.odin` / `input.odin` | Small focused modules |
| `build.bat` | Windows build helper |
