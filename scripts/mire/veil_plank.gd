class_name VeilPlank
extends StaticBody2D
## A plank of the drowned boardwalk over black water (v). In the dark it's
## only bog; in the raised lantern's light it's there, and Wren can walk on
## it. A plank she's standing on stays put until she steps off.

const FADE_SPEED := 4.0

var _shape: CollisionShape2D
var _shown := 0.0
var _solid := true


func _ready() -> void:
	add_to_group("veil_planks")
	# Like water: blocks walking (and enemies) until it's lit.
	Layers.assign(self, Layers.WATER, [])
	_shape = Layers.rect_shape(Vector2(16, 16), Vector2(0, -4))
	add_child(_shape)
	z_index = -9


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
	var shown := move_toward(_shown, 1.0 if real else 0.0, FADE_SPEED * delta)
	if shown != _shown:
		_shown = shown
		queue_redraw()


func _draw() -> void:
	# The room draws the black water underneath.
	if _shown > 0.0:
		draw_texture(MireSprites.VEIL_PLANK, Vector2(-8, -12), Color(1, 1, 1, _shown))
