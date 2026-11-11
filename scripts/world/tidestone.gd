class_name Tidestone
extends StaticBody2D
## A standing stone that doubles as a checkpoint. Touching it wakes it and
## saves the game; dying brings Wren back here. Once the Old One has turned
## over, Wren can face an awake stone and press Interact to turn the tide
## (see Tide.turn): the stone rings, glows and the ground shudders.
##
## The keepers of the Pact raised the stones a thousand years ago along
## their round between the seven shrines, cut from the Kiln's slag with
## the Old One's shed scale ground in, so they hum to the bells (and, once
## the Old One has turned, to the tide). Every keeper since has cut a line
## into them. Facing a stone and pressing Interact reads its carving; after
## the turn, a stone already read turns the tide instead.

## Where Wren stands after loading, relative to the stone.
const CHECKPOINT_OFFSET := Vector2(0, 28)
## Set once Wren has read every stone (Hessa asks them to walk the round).
const ALL_READ_FLAG := "read_every_stone"
## Set once Hessa has cut Wren's line under hers on the Saltmarrow stone.
const WREN_CARVED_FLAG := "hessa_carved_wren"
const WREN_LINE_READ_FLAG := "read_wren_line"
const SALTMARROW_STONE := Vector2i(1, 1)

## Room -> what is cut into its stone. Most are a line under a short
## narration; one stone holds only tally notches.
const CARVINGS := {
	Vector2i(0, 0): ["NARRATE_STONE_WORDS", "STONE_SHORE"],
	Vector2i(1, 1): ["NARRATE_STONE_WORDS", "STONE_SALTMARROW"],
	Vector2i(3, -1): ["NARRATE_STONE_WORDS", "STONE_BRINEWOOD"],
	Vector2i(5, 0): ["NARRATE_STONE_NOTCHES", "NARRATE_STONE_NOTCHES_2"],
	Vector2i(8, -3): ["NARRATE_STONE_WORDS", "STONE_CINDER"],
	Vector2i(9, -1): ["NARRATE_STONE_WORDS", "STONE_KILN_MOUTH"],
	Vector2i(3, 1): ["NARRATE_STONE_WORDS", "STONE_FEN"],
	Vector2i(5, 2): ["NARRATE_STONE_WORDS", "STONE_MIRELIGHT"],
	Vector2i(5, -3): ["NARRATE_STONE_WORDS", "STONE_WINDMERE"],
	Vector2i(5, -4): ["NARRATE_STONE_WORDS", "STONE_SPIRE_FOOT"],
	Vector2i(1, -2): ["NARRATE_STONE_WORDS", "STONE_FROST"],
	Vector2i(1, -3): ["NARRATE_STONE_WORDS", "STONE_FROST_2"],
	Vector2i(0, 2): ["NARRATE_STONE_WORDS", "STONE_VERGE"],
	Vector2i(2, 3): ["NARRATE_STONE_WORDS", "STONE_VERGE_2"],
	Vector2i(9, 0): ["NARRATE_STONE_WORDS", "STONE_DUNES"],
	Vector2i(9, 1): ["NARRATE_STONE_WORDS", "STONE_DUNES_2"],
	Vector2i(10, 10): ["NARRATE_STONE_WORDS", "STONE_HULL"],
	Vector2i(21, 10): ["NARRATE_STONE_WORDS", "STONE_KILN"],
	Vector2i(25, 10): ["NARRATE_STONE_WORDS", "STONE_MIRE"],
	Vector2i(28, 10): ["NARRATE_STONE_WORDS", "STONE_GALE"],
	Vector2i(32, 10): ["NARRATE_STONE_WORDS", "STONE_GLACIER"],
	Vector2i(36, 10): ["NARRATE_STONE_WORDS", "STONE_BELFRY"],
}

var room_coord := Vector2i.ZERO
var awake := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("interactable")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 8), Vector2(0, -4)))
	var area := Area2D.new()
	area.name = "Touch"
	Layers.assign(area, 0, [Layers.PLAYER])
	area.monitorable = false
	area.add_child(Layers.circle_shape(22.0, Vector2(0, -4)))
	area.body_entered.connect(_on_body_entered)
	add_child(area)
	awake = bool(GameState.flags.get(flag_key(), false))
	# Saves that read every stone before the round was asked for still count.
	if read_count() >= CARVINGS.size():
		GameState.set_flag(ALL_READ_FLAG)
	add_child(Art.shadow(true))
	_sprite = Art.sprite(Art.TIDESTONE, 2, 1, 20)
	add_child(_sprite)
	_sprite.frame = 1 if awake else 0


func flag_key() -> String:
	return "tidestone_%d_%d" % [room_coord.x, room_coord.y]


## What a stone says now: Hessa adds Wren's line to the Saltmarrow stone.
static func carving_for(coord: Vector2i) -> Array:
	var carving: Array = CARVINGS.get(coord, [])
	if coord == SALTMARROW_STONE and GameState.has_flag(WREN_CARVED_FLAG):
		return carving + ["STONE_SALTMARROW_WREN"]
	return carving


## How many stones' carvings Wren has read.
static func read_count() -> int:
	var count := 0
	for coord: Vector2i in CARVINGS:
		if GameState.has_flag("tidestone_read_%d_%d" % [coord.x, coord.y]):
			count += 1
	return count


## Set once Wren has read this stone's carving.
func read_key() -> String:
	return "tidestone_read_%d_%d" % [room_coord.x, room_coord.y]


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	Audio.play_sfx("tidestone_wake" if not awake else "save", global_position)
	awake = true
	GameState.flags[flag_key()] = true
	GameState.wake_tidestone(room_coord, position + CHECKPOINT_OFFSET)
	GameState.set_checkpoint(room_coord, position + CHECKPOINT_OFFSET)
	# The hum, the glow and the HUD's turning bubbles say it was saved.
	SaveManager.save_game()
	_sprite.frame = 1


## Reads the stone's carving; once the Old One has turned over, a stone
## already read turns the tide instead.
func interact() -> void:
	if not awake or DialogueBox.is_open or Cutscene.active:
		return
	var carving := carving_for(room_coord)
	# Wren's own new line is always read once, even after the turn.
	var new_line := room_coord == SALTMARROW_STONE and GameState.has_flag(WREN_CARVED_FLAG) and not GameState.has_flag(WREN_LINE_READ_FLAG)
	if not carving.is_empty() and (new_line or not (Tide.can_turn() and GameState.has_flag(read_key()))):
		GameState.set_flag(read_key())
		if new_line:
			GameState.set_flag(WREN_LINE_READ_FLAG)
		if read_count() >= CARVINGS.size() and not GameState.has_flag(ALL_READ_FLAG):
			GameState.set_flag(ALL_READ_FLAG)
			Audio.play_jingle("jingle_secret")
		var pages: Array = []
		for key: String in carving:
			pages.append({"name": "", "portrait": null, "text": key})
		Events.conversation_requested.emit(pages)
		return
	if not Tide.can_turn():
		return
	var to := Tide.turn(get_tree())
	Audio.play_sfx("tide_rise" if to == "high" else "tide_ebb", global_position)
	Feel.shake(2.0)
	var glow := create_tween()
	_sprite.modulate = Color(1.6, 1.6, 1.9)
	glow.tween_property(_sprite, "modulate", Color.WHITE, 0.8)
	SaveManager.save_game()
