class_name PitField
extends Node2D
## Every gap (_) in a room's deck, and every pool of lava (^). Draws them,
## keeps enemies and crates out of them, and drops Wren in when she walks
## in: she loses a bubble and climbs back up where she last stood on solid
## ground.
##
## A room with lava_rise set also has rising lava: once Wren is inside, it
## creeps up the room from the bottom row. If it catches her she's thrown
## back to where she came in and it sinks to start again; once she reaches
## lava_safe_row it drains away for good.
##
## The Tide Hook carries Wren over both (Player.airborne).

## How often (seconds) Wren's footing is remembered, and how far back the
## safe spot is taken from, so she doesn't land on the lip and fall again.
const SAFE_EVERY := 0.1
const SAFE_HISTORY := 8
const SAFE_BACK := 4
## Letters Wren drops into.
const DROPS := "_^"
const LAVA_FRAME_TIME := 0.35
## Seconds before rising lava starts to climb (and after it's reset).
const RISE_GRACE := 1.2
const DRAIN_SPEED := 6.0

var _room: Room
var _safe: Array[Vector2] = []
var _safe_timer := 0.0
var _lava_frame := 0
var _lava_time := 0.0
var _has_lava := false
## Rising lava: the first row it covers (ROWS = none yet).
var level := float(Room.ROWS)
var rising := false
var _rise_grace := RISE_GRACE
var _rise_start := Vector2.INF
var _draining := false


static func rise_flag(coord: Vector2i) -> String:
	return "lava_drained_%d_%d" % [coord.x, coord.y]


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
			if not DROPS.contains(_room.tile_at(x, y)):
				x += 1
				continue
			var start := x
			_has_lava = _has_lava or _room.tile_at(x, y) == "^"
			while x < Room.COLS and DROPS.contains(_room.tile_at(x, y)):
				x += 1
			var size := Vector2((x - start) * Room.TILE - 4, Room.TILE - 4)
			body.add_child(Layers.rect_shape(size, Vector2((start + x) * Room.TILE / 2.0, y * Room.TILE + Room.TILE / 2.0)))
	# Enemies and crates already in the room steer clear of the gaps.
	for child in _room.get_children():
		if child is Enemy or child is Crate:
			(child as CollisionObject2D).collision_mask |= 1 << (Layers.PIT - 1)
	rising = _room.lava_rise > 0.0 and not GameState.has_flag(rise_flag(_room.coord))
	_has_lava = _has_lava or rising


## True when a point (relative to the room) is over a gap or lava.
func is_gap(local: Vector2) -> bool:
	var x := floori(local.x / Room.TILE)
	var y := floori(local.y / Room.TILE)
	var tile := _room.tile_at(x, y)
	return DROPS.contains(tile) or (tile != "#" and y >= _first_lava_row())


## The first row the rising lava covers (Room.ROWS when there's none).
func _first_lava_row() -> int:
	return ceili(level) if rising or _draining else Room.ROWS


func _process(delta: float) -> void:
	if not _has_lava:
		return
	_lava_time += delta
	if _lava_time >= LAVA_FRAME_TIME:
		_lava_time = 0.0
		_lava_frame = 1 - _lava_frame
		queue_redraw()


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.frozen:
		return
	var local := player.global_position - _room.global_position
	if local.x < 0.0 or local.y < 0.0 or local.x > Room.SIZE.x or local.y > Room.SIZE.y:
		return
	# Wren's feet are a little above her origin.
	var feet := local + Vector2(0, -3)
	_update_rise(delta, local)
	if player.airborne:
		# She's crossing over: footing from the far side no longer counts.
		_safe.clear()
		_safe_timer = 0.0
		return
	if player.state in [Player.State.FALL, Player.State.DEAD]:
		return
	if rising and floori(feet.y / Room.TILE) >= _first_lava_row():
		# Caught by the rising lava: back to the way in, and it starts again.
		player.fall(_room.global_position + _rise_start)
		level = float(Room.ROWS)
		_rise_grace = RISE_GRACE + 0.6
		_safe.clear()
		queue_redraw()
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


func _update_rise(delta: float, local: Vector2) -> void:
	if _draining:
		level = minf(level + DRAIN_SPEED * delta, float(Room.ROWS))
		queue_redraw()
		if level >= Room.ROWS:
			_draining = false
		return
	if not rising:
		return
	if _rise_start == Vector2.INF:
		_rise_start = local
	if floori((local.y - 3.0) / Room.TILE) <= _room.lava_safe_row:
		# Made it: the lava drains back into the floor.
		rising = false
		_draining = true
		GameState.set_flag(rise_flag(_room.coord))
		Feel.shake(2.0)
		return
	_rise_grace -= delta
	if _rise_grace > 0.0:
		return
	var before := ceili(level)
	level = maxf(level - _room.lava_rise * delta, float(_room.lava_safe_row + 1))
	if ceili(level) != before:
		Feel.shake(1.0)
		queue_redraw()


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
	var first := _first_lava_row()
	for y in Room.ROWS:
		for x in Room.COLS:
			var letter := _room.tile_at(x, y)
			if letter == "_":
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
			elif letter == "^" or (letter != "#" and y >= first):
				_tile("kiln_lava_%d" % ((_lava_frame + x + y) % 2), x, y)
				if not _is_lava(x, y - 1, first):
					_tile("lava_lip", x, y)
				if not _is_lava(x - 1, y, first):
					_tile("lava_left", x, y)
				if not _is_lava(x + 1, y, first):
					_tile("lava_right", x, y)
				if not _is_lava(x, y + 1, first):
					_tile("lava_bottom", x, y)


func _is_lava(x: int, y: int, first: int) -> bool:
	var letter := _room.tile_at(x, y)
	if letter == "#":
		return true  # Walls meet lava with no rim.
	return letter == "^" or y >= first


func _tile(tile_name: String, x: int, y: int) -> void:
	draw_texture_rect_region(Art.WORLD_TILES, Rect2(x * Room.TILE, y * Room.TILE, Room.TILE, Room.TILE), TileAtlas.region(tile_name))
