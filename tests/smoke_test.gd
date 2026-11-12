extends Node
## Headless smoke test. CI runs it with:
##     godot --headless res://tests/smoke_test.tscn
## Prints "SMOKE TEST PASSED" and exits 0, or lists each failure and exits 1.
## Uses save slot 2 so it never touches a real save.

const TEST_SLOT := 2
## Key prefixes of text that never reaches the dialogue box (_menu_text).
const MENU_TEXT_PREFIXES: Array[String] = ["OPT_"]

var _failures := PackedStringArray()
var _checks := 0


func _ready() -> void:
	SaveManager.current_slot = TEST_SLOT
	# Slot 2 is File 3 on the file select: keep a real save safe.
	SaveManager.set_aside(TEST_SLOT, "testbackup")
	SaveManager.delete_save()
	# SMOKE_ONLY=tomb runs just _test_tomb_dungeon, SMOKE_ONLY=equipment just
	# _test_equipment (for quick local runs).
	var only := OS.get_environment("SMOKE_ONLY")
	if only != "":
		await call(("_test_" + only) if has_method("_test_" + only) else ("_test_%s_dungeon" % only))
	else:
		_test_room_layouts()
		_test_game_state()
		_test_save_load()
		await _test_old_saves()
		_test_keys()
		_test_items()
		await _test_audio()
		_test_text_fit()
		await _test_menus()
		await _test_play()
		await _test_talk_and_dungeon()
		await _test_hull_dungeon()
		await _test_kiln_dungeon()
		await _test_mire_dungeon()
		await _test_gale_dungeon()
		await _test_glacier_dungeon()
		await _test_belfry_dungeon()
		await _test_tomb_dungeon()
		await _test_maw_dungeon()
		await _test_extras_dungeon()
		await _test_echoes_dungeon()
		await _test_foes_dungeon()
		await _test_qa_dungeon()
		await _test_air_dungeon()
		await _test_villagers()
		await _test_story()
		await _test_brinewood_pearl()
		await _test_cinderreach()
		await _test_gloamfen()
		await _test_windmere()
		await _test_frostspine()
		await _test_verge()
		await _test_ossuary()
		await _test_maw_approach()
		await _test_overworld_secrets()
		await _test_tide_turning()
		await _test_sea_bed()
		await _test_tidestone_carvings()
		await _test_challenges()
		await _test_overworld_life()
		await _test_regional_caves()
		await _test_thin_region_screens()
		await _test_elites()
		await _test_far_reaches()
		await _test_puzzle_caves()
		await _test_older_secrets()
		await _test_every_checkpoint()
		await _test_overworld_entrances()
		await _test_ambience()
		await _test_fast_travel()
		await _test_credits()
		await _test_title_talk_key()
		await _test_hud_fade()
		await _test_equipment()
		await _test_side_quests()
		await _test_shop()
		await _test_jumpers()
		_test_satchel_sea_glass()
		await _test_save_transfer()
		await _test_area_stats()
		await _test_dream()
		await _test_journal()
		await _test_tobin()
		await _test_rowing()
		await _test_choir()
		await _test_ide()
		await _test_liesl()
		await _test_wick()
		await _test_gully()
		await _test_sorrel()
		await _test_ottilie()
		await _test_fishing_book()
		await _test_seal_trail()
		await _test_coralie()
		await _test_echo_game()
		_test_hessa_log()
		await _test_lowe_after()
		await _test_hessa_walk()
		await _test_boat_raised()
		await _test_wick_round()
		await _test_gran_table()
		await _test_pad_tour()
		await _test_reeds_song()
		await _test_murmur_and_dace()
		_test_talk_order()
		_test_errands()
		_test_hessa_hints()
		_test_keepers_round()
		await _test_last_singers()
		await _test_edge_survey()
		await _test_scene_music()
		await _test_calf_rest()
		await _test_old_ones_scales()
		await _test_nettle_signals()
		await _test_lighting_day()
		await _test_small_finds()
		_test_jam_trade()
		await _test_singers_at_home()
		await _test_grotto_marks()
		_test_challenge_talk()
		await _test_ebb_shelf()
		_test_late_reactions()
	SaveManager.delete_save()
	SaveManager.restore_aside(TEST_SLOT, "testbackup")
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("SMOKE TEST PASSED (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		print("SMOKE TEST FAILED (%d of %d checks)" % [_failures.size(), _checks])
		get_tree().quit(1)


func _check(condition: bool, what: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(what)


## Waits in real time, so hitstop can't stall the test.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _test_room_layouts() -> void:
	var dir := DirAccess.open("res://rooms")
	_check(dir != null, "res://rooms exists")
	if dir == null:
		return
	var layouts := {}
	for file: String in dir.get_files():
		if not file.ends_with(".tscn"):
			continue
		var room := (load("res://rooms/" + file) as PackedScene).instantiate() as Room
		_check(room != null, file + " has a Room root")
		if room == null:
			continue
		var rows := Room.parse_layout(room.layout)
		var problem := Room.validate_layout(rows)
		# People (and readable signs) stand where the dialogue box can't cover them.
		for y in rows.size():
			for x in rows[y].length():
				var tile := rows[y][x]
				if Npc.LETTERS.has(tile) or (tile == "n" and room.sign_key != ""):
					_check(y <= DialogueBox.LAST_SPEAKER_ROW, "%s: '%s' on row %d would sit behind the dialogue box (keep to rows 0-%d)" % [file, tile, y, DialogueBox.LAST_SPEAKER_ROW])
		_check(problem == "", file + ": " + problem)
		_check(room.name_key != "" and tr(room.name_key) != room.name_key, file + " has a translated name")
		var parts := file.get_basename().trim_prefix("room_").split("_")
		if problem == "" and parts.size() == 2:
			layouts[Vector2i(int(parts[0]), int(parts[1]))] = rows
		room.free()
	_check(layouts.size() >= 4, "at least 4 rooms (found %d)" % layouts.size())
	_check(layouts.has(Vector2i.ZERO), "a start room at 0,0")
	# Every gap in a border wall must line up with a gap in the neighbour.
	for coord: Vector2i in layouts:
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var edge := _open_mask(_edge(layouts[coord], side))
			if not edge.contains("."):
				continue
			var neighbour: Vector2i = coord + side
			_check(layouts.has(neighbour), "room %s opens %s into nothing" % [coord, side])
			if layouts.has(neighbour):
				var other := _open_mask(_edge(layouts[neighbour], -side))
				_check(edge == other, "rooms %s and %s have mismatched openings" % [coord, neighbour])


func _edge(rows: PackedStringArray, side: Vector2i) -> String:
	if side == Vector2i.UP:
		return rows[0]
	if side == Vector2i.DOWN:
		return rows[Room.ROWS - 1]
	var column := 0 if side == Vector2i.LEFT else Room.COLS - 1
	var edge := ""
	for row in rows:
		edge += row[column]
	return edge


func _open_mask(edge: String) -> String:
	var mask := ""
	for tile in edge:
		# A doorway (D) leads elsewhere by warp, not into the neighbour.
		mask += "#" if Room.is_solid(tile) or tile == "D" else "."
	return mask


func _test_game_state() -> void:
	GameState.reset_new_game()
	_check(GameState.bubbles == 5 and GameState.max_bubbles == 5, "new game starts with 5 bubbles")
	GameState.damage(2)
	_check(GameState.bubbles == 3, "a hit pops bubbles")
	_check(not GameState.can_hum(), "can't hum with an empty Resonance meter")
	GameState.add_resonance(GameState.resonance_max)
	_check(GameState.can_hum(), "can hum with a full meter")
	GameState.hum_heal()
	_check(GameState.bubbles == 4, "humming restores one bubble")
	_check(is_equal_approx(GameState.resonance, GameState.resonance_max * 2.0 / 3.0), "humming spends a third of the meter")
	GameState.refill()
	_check(not GameState.can_hum(), "can't hum at full breath")
	GameState.damage(99)
	_check(GameState.is_dead() and GameState.bubbles == 0, "bubbles stop at zero")


## Saves written by earlier releases (tests/old_saves, from each release's
## playthrough) still load: every item is real, the gear worn is owned, the
## breath matches the pearls and shards, and the game starts in their room.
func _test_old_saves() -> void:
	var dir := "res://tests/old_saves"
	var files := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool: return f.ends_with(".json"))
	_check(files.size() >= 3, "old saves to load (%d)" % files.size())
	for file: String in files:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(file)))
		if not parsed is Dictionary:
			_check(false, "%s parses" % file)
			continue
		GameState.reset_new_game()
		_check(SaveManager._write(TEST_SLOT, parsed) and SaveManager.load_game(TEST_SLOT), "%s loads" % file)
		_check(not SaveManager.read_summary(TEST_SLOT).is_empty(), "%s shows on the file select" % file)
		# Read from the file itself: loading quietly drops unknown items, so a
		# renamed item would otherwise vanish from old saves unnoticed.
		var saved: Dictionary = parsed["state"]
		var bad := (saved.get("inventory", {}) as Dictionary).keys().filter(func(id: String) -> bool: return not Items.exists(id))
		_check(bad.is_empty(), "%s: every item it holds still exists (%s)" % [file, bad])
		var worn: Dictionary = saved.get("equipped", {})
		for kind: String in worn:
			_check(worn[kind] == "" or GameState.equipped_item(kind) == worn[kind], "%s: still wears its %s (%s)" % [file, kind, worn[kind]])
		var breath := mini(GameState.START_BUBBLES + GameState.item_count("breath_pearl")
			+ GameState.item_count("pearl_shard") / Items.SHARDS_PER_BUBBLE, GameState.MAX_BUBBLES)
		_check(GameState.max_bubbles == breath, "%s: %d bubbles for its pearls" % [file, GameState.max_bubbles])
		var room := GameState.checkpoint_room
		_check(ResourceLoader.exists("res://rooms/room_%d_%d.tscn" % [room.x, room.y]), "%s: its room %s still exists" % [file, room])
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.6)
		_check(game.current_room != null and is_instance_valid(game.player) and game.current_room.coord == room,
			"%s: the game starts there" % file)
		game.queue_free()
		await _wait(0.1)
	SaveManager.delete_save(TEST_SLOT)
	GameState.reset_new_game()


func _test_save_load() -> void:
	GameState.reset_new_game()
	GameState.damage(1)
	GameState.add_resonance(7.0)
	GameState.set_checkpoint(Vector2i(1, 1), Vector2(40, 60))
	GameState.flags["test_flag"] = true
	_check(SaveManager.save_game(), "save writes a file")
	GameState.reset_new_game()
	_check(SaveManager.load_game(), "load reads it back")
	_check(GameState.bubbles == 4, "load restores bubbles")
	_check(is_equal_approx(GameState.resonance, 7.0), "load restores Resonance")
	_check(GameState.checkpoint_room == Vector2i(1, 1), "load restores the checkpoint room")
	_check(GameState.checkpoint_pos == Vector2(40, 60), "load restores the checkpoint position")
	_check(GameState.flags.get("test_flag") == true, "load restores flags")
	# A damaged save falls back to the one before it.
	var saved_signal := [0]
	var count_saves := func() -> void: saved_signal[0] += 1
	Events.game_saved.connect(count_saves)
	GameState.flags["test_flag"] = false
	SaveManager.save_game()
	Events.game_saved.disconnect(count_saves)
	_check(saved_signal[0] == 1, "saving tells the HUD")
	var path := SaveManager.slot_path()
	_check(FileAccess.file_exists(path + ".bak") and not FileAccess.file_exists(path + ".tmp"),
		"saving keeps the previous save as a backup and leaves no temp file")
	var broken := FileAccess.open(path, FileAccess.WRITE)
	broken.store_string("{\"state\": ")
	broken.close()
	GameState.reset_new_game()
	_check(SaveManager.load_game() and GameState.flags.get("test_flag") == true,
		"a damaged save loads the backup instead")
	_check(not SaveManager.read_summary(SaveManager.current_slot).get("damaged", false),
		"the file select reads the backup of a damaged save")
	# Saving over a damaged file keeps the good backup rather than the damage.
	SaveManager.save_game()
	var bak_data = JSON.parse_string(FileAccess.get_file_as_string(path + ".bak"))
	_check(bak_data is Dictionary and bak_data.get("state") is Dictionary,
		"saving over a damaged save keeps a good backup")
	SaveManager.delete_save()
	_check(not SaveManager.has_save() and not FileAccess.file_exists(path + ".bak"),
		"delete removes the save and its backup")
	# Versions: an unversioned (old) save is brought up to date and loads; a
	# save from a newer version is shown as such and never loaded.
	GameState.reset_new_game()
	GameState.flags["test_flag"] = true
	SaveManager.save_game()
	var old_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	old_data.erase("format_version")
	old_data.erase("summary")
	_write_json(path, old_data)
	GameState.reset_new_game()
	_check(SaveManager.load_game() and GameState.flags.get("test_flag") == true,
		"a save from before versioning still loads")
	_check(SaveManager._migrate(old_data).get("format_version") == SaveManager.FORMAT_VERSION,
		"migrating an old save brings it to the current version")
	var newer_data := old_data.duplicate(true)
	newer_data["format_version"] = SaveManager.FORMAT_VERSION + 1
	_write_json(path, newer_data)
	GameState.reset_new_game()
	_check(not SaveManager.load_game() and GameState.flags.get("test_flag") != true,
		"a save from a newer version is not loaded")
	_check(SaveManager.read_summary(SaveManager.current_slot).get("newer", false),
		"the file select shows a newer save as such")
	_check(SaveManager.latest_slot() != SaveManager.current_slot, "Continue skips a newer save")
	_check(not SaveManager.save_game(), "saving never writes over a newer save")
	_check(SaveManager.is_newer(JSON.parse_string(FileAccess.get_file_as_string(path))),
		"the newer save is still there")
	SaveManager.delete_save()


## Every Tidestone, saved and loaded: the file wakes in the stone's room with
## Wren standing clear (not in a wall, water or a pit) and free to walk off.
func _test_every_checkpoint() -> void:
	var rooms := RoomInfo.all()
	var stones := 0
	for coord: Vector2i in rooms:
		for at: Vector2i in rooms[coord]["stones"]:
			stones += 1
			var spot := Vector2(at.x * Room.TILE + Room.TILE / 2.0, at.y * Room.TILE + Room.TILE - 4) + Tidestone.CHECKPOINT_OFFSET
			var label := "the Tidestone at %s in room %s" % [at, coord]
			if OS.get_environment("CHECKPOINT_TRACE") != "":
				print("checkpoint ", label)
			GameState.reset_new_game()
			GameState.set_checkpoint(coord, spot)
			SaveManager.save_game()
			GameState.reset_new_game()
			if not SaveManager.load_game():
				_check(false, "%s: the save loads" % label)
				continue
			var bubbles := GameState.bubbles
			var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
			add_child(game)
			await _wait(0.1)
			# A room's first visit may open a dialogue, which pauses the game.
			if DialogueBox.is_open:
				for node in get_tree().root.find_children("*", "DialogueBox", true, false):
					(node as DialogueBox).close()
			get_tree().paused = false
			await _wait(0.5)
			var player: Player = game.player
			_check(game.current_room != null and game.current_room.coord == coord, "%s: the file wakes in the stone's room" % label)
			var room_pos: Vector2 = game.current_room.global_position if game.current_room else Vector2.ZERO
			var drift := player.global_position.distance_to(room_pos + spot)
			_check(player.state != Player.State.FALL and player.state != Player.State.DEAD and GameState.bubbles == bubbles,
				"%s: Wren wakes on solid ground (state %d, bubbles %d of %d)" % [label, player.state, GameState.bubbles, bubbles])
			_check(drift < 6.0, "%s: Wren wakes where the stone put them, not pushed out of a wall (%.1f px off)" % [label, drift])
			var free := 0
			for step: Vector2 in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
				if not player.test_move(player.global_transform, step):
					free += 1
			_check(free >= 2, "%s: Wren can walk off from where they wake (%d of 4 ways open)" % [label, free])
			game.queue_free()
			await _wait(0.05)
	get_tree().paused = false
	_check(stones >= 20, "the world has its Tidestones (%d)" % stones)
	SaveManager.delete_save()
	GameState.reset_new_game()


## Fair entrances on the overworld (tests/walker.gd checks the dungeons): no
## foe waits within three tiles of a way in from the next room or a doorway,
## in either of a room's layouts. Galehawks are left out: they circle high,
## out of reach, until they stoop.
func _test_overworld_entrances() -> void:
	var rooms := RoomInfo.all()
	var checked := 0
	for coord: Vector2i in rooms:
		if rooms[coord]["dungeon"] != "":
			continue
		var scene := load("res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]) as PackedScene
		var probe := scene.instantiate() as Room
		var alt := probe.alt_flag if probe.alt_layout != "" else ""
		probe.free()
		for use_alt: bool in ([false, true] if alt != "" else [false]):
			GameState.reset_new_game()
			if use_alt:
				GameState.set_flag(alt)
			var room := scene.instantiate() as Room
			room.coord = coord
			add_child(room)
			var foes: Array[Vector2] = []
			for node in room.find_children("*", "Enemy", true, false):
				if not node.is_in_group("boss") and not node is Galehawk:
					foes.append((node as Node2D).position)
			# Ways in: open border tiles facing a room, and doorways.
			var ways: Array[Vector2] = []
			for x in Room.COLS:
				for y in Room.ROWS:
					var tile := room.raw_tile(x, y)
					var centre := Vector2(x * Room.TILE + Room.TILE / 2.0, y * Room.TILE + Room.TILE / 2.0)
					if tile == "D":
						ways.append(centre)
						continue
					var side := Vector2i(-1 if x == 0 else (1 if x == Room.COLS - 1 else 0), -1 if y == 0 else (1 if y == Room.ROWS - 1 else 0))
					if side == Vector2i.ZERO or not tile in [".", ":", ",", "r", ";"]:
						continue
					for out: Vector2i in [Vector2i(side.x, 0), Vector2i(0, side.y)]:
						if out != Vector2i.ZERO and rooms.has(coord + out):
							ways.append(centre - Vector2(out) * Room.TILE)
			for at in ways:
				checked += 1
				for foe in foes:
					if foe.distance_to(at) < Room.TILE * 3.0:
						_check(false, "room %s%s: a foe at tile %s waits %d px from the way in at tile %s" % [coord, " (after %s)" % alt if use_alt else "", Vector2i(foe / Room.TILE), int(foe.distance_to(at)), Vector2i(at / Room.TILE)])
						break
			room.queue_free()
			await _wait(0.02)
	GameState.reset_new_game()
	_check(checked > 100, "the overworld's ways in were checked (%d)" % checked)


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _test_keys() -> void:
	GameState.reset_new_game()
	_check(GameState.keys("hull") == 0, "no keys at the start")
	_check(not GameState.use_key("hull"), "can't spend a key you don't have")
	GameState.add_key("hull")
	_check(GameState.keys("hull") == 1 and GameState.keys("kiln") == 0, "keys belong to one dungeon")
	_check(GameState.use_key("hull") and GameState.keys("hull") == 0, "using a key spends it")


## Hessa's talk, the doorway into the Rotting Hull, a chest key and a locked hatch.
func _test_talk_and_dungeon() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(0, -1), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	var hessa: Npc = null
	for child in game.current_room.get_children():
		if child is Npc and child.kind == "hessa":
			hessa = child
	_check(hessa != null, "Old Hessa stands in Saltmarrow")
	if hessa == null:
		game.queue_free()
		return
	# Stand below her, face up, press Interact.
	player.global_position = hessa.global_position + Vector2(0, 14)
	player.facing = Vector2.UP
	await _wait(0.1)
	_check(player.try_interact(), "Wren can talk to Hessa")
	await _wait(0.1)
	_check(DialogueBox.is_open and get_tree().paused, "talking opens the box and pauses the game")
	var box: DialogueBox = null
	for child in game.get_children():
		if child is DialogueBox:
			box = child
	_check(box != null and box.current_portrait() == Art.PORTRAIT_HESSA, "Hessa's portrait shows in the box")
	var expected: int = Conversations.TALKS["hessa"][-1]["lines"].size()
	var pages := 0
	while box and DialogueBox.is_open and pages < 20:
		box.advance()
		box.advance()
		pages += 1
	_check(not DialogueBox.is_open and not get_tree().paused, "the talk ends and the game resumes")
	_check(pages == expected and pages >= 6, "Hessa's first talk has every page (%d of %d)" % [pages, expected])
	_check(GameState.has_flag("met_hessa"), "meeting Hessa is remembered")
	_check(hessa.current_pages().size() == 1, "Hessa has a short reminder after that")
	await _wait(0.4)

	# The doorway in Hull Landing leads into the Rotting Hull.
	Events.door_entered.emit(Vector2i(5, 0), Vector2i(11, 8))
	await _wait(1.0)
	_check(game.current_room.coord == Vector2i(5, 0), "a doorway warps to its room")
	var door: Doorway = null
	for child in game.current_room.get_children():
		if child is Doorway:
			door = child
	_check(door != null and door.target_room == Vector2i(10, 10), "Hull Landing has the way into the Hull")
	if door:
		game.player.global_position = door.global_position + Vector2(0, 12)
		Input.action_press("move_up")
		await _wait(0.4)
		Input.action_release("move_up")
		await _wait(1.0)
	_check(game.current_room.coord == Vector2i(10, 10), "walking into the hole enters the Rotting Hull (in %s)" % game.current_room.coord)
	_check(GameState.dungeon == "hull", "GameState knows Wren is in the Hull")
	_check(GameState.has_flag("entered_hull"), "entering the Hull sets a story flag")
	_check(Conversations.branch_for("pell")["lines"][0] == "PELL_HULL_1", "Pell asks about the Hull")
	Conversations.talk("pell")
	_finish_talk(game)
	_check(Conversations.branch_for("pell")["lines"][0] == "PELL_QUEST_1", "after the Hull talk, Pell still asks for a heron feather")
	_check(Conversations.branch_for("hessa")["lines"][0] == "HESSA_HULL_1", "Hessa has news for Wren after the Hull")

	# A chest in the Galley holds the key for the Bilge's hatch.
	Events.door_entered.emit(Vector2i(9, 9), Vector2i(20, 6))
	await _wait(1.0)
	var chest: Chest = null
	for child in game.current_room.get_children():
		if child is Chest:
			chest = child
	_check(chest != null and not chest.opened, "the Galley has a closed chest")
	if chest:
		game.player.global_position = chest.global_position + Vector2(0, 14)
		game.player.facing = Vector2.UP
		await _wait(0.1)
		_check(game.player.try_interact(), "Wren can open the chest")
		_check(chest.opened and GameState.keys("hull") == 1, "the chest gives a small key")
		_check(GameState.flags.get(chest.flag_key(), false), "an opened chest stays open")

	Events.door_entered.emit(Vector2i(10, 9), Vector2i(20, 6))
	await _wait(1.0)
	var hatches := 0
	for child in game.current_room.get_children():
		if child is LockedDoor:
			hatches += 1
	_check(hatches == 3, "the Bilge's east way is barred (%d hatches)" % hatches)
	# Carry a spare key and walk in where two hatch tiles' touch areas
	# overlap: opening the lock must spend only one key.
	GameState.add_key("hull")
	game.player.global_position = game.current_room.global_position + Vector2(21 * Room.TILE + 8, 98)
	Input.action_press("move_right")
	await _wait(0.5)
	Input.action_release("move_right")
	await _wait(0.4)
	_check(GameState.keys("hull") == 1, "the hatch uses exactly one key (left %d)" % GameState.keys("hull"))
	_check(GameState.flags.get(LockedDoor.lock_flag(Vector2i(10, 9)), false), "the open hatch is remembered")
	Input.action_press("move_right")
	await _wait(1.0)
	Input.action_release("move_right")
	_check(game.current_room.coord == Vector2i(11, 9), "through the hatch to the Cargo Hold (in %s)" % game.current_room.coord)
	game.queue_free()
	await _wait(0.1)


## Talks every page of whatever is open.
func _finish_talk(game: Node) -> int:
	var box: DialogueBox = null
	for child in game.get_children():
		if child is DialogueBox:
			box = child
	var pages := 0
	while box and DialogueBox.is_open and pages < 30:
		box.advance()
		box.advance()
		pages += 1
	return pages


## Strings shown only in menus, the HUD, the title or the credits, never in
## the dialogue box.
func _menu_text(key: String) -> bool:
	for prefix in MENU_TEXT_PREFIXES:
		if key.begins_with(prefix):
			return true
	return false


## Saltmarrow's villagers, their portraits, Marga's rope errand (a chain of
## story flags across two people), Pell wandering, and the village sign.
func _test_villagers() -> void:
	GameState.reset_new_game()
	_check(not GameState.has_flag("asked_for_rope"), "a new game has no story flags")
	GameState.set_flag("entered_hull")
	_check(Conversations.branch_for("hessa").get("set", []).has("met_hessa"), "going to the Hull first still gets Hessa's introduction")
	GameState.clear_flag("entered_hull")
	GameState.set_flag("x")
	_check(GameState.has_flag("x") and GameState.flags_match(["x"], ["y"]), "flags set and match")
	GameState.clear_flag("x")
	_check(not GameState.has_flag("x"), "flags clear")
	GameState.set_checkpoint(Vector2i(0, -1), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var people := {}
	var sign: Prop = null
	for child in game.current_room.get_children():
		if child is Npc:
			people[child.kind] = child
		elif child is Prop and child.kind == "n":
			sign = child
	for who in ["hessa", "pell", "marga", "dunstan", "nettle"]:
		_check(people.has(who), "%s lives in Saltmarrow" % who)
	# On screen, each of them, and Wren standing just below to talk, stays
	# above the tallest the dialogue box (and its name tab) ever gets.
	for who in people:
		var feet: float = people[who].get_global_transform_with_canvas().origin.y
		_check(feet + Room.TILE < DialogueBox.HIGHEST_POINT, "%s and Wren stay clear of the dialogue box (%d vs %d)" % [who, feet + Room.TILE, DialogueBox.HIGHEST_POINT])
	for who in Conversations.TALKS:
		_check(not Conversations.branch_for(who).is_empty(), "%s always has something to say" % who)
		for branch: Dictionary in Conversations.TALKS[who]:
			for page: Dictionary in Conversations.pages(who, branch):
				_check(TranslationServer.translate(page["text"]) != page["text"], "line %s is in strings.csv" % page["text"])
	if not people.has("marga") or not people.has("dunstan"):
		game.queue_free()
		return
	# Every line fits in the box, with or without a portrait.
	var fit_box: DialogueBox = null
	for child in game.get_children():
		if child is DialogueBox:
			fit_box = child
	for who in Conversations.TALKS:
		for branch: Dictionary in Conversations.TALKS[who]:
			for page: Dictionary in Conversations.pages(who, branch):
				var lines := fit_box.lines_for(page["text"], page["portrait"] != null)
				_check(lines <= DialogueBox.MAX_LINES, "%s fits the box (%d lines)" % [page["text"], lines])
	for sign_name in ["SALTMARROW", "BARNACLE_WALL", "BRINEWOOD", "MILL_ROW", "BRINE_SPRING",
			"ASHFALL_GATE", "BLEACHED_STRAND", "VERTEBRA_ROAD"]:
		_check(fit_box.lines_for("SIGN_" + sign_name, false) <= DialogueBox.MAX_LINES, "the %s sign fits the box" % sign_name)
	# The bells' narration and the Wayshell scene fit on one page each, too.
	for k in ["HULL", "KILN", "MIRE", "GALE", "GLACIER", "BELFRY", "TOMB"]:
		for part in [1, 2]:
			var key := "BELL_%s_%d" % [k, part]
			_check(fit_box.lines_for(key, false) <= DialogueBox.MAX_LINES, "%s fits the box" % key)
	for key in ["WAYSHELL_1", "WAYSHELL_2", "WAYSHELL_3"]:
		_check(fit_box.lines_for(key, true) <= DialogueBox.MAX_LINES, "%s fits the box" % key)
	# And what's cut into every Tidestone.
	for carving: Array in Tidestone.CARVINGS.values():
		for key: String in carving:
			_check(fit_box.lines_for(key, false) <= DialogueBox.MAX_LINES, "%s fits the box" % key)
	# And every other string the game has: anything new (a carving line, a
	# narrated find, a scene) can only reach the box in one piece. Menu and
	# help text that is never shown there is left out by prefix.
	var csv := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	csv.get_csv_line()
	var too_long: Array[String] = []
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size() < 2 or row[0] == "" or _menu_text(row[0]):
			continue
		# Key names filled in: "{key}" as both default item keys (a longer
		# remapped name may run over onto another page, which the box allows).
		if fit_box.lines_for(MenuKit.fill_keys(tr(row[0])), false) > DialogueBox.MAX_LINES:
			too_long.append(row[0])
	_check(too_long.is_empty(), "every line the box can show fits it (too long: %s)" % ", ".join(too_long))
	# Large text: the same box, one big line per page, long pages split.
	var was_large := Settings.large_text
	Settings.large_text = true
	fit_box.open_pages(Conversations.pages("marga", Conversations.TALKS["marga"][-1]))
	var split_pages := fit_box.page_count()
	var all_fit := true
	while DialogueBox.is_open:
		if fit_box.lines_for(fit_box.current_page()["text"], fit_box.current_portrait() != null) > DialogueBox.LARGE_MAX_LINES:
			all_fit = false
		fit_box.advance()
		fit_box.advance()
	Settings.large_text = was_large
	_check(split_pages > Conversations.TALKS["marga"][-1]["lines"].size(), "large text splits long pages (%d pages)" % split_pages)
	_check(all_fit, "every large-text page fits on one line")
	Settings.large_text = true
	fit_box.open_pages([{"name": "", "portrait": null, "text": "Underwaterbelltowerkeeperlanternlighterassociationofsaltmarrow"}])
	var long_word_fits := true
	while DialogueBox.is_open:
		if fit_box.lines_for(fit_box.current_page()["text"], false) > DialogueBox.LARGE_MAX_LINES:
			long_word_fits = false
		fit_box.advance()
		fit_box.advance()
	Settings.large_text = was_large
	_check(long_word_fits, "a word too long for one line is cut to fit")
	_check(GameState.has_flag("asked_for_rope") == false, "opening the box directly doesn't set story flags")
	var player: Player = game.player

	# Dunstan grunts until Marga sends Wren over.
	_check(people["dunstan"].current_pages()[0]["text"] == "DUNSTAN_1", "Dunstan has nothing to say about rope yet")
	player.global_position = people["marga"].global_position + Vector2(0, 14)
	player.facing = Vector2.UP
	await _wait(0.1)
	_check(player.try_interact(), "Wren can talk to Marga")
	await _wait(0.05)
	var box: DialogueBox = null
	for child in game.get_children():
		if child is DialogueBox:
			box = child
	_check(box != null and box.current_portrait() == Art.PORTRAIT_MARGA, "Marga's portrait shows")
	_check(box != null and box.current_page()["name"] == "NAME_MARGA", "the tab names Marga")
	_finish_talk(game)
	_check(GameState.has_flag("asked_for_rope"), "Marga's errand is remembered")
	await _wait(0.4)
	player.global_position = people["dunstan"].global_position + Vector2(0, 14)
	await _wait(0.1)
	_check(player.try_interact(), "Wren can talk to Dunstan")
	await _wait(0.05)
	var narration := 0
	while box and DialogueBox.is_open:
		if box.current_page()["name"] == "":
			narration += 1
			_check(box.current_portrait() == null, "narration has no portrait")
		box.advance()
		box.advance()
	_check(narration >= 1, "Wren answers without words (narration pages)")
	_check(GameState.has_flag("rope_promised"), "Dunstan promises the rope")
	_check(people["marga"].current_pages()[0]["text"] == "MARGA_THANKS_1", "Marga hears the good news")
	await _wait(0.4)

	# Pell wanders.
	if people.has("pell"):
		player.global_position = game.current_room.global_position + Vector2(22 * Room.TILE, 1 * Room.TILE + 12)
		var from_x: float = people["pell"].position.x
		await _wait(4.0)
		_check(absf(people["pell"].position.x - from_x) > 2.0, "Pell runs about the village")

	# The village sign reads out.
	_check(sign != null and sign.is_in_group("interactable"), "the village sign can be read")
	if sign:
		player.global_position = sign.global_position + Vector2(0, 14)
		player.facing = Vector2.UP
		await _wait(0.1)
		_check(player.try_interact() and box.current_page()["text"] == "SIGN_SALTMARROW", "reading the sign shows its words")
		_finish_talk(game)
	game.queue_free()
	await _wait(0.1)


## Plays story scenes fast, turning every dialogue page, until the scene is
## over or the time runs out. Returns how many pages were shown.
func _play_scene(game: Node, seconds: float) -> int:
	var box: DialogueBox = null
	for child in game.get_children():
		if child is DialogueBox:
			box = child
	var pages := 0
	var waited := 0.0
	while waited < seconds:
		await _wait(0.05)
		waited += 0.05
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
			pages += 1
		elif not Cutscene.active and waited > 0.3:
			break
	return pages


## Wait for any running scene (and its talk) to end, the way a player
## would before ringing a bell.
func _scene_over(game: Node) -> void:
	await _play_scene(game, 20.0)


## Story scenes: the opening on a new file, and the Wayshell after the Hull.
func _test_story() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	GameState.play_opening = true
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.2)
	_check(Cutscene.active and game.player.in_cutscene, "a new file opens with the opening scene")
	var pages := await _play_scene(game, 8.0)
	_check(not Cutscene.active and not game.player.in_cutscene, "the opening ends and hands Wren back")
	_check(GameState.has_flag("seen_opening") and pages == 0, "the opening plays without dialogue pages (%d)" % pages)
	_check(not GameState.play_opening, "the opening only plays once")
	game.queue_free()
	await _wait(0.1)

	# Loading a file never replays it.
	var again: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(again)
	await _wait(0.2)
	_check(not Cutscene.active, "loading a file doesn't replay the opening")
	again.queue_free()
	await _wait(0.1)

	# After the Hull, Mantle lies netted on the Wreck Strand: Wren frees it.
	GameState.reset_new_game()
	GameState.set_flag("tidebell_hull")
	_check(Conversations.branch_for("hessa")["lines"][0] == "HESSA_MANTLE_1", "Hessa sends Wren to the Wreck Strand first")
	GameState.set_checkpoint(Vector2i(4, 0), Vector2(1 * Room.TILE + 8, 6 * Room.TILE + 12))
	var strand: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(strand)
	await _wait(0.2)
	_check(Cutscene.active, "the Wreck Strand after the Hull starts Freeing Mantle")
	var tangle: MantleTangle = null
	for child in strand.current_room.get_children():
		if child is MantleTangle:
			tangle = child
	_check(tangle != null, "Mantle lies netted on the strand")
	var strand_pages := await _play_scene(strand, 10.0)
	_check(not Cutscene.active and not strand.player.in_cutscene, "Freeing Mantle hands Wren back")
	_check(strand_pages == 0 and GameState.has_flag("freed_mantle"), "Mantle is freed, told without text")
	_check(not is_instance_valid(tangle), "Mantle has flown")
	var cut_from: Vector2 = strand.current_room.global_position + StoryDirector.CUT_FROM
	_check(strand.player.global_position.distance_to(cut_from) < 6.0, "Wren walks round the pool to Mantle (%s)" % strand.player.global_position)
	strand.queue_free()
	await _wait(0.1)

	# Back in Saltmarrow with the Point Bell: Hessa gives Wren the Wayshell.
	GameState.reset_new_game()
	GameState.set_flag("tidebell_hull")
	GameState.set_flag("freed_mantle")
	# Coming in from the shore path at the bottom of the village.
	GameState.set_checkpoint(Vector2i(0, -1), Vector2(12 * Room.TILE, 11 * Room.TILE + 12))
	var home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	await _wait(0.2)
	_check(Cutscene.active, "coming home with the bell starts the Wayshell scene")
	await _play_scene(home, 10.0)
	_check(not Cutscene.active and not home.player.in_cutscene, "the Wayshell scene hands Wren back")
	_check(GameState.has_item("wayshell"), "Hessa gives Wren the Wayshell")
	_check(Conversations.branch_for("hessa")["lines"][0] == "HESSA_AFTER_BELL", "Hessa points Wren to the Kiln afterwards")
	home.queue_free()
	await _wait(0.1)

	# The Hull's boss chamber, the first time: Sister Lowe and her singers
	# are prying at the sleeping Matriarch, and drop away when she wakes.
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.HULL_BOSS, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 12))
	var hold: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(hold)
	await _wait(0.2)
	_check(Cutscene.active, "the Matriarch's chamber starts Lowe's scene")
	_check(Audio.music_cue == "story_choir", "the Choir's theme, not the boss's, while she sleeps through Lowe's scene (%s)" % Audio.music_cue)
	var choir: Array = hold.current_room.get_children().filter(func(c: Node) -> bool: return c is ChoirFigure)
	_check(choir.size() == 3, "Lowe and two singers are in the chamber (%d)" % choir.size())
	var sleeper: BarnacleMatriarch = null
	for child in hold.current_room.get_children():
		if child is BarnacleMatriarch:
			sleeper = child
	_check(sleeper != null and sleeper.mode == BarnacleMatriarch.Mode.INTRO and sleeper.modulate == BarnacleMatriarch.SLEEPING, "the Matriarch sleeps through the start")
	var lowe_pages := await _play_scene(hold, 12.0)
	_check(not Cutscene.active and not hold.player.in_cutscene, "Lowe's scene hands Wren back")
	_check(lowe_pages == 3 and GameState.has_flag(StoryDirector.LOWE_HULL_FLAG), "Sister Lowe speaks three times (%d)" % lowe_pages)
	var choir_left := 0
	for figure: Variant in choir:
		if is_instance_valid(figure):
			choir_left += 1
	_check(choir_left == 0, "the Choir is gone through the deck (%d left)" % choir_left)
	for feet in [StoryDirector.LOWE_FROM_BOSS] + StoryDirector.SINGERS_FROM_BOSS:
		var y: float = (sleeper.position.y if sleeper else 0.0) + feet.y
		_check(y < 9 * Room.TILE, "the Choir stands clear of the dialogue box")
	await _wait(1.6)
	_check(is_instance_valid(sleeper) and sleeper.mode != BarnacleMatriarch.Mode.INTRO and sleeper.modulate == Color.WHITE, "the Matriarch wakes and fights")
	_check(Audio.music_cue == "boss", "the boss theme starts as she wakes (%s)" % Audio.music_cue)
	hold.queue_free()
	await _wait(0.1)
	# Coming back (the scene has played): she rises at once, wide awake.
	var back: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(back)
	await _wait(0.2)
	_check(not Cutscene.active, "Lowe's scene only plays once")
	_check(Audio.music_cue == "boss", "a boss's chamber plays the boss theme (%s)" % Audio.music_cue)
	for child in back.current_room.get_children():
		if child is BarnacleMatriarch:
			_check(child.modulate == Color.WHITE, "the Matriarch is awake when Wren comes back")
	back.queue_free()
	await _wait(0.1)

	# Lantern Mire: the Pale Congregation laid to rest, its wisps make a
	# calf of light one last time, and Murmur leaves the Choir.
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.MIRE_BOSS, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 12))
	var mire: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(mire)
	await _wait(0.3)
	_check(not Cutscene.active, "nothing plays in the Still Pool before the fight")
	mire.player._invuln = 60.0
	for child in mire.current_room.get_children():
		if child is PaleCongregation:
			for blow in 20:
				if not is_instance_valid(child) or child.hp <= 0:
					break
				child.mode = PaleCongregation.Mode.SWIM
				child._stun = 0.0
				for wisp: Dictionary in child.wisps:
					wisp["home"] = false
				child.take_hit(1, Vector2.UP)
	await _wait(0.1)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.CALF_FLAG), "laying the Congregation to rest starts the calf scene")
	_check(Audio.music_cue == "dungeon_mire", "the Mire's own music comes back once its boss falls (%s)" % Audio.music_cue)
	var calf_pages := await _play_scene(mire, 15.0)
	_check(not Cutscene.active and not mire.player.in_cutscene, "the calf scene hands Wren back")
	_check(calf_pages == 3, "Murmur speaks three times (%d)" % calf_pages)
	var calf_left: Array = mire.current_room.get_children().filter(func(c: Node) -> bool: return c is CalfOfLights or c is ChoirFigure)
	_check(calf_left.is_empty(), "the lights scatter and Murmur leaves (%d left)" % calf_left.size())
	# Fast scenes outrun the heart's last beats, which run in real time.
	await _wait(4.0)
	var moth_bell: Array = mire.current_room.get_children().filter(func(c: Node) -> bool: return c is Tidebell)
	_check(moth_bell.size() == 1 and _child_of(mire.current_room, Doorway).size() == 1, "the Moth Bell and the way out are there after the scene")
	if moth_bell.size() == 1:
		await _scene_over(mire)
		moth_bell[0].interact()
		var moth_pages := await _play_scene(mire, 10.0)
		_check(moth_pages == 2, "the Moth Bell's scene tells its ringing (%d pages)" % moth_pages)
		_check(GameState.has_flag(Tidebell.flag_for("mire")), "the Moth Bell rings after the scene")
	mire.queue_free()
	await _wait(0.1)

	# The Gale Spire's Crown: with the Stormheron gone, Vael speaks.
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.GALE_BOSS, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 12))
	var crown: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(crown)
	await _wait(0.3)
	_check(not Cutscene.active, "nothing plays on the Crown before the fight")
	# Wren lands the last blow from a side ledge, cut off by open sky.
	crown.player.global_position = crown.current_room.global_position + Vector2(3 * Room.TILE + 8, 6 * Room.TILE + 12)
	var crown_health := GameState.bubbles
	crown.player._invuln = 60.0
	for child in crown.current_room.get_children():
		if child is Stormheron:
			for blow in 20:
				if not is_instance_valid(child) or child.hp <= 0:
					break
				child._stun = 0.0
				child._hits_this_landing = 0
				child.mode = Stormheron.Mode.GROUNDED
				child.take_hit(1, Vector2.UP)
	await _wait(0.1)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.VAEL_FLAG), "bringing the Stormheron down starts Vael's scene")
	var vael_pages := await _play_scene(crown, 15.0)
	_check(not Cutscene.active and not crown.player.in_cutscene, "Vael's scene hands Wren back")
	_check(vael_pages == 4, "Vael speaks four times (%d)" % vael_pages)
	_check(GameState.bubbles == crown_health, "Wren stays safe on the ledge through the scene (%d)" % GameState.bubbles)
	var ledge: Vector2 = crown.player.global_position - crown.current_room.global_position
	_check(ledge.distance_to(Vector2(3 * Room.TILE + 8, 6 * Room.TILE + 12)) < 4.0, "with no way across the sky, Wren stays on the ledge (%s)" % ledge)
	var vael_left: Array = crown.current_room.get_children().filter(func(c: Node) -> bool: return c is ChoirFigure)
	_check(vael_left.is_empty(), "Vael leaves the Crown")
	await _wait(3.0)
	var storm_bell: Tidebell = null
	for child in crown.current_room.get_children():
		if child is Tidebell:
			storm_bell = child
	_check(storm_bell != null, "the Storm Bell is there to ring after Vael goes")
	# Ringing it: far below, the Old One turns over in its sleep.
	if storm_bell:
		GameState.resonance = 0.0
		storm_bell.interact()
		_check(crown.current_room.get_children().any(func(c: Node) -> bool: return c is BellPhrase), "the phrase leaves the bell as notes")
		_check(GameState.resonance == 0.0, "Resonance fills only when the notes reach Wren")
		await _wait(0.2)
		_check(GameState.resonance == GameState.resonance_max, "the notes land and Resonance fills")
		_check(Cutscene.active and not GameState.has_flag(StoryDirector.TURNED_FLAG), "the bell's own scene plays before the turn")
		var turn_pages := await _play_scene(crown, 20.0)
		_check(GameState.has_flag(StoryDirector.TURNED_FLAG), "ringing the Storm Bell makes the Old One turn")
		_check(not Cutscene.active and not crown.player.in_cutscene, "the turn hands Wren back")
		_check(turn_pages <= 3, "only the bell speaks; the turn itself has no words (%d pages)" % turn_pages)
		await _wait(0.3)
		_check(not crown.current_room.get_children().any(func(c: Node) -> bool: return c is OldOneShadow), "the shadow sinks away after the turn")
	crown.queue_free()
	await _wait(0.1)

	# Home again after the turn: Hessa owns up about Vael. (An old save that
	# rang the Storm Bell before the turn existed gets it too.)
	GameState.reset_new_game()
	GameState.flags[StoryDirector.GALE_BELL_FLAG] = true
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(9 * Room.TILE + 8, 9 * Room.TILE + 8))
	var turned_home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(turned_home)
	await _wait(0.3)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.CONFESSION_FLAG), "coming turned_home after the turn starts Hessa's confession")
	var confess_pages := await _play_scene(turned_home, 20.0)
	_check(confess_pages == 5, "Hessa confesses in five pages (%d)" % confess_pages)
	_check(not Cutscene.active and not turned_home.player.in_cutscene, "the confession hands Wren back")
	_check((Conversations.branch_for("hessa").get("lines", []) as Array).has("HESSA_AFTER_TURN"), "afterwards Hessa has something new to say")
	turned_home.queue_free()
	await _wait(0.1)

	# The Marrow Tomb: with the Regent gone to bones, Dace shows Wren the
	# last mural.
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.TOMB_BOSS, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 12))
	var barrow: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(barrow)
	await _wait(0.3)
	_check(not barrow.current_room.get_children().any(func(c: Node) -> bool: return c is LastMural), "the mural is walled up before the fight")
	for child in barrow.current_room.get_children():
		if child is HollowRegent:
			child.ai_enabled = false
			child.mode = HollowRegent.Mode.OPEN
			for blow in 30:
				if not is_instance_valid(child) or child.hp <= 0:
					break
				child._stun = 0.0
				child._hits_this_open = 0
				child.take_hit(1, Vector2.UP)
	await _wait(0.1)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.MURAL_FLAG), "the Regent's fall starts the last mural")
	var mural_pages := await _play_scene(barrow, 20.0)
	_check(mural_pages == 4, "Dace speaks four times (%d)" % mural_pages)
	_check(not Cutscene.active and not barrow.player.in_cutscene, "the mural scene hands Wren back")
	var murals: Array = barrow.current_room.get_children().filter(func(c: Node) -> bool: return c is LastMural)
	_check(murals.size() == 1 and not murals[0].is_showing(), "the mural stays carved on the wall, the close view gone")
	_check(not barrow.current_room.get_children().any(func(c: Node) -> bool: return c is ChoirFigure), "Dace leaves the tomb")
	await _wait(4.0)
	_check(barrow.current_room.get_children().any(func(c: Node) -> bool: return c is Tidebell), "the Marrow Bell waits to be rung")
	barrow.queue_free()
	await _wait(0.1)

	# The ending: the Heart sleeps, Vael stays, Mantle carries Wren home.
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(44, 6), Vector2(11 * Room.TILE + 8, 10 * Room.TILE + 12))
	DreamingHeart.roll_credits = false
	var heart_room: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(heart_room)
	await _wait(0.3)
	GameState.set_flag(DreamingHeart.DEFEATED_FLAG)
	Events.game_finished.emit()
	await _wait(0.1)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.ENDING_FLAG), "when the Old One sleeps, the ending begins")
	var end_pages := await _play_scene(heart_room, 40.0)
	_check(end_pages == 5, "Vael speaks, then home is told (%d pages)" % end_pages)
	_check(not Cutscene.active and GameState.room_coord == StoryDirector.SALTMARROW, "the ending carries Wren home to Saltmarrow")
	_check(GameState.checkpoint_room == StoryDirector.SALTMARROW, "after the credits, Continue starts at home")
	_check(heart_room.current_room.coord == StoryDirector.SALTMARROW and not heart_room.current_room.get_children().any(func(c: Node) -> bool: return c is ChoirFigure), "Vael stays behind in the Maw: no one follows Wren home")
	_check(GameState.has_flag(StoryDirector.CONFESSION_FLAG) and GameState.has_flag("seen_wayshell"), "no older scene waits at home after the credits")
	Events.game_finished.emit()
	await _wait(0.1)
	_check(not Cutscene.active, "the ending only plays once")
	heart_room.queue_free()
	await _wait(0.1)
	# Closed partway through the ending: Continue picks it up again.
	GameState.reset_new_game()
	GameState.set_flag(DreamingHeart.DEFEATED_FLAG)
	GameState.set_checkpoint(Vector2i(44, 6), GameState.NO_POSITION)
	var heart_again: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(heart_again)
	await _wait(0.3)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.ENDING_FLAG), "a save from mid-ending starts the ending again")
	await _play_scene(heart_again, 40.0)
	_check(GameState.room_coord == StoryDirector.SALTMARROW, "and it still ends at home")
	DreamingHeart.roll_credits = true
	heart_again.queue_free()
	await _wait(0.1)

	# A door opening under Wren mid-scene doesn't carry them off.
	GameState.reset_new_game()
	GameState.set_flag(HollowRegent.DEFEATED_FLAG)
	GameState.set_checkpoint(StoryDirector.TOMB_BOSS, Vector2(11 * Room.TILE + 8, 1 * Room.TILE + 12))
	var old_barrow: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(old_barrow)
	await _wait(0.3)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.MURAL_FLAG), "an older save still sees the last mural on the way back in")
	var old_pages := await _play_scene(old_barrow, 20.0)
	_check(old_pages == 4 and GameState.room_coord == StoryDirector.TOMB_BOSS, "standing on the way out, Wren stays for the whole scene (%d pages)" % old_pages)
	old_barrow.queue_free()
	await _wait(0.1)

	# The Kiln's crucible: Lowe's smiths stoke it until the slag wakes.
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.KILN_BOSS, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 12))
	var kiln: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(kiln)
	await _wait(0.2)
	_check(Cutscene.active, "the crucible chamber starts the crucible scene")
	var pot: Array = kiln.current_room.get_children().filter(func(c: Node) -> bool: return c is Crucible)
	var smiths: Array = kiln.current_room.get_children().filter(func(c: Node) -> bool: return c is ChoirFigure)
	_check(pot.size() == 1 and smiths.size() == 3, "Lowe's smiths stoke the crucible (%d, %d)" % [pot.size(), smiths.size()])
	var wyrm: Slagwyrm = null
	for child in kiln.current_room.get_children():
		if child is Slagwyrm:
			wyrm = child
	_check(wyrm != null and wyrm.mode == Slagwyrm.Mode.INTRO and wyrm._sprite.modulate.a == 0.0, "the Slagwyrm sleeps hidden in the melt")
	var kiln_pages := await _play_scene(kiln, 12.0)
	_check(not Cutscene.active and not kiln.player.in_cutscene, "the crucible scene hands Wren back")
	_check(kiln_pages == 3 and GameState.has_flag(StoryDirector.CRUCIBLE_FLAG), "Lowe speaks three times at the Kiln (%d)" % kiln_pages)
	var kiln_left := 0
	for figure: Variant in smiths + pot:
		if is_instance_valid(figure):
			kiln_left += 1
	_check(kiln_left == 0, "the Choir runs and the crucible bursts (%d left)" % kiln_left)
	await _wait(1.8)
	_check(is_instance_valid(wyrm) and wyrm.mode != Slagwyrm.Mode.INTRO, "the Slagwyrm wakes and fights")
	kiln.queue_free()
	await _wait(0.1)
	var kiln_again: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(kiln_again)
	await _wait(1.0)
	_check(not Cutscene.active, "the crucible scene only plays once")
	for child in kiln_again.current_room.get_children():
		if child is Slagwyrm:
			_check(child._sprite.modulate.a > 0.5, "the Slagwyrm rises at once when Wren comes back")
	kiln_again.queue_free()
	await _wait(0.1)
	Cutscene.fast = false


func _test_play() -> void:
	GameState.reset_new_game()
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var player: Player = game.player
	var room: Room = game.current_room
	_check(player != null and room != null, "game builds Wren and the first room")
	if player == null or room == null:
		return
	_check(room.coord == Vector2i.ZERO, "game starts in room 0,0")

	# Movement.
	var start_x := player.global_position.x
	Input.action_press("move_right")
	await _wait(0.3)
	Input.action_release("move_right")
	_check(player.global_position.x > start_x + 10.0, "Wren walks right")

	# Tidestone checkpoint saves the game.
	var stone: Tidestone = null
	for child in room.get_children():
		if child is Tidestone:
			stone = child
	_check(stone != null, "room 0,0 has a Tidestone")
	if stone:
		player.global_position = room.global_position + stone.position + Vector2(0, 16)
		await _wait(0.3)
		_check(SaveManager.has_save(), "touching a Tidestone saves")
		_check(GameState.checkpoint_pos == stone.position + Tidestone.CHECKPOINT_OFFSET, "Tidestone sets the checkpoint")

	# Walk off the east edge into the next room.
	player.global_position = room.global_position + Vector2(Room.SIZE.x - 2.0, 6 * Room.TILE + 12)
	Input.action_press("move_right")
	await _wait(1.0)
	Input.action_release("move_right")
	room = game.current_room
	_check(room.coord == Vector2i(1, 0), "room transition east (now in %s)" % room.coord)
	_check(GameState.room_coord == Vector2i(1, 0), "GameState tracks the current room")

	# Clear the room so only test enemies are present.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(0.1)
	var row_y := 7 * Room.TILE + 12

	# Sword hits a Scuttler and builds Resonance.
	GameState.resonance = 0.0
	var crab := Scuttler.new()
	crab.ai_enabled = false
	crab.position = Vector2(120, row_y)
	room.add_child(crab)
	player.global_position = room.global_position + Vector2(100, row_y)
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.start_attack()
	await _wait(0.4)
	_check(crab.hp == crab.max_hp - 1, "sword hits a Scuttler (hp %d)" % crab.hp)
	_check(GameState.resonance > 0.0, "sword hits build Resonance")
	_check(Engine.time_scale == 1.0, "hitstop ends")

	# Shellback blocks hits on its shell but not from behind.
	var shell := Shellback.new()
	shell.ai_enabled = false
	shell.shell_dir = Vector2.LEFT
	shell.position = Vector2(220, row_y)
	room.add_child(shell)
	player.global_position = room.global_position + Vector2(200, row_y)
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.start_attack()
	await _wait(0.4)
	_check(shell.hp == shell.max_hp, "Shellback blocks a hit on its shell")
	shell.shell_dir = Vector2.RIGHT
	player.global_position = shell.global_position - Vector2(20, 0)
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.start_attack()
	await _wait(0.4)
	_check(shell.hp == shell.max_hp - 1, "Shellback takes a hit from behind (hp %d)" % shell.hp)
	crab.queue_free()
	shell.queue_free()
	await _wait(0.1)

	# Bogskipper can't be hit while buried, rises when Wren comes close.
	var bog := Bogskipper.new()
	bog.position = Vector2(150, row_y)
	room.add_child(bog)
	player.global_position = room.global_position + Vector2(300, row_y)
	await _wait(0.1)
	_check(bog.take_hit(1, Vector2.RIGHT) == Enemy.HitResult.IGNORED, "a buried Bogskipper can't be hit")
	_check(not bog.is_exposed(), "Bogskipper stays buried while Wren is far away")
	player.global_position = room.global_position + Vector2(150 - Bogskipper.WAKE_RANGE + 16, row_y)
	await _wait(Bogskipper.RISE_TIME * 0.5)
	_check(bog.mode == Bogskipper.Mode.RISE, "Bogskipper rises when Wren comes close")
	_check(bog.take_hit(1, Vector2.RIGHT) == Enemy.HitResult.HIT, "a risen Bogskipper can be hit")
	_check(room.get_children().any(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.HIT), "a blow that lands throws a spark")
	bog.hp = 1
	bog.take_hit(1, Vector2.RIGHT)
	_check(room.get_children().any(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.FALL), "a foe that falls leaves dust")
	var bits: Array = room.get_children().filter(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.SHARDS)
	_check(bits.size() == 1 and bits[0].tint != HitSpark.DUST and bits[0].tint.a > 0.5, "and bits of it fly, in its own colour (%s)" % (bits[0].tint if bits.size() == 1 else "none"))
	await _wait(0.6)
	_check(not room.get_children().any(func(n: Node) -> bool: return n is HitSpark), "sparks and dust clear away")
	# A beaten boss's last light lifts off it as it fades.
	var lifter := Scuttler.new()
	lifter.ai_enabled = false
	lifter.position = Vector2(150, row_y)
	room.add_child(lifter)
	await _wait(0.05)
	lifter._dissolve()
	_check(room.get_children().filter(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.RISE).size() == 2, "a fading boss sends up two waves of light")
	lifter.queue_free()
	await _wait(2.1)
	_check(not room.get_children().any(func(n: Node) -> bool: return n is HitSpark), "and they lift away")
	# A landed blow squashes a foe flat for a moment, then it springs back.
	var squashee := Scuttler.new()
	squashee.ai_enabled = false
	squashee.position = Vector2(150, row_y)
	room.add_child(squashee)
	await _wait(0.1)
	squashee.take_hit(1, Vector2.RIGHT)
	# physics_frame fires before nodes' _physics_process, so wait two.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(squashee._sprite.scale.x > squashee._sprite_base_scale.x and squashee._sprite.scale.y < squashee._sprite_base_scale.y, "a blow squashes the foe")
	await _wait(0.3)
	_check(squashee._sprite.scale.is_equal_approx(squashee._sprite_base_scale), "and it springs back")
	squashee.queue_free()
	await _wait(0.1)

	# Boss shots that override _init still join enemy_shots (cleared when a
	# boss falls).
	for shot: Projectile in [IceChunk.new(), InkBlob.new(), SlagGlob.new(), BoneShard.new()]:
		_check(shot.is_in_group("enemy_shots") and shot.shield_tier >= 2, "%s is cleared with the boss's other shots" % shot.get_script().get_global_name())
		shot.free()
	# Knocked into a pit by a blow: the blow costs a bubble, the fall doesn't.
	GameState.refill()
	await _wait(Player.INVULN_TIME + 0.1)
	player.take_damage(1, player.global_position + Vector2(-10, 0))
	var after_blow := GameState.bubbles
	player.fall(player.global_position)
	await _wait(0.6)
	_check(GameState.bubbles == after_blow, "a fall right after a blow takes no second bubble (%d of %d)" % [GameState.bubbles, after_blow])
	GameState.refill()
	await _wait(Player.INVULN_TIME + 0.1)
	var before := GameState.bubbles
	player.fall(player.global_position)
	await _wait(0.6)
	_check(GameState.bubbles == before - 1, "a fall on its own still takes a bubble")
	GameState.refill()
	await _wait(Player.INVULN_TIME + 0.1)

	# A boss's last blow: the great star, time held, then a breath of slow
	# motion, and time back to normal after.
	var stand_in := Scuttler.new()
	stand_in.ai_enabled = false
	stand_in.position = Vector2(150, row_y)
	room.add_child(stand_in)
	stand_in.add_to_group("boss")
	await _wait(0.1)
	# Stars circle a boss's head only while the sword can hurt it.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var stars := stand_in.get_node_or_null("DazeStars")
	_check(stars != null and stars.visible, "stars circle a boss open to the sword")
	stand_in._sprite.visible = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(stars != null and not stars.visible, "but not while the boss is out of sight")
	stand_in._sprite.visible = true
	# Worn down to half, a boss gives off puffs of strain.
	stand_in.max_hp = 4
	stand_in.hp = 4
	stand_in.take_hit(1, Vector2.RIGHT)
	_check(not stand_in.is_worn() and not room.get_children().any(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.WEAR), "a boss above half health shows no wear")
	stand_in.take_hit(1, Vector2.RIGHT)
	_check(stand_in.is_worn() and room.get_children().any(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.WEAR), "the blow that wears a boss to half sends up puffs")
	await _wait(1.0)
	_check(room.get_children().any(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.WEAR), "and the puffs keep coming")
	stand_in.hp = 1
	stand_in.take_hit(1, Vector2.RIGHT)
	# Time is held now, so tick it by hand: the fallen boss loses its stars.
	stand_in._physics_process(0.0)
	_check(stars != null and not stars.visible, "a fallen boss has no stars")
	_check(room.get_children().any(func(n: Node) -> bool: return n is HitSpark and (n as HitSpark).kind == HitSpark.Kind.FINAL) and Engine.time_scale == 0.0, "a boss's last blow throws the great star and holds time")
	await get_tree().create_timer(0.35, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, Feel.SLOW_SCALE), "then time runs slow a moment (%s)" % Engine.time_scale)
	await get_tree().create_timer(Feel.SLOW_TIME + 0.2, true, false, true).timeout
	_check(Engine.time_scale == 1.0, "and comes back to normal")
	GameState.refill()

	# Lanternmoth circles Wren, flares (its tell), then dives.
	var moth := Lanternmoth.new()
	moth.position = Vector2(200, row_y)
	room.add_child(moth)
	player.global_position = room.global_position + Vector2(140, row_y)
	await _wait(0.2)
	_check(moth.mode == Lanternmoth.Mode.CIRCLE, "Lanternmoth starts circling when it sees Wren")
	var flared := false
	for i in 30:
		await _wait(0.1)
		if moth.is_flaring():
			flared = true
			break
	_check(flared, "Lanternmoth flares before it dives")
	await _wait(Lanternmoth.FLARE_TIME + 0.05)
	_check(moth.mode in [Lanternmoth.Mode.DIVE, Lanternmoth.Mode.RETREAT], "Lanternmoth dives after the flare")
	_check(moth.take_hit(1, Vector2.RIGHT) == Enemy.HitResult.HIT, "a Lanternmoth can be hit")
	await _wait(0.4)
	_check(not is_instance_valid(moth), "one hit downs a Lanternmoth")
	GameState.refill()
	await _wait(Player.INVULN_TIME)
	await _wait(0.1)

	# Hold Sword to charge, release to spin: hits all around for 2.
	var ring_crab := Scuttler.new()
	ring_crab.ai_enabled = false
	ring_crab.max_hp = 3
	ring_crab.position = Vector2(100, row_y)
	room.add_child(ring_crab)
	player.global_position = room.global_position + Vector2(100, row_y + 22)
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	Input.action_press("attack")
	await _wait(Player.ATTACK_TIME + Player.CHARGE_TIME + 0.2)
	_check(player.is_charged(), "holding Sword charges a spin")
	Input.action_release("attack")
	await _wait(Player.SPIN_TIME + 0.2)
	_check(ring_crab.hp == ring_crab.max_hp - Player.SPIN_DAMAGE, "spin attack hits an enemy behind Wren (hp %d)" % ring_crab.hp)
	_check(player.state == Player.State.MOVE, "spin ends back in normal movement")
	ring_crab.queue_free()
	await _wait(0.1)

	# A swing pressed near the end of the last one still comes out after it,
	# and only once.
	Input.action_press("attack")
	await _wait(0.05)
	Input.action_release("attack")
	await _wait(Player.ATTACK_TIME - 0.12)
	_check(player.state == Player.State.ATTACK, "the first swing is still going")
	Input.action_press("attack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("attack")
	await _wait(0.12)
	_check(player.state == Player.State.ATTACK and player._state_time < Player.ATTACK_TIME - 0.02,
		"a swing pressed late in the last one follows straight on (state %d)" % player.state)
	await _wait(Player.ATTACK_TIME - player._state_time + 0.06)
	_check(player.state == Player.State.MOVE, "and then Wren stands ready, with no extra swing (state %d)" % player.state)
	# Pressed late and still held as the swing ends, a short tap still swings
	# rather than starting a charge that comes to nothing.
	await _wait(0.2)
	Input.action_press("attack")
	await _wait(0.05)
	Input.action_release("attack")
	await _wait(Player.ATTACK_TIME - 0.12)
	Input.action_press("attack")
	await _wait(0.12)
	_check(player.state == Player.State.CHARGE, "a late press held past the swing's end readies a charge (state %d)" % player.state)
	Input.action_release("attack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.state == Player.State.ATTACK, "let go early, that late press swings (state %d)" % player.state)
	await _wait(Player.ATTACK_TIME + 0.1)

	# Hum heals one bubble for a third of the meter.
	GameState.bubbles = 2
	GameState.resonance = GameState.resonance_max
	Input.action_press("hum")
	await _wait(1.1)
	Input.action_release("hum")
	_check(GameState.bubbles == 3, "humming restores a bubble (bubbles %d)" % GameState.bubbles)
	_check(is_equal_approx(GameState.resonance, GameState.resonance_max * 2.0 / 3.0), "humming spends a third of the meter")
	# Hum set to toggle (an accessibility option): one tap starts it, it
	# keeps going with the key up, and a second tap stops it.
	await _wait(0.3)
	_check(player.state == Player.State.MOVE, "letting go of Hum ends the hum (state %d)" % player.state)
	var was_toggle := Settings.hum_toggle
	Settings.hum_toggle = true
	var hum_key := Settings.main_key("hum") as Key
	GameState.bubbles = 2
	GameState.resonance = GameState.resonance_max
	_press_key(hum_key, true)
	await _wait(0.1)
	_press_key(hum_key, false)
	await _wait(1.0)
	_check(player.state == Player.State.HUM and GameState.bubbles == 3,
		"with Hum on toggle, a tap starts a hum that heals (state %d, bubbles %d)" % [player.state, GameState.bubbles])
	_press_key(hum_key, true)
	await _wait(0.1)
	_press_key(hum_key, false)
	await _wait(0.2)
	_check(player.state == Player.State.MOVE, "a second tap stops the hum")
	Settings.hum_toggle = was_toggle

	# A Spitter fires a projectile.
	var spitter := Spitter.new()
	spitter.position = Vector2(200, row_y)
	room.add_child(spitter)
	player.global_position = room.global_position + Vector2(120, row_y)
	# Back to it: facing it, the cork buckler would turn the shot aside.
	player.facing = Vector2.LEFT
	await _wait(3.0)
	_check(GameState.bubbles < 3 or _count_projectiles(room) > 0, "Spitter shoots at Wren")
	spitter.queue_free()
	for child in room.get_children():
		if child is Projectile:
			child.queue_free()
	# Let any invulnerability from a Spitter hit run out first.
	await _wait(Player.INVULN_TIME + 0.2)

	# Dying shows the game over screen; waking returns Wren to the last
	# Tidestone with full breath.
	GameState.bubbles = 1
	game.player.take_damage(1, game.player.global_position + Vector2(10, 0))
	var over: GameOverScreen = null
	for i in 40:
		await _wait(0.1)
		for child in game.get_children():
			if child is GameOverScreen:
				over = child
		if over:
			break
	_check(over != null, "running out of breath shows the game over screen")
	if over:
		while over._time < GameOverScreen.INPUT_DELAY + 0.05:
			await _wait(0.05)
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _wait(0.05)
	var release := InputEventAction.new()
	release.action = "interact"
	Input.parse_input_event(release)
	for i in 40:
		await _wait(0.1)
		if game.player != null and not game.busy:
			break
	_check(GameState.bubbles == GameState.max_bubbles, "respawn refills breath")
	_check(game.current_room != null and game.current_room.coord == Vector2i.ZERO, "respawn at the Tidestone's room (%s)" % (game.current_room.coord if game.current_room else "none"))
	_check(game.player != null and game.player.state != Player.State.DEAD, "Wren is back on their feet")
	game.queue_free()
	await _wait(0.1)


func _count_projectiles(room: Room) -> int:
	var count := 0
	for child in room.get_children():
		if child is Projectile:
			count += 1
	return count



## Lantern Mire: the Glowmoth Lantern, dark rooms, veiled planks, Shades,
## braziers and the Pale Congregation.
func _test_mire_dungeon() -> void:
	_check(ResourceLoader.exists("res://rooms/room_25_10.tscn"), "Lantern Mire has an entry room")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(25, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	_check(GameState.dungeon == "mire" and game.current_room.biome == "mire", "Wren starts inside Lantern Mire")
	_check(not game.current_room.has_node("Darkness"), "the entry isn't dark")
	_check(not player.use_item("glowmoth_lantern"), "no lantern before it's found")
	GameState.give_item("glowmoth_lantern")
	_check(GameState.item_slots.has("glowmoth_lantern"), "the lantern goes in an item slot")

	# The Drowned Walk: dark, and its planks only there in the light.
	var room := await _goto(game, Vector2i(26, 9), Vector2i(2, 6))
	await _calm(room)
	_check(room.has_node("Darkness"), "the Drowned Walk is dark")
	var planks := _child_of(room, VeilPlank)
	_check(planks.size() > 10 and planks.all(func(p: VeilPlank) -> bool: return not p.is_real()), "its planks aren't there in the dark")
	player.global_position = _tile_pos(room, Vector2i(3, 6))
	Input.action_press("move_right")
	await _wait(0.8)
	Input.action_release("move_right")
	var local := player.global_position - room.global_position
	_check(local.x < 5 * Room.TILE, "Wren can't walk out over the dark water (at %s)" % local)
	_check(player.use_item("glowmoth_lantern") and player.lantern_raised, "Wren raises the lantern")
	await _wait(0.2)
	_check(planks.filter(func(p: VeilPlank) -> bool: return p.is_real()).size() > 0, "planks near the raised lantern become real")
	Input.action_press("move_right")
	await _wait(0.9)
	Input.action_release("move_right")
	local = player.global_position - room.global_position
	_check(local.x > 9 * Room.TILE, "in the lantern's light Wren walks the planks to the island (at %s)" % local)

	# A Shade: out of the light the sword finds nothing; in it, it's hurt.
	player.use_item("glowmoth_lantern")
	_check(not player.lantern_raised, "and lowers it again")
	var shade := Shade.new()
	shade.position = player.position - room.position + Vector2(0, 20)
	room.add_child(shade)
	await _wait(0.1)
	_check(shade.take_hit(1, Vector2.DOWN) == Enemy.HitResult.BLOCKED, "a Shade in the dark can't be hurt")
	player.use_item("glowmoth_lantern")
	await _wait(0.05)
	_check(shade.exposed and shade.take_hit(1, Vector2.DOWN) == Enemy.HitResult.HIT, "caught in the lantern's light, it can")
	shade.queue_free()

	# The Hall of Braziers: light all four and the bars open on a key.
	room = await _goto(game, Vector2i(26, 8), Vector2i(11, 11))
	await _calm(room)
	if not player.lantern_raised:
		player.use_item("glowmoth_lantern")
	var braziers := _child_of(room, Brazier)
	_check(braziers.size() == 4, "four braziers stand in the Hall")
	var bars: Bars = _child_of(room, Bars)[0]
	for brazier: Brazier in braziers:
		_check(not bars.is_open, "the bars stay shut until every brazier burns")
		player.global_position = brazier.global_position + Vector2(0, 16)
		await _wait(0.1)
		_check(brazier.lit, "the raised lantern lights a brazier")
	await _wait(0.4)
	_check(bars.is_open, "all four lit, the bars open")
	player.use_item("glowmoth_lantern")
	player.global_position = _tile_pos(room, Vector2i(11, 3))
	player.facing = Vector2.UP
	await _wait(0.4)
	player.try_interact()
	_check(GameState.keys("mire") == 1, "the Hall's chest holds a small key")
	await _wait(0.6)

	# The Lych Walk: lantern up, out along the planks to three braziers;
	# all three lit open the bars on the big key.
	room = await _goto(game, Vector2i(24, 7), Vector2i(11, 11))
	await _calm(room)
	if not player.lantern_raised:
		player.use_item("glowmoth_lantern")
	player.global_position = _tile_pos(room, Vector2i(11, 10))
	Input.action_press("move_up")
	await _wait(0.6)
	Input.action_release("move_up")
	local = player.global_position - room.global_position
	_check(local.y < 9 * Room.TILE and player.state == Player.State.MOVE, "lantern up, Wren walks the plank out to the Lych Walk's island (at %s)" % local)
	var lych: Array = _child_of(room, Brazier)
	_check(lych.size() == 3, "three braziers stand in the Lych Walk")
	var lych_bars: Bars = _child_of(room, Bars)[0]
	for brazier: Brazier in lych:
		# (The walk out lights the island's brazier on the way.)
		if lych.any(func(b: Brazier) -> bool: return not b.lit):
			_check(not lych_bars.is_open, "the Lych Walk's bars stay shut until every brazier burns")
		player.global_position = brazier.global_position + Vector2(0, 16)
		await _wait(0.1)
		_check(brazier.lit, "the raised lantern lights a Lych Walk brazier")
	await _wait(0.4)
	_check(lych_bars.is_open, "all three lit, the Lych Walk's bars open")
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Lych Walk's chest holds the big key")
	player.use_item("glowmoth_lantern")

	# The Sunken Crypt and the Lantern Loft, off the main path.
	room = await _goto(game, Vector2i(24, 10), Vector2i(11, 1))
	await _calm(room)
	_check(_child_of(room, VeilPlank).size() > 20 and _child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "glint"), "the Sunken Crypt's long plank walk leads to a chest")
	room = await _goto(game, Vector2i(26, 7), Vector2i(19, 11))
	await _wait(0.3)
	_check(_child_of(room, Enemy).size() >= 4, "the Lantern Loft has a fight in it")

	# The Pale Congregation (the calf scene after it is tested in _test_story).
	GameState.refill()
	GameState.set_flag(StoryDirector.CALF_FLAG)
	room = await _goto(game, Vector2i(25, 7), Vector2i(11, 10))
	var bosses := _child_of(room, PaleCongregation)
	_check(bosses.size() == 1, "the Pale Congregation waits in the Still Pool")
	if bosses.size() == 1:
		var boss: PaleCongregation = bosses[0]
		player._invuln = 60.0
		_check(boss.wisps.size() == 22, "its calf is made of 22 wisps")
		await _wait(3.0)
		_check(not boss.is_exposed(), "gathered round the heart, the wisps shield it")
		_check(boss.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED and boss.hp == 6, "the sword can't reach the heart through them")
		player.use_item("glowmoth_lantern")
		await _wait(1.2)
		_check(boss.is_exposed(), "raising the lantern draws the wisps away to Wren")
		var near := 0
		for wisp: Dictionary in boss.wisps:
			if (wisp["at"] as Vector2).distance_to(player.global_position - room.global_position) < PaleCongregation.ORBIT_START + 20.0:
				near += 1
		_check(near > 11, "and they circle Wren, closing in (%d near)" % near)
		player.use_item("glowmoth_lantern")
		await _wait(0.2)
		_check(boss.is_exposed() and boss.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT, "lowered, the heart stays bare while they drift home")
		await _wait(4.0)
		_check(not boss.is_exposed(), "until they gather round it again")
		while boss.hp > 0:
			boss._stun = 0.0
			for wisp: Dictionary in boss.wisps:
				wisp["home"] = false
			boss.take_hit(1, Vector2.UP)
		_check(GameState.flags.get(PaleCongregation.DEFEATED_FLAG, false), "striking the bare heart lays the Congregation to rest")
		await _wait(5.0)
		var bell: Tidebell = null
		for child in room.get_children():
			if child is Tidebell:
				bell = child
		_check(bell != null and bell.bell == "mire", "the Moth Bell rises in the Still Pool")
		if bell:
			await _scene_over(game)
			bell.interact()
			_check(GameState.has_flag(Tidebell.flag_for("mire")), "ringing the Moth Bell counts as a Tidebell")
			await _play_scene(game, 10.0)
		_check(_child_of(room, Doorway).size() == 1, "a way out opens after the fight")
	if player.lantern_raised:
		player.use_item("glowmoth_lantern")
	game.queue_free()
	await _wait(0.1)


## Gale Spire: the Kite Cloak, wind fans, floors that drop to the one
## below, and the Stormheron.
func _test_gale_dungeon() -> void:
	_check(ResourceLoader.exists("res://rooms/room_28_10.tscn"), "Gale Spire has an entry room")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(28, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	_check(GameState.dungeon == "gale" and game.current_room.biome == "gale", "Wren starts inside Gale Spire")
	_check(not player.use_item("kite_cloak"), "no cloak before it's found")
	GameState.give_item("kite_cloak")
	_check(GameState.item_slots.has("kite_cloak"), "the cloak goes in an item slot")

	# The Rope Store: a fan's wind pushes Wren along its stream.
	var room := await _goto(game, Vector2i(27, 10), Vector2i(10, 6))
	await _calm(room)
	var fans := _child_of(room, WindFan)
	_check(fans.size() == 1 and (fans[0] as WindFan).direction == Vector2.RIGHT, "the Rope Store has a fan blowing east")
	player.global_position = _tile_pos(room, Vector2i(10, 6))
	var start := player.global_position.x
	await _wait(0.5)
	_check(player.global_position.x > start + 15.0, "standing in its stream, Wren is pushed along (%.0f px)" % (player.global_position.x - start))
	Input.action_press("move_left")
	await _wait(1.6)
	Input.action_release("move_left")
	_check(player.global_position.x < start - 20.0, "but Wren can still walk against it")

	# The Gust Gallery: on foot the drop is impassable; the cloak and the
	# fan's wind carry Wren over.
	room = await _goto(game, Vector2i(29, 9), Vector2i(2, 6))
	await _calm(room)
	var before := GameState.bubbles
	player.global_position = _tile_pos(room, Vector2i(3, 2))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	_check(player.use_item("kite_cloak") and player.airborne, "Wren throws the cloak open and glides")
	await _wait(1.4)
	await _wait(0.8)
	var local := player.global_position - room.global_position
	_check(GameState.bubbles == before - 1 and local.x < 6 * Room.TILE, "without wind Wren drops short into the sky (at %s)" % local)
	GameState.refill()
	await _wait(1.0)
	player.global_position = _tile_pos(room, Vector2i(4, 6))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(3.0)
	await _wait(0.6)
	local = player.global_position - room.global_position
	_check(GameState.bubbles == GameState.max_bubbles and local.x > 19 * Room.TILE and player.state == Player.State.MOVE, "the fan's wind carries Wren across to the far ledge (at %s)" % local)

	# The Lantern Span: the planks over the sky show only in the raised
	# lantern's light; the hook carries Wren over the break to the post,
	# and the low stream blows home.
	for item in ["glowmoth_lantern", "tide_hook", "stonebreaker"]:
		GameState.give_item(item)
	room = await _goto(game, Vector2i(30, 9), Vector2i(1, 3))
	await _calm(room)
	var span_planks := _child_of(room, VeilPlank)
	_check(span_planks.size() == 8 and span_planks.all(func(p: VeilPlank) -> bool: return not p.is_real()), "the Span's planks aren't there in the dark")
	player.global_position = _tile_pos(room, Vector2i(3, 6))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	before = GameState.bubbles
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(2.4)
	local = player.global_position - room.global_position
	_check(local.x < 4 * Room.TILE and GameState.bubbles == before - 1, "a glide ending over the unlit planks drops Wren back on the ledge (at %s)" % local)
	GameState.refill()
	await _wait(1.0)
	player.global_position = _tile_pos(room, Vector2i(3, 6))
	player.velocity = Vector2.ZERO
	player.use_item("glowmoth_lantern")
	Input.action_press("move_right")
	await _wait(0.9)
	Input.action_release("move_right")
	local = player.global_position - room.global_position
	_check(local.x > 6.5 * Room.TILE and local.x < 10 * Room.TILE, "by lantern light Wren walks out along the planks (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(9, 6))
	player.velocity = Vector2.ZERO
	await _wait(0.2)
	player.use_item("glowmoth_lantern")
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	_check(player.use_item("tide_hook"), "standing on a plank, Wren lowers the lantern and fires the hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(int(local.x) / Room.TILE == 15 and player.state == Player.State.MOVE, "the hook carries Wren over the break to the post (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(21, 9))
	player.facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	before = GameState.bubbles
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(4.5)
	local = player.global_position - room.global_position
	_check(local.x < 4 * Room.TILE and GameState.bubbles == before, "the low stream blows Wren home across the Span (at %s)" % local)

	# The Weathercock Roost: hook up to the island, ride its fans' stream
	# to the west ledge, hammer the pegs down to the key, and ride the low
	# stream back.
	room = await _goto(game, Vector2i(30, 8), Vector2i(20, 11))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(11, 9))
	player.facing = Vector2.UP
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(int(local.y) / Room.TILE == 3 and local.x > 10 * Room.TILE and local.x < 13 * Room.TILE, "the hook lifts Wren onto the Roost's island (at %s)" % local)
	player.facing = Vector2.LEFT
	await _wait(0.1)
	before = GameState.bubbles
	player.use_item("kite_cloak")
	await _wait(3.5)
	local = player.global_position - room.global_position
	_check(local.x < 5 * Room.TILE and GameState.bubbles == before, "the island's fans carry Wren to the west ledge (at %s)" % local)
	var roost_pegs := _child_of(room, Peg)
	_check(roost_pegs.size() == 4, "a row of pegs fences the key off")
	player.global_position = _tile_pos(room, Vector2i(2, 6))
	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("stonebreaker")
	await _wait(0.6)
	_check(roost_pegs.any(func(p: Peg) -> bool: return p.down), "the mallet drives a peg flush")
	Input.action_press("move_down")
	await _wait(0.6)
	Input.action_release("move_down")
	local = player.global_position - room.global_position
	_check(local.y > 7.5 * Room.TILE, "over the hammered peg Wren reaches the key (at %s)" % local)
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "small_key"), "the Roost's chest holds a small key")
	player.global_position = _tile_pos(room, Vector2i(2, 10))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	before = GameState.bubbles
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(3.5)
	local = player.global_position - room.global_position
	_check(local.x > 10 * Room.TILE and GameState.bubbles == before, "the low stream blows Wren back to the way in (at %s)" % local)

	# The Bell Shaft: falling through its floor drops Wren to the Fan Hall.
	room = await _goto(game, Vector2i(28, 8), Vector2i(11, 11))
	await _calm(room)
	before = GameState.bubbles
	player.global_position = _tile_pos(room, Vector2i(10, 10))
	Input.action_press("move_up")
	await _wait(0.6)
	Input.action_release("move_up")
	await _wait(1.4)
	_check(game.current_room.coord == Vector2i(28, 9) and GameState.bubbles == before, "a hole in the Shaft's floor drops Wren to the Fan Hall, unhurt")

	# The updraft carries Wren up the Shaft to the top landing.
	room = await _goto(game, Vector2i(28, 8), Vector2i(12, 11))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(12, 10))
	player.facing = Vector2.UP
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(2.0)
	player.use_item("kite_cloak")
	await _wait(0.3)
	local = player.global_position - room.global_position
	_check(game.current_room == room and local.y < 3 * Room.TILE, "the Shaft's updraft lifts Wren to the top landing (at %s)" % local)

	# The Bell Cage: up, across and down three fans' streams to the big
	# key, and the long stream home.
	room = await _goto(game, Vector2i(27, 7), Vector2i(3, 11))
	await _calm(room)
	before = GameState.bubbles
	var rides := [[Vector2i(1, 9), Vector2.UP], [Vector2i(3, 1), Vector2.RIGHT], [Vector2i(22, 2), Vector2.DOWN], [Vector2i(18, 10), Vector2.LEFT]]
	var ends: Array[Vector2] = []
	for ride: Array in rides:
		player.global_position = _tile_pos(room, ride[0])
		player.facing = ride[1]
		await _wait(0.1)
		player.use_item("kite_cloak")
		await _wait(3.2)
		ends.append(player.global_position - room.global_position)
	_check(game.current_room == room and ends[0].y < 3 * Room.TILE, "the Bell Cage's updraft lifts Wren to the top-left ledge (at %s)" % ends[0])
	_check(ends[1].x > 19 * Room.TILE and ends[1].y < 3 * Room.TILE, "the top stream carries Wren across to the far ledge (at %s)" % ends[1])
	_check(ends[2].x > 18 * Room.TILE and ends[2].y > 8.5 * Room.TILE, "even from the corner, the downdraft sets Wren by the big key (at %s)" % ends[2])
	_check(ends[3].x < 6 * Room.TILE and ends[3].y > 9 * Room.TILE, "the long stream home carries Wren back to the way in (at %s)" % ends[3])
	_check(GameState.bubbles == before and player.state == Player.State.MOVE, "all four rides without a fall")
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Bell Cage's chest holds the big key")
	_check(room.falls_through and room.fall_to == Vector2i(27, 8), "a fall from the Bell Cage lands in the Rookery")

	# The Bellrope Walk: the stream runs on over open sky, so Wren folds
	# the cloak over the island.
	room = await _goto(game, Vector2i(29, 10), Vector2i(1, 6))
	await _calm(room)
	before = GameState.bubbles
	player.global_position = _tile_pos(room, Vector2i(3, 5))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(3.5)
	local = player.global_position - room.global_position
	_check(GameState.bubbles == before - 1 and local.x < 5 * Room.TILE, "ridden to the end, the stream drops Wren into the sky (back at %s)" % local)
	GameState.refill()
	await _wait(1.0)
	player.global_position = _tile_pos(room, Vector2i(3, 5))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("kite_cloak")
	var waited := 0.0
	while (player.global_position - room.global_position).x < 12.5 * Room.TILE and waited < 3.0:
		await get_tree().physics_frame
		waited += 1.0 / 60.0
	Input.action_press("item_1")
	Input.action_press("item_2")
	await get_tree().physics_frame
	Input.action_release("item_1")
	Input.action_release("item_2")
	await _wait(0.6)
	local = player.global_position - room.global_position
	_check(GameState.bubbles == GameState.max_bubbles and local.x > 11 * Room.TILE and local.x < 16 * Room.TILE and not player.airborne, "folded over the island, Wren lands on it (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(12, 8))
	player.facing = Vector2.LEFT
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(3.0)
	local = player.global_position - room.global_position
	_check(local.x < 5 * Room.TILE and GameState.bubbles == GameState.max_bubbles, "the island's fans blow Wren home (at %s)" % local)

	# The Stormheron (Vael's scene after it is tested in _test_story).
	GameState.refill()
	GameState.set_flag(StoryDirector.VAEL_FLAG)
	room = await _goto(game, Vector2i(28, 7), Vector2i(11, 10))
	var bosses := _child_of(room, Stormheron)
	_check(bosses.size() == 1, "the Stormheron waits on the Crown")
	if bosses.size() == 1:
		var heron: Stormheron = bosses[0]
		player._invuln = 60.0
		_check(_child_of(room, LightningRod).size() == 2, "lightning rods stand on the Crown's side islands")
		await _wait(2.0)
		_check(heron.mode == Stormheron.Mode.PERCH and heron.rod != null, "it comes down onto a rod")
		_check(heron.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "perched, the sword can't reach it")
		heron._throws = Stormheron.THROWS_PER_STORM
		heron._timer = 0.0
		await _wait(0.1)
		_check(heron.mode == Stormheron.Mode.STORM and heron.rod.charged, "the storm gathers on its rod")
		await _wait(Stormheron.STORM_TIME + 0.1)
		_check(heron.mode == Stormheron.Mode.GROUNDED, "the bolt knocks it to the ground")
		_check(heron.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT and heron.hp == 5, "grounded, the sword finds it")
		heron._stun = 0.0
		heron.take_hit(1, Vector2.UP)
		await _wait(0.4)
		_check(heron.mode == Stormheron.Mode.FLY, "after two strikes it flies to another rod")
		await _wait(Stormheron.FLY_TIME + 0.2)
		heron.mode = Stormheron.Mode.GROUNDED
		while heron.hp > 0:
			heron._stun = 0.0
			heron._hits_this_landing = 0
			heron.take_hit(1, Vector2.UP)
		_check(GameState.flags.get(Stormheron.DEFEATED_FLAG, false), "striking it enough brings the Stormheron down")
		await _wait(3.5)
		var bell: Tidebell = null
		for child in room.get_children():
			if child is Tidebell:
				bell = child
		_check(bell != null and bell.bell == "gale", "the Storm Bell rises on the Crown")
		if bell:
			GameState.set_flag(StoryDirector.TURNED_FLAG)
			await _scene_over(game)
			bell.interact()
			_check(GameState.has_flag(Tidebell.flag_for("gale")), "ringing the Storm Bell counts as a Tidebell")
			await _play_scene(game, 10.0)
	game.queue_free()
	await _wait(0.1)

## Hollow Glacier: ice, the Frostfang Bow freezing water, ice eyes, crates
## sliding on ice, and Rimeback.
func _test_glacier_dungeon() -> void:
	_check(ResourceLoader.exists("res://rooms/room_32_10.tscn"), "Hollow Glacier has an entry room")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(32, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	_check(GameState.dungeon == "glacier" and game.current_room.biome == "glacier", "Wren starts inside Hollow Glacier")
	_check(not player.use_item("frostfang_bow"), "no bow before it's found")
	GameState.give_item("frostfang_bow")
	_check(GameState.item_slots.has("frostfang_bow"), "the bow goes in an item slot")

	# Ice: Wren keeps sliding after letting go.
	var room: Room = game.current_room
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(14, 3))
	await _wait(0.1)
	_check(player.on_ice(), "the Entry's blue patches are ice")
	Input.action_press("move_right")
	await _wait(0.5)
	Input.action_release("move_right")
	var x0 := player.global_position.x
	await _wait(0.2)
	_check(player.global_position.x > x0 + 4.0, "let go on ice, Wren slides on (%.0f px)" % (player.global_position.x - x0))
	player.global_position = _tile_pos(room, Vector2i(9, 6))
	await _wait(0.1)
	_check(not player.on_ice(), "snow isn't ice")
	Input.action_press("move_right")
	await _wait(0.3)
	Input.action_release("move_right")
	await _wait(0.05)
	x0 = player.global_position.x
	await _wait(0.2)
	_check(absf(player.global_position.x - x0) < 1.0, "on snow, Wren stops at once")

	# The Black Pool: frost arrows freeze a way out to the island, too far
	# off the shore for the Kite Cloak.
	room = await _goto(game, Vector2i(33, 9), Vector2i(1, 6))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(2, 5))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	_check(room.tile_at(3, 5) == "~", "water lies between the shore and the island")
	GameState.give_item("kite_cloak")
	var bubbles_before := GameState.bubbles
	player.use_item("kite_cloak")
	await _wait(2.6)
	var glide_end := player.global_position - room.global_position
	_check(glide_end.x < 3 * Room.TILE and GameState.bubbles == bubbles_before - 1, "a glide that runs out over water drops Wren back on the shore (at %s)" % glide_end)
	GameState.refill()
	player.global_position = _tile_pos(room, Vector2i(2, 5))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.6)
	_check(player.use_item("frostfang_bow"), "Wren looses a frost arrow")
	await _wait(0.6)
	_check(room.tile_at(3, 5) == "I" and room.tile_at(4, 5) == "~", "the arrow freezes the first tile of the lake it reaches, only that one")
	for x in range(3, 10):
		player.global_position = _tile_pos(room, Vector2i(x, 5))
		player.velocity = Vector2.ZERO
		player.facing = Vector2.RIGHT
		await _wait(0.1)
		player.use_item("frostfang_bow")
		await _wait(0.5)
	_check(room.tile_at(9, 5) == "I", "arrow by arrow, the ice reaches the island")
	player.global_position = _tile_pos(room, Vector2i(8, 5))
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await _wait(0.7)
	Input.action_release("move_right")
	var local := player.global_position - room.global_position
	_check(local.x > 10 * Room.TILE, "Wren walks across the new ice to the island (at %s)" % local)

	# Leaving and coming back, the water has thawed.
	room = await _goto(game, Vector2i(32, 9), Vector2i(11, 11))
	room = await _goto(game, Vector2i(33, 9), Vector2i(1, 6))
	_check(room.tile_at(3, 5) == "~", "back in the room, the lake is open water again")

	# The Sluice: one crate slides down the ice channel once its pools are
	# frozen; the other is hooked out of its pocket, pushed onto the ice
	# past a frozen pool, and slides on towards its plate.
	GameState.give_item("tide_hook")
	room = await _goto(game, Vector2i(34, 9), Vector2i(1, 8))
	await _calm(room)
	var sluice_crates: Array = _child_of(room, Crate)
	sluice_crates.sort_custom(func(a: Crate, b: Crate) -> bool: return a.position.y < b.position.y)
	var sluice_bars: Bars = _child_of(room, Bars)[0]
	_check(sluice_crates.size() == 2 and not sluice_bars.is_open, "two crates, two plates, and bars on the key")
	var top: Crate = sluice_crates[0]
	for i in 4:
		top._slide(Vector2.RIGHT)
		await _wait(0.3)
	top._slide(Vector2.RIGHT)
	await _wait(0.4)
	_check(floori(top.position.x / Room.TILE) == 5, "open water stops the crate at the channel's mouth (col %d)" % floori(top.position.x / Room.TILE))
	room.freeze(Vector2i(6, 2))
	room.freeze(Vector2i(14, 2))
	await _wait(0.1)
	top._slide(Vector2.RIGHT)
	await _wait(2.0)
	_check(floori(top.position.x / Room.TILE) == 20, "frozen over, the channel carries the crate onto its plate (col %d)" % floori(top.position.x / Room.TILE))
	var low: Crate = sluice_crates[1]
	player.global_position = _tile_pos(room, Vector2i(15, 11))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	_check(floori(low.position.x / Room.TILE) == 16, "the hook drags the second crate out of its pocket (col %d)" % floori(low.position.x / Room.TILE))
	player.global_position = _tile_pos(room, Vector2i(18, 9))
	for i in 3:
		low._slide(Vector2.LEFT)
		await _wait(0.4)
	low._slide(Vector2.LEFT)
	await _wait(0.4)
	_check(floori(low.position.x / Room.TILE) == 13, "open water stops it at the lane's pool (col %d)" % floori(low.position.x / Room.TILE))
	room.freeze(Vector2i(11, 11))
	await _wait(0.1)
	low._slide(Vector2.LEFT)
	await _wait(2.0)
	_check(floori(low.position.x / Room.TILE) == 3, "over the frozen pool it slides the length of the ice (col %d)" % floori(low.position.x / Room.TILE))
	low._slide(Vector2.LEFT)
	await _wait(0.4)
	low._slide(Vector2.LEFT)
	await _wait(0.4)
	await _wait(0.2)
	_check(sluice_bars.is_open and GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "both plates down, the bars open on the key (low crate at col %d)" % floori(low.position.x / Room.TILE))
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "small_key"), "the Sluice's chest holds a small key")

	# The Eye Gallery: every eye open at once opens the gate.
	room = await _goto(game, Vector2i(32, 8), Vector2i(11, 11))
	await _calm(room)
	var eyes := _child_of(room, IceEye)
	_check(eyes.size() == 3, "the Eye Gallery has three ice eyes")
	var gallery_bars: Array = _child_of(room, Bars)
	_check(gallery_bars.size() == 3 and room.tile_at(1, 6) == "|" and room.tile_at(0, 6) == ".", "bars shut the Gallery's way west")
	player.global_position = _tile_pos(room, Vector2i(2, 10))
	player.velocity = Vector2.ZERO
	player.facing = Vector2.UP
	await _wait(0.1)
	player.use_item("frostfang_bow")
	await _wait(0.6)
	_check((eyes.filter(func(e: IceEye) -> bool: return e.lit)).size() == 1, "an arrow opens the eye it hits")
	eyes[0].arrow_hit(Vector2.UP)
	eyes[1].arrow_hit(Vector2.UP)
	eyes[2].arrow_hit(Vector2.UP)
	await _wait(0.5)
	_check((gallery_bars[0] as Bars).is_open and GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "with every eye open the bars west open")

	# The Icefall: hook to the island, wake its eye to open the bars, ride
	# the fans' stream to the far ledge, break the boulder to the key; the low stream
	# blows home.
	for item in ["tide_hook", "kite_cloak", "stonebreaker"]:
		GameState.give_item(item)
	room = await _goto(game, Vector2i(31, 8), Vector2i(22, 6))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(19, 6))
	player.facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	var at := player.global_position - room.global_position
	_check(int(at.x) / Room.TILE == 13 and int(at.y) / Room.TILE == 6, "the hook carries Wren to the Icefall's island (at %s)" % at)
	var icefall_bars: Array = _child_of(room, Bars)
	_check(icefall_bars.size() == 4 and not (icefall_bars[0] as Bars).is_open, "bars cut the island in two")
	await _shoot(room, player, Vector2i(12, 5), Vector2.UP)
	await _wait(0.3)
	_check((icefall_bars[0] as Bars).is_open, "an arrow wakes the island's eye and the bars open")
	player.global_position = _tile_pos(room, Vector2i(12, 8))
	player.facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	var icefall_before := GameState.bubbles
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(3.0)
	at = player.global_position - room.global_position
	_check(at.x < 5 * Room.TILE and GameState.bubbles == icefall_before, "the fans' stream carries Wren to the far ledge (at %s)" % at)
	var icefall_boulders := _child_of(room, Boulder)
	_check(icefall_boulders.size() == 1, "a boulder blocks the way up to the key")
	player.global_position = _tile_pos(room, Vector2i(2, 6))
	player.facing = Vector2.UP
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("stonebreaker")
	await _wait(0.6)
	_check(_child_of(room, Boulder).is_empty(), "the mallet breaks it")
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "small_key"), "the Icefall's chest holds a small key")
	player.global_position = _tile_pos(room, Vector2i(2, 10))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(3.5)
	at = player.global_position - room.global_position
	_check(at.x > 18 * Room.TILE and GameState.bubbles == icefall_before, "the low stream blows Wren home (at %s)" % at)

	# The Slide Hall: the crate slides on ice till the pool stops it;
	# frozen over, it slides on to the plate.
	room = await _goto(game, Vector2i(33, 8), Vector2i(1, 7))
	await _calm(room)
	var crate: Crate = _child_of(room, Crate)[0]
	crate._slide(Vector2.RIGHT)
	await _wait(1.2)
	var crate_tile := floori(crate.position.x / Room.TILE)
	_check(crate_tile == 10, "pushed onto the ice, the crate slides until the water stops it (col %d)" % crate_tile)
	room.freeze(Vector2i(11, 7))
	_check(room.is_frozen(Vector2i(11, 6)) and room.is_frozen(Vector2i(12, 7)), "a small pool freezes over all at once")
	await _wait(0.1)
	crate._slide(Vector2.RIGHT)
	await _wait(1.5)
	crate_tile = floori(crate.position.x / Room.TILE)
	_check(crate_tile == 18, "over the frozen pool it slides on to the plate (col %d)" % crate_tile)
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "the plate opens the bars north to the Rime Vault")

	# The Rime Vault: freeze out to the middle of the lake, then a lane
	# west, east and north for the arrows; all three eyes at once from the
	# middle open the bars on the big key.
	room = await _goto(game, Vector2i(33, 7), Vector2i(18, 11))
	await _calm(room)
	var vault_eyes := _child_of(room, IceEye)
	_check(vault_eyes.size() == 3, "three ice eyes look onto the Rime Vault's lake")
	var vault_bars: Bars = _child_of(room, Bars)[0]
	for i in 2:
		await _shoot(room, player, Vector2i(11, 10), Vector2.UP)
	_check(room.is_frozen(Vector2i(11, 9)) and room.is_frozen(Vector2i(11, 8)), "two arrows freeze a way out to the middle")
	player.global_position = _tile_pos(room, Vector2i(11, 10))
	player.velocity = Vector2.ZERO
	Input.action_press("move_up")
	await _wait(0.8)
	Input.action_release("move_up")
	await _wait(0.4)
	local = player.global_position - room.global_position
	_check(local.y < 8 * Room.TILE and local.y > 6 * Room.TILE, "Wren crosses the ice to the middle (at %s)" % local)
	for lane: Array in [[Vector2i(11, 6), Vector2.LEFT, Vector2i(7, 6)], [Vector2i(12, 6), Vector2.RIGHT, Vector2i(16, 6)], [Vector2i(11, 6), Vector2.UP, Vector2i(11, 3)]]:
		for i in 4:
			await _shoot(room, player, lane[0], lane[1])
		_check(room.is_frozen(lane[2]), "arrow by arrow, a lane freezes out to an eye (%s)" % lane[2])
	_check(not vault_bars.is_open, "frozen lanes alone don't open the bars")
	await _wait(IceEye.OPEN_TIME + 0.2)
	# From the top edge of the middle (where walking up the ice stops Wren),
	# the arrows still fly down the lanes' middles to the eyes.
	for lane: Array in [[Vector2(11, 6), Vector2.LEFT], [Vector2(12.4, 6), Vector2.RIGHT], [Vector2(11.4, 6), Vector2.UP]]:
		player.global_position = room.global_position + Vector2(lane[0].x * Room.TILE + 8, lane[0].y * Room.TILE + 6.5)
		player.velocity = Vector2.ZERO
		player.facing = lane[1]
		await _wait(0.1)
		player.global_position = room.global_position + Vector2(lane[0].x * Room.TILE + 8, lane[0].y * Room.TILE + 6.5)
		player.use_item("frostfang_bow")
		await _wait(0.5)
	await _wait(0.5)
	_check(vault_eyes.all(func(e: IceEye) -> bool: return e.lit) and vault_bars.is_open, "three arrows from the middle wake every eye, and the bars open")
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Rime Vault's chest holds the big key")

	# The Frost Ford: each pond is small enough to freeze whole.
	room = await _goto(game, Vector2i(33, 10), Vector2i(1, 6))
	await _calm(room)
	await _shoot(room, player, Vector2i(3, 5), Vector2.RIGHT)
	_check(room.is_frozen(Vector2i(4, 5)) and room.is_frozen(Vector2i(5, 6)) and not room.is_frozen(Vector2i(7, 5)), "one arrow freezes the first pond whole, and only it")
	for x in [6, 9, 12, 15]:
		await _shoot(room, player, Vector2i(x, 5), Vector2.RIGHT)
	_check(room.is_frozen(Vector2i(17, 6)), "pond by pond, the ford freezes over")
	player.global_position = _tile_pos(room, Vector2i(3, 6))
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await _wait(4.0)
	Input.action_release("move_right")
	local = player.global_position - room.global_position
	_check(local.x > 18 * Room.TILE, "Wren crosses the frozen ford (at %s)" % local)
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "glint"), "glints wait across the ford")

	# Rimeback.
	GameState.refill()
	room = await _goto(game, Vector2i(32, 7), Vector2i(11, 11))
	var bosses := _child_of(room, Rimeback)
	_check(bosses.size() == 1, "Rimeback waits in the Breathing Hall")
	if bosses.size() == 1:
		var walrus: Rimeback = bosses[0]
		player._invuln = 60.0
		await _wait(0.3)
		_check(walrus.holes.size() == 4, "the hall has four breath holes")
		await _wait(3.0)
		var seen_up := false
		for i in 40:
			if walrus.mode in [Rimeback.Mode.UP, Rimeback.Mode.SPIT]:
				seen_up = true
				break
			await _wait(0.1)
		_check(seen_up, "it surfaces in a breath hole")
		_check(walrus.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "surfaced, its eyes shut, blows glance off")
		# Freeze every hole: it has to break through.
		for i in walrus.holes.size():
			room.freeze(walrus.holes[i]["tiles"][0])
		walrus.mode = Rimeback.Mode.UNDER
		walrus._timer = 0.0
		await _wait(0.1)
		_check(walrus.mode == Rimeback.Mode.BREACH, "with every hole frozen, it breaks up through the ice")
		await _wait(Rimeback.BREACH_TELL + 0.2)
		_check(walrus.mode == Rimeback.Mode.DAZED, "and comes up dazed")
		walrus.arrow_hit(Vector2.UP)
		_check(walrus.hp == 5, "a frost arrow to its open eyes hurts it")
		walrus._stun = 0.0
		walrus.arrow_hit(Vector2.UP)
		await _wait(0.4)
		var thawed := true
		for i in walrus.holes.size():
			thawed = thawed and not walrus.is_hole_frozen(i)
		_check(walrus.mode in [Rimeback.Mode.DIVE, Rimeback.Mode.UNDER] and thawed, "after two hits it thrashes the holes open and dives")
		walrus.mode = Rimeback.Mode.DAZED
		walrus._timer = 10.0
		while walrus.hp > 0:
			walrus._stun = 0.0
			walrus._hits_this_daze = 0
			walrus.take_hit(1, Vector2.UP)
		_check(GameState.flags.get(Rimeback.DEFEATED_FLAG, false), "enough hits bring Rimeback down")
		await _wait(3.0)
		var bell: Tidebell = null
		for child in room.get_children():
			if child is Tidebell:
				bell = child
		_check(bell != null and bell.bell == "glacier", "the Frost Bell rises in the Breathing Hall")
		if bell:
			await _scene_over(game)
			bell.interact()
			_check(GameState.has_flag(Tidebell.flag_for("glacier")), "ringing the Frost Bell counts as a Tidebell")
			await _play_scene(game, 10.0)
	game.queue_free()
	await _wait(0.1)


## The Drowned Belfry: swimming and diving with the Diver's Helm, grates,
## the valve's water level, and Knell.
func _test_belfry_dungeon() -> void:
	_check(ResourceLoader.exists("res://rooms/room_36_10.tscn"), "the Drowned Belfry has an entry room")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(36, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	_check(GameState.dungeon == "belfry" and game.current_room.biome == "belfry", "Wren starts inside the Drowned Belfry")

	# The Bell Court: without the helm, deep water stops Wren.
	var room := await _goto(game, Vector2i(36, 9), Vector2i(11, 11))
	await _calm(room)
	_check(room.flooded() and room.tile_at(10, 5) == "Q", "the Court's middle floor is under deep water")
	player.global_position = _tile_pos(room, Vector2i(10, 10))
	Input.action_press("move_up")
	await _wait(0.8)
	Input.action_release("move_up")
	var local := player.global_position - room.global_position
	_check(local.y > 9 * Room.TILE, "without the helm, deep water stops Wren (at %s)" % local)
	_check(not player.use_item("divers_helm"), "no helm before it's found")

	# With it, Wren swims (slowly) and can dive.
	GameState.give_item("divers_helm")
	_check(GameState.item_slots.has("divers_helm"), "the helm goes in an item slot")
	Input.action_press("move_up")
	await _wait(1.2)
	Input.action_release("move_up")
	local = player.global_position - room.global_position
	_check(local.y < 8 * Room.TILE and player.swimming(), "with the helm, Wren swims out into it (at %s)" % local)
	player.velocity = Vector2.ZERO
	_check(player.use_item("divers_helm") and player.diving, "the helm takes Wren under the surface")
	await _wait(DiversHelm.DIVE_TIME + 0.3)
	_check(not player.diving and player.state == Player.State.MOVE, "they come up when their breath runs out")

	# The Cistern: a ring of grates; swimming stops at them, diving goes under.
	room = await _goto(game, Vector2i(37, 9), Vector2i(1, 6))
	await _calm(room)
	_check(_child_of(room, SunkenGrate).size() == 16, "the Cistern's island is ringed with grates")
	# The grates stop a glide too: no floating over them onto the island.
	GameState.give_item("kite_cloak")
	player.global_position = _tile_pos(room, Vector2i(15, 1))
	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(1.6)
	var glide_at := player.global_position - room.global_position
	_check(glide_at.y < 4 * Room.TILE, "a glide stops at the grates round the island (at %s)" % glide_at)
	await _wait(0.5)
	player.global_position = _tile_pos(room, Vector2i(11, 5))
	player.facing = Vector2.RIGHT
	Input.action_press("move_right")
	await _wait(1.0)
	Input.action_release("move_right")
	local = player.global_position - room.global_position
	_check(local.x < 13 * Room.TILE, "swimming, a grate stops Wren (at %s)" % local)
	player.use_item("divers_helm")
	Input.action_press("move_right")
	await _wait(1.2)
	Input.action_release("move_right")
	await _wait(DiversHelm.DIVE_TIME)
	local = player.global_position - room.global_position
	_check(local.x > 14 * Room.TILE and not player.diving, "diving, Wren goes under it and comes up on the island (at %s)" % local)
	player.facing = Vector2.LEFT
	player.global_position = _tile_pos(room, Vector2i(14, 5))
	await _wait(0.1)
	_check(player.use_item("divers_helm"), "from the island, Wren can dive back in off the edge")
	await _wait(DiversHelm.DIVE_TIME + 0.4)

	# The Valve Chamber: the valve lets the water down through the Belfry.
	room = await _goto(game, Vector2i(36, 8), Vector2i(11, 11))
	await _calm(room)
	var valves := _child_of(room, Valve)
	_check(valves.size() == 1, "the Valve Chamber has its valve")
	(valves[0] as Valve).interact()
	await _wait(Valve.TURN_TIME + 0.3)
	_check(GameState.has_flag(Room.low_water_flag("belfry")) and not room.flooded(), "turning it lets the water down")

	# The Sunken Choir, drained: the crate crosses the floor to the plate.
	room = await _goto(game, Vector2i(35, 8), Vector2i(22, 6))
	await _calm(room)
	_check(room.tile_at(10, 5) == "K" or room.tile_at(12, 5) == ".", "the Choir's floor is dry silt")
	var crate: Crate = _child_of(room, Crate)[0]
	for i in 5:
		crate._slide(Vector2.RIGHT)
		await _wait(0.3)
	crate._slide(Vector2.DOWN)
	await _wait(0.3)
	crate._slide(Vector2.DOWN)
	await _wait(0.4)
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "on the dry floor the crate reaches the plate (at %s)" % crate.position)

	# The Tolling Well (water down): the crate goes round the pillar onto
	# the plate, the bars open on the pool, and a dive under the grates
	# reaches the big key. Its own valve turns the water too.
	room = await _goto(game, Vector2i(38, 8), Vector2i(1, 6))
	await _calm(room)
	var well_crate: Crate = _child_of(room, Crate)[0]
	var well_bars: Array = _child_of(room, Bars)
	_check(well_bars.size() == 2 and not (well_bars[0] as Bars).is_open, "bars shut the Well's pool off")
	for step: Vector2 in [Vector2.RIGHT, Vector2.RIGHT, Vector2.RIGHT, Vector2.RIGHT, Vector2.DOWN, Vector2.DOWN, Vector2.DOWN, Vector2.DOWN, Vector2.DOWN, Vector2.DOWN, Vector2.RIGHT]:
		well_crate._slide(step)
		await _wait(0.3)
	await _wait(0.2)
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false) and (well_bars[0] as Bars).is_open, "round the pillar onto the plate, the crate opens the bars (at %s)" % well_crate.position)
	player.global_position = _tile_pos(room, Vector2i(16, 4))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	_check(player.swimming() and player.use_item("divers_helm"), "Wren dives in the Well's pool")
	Input.action_press("move_right")
	await _wait(1.0)
	Input.action_release("move_right")
	await _wait(DiversHelm.DIVE_TIME)
	local = player.global_position - room.global_position
	_check(local.x > 17.5 * Room.TILE and not player.diving, "under the grates Wren comes up beside the big key (at %s)" % local)
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Tolling Well's chest holds the big key")
	var well_valves := _child_of(room, Valve)
	_check(well_valves.size() == 1, "the Well has a valve of its own")
	(well_valves[0] as Valve).interact()
	await _wait(Valve.TURN_TIME + 0.3)
	_check(room.flooded() and room.tile_at(8, 5) == "Q", "the Well's valve turns the water up")
	(well_valves[0] as Valve).interact()
	await _wait(Valve.TURN_TIME + 0.3)
	_check(not room.flooded(), "and back down")

	# The Drowned Nave: a passage roofed with grates winds up to a sealed
	# chamber; once under, Wren can't surface until they're through.
	room = await _goto(game, Vector2i(35, 10), Vector2i(22, 6))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(9, 10))
	player.facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	Input.action_press("move_left")
	await _wait(0.8)
	Input.action_release("move_left")
	local = player.global_position - room.global_position
	_check(local.x > 7.5 * Room.TILE, "swimming, the grates stop Wren at the passage (at %s)" % local)
	player.use_item("divers_helm")
	Input.action_press("move_left")
	Input.action_press("move_up")
	await _wait(8.0)
	Input.action_release("move_left")
	Input.action_release("move_up")
	await _wait(0.5)
	local = player.global_position - room.global_position
	_check(local.x < 5 * Room.TILE and local.y < 4 * Room.TILE and not player.diving, "diving, Wren winds up the passage into the sealed chamber (at %s)" % local)
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "glint"), "glints wait in the Nave's chamber")

	# Back up again, the Choir floods and its crate is stuck.
	room = await _goto(game, Vector2i(36, 8), Vector2i(11, 11))
	(_child_of(room, Valve)[0] as Valve).interact()
	await _wait(Valve.TURN_TIME + 0.3)
	_check(room.flooded(), "the valve turns the water back up")

	# Knell.
	GameState.give_item("stonebreaker")
	GameState.refill()
	room = await _goto(game, Vector2i(36, 7), Vector2i(11, 11))
	var bosses := _child_of(room, Knell)
	_check(bosses.size() == 1, "Knell waits in its bell")
	if bosses.size() == 1:
		var knell: Knell = bosses[0]
		player._invuln = 60.0
		await _wait(1.6)
		_check(knell.bell != null and knell.arms.size() == 3, "three tentacles rise round the great bell")
		for arm in knell.arms:
			_check(room.tile_at(floori(arm.position.x / Room.TILE), floori((arm.position.y - 4.0) / Room.TILE)) == "Q", "each tentacle rises from deep water")
		_check(knell.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "the sword can't reach it in its bell")
		knell.bell.mallet_hit(Vector2.UP)
		_check(knell.mode == Knell.Mode.ARMS, "ringing the bell while its arms are up does nothing")
		# Dive and cut the first arm the way Wren would.
		var arm: Tentacle = knell.arms[2]
		player.global_position = arm.global_position + Vector2(0, 14)
		player.facing = Vector2.UP
		await _wait(0.1)
		player.use_item("divers_helm")
		await _wait(0.1)
		Input.action_press("attack")
		await _wait(0.05)
		Input.action_release("attack")
		await _wait(0.4)
		_check(arm.severed, "diving under, a slash cuts a tentacle off at the root")
		for a: Tentacle in knell.arms:
			a.dive_hit(Vector2.UP)
		await _wait(0.1)
		_check(knell.mode == Knell.Mode.HIDDEN, "with all three cut it hides in the bell")
		knell.bell.mallet_hit(Vector2.UP)
		_check(knell.mode == Knell.Mode.DAZED, "the Stonebreaker rings the bell and shakes it out, dazed")
		_check(knell.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT and knell.hp == 5, "dazed, the sword finds it")
		knell._stun = 0.0
		knell.take_hit(1, Vector2.UP)
		await _wait(Knell.RETREAT_TIME + 0.4)
		_check(knell.mode == Knell.Mode.ARMS and knell.arms.size() == 3 and not knell.arms[0].severed, "after two hits it drags itself back and grows new arms")
		knell.mode = Knell.Mode.DAZED
		knell._timer = 10.0
		# Stand where the last blow lands, on the island by the bell.
		player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 7 * Room.TILE + 8)
		Cutscene.fast = true
		while knell.hp > 0:
			knell._stun = 0.0
			knell._hits_this_daze = 0
			knell.take_hit(1, Vector2.UP)
		_check(GameState.flags.get(Knell.DEFEATED_FLAG, false), "enough hits bring Knell down")
		# Cutscene 14: Lowe comes up in the water, and Wren hauls her out.
		_check(Cutscene.active and GameState.has_flag(StoryDirector.LOWE_WATER_FLAG), "Knell's end brings Lowe up in the water")
		var lowe: ChoirFigure = null
		var in_water := false
		var hauled := false
		var waited := 0.0
		while Cutscene.active and waited < 25.0:
			await _wait(0.05)
			waited += 0.05
			for child in room.get_children():
				if child is ChoirFigure:
					lowe = child
			if lowe and is_instance_valid(lowe):
				var tile := Vector2i(floori(lowe.position.x / Room.TILE), floori(lowe.position.y / Room.TILE))
				if lowe.sunk > 10.0 and room.tile_at(tile.x, tile.y) == "Q":
					in_water = true
				if in_water and lowe.sunk == 0.0 and room.tile_at(tile.x, tile.y) == ".":
					hauled = true
		_check(in_water, "she surfaces in deep water, half under")
		_check(hauled, "and is pulled out onto the stone")
		_check(not Cutscene.active and (lowe == null or not is_instance_valid(lowe)), "then she's gone, out the door (%.1fs)" % waited)
		_check(game.player.global_position.distance_to(room.global_position + StoryDirector.WREN_REACHES) < 6.0, "Wren went to the edge to reach her")
		Cutscene.fast = false
		await _wait(3.0)
		var bell: Tidebell = null
		for child in room.get_children():
			if child is Tidebell:
				bell = child
		_check(bell != null and bell.bell == "belfry", "the Drowned Bell rises in the hall")
		if bell:
			await _scene_over(game)
			bell.interact()
			_check(GameState.has_flag(Tidebell.flag_for("belfry")), "ringing the Drowned Bell counts as a Tidebell")
			await _play_scene(game, 10.0)
	game.queue_free()
	await _wait(0.1)


## The Marrow Tomb: the Echo Horn, bone walls (seen and hidden), singing
## skulls, Marrowguards and the Hush, and the Hollow Regent.
func _test_tomb_dungeon() -> void:
	_check(ResourceLoader.exists("res://rooms/room_40_10.tscn"), "the Marrow Tomb has an entry room")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(40, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	player._invuln = 600.0
	_check(GameState.dungeon == "tomb" and game.current_room.biome == "tomb", "Wren starts inside the Marrow Tomb")

	# The Hall of Ribs: a barricade of bones blocks the way north.
	var room := await _goto(game, Vector2i(40, 9), Vector2i(11, 11))
	await _calm(room)
	var walls := _child_of(room, BoneWall)
	_check(walls.size() == 2, "a bone barricade blocks the Hall's north way")
	player.global_position = _tile_pos(room, Vector2i(11, 2))
	Input.action_press("move_up")
	await _wait(0.8)
	Input.action_release("move_up")
	var local := player.global_position - room.global_position
	_check(game.current_room == room and local.y > Room.TILE, "the barricade stops Wren (at %s)" % local)
	_check(not player.use_item("echo_horn"), "no horn before it's found")

	# The Horn Crypt: its Marrowguards turn the sword with their shields.
	room = await _goto(game, Vector2i(39, 9), Vector2i(22, 6))
	player.global_position = _tile_pos(room, Vector2i(11, 6))
	await _wait(0.2)
	var guards := _child_of(room, Marrowguard)
	_check(guards.size() == 3, "Marrowguards stand in the Horn Crypt")
	var guard: Marrowguard = guards[0]
	guard.ai_enabled = false
	guard.facing = Vector2.RIGHT
	_check(guard.take_hit(1, Vector2.LEFT) == Enemy.HitResult.BLOCKED, "from the front, the shield turns the sword")
	guard._stun = 0.0
	_check(guard.take_hit(1, Vector2.RIGHT) == Enemy.HitResult.HIT, "from behind, the sword finds it")
	for g: Marrowguard in guards:
		g.shield = false
		g._stun = 0.0
		while not g.dying:
			g._stun = 0.0
			g.take_hit(1, Vector2.UP)
	await _wait(0.6)
	var chest: Chest = _child_of(room, Chest)[0]
	_check(chest.visible, "with the Marrowguards beaten the Echo Horn's chest appears")
	chest.interact()
	for i in 30:
		await _wait(0.2)
		for child in game.get_children():
			if child is DialogueBox and DialogueBox.is_open:
				child.advance()
		if not game.busy and not DialogueBox.is_open and i > 10:
			break
	_check(GameState.has_item("echo_horn"), "Wren has the Echo Horn")

	# The horn shatters a Marrowguard's shield (one fresh from the Entry).
	room = await _goto(game, Vector2i(40, 10), Vector2i(11, 1))
	guards = _child_of(room, Marrowguard)
	_check(guards.size() == 1, "a Marrowguard keeps the Entry")
	if guards.size() == 1:
		guard = guards[0]
		guard.ai_enabled = false
		player.global_position = guard.global_position + Vector2(0, 30)
		player.facing = Vector2.UP
		await _wait(0.1)
		_check(player.use_item("echo_horn"), "Wren blows the Echo Horn")
		await _wait(0.6)
		_check(not guard.shield, "the horn's note shatters its bone shield")

	# Back in the Hall, the horn brings the barricade down.
	room = await _goto(game, Vector2i(40, 9), Vector2i(11, 11))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(11, 3))
	player.facing = Vector2.UP
	await _wait(0.6)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(_child_of(room, BoneWall).is_empty(), "the horn brings the barricade down")

	# The Echo Chamber: all three skulls singing at once.
	room = await _goto(game, Vector2i(40, 8), Vector2i(11, 11))
	await _calm(room)
	var skulls := _child_of(room, SingingSkull)
	_check(skulls.size() == 3, "three skulls sit in the Echo Chamber")
	chest = _child_of(room, Chest)[0]
	_check(not chest.visible, "its chest is hidden")
	for spot in [Vector2i(11, 8), Vector2i(7, 4), Vector2i(16, 4)]:
		player.global_position = _tile_pos(room, spot)
		player.velocity = Vector2.ZERO
		await _wait(0.15)
		player.use_item("echo_horn")
		await _wait(0.75)
	_check(chest.visible, "with every skull singing at once, the chest appears")
	# Its west wall is hidden bone: it looks like wall, and stops Wren.
	_check(room.tile_at(0, 6) == "#", "the Chamber's west wall looks like any wall")
	player.global_position = _tile_pos(room, Vector2i(2, 6))
	player.velocity = Vector2.ZERO
	player.facing = Vector2.LEFT
	await _wait(0.6)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(room.tile_at(0, 6) == "." and _child_of(room, BoneWall).is_empty(), "the horn finds the hidden wall and brings it down")
	Input.action_press("move_left")
	await _wait(1.4)
	Input.action_release("move_left")
	_check(game.current_room.coord == Vector2i(39, 8), "behind it lies the Forgotten Ossuary")

	# The Hush: unseen, the sword passes through it; an echo shows it.
	room = game.current_room
	var hushes := _child_of(room, Hush)
	_check(hushes.size() == 2, "the Hush haunts the Forgotten Ossuary")
	if hushes.size() == 2:
		var hush: Hush = hushes[0]
		hush.ai_enabled = false
		_check(hush.take_hit(1, Vector2.UP) == Enemy.HitResult.IGNORED, "unseen, the sword passes through the Hush")
		player.global_position = hush.global_position + Vector2(20, 0)
		player.velocity = Vector2.ZERO
		await _wait(0.2)
		player.use_item("echo_horn")
		await _wait(0.6)
		_check(hush.shown > 0.0, "the horn's echo shows the Hush")
		_check(hush.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT, "shown, the sword finds it")

	# The Skull Choir: two skulls in each bay, too far apart to wake
	# together. The horn brings the barricades on the short way down; then
	# a blast in each bay, walked between inside the song, opens the chest.
	room = await _goto(game, Vector2i(41, 8), Vector2i(18, 11))
	await _calm(room)
	var choir_skulls := _child_of(room, SingingSkull)
	_check(choir_skulls.size() == 4, "four skulls sit in the Skull Choir")
	var choir_bars: Array = _child_of(room, Bars)
	_check(_child_of(room, BoneWall).size() == 2 and choir_bars.size() == 3 and not (choir_bars[0] as Bars).is_open, "bone barricades shut the short way between the bays, and bars the way east")
	for spot in [Vector2i(4, 4), Vector2i(19, 4)]:
		player.global_position = _tile_pos(room, spot)
		player.velocity = Vector2.ZERO
		await _wait(0.15)
		player.use_item("echo_horn")
		await _wait(SingingSkull.SING_TIME + 0.5)
	_check(_child_of(room, BoneWall).is_empty(), "a blast in each bay brings its barricade down")
	_check(not (choir_bars[0] as Bars).is_open, "one bay at a time, the skulls' song never meets")
	player.global_position = _tile_pos(room, Vector2i(4, 4))
	player.velocity = Vector2.ZERO
	await _wait(0.15)
	player.use_item("echo_horn")
	await _wait(0.45)
	Input.action_press("move_right")
	await _wait(2.6)
	Input.action_release("move_right")
	local = player.global_position - room.global_position
	_check(local.x > 18 * Room.TILE, "Wren runs the short way across (at %s)" % local)
	player.velocity = Vector2.ZERO
	player.use_item("echo_horn")
	await _wait(0.8)
	_check((choir_bars[0] as Bars).is_open, "both bays singing at once, the bars east open")

	# The Lightless Stair: dark; by lantern light Wren walks the planks over
	# the drop, and the horn brings down the bone before the way south.
	GameState.give_item("glowmoth_lantern")
	room = await _goto(game, Vector2i(42, 8), Vector2i(1, 10))
	await _calm(room)
	_check(room.dark and _child_of(room, VeilPlank).size() == 16, "the Lightless Stair is dark, its planks hidden")
	player.global_position = _tile_pos(room, Vector2i(3, 10))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	var stair_bubbles := GameState.bubbles
	Input.action_press("move_right")
	await _wait(1.0)
	Input.action_release("move_right")
	await _wait(1.2)
	local = player.global_position - room.global_position
	_check(GameState.bubbles == stair_bubbles and local.x < 5 * Room.TILE, "in the dark there are no planks to walk on (at %s)" % local)
	GameState.refill()
	player.global_position = _tile_pos(room, Vector2i(3, 10))
	player.velocity = Vector2.ZERO
	player.use_item("glowmoth_lantern")
	for leg: Array in [["move_right", 5], ["move_up", 6], ["move_right", 7]]:
		var target: Vector2i = Vector2i(8, 10) if leg[0] == "move_right" and leg[1] == 5 else (Vector2i(8, 4) if leg[0] == "move_up" else Vector2i(15, 4))
		Input.action_press(leg[0])
		var waited := 0.0
		while waited < 4.0:
			var here := player.global_position - room.global_position
			if (leg[0] == "move_right" and here.x >= target.x * Room.TILE + 8) or (leg[0] == "move_up" and here.y <= target.y * Room.TILE + 12):
				break
			await get_tree().physics_frame
			waited += 1.0 / 60.0
		Input.action_release(leg[0])
		player.velocity = Vector2.ZERO
		player.global_position = _tile_pos(room, target)
		await _wait(0.1)
	local = player.global_position - room.global_position
	_check(int(local.x) / Room.TILE == 15 and GameState.bubbles == GameState.max_bubbles, "by lantern light Wren walks the planks to the far landing (at %s)" % local)
	player.use_item("glowmoth_lantern")
	player.global_position = _tile_pos(room, Vector2i(18, 7))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("echo_horn")
	await _wait(0.6)
	_check(_child_of(room, BoneWall).is_empty(), "the horn brings the bone down before the way south")

	# The Marrow Vault: the horn opens the crate's nook and the hidden way to
	# the second plate; the hook drags the other crate out of its pocket.
	GameState.give_item("tide_hook")
	room = await _goto(game, Vector2i(42, 9), Vector2i(18, 1))
	await _calm(room)
	var vault_crates: Array = _child_of(room, Crate)
	vault_crates.sort_custom(func(a: Crate, b: Crate) -> bool: return a.position.y < b.position.y)
	var vault_bars: Array = _child_of(room, Bars)
	_check(vault_crates.size() == 2 and vault_bars.size() == 4 and not (vault_bars[0] as Bars).is_open, "two crates, two plates, and bars on the key and the way west")
	_check(_child_of(room, BoneWall).size() == 4, "bone shuts the crate's nook and hides the second plate")
	player.global_position = _tile_pos(room, Vector2i(9, 2))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("echo_horn")
	await _wait(0.6)
	player.global_position = _tile_pos(room, Vector2i(16, 10))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("echo_horn")
	await _wait(0.6)
	_check(_child_of(room, BoneWall).is_empty(), "the horn brings both down")
	var nook: Crate = vault_crates[0]
	for i in 7:
		nook._slide(Vector2.RIGHT)
		await _wait(0.4)
	_check(floori(nook.position.x / Room.TILE) == 11, "out of its nook, the crate goes onto the first plate (col %d)" % floori(nook.position.x / Room.TILE))
	_check(not (vault_bars[0] as Bars).is_open, "one plate alone leaves the bars shut")
	var pocket: Crate = vault_crates[1]
	player.global_position = _tile_pos(room, Vector2i(15, 10))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	_check(floori(pocket.position.x / Room.TILE) == 16, "the hook drags the other crate out of its pocket (col %d)" % floori(pocket.position.x / Room.TILE))
	player.global_position = _tile_pos(room, Vector2i(18, 8))
	player.velocity = Vector2.ZERO
	await _wait(0.2)
	for i in 4:
		pocket._slide(Vector2.LEFT)
		await _wait(0.4)
	await _wait(0.2)
	_check(floori(pocket.position.x / Room.TILE) == 12 and (vault_bars[0] as Bars).is_open, "through the broken wall onto the second plate, and the bars open (col %d)" % floori(pocket.position.x / Room.TILE))
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Marrow Vault's chest holds the big key")
	# Through the open bars Wren walks up to the chest.
	player.global_position = _tile_pos(room, Vector2i(9, 6))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	Input.action_press("move_right")
	await _wait(0.6)
	Input.action_release("move_right")
	player.velocity = Vector2.ZERO
	local = player.global_position - room.global_position
	_check(floori(local.x / Room.TILE) == 11, "through the open bars Wren reaches the chest (at %s)" % local)
	player.facing = Vector2.RIGHT
	for vault_chest: Chest in _child_of(room, Chest):
		vault_chest.interact()
	await _wait(0.3)
	await _close_dialogue(game)
	_check(GameState.has_item(Items.dungeon_item("tomb", "big_key")), "Wren takes the big key")
	player.global_position = _tile_pos(room, Vector2i(3, 6))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	Input.action_press("move_left")
	await _wait(1.0)
	Input.action_release("move_left")
	await _wait(0.6)
	_check(game.current_room.coord == Vector2i(41, 9), "the bars west lead back into the Bone Pit (in %s)" % game.current_room.coord)

	# The Bone Orchard: one hidden wall behind another.
	room = await _goto(game, Vector2i(39, 10), Vector2i(22, 6))
	await _calm(room)
	_check(_child_of(room, BoneWall).size() == 2, "two hidden bone walls in the Bone Orchard")
	player.global_position = _tile_pos(room, Vector2i(7, 8))
	player.velocity = Vector2.ZERO
	await _wait(0.15)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(_child_of(room, BoneWall).size() == 1 and room.tile_at(5, 8) == ".", "a blast nearby finds the first")
	player.global_position = _tile_pos(room, Vector2i(2, 6))
	player.velocity = Vector2.ZERO
	await _wait(0.15)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(_child_of(room, BoneWall).is_empty(), "and from behind it, the second")
	Input.action_press("move_up")
	await _wait(1.2)
	Input.action_release("move_up")
	local = player.global_position - room.global_position
	_check(local.y < 4 * Room.TILE, "Wren steps through into the sealed chamber (at %s)" % local)
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "glint"), "glints wait in the Orchard's chamber")

	# The Hollow Regent. (The last mural has its own test in _test_story.)
	GameState.refill()
	GameState.set_flag(StoryDirector.MURAL_FLAG)
	room = await _goto(game, Vector2i(40, 7), Vector2i(11, 11))
	var bosses := _child_of(room, HollowRegent)
	_check(bosses.size() == 1, "the Hollow Regent waits in his barrow")
	if bosses.size() == 1:
		var regent: HollowRegent = bosses[0]
		await _wait(1.4)
		_check(regent.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "armoured, the sword glances off him")
		regent.ai_enabled = false
		player.global_position = regent.global_position + Vector2(0, 40)
		player.velocity = Vector2.ZERO
		player.facing = Vector2.UP
		await _wait(0.1)
		player.use_item("echo_horn")
		await _wait(0.7)
		_check(regent.armour_left() == 2, "one note of the horn shatters one piece of his armour")
		for i in 2:
			await _wait(0.2)
			player.use_item("echo_horn")
			await _wait(0.7)
		_check(regent.armour_left() == 0 and regent.mode == HollowRegent.Mode.OPEN, "with all his armour gone, his ribs stand open")
		_check(regent.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT and regent.hp == 5, "open, the sword finds the marrow-light")
		regent._stun = 0.0
		regent.take_hit(1, Vector2.UP)
		regent.ai_enabled = true
		await _wait(HollowRegent.REBUILD_TIME + 0.3)
		_check(regent.armour_left() == 3 and regent.mode != HollowRegent.Mode.OPEN, "after two hits he draws his armour back up from the bones")
		regent.ai_enabled = false
		regent.mode = HollowRegent.Mode.OPEN
		while regent.hp > 0:
			regent._stun = 0.0
			regent._hits_this_open = 0
			regent.take_hit(1, Vector2.UP)
		_check(GameState.flags.get(HollowRegent.DEFEATED_FLAG, false), "enough hits bring the Regent down")
		await _wait(3.2)
		var bell: Tidebell = null
		for child in room.get_children():
			if child is Tidebell:
				bell = child
		_check(bell != null and bell.bell == "tomb", "the Marrow Bell rises in the barrow")
		if bell:
			await _scene_over(game)
			bell.interact()
			_check(GameState.has_flag(Tidebell.flag_for("tomb")), "ringing the Marrow Bell counts as a Tidebell")
			await _play_scene(game, 10.0)
	game.queue_free()
	await _wait(0.1)


## Closes whatever dialogue is open (paging through to the end).
func _close_dialogue(game: Node) -> void:
	for child in game.get_children():
		if child is DialogueBox:
			var guard := 0
			while DialogueBox.is_open and guard < 40:
				child.advance()
				child.advance()
				guard += 1
				await _wait(0.05)


## The Maw: the Old One's breathing floor, every tool, Cantor Vael and the
## Dreaming Heart.
func _test_maw_dungeon() -> void:
	_check(ResourceLoader.exists("res://rooms/room_44_10.tscn"), "the Maw has an entry room")
	GameState.reset_new_game()
	# The choir's scene has its own test (_test_choir).
	GameState.set_flag(StoryDirector.CHOIR_FLAG)
	GameState.set_checkpoint(Vector2i(44, 10), GameState.NO_POSITION)
	DreamingHeart.roll_credits = false
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	player._invuln = 600.0
	var room: Room = game.current_room
	_check(GameState.dungeon == "maw" and room.biome == "maw", "Wren starts inside the Maw")

	# The Throat: its palate floor floods as the Old One breathes in.
	_check(room.has_node("Breath"), "the Old One's breath reaches the Throat")
	MawBreath.elapsed = 0.0
	await _wait(0.1)
	_check(room.tile_at(5, 5) == "." and not room.flooded(), "breathing out, the palate floor is dry")
	MawBreath.elapsed = MawBreath.OUT_TIME + MawBreath.IN_TELL_TIME + 0.5
	await _wait(0.1)
	_check(room.tile_at(5, 5) == "Q" and room.flooded(), "breathing in, it floods")
	MawBreath.elapsed = 0.0
	await _wait(0.1)

	# The Palate: the map, and a hatch north.
	room = await _goto(game, Vector2i(44, 9), Vector2i(11, 11))
	await _calm(room)
	_check(_child_of(room, Chest).size() == 1, "the Palate keeps the map")
	# The Hollows: hook posts on both sides of the gap.
	room = await _goto(game, Vector2i(43, 9), Vector2i(22, 6))
	_check(room.has_node("PitField") and room.tile_at(8, 6) == "_", "the Hollows are split by a gap")
	_check(room.tile_at(4, 5) == "O" and room.tile_at(11, 7) == "O", "a hook post stands either side")
	await _calm(room)
	GameState.give_item("tide_hook")
	player.global_position = _tile_pos(room, Vector2i(10, 5))
	player.facing = Vector2.LEFT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	var local := player.global_position - room.global_position
	_check(int(local.x) / Room.TILE == 5 and player.state == Player.State.MOVE, "the hook carries Wren west over the gap (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(5, 7))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(int(local.x) / Room.TILE == 10 and player.state == Player.State.MOVE, "and back east (at %s)" % local)
	# The Dim Gallery: four braziers, a hidden chest, veiled planks.
	room = await _goto(game, Vector2i(45, 9), Vector2i(1, 6))
	await _calm(room)
	var braziers := _child_of(room, Brazier)
	var chest: Chest = _child_of(room, Chest)[0]
	_check(braziers.size() == 4 and not chest.visible, "the Dim Gallery's chest waits on four braziers")
	_check(room.tile_at(17, 1) == "|" and room.tile_at(18, 1) == "|" and room.tile_at(17, 0) == "." and room.tile_at(18, 0) == ".", "bars stand in the Gallery's way north")
	for b: Brazier in braziers:
		b.light()
	await _wait(0.2)
	_check(chest.visible, "with every brazier lit, the chest appears")
	_check(_child_of(room, Bars).all(func(b: Bars) -> bool: return b.is_open), "and the bars north onto the Lung open")

	# The Lung: the crate crosses the palate floor only while it's dry; the
	# plate opens the pool, and a dive under the grates reaches the big key.
	GameState.give_item("divers_helm")
	MawBreath.elapsed = 0.0
	room = await _goto(game, Vector2i(45, 8), Vector2i(17, 11))
	await _calm(room)
	var lung_crate: Crate = _child_of(room, Crate)[0]
	var lung_bars: Array = _child_of(room, Bars)
	_check(lung_bars.size() == 2 and not (lung_bars[0] as Bars).is_open, "bars shut the Lung's pool off")
	MawBreath.elapsed = MawBreath.OUT_TIME + MawBreath.IN_TELL_TIME + 0.5
	await _wait(0.1)
	var crate_at := lung_crate.position
	for i in 3:
		lung_crate._slide(Vector2.RIGHT)
		await _wait(0.4)
	_check(lung_crate.position.x < crate_at.x + 2 * Room.TILE + 1.0, "the risen water stops the crate at the palate's edge (moved %s)" % (lung_crate.position - crate_at))
	MawBreath.elapsed = 0.0
	await _wait(0.1)
	for step: Vector2 in [Vector2.DOWN, Vector2.DOWN, Vector2.DOWN, Vector2.DOWN]:
		lung_crate._slide(step)
		await _wait(0.3)
	while lung_crate.position.x < 14 * Room.TILE:
		var before := lung_crate.position
		lung_crate._slide(Vector2.RIGHT)
		await _wait(0.3)
		if lung_crate.position == before:
			break
	await _wait(0.2)
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false) and (lung_bars[0] as Bars).is_open, "with the floor dry, the crate crosses onto the plate (at %s)" % lung_crate.position)
	MawBreath.elapsed = MawBreath.OUT_TIME + MawBreath.IN_TELL_TIME + 0.2
	player.global_position = _tile_pos(room, Vector2i(16, 4))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	_check(room.flooded() and player.swimming() and player.use_item("divers_helm"), "in the risen pool, Wren dives")
	Input.action_press("move_right")
	await _wait(1.0)
	Input.action_release("move_right")
	await _wait(DiversHelm.DIVE_TIME)
	local = player.global_position - room.global_position
	_check(local.x > 17.5 * Room.TILE and not player.diving, "under the grates Wren comes up beside the big key (at %s)" % local)
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "small_key"), "the Lung's chest holds the second small key")
	MawBreath.elapsed = 0.0
	await _wait(0.1)

	# The Gullet: the boulder breaks to the Stonebreaker, the hook crosses
	# from the palate floor to the ledge, and the drop swallows Wren back
	# down to the Throat.
	GameState.give_item("stonebreaker")
	room = await _goto(game, Vector2i(43, 10), Vector2i(21, 10))
	await _calm(room)
	_check(_child_of(room, Boulder).size() == 1 and room.tile_at(2, 2) == "O", "a boulder bars the Gullet's palate, and a post stands on the ledge")
	(_child_of(room, Boulder)[0] as Boulder).mallet_hit(Vector2.LEFT)
	await _wait(0.6)
	_check(_child_of(room, Boulder).is_empty(), "the Stonebreaker breaks the boulder")
	player.global_position = _tile_pos(room, Vector2i(2, 9))
	player.facing = Vector2.UP
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(int(local.y) / Room.TILE == 3 and int(local.x) / Room.TILE == 2, "the hook carries Wren up onto the ledge (at %s)" % local)
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "glint"), "glints wait on the Gullet's ledge")
	player.facing = Vector2.RIGHT
	Input.action_press("move_right")
	await _wait(1.5)
	Input.action_release("move_right")
	await _wait(1.2)
	_check(game.current_room.coord == Vector2i(44, 10), "stepping off the ledge, the Gullet swallows Wren down to the Throat (in %s)" % game.current_room.coord)
	GameState.refill()

	# The Sinus: an ice eye on the east shore and two skulls in the drop must
	# wake together. Only the island hears both skulls, only the shore sees
	# the eye: Wren shoots, zips to the island and blows the horn.
	GameState.give_item("frostfang_bow")
	GameState.give_item("echo_horn")
	GameState.give_item("kite_cloak")
	room = await _goto(game, Vector2i(43, 8), Vector2i(22, 7))
	await _calm(room)
	var sinus_bars: Array = _child_of(room, Bars)
	_check(_child_of(room, IceEye).size() == 1 and _child_of(room, SingingSkull).size() == 2 and sinus_bars.size() == 3 and not (sinus_bars[0] as Bars).is_open, "an eye, two skulls, and bars on the way north")
	player.global_position = _tile_pos(room, Vector2i(17, 6))
	player.facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(floori(local.x / Room.TILE) == 12 and floori(local.y / Room.TILE) == 6, "the hook carries Wren onto the island (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(10, 6))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(_child_of(room, SingingSkull).all(func(z: SingingSkull) -> bool: return z.lit) and not (sinus_bars[0] as Bars).is_open, "from the island both skulls sing, but the eye sleeps and the bars hold")
	await _wait(SingingSkull.SING_TIME + 0.5)
	# The east shore's post carries Wren back.
	player.global_position = _tile_pos(room, Vector2i(12, 6))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(floori(local.x / Room.TILE) == 17 and floori(local.y / Room.TILE) == 6, "the shore's post carries Wren back off the island (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(19, 6))
	player.facing = Vector2.UP
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("frostfang_bow")
	await _wait(0.5)
	_check((_child_of(room, IceEye)[0] as IceEye).lit, "from the shore an arrow wakes the eye")
	player.global_position = _tile_pos(room, Vector2i(17, 6))
	player.facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	player.global_position = _tile_pos(room, Vector2i(10, 6))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false) and sinus_bars.all(func(b: Bars) -> bool: return b.is_open), "eye and skulls awake together, the bars open")
	player.global_position = _tile_pos(room, Vector2i(8, 6))
	player.facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(floori(local.x / Room.TILE) == 3 and floori(local.y / Room.TILE) == 6, "the west post carries Wren off the island (at %s)" % local)
	Input.action_press("move_up")
	await _wait(2.5)
	Input.action_release("move_up")
	await _wait(0.6)
	_check(game.current_room.coord == Vector2i(43, 7), "through the open bars Wren climbs into the Cochlea (in %s)" % game.current_room.coord)

	# The Cochlea: the cloak crosses the drop; the hook drags each crate out
	# of its nook across the pool, but only while the Old One breathes out;
	# the horn finds the bone wall, and the crates go onto the plates.
	room = await _goto(game, Vector2i(43, 7), Vector2i(2, 11))
	await _calm(room)
	var coch_crates: Array = _child_of(room, Crate)
	coch_crates.sort_custom(func(a: Crate, b: Crate) -> bool: return a.position.x < b.position.x)
	var coch_bars: Array = _child_of(room, Bars)
	_check(coch_crates.size() == 2 and _child_of(room, PressurePlate).size() == 2 and coch_bars.size() == 1 and not (coch_bars[0] as Bars).is_open and _child_of(room, BoneWall).size() == 2, "two crates in their nooks, two plates, a hidden bone wall, bars on the big key")
	player.global_position = _tile_pos(room, Vector2i(7, 8))
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(2.6)
	local = player.global_position - room.global_position
	_check(local.x >= 11 * Room.TILE and GameState.bubbles == GameState.max_bubbles, "the cloak carries Wren over the drop (at %s)" % local)
	MawBreath.elapsed = MawBreath.OUT_TIME + MawBreath.IN_TELL_TIME + 0.2
	player.global_position = _tile_pos(room, Vector2i(12, 7))
	player.facing = Vector2.UP
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	var left_crate: Crate = coch_crates[0]
	var right_crate: Crate = coch_crates[1]
	player.use_item("tide_hook")
	await _wait(1.3)
	_check(floori(left_crate.position.y / Room.TILE) == 1, "while the pool is risen, the hook can't drag the crate (row %d)" % floori(left_crate.position.y / Room.TILE))
	MawBreath.elapsed = 0.0
	await _wait(0.2)
	player.facing = Vector2.UP
	player.use_item("tide_hook")
	await _wait(1.3)
	_check(floori(left_crate.position.y / Room.TILE) == 6, "with the pool drained, the hook drags it across (row %d)" % floori(left_crate.position.y / Room.TILE))
	player.global_position = _tile_pos(room, Vector2i(14, 7))
	player.facing = Vector2.UP
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	_check(floori(right_crate.position.y / Room.TILE) == 6, "and the other (row %d)" % floori(right_crate.position.y / Room.TILE))
	player.global_position = _tile_pos(room, Vector2i(16, 8))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(_child_of(room, BoneWall).is_empty(), "the horn finds the bone wall and brings it down")
	player.global_position = _tile_pos(room, Vector2i(13, 7))
	player.velocity = Vector2.ZERO
	await _wait(0.2)
	for i in 6:
		right_crate._slide(Vector2.RIGHT)
		await _wait(0.4)
	_check(not (coch_bars[0] as Bars).is_open, "one plate alone leaves the bars shut")
	# The other goes down a row from the drained pool, then along it.
	player.global_position = _tile_pos(room, Vector2i(12, 5))
	player.velocity = Vector2.ZERO
	await _wait(0.2)
	left_crate._slide(Vector2.DOWN)
	await _wait(0.4)
	player.global_position = _tile_pos(room, Vector2i(11, 8))
	player.velocity = Vector2.ZERO
	await _wait(0.2)
	for i in 8:
		left_crate._slide(Vector2.RIGHT)
		await _wait(0.4)
	await _wait(0.2)
	_check(floori(right_crate.position.x / Room.TILE) == 19 and floori(left_crate.position.x / Room.TILE) == 19 and floori(left_crate.position.y / Room.TILE) == 7 and (coch_bars[0] as Bars).is_open, "both crates on the plates, the bars open (cols %d, %d)" % [floori(left_crate.position.x / Room.TILE), floori(right_crate.position.x / Room.TILE)])
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Cochlea's chest holds the big key")
	player.global_position = _tile_pos(room, Vector2i(18, 9))
	player.velocity = Vector2.ZERO
	await _wait(0.1)
	Input.action_press("move_right")
	await _wait(0.5)
	Input.action_release("move_right")
	player.velocity = Vector2.ZERO
	local = player.global_position - room.global_position
	_check(floori(local.x / Room.TILE) == 19, "through the open bars Wren reaches the big key (at %s)" % local)
	MawBreath.elapsed = 0.0

	# The Choir Loft: Cantor Vael.
	room = await _goto(game, Vector2i(44, 7), Vector2i(11, 11))
	await _wait(0.3)
	await _close_dialogue(game)
	var vaels := _child_of(room, CantorVael)
	_check(vaels.size() == 1, "Cantor Vael waits in the Choir Loft")
	if vaels.size() == 1:
		var vael: CantorVael = vaels[0]
		player.global_position = _tile_pos(room, Vector2i(11, 8))
		await _wait(0.3)
		_check(vael.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "his song turns the sword")
		vael.ai_enabled = false
		var note := SungNote.new()
		note.singer = vael
		note.velocity = Vector2.DOWN * SungNote.SPEED
		room.add_child(note)
		note.global_position = _tile_pos(room, Vector2i(11, 7))
		await _wait(0.1)
		_check(note.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT and note.returning, "the sword sends a note back")
		var hp := vael.hp
		await _wait(1.2)
		_check(vael.hp == hp - 1, "a note sung back at him breaks his song (hp %d)" % vael.hp)
		var wave := ChantWave.new()
		room.add_child(wave)
		wave.global_position = player.global_position
		await _wait(0.1)
		wave.horn_hit(player.global_position)
		await _wait(0.4)
		_check(not is_instance_valid(wave), "the Echo Horn scatters the chant")
		while vael.hp > 0:
			vael.note_hit(null)
		_check(GameState.has_flag(CantorVael.DEFEATED_FLAG), "his song broken, Vael stops and listens")
		# The last blow holds time and slows it a moment before he speaks.
		await _wait(2.2)
		await _close_dialogue(game)
		await _wait(0.3)
		_check(is_instance_valid(vael), "he doesn't fall: he stays")
		var bars := _child_of(room, Bars)
		_check(not bars.is_empty() and GameState.has_flag(RoomPuzzle.flag_for(room.coord)), "the way to the Heart opens")

	# The Dreaming Heart: seven bells on the beat, then the eighth line.
	room = await _goto(game, Vector2i(44, 6), Vector2i(11, 11))
	var hearts := _child_of(room, DreamingHeart)
	_check(hearts.size() == 1, "the Dreaming Heart storms up")
	if hearts.size() == 1:
		var heart: DreamingHeart = hearts[0]
		await _wait(DreamingHeart.WAKE_TIME + 0.3)
		for i in DreamingHeart.STAGES.size():
			var bells := _child_of(room, HeartBell).filter(func(b: HeartBell) -> bool: return not b.rung)
			_check(bells.size() == 1 and bells[0].bell == DreamingHeart.STAGES[i][0], "stage %d: its bell rises" % i)
			_check(_child_of(room, HeartEcho).filter(func(e: HeartEcho) -> bool: return not e.calmed).size() == 1, "stage %d: an echo rises" % i)
			if bells.size() != 1:
				break
			var bell: HeartBell = bells[0]
			if i == 0:
				while heart.off_beat() < DreamingHeart.BEAT_WINDOW + 0.1:
					await get_tree().physics_frame
				bell.take_hit(1, Vector2.UP)
				_check(not bell.rung, "off the beat, the bell only clanks")
				while heart.off_beat() > 0.05:
					await get_tree().physics_frame
				bell.take_hit(1, Vector2.UP)
				_check(not bell.rung, "and it rings dead through the next beat (no mashing)")
				while bell._dead > 0.0:
					await get_tree().physics_frame
			while heart.off_beat() > 0.05:
				await get_tree().physics_frame
			bell.take_hit(1, Vector2.UP)
			_check(bell.rung and heart.stage == i, "on the beat, the bell sings")
			await _wait(DreamingHeart.CALM_TIME + 0.3)
		_check(heart.mode == DreamingHeart.Mode.EIGHTH and GameState.final_line, "every bell rung, the Heart still races")
		await _calm(room)
		var finished := [false]
		Events.game_finished.connect(func() -> void: finished[0] = true, CONNECT_ONE_SHOT)
		player.global_position = _tile_pos(room, Vector2i(11, 8))
		Input.action_press("hum")
		await _wait(1.5)
		_check(player.state == Player.State.HUM and heart.beat_length() > DreamingHeart.BEAT_FAST, "Wren hums, and the Heart slows")
		await _wait(DreamingHeart.HUM_NEEDED)
		Input.action_release("hum")
		_check(GameState.has_flag(DreamingHeart.DEFEATED_FLAG), "the eighth line: the Old One sleeps")
		_check(SaveManager.load_game() and GameState.has_flag(DreamingHeart.DEFEATED_FLAG), "the ending is saved")
		await _wait(3.0)
		await _close_dialogue(game)
		await _wait(2.0)
		_check(finished[0], "and the game is won")
		_check(not GameState.final_line, "Hum goes back to normal")
	DreamingHeart.roll_credits = true
	game.queue_free()
	await _wait(0.1)


## Dungeon completeness: the optional rooms with the finest gear, and the
## map screen in every dungeon with its map and compass.
func _test_extras_dungeon() -> void:
	# Each optional room, its way in, and its chest.
	var extras := [
		[Vector2i(36, 10), Vector2i(37, 9), Vector2i(37, 10), "nacre_buckler"],
		[Vector2i(40, 10), Vector2i(41, 9), Vector2i(41, 10), "abyssal"],
		[Vector2i(44, 10), Vector2i(45, 9), Vector2i(45, 10), "tidecaller_sword"],
	]
	for extra: Array in extras:
		GameState.reset_new_game()
		GameState.set_checkpoint(extra[0], GameState.NO_POSITION)
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.6)
		var player: Player = game.player
		player._invuln = 600.0
		var room := await _goto(game, extra[1], Vector2i(11, 6))
		await _calm(room)
		var below: String = RoomInfo.get_room(extra[2])["rows"][0]
		var above: String = RoomInfo.get_room(extra[1])["rows"][12]
		_check(above[19] != "#" and above[20] != "#" and below[19] == "." and below[20] == ".", "%s opens south to %s" % [room.name_key, extra[2]])
		if extra[3] == "abyssal":
			var walls := _child_of(room, BoneWall).filter(func(w: BoneWall) -> bool: return w.concealed and w.tile.y == 12)
			_check(walls.size() == 2, "a concealed wall hides the Ossuary")
			for wall: BoneWall in walls:
				wall.horn_hit(Vector2.ZERO)
			await _wait(0.3)
			_check(_child_of(room, BoneWall).filter(func(w: BoneWall) -> bool: return w.tile.y == 12 and not w.is_queued_for_deletion()).is_empty(), "the Echo Horn brings it down")
		room = await _goto(game, extra[2], Vector2i(19, 1))
		await _calm(room)
		var chests := _child_of(room, Chest)
		_check(chests.size() == 1 and chests[0].item == extra[3], "%s keeps the %s" % [room.name_key, extra[3]])
		if chests.size() == 1:
			chests[0].interact()
			await _wait(1.0)
			await _close_dialogue(game)
			_check(GameState.equipped_item(Items.kind(extra[3])) == extra[3], "Wren takes up the %s" % extra[3])
		game.queue_free()
		await _wait(0.1)

	# The map screen in each dungeon: the map shows every room, the compass
	# every chest and the boss until it is calmed.
	GameState.reset_new_game()
	for dungeon: String in MapPage.BOSS_FLAGS:
		var rooms := RoomInfo.in_area(dungeon)
		GameState.dungeon = dungeon
		GameState.room_coord = rooms[0]
		var page := MapPage.new()
		add_child(page)
		page.on_open()
		_check(page._rooms.size() == 1, "%s: with no map, only the room Wren stands in" % dungeon)
		GameState.give_item(Items.dungeon_item(dungeon, "map"))
		GameState.give_item(Items.dungeon_item(dungeon, "compass"))
		page.on_open()
		_check(page._rooms.size() == rooms.size(), "%s: the map shows all %d rooms" % [dungeon, rooms.size()])
		var bosses := rooms.filter(func(c: Vector2i) -> bool: return RoomInfo.get_room(c)["boss"] != Vector2i(-1, -1))
		_check(bosses.size() >= 1 and not page._boss_calmed(bosses[0]), "%s: the compass points to its boss" % dungeon)
		GameState.set_flag(MapPage.BOSS_FLAGS[dungeon])
		_check(page._boss_calmed(bosses.filter(func(c: Vector2i) -> bool: return RoomInfo.get_room(c)["name_key"] != "ROOM_MAW_HEART")[0]), "%s: and stops once it is calmed" % dungeon)
		page.queue_free()
	# The overworld map: seen rooms, and the rooms they open onto under fog.
	GameState.reset_new_game()
	GameState.dungeon = ""
	GameState.room_coord = Vector2i(0, 0)
	var world_page := MapPage.new()
	add_child(world_page)
	world_page.on_open()
	_check(world_page._rooms.size() == 1 and world_page._rooms[0] == Vector2i(0, 0), "the overworld map starts with the Shore alone")
	_check(world_page._fringe.has(Vector2i(1, 0)) and world_page._fringe.has(Vector2i(0, -1)),
		"the rooms the Shore opens onto show faint under fog (%s)" % [world_page._fringe])
	_check(world_page._fringe.has(Vector2i(-1, 0)) and not world_page._fringe.has(Vector2i(-1, -1)), "fog shows Dragline Cellar past the Shore's west gap, and nothing past a corner")
	# Lullaby Point's doorway only exists once the seventh bell has rung.
	GameState.mark_seen(Vector2i(2, 1))
	world_page.on_open()
	_check((world_page._doors[Vector2i(2, 1)] as Array).is_empty(), "no door on the map at Lullaby Point before the seventh bell")
	GameState.set_flag(Tidebell.flag_for("tomb"))
	world_page.on_open()
	_check(not (world_page._doors[Vector2i(2, 1)] as Array).is_empty(), "the Maw's mouth is marked once it opens")
	var greens: Array = MapPage.BIOME_COLORS["brinewood"]
	_check(world_page._tile_color("v", greens, true) == greens[2] and world_page._tile_color("M", greens, true) != greens[0],
		"veiled planks hide as water on the map; trees show")
	_check(world_page._tile_color("x", greens, false) == greens[0], "a dungeon's wisp letter isn't drawn as ice")
	world_page.queue_free()
	GameState.reset_new_game()
	await _wait(0.1)


## After the end: the echo stones round the sleeping Heart, a remembered
## fight with a boss in its own room, and the way home.
func _test_echoes_dungeon() -> void:
	GameState.reset_new_game()
	for id: String in EchoTrial.BOSSES:
		GameState.set_flag(EchoTrial.BOSSES[id][1])
	GameState.set_flag(DreamingHeart.DEFEATED_FLAG)
	GameState.set_flag(StoryDirector.ENDING_FLAG)
	GameState.set_checkpoint(EchoTrial.HEART_ROOM, GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	player._invuln = 600.0
	var room: Room = game.current_room
	_check(room.coord == EchoTrial.HEART_ROOM, "after the end, Continue starts by the sleeping Heart")
	await _wait(1.0 + EchoHall.RISE_GAP * 8 + 0.5)
	var stones := _child_of(room, EchoStone)
	_check(stones.size() == 8 and GameState.has_flag(EchoTrial.WOKEN_FLAG), "eight echo stones rise round the Heart")
	_check(not Audio.music_cue.begins_with("boss"), "the sleeping Heart's chamber is no fight (%s)" % Audio.music_cue)
	_check(stones.all(func(s: EchoStone) -> bool: return room.tile_at(s.return_tile.x, s.return_tile.y) == "."), "every stone sends Wren home onto floor")
	if stones.size() == 8:
		var stone: EchoStone = stones.filter(func(s: EchoStone) -> bool: return s.id == "hull")[0]
		var back := stone.return_tile
		stone.activate()
		await _wait(1.0)
		room = game.current_room
		_check(room.coord == EchoTrial.BOSSES["hull"][0] and EchoTrial.boss == "hull", "a stone carries Wren into the Matriarch's echo")
		var bosses := _child_of(room, BarnacleMatriarch)
		_check(bosses.size() == 1 and _child_of(room, BossAftermath).is_empty(), "she is there again, and no bell")
		_check(_child_of(room, CanvasModulate).size() == 1, "the room is washed in dream-light")
		Events.boss_defeated.emit()
		await _wait(EchoTrial.RETURN_DELAY + 1.2)
		room = game.current_room
		_check(room.coord == EchoTrial.HEART_ROOM and EchoTrial.boss == "", "calmed, Wren is carried back to the Heart")
		_check(GameState.has_flag(EchoTrial.cleared_flag("hull")), "and the stone remembers it")
		var local := player.global_position - room.global_position
		_check(Vector2i(local / Room.TILE) == back, "Wren comes back in front of the stone (at %s)" % local)
		# Vael's echo: no words before the song.
		var vael_stone: EchoStone = _child_of(room, EchoStone).filter(func(s: EchoStone) -> bool: return s.id == "vael")[0]
		var talked := [false]
		var listen := func(_pages: Array) -> void: talked[0] = true
		Events.conversation_requested.connect(listen)
		vael_stone.activate()
		await _wait(1.2)
		Events.conversation_requested.disconnect(listen)
		room = game.current_room
		var vaels := _child_of(room, CantorVael)
		_check(vaels.size() == 1 and not talked[0], "Vael's echo sings without a word")
		# Leaving the room ends the echo.
		room = await _goto(game, Vector2i(44, 8), Vector2i(11, 1))
		_check(EchoTrial.boss == "", "walking out of a remembered fight ends it")
		room = await _goto(game, Vector2i(44, 7), Vector2i(11, 11))
		_check(_child_of(room, CantorVael).is_empty(), "and the room is as Wren left it")
		# Walking out in the wait after a calm ends the echo all the same.
		EchoTrial.begin("kiln", Vector2i(4, 7))
		await _wait(1.0)
		Events.boss_defeated.emit()
		await _wait(0.3)
		room = await _goto(game, Vector2i(21, 8), Vector2i(11, 1))
		_check(EchoTrial.boss == "", "leaving before the trip home ends the echo too")
	game.queue_free()
	EchoTrial.end()
	GameState.reset_new_game()
	await _wait(0.1)


## The dungeons' own regular enemies, and how they toughen with depth.
func _test_foes_dungeon() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(36, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	player._invuln = 600.0
	var room: Room = game.current_room
	# A Tollshell: shut, it turns the sword; near, it rattles, tolls, opens.
	var shells := _child_of(room, Tollshell)
	_check(shells.size() == 1, "a Tollshell squats in the Belfry's entry")
	if shells.size() == 1:
		var shell: Tollshell = shells[0]
		_check(shell.max_hp == 3, "deeper down, it's tougher (%d)" % shell.max_hp)
		_check(shell.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "shut, its shell turns the sword")
		player.global_position = shell.global_position + Vector2(0, 30)
		await _wait(Tollshell.RATTLE_TIME + 0.1)
		_check(shell.is_tolling(), "Wren near, it rattles and then tolls")
		await _wait(Tollshell.TOLL_TIME + 0.1)
		_check(shell.is_open(), "then it lifts its lip to look out")
		_check(shell.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT, "and open, the sword finds it")
	# A Puffwisp: draws breath, then blows Wren back.
	room = await _goto(game, Vector2i(28, 10), Vector2i(11, 10))
	await _wait(0.2)
	var puffs := _child_of(room, Puffwisp)
	_check(puffs.size() == 1, "a Puffwisp drifts in the Gale Spire's entry")
	if puffs.size() == 1:
		var puff: Puffwisp = puffs[0]
		for c in _child_of(room, Enemy):
			if c != puff:
				c.queue_free()
		_check(puff.max_hp == 3, "the Gale's foes are tougher than the Hull's (%d)" % puff.max_hp)
		player.global_position = room.global_position + Vector2(12 * 16, 9 * 16)
		puff.global_position = player.global_position + Vector2(40, 0)
		var deadline := Time.get_ticks_msec() + 3000
		while Time.get_ticks_msec() < deadline and not puff.is_blowing():
			await _wait(0.05)
		var before := player.global_position.x
		await _wait(0.4)
		_check(puff.is_blowing() or puff.is_spent(), "it draws breath and blows")
		_check(player.global_position.x < before - 20.0, "the gust shoves Wren back (%.0f px)" % (before - player.global_position.x))
	# A Gumleech: under the flood it can't be reached; it rears and bites;
	# drained, it's stranded and the sword finds it.
	MawBreath.elapsed = MawBreath.OUT_TIME + MawBreath.IN_TELL_TIME + 0.1
	room = await _goto(game, Vector2i(44, 10), Vector2i(11, 10))
	await _wait(0.2)
	var leeches := _child_of(room, Gumleech)
	_check(leeches.size() == 1, "a Gumleech swims in the Maw's throat")
	if leeches.size() == 1:
		var leech: Gumleech = leeches[0]
		_check(leech.is_submerged(), "with the palate flooded, it swims under the water")
		_check(not leech._hurtbox.monitorable and leech._hurtbox.collision_layer == 0, "and under the water the sword can't reach it")
		_check(leech.take_hit(1, Vector2.UP) == Enemy.HitResult.IGNORED, "nor a hook, arrow or bomb")
		player.global_position = _tile_pos(room, Vector2i(16, 3))
		var start := leech.global_position
		var deadline := Time.get_ticks_msec() + 3000
		while Time.get_ticks_msec() < deadline and leech.mode != Gumleech.Mode.RISE:
			await _wait(0.05)
		_check(leech.mode == Gumleech.Mode.RISE, "Wren near the water, it rears up")
		_check(not leech._contact.active, "rearing is only the tell: it doesn't sting yet")
		await _wait(Gumleech.RISE_TIME + 0.1)
		_check(leech.mode in [Gumleech.Mode.BITE, Gumleech.Mode.RETURN], "then lunges to bite")
		_check(leech.global_position.y < start.y - 8.0, "out toward Wren (%.0f px)" % (start.y - leech.global_position.y))
		MawBreath.elapsed = 0.1
		room.refresh_water()
		await _wait(1.5)
		_check(leech.is_stranded(), "the palate drained, it's left stranded")
		_check(leech.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT, "and stranded, the sword finds it")
	# Depth: a Hull Scuttler is as it was; a Tomb Marrowguard hits harder.
	room = await _goto(game, Vector2i(10, 9), Vector2i(11, 11))
	var scuttlers := _child_of(room, Scuttler)
	_check(not scuttlers.is_empty() and scuttlers[0].max_hp == 2 and scuttlers[0].contact_damage == 1, "the Hull's Scuttlers are as they were")
	room = await _goto(game, Vector2i(41, 9), Vector2i(1, 6))
	var guards := _child_of(room, Marrowguard)
	_check(not guards.is_empty() and guards[0].max_hp == 6 and guards[0].contact_damage == 2, "a Tomb Marrowguard is twice as tough and hits harder")
	game.queue_free()
	GameState.reset_new_game()
	await _wait(0.1)


## QA pass: no edge crossing, hook pull or rising bell leaves Wren inside
## something solid.
func _test_qa_dungeon() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(36, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	player._invuln = 600.0
	# The Bone Pit's east edge is open, but the Marrow Vault's bars stand
	# just inside it until its plates are solved: Wren stays in the Pit.
	var room := await _goto(game, Vector2i(41, 9), Vector2i(21, 6))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(23, 6)) + Vector2(7, 0)
	game.call("_change_room", Vector2i.RIGHT)
	await _wait(0.6)
	_check(game.current_room.coord == Vector2i(41, 9), "closed bars over the far edge hold Wren in the Bone Pit")
	_check(player.global_position.x < room.global_position.x + Room.SIZE.x, "and keep them on this side of the edge")
	GameState.set_flag(RoomPuzzle.flag_for(Vector2i(42, 9)))
	game.set("_hatch_blocked", [Vector2i.ZERO, 0])
	player.global_position = _tile_pos(room, Vector2i(23, 6)) + Vector2(7, 0)
	game.call("_change_room", Vector2i.RIGHT)
	await _wait(0.8)
	_check(game.current_room.coord == Vector2i(42, 9), "once the Vault's gate is solved, the way east is open")
	room = game.current_room
	await _calm(room)
	# A hooked crate stops a tile short of Wren, from any distance.
	for gap in [36.0, 40.0, 44.0, 48.0, 56.0]:
		var crate := Crate.new()
		crate.position = _tile_pos(room, Vector2i(20, 3)) - room.global_position
		room.add_child(crate)
		player.global_position = crate.global_position - Vector2(gap, 0)
		player.velocity = Vector2.ZERO
		await _wait(0.05)
		var steps := 0
		while not crate.pull_towards(player.global_position, 2.0) and steps < 200:
			steps += 1
			await get_tree().physics_frame
		var apart := absf(crate.global_position.x - player.global_position.x)
		_check(apart >= 12.0, "a crate hooked from %.0f px stops clear of Wren (%.0f px apart)" % [gap, apart])
		crate.queue_free()
	# Cut short mid-drag, it never settles on Wren's tile.
	var cut := Crate.new()
	cut.position = _tile_pos(room, Vector2i(20, 3)) - room.global_position
	room.add_child(cut)
	await _wait(0.05)
	cut._pull_to = cut.position - Vector2(Room.TILE, 0)
	cut.position.x -= 10.0
	player.global_position = room.global_position + cut._pull_to
	await get_tree().physics_frame
	await get_tree().physics_frame
	cut.stop_pull()
	_check(absf(cut.global_position.x - player.global_position.x) >= 12.0, "a drag cut short doesn't drop the crate on Wren")
	cut.queue_free()
	# A Tidebell rising where Wren stands stays ghostly until they step off.
	player.global_position = _tile_pos(room, Vector2i(16, 2))
	var bell := Tidebell.new()
	bell.rise = true
	bell.position = player.global_position - room.global_position
	room.add_child(bell)
	var shape: CollisionShape2D = bell.get_children().filter(func(n: Node) -> bool: return n is CollisionShape2D)[0]
	await _wait(2.0)
	_check(shape.disabled, "a bell rising on Wren isn't solid while they stand in it")
	player.global_position += Vector2(0, 32)
	await _wait(0.4)
	_check(not shape.disabled, "once Wren steps off, the bell is solid")
	# Bars slammed shut rise back out of the deck to where they stood.
	var bars := Bars.new()
	bars.position = _tile_pos(room, Vector2i(14, 2)) - room.global_position
	room.add_child(bars)
	var up_y: float = bars._sprite.position.y
	bars.open(true)
	bars.close()
	await _wait(0.3)
	_check(is_equal_approx(bars._sprite.position.y, up_y) and is_equal_approx(bars._sprite.modulate.a, 1.0) and bars.visible, "bars that slam shut rise back to where they stood")
	bars.queue_free()
	# A shake caught by a pause settles rather than freezing off centre.
	var camera: Camera2D = game.camera
	Feel.shake(6.0)
	await get_tree().process_frame
	get_tree().paused = true
	await get_tree().process_frame
	await get_tree().process_frame
	_check(camera.offset == Vector2.ZERO, "a pause settles the screen shake (%s)" % camera.offset)
	get_tree().paused = false
	game.queue_free()
	GameState.reset_new_game()
	await _wait(0.1)


## Every dungeon's air has something in it; the overworld has none of it.
func _test_air_dungeon() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(10, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	game.player._invuln = 600.0
	var firsts := {"hull": Vector2i(10, 10), "kiln": Vector2i(21, 10), "mire": Vector2i(25, 10), "gale": Vector2i(28, 10),
		"glacier": Vector2i(32, 10), "belfry": Vector2i(36, 10), "tomb": Vector2i(40, 10), "maw": Vector2i(44, 10)}
	for dungeon: String in firsts:
		var room := await _goto(game, firsts[dungeon], Vector2i(11, 10))
		var air := room.get_node_or_null("Air") as DungeonAir
		_check(air != null, "%s: the air has something in it" % dungeon)
		if air == null:
			continue
		var specks: int = air._motes.size() + air._falls.size() + air._rises.size() + air._rain.size() + air._drips.size() + air._trickles.size()
		_check(specks >= 3, "%s: %d specks in the air" % [dungeon, specks])
		_check(air.z_index < Darkness.Z, "%s: under the Mire's dark, so it can't light it" % dungeon)
	var kiln := await _goto(game, Vector2i(21, 10), Vector2i(11, 10))
	_check(not (kiln.get_node("Air") as DungeonAir)._rises.is_empty(), "embers lift off the Kiln's lava")
	var belfry := await _goto(game, Vector2i(36, 10), Vector2i(11, 11))
	var bubbles: DungeonAir = belfry.get_node("Air")
	_check(not bubbles._rises.is_empty() and not bubbles._drips.is_empty(), "the Belfry drips and bubbles")
	# The drips run their whole course: gather, fall, ring, and again.
	var landed := false
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline and not landed:
		for d in bubbles._drips:
			landed = landed or d.ring >= 0.0
		await _wait(0.1)
	_check(landed, "a drip lands on the floor with a ring")
	# In the Tomb, nothing in the air comes near a hidden bone wall's seam,
	# whose leaking dust is the only sign of it.
	var seam_room := await _goto(game, Vector2i(40, 8), Vector2i(11, 10))
	var seam_air: DungeonAir = seam_room.get_node("Air")
	_check(not seam_air._seams.is_empty(), "the Tomb's air knows where its hidden walls are")
	var near := false
	for tile in seam_air._roof:
		near = near or not seam_air._clear_of_seams(Vector2(tile * Room.TILE))
	_check(not near, "and no sand trickles near one")
	var outside := await _goto(game, Vector2i(1, 1), Vector2i(11, 6))
	_check(outside.get_node_or_null("Air") == null, "the overworld has its own life instead")
	# High contrast: the air steps back.
	var was := Settings.high_contrast
	Settings.high_contrast = true
	var hull := await _goto(game, Vector2i(10, 10), Vector2i(11, 10))
	_check(is_equal_approx((hull.get_node("Air") as DungeonAir)._fade, DungeonAir.CONTRAST_FADE), "with high contrast on, the air fades back")
	Settings.high_contrast = was
	game.queue_free()
	GameState.reset_new_game()
	await _wait(0.1)


## Wren looses a frost arrow from a tile, facing a way, and waits for it.
func _shoot(room: Room, player: Player, tile: Vector2i, facing: Vector2) -> void:
	player.global_position = _tile_pos(room, tile)
	player.velocity = Vector2.ZERO
	player.facing = facing
	await _wait(0.1)
	player.use_item("frostfang_bow")
	await _wait(0.5)


func _tile_pos(room: Room, tile: Vector2i) -> Vector2:
	return room.global_position + Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12)


func _goto(game: Node, coord: Vector2i, tile: Vector2i) -> Room:
	Events.door_entered.emit(coord, tile)
	await _wait(0.9)
	return game.current_room


## Clears a room's enemies and any shots in the air, and fills Wren's
## breath, so a stray hit can't end the run (and free the room) mid-test.
## Spitters add their shots a frame late, so it waits and sweeps again.
func _calm(room: Room) -> void:
	for enemy in _child_of(room, Enemy):
		if not enemy.is_in_group("boss"):
			enemy.queue_free()
	await _wait(0.2)
	for shot in _child_of(room, Projectile):
		shot.queue_free()
	GameState.refill()


func _child_of(room: Room, type: Variant) -> Array:
	return room.get_children().filter(func(n: Node) -> bool: return is_instance_of(n, type))


## The Rotting Hull: gaps, the Tide Hook, crates and plates, a shut-in room,
## the big-key door and the Barnacle Matriarch.
func _test_hull_dungeon() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(10, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player

	# The Orlop's broken deck: walking into a gap costs a bubble. (Its
	# crabs and Spitters go first: a stray hit on top of the fall could
	# empty Wren's breath and reload the room under the test.)
	var room := await _goto(game, Vector2i(11, 8), Vector2i(11, 11))
	_check(room.coord == Vector2i(11, 8) and room.has_node("PitField"), "the Orlop has gaps in its deck")
	await _calm(room)
	var before := GameState.bubbles
	Input.action_press("move_up")
	await _wait(0.6)
	Input.action_release("move_up")
	await _wait(0.8)
	_check(GameState.bubbles == before - 1, "falling through a gap pops a bubble (%d -> %d)" % [before, GameState.bubbles])
	var local := player.global_position - room.global_position
	_check(local.y > 10 * Room.TILE and player.state == Player.State.MOVE, "Wren climbs back onto the deck (at %s)" % local)
	await _wait(1.1)

	# The Tide Hook carries Wren over the gap to the hook post.
	await _calm(room)
	await _wait(1.1)
	_check(not player.use_item("tide_hook"), "no hook before it's found")
	GameState.give_item("tide_hook")
	_check(GameState.item_slots[0] == "tide_hook", "the hook goes in the first item slot")
	player.global_position = _tile_pos(room, Vector2i(11, 11))
	player.facing = Vector2.UP
	await _wait(0.1)
	before = GameState.bubbles
	_check(player.use_item("tide_hook"), "Wren throws the Tide Hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(local.y < 8 * Room.TILE and GameState.bubbles == before, "the hook carries Wren across the gap (at %s)" % local)
	_check(player.state == Player.State.MOVE and not player.airborne, "Wren lands and can move again")

	# The Flooded Hold: a sideways throw from the middle of a row still bites
	# the post, and carries Wren over the water to the chest's island.
	room = await _goto(game, Vector2i(9, 10), Vector2i(12, 11))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(12, 11))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(int(local.x) / Room.TILE == 17 and player.state == Player.State.MOVE, "a sideways hook crosses the Flooded Hold (at %s)" % local)

	# The Cargo Hold: shove the crate onto the plate to open the bars.
	room = await _goto(game, Vector2i(11, 9), Vector2i(8, 6))
	await _calm(room)
	var crate: Crate = _child_of(room, Crate)[0]
	var start := crate.position
	player.global_position = crate.global_position + Vector2(-15, 0)
	Input.action_press("move_right")
	await _wait(0.9)
	Input.action_release("move_right")
	_check(crate.position.x >= start.x + Room.TILE, "leaning on a crate shoves it (%s -> %s)" % [start, crate.position])
	var plate: PressurePlate = _child_of(room, PressurePlate)[0]
	await _wait(0.3)
	player.global_position = _tile_pos(room, plate.tile)
	await _wait(0.3)
	_check(not plate.pressed, "Wren alone is too light for a plate")
	player.global_position = _tile_pos(room, plate.tile + Vector2i(-2, 2))
	crate.position = Vector2(plate.tile.x * Room.TILE + 8, plate.tile.y * Room.TILE + 12)
	await _wait(0.3)
	_check(plate.pressed, "a crate weighs down the plate")
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "the plate solves the room")
	var bars: Array = _child_of(room, Bars)
	_check(bars.size() == 3 and bars.all(func(b: Bars) -> bool: return b.is_open), "the Cargo Hold's bars open")

	# The Captain's Cabin: the hook drags a crate out of its nook.
	room = await _goto(game, Vector2i(9, 8), Vector2i(12, 3))
	await _calm(room)
	var nook: Crate = null
	for c in _child_of(room, Crate):
		if c.position.x < Room.SIZE.x / 2.0:
			nook = c
	start = nook.position
	player.global_position = _tile_pos(room, Vector2i(12, 3))
	player.facing = Vector2.LEFT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.5)
	_check(nook.position.x > start.x + Room.TILE, "the hook drags a crate (%s -> %s)" % [start, nook.position])
	_check(player.state == Player.State.MOVE, "the hook comes home after a drag")

	# The Keel: hook over the trench, drag both crates out of their nooks,
	# and the plates open the way up to the Sail Loft.
	room = await _goto(game, Vector2i(8, 9), Vector2i(17, 4))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(17, 4))
	player.facing = Vector2.LEFT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(int(local.x) / Room.TILE == 14 and player.state == Player.State.MOVE, "the hook crosses the Keel's trench (at %s)" % local)
	for crate_tile: Vector2i in [Vector2i(3, 6), Vector2i(13, 6)]:
		var stuck: Crate = null
		for c in _child_of(room, Crate):
			if int(c.position.x) / Room.TILE == crate_tile.x:
				stuck = c
		start = stuck.position
		player.global_position = _tile_pos(room, crate_tile)
		player.facing = Vector2.UP if crate_tile.x == 3 else Vector2.DOWN
		await _wait(0.1)
		player.use_item("tide_hook")
		await _wait(1.5)
		_check(absf(stuck.position.y - start.y) >= Room.TILE * 2, "the hook drags a Keel crate out of its nook (%s -> %s)" % [start, stuck.position])
	var keel_plates: Array = _child_of(room, PressurePlate)
	var keel_crates: Array = _child_of(room, Crate)
	_check(keel_plates.size() == 2 and keel_crates.size() == 2, "the Keel has two crates for two plates")
	player.global_position = _tile_pos(room, Vector2i(18, 2))
	for i in keel_plates.size():
		keel_crates[i].position = Vector2(keel_plates[i].tile.x * Room.TILE + 8, keel_plates[i].tile.y * Room.TILE + 12)
	await _wait(0.3)
	_check(_child_of(room, Bars).all(func(b: Bars) -> bool: return b.is_open), "both plates open the Keel's bars")

	# The Sail Loft: three hooks, island to island, up to the big key.
	room = await _goto(game, Vector2i(8, 8), Vector2i(11, 10))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(11, 10))
	for step: Array in [[Vector2.UP, Vector2i(11, 7)], [Vector2.LEFT, Vector2i(6, 7)], [Vector2.UP, Vector2i(6, 3)]]:
		player.facing = step[0]
		await _wait(0.1)
		player.use_item("tide_hook")
		await _wait(1.3)
		local = player.global_position - room.global_position
		_check(Vector2i(local / Room.TILE) == step[1] and player.state == Player.State.MOVE and not player.airborne, "the Sail Loft's hook lands Wren on %s (at %s)" % [step[1], local])
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Sail Loft's chest holds the big key")

	# The Chain Locker: hook to the island, then on to the far deck.
	room = await _goto(game, Vector2i(12, 8), Vector2i(7, 6))
	await _calm(room)
	player.global_position = _tile_pos(room, Vector2i(7, 6))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(Vector2i(local / Room.TILE) == Vector2i(12, 6), "the hook reaches the Chain Locker's island (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(12, 4))
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(Vector2i(local / Room.TILE) == Vector2i(17, 4), "the hook reaches the Chain Locker's far deck (at %s)" % local)

	# The Rope Locker shuts Wren in until it's cleared, then shows its chest.
	GameState.inventory.erase("tide_hook")
	GameState.item_slots = ["", ""]
	room = await _goto(game, Vector2i(12, 9), Vector2i(6, 6))
	await _wait(0.3)
	bars = _child_of(room, Bars)
	_check(bars.all(func(b: Bars) -> bool: return not b.is_open), "the Rope Locker's bars slam shut")
	var chest: Chest = _child_of(room, Chest)[0]
	_check(not chest.visible, "its chest is hidden until the room is clear")
	for enemy in _child_of(room, Enemy):
		enemy.take_hit(99, Vector2.RIGHT)
	await _wait(0.6)
	_check(chest.visible and bars.all(func(b: Bars) -> bool: return b.is_open), "clearing the room opens the bars and shows the chest")
	player.global_position = chest.global_position + Vector2(0, 14)
	player.facing = Vector2.UP
	await _wait(0.1)
	player.try_interact()
	_check(GameState.has_item("tide_hook"), "the chest holds the Tide Hook")
	await _wait(1.0)
	for child in game.get_children():
		if child is DialogueBox:
			while DialogueBox.is_open:
				child.advance()
				child.advance()
	await _wait(0.4)

	# The great door needs the big key.
	room = await _goto(game, Vector2i(10, 8), Vector2i(11, 2))
	await _calm(room)
	var doors: Array = _child_of(room, BigDoor)
	_check(doors.size() == 2, "the Listing Deck has the great door")
	player.global_position = (doors[0] as Node2D).global_position + Vector2(0, 8)
	await _wait(0.3)
	_check(not GameState.flags.get(BigDoor.flag_for(room.coord), false), "the great door stays shut without the big key")
	GameState.give_item("hull_big_key")
	player.global_position = _tile_pos(room, Vector2i(11, 3))
	await _wait(0.2)
	player.global_position = (doors[0] as Node2D).global_position + Vector2(0, 8)
	await _wait(0.4)
	_check(GameState.flags.get(BigDoor.flag_for(room.coord), false), "the big key opens the great door")

	# The Barnacle Matriarch (Sister Lowe's scene is tested in _test_story).
	GameState.set_flag(StoryDirector.LOWE_HULL_FLAG)
	room = await _goto(game, Vector2i(10, 7), Vector2i(11, 10))
	var boss: BarnacleMatriarch = _child_of(room, BarnacleMatriarch)[0] if _child_of(room, BarnacleMatriarch).size() > 0 else null
	_check(boss != null, "the Matriarch waits in the Figurehead Hold")
	if boss:
		boss.ai_enabled = false
		_check(boss.plates_left() == 3, "she starts with three planks")
		_check(boss.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "the sword glances off her planks")
		_check(not boss.hook_hit(Vector2.UP), "the hook can't catch her while she's on guard")
		boss.mode = BarnacleMatriarch.Mode.RECOVER
		_check(boss.hook_hit(Vector2.UP) and boss.mode == BarnacleMatriarch.Mode.EXPOSED, "hooking a plank while her claw is stuck exposes her")
		_check(boss.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT and boss.hp == BarnacleMatriarch.MAX_HP - 1, "her soft body takes the sword")
		boss.mode = BarnacleMatriarch.Mode.EXPOSED
		boss.take_hit(99, Vector2.UP)
		# Her fall plus the last blow's held time and slow motion.
		await _wait(3.1)
		_check(GameState.flags.get(BarnacleMatriarch.DEFEATED_FLAG, false), "beating her is remembered")
		var bell: Tidebell = null
		for child in room.get_children():
			if child is Tidebell:
				bell = child
		_check(bell != null, "the Tidebell rises where she fell")
		if bell:
			# The talk box sits at the bottom of the screen: the bell, and Wren
			# standing below it to ring it, must stay clear of it.
			var view_top: float = game.camera.position.y - 216.0 / 2.0
			var below: float = room.position.y + bell.position.y + Room.TILE - view_top
			_check(below < DialogueBox.BOX.position.y - 4.0, "the talk box can't cover the Tidebell or Wren ringing it")
			var resonance_before := GameState.resonance_max
			await _scene_over(game)
			bell.interact()
			_check(GameState.resonance_max > resonance_before and GameState.flags.get(Tidebell.BELL_FLAG, false), "ringing the bell grows the Resonance meter")
			await _play_scene(game, 10.0)
		_check(_child_of(room, Doorway).size() == 1, "a way out opens after the fight")
	game.queue_free()
	await _wait(0.1)


## The Kiln: lava, the Stonebreaker Mallet (boulders, pegs, Clinkers), drop
## hammers, rising lava and the Slagwyrm.
func _test_kiln_dungeon() -> void:
	_check(ResourceLoader.exists("res://rooms/room_21_10.tscn"), "the Kiln has an entry room")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(21, 10), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var player: Player = game.player
	_check(GameState.dungeon == "kiln" and game.current_room.biome == "kiln", "Wren starts inside the Kiln")

	# Lava burns like a gap: a bubble, and back on solid ground.
	var room := await _goto(game, Vector2i(21, 9), Vector2i(5, 6))
	await _calm(room)
	_check(room.has_node("PitField"), "the Casting Floor's lava is handled like the Hull's gaps")
	var field: PitField = room.get_node("PitField")
	_check(field.is_gap(Vector2(5 * Room.TILE + 8, 3 * Room.TILE + 8)), "a lava tile counts as somewhere Wren can't stand")
	var before := GameState.bubbles
	player.global_position = _tile_pos(room, Vector2i(5, 5))
	await _wait(0.4)
	Input.action_press("move_up")
	await _wait(0.5)
	Input.action_release("move_up")
	await _wait(0.8)
	_check(GameState.bubbles == before - 1, "walking into lava pops a bubble (%d -> %d)" % [before, GameState.bubbles])
	var local := player.global_position - room.global_position
	_check(local.y > 5 * Room.TILE and player.state == Player.State.MOVE, "Wren climbs back out of the lava (at %s)" % local)
	await _wait(1.1)

	# The Tide Hook carries Wren over the lava to the locked hatch's side.
	GameState.refill()
	GameState.give_item("tide_hook")
	player.global_position = _tile_pos(room, Vector2i(8, 7))
	player.facing = Vector2.UP
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(local.y < 3 * Room.TILE and player.state == Player.State.MOVE and GameState.bubbles == GameState.max_bubbles, "the hook crosses the lava (at %s)" % local)
	player.global_position = _tile_pos(room, Vector2i(15, 2))
	player.facing = Vector2.DOWN
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.3)
	local = player.global_position - room.global_position
	_check(local.y > 5 * Room.TILE and GameState.bubbles == GameState.max_bubbles, "and a post on the far side brings Wren back (at %s)" % local)

	# The Stonebreaker Mallet bursts the boulders blocking the east way.
	_check(not player.use_item("stonebreaker"), "no mallet before it's found")
	GameState.give_item("stonebreaker")
	_check(GameState.item_slots.has("stonebreaker"), "the mallet goes in an item slot")
	var boulders := _child_of(room, Boulder)
	_check(boulders.size() == 3, "three boulders block the Casting Floor's east side")
	player.global_position = _tile_pos(room, Vector2i(20, 6))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.start_attack()
	await _wait(0.4)
	_check(_child_of(room, Boulder).size() == 3, "the sword can't break a boulder")
	_check(player.use_item("stonebreaker"), "Wren swings the mallet")
	await _wait(0.5)
	_check(_child_of(room, Boulder).size() == 2 and player.state == Player.State.MOVE, "the mallet bursts the boulder in front (%d left)" % _child_of(room, Boulder).size())

	# Slag Pits: a peg hammered flush lets Wren reach the key.
	room = await _goto(game, Vector2i(22, 9), Vector2i(20, 3))
	await _calm(room)
	var peg: Peg = _child_of(room, Peg)[0]
	player.global_position = _tile_pos(room, Vector2i(18, 3))
	player.facing = Vector2.UP
	await _wait(0.1)
	player.try_interact()
	_check(GameState.keys("kiln") == 0, "the chest can't be opened through the wall")
	player.global_position = _tile_pos(room, Vector2i(20, 3))
	player.facing = Vector2.UP
	await _wait(0.1)
	player.use_item("stonebreaker")
	await _wait(0.5)
	_check(peg.down, "the mallet drives the peg into the floor")
	Input.action_press("move_up")
	await _wait(0.35)
	Input.action_release("move_up")
	local = player.global_position - room.global_position
	_check(local.y < 3 * Room.TILE, "Wren walks over the hammered peg (at %s)" % local)
	player.facing = Vector2.LEFT
	player.global_position = _tile_pos(room, Vector2i(19, 1))
	await _wait(0.1)
	player.try_interact()
	_check(GameState.keys("kiln") == 1, "the Slag Pits' chest holds a small key")
	await _wait(0.6)

	# A Clinker: the sword glances off; the mallet flips it; then it's soft.
	var clinker := Clinker.new()
	clinker.position = Vector2(11 * Room.TILE + 8, 7 * Room.TILE + 12)
	room.add_child(clinker)
	await _wait(0.1)
	clinker.ai_enabled = false
	_check(clinker.take_hit(1, Vector2.DOWN) == Enemy.HitResult.BLOCKED, "the sword glances off a Clinker's shell")
	player.global_position = clinker.global_position + Vector2(0, -15)
	player.facing = Vector2.DOWN
	await _wait(0.1)
	player.use_item("stonebreaker")
	await _wait(0.5)
	_check(clinker.mode == Clinker.Mode.FLIPPED, "the mallet flips a Clinker onto its back")
	_check(clinker.take_hit(1, Vector2.DOWN) == Enemy.HitResult.HIT, "a flipped Clinker takes the sword")
	clinker.take_hit(9, Vector2.DOWN)
	var hooked := Clinker.new()
	hooked.position = Vector2(4 * Room.TILE + 8, 7 * Room.TILE + 12)
	room.add_child(hooked)
	await _wait(0.1)
	hooked.ai_enabled = false
	_check(hooked.hook_hit(Vector2.LEFT) and hooked.mode == Clinker.Mode.FLIPPED, "the Tide Hook flips a Clinker too")
	hooked.queue_free()

	# Drop hammers hurt whatever is under them when they land.
	room = await _goto(game, Vector2i(21, 8), Vector2i(11, 8))
	await _calm(room)
	var hammer: DropHammer = _child_of(room, DropHammer)[0]
	var waited := 0.0
	while not hammer.is_down() and waited < 4.0:
		await _wait(0.05)
		waited += 0.05
	before = GameState.bubbles
	player.global_position = hammer.global_position
	await _wait(0.15)
	_check(GameState.bubbles < before, "a drop hammer landing on Wren hurts (%d -> %d)" % [before, GameState.bubbles])
	player.global_position = _tile_pos(room, Vector2i(11, 8))
	await _wait(1.2)

	# The Riser: lava climbs from the bottom; caught, Wren goes back to the
	# way in; reaching the top drains it for good.
	GameState.refill()
	room = await _goto(game, Vector2i(22, 8), Vector2i(11, 11))
	field = room.get_node("PitField")
	_check(field.rising, "the Riser's lava starts to climb")
	await _wait(2.4)
	_check(field.level < Room.ROWS, "the lava has risen (level %.1f)" % field.level)
	before = GameState.bubbles
	var waited_rise := 0.0
	while GameState.bubbles == before and waited_rise < 6.0:
		await _wait(0.1)
		waited_rise += 0.1
	await _wait(0.6)
	local = player.global_position - room.global_position
	_check(GameState.bubbles == before - 1 and int(local.y) / Room.TILE == 11, "the lava catches Wren and they're back at the way in (at %s)" % local)
	_check(field.level >= Room.ROWS - 0.5, "and the lava sinks to start again (level %.1f)" % field.level)
	player.global_position = _tile_pos(room, Vector2i(11, 1))
	await _wait(0.3)
	_check(not field.rising and GameState.has_flag(PitField.rise_flag(room.coord)), "reaching the top drains the lava for good")

	# The Slagwyrm.
	GameState.refill()
	GameState.set_flag(BigDoor.flag_for(Vector2i(21, 8)))
	GameState.set_flag(StoryDirector.CRUCIBLE_FLAG)
	room = await _goto(game, Vector2i(21, 7), Vector2i(11, 10))
	await _wait(0.2)
	var bosses := _child_of(room, Slagwyrm)
	_check(bosses.size() == 1, "the Slagwyrm waits in the Crucible")
	if bosses.size() == 1:
		var wyrm: Slagwyrm = bosses[0]
		wyrm.ai_enabled = false
		player._invuln = 999.0
		_check(wyrm.segments.size() == Slagwyrm.SEGMENTS and wyrm.hp == Slagwyrm.SEGMENTS, "it has six plates, one for each part of its strength")
		_check(wyrm.take_hit(1, Vector2.UP) == Enemy.HitResult.BLOCKED, "the sword glances off its head")
		var plate: WyrmSegment = wyrm.segments[0]
		plate.global_position = _tile_pos(room, Vector2i(11, 8))
		plate.set_surfaced(true)
		_check(not plate.mallet_hit(Vector2.UP) and wyrm.hp == Slagwyrm.SEGMENTS, "a molten plate shrugs off the mallet")
		# Dragged through a quench pool, a plate sets hard.
		wyrm.mode = Slagwyrm.Mode.SURFACE
		plate.global_position = _tile_pos(room, Vector2i(6, 8))
		wyrm._cool_in_pools()
		_check(plate.is_hard(), "a plate passing through a pool sets into crust")
		_check(wyrm.hardened_count() == 1, "the wyrm knows how stiff it is")
		player.global_position = plate.global_position + Vector2(0, 16)
		player.facing = Vector2.UP
		await _wait(0.1)
		player.use_item("stonebreaker")
		await _wait(0.5)
		_check(wyrm.hp == Slagwyrm.SEGMENTS - 1 and wyrm.segments.size() == Slagwyrm.SEGMENTS - 1, "the mallet cracks a crusted plate off (hp %d)" % wyrm.hp)
		# Diving melts every plate soft again.
		wyrm.segments[0].harden(5.0)
		wyrm._go_under()
		_check(wyrm.hardened_count() == 0 and not wyrm.visible, "diving under the floor melts it soft again")
		wyrm._target = _tile_pos(room, Vector2i(11, 6))
		wyrm._erupt()
		_check(wyrm.visible and wyrm.mode == Slagwyrm.Mode.ERUPT, "it bursts back up through the floor")
		while wyrm.segments.size() > 0:
			wyrm.segment_smashed(wyrm.segments[0])
		_check(GameState.flags.get(Slagwyrm.DEFEATED_FLAG, false), "breaking every plate beats the Slagwyrm")
		await _wait(3.9)
		player._invuln = 0.0
		var bell: Tidebell = null
		for child in room.get_children():
			if child is Tidebell:
				bell = child
		_check(bell != null and bell.bell == "kiln", "the Ember Bell rises in the Crucible")
		if bell:
			var view_top: float = game.camera.position.y - 216.0 / 2.0
			var below: float = room.position.y + bell.position.y + Room.TILE - view_top
			_check(below < DialogueBox.BOX.position.y - 4.0, "the talk box can't cover the Ember Bell or Wren ringing it")
			var bells_before := GameState.item_count("tidebell")
			await _scene_over(game)
			bell.interact()
			_check(GameState.has_flag(Tidebell.flag_for("kiln")) and GameState.item_count("tidebell") == bells_before + 1, "ringing the Ember Bell counts as a Tidebell")
			await _play_scene(game, 10.0)
		_check(_child_of(room, Doorway).size() == 1, "a way out opens after the fight")

	# The Chimney: two boulders seal the way down to the Annealing Oven.
	room = await _goto(game, Vector2i(23, 7), Vector2i(2, 6))
	await _calm(room)
	_check(_child_of(room, Boulder).size() == 2 and _child_of(room, DropHammer).size() == 4, "the Chimney has its hammers and boulders")
	player.global_position = _tile_pos(room, Vector2i(10, 10))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("stonebreaker")
	await _wait(0.5)
	_check(_child_of(room, Boulder).size() == 1, "the mallet opens the Chimney's floor")

	# The Annealing Oven: two pegs stand in the crate's one-tile channel;
	# with them down, Wren shoves it along and down onto the plate, and the
	# bars around the big key open.
	room = await _goto(game, Vector2i(23, 8), Vector2i(11, 1))
	await _calm(room)
	var oven_pegs: Array = _child_of(room, Peg)
	_check(oven_pegs.size() == 2, "two pegs stand in the Annealing Oven")
	var oven_crate: Crate = _child_of(room, Crate)[0]
	var oven_plate: PressurePlate = _child_of(room, PressurePlate)[0]
	# With the pegs still up, the crate stops at the first one.
	player.global_position = _tile_pos(room, Vector2i(4, 3))
	Input.action_press("move_right")
	await _wait(4.0)
	Input.action_release("move_right")
	_check(int(oven_crate.position.x) / Room.TILE == 9, "a standing peg stops the Oven's crate (at %s)" % oven_crate.position)
	for oven_peg: Peg in oven_pegs:
		var at := Vector2i(oven_peg.position / Room.TILE)
		player.global_position = _tile_pos(room, at + Vector2i(0, -1))
		player.facing = Vector2.DOWN
		await _wait(0.1)
		player.use_item("stonebreaker")
		await _wait(0.5)
		_check(oven_peg.down, "the mallet drives the Oven's peg at %s" % at)
	player.global_position = _tile_pos(room, Vector2i(8, 3))
	Input.action_press("move_right")
	await _wait(7.0)
	Input.action_release("move_right")
	_check(Vector2i(oven_crate.position / Room.TILE) == Vector2i(18, 3), "the crate runs the channel to its corner (at %s)" % oven_crate.position)
	player.global_position = _tile_pos(room, Vector2i(18, 2))
	Input.action_press("move_down")
	await _wait(5.0)
	Input.action_release("move_down")
	_check(oven_plate.pressed, "shoved down the chute, the crate weighs down the plate (at %s)" % oven_crate.position)
	_check(_child_of(room, Bars).all(func(b: Bars) -> bool: return b.is_open), "the plate opens the bars around the big key")
	_check(_child_of(room, Chest).any(func(c: Chest) -> bool: return c.item == "big_key"), "the Annealing Oven's chest holds the big key")

	# The Sprue: sealed with boulders off the Mould Store.
	room = await _goto(game, Vector2i(19, 9), Vector2i(22, 6))
	await _calm(room)
	_check(_child_of(room, Boulder).size() == 3, "three boulders seal the Sprue")

	# The Bellows Room shuts Wren in; clearing it shows the mallet's chest.
	GameState.inventory.erase("stonebreaker")
	GameState.item_slots = ["", ""]
	room = await _goto(game, Vector2i(20, 10), Vector2i(11, 6))
	await _wait(0.3)
	var shut: Array = _child_of(room, Bars)
	_check(shut.size() == 2 and shut.all(func(b: Bars) -> bool: return not b.is_open), "the Bellows Room's bars slam shut")
	var chest: Chest = _child_of(room, Chest)[0]
	for enemy in _child_of(room, Enemy):
		enemy.queue_free()
	await _wait(0.6)
	_check(chest.visible, "clearing the Bellows Room shows its chest")
	player.global_position = chest.global_position + Vector2(0, 14)
	player.facing = Vector2.UP
	await _wait(0.1)
	player.try_interact()
	_check(GameState.has_item("stonebreaker"), "the chest holds the Stonebreaker Mallet")
	await _wait(1.0)
	for child in game.get_children():
		if child is DialogueBox:
			while DialogueBox.is_open:
				child.advance()
				child.advance()
	game.queue_free()
	await _wait(0.1)


## The item model: giving, slots, equipment, jars, pearls, saving.
func _test_items() -> void:
	# Finding a tool names the key it's on, as bound now (remaps included).
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	var talk := Chest.item_talk("tide_hook")
	_check(talk.size() == 2 and talk[0] == "GOT_TIDE_HOOK_1" and MenuKit.key_name("item_1") in talk[1] and not "{" in talk[1],
		"the Tide Hook's words name its item key (%s)" % talk[1])
	GameState.assign_slot(1, "tide_hook")
	var bound := InputMap.action_get_events("item_2")
	InputMap.action_erase_events("item_2")
	var remapped := InputEventKey.new()
	remapped.physical_keycode = KEY_P
	InputMap.action_add_event("item_2", remapped)
	talk = Chest.item_talk("tide_hook")
	_check(talk[1].begins_with("Press P "), "a remapped item key is the one named (%s)" % talk[1])
	InputMap.action_erase_events("item_2")
	for event in bound:
		InputMap.action_add_event("item_2", event)
	GameState.give_item("divers_helm", 1, false)
	GameState.assign_slot(0, "")
	talk = Chest.item_talk("divers_helm")
	_check(MenuKit.key_name("attack") in talk[1] and (tr("ITEM_KEYS_EITHER") % [MenuKit.key_name("item_1"), MenuKit.key_name("item_2")]) in talk[1],
		"a tool on neither key names both, and the attack key too (%s)" % talk[1])
	GameState.reset_new_game()
	_check(GameState.has_item("driftwood_sword") and GameState.equipped_item(Items.SWORD) == "driftwood_sword",
		"a new file starts with the driftwood sword equipped")
	_check(GameState.item_slots == ["", ""], "item slots start empty")
	GameState.give_item("tide_hook")
	_check(GameState.item_slots[0] == "tide_hook", "a new tool goes to the first empty slot")
	GameState.give_item("puffer_bombs", 5)
	_check(GameState.item_slots[1] == "puffer_bombs" and GameState.item_count("puffer_bombs") == 5, "counted tools stack")
	GameState.give_item("puffer_bombs", 99)
	_check(GameState.item_count("puffer_bombs") == Items.max_count("puffer_bombs"), "counts stop at the max")
	_check(GameState.take_item("puffer_bombs", 3), "spending bombs")
	_check(not GameState.take_item("arrows"), "can't spend what you don't have")
	GameState.assign_slot(0, "puffer_bombs")
	_check(GameState.item_slots == ["puffer_bombs", "tide_hook"], "assigning a slotted tool swaps the slots")
	GameState.assign_slot(1, "echo_horn")
	_check(GameState.item_slots[1] == "tide_hook", "can't slot a tool you don't own")
	GameState.give_item("scaleweave")
	_check(GameState.equipped_item(Items.TUNIC) == "scaleweave", "a better tunic is put on")
	GameState.equip("oilskin")
	_check(GameState.equipped_item(Items.TUNIC) == "oilskin", "equip switches back")
	GameState.give_item("jar", 2)
	_check(GameState.jars == [Items.JAR_EMPTY, Items.JAR_EMPTY], "jars arrive empty")
	_check(GameState.fill_jar(Items.JAR_SPRITE) and GameState.jars[0] == Items.JAR_SPRITE, "a jar can hold a sea sprite")
	GameState.give_item("breath_pearl")
	_check(GameState.max_bubbles == GameState.START_BUBBLES + 1, "a Breath Pearl adds a bubble")
	GameState.give_item(Items.dungeon_item("hull", "map"))
	_check(GameState.has_dungeon_item("hull", "map") and not GameState.has_dungeon_item("hull", "compass"),
		"dungeon items belong to their dungeon")
	_check(Items.name_key("hull_map") == "ITEM_MAP", "dungeon items share one name")
	GameState.wake_tidestone(Vector2i(1, 0), Vector2(100, 120))
	GameState.play_time = 125.0
	SaveManager.save_game()
	GameState.reset_new_game()
	SaveManager.load_game()
	_check(GameState.item_slots == ["puffer_bombs", "tide_hook"], "load restores the item slots")
	_check(GameState.item_count("puffer_bombs") == 17, "load restores counts")
	_check(GameState.equipped_item(Items.TUNIC) == "oilskin", "load restores equipment")
	_check(GameState.jars == [Items.JAR_SPRITE, Items.JAR_EMPTY], "load restores jars")
	_check(GameState.tidestone_position(Vector2i(1, 0)) == Vector2(100, 120), "load restores woken Tidestones")
	_check(is_equal_approx(GameState.play_time, 125.0), "load restores play time")
	var summary := SaveManager.read_summary(TEST_SLOT)
	_check(int(summary.get("bubbles", 0)) == 6 and summary.has("saved_at"), "the save has a file-select summary")
	# A counted tool stays slotted when it runs out, also after loading.
	GameState.take_item("puffer_bombs", 17)
	SaveManager.save_game()
	SaveManager.load_game()
	_check(GameState.item_slots[0] == "puffer_bombs", "an empty counted tool stays slotted after loading")
	# Saves from before summaries still show their bubbles and place.
	var file := FileAccess.open(SaveManager.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string(JSON.stringify({"state": {"max_bubbles": 8, "checkpoint_room": [0, 0]}}))
	file.close()
	var old := SaveManager.read_summary(TEST_SLOT)
	_check(int(old.get("bubbles", 0)) == 8 and str(old.get("place", "")) != "", "old saves get a summary")
	# A gamepad button for Tab Next, which has no default button.
	# It has no button to give back, so it can't take one in use.
	_check(not Settings.rebind("tab_next", _pad_event(JOY_BUTTON_A)), "Tab Next can't take a button in use")
	Settings.rebind("tab_next", _pad_event(JOY_BUTTON_RIGHT_STICK))
	var has_button := false
	for event in InputMap.action_get_events("tab_next"):
		has_button = has_button or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_STICK)
	_check(has_button, "rebinding Tab Next to a free button works")
	Settings.pad_overrides.erase("tab_next")
	Settings.apply()
	# Taking a key another action uses swaps the two.
	var key_was := Settings.key_overrides.duplicate()
	var pad_was := Settings.pad_overrides.duplicate()
	var take_k := InputEventKey.new()
	take_k.physical_keycode = KEY_K
	Settings.rebind("attack", take_k)
	_check(Settings.main_key("attack") == KEY_K and Settings.main_key("interact") == KEY_J,
		"rebinding to a used key swaps the two actions")
	# The web page's touch buttons press the default keys: they're told
	# where each action went, with the label to show.
	var touch := Settings.touch_bindings()
	_check(touch.get("KeyJ") == ["KeyK", "K"] and touch.get("KeyK") == ["KeyJ", "J"] and touch.size() == 2,
		"touch buttons follow a swap (%s)" % str(touch))
	var take_semicolon := InputEventKey.new()
	take_semicolon.physical_keycode = KEY_SEMICOLON
	Settings.rebind("hum", take_semicolon)
	touch = Settings.touch_bindings()
	_check(touch.get("KeyH", [""])[0] == "Semicolon", "touch buttons follow a remap off the letters (%s)" % str(touch))
	_check(Settings.web_code(KEY_L) == "KeyL" and Settings.web_code(KEY_7) == "Digit7" and Settings.web_code(KEY_F2) == "F2"
		and Settings.web_code(KEY_ESCAPE) == "Escape", "keys have their web codes")
	Settings.rebind("item_1", _pad_event(JOY_BUTTON_Y))
	_check(Settings.main_button("item_1") == JOY_BUTTON_Y and Settings.main_button("item_2") == JOY_BUTTON_X,
		"rebinding to a used button swaps the two actions")
	var up_arrow := InputEventKey.new()
	up_arrow.physical_keycode = KEY_UP
	_check(not Settings.rebind("attack", up_arrow) and Settings.main_key("attack") == KEY_K,
		"an arrow key (always movement) can't be taken")
	var pause_k := InputEventKey.new()
	pause_k.physical_keycode = KEY_K
	_check(not Settings.rebind("pause", pause_k) and Settings.main_key("attack") == KEY_K,
		"a swap never moves Escape off Pause")
	Settings.key_overrides = key_was
	Settings.pad_overrides = pad_was
	Settings.apply()
	# Prompts follow the device in use.
	var pad_was_used := Settings.using_pad
	Settings.using_pad = true
	var pad_prompt := MenuKit.key_name("interact")
	Settings.using_pad = false
	var key_prompt := MenuKit.key_name("interact")
	Settings.using_pad = pad_was_used
	Settings.using_pad = true
	var tabs := "%s %s" % [MenuKit.key_name("tab_prev"), MenuKit.key_name("tab_next")]
	Settings.using_pad = pad_was_used
	_check(pad_prompt == "A" and key_prompt == "K", "prompts show pad buttons on a pad, keys on a keyboard (%s, %s)" % [pad_prompt, key_prompt])
	_check(tabs == "LB RT", "the menu tabs show their pad buttons (%s)" % tabs)
	# Prompts use the labels printed on the pad in use.
	_check(Settings.pad_style_for("Xbox Series Controller") == "xbox"
		and Settings.pad_style_for("PS5 Controller") == "playstation"
		and Settings.pad_style_for("DualSense Wireless Controller (STANDARD GAMEPAD Vendor: 054c Product: 0ce6)") == "playstation"
		and Settings.pad_style_for("Nintendo Switch Pro Controller") == "nintendo"
		and Settings.pad_style_for("Generic USB Gamepad") == "xbox", "pads are told apart by name")
	var style_was := Settings.pad_style
	Settings.using_pad = true
	var shown := {}
	for style in ["xbox", "playstation", "nintendo"]:
		Settings.pad_style = style
		shown[style] = "%s %s %s %s" % [MenuKit.key_name("interact"), MenuKit.key_name("attack"),
			MenuKit.key_name("tab_prev"), MenuKit.key_name("tab_next")]
	shown["controls"] = tr(ControlsPage.pad_text("interact"))
	Settings.pad_style = style_was
	Settings.using_pad = pad_was_used
	_check(shown["xbox"] == "A B LB RT" and shown["playstation"] == "✕ ○ L1 R2" and shown["nintendo"] == "B A L ZR",
		"prompts match an Xbox, PlayStation or Nintendo pad (%s)" % shown)
	_check(shown["controls"] == "B", "the controls page names the Nintendo button too (%s)" % shown["controls"])
	var game := Vector2(384, 216)
	_check(Settings.stretch_for(Vector2(844, 390), game) == Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		and Settings.stretch_for(Vector2(1152, 648), game) == Window.CONTENT_SCALE_STRETCH_INTEGER,
		"a phone-sized window scales the game to fit; a big one keeps whole pixels")
	for id: String in Items.DEFS:
		_check(tr(Items.name_key(id)) != Items.name_key(id), "item %s has a name" % id)
	SaveManager.delete_save()


## Every menu page opens, takes input and draws without errors.
func _test_menus() -> void:
	GameState.reset_new_game()
	_check(RoomInfo.has_room(Vector2i(0, 0)), "RoomInfo reads the rooms")
	_check(RoomInfo.stone_landing(Vector2i(1, 0)) != GameState.NO_POSITION or RoomInfo.get_room(Vector2i(1, 0))["stones"].is_empty(),
		"Tidestone landings come from the layout")
	# The options tab saves what it changes: keep the real settings file.
	var settings_path := ProjectSettings.globalize_path(Settings.PATH)
	var had_settings := FileAccess.file_exists(settings_path)
	var old_settings := FileAccess.get_file_as_string(settings_path) if had_settings else ""
	var pause := PauseMenu.new()
	add_child(pause)
	for tab in PauseMenu.TABS.size():
		pause.open(tab)
		for action: String in ["move_right", "move_down", "interact", "move_left", "move_up"]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = true
			pause._unhandled_input(event)
		await get_tree().process_frame
		_check(pause.visible and pause.current == tab, "pause tab %d opens" % tab)
	pause.close()
	_check(not get_tree().paused, "closing the pause menu unpauses")
	# Opening drops the menu in, and Tab Next slides the page; both settle.
	pause.open(PauseMenu.Tab.SATCHEL)
	_check(pause.offset.y < 0.0, "the pause menu drops in as it opens")
	var tab_next := InputEventAction.new()
	tab_next.action = "tab_next"
	tab_next.pressed = true
	pause._unhandled_input(tab_next)
	_check(pause._pages[PauseMenu.Tab.MAP].position.x > 0.0, "Tab Next slides the next page in from the right")
	await _wait(0.3)
	_check(pause.offset == Vector2.ZERO and pause._pages[PauseMenu.Tab.MAP].position == Vector2.ZERO
		and is_equal_approx(pause._pages[PauseMenu.Tab.MAP].modulate.a, 1.0), "the menu settles in place, fully shown")
	pause.close()
	pause.queue_free()
	if had_settings:
		var file := FileAccess.open(settings_path, FileAccess.WRITE)
		file.store_string(old_settings)
		file.close()
	else:
		DirAccess.remove_absolute(settings_path)
	Settings.load_settings()
	Settings.apply()
	var files := FileSelect.new()
	add_child(files)
	files.on_open()
	await get_tree().process_frame
	files.queue_free()
	await get_tree().process_frame


## A real key press or release, the way the keyboard sends it.
func _press_key(key: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	Input.parse_input_event(event)


func _pad_event(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


## Tiles reachable on foot from a tile, by flood fill over a room layout.
static func _walkable_from(rows: PackedStringArray, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := at + step
			if next.x < 0 or next.y < 0 or next.x >= Room.COLS or next.y >= Room.ROWS or seen.has(next):
				continue
			var tile := rows[next.y][next.x]
			if Room.is_solid(tile) or Prop.is_prop(tile) or tile in ["O", "C", "T"]:
				continue
			seen[next] = true
			queue.append(next)
	return seen


## Brinewood's Breath Pearl sits on an island in Heron Shallows that only
## the Tide Hook reaches: a reason to come back after the Rotting Hull.
func _test_brinewood_pearl() -> void:
	var scene := load("res://rooms/room_5_-1.tscn") as PackedScene
	var probe := scene.instantiate() as Room
	var rows := Room.parse_layout(probe.layout)
	_check(probe.chest_item == "breath_pearl", "Heron Shallows' chest holds a Breath Pearl")
	probe.free()
	var on_foot := _walkable_from(rows, Vector2i(0, 6))
	_check(not on_foot.has(Vector2i(12, 3)), "the pearl island can't be reached on foot")
	_check(on_foot.has(Vector2i(13, 7)), "the hook spot south of the island is reachable")

	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(5, -1), Vector2(13 * Room.TILE + 8, 7 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	var player: Player = game.player
	var room: Room = game.current_room
	GameState.give_item("tide_hook")
	player.facing = Vector2.UP
	await _wait(0.1)
	_check(player.use_item("tide_hook"), "Wren throws the hook at the island's post")
	await _wait(1.6)
	var local := player.global_position - room.global_position
	_check(local.y < 5 * Room.TILE, "the hook carries Wren onto the island (at %s)" % local)
	var chest: Chest = null
	for child in room.get_children():
		if child is Chest:
			chest = child
	_check(chest != null, "the island has a chest")
	if chest:
		var bubbles := GameState.max_bubbles
		player.global_position = chest.global_position + Vector2(0, 14)
		player.facing = Vector2.UP
		await _wait(0.1)
		_check(player.try_interact(), "Wren opens the pearl chest")
		_check(GameState.max_bubbles == bubbles + 1, "the Breath Pearl adds a bubble")
		await _wait(2.0)
		for child in game.get_children():
			if child is DialogueBox and DialogueBox.is_open:
				child.close()
		# And back again: the island has to have a way off.
		await _wait(0.3)
		player.global_position = room.global_position + Vector2(9 * Room.TILE + 8, 4 * Room.TILE + 12)
		player.facing = Vector2.DOWN
		await _wait(0.1)
		_check(player.use_item("tide_hook"), "Wren hooks the mainland post from the island")
		await _wait(1.6)
		# Feet rest against the post's base, so look just above them.
		var back := Vector2i((player.global_position - room.global_position - Vector2(0, 4)) / Room.TILE)
		_check(on_foot.has(back), "the hook brings Wren back to the shore (tile %s)" % back)
	game.queue_free()
	await _wait(0.1)


## Cinderreach: the Tide Hook gate at Ashfall Gate, the Slagbeetle's charge
## and flip, and a geyser's cycle.
func _test_cinderreach() -> void:
	var probe := (load("res://rooms/room_7_-2.tscn") as PackedScene).instantiate() as Room
	var rows := Room.parse_layout(probe.layout)
	probe.free()
	var on_foot := _walkable_from(rows, Vector2i(0, 6))
	_check(not on_foot.has(Vector2i(15, 6)), "Cinderreach is cut off by lava until the Tide Hook")
	var mouth := (load("res://rooms/room_10_-2.tscn") as PackedScene).instantiate() as Room
	_check(mouth.door_to == Vector2i(21, 10), "the Kiln's Mouth door points at the Kiln's entry room")
	if ResourceLoader.exists("res://rooms/room_21_10.tscn"):
		var kiln := Room.parse_layout(((load("res://rooms/room_21_10.tscn") as PackedScene).instantiate() as Room).layout)
		_check(not Room.is_solid(kiln[mouth.door_spawn.y][mouth.door_spawn.x]), "the Kiln's Mouth arrives on open floor")
	mouth.free()

	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(7, -2), Vector2(9 * Room.TILE + 8, 5 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	var player: Player = game.player
	var room: Room = game.current_room
	GameState.give_item("tide_hook")
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	_check(player.use_item("tide_hook"), "Wren hooks the post across the lava")
	await _wait(1.6)
	var local := player.global_position - room.global_position
	_check(local.x > 13 * Room.TILE, "the hook carries Wren over the lava (at %s)" % local)

	# Slagbeetle: shell blocks, cracks when lined up, charges, flips on a wall.
	var row_y := 8 * Room.TILE + 12
	var beetle := Slagbeetle.new()
	beetle.position = Vector2(15 * Room.TILE, row_y)
	room.add_child(beetle)
	player.global_position = room.global_position + Vector2(21 * Room.TILE, 2 * Room.TILE + 12)
	await _wait(0.2)
	_check(beetle.take_hit(1, Vector2.LEFT) == Enemy.HitResult.BLOCKED, "the slag shell turns the sword")
	await _wait(0.4)
	player.global_position = room.global_position + Vector2(21 * Room.TILE, row_y)
	var cracked := false
	for i in 20:
		await _wait(0.05)
		if beetle.mode == Slagbeetle.Mode.CRACK:
			cracked = true
			break
	_check(cracked, "the Slagbeetle cracks open when Wren lines up with it")
	# Step aside so it charges past into the wall.
	player.global_position = room.global_position + Vector2(18 * Room.TILE, 3 * Room.TILE + 12)
	var flipped := false
	for i in 40:
		await _wait(0.05)
		if beetle.is_flipped():
			flipped = true
			break
	_check(flipped, "a charging Slagbeetle flips when it hits a wall")
	_check(beetle.take_hit(1, Vector2.RIGHT) == Enemy.HitResult.HIT, "a flipped Slagbeetle can be hit")
	beetle.queue_free()
	GameState.refill()

	# Geyser: idle, hiss, blow, and the steam only hurts while blowing.
	var vent := Geyser.new()
	vent.position = Vector2(4 * Room.TILE, 3 * Room.TILE)
	room.add_child(vent)
	# Wren waits in the column, just above the cone.
	player.global_position = room.global_position + vent.position + Vector2(0, -12)
	GameState.refill()
	var steam_before := GameState.bubbles
	var seen_hiss := false
	var seen_blow := false
	var steam_safe := true
	for i in 80:
		await _wait(0.05)
		seen_hiss = seen_hiss or vent.phase == Geyser.Phase.HISS
		if not vent.is_blowing():
			steam_safe = steam_safe and not vent._steam.active
		if vent.is_blowing():
			seen_blow = seen_hiss
			break
	_check(seen_blow, "a geyser hisses before it blows")
	_check(steam_safe, "a geyser's steam is harmless until it blows")
	_check(vent._steam.active, "the blowing column is live")
	await _wait(0.3)
	_check(GameState.bubbles < steam_before, "the steam hurts Wren standing in the column")
	GameState.refill()
	var beetle_flip := Slagbeetle.new()
	beetle_flip.position = Vector2(4 * Room.TILE, 9 * Room.TILE)
	room.add_child(beetle_flip)
	await _wait(0.05)
	beetle_flip.mode = Slagbeetle.Mode.FLIPPED
	beetle_flip._timer = 5.0
	beetle_flip.take_hit(0, Vector2.LEFT)
	_check(beetle_flip.is_flipped(), "the Tide Hook doesn't right a flipped Slagbeetle")
	beetle_flip.queue_free()
	game.queue_free()
	await _wait(0.1)

## Every effect has a sound, captions follow the option, music picks a cue.
func _test_audio() -> void:
	for id: String in Audio.SFX:
		var stream := Audio.synth(Audio.SFX[id])
		_check(stream.data.size() > 100, "effect %s synthesises" % id)
		var caption := str(Audio.SFX[id].get("caption", ""))
		_check(caption == "" or tr(caption) != caption, "caption for %s is translated" % id)
	_check(Audio.cue_for_room("brinewood", "") == "region_brinewood", "rooms play their region's music")
	_check(Audio.cue_for_room("hull", "hull") == "dungeon_hull", "dungeon rooms play the dungeon's music")
	var heard: Array[String] = []
	var listen := func(key: String, _side: int) -> void: heard.append(key)
	Events.caption.connect(listen)
	var was := Settings.captions
	Settings.captions = true
	Audio.play_sfx("bell_ring")
	Settings.captions = false
	Audio._last_played.clear()
	Audio.play_sfx("bell_ring")
	Settings.captions = was
	Events.caption.disconnect(listen)
	_check(heard == ["CAPTION_BELL"], "captions show only when the option is on")
	var sides: Array[int] = []
	var listen_side := func(_key: String, side: int) -> void: sides.append(side)
	Events.caption.connect(listen_side)
	Settings.captions = true
	for at: Variant in [Vector2(-1000, 0), Vector2(100000, 0), null]:
		Audio._last_played.clear()
		Audio.play_sfx("bell_ring", at)
	Settings.captions = was
	Events.caption.disconnect(listen_side)
	_check(sides == [-1, 1, 0], "captions say which side a sound came from (%s)" % [sides])
	# High contrast outlines sprites that ask for one, only while it's on.
	var outlined := Art.sprite(Art.WREN, 6, 3, 22)
	outlined.set_meta("contrast", Palette.CONTRAST_WREN)
	var contrast_was := Settings.high_contrast
	Settings.high_contrast = true
	Art.set_flash(outlined, 0.0)
	var on: Color = (outlined.material as ShaderMaterial).get_shader_parameter("outline_color")
	Settings.high_contrast = false
	Art.set_flash(outlined, 0.0)
	var off: Color = (outlined.material as ShaderMaterial).get_shader_parameter("outline_color")
	Settings.high_contrast = contrast_was
	outlined.free()
	_check(on == Palette.CONTRAST_WREN and off.a == 0.0, "high contrast outlines Wren only when it's on")
	var shared_loop := (Audio._load(Audio.MUSIC_DIR, "region_saltmarrow") as AudioStreamOggVorbis).loop
	Audio.play_music("region_saltmarrow")
	_check(Audio.music_cue == "region_saltmarrow", "music cues switch")
	var playing: AudioStreamPlayer = Audio._music[Audio._music_index]
	var track := playing.stream as AudioStreamOggVorbis
	_check(track != null and track.loop, "region music loops")
	_check((Audio._load(Audio.MUSIC_DIR, "region_saltmarrow") as AudioStreamOggVorbis).loop == shared_loop, "looping doesn't change the shared track")
	for cue: String in Audio.MUSIC_CUES:
		if cue.begins_with("region_") or cue.begins_with("dungeon_") or cue.begins_with("bell_") or cue in ["title", "overworld", "boss", "miniboss", "credits", "lullaby"]:
			_check(Audio._load(Audio.MUSIC_DIR, cue) != null, "%s has a track" % cue)
	_check(Audio.BELL_ORDER.size() == 7 and Audio.BELL_ORDER.has("hull"), "the seven bells are in lullaby order")
	for bell: String in Tidebell.BELLS:
		_check(Audio.BELL_ORDER.has(bell), "the %s bell has a lullaby phrase" % bell)
	# A phrase rung while the track is still fading in dips it all the same.
	Audio.play_bell_phrase("kiln")
	var phrase := Audio._phrase.stream as AudioStreamPlaylist
	_check(Audio._phrase.playing and phrase != null and phrase.stream_count == 1 and phrase.get_list_stream(0).resource_path.ends_with("bell_2.ogg"), "ringing the Kiln's bell plays the lullaby's second phrase")
	await _wait(Audio.FADE_TIME + 0.3)
	_check(playing.playing and playing.volume_db < -15.0, "the music dips under a bell's phrase, even mid-fade (%.1f dB)" % playing.volume_db)
	# A new track while the phrase still rings comes in dipped too.
	Audio.play_music("dungeon_hull")
	await _wait(Audio.FADE_TIME + 0.3)
	var next: AudioStreamPlayer = Audio._music[Audio._music_index]
	_check(Audio._phrase.playing and next.playing and next.volume_db < -15.0, "a new track stays under the ringing phrase (%.1f dB)" % next.volume_db)
	_check(not playing.playing, "the old track fades out and stops")
	_check(phrase.get_list_stream(0).get_length() >= Audio.PHRASE_BEATS * 60.0 / Audio.LULLABY_BPM, "a phrase is at least three bars long, so it rings out in full")
	Audio.play_lullaby(3)
	phrase = Audio._phrase.stream as AudioStreamPlaylist
	_check(phrase.stream_count == 3 and not phrase.loop, "the lullaby plays the phrases learned so far, once")
	_check(int(phrase.get_list_stream(0).get("beat_count")) == Audio.PHRASE_BEATS and is_equal_approx(float(phrase.get_list_stream(0).get("bpm")), Audio.LULLABY_BPM) and int(phrase.get_list_stream(2).get("beat_count")) == 0, "in a run each phrase hands over after three bars, so phrases stay in time, and the last rings out")
	Audio._phrase.stop()
	Audio.stop_music(0.01)
	# The credits play once, as the soundtrack plan has them.
	Audio.play_music("credits", 0.01)
	var credits := Audio._music[Audio._music_index].stream as AudioStreamOggVorbis
	_check(credits != null and not credits.loop, "the credits music plays once")
	Audio.stop_music(0.01)
	# Every track the game asks for by name has a file: the flight, and the
	# last two bosses' own themes.
	for cue: String in ["story_flight", "credits", "title", CantorVael.MUSIC, DreamingHeart.MUSIC]:
		_check(Audio._load(Audio.MUSIC_DIR, cue) != null, "the %s track exists" % cue)
	# A room can have its own track, or none (only the ambience).
	_check(Audio.music_for_room("sunken_verge", "") == "region_sunken_verge"
		and Audio.music_for_room("sunken_verge", "", "none") == ""
		and Audio.music_for_room("sunken_verge", "", "story_flight") == "story_flight", "a room's own music overrides its region's")
	var shelf: Room = (load("res://rooms/room_1_4.tscn") as PackedScene).instantiate()
	var grotto: Room = (load("res://rooms/room_0_4.tscn") as PackedScene).instantiate()
	_check(shelf.music == "none" and grotto.music == "none", "the Ebb Shelf and Grotto have only the sea's sound")
	shelf.free()
	grotto.free()
	# Music in a hollow is muffled, and clears outside.
	Audio.play_music("region_brinewood", 0.01)
	await _wait(0.1)
	var open_db: float = Audio._music[Audio._music_index].volume_db
	Audio.set_muffled(true, 0.1)
	await _wait(0.3)
	var hollow_db: float = Audio._music[Audio._music_index].volume_db
	_check(Audio._low_pass != null and Audio._low_pass.cutoff_hz < 1000.0 and hollow_db < open_db - 4.0,
		"music in a hollow is quieter and dulled (%.1f to %.1f dB, %d Hz)" % [open_db, hollow_db, Audio._low_pass.cutoff_hz if Audio._low_pass else 0])
	Audio.set_muffled(false, 0.1)
	await _wait(0.3)
	_check(Audio._low_pass.cutoff_hz > 19000.0 and is_equal_approx(Audio._music[Audio._music_index].volume_db, open_db),
		"and clear again outside")
	Audio.stop_music(0.01)


## Gloamfen: the Lumen Pool is only reached by hooking across Stillwater
## Reach, and a Sporecap swells (the tell) before its spores burst.
func _test_gloamfen() -> void:
	var floors := {}
	for biome: String in Room.BIOMES:
		var tile: String = Room.BIOMES[biome]["floor"]
		_check(not floors.has(tile), "%s has its own floor tiles (not %s's)" % [biome, floors.get(tile, "")])
		floors[tile] = biome
	var gate := Room.parse_layout(((load("res://rooms/room_4_0.tscn") as PackedScene).instantiate() as Room).layout)
	_check(gate[11].substr(11, 2) == "YY" and gate[12].substr(11, 2) == "..", "Mallet boulders seal the way from Brinewood into Gloamfen")
	var edge := (load("res://rooms/room_5_2.tscn") as PackedScene).instantiate() as Room
	_check(edge.door_to == Vector2i(25, 10), "Mirelight Edge's doorway leads into the Lantern Mire")
	var edge_rows := Room.parse_layout(edge.layout)
	_check(edge_rows[1][11] == "D" and not Room.is_solid(edge_rows[2][11]), "the Mire doorway has open ground below it")
	edge.free()
	var reach := Room.parse_layout(((load("res://rooms/room_5_1.tscn") as PackedScene).instantiate() as Room).layout)
	var on_foot := _walkable_from(reach, Vector2i(0, 6))
	_check(not on_foot.has(Vector2i(23, 5)), "Stillwater Reach's far bank needs the Tide Hook")
	_check(on_foot.has(Vector2i(9, 5)), "the hook spot facing the far post is reachable")
	var back := _walkable_from(reach, Vector2i(23, 5))
	_check(back.has(Vector2i(13, 7)), "the return hook spot facing the near post is reachable")

	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(4, 1), Vector2(11 * Room.TILE + 8, 1 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	var room: Room = game.current_room
	var player: Player = game.player
	_check(room.biome == "gloamfen", "Fenmouth is in Gloamfen")
	player.global_position = room.global_position + Vector2(20 * Room.TILE, 6 * Room.TILE + 12)
	var cap := Sporecap.new()
	cap.position = Vector2(4 * Room.TILE + 8, 6 * Room.TILE + 12)
	room.add_child(cap)
	await _wait(0.3)
	_check(cap.mode == Sporecap.Mode.WANDER, "a Sporecap ignores Wren from afar")
	cap.position = Vector2(4 * Room.TILE + 8, 6 * Room.TILE + 12)
	# Wren stands still inside the ring the whole time.
	player.global_position = room.global_position + cap.position + Vector2(16, 0)
	GameState.refill()
	var before := GameState.bubbles
	var swelled := false
	var burst_after_swell := false
	for i in 40:
		await _wait(0.05)
		swelled = swelled or cap.mode == Sporecap.Mode.SWELL
		if cap.is_bursting():
			burst_after_swell = swelled
			break
	_check(burst_after_swell, "a Sporecap swells before it bursts")
	await _wait(0.2)
	_check(GameState.bubbles < before, "the spores hurt Wren standing inside the ring")
	player.global_position = room.global_position + Vector2(20 * Room.TILE, 6 * Room.TILE + 12)
	var spent := false
	for i in 30:
		await _wait(0.05)
		if cap.is_spent():
			spent = true
			break
	_check(spent and not cap._cloud.active, "a spent Sporecap is harmless")
	_check(cap.take_hit(1, Vector2.LEFT) == Enemy.HitResult.HIT, "a spent Sporecap can be hit")
	var cap2 := Sporecap.new()
	cap2.position = Vector2(4 * Room.TILE + 8, 9 * Room.TILE + 12)
	room.add_child(cap2)
	await _wait(0.1)
	cap2.take_hit(1, Vector2.LEFT)
	_check(cap2.mode == Sporecap.Mode.SWELL, "a struck Sporecap swells (its tell) rather than bursting at once")
	_check(cap2.take_hit(0, Vector2.LEFT) == Enemy.HitResult.IGNORED, "the Tide Hook's tug doesn't set off a Sporecap")
	cap2.queue_free()
	cap.queue_free()
	game.queue_free()
	await _wait(0.1)

func _test_fast_travel() -> void:
	GameState.reset_new_game()
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	Engine.time_scale = 3.0
	var wren: Player = game.player
	game._on_fast_travel(Vector2i.ZERO)
	await _wait(0.1)
	_check(game.busy and wren.frozen, "Wren waits while Mantle swoops in")
	await _wait(0.3)
	_check(not is_instance_valid(wren) or not wren.visible, "Mantle carries Wren off")
	var flight: FlightScene = null
	for i in 20:
		await _wait(0.1)
		for child in game.get_children():
			if child is FlightScene:
				flight = child
		if flight:
			break
	_check(flight != null, "the flight over the sea plays")
	await _wait(1.6)
	var arrived := false
	for i in 30:
		await _wait(0.1)
		if game.player and game.player.visible and not game.player.frozen and not game.busy:
			arrived = true
			break
	_check(arrived, "Mantle sets Wren down and play resumes")
	_check(GameState.room_coord == Vector2i.ZERO, "fast travel lands at the chosen Tidestone")
	Engine.time_scale = 1.0
	game.queue_free()
	await _wait(0.1)


## The HUD's corner panels fade while Wren is under them, and come back.
func _test_hud_fade() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(0, -1), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var hud: Hud = null
	var slots: ItemSlotsHud = null
	for child in game.get_children():
		if child is Hud:
			hud = child
		elif child is ItemSlotsHud:
			slots = child
	var player: Player = game.player
	var room_at: Vector2 = game.current_room.global_position
	player.global_position = room_at + Vector2(240, 120)
	await _wait(0.4)
	_check(is_equal_approx(hud._gauge.modulate.a, 1.0) and is_equal_approx(slots._canvas.modulate.a, 1.0),
		"the HUD is solid with nothing under it")
	player.global_position = room_at + Vector2(20, 14)
	await _wait(0.4)
	_check(hud._gauge.modulate.a < 0.5 and is_equal_approx(slots._canvas.modulate.a, 1.0),
		"the breath plate fades while Wren is under it (%.2f)" % hud._gauge.modulate.a)
	player.global_position = room_at + Vector2(370, 14)
	await _wait(0.4)
	_check(hud._gauge.modulate.a > 0.9 and slots._canvas.modulate.a < 0.5,
		"the item slots fade instead when Wren moves under them")
	game.queue_free()
	await get_tree().process_frame
	GameState.reset_new_game()


## The talk key (the phone's on-screen confirm button) picks a title item,
## like Enter does.
func _test_title_talk_key() -> void:
	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	add_child(title)
	var until := Time.get_ticks_msec() + 8000
	while get_viewport().gui_get_focus_owner() == null and Time.get_ticks_msec() < until:
		await get_tree().process_frame
	# Journeys, whether or not Continue is showing.
	(title._menu.get_child(1) as Button).grab_focus()
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _wait(0.2)
	_check(title._page == title._files, "the talk key opens Journeys on the title")
	title._leaving = true
	title.queue_free()
	await get_tree().process_frame


func _test_credits() -> void:
	var credits: Control = (load("res://scenes/credits.tscn") as PackedScene).instantiate()
	add_child(credits)
	await _wait(0.3)
	_check(credits._scroll > 0.0, "the credits roll")
	_check(credits._height > 216.0, "the credits have something to roll")
	for key in ["CREDITS_DIRECTION", "CREDITS_END", "MENU_CREDITS", "GAMEOVER_WAKE"]:
		_check(tr(key) != key, "%s is translated" % key)
	_check(credits._vignette_count() == 0, "before the ending, the credits show no epilogue scenes")
	var plain_height: float = credits._height
	# Leaving would change scene and end the test: don't let it.
	credits._leaving = true
	credits.queue_free()
	await _wait(0.1)
	GameState.set_flag(StoryDirector.ENDING_FLAG)
	var after: Control = (load("res://scenes/credits.tscn") as PackedScene).instantiate()
	add_child(after)
	await _wait(0.2)
	_check(after._vignette_count() == CreditsVignettes.KINDS.size(), "after the ending, the epilogue's scenes come between the names")
	_check(after._height > plain_height, "and the roll makes room for them")
	# The credits music plays once, so the roll ends before it does.
	var music_length: float = Audio._load(Audio.MUSIC_DIR, "credits").get_length()
	_check((after._height / after._speed <= music_length + 0.05 or after._speed == after.SPEED * after.MAX_SPEED_UP) and after._speed >= after.SPEED,
		"the roll (%.0f s) ends before the credits music (%.0f s)" % [after._height / after._speed, music_length])
	print("credits roll %.1f s at %.1f px/s (plain %.1f s); music %.1f s" % [after._height / after._speed, after._speed, plain_height / after.SPEED, music_length])
	after._leaving = true
	after.queue_free()
	await _wait(0.1)
	GameState.clear_flag(StoryDirector.ENDING_FLAG)
## Saltmarrow side quests: Pell's three-clawed crab (a Breath Pearl) and
## Marga's smoked eel after the Hull (a jar).
func _test_side_quests() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(1, 0), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var crab: QuestCrab = null
	for child in game.current_room.get_children():
		if child is QuestCrab:
			crab = child
	_check(crab != null, "the three-clawed crab lives in the Tidepools")
	if crab == null:
		game.queue_free()
		return
	_check(not crab.visible and not crab.is_in_group("interactable"), "the crab hides until Pell asks for it")
	GameState.set_flag("met_hessa")
	Conversations.talk("pell")
	_finish_talk(game)
	_check(GameState.has_flag("talked_pell_quest") and crab.visible, "Pell's ask brings the crab out")
	var player: Player = game.player
	player.global_position = crab.global_position + Vector2(0, 12)
	player.facing = Vector2.UP
	await _wait(0.1)
	_check(player.try_interact() and GameState.has_flag("found_crab"), "Wren picks up the crab")
	_finish_talk(game)
	_check(not crab.visible, "the crab is gone once caught")
	var bubbles := GameState.max_bubbles
	var shown := Conversations.talk("pell")
	_finish_talk(game)
	_check(shown.size() == 3 and shown[0]["text"] == "PELL_CRAB_1", "Pell thanks Wren for the crab")
	_check(GameState.item_count("breath_pearl") == 1 and GameState.max_bubbles == bubbles + 1, "Pell's pearl adds a breath bubble")
	Conversations.talk("pell")
	_finish_talk(game)
	_check(GameState.item_count("breath_pearl") == 1, "Pell only gives one pearl")
	_check(Conversations.branch_for("pell")["lines"][0] == "PELL_CRAB_AGAIN", "Pell talks about the crab afterwards")

	# Marga feeds Wren after the Hull and gives them a jar.
	for flag in ["asked_for_rope", "rope_promised", "marga_thanked"]:
		GameState.set_flag(flag)
	_check(Conversations.branch_for("marga")["lines"][0] == "MARGA_AGAIN", "Marga waits for Wren to come back")
	GameState.set_flag("tidebell_hull")
	Conversations.talk("marga")
	_finish_talk(game)
	_check(GameState.item_count("jar") == 1 and GameState.jars.size() == 1, "Marga gives Wren a jar")
	Conversations.talk("marga")
	_finish_talk(game)
	_check(GameState.item_count("jar") == 1, "Marga only gives one jar")

	# Nettle learns the lamp signals once Wren has met Hessa.
	GameState.reset_new_game()
	_check(Conversations.branch_for("nettle")["lines"][0] == "NETTLE_1", "Nettle wants to come along at first")
	GameState.set_flag("met_hessa")
	Conversations.talk("nettle")
	_finish_talk(game)
	_check(GameState.has_flag("nettle_learned"), "Wren teaches Nettle the long glow")
	_check(Conversations.branch_for("nettle")["lines"][0] == "NETTLE_AGAIN", "Nettle practises afterwards")
	game.queue_free()
	await _wait(0.1)

	# Agna Holt waits outside the Kiln, and forges Wren a sword after the Ember Bell.
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(10, -2), GameState.NO_POSITION)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var agna: Npc = null
	for child in game.current_room.get_children():
		if child is Npc and child.kind == "agna":
			agna = child
	_check(agna != null, "Agna Holt stands at the Kiln's Mouth")
	if agna:
		var feet: float = agna.get_global_transform_with_canvas().origin.y
		_check(feet + Room.TILE < DialogueBox.HIGHEST_POINT, "Agna and Wren stay clear of the dialogue box")
	GameState.set_flag("entered_kiln")
	_check(Conversations.branch_for("agna")["lines"][0] == "AGNA_1", "Agna introduces herself even after Wren has been inside")
	Conversations.talk("agna")
	_finish_talk(game)
	_check(GameState.has_flag("met_agna"), "Agna introduces the Kiln")
	_check(Conversations.branch_for("agna")["lines"][0] == "AGNA_KILN_1", "Agna knows Wren has been inside")
	GameState.set_flag("tidebell_kiln")
	Conversations.talk("agna")
	_finish_talk(game)
	_check(GameState.has_item("brinesteel_sword") and GameState.equipped.get("sword", "") == "brinesteel_sword", "Agna's Brinesteel sword is put on")
	Conversations.talk("agna")
	_finish_talk(game)
	_check(Conversations.branch_for("agna")["lines"][0] == "AGNA_SMITH", "Agna only forges one sword")
	game.queue_free()
	await _wait(0.1)


func _test_text_fit() -> void:
	var canvas := Control.new()
	add_child(canvas)
	var long := "A very long line of text that cannot possibly fit in forty pixels"
	var cut := MenuKit.fit(canvas, long, 40.0)
	_check(cut.ends_with("..") and MenuKit.text_width(canvas, cut) <= 40.0, "long text is cut to fit its box")
	_check(MenuKit.fit(canvas, "Hi", 40.0) == "Hi", "short text is left alone")
	_check(Settings.languages()[0] == "en", "English is the first language")
	for key: String in Settings.language_keys():
		_check(tr(key) != key, "%s names its language" % key)
	canvas.queue_free()


## Windmere Heights: gusts pulse (a rising tell, then a shove), carry Wren
## and the Tumbleburrs downwind, and the chasm at Gullwatch Steps can't be
## walked across.
func _test_windmere() -> void:
	var steps := Room.parse_layout(((load("res://rooms/room_3_-3.tscn") as PackedScene).instantiate() as Room).layout)
	# In the dark its veiled planks are only water; the Glowmoth Lantern
	# shows them, a way across.
	var dark := PackedStringArray()
	var lit := PackedStringArray()
	for row in steps:
		dark.append(row.replace("v", "~"))
		lit.append(row.replace("v", "."))
	_check(not _walkable_from(dark, Vector2i(8, 12)).has(Vector2i(8, 3)), "the Gullwatch chasm can't be crossed on foot")
	_check(steps[5].contains("v") and _walkable_from(lit, Vector2i(8, 12)).has(Vector2i(8, 3)), "lantern planks bridge the Gullwatch chasm")
	# The way west to Frostspine is over a sea inlet: a Kite Cloak glide, not a walk.
	_check(not _walkable_from(lit, Vector2i(8, 3)).has(Vector2i(0, 3)), "the inlet below Frostspine can't be walked across")
	_check(steps[3].substr(2, 3) == "~~~" and _walkable_from(lit, Vector2i(1, 3)).has(Vector2i(0, 3)), "a three-tile inlet to glide over, with a landing on the far side")

	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(4, -3), Vector2(11 * Room.TILE + 8, 1 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	var room: Room = game.current_room
	var player: Player = game.player
	var gust := room.get_node_or_null("Gust") as Gust
	_check(gust != null and gust.wind.x > 0.0, "Mill Row has an eastward wind")
	if gust == null:
		game.queue_free()
		return
	var burr := Tumbleburr.new()
	burr.position = Vector2(8 * Room.TILE, 3 * Room.TILE + 12)
	room.add_child(burr)
	player.global_position = room.global_position + Vector2(4 * Room.TILE, 6 * Room.TILE + 12)
	var rose_first := false
	var seen_rise := false
	for i in 120:
		await _wait(0.05)
		seen_rise = seen_rise or gust.phase == Gust.Phase.RISING
		if gust.is_blowing():
			rose_first = seen_rise
			break
	_check(rose_first, "the wind rises (the tell) before it gusts")
	var wren_x := player.global_position.x
	var burr_x := burr.global_position.x
	await _wait(0.8)
	_check(player.global_position.x > wren_x + 10.0, "a gust shoves Wren downwind")
	_check(burr.global_position.x > burr_x + 10.0, "a gust bowls a Tumbleburr downwind")
	_check(burr.take_hit(1, Vector2.LEFT) == Enemy.HitResult.HIT, "one cut scatters a Tumbleburr")
	var mill: Prop = null
	for child in room.get_children():
		if child is Prop and child.kind == "J":
			mill = child
	var turned := false
	if mill != null:
		var first := mill._sprite.frame
		for i in 10:
			await _wait(0.05)
			turned = turned or mill._sprite.frame != first
	_check(turned, "Mill Row's windmills turn")
	# A gust can't bowl a burr out through an exit and off the map.
	var stray := Tumbleburr.new()
	stray.position = Vector2(22 * Room.TILE, 6 * Room.TILE + 12)
	room.add_child(stray)
	for i in 60:
		await _wait(0.05)
	_check(Rect2(Vector2.ZERO, Room.SIZE).has_point(stray.position), "a Tumbleburr stays in its own room (at %s)" % stray.position)
	stray.queue_free()
	game.queue_free()
	await _wait(0.1)


## Frostspine: Wren keeps sliding on slick ice after letting go, and a
## Sledgeseal rears (its tell) before it toboggans, glancing off blows to
## its face while it slides.
func _test_frostspine() -> void:
	# The overworld's x (ice) and q (Sporecap) mean a wisp and a Shade in a
	# dungeon.
	var hollow: Room = (load("res://rooms/room_24_8.tscn") as PackedScene).instantiate()
	add_child(hollow)
	_check(_child_of(hollow, Wisp).size() > 0 and _child_of(hollow, Shade).size() > 0, "Mire rooms still spawn wisps and Shades")
	_check(_child_of(hollow, Sporecap).is_empty() and not hollow.has_node("IceField"), "Mire rooms get no Sporecaps or slick ice")
	hollow.queue_free()
	var foot_room: Room = (load("res://rooms/room_0_-3.tscn") as PackedScene).instantiate()
	var foot := Room.parse_layout(foot_room.layout)
	_check(foot_room.door_to == Vector2i(32, 10) and foot[1][11] == "D" and _walkable_from(foot, Vector2i(23, 3)).has(Vector2i(11, 2)), "Glacier Foot's doorway leads into the Hollow Glacier")
	foot_room.free()
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(1, -3), Vector2(4 * Room.TILE + 8, 5 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	var room: Room = game.current_room
	var player: Player = game.player
	var ice := room.get_node_or_null("IceField") as IceField
	_check(ice != null, "Frostbite Shelf has slick ice")
	if ice != null:
		# Run onto the ice heading right, then let go.
		player.global_position = room.global_position + Vector2(10 * Room.TILE + 8, 6 * Room.TILE + 8)
		ice.momentum = Vector2(Player.SPEED, 0)
		var start_x := player.global_position.x
		await _wait(0.4)
		_check(player.global_position.x > start_x + 12.0, "Wren keeps sliding on the ice with no input (moved %.1f)" % (player.global_position.x - start_x))
		# Off the ice, Wren stops at once.
		player.global_position = room.global_position + Vector2(4 * Room.TILE + 8, 3 * Room.TILE + 12)
		await _wait(0.1)
		ice.momentum = Vector2(90, 0)
		var still := player.global_position
		await _wait(0.3)
		_check(player.global_position.distance_to(still) < 1.0, "on snow Wren has their footing")
	var seal := Sledgeseal.new()
	seal.position = Vector2(4 * Room.TILE, 9 * Room.TILE - 4)
	room.add_child(seal)
	player.global_position = room.global_position + Vector2(11 * Room.TILE, 9 * Room.TILE - 4)
	var reared := false
	var slid_after := false
	for i in 40:
		await _wait(0.05)
		reared = reared or seal.mode == Sledgeseal.Mode.REAR
		if seal.is_sliding():
			slid_after = reared
			break
	_check(slid_after, "a Sledgeseal rears before it slides")
	if seal.is_sliding():
		_check(seal.take_hit(1, Vector2.LEFT) == Enemy.HitResult.BLOCKED, "a blow to a sliding seal's face glances off")
		_check(seal.take_hit(1, Vector2.DOWN) == Enemy.HitResult.HIT, "its flank can be struck")
	seal.queue_free()
	# A slide toward an open exit (row 6 runs out east) pulls up at the edge.
	var runaway := Sledgeseal.new()
	runaway.position = Vector2(18 * Room.TILE, 6 * Room.TILE + 8)
	room.add_child(runaway)
	player.global_position = room.global_position + Vector2(2 * Room.TILE, 3 * Room.TILE + 12)
	await _wait(0.1)
	runaway.mode = Sledgeseal.Mode.SLIDE
	runaway._direction = Vector2.RIGHT
	runaway._timer = Sledgeseal.SLIDE_MAX
	await _wait(1.0)
	_check(Rect2(Vector2.ZERO, Room.SIZE).has_point(runaway.position) and runaway.mode != Sledgeseal.Mode.SLIDE, "a Sledgeseal can't slide out of its room (at %s)" % runaway.position)
	runaway.queue_free()
	GameState.refill()
	game.queue_free()
	await _wait(0.1)


## The Sunken Verge: the frozen-channel entrance, the tide that floods the
## flats, and Siltrays.
func _test_verge() -> void:
	# Causeway End: the channel can't be crossed on foot, but six frozen
	# tiles (Frostfang arrows) make a way over. Six rows of water is more
	# than a Kite Cloak glide carries.
	var causeway: Room = (load("res://rooms/room_1_2.tscn") as PackedScene).instantiate()
	# Until the Old One turns (the Gale Bell), the Verge is still under the sea.
	var drowned := Room.parse_layout(causeway.layout)
	var rows := Room.parse_layout(causeway.alt_layout)
	_check(causeway.alt_flag == "old_one_turned" and not causeway.layout.contains("r") and rows[9].contains("r"), "the Verge's flats only rise once the Old One turns")
	causeway.free()
	_check(drowned[5].count("~") == Room.COLS - 2 and drowned[9].count("Q") == Room.COLS - 4, "before the turn Causeway End is open sea, deep past the shallows")
	_check(not _walkable_from(rows, Vector2i(11, 1)).has(Vector2i(2, 10)), "the Causeway End channel can't be crossed on foot")
	var frozen := rows.duplicate()
	for y in range(3, 9):
		_check(rows[y][7] == "~", "the channel is water on row %d" % y)
		frozen[y] = frozen[y].substr(0, 7) + "." + frozen[y].substr(8)
	_check(_walkable_from(frozen, Vector2i(11, 1)).has(Vector2i(2, 10)), "a line of frozen tiles bridges the channel")
	var square: Room = (load("res://rooms/room_1_3.tscn") as PackedScene).instantiate()
	_check(square.door_to == Vector2i(36, 10) and Room.parse_layout(square.layout)[7][12] == "D", "Belfry Square's doorway leads into the Drowned Belfry")
	square.free()

	GameState.reset_new_game()
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	GameState.set_checkpoint(Vector2i(0, 2), Vector2(6 * Room.TILE + 8, 7 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var room: Room = game.current_room
	var player: Player = game.player
	await _calm(room)
	var tide := room.get_node_or_null("Tide") as Tide
	_check(tide != null, "Cockle Flats has a tide")
	if tide == null:
		Tide.offset = 0.0
		game.queue_free()
		return
	# Low tide: the flats are sand to walk on.
	player.global_position = _tile_pos(room, Vector2i(9, 8))
	await _wait(0.3)
	_check(not tide.is_flooded(Vector2i(9, 8)) and player.global_position.distance_to(_tile_pos(room, Vector2i(9, 8))) < 4.0, "at low tide Wren can stand on the flats")
	# It floods from the sea inward: the tell.
	Tide.offset = Tide.offset_for(Tide.Phase.RISING, Tide.RISING_TIME * 0.3)
	await _wait(0.1)
	_check(tide.cover(Vector2i(2, 4)) > tide.cover(Vector2i(9, 4)), "the tide reaches the flats by the sea first")
	# Paused, the tide holds still.
	var held := Tide.clock()
	get_tree().paused = true
	await get_tree().create_timer(0.3, true).timeout
	get_tree().paused = false
	_check(absf(Tide.clock() - held) < 0.1, "the tide doesn't run while the game is paused")
	# High tide: whoever is still out there is swept back and loses a breath.
	GameState.refill()
	var breath := GameState.bubbles
	Tide.offset = Tide.offset_for(Tide.Phase.HIGH, 0.2)
	await _wait(0.2)
	var at := player.global_position - room.global_position
	var tile := Vector2i(floori(at.x / Room.TILE), floori(at.y / Room.TILE))
	var landed := room.tile_at(tile.x, tile.y)
	_check(Rect2i(0, 0, Room.COLS, Room.ROWS).has_point(tile) and not Tide.is_flat(landed) and not Room.is_solid(landed) and not Prop.is_prop(landed), "the flood sweeps Wren off the flats onto open ground (to %s)" % tile)
	_check(GameState.bubbles < breath, "being swept costs a breath")
	# And the flooded flats block the way.
	await _wait(1.2)
	GameState.refill()
	player.global_position = _tile_pos(room, Vector2i(7, 8))
	Input.action_press("move_right")
	await _wait(0.5)
	Input.action_release("move_right")
	_check(player.global_position.x - room.global_position.x < 8 * Room.TILE, "Wren can't walk into the flood")
	# A Siltray under the water can't be cut; it rears before it leaps.
	var ray := Siltray.new()
	ray.position = Vector2(9 * Room.TILE + 8, 5 * Room.TILE + 12)
	room.add_child(ray)
	await _wait(0.05)
	_check(ray.mode == Siltray.Mode.SWIM and not ray._contact.active, "a Siltray placed in the flood starts swimming, harmless")
	_check(ray.take_hit(1, Vector2.UP) == Enemy.HitResult.IGNORED, "a swimming Siltray can't be cut")
	player.global_position = _tile_pos(room, Vector2i(8, 6))
	var reared := false
	var leapt_after := false
	for i in 30:
		await _wait(0.05)
		reared = reared or ray.mode == Siltray.Mode.REAR
		if ray.mode == Siltray.Mode.LEAP:
			leapt_after = reared
			break
	_check(leapt_after, "a Siltray's fin rears before it leaps")
	ray.queue_free()
	# When the tide goes out it's stranded, and the sword finds it.
	var stranded := Siltray.new()
	stranded.position = Vector2(12 * Room.TILE + 8, 5 * Room.TILE + 12)
	room.add_child(stranded)
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	await _wait(0.3)
	_check(stranded.mode == Siltray.Mode.STRANDED and stranded.take_hit(1, Vector2.UP) == Enemy.HitResult.HIT, "at low tide a Siltray is stranded and can be struck")
	stranded.queue_free()
	Tide.offset = 0.0
	GameState.refill()
	game.queue_free()
	await _wait(0.1)


## The Ossuary Dunes: sealed off by the sea strait, sinking sand, Dunejaws.
func _test_ossuary() -> void:
	# Tangle Shore's sea runs east into the Bleached Strand: no way over
	# on foot (the Diver's Helm's job).
	var strand: Room = (load("res://rooms/room_7_0.tscn") as PackedScene).instantiate()
	var deep := Room.parse_layout(strand.layout)
	strand.free()
	# Without the Diver's Helm, deep water (Q) is as closed as the sea.
	var rows := PackedStringArray()
	for row in deep:
		rows.append(row.replace("Q", "~"))
	_check(deep[9][0] == "Q" and deep[8][3] == "Q" and not _walkable_from(rows, Vector2i(11, 12)).has(Vector2i(0, 9)), "the Ossuary's west shore is deep water")
	# With the Helm the strait is a way through, shore to shore.
	var swum := PackedStringArray()
	for row in deep:
		swum.append(row.replace("Q", "."))
	var tangle: Room = (load("res://rooms/room_6_0.tscn") as PackedScene).instantiate()
	var shore := PackedStringArray()
	for row in Room.parse_layout(tangle.layout):
		shore.append(row.replace("Q", "."))
	tangle.free()
	_check(_walkable_from(swum, Vector2i(11, 12)).has(Vector2i(0, 9)) and _walkable_from(shore, Vector2i(11, 1)).has(Vector2i(23, 9)), "the Diver's Helm swims the strait from Tangle Shore into the dunes")
	var rise: Room = (load("res://rooms/room_9_0.tscn") as PackedScene).instantiate()
	_check(rise.door_to == Vector2i(40, 10) and Room.parse_layout(rise.layout)[7][16] == "D", "the hollow in the whale skull's side leads into the Marrow Tomb")
	rise.free()

	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(7, 1), Vector2(11 * Room.TILE + 8, 1 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var room: Room = game.current_room
	var player: Player = game.player
	await _calm(room)
	var sink := room.get_node_or_null("SinkField") as SinkField
	_check(sink != null, "Sinksand Basin has sinking sand")
	if sink == null:
		game.queue_free()
		return
	# Standing still on the edge of a patch, Wren is dragged in and
	# swallowed, then comes back up on firm ground a breath down.
	player.global_position = _tile_pos(room, Vector2i(10, 5))
	await _wait(0.3)
	GameState.refill()
	var breath := GameState.bubbles
	var middle := sink.middle_at(Vector2(8 * Room.TILE + 8, 3 * Room.TILE + 8))
	player.global_position = room.global_position + middle + Vector2(Room.TILE + 4, 0)
	var start := player.global_position
	await _wait(0.25)
	_check(player.global_position.distance_to(room.global_position + middle) < start.distance_to(room.global_position + middle), "sinking sand drags Wren toward its middle")
	await _wait(1.2)
	var local := player.global_position - room.global_position
	_check(not sink.is_sand(local) and GameState.bubbles < breath, "the sand swallows Wren and they come back up on firm ground (at %s)" % local)
	# Walking away gets them out.
	GameState.refill()
	await _wait(1.2)
	player.global_position = room.global_position + middle - Vector2(Room.TILE + 4, 0)
	Input.action_press("move_left")
	await _wait(0.9)
	Input.action_release("move_left")
	_check(not sink.is_sand(player.global_position - room.global_position), "Wren can walk out of the sinking sand (at %s, state %s)" % [player.global_position - room.global_position, player.state])
	# A Dunejaw can't be cut under the sand; it spouts before it bites.
	var jaw := Dunejaw.new()
	jaw.position = Vector2(11 * Room.TILE + 8, 9 * Room.TILE + 12)
	room.add_child(jaw)
	player.global_position = _tile_pos(room, Vector2i(14, 9))
	await _wait(0.1)
	_check(jaw.take_hit(1, Vector2.LEFT) == Enemy.HitResult.IGNORED, "a buried Dunejaw can't be cut")
	var spouted := false
	var bit_after := false
	for i in 60:
		await _wait(0.05)
		GameState.refill()
		spouted = spouted or jaw.mode == Dunejaw.Mode.SPOUT
		if jaw.mode == Dunejaw.Mode.BITE:
			bit_after = spouted
			break
	_check(bit_after, "a Dunejaw spouts sand before it bites")
	_check(jaw.global_position.distance_to(player.global_position) < 12.0, "a Dunejaw comes up right under Wren")
	for i in 20:
		await _wait(0.05)
		if jaw.mode == Dunejaw.Mode.EXPOSED:
			break
	_check(jaw.mode == Dunejaw.Mode.EXPOSED and jaw.take_hit(1, Vector2.LEFT) == Enemy.HitResult.HIT, "after it bites, a Dunejaw lies exposed to the sword")
	jaw.queue_free()
	GameState.refill()
	game.queue_free()
	await _wait(0.1)


## Ambient life: gulls, fish and crabs on the shore, never in the way, and
## crabs scuttle off when Wren comes close.
func _test_ambience() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(0, 0), Vector2(11 * Room.TILE + 8, 6 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var room: Room = game.current_room
	var life := room.get_node_or_null("Ambience") as Ambience
	_check(life != null, "overworld rooms have ambient life")
	if life == null:
		game.queue_free()
		return
	_check(life.gulls.size() > 0 and life.crabs.size() > 0, "Saltmarrow has gulls and crabs")
	var solid := false
	for node in life.find_children("*", "CollisionObject2D", true, false):
		solid = true
	_check(not solid, "ambient life has nothing to bump into")
	# Walk Wren up to a crab: it bolts.
	var crab: Dictionary = life.crabs[0]
	var start: Vector2 = crab["pos"]
	game.player.global_position = room.global_position + start + Vector2(12, 0)
	await _wait(0.5)
	_check(bool(crab["fleeing"]) or (crab["pos"] as Vector2).distance_to(start) > 6.0, "a crab scuttles off when Wren comes close")
	var tile := Vector2i(floori((crab["pos"] as Vector2).x / Room.TILE), floori((crab["pos"] as Vector2).y / Room.TILE))
	_check(room.tile_at(tile.x, tile.y) == ".", "and stays on the sand")
	# Fish never swim across land between pools.
	var dry := false
	for f: Dictionary in life.fish:
		for target: Vector2 in [f["pos"] as Vector2, f["to"] as Vector2]:
			var at := Vector2i((target / Room.TILE).floor())
			dry = dry or room.tile_at(at.x, at.y) != "~"
		dry = dry or not life._all_water(f["pos"], f["to"])
	_check(life.fish.size() > 0 and not dry, "fish keep to the water")
	game.queue_free()
	await _wait(0.1)
	# Dungeons are left quiet.
	var hull: Room = (load("res://rooms/room_10_10.tscn") as PackedScene).instantiate()
	add_child(hull)
	_check(hull.get_node_or_null("Ambience") == null, "dungeons have no gulls")
	hull.queue_free()
	# Weather: mist in Brinewood, wind over Windmere, ash over Cinderreach,
	# snow (the same falling flakes) over Frostspine, sand blowing over the Ossuary.
	for case in [["res://rooms/room_3_0.tscn", "mist"], ["res://rooms/room_5_-3.tscn", "gusts"],
			["res://rooms/room_8_-2.tscn", "ash"], ["res://rooms/room_0_-3.tscn", "ash"], ["res://rooms/room_7_0.tscn", "gusts"]]:
		var weather_room: Room = (load(case[0]) as PackedScene).instantiate()
		add_child(weather_room)
		var weather := weather_room.get_node_or_null("Ambience") as Ambience
		_check(weather != null and (weather.get(case[1]) as Array).size() > 0, "%s has its %s" % [weather_room.name, case[1]])
		weather_room.queue_free()
	GameState.reset_new_game()


## After the Old One turns, a Tidestone turns the tide and holds it.
func _test_tide_turning() -> void:
	GameState.reset_new_game()
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	var stone := Tidestone.new()
	stone.room_coord = Vector2i(0, 2)
	add_child(stone)
	stone.awake = true
	# Its carving already read, so Interact goes straight to the tide.
	GameState.set_flag(stone.read_key())
	stone.interact()
	_check(Tide.held() == "" and not Tide.can_turn(), "before the Old One turns, a Tidestone leaves the tide alone")
	GameState.set_flag("old_one_turned")
	stone.interact()
	_check(Tide.held() == "high" and is_equal_approx(Tide.level(), 1.0) and Tide.phase() == Tide.Phase.HIGH, "after the turn, a Tidestone brings the tide in (at once, with no flats in sight)")
	# It holds: the clock moving on doesn't let it out again.
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	_check(is_equal_approx(Tide.level(), 1.0), "a held tide stays in")
	stone.interact()
	_check(Tide.held() == "low" and is_equal_approx(Tide.level(), 0.0), "the stone sends it out again")
	stone.queue_free()
	# In the Verge, the turned tide runs in at the flooding pace.
	GameState.set_checkpoint(Vector2i(0, 2), Vector2(6 * Room.TILE + 8, 7 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var room: Room = game.current_room
	var tide := room.get_node_or_null("Tide") as Tide
	_check(tide != null and not tide.is_flooded(Vector2i(9, 4)), "held out, Cockle Flats are dry")
	_check(Tide.turn(get_tree()) == "high" and Tide.phase() == Tide.Phase.RISING, "turned in the Verge, the tide starts rising")
	await _wait(Tide.RISING_TIME + 0.6)
	_check(Tide.phase() == Tide.Phase.HIGH and tide != null and tide.is_flooded(Vector2i(9, 4)), "and the flats go under")
	_check(GameState.has_flag(Tide.HELD_FLAG) and GameState.has_flag(Tide.HELD_IN_FLAG), "the held tide is kept as plain flags")
	# Turned and then left behind mid-ebb, it finishes while Wren is away.
	Tide.turn(get_tree())
	game.queue_free()
	await _wait(0.1)
	_check(Tide.held() == "low" and Tide.phase() == Tide.Phase.LOW, "a tide left mid-turn finishes running out")
	Tide.offset = 0.0
	GameState.reset_new_game()


## Small caves off the regions: Smugglers' Cut (crates onto plates open the
## bars), Rimefall Steps and the Icefall Grotto (three ice eyes).
func _test_regional_caves() -> void:
	GameState.reset_new_game()
	var cut: Room = (load("res://rooms/room_0_1.tscn") as PackedScene).instantiate()
	add_child(cut)
	await _wait(0.2)
	var bars: Array = _child_of(cut, Bars)
	var plates: Array = _child_of(cut, PressurePlate)
	var crates: Array = _child_of(cut, Crate)
	_check(cut.cave and bars.size() == 1 and not bars[0].is_open and plates.size() == 2 and crates.size() == 2, "Smugglers' Cut keeps its chest behind bars, with two crates for two plates")
	for i in 2:
		crates[i].position = Vector2(plates[i].tile.x * Room.TILE + 8, plates[i].tile.y * Room.TILE + 12)
	await _wait(0.3)
	_check(bars[0].is_open, "both plates weighed down open the bars")
	_check(cut.get_node("Ambience").gulls.is_empty(), "no gulls fly under a cave roof")
	cut.queue_free()
	GameState.reset_new_game()
	var grotto: Room = (load("res://rooms/room_1_-4.tscn") as PackedScene).instantiate()
	add_child(grotto)
	await _wait(0.2)
	var eyes: Array = _child_of(grotto, IceEye)
	bars = _child_of(grotto, Bars)
	_check(grotto.gate == "eyes" and eyes.size() == 3 and bars.size() == 1 and not bars[0].is_open, "the Icefall Grotto has three ice eyes and a barred chest")
	for eye in eyes:
		eye.arrow_hit(Vector2.UP)
	await _wait(0.4)
	_check(bars[0].is_open, "every eye open lets Wren at the chest")
	grotto.queue_free()
	# Saltpan Hollow: a hook post on the islet, in line with the shore.
	var pan := Room.parse_layout(((load("res://rooms/room_9_2.tscn") as PackedScene).instantiate() as Room).layout)
	_check(pan[5][15] == "O" and pan[5][14] == "." and pan[5].substr(11, 3) == "~~~" and pan[5][10] == ".", "Saltpan Hollow's hook post pulls Wren from the shore onto the islet")
	# Wreckers' Hold: its chest stands on a reef the low tide bares.
	var hold: Room = (load("res://rooms/room_3_4.tscn") as PackedScene).instantiate()
	add_child(hold)
	await _wait(0.1)
	_check(hold.get_node_or_null("Tide") != null and hold.chest_item == "glint", "Wreckers' Hold is tidal, with a glint chest")
	hold.queue_free()
	for coord: Vector2i in [Vector2i(0, 1), Vector2i(2, -4), Vector2i(1, -4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(9, 2), Vector2i(8, -4), Vector2i(2, -1), Vector2i(6, 2)]:
		var probe: Room = (load("res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]) as PackedScene).instantiate()
		_check(probe.cave, "%s is a cave" % coord)
		probe.free()
	await _wait(0.1)
	# The Clinker Vault: two braziers out on lava islets, hook posts there and back.
	GameState.reset_new_game()
	var vault: Room = (load("res://rooms/room_8_-4.tscn") as PackedScene).instantiate()
	add_child(vault)
	await _wait(0.2)
	var fires := _child_of(vault, Brazier)
	bars = _child_of(vault, Bars)
	var rows := Room.parse_layout(vault.layout)
	_check(vault.gate == "braziers" and fires.size() == 2 and bars.size() == 2 and not bars[0].is_open, "the Clinker Vault bars its chest behind two braziers")
	_check(rows[6].substr(2, 7) == "O.^^^^." and rows[6].substr(16, 6) == ".^^^.O" and rows[7][9] == "O" and rows[7][14] == "O", "each islet has a hook post out and one back")
	for brazier in fires:
		brazier.light(true)
	await _wait(0.3)
	_check(bars[0].is_open and bars[1].is_open, "both braziers lit open the vault")
	vault.queue_free()
	await _wait(0.1)
	# The Sailwind Gallery: too wide to glide, but a fan's stream carries Wren
	# over the sky to the chest ledge, and another blows them home.
	GameState.reset_new_game()
	GameState.give_item("kite_cloak", 1, false)
	GameState.set_checkpoint(Vector2i(6, -3), Vector2(4 * Room.TILE + 8, 5 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var gallery: Room = game.current_room
	var player: Player = game.player
	# Its Tumbleburr wanders the west ledge; out of the way for the rides.
	for burr in _child_of(gallery, Enemy):
		burr.free()
	var before := GameState.bubbles
	var ends: Array[Vector2] = []
	for ride: Array in [[Vector2i(4, 5), Vector2.RIGHT], [Vector2i(20, 9), Vector2.LEFT]]:
		player.global_position = _tile_pos(gallery, ride[0])
		player.facing = ride[1]
		await _wait(0.1)
		player.use_item("kite_cloak")
		await _wait(3.0)
		ends.append(player.global_position - gallery.global_position)
	_check(gallery.coord == Vector2i(6, -3) and gallery.layout.count("_") > 80, "the Sailwind Gallery opens on a wide drop of sky")
	_check(ends[0].x > 18 * Room.TILE, "the stream carries Wren over to the chest ledge (at %s)" % ends[0])
	_check(ends[1].x < 7 * Room.TILE, "and the low stream blows them home (at %s)" % ends[1])
	_check(GameState.bubbles == before and game.current_room == gallery, "both rides without a fall")
	player.global_position = _tile_pos(gallery, Vector2i(5, 7))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(2.5)
	_check(GameState.bubbles == before - 1, "off the stream, the glide falls short into the sky")
	game.queue_free()
	await _wait(0.1)
	# Rootbound Hollow: the chest is walled in by cracked boulders.
	GameState.reset_new_game()
	var hollow: Room = (load("res://rooms/room_2_-1.tscn") as PackedScene).instantiate()
	rows = Room.parse_layout(hollow.layout)
	_check(hollow.cave and rows[2][4] == "C" and rows[2][8] == "Y" and rows[5][4] == "Y" and rows[5][23] == ".", "Rootbound Hollow keeps its chest behind cracked boulders, off Brinewood's west edge")
	hollow.free()
	# The Sporecap Warren: shut in with the fen's foes, the chest shows once they're down.
	var warren: Room = (load("res://rooms/room_6_2.tscn") as PackedScene).instantiate()
	add_child(warren)
	await _wait(0.2)
	var hidden: Chest = _child_of(warren, Chest)[0]
	_check(warren.gate == "clear" and Room.parse_layout(warren.layout)[1].count("|") == 2 and Room.parse_layout(warren.layout)[11].count("|") == 2 and not hidden.visible and _child_of(warren, Enemy).size() >= 5, "the Sporecap Warren hides its chest behind a fight")
	for enemy in _child_of(warren, Enemy):
		enemy.queue_free()
	warren.get_node("Puzzle").set("_shut_in", true)
	await _wait(0.3)
	_check(hidden.visible and GameState.has_flag(RoomPuzzle.flag_for(warren.coord)), "with the warren cleared its chest appears")
	warren.queue_free()
	await _wait(0.1)



## The optional screens off the thinner regions: each wants two tools together.
func _test_thin_region_screens() -> void:
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	GameState.give_item("kite_cloak", 1, false)
	GameState.set_checkpoint(Vector2i(10, 1), Vector2(5 * Room.TILE + 8, 8 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var player: Player = game.player
	player._invuln = 60.0
	# Sinkwhorl Flats: one great whorl of sinking sand between the reefs;
	# the hook posts are the safe way over and back.
	var basin: Room = game.current_room
	for foe in _child_of(basin, Enemy):
		foe.free()
	var ends: Array[Vector2] = []
	for throw: Array in [[Vector2i(8, 8), Vector2.RIGHT], [Vector2i(14, 9), Vector2.LEFT]]:
		player.global_position = _tile_pos(basin, throw[0])
		player.facing = throw[1]
		await _wait(0.1)
		player.use_item("tide_hook")
		await _wait(1.3)
		ends.append(player.global_position - basin.global_position)
	_check(basin.coord == Vector2i(10, 1) and basin.tile_at(11, 8) == "S" and basin.has_node("SinkField"), "Sinkwhorl Flats' reefs are split by sinking sand")
	_check(int(ends[0].x) / Room.TILE == 14 and int(ends[1].x) / Room.TILE == 8, "the hook pulls Wren out to the chest reef and back (at %s, %s)" % ends)
	var before := GameState.bubbles
	# Kestrel Reach: a stream to the stack, the hook down to the chest
	# ledge, and the low stream home.
	var reach: Room = await _goto(game, Vector2i(7, -3), Vector2i(1, 6))
	for foe in _child_of(reach, Enemy):
		foe.free()
	before = GameState.bubbles
	ends.clear()
	# (The stream ends at a rock on the stack's lip, so the hook is thrown from still ground.)
	for move: Array in [[Vector2i(3, 3), Vector2.RIGHT, "kite_cloak", 3.0], [Vector2i(14, 3), Vector2.DOWN, "tide_hook", 1.3], [Vector2i(20, 9), Vector2.LEFT, "kite_cloak", 3.0]]:
		player.global_position = _tile_pos(reach, move[0])
		player.facing = move[1]
		await _wait(0.1)
		player.use_item(move[2])
		await _wait(move[3])
		ends.append(player.global_position - reach.global_position)
	_check(reach.coord == Vector2i(7, -3), "the gallery leads on to Kestrel Reach")
	_check(ends[0].x > 11 * Room.TILE and ends[0].y < 4 * Room.TILE, "the stream sets Wren on the stack (at %s)" % ends[0])
	_check(int(ends[1].y) / Room.TILE == 9, "the hook drops Wren to the chest ledge (at %s)" % ends[1])
	_check(ends[2].x < 6 * Room.TILE, "the low stream blows them home (at %s)" % ends[2])
	_check(GameState.bubbles == before, "all without a fall")
	game.queue_free()
	await _wait(0.1)
	# Crevasse Shelf: from the ice the hook crosses a crevasse, too wide to
	# glide, to a snowy shelf with a chest, and a post on the ice brings Wren back.
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	GameState.set_checkpoint(Vector2i(0, -4), Vector2(3 * Room.TILE + 8, 9 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var shelf: Room = game.current_room
	for foe in _child_of(shelf, Enemy):
		foe.free()
	ends.clear()
	for throw: Array in [[Vector2i(3, 9), Vector2.UP], [Vector2i(5, 3), Vector2.DOWN]]:
		player.global_position = _tile_pos(shelf, throw[0])
		player.facing = throw[1]
		await _wait(0.1)
		player.use_item("tide_hook")
		await _wait(1.3)
		ends.append(player.global_position - shelf.global_position)
	_check(shelf.coord == Vector2i(0, -4) and shelf.tile_at(3, 6) == "_" and Room.BIOMES["frostspine"].get("gap") == "crevasse", "the Crevasse Shelf is cut off by a crevasse")
	_check(int(ends[0].y - 3) / Room.TILE == 3 and int(ends[1].y - 3) / Room.TILE == 9, "the hook pulls Wren up onto the shelf and back down to the ice (at %s, %s)" % ends)
	game.queue_free()
	await _wait(0.1)
	# Tidewrack Strand: a long tide flat out west of the Verge to a wreck.
	var strand: Room = (load("res://rooms/room_-1_3.tscn") as PackedScene).instantiate()
	add_child(strand)
	await _wait(0.1)
	_check(strand.get_node_or_null("Tide") != null and strand.layout.count("r") > 40 and strand.chest_item == "glint", "Tidewrack Strand is a tide flat with a chest on the wreck's islet")
	strand.queue_free()
	await _wait(0.1)
	# Whalefall Steps: cracked boulders shut the way down to the basin.
	var steps: Room = (load("res://rooms/room_10_0.tscn") as PackedScene).instantiate()
	var rows := Room.parse_layout(steps.layout)
	_check(rows[11].substr(11, 2) == "YY" and rows[12].substr(11, 2) == "..", "Whalefall Steps' way down is blocked by cracked boulders")
	steps.free()


## The far reaches: late screens past each region's edge, each a chain of
## the tools Wren has gathered.
func _test_far_reaches() -> void:
	# Windmere north. A deep-water channel from Windbreak Cliffs (the Diver's
	# Helm) to Skerry Sound, whose crates open the way west.
	var cliffs := Room.parse_layout(((load("res://rooms/room_6_-4.tscn") as PackedScene).instantiate() as Room).layout)
	_check(cliffs[0].substr(8, 2) == "QQ" and cliffs[3].substr(8, 2) == "QQ" and cliffs[3][7] == ".", "Windbreak Cliffs' deep channel runs north from the shore")
	GameState.reset_new_game()
	var sound: Room = (load("res://rooms/room_6_-5.tscn") as PackedScene).instantiate()
	add_child(sound)
	await _wait(0.2)
	var rows := Room.parse_layout(sound.layout)
	var bars: Array = _child_of(sound, Bars)
	var plates: Array = _child_of(sound, PressurePlate)
	var crates: Array = _child_of(sound, Crate)
	_check(rows[12].substr(8, 2) == "QQ" and sound.gate == "plates" and plates.size() == 2 and crates.size() == 2 and bars.size() == 2 and not bars[0].is_open, "Skerry Sound: two crates, two plates and barred cliffs west")
	# Each crate has a push onto a plate: (10,3) west twice, (13,4) east then south.
	_check(rows[3].substr(8, 4) == "=.K." and rows[4].substr(12, 3) == ".K." and rows[3][14] == "." and rows[5][14] == "=", "each crate can be pushed onto a plate")
	for i in 2:
		crates[i].position = Vector2(plates[i].tile.x * Room.TILE + 8, plates[i].tile.y * Room.TILE + 12)
	await _wait(0.3)
	_check(bars[0].is_open and bars[1].is_open, "both plates down open the way west")
	sound.queue_free()
	await _wait(0.1)
	# Stormcrown Stacks: hook over the sky to the middle stack, then shoot
	# the two ice eyes on their pillars to open the way on.
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	GameState.set_checkpoint(Vector2i(5, -5), Vector2(17 * Room.TILE + 8, 5 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var player: Player = game.player
	player._invuln = 60.0
	var stacks: Room = game.current_room
	for foe in _child_of(stacks, Enemy):
		foe.free()
	var before := GameState.bubbles
	player.global_position = _tile_pos(stacks, Vector2i(17, 5))
	player.facing = Vector2.LEFT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.5)
	var at := player.global_position - stacks.global_position
	_check(stacks.tile_at(14, 5) == "_" and int(at.x) / Room.TILE == 11 and int(at.y - 3) / Room.TILE == 5 and GameState.bubbles == before, "the hook pulls Wren over the sky to the middle stack (at %s)" % at)
	var eyes: Array = _child_of(stacks, IceEye)
	bars = _child_of(stacks, Bars)
	_check(stacks.gate == "eyes" and eyes.size() == 2 and bars.size() == 2 and not bars[0].is_open, "two ice eyes on pillars bar the way west")
	for eye in eyes:
		eye.arrow_hit(Vector2.UP)
	await _wait(0.4)
	_check(bars[0].is_open and bars[1].is_open, "both eyes shot open the way")
	# And a post on the east stack hooks Wren home again.
	player.global_position = _tile_pos(stacks, Vector2i(11, 7))
	player.facing = Vector2.RIGHT
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(1.5)
	at = player.global_position - stacks.global_position
	_check(int(at.x) / Room.TILE == 17 and int(at.y - 3) / Room.TILE == 7 and GameState.bubbles == before, "a post on the east stack hooks Wren back (at %s)" % at)
	game.queue_free()
	await _wait(0.1)
	# Edgewatch Bluff: a glide over a crevasse to the far brazier; both lit
	# open the cache.
	GameState.reset_new_game()
	GameState.give_item("kite_cloak", 1, false)
	GameState.set_checkpoint(Vector2i(4, -5), Vector2(12 * Room.TILE + 8, 6 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var bluff: Room = game.current_room
	before = GameState.bubbles
	player.global_position = _tile_pos(bluff, Vector2i(8, 6))
	player.facing = Vector2.LEFT
	await _wait(0.1)
	player.use_item("kite_cloak")
	await _wait(2.5)
	at = player.global_position - bluff.global_position
	_check(bluff.tile_at(6, 6) == "_" and at.x < 5 * Room.TILE and GameState.bubbles == before, "the cloak carries Wren over the crevasse to the brazier's islet (at %s)" % at)
	var fires := _child_of(bluff, Brazier)
	bars = _child_of(bluff, Bars)
	_check(bluff.gate == "braziers" and fires.size() == 2 and bars.size() == 1 and not bars[0].is_open and bluff.chest_item == "glint", "Edgewatch Bluff bars its cache behind two braziers")
	for brazier in fires:
		brazier.light(true)
	await _wait(0.3)
	_check(bars[0].is_open, "both braziers lit open the cache")
	game.queue_free()
	await _wait(0.1)
	# Frostspine north: up from the Crevasse Shelf to Rimeglass Inlet, where
	# hook posts span a crevasse both ways.
	var shelf_rows := Room.parse_layout(((load("res://rooms/room_0_-4.tscn") as PackedScene).instantiate() as Room).layout)
	_check(shelf_rows[0].substr(4, 2) == "..", "the Crevasse Shelf opens north")
	var hooks := {
		Vector2i(0, -5): [[Vector2i(14, 6), Vector2.RIGHT, Vector2i(20, 6)], [Vector2i(20, 5), Vector2.LEFT, Vector2i(14, 5)]],
		Vector2i(9, -3): [[Vector2i(15, 9), Vector2.UP, Vector2i(15, 3)], [Vector2i(14, 3), Vector2.DOWN, Vector2i(14, 9)]],
		# Gloamfen south: out over the dark fen to the far bank and home again.
		Vector2i(6, 3): [[Vector2i(17, 8), Vector2.RIGHT, Vector2i(20, 8)], [Vector2i(20, 9), Vector2.LEFT, Vector2i(17, 9)]],
		# The Verge's far south: a reef islet's cache, there and back.
		Vector2i(0, 5): [[Vector2i(19, 8), Vector2.UP, Vector2i(19, 3)], [Vector2i(19, 4), Vector2.DOWN, Vector2i(19, 8)]],
		# The Ossuary's far south: over the bitter sea to Saltgrave Brink and back.
		Vector2i(8, 3): [[Vector2i(17, 9), Vector2.LEFT, Vector2i(12, 9)], [Vector2i(12, 10), Vector2.RIGHT, Vector2i(17, 10)]],
	}
	for coord: Vector2i in hooks:
		GameState.reset_new_game()
		GameState.give_item("tide_hook", 1, false)
		var first: Vector2i = hooks[coord][0][0]
		GameState.set_checkpoint(coord, Vector2(first.x * Room.TILE + 8, first.y * Room.TILE + 12))
		game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.4)
		player = game.player
		player._invuln = 60.0
		var room: Room = game.current_room
		for foe in _child_of(room, Enemy):
			foe.free()
		before = GameState.bubbles
		for throw: Array in hooks[coord]:
			player.global_position = _tile_pos(room, throw[0])
			player.facing = throw[1]
			await _wait(0.1)
			player.use_item("tide_hook")
			await _wait(1.5)
			at = player.global_position - room.global_position
			var want: Vector2i = throw[2]
			_check(int(at.x) / Room.TILE == want.x and int(at.y - 3) / Room.TILE == want.y and GameState.bubbles == before and game.current_room == room,
				"%s: the hook carries Wren from %s to %s (at %s)" % [coord, throw[0], want, at])
		game.queue_free()
		await _wait(0.1)
	# Hoarfrost Cairn: cracked boulders, then two ice eyes out in a lake. The
	# first arrow freezes the water short of an eye, the next flies on to it.
	GameState.reset_new_game()
	GameState.give_item("frostfang_bow", 1, false)
	GameState.set_checkpoint(Vector2i(1, -5), Vector2(9 * Room.TILE + 8, 2 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var cairn: Room = game.current_room
	for foe in _child_of(cairn, Enemy):
		foe.free()
	eyes = _child_of(cairn, IceEye)
	bars = _child_of(cairn, Bars)
	_check(cairn.tile_at(6, 4) == "Y" and cairn.tile_at(6, 5) == "Y" and cairn.gate == "eyes" and eyes.size() == 2 and bars.size() == 2 and not bars[0].is_open, "Hoarfrost Cairn: boulders, two lake eyes and a barred cairn")
	player.global_position = _tile_pos(cairn, Vector2i(9, 2))
	player.facing = Vector2.DOWN
	for i in 3:
		await _wait(0.6)
		player.use_item("frostfang_bow")
	await _wait(1.0)
	_check(eyes.any(func(e: IceEye) -> bool: return e.lit), "arrows freeze a way over the lake to the first eye")
	for eye in eyes:
		eye.arrow_hit(Vector2.UP)
	await _wait(0.4)
	_check(bars[0].is_open and bars[1].is_open and cairn.chest_item == "glint", "both eyes open the cairn")
	game.queue_free()
	await _wait(0.1)
	# Gloamfen south: down from the Sporecap Warren into the dark Glowmire
	# Deep (veiled planks: the lantern) to the Calf's Rest, whose middle is
	# left clear for the calf's skull.
	var warren := Room.parse_layout(((load("res://rooms/room_6_2.tscn") as PackedScene).instantiate() as Room).layout)
	var deep: Room = (load("res://rooms/room_6_3.tscn") as PackedScene).instantiate()
	var rest: Room = (load("res://rooms/room_7_3.tscn") as PackedScene).instantiate()
	var rest_rows := Room.parse_layout(rest.layout)
	_check(warren[12].substr(11, 2) == ".." and deep.dark and deep.layout.count("v") == 10, "the Warren opens south into the dark Glowmire Deep, crossed on veiled planks")
	_check(rest_rows[4].substr(10, 5) == "....." and rest_rows[5].substr(10, 5) == "....." and rest_rows[6].substr(10, 5) == "....." and rest.chest_item == "glint", "the Calf's Rest keeps its middle clear")
	deep.free()
	rest.free()
	# The Verge's far south: down the Ebb Shelf's sea bed (the held tide),
	# then a deep trench only the Diver's Helm swims.
	var ebb := Room.parse_layout(((load("res://rooms/room_1_4.tscn") as PackedScene).instantiate() as Room).layout)
	var wrack := Room.parse_layout(((load("res://rooms/room_1_5.tscn") as PackedScene).instantiate() as Room).layout)
	_check(ebb[12].substr(11, 2) == ";;" and wrack[0].substr(11, 2) == ";;" and wrack[4].count("Q") == 17 and wrack[8].count("Q") == 22, "Wrack Deeps: sea bed from the Ebb Shelf, then five rows of deep trench (a rock-capped shoal in it)")
	# The Ossuary's far south: Saltpan Hollow opens onto Ribfall Sands, shut
	# behind a bone barricade only the Echo Horn brings down.
	_check(Room.parse_layout(((load("res://rooms/room_9_2.tscn") as PackedScene).instantiate() as Room).layout)[12].substr(8, 2) == "..", "Saltpan Hollow opens south to Ribfall Sands")
	GameState.reset_new_game()
	GameState.give_item("echo_horn", 1, false)
	GameState.set_checkpoint(Vector2i(9, 3), Vector2(8 * Room.TILE + 8, 1 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var sands: Room = game.current_room
	for foe in _child_of(sands, Enemy):
		foe.free()
	_check(_child_of(sands, BoneWall).size() == 2 and _child_of(sands, SinkField).size() == 1 and sands.tile_at(2, 9) == "Y" and sands.tile_at(2, 10) == "Y", "Ribfall Sands: a bone barricade, sinking sand, and a cracked boulder at the far side")
	player.global_position = _tile_pos(sands, Vector2i(8, 1))
	player.facing = Vector2.DOWN
	await _wait(0.3)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(_child_of(sands, BoneWall).is_empty(), "the horn brings Ribfall's barricade down")
	game.queue_free()
	await _wait(0.1)
	var brink: Room = (load("res://rooms/room_8_3.tscn") as PackedScene).instantiate()
	_check(brink.sign_key == "SIGN_SALTGRAVE_BRINK" and brink.chest_item == "glint" and brink.chest_count == 200, "Saltgrave Brink: a sign at the edge, and glints out on an islet")
	brink.free()
	# Cinder Crown: two crates onto two plates open the crown's cache.
	_check(Room.parse_layout(((load("res://rooms/room_9_-2.tscn") as PackedScene).instantiate() as Room).layout)[0].substr(15, 2) == "..", "the Slag Fields open north to Brimstone Steps")
	GameState.reset_new_game()
	var crown: Room = (load("res://rooms/room_10_-3.tscn") as PackedScene).instantiate()
	add_child(crown)
	await _wait(0.2)
	crates = _child_of(crown, Crate)
	plates = _child_of(crown, PressurePlate)
	bars = _child_of(crown, Bars)
	rows = Room.parse_layout(crown.layout)
	_check(crown.gate == "plates" and crates.size() == 2 and plates.size() == 2 and bars.size() == 2 and rows[6].substr(7, 10) == "=.K....K.=", "Cinder Crown: each crate two pushes from its plate")
	for i in 2:
		crates[i].position = Vector2(plates[i].tile.x * Room.TILE + 8, plates[i].tile.y * Room.TILE + 12)
	await _wait(0.3)
	_check(bars[0].is_open and bars[1].is_open, "both plates down open the crown's cache")
	crown.queue_free()
	await _wait(0.1)


## The regions' elites: an ordinary foe grown big and bronze, with a second
## step to its pattern, that stays beaten.
func _test_elites() -> void:
	GameState.reset_new_game()
	var cases := {Vector2i(3, -1): "Scuttler", Vector2i(9, -2): "Slagbeetle", Vector2i(6, 1): "Bogskipper", Vector2i(4, -4): "Galehawk", Vector2i(2, -2): "Sledgeseal", Vector2i(1, 3): "Siltray", Vector2i(8, 0): "Dunejaw"}
	for coord: Vector2i in cases:
		var room: Room = (load("res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]) as PackedScene).instantiate()
		room.coord = coord
		add_child(room)
		await _wait(0.1)
		var elites := _child_of(room, Enemy).filter(func(e: Enemy) -> bool: return e.elite)
		_check(elites.size() == 1 and elites[0].get_class() != "" and (elites[0].get_script() as Script).get_global_name() == cases[coord], "%s has one elite %s" % [coord, cases[coord]])
		if elites.is_empty():
			room.queue_free()
			continue
		var boss: Enemy = elites[0]
		# max_hp is set in _init, so a fresh, unready one has its plain toughness.
		var plain := (boss.get_script() as Script).new() as Enemy
		_check(boss.max_hp == plain.max_hp * Enemy.ELITE_HP and boss.scale.x > 1.2, "the elite is bigger and three times as hardy")
		plain.free()
		boss.ai_enabled = false
		if boss is Scuttler:
			var crab := boss as Scuttler
			crab.ai_enabled = true
			var dashes := 1
			for i in 3:
				crab.mode = Scuttler.Mode.DASH
				crab._timer = 0.0
				crab._think(0.016)
				if crab.mode == Scuttler.Mode.WINDUP:
					dashes += 1
			_check(dashes == 3 and crab.mode == Scuttler.Mode.REST, "the elite crab chains three dashes, then rests")
			crab.ai_enabled = false
		elif boss is Slagbeetle:
			var bull := boss as Slagbeetle
			bull.position = Vector2(2 * Room.TILE + 8, 9 * Room.TILE + 12)
			bull.ai_enabled = true
			bull.mode = Slagbeetle.Mode.CHARGE
			bull._direction = Vector2.LEFT
			bull._timer = 2.0
			await _wait(0.3)
			_check(bull.mode == Slagbeetle.Mode.CRACK and bull._bounced and absf(bull._direction.y) == 1.0, "the elite beetle shrugs off its first wall and turns")
			bull.ai_enabled = false
		elif boss is Bogskipper:
			var skip := boss as Bogskipper
			var wren := Player.new()
			wren.add_to_group("player")
			wren.set_physics_process(false)
			room.add_child(wren)
			wren.position = skip.position + Vector2(0, -90)
			var start := skip.position
			skip.ai_enabled = true
			await _wait(0.5)
			_check(skip.mode == Bogskipper.Mode.HIDDEN and skip.position.y < start.y - 4.0, "the elite skipper creeps after Wren under the mud")
			skip.ai_enabled = false
			wren.free()
		elif boss is Galehawk:
			var hawk := boss as Galehawk
			hawk.ai_enabled = true
			hawk._restoop = true
			hawk.mode = Galehawk.Mode.STOOP
			hawk._timer = 0.0
			hawk._think(0.016)
			_check(hawk.mode == Galehawk.Mode.PERCH and hawk._timer <= Galehawk.RESTOOP_PERCH, "the elite hawk's first perch is short")
			hawk._timer = 0.0
			hawk._think(0.016)
			_check(hawk.mode == Galehawk.Mode.MARK and not hawk._restoop, "then it stoops again")
			hawk.mode = Galehawk.Mode.STOOP
			hawk._timer = 0.0
			hawk._think(0.016)
			_check(hawk.mode == Galehawk.Mode.PERCH and hawk._timer > 1.0, "and its second perch is the full one")
			hawk.ai_enabled = false
		elif boss is Sledgeseal:
			var seal := boss as Sledgeseal
			var wren := Player.new()
			wren.set_physics_process(false)
			room.add_child(wren)
			wren.position = seal.position + Vector2(0, 2 * Room.TILE)
			seal.mode = Sledgeseal.Mode.SLIDE
			seal._direction = Vector2.LEFT
			seal._timer = 1.0
			seal._think(0.016)
			_check(seal.mode == Sledgeseal.Mode.REAR and seal._direction == Vector2.DOWN and seal._turned, "the elite seal turns mid-slide toward Wren")
			seal.mode = Sledgeseal.Mode.SLIDE
			seal._direction = Vector2.LEFT
			seal._think(0.016)
			_check(seal.mode == Sledgeseal.Mode.SLIDE, "but only once a slide")
			seal.mode = Sledgeseal.Mode.IDLE
			wren.free()
		elif boss is Siltray:
			var ray := boss as Siltray
			ray._set_mode(Siltray.Mode.LEAP)
			_check(is_equal_approx(ray._timer, Siltray.LEAP_TIME * Siltray.ELITE_REACH), "the elite ray leaps further")
			ray._set_mode(Siltray.Mode.STRANDED)
		elif boss is Dunejaw:
			var jaw := boss as Dunejaw
			var wren := Player.new()
			wren.set_physics_process(false)
			room.add_child(wren)
			wren.position = jaw.position
			jaw._set_mode(Dunejaw.Mode.BITE)
			jaw._timer = 0.0
			jaw._think(0.016)
			_check(jaw.mode == Dunejaw.Mode.BURROW and jaw._rebite, "the elite dunejaw dives straight back after its first bite")
			jaw._think(0.016)
			_check(jaw.mode == Dunejaw.Mode.SPOUT and jaw._timer <= Dunejaw.RESPOUT_TIME, "and spouts again, quicker")
			jaw._set_mode(Dunejaw.Mode.BITE)
			jaw._timer = 0.0
			jaw._think(0.016)
			_check(jaw.mode == Dunejaw.Mode.EXPOSED, "then lies out after the second")
			# Outrun on the second hunt, it gives up and rests before hunting again.
			jaw._set_mode(Dunejaw.Mode.BURROW)
			jaw._rebite = true
			jaw._timer = -Dunejaw.HUNT_GIVE_UP - 0.1
			wren.position = jaw.position + Vector2(120, 0)
			jaw._think(0.016)
			_check(not jaw._rebite and jaw._timer > 0.0 and jaw.velocity == Vector2.ZERO, "an outrun elite dunejaw gives up and rests")
			wren.free()
		for i in 12:
			if not boss.dying:
				if boss is Slagbeetle:
					(boss as Slagbeetle).mode = Slagbeetle.Mode.FLIPPED
				elif boss is Bogskipper:
					(boss as Bogskipper).mode = Bogskipper.Mode.HOP
				elif boss is Galehawk:
					(boss as Galehawk).mode = Galehawk.Mode.PERCH
				elif boss is Dunejaw:
					(boss as Dunejaw)._set_mode(Dunejaw.Mode.EXPOSED)
				elif boss is Siltray:
					(boss as Siltray)._set_mode(Siltray.Mode.STRANDED)
				boss.take_hit(1, Vector2.RIGHT)
		await _wait(0.4)
		_check(GameState.has_flag(Room.elite_flag(coord)), "the fallen elite stays beaten")
		var count := _child_of(room, Enemy).size()
		room.queue_free()
		await _wait(0.1)
		var again: Room = (load("res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]) as PackedScene).instantiate()
		again.coord = coord
		add_child(again)
		await _wait(0.1)
		_check(_child_of(again, Enemy).all(func(e: Enemy) -> bool: return not e.elite), "%s comes back without its elite" % coord)
		again.queue_free()
		await _wait(0.1)

## Overworld life: the Galehawk over Windmere, the newer foes elsewhere, and
## the hares, lizards and reeds.
func _test_overworld_life() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(4, -3), Vector2(13 * Room.TILE + 8, 4 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room: Room = game.current_room
	var hawks := _child_of(room, Galehawk)
	_check(hawks.size() == 1, "Mill Row has a Galehawk")
	if hawks.is_empty():
		game.queue_free()
		return
	var hawk: Galehawk = hawks[0]
	game.player._invuln = 60.0
	_check(hawk.airborne() and hawk.take_hit(1, Vector2.RIGHT) == Enemy.HitResult.IGNORED, "up in the air a Galehawk can't be struck")
	_check(not hawk._can_land(room, Vector2(6 * Room.TILE + 8, 8 * Room.TILE + 8)), "it never stoops into water")
	var perched := false
	for i in 40:
		await _wait(0.1)
		if not hawk.airborne():
			perched = true
			break
	_check(perched and hawk.position.distance_to(room.to_local(game.player.global_position)) < 24.0, "it stoops on Wren's spot (at %s)" % hawk.position)
	_check(perched and hawk.take_hit(1, Vector2.RIGHT) == Enemy.HitResult.HIT, "down on the turf it can be struck")
	game.queue_free()
	await _wait(0.1)
	# A Rimeling out on the open shore turns at the screen's edge, and a
	# hawk's lap stays on screen.
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(0, -3), Vector2(5 * Room.TILE + 8, 8 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	room = game.current_room
	game.player._invuln = 60.0
	var imps := _child_of(room, Rimeling)
	var probe_hawk := Galehawk.new()
	probe_hawk.position = Vector2(2 * Room.TILE, 1 * Room.TILE)
	room.add_child(probe_hawk)
	var out := false
	for i in 30:
		await _wait(0.1)
		for imp in imps:
			out = out or not Rect2(Vector2.ZERO, Room.SIZE).has_point(imp.position)
		var lap: Vector2 = probe_hawk._home
		out = out or lap.x - Galehawk.CIRCLE_RADIUS < 0.0 or lap.y - Galehawk.CIRCLE_RADIUS - Galehawk.HEIGHT < 0.0
	_check(not imps.is_empty() and not out, "Frostspine's Rimeling stays in its room, and a hawk circles on screen")
	game.queue_free()
	await _wait(0.1)
	# Each samey region has a second kind of foe now.
	var foes := {"windmere": "0", "frostspine": "a", "sunken_verge": "b", "gloamfen": "m"}
	for biome: String in foes:
		var found := 0
		for path in DirAccess.get_files_at("res://rooms"):
			if not path.ends_with(".tscn"):
				continue
			var probe: Room = (load("res://rooms/" + path) as PackedScene).instantiate()
			if probe.biome == biome and probe.dungeon == "" and probe.layout.contains(foes[biome]):
				found += 1
			probe.free()
		_check(found >= 3, "%s has %s in %d rooms" % [biome, foes[biome], found])
	# Critters and reeds.
	for case: Array in [[Vector2i(1, -2), "hares"], [Vector2i(8, 1), "lizards"], [Vector2i(3, 0), "reeds"], [Vector2i(5, -3), "reeds"]]:
		var place: Room = (load("res://rooms/room_%d_%d.tscn" % [case[0].x, case[0].y]) as PackedScene).instantiate()
		add_child(place)
		await _wait(0.1)
		var life := place.get_node_or_null("Ambience") as Ambience
		var list: Array = [] if life == null else (life.reeds if case[1] == "reeds" else life.runners)
		_check(not list.is_empty(), "room %s has %s" % [case[0], case[1]])
		if case[1] != "reeds" and not list.is_empty():
			for r: Dictionary in list:
				var at := Vector2i(((r["pos"] as Vector2) / Room.TILE).floor())
				_check(place.tile_at(at.x, at.y) == ".", "a %s starts on open ground" % r["kind"])
		place.queue_free()
	await _wait(0.1)


## The optional challenges: each holds a Breath Pearl behind its own test.
func _test_challenges() -> void:
	GameState.reset_new_game()
	for coord: Vector2i in [Vector2i(8, 2), Vector2i(7, -4), Vector2i(5, 3)]:
		var probe: Room = (load("res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]) as PackedScene).instantiate()
		_check(probe.chest_item == "breath_pearl" and probe.layout.count("C") == 1, "challenge %s holds one Breath Pearl" % coord)
		probe.free()
	# The Bone Ring: the bars stay open till Wren is in, then the ring shuts and
	# the pearl only shows once every foe is down.
	var ring: Room = (load("res://rooms/room_8_2.tscn") as PackedScene).instantiate()
	add_child(ring)
	await _wait(0.2)
	var chest: Chest = _child_of(ring, Chest)[0]
	# The bars sit on row 1, outside the shut-in line, so they never close on Wren.
	_check(Room.parse_layout(ring.layout)[1].count("|") == 2, "the Bone Ring's bars stand clear of the arena")
	_check(ring.gate == "clear" and not chest.visible and not _child_of(ring, Enemy).is_empty(), "the Bone Ring hides its pearl behind a fight")
	for enemy in _child_of(ring, Enemy):
		enemy.queue_free()
	ring.get_node("Puzzle").set("_shut_in", true)
	await _wait(0.3)
	_check(chest.visible and GameState.has_flag(RoomPuzzle.flag_for(ring.coord)), "with the ring cleared the pearl appears")
	ring.queue_free()
	# The Lampless Sink: dark, veiled planks out to four braziers. (Rooms made
	# here all sit at the same coord, so the ring's solved flag goes first.)
	GameState.reset_new_game()
	var sink: Room = (load("res://rooms/room_5_3.tscn") as PackedScene).instantiate()
	add_child(sink)
	await _wait(0.2)
	var braziers := _child_of(sink, Brazier)
	chest = _child_of(sink, Chest)[0]
	_check(sink.dark and braziers.size() == 4 and sink.layout.count("v") > 20 and not chest.visible, "the Lampless Sink is dark, with four braziers over veiled planks")
	for brazier in braziers:
		brazier.light(true)
	await _wait(0.2)
	_check(chest.visible, "four braziers lit bring up its pearl")
	sink.queue_free()
	# Gullcry Stacks: a chasm course that only the kite cloak crosses, into the wind.
	var stacks: Room = (load("res://rooms/room_7_-4.tscn") as PackedScene).instantiate()
	_check(stacks.wind.x < 0 and stacks.layout.count("_") > 150 and Room.BIOMES["windmere"].get("gap") == "galesky", "Gullcry Stacks is a gusty chasm course, drawn as open sky")
	stacks.free()
	await _wait(0.1)


## The sea bed (;): under water while the tide breathes, even at its lowest;
## bared only while Wren holds the tide out.
func _test_sea_bed() -> void:
	GameState.reset_new_game()
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	var square: Room = (load("res://rooms/room_1_3.tscn") as PackedScene).instantiate()
	add_child(square)
	await _wait(0.1)
	var tide := square.get_node_or_null("Tide") as Tide
	var bed := Vector2i(11, 11)
	_check(tide != null and square.tile_at(bed.x, bed.y) == ";" and tide.is_flooded(bed) and not tide.is_flooded(Vector2i(11, 10)),
		"at low tide the flats are bare but the sea bed is still under water")
	GameState.set_flag(Tide.TURNED_FLAG)
	GameState.set_flag(Tide.HELD_FLAG)
	await _wait(0.1)
	_check(tide != null and not tide.is_flooded(bed), "held out, the tide bares the sea bed")
	GameState.set_flag(Tide.HELD_IN_FLAG)
	await _wait(0.1)
	_check(tide != null and tide.is_flooded(bed) and tide.is_flooded(Vector2i(11, 10)), "held in, it's all under again")
	square.queue_free()
	# The map only joins Belfry Square to the Ebb Shelf while the sea bed is bare.
	var map := MapPage.new()
	_check(not map._joined(Vector2i(1, 3), Vector2i(1, 4), Vector2i.DOWN), "the map keeps the Ebb Shelf hidden while the tide is in")
	GameState.clear_flag(Tide.HELD_IN_FLAG)
	_check(map._joined(Vector2i(1, 3), Vector2i(1, 4), Vector2i.DOWN), "and joins it once the tide is held out")
	map.free()
	# The Ebb Shelf has its own bed of sound, and both new loops exist.
	var shelf: Room = (load("res://rooms/room_1_4.tscn") as PackedScene).instantiate()
	_check(Audio.ambience_for_room(shelf.biome, shelf.dungeon, shelf.ambience, shelf.cave) == "ebb", "the Ebb Shelf plays the ebb loop")
	shelf.free()
	for loop in ["ebb", "hollow"]:
		_check(ResourceLoader.exists(Audio.AMBIENCE_DIR + loop + ".wav"), "the %s ambience loop is there" % loop)
	# Frost can't make a path out to it: only open water freezes.
	GameState.clear_flag(Tide.HELD_FLAG)
	var steps: Room = (load("res://rooms/room_2_3.tscn") as PackedScene).instantiate()
	add_child(steps)
	await _wait(0.1)
	var froze := steps.freeze(Vector2i(10, 11))
	var laid := Room.parse_layout(steps.layout)
	_check(not froze.is_empty() and froze.all(func(t: Vector2i) -> bool: return laid[t.y][t.x] == "~"),
		"a frost arrow beside the sea bed freezes only the open water")
	# Turned in at a breathing low tide, the sea bed never shows on the way up.
	var steps_tide := steps.get_node_or_null("Tide") as Tide
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	Tide.turn(get_tree())
	await _wait(0.2)
	_check(Tide.held() == "high" and steps_tide != null and steps_tide.is_flooded(Vector2i(9, 11)) and steps_tide.cover(Vector2i(9, 11)) >= 1.0,
		"turning the tide in at low water never bares the sea bed")
	steps.queue_free()
	Tide.offset = 0.0
	GameState.reset_new_game()


## Every Tidestone has a keeper's line cut into it. Interact reads it; after
## the turn, a stone already read turns the tide instead.
func _test_tidestone_carvings() -> void:
	GameState.reset_new_game()
	var stones := 0
	for file in DirAccess.get_files_at("res://rooms"):
		file = file.trim_suffix(".remap")
		if not file.ends_with(".tscn"):
			continue
		var parts := file.trim_prefix("room_").trim_suffix(".tscn").split("_")
		var coord := Vector2i(int(parts[0]), int(parts[1]))
		var room: Room = (load("res://rooms/" + file) as PackedScene).instantiate()
		if (room.layout + room.alt_layout).contains("T"):
			stones += 1
			var carving: Array = Tidestone.CARVINGS.get(coord, [])
			_check(not carving.is_empty(), "the Tidestone in room %s has a carving" % coord)
			for key: String in carving:
				_check(tr(key) != key, "%s has its text" % key)
		room.free()
	_check(stones == Tidestone.CARVINGS.size(), "every carving belongs to a stone (%d stones)" % stones)
	var shown: Array = []
	var catch := func(pages: Array) -> void: shown.append_array(pages)
	Events.conversation_requested.connect(catch)
	var stone := Tidestone.new()
	stone.room_coord = Vector2i(5, -4)
	add_child(stone)
	stone.awake = true
	stone.interact()
	_check(shown.size() == 2 and shown[1]["text"] == "STONE_SPIRE_FOOT", "facing a stone, Wren reads what's cut into it")
	GameState.set_flag("old_one_turned")
	# Turned at low water, the tide runs in (pinned: earlier tests' rooms
	# with tides run the shared clock on).
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	stone.interact()
	_check(shown.size() == 2 and Tide.held() == "high", "after the turn, a stone already read turns the tide")
	stone.room_coord = Vector2i(0, 0)
	stone.interact()
	_check(shown.size() == 4 and Tide.held() == "high", "an unread stone shows its carving first, even after the turn")
	Events.conversation_requested.disconnect(catch)
	stone.queue_free()
	Tide.offset = 0.0
	GameState.reset_new_game()


## Overworld secrets: chests hold what their room says, a cache holds a
## count, and the Ember Ridge jar sits behind a cracked boulder.
func _test_overworld_secrets() -> void:
	var expect := {
		Vector2i(8, -3): "jar", Vector2i(7, 1): "jar", Vector2i(4, 2): "coral_buckler",
		Vector2i(0, 3): "scaleweave", Vector2i(6, -4): "glint", Vector2i(1, -3): "glint",
		# Side areas off the main path.
		Vector2i(1, -1): "glint", Vector2i(7, -1): "glint", Vector2i(3, 3): "glint",
		# Out on the sea bed.
		Vector2i(2, 3): "glint", Vector2i(1, 4): "glint", Vector2i(0, 4): "glint",
		# The regional caves, one or two per region.
		Vector2i(0, 1): "glint", Vector2i(1, -4): "glint", Vector2i(3, 4): "glint", Vector2i(9, 2): "glint",
		Vector2i(8, -4): "glint", Vector2i(6, -3): "glint", Vector2i(2, -1): "glint", Vector2i(6, 2): "glint",
	}
	for coord: Vector2i in expect:
		var room: Room = (load("res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]) as PackedScene).instantiate()
		_check(room.chest_item == expect[coord] and room.layout.contains("C"), "room %s hides a chest of %s" % [coord, expect[coord]])
		if coord == Vector2i(8, -3):
			var rows := Room.parse_layout(room.layout)
			var sealed := rows.duplicate()
			sealed[2] = sealed[2].replace("Y", "#")
			_check(rows[2][4] == "Y" and not _walkable_from(sealed, Vector2i(10, 7)).has(Vector2i(2, 2)), "the Ember Ridge nook is sealed by a cracked boulder")
			var broken := rows.duplicate()
			broken[2] = broken[2].substr(0, 4) + "." + broken[2].substr(5)
			_check(_walkable_from(broken, Vector2i(10, 7)).has(Vector2i(2, 2)), "breaking the boulder opens the nook")
		if coord == Vector2i(6, -4):
			_check(room.chest_count == 30, "the Windmere sea stack holds 30 glints")
		if coord in [Vector2i(1, -1), Vector2i(7, -1), Vector2i(3, 3), Vector2i(0, 1), Vector2i(1, -4), Vector2i(3, 4), Vector2i(9, 2), Vector2i(8, -4), Vector2i(2, -1), Vector2i(6, 2)]:
			_check(room.chest_count >= 100 and tr(room.name_key) != room.name_key, "side area %s has a name and a cache of %d glints" % [coord, room.chest_count])
			_check(room.cave, "side area %s is shaded like a hollow" % coord)
			_check(Audio.ambience_for_room(room.biome, room.dungeon, room.ambience, room.cave) == "hollow", "side area %s sounds like a hollow" % coord)
		room.free()
	# Frost can't freeze lava: Cinder Hollow's islet still needs the hook or cloak.
	var hollow: Room = (load("res://rooms/room_7_-1.tscn") as PackedScene).instantiate()
	add_child(hollow)
	_check(hollow.is_lava() and hollow.freeze(Vector2i(9, 5)).is_empty() and hollow.tile_at(9, 5) == "~", "a frost arrow leaves Cinderreach's lava alone")
	hollow.queue_free()
	# A cache gives its whole count at once.
	GameState.reset_new_game()
	var chest := Chest.new()
	chest.room_coord = Vector2i(6, -4)
	chest.tile = Vector2i(21, 6)
	chest.item = "glint"
	chest.count = 30
	add_child(chest)
	var before := GameState.item_count("glint")
	chest.interact()
	_check(GameState.item_count("glint") == before + 30, "a glint cache gives all 30 glints")
	await _wait(0.1)
	chest.queue_free()
	GameState.reset_new_game()
	await _test_sea_glass()
	await _test_pearl_shards()
	await _test_progress()


## The Progress tab's counts (Completion): every errand flag is one the game
## sets, every room and dungeon belongs to a region, the totals match the
## world, and finding things moves the numbers.
func _test_progress() -> void:
	var sources := ""
	for path in ["res://scripts/dialogue/conversations.gd", "res://scripts/story/story_director.gd"]:
		sources += FileAccess.get_file_as_string(path)
	var ids := {}
	for quest: Dictionary in Completion.QUESTS:
		_check(not ids.has(quest["id"]), "errand %s is listed once" % quest["id"])
		ids[quest["id"]] = true
		_check(Completion.REGIONS.has(quest["region"]), "errand %s is in a region" % quest["id"])
		for key in ["start", "done"]:
			_check(sources.contains("\"%s\"" % quest[key]), "errand %s's %s flag %s is one the game uses" % [quest["id"], key, quest[key]])
	for region: String in Completion.REGIONS:
		var key := "REGION_" + region.to_upper()
		_check(tr(key) != key, "%s has a name" % region)
	var unplaced: Array = []
	for coord: Vector2i in RoomInfo.all():
		if not Completion.REGIONS.has(Completion.region_of(coord)):
			unplaced.append(coord)
	_check(unplaced.is_empty(), "every room, dungeons too, counts toward a region (%s)" % [unplaced])
	_check(Completion.region_of(Vector2i(10, 10)) == "brinewood" and Completion.region_of(Vector2i(44, 10)) == "saltmarrow",
		"a dungeon counts toward the region its door stands in")
	GameState.reset_new_game()
	var rows := Completion.tally()
	var all := Completion.totals(rows)
	_check(all["stones"][1] == Tidestone.CARVINGS.size(), "every carved Tidestone is counted (%d)" % all["stones"][1])
	_check(all["shards"][1] <= PearlShard.TOTAL, "the shards counted are the ones placed (%d)" % all["shards"][1])
	_check(all["glass"][1] > 0 and all["chests"][1] > 0 and all["done"][1] == Completion.QUESTS.size(), "sea-glass, chests and errands are all counted")
	var nothing := true
	for kind: String in Completion.KINDS:
		nothing = nothing and all[kind][0] == 0
	_check(nothing and not rows["saltmarrow"]["seen"], "a new file has found nothing and been nowhere")
	var quest: Dictionary = Completion.QUESTS[0]
	GameState.set_flag(quest["start"])
	GameState.set_flag(Completion.QUESTS[1]["done"])
	GameState.set_flag("tidestone_read_%d_%d" % [Tidestone.CARVINGS.keys()[0].x, Tidestone.CARVINGS.keys()[0].y])
	GameState.mark_seen(Vector2i(0, -1))
	rows = Completion.tally()
	all = Completion.totals(rows)
	_check(rows["saltmarrow"]["seen"] and rows[quest["region"]]["underway"][0] == 1 and all["underway"][0] == 1 and all["done"][0] == 1,
		"an errand asked shows underway, one done shows done, and a room walked shows its region")
	_check(all["stones"][0] == 1, "a carving read is counted")
	GameState.set_flag(quest["done"])
	_check(Completion.totals(Completion.tally())["underway"][0] == 0, "a finished errand stops being underway")
	GameState.reset_new_game()


## Pearl shards: every fourth adds a breath bubble. Walking over one picks
## it up and the box says how far to the next bubble; a chest can hold one;
## the Satchel shows them; the count and each shard's flag are saved.
func _test_pearl_shards() -> void:
	_check(Items.max_count("pearl_shard") == PearlShard.TOTAL and tr("ITEM_PEARL_SHARD") != "ITEM_PEARL_SHARD", "twelve pearl shards, named")
	var total := 0
	for coord: Vector2i in RoomInfo.in_area(""):
		total += "".join(RoomInfo.get_room(coord)["rows"]).count("8")
	# Eleven lie loose; the twelfth is the Smugglers' Vault's prize.
	var vault := (load("res://rooms/room_-2_0.tscn") as PackedScene).instantiate() as Room
	if vault.chest_item == "pearl_shard":
		total += 1
	vault.free()
	_check(total == PearlShard.TOTAL, "all twelve pearl shards are out in the world (%d)" % total)
	GameState.reset_new_game()
	GameState.give_item("pearl_shard", 3, false)
	_check(GameState.max_bubbles == GameState.START_BUBBLES, "three shards aren't a bubble yet")
	GameState.give_item("pearl_shard", 1, false)
	_check(GameState.max_bubbles == GameState.START_BUBBLES + 1 and GameState.bubbles == GameState.max_bubbles, "the fourth makes one more bubble, full")
	GameState.give_item("pearl_shard", 20, false)
	_check(GameState.item_count("pearl_shard") == PearlShard.TOTAL and GameState.max_bubbles == GameState.START_BUBBLES + 3, "twelve make three bubbles, and no more")
	_check(PearlShard.talk(0, 1)[0] == "GOT_PEARL_SHARD_FIRST" and "1" in PearlShard.talk(0, 1)[1], "the first shard explains itself and counts")
	_check(PearlShard.talk(3, 4)[0] == "GOT_PEARL_SHARD_WHOLE" and Array(PearlShard.talk(11, 12)).has("GOT_PEARL_SHARD_LAST"), "a fourth says it's whole, the twelfth that it's the last")
	_check(PearlShard.talk(3, 5)[0] == "GOT_PEARL_SHARD_WHOLE" and PearlShard.talk(3, 5).size() == 2 and PearlShard.talk(12, 12).is_empty(),
		"two at once can cross a bubble and still count on; none gained says nothing")
	_check(Chest.item_talk("pearl_shard").size() > 0, "a shard from a chest explains itself too")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(1, 1), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.5)
	var room: Room = game.current_room
	var player: Player = game.player
	var shard := PearlShard.new()
	shard.room_coord = room.coord
	# Away from where Wren wakes, so it isn't picked up at once.
	shard.tile = Vector2i(5, 6)
	shard.position = Vector2(5 * Room.TILE + 8, 6 * Room.TILE + 12)
	room.add_child(shard)
	var at := shard.global_position
	await _wait(0.1)
	_check(is_instance_valid(shard) and GameState.item_count("pearl_shard") == 0, "a shard lies waiting")
	player.frozen = true
	player.global_position = at
	await _wait(0.3)
	_check(GameState.item_count("pearl_shard") == 0 and is_instance_valid(shard), "not while Wren is held (a door's fade)")
	player.frozen = false
	await _wait(0.3)
	_check(GameState.item_count("pearl_shard") == 1 and not is_instance_valid(shard), "walking over a shard picks it up")
	_check(DialogueBox.is_open, "and the box explains it")
	await _play_scene(game, 5.0)
	_check(not DialogueBox.is_open and not get_tree().paused, "the box closes and play goes on")
	var page := SatchelPage.new()
	add_child(page)
	page.on_open()
	var cell := page._cells.find_custom(func(c: Dictionary) -> bool: return c["role"] == "shard")
	_check(cell >= 0 and page._owned_id(page._cells[cell]) == "pearl_shard", "the Satchel shows the shards")
	page.queue_free()
	var saved := GameState.to_dict()
	GameState.reset_new_game()
	GameState.from_dict(saved)
	var flag := "pearl_shard_%d_%d_5_6" % [room.coord.x, room.coord.y]
	_check(GameState.item_count("pearl_shard") == 1 and GameState.has_flag(flag), "the shard count and the shard's flag are saved")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## Twelve pieces of sea-glass, one per room; walking over one picks it up
## for good, and the count survives a save.
func _test_sea_glass() -> void:
	var total := 0
	for coord: Vector2i in RoomInfo.in_area(""):
		total += "".join(RoomInfo.get_room(coord)["rows"]).count("*")
	_check(total == SeaGlass.TOTAL and Items.max_count("sea_glass") == SeaGlass.TOTAL, "%d pieces of sea-glass in the overworld" % total)
	_check(tr("ITEM_SEA_GLASS") != "ITEM_SEA_GLASS", "sea-glass has a name")
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(1, 1), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.5)
	var glass: SeaGlass = null
	for child in game.current_room.get_children():
		if child is SeaGlass:
			glass = child
	_check(glass != null, "the Wreck's ruin holds a piece of sea-glass")
	if glass:
		var player: Player = game.player
		player.global_position = glass.global_position
		await _wait(0.3)
		_check(GameState.item_count("sea_glass") == 1 and not is_instance_valid(glass), "walking over sea-glass picks it up")
		var saved := GameState.to_dict()
		GameState.reset_new_game()
		GameState.from_dict(saved)
		_check(GameState.item_count("sea_glass") == 1 and GameState.has_flag("sea_glass_1_1"), "the sea-glass count and the piece's flag are saved")
		var again: Room = (load("res://rooms/room_1_1.tscn") as PackedScene).instantiate()
		again.coord = Vector2i(1, 1)
		add_child(again)
		await _wait(0.1)
		_check(not again.get_children().any(func(c: Node) -> bool: return c is SeaGlass and not c.is_queued_for_deletion()), "a piece picked up stays gone")
		again.queue_free()
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## Lullaby Point: open sea until the seventh bell; then the Old One's back
## and lip rise from the bay and its mouth leads into the Maw.
func _test_maw_approach() -> void:
	var flag := Tidebell.flag_for("tomb")
	GameState.reset_new_game()
	var scene := load("res://rooms/room_2_1.tscn") as PackedScene
	var calm: Room = scene.instantiate()
	add_child(calm)
	var rows := Room.parse_layout(calm.layout)
	_check(not calm.layout.contains("D") and not _walkable_from(rows, Vector2i(2, 9)).has(Vector2i(11, 5)), "before the seventh bell the bay at Lullaby Point is open sea")
	calm.free()
	GameState.set_flag(flag)
	var risen: Room = scene.instantiate()
	add_child(risen)
	rows = PackedStringArray()
	for row in Room.parse_layout(risen.layout):
		rows.append(row.replace("N", "p"))
	var lip := _child_of(risen, Prop).filter(func(p: Prop) -> bool: return p.kind == "N")
	_check(lip.size() == 1 and rows[4][11] == "D" and risen.door_to == Vector2i(44, 10), "after it, the Old One's lip rises with the Maw's door in its mouth")
	_check(_walkable_from(rows, Vector2i(2, 9)).has(Vector2i(11, 5)) and _walkable_from(rows, Vector2i(2, 9)).has(Vector2i(10, 5)), "its back makes a path out to the mouth")
	risen.free()
	GameState.clear_flag(flag)


## Equipment does something: swords hit harder by tier (bosses capped),
## shields turn shots aside when Wren faces them, tunics soak up hits.
func _test_equipment() -> void:
	GameState.reset_new_game()
	_check(GameState.equipped_item(Items.SHIELD) == "cork_buckler", "a new file starts with the cork buckler")
	_check(Player.sword_damage() == 1 and Player.sword_damage(null, true) == 2, "the driftwood sword: 1 a slash, 2 a spin")
	GameState.give_item("brinesteel_sword", 1, false)
	_check(GameState.equipped_item(Items.SWORD) == "brinesteel_sword" and Player.sword_damage() == 2, "brinesteel hits for 2")
	GameState.give_item("tidecaller_sword", 1, false)
	_check(Player.sword_damage() == 3 and Player.sword_damage(null, true) == 6, "the tidecaller hits for 3, a spin for 6")
	var boss := Node.new()
	boss.add_to_group("boss")
	_check(Player.sword_damage(boss) == 1 and Player.sword_damage(boss, true) == 2, "a boss takes 1 from a slash and 2 from a spin, whatever the sword")
	boss.free()

	# Tunics: of four one-bubble hits, oilskin pops 4, scaleweave 3, abyssal 2.
	for tunic: Array in [["oilskin", 4], ["scaleweave", 3], ["abyssal", 2]]:
		GameState.give_item(tunic[0], 1, false)
		GameState.equip(tunic[0])
		GameState.refill()
		GameState._hurt_owed = 0.0
		var popped := 0
		for i in 4:
			popped += GameState.hurt(1)
		_check(popped == tunic[1] and GameState.bubbles == GameState.max_bubbles - tunic[1], "%s: four hits pop %d bubbles (%d)" % [tunic[0], tunic[1], popped])
	GameState.equip("abyssal")
	GameState._hurt_owed = 0.0
	_check(GameState.hurt(2) == 1, "the abyssal tunic halves a heavy hit")

	# A file from before shields mattered gets the cork buckler on load.
	GameState.reset_new_game()
	var old := GameState.to_dict()
	old["inventory"].erase("cork_buckler")
	old["equipped"].erase(Items.SHIELD)
	GameState._hurt_owed = 0.4
	GameState.from_dict(old)
	_check(GameState.equipped_item(Items.SHIELD) == "cork_buckler", "an older file is given the cork buckler")
	_check(GameState._hurt_owed == 0.0, "loading a file forgets a part-paid hit")

	# Shields, in play.
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i.ZERO, Vector2(11 * Room.TILE + 8, 9 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	var room: Room = game.current_room
	await _calm(room)
	var player: Player = game.player
	player.facing = Vector2.UP
	var bubbles := GameState.bubbles
	var shot := Projectile.new()
	room.add_child(shot)
	shot.global_position = player.global_position + Vector2(0, -10)
	await _wait(0.15)
	_check(not is_instance_valid(shot) and GameState.bubbles == bubbles, "the cork buckler turns aside a bubble shot from the front")
	var behind := Projectile.new()
	room.add_child(behind)
	behind.global_position = player.global_position + Vector2(0, -1)
	await _wait(0.15)
	_check(GameState.bubbles == bubbles - 1, "a shot from behind still hurts")
	player._invuln = 0.0
	await _wait(0.4)
	GameState.refill()
	bubbles = GameState.bubbles
	var ice := IceChunk.new()
	room.add_child(ice)
	ice.global_position = player.global_position + Vector2(0, -10)
	await _wait(0.15)
	_check(GameState.bubbles == bubbles - 1, "cork can't stop a chunk of ice")
	player._invuln = 0.0
	await _wait(0.4)
	GameState.give_item("coral_buckler", 1, false)
	GameState.refill()
	bubbles = GameState.bubbles
	player.facing = Vector2.UP
	var ice2 := IceChunk.new()
	room.add_child(ice2)
	ice2.global_position = player.global_position + Vector2(0, -10)
	await _wait(0.15)
	_check(GameState.equipped_item(Items.SHIELD) == "coral_buckler" and GameState.bubbles == bubbles, "the coral buckler does")
	var slag := SlagGlob.new()
	room.add_child(slag)
	slag.global_position = player.global_position + Vector2(0, -10)
	await _wait(0.15)
	_check(GameState.bubbles == bubbles - 1, "molten slag gets through coral")

	# A soaked hit still breaks a hum and makes Wren reel, but pops nothing.
	await _wait(0.5)
	GameState.give_item("abyssal", 1, false)
	GameState.refill()
	GameState._hurt_owed = 0.0
	player._invuln = 0.0
	player.take_damage(1, player.global_position + Vector2(10, 0))
	_check(GameState.bubbles == GameState.max_bubbles - 1, "abyssal: the first hit pops a bubble")
	await _wait(0.6)
	player._invuln = 0.0
	player._enter(Player.State.HUM)
	player.take_damage(1, player.global_position + Vector2(10, 0))
	_check(GameState.bubbles == GameState.max_bubbles - 1 and player.state == Player.State.HURT, "the next is soaked up, but it breaks the hum")
	game.queue_free()
	await _wait(0.1)


## Sea-glass shows in the satchel, with its count, only once a piece is found.
func _test_satchel_sea_glass() -> void:
	GameState.reset_new_game()
	var page := SatchelPage.new()
	add_child(page)
	page.on_open()
	var shown := func() -> bool:
		return page._cells.any(func(c: Dictionary) -> bool: return c["id"] == "sea_glass")
	_check(not shown.call(), "no sea-glass in the satchel before any is found")
	GameState.give_item("sea_glass", 3, false)
	page.on_open()
	_check(shown.call(), "found sea-glass shows in the satchel")
	page._cursor = page._cells.size() - 1
	_check(page._owned_id(page._cells[page._cursor]) == "sea_glass", "the sea-glass cell can be looked at")
	# Every Breath Pearl and pearl shard there is: the most breath, and a
	# full shelf that stays inside its panel.
	GameState.give_item("breath_pearl", Items.max_count("breath_pearl"), false)
	GameState.give_item("pearl_shard", Items.max_count("pearl_shard"), false)
	var most := GameState.START_BUBBLES + Items.max_count("breath_pearl") + Items.max_count("pearl_shard") / Items.SHARDS_PER_BUBBLE
	_check(GameState.max_bubbles == GameState.MAX_BUBBLES and most == GameState.MAX_BUBBLES,
		"every Breath Pearl and pearl shard together give the most breath (%d)" % GameState.max_bubbles)
	page.on_open()
	var pearls := page._cells.filter(func(c: Dictionary) -> bool: return c["role"] == "pearl")
	_check(pearls.size() == Items.max_count("breath_pearl"), "the satchel has a place for every Breath Pearl")
	for cell: Dictionary in page._cells:
		var drawn := Rect2(cell["rect"].position, (cell["rect"].size as Vector2).max(Vector2(16, 16)))
		_check(SatchelPage.KEEPER_PANEL.encloses(drawn) or SatchelPage.TOOLS_PANEL.encloses(drawn) or SatchelPage.GEAR_PANEL.encloses(drawn),
			"satchel cell %s %d sits inside its panel" % [cell["role"], cell["index"]])
	# The plate behind the breath bubbles stops short of the item keys.
	_check(2 + GameState.MAX_BUBBLES * Hud.BUBBLE_SPACING + 5 < ItemSlotsHud.SLOT_AT[0].x - 4, "the most breath fits beside the item keys")
	page.queue_free()
	GameState.reset_new_game()


## Ottilie's Knits: bought once from her stock, worn by Wren, changed in
## the Satchel, kept in the save.
func _test_jumpers() -> void:
	GameState.reset_new_game()
	_check(Jumpers.owned() == [""] and GameState.jumper == "", "a new file has only the keeper's navy")
	var stock := Jumpers.stock()
	_check(stock.size() == Jumpers.ORDER.size() and stock.all(func(r: Dictionary) -> bool: return tr(r["name"]) != r["name"] and tr(r["info"]) != r["info"]),
		"every knit is for sale, named and described")
	GameState.set_checkpoint(StoryDirector.SALTMARROW, GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.3)
	GameState.give_item("glint", 200, false)
	var menu := ShopMenu.new()
	menu.stock = stock
	menu.keeper = {"portrait": Art.PORTRAIT_OTTILIE, "name": "NAME_OTTILIE", "title": "SHOP_TITLE_OTTILIE"}
	game.add_child(menu)
	await _wait(0.3)
	_check(menu.buy(0) and GameState.has_flag("jumper_kelp") and GameState.jumper == "kelp" and GameState.item_count("glint") == 50,
		"buying a knit costs its price and Wren puts it on")
	_check(not menu.buy(0) and ShopMenu.blocked(stock[0]) == "SHOP_OWNED", "a knit is bought once")
	_check(not menu.buy(1) and GameState.item_count("glint") == 50, "a knit beyond the purse stays on the shelf")
	# Five knits and Leave: the list scrolls to keep the cursor in view.
	for i in stock.size():
		var down := InputEventAction.new()
		down.action = "move_down"
		down.pressed = true
		menu._input(down)
	_check(menu._cursor == stock.size() and menu._top == stock.size() + 1 - ShopMenu.VISIBLE, "the knits scroll down to Leave")
	menu.close()
	await _wait(0.2)
	var material := game.player._body.material as ShaderMaterial
	_check(int(material.get_shader_parameter("swap_count")) == 5, "Wren's stripes take the knit's colours")
	_check(Jumpers.owned() == ["", "kelp"] and Jumpers.next("kelp") == "" and Jumpers.next("") == "kelp", "the Satchel cycles the jumpers Wren owns")
	var page := SatchelPage.new()
	add_child(page)
	page.on_open()
	var cell := page._cells.find_custom(func(c: Dictionary) -> bool: return c["role"] == "jumper")
	_check(cell >= 0 and SatchelPage.GEAR_PANEL.encloses(page._cells[cell]["rect"]), "the Satchel shows the jumper once there's a choice")
	if cell >= 0:
		page._cursor = cell
		var press := InputEventAction.new()
		press.action = "interact"
		press.pressed = true
		page.handle_input(press)
		_check(GameState.jumper == "", "the Satchel changes the jumper")
	page.queue_free()
	await _wait(0.1)
	_check(int(material.get_shader_parameter("swap_count")) == 0, "back in the keeper's navy")
	GameState.jumper = "kelp"
	var saved := GameState.to_dict()
	GameState.from_dict(saved)
	_check(GameState.jumper == "kelp", "the jumper is saved")
	var over := GameOverScreen.new()
	add_child(over)
	_check(int((over._wren.material as ShaderMaterial).get_shader_parameter("swap_count")) == 5, "Wren sinks in the knit they wear")
	over.free()
	saved["jumper"] = "storm"
	GameState.from_dict(saved)
	_check(GameState.jumper == "", "a save can't wear a jumper it never bought")
	game.queue_free()
	await get_tree().process_frame
	GameState.reset_new_game()


## Marlo Pike's stall in Saltmarrow: a word across the counter, then wares
## bought with glints.
func _test_shop() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.SALTMARROW, GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var stall := get_tree().get_first_node_in_group("market_stall") as MarketStall
	_check(stall != null and game.current_room.is_ancestor_of(stall), "Marlo Pike's stall stands in Saltmarrow")
	if stall == null:
		game.queue_free()
		return
	var feet: float = stall.marlo.get_global_transform_with_canvas().origin.y
	_check(feet + Room.TILE < DialogueBox.HIGHEST_POINT, "Marlo stays clear of the dialogue box (%d vs %d)" % [feet + Room.TILE, DialogueBox.HIGHEST_POINT])
	for child in game.get_children():
		if child is DialogueBox:
			_check(child.lines_for("MARLO_THANKS", true) <= DialogueBox.MAX_LINES, "Marlo's thanks fit the box")
	_check(ShopMenu.rows().all(func(r: Dictionary) -> bool: return r.get("id", "") != "puffer_bombs"), "no puffer bombs before the Hull")
	# Wren steps up to the counter and talks.
	game.player.global_position = stall.global_position + Vector2(0, 14)
	game.player.facing = Vector2.UP
	await _wait(0.1)
	GameState.give_item("glint", 100, false)
	_check(game.player.try_interact(), "Wren can talk across the counter")
	_check(DialogueBox.is_open and GameState.has_flag("met_marlo"), "Marlo introduces himself")
	_finish_talk(game)
	await _wait(0.3)
	var menu := get_tree().get_first_node_in_group("shop_menu") as ShopMenu
	_check(menu != null and get_tree().paused, "then his wares come up, with the game paused")
	if menu == null:
		game.queue_free()
		return
	var oil := -1
	var tonic := -1
	var rows := ShopMenu.rows()
	for i in rows.size():
		if rows[i].get("id", "") == "lamp_oil":
			oil = i
		elif rows[i].has("jar"):
			tonic = i
	_check(menu.buy(oil) and GameState.item_count("lamp_oil") == 3 and GameState.item_count("glint") == 85, "lamp oil costs 15 glints")
	_check(not "lamp_oil" in GameState.item_slots, "bought goods wait in the satchel, off the item slots")
	_check(ShopMenu.blocked(rows[tonic]) == "SHOP_NO_JAR" and not menu.buy(tonic) and GameState.item_count("glint") == 85, "no tonic without an empty jar")
	GameState.give_item("jar", 1, false)
	_check(menu.buy(tonic) and GameState.jars[0] == Items.JAR_POTION and GameState.item_count("glint") == 55, "kelp tonic fills the jar for 30")
	_check(ShopMenu.blocked(rows[tonic]) == "SHOP_NO_JAR", "a full jar takes no more")
	GameState.take_item("glint", 50)
	_check(not menu.buy(oil) and GameState.item_count("lamp_oil") == 3 and GameState.item_count("glint") == 5, "Marlo gives no credit")
	GameState.give_item("lamp_oil", 5, false)
	_check(GameState.item_count("lamp_oil") == 8 and ShopMenu.blocked(rows[oil]) == "SHOP_FULL", "no paying for three when only two more fit")
	menu.close()
	_check(ShopMenu.recently_closed(), "the press that closes the shop doesn't reach Wren")
	await _wait(0.1)
	_check(DialogueBox.is_open, "Marlo thanks Wren for the trade")
	_finish_talk(game)
	await _wait(0.1)
	_check(not get_tree().paused and get_tree().get_first_node_in_group("shop_menu") == null, "the game carries on after the shop")
	# After the Hull, puffers.
	GameState.set_flag("tidebell_hull")
	_check(ShopMenu.rows()[0]["id"] == "puffer_bombs", "puffer bombs are stocked after the Hull")
	_check(Conversations.branch_for("marlo")["lines"][0] == "MARLO_PUFFERS_1", "and Marlo says so")
	game.queue_free()
	await _wait(0.1)


## Home after the credits: the Old One dreams, and the lighthouse points
## its beam out to sea, towards the Maw, until Wren has been back to the Heart.
func _test_dream() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.ENDING_FLAG)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, GameState.NO_POSITION)
	var home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	await _wait(0.3)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.DREAM_FLAG), "back home after the credits, the Old One dreams")
	for child in home.get_children():
		if child is DialogueBox:
			for key in ["HESSA_DREAM_1", "HESSA_DREAM_2", "HESSA_AFTER_END"]:
				_check(child.lines_for(key, true) <= DialogueBox.MAX_LINES, "%s fits the box" % key)
	var pages := await _play_scene(home, 20.0)
	_check(pages == 2 and not Cutscene.active, "Hessa felt it too (%d pages)" % pages)
	var beam := get_tree().get_first_node_in_group("lighthouse_beam") as LighthouseBeam
	_check(beam != null and absf(beam.angle - LighthouseBeam.SEAWARD) < 0.01, "the lighthouse turns its beam out to sea, towards the Maw")
	_check(Conversations.branch_for("hessa")["lines"][0] == "HESSA_AFTER_END", "Hessa still feels it breathing")
	home.queue_free()
	await _wait(0.1)
	home = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	await _wait(0.3)
	_check(not Cutscene.active and get_tree().get_first_node_in_group("lighthouse_beam") != null, "the scene plays once; the beam stays lit")
	home.queue_free()
	await _wait(0.1)
	# Down at the sleeping Heart again, the beam can rest.
	GameState.set_flag(DreamingHeart.DEFEATED_FLAG)
	GameState.set_checkpoint(Vector2i(44, 6), GameState.NO_POSITION)
	var heart: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(heart)
	await _wait(0.3)
	_check(GameState.has_flag(StoryDirector.HEART_VISIT_FLAG) and not Cutscene.active, "Wren goes back down to the Heart")
	heart.queue_free()
	await _wait(0.1)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, GameState.NO_POSITION)
	home = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	await _wait(0.3)
	_check(get_tree().get_first_node_in_group("lighthouse_beam") == null, "and the lighthouse rests")
	home.queue_free()
	await _wait(0.1)
	Cutscene.fast = false


## Cutscene 13: young Hessa's and Vael's journal, frozen through the Hollow
## Glacier, and the vision after Rimeback.
func _test_journal() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(32, 10), GameState.NO_POSITION)
	var glacier: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(glacier)
	await _wait(0.3)
	var page := get_tree().get_first_node_in_group("journal_page") as JournalPage
	_check(page != null and page.page == 1, "the first page lies frozen at the glacier's mouth")
	for child in glacier.get_children():
		if child is DialogueBox:
			for number in JournalPage.PAGES:
				for p: Dictionary in JournalPage.pages_for(number):
					_check(child.lines_for(p["text"], p["portrait"] != null) <= DialogueBox.MAX_LINES, "%s fits the box" % p["text"])
					_check(TranslationServer.translate(p["text"]) != p["text"], "%s is in strings.csv" % p["text"])
	if page:
		glacier.player.global_position = page.global_position + Vector2(0, 14)
		glacier.player.facing = Vector2.UP
		await _wait(0.1)
		_check(glacier.player.try_interact() and DialogueBox.is_open, "Wren reads it where it lies")
		_finish_talk(glacier)
		_check(GameState.has_flag(JournalPage.flag_for(1)), "and it stays read")
	glacier.queue_free()
	await _wait(0.1)
	# Every page has a floor to lie on.
	for coord: Vector2i in StoryDirector.JOURNAL_PAGES:
		var tile: Vector2i = StoryDirector.JOURNAL_PAGES[coord][0]
		var row: String = RoomInfo.get_room(coord).get("rows", [])[tile.y] if RoomInfo.get_room(coord).has("rows") else ""
		_check(row == "" or row[tile.x] == ".", "page %d lies on open floor" % StoryDirector.JOURNAL_PAGES[coord][1])
	# Rimeback calmed: the last page rises out of the ice.
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.GLACIER_BOSS, Vector2(5 * Room.TILE + 8, 3 * Room.TILE + 12))
	var hall: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(hall)
	await _wait(0.3)
	_check(get_tree().get_first_node_in_group("journal_page") == null, "no last page while Rimeback is up")
	# As Rimeback itself does: the flag written quietly, then the fight's end
	# (with the beast itself gone, so it can't knock Wren about meanwhile).
	for boss in get_tree().get_nodes_in_group("boss"):
		boss.queue_free()
	await _wait(0.05)
	GameState.flags[Rimeback.DEFEATED_FLAG] = true
	Events.boss_defeated.emit()
	await _wait(0.2)
	var last := get_tree().get_first_node_in_group("journal_page") as JournalPage
	_check(last != null and last.page == JournalPage.LAST, "once it calms, the last page rises out of the ice")
	if last:
		await _wait(2.0)
		hall.player.global_position = last.global_position + Vector2(0, 14)
		hall.player.facing = Vector2.UP
		await _wait(0.1)
		hall.player.try_interact()
		await _wait(0.1)
		_check(Cutscene.active and GameState.has_flag(StoryDirector.JOURNAL_FLAG), "reading it brings the vision")
		var pages := await _play_scene(hall, 30.0)
		_check(pages == 4 and not Cutscene.active, "Vael's last page, and Hessa's later words (%d pages)" % pages)
		_check(not hall.current_room.get_children().any(func(c: Node) -> bool: return c is ChoirFigure), "the young keepers fade with the vision")
		await _wait(0.2)
		hall.player.try_interact()
		await _wait(0.1)
		_check(not Cutscene.active and DialogueBox.is_open, "read again, it's only the page: the vision doesn't replay")
		await _play_scene(hall, 5.0)
	hall.queue_free()
	await _wait(0.1)
	Cutscene.fast = false


## Cutscene 16: Tobin meets Wren on Skull Rise once the seventh bell rings,
## then comes home to Dunstan, and stays on the dock after.
func _test_tobin() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.SKULL_RISE, Vector2(16 * Room.TILE + 8, 8 * Room.TILE + 10))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(not Cutscene.active and not GameState.has_flag(StoryDirector.TOBIN_WARNED_FLAG), "no Tobin on Skull Rise before the Tomb's bell")
	game.queue_free()
	await _wait(0.1)
	GameState.set_flag(StoryDirector.TOMB_BELL_FLAG)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(Cutscene.active and GameState.has_flag(StoryDirector.TOBIN_WARNED_FLAG), "with the seventh bell rung, Tobin comes running over the dunes")
	var room: Room = game.current_room
	for point: Vector2 in StoryDirector.TOBIN_RUNS_IN.slice(1) + StoryDirector.TOBIN_LEAVES.slice(0, 1):
		var tile := Vector2i(floori(point.x / Room.TILE), floori(point.y / Room.TILE))
		_check(room.tile_at(tile.x, tile.y) == ".", "Tobin's path crosses open sand at %s" % tile)
	var pages := await _play_scene(game, 30.0)
	_check(pages == 5 and not Cutscene.active, "he tells Wren where the Choir went and how singers go in (%d pages)" % pages)
	_check(not room.get_children().any(func(c: Node) -> bool: return c is ChoirFigure), "and heads off west, home")
	game.queue_free()
	await _wait(0.1)
	# Home: Tobin on the dock by his dad.
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(12 * Room.TILE + 8, 11 * Room.TILE + 10))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(Cutscene.active, "back in Saltmarrow, Tobin's home")
	pages = await _play_scene(game, 30.0)
	_check(pages >= 6 and not Cutscene.active and GameState.has_flag(StoryDirector.TOBIN_HOME_FLAG), "Dunstan finds his words (%d pages)" % pages)
	_check(game.player.global_position.distance_to(game.current_room.global_position + StoryDirector.WREN_AT_DOCK) < 6.0, "Wren walks up to the pair (%s)" % (game.player.global_position - game.current_room.global_position))
	var tobins: Array = game.current_room.get_children().filter(func(c: Node) -> bool: return c is Npc and c.kind == "tobin")
	_check(tobins.size() == 1, "Tobin stays on the dock, someone to talk to")
	_check(Conversations.branch_for("dunstan").get("lines", []) == ["DUNSTAN_TOBIN_AFTER"], "and Dunstan has a new line about him")
	GameState.set_flag("asked_for_rope")
	_check(Conversations.branch_for("dunstan").get("set", []) == ["rope_promised"], "Marga's rope errand still works with Tobin home")
	GameState.clear_flag("asked_for_rope")
	game.queue_free()
	await _wait(0.1)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(not Cutscene.active, "the homecoming plays once")
	_check(game.current_room.get_children().filter(func(c: Node) -> bool: return c is Npc and c.kind == "tobin").size() == 1, "and Tobin's still there next time")
	game.queue_free()
	await _wait(0.1)
	Cutscene.fast = false


## Cutscene 17: Hessa rows Wren out to the Maw, or waits there in her boat.
func _test_rowing() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	for flag in ["met_hessa", "seen_wayshell", StoryDirector.CONFESSION_FLAG, StoryDirector.TURNED_FLAG, StoryDirector.TOMB_BELL_FLAG]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(18 * Room.TILE + 8, 6 * Room.TILE + 10))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(not Cutscene.active, "home quietly, with Hessa there")
	game.player.facing = Vector2.UP
	await _wait(0.05)
	game.player.try_interact()
	await _wait(0.2)
	_check(GameState.has_flag(StoryDirector.ROW_ASKED_FLAG), "with all seven bells rung she offers to row Wren out")
	var pages := await _play_scene(game, 40.0)
	_check(pages >= 5 and not Cutscene.active, "she rows them over and has her say about Vael (%d pages)" % pages)
	_check(GameState.room_coord == StoryDirector.LULLABY_POINT and GameState.has_flag(StoryDirector.ROWED_FLAG), "and leaves Wren at Lullaby Point")
	_check(not game.current_room.get_children().any(func(c: Node) -> bool: return c is Rowboat), "then rows herself home")
	_check(game.player.global_position.distance_to(game.current_room.global_position + StoryDirector.WREN_AT_BOAT) < 4.0, "Wren stands on the shore by the boat")
	var shore := Vector2i(floori(StoryDirector.WREN_AT_BOAT.x / Room.TILE), floori(StoryDirector.WREN_AT_BOAT.y / Room.TILE))
	var water := Vector2i(floori(StoryDirector.BOAT_AT.x / Room.TILE), floori(StoryDirector.BOAT_AT.y / Room.TILE))
	_check(game.current_room.tile_at(shore.x, shore.y) == "." and game.current_room.tile_at(water.x, water.y) == "~", "on sand, with the boat on the water")
	game.queue_free()
	await _wait(0.1)
	# On foot instead: she's out there waiting.
	GameState.clear_flag(StoryDirector.ROW_ASKED_FLAG)
	GameState.clear_flag(StoryDirector.ROWED_FLAG)
	GameState.set_checkpoint(StoryDirector.LULLABY_POINT, Vector2(1 * Room.TILE + 8, 9 * Room.TILE + 10))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(Cutscene.active, "walking to Lullaby Point, Hessa's waiting in her boat")
	pages = await _play_scene(game, 40.0)
	_check(pages >= 4 and not Cutscene.active and GameState.has_flag(StoryDirector.ROWED_FLAG), "she says she came to find them (%d pages)" % pages)
	_check(game.player.global_position.distance_to(game.current_room.global_position + StoryDirector.WREN_AT_BOAT) < 4.0, "Wren walks down to the boat")
	game.queue_free()
	await _wait(0.1)
	Cutscene.fast = false


## Wick at Fenmouth, who counts the fen's lanterns, and the five gone dark
## that the raised Glowmoth Lantern lights again.
func _test_wick() -> void:
	GameState.reset_new_game()
	GameState.give_item("glowmoth_lantern")
	var talk_at := Vector2(StoryDirector.WICK_AT.x - 14, StoryDirector.WICK_AT.y)
	GameState.set_checkpoint(StoryDirector.FENMOUTH, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "wick") != null, "Wick stands at Fenmouth")
	game.player.facing = Vector2.RIGHT
	await _wait(0.05)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages >= 2 and GameState.has_flag("wick_asked"), "they ask Wren to light the dark lanterns (%d pages)" % pages)
	game.queue_free()
	await _wait(0.1)
	var jars := GameState.item_count("jar")
	for coord: Vector2i in FenLantern.SPOTS:
		var tile: Vector2i = FenLantern.SPOTS[coord]
		var at := Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12)
		GameState.set_checkpoint(coord, at + Vector2(0, -20))
		game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.3)
		var room: Room = game.current_room
		_check(room.tile_at(tile.x, tile.y) == ".", "%s's lantern stands on dry ground" % coord)
		var lanterns: Array = room.get_children().filter(func(c: Node) -> bool: return c is FenLantern)
		_check(lanterns.size() == 1 and not (lanterns[0] as FenLantern).lit, "%s has a dark lantern" % coord)
		# Walking past with the lantern down does nothing.
		game.player.global_position = room.global_position + at + Vector2(0, 10)
		await _wait(0.2)
		_check(not (lanterns[0] as FenLantern).lit, "only the raised lantern lights it")
		_check(game.player.use_item("glowmoth_lantern") and game.player.lantern_raised, "Wren raises the Glowmoth Lantern")
		await _wait(0.2)
		_check((lanterns[0] as FenLantern).lit and GameState.has_flag(FenLantern.flag_for(coord)), "%s's lantern catches" % coord)
		game.player.use_item("glowmoth_lantern")
		game.queue_free()
		await _wait(0.1)
	_check(GameState.has_flag(FenLantern.ALL_LIT_FLAG), "all five burn again")
	# They stay lit.
	var first: Vector2i = FenLantern.SPOTS.keys()[0]
	GameState.set_checkpoint(first, Vector2(12 * Room.TILE + 8, 6 * Room.TILE + 10))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.3)
	var again: Array = game.current_room.get_children().filter(func(c: Node) -> bool: return c is FenLantern)
	_check(again.size() == 1 and (again[0] as FenLantern).lit, "and stay lit")
	game.queue_free()
	await _wait(0.1)
	GameState.set_checkpoint(StoryDirector.FENMOUTH, talk_at)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	game.player.facing = Vector2.RIGHT
	await _wait(0.05)
	game.player.try_interact()
	pages = await _play_scene(game, 10.0)
	_check(GameState.has_flag("wick_gave_jar") and GameState.item_count("jar") == jars + 1, "Wick gives Wren a jar")
	_check(Conversations.branch_for("wick").get("lines")[0] == "WICK_SINK_1", "then wonders about the Lampless Sink")
	GameState.set_flag("wick_told_sink")
	_check(Conversations.branch_for("wick").get("lines") == ["WICK_AFTER"], "and is glad of every light")
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("wick").get("lines")[0] == "WICK_END", "after the ending they counted the strange lights leaving")
	game.queue_free()
	await _wait(0.1)


## Liesl in Drowned Lane, and her great-grandmother's door bell out on
## Belfry Square's flats, there to find only at low tide.
func _test_liesl() -> void:
	GameState.reset_new_game()
	var talk_at := Vector2(StoryDirector.LIESL_AT.x - 14, StoryDirector.LIESL_AT.y)
	GameState.set_checkpoint(StoryDirector.DROWNED_LANE, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room: Room = game.current_room
	_check(_find_kind(room, "liesl") != null, "Liesl sweeps at the head of Drowned Lane")
	_check(room.tile_at(floori(StoryDirector.LIESL_AT.x / Room.TILE), floori(StoryDirector.LIESL_AT.y / Room.TILE)) == "." and StoryDirector.LIESL_AT.y < 9 * Room.TILE, "on dry ground, clear of the dialogue box")
	game.player.facing = Vector2.RIGHT
	await _wait(0.05)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages >= 2 and GameState.has_flag("liesl_asked"), "she asks after her great-grandmother's door bell (%d pages)" % pages)
	game.queue_free()
	await _wait(0.1)
	# Out on Belfry Square's flats: the bell is there only while the tide's out.
	var was := Tide.offset
	Tide.offset = Tide.offset_for(Tide.Phase.HIGH, 0.5)
	var find_at := StoryDirector.DOORBELL_LOST_AT + Vector2(-14, 0)
	GameState.set_checkpoint(StoryDirector.BELFRY_SQUARE, Vector2(12 * Room.TILE + 8, 5 * Room.TILE + 10))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.3)
	room = game.current_room
	var bells: Array = room.get_children().filter(func(c: Node) -> bool: return c is Doorbell)
	_check(bells.size() == 1 and not (bells[0] as Doorbell).visible, "at high tide the flats keep the bell")
	_check(room.tile_at(floori(StoryDirector.DOORBELL_LOST_AT.x / Room.TILE), floori(StoryDirector.DOORBELL_LOST_AT.y / Room.TILE)) == "r", "it lies on the tide flats")
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	await _wait(0.6)
	game.player.global_position = room.global_position + find_at
	game.player.facing = Vector2.RIGHT
	await _wait(0.1)
	_check(bells.size() == 1 and (bells[0] as Doorbell).visible, "at low tide it glints in the sand")
	game.player.try_interact()
	await _wait(0.2)
	_check(GameState.has_flag("found_doorbell"), "Wren picks it up")
	await _close_dialogue(game)
	await _wait(0.1)
	_check(bells.size() == 1 and not (bells[0] as Doorbell).visible, "and it's gone from the sand")
	game.queue_free()
	await _wait(0.1)
	# Back to Liesl with it.
	var glints := GameState.item_count("glint")
	GameState.set_checkpoint(StoryDirector.DROWNED_LANE, talk_at)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	game.player.facing = Vector2.RIGHT
	await _wait(0.05)
	game.player.try_interact()
	pages = await _play_scene(game, 10.0)
	_check(GameState.has_flag("liesl_bell_hung") and GameState.item_count("glint") == glints + 50, "she takes it back and gives Wren 50 old coins")
	_check(not game.current_room.get_children().any(func(c: Node) -> bool: return c is Doorbell), "she hangs it once Wren's gone")
	game.queue_free()
	await _wait(0.1)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var hung: Array = game.current_room.get_children().filter(func(c: Node) -> bool: return c is Doorbell and c.hung)
	_check(hung.size() == 1, "next time, the bell hangs by the drowned cottage's door")
	_check(Conversations.branch_for("liesl").get("lines") == ["LIESL_AFTER"], "and Liesl's glad of it")
	GameState.set_flag("tidebell_belfry")
	_check(Conversations.branch_for("liesl").get("lines")[0] == "LIESL_VERGE", "with the Verge Bell rung, her little one rings back")
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("liesl").get("lines") == ["LIESL_END"], "and after the ending she has her own word")
	game.queue_free()
	await _wait(0.1)
	Tide.offset = was


func _find_kind(room: Node, kind: String) -> Npc:
	for child in room.get_children():
		if child is Npc and child.kind == kind:
			return child
	return null


## Ide's ferry at Causeway End: tied up while the Belfry's bell rings
## wrong, then over the channel and back by the hand bell.
func _test_ide() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	var talk_at := Vector2(StoryDirector.IDE_AT.x - 14, StoryDirector.IDE_AT.y)
	GameState.set_checkpoint(StoryDirector.CAUSEWAY_END, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room: Room = game.current_room
	var ides: Array = room.get_children().filter(func(c: Node) -> bool: return c is Npc and c.kind == "ide")
	var boats: Array = room.get_children().filter(func(c: Node) -> bool: return c is Rowboat)
	_check(ides.size() == 1 and boats.size() == 1 and (boats[0] as Rowboat).rider == null, "Ide stands on the north shore by her empty boat")
	_check(not room.get_children().any(func(c: Node) -> bool: return c is FerryBell), "no bell on the far landing while the Belfry still rings")
	for at: Vector2 in [StoryDirector.IDE_AT, StoryDirector.WREN_NORTH, StoryDirector.WREN_NORTH_EAST, StoryDirector.WREN_SOUTH, StoryDirector.FERRY_BELL_AT]:
		_check(room.tile_at(floori(at.x / Room.TILE), floori(at.y / Room.TILE)) == ".", "the ferry's footing at %s is dry ground" % at)
	for at: Vector2 in [StoryDirector.FERRY_NORTH, StoryDirector.FERRY_SOUTH]:
		_check(room.tile_at(floori(at.x / Room.TILE), floori(at.y / Room.TILE)) == "~", "the boat at %s sits on the channel" % at)
	_check(StoryDirector.IDE_AT.y < 9 * Room.TILE, "Ide stands clear of the dialogue box")
	game.player.facing = Vector2.RIGHT
	await _wait(0.05)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages >= 1 and not GameState.has_flag(StoryDirector.FERRY_FLAG) and not Cutscene.active, "before the Belfry's bell she won't put a boat out")
	# The Belfry's bell is quiet: she rows Wren over.
	GameState.set_flag("tidebell_belfry")
	game.player.global_position = room.global_position + talk_at
	game.player.facing = Vector2.RIGHT
	await _wait(0.05)
	game.player.try_interact()
	pages = await _play_scene(game, 40.0)
	_check(pages >= 2 and GameState.has_flag("met_ide_ferry") and not GameState.has_flag(StoryDirector.FERRY_FLAG), "she offers the ferry and rows (%d pages)" % pages)
	_check(game.player.global_position.distance_to(room.global_position + StoryDirector.WREN_SOUTH) < 4.0, "Wren lands on the south landing (at %s)" % (game.player.global_position - room.global_position))
	var boat: Rowboat = boats[0]
	_check(boat.position.distance_to(StoryDirector.FERRY_NORTH) < 1.0 and boat.rider == null and (ides[0] as Npc).visible, "and Ide rows home and steps back onto her shore")
	game.queue_free()
	await _wait(0.1)
	# Back from the south: the bell on the landing calls her over.
	GameState.set_checkpoint(StoryDirector.CAUSEWAY_END, StoryDirector.FERRY_BELL_AT + Vector2(0, 10))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	room = game.current_room
	var bells: Array = room.get_children().filter(func(c: Node) -> bool: return c is FerryBell)
	_check(bells.size() == 1, "now a hand bell hangs on the south landing")
	game.player.facing = Vector2.UP
	await _wait(0.05)
	game.player.try_interact()
	await _wait(0.1)
	_check(Cutscene.active, "ringing it brings Ide over")
	pages = await _play_scene(game, 40.0)
	_check(not Cutscene.active and not GameState.has_flag(StoryDirector.FERRY_FLAG), "she rows Wren back without a word (%d pages)" % pages)
	_check(game.player.global_position.distance_to(room.global_position + StoryDirector.WREN_NORTH) < 4.0, "back on the north shore (at %s)" % (game.player.global_position - room.global_position))
	# The talk after the first ride, and after the ending.
	_check(Conversations.branch_for("ide").get("lines") == ["IDE_FERRY_AGAIN"], "the next time it's just a nod over")
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("ide").get("lines") == ["IDE_END"], "after the ending she'd row Wren anywhere")
	game.queue_free()
	await _wait(0.1)
	Cutscene.fast = false


## Cutscene 18: the Choir mid-song in Vael's hall; the fight waits for it.
func _test_choir() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.MAW_VAEL, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 10))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.3)
	var vaels: Array = game.current_room.get_children().filter(func(c: Node) -> bool: return c is CantorVael)
	_check(vaels.size() == 1, "Vael is in his hall")
	if vaels.is_empty():
		game.queue_free()
		return
	var vael: CantorVael = vaels[0]
	_check(Cutscene.active and vael.asleep and GameState.has_flag(StoryDirector.CHOIR_FLAG), "the first time in, the Choir is singing and the fight waits")
	_check(not Audio.music_cue.begins_with("boss"), "no boss theme over the song (%s)" % Audio.music_cue)
	await _wait(0.3)
	_check(get_tree().get_nodes_in_group("choir_extra").size() == StoryDirector.CHOIR_EXTRAS.size(), "the whole Choir stands along the hall")
	var pages := await _play_scene(game, 40.0)
	_check(pages >= 1 and not Cutscene.active, "Vael has his say (%d pages)" % pages)
	_check(not vael.asleep and Audio.music_cue == CantorVael.MUSIC, "then the duel begins (%s)" % Audio.music_cue)
	_check(game.player.global_position.distance_to(game.current_room.global_position + StoryDirector.WATCH_FROM) < 6.0, "Wren walked up the hall into the song")
	_check(not game.current_room.get_children().any(func(c: Node) -> bool: return c is WakingSong), "the song's notes are gone once it's broken off")
	# Break his song: the rest of the Choir slips away.
	game.player._invuln = 60.0
	while vael.hp > 0:
		vael.note_hit(null)
	await _wait(2.0)
	await _play_scene(game, 10.0)
	await _wait(1.5)
	_check(get_tree().get_nodes_in_group("choir_extra").all(func(c: Node) -> bool: return not c.visible or c.modulate.a < 0.1), "with his song broken, the Choir slips away")
	game.queue_free()
	await _wait(0.1)
	# Back again later: no second song.
	GameState.clear_flag(CantorVael.DEFEATED_FLAG)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.3)
	_check(not Cutscene.active, "the choir scene plays once")
	await _play_scene(game, 5.0)
	game.queue_free()
	await _wait(0.1)
	Cutscene.fast = false


func _test_gully() -> void:
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	var talk_at := StoryDirector.GULLY_AT + Vector2(0, 18)
	GameState.set_checkpoint(StoryDirector.WRECK_STRAND, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room: Room = game.current_room
	_check(_find_kind(room, "gully") != null, "Gully dozes on Wreck Strand")
	var boxes: Array = game.current_room.get_children().filter(func(c: Node) -> bool: return c is Strongbox)
	_check(boxes.size() == 1 and not (boxes[0] as Strongbox).visible, "his strongbox isn't out there until he's asked")
	var gully_tile := Vector2i(StoryDirector.GULLY_AT / Room.TILE)
	_check(gully_tile.y <= 8 and room.tile_at(gully_tile.x, gully_tile.y + 1) == ".", "Gully can be talked to from dry ground")
	game.player.facing = Vector2.UP
	await _wait(0.05)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages >= 2 and GameState.has_flag("gully_asked"), "he asks Wren to fetch his strongbox (%d pages)" % pages)
	var box := boxes[0] as Strongbox
	_check(box.visible, "and there it is, out in the pool")
	var box_tile := Vector2i(StoryDirector.STRONGBOX_AT / Room.TILE)
	_check(room.tile_at(box_tile.x, box_tile.y) == "~", "the strongbox bobs in the water")
	# Hook it from the shore west of the pool.
	_enemies_away()
	game.player.global_position = room.global_position + Vector2(9 * Room.TILE + 8, box_tile.y * Room.TILE + 10)
	game.player.facing = Vector2.RIGHT
	await _wait(0.1)
	var glints := GameState.item_count("glint")
	game.player.use_item("tide_hook")
	var waited := 0.0
	while not GameState.has_flag("gully_box_hauled") and waited < 3.0:
		await _wait(0.05)
		waited += 0.05
	_check(GameState.has_flag("gully_box_hauled"), "the Tide Hook hauls it in")
	await _play_scene(game, 4.0)
	_check(not is_instance_valid(box), "and it's out of the water")
	game.player.global_position = room.global_position + talk_at
	game.player.facing = Vector2.UP
	await _wait(0.2)
	game.player.try_interact()
	await _play_scene(game, 10.0)
	_check(GameState.has_flag("gully_paid") and GameState.item_count("glint") == glints + 100, "Gully pays a salvager's cut")
	_check(Conversations.branch_for("gully").get("lines")[0] == "GULLY_AFTER", "and keeps the figurehead company")
	game.queue_free()
	await _wait(0.1)
	# Back again: the box stays hauled.
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.3)
	_check(game.current_room.get_children().filter(func(c: Node) -> bool: return c is Strongbox).is_empty(), "the pool stays empty")
	game.queue_free()
	await _wait(0.1)
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	_check(Conversations.branch_for("gully").get("lines")[0] == "GULLY_TURNED", "he felt the Old One turn")
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("gully").get("lines")[0] == "GULLY_END", "and after the ending she sleeps too")


func _test_sorrel() -> void:
	GameState.reset_new_game()
	var talk_at := StoryDirector.SORREL_AT + Vector2(0, 18)
	GameState.set_checkpoint(StoryDirector.GULLWATCH_STEPS, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	_check(_find_kind(room, "sorrel") != null, "Captain Sorrel stands on Gullwatch Steps")
	var posts: Array = room.get_children().filter(func(c: Node) -> bool: return c is KitePost)
	_check(posts.size() == 1 and not (posts[0] as KitePost).won, "the far post flies her red pennant")
	var post_tile := Vector2i(StoryDirector.KITE_POST_AT / Room.TILE)
	_check(room.tile_at(post_tile.x, post_tile.y) == "." and room.tile_at(post_tile.x, 6) == "~", "the post is on the far bank, over the water")
	game.player.facing = Vector2.UP
	await _wait(0.05)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages >= 2 and GameState.has_flag("sorrel_asked") and not GameState.has_flag(StoryDirector.RACE_FLAG), "no race without wings (%d pages)" % pages)
	GameState.give_item("kite_cloak", 1, false)
	game.player.try_interact()
	await _play_scene(game, 10.0)
	await _wait(0.1)
	var kites: Array = room.get_children().filter(func(c: Node) -> bool: return c is RaceKite)
	_check(GameState.has_flag(StoryDirector.RACE_FLAG) and kites.size() == 1, "with the Kite Cloak she races: her kite's off")
	# Standing still loses.
	await _wait(StoryDirector.KITE_TIME + 0.3)
	_check(not GameState.has_flag(StoryDirector.RACE_FLAG) and not GameState.has_flag(StoryDirector.RACE_WON_FLAG), "her kite gets there first")
	await _wait(1.8)
	_check(room.get_children().filter(func(c: Node) -> bool: return c is RaceKite).is_empty(), "and is gathered in")
	game.player.global_position = room.global_position + talk_at
	game.player.facing = Vector2.UP
	await _wait(0.1)
	game.player.try_interact()
	await _play_scene(game, 10.0)
	_check(GameState.has_flag(StoryDirector.RACE_FLAG), "she'll race again")
	_check(Conversations.branch_for("sorrel").get("lines") == ["SORREL_FLYING"], "and while her kite's up she just says go")
	# Straight across: from the near bank, glide over the water.
	game.player.global_position = room.global_position + Vector2(post_tile.x * Room.TILE + 8, 4 * Room.TILE + 6)
	game.player.facing = Vector2.DOWN
	await _wait(0.05)
	_check(game.player.use_item("kite_cloak"), "Wren throws open the Kite Cloak")
	await _wait(1.0)
	var landed: Vector2 = game.player.global_position - room.global_position
	_check(landed.y > 7 * Room.TILE, "and glides over the water to the far bank (%s)" % landed)
	_check(GameState.has_flag(StoryDirector.RACE_FLAG) or GameState.has_flag(StoryDirector.RACE_WON_FLAG), "ahead of the kite")
	game.player.global_position = room.global_position + StoryDirector.KITE_POST_AT + Vector2(0, 10)
	await _wait(0.2)
	_check(GameState.has_flag(StoryDirector.RACE_WON_FLAG) and (posts[0] as KitePost).won, "Wren's first to the post")
	await _wait(2.0)
	game.player.global_position = room.global_position + talk_at
	game.player.facing = Vector2.UP
	await _wait(0.1)
	var glints := GameState.item_count("glint")
	game.player.try_interact()
	await _play_scene(game, 10.0)
	_check(GameState.has_flag("sorrel_paid") and GameState.item_count("glint") == glints + 150, "Sorrel pays a courier's wage")
	game.queue_free()
	await _wait(0.1)
	# A race the game closed in the middle of is over when Wren comes back.
	GameState.set_flag(StoryDirector.RACE_FLAG)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.3)
	_check(not GameState.has_flag(StoryDirector.RACE_FLAG), "an unfinished race is called off")
	var again: Array = game.current_room.get_children().filter(func(c: Node) -> bool: return c is KitePost)
	_check(again.size() == 1 and (again[0] as KitePost).won, "Wren's pennant still flies")
	game.queue_free()
	await _wait(0.1)
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("sorrel").get("lines")[0] == "SORREL_LETTERS_1", "after the race, Sorrel's last letters come first")
	GameState.set_flag("sorrel_letters")
	GameState.set_flag("sorrel_letters_paid")
	_check(Conversations.branch_for("sorrel").get("lines")[0] == "SORREL_STACKS_1", "then she dares Wren to fly Gullcry Stacks")
	GameState.set_flag("sorrel_dared_stacks")
	_check(Conversations.branch_for("sorrel").get("lines")[0] == "SORREL_END", "after the ending she flies letters again")


func _test_ottilie() -> void:
	GameState.reset_new_game()
	var talk_at := StoryDirector.OTTILIE_AT + Vector2(0, -18)
	GameState.set_checkpoint(StoryDirector.STILL_COVE, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	_check(_find_kind(room, "ottilie") != null, "Ottilie fishes Still Cove")
	var holes: Array = room.get_children().filter(func(c: Node) -> bool: return c is FishingHole)
	_check(holes.size() == 1, "by her fishing hole")
	var hole := holes[0] as FishingHole
	for at: Vector2 in [StoryDirector.OTTILIE_AT, StoryDirector.FISHING_HOLE_AT]:
		var tile := Vector2i(at / Room.TILE)
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y - 1) == ".", "%s stands on the shore, reachable from above" % tile)
	# Before she asks, the hole is just a hole.
	game.player.global_position = room.global_position + StoryDirector.FISHING_HOLE_AT + Vector2(0, -18)
	game.player.facing = Vector2.DOWN
	await _wait(0.1)
	game.player.try_interact()
	await _wait(0.1)
	_check(hole.state == FishingHole.State.IDLE, "Wren can't fish until Ottilie asks")
	game.player.global_position = room.global_position + talk_at
	await _wait(0.1)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages >= 2 and GameState.has_flag("ottilie_asked"), "she asks for three rimefin (%d pages)" % pages)
	game.player.global_position = room.global_position + StoryDirector.FISHING_HOLE_AT + Vector2(0, -18)
	game.player.facing = Vector2.DOWN
	await _wait(0.1)
	# Pulling too early loses the fish.
	game.player.try_interact()
	_check(hole.state == FishingHole.State.WAITING, "the float goes in")
	game.player.try_interact()
	_check(hole.state == FishingHole.State.IDLE and FishingHole.caught() == 0, "pulled too soon: nothing")
	# Too late, too.
	game.player.try_interact()
	hole.bite_in = 0.1
	await _wait(0.3)
	_check(hole.state == FishingHole.State.BITE, "the float goes under")
	await _wait(FishingHole.BITE_WINDOW + 0.1)
	_check(hole.state == FishingHole.State.IDLE and FishingHole.caught() == 0, "too slow: it's gone")
	for i in FishingHole.WANTED:
		game.player.try_interact()
		hole.bite_in = 0.1
		await _wait(0.3)
		game.player.try_interact()
		await _wait(0.1)
	_check(FishingHole.caught() == FishingHole.WANTED and GameState.has_flag(FishingHole.DONE_FLAG), "three rimefin landed")
	game.player.try_interact()
	_check(hole.state == FishingHole.State.IDLE, "and she has all she needs")
	await _wait(0.6)
	game.player.global_position = room.global_position + talk_at
	game.player.facing = Vector2.DOWN
	await _wait(0.1)
	var glints := GameState.item_count("glint")
	game.player.try_interact()
	await _play_scene(game, 10.0)
	_check(GameState.has_flag("ottilie_paid") and GameState.item_count("glint") == glints + 200, "Ottilie pays in old keepers' coin")
	var knits: ShopMenu = null
	for node in get_tree().current_scene.get_children():
		if node is ShopMenu:
			knits = node
	_check(GameState.has_flag(Jumpers.SELLER_FLAG) and knits != null and knits.stock.size() == Jumpers.ORDER.size(),
		"then she offers her knits, and her shelf opens")
	if knits:
		knits.close()
		await _wait(0.2)
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_TURNED", "after the turn she remembers training with Hessa and Vael, even after the ending")
	Conversations.talk("ottilie")
	await _play_scene(game, 10.0)
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_BOOK_1", "then she opens her fishing book")
	Conversations.talk("ottilie")
	await _play_scene(game, 10.0)
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_END", "and then the ice hums")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_1", "met after the turn but before Hessa's word, she's a stranger")
	GameState.set_flag(StoryDirector.CONFESSION_FLAG)
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_HESSA", "once Hessa's sent Wren, she knows")


## After the rimefin, Ottilie's fishing book keeps the hole open: perch,
## glass eels that nibble first, the Old Grey once those are in, and prizes
## for runs without a loss.
func _test_fishing_book() -> void:
	GameState.reset_new_game()
	for f in ["ottilie_asked", FishingHole.DONE_FLAG, "ottilie_paid", "ottilie_knits_told"]:
		GameState.set_flag(f)
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_BOOK_1", "once paid and the knits are told, she opens her fishing book")
	_check(FishingHole.biting() == ["rimefin"], "before the book, only rimefin bite")
	Conversations.talk("ottilie")
	_check(GameState.has_flag(FishingHole.BOOK_FLAG), "the book is open")
	var talk_at := StoryDirector.OTTILIE_AT + Vector2(0, -18)
	GameState.set_checkpoint(StoryDirector.STILL_COVE, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	var hole := room.get_children().filter(func(c: Node) -> bool: return c is FishingHole)[0] as FishingHole
	game.player.global_position = room.global_position + StoryDirector.FISHING_HOLE_AT + Vector2(0, -18)
	game.player.facing = Vector2.DOWN
	await _wait(0.1)
	_check(FishingHole.biting() == ["rimefin", "perch", "eel"], "with the book open, perch and eels bite too, but not the Old Grey yet")
	# A cast: what's on the line is set when the float goes in; tests pick it.
	var cast := func(kind: String, nibbles: int) -> void:
		game.player.try_interact()
		hole.species = kind
		hole.nibbles = nibbles
		hole.bite_in = 0.1
	# An eel nibbles: pulling on the dip loses it, and the run.
	GameState.set_flag(FishingHole.STREAK_FLAG, 3)
	cast.call("eel", 1)
	await _wait(0.2)
	_check(hole.state == FishingHole.State.NIBBLE, "the float dips on a nibble")
	game.player.try_interact()
	_check(hole.state == FishingHole.State.IDLE and not GameState.has_flag("caught_eel") and int(GameState.flags.get(FishingHole.STREAK_FLAG, 0)) == 0, "pulling on a nibble loses the fish and the run")
	# Waiting out the nibble lands it.
	cast.call("eel", 1)
	await _wait(FishingHole.NIBBLE_TIME + 0.2)
	_check(hole.state == FishingHole.State.WAITING, "the float comes back up after a nibble")
	hole.bite_in = 0.05
	await _wait(0.15)
	_check(hole.state == FishingHole.State.BITE, "after the nibble, the real bite")
	game.player.try_interact()
	_check(GameState.has_flag("caught_eel"), "a glass eel landed")
	# Frostperch don't stay under long.
	cast.call("perch", 0)
	await _wait(0.2)
	await _wait(FishingHole.SPECIES["perch"][1] + 0.05)
	_check(hole.state == FishingHole.State.IDLE and not GameState.has_flag("caught_perch"), "a frostperch is gone in a blink")
	cast.call("perch", 0)
	await _wait(0.2)
	game.player.try_interact()
	_check(GameState.has_flag("caught_perch"), "a frostperch landed")
	_check(FishingHole.biting().has(FishingHole.GREY), "with perch and eel in, the Old Grey can bite")
	# The Old Grey takes three pulls, one per dive.
	cast.call(FishingHole.GREY, 0)
	for i in FishingHole.GREY_PULLS:
		hole.bite_in = minf(hole.bite_in, 0.1)
		await _wait(0.2)
		_check(hole.state == FishingHole.State.BITE, "the Old Grey pulls under (%d)" % (i + 1))
		game.player.try_interact()
		if i < FishingHole.GREY_PULLS - 1:
			_check(hole.state == FishingHole.State.WAITING and not GameState.has_flag("caught_grey"), "and dives again")
	_check(GameState.has_flag("caught_grey"), "the Old Grey landed in three pulls")
	# Walking off mid-cast loses the run too.
	GameState.set_flag(FishingHole.STREAK_FLAG, 4)
	cast.call("rimefin", 0)
	game.player.global_position += Vector2(0, -FishingHole.LEAVE - 10)
	await _wait(0.1)
	_check(hole.state == FishingHole.State.IDLE and int(GameState.flags.get(FishingHole.STREAK_FLAG, 0)) == 0, "walking off from a cast ends the run")
	game.player.global_position = room.global_position + StoryDirector.FISHING_HOLE_AT + Vector2(0, -18)
	await _wait(0.1)
	# Runs: five, then ten, without a loss.
	GameState.set_flag(FishingHole.STREAK_FLAG, 0)
	for i in 10:
		cast.call("rimefin", 0)
		await _wait(0.2)
		game.player.try_interact()
		if i == 4:
			_check(GameState.has_flag("fish_streak_5") and not GameState.has_flag("fish_streak_10"), "five in a row")
	_check(GameState.has_flag("fish_streak_10"), "ten in a row")
	await _wait(1.0)
	game.queue_free()
	await _wait(0.1)
	# Ottilie books each one, then the prizes, one talk at a time.
	var glints := GameState.item_count("glint")
	var expect := [["OTTILIE_GREY_1", 250], ["OTTILIE_PERCH_1", 40], ["OTTILIE_EEL_1", 40], ["OTTILIE_STREAK_10_1", 200]]
	for e: Array in expect:
		_check(Conversations.branch_for("ottilie").get("lines").has(e[0]), "Ottilie: %s" % e[0])
		Conversations.talk("ottilie")
		glints += int(e[1])
	_check(GameState.item_count("glint") == glints, "she pays for each (%d)" % GameState.item_count("glint"))
	_check(GameState.has_flag("ottilie_streak_5"), "ten in a row covers the five-in-a-row prize too")
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_AFTER", "then she's back to her usual")
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_END", "and after the ending, the ice hums")
	GameState.reset_new_game()
	for f in ["ottilie_paid", "ottilie_knits_told", FishingHole.BOOK_FLAG]:
		GameState.set_flag(f)
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_BOOK_WAITING", "until the Old Grey's in, she's watching the float")
	GameState.set_flag("fish_streak_5")
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_STREAK_5_1", "five in a row has its own prize")
	GameState.set_flag("caught_grey")
	_check(Conversations.branch_for("ottilie").get("lines").has("OTTILIE_GREY_4B"), "the Old Grey before the reunion: she wishes she could tell Hessa")
	GameState.set_flag("ottilie_reunion")
	_check(Conversations.branch_for("ottilie").get("lines").has("OTTILIE_GREY_4"), "after it, she'll collect on their old bet")


## Hessa's logbook: after she's sent Wren round the stones, she asks for the
## pages the lantern-boat storm blew down the coast; all six bring 200
## glints and the last page's story. Found early, they hand straight in.
func _test_hessa_log() -> void:
	var pages := StoryDirector.FINDS.keys().filter(func(id: String) -> bool: return id.begins_with("log_"))
	_check(pages.size() == 6, "six logbook pages")
	var line := func() -> Array: return Conversations.branch_for("hessa").get("lines", [])
	var first := func() -> String: return str(line.call()[0]) if line.call()[0] is String else str(line.call()[1])
	GameState.reset_new_game()
	# Every stone read before the round was even asked: the logbook still comes.
	for flag in ["met_hessa", "seen_wayshell", "tidebell_kiln", Tidestone.ALL_READ_FLAG, "hessa_carved_wren"]:
		GameState.set_flag(flag)
	_check(first.call() == "HESSA_HINT_MIRE_1", "no logbook before the Old One turns (the Verge is still under)")
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	# Story beats first: Ottilie's sign.
	GameState.set_flag("ottilie_signal")
	_check(first.call() == "HESSA_OTTILIE_1", "Ottilie's sign comes ahead of the logbook")
	Conversations.talk("hessa")
	_check(first.call() == "HESSA_LOG_1", "then she asks for her logbook pages")
	Conversations.talk("hessa")
	_check(first.call() != "HESSA_LOG_1" and not str(first.call()).begins_with("HESSA_LOG"), "once, then her usual")
	for i in pages.size():
		_check(not line.call().has("HESSA_LOG_DONE_1"), "not before page %d" % (i + 1))
		var shown: Array = Conversations.talk("find_" + pages[i])
		_check(GameState.has_flag(QuestFind.flag_for(pages[i])) and str(shown[-1]["text"]) == "NARRATE_LOG_" + pages[i].trim_prefix("log_").to_upper(), "%s read" % pages[i])
	var glints := GameState.item_count("glint")
	_check(line.call().has("HESSA_LOG_DONE_1"), "all six home")
	Conversations.talk("hessa")
	_check(GameState.item_count("glint") == glints + 200 and not line.call().has("HESSA_LOG_DONE_1"), "she pays, once")
	GameState.set_flag("tidebell_tomb")
	_check(first.call() == "HESSA_ROW_1", "and the row to the Maw still comes first")
	GameState.reset_new_game()
	for id: String in pages:
		GameState.set_flag(QuestFind.flag_for(id))
	GameState.set_flag("met_hessa")
	_check(not line.call().has("HESSA_LOG_EARLY"), "no hand-in before the Wayshell")
	GameState.set_flag("seen_wayshell")
	_check(line.call().has("HESSA_LOG_EARLY"), "all six found before she asks: straight in")
	Conversations.talk("hessa")
	_check(GameState.has_flag("hessa_log_done") and GameState.item_count("glint") == 200, "and paid")


## Coralie's echo game: once the chime's hung she shows Wren; striking the
## chime sings a tune on four shells, and Wren hops it back. Each tune
## landed adds a note; a wrong shell or walking off ends the round.
func _test_echo_game() -> void:
	GameState.reset_new_game()
	for flag in ["met_hessa", "coralie_asked", "coralie_chime_done"]:
		GameState.set_flag(flag)
	var first := func() -> String: return str(Conversations.branch_for("coralie").get("lines", [""])[0])
	_check(first.call() == "CORALIE_ECHO_1", "with the chime hung, Coralie shows Wren her gran's game")
	var talk_at := StoryDirector.CORALIE_AT + Vector2(0, -18)
	GameState.set_checkpoint(StoryDirector.SHORE, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	var echo := room.get_children().filter(func(c: Node) -> bool: return c is EchoGame)[0] as EchoGame
	var chime := room.get_children().filter(func(c: Node) -> bool: return c is GlassChime)[0] as GlassChime
	for tile: Vector2i in EchoGame.SHELLS:
		_check(room.tile_at(tile.x, tile.y) == ".", "shell %s on open sand" % tile)
	chime.interact()
	_check(echo.state == EchoGame.State.IDLE, "the chime's just a chime before she asks")
	Conversations.talk("coralie")
	await _play_scene(game, 10.0)
	_check(EchoGame.open() and first.call() == "CORALIE_AFTER", "she's asked, and back to her usual")
	var at_shells := room.global_position + EchoGame.centre() + Vector2(0, 30)
	game.player.global_position = at_shells
	await _wait(0.1)
	chime.interact()
	_check(echo.state == EchoGame.State.SHOW and echo.tune.size() == EchoGame.START_LENGTH, "striking the chime sings three notes")
	await _wait(EchoGame.LEAD_IN + EchoGame.NOTE_TIME * EchoGame.START_LENGTH + 0.2)
	_check(echo.state == EchoGame.State.LISTEN, "then it's Wren's turn")
	# A wrong shell ends it.
	echo.hop((echo.tune[0] + 1) % EchoGame.SHELLS.size())
	_check(echo.state == EchoGame.State.IDLE, "a wrong shell ends the round")
	# Hopping by walking: stand on each shell in turn.
	chime.interact()
	await _wait(EchoGame.LEAD_IN + EchoGame.NOTE_TIME * EchoGame.START_LENGTH + 0.2)
	for i: int in echo.tune.duplicate():
		game.player.global_position = room.global_position + EchoGame.shell_at(i)
		await _wait(0.1)
		game.player.global_position = at_shells
		await _wait(0.1)
	_check(EchoGame.best() == EchoGame.START_LENGTH and echo.tune.size() == EchoGame.START_LENGTH + 1 and echo.state == EchoGame.State.SHOW, "walking the shells in order lands it, and the next tune is a note longer")
	# Landing tunes up to twelve, by hops.
	while echo.tune.size() <= 12:
		echo.state = EchoGame.State.LISTEN
		echo.at = 0
		for i: int in echo.tune.duplicate():
			echo.hop(i)
		if echo.tune.size() == 6:
			_check(GameState.has_flag("echo_5") and not GameState.has_flag("echo_8"), "five notes")
	_check(GameState.has_flag("echo_8") and GameState.has_flag("echo_12") and EchoGame.best() == 12, "eight and twelve")
	# Walking off ends a round.
	game.player.global_position = room.global_position + EchoGame.centre() + Vector2(-EchoGame.LEAVE - 20, 0)
	await _wait(0.1)
	_check(echo.state == EchoGame.State.IDLE, "walking off ends the round")
	game.queue_free()
	await _wait(0.1)
	var glints := GameState.item_count("glint")
	for e: Array in [["CORALIE_ECHO_5_1", 50], ["CORALIE_ECHO_8_1", 100], ["CORALIE_ECHO_12_1", 200]]:
		_check(first.call() == e[0], "Coralie pays for each: %s" % e[0])
		Conversations.talk("coralie")
		glints += int(e[1])
	_check(GameState.item_count("glint") == glints and first.call() == "CORALIE_AFTER", "every prize paid, even reaching twelve first")
	GameState.reset_new_game()
	for flag in ["coralie_asked", "coralie_chime_done", "coralie_echo_ask", "echo_5"]:
		GameState.set_flag(flag)
	_check(first.call() == "CORALIE_ECHO_5_1", "five has its own prize")
	Conversations.talk("coralie")
	_check(GameState.item_count("glint") == 50, "fifty glints")


## Pell's night bell: after the Hull, Pell asks who rings a bell out on
## the water at night. A trail of clues, each showing once the last is
## found, leads to a seal pup, who comes home to the Shore. Pell names her; Corrin pays.
func _test_seal_trail() -> void:
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	for flag in ["met_hessa", "talked_pell_quest", "talked_corrin_quest", "heard_pell_hull", "heard_corrin_hull"]:
		GameState.set_flag(flag)
	_check(first.call("pell") == "PELL_AGAIN", "no night bell before the Hull's bell is back")
	GameState.set_flag("heard_pell_bell")
	_check(first.call("pell") == "PELL_NIGHT_1", "then Pell asks who rings a bell out on the water at night")
	# No trail before Pell asks.
	var track: Array = StoryDirector.FINDS["seal_track"]
	var game: Node = await _stand_below(track[0], track[1])
	_check(not game.current_room.get_children().any(func(c: Node) -> bool: return c is QuestFind and (c as QuestFind).id == "seal_track"), "no tracks before Pell asks")
	game.queue_free()
	await _wait(0.1)
	Conversations.talk("pell")
	_check(first.call("pell") == "PELL_NIGHT_WAITING", "Pell waits up")
	# Each clue only once the one before is found.
	var order := ["seal_track", "seal_bones", "seal_net", "seal_pup"]
	for i in order.size():
		var id: String = order[i]
		_check(GameState.has_flag(StoryDirector.FIND_NEEDS[id]), "%s shows once %s" % [id, StoryDirector.FIND_NEEDS[id]])
		if i + 1 < order.size():
			_check(not GameState.has_flag(StoryDirector.FIND_NEEDS[order[i + 1]]), "and %s doesn't yet" % order[i + 1])
		Conversations.talk("find_" + id)
	_check(GameState.has_flag(QuestFind.flag_for("seal_pup")), "the pup found")
	# She's at home on the Shore now.
	var home: Array = StoryDirector.SEAL_PUP_HOME
	game = await _stand_below(home[0], home[1])
	var room: Room = game.current_room
	_check(room.get_children().filter(func(c: Node) -> bool: return c is SealPup).size() == 1, "the seal pup lives on the Shore")
	_check(home[1].y <= 8 and room.tile_at(home[1].x, home[1].y) == "." and room.tile_at(home[1].x, home[1].y + 1) == ".", "on dry sand, reachable from below")
	_check(game.player.try_interact(), "Wren can say hello")
	await _play_scene(game, 10.0)
	game.queue_free()
	await _wait(0.1)
	_check(Conversations.branch_for("pell").get("lines").has("PELL_PUP_1"), "Pell meets her")
	Conversations.talk("pell")
	_check(first.call("pell") == "PELL_AGAIN" and first.call("seal_pup") == "NARRATE_PUP_DING", "and names her Ding")
	var glints := GameState.item_count("glint")
	_check(Conversations.branch_for("corrin").get("lines").has("CORRIN_PUP_1"), "Corrin meets the net thief")
	Conversations.talk("corrin")
	_check(GameState.item_count("glint") == glints + 150 and first.call("corrin") == "CORRIN_AGAIN", "and pays for a night's sleep, once")
	# With Pell's shell errand open, the night bell still gets through.
	GameState.reset_new_game()
	for flag in ["met_hessa", "talked_pell_quest", "heard_pell_bell", "heard_pell_hull", "seen_wayshell", "pell_shell_ask"]:
		GameState.set_flag(flag)
	_check(first.call("pell") == "PELL_NIGHT_1", "the night bell asks ahead of the shell's waiting line")
	Conversations.talk("pell")
	GameState.set_flag(QuestFind.flag_for("seal_pup"))
	_check(Conversations.branch_for("pell").get("lines").has("PELL_PUP_1"), "and the pup's hand-in too")
	# And Corrin's bottles errand doesn't hold up the pup's pay.
	for flag in ["talked_corrin_quest", "corrin_bottles_ask"]:
		GameState.set_flag(flag)
	_check(Conversations.branch_for("corrin").get("lines").has("CORRIN_PUP_1"), "Corrin's waiting for bottles doesn't hide the net thief")


## Coralie on Saltmarrow Shore takes sea-glass for her chime, 25 glints a
## piece, and a little more when all twelve are hung.
func _test_coralie() -> void:
	GameState.reset_new_game()
	var talk_at := StoryDirector.CORALIE_AT + Vector2(0, -18)
	GameState.set_checkpoint(StoryDirector.SHORE, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "coralie") == null, "Coralie isn't on the shore before the opening's done")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()
	GameState.set_flag("met_hessa")
	GameState.set_checkpoint(StoryDirector.SHORE, talk_at)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	_check(_find_kind(room, "coralie") != null, "Coralie combs Saltmarrow Shore")
	var chimes: Array = room.get_children().filter(func(c: Node) -> bool: return c is GlassChime)
	_check(chimes.size() == 1, "beside her chime")
	for at: Vector2 in [StoryDirector.CORALIE_AT, StoryDirector.CHIME_AT]:
		var tile := Vector2i(at / Room.TILE)
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y - 1) == ".", "%s stands on open sand, reachable from above" % tile)
	# Glass found before she asks is kept until she does.
	GameState.give_item("sea_glass", 2, false)
	game.player.global_position = room.global_position + talk_at
	game.player.facing = Vector2.DOWN
	await _wait(0.1)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages >= 2 and GameState.has_flag("coralie_asked") and GameState.item_count("sea_glass") == 2, "she asks for sea-glass (%d pages)" % pages)
	var glints := GameState.item_count("glint")
	game.player.try_interact()
	await _play_scene(game, 10.0)
	_check(GameState.item_count("sea_glass") == 0 and GlassChime.hung() == 2, "she hangs both pieces")
	_check(SeaGlass.found() == 2, "pieces on the chime still count as found, for the last piece's jingle")
	_check(GameState.item_count("glint") == glints + 50, "and pays 25 glints a piece")
	_check(Conversations.branch_for("coralie").get("lines") == ["CORALIE_WAITING"], "with no glass, she waits for more")
	# Most of the rest, then the last: the chime's done and she adds her savings.
	GameState.give_item("sea_glass", 9, false)
	_check(Conversations.branch_for("coralie").get("lines")[0] == "CORALIE_HANG", "eleven isn't twelve")
	Conversations.talk("coralie")
	await _play_scene(game, 10.0)
	_check(GlassChime.hung() == 11 and not GameState.has_flag("coralie_chime_done"), "eleven hung")
	GameState.give_item("sea_glass", 1, false)
	glints = GameState.item_count("glint")
	_check(Conversations.branch_for("coralie").get("lines")[0] == "CORALIE_DONE_1", "the twelfth piece finishes it")
	Conversations.talk("coralie")
	await _play_scene(game, 10.0)
	_check(GlassChime.hung() == SeaGlass.TOTAL and GameState.has_flag("coralie_chime_done"), "twelve hung")
	_check(GameState.item_count("glint") == glints + 25 + 100, "the last piece, and her savings")
	_check(Conversations.branch_for("coralie").get("lines")[0] == "CORALIE_ECHO_1", "then she shows Wren her echo game (_test_echo_game)")
	GameState.set_flag(EchoGame.ASK_FLAG)
	_check(Conversations.branch_for("coralie").get("lines") == ["CORALIE_AFTER"], "then she listens to the wind")
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	_check(Conversations.branch_for("coralie").get("lines") == ["CORALIE_TURNED"], "the chime rings when the Old One turns")
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("coralie").get("lines") == ["CORALIE_END"], "and after the ending")
	# Saved and loaded, the tally comes back as a float: still twelve.
	GameState.flags["coralie_glass"] = 12.0
	_check(GlassChime.hung() == 12, "a loaded tally still counts")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## After the ending, Sister Lowe stands alone on Lullaby Point.
func _test_lowe_after() -> void:
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.TOMB_BELL_FLAG)
	GameState.set_checkpoint(StoryDirector.LULLABY_POINT, StoryDirector.LOWE_AT + Vector2(-20, 0))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "lowe") == null, "Lowe isn't on the point before the ending")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()
	for flag in [StoryDirector.TOMB_BELL_FLAG, StoryDirector.ROWED_FLAG, StoryDirector.ENDING_FLAG, StoryDirector.DREAM_FLAG]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.LULLABY_POINT, StoryDirector.LOWE_AT + Vector2(-20, 0))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	var lowe := _find_kind(room, "lowe")
	_check(lowe != null, "after the ending, Lowe keeps watch on the point")
	var tile := Vector2i(StoryDirector.LOWE_AT / Room.TILE)
	_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == ".", "she stands on the point's rocks, above the dialogue box")
	game.player.facing = Vector2.RIGHT
	await _wait(0.1)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages == 4 and GameState.has_flag("lowe_spoke"), "she talks about Vael and home (%d pages)" % pages)
	_check(Conversations.branch_for("lowe").get("lines")[0] == "LOWE_SINGERS_1", "then asks after her last singers")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## Hessa's walk: after the ending she asks Wren to light her way out to
## Lullaby Point. She follows the lamp, waits when Wren goes out of sight,
## crosses only when close, and on the Point has her word with Lowe.
func _test_hessa_walk() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	for flag in ["met_hessa", "seen_wayshell", StoryDirector.TURNED_FLAG, StoryDirector.CONFESSION_FLAG, StoryDirector.TOMB_BELL_FLAG, StoryDirector.ROWED_FLAG, StoryDirector.ENDING_FLAG, StoryDirector.DREAM_FLAG, StoryDirector.HEART_VISIT_FLAG, "hessa_log_ask"]:
		GameState.set_flag(flag)
	var first := func() -> String: return str(Conversations.branch_for("hessa").get("lines", [""])[0])
	_check(first.call() == "HESSA_AFTER_END", "no walk before Wren has met Lowe on the Point")
	GameState.set_flag("lowe_spoke")
	_check(first.call() == "HESSA_WALK_1", "then Hessa asks Wren to light her way out to Lowe")
	for line: String in ["HESSA_WALK_1", "HESSA_WALK_1B", "HESSA_WALK_2", "HESSA_WALK_2B", "HESSA_WALK_SHORE", "HESSA_WALK_POOLS_B", "HESSA_WALK_POINT_3", "LOWE_WALK_4", "HESSA_POINT_STAY", "LOWE_WALK_AFTER_2"]:
		_check(tr(line).length() <= 70, "%s fits the box" % line)
	var home := Vector2(18 * 16 + 8, 5 * 16 + 12)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, home + StoryDirector.HOME_FROM_HESSA)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var player: Player = game.player
	player._invuln = 600.0
	var director: StoryDirector = get_tree().get_first_node_in_group("story_director")
	var room: Room = game.current_room
	player.facing = Vector2.UP
	await _wait(0.1)
	player.try_interact()
	await _play_scene(game, 6.0)
	await _wait(0.2)
	var walker := director._walker
	_check(GameState.has_flag(StoryDirector.WALK_FLAG) and is_instance_valid(walker) and _find_kind(room, "hessa") == null, "she leaves her spot and follows")
	# She follows Wren over open ground.
	player.global_position = _tile_pos(room, Vector2i(14, 8))
	var before := walker.global_position.distance_to(player.global_position)
	await _wait(1.0)
	_check(walker.global_position.distance_to(player.global_position) < before - 20.0, "she walks after the lamp")
	# Out of sight, she stops and holds up her own lamp.
	player.global_position = _tile_pos(room, Vector2i(2, 11))
	walker.position = Vector2(21 * 16 + 8, 8 * 16 + 10)
	await _wait(0.6)
	var stood := walker.position
	await _wait(0.5)
	_check(walker.waiting and walker.position == stood, "too far: she waits for Wren to come back")
	# Leave without her: she stays in the village.
	player.global_position = _tile_pos(room, Vector2i(11, 12)) + Vector2(0, 12)
	await _wait(0.8)
	_check(game.current_room.coord == StoryDirector.SHORE and director._walker == null and director.walk_room == StoryDirector.SALTMARROW, "left behind, she waits at home")
	player.global_position = _tile_pos(game.current_room, Vector2i(11, 0)) + Vector2(0, -24)
	await _wait(0.8)
	room = game.current_room
	walker = director._walker
	_check(room.coord == StoryDirector.SALTMARROW and is_instance_valid(walker) and walker.position.distance_to(stood) < 2.0 and _find_kind(room, "hessa") == null, "and she's still waiting where she stood")
	# Now together, all the way out.
	var route := [[Vector2i(11, 12), Vector2i.DOWN, Vector2(0, 6)], [Vector2i(23, 6), Vector2i.RIGHT, Vector2(6, 0)], [Vector2i(11, 12), Vector2i.DOWN, Vector2(0, 6)], [Vector2i(23, 9), Vector2i.RIGHT, Vector2(6, 0)]]
	var beats := ["hessa_walk_shore", "hessa_walk_pools", "hessa_walk_wreck"]
	for i in route.size():
		room = game.current_room
		player.global_position = _tile_pos(room, route[i][0])
		director._walker.position = player.global_position - room.global_position - Vector2(route[i][1]) * 16.0
		await _wait(0.1)
		# Over the edge: the game slides on to the next room.
		player.global_position += route[i][2] * 2.0
		await _wait(0.8)
		if i < beats.size():
			await _play_scene(game, 6.0)
			_check(is_instance_valid(director._walker) and GameState.has_flag(beats[i]), "she comes along and has a word (%s)" % beats[i])
	room = game.current_room
	var glints := GameState.item_count("glint")
	var pages := await _play_scene(game, 20.0)
	_check(room.coord == StoryDirector.LULLABY_POINT and pages >= 12, "on the Point, Hessa and Lowe talk (%d pages)" % pages)
	_check(GameState.has_flag(StoryDirector.WALK_DONE_FLAG) and not GameState.has_flag(StoryDirector.WALK_FLAG) and GameState.item_count("glint") == glints + StoryDirector.WALK_GLINTS, "the walk's done, and she pays for the oil")
	var stays := _find_kind(room, "hessa_point")
	_check(stays != null and director._walker == null and Vector2i(stays.position / Room.TILE).y <= 8, "she stays on the Point with Lowe, above the box")
	_check(Conversations.branch_for("hessa_point").get("lines") == ["HESSA_POINT_STAY"], "and sends Wren home")
	_check(Conversations.branch_for("lowe").get("lines")[0] != "LOWE_WALK_AFTER_1", "Lowe keeps her evenings to herself for now")
	_check(first.call() == "HESSA_WALK_HOME_1", "Hessa has a word about it, back home")
	Conversations.talk("hessa")
	_check(Conversations.branch_for("lowe").get("lines")[0] == "LOWE_WALK_AFTER_1", "and then so does Lowe")
	game.queue_free()
	await _wait(0.1)
	# Gone further than the next room without her: she makes her own way home.
	GameState.reset_new_game()
	for flag in ["met_hessa", "seen_wayshell", StoryDirector.TURNED_FLAG, StoryDirector.CONFESSION_FLAG, StoryDirector.TOMB_BELL_FLAG, StoryDirector.ROWED_FLAG, StoryDirector.ENDING_FLAG, StoryDirector.DREAM_FLAG, StoryDirector.HEART_VISIT_FLAG, "hessa_log_ask", "lowe_spoke", "hessa_walk_ask"]:
		GameState.set_flag(flag)
	_check(first.call() == "HESSA_WALK_AGAIN", "asked again after a walk that came to nothing")
	GameState.set_checkpoint(StoryDirector.SALTMARROW, home + StoryDirector.HOME_FROM_HESSA)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	player = game.player
	player._invuln = 600.0
	director = get_tree().get_first_node_in_group("story_director")
	Conversations.talk("hessa")
	await _play_scene(game, 6.0)
	_check(GameState.has_flag(StoryDirector.WALK_FLAG), "and she sets off again")
	director._walker.position = Vector2(2 * 16 + 8, 8 * 16 + 10)
	await _wait(0.1)
	player.global_position = _tile_pos(game.current_room, Vector2i(11, 12)) + Vector2(0, 12)
	await _wait(0.8)
	player.global_position = _tile_pos(game.current_room, Vector2i(23, 6)) + Vector2(12, 0)
	await _wait(0.8)
	_check(not GameState.has_flag(StoryDirector.WALK_FLAG) and director._walker == null, "two rooms off without her: she's gone home")
	# Off the route, she stays at the edge rather than wander off with Wren.
	GameState.flags[StoryDirector.WALK_FLAG] = true
	director.walk_room = Vector2i(1, 0)
	director._walker = HessaWalker.new()
	director._walker.near = true
	director._walk_on(Vector2i(2, 0))
	_check(director.walk_room == Vector2i(1, 0) and GameState.has_flag(StoryDirector.WALK_FLAG), "she won't be led off the way to the Point")
	# Mantle flies Wren off: the walk's over.
	director.end_walk()
	_check(not GameState.has_flag(StoryDirector.WALK_FLAG), "flown off: she makes her own way home")
	game.queue_free()
	await _wait(0.1)
	Cutscene.fast = false
	GameState.reset_new_game()


## Raising the lantern-boat: once Wren has shown Hessa the cap, Gully
## wants her afloat. Planks from Dunstan, pitch from Agna, a sail from
## Sorrel and Hessa's lamp; then she floats, and rides at Saltmarrow's
## steps with her lamp lit.
func _test_boat_raised() -> void:
	Cutscene.fast = true
	GameState.reset_new_game()
	var first := func(who: String) -> String:
		var lines: Array = Conversations.branch_for(who).get("lines", [""])
		return str(lines[0]) if lines[0] is String else str(lines[1])
	for flag in ["met_hessa", StoryDirector.TURNED_FLAG, StoryDirector.CONFESSION_FLAG, "gully_asked", "gully_paid", "gully_ebb_told", "found_wren_cap", "hessa_saw_cap", "met_agna", "agna_gave_sword", "agna_scales_ask", "sorrel_asked", "sorrel_paid", "sorrel_dared_stacks", "hessa_log_ask", "hessa_round_ask"]:
		GameState.set_flag(flag)
	_check(first.call("gully_ebb") == "GULLY_EBB_AFTER", "no ask before the Wayshell")
	GameState.set_flag("seen_wayshell")
	_check(first.call("gully_ebb") == "GULLY_BOAT_1", "then Gully wants the lantern-boat afloat")
	for who in ["dunstan", "agna", "sorrel", "hessa"]:
		_check(not first.call(who).contains("BOATFIX"), "%s has nothing for the boat before Gully asks" % who)
	Conversations.talk("gully_ebb")
	_check(first.call("gully_ebb") == "GULLY_BOAT_WAITING", "and waits for the parts")
	for part: Array in [["dunstan", "DUNSTAN_BOATFIX_1", "boat_planks"], ["agna", "AGNA_BOATFIX_1", "boat_pitch"], ["sorrel", "SORREL_BOATFIX_1", "boat_sail"], ["hessa", "HESSA_BOATFIX_1", "boat_lamp"]]:
		_check(first.call("gully_ebb") == "GULLY_BOAT_WAITING", "not ready before %s" % part[2])
		_check(first.call(part[0]) == part[1], "%s gives a hand" % part[0])
		Conversations.talk(part[0])
		_check(GameState.has_flag(part[2]) and first.call(part[0]) != part[1], "%s, once" % part[2])
	for line: String in ["GULLY_BOAT_1", "GULLY_BOAT_1B", "DUNSTAN_BOATFIX_1", "HESSA_BOATFIX_2", "NARRATE_BOAT_WORK", "NARRATE_BOAT_FLOATS", "GULLY_BOAT_DONE_2", "NARRATE_BOAT_HOME", "HESSA_BOAT_HOME_2"]:
		_check(tr(line).length() <= 70, "%s fits the box" % line)
	_check(first.call("gully_ebb") == "GULLY_BOAT_DONE_1", "everything back to Gully")
	Conversations.talk("gully_ebb")
	_check(GameState.has_flag(StoryDirector.BOAT_DONE_FLAG) and first.call("gully_ebb") == "GULLY_BOAT_AFTER", "she floats, and Gully rows her home")
	# Home at the harbour steps, lamp lit, and Hessa has her say.
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(18 * 16 + 8, 5 * 16 + 12) + StoryDirector.HOME_FROM_HESSA)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	var homes := room.get_children().filter(func(c: Node) -> bool: return c is BoatHome)
	_check(homes.size() == 1, "the lantern-boat is moored at Saltmarrow")
	var at := Vector2i(StoryDirector.BOAT_HOME_AT / Room.TILE)
	_check(room.tile_at(at.x, at.y) == "~" and room.tile_at(at.x - 1, at.y) == "~" and room.tile_at(at.x, at.y - 1) == "~", "on the harbour water")
	var pages := await _play_scene(game, 12.0)
	_check(GameState.has_flag(StoryDirector.BOAT_HOME_FLAG) and pages == 3, "Hessa sees her home (%d pages)" % pages)
	game.queue_free()
	await _wait(0.1)
	# And the Ebb Shelf has only sand where she lay.
	GameState.set_flag(Tide.HELD_FLAG)
	GameState.set_checkpoint(StoryDirector.EBB_SHELF, StoryDirector.GULLY_EBB_AT + Vector2(0, 16))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	room = game.current_room
	_check(_find_kind(room, "gully_ebb") != null and not room.get_children().any(func(c: Node) -> bool: return c is LanternBoat or (c is Prop and c.kind == "W" and not c.is_queued_for_deletion())), "the Shelf's wreck is gone, Gully's still there")
	game.queue_free()
	await _wait(0.1)
	# Floated while Wren watches: she's gone from the sand at once.
	GameState.clear_flag(StoryDirector.BOAT_DONE_FLAG)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	room = game.current_room
	_check(room.get_children().any(func(c: Node) -> bool: return c is LanternBoat), "before she floats, she's in the sand")
	GameState.set_flag(StoryDirector.BOAT_DONE_FLAG)
	await _wait(0.2)
	_check(not room.get_children().any(func(c: Node) -> bool: return c is LanternBoat and not c.is_queued_for_deletion()), "once Gully's floated her, she's gone from the Shelf")
	game.queue_free()
	await _wait(0.1)
	Cutscene.fast = false
	GameState.reset_new_game()


## A whole pass on a gamepad, with real pad events: the title, the pause
## menu's every tab, remapping, the minigames and the glyphs in the text.
func _test_pad_tour() -> void:
	var settings_path := ProjectSettings.globalize_path(Settings.PATH)
	var had_settings := FileAccess.file_exists(settings_path)
	var old_settings := FileAccess.get_file_as_string(settings_path) if had_settings else ""
	Settings.reset_controls()
	# Whatever ran before may have left the game paused or an action held.
	get_tree().paused = false
	for held: String in Settings.REMAPPABLE:
		Input.action_release(held)
	# The title: the D-pad and the stick move between buttons, A picks, B backs out.
	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	add_child(title)
	var until := Time.get_ticks_msec() + 8000
	while get_viewport().gui_get_focus_owner() == null and Time.get_ticks_msec() < until:
		await get_tree().process_frame
	(title._menu.get_child(1) as Button).grab_focus()
	await _pad_tap(JOY_BUTTON_DPAD_DOWN)
	var after_dpad := get_viewport().gui_get_focus_owner()
	_check(after_dpad == title._menu.get_child(2), "the D-pad moves down the title menu")
	await _stick_tap(JOY_AXIS_LEFT_Y, -1.0)
	_check(get_viewport().gui_get_focus_owner() == title._menu.get_child(1), "and the stick moves back up")
	_check(Settings.using_pad, "pad presses switch the prompts to the pad")
	await _pad_tap(JOY_BUTTON_A)
	_check(title._page == title._files, "A opens Journeys on the title")
	await _pad_tap(JOY_BUTTON_B)
	_check(title._page == null, "B goes back to the title menu")
	title._leaving = true
	title.queue_free()
	await get_tree().process_frame
	# The pause menu: Start opens it, the triggers and LB go round every tab.
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.STILL_COVE, StoryDirector.FISHING_HOLE_AT + Vector2(0, -18))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	game.player._invuln = 600.0
	var menu: PauseMenu = game.get_node("PauseMenu") if game.has_node("PauseMenu") else null
	if menu == null:
		for child in game.get_children():
			if child is PauseMenu:
				menu = child
	_check(menu != null, "the game has a pause menu")
	if menu == null:
		game.queue_free()
		_restore_pad_settings(had_settings, old_settings)
		return
	await _pad_tap(JOY_BUTTON_START)
	_check(menu.visible and menu.current == PauseMenu.Tab.SATCHEL, "Start opens the pause menu on the Satchel")
	var visited := [menu.current]
	for i in PauseMenu.TABS.size():
		await _stick_tap(JOY_AXIS_TRIGGER_RIGHT, 1.0)
		visited.append(menu.current)
	_check(visited == [0, 1, 2, 3, 4, 0], "RT goes through every tab, Progress too, and round (%s)" % [visited])
	await _pad_tap(JOY_BUTTON_LEFT_SHOULDER)
	_check(menu.current == PauseMenu.Tab.JOURNEY, "LB goes back a tab")
	await _stick_tap(JOY_AXIS_TRIGGER_LEFT, 1.0)
	_check(menu.current == PauseMenu.Tab.OPTIONS, "and so does LT")
	# On a pad, no page's hint names a keyboard key.
	var compared := 0
	for tab in PauseMenu.TABS.size():
		menu.show_tab(tab)
		var page: MenuPage = menu._pages[tab]
		Settings.using_pad = false
		var keys_hint := page.hint()
		Settings.using_pad = true
		var pad_hint := page.hint()
		for action: String in Settings.REMAPPABLE:
			var key := MenuKit.keyboard_name(action)
			var word := RegEx.create_from_string("(^|[^A-Za-z])%s([^A-Za-z]|$)" % key)
			if word.search(keys_hint) != null:
				compared += 1
				_check(word.search(pad_hint) == null, "%s's hint shows no keyboard key on a pad: %s" % [PauseMenu.TABS[tab], pad_hint])
	_check(compared > 0, "some page hints name keys to compare")
	_check(_pad_names_ok(), "every action has a pad button with a name")
	await _pad_tap(JOY_BUTTON_B)
	_check(not menu.visible, "B closes the pause menu")
	# Remapping on a pad: the cursor starts on the pad column, and a pad button
	# rebinds the button even from the keyboard column.
	var controls := ControlsPage.new()
	add_child(controls)
	controls.on_open()
	_check(controls._column == 1, "on a pad, remapping starts in the gamepad column")
	var action: String = Settings.REMAPPABLE[controls._row]
	controls.handle_input(_pad_event(JOY_BUTTON_A))
	_check(controls._waiting, "A waits for the new button")
	controls.handle_input(_pad_event(JOY_BUTTON_RIGHT_STICK))
	_check(not controls._waiting and ControlsPage.pad_text(action) == MenuKit.pad_key("PAD_BUTTON_%d" % JOY_BUTTON_RIGHT_STICK), "a pad button rebinds it")
	controls._column = 0
	controls.handle_input(_pad_event(JOY_BUTTON_A))
	controls.handle_input(_pad_event(JOY_BUTTON_LEFT_STICK))
	_check(not controls._waiting and controls._column == 1 and ControlsPage.pad_text(action) == MenuKit.pad_key("PAD_BUTTON_%d" % JOY_BUTTON_LEFT_STICK), "picked on the keyboard column, a pad button still rebinds the button")
	controls.handle_input(_pad_event(JOY_BUTTON_A))
	_check(not OS.get_keycode_string(KEY_ESCAPE) in controls.hint(), "on a pad, waiting says Start cancels, not Escape: " + controls.hint())
	controls.handle_input(_pad_event(JOY_BUTTON_START))
	_check(not controls._waiting, "Start cancels waiting for a button")
	controls.queue_free()
	Settings.reset_controls()
	Settings.save_settings()
	# The left stick walks Wren.
	var from: Vector2 = game.player.global_position
	_stick(JOY_AXIS_LEFT_X, -1.0)
	await _wait(0.3)
	_stick(JOY_AXIS_LEFT_X, 0.0)
	_check(game.player.global_position.x < from.x - 4, "the left stick walks Wren")
	# Ice fishing: A casts.
	var room: Room = game.current_room
	var hole := room.get_children().filter(func(c: Node) -> bool: return c is FishingHole)[0] as FishingHole
	GameState.set_flag("ottilie_asked")
	game.player.global_position = room.global_position + StoryDirector.FISHING_HOLE_AT + Vector2(0, -18)
	game.player.facing = Vector2.DOWN
	await _wait(0.1)
	await _pad_tap(JOY_BUTTON_A)
	_check(hole.state == FishingHole.State.WAITING, "A casts at the fishing hole")
	game.queue_free()
	await _wait(0.1)
	# The echo game: A strikes Coralie's chime.
	GameState.reset_new_game()
	for flag in ["met_hessa", "coralie_asked", "coralie_chime_done", EchoGame.ASK_FLAG]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.SHORE, StoryDirector.CHIME_AT + Vector2(0, 18))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	room = game.current_room
	var echo := room.get_children().filter(func(c: Node) -> bool: return c is EchoGame)[0] as EchoGame
	game.player.global_position = room.global_position + StoryDirector.CHIME_AT + Vector2(0, 18)
	game.player.facing = Vector2.UP
	await _wait(0.1)
	await _pad_tap(JOY_BUTTON_A)
	_check(echo.state == EchoGame.State.SHOW, "A strikes the chime and starts the echo game")
	game.queue_free()
	await _wait(0.1)
	# Wick's round: A rings the dusk bell.
	GameState.reset_new_game()
	var flags := ["wick_asked", "wick_gave_jar", "wick_told_sink", FenLantern.ALL_LIT_FLAG, StoryDirector.TURNED_FLAG, LamplighterRound.ASK_FLAG]
	for coord: Vector2i in FenLantern.SPOTS:
		flags.append(FenLantern.flag_for(coord))
	for flag: String in flags:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.FENMOUTH, StoryDirector.DUSK_BELL_AT + Vector2(0, 18))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	game.player._invuln = 600.0
	game.player.global_position = game.current_room.global_position + StoryDirector.DUSK_BELL_AT + Vector2(0, 18)
	game.player.facing = Vector2.UP
	await _wait(0.1)
	await _pad_tap(JOY_BUTTON_A)
	_check(LamplighterRound.running, "A rings Wick's dusk bell and starts the round")
	if is_instance_valid(LamplighterRound.current):
		LamplighterRound.current.stop()
	game.queue_free()
	await _wait(0.1)
	# Every line that names a control names a pad button, in every pad style.
	var csv := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	var with_tokens: Array[String] = []
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size() > 1 and "{" in row[1]:
			with_tokens.append(row[0])
	_check(not with_tokens.is_empty(), "some lines name controls")
	Settings.using_pad = true
	for style: String in ["xbox", "playstation", "nintendo"]:
		Settings.pad_style = style
		_check(_pad_names_ok(), "every action has a named %s button" % style)
		var either := tr("ITEM_KEYS_EITHER") % [MenuKit.pad_name("item_1"), MenuKit.pad_name("item_2")]
		for key: String in with_tokens:
			var expected := tr(key).replace("{key}", either)
			for act: String in Settings.REMAPPABLE:
				expected = expected.replace("{%s}" % act, MenuKit.pad_name(act))
			var text := MenuKit.fill_keys(tr(key))
			_check(text == expected and not "{" in text, "%s names %s buttons: %s" % [key, style, text])
	_restore_pad_settings(had_settings, old_settings)


## Puts the settings file and the pad state back after the pad tour.
func _restore_pad_settings(had_settings: bool, old_settings: String) -> void:
	var settings_path := ProjectSettings.globalize_path(Settings.PATH)
	Settings.pad_style = "xbox"
	Settings.using_pad = false
	Settings._pad_device = -1
	if had_settings:
		var file := FileAccess.open(settings_path, FileAccess.WRITE)
		file.store_string(old_settings)
		file.close()
	else:
		DirAccess.remove_absolute(settings_path)
	Settings.load_settings()
	Settings.apply()


## Every action has a gamepad button, and the button has a name.
func _pad_names_ok() -> bool:
	for action: String in Settings.REMAPPABLE:
		var named := false
		for event in InputMap.action_get_events(action):
			var key := ""
			if event is InputEventJoypadButton:
				key = MenuKit.pad_key("PAD_SHORT_%d" % event.button_index)
			elif event is InputEventJoypadMotion:
				key = MenuKit.pad_key("PAD_SHORT_AXIS_%d" % event.axis)
			if key != "":
				named = tr(key) != key
				break
		if not named:
			return false
	return true


## A pad button pressed and let go, the way a pad sends it.
func _pad_tap(button: JoyButton) -> void:
	Input.parse_input_event(_pad_event(button))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var up := _pad_event(button)
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().physics_frame
	await get_tree().process_frame


func _stick(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


## A stick (or trigger) pushed and let back.
func _stick_tap(axis: JoyAxis, value: float) -> void:
	_stick(axis, value)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_stick(axis, 0.0)
	await get_tree().physics_frame
	await get_tree().process_frame

## Wick's lamplighter's round: ring the dusk bell and the fen's lanterns
## go out for the round; light all five against the clock. The lanterns'
## own flags stay as they were; each time beaten earns a purse, in order.
func _test_wick_round() -> void:
	GameState.reset_new_game()
	var flags := ["wick_asked", "wick_gave_jar", "wick_told_sink", FenLantern.ALL_LIT_FLAG, StoryDirector.TURNED_FLAG]
	for coord: Vector2i in FenLantern.SPOTS:
		flags.append(FenLantern.flag_for(coord))
	for flag: String in flags:
		GameState.set_flag(flag)
	var first := func() -> String:
		var lines: Array = Conversations.branch_for("wick").get("lines", [""])
		return str(lines[0]) if lines[0] is String else str(lines[1])
	_check(first.call() == "WICK_ROUND_1", "once the Old One's turned, Wick tells of the round")
	for line: String in ["WICK_ROUND_1", "WICK_ROUND_1B", "WICK_ROUND_2", "WICK_ROUND_2B", "WICK_ROUND_65_1", "WICK_ROUND_65_2", "NARRATE_DUSK_BELL"]:
		_check(tr(line).length() <= 70, "%s fits the box" % line)
	GameState.set_checkpoint(StoryDirector.FENMOUTH, StoryDirector.DUSK_BELL_AT + Vector2(0, 18))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	game.player._invuln = 600.0
	var room: Room = game.current_room
	var bells := room.get_children().filter(func(c: Node) -> bool: return c is DuskBell)
	_check(bells.size() == 1, "Wick's dusk bell stands at Fenmouth")
	var tile := Vector2i(StoryDirector.DUSK_BELL_AT / Room.TILE)
	_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y + 1) == ".", "on open ground, above the box")
	var bell: DuskBell = bells[0]
	bell.interact()
	await _close_dialogue(game)
	_check(not LamplighterRound.running, "before Wick explains it, the bell's just a bell")
	Conversations.talk("wick")
	await _close_dialogue(game)
	bell.interact()
	_check(LamplighterRound.running and is_instance_valid(LamplighterRound.current), "rung, the round begins")
	await _wait(0.5)
	_check(LamplighterRound.current.elapsed > 0.3, "and the clock runs")
	# Over to Glowcap Grove: its lantern is out for the round.
	game.player.global_position = room.global_position + Vector2(-12, 5 * 16 + 8)
	await _wait(0.8)
	room = game.current_room
	var lantern: FenLantern = room.get_children().filter(func(c: Node) -> bool: return c is FenLantern)[0]
	_check(room.coord == Vector2i(3, 1) and LamplighterRound.running and not lantern.lit, "the next room's lantern is out for the round")
	lantern.light()
	_check(lantern.lit and LamplighterRound.lit.has(Vector2i(3, 1)), "and lights again for it")
	# Back through Fenmouth and south off the fen: the round's off.
	game.player.global_position = room.global_position + Vector2(Room.SIZE.x + 12, 5 * 16 + 8)
	await _wait(0.8)
	_check(game.current_room.coord == StoryDirector.FENMOUTH and LamplighterRound.running, "Fenmouth is part of the round")
	game.player.global_position = game.current_room.global_position + Vector2(11 * 16 + 8, Room.SIZE.y + 12)
	await _wait(0.8)
	_check(not LamplighterRound.running and LamplighterRound.current == null, "off the fen, the round's off")
	for coord: Vector2i in FenLantern.SPOTS:
		_check(GameState.has_flag(FenLantern.flag_for(coord)), "lantern %s still lit for keeps" % coord)
	# A fast round: all five in 60 seconds beats every time.
	LamplighterRound.begin(game)
	LamplighterRound.current.elapsed = 60.0
	for coord: Vector2i in FenLantern.SPOTS:
		LamplighterRound.lantern_lit(coord)
	_check(not LamplighterRound.running and LamplighterRound.best() == 60, "all five: the time stands (%d)" % LamplighterRound.best())
	for tier: int in LamplighterRound.TIERS:
		_check(GameState.has_flag(LamplighterRound.tier_flag(tier)), "beat %d seconds" % tier)
	var glints := GameState.item_count("glint")
	for expect: Array in [["WICK_ROUND_100_1", 50], ["WICK_ROUND_80_1", 100], ["WICK_ROUND_65_1", 200]]:
		_check(first.call() == expect[0], "Wick pays: %s" % expect[0])
		Conversations.talk("wick")
		glints += int(expect[1])
	_check(GameState.item_count("glint") == glints and not first.call().begins_with("WICK_ROUND"), "every purse paid, once")
	# A slower round doesn't spoil the best.
	LamplighterRound.begin(game)
	LamplighterRound.current.elapsed = 120.0
	for coord: Vector2i in FenLantern.SPOTS:
		LamplighterRound.lantern_lit(coord)
	_check(LamplighterRound.best() == 60, "a slower round keeps the best")
	await _wait(0.2)
	game.queue_free()
	await _wait(0.1)
	_check(not LamplighterRound.running, "nothing left running")
	GameState.reset_new_game()


## Murmur helps Wick at Fenmouth once out of the Choir; Mother Dace sits by
## the last mural after the ending.
func _test_murmur_and_dace() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.FENMOUTH, StoryDirector.MURMUR_FEN_AT + Vector2(0, 20))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "murmur") == null, "Murmur isn't at Fenmouth while still in the Choir")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.CALF_FLAG)
	GameState.set_checkpoint(StoryDirector.FENMOUTH, StoryDirector.MURMUR_FEN_AT + Vector2(0, 20))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	var room: Room = game.current_room
	_check(_find_kind(room, "murmur") != null, "after the calf, Murmur tends Fenmouth's lanterns with Wick")
	var tile := Vector2i(StoryDirector.MURMUR_FEN_AT / Room.TILE)
	_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == ".", "Murmur stands on dry ground, above the dialogue box")
	game.player.facing = Vector2.UP
	await _wait(0.1)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages == 3 and GameState.has_flag("murmur_met"), "Murmur hums the lights home now (%d pages)" % pages)
	_check(Conversations.branch_for("murmur").get("lines") == ["MURMUR_AGAIN"], "and helps Wick count")
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	_check(Conversations.branch_for("murmur").get("lines") == ["MURMUR_TURNED"], "Murmur feels the turn")
	GameState.set_flag(StoryDirector.ENDING_FLAG)
	_check(Conversations.branch_for("murmur").get("lines") == ["MURMUR_END"], "and sees the lights go out to sea")
	var robed: Npc = _find_kind(room, "murmur")
	_check(robed._sprite.texture == Art.VILLAGER_MURMUR, "met before the ending, Murmur still wears the robe")
	var plain := Npc.new("murmur")
	room.add_child(plain)
	_check(plain._sprite.texture == Art.VILLAGER_MURMUR_PLAIN, "after the ending, Murmur has put the Choir robe away")
	_check(Conversations.pages("murmur", {"lines": ["MURMUR_END"]})[0]["portrait"] == Art.PORTRAIT_MURMUR_PLAIN, "and the portrait matches")
	plain.queue_free()
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()
	for flag in [HollowRegent.DEFEATED_FLAG, StoryDirector.MURAL_FLAG]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.TOMB_BOSS, StoryDirector.DACE_AFTER_AT + Vector2(0, 20))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "dace") == null, "before the ending, Dace isn't back at the mural")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()
	for flag in [HollowRegent.DEFEATED_FLAG, StoryDirector.MURAL_FLAG, StoryDirector.ENDING_FLAG, StoryDirector.DREAM_FLAG]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.TOMB_BOSS, StoryDirector.DACE_AFTER_AT + Vector2(0, 20))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_enemies_away()
	room = game.current_room
	_check(_find_kind(room, "dace") != null, "after the ending, Mother Dace sits by the last mural")
	tile = Vector2i(StoryDirector.DACE_AFTER_AT / Room.TILE)
	_check(room.tile_at(tile.x, tile.y) == ".", "on open sand")
	_check(Conversations.branch_for("dace").get("lines")[0] == "DACE_END_1", "she talks of the bones and the dreaming")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## Three errands across the coast, played as conversations: Sorrel's last
## letters, Ottilie's lamp sign for Hessa, and a lantern for Murmur's family.
func _test_errands() -> void:
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	var talk := func(who: String) -> void: Conversations.talk(who)
	# Sorrel's letters.
	for flag in ["sorrel_asked", "sorrel_raced", "sorrel_won", "sorrel_paid"]:
		GameState.set_flag(flag)
	_check(first.call("sorrel") == "SORREL_LETTERS_1", "after the race, Sorrel has three letters that never went out")
	talk.call("sorrel")
	_check(first.call("agna") == "AGNA_1" and first.call("liesl") == "LIESL_1" and first.call("ottilie") == "OTTILIE_1", "everyone still introduces themselves before taking a letter")
	for flag in ["ottilie_asked", "liesl_asked", "met_agna", "agna_gave_sword"]:
		GameState.set_flag(flag)
	_check(first.call("sorrel") == "SORREL_LETTERS_WAITING", "she waits while Wren carries them")
	var glints := GameState.item_count("glint")
	for who in ["ottilie", "liesl", "agna"]:
		_check(Conversations.branch_for(who).get("lines")[1] == who.to_upper() + "_LETTER_1", "%s gets a letter" % who)
		talk.call(who)
	_check(first.call("sorrel") == "SORREL_LETTERS_DONE_1", "all three delivered")
	talk.call("sorrel")
	GameState.set_flag("sorrel_dared_stacks")
	_check(GameState.item_count("glint") == glints + 150 and first.call("sorrel") == "SORREL_AFTER", "courier's pay, then back to her usual")
	# Ottilie's sign for Hessa.
	GameState.set_flag("ottilie_paid")
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	GameState.set_flag("ottilie_told_vael")
	GameState.set_flag("ottilie_knits_told")
	# Her fishing book long since opened and the Old Grey landed.
	GameState.set_flag(FishingHole.BOOK_FLAG)
	GameState.set_flag("booked_grey")
	_check(first.call("ottilie") == "OTTILIE_AFTER", "before Hessa's confession, Ottilie keeps her quarrel to herself")
	GameState.set_flag(StoryDirector.CONFESSION_FLAG)
	_check(first.call("ottilie") == "OTTILIE_SIGNAL_1", "after it, she sends Hessa her old cave sign")
	talk.call("ottilie")
	_check(first.call("ottilie") == "OTTILIE_SIGNAL_WAITING", "and waits for an answer")
	_check(Conversations.branch_for("hessa").get("lines")[1] == "HESSA_OTTILIE_1", "Wren shows Hessa the sign")
	talk.call("hessa")
	glints = GameState.item_count("glint")
	_check(Conversations.branch_for("ottilie").get("lines")[1] == "OTTILIE_REPLY_1", "Wren flashes Hessa's yes back to Ottilie")
	talk.call("ottilie")
	_check(GameState.item_count("glint") == glints + 100 and first.call("ottilie") == "OTTILIE_AFTER", "and thanks Wren")
	# A lantern for Murmur's family.
	for flag in ["wick_asked", "fen_lanterns_lit", "wick_gave_jar", "wick_round_ask", "murmur_met"]:
		GameState.set_flag(flag)
	_check(first.call("wick") == "WICK_MURMUR_1", "Wick wants a lantern for Murmur's family")
	talk.call("wick")
	_check(first.call("wick") == "WICK_MURMUR_WAITING", "and sends Wren to ask Liesl")
	_check(first.call("liesl") == "LIESL_MURMUR_1", "Liesl knows the family")
	talk.call("liesl")
	GameState.give_item("glowmoth_lantern", 1, false)
	_check(first.call("wick") == "WICK_LANTERN_1", "with it, Wren lights the Reed lantern")
	talk.call("wick")
	_check(first.call("murmur") == "MURMUR_LANTERN_1", "Murmur finds it")
	talk.call("murmur")
	_check(first.call("murmur") == "MURMUR_SONG_1", "and afterwards, the turn has Murmur thinking of the Reeds' song")
	GameState.clear_flag(StoryDirector.TURNED_FLAG)
	_check(first.call("murmur") == "MURMUR_LANTERN_AGAIN", "before the turn, Murmur keeps the lantern lit")
	GameState.reset_new_game()


## With the tide held out, Gully is out on the Ebb Shelf by a lantern-boat
## the ebb bared, and there is a child's cap under its bench.
func _test_ebb_shelf() -> void:
	GameState.reset_new_game()
	for flag in [StoryDirector.TURNED_FLAG, Tide.HELD_FLAG, "met_hessa", "gully_asked"]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.EBB_SHELF, StoryDirector.GULLY_EBB_AT + Vector2(0, 16))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "gully_ebb") == null, "until his strongbox is home, Gully stays on the Wreck Strand")
	game.queue_free()
	await _wait(0.1)
	GameState.set_flag("gully_paid")
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room: Room = game.current_room
	var tile := Vector2i(StoryDirector.GULLY_EBB_AT / Room.TILE)
	_check(_find_kind(room, "gully_ebb") != null and room.tile_at(tile.x, tile.y) == ".", "with the tide held out, Gully stands on the Shelf's dry sandbar")
	_check(tile.y <= 8, "above the dialogue box")
	var boat: LanternBoat = null
	for child in room.get_children():
		if child is LanternBoat:
			boat = child
	_check(boat != null, "the bared wreck can be searched")
	_check(Conversations.branch_for("lantern_boat").get("lines") == ["NARRATE_LANTERN_BOAT"], "before Gully's story, it's only an old boat")
	game.player.facing = Vector2.UP
	await _wait(0.1)
	game.player.try_interact()
	var pages := await _play_scene(game, 10.0)
	_check(pages == 4 and GameState.has_flag("gully_ebb_told"), "Gully remembers the storm twelve years back (%d pages)" % pages)
	_check(Conversations.branch_for("lantern_boat").get("lines")[1] == "NARRATE_FOUND_CAP_1", "now Wren finds the cap under the bench")
	await _close_dialogue(game)
	for side: Vector2 in [Vector2(0, 10), Vector2(0, -20)]:
		game.player.global_position = boat.global_position + side
		game.player.facing = Vector2.UP if side.y > 0 else Vector2.DOWN
		await _wait(0.4)
		_check(game.player.try_interact() and DialogueBox.is_open, "Wren can search the boat from the %s" % ("south" if side.y > 0 else "north"))
		await _close_dialogue(game)
		await _wait(0.4)
	_check(GameState.has_flag("found_wren_cap") and Conversations.branch_for("lantern_boat").get("lines") == ["NARRATE_LANTERN_BOAT_EMPTY"], "and the boat is empty after")
	_check(Conversations.branch_for("gully_ebb").get("lines") == ["GULLY_EBB_AFTER"], "Gully sees Wren found something")
	_check(Conversations.branch_for("hessa").get("lines")[1] == "HESSA_CAP_1", "Wren shows Hessa the cap")
	Conversations.talk("hessa")
	_check(GameState.has_flag("hessa_saw_cap") and not (Conversations.branch_for("hessa").get("lines") as Array).has("HESSA_CAP_1"), "once")
	await _close_dialogue(game)
	game.queue_free()
	await _wait(0.1)
	# Meanwhile the Wreck Strand is without him; with the tide free, he's home.
	for held in [true, false]:
		if not held:
			GameState.clear_flag(Tide.HELD_FLAG)
		GameState.set_checkpoint(StoryDirector.WRECK_STRAND, StoryDirector.GULLY_AT + Vector2(0, 20))
		game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.4)
		_check((_find_kind(game.current_room, "gully") == null) == held, "Gully %s the Wreck Strand" % ("is away from" if held else "is back on"))
		game.queue_free()
		await _wait(0.1)
	GameState.reset_new_game()


## Sorrel, Wick and Dace each point Wren at one of the overworld trials,
## and notice when it's done.
func _test_challenge_talk() -> void:
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	var steps := [
		["sorrel", ["sorrel_asked", "sorrel_raced", "sorrel_won", "sorrel_paid", "sorrel_letters", "sorrel_letters_paid"], "SORREL_STACKS_1", "chest_7_-4_20_2", "SORREL_STACKS_DONE_1", "SORREL_AFTER"],
		["wick", ["wick_asked", "fen_lanterns_lit", "wick_gave_jar"], "WICK_SINK_1", "gate_5_3", "WICK_SINK_DONE_1", "WICK_AFTER"],
		["dace", ["dace_sat"], "DACE_RING_1", "gate_8_2", "DACE_RING_DONE_1", "DACE_AGAIN"],
	]
	for step: Array in steps:
		GameState.reset_new_game()
		for flag: String in step[1]:
			GameState.set_flag(flag)
		_check(first.call(step[0]) == step[2], "%s points Wren at the trial" % step[0])
		Conversations.talk(step[0])
		_check(first.call(step[0]) == step[5], "%s says it once" % step[0])
		GameState.set_flag(step[3])
		_check(first.call(step[0]) == step[4], "%s notices it's done" % step[0])
		Conversations.talk(step[0])
		_check(first.call(step[0]) == step[5], "and then back to the usual")
	# Done before being asked: straight to the praise, never the dare.
	GameState.reset_new_game()
	for flag in ["wick_asked", "fen_lanterns_lit", "wick_gave_jar", "gate_5_3"]:
		GameState.set_flag(flag)
	Conversations.talk("wick")
	_check(first.call("wick") == "WICK_AFTER", "a trial done unasked is praised, not dared")
	GameState.reset_new_game()


## Hessa sends Wren to read every Tidestone; when they have, she cuts
## Wren's line under her own on the Saltmarrow stone.
func _test_keepers_round() -> void:
	GameState.reset_new_game()
	for flag in ["met_hessa", "seen_wayshell", "tidebell_kiln", "hessa_round_ask"]:
		GameState.set_flag(flag)
	var stone := Tidestone.new()
	add_child(stone)
	stone.awake = true
	var coords: Array = Tidestone.CARVINGS.keys()
	for coord: Vector2i in coords:
		stone.room_coord = coord
		if coord == coords[-1]:
			_check(not GameState.has_flag(Tidestone.ALL_READ_FLAG), "one stone short, the round isn't done")
		stone.interact()
	_check(Tidestone.read_count() == coords.size() and GameState.has_flag(Tidestone.ALL_READ_FLAG), "every stone read")
	_check(Conversations.branch_for("hessa").get("lines")[0] == "HESSA_ROUND_DONE_1", "Hessa sees Wren has walked the round")
	_check(Tidestone.carving_for(Tidestone.SALTMARROW_STONE).size() == 2, "before she carves, the village stone holds only her line")
	Conversations.talk("hessa")
	_check(Tidestone.carving_for(Tidestone.SALTMARROW_STONE)[-1] == "STONE_SALTMARROW_WREN", "and now Wren's line is cut under hers")
	_check(Conversations.branch_for("hessa").get("lines")[0] != "HESSA_ROUND_DONE_1", "once")
	# After the turn, a read stone turns the tide, but Wren's new line is read first.
	GameState.set_flag(Tide.TURNED_FLAG)
	stone.room_coord = Tidestone.SALTMARROW_STONE
	stone.interact()
	_check(GameState.has_flag(Tidestone.WREN_LINE_READ_FLAG), "after the turn, Wren's new line is still read once")
	stone.interact()
	_check(Tide.held() != "", "and then the stone turns the tide as before")
	stone.queue_free()
	GameState.reset_new_game()


## After the ending, Sister Lowe asks Wren to find four singers who never
## went home; each needs a small push from someone Wren already knows.
func _test_last_singers() -> void:
	GameState.reset_new_game()
	for flag in [StoryDirector.ENDING_FLAG, StoryDirector.DREAM_FLAG]:
		GameState.set_flag(flag)
	for kind: String in StoryDirector.SINGERS:
		var spot: Array = StoryDirector.SINGERS[kind]
		var at := Vector2(spot[1]) * 16.0 + Vector2(8, 10)
		GameState.set_checkpoint(spot[0], at + Vector2(0, 20))
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.4)
		var room: Room = game.current_room
		var tile: Vector2i = spot[1]
		_check(_find_kind(room, kind) != null, "%s sits alone in room %s" % [kind, spot[0]])
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y + 1) != "#", "%s is on dry ground Wren can reach, above the box" % kind)
		game.queue_free()
		await _wait(0.1)
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	var lines := func(who: String) -> Array: return Conversations.branch_for(who).get("lines", [])
	for flag in ["lowe_spoke", "met_agna", "ottilie_asked", "sorrel_asked", "wick_asked"]:
		GameState.set_flag(flag)
	_check(first.call("lowe") == "LOWE_SINGERS_1", "Lowe asks after her last four singers")
	Conversations.talk("lowe")
	_check(first.call("lowe") == "LOWE_SINGERS_WAITING", "and counts them while Wren looks")
	# Each one, then the friend who sends for them.
	for pair in [["bram", "agna", "AGNA_BRAM_1"], ["sela", "ottilie", "OTTILIE_SELA_1"], ["ansel", "sorrel", "SORREL_ANSEL_1"]]:
		_check(first.call(pair[1]) != pair[2], "%s has nothing to say of %s before Wren meets them" % [pair[1], pair[0]])
		Conversations.talk(pair[0])
		_check(first.call(pair[0]) == pair[0].to_upper() + "_WAITING", "%s won't go home alone" % pair[0])
		_check(first.call(pair[1]) == pair[2], "%s sends word" % pair[1])
		Conversations.talk(pair[1])
		_check((lines.call(pair[0]) as Array).has(pair[0].to_upper() + "_HOME_1"), "and %s goes home" % pair[0])
		Conversations.talk(pair[0])
		_check(GameState.has_flag(pair[0] + "_home"), "%s is home" % pair[0])
	Conversations.talk("pim")
	_check(first.call("pim") == "PIM_WAITING", "Pim waits for a light")
	GameState.give_item("glowmoth_lantern", 1, false)
	Conversations.talk("pim")
	_check(GameState.has_flag("pim_home") and first.call("wick") == "WICK_PIM", "Wren lights Pim home, and Wick has a new counter")
	var glints := GameState.item_count("glint")
	_check(first.call("lowe") == "LOWE_SINGERS_DONE_1", "all four home")
	Conversations.talk("lowe")
	_check(GameState.item_count("glint") == glints + 300 and first.call("lowe") == "LOWE_JUST_LOWE", "Lowe sets down her robe and the Choir's purse")
	# They've gone home, and Bram is at the forge.
	GameState.set_checkpoint(StoryDirector.KILN_MOUTH, StoryDirector.BRAM_FORGE_AT + Vector2(0, 20))
	var forge: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(forge)
	await _wait(0.4)
	var tile := Vector2i(StoryDirector.BRAM_FORGE_AT / Room.TILE)
	_check(_find_kind(forge.current_room, "bram") != null and forge.current_room.tile_at(tile.x, tile.y) == "." and forge.current_room.tile_at(tile.x, tile.y + 1) != "#", "Bram works Agna's bellows now")
	_check(first.call("bram") == "BRAM_FORGE", "and is learning")
	forge.queue_free()
	await _wait(0.1)
	var spot: Array = StoryDirector.SINGERS["sela"]
	GameState.set_checkpoint(spot[0], Vector2(spot[1]) * 16.0 + Vector2(8, 30))
	var cold: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(cold)
	await _wait(0.4)
	_check(_find_kind(cold.current_room, "sela") == null, "Sela's spot is empty once she's home")
	cold.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## A cutscene scored with a story cue hands the room its own music back.
func _test_scene_music() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(12 * 16 + 8, 8 * 16 + 10))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room_cue := Audio.music_cue
	var scene := Cutscene.new(game)
	add_child(scene)
	scene.begin()
	scene.music("story_sorrow")
	_check(Audio.music_cue == "story_sorrow", "a scene can score itself")
	scene.finish()
	_check(Audio.music_cue == room_cue and room_cue != "", "and the room's music comes back after")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## Ferrin the mapmaker gives Wren three survey stakes for the far reaches,
## and finishes his map when all three are driven in.
func _test_edge_survey() -> void:
	GameState.reset_new_game()
	# Ferrin and each stake stand where Wren can reach them from below.
	var spots := {"ferrin": [StoryDirector.FERRIN_ROOM, Vector2i(StoryDirector.FERRIN_AT / Room.TILE)]}
	for id: String in StoryDirector.SURVEY_STAKES:
		spots["stake_" + id] = StoryDirector.SURVEY_STAKES[id]
	for what: String in spots:
		var spot: Array = spots[what]
		var tile: Vector2i = spot[1]
		GameState.set_checkpoint(spot[0], Vector2(tile) * 16.0 + Vector2(8, 30))
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.4)
		var room: Room = game.current_room
		var found := room.get_children().any(func(c: Node) -> bool: return (c is Npc and what == "ferrin") or (c is SurveyStake and "stake_" + (c as SurveyStake).id == what))
		_check(found, "%s is placed in room %s" % [what, spot[0]])
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y + 1) == ".", "%s stands on dry floor with dry floor below" % what)
		game.queue_free()
		await _wait(0.1)
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	_check(first.call("survey_stake_frost") == "NARRATE_STAKE_CAIRN", "before Ferrin asks, a stake spot is only a cairn")
	Conversations.talk("survey_stake_frost")
	_check(not GameState.has_flag("survey_stake_frost"), "and Wren can't drive a stake they don't have")
	_check(first.call("ferrin") == "FERRIN_1", "Ferrin introduces himself")
	Conversations.talk("ferrin")
	_check(first.call("ferrin") == "FERRIN_WAITING", "and waits on the stakes")
	for id in ["frost", "cinder", "verge"]:
		_check(first.call("ferrin") == "FERRIN_WAITING", "not done before the %s stake" % id)
		Conversations.talk("survey_stake_" + id)
		_check(GameState.has_flag("survey_stake_" + id) and first.call("survey_stake_" + id) == "NARRATE_STAKE_STANDS", "the %s stake goes in, and stays" % id)
	var glints := GameState.item_count("glint")
	_check(first.call("ferrin") == "FERRIN_DONE_1", "all three in")
	Conversations.talk("ferrin")
	_check(GameState.item_count("glint") == glints + 200 and first.call("ferrin") == "FERRIN_AFTER", "Ferrin finishes his map and pays")
	GameState.reset_new_game()


## Loads the room and puts Wren a tile below `tile`, facing up at it.
func _stand_below(coord: Vector2i, tile: Vector2i) -> Node:
	GameState.set_checkpoint(coord, Vector2(tile) * 16.0 + Vector2(8, 30))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	game.player.facing = Vector2.UP
	await _wait(0.05)
	return game


## Agna's hand-bell: six shed scales, one in each puzzle cave, then Nettle.
func _test_old_ones_scales() -> void:
	GameState.reset_new_game()
	_check(StoryDirector.SHED_SCALES.size() == ShedScale.IDS.size(), "every scale has a spot")
	for id: String in StoryDirector.SHED_SCALES:
		var spot: Array = StoryDirector.SHED_SCALES[id]
		var tile: Vector2i = spot[1]
		var game: Node = await _stand_below(spot[0], tile)
		var room: Room = game.current_room
		_check(room.get_children().any(func(c: Node) -> bool: return c is ShedScale and (c as ShedScale).id == id), "the %s scale lies in room %s" % [id, spot[0]])
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y + 1) == ".", "the %s scale is on dry floor with dry floor below" % id)
		_check(game.player.try_interact(), "Wren can pick up the %s scale" % id)
		await _play_scene(game, 10.0)
		_check(GameState.has_flag(ShedScale.flag_for(id)) and not room.get_children().any(func(c: Node) -> bool: return c is ShedScale and c.visible and c.is_in_group("interactable")), "and does, and it's gone from the floor")
		game.queue_free()
		await _wait(0.1)
		# Once picked up, it's gone.
		game = await _stand_below(spot[0], tile)
		_check(not game.current_room.get_children().any(func(c: Node) -> bool: return c is ShedScale), "the %s scale stays picked up" % id)
		game.queue_free()
		await _wait(0.1)
	_check(ShedScale.found() == 6, "all six found")
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	for flag in ["met_agna", "tidebell_kiln", "agna_gave_sword", "met_hessa", "nettle_learned"]:
		GameState.set_flag(flag)
	_check(first.call("agna") == "AGNA_SMITH", "Agna waits for the Wayshell before asking")
	GameState.set_flag("seen_wayshell")
	_check(first.call("agna") == "AGNA_SCALES_1", "then asks for scale")
	Conversations.talk("agna")
	for id: String in ShedScale.IDS:
		_check(first.call("agna") == "AGNA_SCALES_WAITING", "not done before the %s scale" % id)
		GameState.set_flag(ShedScale.flag_for(id))
	var glints := GameState.item_count("glint")
	_check(first.call("agna") == "AGNA_SCALES_DONE_1", "six scales")
	Conversations.talk("agna")
	_check(GameState.item_count("glint") == glints + 250 and GameState.has_flag("agna_bell_cast"), "Agna pours the bell and pays")
	_check(first.call("agna") == "AGNA_BELL_WAITING", "and wants it delivered")
	var gives_bell := func() -> bool: return Conversations.branch_for("nettle").get("set", []).has("nettle_got_bell")
	_check(gives_bell.call(), "Wren gives Nettle the bell")
	Conversations.talk("nettle")
	_check(first.call("agna") == "AGNA_SMITH" and not gives_bell.call(), "once")
	GameState.reset_new_game()


## Nettle's signals: "I'm here" from three old signal stones.
func _test_nettle_signals() -> void:
	GameState.reset_new_game()
	for id: String in StoryDirector.SIGNAL_STONES:
		var spot: Array = StoryDirector.SIGNAL_STONES[id]
		var tile: Vector2i = spot[1]
		var game: Node = await _stand_below(spot[0], tile)
		var room: Room = game.current_room
		_check(room.get_children().any(func(c: Node) -> bool: return c is SignalStone and (c as SignalStone).id == id), "the %s signal stone stands in room %s" % [id, spot[0]])
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y + 1) == ".", "the %s stone is on dry floor with dry floor below" % id)
		_check(game.player.try_interact(), "Wren can look at the %s stone" % id)
		await _play_scene(game, 10.0)
		_check(not GameState.has_flag("signal_stone_" + id), "but can't light it before Nettle asks")
		game.queue_free()
		await _wait(0.1)
	# The first stone plays the signal scene and hands control back.
	for flag in ["met_hessa", "nettle_learned", "seen_wayshell", "nettle_signals_ask"]:
		GameState.set_flag(flag)
	var stacks: Array = StoryDirector.SIGNAL_STONES["stacks"]
	var game: Node = await _stand_below(stacks[0], stacks[1])
	_check(game.player.try_interact(), "Wren lights the Stacks stone")
	await _play_scene(game, 15.0)
	_check(GameState.has_flag("signal_stone_stacks") and not Cutscene.active and not DialogueBox.is_open, "the light is answered, and the scene ends")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	for flag in ["met_hessa", "nettle_learned"]:
		GameState.set_flag(flag)
	_check(first.call("nettle") == "NETTLE_AGAIN", "Nettle waits for the Wayshell before asking")
	GameState.set_flag("seen_wayshell")
	_check(first.call("nettle") == "NETTLE_SIGNALS_1", "then asks for the signals")
	Conversations.talk("nettle")
	for id: String in StoryDirector.SIGNAL_STONES:
		_check(first.call("nettle") == "NETTLE_SIGNALS_WAITING", "not done before the %s stone" % id)
		Conversations.talk("signal_stone_" + id)
		_check(first.call("signal_stone_" + id) == "NARRATE_SIGNAL_LIT", "the %s stone stays lit" % id)
	var glints := GameState.item_count("glint")
	Conversations.talk("nettle")
	_check(GameState.item_count("glint") == glints + 150 and GameState.has_flag("nettle_signals_done"), "Nettle saw all three")
	GameState.set_flag("nettle_got_bell")
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	_check(first.call("nettle") == "NETTLE_NEARLY", "bell and signals: nearly a keeper, even after the turn")
	Conversations.talk("nettle")
	_check(first.call("nettle") == "NETTLE_TURNED", "once")
	GameState.reset_new_game()


## Gran's table: once Liesl knows Gran lived, she asks for Gran's things.
## Ide has the cup; the candlestick and salt fish are finds. Handing them
## over plays supper in Drowned Lane.
func _test_gran_table() -> void:
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	var ide_first := func() -> String: return str(Conversations.branch_for("ide").get("lines", [""])[0])
	for flag in ["liesl_asked", StoryDirector.TURNED_FLAG, "tidebell_belfry", "met_ide_ferry"]:
		GameState.set_flag(flag)
	_check(first.call("liesl") == "LIESL_WAITING" and ide_first.call() != "IDE_CUP_1", "no table before Liesl hears of the grotto marks")
	GameState.set_flag("read_grotto_marks")
	_check(first.call("liesl") == "LIESL_MARKS_1", "the marks first")
	Conversations.talk("liesl")
	_check(first.call("liesl") == "LIESL_WAITING", "no table while her door bell's still lost")
	GameState.set_flag("found_doorbell")
	_check(first.call("liesl") == "LIESL_BELL_1", "the bell's hand-in isn't hidden")
	Conversations.talk("liesl")
	_check(first.call("liesl") == "LIESL_TABLE_1", "then Liesl asks for Gran's things")
	Conversations.talk("liesl")
	_check(first.call("liesl") == "LIESL_TABLE_WAITING", "and waits")
	for id in ["gran_candle", "gran_salt"]:
		_check(StoryDirector.FIND_NEEDS[id] == "liesl_table_ask", "%s only once she's asked" % id)
	GameState.clear_flag("met_ide_ferry")
	_check(ide_first.call() == "IDE_FERRY_1", "meeting Ide comes before the cup")
	GameState.set_flag("met_ide_ferry")
	_check(ide_first.call() == "IDE_CUP_1", "Ide has the blue cup")
	Conversations.talk("ide")
	_check(GameState.has_flag("table_cup") and ide_first.call() != "IDE_CUP_1", "and hands it over, once")
	Conversations.talk("find_gran_candle")
	_check(first.call("liesl") == "LIESL_TABLE_WAITING", "two of three isn't a table")
	Conversations.talk("find_gran_salt")
	# The table stands in the lane, bare, until supper.
	var talk_at := StoryDirector.LIESL_AT + Vector2(-14, 0)
	GameState.set_checkpoint(StoryDirector.DROWNED_LANE, talk_at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room: Room = game.current_room
	var tables: Array = room.get_children().filter(func(c: Node) -> bool: return c is GranTable)
	_check(tables.size() == 1 and not (tables[0] as GranTable).set_out, "Liesl's laid the plates")
	var at := Vector2i(StoryDirector.GRAN_TABLE_AT / 16.0)
	_check(room.tile_at(at.x, at.y) == "." and room.tile_at(at.x - 1, at.y) == "." and room.tile_at(at.x, at.y - 1) == ".", "the table stands on the lane's dry ground")
	for spot: Vector2 in [StoryDirector.WREN_SUPPER_AT, StoryDirector.IDE_SUPPER_AT, StoryDirector.LIESL_SUPPER_AT]:
		var cell := Vector2i(spot / 16.0)
		_check(cell.y <= 8 and room.tile_at(cell.x, cell.y) == ".", "supper places on the floor (%s)" % cell)
	var glints := GameState.item_count("glint")
	game.player.facing = Vector2.RIGHT
	await _wait(0.05)
	game.player.try_interact()
	var pages := await _play_scene(game, 40.0)
	_check(GameState.has_flag(StoryDirector.SUPPER_DONE_FLAG) and pages >= 12, "supper with Gran's things (%d pages)" % pages)
	_check(GameState.item_count("glint") == glints + StoryDirector.SUPPER_GLINTS, "Gran's housekeeping for Wren")
	var table: GranTable = tables[0]
	_check(table.set_out and table.candle_lit and table.bread, "cup, candle lit, fish and Ide's bread")
	_check(_find_kind(room, "ide") == null and not Cutscene.active, "Ide's gone back up the lane to her boat by the scene's end")
	_check(first.call("liesl") == "LIESL_TABLE_AFTER", "Liesl lays Gran's place every night now")
	game.queue_free()
	await _wait(0.2)
	# Back again: the table's still set, and supper doesn't play twice.
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	tables = game.current_room.get_children().filter(func(c: Node) -> bool: return c is GranTable)
	_check(tables.size() == 1 and (tables[0] as GranTable).candle_lit and not Cutscene.active, "her table stays set")
	game.queue_free()
	await _wait(0.2)
	# A supper the game closed partway through plays on the way back in,
	# Wren coming in from the far end of the lane.
	GameState.clear_flag(StoryDirector.SUPPER_DONE_FLAG)
	GameState.set_checkpoint(StoryDirector.DROWNED_LANE, Vector2(21 * 16 + 8, 2 * 16 + 10))
	glints = GameState.item_count("glint")
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	await _play_scene(game, 40.0)
	_check(GameState.has_flag(StoryDirector.SUPPER_DONE_FLAG) and GameState.item_count("glint") == glints + StoryDirector.SUPPER_GLINTS, "an unfinished supper picks up again")
	_check(game.player.global_position.distance_to(game.current_room.global_position + StoryDirector.WREN_SUPPER_AT) < 6.0, "and Wren finds their way round to the table")
	game.queue_free()
	await _wait(0.2)
	GameState.reset_new_game()


## The Reeds' song: after the turn, Murmur asks for the family's hymn
## pages (the Drowned Chapel, the Wreck Vault, Liesl), then sings it in the
## chapel.
func _test_reeds_song() -> void:
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	for flag in [StoryDirector.CALF_FLAG, "murmur_met", "murmur_lantern_lit", "murmur_saw_lantern", "liesl_asked"]:
		GameState.set_flag(flag)
	_check(first.call("murmur") == "MURMUR_LANTERN_AGAIN", "no song before the turn")
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	_check(first.call("murmur") == "MURMUR_SONG_1", "then Murmur asks after the Reeds' song")
	Conversations.talk("murmur")
	_check(first.call("murmur") == "MURMUR_SONG_WAITING", "and waits")
	for id in ["hymn_chapel", "hymn_vault"]:
		_check(StoryDirector.FIND_NEEDS[id] == "murmur_song_ask", "%s only once Murmur's asked" % id)
	_check(first.call("liesl") == "LIESL_HYMN_1", "Liesl has her gran's page")
	Conversations.talk("liesl")
	_check(GameState.has_flag("song_liesl") and first.call("liesl") != "LIESL_HYMN_1", "and hands it over, once")
	Conversations.talk("find_hymn_chapel")
	_check(first.call("murmur") == "MURMUR_SONG_WAITING", "two pages aren't the song")
	Conversations.talk("find_hymn_vault")
	_check(first.call("murmur") == "NARRATE_HAND_HYMNS" or (Conversations.branch_for("murmur").get("lines") as Array).has("MURMUR_SONG_DONE_1"), "all three: Murmur can read it")
	Conversations.talk("murmur")
	_check(GameState.has_flag(StoryDirector.REED_FLAG) and first.call("murmur") == "MURMUR_SONG_GO", "and goes to the chapel to sing it")
	# Not in the fen while waiting in the chapel.
	GameState.set_checkpoint(StoryDirector.FENMOUTH, StoryDirector.MURMUR_FEN_AT + Vector2(0, 20))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "murmur") == null, "Murmur's gone from the fen")
	game.queue_free()
	await _wait(0.2)
	# Into the chapel by its south door: the song.
	GameState.set_checkpoint(StoryDirector.DROWNED_CHAPEL, Vector2(9 * 16 + 8, 10 * 16 + 8))
	var glints := GameState.item_count("glint")
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.2)
	var room: Room = game.current_room
	for spot: Vector2 in [StoryDirector.MURMUR_CHAPEL_AT, StoryDirector.WREN_CHAPEL_AT]:
		var cell := Vector2i(spot / 16.0)
		_check(cell.y <= 8 and room.tile_at(cell.x, cell.y) == ".", "chapel places on the floor (%s)" % cell)
	var pages := await _play_scene(game, 40.0)
	_check(GameState.has_flag(StoryDirector.REED_DONE_FLAG) and pages >= 8, "Murmur sings the Reeds' song (%d pages)" % pages)
	_check(GameState.item_count("glint") == glints + StoryDirector.REED_GLINTS, "the Reed pew box for Wren")
	_check(game.player.global_position.distance_to(room.global_position + StoryDirector.WREN_CHAPEL_AT) < 6.0, "Wren stands to listen")
	_check(_find_kind(room, "murmur") == null and not Cutscene.active, "and Murmur heads home by the scene's end")
	_check(first.call("murmur") == "MURMUR_SONG_AFTER", "Murmur sings it to the lantern now")
	game.queue_free()
	await _wait(0.2)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "murmur") == null and not Cutscene.active, "the song plays once")
	game.queue_free()
	await _wait(0.2)
	GameState.set_checkpoint(StoryDirector.FENMOUTH, StoryDirector.MURMUR_FEN_AT + Vector2(0, 20))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	_check(_find_kind(game.current_room, "murmur") != null, "Murmur's back in the fen")
	game.queue_free()
	await _wait(0.2)
	GameState.reset_new_game()


## Small errands: Corrin's bottles, Pell's shell, Dunstan's driftwood.
func _test_small_finds() -> void:
	GameState.reset_new_game()
	for id: String in StoryDirector.FINDS:
		var spot: Array = StoryDirector.FINDS[id]
		var tile: Vector2i = spot[1]
		if StoryDirector.FIND_NEEDS.has(id):
			GameState.set_flag(StoryDirector.FIND_NEEDS[id])
		var game: Node = await _stand_below(spot[0], tile)
		var room: Room = game.current_room
		_check(room.get_children().any(func(c: Node) -> bool: return c is QuestFind and (c as QuestFind).id == id), "%s lies in room %s" % [id, spot[0]])
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y + 1) == ".", "%s is on dry floor with dry floor below" % id)
		_check(game.player.try_interact(), "Wren can pick up %s" % id)
		await _play_scene(game, 10.0)
		_check(GameState.has_flag(QuestFind.flag_for(id)), "and does")
		game.queue_free()
		await _wait(0.1)
		game = await _stand_below(spot[0], tile)
		_check(not game.current_room.get_children().any(func(c: Node) -> bool: return c is QuestFind and (c as QuestFind).id == id), "%s stays picked up" % id)
		game.queue_free()
		await _wait(0.1)
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	# (Pell's night bell long since done: _test_seal_trail.)
	for flag in ["met_hessa", "talked_corrin_quest", "talked_pell_quest", "heard_pell_bell", "heard_pell_hull", "heard_corrin_hull", "pell_night_ask", "found_seal_pup", "pell_pup_told", "corrin_pup_paid"]:
		GameState.set_flag(flag)
	_check(first.call("corrin") == "CORRIN_AGAIN" and first.call("pell") == "PELL_AGAIN", "no errands before the Wayshell")
	GameState.set_flag("seen_wayshell")
	_check(first.call("corrin") == "CORRIN_BOTTLES_1" and first.call("pell") == "PELL_SHELL_1", "then Corrin and Pell ask")
	Conversations.talk("corrin")
	Conversations.talk("pell")
	for id in ["bottle_shore", "bottle_pools"]:
		GameState.set_flag(QuestFind.flag_for(id))
	_check(first.call("corrin") == "CORRIN_BOTTLES_WAITING", "two bottles aren't three")
	GameState.set_flag(QuestFind.flag_for("bottle_strand"))
	var glints := GameState.item_count("glint")
	Conversations.talk("corrin")
	_check(GameState.item_count("glint") == glints + 120 and first.call("corrin") == "CORRIN_BOTTLES_AFTER", "Corrin's grandad comes home")
	Conversations.talk("corrin")
	_check(first.call("corrin") == "CORRIN_AGAIN", "once")
	_check(first.call("pell") == "PELL_SHELL_WAITING", "Pell waits for the shell")
	GameState.set_flag(QuestFind.flag_for("pell_shell"))
	Conversations.talk("pell")
	_check(GameState.has_flag("pell_shell_done") and first.call("pell") == "PELL_AGAIN", "and gets it back")
	GameState.set_flag("tobin_home")
	_check(not Conversations.branch_for("dunstan").get("set", []).has("dunstan_boat_ask"), "Dunstan's first word is about Tobin")
	Conversations.talk("tobin")
	_check(Conversations.branch_for("dunstan").get("set", []).has("dunstan_boat_ask"), "then, once Wren's said hello to Tobin, about driftwood")
	Conversations.talk("dunstan")
	_check(first.call("dunstan") == "DUNSTAN_BOAT_WAITING", "and waits for it")
	GameState.set_flag(QuestFind.flag_for("driftwood"))
	Conversations.talk("dunstan")
	_check(GameState.has_flag("dunstan_boat_done") and first.call("tobin") == "TOBIN_BOAT", "two boats, one for Tobin")
	# Bram's chimes: asked once he's settled in at the forge.
	for flag in ["bram_met", "agna_bram", "met_agna", "agna_gave_sword", "bram_home"]:
		GameState.set_flag(flag)
	_check(first.call("bram") == "BRAM_FORGE", "Bram's first word at the forge is about the coal")
	Conversations.talk("bram")
	_check(first.call("bram") == "BRAM_CHIMES_1", "then he asks for the Choir's chimes")
	Conversations.talk("bram")
	for id in ["chime_pass", "chime_fen"]:
		GameState.set_flag(QuestFind.flag_for(id))
	_check(first.call("bram") == "BRAM_CHIMES_WAITING", "two chimes aren't three")
	GameState.set_flag(QuestFind.flag_for("chime_wood"))
	glints = GameState.item_count("glint")
	Conversations.talk("bram")
	_check(GameState.item_count("glint") == glints + 150 and first.call("bram") == "BRAM_CHIMES_AFTER", "Bram pours Agna a pot")
	_check(first.call("agna") == "AGNA_POT_1", "and Agna has a word about it")
	Conversations.talk("agna")
	Conversations.talk("bram")
	_check(first.call("bram") == "BRAM_FORGE" and first.call("agna") != "AGNA_POT_1", "once each")
	# Marlo's pearls: asked once Wren can dive for them.
	GameState.set_flag("met_marlo")
	_check(first.call("marlo") == "MARLO_AGAIN", "no pearls without the Diver's Helm")
	GameState.give_item("divers_helm", 1, false)
	_check(first.call("marlo") == "MARLO_PEARLS_1", "then Marlo asks for some")
	Conversations.talk("marlo")
	for id in ["pearl_verge", "pearl_tangle"]:
		GameState.set_flag(QuestFind.flag_for(id))
	_check(first.call("marlo") == "MARLO_PEARLS_WAITING", "two pearls aren't three")
	GameState.set_flag(QuestFind.flag_for("pearl_deep"))
	glints = GameState.item_count("glint")
	Conversations.talk("marlo")
	_check(GameState.item_count("glint") == glints + 180 and first.call("marlo") == "MARLO_PEARLS_AFTER", "pearls for Marlo's mum")
	Conversations.talk("marlo")
	_check(first.call("marlo") == "MARLO_AGAIN", "once")
	# Gully's lanterns, once his strongbox is home and Wren has the Wayshell.
	for flag in ["gully_asked", "gully_box_hauled", "gully_paid", "seen_wayshell"]:
		GameState.set_flag(flag)
	_check(first.call("gully") == "GULLY_LANTERNS_1", "Gully asks after the Lantern Wake's lanterns")
	Conversations.talk("gully")
	for id in ["lantern_tidewrack", "lantern_dunes"]:
		GameState.set_flag(QuestFind.flag_for(id))
	_check(first.call("gully") == "GULLY_LANTERNS_WAITING", "two lanterns aren't three")
	GameState.set_flag(QuestFind.flag_for("lantern_cove"))
	glints = GameState.item_count("glint")
	Conversations.talk("gully")
	_check(GameState.item_count("glint") == glints + 150 and first.call("gully") == "GULLY_LANTERNS_AFTER", "the Lantern Wake is lit again")
	Conversations.talk("gully")
	_check(first.call("gully") == "GULLY_AFTER", "once")
	# Lowe's garden, after the singers are home and she's just Lowe.
	for flag in ["lowe_spoke", "lowe_singers_ask", "lowe_singers_done"]:
		GameState.set_flag(flag)
	_check(first.call("lowe") == "LOWE_JUST_LOWE", "Lowe is just Lowe first")
	Conversations.talk("lowe")
	_check(first.call("lowe") == "LOWE_GARDEN_1", "then wants a garden")
	Conversations.talk("lowe")
	for id in ["seed_frost", "seed_ember"]:
		GameState.set_flag(QuestFind.flag_for(id))
	_check(first.call("lowe") == "LOWE_GARDEN_WAITING", "two plants aren't three")
	GameState.set_flag(QuestFind.flag_for("seed_fen"))
	glints = GameState.item_count("glint")
	Conversations.talk("lowe")
	_check(GameState.item_count("glint") == glints + 120 and first.call("lowe") == "LOWE_GARDEN_AFTER", "Lowe plants her garden")
	Conversations.talk("lowe")
	_check(first.call("lowe") == "LOWE_JUST_LOWE", "once")
	# Ide's nameboard: asked on the third talk, and every talk still rows.
	for flag in ["tidebell_belfry", "met_ide_ferry"]:
		GameState.set_flag(flag)
	_check(first.call("ide") == "IDE_FERRY_AGAIN", "Ide just nods Wren aboard at first")
	Conversations.talk("ide")
	_check(first.call("ide") == "IDE_BOARD_1" and Conversations.branch_for("ide")["set"].has("ide_ferry"), "then asks after her nameboard, and still rows")
	Conversations.talk("ide")
	_check(first.call("ide") == "IDE_BOARD_WAITING" and Conversations.branch_for("ide")["set"].has("ide_ferry"), "waiting still rows")
	GameState.set_flag(QuestFind.flag_for("nameboard"))
	glints = GameState.item_count("glint")
	_check(Conversations.branch_for("ide")["set"].has("ide_ferry"), "and so does handing it in")
	Conversations.talk("ide")
	_check(GameState.item_count("glint") == glints + 100 and first.call("ide") == "IDE_FERRY_AGAIN", "Patience gets her name back")
	# Met once before the ending, asked after it.
	GameState.reset_new_game()
	for flag in ["tidebell_belfry", "met_ide_ferry", "seen_ending"]:
		GameState.set_flag(flag)
	Conversations.talk("ide")
	_check(first.call("ide") == "IDE_BOARD_1", "after the ending Ide still asks after her nameboard")
	# Found before anyone asked: the hand-in comes straight away.
	GameState.reset_new_game()
	for flag in ["met_hessa", "talked_corrin_quest", "heard_corrin_hull", "tobin_home", "talked_tobin_home", "found_bottle_shore", "found_bottle_pools", "found_bottle_strand", "found_driftwood", "bram_home", "found_chime_pass", "found_chime_fen", "found_chime_wood", "tidebell_belfry", "met_ide_ferry", "found_nameboard", "met_marlo", "found_pearl_verge", "found_pearl_tangle", "found_pearl_deep", "gully_paid", "found_lantern_tidewrack", "found_lantern_dunes", "found_lantern_cove", "lowe_spoke", "lowe_singers_done", "found_seed_frost", "found_seed_ember", "found_seed_fen"]:
		GameState.set_flag(flag)
	for who in ["corrin", "dunstan", "bram", "ide", "marlo", "gully", "lowe"]:
		Conversations.talk(who)
	_check(GameState.has_flag("corrin_bottles_done") and GameState.has_flag("dunstan_boat_done") and GameState.has_flag("bram_pot_cast") and GameState.has_flag("ide_board_done") and GameState.has_flag("marlo_pearls_done") and GameState.has_flag("gully_lanterns_done") and GameState.has_flag("lowe_garden_done"), "things found early are handed straight in")
	GameState.reset_new_game()


## The last singers, home: Pim at Fenmouth, Sela at the mills, Ansel at
## the Gullwatch post, each with new lines once they're settled.
func _test_singers_at_home() -> void:
	for kind: String in StoryDirector.SINGER_HOMES:
		GameState.reset_new_game()
		var home: Array = StoryDirector.SINGER_HOMES[kind]
		var tile: Vector2i = home[1]
		var game: Node = await _stand_below(home[0], tile)
		_check(_find_kind(game.current_room, kind) == null, "%s isn't home before going home" % kind)
		game.queue_free()
		await _wait(0.1)
		for flag in [StoryDirector.ENDING_FLAG, kind + "_met", kind + "_home"]:
			GameState.set_flag(flag)
		_check(str(Conversations.branch_for(kind)["lines"][0]).ends_with("_BYE"), "%s says goodbye where Wren found them" % kind)
		game = await _stand_below(home[0], tile)
		var room: Room = game.current_room
		_check(_find_kind(room, kind) != null and GameState.has_flag("settled_" + kind), "%s is home in %s" % [kind, home[0]])
		_check(tile.y <= 8 and room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y + 1) == ".", "%s stands on open floor clear of the box" % kind)
		_check(game.player.try_interact(), "Wren can talk to %s" % kind)
		await _play_scene(game, 10.0)
		_check(not DialogueBox.is_open and GameState.has_flag(kind + ("_fen_told" if kind == "pim" else "_mills_told" if kind == "sela" else "_post_told")), "%s has news" % kind)
		_check(str(Conversations.branch_for(kind)["lines"][0]).ends_with("_AGAIN"), "and a line for every visit after")
		game.queue_free()
		await _wait(0.1)
	GameState.reset_new_game()


## The jam trade: Marga's bramble jam goes round the coast, one villager to
## the next, and comes back to her as thank-you letters.
func _test_jam_trade() -> void:
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	var says := func(who: String, key: String) -> bool: return (Conversations.branch_for(who).get("lines", []) as Array).has(key)
	for flag in ["met_hessa", "asked_for_rope", "rope_promised", "marga_thanked", "tidebell_hull", "marga_gave_jar", "wick_asked", "fen_lanterns_lit", "wick_gave_jar", "wick_told_sink", "sorrel_asked", "ferrin_survey_ask", "tidebell_belfry", "met_ide_ferry"]:
		GameState.set_flag(flag)
	_check(first.call("marga") == "MARGA_AFTER", "no trade before the Wayshell")
	GameState.set_flag("seen_wayshell")
	_check(first.call("marga") == "MARGA_TRADE_1", "then Marga sends jam to Wick")
	_check(not says.call("wick", "WICK_TRADE_1") and not says.call("sorrel", "SORREL_TRADE_1"), "nobody trades before the jam")
	Conversations.talk("marga")
	_check(first.call("marga") == "MARGA_TRADE_WAITING", "Marga reminds Wren where it's going")
	_check(says.call("wick", "WICK_TRADE_1"), "Wick takes the jam")
	Conversations.talk("wick")
	_check(first.call("wick") == "WICK_TRADE_WAITING" and first.call("marga") == "MARGA_AFTER", "and sends candles to Sorrel")
	_check(says.call("sorrel", "SORREL_TRADE_1"), "Sorrel takes the candles")
	Conversations.talk("sorrel")
	_check(first.call("sorrel") == "SORREL_TRADE_WAITING", "and sends kite cord to Ferrin")
	_check(says.call("ferrin", "FERRIN_TRADE_1"), "Ferrin takes the cord")
	Conversations.talk("ferrin")
	_check(first.call("ferrin") == "FERRIN_WAITING", "his own survey still comes first while it's open")
	GameState.set_flag("ferrin_map_done")
	_check(first.call("ferrin") == "FERRIN_TRADE_WAITING", "then he reminds Wren the chart's for Ide")
	var glints := GameState.item_count("glint")
	_check(says.call("ide", "IDE_TRADE_1") and Conversations.branch_for("ide")["set"].has("ide_ferry"), "Ide takes the chart, and still rows")
	Conversations.talk("ide")
	_check(GameState.item_count("glint") == glints + 200 and GameState.has_flag("trade_done"), "fares from a good week")
	_check(first.call("ferrin") == "FERRIN_AFTER" and first.call("sorrel") != "SORREL_TRADE_WAITING" and first.call("wick") != "WICK_TRADE_WAITING", "the waiting lines stop")
	_check(first.call("marga") == "MARGA_TRADE_DONE_1", "and the thank-yous reach Marga")
	Conversations.talk("marga")
	_check(first.call("marga") == "MARGA_AFTER", "once")
	GameState.reset_new_game()
	# Mid-trade, the waiting lines never hold up Wick's jar or Sorrel's race.
	for flag in ["wick_asked", "fen_lanterns_lit", "sorrel_asked", "trade_jam", "trade_candles", "trade_line"]:
		GameState.set_flag(flag)
	_check(first.call("wick") == "WICK_DONE_1", "Wick still hands over the jar")
	_check(first.call("sorrel") == "SORREL_TRADE_WAITING", "Sorrel reminds Wren about the cord before the race")
	GameState.give_item("kite_cloak", 1, false)
	_check(first.call("sorrel") == "SORREL_CLOAK_1", "but the race still comes first once Wren can glide")
	GameState.reset_new_game()


## Hessa's lighting day: Nettle's surprise party, five guests, one scene.
func _test_lighting_day() -> void:
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	for flag in ["met_hessa", "nettle_learned", "heard_nettle_bell", "seen_wayshell", "nettle_signals_ask", "nettle_signals_done", "ottilie_asked", "ottilie_reunion", "met_agna", "wick_asked", "sorrel_asked", "asked_for_rope"]:
		GameState.set_flag(flag)
	_check(first.call("nettle") != "NETTLE_PARTY_1", "no party before Hessa's confession")
	GameState.set_flag(StoryDirector.CONFESSION_FLAG)
	_check(first.call("nettle") == "NETTLE_PARTY_1", "then Nettle plans one")
	Conversations.talk("nettle")
	_check(first.call("nettle") == "NETTLE_PARTY_WAITING", "and waits on the guests")
	GameState.clear_flag("nettle_signals_done")
	_check(first.call("nettle") == "NETTLE_SIGNALS_WAITING", "without holding up the signal stones")
	GameState.set_flag("nettle_signals_done")
	GameState.clear_flag("ottilie_reunion")
	_check(first.call("ottilie") != "OTTILIE_PARTY_1", "Ottilie comes only once she and Hessa have made up")
	GameState.set_flag("ottilie_reunion")
	# Marga needs Ottilie's rimefin for the pie.
	_check(first.call("marga") == "MARGA_PARTY_1", "Marga wants a rimefin")
	Conversations.talk("marga")
	# Her rope errand still comes first.
	_check(first.call("marga") == "MARGA_WAITING", "the rope errand comes first")
	GameState.set_flag("rope_promised")
	_check(first.call("marga") == "MARGA_THANKS_1", "and its thanks")
	GameState.set_flag("marga_thanked")
	_check(first.call("marga") == "MARGA_PARTY_WAITING", "then she waits for the fish")
	GameState.set_flag("marga_gave_jar")
	_check(first.call("marga") == "MARGA_PARTY_WAITING", "even after the jar")
	for who in ["ottilie", "agna", "wick", "sorrel"]:
		_check(first.call(who) == who.to_upper() + "_PARTY_1", "%s hears about the party" % who)
		Conversations.talk(who)
		_check(GameState.has_flag("party_" + who) and first.call(who) != who.to_upper() + "_PARTY_1", "%s is coming, once" % who)
	_check(first.call("nettle") == "NETTLE_PARTY_WAITING", "not ready without the pie")
	Conversations.talk("marga")
	_check(GameState.has_flag("party_marga"), "the pie's in the oven")
	_check(first.call("nettle") == "NETTLE_PARTY_READY", "everyone's coming")
	# The party itself, in Saltmarrow.
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(10 * 16 + 8, 5 * 16 + 8))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var glints := GameState.item_count("glint")
	Conversations.talk("nettle")
	await _play_scene(game, 30.0)
	_check(GameState.has_flag(StoryDirector.PARTY_DONE_FLAG) and not Cutscene.active, "the party happens, and ends")
	_check(GameState.item_count("glint") == glints + 300, "the guests pass the hat")
	_check(get_tree().get_nodes_in_group("party_guest").filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).is_empty(), "the guests go home")
	var nettle: Node = game.current_room.get_children().filter(func(c: Node) -> bool: return c is Npc and c.kind == "nettle").front()
	_check(nettle != null and nettle.is_in_group("interactable"), "and Nettle can be talked to again")
	_check(first.call("hessa") == "HESSA_PARTY_AFTER" and first.call("nettle") == "NETTLE_PARTY_AFTER", "both remember it")
	game.queue_free()
	await _wait(0.1)
	GameState.reset_new_game()


## The Ebb Grotto's flood marks, and what they tell Liesl.
func _test_grotto_marks() -> void:
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	var at := StoryDirector.GROTTO_MARKS_AT + Vector2(0, 16)
	GameState.set_checkpoint(StoryDirector.EBB_GROTTO, at)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var room: Room = game.current_room
	var tile := Vector2i(StoryDirector.GROTTO_MARKS_AT / Room.TILE)
	_check(room.tile_at(tile.x, tile.y) == "." and room.tile_at(tile.x, tile.y - 1) == "#" and room.tile_at(tile.x, tile.y + 1) == ".", "the marks are on the wall, over dry floor")
	game.player.global_position = room.global_position + at
	game.player.facing = Vector2.UP
	await _wait(0.05)
	_check(game.player.try_interact(), "Wren can read them")
	await _play_scene(game, 10.0)
	_check(GameState.has_flag("read_grotto_marks"), "and does")
	game.queue_free()
	await _wait(0.1)
	GameState.set_flag("liesl_asked")
	_check(first.call("liesl") == "LIESL_MARKS_1", "Liesl hears of the marks")
	Conversations.talk("liesl")
	_check(first.call("liesl") == "LIESL_WAITING", "once")
	GameState.reset_new_game()


## The Calf's Rest: the little skull in the far fen, and Murmur's robe.
func _test_calf_rest() -> void:
	GameState.reset_new_game()
	for coord: Vector2i in StoryDirector.CALF_REST:
		var tile: Vector2i = StoryDirector.CALF_REST[coord]
		GameState.set_checkpoint(coord, Vector2(tile) * 16.0 + Vector2(8, 30))
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.4)
		var room: Room = game.current_room
		_check(room.get_children().any(func(c: Node) -> bool: return c is CalfSkull), "the calf's skull lies in room %s" % coord)
		var clear := true
		for x in range(tile.x - 1, tile.x + 2):
			for y in [tile.y - 1, tile.y, tile.y + 1]:
				clear = clear and room.tile_at(x, y) == "."
		_check(clear, "on clear floor, with dry ground in front")
		game.player.facing = Vector2.UP
		await _wait(0.05)
		_check(game.player.try_interact(), "and Wren can look at it")
		await _play_scene(game, 10.0)
		game.queue_free()
		await _wait(0.1)
	GameState.reset_new_game()
	var first := func(who: String) -> String: return str(Conversations.branch_for(who).get("lines", [""])[0])
	GameState.set_flag("murmur_met")
	_check(first.call("calf_skull") == "NARRATE_CALF_1", "Wren finds the calf's skull")
	Conversations.talk("calf_skull")
	_check(first.call("calf_skull") == "NARRATE_CALF_AGAIN", "once")
	_check(first.call("murmur") == "MURMUR_REST_EARLY", "Murmur asks Wren to keep it quiet")
	Conversations.talk("murmur")
	_check(first.call("murmur") != "MURMUR_REST_EARLY", "once")
	GameState.set_flag(StoryDirector.ENDING_FLAG)
	_check(first.call("murmur") == "MURMUR_REST_1", "after the ending, Murmur takes the robe out there")
	Conversations.talk("murmur")
	_check(first.call("calf_skull") == "NARRATE_CALF_ROBE" and first.call("murmur") == "MURMUR_END", "and it lies folded on the skull")
	var skull := CalfSkull.new()
	add_child(skull)
	skull._process(0.0)
	_check(skull._robe.visible, "where Wren can see it")
	skull.queue_free()
	GameState.reset_new_game()


## Hessa always has a word on where the next bell is, if Wren asks.
func _test_hessa_hints() -> void:
	GameState.reset_new_game()
	var first := func() -> String: return str(Conversations.branch_for("hessa").get("lines", [""])[0])
	for flag in ["met_hessa", "entered_hull", "heard_hessa_hull", "tidebell_hull", "freed_mantle", "seen_wayshell"]:
		GameState.set_flag(flag)
	_check(first.call() == "HESSA_AFTER_BELL", "after the Wayshell, Hessa points Wren to the Kiln first")
	GameState.set_flag("tidebell_kiln")
	_check(first.call() == "HESSA_ROUND_1", "with the Kiln's bell rung, she sends Wren round the Tidestones")
	Conversations.talk("hessa")
	GameState.clear_flag("tidebell_kiln")
	var expect := [
		["", "HESSA_AFTER_BELL"], ["tidebell_kiln", "HESSA_HINT_MIRE_1"], ["tidebell_mire", "HESSA_HINT_GALE_1"],
		["seen_hessa_confession", "HESSA_AFTER_TURN"], ["tidebell_glacier", "HESSA_HINT_BELFRY_1"],
		["tidebell_belfry", "HESSA_HINT_TOMB_1"], ["tidebell_tomb", "HESSA_ROW_1"], ["hessa_rows", "HESSA_HINT_MAW"],
		["hessa_rowed", "HESSA_HINT_MAW"], ["seen_ending", "HESSA_AFTER_END"],
	]
	for step: Array in expect:
		if step[0] != "":
			GameState.set_flag(step[0])
		_check(first.call() == step[1], "with %s, Hessa says %s (got %s)" % [step[0], step[1], first.call()])
	GameState.reset_new_game()


## No talk branch is hidden for good behind a single earlier one: a branch
## that matches whenever a later one does makes the later one unreachable.
func _test_talk_order() -> void:
	var hidden := 0
	for who: String in Conversations.TALKS:
		var branches: Array = Conversations.TALKS[who]
		for j in branches.size():
			for k in j:
				if _branch_covers(branches[k], branches[j]):
					hidden += 1
					_check(false, "%s's branch %d can never be reached: branch %d always comes first" % [who, j, k])
	_check(hidden == 0, "every talk branch can be reached")


## True when `first` matches in every state where `later` matches.
func _branch_covers(first: Dictionary, later: Dictionary) -> bool:
	if first.has("reaches"):
		return false
	for key in ["if", "unless", "has"]:
		for item in first.get(key, []):
			if not item in later.get(key, []):
				return false
	return true


## Saltmarrow and the locals notice the Old One turn, and the ending.
func _test_late_reactions() -> void:
	GameState.reset_new_game()
	for flag in ["talked_corrin_quest", "talked_pell_quest", "nettle_learned", "agna_gave_sword", "marga_gave_jar", "rope_promised", "wick_gave_jar", "wick_round_ask", "sorrel_paid", "sorrel_letters", "sorrel_letters_paid", "letter_ottilie", "letter_liesl", "letter_agna", "seen_wayshell", "sorrel_dared_stacks", "wick_told_sink", "agna_scales_ask", "agna_bell_cast", "nettle_got_bell", "nettle_signals_ask", "nettle_signals_done", "nettle_nearly_told", "corrin_bottles_ask", "corrin_bottles_done", "corrin_bottles_after", "pell_shell_ask", "pell_shell_done", "trade_jam", "trade_candles", "trade_line", "trade_chart", "trade_done", "marga_heard_trade"]:
		GameState.set_flag(flag)
	# Taught Nettle the signals late, after the Wayshell: the lesson still comes.
	GameState.clear_flag("nettle_learned")
	GameState.set_flag("met_hessa")
	_check(Conversations.branch_for("nettle").get("lines")[0] == "NETTLE_LEARN_1", "Nettle's lamp lessons still happen after the Wayshell")
	GameState.set_flag("nettle_learned")
	GameState.set_flag("heard_nettle_bell")
	# A crab found late still gets its name before the late lines.
	GameState.set_flag("pell_gave_pearl")
	_check(Conversations.branch_for("pell").get("lines") == ["PELL_CRAB_AGAIN"], "Pell names the crab Admiral")
	GameState.set_flag("heard_pell_admiral")
	var who := ["corrin", "pell", "nettle", "agna", "marga", "dunstan", "wick"]
	for speaker in who:
		_check(not str(Conversations.branch_for(speaker).get("lines")[0]).ends_with("_TURNED"), "%s has nothing to say about a turn that hasn't happened" % speaker)
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	for speaker in who:
		_check(Conversations.branch_for(speaker).get("lines")[0] == speaker.to_upper() + "_TURNED", "%s felt the Old One turn" % speaker)
	_check(Conversations.branch_for("sorrel").get("lines")[1] == "SORREL_TURNED", "Sorrel feels the gales ease")
	GameState.set_flag("seen_ending")
	for speaker in ["corrin", "pell", "nettle", "agna", "marga", "dunstan", "wick", "sorrel"]:
		_check(str(Conversations.branch_for(speaker).get("lines")[0]).begins_with(speaker.to_upper() + "_END"), "%s has a word after the ending" % speaker)


func _enemies_away() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()


## Export and Import on the file select: a save goes out as text and comes
## back into an empty file the same; junk, a newer game's save or a filled
## file are turned away.
func _test_save_transfer() -> void:
	const OTHER := 0
	SaveManager.set_aside(OTHER, "testtransfer")
	SaveManager.delete_save(TEST_SLOT)
	GameState.reset_new_game()
	GameState.give_item("tidebell")
	GameState.play_time = 3725.0
	SaveManager.save_game(TEST_SLOT)
	var text := SaveManager.export_text(TEST_SLOT)
	_check(text != "" and SaveManager.export_text(OTHER) == "", "a save exports as text; an empty file doesn't")
	_check(SaveManager.export_file_name(TEST_SLOT).begins_with("leviathan-file3-"), "the exported file is named for its slot")
	_check(SaveManager.import_text(text, TEST_SLOT) == "FILES_IMPORT_NEED_EMPTY", "import never writes over a file")
	_check(SaveManager.import_text("{not json", OTHER) == "FILES_IMPORT_BAD"
		and SaveManager.import_text('{"state": 3}', OTHER) == "FILES_IMPORT_BAD"
		and not SaveManager.has_save(OTHER), "junk isn't imported")
	var newer = JSON.parse_string(text)
	newer["format_version"] = SaveManager.FORMAT_VERSION + 1
	_check(SaveManager.import_text(JSON.stringify(newer), OTHER) == "FILES_NEWER" and not SaveManager.has_save(OTHER),
		"a newer game's save isn't imported")

	# The same through the file select's buttons.
	var files := FileSelect.new()
	files.transfer = SaveTransfer.new()
	files.transfer.test_mode = true
	files.add_child(files.transfer)
	add_child(files)
	files.on_open()
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	var back := InputEventAction.new()
	back.action = "attack"
	back.pressed = true
	var buttons: Array = files._buttons()
	_check(buttons.has("FILES_EXPORT") and buttons.has("FILES_IMPORT"), "the file select offers Export and Import")
	files._cursor = SaveManager.SLOT_COUNT + buttons.find("FILES_EXPORT")
	files.handle_input(press)
	files._cursor = TEST_SLOT
	files.handle_input(press)
	_check(files.transfer.last_export == text and files._note == "FILES_EXPORTED", "Export hands over the chosen file")
	files.transfer.test_import = files.transfer.last_export
	files._cursor = SaveManager.SLOT_COUNT + buttons.find("FILES_IMPORT")
	files.handle_input(press)
	_check(files._cursor == OTHER, "Import starts on an empty file (%d)" % files._cursor)
	files.handle_input(press)
	await get_tree().process_frame
	var summary := SaveManager.read_summary(OTHER)
	_check(files._note == "FILES_IMPORTED" and int(summary.get("bells", 0)) == 1
		and is_equal_approx(float(summary.get("play_time", 0.0)), 3725.0), "Import brings the file back as it was")
	SaveManager.current_slot = OTHER
	_check(SaveManager.load_game(OTHER) and GameState.item_count("tidebell") == 1, "an imported file loads")
	SaveManager.current_slot = TEST_SLOT
	# Into a filled file, and a cancelled pick.
	files._cursor = SaveManager.SLOT_COUNT + buttons.find("FILES_IMPORT")
	files.handle_input(press)
	files._cursor = OTHER
	files.handle_input(press)
	_check(files._note == "FILES_IMPORT_NEED_EMPTY" and files._mode == FileSelect.Mode.IMPORT, "Import asks for an empty file")
	SaveManager.delete_save(OTHER)
	files.transfer.test_import = ""
	files._refresh()
	files.handle_input(press)
	await get_tree().process_frame
	_check(files._mode == FileSelect.Mode.PLAY and files._note == "" and not SaveManager.has_save(OTHER),
		"a cancelled pick changes nothing")
	files.handle_input(back)
	files.queue_free()
	await get_tree().process_frame
	SaveManager.delete_save(TEST_SLOT)
	SaveManager.restore_aside(OTHER, "testtransfer")


## The hidden playtime record: time and deaths by region and dungeon, kept
## through saving, loading and dying.
func _test_area_stats() -> void:
	GameState.reset_new_game()
	_check(GameState.area_stats.is_empty(), "a new file has no playtime record")
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(1.0)
	var area := Audio.cue_for_room(game.current_room.biome, game.current_room.dungeon)
	var counted := float(GameState.area_stats.get(area, {}).get("time", 0.0))
	# Everything played so far was in this one area.
	_check(counted > 0.0 and absf(counted - GameState.play_time) < 0.01,
		"time in %s is counted (%.2f of %.2f s)" % [area, counted, GameState.play_time])
	GameState.count_area_death(area)
	GameState.count_area_time("dungeon_hull", 60.0)
	SaveManager.save_game()
	var before := GameState.area_stats.duplicate(true)
	GameState.reset_new_game()
	SaveManager.load_game()
	_check(int(GameState.area_stats.get(area, {}).get("deaths", 0)) == 1
		and is_equal_approx(float(GameState.area_stats.get("dungeon_hull", {}).get("time", 0.0)), 60.0)
		and GameState.area_stats.size() == before.size(), "the playtime record survives saving (%s)" % GameState.area_stats)
	# Reading a conversation pauses the game but counts as playing.
	var reading_from := float(GameState.area_stats[area]["time"])
	Events.dialogue_requested.emit("NAME_HESSA", PackedStringArray(["HESSA_1"]))
	await _wait(0.5)
	_check(get_tree().paused and float(GameState.area_stats[area]["time"]) > reading_from + 0.3,
		"time reading a conversation counts (%.2f to %.2f s)" % [reading_from, float(GameState.area_stats[area]["time"])])
	for box in game.get_children():
		if box is DialogueBox:
			box.close()
	get_tree().paused = false
	# Leaving without saving keeps the time and deaths, not the rest.
	GameState.count_area_death(area)
	GameState.play_time += 100.0
	GameState.give_item("glint", 50, false)
	_check(SaveManager.save_clock(), "leaving keeps the time played")
	GameState.reset_new_game()
	SaveManager.load_game()
	_check(int(GameState.area_stats.get(area, {}).get("deaths", 0)) == 2 and GameState.play_time > 100.0
		and GameState.item_count("glint") == 0, "only the time and deaths are kept (%s)" % GameState.area_stats)
	game.queue_free()
	await _wait(0.1)
	SaveManager.delete_save()


## Exploration secrets in the older regions: each needs a tool found later,
## so the early screens pay out on the way back.
func _test_older_secrets() -> void:
	GameState.reset_new_game()
	# Tidepools: a rock pool whose floor is sea bed, with a chest in it.
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	var pools: Room = (load("res://rooms/room_1_0.tscn") as PackedScene).instantiate()
	add_child(pools)
	await _wait(0.1)
	var tide := pools.get_node_or_null("Tide") as Tide
	var bed := Vector2i(7, 10)
	_check(pools.chest_item == "glint" and pools.tile_at(6, 10) == "C" and tide != null and tide.is_flooded(bed),
		"Tidepools: the rock pool's chest is under water even at low tide")
	_check(tide != null and tide._shapes.size() == tide._seabed.size(), "the rock pool is all sea bed, so the breathing tide never sounds its rush there")
	GameState.set_flag(Tide.TURNED_FLAG)
	GameState.set_flag(Tide.HELD_FLAG)
	await _wait(0.1)
	_check(tide != null and not tide.is_flooded(bed) and not tide.is_flooded(Vector2i(9, 10)), "held out, the tide bares the pool floor up to the chest")
	pools.queue_free()
	GameState.reset_new_game()
	Tide.offset = 0.0
	# Barnacle Wall: a cove in the north-east corner behind a cracked boulder.
	var wall: Room = (load("res://rooms/room_2_0.tscn") as PackedScene).instantiate()
	var rows := Room.parse_layout(wall.layout)
	_check(wall.chest_item == "glint" and rows[2][21] == "C" and rows[3][18] == "Y", "Barnacle Wall: a chest in a cove behind a cracked boulder")
	var sealed := rows.duplicate()
	sealed[3] = sealed[3].replace("Y", "#")
	_check(not _walkable_from(sealed, Vector2i(5, 6)).has(Vector2i(21, 3)), "the boulder seals the cove")
	var broken := rows.duplicate()
	broken[3] = broken[3].replace("Y", ".")
	_check(_walkable_from(broken, Vector2i(5, 6)).has(Vector2i(21, 3)), "broken, it lets Wren in")
	wall.free()
	# Mothlight Glade: a barred hollow that opens once both braziers burn,
	# one of them on a pond islet that no bank comes near.
	var glade: Room = (load("res://rooms/room_4_-2.tscn") as PackedScene).instantiate()
	add_child(glade)
	await _wait(0.1)
	var braziers := _child_of(glade, Brazier)
	var bars := _child_of(glade, Bars)
	_check(glade.gate == "braziers" and braziers.size() == 2 and bars.size() == 1 and not bars[0].is_open and glade.tile_at(19, 2) == "C",
		"Mothlight Glade: two braziers and a barred hollow")
	var islet: Brazier = braziers[0] if (braziers[0] as Brazier).position.x > (braziers[1] as Brazier).position.x else braziers[1]
	var nearest := INF
	for y in Room.ROWS:
		for x in Room.COLS:
			if glade.tile_at(x, y) == "." and Vector2i(x, y) != Vector2i(10, 6):
				nearest = minf(nearest, _tile_pos(glade, Vector2i(x, y)).distance_to(islet.global_position))
	_check(nearest > Brazier.REACH + 8.0, "no bank comes within the islet brazier's reach (nearest %.0f px)" % nearest)
	islet.light(true)
	await _wait(0.1)
	_check(not bars[0].is_open, "one brazier isn't enough")
	for b: Brazier in braziers:
		b.light(true)
	await _wait(0.1)
	_check(bars[0].is_open, "both burning, the hollow opens")
	glade.queue_free()
	# Tangle Shore: an islet out in deep water, hooked to and back.
	var tangle: Room = (load("res://rooms/room_6_0.tscn") as PackedScene).instantiate()
	var sea := Room.parse_layout(tangle.layout)
	_check(tangle.chest_item == "glint" and sea[10][12] == "C" and sea[10][14] == "O" and sea[5][14] == "O"
		and sea[8][14] == "Q" and sea[8][13] == "Q", "Tangle Shore: a chest on a deep-water islet, with hook posts out and back")
	tangle.free()
	# Fenmouth: a crate wedged in a slot only the Tide Hook drags it out
	# of; on the plate it unbars a shrine.
	GameState.reset_new_game()  # The glade's solved gate is saved under this test room's coord too.
	var fen: Room = (load("res://rooms/room_4_1.tscn") as PackedScene).instantiate()
	add_child(fen)
	await _wait(0.1)
	var fen_rows := Room.parse_layout(fen.layout)
	var fen_bars := _child_of(fen, Bars)
	var fen_crates := _child_of(fen, Crate)
	var fen_plates := _child_of(fen, PressurePlate)
	_check(fen.gate == "plates" and fen_bars.size() == 1 and not fen_bars[0].is_open and fen_crates.size() == 1 and fen_plates.size() == 1 and fen_rows[2][20] == "C",
		"Fenmouth: a crate, a plate and a barred shrine")
	var slot := _walkable_from(fen_rows, Vector2i(12, 6))
	_check(slot.has(Vector2i(4, 10)) and fen_rows[10][2] == "#", "Wren reaches the crate's slot only from the open side")
	_check(fen_rows[9].substr(0, 6) == "######" and fen_rows[11].substr(0, 6) == "######" and fen_rows[10][3] == "K", "the slot is one tile wide, walled above and below")
	(fen_crates[0] as Crate).global_position = (fen_plates[0] as Node2D).global_position
	await _wait(0.2)
	_check(fen_bars[0].is_open, "the crate on the plate unbars the shrine")
	fen.queue_free()
	# Witheroot Hollow: a hidden wall, drawn as rock, in the north crag.
	var root: Room = (load("res://rooms/room_3_2.tscn") as PackedScene).instantiate()
	add_child(root)
	await _wait(0.1)
	var hidden := _child_of(root, BoneWall)
	_check(hidden.size() == 1 and (hidden[0] as BoneWall).concealed and (hidden[0] as BoneWall).tile == Vector2i(12, 2) and (hidden[0] as BoneWall)._into_room() == Vector2.DOWN
		and Room.parse_layout(root.layout)[1][11] == "C", "Witheroot Hollow: a concealed wall in the crag, its draft blowing out to the hollow, a chest behind")
	root.queue_free()
	# Ashfall Gate: a barred niche in the east crag that opens once a
	# brazier burns on each bank of the lava river.
	GameState.reset_new_game()  # Fenmouth's solved gate is saved under this test room's coord too.
	var ash: Room = (load("res://rooms/room_7_-2.tscn") as PackedScene).instantiate()
	add_child(ash)
	await _wait(0.1)
	var ash_rows := Room.parse_layout(ash.layout)
	var ash_fires := _child_of(ash, Brazier)
	var ash_bars := _child_of(ash, Bars)
	_check(ash.gate == "braziers" and ash_fires.size() == 2 and ash_bars.size() == 1 and not ash_bars[0].is_open and ash_rows[2][20] == "C",
		"Ashfall Gate: two braziers and a barred niche")
	var banks := 0
	for b: Brazier in ash_fires:
		var bx := int(b.position.x) / Room.TILE
		banks += 1 if bx < 10 else (2 if bx > 12 else 0)
	_check(banks == 3, "one brazier on each bank of the lava river")
	var shut := ash_rows.duplicate()
	shut[2] = shut[2].replace("|", "#")
	_check(not _walkable_from(shut, Vector2i(16, 6)).has(Vector2i(19, 2)), "the bars are the niche's only way in")
	for b: Brazier in ash_fires:
		b.light(true)
	await _wait(0.1)
	_check(ash_bars[0].is_open, "both burning, the niche opens")
	ash.queue_free()
	GameState.reset_new_game()
	# Kiln Mouth: a hidden wall west of the Kiln's door, a chamber behind.
	var kiln: Room = (load("res://rooms/room_10_-2.tscn") as PackedScene).instantiate()
	add_child(kiln)
	await _wait(0.1)
	var kiln_wall := _child_of(kiln, BoneWall)
	_check(kiln_wall.size() == 1 and (kiln_wall[0] as BoneWall).concealed and (kiln_wall[0] as BoneWall).tile == Vector2i(4, 4) and (kiln_wall[0] as BoneWall)._into_room() == Vector2.DOWN
		and Room.parse_layout(kiln.layout)[2][5] == "C", "Kiln Mouth: a concealed wall beside the Kiln's door, a chamber and chest behind")
	kiln.queue_free()
	# Whalefall Steps: a ledge over a pool, its chest in the crag; a hook post
	# beyond it pulls Wren across (or the pool freezes, or a glide clears it).
	var fall: Room = (load("res://rooms/room_10_0.tscn") as PackedScene).instantiate()
	var fall_rows := Room.parse_layout(fall.layout)
	_check(fall.chest_item == "glint" and fall_rows[1][17] == "C" and fall_rows[2][18] == "O" and fall_rows[2][17] == "."
		and fall_rows[2].substr(15, 2) == "~~" and fall_rows[3][17] == "~", "Whalefall Steps: a ledge over a pool, a hook post beyond it, a chest above")
	var dry_fall := _walkable_from(fall_rows, Vector2i(10, 8))
	_check(dry_fall.has(Vector2i(14, 2)) and not dry_fall.has(Vector2i(17, 2)), "the hook spot is on dry ground, the ledge isn't")
	_check(fall_rows[3][18] == "#", "rock under the post, so a pull from below can't drop Wren in the pool")
	fall.free()
	# Rib Hollow: a bone barricade walls a niche in the south-east crag.
	var ribs: Room = (load("res://rooms/room_8_0.tscn") as PackedScene).instantiate()
	var rib_rows := Room.parse_layout(ribs.layout)
	_check(ribs.chest_item == "glint" and rib_rows[10][20] == "%" and rib_rows[10][21] == "." and rib_rows[10][22] == "C" and rib_rows[9].substr(21, 2) == "##" and rib_rows[11].substr(21, 2) == "##",
		"Rib Hollow: a chest in a niche behind a bone barricade")
	ribs.free()
	# The Brine Cistern, Sluice Gallery and Smugglers' Vault: a cave run west
	# of Smugglers' Cut. Two crates on two plates unbar the way on, boulders
	# seal the gallery's far end, and the vault shuts Wren in with its crew.
	GameState.reset_new_game()
	var cut := Room.parse_layout(((load("res://rooms/room_0_1.tscn") as PackedScene).instantiate() as Room).layout)
	_check(cut[8][0] == "." and cut[9][0] == ".", "Smugglers' Cut opens west to the Brine Cistern")
	var cistern: Room = (load("res://rooms/room_-1_1.tscn") as PackedScene).instantiate()
	add_child(cistern)
	await _wait(0.1)
	var c_rows := Room.parse_layout(cistern.layout)
	var c_bars := _child_of(cistern, Bars)
	var c_crates := _child_of(cistern, Crate)
	var c_plates := _child_of(cistern, PressurePlate)
	_check(cistern.cave and cistern.gate == "plates" and c_bars.size() == 2 and c_crates.size() == 2 and c_plates.size() == 2
		and c_rows[8][23] == "." and c_rows[9][23] == "." and c_rows[5][0] == "." and c_rows[6][0] == ".",
		"the Brine Cistern: two crates, two plates, barred to the west")
	# One crate sits at the dead end of a ledge, walled on three sides: only
	# the Tide Hook drags it out. No hook posts, so nothing can strand Wren.
	var dry := _walkable_from(c_rows, Vector2i(18, 8))
	_check(dry.has(Vector2i(5, 5)) and dry.has(Vector2i(19, 3)) and c_rows[3][20] == "K" and c_rows[2][20] == "#" and c_rows[4][20] == "#" and c_rows[3][21] == "#"
		and not "O" in "".join(c_rows), "the Cistern is one floor; its ledge crate is walled in on three sides")
	(c_crates[0] as Crate).global_position = (c_plates[0] as Node2D).global_position
	await _wait(0.2)
	_check(not (c_bars[0] as Bars).is_open, "one crate isn't enough")
	(c_crates[1] as Crate).global_position = (c_plates[1] as Node2D).global_position
	await _wait(0.2)
	_check((c_bars[0] as Bars).is_open and (c_bars[1] as Bars).is_open, "both plates down, the bars open")
	cistern.queue_free()
	GameState.reset_new_game()
	var sluice := Room.parse_layout(((load("res://rooms/room_-2_1.tscn") as PackedScene).instantiate() as Room).layout)
	var unbroken := sluice.duplicate()
	unbroken[2] = unbroken[2].replace("Y", "#")
	_check(sluice[5][23] == "." and sluice[6][23] == "." and sluice[2].substr(5, 2) == "YY" and sluice[1].substr(5, 2) == ".." and not _walkable_from(unbroken, Vector2i(18, 5)).has(Vector2i(5, 0)),
		"the Sluice Gallery: boulders seal the way north")
	var vault: Room = (load("res://rooms/room_-2_0.tscn") as PackedScene).instantiate()
	add_child(vault)
	await _wait(0.1)
	var v_rows := Room.parse_layout(vault.layout)
	var v_chests := _child_of(vault, Chest)
	_check(vault.gate == "clear" and vault.chest_hidden and _child_of(vault, Bars).size() == 2 and v_chests.size() == 1 and not (v_chests[0] as Chest).visible
		and v_rows[12][5] == "." and v_rows[12][6] == "." and v_rows[11].substr(5, 2) == "||", "the Smugglers' Vault: a hidden cache, bars that shut behind Wren")
	var crew := 0
	for child in vault.get_children():
		if child is Enemy:
			crew += 1
	_check(crew >= 5, "the vault keeps a crew (%d)" % crew)
	vault.queue_free()
	GameState.reset_new_game()
	# Three shoals out in deep water, walled by rocks so that no glide, even
	# a steered one, can curve in: the Diver's Helm alone reaches them (the
	# story thread leaves pearls on them).
	for shoal: Array in [[Vector2i(6, 0), Vector2i(20, 8)], [Vector2i(1, 5), Vector2i(20, 5)], [Vector2i(6, -5), Vector2i(10, 8)]]:
		var probe: Room = (load("res://rooms/room_%d_%d.tscn" % [shoal[0].x, shoal[0].y]) as PackedScene).instantiate()
		var swim_rows := Room.parse_layout(probe.layout)
		var at: Vector2i = shoal[1]
		var ways := 0
		for side: Vector2i in [at + Vector2i.LEFT, at + Vector2i.RIGHT, at + Vector2i(-1, 1), at + Vector2i(1, 1), at + Vector2i(0, 2)]:
			if swim_rows[side.y][side.x] == "Q":
				ways += 1
		_check(swim_rows[at.y][at.x] == "." and swim_rows[at.y + 1][at.x] == "." and swim_rows[at.y - 1][at.x] == "#" and ways >= 1,
			"room %s has a rock-sheltered shoal at %s, open to deep water" % [shoal[0], at])
		probe.free()
	# The Kelp Stair, Drowned Chapel and Wreck Vault: a cave run under the
	# Verge, south of Wreckers' Stair. Deep water only the Diver's Helm
	# crosses, two eyes for the bow, and a vault that shuts Wren in.
	GameState.reset_new_game()
	var wreckers := Room.parse_layout(((load("res://rooms/room_2_4.tscn") as PackedScene).instantiate() as Room).layout)
	_check(wreckers[12].substr(14, 2) == "..", "Wreckers' Stair opens south to the Kelp Stair")
	var stair: Room = (load("res://rooms/room_2_5.tscn") as PackedScene).instantiate()
	var s_rows := Room.parse_layout(stair.layout)
	var band := true
	for y in range(5, 10):
		for x in range(5, 22):
			band = band and s_rows[y][x] == "Q"
	var north_side := _walkable_from(s_rows, Vector2i(14, 1))
	_check(stair.cave and stair.biome == "sunken_verge" and band and s_rows[0].substr(14, 2) == ".." and s_rows[10][23] == "." and s_rows[11][23] == "."
		and not north_side.has(Vector2i(10, 10)), "the Kelp Stair: five rows of deep water between the stair and the way on")
	stair.free()
	var chapel: Room = (load("res://rooms/room_3_5.tscn") as PackedScene).instantiate()
	add_child(chapel)
	await _wait(0.2)
	var ch_rows := Room.parse_layout(chapel.layout)
	var ch_eyes: Array = _child_of(chapel, IceEye)
	var ch_bars := _child_of(chapel, Bars)
	_check(chapel.cave and chapel.biome == "sunken_verge" and chapel.gate == "eyes" and ch_eyes.size() == 2 and ch_bars.size() == 2 and not (ch_bars[0] as Bars).is_open
		and ch_rows[10][0] == "." and ch_rows[11][0] == "." and ch_rows[12].substr(9, 2) == "..", "the Drowned Chapel: two eyes bar the way down")
	(ch_eyes[0] as IceEye).arrow_hit(Vector2.UP)
	await _wait(0.3)
	_check(not (ch_bars[0] as Bars).is_open, "one eye isn't enough")
	(ch_eyes[1] as IceEye).arrow_hit(Vector2.UP)
	await _wait(0.4)
	_check((ch_bars[0] as Bars).is_open and (ch_bars[1] as Bars).is_open, "both eyes open, the bars lift")
	chapel.queue_free()
	GameState.reset_new_game()
	var wreck: Room = (load("res://rooms/room_3_6.tscn") as PackedScene).instantiate()
	add_child(wreck)
	await _wait(0.1)
	var w_rows := Room.parse_layout(wreck.layout)
	var w_chests := _child_of(wreck, Chest)
	var w_crew := 0
	for child in wreck.get_children():
		if child is Enemy:
			w_crew += 1
	_check(wreck.cave and wreck.biome == "sunken_verge" and wreck.gate == "clear" and wreck.chest_hidden and _child_of(wreck, Bars).size() == 2 and w_chests.size() == 1 and not (w_chests[0] as Chest).visible
		and w_rows[0].substr(9, 2) == ".." and w_rows[1].substr(9, 2) == "||" and w_crew >= 5, "the Wreck Vault: a hidden cache, a crew of %d, bars that shut behind Wren" % w_crew)
	wreck.queue_free()
	GameState.reset_new_game()



## One short trial cave per region: a single puzzle and a glint cache.
func _test_puzzle_caves() -> void:
	# Dragline Cellar, west of the Shore: cracked boulders, then a crate stuck
	# at the end of a one-wide alcove. Only the hook drags it out.
	var shore := Room.parse_layout(((load("res://rooms/room_0_0.tscn") as PackedScene).instantiate() as Room).layout)
	_check(shore[6][0] == "." and shore[7][0] == ".", "the Shore opens west to Dragline Cellar")
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	GameState.set_checkpoint(Vector2i(-1, 0), Vector2(4 * Room.TILE + 8, 6 * Room.TILE + 12))
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	var player: Player = game.player
	player._invuln = 60.0
	var hole: Room = game.current_room
	var crates := _child_of(hole, Crate)
	var plates := _child_of(hole, PressurePlate)
	var bars := _child_of(hole, Bars)
	_check(hole.cave and hole.gate == "plates" and crates.size() == 2 and plates.size() == 2 and bars.size() == 1 and not bars[0].is_open, "Dragline Cellar: two crates, two plates and a barred cache")
	_check(hole.tile_at(20, 6) == "Y" and hole.tile_at(20, 7) == "Y", "cracked boulders hold the way in")
	var stuck: Crate = crates[0] if (crates[0] as Crate).position.y > (crates[1] as Crate).position.y else crates[1]
	player.global_position = _tile_pos(hole, Vector2i(18, 6))
	player.facing = Vector2.DOWN
	await _wait(0.1)
	player.use_item("tide_hook")
	await _wait(2.0)
	var crate_tile := Vector2i(int(stuck.position.x) / Room.TILE, int(stuck.position.y) / Room.TILE)
	_check(crate_tile.y <= 8 and crate_tile.x == 18, "the hook drags the stuck crate out of its alcove (now at %s)" % crate_tile)
	for i in 2:
		(crates[i] as Crate).position = (plates[i] as Node2D).position
	await _wait(0.4)
	_check(bars[0].is_open, "both crates on their plates open the cache")
	game.queue_free()
	await _wait(0.1)
	# Rimelight Hollow, west of Glacier Foot: three ice eyes round a slick
	# floor, the last under a pool that has to be frozen first.
	var foot := Room.parse_layout(((load("res://rooms/room_0_-3.tscn") as PackedScene).instantiate() as Room).layout)
	_check(foot[6][0] == "." and foot[7][0] == ".", "Glacier Foot opens west to Rimelight Hollow")
	GameState.reset_new_game()
	GameState.give_item("frostfang_bow", 1, false)
	GameState.set_checkpoint(Vector2i(-1, -3), Vector2(21 * Room.TILE + 8, 6 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var hollow: Room = game.current_room
	for foe in _child_of(hollow, Enemy):
		foe.free()
	var eyes := _child_of(hollow, IceEye)
	bars = _child_of(hollow, Bars)
	_check(hollow.cave and hollow.gate == "eyes" and eyes.size() == 3 and bars.size() == 1 and _child_of(hollow, IceField).size() == 1, "Rimelight Hollow: three ice eyes round a slick floor")
	player.global_position = _tile_pos(hollow, Vector2i(6, 9))
	player.facing = Vector2.DOWN
	for i in 2:
		await _wait(0.6)
		player.use_item("frostfang_bow")
	await _wait(1.0)
	_check(hollow.is_frozen(Vector2i(6, 10)) and eyes.any(func(e: IceEye) -> bool: return e.lit), "an arrow freezes the pool, the next opens the eye under it")
	for eye in eyes:
		eye.arrow_hit(Vector2.UP)
	await _wait(0.4)
	_check(bars[0].is_open, "all three eyes open the cache")
	game.queue_free()
	await _wait(0.1)
	# Emberwell Vault, east of Scorched Pass: two braziers on lava islets.
	# The hook crosses to the first; a cracked boulder sits in the line to
	# the second until the Stonebreaker clears it.
	var pass_rows := Room.parse_layout(((load("res://rooms/room_9_-1.tscn") as PackedScene).instantiate() as Room).layout)
	_check(pass_rows[5][23] == "." and pass_rows[6][23] == ".", "Scorched Pass opens east to Emberwell Vault")
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	GameState.set_checkpoint(Vector2i(10, -1), Vector2(2 * Room.TILE + 8, 5 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var vault: Room = game.current_room
	var braziers := _child_of(vault, Brazier)
	bars = _child_of(vault, Bars)
	_check(vault.cave and vault.gate == "braziers" and braziers.size() == 2 and bars.size() == 1 and not bars[0].is_open and vault.tile_at(13, 4) == "Y", "Emberwell Vault: two braziers over lava, and a boulder in the way")
	for throw: Array in [[Vector2i(5, 5), Vector2.RIGHT, Vector2i(10, 5)], [Vector2i(12, 4), Vector2.RIGHT, Vector2i(12, 4)]]:
		player.global_position = _tile_pos(vault, throw[0])
		player.facing = throw[1]
		await _wait(0.1)
		player.use_item("tide_hook")
		await _wait(1.5)
		var at := player.global_position - vault.global_position
		var want: Vector2i = throw[2]
		_check(int(at.x) / Room.TILE == want.x and int(at.y - 3) / Room.TILE == want.y and game.current_room == vault,
			"Emberwell: hooking from %s ends at %s (at %s)" % [throw[0], want, at])
	for brazier in braziers:
		brazier.light(true)
	await _wait(0.4)
	_check(bars[0].is_open, "both braziers lit open the vault's cache")
	game.queue_free()
	await _wait(0.1)
	# Drybone Crypt, east of Whalefall Steps: a closed hall whose way on is a
	# bone wall that looks like any other (bar a crack and a breath of dust)
	# until the Echo Horn finds it.
	var steps_rows := Room.parse_layout(((load("res://rooms/room_10_0.tscn") as PackedScene).instantiate() as Room).layout)
	_check(steps_rows[6][23] == "." and steps_rows[7][23] == ".", "Whalefall Steps opens east to Drybone Crypt")
	GameState.reset_new_game()
	GameState.give_item("echo_horn", 1, false)
	GameState.set_checkpoint(Vector2i(11, 0), Vector2(3 * Room.TILE + 8, 6 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var crypt: Room = game.current_room
	for foe in _child_of(crypt, Enemy):
		foe.free()
	_check(crypt.cave and _child_of(crypt, BoneWall).size() == 1 and crypt.tile_at(7, 4) == "#" and _child_of(crypt, SinkField).size() == 1, "Drybone Crypt: a closed hall with one hidden bone wall")
	player.global_position = _tile_pos(crypt, Vector2i(7, 6))
	player.facing = Vector2.UP
	await _wait(0.3)
	player.use_item("echo_horn")
	await _wait(0.8)
	_check(crypt.tile_at(7, 4) == "." and _child_of(crypt, BoneWall).is_empty(), "the horn opens the hidden way north")
	game.queue_free()
	await _wait(0.1)
	# Gustway Ledges, west of Edgewatch Bluff: a one-wide ledge over the sky
	# that gusts sweep from the north, with nooks to shelter in, then a gap
	# to the cache that the hook (or the cloak) crosses both ways.
	var bluff := Room.parse_layout(((load("res://rooms/room_4_-5.tscn") as PackedScene).instantiate() as Room).layout)
	_check(bluff[7][0] == "." and bluff[8][0] == ".", "Edgewatch Bluff opens west to Gustway Ledges")
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	GameState.set_checkpoint(Vector2i(3, -5), Vector2(20 * Room.TILE + 8, 8 * Room.TILE + 12))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.4)
	player = game.player
	player._invuln = 60.0
	var ledges: Room = game.current_room
	var ledge_rows := Room.parse_layout(ledges.layout)
	_check(ledges.wind.y > 0.0 and ledges.has_node("Gust") and ledge_rows[8].substr(4, 12) == "____________" and ledge_rows[6].substr(10, 2) == ".." and ledge_rows[6].substr(14, 2) == "..", "Gustway Ledges: a ledge over the sky, gusts from the north, wider steps to wait them out on")
	# A gust shoves Wren south, but not while they still blink from a fall.
	var gust: Gust = ledges.get_node("Gust")
	gust.phase = Gust.Phase.BLOWING
	gust._timer = 5.0
	player.global_position = _tile_pos(ledges, Vector2i(18, 8))
	var held := player.global_position.y
	player._invuln = 1.0
	await _wait(0.3)
	var still := player.global_position.y
	player._invuln = 0.0
	await _wait(0.3)
	_check(is_equal_approx(still, held) and player.global_position.y > still + 5.0, "the gust spares Wren while they blink, then shoves them south (%s, %s, %s)" % [held, still, player.global_position.y])
	# Still the gusts for the throws: the landings sit right by the drop.
	ledges.get_node("Gust").free()
	var ledge_breath := GameState.bubbles
	for throw: Array in [[Vector2i(7, 7), Vector2.LEFT, Vector2i(2, 7)], [Vector2i(3, 6), Vector2.RIGHT, Vector2i(7, 6)]]:
		player.global_position = _tile_pos(ledges, throw[0])
		player.facing = throw[1]
		await _wait(0.1)
		player.use_item("tide_hook")
		await _wait(1.5)
		var at := player.global_position - ledges.global_position
		var want: Vector2i = throw[2]
		_check(int(at.x) / Room.TILE == want.x and int(at.y - 3) / Room.TILE == want.y and game.current_room == ledges and GameState.bubbles == ledge_breath,
			"Gustway: the hook carries Wren from %s to %s (at %s)" % [throw[0], want, at])
	game.queue_free()
	await _wait(0.1)
