class_name MantleSwoop
extends Node2D
## Mantle sweeping low over the play area to pick Wren up or set her down:
## the ray flies in from the upper left, skims just above her, and climbs
## away to the upper right. Its shadow slides along the ground beneath.
## `passed` fires as Mantle is right over her; `finished` once it is gone.

signal passed
signal finished

const TIME := 1.6
const FRAMES := 4
const FPS := 9.0
const FRAME_SIZE := Vector2(96, 80)
## How far outside the view Mantle starts and ends.
const MARGIN := Vector2(64, 56)
## How high above Wren Mantle passes.
const LOW := 14.0

var target := Vector2.ZERO
var _t := 0.0
var _passed := false
var _control := Vector2.ZERO
var _from := Vector2.ZERO
var _to := Vector2.ZERO


static func make(at: Vector2) -> MantleSwoop:
	var swoop := MantleSwoop.new()
	swoop.target = at
	return swoop


func _ready() -> void:
	z_as_relative = false
	z_index = 100
	# From beyond the view's top left to beyond its top right, so Mantle
	# never pops in or out on screen.
	var view := get_viewport_rect().size
	var center := target
	var camera := get_viewport().get_camera_2d()
	if camera:
		# The camera may have just jumped to a new room this frame.
		camera.force_update_scroll()
		center = camera.get_screen_center_position()
	var top_left := center - view / 2.0
	_from = Vector2(top_left.x - MARGIN.x, top_left.y - MARGIN.y)
	_to = Vector2(top_left.x + view.x + MARGIN.x, top_left.y - MARGIN.y)
	# A quadratic curve through the low point halfway along.
	var low := target + Vector2(0, -LOW)
	_control = 2.0 * low - (_from + _to) / 2.0
	Audio.play_sfx("mantle_wings", target)
	queue_redraw()


func _process(delta: float) -> void:
	_t = minf(_t + delta / TIME, 1.0)
	if not _passed and _t >= 0.5:
		_passed = true
		Audio.play_sfx("mantle_wings", target, 0.85)
		passed.emit()
	queue_redraw()
	if _t >= 1.0:
		finished.emit()
		queue_free()


func _point(t: float) -> Vector2:
	return _from.lerp(_control, t).lerp(_control.lerp(_to, t), t)


func _draw() -> void:
	var pos := _point(_t) - global_position
	var height := target.y - _point(_t).y
	# The shadow on the ground, softer and wider the higher Mantle is.
	var ground := Vector2(pos.x + height * 0.15, target.y - global_position.y + 2.0).round()
	var spread := 1.0 + height / 160.0
	draw_set_transform(ground, 0.0, Vector2(1.6 * spread, 0.55 * spread))
	var edge := clampf(minf(_t, 1.0 - _t) * 6.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, 22.0, Color(0.05, 0.04, 0.12, 0.32 / spread * edge))
	# Mantle, unrotated so its pixels stay crisp.
	draw_set_transform(pos.round(), 0.0, Vector2.ONE)
	var frame := int(_t * TIME * FPS) % FRAMES
	draw_texture_rect_region(Art.MANTLE, Rect2(-FRAME_SIZE / 2.0, FRAME_SIZE),
		Rect2(Vector2(frame * FRAME_SIZE.x, 0), FRAME_SIZE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
