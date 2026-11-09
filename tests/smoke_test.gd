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
	var real_save := ProjectSettings.globalize_path(SaveManager.slot_path(TEST_SLOT))
	# A run that crashed left the real save in the backup: never overwrite it.
	if FileAccess.file_exists(real_save + ".testbackup"):
		DirAccess.remove_absolute(real_save)
		DirAccess.rename_absolute(real_save + ".testbackup", real_save)
	if FileAccess.file_exists(real_save):
		DirAccess.rename_absolute(real_save, real_save + ".testbackup")
	SaveManager.delete_save()
	_test_room_layouts()
	_test_game_state()
	_test_save_load()
	_test_keys()
	_test_items()
	_test_audio()
	_test_text_fit()
	await _test_menus()
	await _test_play()
	await _test_talk_and_dungeon()
	await _test_hull_dungeon()
	await _test_kiln_dungeon()
	await _test_villagers()
	await _test_story()
	await _test_brinewood_pearl()
	await _test_cinderreach()
	await _test_gloamfen()
	await _test_windmere()

	await _test_fast_travel()
	await _test_credits()
	await _test_side_quests()
	SaveManager.delete_save()
	if FileAccess.file_exists(real_save + ".testbackup"):
		DirAccess.rename_absolute(real_save + ".testbackup", real_save)
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
	SaveManager.delete_save()
	_check(not SaveManager.has_save(), "delete removes the save")


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
	for who in ["hessa", "pell", "marga", "dunstan"]:
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
	_check(fit_box.lines_for("SIGN_SALTMARROW", false) <= DialogueBox.MAX_LINES, "the sign fits the box")
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
	_check(game.current_room != null and game.current_room.coord == Vector2i.ZERO, "respawn at the Tidestone's room")
	_check(game.player != null and game.player.state != Player.State.DEAD, "Wren is back on their feet")
	game.queue_free()
	await _wait(0.1)


func _count_projectiles(room: Room) -> int:
	var count := 0
	for child in room.get_children():
		if child is Projectile:
			count += 1
	return count


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

	# The Barnacle Matriarch.
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
			bell.interact()
			_check(GameState.resonance_max > resonance_before and GameState.flags.get(Tidebell.BELL_FLAG, false), "ringing the bell grows the Resonance meter")
			for child in game.get_children():
				if child is DialogueBox:
					while DialogueBox.is_open:
						child.advance()
						child.advance()
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
			bell.interact()
			_check(GameState.has_flag(Tidebell.flag_for("kiln")) and GameState.item_count("tidebell") == bells_before + 1, "ringing the Ember Bell counts as a Tidebell")
			for child in game.get_children():
				if child is DialogueBox:
					while DialogueBox.is_open:
						child.advance()
						child.advance()
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
	Settings.rebind("tab_next", _pad_event(JOY_BUTTON_RIGHT_SHOULDER))
	var has_button := false
	for event in InputMap.action_get_events("tab_next"):
		has_button = has_button or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_SHOULDER)
	_check(has_button, "rebinding Tab Next to a button works")
	Settings.pad_overrides.erase("tab_next")
	Settings.apply()
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
	var listen := func(key: String) -> void: heard.append(key)
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
	Audio.play_music("region_saltmarrow")
	_check(Audio.music_cue == "region_saltmarrow", "music cues switch even before the track exists")
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
	# Leaving would change scene and end the test: don't let it.
	credits._leaving = true
	credits.queue_free()
	await _wait(0.1)
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
	var below := _walkable_from(steps, Vector2i(8, 12))
	_check(not below.has(Vector2i(8, 3)), "the Gullwatch chasm can't be crossed on foot")

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
