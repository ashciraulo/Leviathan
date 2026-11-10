class_name FerryBell
extends Node2D
## A hand bell hung on a post at Causeway End's south landing. Ring it and
## Ide, over on the north shore, rows across for Wren (StoryDirector).

const WOOD := Color("#6b4a32")
const WOOD_LIGHT := Color("#8d6644")
const BRASS := Color("#d9a441")
const BRASS_LIGHT := Color("#f2d27a")

var _swing := 0.0
var _time := 0.0


func _ready() -> void:
	add_to_group("interactable")
	add_child(Art.shadow())


func _process(delta: float) -> void:
	_time += delta
	_swing = maxf(_swing - delta, 0.0)
	queue_redraw()


func interact() -> void:
	if Cutscene.active:
		return
	ring()
	GameState.set_flag(StoryDirector.FERRY_FLAG)


## The bell swings and rings out over the channel.
func ring() -> void:
	_swing = 1.2
	Audio.play_sfx("bell_ring", global_position, 1.7)


func _draw() -> void:
	# The post, with a crossarm leaning out over the water.
	draw_rect(Rect2(-2, -20, 4, 20), Palette.OUTLINE)
	draw_rect(Rect2(-1, -19, 2, 19), WOOD)
	draw_rect(Rect2(-1, -19, 1, 19), WOOD_LIGHT)
	draw_rect(Rect2(-2, -21, 10, 3), Palette.OUTLINE)
	draw_rect(Rect2(-1, -20, 8, 1), WOOD_LIGHT)
	# The bell, swinging when rung and stirring a little in the wind.
	var angle := sin(_time * 1.3) * 0.08 + sin(_swing * 14.0) * 0.5 * _swing
	draw_set_transform(Vector2(6, -18), angle, Vector2.ONE)
	draw_line(Vector2.ZERO, Vector2(0, 3), Palette.OUTLINE, 1.0)
	var bell := PackedVector2Array([Vector2(-1, 2), Vector2(1, 2), Vector2(3, 8), Vector2(-3, 8)])
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 1), Vector2(2, 1), Vector2(4, 9), Vector2(-4, 9)]), Palette.OUTLINE)
	draw_colored_polygon(bell, BRASS)
	draw_line(Vector2(-1, 3), Vector2(-2, 7), BRASS_LIGHT, 1.0)
	draw_rect(Rect2(-1, 8, 2, 2), Palette.OUTLINE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Rings of sound while it's ringing.
	if _swing > 0.0:
		var spread := (1.2 - _swing) * 18.0
		draw_arc(Vector2(6, -14), 4.0 + spread, -PI * 0.9, -PI * 0.1, 12, Color(1, 0.95, 0.7, _swing * 0.6), 1.0)
