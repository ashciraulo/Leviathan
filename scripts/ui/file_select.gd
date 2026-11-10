class_name FileSelect
extends MenuPage
## Pick a journey: three save files, each showing where Wren is, their breath
## bubbles, the Tidebells rung and the time played. Copy and Erase work on
## whole files. Export and Import move a file to and from the player's device
## (SaveTransfer), so browser saves survive a cleared cache. An empty file
## starts a new game.

## The player chose a file. new_game is true for an empty one.
signal file_chosen(slot: int, new_game: bool)

const CARD_X := 32
const CARD_W := 320
const CARD_H := 44
const CARD_TOP := 24
const CARD_STEP := 48
const BUTTON_Y := 176
const BUTTONS := ["FILES_COPY", "FILES_ERASE", "FILES_BACK"]
const BUTTONS_WITH_TRANSFER := ["FILES_COPY", "FILES_ERASE", "FILES_EXPORT", "FILES_IMPORT", "FILES_BACK"]

enum Mode { PLAY, COPY_FROM, COPY_TO, ERASE, ERASE_CONFIRM, EXPORT, IMPORT, IMPORT_WAIT }

## Export and Import, when this platform can reach the player's files.
var transfer: SaveTransfer = null

var _mode := Mode.PLAY
var _cursor := 0
var _source := -1
var _summaries: Array[Dictionary] = []
var _note := ""


func _ready() -> void:
	super()
	if SaveTransfer.available() and transfer == null:
		transfer = SaveTransfer.new()
		add_child(transfer)
	if transfer:
		transfer.finished.connect(_on_transfer_finished)


func on_open() -> void:
	if transfer and transfer.busy():
		transfer.cancel()
	_mode = Mode.PLAY
	_note = ""
	_refresh()
	var latest := SaveManager.latest_slot()
	_cursor = latest if latest >= 0 else 0


func _refresh() -> void:
	_summaries.clear()
	for slot in SaveManager.SLOT_COUNT:
		_summaries.append(SaveManager.read_summary(slot))


func _filled(slot: int) -> bool:
	return not _summaries[slot].is_empty()


func _cells() -> Array:
	var out := []
	for slot in SaveManager.SLOT_COUNT:
		out.append(_card_rect(slot))
	if _mode == Mode.PLAY:
		for i in _buttons().size():
			out.append(_button_rect(i))
	return out


func _buttons() -> Array:
	return BUTTONS_WITH_TRANSFER if transfer else BUTTONS


func _card_rect(slot: int) -> Rect2:
	return Rect2(CARD_X, CARD_TOP + slot * CARD_STEP, CARD_W, CARD_H)


func _button_rect(i: int) -> Rect2:
	var w := float(CARD_W) / _buttons().size()
	return Rect2(CARD_X + i * w + 4, BUTTON_Y, w - 8, 14)


func handle_input(event: InputEvent) -> bool:
	if _mode == Mode.IMPORT_WAIT:
		# The browser's or system's file picker is open; Back gives up on it.
		if MenuKit.cancel(event):
			transfer.cancel()
			_note = ""
			_set_mode(Mode.PLAY, _source)
		return true
	if _mode == Mode.ERASE_CONFIRM:
		var dir_confirm := MenuKit.direction(event)
		if dir_confirm.x != 0:
			_cursor = 1 - _cursor
		elif MenuKit.confirm(event):
			if _cursor == 0:
				SaveManager.delete_save(_source)
				_note = "FILES_ERASED"
			_set_mode(Mode.PLAY, _source)
		elif MenuKit.cancel(event):
			_set_mode(Mode.PLAY, _source)
		return true
	var dir := MenuKit.direction(event)
	if dir != Vector2i.ZERO:
		_cursor = MenuKit.step(_cells(), _cursor, dir)
		return true
	if MenuKit.cancel(event):
		if _mode == Mode.PLAY:
			back_requested.emit()
		else:
			_set_mode(Mode.PLAY, _cursor)
		return true
	if not MenuKit.confirm(event):
		return false
	if _cursor >= SaveManager.SLOT_COUNT:
		_note = ""
		match _buttons()[_cursor - SaveManager.SLOT_COUNT]:
			"FILES_COPY":
				_set_mode(Mode.COPY_FROM, 0)
			"FILES_ERASE":
				_set_mode(Mode.ERASE, 0)
			"FILES_EXPORT":
				_set_mode(Mode.EXPORT, maxi(SaveManager.latest_slot(), 0))
			"FILES_IMPORT":
				_set_mode(Mode.IMPORT, _first_empty())
			"FILES_BACK":
				back_requested.emit()
		return true
	var slot := _cursor
	match _mode:
		Mode.PLAY:
			if _summaries[slot].get("damaged", false):
				_note = "FILES_DAMAGED"
			elif _summaries[slot].get("newer", false):
				_note = "FILES_NEWER"
			else:
				file_chosen.emit(slot, not _filled(slot))
		Mode.COPY_FROM:
			if _filled(slot):
				_source = slot
				_set_mode(Mode.COPY_TO, (slot + 1) % SaveManager.SLOT_COUNT)
		Mode.COPY_TO:
			if slot == _source:
				return true
			if _filled(slot):
				_note = "FILES_COPY_NEED_EMPTY"
				return true
			if SaveManager.copy_save(_source, slot):
				_note = "FILES_COPIED"
				_set_mode(Mode.PLAY, slot)
			else:
				_note = "FILES_DAMAGED"
		Mode.ERASE:
			if _filled(slot):
				_source = slot
				_set_mode(Mode.ERASE_CONFIRM, 1)
		Mode.EXPORT:
			if _filled(slot):
				_source = slot
				transfer.export_slot(slot)
		Mode.IMPORT:
			if _filled(slot):
				_note = "FILES_IMPORT_NEED_EMPTY"
				return true
			_source = slot
			_note = ""
			_set_mode(Mode.IMPORT_WAIT, slot)
			transfer.import_to(slot)
	return true


func _first_empty() -> int:
	for slot in SaveManager.SLOT_COUNT:
		if not _filled(slot):
			return slot
	return 0


func _on_transfer_finished(note: String) -> void:
	# A browser only opens its file picker after a key or a tap, not a pad.
	_note = tr(note) % MenuKit.keyboard_name("interact") if note == "FILES_IMPORT_NEEDS_TOUCH" else note
	_set_mode(Mode.PLAY, _source if _source >= 0 else _cursor)


func _set_mode(mode: Mode, cursor: int) -> void:
	_mode = mode
	_cursor = cursor
	_refresh()


func hint() -> String:
	match _mode:
		Mode.COPY_FROM:
			return "FILES_PICK_COPY_FROM"
		Mode.COPY_TO:
			return "FILES_PICK_COPY_TO"
		Mode.ERASE:
			return "FILES_PICK_ERASE"
		Mode.EXPORT:
			return "FILES_PICK_EXPORT"
		Mode.IMPORT:
			return "FILES_PICK_IMPORT"
		Mode.IMPORT_WAIT:
			return "FILES_IMPORT_WAIT"
	return ""


func _draw() -> void:
	MenuKit.draw_text(self, "FILES_TITLE", Vector2(0, 8), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_CENTER, 384)
	for slot in SaveManager.SLOT_COUNT:
		_draw_card(slot)
	if _mode == Mode.PLAY:
		var buttons := _buttons()
		for i in buttons.size():
			var r := _button_rect(i)
			var selected := _cursor == SaveManager.SLOT_COUNT + i
			MenuKit.draw_text(self, buttons[i], r.position + Vector2(0, 2), MenuKit.TEXT if selected else MenuKit.TEXT_DIM,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var line := _note if _note != "" else hint()
	if _mode == Mode.ERASE_CONFIRM:
		line = tr("FILES_ERASE_CONFIRM") % (_source + 1)
		var yes := tr("FILES_YES")
		var no := tr("FILES_NO")
		MenuKit.draw_text(self, ("~ %s ~" % yes) if _cursor == 0 else yes, Vector2(132, BUTTON_Y),
			MenuKit.TEXT_WARN if _cursor == 0 else MenuKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, 60)
		MenuKit.draw_text(self, ("~ %s ~" % no) if _cursor == 1 else no, Vector2(192, BUTTON_Y),
			MenuKit.TEXT if _cursor == 1 else MenuKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, 60)
	if line != "":
		MenuKit.draw_text(self, line, Vector2(0, 196), MenuKit.TEXT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 384)
	if _cursor < SaveManager.SLOT_COUNT:
		MenuKit.draw_cursor(self, _card_rect(_cursor))
	elif _mode == Mode.PLAY:
		MenuKit.draw_cursor(self, _button_rect(_cursor - SaveManager.SLOT_COUNT))


func _draw_card(slot: int) -> void:
	var rect := _card_rect(slot)
	MenuKit.draw_panel(self, rect)
	var picked := _mode in [Mode.COPY_TO, Mode.ERASE_CONFIRM, Mode.IMPORT_WAIT] and slot == _source
	if picked:
		draw_rect(rect.grow(-4), Color(MenuKit.TEXT_GOLD, 0.15))
	var data := _summaries[slot]
	var at := rect.position + Vector2(12, 7)
	MenuKit.draw_text(self, tr("JOURNEY_FILE_N") % (slot + 1), at, MenuKit.TEXT_GOLD)
	if data.is_empty():
		MenuKit.draw_text(self, "FILES_EMPTY", Vector2(rect.position.x, rect.position.y + 17), MenuKit.TEXT_DIM,
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		return
	if data.get("damaged", false) or data.get("newer", false):
		var key := "FILES_DAMAGED" if data.get("damaged", false) else "FILES_NEWER"
		MenuKit.draw_text(self, key, Vector2(rect.position.x, rect.position.y + 17), MenuKit.TEXT_WARN,
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		return
	var place := str(data.get("place", ""))
	MenuKit.draw_text(self, place if place != "" else "MAP_UNKNOWN_ROOM", at + Vector2(52, 0), MenuKit.TEXT)
	var time := MenuKit.format_time(float(data.get("play_time", 0.0)))
	MenuKit.draw_text(self, time, Vector2(rect.end.x - 12 - MenuKit.text_width(self, time), at.y), MenuKit.TEXT_DIM)
	# Breath bubbles, then the seven bells.
	var bubbles := int(data.get("bubbles", GameState.START_BUBBLES))
	for i in bubbles:
		draw_texture_rect_region(Art.BUBBLES, Rect2(at + Vector2(52 + i * 12, 15), Vector2(11, 11)), Rect2(0, 0, 11, 11))
	var bells := int(data.get("bells", 0))
	for i in Items.max_count("tidebell"):
		MenuKit.draw_icon(self, "tidebell", Vector2(rect.end.x - 12 - (7 - i) * 15, at.y + 13),
			Color.WHITE if i < bells else Color(0.2, 0.25, 0.4, 0.7))
