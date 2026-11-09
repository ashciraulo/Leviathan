extends Control
## Title screen: the sleeping leviathan at dusk, the logo, and a short menu
## (Continue when a save exists, New game, Quit).

const GAME_SCENE := "res://scenes/game.tscn"
const LOGO_TOP := 18.0
const LOGO_BOB := 2.0

var _logo: TextureRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := TextureRect.new()
	background.texture = Art.TITLE_BG
	background.stretch_mode = TextureRect.STRETCH_KEEP
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_logo = TextureRect.new()
	_logo.texture = Art.TITLE_LOGO
	_logo.position = Vector2(roundf((get_viewport_rect().size.x - Art.TITLE_LOGO.get_width()) / 2.0), LOGO_TOP)
	add_child(_logo)
	_bob_logo()

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 0)
	menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu.offset_bottom = -16
	add_child(menu)

	var continue_button := UI.button("MENU_CONTINUE", _on_continue)
	continue_button.visible = SaveManager.has_save()
	menu.add_child(continue_button)
	var new_game_button := UI.button("MENU_NEW_GAME", _on_new_game)
	menu.add_child(new_game_button)
	menu.add_child(UI.button("MENU_QUIT", func() -> void: get_tree().quit()))

	var controls := UI.label("TITLE_CONTROLS")
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	controls.offset_bottom = -2
	controls.modulate = Color(1, 1, 1, 0.6)
	add_child(controls)

	var first := continue_button if continue_button.visible else new_game_button
	first.grab_focus.call_deferred()


## The logo rises and settles like a slow swell.
func _bob_logo() -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_logo, "position:y", LOGO_TOP - LOGO_BOB, 1.6)
	tween.tween_property(_logo, "position:y", LOGO_TOP, 1.6)


func _on_continue() -> void:
	if not SaveManager.load_game():
		GameState.reset_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_new_game() -> void:
	# The prototype has one slot: starting over replaces it, so dying before
	# the first Tidestone brings Wren back to the start, not to an old save.
	GameState.reset_new_game()
	SaveManager.save_game()
	get_tree().change_scene_to_file(GAME_SCENE)
