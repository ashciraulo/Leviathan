class_name FrostfangBow
extends Node2D
## The Frostfang Bow, Hollow Glacier's tool. Wren draws and looses a frost
## arrow the way they face. The bow makes its own arrows out of the cold, so
## it never runs dry. See FrostArrow for what an arrow does.
##
## Lives as a child of Wren while in use, and frees itself when done.

const DRAW := 0.14
const RECOVER := 0.16
## On ice Wren keeps sliding while they shoot, slowing like this.
const SLIDE_DRAG := 45.0

var direction := Vector2.DOWN
var _player: Player
var _time := 0.0
var _loosed := false


func _ready() -> void:
	_player = get_parent() as Player
	direction = _player.facing
	z_index = 1 if direction.y >= 0.0 else -1
	Audio.play_sfx("bow_draw", _player.global_position)


func _physics_process(delta: float) -> void:
	if _player == null or not _player.is_using_item():
		queue_free()
		return
	_time += delta
	_player.item_velocity = _player.item_velocity.move_toward(Vector2.ZERO, SLIDE_DRAG * delta)
	if not _loosed and _time >= DRAW:
		_loosed = true
		var arrow := FrostArrow.new()
		arrow.direction = direction
		_player.get_parent().add_child(arrow)
		# Loosed down the middle of the row (or column) Wren stands in, so an
		# arrow along a one-tile lane, or at an eye in a niche, never clips
		# the wall beside it wherever in the tile Wren's feet are.
		var at := _player.global_position + Vector2(0, -7)
		var tile := Vector2(floorf(_player.global_position.x / Room.TILE), floorf(_player.global_position.y / Room.TILE)) * Room.TILE
		if direction.x != 0.0:
			at.y = tile.y + Room.TILE - 11.0
		else:
			at.x = tile.x + Room.TILE * 0.5
		arrow.global_position = at + direction * 8.0
		Audio.play_sfx("bow_loose", _player.global_position)
	if _time >= DRAW + RECOVER:
		# Coming off the bow on ice, Wren keeps what slide they had.
		var keep := _player.item_velocity
		_player.end_item()
		_player.velocity = keep
		queue_free()
	queue_redraw()


func _draw() -> void:
	var at := Vector2(0, -8) + direction * 6.0
	draw_set_transform(at, direction.angle(), Vector2.ONE)
	draw_texture(GlacierSprites.BOW_DRAWN, Vector2(-8, -8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
