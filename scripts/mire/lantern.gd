class_name Lantern
extends Object
## The Glowmoth Lantern, Lantern Mire's tool. Wren raises it (item key) and
## lowers it again (same key). Raised, it throws a wide circle of light:
##   * veiled planks in the light become real enough to walk on
##   * braziers it reaches catch light
##   * Shades caught in it shrink back and can be struck
##   * wisps drift towards it (the Pale Congregation's too)
## These helpers answer "is this spot in the lantern's light?".

## How far the raised lantern's light reaches (pixels).
const RADIUS := 72.0
## Wren's own faint glow in a dark room, lantern down.
const GLOW := 26.0

static var _light_texture: Texture2D


static func player(tree: SceneTree) -> Player:
	return tree.get_first_node_in_group("player") as Player


static func is_raised(tree: SceneTree) -> bool:
	var wren := player(tree)
	return wren != null and wren.lantern_raised


## True when `at` (global) is inside the raised lantern's light.
static func lights(tree: SceneTree, at: Vector2, margin: float = 0.0) -> bool:
	var wren := player(tree)
	if wren == null or not wren.lantern_raised:
		return false
	return (wren.global_position + Vector2(0, -8)).distance_to(at) <= RADIUS + margin


## A soft round light, for PointLight2D (256 px across, white in the
## middle fading to nothing at the edge).
static func light_texture() -> Texture2D:
	if _light_texture:
		return _light_texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.55, Color(1, 1, 1, 0.85))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	_light_texture = texture
	return texture


## A PointLight2D of the given radius and colour.
static func make_light(radius: float, color: Color, energy: float = 1.0) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = light_texture()
	light.texture_scale = radius / 128.0
	light.color = color
	light.energy = energy
	return light
