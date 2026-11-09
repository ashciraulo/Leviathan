class_name ControlsPage
extends MenuPage
## Remapping: every action with its keyboard key and gamepad button.
## Pick a cell and press Interact, then press the new key or button.
## Escape (or Start on a pad) cancels. The last row resets everything.

const PANEL := Rect2(8, 22, 368, 128)
const INFO_PANEL := Rect2(8, 152, 368, 44)
const ROW_H := 12
const LIST_TOP := 44
const VISIBLE_ROWS := 7
const KEY_X := 196
const PAD_X := 290

var _row := 0
var _column := 0
var _scroll := 0
var _waiting := false


func on_open() -> void:
	_row = 0
	_column = 0
	_scroll = 0
	_waiting = false


func _rows() -> int:
	return Settings.REMAPPABLE.size() + 1


func handle_input(event: InputEvent) -> bool:
	if _waiting:
		return _capture(event)
	var dir := MenuKit.direction(event)
	if dir.y != 0:
		_row = clampi(_row + dir.y, 0, _rows() - 1)
		if _row < _scroll:
			_scroll = _row
		elif _row >= _scroll + VISIBLE_ROWS:
			_scroll = _row - VISIBLE_ROWS + 1
		return true
	if dir.x != 0:
		_column = clampi(_column + dir.x, 0, 1)
		return true
	if MenuKit.confirm(event):
		if _row == Settings.REMAPPABLE.size():
			Settings.reset_controls()
			Settings.save_settings()
		else:
			_waiting = true
		return true
	if MenuKit.cancel(event):
		back_requested.emit()
		return true
	return false


## Takes the next key (column 0) or pad button (column 1).
func _capture(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return true
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		_waiting = false
		return true
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
		_waiting = false
		return true
	var wanted := (_column == 0 and event is InputEventKey) or (_column == 1 and event is InputEventJoypadButton)
	if wanted:
		Settings.rebind(Settings.REMAPPABLE[_row], event)
		Settings.save_settings()
		_waiting = false
	return true


func hint() -> String:
	if _waiting:
		return tr("HINT_CONTROLS_WAIT")
	return tr("HINT_CONTROLS") % [MenuKit.key_name("interact"), MenuKit.key_name("attack")]


static func pad_text(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return "PAD_BUTTON_%d" % event.button_index
		if event is InputEventJoypadMotion:
			return "PAD_AXIS_%d" % event.axis
	return "-"


func _draw() -> void:
	MenuKit.draw_panel(self, PANEL)
	MenuKit.draw_panel(self, INFO_PANEL)
	MenuKit.draw_text(self, "OPT_CONTROLS", Vector2(20, 30), MenuKit.TEXT_HEAD)
	MenuKit.draw_text(self, "CONTROLS_KEYBOARD", Vector2(KEY_X, 30), MenuKit.TEXT_HEAD)
	MenuKit.draw_text(self, "CONTROLS_GAMEPAD", Vector2(PAD_X, 30), MenuKit.TEXT_HEAD)
	for n in VISIBLE_ROWS:
		var i := _scroll + n
		if i >= _rows():
			break
		var y := LIST_TOP + n * ROW_H
		var selected := i == _row
		if selected:
			draw_rect(Rect2(14, y - 1, PANEL.size.x - 12, ROW_H), Color(MenuKit.FILL_DARK, 0.9))
		var color := MenuKit.TEXT if selected else MenuKit.TEXT_DIM
		if i == Settings.REMAPPABLE.size():
			MenuKit.draw_text(self, "CONTROLS_RESET", Vector2(28, y), MenuKit.TEXT_WARN if selected else color)
			continue
		var action: String = Settings.REMAPPABLE[i]
		MenuKit.draw_text(self, "ACTION_" + action.to_upper(), Vector2(28, y), color)
		for col in 2:
			var x := KEY_X if col == 0 else PAD_X
			var text := MenuKit.key_name(action) if col == 0 else pad_text(action)
			var active := selected and col == _column
			if active and _waiting:
				text = "CONTROLS_PRESS" if int(Time.get_ticks_msec() / 300) % 2 == 0 else ""
			if active:
				draw_rect(Rect2(x - 4, y - 1, 82, ROW_H), Color(MenuKit.FILL, 1.0))
				MenuKit.draw_text(self, "~", Vector2(x - 10, y), MenuKit.TEXT_HEAD)
			MenuKit.draw_text(self, text, Vector2(x, y), MenuKit.TEXT_GOLD if active else color)
	if _scroll + VISIBLE_ROWS < _rows():
		MenuKit.draw_text(self, "v", Vector2(PANEL.end.x - 18, PANEL.end.y - 16), MenuKit.TEXT_DIM)
	if _scroll > 0:
		MenuKit.draw_text(self, "^", Vector2(PANEL.end.x - 18, PANEL.position.y + 4), MenuKit.TEXT_DIM)
	var at := INFO_PANEL.position + Vector2(10, 5)
	MenuKit.draw_wrapped(self, "CONTROLS_DESC", at, INFO_PANEL.size.x - 20, MenuKit.TEXT, 2)
