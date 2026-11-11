class_name KiteCloak
extends Node2D
## The Kite Cloak, Gale Spire's tool. Wren throws it open overhead and
## glides straight ahead: holes in the floor, water and low hazards pass
## underneath. On their own they only carry a few tiles; in a fan's stream
## the wind takes them along and keeps them up as long as they stay in it.
## They can lean left and right a little, and fold the cloak (the item key
## again) to come down early. When the glide ends they drop where they are
## (into the sky, if that's where they are). A glide never comes down on
## water: ending over it, Wren drops back where they took off, a bubble
## lighter. Only a stream can carry them across wide water.
##
## Lives as a child of Wren while in use, and frees itself when done.

const SPEED := 95.0
## How long Wren stays up on their own (seconds).
const GLIDE_TIME := 0.75
## Riding a stream keeps at least this much glide in hand...
const LIFT_TIME := 0.3
## ...but no glide lasts longer than this.
const MAX_TIME := 4.0
const STEER := 140.0
## How strongly a stream carries Wren compared with walking.
const WIND_SCALE := 1.6

var _player: Player
var _left := GLIDE_TIME
var _time := 0.0
var _velocity := Vector2.ZERO
var _lift := 0.0
var _stuck := 0.0
var _from := Vector2.ZERO


func _ready() -> void:
	_player = get_parent() as Player
	_velocity = _player.facing * SPEED
	_from = _player.global_position
	_player.airborne = true
	# Over water and holes alike: only walls stop Wren.
	_player.collision_mask = Player.AIR_MASK
	z_index = 2
	Audio.play_sfx("cloak_open", _player.global_position)


func _physics_process(delta: float) -> void:
	if _player == null or not _player.is_using_item():
		_land()
		return
	_time += delta
	_left -= delta
	var wind := WindFan.wind_at(get_tree(), _player.global_position + Vector2(0, -4))
	if wind != Vector2.ZERO:
		_left = maxf(_left, LIFT_TIME)
	# Lean across the way they're going.
	var steer := _player.steer_input()
	var across := Vector2(-_velocity.y, _velocity.x).normalized()
	_velocity += across * across.dot(steer) * STEER * delta
	_velocity = _velocity.normalized() * SPEED
	_player.item_velocity = _velocity + wind * WIND_SCALE
	_lift = minf(_lift + delta * 6.0, 1.0)
	queue_redraw()
	# The item key again folds the cloak and drops Wren where they are.
	var fold := _time > 0.15 and (Input.is_action_just_pressed("item_1") or Input.is_action_just_pressed("item_2"))
	# Blown up against a wall, there's nowhere to go but down.
	_stuck = _stuck + delta if _time > 0.1 and _player.get_real_velocity().length() < 20.0 else 0.0
	if _left <= 0.0 or _time >= MAX_TIME or fold or _stuck > 0.2:
		if not _over_water():
			_land()
		else:
			# Out of glide over water: no carrying on to the far bank on
			# their own, Wren drops back where they took off.
			_land()
			_player.fall(_from)


func _over_water() -> bool:
	var at := _player.global_position + Vector2(0, -3)
	var room := Room.under(get_tree(), at)
	if room == null:
		return false
	var local := at - room.global_position
	var cell := Vector2i(floori(local.x / Room.TILE), floori(local.y / Room.TILE))
	var tile := room.tile_at(cell.x, cell.y)
	# Tide flats and the sea bed count as water while they're under.
	var tide := room.get_node_or_null("Tide") as Tide
	if tide != null and tide.is_flooded(cell):
		return true
	# A veiled plank the lantern isn't showing is no footing either.
	if tile == "v":
		for plank: VeilPlank in get_tree().get_nodes_in_group("veil_planks"):
			if plank.get_parent() == room and Vector2i(floori(plank.position.x / Room.TILE), floori(plank.position.y / Room.TILE)) == cell:
				return not plank.is_real()
		return true
	return tile == "~" or (tile == "Q" and not GameState.has_item("divers_helm"))


func _land() -> void:
	if _player and is_instance_valid(_player):
		_player.airborne = false
		_player.collision_mask = _player.ground_mask()
		if _player.is_using_item():
			_player.end_item()
	queue_free()


func _draw() -> void:
	# The cloak spread over Wren's head, rocking a little in the air.
	var rock := sin(_time * 7.0) * 1.5
	var at := Vector2(-14, -34 - 4.0 * _lift + rock * 0.3)
	draw_set_transform(Vector2(0, -24), rock * 0.03, Vector2.ONE)
	draw_texture(GaleSprites.CLOAK_OPEN, at - Vector2(0, -24))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
