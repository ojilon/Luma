package main

import "vendor:raylib"

// input_read polls the keyboard and fills the PlayerInput struct.
input_read :: proc() -> PlayerInput {
	inp := PlayerInput{}
	inp.dx = 0
	inp.dy = 0
	inp.boost = false

	if raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_A) || raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_LEFT) {
		inp.dx -= 1
	}
	if raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_D) || raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_RIGHT) {
		inp.dx += 1
	}
	if raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_W) || raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_UP) {
		inp.dy -= 1
	}
	if raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_S) || raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_DOWN) {
		inp.dy += 1
	}
	if raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_LEFT_SHIFT) || raylib.IsKeyDown(cast(raylib.KeyboardKey) KEY_RIGHT_SHIFT) {
		inp.boost = true
	}

	// Normalize diagonal input so moving diagonally isn't faster.
	if inp.dx != 0 && inp.dy != 0 {
		inp.dx *= 0.7071
		inp.dy *= 0.7071
	}

	return inp
}
