class_name Bogskipper
extends Enemy
## Ambusher (a Brinewood mudskipper). Lies buried with only its eyes showing,
## where it can't be hit. When Wren comes close it heaves up out of the mud,
## mouth open and shaking (the tell), then leaps at Wren. After a few hops
## around it burrows again.

enum Mode { HIDDEN, RISE, LEAP, HOP, BURROW }

const WAKE_RANGE := 56.0
const RISE_TIME := 0.5
const LEAP_TIME := 0.4
const LEAP_SPEED := 140.0
const LEAP_HEIGHT := 10.0
const HOP_TIME := 2.4
const HOP_SPEED := 36.0
const BURROW_TIME := 0.4

var mode := Mode.HIDDEN
var _timer := 0.0
var _direction := Vector2.ZERO
var _hop_phase := 0.0


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 8)


func _ready() -> void:
	super()
	_set_exposed(false)


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	match mode:
		Mode.HIDDEN:
			velocity = Vector2.ZERO
			if player and global_position.distance_to(player.global_position) < WAKE_RANGE:
				mode = Mode.RISE
				_timer = RISE_TIME
				_set_exposed(true)
		Mode.RISE:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.LEAP
				_timer = LEAP_TIME
				_direction = (player.global_position - global_position).normalized() if player else Vector2.DOWN
		Mode.LEAP:
			velocity = _direction * LEAP_SPEED
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				mode = Mode.HOP
				_timer = HOP_TIME
		Mode.HOP:
			_hop_phase += delta
			if int(_hop_phase / 0.5) != int((_hop_phase - delta) / 0.5):
				_direction = Vector2.from_angle(randf() * TAU)
			velocity = _direction * HOP_SPEED if fmod(_hop_phase, 0.5) < 0.25 else Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.BURROW
				_timer = BURROW_TIME
		Mode.BURROW:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.HIDDEN
				_set_exposed(false)


## Hidden in the mud: no contact damage and nothing for the sword to hit.
func _set_exposed(exposed: bool) -> void:
	_contact.active = exposed
	_hurtbox.set_deferred("monitorable", exposed)


func is_exposed() -> bool:
	return mode != Mode.HIDDEN


func _on_hurt() -> void:
	# Knocked out of a leap: flop about, then dig back in.
	if mode == Mode.LEAP or mode == Mode.RISE:
		mode = Mode.HOP
		_timer = HOP_TIME


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.BOGSKIPPER, 3, 1, 12)


func _update_sprite() -> void:
	match mode:
		Mode.HIDDEN:
			_sprite.frame = 0
		Mode.RISE:
			_sprite.frame = 1
			if ai_enabled:
				_jitter(_timer)
		Mode.BURROW:
			_sprite.frame = 1
		Mode.LEAP:
			_sprite.frame = 2
			var t := 1.0 - _timer / LEAP_TIME
			_sprite.position.y -= roundf(sin(t * PI) * LEAP_HEIGHT)
		Mode.HOP:
			_sprite.frame = 2
			var p := fmod(_hop_phase, 0.5) / 0.25
			if p < 1.0:
				_sprite.position.y -= roundf(sin(p * PI) * 3.0)


func take_hit(damage: int, direction: Vector2) -> HitResult:
	if mode == Mode.HIDDEN:
		return HitResult.IGNORED
	return super(damage, direction)
