class_name Dunejaw
extends Enemy
## An eyeless eel-thing that swims under the Ossuary's dunes (layout
## letter A). Below the sand only a ripple shows, and blades pass over it.
## It closes on Wren; then a spout of sand and a dry rattle mark where it's
## about to burst up (the tell). It bites, and lies out on the sand a moment
## afterwards: that's when to strike.
##
## An elite (Room.elite) bites twice: after the first bite it drops straight
## back under, races after Wren and spouts again (a shorter rattle, pitched
## low) before it lies out.

enum Mode { BURROW, SPOUT, BITE, EXPOSED }

const BURROW_SPEED := 40.0
## It comes up right under Wren: they have the spout to step away.
const STRIKE_RANGE := 8.0
const SPOUT_TIME := 0.6
const BITE_TIME := 0.35
const EXPOSED_TIME := 1.1
const REST_TIME := 0.8
## An elite's second spout is this short, and it hunts at this speed.
const RESPOUT_TIME := 0.45
const HUNT_SPEED := 70.0
const HUNT_GIVE_UP := 1.5

var mode := Mode.BURROW
var _timer := 0.0
## An elite still has its second bite to come.
var _rebite := false


func _init() -> void:
	max_hp = 3
	body_size = Vector2(14, 8)


func _ready() -> void:
	super._ready()
	_set_mode(Mode.BURROW)
	_timer = REST_TIME


func _set_mode(next: Mode) -> void:
	mode = next
	_contact.active = mode == Mode.BITE
	# Under the sand it's no obstacle; up, it's in the way like any enemy.
	var buried := mode in [Mode.BURROW, Mode.SPOUT]
	set_deferred("collision_layer", 0 if buried else 1 << (Layers.ENEMY - 1))
	# Nothing to catch or cut under the sand (the Tide Hook included).
	_hurtbox.set_deferred("monitorable", not buried)
	match mode:
		Mode.SPOUT:
			_timer = SPOUT_TIME
		Mode.BITE:
			_timer = BITE_TIME
		Mode.EXPOSED:
			_timer = EXPOSED_TIME
		Mode.BURROW:
			_timer = REST_TIME


func _think(delta: float) -> void:
	_timer -= delta
	velocity = Vector2.ZERO
	match mode:
		Mode.BURROW:
			var player := get_player()
			# The second hunt gives up if Wren outruns it for long enough.
			if _rebite and _timer < -HUNT_GIVE_UP:
				_rebite = false
			if player == null or (_timer > 0.0 and not _rebite) or not _in_room(player):
				return
			var to := player.global_position - global_position
			if to.length() <= STRIKE_RANGE:
				_set_mode(Mode.SPOUT)
				if _rebite:
					_timer = RESPOUT_TIME
				Audio.play_sfx("jaw_rattle", global_position, 0.8 if _rebite else 1.0)
			else:
				velocity = to.normalized() * (HUNT_SPEED if _rebite else BURROW_SPEED)
		Mode.SPOUT:
			# It holds still where it will come up: step off the spot.
			if _timer <= 0.0:
				_set_mode(Mode.BITE)
				Audio.play_sfx("jaw_snap", global_position)
		Mode.BITE:
			if _timer <= 0.0:
				if elite and not _rebite:
					_rebite = true
					_set_mode(Mode.BURROW)
				else:
					_rebite = false
					_set_mode(Mode.EXPOSED)
		Mode.EXPOSED:
			if _timer <= 0.0:
				_set_mode(Mode.BURROW)
	var margin := Vector2(12, 12)
	position = position.clamp(margin, Room.SIZE - margin)


func _in_room(player: Node2D) -> bool:
	var room := get_parent() as Node2D
	return room != null and Rect2(Vector2.ZERO, Room.SIZE).has_point(player.global_position - room.global_position)


## Under the sand, a blade passes over it.
func take_hit(damage: int, direction: Vector2) -> HitResult:
	if mode in [Mode.BURROW, Mode.SPOUT]:
		return HitResult.IGNORED
	var result := super.take_hit(damage, direction)
	# Struck while out, it dives at once.
	if result == HitResult.HIT and not dying:
		_rebite = false
		_set_mode(Mode.BURROW)
	return result


func is_buried() -> bool:
	return mode in [Mode.BURROW, Mode.SPOUT]


func _make_sprite() -> Sprite2D:
	return Art.sprite(OssuarySprites.DUNEJAW, 4, 1, 18)


func _update_sprite() -> void:
	_sprite.frame = [0, 1, 2, 3][mode]
	if mode == Mode.SPOUT and ai_enabled:
		_jitter(_timer)
