class_name PauseMenu
extends CanvasLayer
## The pause menu: a tab bar over five pages (Satchel, Map, Progress,
## Options, Journey). Pause opens it on the Satchel, Map opens it on the Map.
## Tab Prev / Tab Next (Q / E) switch tabs. Keeps running while the rest
## of the game is paused.

const TITLE_SCENE := "res://scenes/title.tscn"
const TABS := ["TAB_SATCHEL", "TAB_MAP", "TAB_PROGRESS", "TAB_OPTIONS", "TAB_JOURNEY"]
enum Tab { SATCHEL, MAP, PROGRESS, OPTIONS, JOURNEY }
const TAB_Y := 5
const TAB_H := 14
## The menu drops in this far as it opens, and a page slides this far in from
## the side it was switched from (pixels, over the times below).
const OPEN_DROP := 8.0
const OPEN_TIME := 0.12
const TAB_SLIDE := 6.0
const TAB_TIME := 0.08

var current := Tab.SATCHEL
var _pages: Array[MenuPage] = []
var _chrome: Control
var _opened_at := 0
var _juice: Tween


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.1, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	for page: MenuPage in [SatchelPage.new(), MapPage.new(), ProgressPage.new(), SettingsPage.new(), JourneyPage.new()]:
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		page.visible = false
		page.close_requested.connect(close)
		add_child(page)
		_pages.append(page)
	(_pages[Tab.JOURNEY] as JourneyPage).resume_pressed.connect(close)
	(_pages[Tab.JOURNEY] as JourneyPage).quit_pressed.connect(_quit_to_title)
	_chrome = Control.new()
	_chrome.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome.draw.connect(_draw_chrome)
	add_child(_chrome)


func _process(_delta: float) -> void:
	if visible:
		_chrome.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		# Not during dialogue, a cutscene, or a death, slide or flight sequence.
		if DialogueBox.is_open or Cutscene.active or bool(get_parent().get("busy")):
			return
		if event.is_action_pressed("pause"):
			open(Tab.SATCHEL)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("map"):
			open(Tab.MAP)
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	_play_input_sound(event)
	if event.is_action_pressed("pause") or (event.is_action_pressed("map") and current == Tab.MAP):
		# The controls page may be waiting for a key: let it see Escape first.
		if not _pages[current].handle_input(event):
			close()
		return
	if _pages[current].handle_input(event):
		return
	if event.is_action_pressed("tab_prev"):
		show_tab(posmod(current - 1, TABS.size()), -1)
	elif event.is_action_pressed("tab_next"):
		show_tab(posmod(current + 1, TABS.size()), 1)
	elif event.is_action_pressed("map"):
		show_tab(Tab.MAP)
	elif MenuKit.cancel(event):
		close()


## Menu blips: move, select, back, tab switch.
func _play_input_sound(event: InputEvent) -> void:
	if MenuKit.direction(event) != Vector2i.ZERO:
		Audio.play_sfx("ui_move")
	elif MenuKit.confirm(event) or event.is_action_pressed("item_1") or event.is_action_pressed("item_2"):
		Audio.play_sfx("ui_select")
	elif event.is_action_pressed("tab_prev") or event.is_action_pressed("tab_next"):
		Audio.play_sfx("ui_move", null, 0.8)
	elif MenuKit.cancel(event) or event.is_action_pressed("pause"):
		Audio.play_sfx("ui_back")


func open(tab: Tab = Tab.SATCHEL) -> void:
	Audio.play_sfx("ui_open")
	visible = true
	get_tree().paused = true
	_opened_at = Time.get_ticks_msec()
	show_tab(tab)
	# It drops in and brightens rather than popping up.
	_restart_juice()
	offset = Vector2(0, -OPEN_DROP)
	_set_alpha(0.0)
	_juice.tween_property(self, "offset", Vector2.ZERO, OPEN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_juice.parallel().tween_method(_set_alpha, 0.0, 1.0, OPEN_TIME)


## `from` is -1 or 1 when Tab Prev or Tab Next switched to it: the page
## slides in from that side.
func show_tab(tab: int, from: int = 0) -> void:
	current = tab as Tab
	for i in _pages.size():
		_pages[i].visible = i == tab
		_pages[i].position = Vector2.ZERO
	_pages[tab].on_open()
	if from != 0:
		_restart_juice()
		_pages[tab].position = Vector2(TAB_SLIDE * from, 0)
		_juice.tween_property(_pages[tab], "position", Vector2.ZERO, TAB_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Stops any half-played open or slide, landing it where it was going.
func _restart_juice() -> void:
	if _juice and _juice.is_valid():
		_juice.kill()
	offset = Vector2.ZERO
	_set_alpha(1.0)
	for page in _pages:
		page.position = Vector2.ZERO
	_juice = create_tween()


func _set_alpha(alpha: float) -> void:
	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate.a = alpha


func close() -> void:
	if _juice and _juice.is_valid():
		_juice.kill()
	offset = Vector2.ZERO
	_set_alpha(1.0)
	visible = false
	get_tree().paused = false


func _quit_to_title() -> void:
	SaveManager.save_clock()
	get_tree().paused = false
	Feel.reset()
	get_tree().change_scene_to_file(TITLE_SCENE)


func _draw_chrome() -> void:
	# Solid bands behind the tabs and the hint line hide the HUD and toasts.
	_chrome.draw_rect(Rect2(0, 0, 384, 21), MenuKit.INK)
	_chrome.draw_rect(Rect2(0, 198, 384, 18), MenuKit.INK)
	# Tabs, centred, with the switch keys either side.
	var widths: Array[float] = []
	var total := 0.0
	for key: String in TABS:
		var w := MenuKit.text_width(_chrome, key) + 16.0
		widths.append(w)
		total += w + 2.0
	var x := roundf((384.0 - total) / 2.0)
	MenuKit.draw_text(_chrome, MenuKit.key_name("tab_prev"), Vector2(x - 16, TAB_Y + 2), MenuKit.TEXT_DIM)
	for i in TABS.size():
		var active := i == current
		var rect := Rect2(x, TAB_Y - (1 if active else 0), widths[i], TAB_H + (1 if active else 0))
		RenderingServer.canvas_item_add_nine_patch(_chrome.get_canvas_item(), rect,
			Rect2(16 * int(active), 0, 16, 14), MenuKit.TAB.get_rid(), Vector2(3, 3), Vector2(3, 1))
		MenuKit.draw_text(_chrome, TABS[i], Vector2(x + 8, TAB_Y + 2),
			MenuKit.TEXT if active else MenuKit.TEXT_DIM)
		x += widths[i] + 2.0
	MenuKit.draw_text(_chrome, MenuKit.key_name("tab_next"), Vector2(x + 8, TAB_Y + 2), MenuKit.TEXT_DIM)
	var hint := _pages[current].hint()
	if hint != "":
		MenuKit.draw_text(_chrome, hint, Vector2(0, 201), MenuKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, 384, 376)
