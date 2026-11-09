class_name Sporecap
extends Enemy
## Area denial (a waddling glowcap toadstool). It drifts about the fen; when
## Wren comes close its cap swells and its spots turn pink (the tell), then
## it bursts a ring of stinging spores around itself. Afterwards it sags,
## spent, for a moment: the time to strike. Hitting it before then is fine
## too, but it makes it burst at once.

enum Mode { WANDER, SWELL, BURST, SPENT }

const WANDER_SPEED := 14.0
## How close Wren has to come before it swells.
const TRIGGER_RANGE := 34.0
const SWELL_TIME := 0.6
const BURST_TIME := 0.5
const SPENT_TIME := 1.6
## Radius of the spore ring.
const CLOUD_RADIUS := 26.0
const WANDER_DIRECTIONS := [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var mode := Mode.WANDER
var _timer := 0.0
var _direction := Vector2.ZERO
var _cloud: DamageArea
var _cloud_sprite: Sprite2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(10, 7)


func _ready() -> void:
	super()
	_cloud = DamageArea.new()
	_cloud.name = "Spores"
	Layers.assign(_cloud, Layers.ENEMY_ATTACK, [])
	_cloud.monitoring = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = CLOUD_RADIUS
	shape.shape = circle
	shape.position = Vector2(0, -6)
	_cloud.add_child(shape)
	add_child(_cloud)
	_cloud_sprite = Art.sprite(Art.SPORE_CLOUD, 3, 1, 29)
	_cloud_sprite.z_index = 4
	_cloud_sprite.visible = false
	add_child(_cloud_sprite)
	_set_cloud(false)


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	match mode:
		Mode.WANDER:
			if _timer <= 0.0:
				_timer = randf_range(1.2, 2.4)
				_direction = WANDER_DIRECTIONS.pick_random()
			velocity = _direction * WANDER_SPEED
			if player != null and player.global_position.distance_to(global_position) < TRIGGER_RANGE:
				_swell()
		Mode.SWELL:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_burst()
		Mode.BURST:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_set_cloud(false)
				mode = Mode.SPENT
				_timer = SPENT_TIME
		Mode.SPENT:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.WANDER


func _swell() -> void:
	mode = Mode.SWELL
	_timer = SWELL_TIME
	velocity = Vector2.ZERO


func _burst() -> void:
	mode = Mode.BURST
	_timer = BURST_TIME
	_set_cloud(true)


func _set_cloud(on: bool) -> void:
	_cloud.set_deferred("monitorable", on)
	_cloud.active = on
	_cloud_sprite.visible = on


func is_bursting() -> bool:
	return mode == Mode.BURST


func is_spent() -> bool:
	return mode == Mode.SPENT


func _on_hurt() -> void:
	# Struck while still full of spores: it bursts at once.
	if mode == Mode.WANDER or mode == Mode.SWELL:
		_burst()


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.SPORECAP, 4, 1, 13)


func _update_sprite() -> void:
	match mode:
		Mode.SWELL:
			_sprite.frame = 2
			if ai_enabled:
				_jitter(_timer)
		Mode.BURST:
			_sprite.frame = 2
			_cloud_sprite.frame = clampi(int((1.0 - _timer / BURST_TIME) * 3.0), 0, 2)
		Mode.SPENT:
			_sprite.frame = 3
		_:
			_sprite.frame = int(Time.get_ticks_msec() / 180) % 2 if velocity.length() > 1.0 else 0
