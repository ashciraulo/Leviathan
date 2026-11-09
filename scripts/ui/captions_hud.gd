class_name CaptionsHud
extends CanvasLayer
## Sound captions: a short line near the top of the screen for important
## sounds ("[A bell rings]"), shown when Options > Sound captions is on.
## Up to three at once; each fades after a moment. Large text doubles them.
## A sound from the left or right of the screen gets an arrow on that side.

const SHOW_TIME := 2.2
const MAX_LINES := 3
const TOP := 28.0

var _lines: Array[Dictionary] = []
var _canvas: Control


func _ready() -> void:
	layer = 6
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_lines)
	add_child(_canvas)
	Events.caption.connect(show_caption)


func show_caption(text_key: String, side: int = 0) -> void:
	for line in _lines:
		if line["key"] == text_key:
			line["age"] = 0.0
			line["side"] = side
			return
	_lines.append({"key": text_key, "age": 0.0, "side": side})
	while _lines.size() > MAX_LINES:
		_lines.pop_front()


func _process(delta: float) -> void:
	for line in _lines:
		line["age"] += delta
	_lines = _lines.filter(func(l: Dictionary) -> bool: return l["age"] < SHOW_TIME)
	_canvas.queue_redraw()


func _draw_lines() -> void:
	var size := UI.FONT_SIZE * (2 if Settings.large_text else 1)
	var font := ThemeDB.fallback_font
	var y := TOP
	for line in _lines:
		var text := "[%s]" % tr(line["key"])
		var alpha := clampf((SHOW_TIME - float(line["age"])) / 0.4, 0.0, 1.0)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var side: int = line.get("side", 0)
		var arrow := float(size) / 2.0
		var pad := 4.0 + (arrow + 3.0 if side != 0 else 0.0)
		var rect := Rect2(roundf((384.0 - w) / 2.0) - 4, y - 1, w + 8, size + 2)
		if side < 0:
			rect = Rect2(rect.position - Vector2(arrow + 3.0, 0), rect.size + Vector2(arrow + 3.0, 0))
		elif side > 0:
			rect.size.x += arrow + 3.0
		var backing := 1.0 if Settings.high_contrast else 0.75
		_canvas.draw_rect(rect, Color(MenuKit.INK, backing * alpha))
		var colour := Color(MenuKit.TEXT_HEAD, alpha)
		var text_x := rect.position.x + (pad if side < 0 else 4.0)
		_canvas.draw_string(font, Vector2(text_x, y + size * 8.0 / 11.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
		var mid := y + float(size) / 2.0
		if side < 0:
			var tip := rect.position.x + 3.0
			_canvas.draw_colored_polygon(PackedVector2Array([Vector2(tip, mid),
				Vector2(tip + arrow, mid - arrow), Vector2(tip + arrow, mid + arrow)]), colour)
		elif side > 0:
			var tip := rect.end.x - 3.0
			_canvas.draw_colored_polygon(PackedVector2Array([Vector2(tip, mid),
				Vector2(tip - arrow, mid - arrow), Vector2(tip - arrow, mid + arrow)]), colour)
		y += size + 4
