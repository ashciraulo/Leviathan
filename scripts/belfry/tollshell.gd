class_name Tollshell
extends Enemy
## A little bell-shaped hermit (the Drowned Belfry), squatting on the nave
## floor. Shut, its bronze shell turns the sword (a clang). When Wren comes
## near it rattles and shivers (the tell), then tolls: a ring of sound
## rolls out round it and stings anything inside. After tolling it lifts
## its lip to look out, and that's the moment to strike. It never moves.

enum Mode { SHUT, RATTLE, TOLL, OPEN }

## How close Wren has to come before it starts to rattle.
const TRIGGER_RANGE := 40.0
const RATTLE_TIME := 0.75
const TOLL_TIME := 0.45
const OPEN_TIME := 1.5
## Rests shut a little after looking out, before it can toll again.
const REST_TIME := 0.9
## How far the ring of sound rolls out.
const RING_RADIUS := 34.0
const RING_COLOR := Color(0.72, 1.0, 0.9)

var mode := Mode.SHUT
var _timer := 0.0
var _ring: DamageArea
var _ring_shape: CircleShape2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 8)
	knockback_scale = 0.0


func _ready() -> void:
	super()
	_ring = DamageArea.new()
	_ring.name = "Toll"
	Layers.assign(_ring, Layers.ENEMY_ATTACK, [])
	_ring.monitoring = false
	var shape := CollisionShape2D.new()
	_ring_shape = CircleShape2D.new()
	_ring_shape.radius = 4.0
	shape.shape = _ring_shape
	shape.position = Vector2(0, -5)
	_ring.add_child(shape)
	add_child(_ring)
	_set_ring(false)


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	match mode:
		Mode.SHUT:
			var player := get_player()
			if _timer <= 0.0 and player != null and player.global_position.distance_to(global_position) < TRIGGER_RANGE:
				mode = Mode.RATTLE
				_timer = RATTLE_TIME
				Audio.play_sfx("toll_rattle", global_position)
		Mode.RATTLE:
			if _timer <= 0.0:
				mode = Mode.TOLL
				_timer = TOLL_TIME
				Audio.play_sfx("toll_ring", global_position)
				Feel.shake(0.8)
				_set_ring(true)
		Mode.TOLL:
			_ring_shape.radius = lerpf(4.0, RING_RADIUS, 1.0 - maxf(_timer, 0.0) / TOLL_TIME)
			queue_redraw()
			if _timer <= 0.0:
				_set_ring(false)
				mode = Mode.OPEN
				_timer = OPEN_TIME
		Mode.OPEN:
			if _timer <= 0.0:
				mode = Mode.SHUT
				_timer = REST_TIME
				Audio.play_sfx("shell_clack", global_position)


func _set_ring(on: bool) -> void:
	_ring.active = on
	_ring.set_deferred("monitorable", on)
	if not on:
		_ring_shape.radius = 4.0
	queue_redraw()


func is_open() -> bool:
	return mode == Mode.OPEN


func is_tolling() -> bool:
	return mode == Mode.TOLL


## Shut (or about to toll), the shell turns every blow.
func _blocks_hit(_direction: Vector2) -> bool:
	return mode != Mode.OPEN


func _die() -> void:
	_set_ring(false)
	super()


func _draw() -> void:
	if mode != Mode.TOLL:
		return
	# The toll rolling out: a bright ring, fading as it goes.
	var r := _ring_shape.radius
	var a := clampf(1.0 - r / RING_RADIUS, 0.0, 1.0) * 0.8 + 0.2
	draw_arc(Vector2(0, -5), r, 0.0, TAU, 32, Palette.CONTRAST_ENEMY if Settings.high_contrast else Color(RING_COLOR, a), 2.0)
	draw_arc(Vector2(0, -5), r * 0.7, 0.0, TAU, 28, Color(RING_COLOR, a * 0.4), 1.0)


func _make_sprite() -> Sprite2D:
	return Art.sprite(BelfrySprites.TOLLSHELL, 3, 1, 14)


func _update_sprite() -> void:
	match mode:
		Mode.RATTLE:
			_sprite.frame = 1
			if ai_enabled:
				_jitter(_timer)
		Mode.TOLL:
			_sprite.frame = 1
		Mode.OPEN:
			_sprite.frame = 2
		_:
			_sprite.frame = 0
