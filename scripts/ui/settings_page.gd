class_name SettingsPage
extends MenuPage
## Options: text, accessibility, sound, display and controls. Left and
## right change the selected option; it applies and saves at once. The
## controls row opens the remapping page. Used by the pause menu and the
## title screen.

const PANEL := Rect2(8, 22, 368, 128)
const INFO_PANEL := Rect2(8, 152, 368, 44)
const ROW_H := 12
const LIST_TOP := 30
const VISIBLE_ROWS := 9
const VALUE_X := 236

var _rows: Array[Dictionary] = []
var _cursor := 1
var _scroll := 0
var _controls: ControlsPage


func _ready() -> void:
	super()
	_build_rows()
	_controls = ControlsPage.new()
	_controls.visible = false
	_controls.back_requested.connect(_close_controls)
	add_child(_controls)


func _build_rows() -> void:
	_rows = [
		_header("OPT_SECTION_TEXT"),
		_choice("OPT_TEXT_SPEED", ["OPT_SLOW", "OPT_NORMAL", "OPT_FAST", "OPT_INSTANT"], "text_speed"),
		_toggle("OPT_LARGE_TEXT", "large_text"),
		_toggle("OPT_CAPTIONS", "captions"),
		_header("OPT_SECTION_ACCESS"),
		_choice("OPT_COLOR_FILTER", ["OPT_OFF", "OPT_PROTAN", "OPT_DEUTAN", "OPT_TRITAN"], "color_filter"),
		_toggle("OPT_HIGH_CONTRAST", "high_contrast"),
		_percent("OPT_SCREEN_SHAKE", "screen_shake_scale"),
		_percent("OPT_HITSTOP", "hitstop_scale"),
		_choice("OPT_FLASHES", ["OPT_FLASH_SOFT", "OPT_FLASH_FULL"], "flashes"),
		_choice("OPT_HUM", ["OPT_HOLD", "OPT_TOGGLE"], "hum_toggle"),
		_header("OPT_SECTION_SOUND"),
		_volume("OPT_MUSIC", "music_volume"),
		_volume("OPT_EFFECTS", "effects_volume"),
		_volume("OPT_AMBIENCE", "ambience_volume"),
		_header("OPT_SECTION_DISPLAY"),
		_toggle("OPT_FULLSCREEN", "fullscreen"),
		_choice("OPT_LANGUAGE", Settings.language_keys(), "locale_index"),
		_header("OPT_SECTION_CONTROLS"),
		{"kind": "action", "key": "OPT_CONTROLS", "desc": "OPT_CONTROLS_DESC"},
	]


func _header(key: String) -> Dictionary:
	return {"kind": "header", "key": key}


func _choice(key: String, options: Array, prop: String) -> Dictionary:
	return {"kind": "choice", "key": key, "options": options, "prop": prop, "desc": key + "_DESC"}


func _toggle(key: String, prop: String) -> Dictionary:
	return _choice(key, ["OPT_OFF", "OPT_ON"], prop)


func _percent(key: String, prop: String) -> Dictionary:
	return {"kind": "percent", "key": key, "prop": prop, "desc": key + "_DESC"}


func _volume(key: String, prop: String) -> Dictionary:
	return {"kind": "volume", "key": key, "prop": prop, "desc": "OPT_VOLUME_DESC"}


func on_open() -> void:
	_close_controls()
	if _rows[_cursor]["kind"] == "header":
		_cursor = _next_row(_cursor, 1)


func handle_input(event: InputEvent) -> bool:
	if _controls.visible:
		return _controls.handle_input(event)
	var dir := MenuKit.direction(event)
	if dir.y != 0:
		_cursor = _next_row(_cursor, dir.y)
		_keep_visible()
		return true
	var row := _rows[_cursor]
	if dir.x != 0 and row["kind"] != "action":
		_change(row, dir.x)
		return true
	if MenuKit.confirm(event):
		if row["kind"] == "action":
			_controls.visible = true
			_controls.on_open()
		else:
			_change(row, 1, true)
		return true
	return false


func hint() -> String:
	if _controls.visible:
		return _controls.hint()
	return tr("HINT_OPTIONS")


func _next_row(from: int, step: int) -> int:
	var i := from
	for _n in _rows.size():
		i += step
		if i < 0 or i >= _rows.size():
			return from
		if _rows[i]["kind"] != "header":
			return i
	return from


func _keep_visible() -> void:
	var top := _cursor - 1 if _cursor > 0 and _rows[_cursor - 1]["kind"] == "header" else _cursor
	if top < _scroll:
		_scroll = top
	elif _cursor >= _scroll + VISIBLE_ROWS:
		_scroll = _cursor - VISIBLE_ROWS + 1


func _close_controls() -> void:
	if _controls:
		_controls.visible = false


# --------------------------------------------------------------------------
# Values
# --------------------------------------------------------------------------

func _get_value(row: Dictionary) -> int:
	var prop: String = row["prop"]
	if prop == "locale_index":
		return maxi(Settings.languages().find(Settings.locale), 0)
	var value = Settings.get(prop)
	match row["kind"]:
		"percent":
			return roundi(float(value) * 4.0)
		_:
			return int(value)


func _change(row: Dictionary, step: int, wrap: bool = false) -> void:
	var prop: String = row["prop"]
	var count := 0
	match row["kind"]:
		"choice":
			count = row["options"].size()
		"percent":
			count = 5
		"volume":
			count = 11
	var value := _get_value(row) + step
	value = posmod(value, count) if wrap or row["kind"] == "choice" else clampi(value, 0, count - 1)
	if prop == "locale_index":
		Settings.locale = Settings.languages()[value]
		Settings.apply()
		Settings.save_settings()
		return
	match row["kind"]:
		"percent":
			Settings.set(prop, value / 4.0)
		_:
			if typeof(Settings.get(prop)) == TYPE_BOOL:
				Settings.set(prop, value == 1)
			else:
				Settings.set(prop, value)
	Settings.apply()
	Settings.save_settings()


func _value_text(row: Dictionary) -> String:
	var value := _get_value(row)
	match row["kind"]:
		"choice":
			return tr(row["options"][value])
		"percent":
			return "%d%%" % (value * 25)
		"volume":
			return str(value)
	return ""


# --------------------------------------------------------------------------
# Drawing
# --------------------------------------------------------------------------

func _draw() -> void:
	if _controls.visible:
		return
	MenuKit.draw_panel(self, PANEL)
	MenuKit.draw_panel(self, INFO_PANEL)
	for n in VISIBLE_ROWS:
		var i := _scroll + n
		if i >= _rows.size():
			break
		_draw_row(_rows[i], LIST_TOP + n * ROW_H, i == _cursor)
	# Scroll marks.
	if _scroll > 0:
		MenuKit.draw_text(self, "^", Vector2(PANEL.end.x - 18, PANEL.position.y + 4), MenuKit.TEXT_DIM)
	if _scroll + VISIBLE_ROWS < _rows.size():
		MenuKit.draw_text(self, "v", Vector2(PANEL.end.x - 18, PANEL.end.y - 16), MenuKit.TEXT_DIM)
	var row := _rows[_cursor]
	var at := INFO_PANEL.position + Vector2(10, 5)
	MenuKit.draw_text(self, row["key"], at, MenuKit.TEXT_GOLD)
	MenuKit.draw_wrapped(self, row.get("desc", ""), at + Vector2(0, 13), INFO_PANEL.size.x - 20, MenuKit.TEXT, 2)


func _draw_row(row: Dictionary, y: float, selected: bool) -> void:
	if row["kind"] == "header":
		MenuKit.draw_text(self, row["key"], Vector2(20, y), MenuKit.TEXT_HEAD)
		return
	var color := MenuKit.TEXT if selected else MenuKit.TEXT_DIM
	if selected:
		draw_rect(Rect2(14, y - 1, PANEL.size.x - 12, ROW_H), Color(MenuKit.FILL_DARK, 0.9))
		MenuKit.draw_text(self, "~", Vector2(18, y), MenuKit.TEXT_HEAD)
	MenuKit.draw_text(self, row["key"], Vector2(28, y), color)
	match row["kind"]:
		"volume":
			var value := _get_value(row)
			for i in 10:
				var filled := i < value
				draw_rect(Rect2(VALUE_X + 14 + i * 7, y + 2, 5, 6),
					MenuKit.TEXT_HEAD if filled else Color(MenuKit.INK, 0.9))
			_draw_arrows(y, selected, VALUE_X + 14 + 70 + 4)
		"action":
			MenuKit.draw_text(self, "...", Vector2(VALUE_X + 14, y), color)
		_:
			var text := _value_text(row)
			var w := MenuKit.text_width(self, text)
			var mid := VALUE_X + 50.0
			MenuKit.draw_text(self, text, Vector2(roundf(mid - w / 2.0), y), MenuKit.TEXT_GOLD if selected else color)
			_draw_arrows(y, selected, VALUE_X + 92)


func _draw_arrows(y: float, selected: bool, right: float) -> void:
	if not selected:
		return
	MenuKit.draw_text(self, "<", Vector2(VALUE_X, y), MenuKit.TEXT_HEAD)
	MenuKit.draw_text(self, ">", Vector2(right, y), MenuKit.TEXT_HEAD)
