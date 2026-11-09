class_name BoneWall
extends StaticBody2D
## Bone that blocks a way through, and that the Echo Horn's note brings
## down. A barricade (%) is a heap of bones anyone can see. A concealed wall
## ($) looks just like the barrow's wall (the room draws it as wall) with
## only a hairline crack to give it away. Both come back when Wren leaves
## the room, like rocks do.

var concealed := false
var tile := Vector2i.ZERO
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("echo")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(16, 16), Vector2(0, -4)))
	if concealed:
		return
	add_child(Art.shadow())
	_sprite = Art.sprite(TombSprites.BARRICADE, 1, 1, 22)
	add_child(_sprite)


func horn_hit(_from: Vector2) -> void:
	if is_queued_for_deletion():
		return
	var room := get_parent() as Room
	if room and concealed:
		room.break_wall(tile)
	KilnDebris.burst(get_parent(), global_position + Vector2(0, -6), 9, TombSprites.BONE_SHARD)
	Audio.play_sfx("bone_crumble", global_position)
	Feel.shake(2.0)
	queue_free()


func _draw() -> void:
	if not concealed:
		return
	# The hairline crack.
	var c := Color(0.1, 0.07, 0.06, 0.55)
	draw_line(Vector2(-2, -11), Vector2(1, -6), c)
	draw_line(Vector2(1, -6), Vector2(-1, -1), c)
	draw_line(Vector2(1, -6), Vector2(4, -4), c)
