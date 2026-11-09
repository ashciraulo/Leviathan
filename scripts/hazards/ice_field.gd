class_name IceField
extends Node2D
## Slick ice (layout letter x). On it Wren keeps sliding the way they were
## going and only slowly changes course; off it they have their footing back.
## The room adds one of these when its layout has any ice.

## How quickly Wren's slide turns toward where they're steering (per second).
const GRIP := 2.2
## How quickly a slide with no steering dies away (per second).
const FRICTION := 0.35

var momentum := Vector2.ZERO
var _room: Room
var _last := Vector2.INF


func _ready() -> void:
	_room = get_parent() as Room
	# Run after Wren has moved this frame, whichever was added first.
	process_physics_priority = 10


## Is this point (room-local) on ice?
func is_ice(local: Vector2) -> bool:
	return _room.tile_at(floori(local.x / Room.TILE), floori(local.y / Room.TILE)) == "x"


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var local := player.global_position - _room.global_position
	# A swing or a charge doesn't stop a slide; a knock sends them sliding.
	var sliding := player.state in [Player.State.MOVE, Player.State.ATTACK, Player.State.CHARGE] \
		and not player.frozen and not player.airborne and not player.in_cutscene \
		and Rect2(Vector2.ZERO, Room.SIZE).has_point(local) and is_ice(local)
	if not sliding:
		# Keep what they brought onto the ice, so they slide in from the edge.
		momentum = player.velocity if player.state in [Player.State.MOVE, Player.State.HURT] else Vector2.ZERO
		_last = Vector2.INF
		return
	if _last == Vector2.INF and momentum.length() > 20.0:
		# A hiss underfoot as Wren slides onto the ice.
		Audio.play_sfx("ice_slide", player.global_position)
	# The player script has already set velocity from the stick this frame
	# and moved them by it; replace that step with the slide.
	var steer := player.velocity
	if steer == Vector2.ZERO:
		momentum = momentum.move_toward(Vector2.ZERO, Player.SPEED * FRICTION * delta)
	else:
		momentum = momentum.lerp(steer, clampf(GRIP * delta, 0.0, 1.0))
	player.move_and_collide((momentum - steer) * delta)
	# Bumping a wall stops the slide along it.
	if _last != Vector2.INF and player.global_position.distance_to(_last) < 0.05 and momentum.length() > 5.0:
		momentum *= 0.5
	_last = player.global_position
