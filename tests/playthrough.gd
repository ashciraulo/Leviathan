extends Node
## End-to-end playthrough: one game from a new file, never reset, through
## every dungeon that is built so far, in order. CI runs it with:
##     godot --headless res://tests/playthrough.tscn
## Prints "PLAYTHROUGH PASSED" and exits 0, or lists each failure and exits 1.
##
## The smoke test checks each dungeon on its own, from a fresh GameState.
## This one checks that they fit together: the story scenes fire in order,
## each overworld doorway leads into its dungeon, every room builds, the
## chests hold the big key and the dungeon's item, each boss falls (and the
## music follows), its bell rings, the shaft it leaves leads back out, and
## the game saves and loads between dungeons with nothing lost. It doesn't
## walk between rooms inside a dungeon: tools/*_rooms.py --check covers that.
## Puzzles and fights are skipped: Wren is set down in each room, chests are
## opened by hand, and each boss is brought down with its own _die(), so the
## story and the aftermath that follow are the real ones.
##
## Uses save slot 2, like the smoke test, and keeps a real save safe.

const TEST_SLOT := 2
## Each dungeon in the order the world opens them: [id, entry room, the item
## Wren comes out with]. Keep in step with tools/world_rooms.py.
const DUNGEONS := [
	["hull", Vector2i(10, 10), "tide_hook"],
	["kiln", Vector2i(21, 10), "stonebreaker"],
	["mire", Vector2i(25, 10), "glowmoth_lantern"],
	["gale", Vector2i(28, 10), "kite_cloak"],
	["glacier", Vector2i(32, 10), "frostfang_bow"],
	["belfry", Vector2i(36, 10), "divers_helm"],
	["tomb", Vector2i(40, 10), ""],
	["maw", Vector2i(44, 10), ""],
]

var _failures := PackedStringArray()
var _checks := 0
var _game: Node
## Room coord -> [dungeon, door_to] for every room scene.
var _rooms := {}


func _ready() -> void:
	SaveManager.current_slot = TEST_SLOT
	SaveManager.set_aside(TEST_SLOT, "playthroughbackup")
	SaveManager.delete_save()
	_index_rooms()
	if OS.get_environment("LEVIATHAN_TRACE") != "":
		Events.room_entered.connect(func(c: Vector2i) -> void: print("  entered %s" % c))
		Events.player_died.connect(func() -> void: print("  DIED"))
		Events.door_entered.connect(func(c: Vector2i, t: Vector2i) -> void: print("  door to %s %s" % [c, t]))
	GameState.reset_new_game()
	_game = _new_game()
	await _wait(0.6)
	await _play_scene(20.0)
	_check(_game.current_room != null, "a new game starts in a room")
	# Dungeons are built in order: every one up to the first missing entry
	# room has to be cleared, and none may exist past a gap.
	var built := 0
	while built < DUNGEONS.size() and ResourceLoader.exists(_room_path(DUNGEONS[built][1])):
		built += 1
	for i in range(built, DUNGEONS.size()):
		_check(not ResourceLoader.exists(_room_path(DUNGEONS[i][1])), "%s is built but %s before it isn't" % [DUNGEONS[i][0], DUNGEONS[built][0]])
	var cleared := 0
	for spec: Array in DUNGEONS.slice(0, built):
		var ok: bool = await _dungeon(spec[0], spec[1], spec[2])
		if not ok:
			break
		cleared += 1
		await _save_and_reload(spec[0])
	print("Playthrough cleared %d of %d built dungeons." % [cleared, built])
	_check(cleared == built and built >= 6, "the run clears every built dungeon (%d of %d)" % [cleared, built])
	_game.queue_free()
	await _wait(0.1)
	SaveManager.delete_save()
	SaveManager.restore_aside(TEST_SLOT, "playthroughbackup")
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("PLAYTHROUGH PASSED (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		print("PLAYTHROUGH FAILED (%d of %d checks)" % [_failures.size(), _checks])
		get_tree().quit(1)


## One dungeon, from the overworld doorway that leads to it to walking back
## out after its bell. False when it can't go on (the rest would only fail).
func _dungeon(id: String, entry: Vector2i, item: String) -> bool:
	print("Playthrough: %s" % id)
	# In through the real doorway on the overworld.
	var outside := _door_room_for(entry)
	_check(outside != Vector2i(-999, -999), "%s: an overworld room has its doorway" % id)
	if outside == Vector2i(-999, -999):
		return false
	var room := await _goto(outside)
	await _play_scene(20.0)
	var door := _doorway_to(room, entry)
	_check(door != null, "%s: the doorway in %s is there" % [id, outside])
	if door == null:
		return false
	_keep_safe()
	_game.player.global_position = door.global_position
	await _wait(0.3)
	await _settle()
	await _play_scene(20.0)
	_check(_game.current_room.coord == entry and GameState.dungeon == id, "%s: the doorway leads into its entry room (%s, %s)" % [id, _game.current_room.coord, GameState.dungeon])
	if _game.current_room.coord != entry:
		return false
	# Every room: it builds, its scenes play, its chests open.
	var boss_room := Vector2i(-999, -999)
	var chests := 0
	var way_out := false
	for coord: Vector2i in _rooms_of(id):
		room = await _goto(coord)
		await _play_scene(20.0)
		if room == null or room.coord != coord:
			_check(false, "%s: room %s loads (in %s, busy %s, cutscene %s)" % [id, coord, room.coord if room else null, _game.busy, Cutscene.active])
			continue
		for chest in _all(room, Chest):
			chests += 1
			chest.interact()
			_check(chest.opened, "%s: the chest in %s opens" % [id, coord])
			# Its item's line comes up a moment later: read it through.
			await _wait(1.0)
			await _play_scene(5.0)
		if coord == entry:
			for d: Doorway in _all(room, Doorway):
				way_out = way_out or (_rooms.has(d.target_room) and _rooms[d.target_room][0] == "")
		if not get_tree().get_nodes_in_group("boss").filter(func(b: Node) -> bool: return room.is_ancestor_of(b)).is_empty():
			boss_room = coord
	_check(way_out, "%s: its entry room has a doorway back out" % id)
	_check(chests >= 3, "%s: it has chests (%d)" % [id, chests])
	_check(GameState.has_dungeon_item(id, "big_key"), "%s: its big key is in a chest" % id)
	if item != "":
		_check(GameState.has_item(item), "%s: its item (%s) is in one of its chests" % [id, item])
	# The boss: back to its room, through any scene, and down.
	_check(boss_room != Vector2i(-999, -999), "%s: it has a boss" % id)
	if boss_room != Vector2i(-999, -999):
		room = await _goto(boss_room)
		await _play_scene(25.0)
		await _wait(2.0)
		var bosses := get_tree().get_nodes_in_group("boss").filter(func(b: Node) -> bool: return room.is_ancestor_of(b))
		_check(bosses.size() == 1, "%s: one boss in %s" % [id, boss_room])
		if bosses.size() == 1:
			_check(Audio.music_cue == "boss", "%s: the boss theme plays (%s)" % [id, Audio.music_cue])
			bosses[0]._die()
			_check(GameState.flags.get(bosses[0].DEFEATED_FLAG, false), "%s: its boss falls" % id)
			# The boss's last moments and the aftermath, up to 30 s.
			var deadline := Time.get_ticks_msec() + 30000
			while Time.get_ticks_msec() < deadline and _all(room, Tidebell).is_empty():
				await _play_scene(25.0)
				await _wait(0.5)
			_check(Audio.music_cue == Audio.cue_for_room(room.biome, room.dungeon), "%s: its own music comes back (%s)" % [id, Audio.music_cue])
			var bells := _all(room, Tidebell)
			_check(bells.size() == 1, "%s: its bell rises" % id)
			if bells.size() == 1:
				var before := GameState.item_count("tidebell")
				bells[0].interact()
				await _play_scene(25.0)
				_check(GameState.has_flag(Tidebell.flag_for(bells[0].bell)) and GameState.item_count("tidebell") == before + 1, "%s: ringing its bell counts" % id)
	# Out by the shaft of daylight that opens where the boss fell.
	room = _game.current_room
	var out: Doorway = null
	for d: Doorway in _all(room, Doorway):
		if _rooms.has(d.target_room) and _rooms[d.target_room][0] == "":
			out = d
	_check(out != null, "%s: a way out opens in the boss room" % id)
	if out:
		_keep_safe()
		_game.player.global_position = out.global_position
		await _wait(0.3)
		await _settle()
		await _play_scene(30.0)
		_check(GameState.dungeon == "" and _rooms.has(_game.current_room.coord) and _rooms[_game.current_room.coord][0] == "", "%s: it leads back out to the overworld (%s)" % [id, _game.current_room.coord])
	return true


## Saves, throws the game away, loads it into a fresh one, and checks that
## nothing was lost.
func _save_and_reload(after: String) -> void:
	var room: Room = _game.current_room
	GameState.set_checkpoint(room.coord, _game.player.global_position - room.global_position)
	var before: Dictionary = GameState.to_dict()
	_check(SaveManager.save_game(), "after %s: the game saves" % after)
	_game.queue_free()
	await _wait(0.2)
	GameState.reset_new_game()
	_check(SaveManager.load_game(), "after %s: the save loads" % after)
	var after_load: Dictionary = GameState.to_dict()
	# Saved as JSON, numbers come back as floats: compare 2 and 2.0 as equal.
	before = _whole(before)
	after_load = _whole(after_load)
	for key: String in before:
		if key == "play_time":
			continue
		# Compared as JSON, the way it's saved (a 2 comes back as 2.0).
		var was := JSON.stringify(before[key], "", true)
		var now := JSON.stringify(after_load.get(key), "", true)
		if key == "flags" and was != now:
			for flag: String in before[key]:
				if JSON.stringify(after_load[key].get(flag)) != JSON.stringify(before[key][flag]):
					printerr("  flag %s: %s -> %s" % [flag, before[key][flag], after_load[key].get(flag)])
		_check(now == was, "after %s: %s survives saving" % [after, key])
	_game = _new_game()
	await _wait(0.6)
	await _play_scene(20.0)
	_check(_game.current_room != null and _game.current_room.coord == GameState.room_coord, "after %s: the game picks up where it was saved" % after)


## A copy with every whole float turned back into an int.
func _whole(value: Variant) -> Variant:
	if value is float and value == floorf(value) and absf(value) < 1e15:
		return int(value)
	if value is Dictionary:
		var out := {}
		for key: Variant in value:
			out[key] = _whole(value[key])
		return out
	if value is Array:
		return value.map(_whole)
	return value


func _new_game() -> Node:
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	return game


## Sets Wren down in a room (on its first open floor tile near the middle)
## the way a doorway would.
func _goto(coord: Vector2i) -> Room:
	# A room can move Wren on by itself (a tilted deck into a hole, a
	# current): let that land first, or the game ignores the doorway.
	for i in 3:
		await _settle()
		_keep_safe()
		Events.door_entered.emit(coord, _open_tile(coord))
		await _settle()
		if _game.current_room and _game.current_room.coord == coord:
			break
	_keep_safe()
	return _game.current_room


## Waits for a room change in progress to finish. A conversation that
## opened on the way (it pauses the game, fade and all) is read through.
func _settle() -> void:
	await _wait(0.1)
	for i in 60:
		_read_dialogue()
		if not _game.busy and _game.current_room != null:
			return
		await _wait(0.1)


func _read_dialogue() -> void:
	for child in _game.get_children():
		if child is DialogueBox and DialogueBox.is_open:
			child.advance()
			child.advance()


## Wren can't be hurt, and every room's enemies are gone, so the run never
## ends in a game over (the smoke test covers the fights).
func _keep_safe() -> void:
	if _game.player:
		_game.player._invuln = 60.0
	GameState.refill()
	if _game.current_room:
		for enemy in _all(_game.current_room, Enemy):
			if not enemy.is_in_group("boss"):
				enemy.queue_free()
		for shot in _all(_game.current_room, Projectile):
			shot.queue_free()


## Plays out a story scene or conversation if one is open, then returns.
func _play_scene(seconds: float) -> void:
	var box: DialogueBox = null
	for child in _game.get_children():
		if child is DialogueBox:
			box = child
	var waited := 0.0
	while waited < seconds:
		await _wait(0.05)
		waited += 0.05
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		elif not Cutscene.active and waited > 0.3:
			break
	_keep_safe()


func _index_rooms() -> void:
	for file in DirAccess.get_files_at("res://rooms/"):
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tscn") or not name.begins_with("room_"):
			continue
		var room: Room = (load("res://rooms/" + name) as PackedScene).instantiate()
		var parts := name.trim_prefix("room_").trim_suffix(".tscn").split("_")
		_rooms[Vector2i(int(parts[0]), int(parts[1]))] = [room.dungeon, room.door_to, room.layout]
		room.free()


func _rooms_of(id: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for coord: Vector2i in _rooms:
		if _rooms[coord][0] == id:
			out.append(coord)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y > b.y or (a.y == b.y and a.x < b.x))
	return out


func _door_room_for(entry: Vector2i) -> Vector2i:
	for coord: Vector2i in _rooms:
		if _rooms[coord][0] == "" and _rooms[coord][1] == entry:
			return coord
	return Vector2i(-999, -999)


func _doorway_to(room: Room, target: Vector2i) -> Doorway:
	for door: Doorway in _all(room, Doorway):
		if door.target_room == target:
			return door
	return null


## An open floor tile, as near the middle of the room as possible.
func _open_tile(coord: Vector2i) -> Vector2i:
	var rows := Room.parse_layout(_rooms[coord][2]) if _rooms.has(coord) else PackedStringArray()
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


func _all(room: Node, type: Variant) -> Array:
	return room.find_children("*", "", true, false).filter(func(n: Node) -> bool: return is_instance_of(n, type))


func _room_path(coord: Vector2i) -> String:
	return "res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]


func _check(condition: bool, what: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(what)
		printerr("FAIL: " + what)


## Waits in real time, so hitstop can't stall the test.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
