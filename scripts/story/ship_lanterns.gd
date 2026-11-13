class_name ShipLanterns
extends Node2D
## The Lantern Wake's three ship's lanterns, back on her figurehead on
## Wreck Strand once Gully has hung them and Wren has lit them
## (StoryDirector._put_gully): one hooked on her shoulder, two on stakes
## driven into the sand at her foot. Placed at the figurehead's own spot.

const FLAG := "gully_lanterns_done"
## Where each lantern's body sits, from the figurehead's foot.
const SPOTS := [Vector2(-9, -26), Vector2(-15, -6), Vector2(15, -6)]
const BRASS := Color("#b08a3a")
const BRASS_DARK := Color("#6e5426")
const GLASS := Color("#7ad0a0")
const FLAME := Color("#fff2b0")
const STAKE := Color("#6a5038")

var _time := 0.0


func _ready() -> void:
	visible = GameState.has_flag(FLAG)
	Events.flag_changed.connect(func(flag: String, _value: Variant) -> void:
		if flag == FLAG:
			_show_after_talk())


## Gully's talk tells it (hung, then lit): shown once read.
func _show_after_talk() -> void:
	await get_tree().process_frame
	if DialogueBox.is_open:
		await Events.dialogue_finished
	visible = GameState.has_flag(FLAG)


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	for i in SPOTS.size():
		var at: Vector2 = SPOTS[i]
		if i > 0:
			# A stake in the sand.
			draw_rect(Rect2(at + Vector2(-1, 2), Vector2(2, absf(at.y) + 4)), Palette.OUTLINE)
			draw_rect(Rect2(at + Vector2(-0.5, 2), Vector2(1, absf(at.y) + 3)), STAKE)
		var flicker := 0.6 * sin(_time * 5.0 + i * 2.1)
		draw_circle(at, 8.0 + flicker, Color(0.55, 1.0, 0.75, 0.13))
		draw_rect(Rect2(at + Vector2(-3, -4), Vector2(6, 7)), Palette.OUTLINE)
		draw_rect(Rect2(at + Vector2(-2, -3), Vector2(4, 5)), GLASS)
		draw_rect(Rect2(at + Vector2(-1, -2), Vector2(2, 3)), FLAME)
		draw_rect(Rect2(at + Vector2(-2, -4), Vector2(4, 1)), BRASS)
		draw_rect(Rect2(at + Vector2(-2, 2), Vector2(4, 1)), BRASS_DARK)
		draw_rect(Rect2(at + Vector2(-1, -6), Vector2(2, 2)), BRASS)
