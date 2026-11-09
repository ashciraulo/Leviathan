class_name UI
extends Object
## Small helpers for building menus in code. Text is always a translation key;
## Godot translates Label and Button text automatically.

## Native size of Tide, the pixel font. Use whole multiples so it stays crisp.
const FONT_SIZE := 11


static func label(key: String, font_size: int = UI.FONT_SIZE) -> Label:
	var node := Label.new()
	node.text = key
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	return node


static func button(key: String, on_pressed: Callable) -> Button:
	var node := Button.new()
	node.text = key
	node.pressed.connect(on_pressed)
	return node


## A full-screen centred column to put menu items in.
static func centered_column(parent: Node) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	center.add_child(column)
	return column
