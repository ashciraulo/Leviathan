class_name BoneShard
extends Projectile
## A shard of bone the Hollow Regent hurls. Walls stop it.


## Bone splits cork.
func _init() -> void:
	shield_tier = 2


func _ready() -> void:
	super._ready()
	_sprite.texture = TombSprites.BONE_SHARD
	_sprite.hframes = 1


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_sprite.rotation += delta * 12.0
	_life -= delta
	if _life <= 0.0:
		queue_free()
