package main

import "vendor:raylib"

// circle_circle returns true if two circles overlap (with an optional margin).
collide_circle_circle :: proc(a_pos, b_pos: raylib.Vector2, a_radius, b_radius: f32,
	                            margin: f32) -> bool {
	dx := a_pos[0] - b_pos[0]
	dy := a_pos[1] - b_pos[1]
	dist_sq := dx*dx + dy*dy
	combined := a_radius + b_radius + margin
	return dist_sq < combined * combined
}

// point_in_circle returns true if a point is inside a circle.
point_in_circle :: proc(point, center: raylib.Vector2, radius: f32) -> bool {
	dx := point[0] - center[0]
	dy := point[1] - center[1]
	return dx*dx + dy*dy < radius * radius
}
