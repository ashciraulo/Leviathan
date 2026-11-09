class_name Bars
extends StaticBody2D
## Iron bars across a way through. The room's puzzle opens them.

var is_open := false
## Fixed bars (a cell) never open, whatever the room's gate does.
var fixed := false
var _sprite: Sprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("bars")
	Layers.assign(self, Layers.WORLD, [])
	_shape = Layers.rect_shape(Vector2(16, 16), Vector2(0, -4))
	add_child(_shape)
	_sprite = Art.sprite(HullSprites.BARS, 1, 1, 15)
	_sprite.position.y += 4
	add_child(_sprite)


## Sink the bars into the deck (instant when `quiet`, e.g. on room load).
func open(quiet := false) -> void:
	if is_open:
		return
	is_open = true
	_shape.set_deferred("disabled", true)
	if quiet:
		visible = false
		return
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", _sprite.position.y + 10, 0.3)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: visible = false)
	Feel.shake(1.0)


## Raise the bars again (a room that shuts Wren in until it's cleared).
func close() -> void:
	is_open = false
	visible = true
	_sprite.modulate.a = 1.0
	_shape.set_deferred("disabled", false)
