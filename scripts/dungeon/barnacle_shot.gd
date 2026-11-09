class_name BarnacleShot
extends Projectile
## A barnacle the Matriarch spits: a hard little shell that tumbles across
## the deck.


func _ready() -> void:
	super._ready()
	_sprite.texture = HullSprites.BARNACLE_SHOT
