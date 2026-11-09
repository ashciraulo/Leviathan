class_name LighthouseBeam
extends Node2D
## After the ending, Saltmarrow's lighthouse turns its beam down across the
## village and out through the gate to the sea, towards the Maw, and it
## swells in time with the Old One's breathing. It stays that way until Wren has been back down to the Heart.
## Put it at the lamp room (see at_lighthouse).

## The lamp room, from the lighthouse prop's origin (its base).
const LAMP := Vector2(0, -65)
## Seaward: from the lamp down through Saltmarrow's south gate.
const SEAWARD := 2.17
## Where the beam starts before it turns: out east, over the wall.
const START := -0.2
const LENGTH := 250.0
const SPREAD := 0.09
const LIGHT := Color(1.0, 0.93, 0.62)
## One slow breath of the Old One, in seconds.
const BREATH := 4.0
## Evening falls over the village while the beam is lit, so it shows.
const DUSK := Color(0.58, 0.56, 0.78)

var angle := SEAWARD
## 0..1: how strongly it shines (fades in when it first lights).
var strength := 1.0
var _time := 0.0
var _dusk: CanvasModulate


## A beam on the room's lighthouse, or null if the room has none.
static func at_lighthouse(room: Node) -> LighthouseBeam:
	for child in room.get_children():
		if child is Prop and child.kind == "L":
			var beam := LighthouseBeam.new()
			beam.position = child.position + LAMP
			room.add_child(beam)
			return beam
	return null


func _ready() -> void:
	add_to_group("lighthouse_beam")
	# Over the village (and the tower itself), under the HUD.
	z_index = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Light adds to what's under it.
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add
	_dusk = CanvasModulate.new()
	_dusk.color = Color.WHITE.lerp(DUSK, strength)
	get_parent().add_child.call_deferred(_dusk)


func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(_dusk):
		_dusk.color = Color.WHITE.lerp(DUSK, strength)
	queue_redraw()


## Swing round from `from` to point seaward. Await it.
func turn(from: float, seconds: float) -> void:
	angle = from
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "angle", SEAWARD, seconds)
	await tween.finished


func _draw() -> void:
	# It swells with each breath, never quite going out.
	var breath := 0.5 + 0.5 * sin(_time * TAU / BREATH)
	var a := strength * (0.16 + 0.12 * breath)
	# Three wedges, widest and faintest first, for a soft edge.
	for layer in 3:
		var spread := SPREAD * (1.0 - layer * 0.3)
		var tip := Vector2.from_angle(angle)
		var left := tip.rotated(-spread) * LENGTH
		var right := tip.rotated(spread) * LENGTH
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, left, right]), Color(LIGHT, a))
	# A pool of light where it lands, at the gate.
	var end := Vector2.from_angle(angle) * LENGTH
	for ring in 3:
		var r := 22.0 - ring * 6.0
		_ellipse(end, Vector2(r, r * 0.45), Color(LIGHT, a * (0.6 + ring * 0.3)))
	# The lamp itself, glowing.
	draw_circle(Vector2.ZERO, 5.0 + 2.0 * breath, Color(LIGHT, strength * (0.3 + 0.2 * breath)))
	draw_circle(Vector2.ZERO, 2.5, Color(1, 1, 1, strength * 0.8))


func _ellipse(center: Vector2, radius: Vector2, colour: Color) -> void:
	var points := PackedVector2Array()
	for i in 20:
		points.append(center + Vector2.from_angle(TAU * i / 20.0) * radius)
	draw_colored_polygon(points, colour)
