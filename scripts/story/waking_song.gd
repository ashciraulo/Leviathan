class_name WakingSong
extends Node2D
## Cutscene 18, "Vael's choir": the lullaby sung backwards. Where a Tidebell's
## phrase lifts off in warm notes (BellPhrase), the Waking Song's notes are
## cold, and fall: out of each singer's mouth, down, and into the floor,
## sinking towards the Old One with a ring where each goes under.

const NOTE := Color(0.72, 0.6, 1.0)
const EVERY := 0.55
const FALL := 1.3

## Where the voices are, in this node's space (mouths are drawn above).
var sources: Array[Vector2] = []
var _hushed: Array[bool] = []
var _time := 0.0
## Live notes: [source index, age, sideways drift].
var _notes: Array = []
var _next: Array[float] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 20
	for i in sources.size():
		_hushed.append(false)
		_next.append(randf_range(0.0, EVERY))


## One voice falls silent.
func hush(index: int) -> void:
	if index >= 0 and index < _hushed.size():
		_hushed[index] = true


func singing() -> int:
	return _hushed.count(false)


func _process(delta: float) -> void:
	var step := delta / Cutscene.scaled(1.0)
	_time += step
	for i in sources.size():
		if _hushed[i]:
			continue
		_next[i] -= step
		if _next[i] <= 0.0:
			_next[i] = EVERY * randf_range(0.8, 1.3)
			_notes.append([i, 0.0, (1.0 if randf() < 0.5 else -1.0) * randf_range(9.0, 15.0)])
	for note: Array in _notes:
		note[1] += step
	_notes = _notes.filter(func(note: Array) -> bool: return note[1] < FALL + 0.5)
	queue_redraw()


func _draw() -> void:
	for note: Array in _notes:
		var from: Vector2 = sources[note[0]] + Vector2(0, -24)
		var age: float = note[1]
		if age < FALL:
			var t := age / FALL
			# Out a little, then down: heavier as they fall.
			var at := from + Vector2(note[2] * sin(t * PI * 0.5), -8.0 * sin(t * PI) + 30.0 * t * t)
			var alpha := minf(1.0, t * 4.0) * 0.95
			draw_circle(at + Vector2(0, -2), 5.0, Color(NOTE, alpha * 0.2))
			draw_circle(at, 2.2, Color(NOTE, alpha))
			draw_line(at + Vector2(2.0, 0), at + Vector2(2.0, -7), Color(NOTE, alpha), 1.0)
			draw_line(at + Vector2(2.0, -7), at + Vector2(4.5, -5), Color(NOTE, alpha), 1.0)
		else:
			# Gone under: a ring spreading where it sank.
			var t := (age - FALL) / 0.5
			var at := from + Vector2(note[2], 22.0)
			draw_set_transform(at, 0.0, Vector2(1.0, 0.4))
			draw_arc(Vector2.ZERO, 3.0 + t * 8.0, 0.0, TAU, 16, Color(NOTE, 0.6 * (1.0 - t)), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
