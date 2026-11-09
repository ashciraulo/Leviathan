class_name GameOverScreen
extends CanvasLayer
## Shown when Wren runs out of breath: she drifts down through dark water
## among rising bubbles, and the player picks Wake at the Tidestone (back
## to the last save) or Return to the title.

signal chosen(wake: bool)

const OPTIONS := ["GAMEOVER_WAKE", "GAMEOVER_TITLE"]
## Input is ignored this long, so a button mashed at the moment of death
## doesn't pick an option.
const INPUT_DELAY := 0.8
const TOP := Color("#0c2238")
const BOTTOM := Color("#03070f")
const BUBBLE := Color("#a8e6cf")

var _time := 0.0
var _cursor := 0
var _done := false
var _canvas: Control
var _bubbles: Array[Vector3] = []


func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 7
	for i in 24:
		# x, start y, speed
		_bubbles.append(Vector3(rnd.randf_range(8, 376), rnd.randf_range(0, 216), rnd.randf_range(10, 28)))
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_screen)
	add_child(_canvas)


func _process(delta: float) -> void:
	_time += delta
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	# The pause menu and Wren must not see input while this is up.
	if event is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if _done or _time < INPUT_DELAY:
		return
	var dir := MenuKit.direction(event)
	if dir.y != 0:
		_cursor = clampi(_cursor + dir.y, 0, OPTIONS.size() - 1)
		Audio.play_sfx("ui_move")
	elif MenuKit.confirm(event):
		_done = true
		Audio.play_sfx("ui_select")
		chosen.emit(_cursor == 0)


func _draw_screen() -> void:
	# Deep water, lighter towards the surface.
	for y in range(0, 216, 4):
		_canvas.draw_rect(Rect2(0, y, 384, 4), TOP.lerp(BOTTOM, y / 216.0))
	# Bubbles rising and wobbling.
	for b in _bubbles:
		var y := fposmod(b.y - _time * b.z, 232.0) - 8.0
		var x := roundf(b.x + sin(_time * 1.7 + b.y) * 2.0)
		var color := BUBBLE
		color.a = 0.25 + 0.35 * (1.0 - y / 216.0)
		var at := Vector2(x, roundf(y))
		if b.z < 18.0:
			_canvas.draw_rect(Rect2(at, Vector2(1, 1)), color)
		else:
			# A 4x4 ring with the corners left out.
			_canvas.draw_rect(Rect2(at + Vector2(1, 0), Vector2(2, 1)), color)
			_canvas.draw_rect(Rect2(at + Vector2(1, 3), Vector2(2, 1)), color)
			_canvas.draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, 2)), color)
			_canvas.draw_rect(Rect2(at + Vector2(3, 1), Vector2(1, 2)), color)
			_canvas.draw_rect(Rect2(at + Vector2(1, 1), Vector2(1, 1)), Color(1, 1, 1, color.a))
	# Wren drifting down, the light above fading.
	var fall := minf(_time / 2.5, 1.0)
	var wren_y := roundf(70.0 + fall * 18.0 + sin(_time * 1.2) * 1.5)
	_canvas.draw_texture_rect_region(Art.WREN, Rect2(184, wren_y, 16, 24),
		Rect2(0, 0, 16, 24), Color(0.55, 0.65, 0.85, 1.0))
	var fade := clampf(_time / INPUT_DELAY, 0.0, 1.0)
	MenuKit.draw_text(_canvas, "GAMEOVER_TITLE_TEXT", Vector2(0, 30), Color(MenuKit.TEXT, fade),
		HORIZONTAL_ALIGNMENT_CENTER, 384)
	for i in OPTIONS.size():
		var active := i == _cursor
		var text := _canvas.tr(OPTIONS[i])
		if active:
			text = "~ %s ~" % text
		MenuKit.draw_text(_canvas, text, Vector2(0, 140 + i * 16),
			Color(MenuKit.TEXT if active else MenuKit.TEXT_DIM, fade), HORIZONTAL_ALIGNMENT_CENTER, 384)
