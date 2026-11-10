class_name Darkness
extends Node2D
## Makes a dark room dark (Room.dark). Wren carries a faint glow of their own;
## with the Glowmoth Lantern raised it opens out into a wide circle. Lit
## braziers and the mire's own glowing things (every Glow in the room) add
## lights of their own.
##
## One sheet over the whole room, multiplying what's under it by the dark
## and letting the lights through, all in a single shader pass. (A
## CanvasModulate with PointLight2Ds looked the same, but in the web build's
## renderer each light redrew the whole room again: half speed.)

const DARK := Color(0.15, 0.12, 0.26)
const LANTERN_COLOR := Color(1.0, 0.95, 0.8)
## Above everything in the room (Wren, enemies, props), below the HUD.
const Z := 200
## The most lights the shader takes at once (Wren's is one of them).
const MAX_LIGHTS := 16

const SHADER := """
shader_type canvas_item;
render_mode blend_mul, unshaded;

uniform vec3 dark = vec3(0.15, 0.12, 0.26);
uniform int count = 0;
// Room-local position (xy), radius (z), energy (w); and colour.
uniform vec4 lights[16];
uniform vec3 colors[16];

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec3 light = dark;
	for (int i = 0; i < count; i++) {
		float d = distance(local, lights[i].xy) / lights[i].z;
		if (d < 1.0) {
			// The same falloff as Lantern.light_texture(): full in the
			// middle, 0.85 at 55%, nothing at the edge.
			float a = d < 0.55 ? mix(1.0, 0.85, d / 0.55) : mix(0.85, 0.0, (d - 0.55) / 0.45);
			light += colors[i] * lights[i].w * a;
		}
	}
	COLOR = vec4(min(light, vec3(1.0)), 1.0);
}
"""

static var _shader: Shader

var _radius := Lantern.GLOW
## How dark it has got (0 clear, 1 fully dark): a room sliding in starts clear.
var _amount := 0.0
var _sheet: ColorRect
var _material: ShaderMaterial
var _lights := PackedVector4Array()
var _colors := PackedVector3Array()


func _ready() -> void:
	z_as_relative = false
	z_index = Z
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = _shader
	_sheet = ColorRect.new()
	_sheet.name = "Sheet"
	_sheet.size = Room.SIZE
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.material = _material
	add_child(_sheet)
	_lights.resize(MAX_LIGHTS)
	_colors.resize(MAX_LIGHTS)
	_update(0.0)


func _process(delta: float) -> void:
	_amount = lerpf(_amount, 1.0, minf(delta * 8.0, 1.0))
	var wren := Lantern.player(get_tree())
	if wren != null:
		var want := Lantern.reach(wren) * 1.25 if wren.lantern_raised else Lantern.GLOW
		_radius = move_toward(_radius, want, 220.0 * delta)
	_update(delta)


func _update(_delta: float) -> void:
	_material.set_shader_parameter("dark", Color.WHITE.lerp(DARK, _amount))
	var count := 0
	var wren := Lantern.player(get_tree()) if is_inside_tree() else null
	if wren != null:
		var at := wren.global_position + Vector2(0, -8) - global_position
		_lights[count] = Vector4(at.x, at.y, _radius, 1.0)
		_colors[count] = Vector3(LANTERN_COLOR.r, LANTERN_COLOR.g, LANTERN_COLOR.b)
		count += 1
	if is_inside_tree():
		var room := get_parent()
		for node in get_tree().get_nodes_in_group(Glow.GROUP):
			if count >= MAX_LIGHTS:
				break
			var glow := node as Glow
			if glow == null or not glow.is_visible_in_tree() or room == null or not room.is_ancestor_of(glow):
				continue
			var at := glow.global_position - global_position
			_lights[count] = Vector4(at.x, at.y, glow.radius, glow.energy)
			_colors[count] = Vector3(glow.color.r, glow.color.g, glow.color.b)
			count += 1
	_material.set_shader_parameter("count", count)
	_material.set_shader_parameter("lights", _lights)
	_material.set_shader_parameter("colors", _colors)
