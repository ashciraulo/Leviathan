class_name PitField
extends Node2D
## Every gap (_) in a room's deck, and every pool of lava (^). Draws them,
## keeps enemies and crates out of them, and drops Wren in when they walk
## in: they lose a bubble and climb back up where they last stood on solid
## ground.
##
## A room with lava_rise set also has rising lava: once Wren is inside, it
## creeps up the room from the bottom row. If it catches them they're thrown
## back to where they came in and it sinks to start again; once they reach
## lava_safe_row it drains away for good.
##
## The Tide Hook carries Wren over both (Player.airborne).

## How often (seconds) Wren's footing is remembered, and how far back the
## safe spot is taken from, so they don't land on the lip and fall again.
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
	# (Not fliers, which nothing in the room stops: their mask is empty; nor
	# floaters that keep to walls but drift over gaps: meta "floats".)
	for child in _room.get_children():
		if (child is Enemy and (child as Enemy).collision_mask != 0 and not child.has_meta("floats")) or child is Crate:
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
	# Wren's feet are a little above their origin.
	var feet := local + Vector2(0, -3)
	_update_rise(delta, local)
	if player.airborne:
		# Crossing over: if they drop short, they're back where they took off.
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
		var tile := _room.tile_at(floori(feet.x / Room.TILE), floori(feet.y / Room.TILE))
		if _room.falls_through and tile == "_":
			player.drop_through(_room.fall_to, _room.fall_spawn)
		else:
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
	# Nothing remembered (they fell the moment they arrived): step back out.
	return fallback + Vector2(0, Room.TILE)


func _near_gap(local: Vector2) -> bool:
	for offset in [Vector2(-6, -3), Vector2(6, -3), Vector2(0, -9), Vector2(0, 3)]:
		if is_gap(local + offset):
			return true
	return false


func _draw() -> void:
	var first := _first_lava_row()
	var gap: String = Room.BIOMES.get(_room.biome, {}).get("gap", "gap")
	for y in Room.ROWS:
		for x in Room.COLS:
			var letter := _room.tile_at(x, y)
			if letter == "_":
				var variant := (x * 7 + y * 3) % 2
				if gap != "gap":
					# Open sky: only now and then a wisp of cloud.
					variant = 1 if (x * 7 + y * 13 + x * y) % 6 == 0 else 0
				_tile("%s_%d" % [gap, variant], x, y)
				# 3/4 view: the far side of the hole shows its broken edge.
				if _room.tile_at(x, y - 1) != "_":
					_tile(gap + "_lip", x, y)
				if _room.tile_at(x - 1, y) != "_":
					_tile(gap + "_left", x, y)
				if _room.tile_at(x + 1, y) != "_":
					_tile(gap + "_right", x, y)
				if _room.tile_at(x, y + 1) != "_":
					_tile(gap + "_bottom", x, y)
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
	if Settings.high_contrast:
		_draw_contrast_edges(first)


## High contrast: a bright line round every pit and every pool of lava, on
## the edges where it meets safe ground.
func _draw_contrast_edges(first: int) -> void:
	for y in Room.ROWS:
		for x in Room.COLS:
			var letter := _room.tile_at(x, y)
			var hazard := letter == "_"
			if not hazard and letter != "#" and (letter == "^" or y >= first):
				hazard = true
			if not hazard:
				continue
			var at := Vector2(x, y) * Room.TILE
			var t := float(Room.TILE)
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if _is_safe(x + side.x, y + side.y, first):
					var a := at + Vector2(maxf(side.x, 0.0) * (t - 1.0), maxf(side.y, 0.0) * (t - 1.0))
					var size := Vector2(1.0, t) if side.x != 0 else Vector2(t, 1.0)
					draw_rect(Rect2(a, size), Palette.CONTRAST_HAZARD)


func _is_safe(x: int, y: int, first: int) -> bool:
	if x < 0 or y < 0 or x >= Room.COLS or y >= Room.ROWS:
		return false
	var letter := _room.tile_at(x, y)
	if letter == "#" or letter == "_":
		return false
	return not (letter == "^" or y >= first)


func _is_lava(x: int, y: int, first: int) -> bool:
	var letter := _room.tile_at(x, y)
	if letter == "#":
		return true  # Walls meet lava with no rim.
	return letter == "^" or y >= first


func _tile(tile_name: String, x: int, y: int) -> void:
	draw_texture_rect_region(Art.WORLD_TILES, Rect2(x * Room.TILE, y * Room.TILE, Room.TILE, Room.TILE), TileAtlas.region(tile_name))
