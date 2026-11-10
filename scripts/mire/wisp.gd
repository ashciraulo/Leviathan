class_name Wisp
extends Enemy
## A wisp: a leaked dream, a small pale flame. It drifts about, and goes
## straight for the Glowmoth Lantern's light when Wren raises it. One touch
## of the sword scatters it.

const DRIFT_SPEED := 20.0
const DRAWN_SPEED := 52.0

var _time := 0.0
var _drift := Vector2.RIGHT
var _light: PointLight2D


func _init() -> void:
	max_hp = 1
	body_size = Vector2(8, 6)


func _ready() -> void:
	super._ready()
	# Wisps float over the bog.
	collision_mask = 1 << (Layers.WORLD - 1)
	_time = randf() * TAU
	_light = Lantern.make_light(28.0, Color(0.75, 1.0, 0.9), 0.7)
	_light.position = Vector2(0, -12)
	add_child(_light)


func _think(delta: float) -> void:
	_time += delta
	var wren := get_player()
	if wren and wren.lantern_raised and wren.global_position.distance_to(global_position) < Lantern.reach(wren) * 2.0:
		velocity = (wren.global_position + Vector2(0, -8) - global_position).normalized() * DRAWN_SPEED
		return
	if int(_time * 0.7) != int((_time - delta) * 0.7):
		_drift = Vector2.from_angle(randf() * TAU)
	# They float over water, but never out of the room (a "clear" gate
	# would wait for one forever).
	var room := get_parent() as Node2D
	var local := position if room == null else global_position - room.global_position
	var inside := Rect2(Vector2(24, 24), Room.SIZE - Vector2(48, 40))
	if not inside.has_point(local):
		_drift = (inside.get_center() - local).normalized()
	velocity = _drift * DRIFT_SPEED


func _make_sprite() -> Sprite2D:
	return Art.sprite(MireSprites.WISP, 2, 1, 11)


func _update_sprite() -> void:
	_sprite.frame = int(_time * 5.0) % 2
	_sprite.position.y += -4.0 + sin(_time * 3.0) * 2.0
