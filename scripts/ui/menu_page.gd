class_name MenuPage
extends Control
## One page of a menu (a pause tab, the options list, the file select).
## Pages draw themselves; the owner forwards input to handle_input.

## Ask the owner to close the whole menu (e.g. after choosing fast travel).
signal close_requested
## Ask the owner to go back one level (e.g. leave a sub-page).
signal back_requested


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


## Called each time the page is shown.
func on_open() -> void:
	pass


## Returns true when the page used the event.
func handle_input(_event: InputEvent) -> bool:
	return false


## A short line of button hints for the bottom of the screen.
func hint() -> String:
	return ""
