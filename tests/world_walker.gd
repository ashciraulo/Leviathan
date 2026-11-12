extends "res://tests/walker.gd"
## The dungeon walker's checks, on every overworld screen:
##   - a snag: a spot the layout calls ground that a prop, a stone or a wall
##     from the next tile spills onto, or a corner Wren catches on;
##   - an unfair entrance: an enemy within three tiles of an edge Wren comes
##     in by;
##   - a confusing exit: open ground at a screen's edge that leads out of
##     the world, or meets a wall or a prop on the screen next door;
##   - a bad landing: every Tidestone sets Wren down (fast travel and
##     checkpoints) on open ground, with room to walk away.
## Ice, sinking sand, tide flats and geysers aren't walked (they move Wren
## on their own), nor is anything a tool opens.
##
##     godot --headless --fixed-fps 60 res://tests/world_walker.tscn
## Optional: WALK_ONLY=<x>,<y> walks one screen; WALK_TRACE=1 prints each
## leg. Prints "WORLD WALK PASSED" and exits 0, or lists each snag and exits 1.

## Ground that can't be walked but still runs off a screen's edge into the
## next one: water, ice, sand, tide flats, the sea bed.
const OPEN_EDGE := "~QrxISy;"


func _init() -> void:
	walkable_letters = ".:P*8pcbswmeqtg0dAa"
	label = "WORLD WALK"


## The layout's ground, less what the scenery's real footprints cover: a
## hut or a wreck stands on more than its own tile, and the tide floods
## the flats. (Those are meant: Wren walks around them. A way through that
## they close shows up as a target no other target reaches.)
func _walkable(room: Room) -> Dictionary:
	var out := super._walkable(room)
	_raw_walk = out.duplicate()
	var space: PhysicsDirectSpaceState2D = (_game.player as Player).get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 6)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = (_game.player as Player).collision_mask
	query.exclude = [(_game.player as Player).get_rid()]
	for tile: Vector2i in out.keys():
		query.transform = Transform2D(0.0, _foot(room, tile) + Vector2(0, -3))
		for hit in space.intersect_shape(query, 4):
			var by: Object = hit.collider
			# Only scenery meant to stand on more than its own tile (props,
			# the market stall, the tide's flood) takes ground away; anything
			# else spilling onto it is left for _check_floor to report.
			# Something set down on the tile itself (a story lantern, a sign)
			# takes it too: Wren walks round it.
			var own := by is Node2D and Vector2i(((by as Node2D).global_position - room.global_position) / Room.TILE) == tile
			if own or (by is Node and ((by as Node).get_parent() is Prop or (by as Node).get_parent() is MarketStall \
					or by is MarketStall or by is Prop or (by as Node).get_parent() is Tide)):
				out.erase(tile)
				break
	return out


## The layout's ground before the footprints come off (see _walkable).
var _raw_walk := {}


## The walk's targets, and a check that no prop's footprint closes a way
## between two of them that the layout leaves open.
func _targets(room: Room, walk: Dictionary) -> Array[Vector2i]:
	var out := super._targets(room, walk)
	var raw := super._targets(room, _raw_walk)
	for i in raw.size():
		for j in range(i + 1, raw.size()):
			if _path(_raw_walk, raw[i], raw[j]).is_empty():
				continue
			if not walk.has(raw[i]) or not walk.has(raw[j]) or _path(walk, raw[i], raw[j]).is_empty():
				_fail("overworld %s: scenery closes the way from %s to %s" % [room.coord, raw[i], raw[j]])
	return out


func _wants(room: Room) -> bool:
	return room.dungeon == ""


func _name_for(room: Room) -> String:
	return "overworld"


func _ready() -> void:
	var only := OS.get_environment("WALK_ONLY")
	if only.contains(","):
		# A screen, not a dungeon: the base walk filters on its name.
		OS.set_environment("WALK_ONLY", "")
		_only = Vector2i(int(only.get_slice(",", 0)), int(only.get_slice(",", 1)))
	await super._ready()


var _only := Vector2i(9999, 9999)


func _rooms_to_walk() -> Dictionary:
	var out := super._rooms_to_walk()
	if _only != Vector2i(9999, 9999):
		var one := {}
		if out.has(_only):
			one[_only] = out[_only]
		# Exits still look next door.
		_check_exits_world(out)
		_exits_checked = true
		return one
	return out


var _exits_checked := false


func _check_exits(rooms: Dictionary) -> void:
	if not _exits_checked:
		_check_exits_world(rooms)


func _check_exits_world(rooms: Dictionary) -> void:
	for coord: Vector2i in rooms:
		var rows: PackedStringArray = _layouts[coord]
		for x in Room.COLS:
			_world_exit(coord, rows, Vector2i(x, 0), Vector2i.UP)
			_world_exit(coord, rows, Vector2i(x, Room.ROWS - 1), Vector2i.DOWN)
		for y in Room.ROWS:
			_world_exit(coord, rows, Vector2i(0, y), Vector2i.LEFT)
			_world_exit(coord, rows, Vector2i(Room.COLS - 1, y), Vector2i.RIGHT)


## Ground at the edge must carry on next door. Water may run off the map
## (it's the sea), but not into a wall.
func _world_exit(coord: Vector2i, rows: PackedStringArray, edge: Vector2i, out: Vector2i) -> void:
	var t := rows[edge.y][edge.x]
	var ground := walkable_letters.contains(t)
	if not ground and not OPEN_EDGE.contains(t):
		return
	var next := coord + out
	if not _layouts.has(next):
		if ground:
			_fail("overworld %s: ground at %s leads out of the world" % [coord, edge])
		return
	var far := Vector2i(posmod(edge.x + out.x, Room.COLS), posmod(edge.y + out.y, Room.ROWS))
	var other: PackedStringArray = _layouts[next]
	var o := other[far.y][far.x]
	if ground and not (walkable_letters.contains(o) or OPEN_EDGE.contains(o)):
		_fail("overworld %s: ground at %s meets '%s' at %s in %s" % [coord, edge, o, far, next])
	elif not ground and o == "#":
		_fail("overworld %s: '%s' at %s meets a wall at %s in %s" % [coord, t, edge, far, next])


## Every Tidestone's landing spot: Wren stands there free, and can walk
## from it to a way out of the screen.
func _extra_checks(rooms: Dictionary) -> void:
	var coords: Array = rooms.keys()
	coords.sort()
	# Screens that change later in the game (the Verge rising, the bones
	# coming down) are walked again as they stand then.
	for coord: Vector2i in coords:
		var info := RoomInfo.get_room(coord)
		var flag := str(info.get("alt_flag", ""))
		if flag == "" or (info.get("alt_rows", PackedStringArray()) as PackedStringArray).is_empty():
			continue
		GameState.set_flag(flag)
		await _walk_room(coord, "overworld (%s)" % flag)
		GameState.set_flag(flag, false)
	for coord: Vector2i in coords:
		var rows: PackedStringArray = _layouts[coord]
		var has_stone := false
		for r in rows:
			has_stone = has_stone or r.contains("T")
		if not has_stone:
			continue
		var landing := RoomInfo.stone_landing(coord)
		var room := await _goto(coord)
		if room == null or room.coord != coord:
			_fail("overworld %s: couldn't enter to check its Tidestone" % [coord])
			continue
		var player: Player = _game.player
		_keep_safe()
		player.velocity = Vector2.ZERO
		player.global_position = room.global_position + landing
		await get_tree().physics_frame
		await get_tree().physics_frame
		var free := 0
		for d: Vector2 in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
			if not player.test_move(player.global_transform, d):
				free += 1
		var tile := Vector2i((landing / Room.TILE).floor())
		if free < 2:
			_fail("overworld %s: the Tidestone sets Wren down wedged at %s (%d of 4 ways open)" % [coord, tile, free])
			continue
		var walk := _walkable(room)
		if not walk.has(tile) and not "xI".contains(room.raw_tile(tile.x, tile.y)):
			_fail("overworld %s: the Tidestone sets Wren down on '%s' at %s" % [coord, room.raw_tile(tile.x, tile.y), tile])
			continue
		var ways := super._targets(room, walk)
		var out := false
		for target in ways:
			if not _path(walk, tile, target).is_empty():
				out = true
				break
		if not out:
			_fail("overworld %s: no path from the Tidestone landing at %s to a way out" % [coord, tile])
