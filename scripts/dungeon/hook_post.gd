class_name HookPost
extends StaticBody2D
## A mooring bollard with an iron ring: the Tide Hook bites into it and
## carries Wren across.


func _ready() -> void:
	add_to_group("hook_post")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(10, 8), Vector2(0, -4)))
	# The chain flies at Wren's hand height; this lets a sideways throw from
	# anywhere in the same row bite the ring.
	var catch := Area2D.new()
	Layers.assign(catch, Layers.ENEMY_HURTBOX, [])
	catch.monitoring = false
	catch.add_child(Layers.rect_shape(Vector2(12, 18), Vector2(0, -9)))
	add_child(catch)
	add_child(Art.shadow())
	add_child(Art.sprite(HullSprites.HOOK_POST, 1, 1, 19))
