class_name Scuttler
extends Enemy
## Chaser (a shore crab). Wanders, then crouches and flashes yellow (the tell)
## before dashing in a straight line at Wren.

enum Mode { WANDER, WINDUP, DASH, REST }

const WANDER_SPEED := 24.0
const DASH_SPEED := 150.0
const SIGHT := 96.0
const WINDUP_TIME := 0.45
const DASH_TIME := 0.35
const REST_TIME := 0.7
const WANDER_DIRECTIONS := [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var mode := Mode.WANDER
var _timer := 0.0
var _direction := Vector2.ZERO


func _init() -> void:
	max_hp = 2
	body_size = Vector2(14, 8)


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	match mode:
		Mode.WANDER:
			if _timer <= 0.0:
				_timer = randf_range(0.8, 1.6)
				_direction = WANDER_DIRECTIONS.pick_random()
			velocity = _direction * WANDER_SPEED
			if player and global_position.distance_to(player.global_position) < SIGHT:
				mode = Mode.WINDUP
				_timer = WINDUP_TIME
				velocity = Vector2.ZERO
		Mode.WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.DASH
				_timer = DASH_TIME
				_direction = (player.global_position - global_position).normalized() if player else Vector2.DOWN
		Mode.DASH:
			velocity = _direction * DASH_SPEED
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				_rest()
		Mode.REST:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.WANDER


func _on_hurt() -> void:
	_rest()


func _rest() -> void:
	mode = Mode.REST
	_timer = REST_TIME


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.SCUTTLER, 3, 1, 11)


func _update_sprite() -> void:
	if mode == Mode.WINDUP and ai_enabled:
		_sprite.frame = 2
		_jitter(_timer)
	elif velocity.length() > 1.0:
		_sprite.frame = int(Time.get_ticks_msec() / 90) % 2
	else:
		_sprite.frame = 0
