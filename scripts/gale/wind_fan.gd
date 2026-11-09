class_name WindFan
extends StaticBody2D
## A fan set in the tower floor (> < N S: the way it blows). It drives a
## stream of wind straight ahead until a wall or the room's edge stops it
## (it never blows out through a doorway). Walking, Wren is
## pushed along it (they can still walk against it, slowly, and it never
## blows them off an edge); gliding on the Kite Cloak, the stream carries
## them and keeps them up.

## Strength of the stream (pixels per second).
const PUSH := 55.0
## How far the stream reaches at most (tiles).
const REACH := 22
const LETTERS := {">": Vector2.RIGHT, "<": Vector2.LEFT, "N": Vector2.UP, "S": Vector2.DOWN}

var direction := Vector2.RIGHT
## The stream, in the room's coordinates.
var stream := Rect2()
var _sprite: Sprite2D
var _time := 0.0
var _gusts: Array[float] = []


## The wind at `at` (global): the sum of every stream it stands in.
static func wind_at(tree: SceneTree, at: Vector2) -> Vector2:
	var total := Vector2.ZERO
	for fan: WindFan in tree.get_nodes_in_group("wind_fans"):
		var room := fan.get_parent() as Node2D
		if fan.stream.has_point(at - room.global_position):
			total += fan.direction * PUSH
	return total


func _ready() -> void:
	add_to_group("wind_fans")
	# Set flush in the floor: Wren walks (and glides) right over it.
	collision_layer = 0
	_sprite = Art.sprite(GaleSprites.FAN, 2, 1, 14)
	add_child(_sprite)
	z_index = -1
	var room := get_parent() as Room
	var tile := Vector2i(int(position.x) / Room.TILE, int(position.y) / Room.TILE)
	var step := Vector2i(direction)
	var last := tile
	for i in REACH:
		var next := last + step
		if room == null or room.tile_at(next.x, next.y) == "#":
			break
		if next.x <= 0 or next.y <= 0 or next.x >= Room.COLS - 1 or next.y >= Room.ROWS - 1:
			break
		last = next
	var a := Vector2(mini(tile.x, last.x), mini(tile.y, last.y)) * Room.TILE
	var b := Vector2(maxi(tile.x, last.x) + 1, maxi(tile.y, last.y) + 1) * Room.TILE
	stream = Rect2(a, b - a)
	for i in 6:
		_gusts.append(randf())


func _physics_process(delta: float) -> void:
	# Walking in the stream, Wren is pushed along it.
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.frozen or player.airborne:
		return
	if not (player.state in [Player.State.MOVE, Player.State.ATTACK, Player.State.CHARGE, Player.State.HUM, Player.State.HURT]):
		return
	var room := get_parent() as Node2D
	var local := player.global_position - room.global_position
	if not stream.has_point(local + Vector2(0, -4)):
		return
	# It leans on Wren at the edge of a drop, but never blows them off it.
	var field := room.get_node_or_null("PitField") as PitField
	if field and field.is_gap(local + Vector2(0, -3) + direction * 7.0):
		return
	player.move_and_collide(direction * PUSH * delta)


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time * 14.0) % 2
	for i in _gusts.size():
		_gusts[i] = fmod(_gusts[i] + delta * (0.9 + i * 0.08), 1.0)
	queue_redraw()


## Streaks of wind running along the stream.
func _draw() -> void:
	var length := maxf(stream.size.x, stream.size.y) - Room.TILE
	var across := Vector2(-direction.y, direction.x)
	var origin := stream.get_center() - position - direction * (length + Room.TILE) / 2.0
	for i in _gusts.size():
		var t := _gusts[i]
		var at := origin + direction * (Room.TILE * 0.5 + t * length) + across * (float(i % 3) - 1.0) * 4.0
		var color := Color(1, 1, 1, 0.55 * sin(t * PI))
		draw_line(at, at - direction * 6.0, color, 1.0)
