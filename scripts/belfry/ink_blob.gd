class_name InkBlob
extends Projectile
## A glob of ink Knell spits from the bell's mouth. It flies over water.


func _ready() -> void:
	super._ready()
	_sprite.texture = BelfrySprites.INK_BLOB
	_sprite.hframes = 1


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_sprite.rotation += delta * 5.0
	_life -= delta
	if _life <= 0.0:
		queue_free()
