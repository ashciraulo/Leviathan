class_name IceEye
extends StaticBody2D
## An eye frozen in a crystal of ice (E). A frost arrow wakes it, and it
## glows for a few seconds before it shuts again. A room whose gate is
## "eyes" opens once every eye in it is open at the same time.

signal changed

## How long an eye stays open.
const OPEN_TIME := 6.0

var lit := false
var _left := 0.0
var _held := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("ice_eyes")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 10), Vector2(0, -5)))
	add_child(Art.shadow())
	_sprite = Art.sprite(GlacierSprites.ICE_EYE, 2, 1, 22)
	add_child(_sprite)


func arrow_hit(_direction: Vector2) -> void:
	_left = OPEN_TIME
	if lit:
		return
	lit = true
	_sprite.frame = 1
	Audio.play_sfx("ice_eye_open", global_position)
	changed.emit()


## Opened for good (the room's gate is solved).
func hold_open() -> void:
	_held = true
	lit = true
	_sprite.frame = 1


func _physics_process(delta: float) -> void:
	if not lit or _held:
		return
	_left -= delta
	# Blinking as it's about to shut.
	_sprite.visible = _left > 1.5 or int(_left * 8.0) % 2 == 0
	if _left <= 0.0:
		lit = false
		_sprite.visible = true
		_sprite.frame = 0
		Audio.play_sfx("ice_eye_shut", global_position)
		changed.emit()
