class_name Darkness
extends CanvasModulate
## Makes a dark room dark (Room.dark). Wren carries a faint glow of her own;
## with the Glowmoth Lantern raised it opens out into a wide circle. Lit
## braziers and the mire's own glowing things add lights of their own.

const DARK := Color(0.15, 0.12, 0.26)
const LANTERN_COLOR := Color(1.0, 0.95, 0.8)

var _light: PointLight2D
var _radius := Lantern.GLOW


func _ready() -> void:
	# Starts clear and darkens once the room is live, so a room sliding in
	# doesn't darken the one Wren is leaving.
	color = Color.WHITE
	_light = Lantern.make_light(Lantern.GLOW, LANTERN_COLOR)
	_light.name = "WrenLight"
	add_child(_light)


func _process(delta: float) -> void:
	color = color.lerp(DARK, minf(delta * 8.0, 1.0))
	var wren := Lantern.player(get_tree())
	if wren == null:
		return
	_light.global_position = wren.global_position + Vector2(0, -8)
	var want := Lantern.RADIUS * 1.25 if wren.lantern_raised else Lantern.GLOW
	_radius = move_toward(_radius, want, 220.0 * delta)
	_light.texture_scale = _radius / 128.0
