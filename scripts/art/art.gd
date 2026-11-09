class_name Art
extends Object
## Loads the generated pixel art (see tools/build_art.py) and builds sprites.
## Sprites use a small shader for the white hit flash.

const WREN := preload("res://assets/sprites/wren.png")
const SWORD := preload("res://assets/sprites/sword.png")
const SCUTTLER := preload("res://assets/sprites/scuttler.png")
const SPITTER := preload("res://assets/sprites/spitter.png")
const BOGSKIPPER := preload("res://assets/sprites/bogskipper.png")
const LANTERNMOTH := preload("res://assets/sprites/lanternmoth.png")
const SLAGBEETLE := preload("res://assets/sprites/slagbeetle.png")
const GEYSER := preload("res://assets/sprites/geyser.png")
const SPORECAP := preload("res://assets/sprites/sporecap.png")
const SPORE_CLOUD := preload("res://assets/sprites/spore_cloud.png")
const SHELLBACK := preload("res://assets/sprites/shellback.png")
const TIDESTONE := preload("res://assets/sprites/tidestone.png")
const SHOT := preload("res://assets/sprites/shot.png")
const SHADOW_SMALL := preload("res://assets/sprites/shadow_small.png")
const SHADOW_LARGE := preload("res://assets/sprites/shadow_large.png")
const BUBBLES := preload("res://assets/ui/bubbles.png")
const TITLE_LOGO := preload("res://assets/ui/title_logo.png")
const TITLE_BG := preload("res://assets/ui/title_bg.png")
const POT := preload("res://assets/props/pot.png")
const BARREL := preload("res://assets/props/barrel.png")
const FENCE := preload("res://assets/props/fence.png")
const SIGN := preload("res://assets/props/sign.png")
const HUT := preload("res://assets/props/hut.png")
const LIGHTHOUSE := preload("res://assets/props/lighthouse.png")
const WORLD_TILES := preload("res://assets/tiles/world.png")
const MANGROVE := preload("res://assets/props/mangrove.png")
const WRECK := preload("res://assets/props/wreck.png")
const LANTERN_POST := preload("res://assets/props/lantern_post.png")
const HULL := preload("res://assets/props/hull.png")
const HESSA := preload("res://assets/sprites/hessa.png")
const CHEST := preload("res://assets/sprites/chest.png")
const LOCKED_HATCH := preload("res://assets/sprites/locked_hatch.png")
const SMALL_KEY := preload("res://assets/sprites/small_key.png")
const VILLAGER_CORRIN := preload("res://assets/sprites/villager_corrin.png")
const VILLAGER_PELL := preload("res://assets/sprites/villager_pell.png")
const VILLAGER_MARGA := preload("res://assets/sprites/villager_marga.png")
const VILLAGER_DUNSTAN := preload("res://assets/sprites/villager_dunstan.png")
const MANTLE := preload("res://assets/sprites/mantle.png")
const FLIGHT_SKY := preload("res://assets/ui/flight_sky.png")
const FLIGHT_CLOUDS := preload("res://assets/ui/flight_clouds.png")
const FLIGHT_SEA := preload("res://assets/ui/flight_sea.png")
const PORTRAIT_HESSA := preload("res://assets/portraits/hessa.png")
const PORTRAIT_CORRIN := preload("res://assets/portraits/corrin.png")
const PORTRAIT_PELL := preload("res://assets/portraits/pell.png")
const PORTRAIT_MARGA := preload("res://assets/portraits/marga.png")
const PORTRAIT_DUNSTAN := preload("res://assets/portraits/dunstan.png")

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
