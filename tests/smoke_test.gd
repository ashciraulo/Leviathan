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
	SaveManager.delete_save()
	_test_room_layouts()
	_test_game_state()
	_test_save_load()
	_test_keys()
	await _test_play()
	await _test_talk_and_dungeon()
	await _test_villagers()
	SaveManager.delete_save()
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
	game.player.global_position = game.current_room.global_position + Vector2(21 * Room.TILE + 8, 6 * Room.TILE + 12)
	Input.action_press("move_right")
	await _wait(0.5)
	Input.action_release("move_right")
	await _wait(0.4)
	_check(GameState.keys("hull") == 0, "the hatch uses the key")
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
	for who in Conversations.TALKS:
		_check(not Conversations.branch_for(who).is_empty(), "%s always has something to say" % who)
		for branch: Dictionary in Conversations.TALKS[who]:
			for page: Dictionary in Conversations.pages(who, branch):
				_check(TranslationServer.translate(page["text"]) != page["text"], "line %s is in strings.csv" % page["text"])
	if not people.has("marga") or not people.has("dunstan"):
		game.queue_free()
		return
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

	# Dying returns Wren to the last Tidestone with full breath.
	GameState.bubbles = 1
	game.player.take_damage(1, game.player.global_position + Vector2(10, 0))
	await _wait(2.0)
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
