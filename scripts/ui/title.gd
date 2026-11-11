extends Control
## Title screen: the sleeping leviathan at dusk, the logo, and a short menu
## (Continue the latest save, Journeys for the file select, Options,
## Credits, Quit).

const GAME_SCENE := "res://scenes/game.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"
const LOGO_TOP := 18.0
const LOGO_BOB := 2.0
const FADE_IN := 0.8
const FADE_OUT := 0.5
## The leviathan's breath on the title: glow alpha and timings (seconds).
const BREATH_LOW := 0.25
const BREATH_IN := 2.4
const BREATH_OUT := 3.4

var _logo: TextureRect
var _menu: VBoxContainer
var _overlay: Control
var _page: MenuPage
var _files: FileSelect
var _options: SettingsPage
var _last_focus: Control
var _continue: Button
var _fade: ColorRect
var _leaving := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := TextureRect.new()
	background.texture = Art.TITLE_BG
	background.stretch_mode = TextureRect.STRETCH_KEEP
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# The leviathan's light, brightening and dimming as it breathes.
	var glow := TextureRect.new()
	glow.texture = Art.TITLE_GLOW
	glow.stretch_mode = TextureRect.STRETCH_KEEP
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(glow)
	_breathe(glow)

	_logo = TextureRect.new()
	_logo.texture = Art.TITLE_LOGO
	_logo.position = Vector2(roundf((get_viewport_rect().size.x - Art.TITLE_LOGO.get_width()) / 2.0), LOGO_TOP)
	add_child(_logo)
	_bob_logo()
	Audio.play_music("title")
	Audio.play_ambience("saltmarrow")
	BootCheck.run_if_asked(self)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 0)
	menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu.offset_bottom = -10
	# A dark outline keeps the words readable over the pale whale.
	var outline := Theme.new()
	outline.set_constant("outline_size", "Button", 4)
	outline.set_color("font_outline_color", "Button", Color(MenuKit.INK, 0.9))
	menu.theme = outline
	# The menu surfaces a moment after the scene fades in.
	# It takes no input until it has fully appeared.
	menu.modulate.a = 0.0
	menu.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	add_child(menu)

	_menu = menu
	var continue_button := UI.button("MENU_CONTINUE", _on_continue)
	_continue = continue_button
	continue_button.visible = SaveManager.latest_slot() >= 0
	menu.add_child(continue_button)
	var new_game_button := UI.button("MENU_JOURNEYS", func() -> void: _show_page(_files))
	menu.add_child(new_game_button)
	menu.add_child(UI.button("MENU_OPTIONS", func() -> void: _show_page(_options)))
	menu.add_child(UI.button("MENU_CREDITS", func() -> void: _leave_to(CREDITS_SCENE)))
	# A browser tab can't be closed by the page, so the web build has no Quit.
	if not OS.has_feature("web"):
		menu.add_child(UI.button("MENU_QUIT", func() -> void: get_tree().quit()))

	_overlay = ColorRect.new()
	(_overlay as ColorRect).color = Color(0.03, 0.05, 0.1, 0.78)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	_files = FileSelect.new()
	_files.file_chosen.connect(_on_file_chosen)
	_options = SettingsPage.new()
	for page: MenuPage in [_files, _options]:
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		page.visible = false
		page.back_requested.connect(_hide_page)
		_overlay.add_child(page)

	var first := continue_button if continue_button.visible else new_game_button

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, FADE_IN)
	var appear := create_tween()
	appear.tween_property(menu, "modulate:a", 1.0, 0.6).set_delay(FADE_IN * 0.75)
	appear.tween_callback(func() -> void:
		if _leaving:
			return
		menu.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		first.grab_focus()
		# The browser check (tools/web_check.mjs) waits for this before it
		# presses keys, so none land while the menu is still appearing.
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__lvTitleReady = true;", true))


func _show_page(page: MenuPage) -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	_page = page
	_overlay.visible = true
	_menu.visible = false
	for child in _overlay.get_children():
		child.visible = child == page
	page.on_open()


func _hide_page() -> void:
	_overlay.visible = false
	_menu.visible = true
	_continue.visible = SaveManager.latest_slot() >= 0
	if _last_focus == _continue and not _continue.visible:
		_last_focus = _menu.get_child(1)
	_page = null
	if _last_focus:
		_last_focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _page == null:
		# Buttons only take Enter and Space (ui_accept); the talk key confirms
		# everywhere else, and it's the phone's on-screen confirm button.
		var focus := get_viewport().gui_get_focus_owner() as BaseButton
		if event.is_action_pressed("interact") and focus and _menu.is_ancestor_of(focus) and not focus.disabled:
			get_viewport().set_input_as_handled()
			focus.pressed.emit()
		return
	get_viewport().set_input_as_handled()
	if MenuKit.direction(event) != Vector2i.ZERO:
		Audio.play_sfx("ui_move")
	elif MenuKit.confirm(event):
		Audio.play_sfx("ui_select")
	if _page.handle_input(event):
		return
	if MenuKit.cancel(event) or event.is_action_pressed("pause"):
		_hide_page()


## Slow breaths: the glow swells in, holds, and ebbs away.
func _breathe(glow: CanvasItem) -> void:
	glow.modulate.a = BREATH_LOW
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", 1.0, BREATH_IN)
	tween.tween_interval(0.6)
	tween.tween_property(glow, "modulate:a", BREATH_LOW, BREATH_OUT)


## The logo rises and settles like a slow swell.
func _bob_logo() -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_logo, "position:y", LOGO_TOP - LOGO_BOB, 1.6)
	tween.tween_property(_logo, "position:y", LOGO_TOP, 1.6)


func _on_continue() -> void:
	_on_file_chosen(maxi(SaveManager.latest_slot(), 0), false)


func _on_file_chosen(slot: int, new_game: bool) -> void:
	SaveManager.current_slot = slot
	if new_game:
		# A new file is saved at once, so dying before the first Tidestone
		# brings Wren back to the start.
		GameState.reset_new_game()
		GameState.play_opening = true
		SaveManager.save_game()
	elif not SaveManager.load_game():
		# Never overwrite a file that won't load: show the files instead.
		_show_page(_files)
		return
	_leave_to(GAME_SCENE)


## Fade to black, then change scene. Menus stop taking input meanwhile.
func _leave_to(scene: String) -> void:
	if _leaving:
		return
	_leaving = true
	get_viewport().gui_release_focus()
	_page = null
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	# Tab could otherwise put focus back on a button mid-fade.
	_menu.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_overlay.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	Audio.stop_music(FADE_OUT)
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_OUT)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(scene))
