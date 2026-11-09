class_name Valve
extends StaticBody2D
## A great brass valve wheel (R). Turning it raises or lowers the water
## through the whole Drowned Belfry: the "," floor floods or drains.

const TURN_TIME := 0.6

var _sprite: Sprite2D
var _busy := false


func _ready() -> void:
	add_to_group("interactable")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 8), Vector2(0, -4)))
	add_child(Art.shadow())
	_sprite = Art.sprite(BelfrySprites.VALVE, 2, 1, 23)
	add_child(_sprite)


func interact() -> void:
	if _busy:
		return
	_busy = true
	var room := get_parent() as Room
	Audio.play_sfx("valve_turn", global_position)
	for i in 3:
		_sprite.frame = 1 - _sprite.frame
		await get_tree().create_timer(TURN_TIME / 3.0).timeout
		if not is_inside_tree():
			return
	var flag := Room.low_water_flag(room.dungeon if room else "belfry")
	if GameState.has_flag(flag):
		GameState.flags.erase(flag)
	else:
		GameState.set_flag(flag)
	Audio.play_sfx("water_rush", global_position)
	Feel.shake(2.5)
	for node in get_tree().get_nodes_in_group("rooms"):
		(node as Room).refresh_water()
	_busy = false
