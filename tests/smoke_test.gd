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
	await _test_hull_dungeon()
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
		if child is Npc:
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
	var pages := 0
	while box and DialogueBox.is_open and pages < 20:
		box.advance()
		box.advance()
		pages += 1
	_check(not DialogueBox.is_open and not get_tree().paused, "the talk ends and the game resumes")
	_check(pages == Npc.KINDS["hessa"]["first"].size(), "Hessa's first talk has every page (%d)" % pages)
	_check(GameState.flags.get("met_hessa", false), "meeting Hessa is remembered")
	_check(hessa.current_lines().size() == 1, "Hessa has a short reminder after that")
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


func _tile_pos(room: Room, tile: Vector2i) -> Vector2:
	return room.global_position + Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12)


func _goto(game: Node, coord: Vector2i, tile: Vector2i) -> Room:
	Events.door_entered.emit(coord, tile)
	await _wait(0.9)
	return game.current_room


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

	# The Orlop's broken deck: walking into a gap costs a bubble.
	var room := await _goto(game, Vector2i(11, 8), Vector2i(11, 11))
	_check(room.coord == Vector2i(11, 8) and room.has_node("PitField"), "the Orlop has gaps in its deck")
	var before := GameState.bubbles
	Input.action_press("move_up")
	await _wait(0.6)
	Input.action_release("move_up")
	await _wait(0.8)
	_check(GameState.bubbles == before - 1, "falling through a gap pops a bubble (%d -> %d)" % [before, GameState.bubbles])
	var local := player.global_position - room.global_position
	_check(local.y > 10 * Room.TILE and player.state == Player.State.MOVE, "Wren climbs back onto the deck (at %s)" % local)
	await _wait(1.1)

	# The Tide Hook carries Wren over the gap to the hook post. (Clear the
	# crabs out first so none wanders into the chain's path.)
	for enemy in _child_of(room, Enemy):
		enemy.queue_free()
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

	# The Cargo Hold: shove the crate onto the plate to open the bars.
	room = await _goto(game, Vector2i(11, 9), Vector2i(8, 6))
	var crate: Crate = _child_of(room, Crate)[0]
	var start := crate.position
	player.global_position = crate.global_position + Vector2(-15, 0)
	Input.action_press("move_right")
	await _wait(0.9)
	Input.action_release("move_right")
	_check(crate.position.x >= start.x + Room.TILE, "leaning on a crate shoves it (%s -> %s)" % [start, crate.position])
	var plate: PressurePlate = _child_of(room, PressurePlate)[0]
	await _wait(0.3)
	crate.position = Vector2(plate.tile.x * Room.TILE + 8, plate.tile.y * Room.TILE + 12)
	await _wait(0.3)
	_check(plate.pressed, "a crate weighs down the plate")
	_check(GameState.flags.get(RoomPuzzle.flag_for(room.coord), false), "the plate solves the room")
	var bars: Array = _child_of(room, Bars)
	_check(bars.size() == 3 and bars.all(func(b: Bars) -> bool: return b.is_open), "the Cargo Hold's bars open")

	# The Captain's Cabin: the hook drags a crate out of its nook.
	room = await _goto(game, Vector2i(9, 8), Vector2i(12, 3))
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
