class_name Sledgeseal
extends Enemy
## Slider (a stocky seal of the glacier shore). It lolls about until Wren
## lines up with it, rears up (the tell), then throws itself onto its belly
## and toboggans straight at them, sliding on until it hits something. On
## its belly it can't turn: step aside and strike its flank as it passes or
## while it lies winded against the wall.

enum Mode { IDLE, REAR, SLIDE, WINDED }

const WANDER_SPEED := 12.0
const SLIDE_SPEED := 150.0
const SIGHT := 140.0
const LINE_SLACK := 12.0
const REAR_TIME := 0.6
const SLIDE_MAX := 2.0
const WINDED_TIME := 1.2

var mode := Mode.IDLE
var _timer := 0.0
var _direction := Vector2.ZERO
var _wander := Vector2.ZERO


func _init() -> void:
	max_hp = 3
	body_size = Vector2(16, 9)


func _think(delta: float) -> void:
	_timer -= delta
	match mode:
		Mode.IDLE:
			if _timer <= 0.0:
				_timer = randf_range(1.2, 2.4)
				_wander = [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT].pick_random()
			velocity = _wander * WANDER_SPEED
			var line := _lined_up(get_player())
			if line != Vector2.ZERO:
				mode = Mode.REAR
				_timer = REAR_TIME
				_direction = line
				velocity = Vector2.ZERO
				Audio.play_sfx("seal_bark", global_position)
		Mode.REAR:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.SLIDE
				_timer = SLIDE_MAX
		Mode.SLIDE:
			velocity = _direction * SLIDE_SPEED
			if get_slide_collision_count() > 0 or _timer <= 0.0:
				mode = Mode.WINDED
				_timer = WINDED_TIME
				velocity = Vector2.ZERO
		Mode.WINDED:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.IDLE


func _lined_up(player: Node2D) -> Vector2:
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


## A blow straight on, into its face as it slides, glances off its blubber.
func _blocks_hit(direction: Vector2) -> bool:
	return mode == Mode.SLIDE and direction.dot(_direction) < -0.7


func is_sliding() -> bool:
	return mode == Mode.SLIDE


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.SLEDGESEAL, 3, 1, 12)


func _update_sprite() -> void:
	match mode:
		Mode.REAR:
			_sprite.frame = 1
			if ai_enabled:
				_jitter(_timer)
		Mode.SLIDE:
			_sprite.frame = 2
			_sprite.flip_h = _direction.x < 0.0
		_:
			_sprite.frame = 0
