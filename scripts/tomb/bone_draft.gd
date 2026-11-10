class_name BoneDraft
extends Node2D
## The thin drift of bone dust that leaks from a concealed bone wall's seam
## (see BoneWall). A handful of motes drawn by hand: a CPUParticles2D looked
## the same, but in the web build it stalled the game for a fifth of a
## second every second or so.

const COUNT := 9
const LIFETIME := 2.4
const SPREAD := deg_to_rad(25.0)
const GRAVITY := Vector2(0, 2)
const SPEED_MIN := 6.0
const SPEED_MAX := 11.0
const COLOR := Color(0.94, 0.9, 0.8)
## How opaque a mote is at its brightest (a fifth of the way through its life).
const PEAK := 0.95

## Which way the air comes out (into the room).
var direction := Vector2.RIGHT
## Half the size of the seam the dust leaks along.
var extents := Vector2(1, 6)

var _at := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := PackedFloat32Array()
var _size := PackedInt32Array()


func _ready() -> void:
	_at.resize(COUNT)
	_vel.resize(COUNT)
	_age.resize(COUNT)
	_size.resize(COUNT)
	# Already drifting when the room opens, each mote at its own point in life.
	for i in COUNT:
		_spawn(i)
		var head := LIFETIME * i / COUNT
		_age[i] = head
		_at[i] += _vel[i] * head + GRAVITY * head * head * 0.5
		_vel[i] += GRAVITY * head


func _spawn(i: int) -> void:
	_at[i] = Vector2(randf_range(-extents.x, extents.x), randf_range(-extents.y, extents.y))
	_vel[i] = direction.rotated(randf_range(-SPREAD, SPREAD)) * randf_range(SPEED_MIN, SPEED_MAX)
	_age[i] = 0.0
	_size[i] = randi_range(1, 2)


func _process(delta: float) -> void:
	for i in COUNT:
		_age[i] += delta
		if _age[i] >= LIFETIME:
			_spawn(i)
			continue
		_vel[i] += GRAVITY * delta
		_at[i] += _vel[i] * delta
	queue_redraw()


func _draw() -> void:
	for i in COUNT:
		var t := _age[i] / LIFETIME
		var a := PEAK * (t / 0.2 if t < 0.2 else (1.0 - t) / 0.8)
		if a <= 0.02:
			continue
		var s := _size[i]
		draw_rect(Rect2(_at[i].floor(), Vector2(s, s)), Color(COLOR, a))
