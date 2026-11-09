class_name SingingSkull
extends StaticBody2D
## A skull on a cairn (Z). The Echo Horn's note wakes it, and it sings the
## note back for a few seconds before it falls quiet. A room whose gate is
## "skulls" opens once every skull in it is singing at the same time.

signal changed

## How long a skull keeps singing.
const SING_TIME := 5.0

var lit := false
var _left := 0.0
var _held := false
var _sprite: Sprite2D
var _hum := 0.0


func _ready() -> void:
	add_to_group("echo")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 10), Vector2(0, -5)))
	add_child(Art.shadow())
	_sprite = Art.sprite(TombSprites.SINGING_SKULL, 2, 1, 18)
	add_child(_sprite)


func horn_hit(_from: Vector2) -> void:
	_left = SING_TIME
	if lit:
		return
	lit = true
	_sprite.frame = 1
	Audio.play_sfx("skull_sing", global_position)
	changed.emit()


## Singing for good (the room's gate is solved).
func hold_open() -> void:
	_held = true
	lit = true
	_sprite.frame = 1
	_sprite.visible = true


func _physics_process(delta: float) -> void:
	if not lit:
		return
	_hum += delta
	# A little tremble while it sings.
	_sprite.offset.x = 0.5 if int(_hum * 20.0) % 2 == 0 else -0.5
	if _held:
		return
	_left -= delta
	# Fading as it's about to stop.
	_sprite.modulate.a = 1.0 if _left > 1.2 or int(_left * 8.0) % 2 == 0 else 0.6
	if _left <= 0.0:
		lit = false
		_sprite.frame = 0
		_sprite.offset.x = 0.0
		_sprite.modulate.a = 1.0
		Audio.play_sfx("skull_quiet", global_position)
		changed.emit()
