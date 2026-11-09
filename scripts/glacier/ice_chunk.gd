class_name IceChunk
extends Projectile
## A chunk of ice Rimeback spits. It flies over water; walls stop it.


func _ready() -> void:
	super._ready()
	_sprite.texture = GlacierSprites.ICE_CHUNK
	_sprite.hframes = 1


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_sprite.rotation += delta * 9.0
	_life -= delta
	if _life <= 0.0:
		queue_free()
