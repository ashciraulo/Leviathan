class_name DamageArea
extends Area2D
## Anything that hurts Wren on contact. Wren's hurtbox looks for these.

@export var damage := 1
## Turned off while the owner is dying.
var active := true


## Called after this area hurts Wren. Projectiles free themselves here.
func notify_hit() -> void:
	pass
