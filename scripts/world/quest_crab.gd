class_name QuestCrab
extends Node2D
## Pell's three-clawed crab, hiding in the Tidepools (room letter k). It only
## turns up once Pell has asked for one, and Wren picks it up with Interact.
## Drawn in code: a small blue crab, outlined, with two orange claws on the
## left and one on the right, that sidles back and forth.

const SIDLE := 6.0
const SIDLE_SPEED := 0.9
## Blue shell and bright orange claws: reads against sand, and never
## mistaken for the red Scuttlers.
const SHELL := Color("#3f86b0")
const SHELL_DARK := Color("#285a80")
const CLAW := Color("#f08a3c")
const EYE := Color("#2a1e36")
const OUTLINE := Color("#2a1e36")

## [x, y, w, h, colour] relative to the crab's feet.
const PIXELS := [
	[-4, -7, 8, 4, SHELL], [-5, -6, 10, 2, SHELL], [-4, -4, 8, 1, SHELL_DARK],
	[-3, -9, 1, 2, EYE], [2, -9, 1, 2, EYE],
	# Legs.
	[-6, -3, 1, 2, SHELL_DARK], [-4, -3, 1, 2, SHELL_DARK],
	[3, -3, 1, 2, SHELL_DARK], [5, -3, 1, 2, SHELL_DARK],
	# Two claws on the left, one on the right: the third claw is the prize.
	[-9, -10, 3, 3, CLAW], [-9, -6, 3, 2, CLAW], [-7, -8, 2, 1, CLAW],
	[6, -9, 3, 3, CLAW], [5, -7, 2, 1, CLAW],
]

var _time := 0.0
var _home := Vector2.ZERO


func _ready() -> void:
	_home = position
	z_index = 0
	var shade := Art.shadow()
	add_child(shade)
	_refresh()
	Events.flag_changed.connect(func(_flag: String, _value: Variant) -> void: _refresh())


## Visible (and interactable) only while Pell is waiting for it.
func _refresh() -> void:
	var waiting := GameState.has_flag("talked_pell_quest") and not GameState.has_flag("found_crab")
	visible = waiting
	if waiting:
		add_to_group("interactable")
	elif is_in_group("interactable"):
		remove_from_group("interactable")


func _process(delta: float) -> void:
	if not visible or DialogueBox.is_open:
		return
	_time += delta
	position.x = _home.x + roundf(sin(_time * SIDLE_SPEED * TAU / 2.0) * SIDLE)
	queue_redraw()


func _draw() -> void:
	var step := 1.0 if fmod(_time * 4.0, 2.0) < 1.0 else 0.0
	# A dark outline first, one pixel round every part, then the colours.
	for p: Array in PIXELS:
		if p[4] != EYE:
			var lift := step if p[4] == CLAW else 0.0
			draw_rect(Rect2(p[0] - 1, p[1] - 1 - lift, p[2] + 2, p[3] + 2), OUTLINE)
	for p: Array in PIXELS:
		var lift := step if p[4] == CLAW else 0.0
		draw_rect(Rect2(p[0], p[1] - lift, p[2], p[3]), p[4])


func interact() -> void:
	GameState.set_flag("found_crab")
	Audio.play_jingle("jingle_secret")
	Events.conversation_requested.emit([{"name": "", "portrait": null, "text": "NARRATE_FOUND_CRAB"}])
