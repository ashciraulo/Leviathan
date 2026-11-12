extends Node
## Walks Wren around every dungeon room with real input, looking for the
## rough edges a player would find:
##   - a snag: a spot the layout calls floor that something solid from the
##     next tile spills onto, or a corner Wren catches on;
##   - an unfair entrance: an enemy within three tiles of a gap Wren comes
##     in by, or a pit or lava pool right in front of it;
##   - a confusing exit: a gap in the border that leads out of the world or
##     meets a wall on the other side.
##
## For each room: the enemies are cleared, then Wren walks a tour between
## the room's exits (one tile in from each gap in the border), its doorways
## and its chests, along the shortest path over plain floor tiles. A leg
## that stops making progress is a snag. Puzzles aren't solved: closed bars,
## crates and hazards are walked around, and a target cut off by them is
## left out.
##
##     godot --headless --fixed-fps 60 res://tests/walker.tscn
## Optional: WALK_ONLY=<dungeon> limits it to one dungeon; WALK_TRACE=1
## prints each room's targets and each leg walked.
## Prints "WALKER PASSED" and exits 0, or lists each snag and exits 1.

const TEST_SLOT := 2
## Layout letters Wren can walk over (floor, plates, and the enemies the
## walker clears away).
const WALKABLE := ".:P=,cbswmegqakxMU&+dt"
## Seconds a leg may go without getting closer before it counts as a snag.
const STALL := 1.2
## Falls tried per room (spread across the room's edges of gaps and lava).
const FALL_TRIES := 6

var _failures := PackedStringArray()
var _legs := 0
var _falls := 0
var _game: Node
var _layouts := {}
## Where the enemies stood as the room opened, before the walker cleared them.
var _enemies_at: Array[Vector2] = []


func _ready() -> void:
	SaveManager.current_slot = TEST_SLOT
	SaveManager.set_aside(TEST_SLOT, "walkerbackup")
	SaveManager.delete_save()
	GameState.reset_new_game()
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(_game)
	await _wait(0.6)
	await _read_through(20.0)
	Events.room_entered.connect(_note_enemies)
	var only := OS.get_environment("WALK_ONLY")
	var rooms := _dungeon_rooms()
	_check_exits(rooms)
	for coord: Vector2i in rooms:
		if only != "" and rooms[coord] != only:
			continue
		await _walk_room(coord, rooms[coord])
	SaveManager.delete_save()
	SaveManager.restore_aside(TEST_SLOT, "walkerbackup")
	if _failures.is_empty():
		print("WALKER PASSED (%d rooms, %d legs, %d falls)" % [rooms.size(), _legs, _falls])
		get_tree().quit(0)
	else:
		print("WALKER FAILED: %d snags in %d legs" % [_failures.size(), _legs])
		get_tree().quit(1)


func _dungeon_rooms() -> Dictionary:
	var out := {}
	var names := Array(DirAccess.get_files_at("res://rooms/"))
	names.sort()
	for file: String in names:
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tscn") or not name.begins_with("room_"):
			continue
		var room: Room = (load("res://rooms/" + name) as PackedScene).instantiate()
		var parts := name.trim_prefix("room_").trim_suffix(".tscn").split("_")
		var coord := Vector2i(int(parts[0]), int(parts[1]))
		_layouts[coord] = Room.parse_layout(room.layout)
		if room.dungeon != "":
			out[coord] = room.dungeon
		room.free()
	return out


## Every gap in a dungeon room's border leads somewhere: into a room next
## door that has a gap of its own on the same tile.
func _check_exits(rooms: Dictionary) -> void:
	for coord: Vector2i in rooms:
		var rows: PackedStringArray = _layouts[coord]
		for x in Room.COLS:
			_check_exit(rooms[coord], coord, rows, Vector2i(x, 0), Vector2i.UP)
			_check_exit(rooms[coord], coord, rows, Vector2i(x, Room.ROWS - 1), Vector2i.DOWN)
		for y in Room.ROWS:
			_check_exit(rooms[coord], coord, rows, Vector2i(0, y), Vector2i.LEFT)
			_check_exit(rooms[coord], coord, rows, Vector2i(Room.COLS - 1, y), Vector2i.RIGHT)


func _check_exit(dungeon: String, coord: Vector2i, rows: PackedStringArray, edge: Vector2i, out: Vector2i) -> void:
	# A doorway (D) leads back out to the overworld.
	if rows[edge.y][edge.x] in ["#", "D"]:
		return
	var next := coord + out
	if not _layouts.has(next):
		_fail("%s %s: the gap at %s leads out of the world" % [dungeon, coord, edge])
		return
	var far := Vector2i(posmod(edge.x + out.x, Room.COLS), posmod(edge.y + out.y, Room.ROWS))
	var other: PackedStringArray = _layouts[next]
	if other[far.y][far.x] == "#":
		_fail("%s %s: the gap at %s meets a wall in %s" % [dungeon, coord, edge, next])


func _walk_room(coord: Vector2i, dungeon: String) -> void:
	var room := await _goto(coord)
	if room == null or room.coord != coord:
		if OS.get_environment("WALK_TRACE") != "":
			print("  wanted %s, in %s, busy %s" % [coord, room.coord if room else null, _game.busy])
		_fail("%s %s: couldn't enter the room" % [dungeon, coord])
		return
	# Bosses and their arenas are fights, not walks.
	if not get_tree().get_nodes_in_group("boss").is_empty():
		return
	_hold_breath()
	await get_tree().physics_frame
	var walk := _walkable(room)
	await get_tree().physics_frame
	_check_floor(room, dungeon, walk)
	_check_entrances(room, dungeon, walk)
	await _check_falls(room, dungeon, walk)
	var targets := _targets(room, walk)
	if OS.get_environment("WALK_TRACE") != "":
		print("  %s %s: %d targets %s" % [dungeon, coord, targets.size(), targets])
	if targets.size() < 2:
		return
	# Tour: each target to the next one it can reach.
	for i in targets.size():
		var from: Vector2i = targets[i]
		for j in range(i + 1, targets.size()):
			var path := _path(walk, from, targets[j])
			if path.is_empty():
				continue
			if not await _walk(room, dungeon, path):
				return
			break


## The tiles Wren should be able to walk on, by the layout.
func _walkable(room: Room) -> Dictionary:
	var out := {}
	var flooded := room.flooded()
	for y in Room.ROWS:
		for x in Room.COLS:
			var t := room.raw_tile(x, y)
			if t == "," and flooded:
				continue
			if WALKABLE.contains(t):
				out[Vector2i(x, y)] = true
	return out


## Every floor tile has room for Wren to stand: nothing solid spills onto
## it from a neighbouring tile (a prop's body, a door frame, a wall).
func _check_floor(room: Room, dungeon: String, walk: Dictionary) -> void:
	var space: PhysicsDirectSpaceState2D = (_game.player as Player).get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 6)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = (_game.player as Player).collision_mask
	query.exclude = [(_game.player as Player).get_rid()]
	for tile: Vector2i in walk:
		query.transform = Transform2D(0.0, _foot(room, tile) + Vector2(0, -3))
		for hit in space.intersect_shape(query, 4):
			var by: Object = hit.collider
			if by is Node and (by as Node).get_parent() is Enemy:
				continue
			# Something placed on the tile itself (a story item, a sign) is
			# meant to be walked around; only a body spilling over from
			# another tile is a snag.
			if by is Node2D and Vector2i(((by as Node2D).global_position - room.global_position) / Room.TILE) == tile:
				continue
			_fail("%s %s: floor tile %s is blocked by %s" % [dungeon, room.coord, tile, _describe(by)])
			break


func _describe(node: Object) -> String:
	if node is Node:
		var n := node as Node
		var parent := n.get_parent()
		var at := (n as Node2D).global_position - (_game.current_room as Room).global_position if n is Node2D else Vector2.ZERO
		var shapes := PackedStringArray()
		for c in n.get_children():
			if c is CollisionShape2D:
				shapes.append("%s at %s" % [(c as CollisionShape2D).shape.get_rect().size if (c as CollisionShape2D).shape else null, (c as Node2D).position])
		return "%s (%s) at %s %s, under %s (%s)" % [n.name, n.get_script().get_global_name() if n.get_script() else n.get_class(), at, shapes, parent.name, parent.get_script().get_global_name() if parent.get_script() else parent.get_class()]
	return str(node)


## One tile in from each gap in the border, in front of each doorway, and
## below each chest.
func _targets(room: Room, walk: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in Room.COLS:
		_add_target(out, walk, Vector2i(x, 0), Vector2i(x, 1))
		_add_target(out, walk, Vector2i(x, Room.ROWS - 1), Vector2i(x, Room.ROWS - 2))
	for y in Room.ROWS:
		_add_target(out, walk, Vector2i(0, y), Vector2i(1, y))
		_add_target(out, walk, Vector2i(Room.COLS - 1, y), Vector2i(Room.COLS - 2, y))
	for y in Room.ROWS:
		for x in Room.COLS:
			if room.raw_tile(x, y) in ["C", "D", "G", "X"]:
				for below in [Vector2i(x, y + 1), Vector2i(x, y - 1), Vector2i(x - 1, y), Vector2i(x + 1, y)]:
					if walk.has(below) and not out.has(below):
						out.append(below)
						break
	return out


## Only the first tile of a wide gap, so a three-tile exit is one target.
func _add_target(out: Array[Vector2i], walk: Dictionary, edge: Vector2i, inner: Vector2i) -> void:
	if not walk.has(edge) or not walk.has(inner) or out.has(inner):
		return
	var along := Vector2i(1, 0) if edge.y == 0 or edge.y == Room.ROWS - 1 else Vector2i(0, 1)
	if walk.has(edge - along):
		return
	out.append(inner)


func _path(walk: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var came := {from: from}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		if at == to:
			break
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next: Vector2i = at + step
			if walk.has(next) and not came.has(next) and next.x > 0 and next.y > 0 and next.x < Room.COLS - 1 and next.y < Room.ROWS - 1:
				came[next] = at
				queue.append(next)
	var out: Array[Vector2i] = []
	if not came.has(to):
		return out
	var at := to
	while at != from:
		out.push_front(at)
		at = came[at]
	out.push_front(from)
	return out


## Walks one leg. False when Wren was carried out of the room (the room is
## gone then, so the rest of its tour is skipped).
func _walk(room: Room, dungeon: String, path: Array[Vector2i]) -> bool:
	_legs += 1
	_hold_breath()
	var player: Player = _game.player
	_keep_safe()
	player.velocity = Vector2.ZERO
	player.global_position = _foot(room, path[0])
	await get_tree().physics_frame
	await get_tree().physics_frame
	var i := 1
	var best := INF
	var since := 0.0
	while i < path.size():
		if _game.current_room != room or _game.busy:
			_release()
			_fail("%s %s: left the room walking %s -> %s" % [dungeon, room.coord, path[0], path[-1]])
			await _goto(room.coord)
			return false
		var target := _foot(room, path[i])
		var d := target - player.global_position
		if d.length() < 2.5:
			i += 1
			best = INF
			since = 0.0
			continue
		_steer(d)
		await get_tree().physics_frame
		var left := (target - player.global_position).length()
		if left < best - 0.25:
			best = left
			since = 0.0
		else:
			since += get_physics_process_delta_time()
			if since > STALL:
				_release()
				var at := Vector2i(((player.global_position - room.global_position) / Room.TILE).floor())
				_fail("%s %s: stuck at tile %s heading for %s (leg %s -> %s)" % [dungeon, room.coord, at, path[i], path[0], path[-1]])
				return true
	_release()
	if OS.get_environment("WALK_TRACE") != "":
		print("  %s %s: walked %s -> %s (%d tiles), ended %s" % [dungeon, room.coord, path[0], path[-1], path.size(), player.global_position - room.global_position])
	return true


## Falls: Wren walks off the edge into a gap or a lava pool from up to
## FALL_TRIES spots around the room, and must climb back out onto solid
## floor (not into the drop again, not into a wall) and walk on from there.
## Returns false if Wren ended up out of the room (the room is gone).
func _check_falls(room: Room, dungeon: String, walk: Dictionary) -> bool:
	var lips: Array = []
	for at: Vector2i in walk:
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var t := room.raw_tile(at.x + d.x, at.y + d.y)
			if t in ["_", "^"] and not (room.falls_through and t == "_"):
				# Wren needs a tile of run-up behind them.
				if walk.has(at - d):
					lips.append([at, d])
				break
	if lips.is_empty():
		return true
	lips.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y * 100 + a[0].x < b[0].y * 100 + b[0].x)
	var step := maxi(1, lips.size() / FALL_TRIES)
	var player: Player = _game.player
	var fell_here := 0
	for k in range(0, lips.size(), step):
		var from: Vector2i = lips[k][0]
		var dir: Vector2i = lips[k][1]
		_hold_breath()
		_keep_safe()
		player.velocity = Vector2.ZERO
		# A tile back, then a moment standing there so the floor is remembered.
		player.global_position = _foot(room, from - dir)
		await _wait(0.6)
		_steer(Vector2(dir) * 16.0)
		var fell := false
		var waited := 0.0
		while waited < 2.0 and not fell:
			await get_tree().physics_frame
			waited += get_physics_process_delta_time()
			fell = player.state == Player.State.FALL
		_release()
		if not fell:
			# Something in the way (a crate, closed bars, a ledge): not a fall.
			continue
		_falls += 1
		fell_here += 1
		waited = 0.0
		while waited < 4.0 and player.state == Player.State.FALL:
			await get_tree().physics_frame
			waited += get_physics_process_delta_time()
		await _wait(0.3)
		var where := "%s %s: fell in at %s going %s" % [dungeon, room.coord, from, dir]
		if _game.current_room != room:
			_fail("%s, and came back in another room" % where)
			await _goto(room.coord)
			return false
		var tile := Vector2i(((player.global_position - room.global_position) / Room.TILE).floor())
		if player.state == Player.State.FALL:
			_fail("%s, and is still falling" % where)
		elif room.raw_tile(tile.x, tile.y) in ["_", "^"]:
			_fail("%s, and came back on the drop at %s" % [where, tile])
		else:
			var free := 0
			for d: Vector2 in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
				if not player.test_move(player.global_transform, d):
					free += 1
			if free < 2:
				_fail("%s, and came back wedged at %s (%d of 4 ways open)" % [where, tile, free])
	# Every try blocked would mean the check checked nothing.
	if fell_here == 0:
		_fail("%s %s: Wren couldn't walk into any of its %d drops" % [dungeon, room.coord, lips.size()])
	return true


## The Maw's palate floor (",") floods and drains on the Old One's breath:
## keep it dry (seven seconds of out-breath) so each leg sees the same floor.
func _hold_breath() -> void:
	MawBreath.elapsed = 0.0
	if _game.current_room:
		(_game.current_room as Room).refresh_water()


## Presses the move keys toward the next tile: the far axis first, both
## only when the near one is well off (as a player would on a corner).
func _steer(d: Vector2) -> void:
	_release()
	if absf(d.x) > 1.5:
		Input.action_press("move_right" if d.x > 0 else "move_left")
	if absf(d.y) > 1.5:
		Input.action_press("move_down" if d.y > 0 else "move_up")


func _release() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)


func _foot(room: Room, tile: Vector2i) -> Vector2:
	return room.global_position + Vector2(tile.x * Room.TILE + Room.TILE / 2.0, tile.y * Room.TILE + 12)


func _goto(coord: Vector2i) -> Room:
	for i in 3:
		await _settle()
		_keep_safe()
		Events.door_entered.emit(coord, _open_tile(coord))
		await _settle()
		if _game.current_room and _game.current_room.coord == coord:
			break
	await _read_through(10.0)
	_keep_safe()
	await _wait(0.2)
	return _game.current_room


## A plain floor tile, as near the middle of the room as possible.
func _open_tile(coord: Vector2i) -> Vector2i:
	var rows: PackedStringArray = _layouts.get(coord, PackedStringArray())
	var best := Vector2i(Room.COLS / 2, Room.ROWS / 2)
	var best_d := INF
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] != ".":
				continue
			var d := Vector2(x - Room.COLS / 2.0, y - Room.ROWS / 2.0).length()
			if d < best_d:
				best_d = d
				best = Vector2i(x, y)
	return best


func _note_enemies(_coord: Vector2i) -> void:
	_enemies_at.clear()
	var room: Room = _game.current_room
	for node in room.find_children("*", "", true, false):
		if node is Enemy and not node.is_in_group("boss"):
			_enemies_at.append((node as Node2D).global_position - room.global_position)


## Fair entrances: Wren never steps into a room with an enemy at arm's
## length, or a pit or lava right in front of them.
func _check_entrances(room: Room, dungeon: String, walk: Dictionary) -> void:
	for x in Room.COLS:
		_check_entrance(room, dungeon, walk, Vector2i(x, 0), Vector2i.DOWN)
		_check_entrance(room, dungeon, walk, Vector2i(x, Room.ROWS - 1), Vector2i.UP)
	for y in Room.ROWS:
		_check_entrance(room, dungeon, walk, Vector2i(0, y), Vector2i.RIGHT)
		_check_entrance(room, dungeon, walk, Vector2i(Room.COLS - 1, y), Vector2i.LEFT)


func _check_entrance(room: Room, dungeon: String, walk: Dictionary, edge: Vector2i, inward: Vector2i) -> void:
	# Gaps, hatches, big-key doors and doorways are all ways in.
	if not walk.has(edge) and not room.raw_tile(edge.x, edge.y) in ["X", "G", "D"]:
		return
	var at := _foot(room, edge) - room.global_position
	for enemy in _enemies_at:
		if enemy.distance_to(at) < Room.TILE * 3.0:
			_fail("%s %s: an enemy waits %d px from the entrance at %s" % [dungeon, room.coord, int(enemy.distance_to(at)), edge])
			break
	for step in 2:
		var t := room.raw_tile(edge.x + inward.x * (step + 1), edge.y + inward.y * (step + 1))
		if t in ["_", "^"]:
			_fail("%s %s: a %s %d tile(s) in from the entrance at %s" % [dungeon, room.coord, "pit" if t == "_" else "lava pool", step + 1, edge])
			break


func _settle() -> void:
	await _wait(0.1)
	for i in 60:
		_advance_dialogue()
		if not _game.busy and _game.current_room != null:
			return
		await _wait(0.1)


func _advance_dialogue() -> void:
	for child in _game.get_children():
		if child is DialogueBox and DialogueBox.is_open:
			child.advance()
			child.advance()


func _read_through(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds:
		await _wait(0.05)
		waited += 0.05
		if DialogueBox.is_open:
			_advance_dialogue()
		elif not Cutscene.active and waited > 0.3:
			break


func _keep_safe() -> void:
	if _game.player:
		_game.player._invuln = 60.0
	GameState.refill()
	if _game.current_room:
		for node in _game.current_room.find_children("*", "", true, false):
			if (node is Enemy and not node.is_in_group("boss")) or node is Projectile:
				node.queue_free()


## Prints each snag as it's found, so a run that dies early still shows them.
func _fail(what: String) -> void:
	_failures.append(what)
	printerr("SNAG: " + what)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
