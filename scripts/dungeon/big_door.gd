class_name BigDoor
extends StaticBody2D
## The great carved door to the boss. Only the dungeon's big key opens it.
## Like hatches, every big-door tile in a room opens together.

const TOAST_COOLDOWN := 1.5

var room_coord := Vector2i.ZERO
var dungeon := ""
## The right-hand half of a two-tile door (drawn mirrored).
var right_half := false
var _touch: Area2D
var _last_toast := -100000


static func flag_for(coord: Vector2i) -> String:
	return "bigdoor_%d_%d" % [coord.x, coord.y]


func _ready() -> void:
	if GameState.flags.get(flag_for(room_coord), false):
		queue_free()
		return
	add_to_group("big_doors")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(16, 16), Vector2(0, -4)))
	var sprite := Art.sprite(HullSprites.BIG_DOOR, 2, 1, 15)
	sprite.frame = 1 if right_half else 0
	sprite.position.y += 4
	add_child(sprite)
	_touch = Area2D.new()
	Layers.assign(_touch, 0, [Layers.PLAYER])
	_touch.monitorable = false
	_touch.add_child(Layers.rect_shape(Vector2(20, 22), Vector2(0, -4)))
	_touch.body_entered.connect(_on_touch)
	add_child(_touch)


func _on_touch(body: Node2D) -> void:
	if not (body is Player):
		return
	if GameState.has_dungeon_item(dungeon, "big_key"):
		GameState.flags[flag_for(room_coord)] = true
		Audio.play_sfx("door_unlock", global_position)
		Audio.play_sfx("door_slide", global_position)
		Feel.shake(3.0)
		for door in get_tree().get_nodes_in_group("big_doors"):
			if door is BigDoor and door.room_coord == room_coord:
				door._vanish()
	elif Time.get_ticks_msec() - _last_toast > TOAST_COOLDOWN * 1000.0:
		_last_toast = Time.get_ticks_msec()
		Audio.play_sfx("door_locked", global_position)


func _vanish() -> void:
	remove_from_group("big_doors")
	collision_layer = 0
	_touch.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 10, 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
