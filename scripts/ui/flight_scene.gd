class_name FlightScene
extends CanvasLayer
## The flight on Mantle's back: sky, clouds rushing past, the sea far
## below and the ray beating its wings in the middle, with where they're
## headed written at the top. Lasts a few seconds; any button skips it.

signal finished

const TIME := 3.0
## Skipping only works after this long, so the button that chose the
## destination doesn't skip the flight too.
const SKIP_AFTER := 0.5
const FRAME_SIZE := Vector2(96, 80)
const SEA_Y := 152.0

var destination_key := ""
var _time := 0.0
var _done := false
var _canvas: Control


static func make(destination: String) -> FlightScene:
	var scene := FlightScene.new()
	scene.destination_key = destination
	return scene


func _ready() -> void:
	layer = 25
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_flight)
	add_child(_canvas)
	Audio.set_muffled(false, 0.4)
	Audio.play_music("story_flight", 0.4)


func _process(delta: float) -> void:
	_time += delta
	_canvas.queue_redraw()
	if _time >= TIME:
		_finish()


func _input(event: InputEvent) -> void:
	# Keep the pause menu and Wren from seeing input during the flight.
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_pressed() and not event.is_echo() and _time >= SKIP_AFTER:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


func _draw_flight() -> void:
	_canvas.draw_texture(Art.FLIGHT_SKY, Vector2.ZERO)
	_scroll(Art.FLIGHT_SEA, SEA_Y, 24.0, Color.WHITE)
	_scroll(Art.FLIGHT_CLOUDS, -30.0, 70.0, Color(1, 1, 1, 0.55))
	# Mantle, bobbing on the wind.
	var frame := int(_time * 7.0) % 4
	var bob := roundf(sin(_time * 2.6) * 4.0)
	var at := Vector2(144, 70 + bob)
	_canvas.draw_texture_rect_region(Art.MANTLE, Rect2(at, FRAME_SIZE),
		Rect2(Vector2(frame * FRAME_SIZE.x, 0), FRAME_SIZE))
	# Streaks of wind past the wing tips.
	for i in 6:
		var y := 40.0 + i * 27.0
		var x := 384.0 - fmod(_time * (260.0 + i * 37.0) + i * 97.0, 440.0)
		_canvas.draw_rect(Rect2(roundf(x), y, 14 + i % 3 * 6, 1), Color(1, 1, 1, 0.5))
	_scroll(Art.FLIGHT_CLOUDS, 40.0, 150.0, Color.WHITE)
	if destination_key != "":
		_canvas.draw_rect(Rect2(0, 8, 384, 15), Color(MenuKit.INK, 0.7))
		MenuKit.draw_text(_canvas, destination_key, Vector2(0, 10), MenuKit.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, 384)


## Draw a tileable layer scrolling left at `speed` pixels a second.
func _scroll(texture: Texture2D, y: float, speed: float, tint: Color) -> void:
	var w := float(texture.get_width())
	var x := -fmod(_time * speed, w)
	x = roundf(x)
	_canvas.draw_texture(texture, Vector2(x, y), tint)
	_canvas.draw_texture(texture, Vector2(x + w, y), tint)
