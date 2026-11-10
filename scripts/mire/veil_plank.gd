class_name VeilPlank
extends StaticBody2D
## A plank of the drowned boardwalk over black water (v). In the dark it's
## only bog; in the raised lantern's light it's there, and Wren can walk on
## it. A plank Wren is standing on stays put until they step off.

const FADE_SPEED := 4.0
## Unlit, a plank shows only a few glints of wet wood on the black water,
## slowly breathing: enough to say something
## is there for the lantern to find.
const GLIMMER := 0.8
const GLIMMER_SPEED := 1.6
const GLINTS := [Vector2(-5, -9), Vector2(2, -6), Vector2(-1, -2), Vector2(5, -1)]

var _shape: CollisionShape2D
var _shown := 0.0
var _solid := true
var _time := 0.0
var _glint: Node2D
var _glint_color := Color.WHITE


func _ready() -> void:
	add_to_group("veil_planks")
	# Like water: blocks walking (and enemies) until it's lit.
	Layers.assign(self, Layers.WATER, [])
	_shape = Layers.rect_shape(Vector2(16, 16), Vector2(0, -4))
	add_child(_shape)
	z_index = -9
	# Plain wet light. In a dark room the glint shows above the dark (it's
	# what gives the hidden way away), a little paler.
	var room := get_parent() as Room
	var dark := room != null and room.dark
	_glint_color = Color(0.72, 0.86, 0.92) if dark else Color(0.62, 0.78, 0.86)
	_glint = Node2D.new()
	_glint.draw.connect(_draw_glints)
	if dark:
		_glint.z_as_relative = false
		_glint.z_index = Darkness.Z + 1
	add_child(_glint)


func is_real() -> bool:
	return not _solid


func _physics_process(delta: float) -> void:
	var center := global_position + Vector2(0, -4)
	var wren := Lantern.player(get_tree())
	var under := wren != null and absf(wren.global_position.x - center.x) < 13.0 and absf(wren.global_position.y - 3.0 - center.y) < 13.0
	var lit := Lantern.lights(get_tree(), center, 8.0)
	var real := lit or (under and not _solid)
	if real == _solid:
		_solid = not real
		_shape.set_deferred("disabled", real)
	_time += delta
	var shown := move_toward(_shown, 1.0 if real else 0.0, FADE_SPEED * delta)
	if shown != _shown:
		_shown = shown
		queue_redraw()
	if _shown < 1.0:
		_glint.queue_redraw()


func _draw() -> void:
	# The room draws the black water underneath.
	if _shown > 0.0:
		draw_texture(MireSprites.VEIL_PLANK, Vector2(-8, -12), Color(1, 1, 1, _shown))


func _draw_glints() -> void:
	# Each glint breathes a little out of step with the others, and they
	# fade as the plank itself comes into the light.
	var fade := 1.0 - _shown
	for i in GLINTS.size():
		var phase: float = _time * GLIMMER_SPEED + position.x * 0.07 + position.y * 0.11 + i * 1.9
		var a := GLIMMER * fade * maxf(0.0, sin(phase))
		if a > 0.02:
			_glint.draw_rect(Rect2(GLINTS[i], Vector2(2, 1)), Color(_glint_color, a))
