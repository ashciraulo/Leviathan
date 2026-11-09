class_name Tidestone
extends StaticBody2D
## A standing stone that doubles as a checkpoint. Touching it wakes it and
## saves the game; dying brings Wren back here. Once the Old One has turned
## over, Wren can face an awake stone and press Interact to turn the tide
## (see Tide.turn): the stone rings, glows and the ground shudders.

## Where Wren stands after loading, relative to the stone.
const CHECKPOINT_OFFSET := Vector2(0, 28)

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
	add_child(Art.shadow(true))
	_sprite = Art.sprite(Art.TIDESTONE, 2, 1, 20)
	add_child(_sprite)
	_sprite.frame = 1 if awake else 0


func flag_key() -> String:
	return "tidestone_%d_%d" % [room_coord.x, room_coord.y]


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


## Turns the tide, once the Old One has turned over. Before that the stone
## has nothing to say.
func interact() -> void:
	if not awake or not Tide.can_turn():
		return
	var to := Tide.turn(get_tree())
	Audio.play_sfx("tide_rise" if to == "high" else "tide_ebb", global_position)
	Feel.shake(2.0)
	var glow := create_tween()
	_sprite.modulate = Color(1.6, 1.6, 1.9)
	glow.tween_property(_sprite, "modulate", Color.WHITE, 0.8)
	SaveManager.save_game()
