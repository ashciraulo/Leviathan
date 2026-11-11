class_name ItemSlotsHud
extends CanvasLayer
## Top right of the screen: the two item slots, each showing its tool (and
## count, for bombs and arrows) with the key that uses it.

const SLOT_AT := [Vector2(336, 3), Vector2(360, 3)]

var _canvas: Control


func _ready() -> void:
	layer = 5
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_slots)
	add_child(_canvas)


func _process(delta: float) -> void:
	_canvas.queue_redraw()
	_canvas.modulate.a = HudFade.step(_canvas.modulate.a, HudFade.covered(get_tree(), slots_rect()), delta)


## The two slots' screen rect, with their key names.
static func slots_rect() -> Rect2:
	return Rect2(SLOT_AT[0] - Vector2(4, 3), SLOT_AT[1] - SLOT_AT[0] + Vector2(28, 26))


func _draw_slots() -> void:
	for i in 2:
		var at: Vector2 = SLOT_AT[i]
		var id: String = GameState.item_slots[i]
		MenuKit.draw_slot(_canvas, at, id != "")
		if id != "":
			var dim := Items.kind(id) == Items.AMMO and GameState.item_count(id) <= 0
			MenuKit.draw_icon(_canvas, id, at + Vector2(2, 2), Color(1, 1, 1, 0.4) if dim else Color.WHITE)
			if Items.kind(id) == Items.AMMO:
				var text := str(GameState.item_count(id))
				MenuKit.draw_text(_canvas, text, at + Vector2(19 - MenuKit.text_width(_canvas, text), 10))
		MenuKit.draw_text(_canvas, MenuKit.key_name("item_1" if i == 0 else "item_2"), at + Vector2(-3, 11),
			MenuKit.TEXT_GOLD)
