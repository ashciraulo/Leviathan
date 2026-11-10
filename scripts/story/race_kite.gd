class_name RaceKite
extends Node2D
## Captain Sorrel's courier kite, racing Wren across Gullwatch Steps to the
## far post (StoryDirector.sorrel_race). It flies its route in `duration`
## seconds, high over the water with its shadow on the ground below, and
## settles on the post when it gets there (`arrived`).

const SAIL := Color("#e2574c")
const SAIL_LIGHT := Color("#ff9a7a")
const SPAR := Color("#7a5240")
const TAIL := Color("#fff4d6")
## How high it flies above its shadow.
const HEIGHT := 22.0

## Points in the room the kite flies through, start to finish.
var route: Array = []
var duration := 3.0
var arrived := false
## Once the race is lost or won it drifts down: 0 aloft, 1 landed.
var _settle := 0.0
var _time := 0.0
var _flown := 0.0
var _length := 0.0


func _ready() -> void:
	z_index = 3
	for i in range(1, route.size()):
		_length += (route[i] as Vector2).distance_to(route[i - 1])
	if not route.is_empty():
		position = route[0]


func _process(delta: float) -> void:
	_time += delta
	if not arrived:
		_flown = minf(_flown + delta, duration)
		position = _along(_flown / duration)
		if _flown >= duration:
			arrived = true
	else:
		_settle = minf(_settle + delta * 1.6, 1.0)
		# Gathered in: it fades as it comes down.
		modulate.a = 1.0 - _settle * 0.8
	queue_redraw()


## Where the kite is a fraction `t` of the way along its route.
func _along(t: float) -> Vector2:
	var want := t * _length
	for i in range(1, route.size()):
		var a: Vector2 = route[i - 1]
		var b: Vector2 = route[i]
		var leg := a.distance_to(b)
		if want <= leg or i == route.size() - 1:
			return a.lerp(b, clampf(want / maxf(leg, 0.001), 0.0, 1.0))
		want -= leg
	return route[-1]


func _draw() -> void:
	var lift := HEIGHT * (1.0 - _settle) + 6.0 * _settle
	# Its shadow on the ground (or the water) below.
	draw_circle(Vector2(0, 0), 4.0 * (1.0 - _settle * 0.5), Color(0.1, 0.08, 0.15, 0.3))
	var bob := sin(_time * 5.0) * 1.5 * (1.0 - _settle)
	var at := Vector2(0, -lift + bob)
	var tilt := sin(_time * 3.0) * 0.15 * (1.0 - _settle)
	draw_set_transform(at, tilt, Vector2.ONE)
	# The tail streams out behind, flicking.
	var tail := PackedVector2Array()
	for i in 6:
		tail.append(Vector2(-2.0 - i * 2.5, 5.0 + i * 1.2 + sin(_time * 10.0 + i) * 1.5))
	draw_polyline(PackedVector2Array([Vector2(0, 5)]) + tail, Palette.OUTLINE, 1.0)
	for i in range(1, tail.size(), 2):
		draw_rect(Rect2(tail[i] - Vector2(1, 1), Vector2(2, 2)), TAIL)
	# A diamond of red sailcloth on a cross of spars.
	var outline := PackedVector2Array([Vector2(0, -7), Vector2(6, -1), Vector2(0, 6), Vector2(-6, -1)])
	draw_colored_polygon(outline, Palette.OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(5, -1), Vector2(0, 5), Vector2(-5, -1)]), SAIL)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(5, -1), Vector2(0, -1)]), SAIL_LIGHT)
	draw_line(Vector2(0, -6), Vector2(0, 5), SPAR, 1.0)
	draw_line(Vector2(-5, -1), Vector2(5, -1), SPAR, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
