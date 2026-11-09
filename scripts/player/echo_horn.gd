class_name EchoHorn
extends Node2D
## The Echo Horn, the Marrow Tomb's tool. Wren lifts it and blows one long
## low note, and the note spreads out round them (see EchoWave): bone
## walls crumble, skulls sing back, hidden things show, and bone armour
## shatters.
##
## Lives as a child of Wren while in use, and frees itself when done.

const BLOW_TIME := 0.4

var _player: Player
var _time := 0.0


func _ready() -> void:
	_player = get_parent() as Player
	z_index = 1
	Audio.play_sfx("horn_blow", _player.global_position)
	var wave := EchoWave.new()
	_player.get_parent().add_child(wave)
	wave.global_position = _player.global_position


func _physics_process(delta: float) -> void:
	if _player == null or not _player.is_using_item():
		queue_free()
		return
	_time += delta
	_player.item_velocity = Vector2.ZERO
	if _time >= BLOW_TIME:
		_player.end_item()
		queue_free()
	queue_redraw()


func _draw() -> void:
	# The horn at Wren's mouth, bell turned up and out.
	var side := -1.0 if _player and _player.facing.x < 0.0 else 1.0
	draw_set_transform(Vector2(6 * side, -16), -0.5 * side, Vector2(side, 1))
	draw_texture(TombSprites.ECHO_HORN, Vector2(-8, -8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
