class_name Glow
extends Node2D
## A soft round light: braziers, wisps and the like. In a dark room the
## Darkness reads every Glow inside it and lets its circle through; in a lit
## room it only adds a faint wash of its colour. Cheap where a PointLight2D
## is not: in the web build's renderer every 2D light redraws everything it
## touches (the whole floor), so a room with a few lights ran at half speed.

## Every Glow, for the Darkness to read.
const GROUP := "glows"
## How much of a Glow shows as a wash of colour in a lit room.
const WASH := 0.18

var radius := 32.0:
	set(value):
		radius = value
		queue_redraw()
var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()
var energy := 1.0:
	set(value):
		energy = value
		queue_redraw()


static func make(at_radius: float, with_color: Color, with_energy: float = 1.0) -> Glow:
	var glow := Glow.new()
	glow.radius = at_radius
	glow.color = with_color
	glow.energy = with_energy
	return glow


func _ready() -> void:
	add_to_group(GROUP)
	var material_add := CanvasItemMaterial.new()
	material_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = material_add


func _draw() -> void:
	# In a dark room the Darkness lets this light through; a wash on top
	# would light it twice.
	var room := get_parent()
	while room != null and not room is Room:
		room = room.get_parent()
	if room != null and (room as Room).dark:
		return
	var tint := color * (energy * WASH)
	tint.a = 1.0
	draw_texture_rect(Lantern.light_texture(), Rect2(-radius, -radius, radius * 2.0, radius * 2.0), false, tint)
