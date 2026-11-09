class_name Projectile
extends DamageArea
## A slow bubble shot. Stops on walls (it flies over water) and on Wren.

const LIFETIME := 4.0

var velocity := Vector2.ZERO
## The weakest shield that turns this shot aside when Wren faces it
## (Items tier: 1 cork, 2 coral, 3 nacre). 0: no shield stops it.
var shield_tier := 1
var _life := LIFETIME
var _sprite: Sprite2D


func _init() -> void:
	# Shots still in the air are cleared when a boss falls.
	add_to_group("enemy_shots")


func _ready() -> void:
	Layers.assign(self, Layers.ENEMY_ATTACK, [Layers.WORLD])
	add_child(Layers.circle_shape(3.0, Vector2.ZERO))
	body_entered.connect(_on_body_entered)
	_sprite = Sprite2D.new()
	_sprite.texture = Art.SHOT
	_sprite.hframes = 2
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
	_sprite.frame = int(_life * 8.0) % 2


func notify_hit() -> void:
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
