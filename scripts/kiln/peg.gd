class_name Peg
extends StaticBody2D
## An iron-capped timber peg standing out of the floor, blocking the way.
## The Stonebreaker Mallet drives it flush with the floor. Pegs stand up
## again when Wren leaves the room.

var down := false
var _sprite: Sprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("smashable")
	Layers.assign(self, Layers.WORLD, [])
	_shape = Layers.rect_shape(Vector2(14, 10), Vector2(0, -5))
	add_child(_shape)
	_sprite = Art.sprite(KilnSprites.PEG, 2, 1, 13)
	add_child(_sprite)


func mallet_hit(_direction: Vector2) -> bool:
	if down:
		return false
	down = true
	_sprite.frame = 1
	z_index = -5
	_shape.set_deferred("disabled", true)
	Audio.play_sfx("hit_shell", global_position, 0.5)
	Feel.shake(1.5)
	return true
