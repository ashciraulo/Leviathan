class_name CaptionsHud
extends CanvasLayer
## Sound captions: a short line near the top of the screen for important
## sounds ("[A bell rings]"), shown when Options > Sound captions is on.
## Up to three at once; each fades after a moment. Large text doubles them.

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


func show_caption(text_key: String) -> void:
	for line in _lines:
		if line["key"] == text_key:
			line["age"] = 0.0
			return
	_lines.append({"key": text_key, "age": 0.0})
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
		var rect := Rect2(roundf((384.0 - w) / 2.0) - 4, y - 1, w + 8, size + 2)
		_canvas.draw_rect(rect, Color(MenuKit.INK, 0.75 * alpha))
		_canvas.draw_string(font, Vector2(rect.position.x + 4, y + size * 8.0 / 11.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(MenuKit.TEXT_HEAD, alpha))
		y += size + 4
