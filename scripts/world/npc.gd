class_name Npc
extends StaticBody2D
## Someone Wren can talk to. Walk up, face them and press Interact.
## Each kind has its first conversation and a shorter line for after that.

## kind: texture, sheet frames, speaker name key, flag set after the first
## talk, first talk, later talks.
const KINDS := {
	"hessa": {
		"texture": Art.HESSA,
		"frames": 3,
		"name": "NAME_HESSA",
		"flag": "met_hessa",
		"first": ["HESSA_1", "HESSA_2", "HESSA_3", "HESSA_4", "HESSA_5", "HESSA_6"],
		"again": ["HESSA_AGAIN"],
	},
}
## Sheet columns: idle, breathe, listen (Hessa lifts her ear trumpet).
const FRAME_IDLE := 0
const FRAME_BREATHE := 1
const FRAME_LISTEN := 2
const BREATHE_TIME := 0.8
## Wren this close makes the NPC turn and listen, and shows the talk mark.
const NOTICE_RANGE := 44.0
const TALK_RANGE := 26.0

var kind := "hessa"
var _sprite: Sprite2D
var _mark: Node2D
var _time := 0.0
var _player_near := false
var _can_talk := false


func _init(npc_kind: String = "hessa") -> void:
	kind = npc_kind


func _ready() -> void:
	add_to_group("interactable")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 7), Vector2(0, -3.5)))
	add_child(Art.shadow())
	var spec: Dictionary = KINDS[kind]
	_sprite = Art.sprite(spec["texture"], spec["frames"], 1, 22)
	add_child(_sprite)
	_mark = Node2D.new()
	_mark.position = Vector2(0, -30)
	_mark.draw.connect(_draw_mark)
	add_child(_mark)


func _process(delta: float) -> void:
	_time += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var distance := INF if player == null else player.global_position.distance_to(global_position)
	_player_near = distance < NOTICE_RANGE
	_can_talk = distance < TALK_RANGE
	if _player_near:
		_sprite.frame = FRAME_LISTEN
		_sprite.flip_h = player.global_position.x < global_position.x - 4.0
	else:
		_sprite.frame = FRAME_BREATHE if int(_time / BREATHE_TIME) % 2 == 1 else FRAME_IDLE
		_sprite.flip_h = false
	_mark.visible = _can_talk and not DialogueBox.is_open
	_mark.position.y = -30 + (1 if int(_time * 2.0) % 2 == 0 else 0)
	_mark.queue_redraw()


## What the next talk would say: the first conversation, then the short one.
func current_lines() -> PackedStringArray:
	var spec: Dictionary = KINDS[kind]
	if GameState.flags.get(spec["flag"], false):
		return PackedStringArray(spec["again"])
	return PackedStringArray(spec["first"])


func interact() -> void:
	var spec: Dictionary = KINDS[kind]
	var lines := current_lines()
	GameState.flags[spec["flag"]] = true
	Events.dialogue_requested.emit(spec["name"], lines)


## A little speech bubble with three dots.
func _draw_mark() -> void:
	var rect := Rect2(-6, -6, 12, 8)
	_mark.draw_rect(rect.grow(1), Palette.OUTLINE)
	_mark.draw_rect(rect, Palette.MENU_ACTIVE)
	_mark.draw_rect(Rect2(-1, 2, 2, 2), Palette.MENU_ACTIVE)
	_mark.draw_rect(Rect2(-1, 4, 1, 1), Palette.OUTLINE)
	for x in [-4, -1, 2]:
		_mark.draw_rect(Rect2(x, -3, 2, 2), Palette.OUTLINE)
