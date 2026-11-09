class_name GreatBell
extends StaticBody2D
## The great bell tipped on its lip in the middle of the Drowned Bell's
## hall, where Knell lives. A blow from the Stonebreaker rings it.

var knell: Knell
var _sprite: Sprite2D
var _ring := 0.0
var _base_x := 0.0


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(44, 12), Vector2(0, -6)))
	add_child(Art.shadow(true))
	_sprite = Art.sprite(BelfrySprites.GREAT_BELL, 2, 1, 52)
	add_child(_sprite)
	_base_x = _sprite.position.x


func mallet_hit(_direction: Vector2) -> bool:
	_ring = 0.8
	Audio.play_sfx("great_bell", global_position)
	Feel.shake(4.0)
	if knell and is_instance_valid(knell):
		knell.on_bell_rung()
	return true


func _process(delta: float) -> void:
	if _ring <= 0.0:
		return
	_ring -= delta
	_sprite.frame = 1 if _ring > 0.0 else 0
	var shake := (1.0 if int(_ring * 30.0) % 2 == 0 else -1.0) if _ring > 0.0 else 0.0
	_sprite.position.x = _base_x + shake
