class_name JourneyPage
extends MenuPage
## The journey tab: where Wren is, how long this file has run, what they have
## found, and Resume / Quit to title. Saving only happens at Tidestones.

signal resume_pressed
signal quit_pressed

const PANEL := Rect2(8, 22, 368, 128)
const INFO_PANEL := Rect2(8, 152, 368, 44)
const BUTTONS := ["MENU_RESUME", "MENU_QUIT_TO_TITLE"]
const BUTTON_Y := 112

var _cursor := 0
var _confirm_quit := false


func on_open() -> void:
	_cursor = 0
	_confirm_quit = false


func handle_input(event: InputEvent) -> bool:
	var dir := MenuKit.direction(event)
	if dir.y != 0:
		_cursor = clampi(_cursor + dir.y, 0, BUTTONS.size() - 1)
		_confirm_quit = false
		return true
	if MenuKit.confirm(event):
		if _cursor == 0:
			resume_pressed.emit()
		elif _confirm_quit:
			quit_pressed.emit()
		else:
			_confirm_quit = true
		return true
	return false


func hint() -> String:
	return tr("HINT_CHOOSE") % MenuKit.key_name("interact")


func _draw() -> void:
	MenuKit.draw_panel(self, PANEL)
	MenuKit.draw_panel(self, INFO_PANEL)
	var info := RoomInfo.get_room(GameState.room_coord)
	var left := Vector2(24, 34)
	MenuKit.draw_text(self, "JOURNEY_FILE", left, MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 104)
	MenuKit.draw_text(self, tr("JOURNEY_FILE_N") % (SaveManager.current_slot + 1), left + Vector2(110, 0))
	MenuKit.draw_text(self, "JOURNEY_PLACE", left + Vector2(0, 14), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 104)
	MenuKit.draw_text(self, info.get("name_key", "MAP_UNKNOWN_ROOM"), left + Vector2(110, 14), MenuKit.TEXT,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, PANEL.end.x - left.x - 118)
	MenuKit.draw_text(self, "JOURNEY_TIME", left + Vector2(0, 28), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 104)
	MenuKit.draw_text(self, MenuKit.format_time(GameState.play_time), left + Vector2(110, 28))
	MenuKit.draw_text(self, "JOURNEY_BELLS", left + Vector2(0, 42), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 104)
	for i in Items.max_count("tidebell"):
		var lit := i < GameState.item_count("tidebell")
		MenuKit.draw_icon(self, "tidebell", left + Vector2(108 + i * 17, 38),
			Color.WHITE if lit else Color(0.2, 0.25, 0.4, 0.7))
	MenuKit.draw_text(self, "JOURNEY_STONES", left + Vector2(0, 58), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 104)
	MenuKit.draw_text(self, str(GameState.tidestones.size()), left + Vector2(110, 58))
	for i in BUTTONS.size():
		var y := BUTTON_Y + i * 14
		var selected := i == _cursor
		var key: String = BUTTONS[i]
		if i == 1 and _confirm_quit:
			key = "JOURNEY_QUIT_CONFIRM"
		var text := tr(key)
		if selected:
			text = "~ %s ~" % text
		MenuKit.draw_text(self, text, Vector2(PANEL.position.x, y),
			(MenuKit.TEXT_WARN if _confirm_quit and i == 1 else MenuKit.TEXT) if selected else MenuKit.TEXT_DIM,
			HORIZONTAL_ALIGNMENT_CENTER, PANEL.size.x)
	MenuKit.draw_wrapped(self, "JOURNEY_SAVE_NOTE", INFO_PANEL.position + Vector2(10, 5),
		INFO_PANEL.size.x - 20, MenuKit.TEXT, 2)
