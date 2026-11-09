class_name Shade
extends Enemy
## A Shade: a low smear of living dark that creeps after Wren. Out of the
## light nothing touches it, and it's hard to see. Caught in the raised
## lantern's light it rears up and shrinks away, and then the sword can
## find it.

const CREEP_SPEED := 30.0
const FLEE_SPEED := 40.0
const SIGHT := 160.0

var exposed := false
var _sway := 0.0


func _init() -> void:
	max_hp = 2
	body_size = Vector2(14, 8)


func _think(delta: float) -> void:
	_sway += delta
	exposed = Lantern.lights(get_tree(), global_position + Vector2(0, -6))
	var wren := get_player()
	if wren == null:
		velocity = Vector2.ZERO
		return
	var to_wren := wren.global_position - global_position
	if exposed:
		velocity = -to_wren.normalized() * FLEE_SPEED
	elif to_wren.length() < SIGHT:
		velocity = to_wren.normalized() * CREEP_SPEED
	else:
		velocity = Vector2.ZERO


func _blocks_hit(_direction: Vector2) -> bool:
	return not exposed


func _on_blocked(_direction: Vector2) -> void:
	_flash = 0.03


func _make_sprite() -> Sprite2D:
	return Art.sprite(MireSprites.SHADE, 3, 1, 14)


func _update_sprite() -> void:
	_sprite.frame = 2 if exposed else int(_sway * 4.0) % 2
	_sprite.modulate.a = 1.0 if exposed else 0.45
	_sprite.flip_h = velocity.x < 0.0
