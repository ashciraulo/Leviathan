class_name MenuKit
extends Object
## Shared look and input for the menu screens (pause, satchel, map,
## options, file select). Art comes from tools/ui_art.py.
##
## Menus draw themselves and move a cursor by hand rather than using
## Godot's focus, so grids, maps and lists all move the same way and work
## the same on keyboard and gamepad.

const ITEMS := preload("res://assets/ui/items.png")
const PANEL := preload("res://assets/ui/panel.png")
const SLOT := preload("res://assets/ui/slot.png")
const CURSOR := preload("res://assets/ui/cursor.png")
const MARKERS := preload("res://assets/ui/map_markers.png")
const TAB := preload("res://assets/ui/tab.png")

const PANEL_MARGIN := 8
const SLOT_SIZE := 20
const CURSOR_SIZE := 24

const TEXT := Color("#fff4d6")
const TEXT_DIM := Color("#8e84a8")
const TEXT_HEAD := Color("#a8e6cf")
const TEXT_GOLD := Color("#f4c542")
const TEXT_WARN := Color("#f27a5e")
const FILL := Color("#18324a")
const FILL_DARK := Color("#10223a")
const INK := Color("#0c1626")

## Map marker frames in map_markers.png.
enum Marker { WREN, STONE_ASLEEP, STONE_AWAKE, CHEST, BOSS, DOOR }


## A nine-slice rope-and-brass panel covering rect.
static func panel(rect: Rect2) -> NinePatchRect:
	var node := NinePatchRect.new()
	node.texture = PANEL
	node.patch_margin_left = PANEL_MARGIN
	node.patch_margin_top = PANEL_MARGIN
	node.patch_margin_right = PANEL_MARGIN
	node.patch_margin_bottom = PANEL_MARGIN
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Draws a panel on any CanvasItem (for screens that draw everything).
static func draw_panel(canvas: CanvasItem, rect: Rect2) -> void:
	var m := float(PANEL_MARGIN)
	var src := Rect2(Vector2.ZERO, PANEL.get_size())
	RenderingServer.canvas_item_add_nine_patch(canvas.get_canvas_item(), rect, src, PANEL.get_rid(),
		Vector2(m, m), Vector2(m, m))


static func draw_slot(canvas: CanvasItem, pos: Vector2, assigned: bool = false) -> void:
	canvas.draw_texture_rect_region(SLOT, Rect2(pos, Vector2(SLOT_SIZE, SLOT_SIZE)),
		Rect2(SLOT_SIZE if assigned else 0, 0, SLOT_SIZE, SLOT_SIZE))


## Draws an item's 16x16 icon with its top-left at pos.
static func draw_icon(canvas: CanvasItem, id: String, pos: Vector2, modulate: Color = Color.WHITE) -> void:
	draw_icon_frame(canvas, Items.icon(id), pos, modulate)


static func draw_icon_frame(canvas: CanvasItem, frame: int, pos: Vector2, modulate: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect_region(ITEMS, Rect2(pos, Vector2(16, 16)), Items.icon_rect(frame), modulate)


## The breathing selection brackets around a rect (centred on it).
static func draw_cursor(canvas: CanvasItem, around: Rect2) -> void:
	var frame := int(Time.get_ticks_msec() / 400) % 2
	var size := Vector2(CURSOR_SIZE, CURSOR_SIZE)
	if around.size.x <= CURSOR_SIZE + 2 and around.size.y <= CURSOR_SIZE + 2:
		var pos := (around.get_center() - size / 2.0).round()
		canvas.draw_texture_rect_region(CURSOR, Rect2(pos, size), Rect2(frame * CURSOR_SIZE, 0, CURSOR_SIZE, CURSOR_SIZE))
		return
	# Bigger targets: draw the four corners at the rect's corners.
	var r := around.grow(2 - frame)
	var half := CURSOR_SIZE / 2.0
	var corners := [
		[r.position, Vector2.ZERO],
		[Vector2(r.end.x - half, r.position.y), Vector2(half, 0)],
		[Vector2(r.position.x, r.end.y - half), Vector2(0, half)],
		[r.end - Vector2(half, half), Vector2(half, half)],
	]
	for c: Array in corners:
		canvas.draw_texture_rect_region(CURSOR, Rect2(c[0], Vector2(half, half)),
			Rect2(Vector2(frame * CURSOR_SIZE, 0) + c[1], Vector2(half, half)))


static func draw_marker(canvas: CanvasItem, marker: Marker, center: Vector2) -> void:
	canvas.draw_texture_rect_region(MARKERS, Rect2((center - Vector2(4, 4)).round(), Vector2(8, 8)),
		Rect2(int(marker) * 8, 0, 8, 8))


## Text in Tide at its native size. Translates key first. Text wider than
## max_width (or than width, when that's given) is cut short with "..",
## so a long translation never spills out of its box.
static func draw_text(canvas: CanvasItem, text: String, pos: Vector2, color: Color = TEXT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0,
		max_width: float = -1.0) -> void:
	var font := ThemeDB.fallback_font
	var limit := max_width if max_width > 0.0 else width
	var shown := fit(canvas, text, limit) if limit > 0.0 else canvas.tr(text)
	canvas.draw_string(font, pos + Vector2(0, 8), shown, align, width, UI.FONT_SIZE, color)


## The translated text, cut short with ".." if it is wider than max_width.
static func fit(canvas: CanvasItem, text: String, max_width: float) -> String:
	var font := ThemeDB.fallback_font
	var full := canvas.tr(text)
	if font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FONT_SIZE).x <= max_width:
		return full
	var cut := full
	while cut.length() > 1:
		cut = cut.left(-1)
		var tried := cut.strip_edges() + ".."
		if font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FONT_SIZE).x <= max_width:
			return tried
	return ".."


static func text_width(canvas: CanvasItem, text: String) -> float:
	return ThemeDB.fallback_font.get_string_size(canvas.tr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FONT_SIZE).x


## Draws wrapped text (Tide, native size) inside width. Returns lines used.
static func draw_wrapped(canvas: CanvasItem, text: String, pos: Vector2, width: float, color: Color = TEXT_DIM,
		max_lines: int = 3) -> int:
	var font := ThemeDB.fallback_font
	var shown := canvas.tr(text)
	# Too long for max_lines: drop words from the end and finish with "..".
	if _lines(shown, width) > max_lines:
		var words := shown.split(" ")
		while words.size() > 1:
			words.resize(words.size() - 1)
			shown = " ".join(words) + ".."
			if _lines(shown, width) <= max_lines:
				break
	canvas.draw_multiline_string(font, pos + Vector2(0, 8), shown, HORIZONTAL_ALIGNMENT_LEFT, width,
		UI.FONT_SIZE, max_lines, color)
	return mini(_lines(shown, width), max_lines)


static func _lines(text: String, width: float) -> int:
	var font := ThemeDB.fallback_font
	var height := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, UI.FONT_SIZE).y
	return maxi(roundi(height / font.get_height(UI.FONT_SIZE)), 1)


# --------------------------------------------------------------------------
# Input. Menus read both Wren's move keys and Godot's ui_ arrows.
# --------------------------------------------------------------------------

## The direction a press points, or zero. Includes key repeat.
static func direction(event: InputEvent) -> Vector2i:
	for pair: Array in [["move_up", "ui_up", Vector2i.UP], ["move_down", "ui_down", Vector2i.DOWN],
			["move_left", "ui_left", Vector2i.LEFT], ["move_right", "ui_right", Vector2i.RIGHT]]:
		if event.is_action_pressed(pair[0], true) or event.is_action_pressed(pair[1], true):
			return pair[2]
	return Vector2i.ZERO


static func confirm(event: InputEvent) -> bool:
	return event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")


static func cancel(event: InputEvent) -> bool:
	return event.is_action_pressed("attack") or event.is_action_pressed("ui_cancel")


## The first keyboard key bound to an action, as text ("U", "Space").
static func key_name(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return key_text(event)
	return "-"


static func key_text(key: InputEventKey) -> String:
	# Physical codes name the key by its US-layout position (W, A, S, D).
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return OS.get_keycode_string(code)


## Picks the cell nearest to from in a direction. cells are Rect2s.
## Returns from_index when there is nothing that way.
static func step(cells: Array, from_index: int, dir: Vector2i) -> int:
	if cells.is_empty() or dir == Vector2i.ZERO:
		return from_index
	var origin: Vector2 = (cells[from_index] as Rect2).get_center()
	var d := Vector2(dir)
	var best := from_index
	var best_score := INF
	for i in cells.size():
		if i == from_index:
			continue
		var offset: Vector2 = (cells[i] as Rect2).get_center() - origin
		var along := offset.dot(d)
		if along <= 1.0:
			continue
		var across := absf(offset.dot(Vector2(-d.y, d.x)))
		# Prefer cells straight ahead; sideways distance costs more.
		var score := along + across * 2.5
		if score < best_score:
			best_score = score
			best = i
	return best


static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 3600, (total / 60) % 60]
