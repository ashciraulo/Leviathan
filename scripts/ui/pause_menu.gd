class_name PauseMenu
extends CanvasLayer
## Pause menu. Keeps running while the rest of the game is paused.

const TITLE_SCENE := "res://scenes/title.tscn"

var _resume: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var column := UI.centered_column(self)
	column.add_child(UI.label("PAUSE_TITLE", UI.FONT_SIZE * 2))
	_resume = UI.button("MENU_RESUME", close)
	column.add_child(_resume)
	column.add_child(UI.button("MENU_QUIT_TO_TITLE", _quit_to_title))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if DialogueBox.is_open:
			return
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	get_tree().paused = true
	_resume.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _quit_to_title() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(TITLE_SCENE)
