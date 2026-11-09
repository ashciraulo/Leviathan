class_name CalfOfLights
extends Node2D
## Cutscene 9, "The calf in the lights": once the Pale Congregation is laid
## to rest, its wisps drift back together one last time, quietly, into the
## shape of a leviathan calf, hang there, then scatter home to the fen's
## lanterns. Uses the Congregation's own outline (PaleCongregation.calf_shape).

const SCALE := 1.5
const GATHER_TIME := 2.4
const SCATTER_TIME := 1.8
const WISP_SIZE := Vector2(10, 12)
const GLOW := Color(0.56, 0.89, 0.78, 0.2)

var _slots: Array[Vector2] = []
var _from: Array[Vector2] = []
var _to: Array[Vector2] = []
var _progress := 0.0
var _fade := 1.0
var _time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4
	var outline := PaleCongregation.calf_shape()
	# Fill the body's ring in: a point between each pair round the body.
	for i in 12:
		outline.append((outline[i] + outline[(i + 1) % 12]) / 2.0)
	outline.append(Vector2(14, -3))  # the eye
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for point in outline:
		_slots.append(point * SCALE)
		# Each drifts in from somewhere round the room's edge, low and dim.
		var angle := rng.randf() * TAU
		_from.append(Vector2.from_angle(angle) * Vector2(220, 130))
		_to.append(_from.back())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## The wisps drift in and take the calf's shape.
func gather() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_progress", 1.0, Cutscene.scaled(GATHER_TIME))
	await tween.finished


## They let go of the shape and scatter outwards, fading.
func scatter() -> void:
	for i in _slots.size():
		_from[i] = _slots[i]
		_to[i] = _slots[i] + _slots[i].normalized() * 160.0 + Vector2(0, -40)
	_progress = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(self, "_progress", 1.0, Cutscene.scaled(SCATTER_TIME)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_fade", 0.0, Cutscene.scaled(SCATTER_TIME))
	await tween.finished
	queue_free()


func _draw() -> void:
	var gathered := _from[0] != _slots[0]
	for i in _slots.size():
		var at: Vector2
		if gathered:
			at = _from[i].lerp(_slots[i], _progress)
		else:
			at = _from[i].lerp(_to[i], _progress)
		# Swimming: a slow wave runs down the body from head to tail.
		at.y += sin(_time * 2.0 + at.x * 0.06) * 1.5 * (_progress if gathered else 1.0 - _progress)
		at = at.round()
		var bright := (0.4 + 0.6 * _progress if gathered else 1.0) * _fade
		draw_circle(at, 7.0, Color(GLOW, GLOW.a * bright))
		var frame := (int(_time * 5.0) + i) % 2
		draw_texture_rect_region(MireSprites.WISP, Rect2(at - Vector2(5, 8), WISP_SIZE),
			Rect2(frame * WISP_SIZE.x, 0, WISP_SIZE.x, WISP_SIZE.y), Color(1, 1, 1, bright))
