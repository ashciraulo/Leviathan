class_name Bars
extends StaticBody2D
## Iron bars across a way through. The room's puzzle opens them.

var is_open := false
## Fixed bars (a cell) never open, whatever the room's gate does.
var fixed := false
var _sprite: Sprite2D
var _shape: CollisionShape2D
## Where the sprite stands when the bars are up.
var _rest_y := 0.0
## The bars' rise or sink, so a new one can cut the last one short.
var _tween: Tween


func _ready() -> void:
	add_to_group("bars")
	Layers.assign(self, Layers.WORLD, [])
	_shape = Layers.rect_shape(Vector2(16, 16), Vector2(0, -4))
	add_child(_shape)
	_sprite = Art.sprite(HullSprites.BARS, 1, 1, 15)
	_sprite.position.y += 4
	_rest_y = _sprite.position.y
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
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_sprite, "position:y", _rest_y + 10, 0.3)
	_tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func() -> void: visible = false)
	Feel.shake(1.0)


## Raise the bars again (a room that shuts Wren in until it's cleared).
func close() -> void:
	is_open = false
	visible = true
	_shape.set_deferred("disabled", false)
	# Spring back up out of the deck, with a clang, the way they sank.
	var rest := _rest_y
	_sprite.position.y = rest + 10.0
	_sprite.modulate.a = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite, "position:y", rest, 0.15)
	_tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)
	Audio.play_sfx("door_slide", global_position)
