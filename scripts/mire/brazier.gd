class_name Brazier
extends StaticBody2D
## A stone bowl of old lamp-moss. Hold the raised Glowmoth Lantern close and
## it catches, and stays lit. A room whose gate is "braziers" opens once
## every brazier in it burns.

signal changed

const REACH := 26.0

var lit := false
var _sprite: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	add_to_group("braziers")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 8), Vector2(0, -4)))
	add_child(Art.shadow())
	_sprite = Art.sprite(MireSprites.BRAZIER, 2, 1, 18)
	add_child(_sprite)
	_light = Lantern.make_light(48.0, Color(0.6, 1.0, 0.85), 0.9)
	_light.position = Vector2(0, -12)
	# Unlit, a few embers of moss still glow, so it can be found in the dark.
	_light.texture_scale = 14.0 / 128.0
	_light.energy = 0.5
	add_child(_light)


func _physics_process(_delta: float) -> void:
	if lit:
		return
	var wren := Lantern.player(get_tree())
	if wren and wren.lantern_raised and wren.global_position.distance_to(global_position) <= REACH:
		light()


## Catch light (quietly when `quiet`, e.g. a solved room loading).
func light(quiet := false) -> void:
	if lit:
		return
	lit = true
	_sprite.frame = 1
	_light.texture_scale = 48.0 / 128.0
	_light.energy = 0.9
	if not quiet:
		Audio.play_sfx("brazier_catch", global_position)
		Feel.shake(0.6)
	changed.emit()
