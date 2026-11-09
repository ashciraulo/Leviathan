class_name HookPost
extends StaticBody2D
## A mooring bollard with an iron ring: the Tide Hook bites into it and
## carries Wren across.


func _ready() -> void:
	add_to_group("hook_post")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(10, 8), Vector2(0, -4)))
	add_child(Art.shadow())
	add_child(Art.sprite(HullSprites.HOOK_POST, 1, 1, 19))
