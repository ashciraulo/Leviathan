class_name LockedDoor
extends StaticBody2D
## A barred hatch in a dungeon doorway. Walk into it with a small key and it
## opens (all the hatch tiles in that room open together, and stay open).
## Without a key it says it's locked.

const TOAST_COOLDOWN := 1.5

var room_coord := Vector2i.ZERO
var dungeon := ""
var _touch: Area2D
var _last_toast := -100000


static func lock_flag(coord: Vector2i) -> String:
	return "door_%d_%d" % [coord.x, coord.y]


func _ready() -> void:
	if GameState.flags.get(lock_flag(room_coord), false):
		queue_free()
		return
	add_to_group("locked_doors")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(16, 16), Vector2(0, -4)))
	var sprite := Art.sprite(Art.LOCKED_HATCH, 1, 1, 15)
	sprite.position.y += 4
	add_child(sprite)
	_touch = Area2D.new()
	Layers.assign(_touch, 0, [Layers.PLAYER])
	_touch.monitorable = false
	_touch.add_child(Layers.rect_shape(Vector2(20, 20), Vector2(0, -4)))
	_touch.body_entered.connect(_on_touch)
	add_child(_touch)


func _on_touch(body: Node2D) -> void:
	if not (body is Player):
		return
	# Touch areas of neighbouring hatch tiles overlap, so Wren can enter two in
	# one step. Once the lock is open (or this hatch is going), ignore it.
	if GameState.flags.get(lock_flag(room_coord), false) or not is_in_group("locked_doors"):
		return
	if GameState.use_key(dungeon):
		open_lock(room_coord)
		Audio.play_sfx("door_unlock", global_position)
	elif Time.get_ticks_msec() - _last_toast > TOAST_COOLDOWN * 1000.0:
		_last_toast = Time.get_ticks_msec()
		Audio.play_sfx("door_locked", global_position)


## Opens every hatch in the room and remembers it.
func open_lock(coord: Vector2i) -> void:
	GameState.flags[lock_flag(coord)] = true
	for door in get_tree().get_nodes_in_group("locked_doors"):
		if door is LockedDoor and door.room_coord == coord:
			door._vanish()


func _vanish() -> void:
	remove_from_group("locked_doors")
	collision_layer = 0
	_touch.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
