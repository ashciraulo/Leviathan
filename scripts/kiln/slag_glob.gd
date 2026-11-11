class_name SlagGlob
extends Projectile
## A glob of molten slag the Slagwyrm spits once it's hurting.


## Molten slag burns through all but nacre.
func _init() -> void:
	super()
	shield_tier = 3


func _ready() -> void:
	super._ready()
	_sprite.texture = KilnSprites.SLAG_GLOB
