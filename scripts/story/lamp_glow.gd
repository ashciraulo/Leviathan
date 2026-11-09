class_name LampGlow
extends Node2D
## A lamp signal: warm light that flashes once (yes), twice (no) or glows
## long ("I'm here"). Frees itself and emits `done` when finished.

signal done

## Each signal is a list of [on seconds, off seconds].
const PATTERNS := {
	"yes": [[0.35, 0.4]],
	"no": [[0.25, 0.25], [0.25, 0.4]],
	"here": [[1.8, 0.4]],
}
const RADIUS := 22.0

var kind := "yes"
var _level := 0.0
var _finished := false


func _init(signal_kind: String = "yes") -> void:
	kind = signal_kind


func _ready() -> void:
	z_index = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for step: Array in PATTERNS.get(kind, PATTERNS["yes"]):
		tween.tween_method(_set_level, 0.0, 1.0, Cutscene.scaled(0.08))
		tween.tween_interval(Cutscene.scaled(step[0]))
		tween.tween_method(_set_level, 1.0, 0.0, Cutscene.scaled(0.12))
		tween.tween_interval(Cutscene.scaled(step[1]))
	tween.finished.connect(_finish)


## Always signal the end, even when the room is torn down mid-glow (a death
## or fast travel), so a waiting scene never hangs.
func _exit_tree() -> void:
	if not _finished:
		_finished = true
		done.emit()


func _finish() -> void:
	queue_free()
	if not _finished:
		_finished = true
		done.emit()


func _set_level(value: float) -> void:
	_level = value
	queue_redraw()


func _draw() -> void:
	if _level <= 0.0:
		return
	# Stepped rings, so the glow stays pixel-art rather than a smooth blur.
	for i in 4:
		var r := RADIUS * (1.0 - i * 0.22)
		var color := Palette.KEY_TEXT
		color.a = (0.12 + i * 0.12) * _level
		draw_circle(Vector2(0, -12), r, color)
	draw_circle(Vector2(0, -12), 3.0, Color(1, 1, 0.9, _level))
