class_name Lanternmoth
extends Enemy
## Flyer (a big dusty moth drawn to Wren's lantern). Drifts about its home,
## circles Wren once it spots the light, then stops and its eye-spots flare
## amber (the tell) before it dives at where Wren stood. Flies over water.

enum Mode { DRIFT, CIRCLE, FLARE, DIVE, RETREAT }

const DRIFT_SPEED := 20.0
const CIRCLE_SPEED := 70.0
const CIRCLE_RADIUS := 38.0
const CIRCLE_TIME := 1.4
const FLARE_TIME := 0.5
const DIVE_SPEED := 165.0
const DIVE_TIME := 0.38
const RETREAT_SPEED := 60.0
const RETREAT_TIME := 0.7
const SIGHT := 104.0
## How high it flies above its shadow, in pixels.
const HOVER := 9.0

var mode := Mode.DRIFT
var _timer := 0.0
var _home := Vector2.ZERO
var _angle := 0.0
var _direction := Vector2.ZERO
var _wing := 0.0


func _init() -> void:
	max_hp = 1
	body_size = Vector2(12, 6)


func _ready() -> void:
	super()
	_home = position
	_angle = randf() * TAU
	# Flying: walls stop it, water doesn't.
	Layers.assign(self, Layers.ENEMY, [Layers.WORLD, Layers.ENEMY])


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	var to_player := Vector2.ZERO if player == null else player.global_position - global_position
	match mode:
		Mode.DRIFT:
			_angle += delta * 0.9
			var target := _home + Vector2(cos(_angle), sin(_angle * 2.0) * 0.5) * 20.0
			velocity = (target - position).limit_length(DRIFT_SPEED)
			if player and to_player.length() < SIGHT:
				mode = Mode.CIRCLE
				_timer = CIRCLE_TIME
				_angle = (-to_player).angle()
		Mode.CIRCLE:
			if player == null:
				mode = Mode.DRIFT
				return
			_angle += delta * CIRCLE_SPEED / CIRCLE_RADIUS
			var spot := player.global_position + Vector2.from_angle(_angle) * CIRCLE_RADIUS
			velocity = (spot - global_position).limit_length(CIRCLE_SPEED)
			if _timer <= 0.0:
				mode = Mode.FLARE
				_timer = FLARE_TIME
		Mode.FLARE:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.DIVE
				_timer = DIVE_TIME
				_direction = to_player.normalized() if to_player != Vector2.ZERO else Vector2.DOWN
		Mode.DIVE:
			velocity = _direction * DIVE_SPEED
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				_retreat()
		Mode.RETREAT:
			velocity = -_direction * RETREAT_SPEED
			if _timer <= 0.0:
				mode = Mode.CIRCLE if player and to_player.length() < SIGHT * 1.3 else Mode.DRIFT
				_timer = CIRCLE_TIME
				_home = position if mode == Mode.DRIFT else _home


func _on_hurt() -> void:
	_retreat()


func _retreat() -> void:
	mode = Mode.RETREAT
	_timer = RETREAT_TIME


func is_flaring() -> bool:
	return mode == Mode.FLARE


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.LANTERNMOTH, 3, 1, 9)


func _update_sprite() -> void:
	_wing += get_physics_process_delta_time()
	# Bob in the air above the shadow.
	_sprite.position.y -= HOVER + (1.0 if int(_wing * 4.0) % 2 == 0 else 0.0)
	if mode == Mode.FLARE and ai_enabled:
		_sprite.frame = 2
		_jitter(_timer)
	else:
		var flap := 0.06 if mode == Mode.DIVE else 0.12
		_sprite.frame = int(_wing / flap) % 2
