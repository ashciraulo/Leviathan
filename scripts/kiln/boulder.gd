class_name Boulder
extends StaticBody2D
## A cracked basalt boulder. The sword can't touch it; one blow of the
## Stonebreaker Mallet bursts it. Boulders come back when Wren leaves the
## room, like rocks do.

var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("smashable")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(16, 12), Vector2(0, -6)))
	add_child(Art.shadow())
	_sprite = Art.sprite(KilnSprites.BOULDER, 1, 1, 16)
	add_child(_sprite)


## The mallet struck it.
func mallet_hit(_direction: Vector2) -> bool:
	if is_queued_for_deletion():
		return false
	KilnDebris.burst(get_parent(), global_position + Vector2(0, -6), 7)
	Feel.shake(2.0)
	queue_free()
	return true
