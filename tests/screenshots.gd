extends Node
## Captures preview screenshots of the prototype. Needs a real renderer, so CI
## runs it under a virtual display:
##     xvfb-run godot --rendering-driver opengl3 res://tests/screenshots.tscn
## PNGs (4x, nearest-neighbour) land in <project>/screenshots/.
## Uses save slot 2 so it never touches a real save.
##
## With LEVIATHAN_PSEUDO=1 every string is 40% longer and bracketed, and only
## the text-heavy shots are taken (HUD, conversations, large text, a
## cutscene), saved as pseudo_*.png: a check that longer translations still
## fit the dialogue box and the HUD.

const SCALE := 4
const TEST_SLOT := 2

var _out_dir := ""
var _pseudo := false


func _ready() -> void:
	if PseudoText.requested():
		_pseudo = true
		PseudoText.enable()
	_out_dir = ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	SaveManager.current_slot = TEST_SLOT
	SaveManager.set_aside(TEST_SLOT, "testbackup")
	SaveManager.delete_save()

	# 1. Title screen.
	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	add_child(title)
	await _wait(1.6)
	await _capture("01_title")
	title.queue_free()

	# 2. Starting room with the HUD.
	GameState.reset_new_game()
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.6)
	# SHOTS_ONLY=kiln captures just the Kiln (for quick local runs).
	if OS.get_environment("SHOTS_ONLY") in ["kiln", "mire", "gale", "glacier", "belfry", "tomb", "mantle", "lowe", "crucible"]:
		match OS.get_environment("SHOTS_ONLY"):
			"kiln":
				await _kiln_shots(game)
			"mire":
				await _mire_shots(game)
			"gale":
				await _gale_shots(game)
			"glacier":
				await _glacier_shots(game)
			"belfry":
				await _belfry_shots(game)
			"tomb":
				await _tomb_shots(game)
			"mantle":
				game.queue_free()
				await _wait(0.2)
				await _mantle_shots()
			"lowe":
				game.queue_free()
				await _wait(0.2)
				await _lowe_shots()
			"crucible":
				game.queue_free()
				await _wait(0.2)
				await _crucible_shots()
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return
	await _capture("02_saltmarrow_shore")

	# 3. Tidepools: walk east into the Scuttlers.
	var player: Player = game.player
	player.global_position = game.current_room.global_position + Vector2(Room.SIZE.x - 2.0, 6 * Room.TILE + 12)
	Input.action_press("move_right")
	await _wait(0.25)
	await _capture("03_room_transition")
	await _wait(0.5)
	Input.action_release("move_right")
	await _wait(0.4)
	await _capture("04_tidepools_scuttlers")
	# Accessibility: high contrast outlines and a caption from each side,
	# away from the crabs and not mid-blink from a pinch.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.ai_enabled = false
	player.global_position = game.current_room.global_position + Vector2(200, 7 * Room.TILE + 12)
	await _wait(2.0)
	var contrast_was := Settings.high_contrast
	var captions_was := Settings.captions
	Settings.high_contrast = true
	Settings.captions = true
	Audio.play_sfx("bell_ring", game.current_room.global_position + Vector2(8, 60))
	Audio.play_sfx("door_locked", game.current_room.global_position + Vector2(370, 60))
	await _wait(0.2)
	await _capture("04b_high_contrast")
	Settings.high_contrast = contrast_was
	Settings.captions = captions_was
	# The little ring of bubbles that turns after a save.
	Events.game_saved.emit()
	await _wait(0.5)
	await _capture("04c_saved")

	# 4. A sword swing connecting with a Scuttler.
	var room: Room = game.current_room
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(0.1)
	GameState.bubbles = 3
	GameState.resonance = 12.0
	var crab := Scuttler.new()
	crab.ai_enabled = false
	crab.position = Vector2(140, 7 * Room.TILE + 12)
	room.add_child(crab)
	player.global_position = room.global_position + Vector2(120, 7 * Room.TILE + 12)
	player.facing = Vector2.RIGHT
	await _wait(0.2)
	player.start_attack()
	await _wait(0.07)
	await _capture("05_sword_hit")
	await _wait(0.5)

	# 5. Humming to heal.
	GameState.resonance = GameState.resonance_max
	Input.action_press("hum")
	await _wait(0.45)
	await _capture("06_hum_heal")
	Input.action_release("hum")
	crab.queue_free()

	# 6. Other rooms, enemies live.
	# coord: [file name, spawn tile]
	var shots := {
		Vector2i(2, 0): ["07_barnacle_wall", Vector2i(5, 11)],
		Vector2i(1, 1): ["08_wreck_hollow", Vector2i(5, 11)],
		Vector2i(3, 0): ["11_brinewood_edge", Vector2i(7, 6)],
		Vector2i(3, -1): ["12_mangrove_deep", Vector2i(8, 11)],
		Vector2i(4, 0): ["13_wreck_strand", Vector2i(3, 7)],
		Vector2i(4, -1): ["14_lantern_walk", Vector2i(11, 11)],
		Vector2i(5, -1): ["15_heron_shallows", Vector2i(19, 11)],
		Vector2i(5, 0): ["16_hull_landing", Vector2i(11, 9)],
		Vector2i(10, 10): ["17_hull_entry", Vector2i(11, 10)],
		Vector2i(10, 9): ["18_hull_bilge", Vector2i(12, 6)],
		Vector2i(11, 9): ["20_hull_cargo", Vector2i(3, 6)],
		Vector2i(4, -2): ["24_mothlight_glade", Vector2i(11, 11)],
		Vector2i(3, -2): ["25_hollow_bole", Vector2i(21, 6)],
		Vector2i(5, -2): ["26_old_stilts", Vector2i(2, 6)],
		Vector2i(6, -2): ["27_brine_spring", Vector2i(18, 7)],
		Vector2i(6, -1): ["28_rootmaze", Vector2i(11, 1)],
		Vector2i(6, 0): ["29_tangle_shore", Vector2i(11, 2)],
		Vector2i(7, -2): ["40_ashfall_gate", Vector2i(15, 6)],
		Vector2i(8, -2): ["41_cinder_flats", Vector2i(11, 11)],
		Vector2i(8, -3): ["42_ember_ridge", Vector2i(11, 11)],
		Vector2i(9, -2): ["43_slag_fields", Vector2i(2, 6)],
		Vector2i(10, -2): ["44_kiln_mouth", Vector2i(11, 5)],
		Vector2i(8, -1): ["45_geyser_basin", Vector2i(11, 1)],
		Vector2i(9, -1): ["46_scorched_pass", Vector2i(2, 7)],
		Vector2i(4, 1): ["47_fenmouth", Vector2i(11, 1)],
		Vector2i(3, 1): ["48_glowcap_grove", Vector2i(3, 3)],
		Vector2i(5, 1): ["49_stillwater_reach", Vector2i(5, 6)],
		Vector2i(6, 1): ["50_lumen_pool", Vector2i(3, 5)],
		Vector2i(4, 2): ["51_drowned_causeway", Vector2i(11, 1)],
		Vector2i(3, 2): ["52_witherroot_hollow", Vector2i(5, 1)],
		Vector2i(5, 2): ["53_mirelight_edge", Vector2i(3, 7)],
		Vector2i(3, -3): ["54_gullwatch_steps", Vector2i(8, 9)],
		Vector2i(4, -3): ["55_mill_row", Vector2i(11, 4)],
		Vector2i(5, -3): ["56_gale_flats", Vector2i(13, 4)],
		Vector2i(4, -4): ["57_kestrel_ledge", Vector2i(11, 10)],
		Vector2i(3, -4): ["58_thrift_point", Vector2i(16, 7)],
		Vector2i(5, -4): ["59_spire_approach", Vector2i(11, 3)],
		Vector2i(6, -4): ["60_windbreak_cliffs", Vector2i(3, 5)],
		Vector2i(2, -3): ["61_rimewatch_pass", Vector2i(20, 3)],
		Vector2i(1, -3): ["62_frostbite_shelf", Vector2i(4, 4)],
		Vector2i(0, -3): ["63_glacier_foot", Vector2i(20, 4)],
		Vector2i(2, -2): ["64_shiver_coast", Vector2i(11, 2)],
		Vector2i(1, -2): ["65_floe_strand", Vector2i(9, 7)],
		Vector2i(0, -2): ["66_still_cove", Vector2i(21, 7)],
		Vector2i(1, 2): ["67_causeway_end", Vector2i(11, 1)],
		Vector2i(0, 2): ["68_cockle_flats", Vector2i(6, 7)],
		Vector2i(2, 2): ["69_wrack_shore", Vector2i(3, 8)],
		Vector2i(0, 3): ["70_drowned_lane", Vector2i(8, 4)],
		Vector2i(1, 3): ["71_belfry_square", Vector2i(12, 8), Tide.Phase.RISING],
		Vector2i(2, 3): ["72_weir_steps", Vector2i(17, 6), Tide.Phase.HIGH],
		Vector2i(7, 0): ["73_bleached_strand", Vector2i(11, 11)],
		Vector2i(8, 0): ["74_rib_hollow", Vector2i(3, 6)],
		Vector2i(9, 0): ["75_skull_rise", Vector2i(12, 7)],
		Vector2i(7, 1): ["76_sinksand_basin", Vector2i(11, 1)],
		Vector2i(8, 1): ["77_vertebra_road", Vector2i(4, 6)],
		Vector2i(9, 1): ["78_hollow_wind_flats", Vector2i(16, 6)],
		# After the seventh bell, the Old One's lip breaks the bay.
		Vector2i(2, 1): ["79_lullaby_point", Vector2i(11, 9), Tide.Phase.LOW, Tidebell.flag_for("tomb")],
		Vector2i(0, -1): ["10_saltmarrow_village", Vector2i(5, 11)],
	}
	if _pseudo:
		# Only the village, where the conversations are.
		for coord: Vector2i in shots.keys():
			if shots[coord][0] != "10_saltmarrow_village":
				shots.erase(coord)
	for coord: Vector2i in shots:
		var tile: Vector2i = shots[coord][1]
		GameState.set_checkpoint(coord, Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12))
		var story_flag: String = shots[coord][3] if shots[coord].size() > 3 else ""
		if story_flag != "":
			GameState.set_flag(story_flag)
		SaveManager.save_game()
		# The Sunken Verge's tide: out, unless the shot asks for it in.
		var tide: Tide.Phase = shots[coord][2] if shots[coord].size() > 2 else Tide.Phase.LOW
		var into: float = {Tide.Phase.LOW: 3.0, Tide.Phase.RISING: Tide.RISING_TIME * 0.6, Tide.Phase.HIGH: 1.0}[tide]
		Tide.offset = Tide.offset_for(tide, into - 2.2)
		# Reuse the respawn path to jump straight to that room.
		game.respawn()
		await _wait(2.2)
		await _capture(shots[coord][0])
		if story_flag != "":
			GameState.clear_flag(story_flag)
			SaveManager.save_game()

	# 7. Talking to Old Hessa (we're in the village now).
	var hessa: Npc = null
	for child in game.current_room.get_children():
		if child is Npc and child.kind == "hessa":
			hessa = child
	if hessa:
		game.player.global_position = hessa.global_position + Vector2(-2, 16)
		game.player.facing = Vector2.UP
		await _wait(0.3)
		await _capture("21_hessa_listens")
		game.player.try_interact()
		await _wait(0.2)
		for child in game.get_children():
			if child is DialogueBox:
				child.advance()
				child.advance()
		await _wait(3.5)
		await _capture("22_hessa_talks")
		for child in game.get_children():
			if child is DialogueBox:
				child.close()
		await _wait(0.3)

	# 7b. Saltmarrow's villagers: Marga's errand, with portraits and narration.
	var people := {}
	for child in game.current_room.get_children():
		if child is Npc:
			people[child.kind] = child
	if people.has("marga") and people.has("dunstan"):
		game.player.global_position = people["marga"].global_position + Vector2(10, 18)
		game.player.facing = Vector2.UP
		await _wait(0.4)
		await _capture("24_saltmarrow_villagers")
		game.player.global_position = people["marga"].global_position + Vector2(0, 18)
		await _wait(0.1)
		game.player.try_interact()
		await _wait(2.5)
		await _capture("25_marga_asks")
		await _finish_talk(game)
		# Large text: same box, one big line per page.
		var was_large := Settings.large_text
		Settings.large_text = true
		var big := _dialogue_box(game)
		if big:
			big.open_pages(Conversations.pages("marga", Conversations.TALKS["marga"][-1]))
			big.advance()
			big.advance()
			await _wait(1.5)
			await _capture("28_large_text")
			await _finish_talk(game)
		Settings.large_text = was_large
		game.player.global_position = people["dunstan"].global_position + Vector2(-4, 20)
		await _wait(0.2)
		game.player.try_interact()
		var box := _dialogue_box(game)
		if box:
			box.advance()
			box.advance()
			await _wait(0.8)
			await _capture("26_wren_nods")
			box.advance()
			box.advance()
			await _wait(1.5)
			await _capture("27_dunstan_portrait")
		await _finish_talk(game)

	if _pseudo:
		# A cutscene with portraits, then done: the rest has little text.
		game.queue_free()
		await _wait(0.2)
		await _lowe_shots()
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# 8. Opening a chest in the Hull's galley.
	GameState.set_checkpoint(Vector2i(9, 9), Vector2(15 * Room.TILE + 8, 4 * Room.TILE + 4))
	SaveManager.save_game()
	game.respawn()
	await _wait(2.2)
	await _capture("19_hull_galley")
	for child in game.current_room.get_children():
		if child is Chest:
			game.player.facing = Vector2.UP
			game.player.global_position = child.global_position + Vector2(0, 14)
			await _wait(0.2)
			game.player.try_interact()
			await _wait(0.5)
			await _capture("23_chest_key")

	# 8b. The rest of the Rotting Hull, and the fight at its heart.
	await _hull_shots(game)

	# 8c. The Kiln.
	await _kiln_shots(game)

	# 8d. Lantern Mire.
	await _mire_shots(game)

	# 8e. Gale Spire.
	await _gale_shots(game)

	# 8f. Hollow Glacier.
	await _glacier_shots(game)

	# 8g. Drowned Belfry.
	await _belfry_shots(game)

	# 8h. Marrow Tomb.
	await _tomb_shots(game)

	# 9. Pause menu.
	var pause: PauseMenu = null
	for child in game.get_children():
		if child is PauseMenu:
			pause = child
	if pause:
		pause.open()
		await _wait(0.2)
		await _capture("09_pause")
		pause.close()

	# 10. Story scenes: the opening, then the Wayshell after the Hull.
	game.queue_free()
	await _wait(0.2)
	GameState.reset_new_game()
	GameState.play_opening = true
	var story: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(story)
	await _wait(1.6)
	await _capture("30_opening")
	# The veil lifts after the three lines; then Hessa's lamp glows.
	await _wait(12.4)
	await _capture("31_hessa_calls")
	await _skip_scene(story)
	story.queue_free()
	await _wait(0.2)
	await _mantle_shots()
	await _lowe_shots()
	await _crucible_shots()
	GameState.reset_new_game()
	GameState.set_flag("tidebell_hull")
	GameState.set_flag("freed_mantle")
	# Coming in from the shore path at the bottom of the village.
	GameState.set_checkpoint(Vector2i(0, -1), Vector2(12 * Room.TILE, 11 * Room.TILE + 12))
	var home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	while Cutscene.active and not DialogueBox.is_open:
		await _wait(0.1)
	await _wait(2.0)
	await _capture("32_wayshell")
	await _skip_scene(home)
	home.queue_free()
	await _wait(0.2)

	# 11. Side quests: Pell's three-clawed crab in the Tidepools, then the pearl.
	GameState.reset_new_game()
	for flag in ["seen_opening", "met_hessa", "talked_pell_quest"]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(Vector2i(1, 0), Vector2(17 * Room.TILE + 8, 8 * Room.TILE + 12))
	var pools: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(pools)
	await _wait(1.2)
	await _capture("33_three_clawed_crab")
	GameState.set_flag("found_crab")
	GameState.set_checkpoint(Vector2i(0, -1), Vector2(8 * Room.TILE + 8, 9 * Room.TILE + 12))
	SaveManager.save_game()
	pools.respawn()
	await _wait(2.4)
	for child in pools.current_room.get_children():
		if child is Npc and child.kind == "pell":
			child.set_process(false)
			child.position = Vector2(8 * Room.TILE + 8, 7 * Room.TILE + 12)
	pools.player.facing = Vector2.UP
	Conversations.talk("pell")
	await _wait(1.5)
	await _capture("34_pell_pearl")
	_finish_talk(pools)
	# Nettle, with their paper lantern held up as they talk.
	for child in pools.current_room.get_children():
		if child is Npc and child.kind == "nettle":
			pools.player.global_position = child.global_position + Vector2(0, 18)
	pools.player.facing = Vector2.UP
	Conversations.talk("nettle")
	await _wait(1.5)
	await _capture("37_nettle")
	_finish_talk(pools)
	# Agna Holt, the last founder, outside the Kiln.
	GameState.set_checkpoint(Vector2i(10, -2), Vector2(14 * Room.TILE + 8, 6 * Room.TILE + 12))
	SaveManager.save_game()
	pools.respawn()
	await _wait(2.4)
	pools.player.facing = Vector2.UP
	Conversations.talk("agna")
	await _wait(1.5)
	await _capture("38_agna")
	_finish_talk(pools)

	SaveManager.delete_save()
	SaveManager.restore_aside(TEST_SLOT, "testbackup")
	print("SCREENSHOTS DONE: " + _out_dir)
	get_tree().quit(0)


func _jump(game: Node, coord: Vector2i, tile: Vector2i) -> Room:
	GameState.set_checkpoint(coord, Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12))
	SaveManager.save_game()
	game.respawn()
	await _wait(2.2)
	return game.current_room


func _hull_shots(game: Node) -> void:
	# coord: [file name, spawn tile]
	var rooms := {
		Vector2i(11, 9): ["30_hull_cargo_crate", Vector2i(8, 6)],
		Vector2i(12, 9): ["31_hull_rope_locker", Vector2i(3, 6)],
		Vector2i(10, 8): ["33_hull_listing_deck", Vector2i(21, 6)],
		Vector2i(9, 8): ["34_hull_captains_cabin", Vector2i(12, 7)],
		Vector2i(9, 10): ["35_hull_flooded_hold", Vector2i(12, 2)],
		Vector2i(11, 10): ["36_hull_brig", Vector2i(3, 6)],
	}
	for coord: Vector2i in rooms:
		await _jump(game, coord, rooms[coord][1])
		await _capture(rooms[coord][0])

	# The Tide Hook mid-flight across the Orlop's broken deck.
	GameState.give_item("tide_hook")
	var room := await _jump(game, Vector2i(11, 8), Vector2i(11, 11))
	for enemy in room.get_children():
		if enemy is Enemy:
			enemy.queue_free()
	game.player.facing = Vector2.UP
	await _wait(0.2)
	game.player.use_item("tide_hook")
	await _wait(0.22)
	await _capture("32_hull_orlop_hook")
	await _wait(0.2)
	await _capture("32b_hull_orlop_zip")
	await _wait(1.0)

	# The Barnacle Matriarch: rearing up, then her soft body exposed.
	GameState.set_flag(StoryDirector.LOWE_HULL_FLAG)
	room = await _jump(game, Vector2i(10, 7), Vector2i(11, 9))
	await _wait(1.0)
	var boss: BarnacleMatriarch = null
	for child in room.get_children():
		if child is BarnacleMatriarch:
			boss = child
	if boss:
		boss.ai_enabled = false
		await _capture("37_matriarch")
		boss.mode = BarnacleMatriarch.Mode.WINDUP
		boss._timer = 0.5
		await _wait(0.05)
		await _capture("38_matriarch_windup")
		boss.mode = BarnacleMatriarch.Mode.RECOVER
		boss.hook_hit(Vector2.UP)
		game.player.global_position = boss.global_position + Vector2(0, 22)
		game.player.facing = Vector2.UP
		await _wait(0.35)
		await _capture("39_matriarch_exposed")
		boss.mode = BarnacleMatriarch.Mode.EXPOSED
		boss.take_hit(99, Vector2.UP)
		await _wait(3.2)
		game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 7 * Room.TILE)
		await _wait(0.3)
		await _capture("40_tidebell")
		# Ringing it: the talk box stays at the bottom, clear of Wren and the bell.
		for child in room.get_children():
			if child is Tidebell:
				game.player.global_position = child.global_position + Vector2(0, 16)
				game.player.facing = Vector2.UP
				await _wait(0.2)
				game.player.try_interact()
				await _wait(2.0)
				await _capture("41_tidebell_rung")
				for box in game.get_children():
					if box is DialogueBox:
						box.close()


func _kiln_shots(game: Node) -> void:
	GameState.give_item("tide_hook")
	GameState.give_item("stonebreaker")
	# coord: [file name, spawn tile]
	var rooms := {
		Vector2i(21, 10): ["50_kiln_entry", Vector2i(11, 10)],
		Vector2i(21, 9): ["51_kiln_casting_floor", Vector2i(18, 6)],
		Vector2i(20, 9): ["52_kiln_mould_store", Vector2i(11, 7)],
		Vector2i(20, 10): ["53_kiln_bellows", Vector2i(11, 9)],
		Vector2i(22, 9): ["54_kiln_slag_pits", Vector2i(11, 3)],
		Vector2i(22, 10): ["55_kiln_quench_room", Vector2i(11, 4)],
		Vector2i(21, 8): ["57_kiln_gallery", Vector2i(11, 5)],
		Vector2i(20, 8): ["58_kiln_pattern_shop", Vector2i(20, 6)],
		Vector2i(22, 7): ["59_kiln_bell_loft", Vector2i(11, 10)],
	}
	for coord: Vector2i in rooms:
		await _jump(game, coord, rooms[coord][1])
		await _wait(0.4)
		await _capture(rooms[coord][0])

	# The mallet coming down on a boulder in the Slag Pits.
	var room := await _jump(game, Vector2i(22, 9), Vector2i(11, 3))
	for enemy in room.get_children():
		if enemy is Enemy:
			enemy.queue_free()
	game.player.facing = Vector2.UP
	await _wait(0.2)
	game.player.use_item("stonebreaker")
	await _wait(0.1)
	await _capture("54b_kiln_mallet_raise")
	await _wait(0.1)
	await _capture("54c_kiln_mallet_smash")
	await _wait(0.5)

	# A Clinker flipped onto its back.
	for child in room.get_children():
		if child is Clinker:
			child.queue_free()
	var clinker := Clinker.new()
	clinker.position = Vector2(11 * Room.TILE + 8, 5 * Room.TILE + 12)
	room.add_child(clinker)
	game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 3 * Room.TILE + 12)
	game.player.facing = Vector2.DOWN
	await _wait(0.1)
	clinker.ai_enabled = false
	clinker.mallet_hit(Vector2.DOWN)
	await _wait(0.4)
	await _capture("54d_kiln_clinker_flipped")

	# The Riser: lava climbing behind Wren.
	room = await _jump(game, Vector2i(22, 8), Vector2i(11, 11))
	game.player.global_position = room.global_position + Vector2(20 * Room.TILE + 8, 8 * Room.TILE + 12)
	await _wait(5.0)
	await _capture("56_kiln_riser")

	# The Slagwyrm: chasing, plates set hard by a pool, then the wake.
	GameState.set_flag(StoryDirector.CRUCIBLE_FLAG)
	room = await _jump(game, Vector2i(21, 7), Vector2i(11, 10))
	await _wait(1.6)
	var boss: Slagwyrm = null
	for child in room.get_children():
		if child is Slagwyrm:
			boss = child
	if boss:
		# Wren can't be hurt during these shots: a death would reload the room.
		game.player._invuln = 999.0
		game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 9 * Room.TILE + 12)
		await _wait(1.6)
		await _capture("60_slagwyrm")
		for i in boss.segments.size():
			if i % 2 == 0:
				boss.segments[i].harden(6.0)
		boss.ai_enabled = false
		await _wait(0.3)
		await _capture("61_slagwyrm_crusted")
		boss.ai_enabled = true
		boss._go_under()
		await _wait(0.6)
		await _capture("62_slagwyrm_wake")
		await _wait(1.4)
		await _capture("63_slagwyrm_tell")
		await _wait(1.0)
		while boss and is_instance_valid(boss) and boss.segments.size() > 0:
			boss.segment_smashed(boss.segments[0])
		await _wait(1.6)
		await _capture("64_slagwyrm_stone")
		await _wait(2.5)
		game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 7 * Room.TILE + 12)
		await _wait(0.3)
		await _capture("65_ember_bell")
		game.player._invuln = 0.0


func _mire_shots(game: Node) -> void:
	GameState.give_item("glowmoth_lantern")
	# coord: [file name, spawn tile, lantern raised]
	var rooms := [
		[Vector2i(25, 10), "70_mire_entry", Vector2i(11, 10), false],
		[Vector2i(25, 9), "71_mire_mourners_walk", Vector2i(11, 7), false],
		[Vector2i(24, 9), "72_mire_candle_store", Vector2i(12, 8), false],
		[Vector2i(25, 8), "73_mire_moth_chapel", Vector2i(11, 9), false],
		[Vector2i(26, 9), "74_mire_drowned_walk_dark", Vector2i(3, 6), false],
		[Vector2i(26, 9), "75_mire_drowned_walk_lantern", Vector2i(3, 6), true],
		[Vector2i(26, 8), "76_mire_brazier_hall", Vector2i(11, 10), true],
		[Vector2i(26, 10), "77_mire_grave_lamps", Vector2i(11, 4), true],
		[Vector2i(24, 8), "78_mire_ossuary", Vector2i(20, 7), true],
	]
	for shot: Array in rooms:
		await _jump(game, shot[0], shot[2])
		_mire_lantern(game, shot[3])
		await _wait(0.5)
		await _capture(shot[1])

	# A brazier catching, and a Shade cringing from the light.
	var room := await _jump(game, Vector2i(26, 8), Vector2i(4, 10))
	_mire_lantern(game, true)
	var shade := Shade.new()
	shade.position = Vector2(7 * Room.TILE + 8, 9 * Room.TILE + 12)
	room.add_child(shade)
	await _wait(0.4)
	await _capture("79_mire_brazier_and_shade")

	# The Pale Congregation.
	room = await _jump(game, Vector2i(25, 7), Vector2i(11, 10))
	_mire_lantern(game, false)
	await _wait(3.0)
	await _capture("80_pale_congregation")
	var boss: PaleCongregation = null
	for child in room.get_children():
		if child is PaleCongregation:
			boss = child
	_mire_lantern(game, true)
	await _wait(1.0)
	await _capture("81_congregation_drawn_to_lantern")
	_mire_lantern(game, false)
	await _wait(0.6)
	await _capture("82_congregation_heart_bare")
	if boss:
		while is_instance_valid(boss) and boss.hp > 0:
			boss._stun = 0.0
			for wisp: Dictionary in boss.wisps:
				wisp["home"] = false
			boss.take_hit(1, Vector2.UP)
	await _wait(1.2)
	await _capture("83_congregation_released")
	# The calf in the lights, with Murmur.
	while Cutscene.active and not DialogueBox.is_open:
		await _wait(0.1)
	await _wait(1.6)
	await _capture("43_calf_in_the_lights")
	await _skip_scene(game)
	await _wait(0.5)
	game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 8 * Room.TILE + 12)
	await _wait(0.3)
	await _capture("84_moth_bell")
	game.player._invuln = 0.0


func _gale_shots(game: Node) -> void:
	GameState.give_item("kite_cloak")
	# coord: [file name, spawn tile]
	var rooms := [
		[Vector2i(28, 10), "90_gale_entry", Vector2i(11, 10)],
		[Vector2i(27, 10), "91_gale_rope_store", Vector2i(10, 8)],
		[Vector2i(28, 9), "92_gale_fan_hall", Vector2i(11, 9)],
		[Vector2i(27, 9), "93_gale_sail_loft", Vector2i(11, 9)],
		[Vector2i(29, 9), "94_gale_gust_gallery", Vector2i(2, 6)],
		[Vector2i(28, 8), "95_gale_bell_shaft", Vector2i(11, 11)],
		[Vector2i(29, 8), "96_gale_weathervane", Vector2i(2, 6)],
		[Vector2i(27, 8), "97_gale_rookery", Vector2i(21, 6)],
	]
	for shot: Array in rooms:
		await _jump(game, shot[0], shot[2])
		game.player._invuln = 600.0
		await _wait(0.4)
		await _capture(shot[1])

	# Gliding over the drop on the fan's wind.
	await _jump(game, Vector2i(29, 9), Vector2i(4, 6))
	game.player._invuln = 600.0
	game.player.facing = Vector2.RIGHT
	game.player.use_item("kite_cloak")
	await _wait(0.6)
	await _capture("98_gale_gliding")
	await _wait(2.0)

	# The Stormheron.
	var room := await _jump(game, Vector2i(28, 7), Vector2i(11, 10))
	game.player._invuln = 600.0
	await _wait(2.4)
	await _capture("99_stormheron_perched")
	var heron: Stormheron = null
	for child in room.get_children():
		if child is Stormheron:
			heron = child
	if heron:
		heron._throws = 0
		heron.mode = Stormheron.Mode.FLARE
		heron._timer = 0.3
		await _wait(0.45)
		await _capture("100_stormheron_feathers")
		heron._throws = Stormheron.THROWS_PER_STORM
		heron.mode = Stormheron.Mode.PERCH
		heron._timer = 0.0
		await _wait(0.8)
		await _capture("101_stormheron_storm")
		await _wait(0.75)
		await _capture("102_stormheron_struck")
		await _wait(0.5)
		game.player.global_position = heron.global_position + Vector2(-20, 6)
		await _wait(0.3)
		await _capture("103_stormheron_grounded")
		while is_instance_valid(heron) and heron.hp > 0:
			heron._stun = 0.0
			heron._hits_this_landing = 0
			heron.mode = Stormheron.Mode.GROUNDED
			heron.take_hit(1, Vector2.UP)
	# Vael at the spire.
	for page in 3:
		while Cutscene.active and not DialogueBox.is_open:
			await _wait(0.1)
		await _wait(1.6)
		if page == 2:
			await _capture("44_vael_at_the_spire")
		var box := _dialogue_box(game)
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		await _wait(0.2)
	await _skip_scene(game)
	await _wait(0.5)
	game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 4)
	await _wait(0.3)
	await _capture("104_storm_bell")
	game.player._invuln = 0.0


func _tomb_shots(game: Node) -> void:
	# coord: [file name, spawn tile]
	var rooms := [
		[Vector2i(40, 10), "135_tomb_entry", Vector2i(11, 10)],
		[Vector2i(40, 9), "136_tomb_hall_of_ribs", Vector2i(11, 11)],
		[Vector2i(39, 9), "137_tomb_horn_crypt", Vector2i(11, 7)],
		[Vector2i(40, 8), "138_tomb_echo_chamber", Vector2i(11, 11)],
		[Vector2i(39, 8), "139_tomb_forgotten_ossuary", Vector2i(21, 6)],
		[Vector2i(41, 9), "140_tomb_bone_pit", Vector2i(3, 6)],
	]
	for shot: Array in rooms:
		var at := await _jump(game, shot[0], shot[2])
		game.player._invuln = 600.0
		# Everyone holds still for the picture.
		for child in at.get_children():
			if child is Enemy:
				child.ai_enabled = false
		await _wait(0.5)
		game.player._invuln = 0.0
		await _wait(0.05)
		await _capture(shot[1])
	GameState.give_item("echo_horn")

	# The horn's note, and the barricade coming down.
	var room := await _jump(game, Vector2i(40, 9), Vector2i(11, 3))
	game.player._invuln = 600.0
	game.player.facing = Vector2.UP
	await _wait(0.3)
	game.player.use_item("echo_horn")
	await _wait(0.2)
	await _capture("141_tomb_echo_horn")
	await _wait(0.6)

	# Skulls singing in the Echo Chamber, and the hidden wall found.
	room = await _jump(game, Vector2i(40, 8), Vector2i(7, 4))
	game.player._invuln = 600.0
	await _wait(0.3)
	game.player.use_item("echo_horn")
	await _wait(0.8)
	game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 8 * Room.TILE + 12)
	await _wait(0.2)
	game.player.use_item("echo_horn")
	await _wait(0.5)
	game.player._invuln = 0.0
	await _capture("142_tomb_skulls_singing")
	game.player._invuln = 600.0
	game.player.global_position = room.global_position + Vector2(2 * Room.TILE + 8, 6 * Room.TILE + 12)
	game.player.facing = Vector2.LEFT
	await _wait(0.3)
	game.player.use_item("echo_horn")
	await _wait(0.9)
	game.player._invuln = 0.0
	await _capture("143_tomb_hidden_wall_found")

	# The Hush, shown by an echo.
	room = await _jump(game, Vector2i(39, 8), Vector2i(12, 6))
	game.player._invuln = 600.0
	await _wait(0.4)
	game.player.use_item("echo_horn")
	await _wait(0.6)
	game.player._invuln = 0.0
	await _capture("144_tomb_hush_shown")

	# The Hollow Regent.
	room = await _jump(game, Vector2i(40, 7), Vector2i(11, 11))
	game.player._invuln = 600.0
	var regent: HollowRegent = null
	for child in room.get_children():
		if child is HollowRegent:
			regent = child
	if regent:
		await _wait(1.6)
		await _capture("145_regent_armoured")
		regent.ai_enabled = false
		regent.mode = HollowRegent.Mode.RAISE
		await _wait(0.2)
		await _capture("146_regent_raises_sceptre")
		game.player.global_position = regent.global_position + Vector2(0, 40)
		regent.mode = HollowRegent.Mode.WALK
		for i in 3:
			game.player.use_item("echo_horn")
			await _wait(0.7)
		await _wait(0.2)
		await _capture("147_regent_open")


func _belfry_shots(game: Node) -> void:
	GameState.give_item("divers_helm")
	GameState.flags.erase(Room.low_water_flag("belfry"))
	# coord: [file name, spawn tile]
	var rooms := [
		[Vector2i(36, 10), "120_belfry_entry", Vector2i(11, 10)],
		[Vector2i(36, 9), "121_belfry_flooded_court", Vector2i(11, 11)],
		[Vector2i(35, 9), "122_belfry_vestry", Vector2i(22, 6)],
		[Vector2i(37, 9), "123_belfry_cistern", Vector2i(1, 6)],
		[Vector2i(36, 8), "124_belfry_valve_chamber", Vector2i(11, 11)],
		[Vector2i(35, 8), "125_belfry_choir", Vector2i(22, 6)],
		[Vector2i(37, 8), "126_belfry_loft", Vector2i(1, 6)],
	]
	for shot: Array in rooms:
		await _jump(game, shot[0], shot[2])
		game.player._invuln = 600.0
		await _wait(0.4)
		game.player._invuln = 0.0
		await _wait(0.05)
		await _capture(shot[1])

	# Swimming, then diving under the Cistern's grates.
	var room := await _jump(game, Vector2i(37, 9), Vector2i(1, 6))
	game.player._invuln = 600.0
	game.player.global_position = room.global_position + Vector2(10 * Room.TILE + 8, 5 * Room.TILE + 12)
	game.player.facing = Vector2.RIGHT
	await _wait(0.5)
	game.player._invuln = 0.0
	await _wait(0.05)
	await _capture("127_belfry_swimming")
	game.player.use_item("divers_helm")
	await _wait(0.5)
	await _capture("128_belfry_diving")
	await _wait(DiversHelm.DIVE_TIME)

	# The valve lets the water down.
	room = await _jump(game, Vector2i(36, 8), Vector2i(11, 11))
	for child in room.get_children():
		if child is Valve:
			child.interact()
	await _wait(1.0)
	game.player._invuln = 0.0
	await _capture("129_belfry_water_down")
	room = await _jump(game, Vector2i(36, 9), Vector2i(11, 11))
	await _wait(0.4)
	await _capture("130_belfry_court_drained")
	GameState.flags.erase(Room.low_water_flag("belfry"))

	# Knell.
	room = await _jump(game, Vector2i(36, 7), Vector2i(11, 11))
	game.player._invuln = 600.0
	var knell: Knell = null
	for child in room.get_children():
		if child is Knell:
			knell = child
	if knell:
		await _wait(2.5)
		await _capture("131_knell_arms")
		var arm: Tentacle = knell.arms[2]
		game.player.global_position = arm.global_position + Vector2(0, 14)
		game.player.facing = Vector2.UP
		await _wait(0.1)
		game.player.use_item("divers_helm")
		await _wait(0.3)
		await _capture("132_knell_dive_under")
		for a: Tentacle in knell.arms:
			a.dive_hit(Vector2.UP)
		await _wait(DiversHelm.DIVE_TIME)
		await _wait(0.3)
		await _capture("133_knell_hidden")
		knell.bell.mallet_hit(Vector2.UP)
		game.player.global_position = knell.global_position + Vector2(0, 30)
		await _wait(0.4)
		await _capture("134_knell_dazed")


func _glacier_shots(game: Node) -> void:
	GameState.give_item("frostfang_bow")
	# coord: [file name, spawn tile]
	var rooms := [
		[Vector2i(32, 10), "105_glacier_entry", Vector2i(11, 10)],
		[Vector2i(31, 10), "106_glacier_frozen_pond", Vector2i(21, 6)],
		[Vector2i(32, 9), "107_glacier_crevasse_hall", Vector2i(11, 10)],
		[Vector2i(31, 9), "108_glacier_bowyers_cave", Vector2i(20, 6)],
		[Vector2i(33, 9), "109_glacier_black_pool", Vector2i(1, 6)],
		[Vector2i(32, 8), "110_glacier_eye_gallery", Vector2i(11, 11)],
		[Vector2i(33, 8), "111_glacier_slide_hall", Vector2i(1, 7)],
	]
	for shot: Array in rooms:
		await _jump(game, shot[0], shot[2])
		game.player._invuln = 600.0
		await _wait(0.4)
		await _capture(shot[1])

	# Freezing a way across the Black Pool.
	var room := await _jump(game, Vector2i(33, 9), Vector2i(2, 5))
	game.player._invuln = 600.0
	game.player.facing = Vector2.RIGHT
	await _wait(0.2)
	game.player.use_item("frostfang_bow")
	await _wait(0.2)
	await _capture("112_glacier_frost_arrow")
	await _wait(0.4)
	for x in range(3, 7):
		game.player.global_position = room.global_position + Vector2(x * Room.TILE + 8, 5 * Room.TILE + 12)
		game.player.velocity = Vector2.ZERO
		game.player.facing = Vector2.RIGHT
		await _wait(0.2)
		game.player.use_item("frostfang_bow")
		await _wait(0.5)
	game.player._invuln = 0.0
	await _wait(0.05)
	await _capture("113_glacier_frozen_path")

	# Two eyes open in the Eye Gallery.
	room = await _jump(game, Vector2i(32, 8), Vector2i(11, 11))
	game.player._invuln = 600.0
	var eyes := room.get_children().filter(func(n: Node) -> bool: return n is IceEye)
	if eyes.size() >= 2:
		eyes[0].arrow_hit(Vector2.UP)
		eyes[1].arrow_hit(Vector2.UP)
	game.player.global_position = room.global_position + Vector2(10 * Room.TILE + 8, 6 * Room.TILE + 12)
	await _wait(0.4)
	await _capture("114_glacier_eyes_open")

	# Rimeback.
	room = await _jump(game, Vector2i(32, 7), Vector2i(11, 11))
	game.player._invuln = 600.0
	var walrus: Rimeback = null
	for child in room.get_children():
		if child is Rimeback:
			walrus = child
	if walrus:
		await _wait(0.3)
		walrus.hole = 0
		walrus._come_up(game.player)
		await _wait(Rimeback.RISE_TIME + 0.4)
		await _capture("115_rimeback_surfaced")
		walrus.mode = Rimeback.Mode.SPIT
		walrus._timer = 0.3
		await _wait(0.45)
		await _capture("116_rimeback_ice")
		for i in walrus.holes.size():
			room.freeze(walrus.holes[i]["tiles"][0])
		walrus.mode = Rimeback.Mode.UNDER
		walrus._timer = 0.0
		await _wait(0.6)
		await _capture("117_rimeback_breaking_through")
		await _wait(Rimeback.BREACH_TELL)
		game.player.global_position = walrus.global_position + Vector2(0, 30)
		await _wait(0.3)
		await _capture("118_rimeback_dazed")
		while is_instance_valid(walrus) and walrus.hp > 0:
			walrus._stun = 0.0
			walrus._hits_this_daze = 0
			walrus.mode = Rimeback.Mode.DAZED
			walrus.take_hit(1, Vector2.UP)
	await _wait(4.0)
	game.player.global_position = room.global_position + Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 4)
	await _wait(0.3)
	await _capture("119_frost_bell")
	game.player._invuln = 0.0


## Wren (after a respawn, a new Wren) with the lantern up or down, and no
## harm coming to them mid-shot.
func _mire_lantern(game: Node, raised: bool) -> void:
	var player: Player = game.player
	player._invuln = 600.0
	if player.lantern_raised != raised:
		player.use_item("glowmoth_lantern")


func _dialogue_box(game: Node) -> DialogueBox:
	for child in game.get_children():
		if child is DialogueBox:
			return child
	return null


func _finish_talk(game: Node) -> void:
	var box := _dialogue_box(game)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
	await _wait(0.4)


func _skip_scene(game: Node) -> void:
	var waited := 0.0
	while Cutscene.active and waited < 20.0:
		var box := _dialogue_box(game)
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		await _wait(0.1)
		waited += 0.1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	var path := _out_dir.path_join(("pseudo_" if _pseudo else "") + file_name + ".png")
	var err := image.save_png(path)
	print("Saved %s (%s)" % [path, error_string(err)])


## Freeing Mantle on the Wreck Strand: netted, then cut free and rising.
func _mantle_shots() -> void:
	GameState.reset_new_game()
	GameState.set_flag("tidebell_hull")
	GameState.set_checkpoint(Vector2i(4, 0), Vector2(1 * Room.TILE + 8, 6 * Room.TILE + 12))
	var strand: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(strand)
	await _wait(1.0)
	await _capture("35_mantle_netted")
	await _wait(6.0)
	await _capture("36_mantle_rises")
	await _skip_scene(strand)
	strand.queue_free()
	await _wait(0.2)


## Sister Lowe at the Hull: her singers pry at the sleeping Matriarch, she
## warns Wren off, then the Choir scatters as the Matriarch wakes.
func _lowe_shots() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.HULL_BOSS, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 12))
	var hold: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(hold)
	for page in 3:
		while Cutscene.active and not DialogueBox.is_open:
			await _wait(0.1)
		await _wait(1.2)
		if page == 1:
			await _capture("39_lowe_at_the_hull")
		var box := _dialogue_box(hold)
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		await _wait(0.2)
	await _wait(0.5)
	await _capture("40_choir_scatters")
	await _skip_scene(hold)
	hold.queue_free()
	await _wait(0.2)


## The crucible at the Kiln: Lowe's smiths stoke it, then the Slagwyrm
## bursts out of the melt and the Choir runs.
func _crucible_shots() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.KILN_BOSS, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 12))
	var kiln: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(kiln)
	for page in 3:
		while Cutscene.active and not DialogueBox.is_open:
			await _wait(0.1)
		await _wait(1.2)
		if page == 0:
			await _capture("41_the_crucible")
		var box := _dialogue_box(kiln)
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		await _wait(0.2)
	await _wait(0.6)
	await _capture("42_slagwyrm_wakes")
	await _skip_scene(kiln)
	kiln.queue_free()
	await _wait(0.2)
