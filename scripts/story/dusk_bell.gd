class_name DuskBell
extends StaticBody2D
## Wick's dusk bell at Fenmouth: a little brass bell on a post. Once Wick
## has told Wren about the lamplighter's round, ringing it puts the fen's
## lanterns out and starts one (LamplighterRound).

const WOOD := Color("#5a4636")
const BRASS := Color("#c8a048")
const BRASS_DARK := Color("#8a6a2a")

var _time := 0.0
var _swing := 0.0


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(6, 4), Vector2(0, -2)))
	add_child(Art.shadow())
	add_to_group("interactable")


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active:
		return
	_swing = 1.0
	if not GameState.has_flag(LamplighterRound.ASK_FLAG) or LamplighterRound.running:
		Audio.play_sfx("text_blip", global_position, 1.4)
		if not LamplighterRound.running:
			Conversations.talk("dusk_bell")
		return
	Audio.play_sfx("bell_quiet", global_position, 1.2)
	LamplighterRound.begin(get_tree().get_first_node_in_group("story_director").game)


func _process(delta: float) -> void:
	_time += delta
	_swing = maxf(_swing - delta * 0.8, 0.0)
	queue_redraw()


func _draw() -> void:
	# A short post with an arm, the bell hung from it, swinging when rung.
	draw_rect(Rect2(-2, -22, 3, 22), Palette.OUTLINE)
	draw_rect(Rect2(-1, -21, 1, 21), WOOD)
	draw_rect(Rect2(-2, -23, 9, 2), Palette.OUTLINE)
	var tilt := sin(_time * 14.0) * 0.5 * _swing
	draw_set_transform(Vector2(5, -21), tilt, Vector2.ONE)
	draw_rect(Rect2(-3, 1, 7, 6), Palette.OUTLINE)
	draw_rect(Rect2(-2, 2, 5, 4), BRASS)
	draw_rect(Rect2(-2, 5, 5, 1), BRASS_DARK)
	draw_rect(Rect2(0, 7, 1, 1), BRASS_DARK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
