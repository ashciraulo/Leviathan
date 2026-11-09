class_name KilnDebris
extends Node2D
## Chips of stone and crust flying out of something the mallet broke.

var _bits: Array = []
var _life := 0.5
var _texture: Texture2D = KilnSprites.WYRM_SHARD


## Adds a burst of `count` chips at `at` (global) to `parent`.
## `texture` is the chip (8x8); stone by default.
static func burst(parent: Node, at: Vector2, count: int, texture: Texture2D = null) -> void:
	var debris := KilnDebris.new()
	if texture:
		debris._texture = texture
	debris.z_index = 3
	for i in count:
		var angle := TAU * i / count + randf_range(-0.3, 0.3)
		debris._bits.append({"pos": Vector2.ZERO, "vel": Vector2.from_angle(angle) * randf_range(40.0, 90.0) + Vector2(0, -40)})
	parent.add_child(debris)
	debris.global_position = at


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	for bit: Dictionary in _bits:
		bit["vel"] += Vector2(0, 260) * delta
		bit["pos"] += bit["vel"] * delta
	queue_redraw()


func _draw() -> void:
	for bit: Dictionary in _bits:
		var at: Vector2 = (bit["pos"] as Vector2).round()
		draw_texture(_texture, at - Vector2(4, 4), Color(1, 1, 1, clampf(_life * 3.0, 0.0, 1.0)))
