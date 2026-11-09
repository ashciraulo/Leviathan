class_name QuestCrab
extends Node2D
## Pell's three-clawed crab, hiding in the Tidepools (room letter k). It only
## turns up once Pell has asked for one, and Wren picks it up with Interact.
## The Scuttler's sprite with a blue shell, orange claws and a third claw
## (tools/build_art.py), sidling back and forth.

const SIDLE := 6.0
const SIDLE_SPEED := 0.9

var _time := 0.0
var _home := Vector2.ZERO
var _sprite: Sprite2D


func _ready() -> void:
	_home = position
	add_child(Art.shadow())
	_sprite = Art.sprite(Art.QUEST_CRAB, 2, 1, 11)
	add_child(_sprite)
	_refresh()
	Events.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(_flag: String, _value: Variant) -> void:
	_refresh()


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
	var x := roundf(sin(_time * SIDLE_SPEED * TAU / 2.0) * SIDLE)
	_sprite.frame = int(_time * 8.0) % 2 if x != position.x - _home.x else 0
	position.x = _home.x + x


func interact() -> void:
	GameState.set_flag("found_crab")
	Audio.play_jingle("jingle_secret")
	Events.conversation_requested.emit([{"name": "", "portrait": null, "text": "NARRATE_FOUND_CRAB"}])
