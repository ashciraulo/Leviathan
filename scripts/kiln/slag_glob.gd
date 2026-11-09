class_name SlagGlob
extends Projectile
## A glob of molten slag the Slagwyrm spits once it's hurting.


func _ready() -> void:
	super._ready()
	_sprite.texture = KilnSprites.SLAG_GLOB
