class_name KitePost
extends StaticBody2D
## The far post of Gullwatch's old kite-post, where Captain Sorrel's races
## finish (StoryDirector). Flies Sorrel's red pennant, or, once Wren has
## beaten her kite to it, a pennant striped like Wren's jumper.

const WOOD := Color("#6b4a32")
const WOOD_LIGHT := Color("#8d6644")
const SORREL_RED := Color("#e2574c")
const NAVY := Color("#3a4e8e")
const STRIPE := Color("#fff4d6")

var won := false
var _time := 0.0


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(4, 4), Vector2(0, -2)))
	add_child(Art.shadow())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-2, -28, 4, 28), Palette.OUTLINE)
	draw_rect(Rect2(-1, -27, 2, 27), WOOD)
	draw_rect(Rect2(-1, -27, 1, 27), WOOD_LIGHT)
	draw_rect(Rect2(-2, -30, 4, 3), Palette.OUTLINE)
	# The pennant, snapping in the wind.
	var flap := PackedVector2Array()
	var ripple := PackedVector2Array()
	for i in 6:
		var x := 2.0 + i * 2.0
		var y := sin(_time * 7.0 - i * 0.9) * (0.4 + i * 0.25)
		flap.append(Vector2(x, -27.0 + y - (5.0 - i * 0.8)))
		ripple.append(Vector2(x, -27.0 + y + (5.0 - i * 0.8)))
	ripple.reverse()
	var shape := PackedVector2Array([Vector2(1, -32)]) + flap + ripple + PackedVector2Array([Vector2(1, -22)])
	draw_colored_polygon(shape, Palette.OUTLINE)
	var inner := PackedVector2Array()
	for p in shape:
		inner.append(p.lerp(Vector2(6, -27), 0.22))
	draw_colored_polygon(inner, NAVY if won else SORREL_RED)
	if won:
		for i in [1, 3]:
			draw_line(flap[i] + Vector2(0, 1), ripple[ripple.size() - 1 - i] + Vector2(0, -1), STRIPE, 1.0)
