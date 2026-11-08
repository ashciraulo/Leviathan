class_name Projectile
extends DamageArea
## A slow bubble shot. Stops on walls (it flies over water) and on Wren.

const LIFETIME := 4.0

var velocity := Vector2.ZERO
var _life := LIFETIME


func _ready() -> void:
	Layers.assign(self, Layers.ENEMY_ATTACK, [Layers.WORLD])
	add_child(Layers.circle_shape(3.0, Vector2.ZERO))
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
	queue_redraw()


func notify_hit() -> void:
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Palette.OUTLINE)
	draw_circle(Vector2.ZERO, 3.0, Palette.SHOT)
	draw_rect(Rect2(-2, -2, 1, 1), Palette.FLASH)
