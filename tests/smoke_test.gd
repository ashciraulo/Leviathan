extends Node
## Headless smoke test. CI runs it with:
##     godot --headless res://tests/smoke_test.tscn
## Prints "SMOKE TEST PASSED" and exits 0, or lists each failure and exits 1.
## Uses save slot 2 so it never touches a real save.

const TEST_SLOT := 2

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
		await _test_ambience()
		await _test_fast_travel()
		await _test_credits()
		await _test_equipment()
		await _test_side_quests()
		await _test_shop()
		_test_satchel_sea_glass()
		await _test_save_transfer()
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
		await _test_coralie()
		await _test_lowe_after()
		await _test_murmur_and_dace()
		_test_talk_order()
		_test_errands()
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
	_check(Audio.music_cue == "dungeon_hull", "no boss theme while she sleeps through Lowe's scene (%s)" % Audio.music_cue)
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
	bog.queue_free()
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

	# Hum heals one bubble for a third of the meter.
	GameState.bubbles = 2
	GameState.resonance = GameState.resonance_max
	Input.action_press("hum")
	await _wait(1.1)
	Input.action_release("hum")
	_check(GameState.bubbles == 3, "humming restores a bubble (bubbles %d)" % GameState.bubbles)
	_check(is_equal_approx(GameState.resonance, GameState.resonance_max * 2.0 / 3.0), "humming spends a third of the meter")

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

	# The Eye Gallery: every eye open at once opens the gate.
	room = await _goto(game, Vector2i(32, 8), Vector2i(11, 11))
	await _calm(room)
	var eyes := _child_of(room, IceEye)
	_check(eyes.size() == 3, "the Eye Gallery has three ice eyes")
	var chest: Chest = _child_of(room, Chest)[0]
	_check(not chest.visible, "its chest is hidden")
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
	_check(chest.visible and GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "with every eye open the chest appears")

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
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "the plate opens the bars to the big key")

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
	for b: Brazier in braziers:
		b.light()
	await _wait(0.2)
	_check(chest.visible, "with every brazier lit, the chest appears")

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
		await _wait(1.5)
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
	_check(not world_page._fringe.has(Vector2i(-1, 0)), "no fog where there's no room")
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
	_check(Audio.music_cue != "boss", "the sleeping Heart's chamber is no fight (%s)" % Audio.music_cue)
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
	# the post, and carries Wren over the water to the big key's island.
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
		await _wait(2.6)
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
		await _wait(3.4)
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
	Audio.play_music("region_saltmarrow")
	_check(Audio.music_cue == "region_saltmarrow", "music cues switch")
	var playing: AudioStreamPlayer = Audio._music[Audio._music_index]
	var track := playing.stream as AudioStreamOggVorbis
	_check(track != null and track.loop, "region music loops")
	_check(not (Audio._load(Audio.MUSIC_DIR, "region_saltmarrow") as AudioStreamOggVorbis).loop, "looping doesn't change the shared track")
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
	_check(is_equal_approx(phrase.get_list_stream(0).get_length(), 9 * 60.0 / 80.0), "a phrase is three bars long, so phrases run on in time")
	Audio.play_lullaby(3)
	phrase = Audio._phrase.stream as AudioStreamPlaylist
	_check(phrase.stream_count == 3 and not phrase.loop, "the lullaby plays the phrases learned so far, once")
	Audio._phrase.stop()
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
	_check(rise.door_to == Vector2i(40, 10) and Room.parse_layout(rise.layout)[6][12] == "D", "the beast skull's throat leads into the Marrow Tomb")
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
		if coord in [Vector2i(1, -1), Vector2i(7, -1), Vector2i(3, 3)]:
			_check(room.chest_count >= 100 and tr(room.name_key) != room.name_key, "side area %s has a name and a cache of %d glints" % [coord, room.chest_count])
			_check(room.cave, "side area %s is shaded like a hollow" % coord)
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
	page.queue_free()
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
	GameState.set_checkpoint(StoryDirector.SKULL_RISE, Vector2(12 * Room.TILE + 8, 7 * Room.TILE + 10))
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
	_check(Audio.music_cue != "boss", "no boss theme over the song (%s)" % Audio.music_cue)
	await _wait(0.3)
	_check(get_tree().get_nodes_in_group("choir_extra").size() == StoryDirector.CHOIR_EXTRAS.size(), "the whole Choir stands along the hall")
	var pages := await _play_scene(game, 40.0)
	_check(pages >= 1 and not Cutscene.active, "Vael has his say (%d pages)" % pages)
	_check(not vael.asleep and Audio.music_cue == "boss", "then the duel begins (%s)" % Audio.music_cue)
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
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	GameState.set_flag("seen_ending")
	_check(Conversations.branch_for("ottilie").get("lines")[0] == "OTTILIE_TURNED", "after the turn she remembers training with Hessa and Vael, even after the ending")
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
	_check(Conversations.branch_for("lowe").get("lines") == ["LOWE_END_AGAIN"], "then just watches the tide")
	game.queue_free()
	await _wait(0.1)
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
	_check(GameState.item_count("glint") == glints + 150 and first.call("sorrel") == "SORREL_AFTER", "courier's pay, then back to her usual")
	# Ottilie's sign for Hessa.
	GameState.set_flag("ottilie_paid")
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	GameState.set_flag("ottilie_told_vael")
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
	for flag in ["wick_asked", "fen_lanterns_lit", "wick_gave_jar", "murmur_met"]:
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
	_check(first.call("murmur") == "MURMUR_TURNED", "and still feels the turn afterwards")
	GameState.clear_flag(StoryDirector.TURNED_FLAG)
	_check(first.call("murmur") == "MURMUR_LANTERN_AGAIN", "before the turn, Murmur keeps the lantern lit")
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
	for flag in ["talked_corrin_quest", "talked_pell_quest", "nettle_learned", "agna_gave_sword", "marga_gave_jar", "rope_promised", "wick_gave_jar", "sorrel_paid", "sorrel_letters", "sorrel_letters_paid", "letter_ottilie", "letter_liesl", "letter_agna", "seen_wayshell"]:
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
