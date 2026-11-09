class_name PitField
extends Node2D
## Every gap (_) in a room's deck. Draws the holes, keeps enemies and crates
## out of them, and drops Wren through when she walks in: she loses a bubble
## and climbs back up where she last stood on solid deck.
##
## The Tide Hook carries Wren over gaps (Player.airborne).

## How often (seconds) Wren's footing is remembered, and how far back the
## safe spot is taken from, so she doesn't land on the lip and fall again.
const SAFE_EVERY := 0.1
const SAFE_HISTORY := 8
const SAFE_BACK := 4

var _room: Room
var _safe: Array[Vector2] = []
var _safe_timer := 0.0


func _ready() -> void:
	_room = get_parent() as Room
	z_index = -9
	# Solid to enemies and crates only (Wren doesn't collide with PIT).
	var body := StaticBody2D.new()
	body.name = "Edges"
	Layers.assign(body, Layers.PIT, [])
	add_child(body)
	for y in Room.ROWS:
		var x := 0
		while x < Room.COLS:
			if _room.tile_at(x, y) != "_":
				x += 1
				continue
			var start := x
			while x < Room.COLS and _room.tile_at(x, y) == "_":
				x += 1
			var size := Vector2((x - start) * Room.TILE - 4, Room.TILE - 4)
			body.add_child(Layers.rect_shape(size, Vector2((start + x) * Room.TILE / 2.0, y * Room.TILE + Room.TILE / 2.0)))
	# Enemies and crates already in the room steer clear of the gaps.
	for child in _room.get_children():
		if child is Enemy or child is Crate:
			(child as CollisionObject2D).collision_mask |= 1 << (Layers.PIT - 1)


## True when a point (relative to the room) is over a gap.
func is_gap(local: Vector2) -> bool:
	return _room.tile_at(floori(local.x / Room.TILE), floori(local.y / Room.TILE)) == "_"


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.frozen:
		return
	var local := player.global_position - _room.global_position
	if local.x < 0.0 or local.y < 0.0 or local.x > Room.SIZE.x or local.y > Room.SIZE.y:
		return
	# Wren's feet are a little above her origin.
	var feet := local + Vector2(0, -3)
	if player.airborne:
		# She's crossing over: footing from the far side no longer counts.
		_safe.clear()
		_safe_timer = 0.0
		return
	if player.state in [Player.State.FALL, Player.State.DEAD]:
		return
	if is_gap(feet):
		player.fall(_room.global_position + _safe_spot(local))
		return
	_safe_timer -= delta
	if _safe_timer <= 0.0:
		_safe_timer = SAFE_EVERY
		_safe.append(local)
		if _safe.size() > SAFE_HISTORY:
			_safe.pop_front()


func _safe_spot(fallback: Vector2) -> Vector2:
	# Prefer a spot from a moment ago that isn't on the lip of a gap.
	for i in range(_safe.size() - 1 - SAFE_BACK, -1, -1):
		if not _near_gap(_safe[i]):
			return _safe[i]
	for i in range(_safe.size() - 1, -1, -1):
		if not is_gap(_safe[i] + Vector2(0, -3)):
			return _safe[i]
	# Nothing remembered (she fell the moment she arrived): step back out.
	return fallback + Vector2(0, Room.TILE)


func _near_gap(local: Vector2) -> bool:
	for offset in [Vector2(-6, -3), Vector2(6, -3), Vector2(0, -9), Vector2(0, 3)]:
		if is_gap(local + offset):
			return true
	return false


func _draw() -> void:
	for y in Room.ROWS:
		for x in Room.COLS:
			if _room.tile_at(x, y) != "_":
				continue
			_tile("gap_%d" % ((x * 7 + y * 3) % 2), x, y)
			# 3/4 view: the far side of the hole shows its broken planks.
			if _room.tile_at(x, y - 1) != "_":
				_tile("gap_lip", x, y)
			if _room.tile_at(x - 1, y) != "_":
				_tile("gap_left", x, y)
			if _room.tile_at(x + 1, y) != "_":
				_tile("gap_right", x, y)
			if _room.tile_at(x, y + 1) != "_":
				_tile("gap_bottom", x, y)


func _tile(tile_name: String, x: int, y: int) -> void:
	draw_texture_rect_region(Art.WORLD_TILES, Rect2(x * Room.TILE, y * Room.TILE, Room.TILE, Room.TILE), TileAtlas.region(tile_name))
