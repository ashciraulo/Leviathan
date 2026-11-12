class_name GranTable
extends StaticBody2D
## Liesl's table in Drowned Lane, laid for her great-grandmother
## (StoryDirector.grans_supper). While Liesl waits it is four bare plates;
## set, it carries Gran's blue cup, her pewter candlestick and her little
## salt fish, a loaf of Ide's bread, and the candle Wren lit.

const WOOD := Color("#8a5a3a")
const WOOD_LIGHT := Color("#b07a4e")
const WOOD_DARK := Color("#5a3a26")
const PLATE := Color("#e8e0d0")
const PLATE_DARK := Color("#b8ac98")
const CUP := Color("#4a78c8")
const CUP_LIGHT := Color("#7ea4e8")
const PEWTER := Color("#9aa0a8")
const PEWTER_DARK := Color("#666c78")
const WAX := Color("#f0e6c8")
const FLAME := Color("#ffd26a")
const FLAME_CORE := Color("#fff4c0")
const BREAD := Color("#c88a48")
const BREAD_LIGHT := Color("#e0aa68")
## Half the table's width and its depth, in pixels.
const HALF := 18.0
const DEPTH := 10.0
## Where the candle's flame sits, for the lamp's glow in the scene.
const FLAME_AT := Vector2(0, -15)

## Gran's things are on it.
var set_out := false
var candle_lit := false
var bread := false
var _time := 0.0


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(HALF * 2.0, 6)
	shape.shape = box
	shape.position = Vector2(0, -3)
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	if candle_lit:
		queue_redraw()


func _draw() -> void:
	# Legs, then the top, seen from a little above.
	for x in [-HALF + 2, HALF - 4]:
		draw_rect(Rect2(x - 1, -4, 4, 5), Palette.OUTLINE)
		draw_rect(Rect2(x, -4, 2, 4), WOOD_DARK)
	draw_rect(Rect2(-HALF - 1, -DEPTH - 5, HALF * 2 + 2, DEPTH + 2), Palette.OUTLINE)
	draw_rect(Rect2(-HALF, -DEPTH - 4, HALF * 2, DEPTH), WOOD)
	draw_rect(Rect2(-HALF, -DEPTH - 4, HALF * 2, 1), WOOD_LIGHT)
	draw_rect(Rect2(-HALF, -5, HALF * 2, 1), WOOD_DARK)
	# Four plates: two along the back, one at each end.
	for p in [Vector2(-9, -11), Vector2(9, -11), Vector2(-15, -8), Vector2(15, -8)]:
		draw_set_transform(p, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, 3.5, PLATE_DARK)
		draw_circle(Vector2(0, -0.5), 2.8, PLATE)
		draw_set_transform(Vector2.ZERO)
	if not set_out:
		return
	# Gran's blue cup by her plate at the head (the left end).
	draw_rect(Rect2(-13, -14, 4, 4), Palette.OUTLINE)
	draw_rect(Rect2(-12, -13, 2, 2), CUP)
	draw_rect(Rect2(-12, -13, 2, 1), CUP_LIGHT)
	draw_rect(Rect2(-9, -13, 1, 2), CUP)
	# The salt fish, nose to the cup.
	draw_rect(Rect2(4, -9, 6, 3), Palette.OUTLINE)
	draw_rect(Rect2(5, -8, 4, 1), PEWTER)
	draw_rect(Rect2(10, -9, 2, 3), PEWTER_DARK)
	draw_rect(Rect2(6, -8, 1, 1), PEWTER_DARK)
	# The candlestick in the middle.
	draw_rect(Rect2(-3, -9, 6, 2), PEWTER_DARK)
	draw_rect(Rect2(-1, -14, 2, 6), PEWTER)
	draw_rect(Rect2(-1, -14, 2, 1), WAX)
	if candle_lit:
		var flicker := 1.0 if fmod(_time, 0.5) < 0.25 else 0.0
		draw_circle(Vector2(0, -16), 9.0 + flicker, Color(1.0, 0.85, 0.45, 0.16))
		draw_circle(Vector2(0, -16), 5.0, Color(1.0, 0.9, 0.55, 0.22))
		draw_rect(Rect2(-1, -18 - flicker, 2, 4 + flicker), FLAME)
		draw_rect(Rect2(0, -16, 1, 2), FLAME_CORE)
	if bread:
		draw_rect(Rect2(-8, -8, 8, 4), Palette.OUTLINE)
		draw_rect(Rect2(-7, -7, 6, 2), BREAD)
		draw_rect(Rect2(-6, -7, 4, 1), BREAD_LIGHT)
