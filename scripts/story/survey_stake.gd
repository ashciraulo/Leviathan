class_name SurveyStake
extends StaticBody2D
## One of Ferrin's survey stakes for the Edge Survey (StoryDirector): a
## red-and-white striped pole with a little pennant, at the far end of a
## reach. Before Wren drives it in, it's only a bare patch Wren can look
## at; afterwards it stands there for good. Talking to it is a
## conversation with no speaker (Conversations "survey_stake_<id>").

const RED := Color("#d85a50")
const WHITE := Color("#f6eedc")
const FLAG := Color("#f7d35a")
const FLAG_DARK := Color("#e0a93a")
const HEIGHT := 22.0

## "frost", "cinder" or "verge".
var id := ""
var _time := 0.0


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(4, 3), Vector2(0, -1)))
	add_child(Art.shadow())
	add_to_group("interactable")
	set_process(driven())


func flag() -> String:
	return "survey_stake_" + id


func driven() -> bool:
	return GameState.has_flag(flag())


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active:
		return
	var was := driven()
	if Conversations.talk(flag()).is_empty():
		return
	if not was and driven():
		Audio.play_sfx("block", global_position)
		Feel.shake(1.0)
		set_process(true)
		queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if not driven():
		# A cairn of three stones marks where the stake should go.
		for p in [Vector2(-3, -2), Vector2(2, -2), Vector2(0, -5)]:
			draw_circle(p, 2.5, Palette.OUTLINE)
			draw_circle(p, 1.8, Color("#a09080"))
		return
	draw_rect(Rect2(-2, -HEIGHT - 1, 4, HEIGHT + 1), Palette.OUTLINE)
	for i in int(HEIGHT / 4.0):
		draw_rect(Rect2(-1, -HEIGHT + i * 4, 2, 4), RED if i % 2 == 0 else WHITE)
	# The pennant flaps in the wind.
	var flap := sin(_time * 6.0) * 1.5
	var tip := Vector2(9, -HEIGHT + 3 + flap)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -HEIGHT - 1), tip + Vector2(1, 0), Vector2(1, -HEIGHT + 7)]), Palette.OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -HEIGHT), tip, Vector2(1, -HEIGHT + 6)]), FLAG)
	draw_line(Vector2(1, -HEIGHT + 3), tip, FLAG_DARK)
