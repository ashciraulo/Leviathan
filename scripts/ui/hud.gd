class_name Hud
extends CanvasLayer
## Breath bubbles (Wren's life), the Resonance meter, and short toasts.
## No hearts: life is a row of bubbles that pop when Wren is hit.

const BUBBLE_SPACING := 12.0
const TOAST_TIME := 1.8

var _gauge: Control
var _toast: Label
var _toast_tween: Tween
var _keys: Label

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
	_toast.modulate.a = 0.0
	add_child(_toast)
	Events.toast.connect(show_toast)

	_keys = UI.label("")
	_keys.name = "Keys"
	_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_keys.position = Vector2(KEYS_AT.x + 14, KEYS_AT.y + 2)
	_keys.add_theme_color_override("font_color", Palette.KEY_TEXT)
	add_child(_keys)


func _process(_delta: float) -> void:
	_gauge.queue_redraw()
	var in_dungeon := GameState.dungeon != ""
	_keys.visible = in_dungeon
	if in_dungeon:
		_keys.text = "x%d" % GameState.keys(GameState.dungeon)


func show_toast(text_key: String) -> void:
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
	_gauge.draw_rect(Rect2(2, 2, count * BUBBLE_SPACING + 5, 23), Palette.UI_DARK)
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
