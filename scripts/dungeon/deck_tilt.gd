class_name DeckTilt
extends Node2D
## A listing deck: the wreck leans, so Wren slides downhill unless they walk
## against it. Loose grit drifts the same way so the slope reads at a glance.

const MOTES := 26

## Pixels per second, downhill.
var push := Vector2.ZERO
var _room: Room
var _motes: Array[Vector2] = []


func _ready() -> void:
	_room = get_parent() as Room
	z_index = -8
	var rnd := RandomNumberGenerator.new()
	rnd.seed = hash(_room.coord)
	for i in MOTES:
		_motes.append(Vector2(rnd.randf() * Room.SIZE.x, rnd.randf() * Room.SIZE.y))


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.frozen or player.airborne:
		return
	if not (player.state in [Player.State.MOVE, Player.State.ATTACK, Player.State.CHARGE, Player.State.HUM, Player.State.HURT]):
		return
	var local := player.global_position - _room.global_position
	if Rect2(Vector2.ZERO, Room.SIZE).has_point(local):
		player.move_and_collide(push * delta)
	# Grit slides downhill and wraps around.
	for i in _motes.size():
		var m := _motes[i] + push * delta * (1.2 + (i % 3) * 0.4)
		m.x = fposmod(m.x, Room.SIZE.x)
		m.y = fposmod(m.y, Room.SIZE.y)
		_motes[i] = m
	queue_redraw()


func _draw() -> void:
	for i in _motes.size():
		var m := _motes[i]
		var tile := _room.tile_at(int(m.x) / Room.TILE, int(m.y) / Room.TILE)
		if tile in ["#", "~", "_"]:
			continue
		var color := Color("#3e2e32") if i % 2 == 0 else Color("#7a5e4a")
		draw_rect(Rect2(m.floor(), Vector2(1, 1)), color)
		draw_rect(Rect2(m.floor() - push.normalized().round(), Vector2(1, 1)), Color(color, 0.5))
