class_name DialogueBox
extends CanvasLayer
## The talk box: a dark panel along the bottom of the screen, a name tab,
## a portrait of whoever is talking, and text that types itself out.
## Opened through Events.conversation_requested (pages with their own
## speakers, see Conversations) or Events.dialogue_requested (one speaker).
## Pages with no speaker are narration: no tab, no portrait, softer text.
## The game pauses while it is open. Interact or Sword finishes the page,
## then turns to the next one.

const CHARS_PER_SECOND := 45.0
const BOX := Rect2(8, 148, 368, 60)
const TEXT_MARGIN := Vector2(9, 7)
## The portrait sits in a frame at the left of the box; text moves over.
const PORTRAIT_SIZE := 32
const PORTRAIT_AT := Vector2(7, 14)
const PORTRAIT_TEXT_INDENT := 42.0
## Wren ignores Interact and Sword for this long after the box closes, so the
## press that closed it doesn't start a swing or reopen the talk.
const CLOSE_GRACE_MSEC := 250

static var is_open := false
static var _closed_at := -100000

var _panel: Control
var _text: Label
var _name: Label
var _pages: Array = []
var _page := 0
var _shown := 0.0
var _blink := 0.0


static func recently_closed() -> bool:
	return is_open or Time.get_ticks_msec() - _closed_at < CLOSE_GRACE_MSEC


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.draw.connect(_draw_panel)
	add_child(_panel)

	_text = Label.new()
	_text.position = BOX.position + TEXT_MARGIN
	_text.size = BOX.size - TEXT_MARGIN * 2.0
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", UI.FONT_SIZE)
	_text.add_theme_color_override("font_color", Palette.MENU_ACTIVE)
	_text.add_theme_constant_override("line_spacing", 1)
	add_child(_text)

	_name = Label.new()
	_name.position = BOX.position + Vector2(8, -13)
	_name.add_theme_font_size_override("font_size", UI.FONT_SIZE)
	_name.add_theme_color_override("font_color", Palette.SPEAKER)
	add_child(_name)
	Events.dialogue_requested.connect(open)
	Events.conversation_requested.connect(open_pages)
	tree_exiting.connect(func() -> void: is_open = false)


## One speaker, no portrait: every line is a page.
func open(speaker_key: String, lines: PackedStringArray) -> void:
	var pages: Array = []
	for line in lines:
		pages.append({"name": speaker_key, "portrait": null, "text": line})
	open_pages(pages)


## Pages are {"name": key or "", "portrait": Texture2D or null, "text": key}.
func open_pages(pages: Array) -> void:
	if pages.is_empty():
		return
	_pages = pages
	_page = 0
	visible = true
	is_open = true
	get_tree().paused = true
	_show_page()


func close() -> void:
	visible = false
	is_open = false
	_closed_at = Time.get_ticks_msec()
	get_tree().paused = false
	Events.dialogue_finished.emit()


## True once the whole page has typed out.
func page_done() -> bool:
	return _text.visible_characters < 0 or _text.visible_characters >= _text.get_total_character_count()


## Finish typing this page, or turn to the next one (closing after the last).
func advance() -> void:
	if not page_done():
		_text.visible_characters = -1
		return
	_page += 1
	if _page >= _pages.size():
		close()
	else:
		_show_page()


func _show_page() -> void:
	var page := current_page()
	var speaker := str(page.get("name", ""))
	_name.text = speaker
	_name.visible = speaker != ""
	var indent := PORTRAIT_TEXT_INDENT if current_portrait() else 0.0
	_text.position = BOX.position + TEXT_MARGIN + Vector2(indent, 0)
	_text.size = BOX.size - TEXT_MARGIN * 2.0 - Vector2(indent, 0)
	_text.add_theme_color_override("font_color", Palette.MENU_ACTIVE if speaker != "" else Palette.NARRATION)
	_text.text = str(page.get("text", ""))
	_text.visible_characters = 0
	_shown = 0.0
	_panel.queue_redraw()


## The page on screen ({} when closed).
func current_page() -> Dictionary:
	if not is_open or _page >= _pages.size():
		return {}
	return _pages[_page]


func current_portrait() -> Texture2D:
	return current_page().get("portrait") as Texture2D


func _process(delta: float) -> void:
	if not visible:
		return
	_blink += delta
	if not page_done():
		_shown += delta * CHARS_PER_SECOND
		_text.visible_characters = int(_shown)
	_panel.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		advance()
		get_viewport().set_input_as_handled()


func _draw_panel() -> void:
	var box := BOX
	_panel.draw_rect(box.grow(1), Palette.OUTLINE)
	_panel.draw_rect(box, Palette.TALK_BG)
	_panel.draw_rect(Rect2(box.position, Vector2(box.size.x, 1)), Palette.TALK_EDGE)
	if _name.visible:
		var tab := Rect2(box.position + Vector2(4, -14), Vector2(_name.get_minimum_size().x + 8, 14))
		_panel.draw_rect(tab.grow(1), Palette.OUTLINE)
		_panel.draw_rect(tab, Palette.TALK_BG)
		_panel.draw_rect(Rect2(tab.position, Vector2(tab.size.x, 1)), Palette.TALK_EDGE)
	var portrait := current_portrait()
	if portrait:
		var frame := Rect2(box.position + PORTRAIT_AT - Vector2(2, 2), Vector2.ONE * (PORTRAIT_SIZE + 4))
		_panel.draw_rect(frame.grow(1), Palette.OUTLINE)
		_panel.draw_rect(frame, Palette.TALK_EDGE)
		_panel.draw_rect(frame.grow(-1), Palette.PORTRAIT_BG)
		_panel.draw_texture(portrait, box.position + PORTRAIT_AT)
	# A small wave mark bobs in the corner when the page is done.
	if page_done() and int(_blink * 3.0) % 2 == 0:
		var at := box.end - Vector2(12, 8)
		_panel.draw_rect(Rect2(at, Vector2(5, 1)), Palette.SPEAKER)
		_panel.draw_rect(Rect2(at + Vector2(1, 1), Vector2(3, 1)), Palette.SPEAKER)
		_panel.draw_rect(Rect2(at + Vector2(2, 2), Vector2(1, 1)), Palette.SPEAKER)
