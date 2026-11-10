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
		_draft()
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


## A concealed wall breathes: the barrow's air leaks through its seam as a
## thin drift of bone dust, out into the room. That's what sets it apart
## from the barrow's ordinary cracked walls.
func _draft() -> void:
	var dust := BoneDraft.new()
	var into := _into_room()
	dust.direction = into
	# Along the seam, across the way the air comes out.
	dust.extents = Vector2(1, 6) if into.x != 0 else Vector2(6, 1)
	dust.position = Vector2(0, -4) + into * 7.0
	dust.z_index = 1
	add_child(dust)


## Which way the room is from this wall tile. A wall in the room's border
## faces in; one inside the room faces the first open tile beside it, down
## and across before up, so the dust drifts out where Wren comes upon it.
func _into_room() -> Vector2:
	if tile.x <= 0:
		return Vector2.RIGHT
	if tile.x >= Room.COLS - 1:
		return Vector2.LEFT
	if tile.y <= 0:
		return Vector2.DOWN
	if tile.y >= Room.ROWS - 1:
		return Vector2.UP
	var room := get_parent() as Room
	if room:
		for dir in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]:
			if not room.tile_at(tile.x + dir.x, tile.y + dir.y) in ["#", "$", "%", "!"]:
				return Vector2(dir)
	return Vector2.UP


func _draw() -> void:
	if not concealed:
		return
	# The crack, darker than the barrow's own, with a pale lip of dust.
	var c := Color(0.08, 0.05, 0.04, 0.8)
	var lip := Color(0.9, 0.86, 0.74, 0.5)
	draw_line(Vector2(-2, -12), Vector2(1, -7), c)
	draw_line(Vector2(1, -7), Vector2(-1, -2), c)
	draw_line(Vector2(-1, -2), Vector2(1, 3), c)
	draw_line(Vector2(1, -7), Vector2(4, -5), c)
	draw_line(Vector2(2, -12), Vector2(3, -7), lip)
	draw_line(Vector2(0, -2), Vector2(2, 3), lip)
