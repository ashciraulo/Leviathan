class_name Hud
extends CanvasLayer
## Breath bubbles (Wren's life), the Resonance meter, and short toasts.
## No hearts: life is a row of bubbles that pop when Wren is hit.

const BUBBLE_SPACING := 12.0
const TOAST_TIME := 1.8
## After a save: a small ring of bubbles turns in the bottom right corner.
const SAVED_TIME := 1.6
const SAVED_AT := Vector2(370, 202)

var _gauge: Control
var _toast: Label
var _toast_tween: Tween
var _keys: Label
var _saved := 0.0

## Top right, under the item slots: the small-key count, shown only inside
## a dungeon.
const KEYS_AT := Vector2(346, 30)


func _ready() -> void:
	layer = 5
	_gauge = Control.new()
	_gauge.name = "Gauge"
	_gauge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.draw.connect(_draw_gauge)
	add_child(_gauge)

	_toast = UI.label("")
	_toast.name = "Toast"
	_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_toast.offset_top = -22
	_toast.offset_bottom = -6
	# Grows upwards when large text wraps it onto more lines.
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_toast.modulate.a = 0.0
	add_child(_toast)
	Events.toast.connect(show_toast)
	Events.game_saved.connect(func() -> void: _saved = SAVED_TIME)

	_keys = UI.label("")
	_keys.name = "Keys"
	# A count, not a text key.
	_keys.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_keys.position = Vector2(KEYS_AT.x + 14, KEYS_AT.y + 2)
	_keys.add_theme_color_override("font_color", Palette.KEY_TEXT)
	add_child(_keys)


func _process(delta: float) -> void:
	_saved = maxf(_saved - delta, 0.0)
	_gauge.queue_redraw()
	var in_dungeon := GameState.dungeon != ""
	_keys.visible = in_dungeon
	if in_dungeon:
		_keys.text = "x%d" % GameState.keys(GameState.dungeon)


func show_toast(text_key: String) -> void:
	# Large text doubles toasts (Tide stays crisp at whole multiples).
	var big := Settings.large_text
	_toast.add_theme_font_size_override("font_size", UI.FONT_SIZE * (2 if big else 1))
	_toast.offset_top = -72 if big else -22
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if text_key == "":
		return
	_toast.text = text_key
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(TOAST_TIME)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _draw_gauge() -> void:
	var count: int = GameState.max_bubbles
	var plate := Rect2(2, 2, count * BUBBLE_SPACING + 5, 23)
	if Settings.high_contrast:
		_gauge.draw_rect(plate.grow(1), Palette.CONTRAST_WREN)
	_gauge.draw_rect(plate, Palette.UI_DARK)
	for i in count:
		var cell := Rect2(4 + i * BUBBLE_SPACING, 4, 11, 11)
		var full := i < GameState.bubbles
		_gauge.draw_texture_rect_region(Art.BUBBLES, cell, Rect2(0 if full else 11, 0, 11, 11))
	# Resonance meter, marked in thirds: each third is one Hum.
	var bar := Rect2(5, 18, count * BUBBLE_SPACING - 1, 4)
	_gauge.draw_rect(bar.grow(1), Palette.OUTLINE)
	_gauge.draw_rect(bar, Palette.RESONANCE_EMPTY)
	var fill: float = GameState.resonance / GameState.resonance_max
	_gauge.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), Palette.RESONANCE)
	if GameState.dungeon != "":
		_gauge.draw_rect(Rect2(KEYS_AT - Vector2(2, 2), Vector2(36, 19)), Palette.UI_DARK)
		_gauge.draw_texture(Art.SMALL_KEY, KEYS_AT + Vector2(-3, -1))
	for third in [1, 2]:
		var x: float = bar.position.x + bar.size.x * third / 3.0
		_gauge.draw_rect(Rect2(x, bar.position.y, 1, bar.size.y), Palette.OUTLINE)
	if _saved > 0.0:
		_draw_saved()


## Six bubbles chasing round a ring, fading in and out.
func _draw_saved() -> void:
	var alpha := clampf(minf(_saved / 0.4, (SAVED_TIME - _saved) / 0.2), 0.0, 1.0)
	var turn := (SAVED_TIME - _saved) * 5.0
	_gauge.draw_circle(SAVED_AT + Vector2(1, 1), 10.0, Color(Palette.UI_DARK, 0.8 * alpha))
	for i in 6:
		var a := turn + i * TAU / 6.0
		var at := (SAVED_AT + Vector2(cos(a), sin(a)) * 5.0).round()
		var lead := 1.0 - i / 6.0
		_gauge.draw_rect(Rect2(at, Vector2(2, 2)), Color(Palette.RESONANCE, alpha * (0.45 + 0.55 * lead)))
