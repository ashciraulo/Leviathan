class_name Prop
extends StaticBody2D
## A solid piece of scenery: one sprite plus a collision footprint at its base.
## Rooms place props by letter (see Room). Big props are anchored at the
## bottom-centre of their tile, and their art can rise over the tiles above.

## letter: [texture, foot row in the sprite, footprint size, large shadow]
const KINDS := {
	"o": [Art.POT, 12, Vector2(12, 8), false],
	"u": [Art.BARREL, 11, Vector2(12, 8), false],
	"f": [Art.FENCE, 11, Vector2(16, 6), false],
	"n": [Art.SIGN, 11, Vector2(6, 6), false],
	"H": [Art.HUT, 44, Vector2(38, 20), true],
	"L": [Art.LIGHTHOUSE, 76, Vector2(22, 12), true],
	"M": [Art.MANGROVE, 60, Vector2(20, 10), true],
	"W": [Art.WRECK, 27, Vector2(40, 14), true],
	"l": [Art.LANTERN_POST, 29, Vector2(6, 4), false],
}

var kind := ""


static func is_prop(letter: String) -> bool:
	return KINDS.has(letter)


func _init(letter: String = "o") -> void:
	kind = letter


func _ready() -> void:
	var spec: Array = KINDS[kind]
	var footprint: Vector2 = spec[2]
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(footprint, Vector2(0, -footprint.y / 2.0)))
	if spec[3]:
		var shade := Art.shadow(true)
		shade.scale = Vector2(footprint.x / 14.0, 1.5)
		add_child(shade)
	add_child(Art.sprite(spec[0], 1, 1, spec[1]))
