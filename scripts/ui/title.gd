extends Control
## Title screen: Continue (when a save exists), New game, Quit.

const GAME_SCENE := "res://scenes/game.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Palette.DEEP
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := UI.centered_column(self)
	column.add_child(UI.label("GAME_TITLE", UI.FONT_SIZE * 2))
	column.add_child(UI.label("TITLE_SUBTITLE"))
	var continue_button := UI.button("MENU_CONTINUE", _on_continue)
	continue_button.visible = SaveManager.has_save()
	column.add_child(continue_button)
	var new_game_button := UI.button("MENU_NEW_GAME", _on_new_game)
	column.add_child(new_game_button)
	column.add_child(UI.button("MENU_QUIT", func() -> void: get_tree().quit()))
	column.add_child(UI.label("TITLE_CONTROLS"))

	var first := continue_button if continue_button.visible else new_game_button
	first.grab_focus.call_deferred()


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
