class_name CaveShade
extends Node2D
## The gloom of a hollow or grotto (Room.cave): stepped bands of shadow
## that deepen toward the room's edges, drawn over the scene (Wren too,
## when they walk into the dark), so the middle reads as a pool of light.

## Each band: how far in from the edge it reaches (px) and how dark it is.
const BANDS := [[56.0, 0.10], [36.0, 0.12], [20.0, 0.14], [8.0, 0.16]]
const SHADOW := Color(0.02, 0.03, 0.06)


func _ready() -> void:
	z_index = 25
	queue_redraw()


func _draw() -> void:
	var size := Room.SIZE
	for band: Array in BANDS:
		var d: float = band[0]
		var c := Color(SHADOW, band[1])
		# Four strips that don't overlap at the corners: top and bottom run
		# the full width, the sides fill in between.
		draw_rect(Rect2(0, 0, size.x, d), c)
		draw_rect(Rect2(0, size.y - d, size.x, d), c)
		draw_rect(Rect2(0, d, d, size.y - d * 2), c)
		draw_rect(Rect2(size.x - d, d, d, size.y - d * 2), c)
