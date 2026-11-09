class_name FeatherDart
extends Projectile
## A storm feather the Stormheron flings from its perch.


func _ready() -> void:
	super._ready()
	# Feathers fly over the open sky; only walls stop them.
	_sprite.texture = GaleSprites.FEATHER_DART
	_sprite.hframes = 1
	_sprite.rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
