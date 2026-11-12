class_name BoatHome
extends Node2D
## Wren's lantern-boat, raised off the Ebb Shelf and moored at Saltmarrow's
## harbour steps (StoryDirector): an empty rowboat on the swell with
## Hessa's old brass lamp lit at its bow.

## The lamp on its hook, from the boat's middle.
const LAMP_AT := Vector2(-11, -6)
const WARM := Color(1.0, 0.82, 0.45)

var boat: Rowboat
var _lamp: Node2D
var _time := 0.0


func _ready() -> void:
	boat = Rowboat.new()
	boat.rider_kind = ""
	add_child(boat)
	_lamp = Node2D.new()
	_lamp.z_index = 1
	_lamp.draw.connect(_draw_lamp)
	add_child(_lamp)


func _process(delta: float) -> void:
	_time += delta
	_lamp.position.y = sin(_time * 2.2) * Rowboat.BOB
	_lamp.queue_redraw()


func _draw_lamp() -> void:
	var glow := 0.22 + 0.05 * sin(_time * 3.1)
	_lamp.draw_circle(LAMP_AT, 11.0, Color(WARM, glow * 0.5))
	_lamp.draw_circle(LAMP_AT, 6.0, Color(WARM, glow))
	# The hook, and the little lamp hanging from it.
	_lamp.draw_line(LAMP_AT + Vector2(1, 7), LAMP_AT + Vector2(1, -3), Palette.OUTLINE, 1.0)
	_lamp.draw_line(LAMP_AT + Vector2(1, -3), LAMP_AT + Vector2(-1, -3), Palette.OUTLINE, 1.0)
	_lamp.draw_rect(Rect2(LAMP_AT + Vector2(-2, -2), Vector2(3, 4)), Color("#b08a3a"))
	_lamp.draw_rect(Rect2(LAMP_AT + Vector2(-1, -1), Vector2(1, 2)), Color(1.0, 0.95, 0.7))
