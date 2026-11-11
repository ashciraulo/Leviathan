class_name Galehawk
extends Enemy
## Diver (a slate-backed hawk of the heights). It circles high over the turf,
## out of reach, its shadow sweeping the ground. When Wren comes near it
## hangs over them with a shriek and its shadow stops (the tell), then
## stoops on the spot it marked. It sits there a moment, wings mantled over
## the turf, and that is the time to strike before it climbs again.

enum Mode { CIRCLE, MARK, STOOP, PERCH, CLIMB }

const HEIGHT := 30.0
const CIRCLE_SPEED := 1.1
const CIRCLE_RADIUS := 34.0
const SIGHT := 110.0
const MARK_TIME := 0.7
const STOOP_TIME := 0.3
const PERCH_TIME := 1.3
const CLIMB_TIME := 0.5
## Rest between dives, so a hawk never stoops twice in a row.
const REST := 1.6
const EDGE := 20.0

var mode := Mode.CIRCLE
var _timer := 0.0
var _rest := 0.0
var _angle := 0.0
var _home := Vector2.ZERO
var _from := Vector2.ZERO
var _mark := Vector2.ZERO
var _height := HEIGHT
var _grounded_mask := 0
var _grounded_layer := 0
var _hurtbox_layer := 0


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 8)


func _ready() -> void:
	super._ready()
	_home = _orbit_centre(position)
	_angle = fposmod(position.x * 0.13 + position.y * 0.07, TAU)
	_grounded_mask = collision_mask
	_grounded_layer = collision_layer
	_hurtbox_layer = _hurtbox.collision_layer
	_lift(true)


func airborne() -> bool:
	return mode != Mode.PERCH


func take_hit(damage: int, direction: Vector2) -> HitResult:
	if airborne():
		return HitResult.IGNORED
	return super.take_hit(damage, direction)


func _think(delta: float) -> void:
	_timer -= delta
	_rest = maxf(_rest - delta, 0.0)
	match mode:
		Mode.CIRCLE:
			_angle = fposmod(_angle + CIRCLE_SPEED * delta, TAU)
			var target := _home + Vector2.from_angle(_angle) * CIRCLE_RADIUS
			velocity = (target - position) * 4.0
			var player := get_player()
			if _rest <= 0.0 and player != null and global_position.distance_to(player.global_position) < SIGHT:
				var room := get_parent() as Room
				var spot := _inside(room.to_local(player.global_position)) if room != null else position
				if room == null or _can_land(room, spot):
					mode = Mode.MARK
					_timer = MARK_TIME
					_mark = spot
					Audio.play_sfx("hawk_shriek", global_position)
		Mode.MARK:
			# Hang over the mark: the shadow slides there and stops.
			velocity = (_mark - position) * 8.0
			if _timer <= 0.0:
				mode = Mode.STOOP
				_timer = STOOP_TIME
				position = _mark
				velocity = Vector2.ZERO
		Mode.STOOP:
			velocity = Vector2.ZERO
			_height = HEIGHT * maxf(_timer / STOOP_TIME, 0.0)
			if _timer <= 0.0:
				mode = Mode.PERCH
				_timer = PERCH_TIME
				_lift(false)
				Audio.play_sfx("wingbeat", global_position, 0.8)
		Mode.PERCH:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.CLIMB
				_timer = CLIMB_TIME
				_lift(true)
				Audio.play_sfx("wingbeat", global_position)
		Mode.CLIMB:
			velocity = Vector2.ZERO
			_height = HEIGHT * (1.0 - maxf(_timer / CLIMB_TIME, 0.0))
			if _timer <= 0.0:
				mode = Mode.CIRCLE
				_home = _orbit_centre(position)
				_angle = randf() * TAU
				_rest = REST


## Up in the air it flies over walls and water and can't touch or be touched:
## no body for burrs to bump, nothing for arrows or the hook to find. (Its
## contact stays monitorable, only inactive, so landing on Wren still hurts.)
func _lift(up: bool) -> void:
	collision_mask = 0 if up else _grounded_mask
	set_deferred("collision_layer", 0 if up else _grounded_layer)
	_hurtbox.set_deferred("collision_layer", 0 if up else _hurtbox_layer)
	_contact.active = not up
	_hurtbox.set_deferred("monitorable", not up)
	if not up:
		_height = 0.0


## Only open ground: it won't stoop into water, a chasm or a wall (Wren
## gliding over a gap is safe from it).
func _can_land(room: Room, spot: Vector2) -> bool:
	var tile := room.tile_at(int(spot.x) / Room.TILE, int(spot.y) / Room.TILE)
	return not tile in ["#", "~", "_", "^", "Q", ";", "I"]


## Keeps a point inside the room, clear of its edge.
func _inside(at: Vector2) -> Vector2:
	return at.clamp(Vector2(EDGE, EDGE + 8.0), Room.SIZE - Vector2(EDGE, EDGE))


## Where it circles: far enough in that the whole lap, and the bird drawn
## high above its shadow, stays on screen.
func _orbit_centre(at: Vector2) -> Vector2:
	var margin := Vector2(CIRCLE_RADIUS + 12.0, CIRCLE_RADIUS + 12.0)
	return at.clamp(margin + Vector2(0.0, HEIGHT), Room.SIZE - margin)


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.GALEHAWK, 3, 1, 13)


func _update_sprite() -> void:
	match mode:
		Mode.PERCH:
			_sprite.frame = 2
		Mode.STOOP:
			_sprite.frame = 1
		Mode.MARK:
			_sprite.frame = 0
			if ai_enabled:
				_jitter(_timer)
		_:
			_sprite.frame = 0
	_sprite.position.y -= _height
	_sprite.z_index = 2 if airborne() else 0
