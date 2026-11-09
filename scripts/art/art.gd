class_name Art
extends Object
## Loads the generated pixel art (see tools/build_art.py) and builds sprites.
## Sprites use a small shader for the white hit flash.

const WREN := preload("res://assets/sprites/wren.png")
const SWORD := preload("res://assets/sprites/sword.png")
const SCUTTLER := preload("res://assets/sprites/scuttler.png")
const SPITTER := preload("res://assets/sprites/spitter.png")
const SHELLBACK := preload("res://assets/sprites/shellback.png")
const TIDESTONE := preload("res://assets/sprites/tidestone.png")
const SHOT := preload("res://assets/sprites/shot.png")
const SHADOW_SMALL := preload("res://assets/sprites/shadow_small.png")
const SHADOW_LARGE := preload("res://assets/sprites/shadow_large.png")
const BUBBLES := preload("res://assets/ui/bubbles.png")
const SALTMARROW_TILES := preload("res://assets/tiles/saltmarrow.png")

const FLASH_SHADER := """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
	COLOR = vec4(mix(COLOR.rgb, flash_color.rgb, flash), COLOR.a);
}
"""

static var _flash_shader: Shader


## A sprite whose `foot_row` (the last row of pixels it stands on) sits on
## the node's origin, so y-sorting and shadows line up.
static func sprite(texture: Texture2D, hframes: int, vframes: int, foot_row: int) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = texture
	node.hframes = hframes
	node.vframes = vframes
	node.centered = false
	var frame_width := texture.get_width() / hframes
	node.position = Vector2(-frame_width / 2, -foot_row - 1)
	node.material = flash_material()
	return node


## A soft drop shadow, offset down and to the right (light is top left).
static func shadow(large: bool = false) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = SHADOW_LARGE if large else SHADOW_SMALL
	node.position = Vector2(1, 0)
	return node


static func flash_material() -> ShaderMaterial:
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = FLASH_SHADER
	var material := ShaderMaterial.new()
	material.shader = _flash_shader
	return material


## Sets the flash on a sprite made by sprite(). Respects the soft-flash option.
static func set_flash(node: CanvasItem, amount: float) -> void:
	var material := node.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("flash", amount)
	material.set_shader_parameter("flash_color", Palette.FLASH if Settings.flashes else Palette.SOFT_FLASH)
