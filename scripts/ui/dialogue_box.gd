class_name DialogueBox
extends CanvasLayer
## The talk box: a dark panel along the bottom of the screen, a name tab,
## a portrait of whoever is talking, and text that types itself out.
## Opened through Events.conversation_requested (pages with their own
## speakers, see Conversations) or Events.dialogue_requested (one speaker).
## Pages with no speaker are narration: no tab, no portrait, softer text.
## The box always sits along the bottom of the screen, always the same size. Rooms keep the people Wren
## talks to on rows the box can't cover (see LAST_SPEAKER_ROW).
## The game pauses while it is open. Interact or Sword finishes the page,
## then turns to the next one.

## Typing speed comes from Settings.text_chars_per_second() (Options > Text speed).
const SCREEN := Vector2(384, 216)
## One fixed size for every conversation: two lines of text, about 15% of
## the screen. Longer speeches are split over more pages.
const BOX := Rect2(4, 180, 376, 32)
const PAD := Vector2(8, 4)
const MAX_LINES := 2
## Large text (Options) doubles the font, so the same box holds one line.
## Pages that don't fit are split into more pages at word breaks.
const LARGE_MAX_LINES := 1
## The portrait sits at the left, its frame poking a few pixels above the
## box; the name tab sits beside it.
const PORTRAIT_SIZE := 32
const PORTRAIT_AT := Vector2(6, -5)
const PORTRAIT_TEXT_INDENT := 40.0
const TAB_HEIGHT := 14
## The highest pixel anything in the box reaches (the name tab).
const HIGHEST_POINT := 180 - TAB_HEIGHT
const LAST_SPEAKER_ROW := 8
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
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", UI.FONT_SIZE)
	_text.add_theme_color_override("font_color", Palette.MENU_ACTIVE)
	_text.add_theme_constant_override("line_spacing", 1)
	add_child(_text)

	_name = Label.new()
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
	_apply_text_size()
	_pages = _paginate(pages)
	_page = 0
	visible = true
	is_open = true
	_name.position = _tab_rect().position + Vector2(4, 1)
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
	_text.position = BOX.position + PAD + Vector2(indent, 0)
	_text.size = Vector2(BOX.size.x - PAD.x * 2.0 - indent, BOX.size.y - PAD.y * 2.0)
	_name.position = _tab_rect().position + Vector2(4, 1)
	_text.add_theme_color_override("font_color", Palette.MENU_ACTIVE if speaker != "" else Palette.NARRATION)
	_text.text = str(page.get("text", ""))
	_text.visible_characters = 0
	_shown = 0.0
	_panel.queue_redraw()


## The name tab: beside the portrait when there is one.
func _tab_rect() -> Rect2:
	var x := BOX.position.x + 4
	if current_portrait():
		x += PORTRAIT_AT.x + PORTRAIT_SIZE + 2
	return Rect2(Vector2(x, BOX.position.y - TAB_HEIGHT), Vector2(_name.get_minimum_size().x + 8, TAB_HEIGHT))


## How many lines a page of text takes in the box.
func lines_for(text_key: String, with_portrait: bool) -> int:
	var probe := _probe(with_portrait)
	probe.text = text_key
	var count := probe.get_line_count()
	probe.queue_free()
	return count


## How many lines fit in the box at the current text size.
static func max_lines() -> int:
	return LARGE_MAX_LINES if Settings.large_text else MAX_LINES


func _apply_text_size() -> void:
	var font_size := UI.FONT_SIZE * (2 if Settings.large_text else 1)
	_text.add_theme_font_size_override("font_size", font_size)
	_text.add_theme_constant_override("line_spacing", 1 if not Settings.large_text else 0)


## A hidden copy of the text label, sized like the box's text area.
func _probe(with_portrait: bool) -> Label:
	var indent := PORTRAIT_TEXT_INDENT if with_portrait else 0.0
	var probe := _text.duplicate() as Label
	probe.size = Vector2(BOX.size.x - PAD.x * 2.0 - indent, 400)
	probe.visible_characters = -1
	add_child(probe)
	return probe


## Splits any page that runs past max_lines() into several, at word breaks.
## Lines are written to fit at normal size, so this mostly matters for Large
## text and for languages that run longer than English.
func _paginate(pages: Array) -> Array:
	var out: Array = []
	for page: Dictionary in pages:
		var text := tr(str(page.get("text", "")))
		var probe := _probe(page.get("portrait") != null)
		probe.text = text
		if probe.get_line_count() <= max_lines():
			out.append(page)
			probe.queue_free()
			continue
		var words := text.split(" ", false)
		var chunk := ""
		for word in words:
			var trial := word if chunk == "" else chunk + " " + word
			probe.text = trial
			if chunk != "" and probe.get_line_count() > max_lines():
				out.append(_with_text(page, chunk))
				chunk = word
			else:
				chunk = trial
		if chunk != "":
			out.append(_with_text(page, chunk))
		probe.queue_free()
	return out


static func _with_text(page: Dictionary, text: String) -> Dictionary:
	var copy := page.duplicate()
	copy["text"] = text
	return copy


## How many pages the box is showing in this conversation (after splitting).
func page_count() -> int:
	return _pages.size()


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
		_shown += delta * Settings.text_chars_per_second()
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
		var tab := _tab_rect()
		_panel.draw_rect(tab.grow(1), Palette.OUTLINE)
		_panel.draw_rect(tab, Palette.TALK_BG)
		_panel.draw_rect(Rect2(tab.position, Vector2(tab.size.x, 1)), Palette.TALK_EDGE)
	var portrait := current_portrait()
	if portrait:
		var at := box.position + PORTRAIT_AT
		var frame := Rect2(at - Vector2.ONE, Vector2.ONE * (PORTRAIT_SIZE + 2))
		_panel.draw_rect(frame.grow(1), Palette.OUTLINE)
		_panel.draw_rect(frame, Palette.TALK_EDGE)
		_panel.draw_rect(frame.grow(-1), Palette.PORTRAIT_BG)
		_panel.draw_texture(portrait, at)
	# A small wave mark bobs in the corner when the page is done.
	if page_done() and int(_blink * 3.0) % 2 == 0:
		var mark := box.end - Vector2(12, 7)
		_panel.draw_rect(Rect2(mark, Vector2(5, 1)), Palette.SPEAKER)
		_panel.draw_rect(Rect2(mark + Vector2(1, 1), Vector2(3, 1)), Palette.SPEAKER)
		_panel.draw_rect(Rect2(mark + Vector2(2, 2), Vector2(1, 1)), Palette.SPEAKER)
