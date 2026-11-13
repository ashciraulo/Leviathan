class_name LoweGarden
extends Node2D
## Lowe's watch on Lullaby Point (StoryDirector._put_lowe): her Choir robe
## folded on the rocks once her four singers are home, and the stubborn
## little garden she plants from Wren's finds (frost thistle, ember moss,
## a fen lily).

const ROBE_FLAG := "lowe_singers_done"
const GARDEN_FLAG := "lowe_garden_done"
## Where the robe lies and where the three plants grow, from Lowe's feet.
const ROBE_AT := Vector2(22, 2)
const PLANTS_AT := [Vector2(-20, 10), Vector2(-10, 13), Vector2(0, 11)]
const THISTLE := Color("#6aa0e0")
const THISTLE_DARK := Color("#3a5a9a")
const MOSS := Color("#e07a3a")
const MOSS_LIGHT := Color("#ffb060")
const LILY := Color("#f2ecd8")
const STEM := Color("#4e7a44")

var _robe: RobeHeap


func _ready() -> void:
	z_index = -1
	_robe = RobeHeap.new()
	_robe.position = ROBE_AT
	add_child(_robe)
	Events.flag_changed.connect(func(_flag: String, _value: Variant) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	_robe.visible = GameState.has_flag(ROBE_FLAG)
	queue_redraw()


func _draw() -> void:
	if not GameState.has_flag(GARDEN_FLAG):
		return
	# Frost thistle: a blue, bristling head on a short stem.
	var t: Vector2 = PLANTS_AT[0]
	draw_rect(Rect2(t + Vector2(-1, -5), Vector2(2, 5)), Palette.OUTLINE)
	draw_rect(Rect2(t + Vector2(0, -5), Vector2(1, 5)), STEM)
	draw_circle(t + Vector2(0, -7), 3.0, Palette.OUTLINE)
	draw_circle(t + Vector2(0, -7), 2.0, THISTLE_DARK)
	draw_rect(Rect2(t + Vector2(-1, -9), Vector2(2, 2)), THISTLE)
	# Ember moss: a low, warm tuft.
	var m: Vector2 = PLANTS_AT[1]
	draw_set_transform(m, 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 4.0, Palette.OUTLINE)
	draw_circle(Vector2(0, -0.5), 3.0, MOSS)
	draw_circle(Vector2(-1, -1.5), 1.2, MOSS_LIGHT)
	draw_set_transform(Vector2.ZERO)
	# The fen lily: two leaves and a pale cup.
	var l: Vector2 = PLANTS_AT[2]
	draw_rect(Rect2(l + Vector2(-3, -3), Vector2(2, 3)), STEM)
	draw_rect(Rect2(l + Vector2(1, -3), Vector2(2, 3)), STEM)
	draw_rect(Rect2(l + Vector2(-2, -8), Vector2(4, 4)), Palette.OUTLINE)
	draw_rect(Rect2(l + Vector2(-1, -7), Vector2(2, 3)), LILY)
