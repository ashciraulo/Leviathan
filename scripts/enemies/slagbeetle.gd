class_name Slagbeetle
extends Enemy
## Charger (a beetle under a shell of cooled slag). Ambles about until Wren
## lines up with it, then its shell cracks open with ember light (the tell)
## and it charges straight along that line. The shell turns the sword. If
## the charge ends against a wall the beetle flips onto its back, belly up,
## and can be hit until it rights itself.

enum Mode { WANDER, CRACK, CHARGE, FLIPPED, REST }

const WANDER_SPEED := 16.0
const CHARGE_SPEED := 165.0
const SIGHT := 150.0
## How far off Wren's row or column still counts as lined up.
const LINE_SLACK := 10.0
const CRACK_TIME := 0.55
const CHARGE_TIME := 1.4
const FLIPPED_TIME := 1.8
const REST_TIME := 0.8
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
				_timer = randf_range(1.0, 2.0)
				_direction = WANDER_DIRECTIONS.pick_random()
			velocity = _direction * WANDER_SPEED
			var line := lined_up(player)
			if line != Vector2.ZERO:
				mode = Mode.CRACK
				_timer = CRACK_TIME
				_direction = line
				velocity = Vector2.ZERO
		Mode.CRACK:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.CHARGE
				_timer = CHARGE_TIME
		Mode.CHARGE:
			velocity = _direction * CHARGE_SPEED
			if get_slide_collision_count() > 0:
				mode = Mode.FLIPPED
				_timer = FLIPPED_TIME
				Feel.shake(2.0)
			elif _timer <= 0.0:
				_rest()
		Mode.FLIPPED:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_rest()
		Mode.REST:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.WANDER


## The cardinal direction to Wren if Wren is lined up and close, else zero.
func lined_up(player: Node2D) -> Vector2:
	if player == null:
		return Vector2.ZERO
	var to := player.global_position - global_position
	if to.length() > SIGHT:
		return Vector2.ZERO
	if absf(to.y) <= LINE_SLACK:
		return Vector2(signf(to.x), 0.0)
	if absf(to.x) <= LINE_SLACK:
		return Vector2(0.0, signf(to.y))
	return Vector2.ZERO


func is_flipped() -> bool:
	return mode == Mode.FLIPPED


func _blocks_hit(_direction_of_hit: Vector2) -> bool:
	return mode != Mode.FLIPPED


func _on_hurt() -> void:
	# A hit while belly up knocks it the rest of the way round.
	_rest()


func _rest() -> void:
	mode = Mode.REST
	_timer = REST_TIME


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.SLAGBEETLE, 4, 1, 11)


func _update_sprite() -> void:
	match mode:
		Mode.CRACK:
			_sprite.frame = 2
			if ai_enabled:
				_jitter(_timer)
		Mode.FLIPPED:
			_sprite.frame = 3
		Mode.CHARGE:
			_sprite.frame = int(Time.get_ticks_msec() / 50) % 2
		_:
			_sprite.frame = int(Time.get_ticks_msec() / 140) % 2 if velocity.length() > 1.0 else 0
