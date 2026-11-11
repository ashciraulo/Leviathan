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
	# SHOTS_ONLY=seaglass: a few of the pieces of sea-glass where they lie.
	if OS.get_environment("SHOTS_ONLY") == "seaglass":
		await _sea_glass_shots(game)
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# SHOTS_ONLY=ebb: the sea bed, under water and then held bare.
	if OS.get_environment("SHOTS_ONLY") == "ebb":
		await _ebb_shots(game)
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# SHOTS_ONLY=caves: the side areas and hidden nooks, and their ways in.
	if OS.get_environment("SHOTS_ONLY") == "caves":
		await _room_shots(game, {
			Vector2i(1, -2): ["caves_rime_way_in", Vector2i(12, 6)],
			Vector2i(1, -1): ["caves_rime_hollow", Vector2i(12, 10)],
			Vector2i(8, -1): ["caves_cinder_way_in", Vector2i(3, 6)],
			Vector2i(7, -1): ["caves_cinder_hollow", Vector2i(20, 5)],
			Vector2i(3, 2): ["caves_glowworm_way_in", Vector2i(13, 8)],
			Vector2i(3, 3): ["caves_glowworm_hollow", Vector2i(10, 2)],
			Vector2i(8, -3): ["caves_ember_ridge", Vector2i(6, 6)],
			Vector2i(7, 1): ["caves_ossuary_ring", Vector2i(12, 10)],
			Vector2i(4, 2): ["caves_mural_lake", Vector2i(12, 7)],
		})
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# SHOTS_ONLY=regional_caves: the small caves off each region, and their ways in.
	if OS.get_environment("SHOTS_ONLY") == "regional_caves":
		GameState.give_item("frostfang_bow")
		await _room_shots(game, {
			Vector2i(0, 0): ["rcave_smugglers_way_in", Vector2i(4, 10)],
			Vector2i(0, 1): ["rcave_smugglers_cut", Vector2i(4, 2)],
			Vector2i(2, -3): ["rcave_rimefall_way_in", Vector2i(18, 3)],
			Vector2i(2, -4): ["rcave_rimefall_steps", Vector2i(18, 10)],
			Vector2i(1, -4): ["rcave_icefall_grotto", Vector2i(21, 6)],
			Vector2i(2, 3): ["rcave_wreckers_way_in", Vector2i(18, 10)],
			Vector2i(2, 4): ["rcave_wreckers_stair", Vector2i(17, 2)],
			Vector2i(3, 4): ["rcave_wreckers_hold", Vector2i(1, 9)],
			Vector2i(9, 1): ["rcave_saltpan_way_in", Vector2i(7, 9)],
			Vector2i(9, 2): ["rcave_saltpan_hollow", Vector2i(7, 2)],
			Vector2i(8, -3): ["rcave_clinker_way_in", Vector2i(11, 2)],
			Vector2i(8, -4): ["rcave_clinker_vault", Vector2i(11, 10)],
			Vector2i(6, -4): ["rcave_sailwind_way_in", Vector2i(12, 10)],
			Vector2i(6, -3): ["rcave_sailwind_gallery", Vector2i(3, 7)],
			Vector2i(3, -1): ["rcave_rootbound_way_in", Vector2i(2, 6)],
			Vector2i(2, -1): ["rcave_rootbound_hollow", Vector2i(21, 6)],
			Vector2i(6, 1): ["rcave_warren_way_in", Vector2i(8, 10)],
			Vector2i(6, 2): ["rcave_sporecap_warren", Vector2i(8, 2)],
		})
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# SHOTS_ONLY=life: overworld critters, reeds, and the newer foes per region.
	if OS.get_environment("SHOTS_ONLY") == "life":
		await _room_shots(game, {
			Vector2i(4, -3): ["life_windmere_galehawk", Vector2i(13, 4)],
			Vector2i(5, -3): ["life_windmere_grass", Vector2i(6, 8)],
			Vector2i(1, -2): ["life_frostspine_hares", Vector2i(12, 8)],
			Vector2i(8, 1): ["life_ossuary_lizards", Vector2i(11, 10)],
			Vector2i(8, -2): ["life_cinder_lizards", Vector2i(11, 11)],
			Vector2i(3, 0): ["life_brinewood_reeds", Vector2i(7, 6)],
			Vector2i(4, 1): ["life_gloamfen_reeds", Vector2i(11, 1)],
			Vector2i(2, 2): ["life_verge_shellback", Vector2i(6, 6)],
		})
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# SHOTS_ONLY=challenges: the optional challenges, each with a Breath Pearl.
	if OS.get_environment("SHOTS_ONLY") == "challenges":
		for item in ["kite_cloak", "glowmoth_lantern", "frostfang_bow", "tide_hook"]:
			GameState.give_item(item)
		await _room_shots(game, {
			Vector2i(8, 1): ["challenge_bone_ring_way_in", Vector2i(11, 10)],
			Vector2i(8, 2): ["challenge_bone_ring", Vector2i(11, 4)],
			Vector2i(6, -4): ["challenge_gullcry_way_in", Vector2i(19, 8)],
			Vector2i(7, -4): ["challenge_gullcry_stacks", Vector2i(2, 8)],
			Vector2i(5, 2): ["challenge_sink_way_in", Vector2i(11, 9)],
			Vector2i(5, 3): ["challenge_lampless_sink", Vector2i(11, 7)],
		})
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# SHOTS_ONLY=pacing: the small finds in rooms that had nothing else.
	if OS.get_environment("SHOTS_ONLY") == "pacing":
		await _pacing_shots(game)
		SaveManager.delete_save()
		SaveManager.restore_aside(TEST_SLOT, "testbackup")
		get_tree().quit(0)
		return

	# SHOTS_ONLY=kiln captures just the Kiln (for quick local runs).
	if OS.get_environment("SHOTS_ONLY") in ["hull", "kiln", "mire", "gale", "glacier", "belfry", "tomb", "maw", "extras", "goods", "echoes", "mantle", "lowe", "crucible", "turn", "mural", "ending", "shop", "dream", "ambience", "journal", "belfry_lowe", "tobin", "rowing", "choir", "ide", "liesl", "wick", "gully", "sorrel", "ottilie", "coralie", "lowe_after", "epilogue", "murmur_dace", "contrast"]:
		match OS.get_environment("SHOTS_ONLY"):
			"ambience":
				await _ambience_shots(game)
			"hull":
				await _hull_shots(game)
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
			"maw":
				await _maw_shots(game)
			"extras":
				await _extras_shots(game)
			"contrast":
				await _contrast_shots(game)
			"goods":
				await _goods_shots(game)
			"echoes":
				await _echoes_shots(game)
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
			"turn":
				game.queue_free()
				await _wait(0.2)
				await _turn_shots()
			"mural":
				game.queue_free()
				await _wait(0.2)
				await _mural_shots()
			"ending":
				game.queue_free()
				await _wait(0.2)
				await _ending_shots()
			"shop":
				game.queue_free()
				await _wait(0.2)
				await _shop_shots()
			"dream":
				game.queue_free()
				await _wait(0.2)
				await _dream_shots()
			"belfry_lowe":
				game.queue_free()
				await _wait(0.2)
				await _belfry_lowe_shots()
			"choir":
				game.queue_free()
				await _wait(0.2)
				await _choir_shots()
			"wick":
				game.queue_free()
				await _wait(0.2)
				await _wick_shots()
			"gully":
				game.queue_free()
				await _wait(0.2)
				await _gully_shots()
			"sorrel":
				game.queue_free()
				await _wait(0.2)
				await _sorrel_shots()
			"ottilie":
				game.queue_free()
				await _wait(0.2)
				await _ottilie_shots()
			"coralie":
				game.queue_free()
				await _wait(0.2)
				await _coralie_shots()
			"lowe_after":
				game.queue_free()
				await _wait(0.2)
				await _lowe_after_shots()
			"murmur_dace":
				game.queue_free()
				await _wait(0.2)
				await _murmur_dace_shots()
			"epilogue":
				game.queue_free()
				await _wait(0.2)
				await _epilogue_shots()
			"liesl":
				game.queue_free()
				await _wait(0.2)
				await _liesl_shots()
			"ide":
				game.queue_free()
				await _wait(0.2)
				await _ide_shots()
			"rowing":
				game.queue_free()
				await _wait(0.2)
				await _rowing_shots()
			"tobin":
				game.queue_free()
				await _wait(0.2)
				await _tobin_shots()
			"journal":
				game.queue_free()
				await _wait(0.2)
				await _journal_shots()
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
		Vector2i(1, 2): ["67_causeway_end", Vector2i(11, 1), Tide.Phase.LOW, "old_one_turned"],
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

	# 8i. The Maw.
	await _maw_shots(game)
	await _contrast_shots(game)

	# 8j. The optional rooms, and a dungeon map with its compass.
	await _extras_shots(game)
	await _goods_shots(game)

	# 8k. After the end: the echo stones, and a remembered fight.
	await _echoes_shots(game)

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
	await _turn_shots()
	await _mural_shots()
	await _ending_shots()
	await _shop_shots()
	await _dream_shots()
	await _journal_shots()
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


## SHOTS_ONLY=contrast: dungeon hazards with high contrast on (enemy shots,
## pits and lava edged, the Mire's dark a little lighter).
func _contrast_shots(game: Node) -> void:
	var contrast_was := Settings.high_contrast
	Settings.high_contrast = true
	var rooms := [
		[Vector2i(22, 8), "180_contrast_kiln_lava", Vector2i(11, 11)],
		[Vector2i(24, 8), "181_contrast_mire_dark", Vector2i(11, 11)],
		[Vector2i(36, 7), "182_contrast_knell_arms", Vector2i(11, 11)],
		[Vector2i(28, 7), "183_contrast_stormheron", Vector2i(11, 11)],
	]
	for entry in rooms:
		await _jump(game, entry[0], entry[2])
		game.player._invuln = 600.0
		await _wait(2.0)
		game.player._invuln = 0.0
		await _wait(0.1)
		await _capture(entry[1])
	game.player._invuln = 0.0
	Settings.high_contrast = contrast_was


func _hull_shots(game: Node) -> void:
	# coord: [file name, spawn tile]
	var rooms := {
		Vector2i(11, 9): ["30_hull_cargo_crate", Vector2i(8, 6)],
		Vector2i(12, 9): ["31_hull_rope_locker", Vector2i(3, 6)],
		Vector2i(10, 8): ["33_hull_listing_deck", Vector2i(21, 6)],
		Vector2i(9, 8): ["34_hull_captains_cabin", Vector2i(12, 7)],
		Vector2i(9, 10): ["35_hull_flooded_hold", Vector2i(12, 2)],
		Vector2i(11, 10): ["36_hull_brig", Vector2i(3, 6)],
		Vector2i(8, 9): ["36b_hull_keel", Vector2i(20, 6)],
		Vector2i(8, 8): ["36c_hull_sail_loft", Vector2i(12, 10)],
		Vector2i(12, 8): ["36d_hull_chain_locker", Vector2i(3, 6)],
	}
	for coord: Vector2i in rooms:
		var at := await _jump(game, coord, rooms[coord][1])
		for child in at.get_children():
			if child is Enemy:
				child.ai_enabled = false
		game.player._invuln = 0.0
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
				var waited := 0.0
				while not DialogueBox.is_open and waited < 10.0:
					await _wait(0.1)
					waited += 0.1
				await _wait(1.5)
				await _capture("41_tidebell_rung")
				await _skip_scene(game)


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
		Vector2i(23, 7): ["59b_kiln_chimney", Vector2i(2, 6)],
		Vector2i(23, 8): ["59c_kiln_annealing_oven", Vector2i(11, 1)],
		Vector2i(19, 9): ["59d_kiln_sprue", Vector2i(22, 6)],
	}
	for coord: Vector2i in rooms:
		var at := await _jump(game, coord, rooms[coord][1])
		# Everyone holds still for the picture.
		for child in at.get_children():
			if child is Enemy:
				child.ai_enabled = false
		game.player._invuln = 0.0
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
		[Vector2i(24, 7), "78b_mire_lych_walk", Vector2i(11, 10), true],
		[Vector2i(26, 7), "78c_mire_lantern_loft", Vector2i(19, 10), true],
		[Vector2i(24, 10), "78d_mire_sunken_crypt", Vector2i(11, 2), true],
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
		[Vector2i(27, 7), "97b_gale_bell_cage", Vector2i(3, 10)],
		[Vector2i(29, 10), "97c_gale_bellrope_walk", Vector2i(2, 6)],
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
		heron.mode = Stormheron.Mode.CROUCH
		heron._timer = 0.5
		await _wait(0.2)
		await _capture("179_stormheron_dive_tell")
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
		[Vector2i(41, 8), "140b_tomb_skull_choir", Vector2i(18, 11)],
		[Vector2i(39, 10), "140c_tomb_bone_orchard", Vector2i(21, 6)],
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
		regent.mode = HollowRegent.Mode.THROW
		await _wait(0.2)
		await _capture("176_regent_throw_tell")
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
		[Vector2i(38, 8), "126b_belfry_tolling_well", Vector2i(2, 6)],
		[Vector2i(35, 10), "126c_belfry_drowned_nave", Vector2i(21, 6)],
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
		# Its entrance (over by the time the room has faded in here).
		knell.ai_enabled = false
		knell.mode = Knell.Mode.INTRO
		knell._timer = 0.6
		await _wait(0.1)
		await _capture("177_knell_entrance")
		knell.ai_enabled = true
		await _wait(2.1)
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
		[Vector2i(33, 7), "111b_glacier_rime_vault", Vector2i(18, 11)],
		[Vector2i(33, 10), "111c_glacier_frost_ford", Vector2i(2, 6)],
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
		# Its entrance (mostly over by the time the room has faded in here).
		walrus.ai_enabled = false
		walrus.mode = Rimeback.Mode.INTRO
		walrus._timer = Rimeback.INTRO_TIME * 0.6
		await _wait(0.1)
		await _capture("178_rimeback_entrance")
		walrus.ai_enabled = true
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


## The ending: Vael stays as the Old One's keeper, dawn, and home.
func _ending_shots() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(44, 6), Vector2(11 * Room.TILE + 8, 10 * Room.TILE + 12))
	DreamingHeart.roll_credits = false
	var heart: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(heart)
	await _wait(0.6)
	GameState.set_flag(DreamingHeart.DEFEATED_FLAG)
	Events.game_finished.emit()
	var page := 0
	var dawn_taken := false
	var waited := 0.0
	while Cutscene.active and waited < 90.0:
		if DialogueBox.is_open:
			await _wait(2.6)
			if page == 0:
				await _capture("50_vael_at_the_heart")
			elif page == 1:
				await _capture("51_vael_keeps_watch")
			elif page == 3:
				await _capture("53_home")
			page += 1
			var box := _dialogue_box(heart)
			if box and DialogueBox.is_open:
				box.advance()
				box.advance()
			await _wait(0.3)
		elif page == 3 and not dawn_taken:
			await _wait(3.2)
			await _capture("52_dawn")
			dawn_taken = true
		else:
			await _wait(0.1)
			waited += 0.1
	DreamingHeart.roll_credits = true
	heart.queue_free()
	await _wait(0.2)


## The last mural in the Marrow Tomb: Dace, the carving close up.
func _mural_shots() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.TOMB_BOSS, Vector2(11 * Room.TILE + 8, 9 * Room.TILE + 12))
	var barrow: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(barrow)
	await _wait(0.5)
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
	for page in 4:
		while Cutscene.active and not DialogueBox.is_open:
			await _wait(0.1)
		await _wait(2.0)
		if page == 0:
			await _capture("48_dace_at_the_mural")
		elif page == 1:
			await _capture("49_the_last_mural")
		var box := _dialogue_box(barrow)
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		await _wait(0.2)
	await _skip_scene(barrow)
	barrow.queue_free()
	await _wait(0.2)


## The frozen journal: a page in the ice, then the vision of young Hessa
## and Vael in Rimeback's hall.
func _journal_shots() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(Vector2i(31, 10), Vector2(21 * Room.TILE + 8, 2 * Room.TILE + 14))
	var pond: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(pond)
	await _wait(0.5)
	pond.player.facing = Vector2.UP
	await _wait(0.2)
	await _capture("59_a_page_in_the_ice")
	pond.player.try_interact()
	await _wait(1.6)
	await _capture("60_young_vael_writes")
	var box := _dialogue_box(pond)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.05)
	pond.queue_free()
	await _wait(0.2)
	GameState.reset_new_game()
	GameState.set_flag(Rimeback.DEFEATED_FLAG)
	GameState.set_checkpoint(StoryDirector.GLACIER_BOSS, Vector2(5 * Room.TILE + 8, 2 * Room.TILE + 14))
	var hall: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(hall)
	await _wait(0.6)
	hall.player.facing = Vector2.UP
	await _wait(0.1)
	hall.player.try_interact()
	box = _dialogue_box(hall)
	await _wait(0.3)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	# The vision: both fade in, Hessa signals, Vael bows his head.
	await _wait(3.1)
	await _capture("61_the_vision_in_the_ice")
	await _wait(2.6)
	await _capture("62_vael_hears_it")
	await _skip_scene(hall)
	hall.queue_free()
	await _wait(0.2)


## Cutscene 14: Knell gone, Lowe comes up in the water and Wren hauls her
## out. She leaves without a word.
func _belfry_lowe_shots() -> void:
	GameState.reset_new_game()
	for item in ["divers_helm", "stonebreaker"]:
		GameState.give_item(item)
	GameState.set_checkpoint(StoryDirector.BELFRY_BOSS, Vector2(11 * Room.TILE + 8, 7 * Room.TILE + 8))
	var hall: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(hall)
	await _wait(0.6)
	hall.player._invuln = 600.0
	var knell: Knell = null
	for child in hall.current_room.get_children():
		if child is Knell:
			knell = child
	if knell == null:
		hall.queue_free()
		return
	await _wait(1.5)
	for a: Tentacle in knell.arms:
		a.dive_hit(Vector2.UP)
	await _wait(0.2)
	knell.bell.mallet_hit(Vector2.UP)
	await _wait(0.3)
	hall.player.global_position = hall.current_room.global_position + Vector2(11 * Room.TILE + 8, 7 * Room.TILE + 8)
	hall.player.facing = Vector2.UP
	knell._timer = 10.0
	while knell.hp > 0:
		knell._stun = 0.0
		knell._hits_this_daze = 0
		knell.take_hit(1, Vector2.UP)
	# Nothing left to hurt Wren; stop the blinking.
	hall.player._invuln = 0.0
	var lowe: ChoirFigure = null
	var shots := {"63_lowe_in_the_water": false, "64_hauled_out": false, "65_not_a_word": false, "66_the_long_way_out": false}
	var hauled_at := -1.0
	var time := 0.0
	while Cutscene.active and time < 40.0:
		await _wait(0.05)
		time += 0.05
		if lowe == null:
			for child in hall.current_room.get_children():
				if child is ChoirFigure:
					lowe = child
			continue
		if not is_instance_valid(lowe):
			break
		if not shots["63_lowe_in_the_water"] and lowe.struggling and hall.player.global_position.distance_to(hall.current_room.global_position + StoryDirector.WREN_REACHES) < 3.0:
			await _wait(0.3)
			shots["63_lowe_in_the_water"] = true
			await _capture("63_lowe_in_the_water")
		elif not shots["64_hauled_out"] and lowe.dripping and lowe.position.distance_to(StoryDirector.LOWE_HAULED) < 1.5:
			shots["64_hauled_out"] = true
			hauled_at = time
			await _capture("64_hauled_out")
		elif not shots["65_not_a_word"] and hauled_at > 0.0 and time - hauled_at > 2.6:
			shots["65_not_a_word"] = true
			await _capture("65_not_a_word")
		elif not shots["66_the_long_way_out"] and lowe.dripping and lowe.position.y > 11 * Room.TILE and lowe.position.x < 15 * Room.TILE:
			shots["66_the_long_way_out"] = true
			await _capture("66_the_long_way_out")
	hall.queue_free()
	await _wait(0.2)


## Cutscene 18: the Choir singing the Waking Song in Vael's hall.
func _choir_shots() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.MAW_VAEL, Vector2(11 * Room.TILE + 8, 11 * Room.TILE + 10))
	var hall: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(hall)
	await _wait(1.4)
	await _capture("75_the_waking_song")
	await _wait(3.4)
	await _capture("76_the_lamp_hushes_them")
	while Cutscene.active and not DialogueBox.is_open:
		await _wait(0.1)
	await _wait(0.8)
	await _capture("77_vael_turns")
	await _skip_scene(hall)
	await _wait(0.4)
	hall.queue_free()
	await _wait(0.2)


## Cutscene 17: Hessa rows Wren out to the Maw.
func _rowing_shots() -> void:
	GameState.reset_new_game()
	for flag in ["met_hessa", "seen_wayshell", StoryDirector.CONFESSION_FLAG, StoryDirector.TURNED_FLAG, StoryDirector.TOMB_BELL_FLAG]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(18 * Room.TILE + 8, 6 * Room.TILE + 10))
	var home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	await _wait(0.6)
	home.player.facing = Vector2.UP
	await _wait(0.05)
	home.player.try_interact()
	await _wait(1.6)
	await _capture("71_ill_row_you")
	var box := _dialogue_box(home)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	# Out at the point, in her boat beside the Old One's lip.
	while Cutscene.active and not DialogueBox.is_open:
		await _wait(0.1)
	await _wait(1.4)
	await _capture("72_off_lullaby_point")
	# Through her words to the lamp signals.
	var quiet := 0.0
	while Cutscene.active and quiet < 0.5:
		if DialogueBox.is_open:
			quiet = 0.0
			box.advance()
			box.advance()
		else:
			quiet += 0.1
		await _wait(0.1)
	await _wait(0.2)
	await _capture("73_ill_keep_the_lamp_lit")
	await _wait(5.2)
	await _capture("74_hessa_rows_home")
	await _skip_scene(home)
	home.queue_free()
	await _wait(0.2)


## Wick at Fenmouth, a dark memorial lantern out in the fen, and the
## Glowmoth Lantern lighting it.
func _wick_shots() -> void:
	GameState.reset_new_game()
	GameState.give_item("glowmoth_lantern")
	GameState.set_checkpoint(StoryDirector.FENMOUTH, Vector2(StoryDirector.WICK_AT.x - 14, StoryDirector.WICK_AT.y))
	var fen: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(fen)
	await _wait(0.6)
	fen.player.facing = Vector2.RIGHT
	await _wait(0.05)
	fen.player.try_interact()
	var box := _dialogue_box(fen)
	await _wait(2.4)
	await _capture("84_wick_counts_the_lanterns")
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	fen.queue_free()
	await _wait(0.2)
	var coord := Vector2i(5, 1)
	var tile: Vector2i = FenLantern.SPOTS[coord]
	var at := Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12)
	GameState.set_checkpoint(coord, at + Vector2(-34, 4))
	var reach: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(reach)
	await _wait(0.3)
	# The moths stay out of this one.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(1.7)
	reach.player.facing = Vector2.RIGHT
	reach.player._invuln = 0.0
	await _capture("85_a_lantern_gone_dark")
	reach.player.use_item("glowmoth_lantern")
	reach.player.global_position = reach.current_room.global_position + at + Vector2(-18, 4)
	await _wait(0.25)
	reach.player._invuln = 0.0
	await _capture("86_it_catches")
	reach.queue_free()
	await _wait(0.2)


## Ottilie at Still Cove, the float going under, and a rimefin landed.
func _ottilie_shots() -> void:
	GameState.reset_new_game()
	GameState.set_checkpoint(StoryDirector.STILL_COVE, StoryDirector.OTTILIE_AT + Vector2(0, -18))
	var cove: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(cove)
	await _wait(0.2)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(0.6)
	cove.player.facing = Vector2.DOWN
	await _wait(0.05)
	cove.player.try_interact()
	var box := _dialogue_box(cove)
	for i in 2:
		await _wait(0.4)
		box.advance()
		box.advance()
	await _wait(1.6)
	await _capture("93_ottilie_of_still_cove")
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	var room: Node2D = cove.current_room
	cove.player.global_position = room.global_position + StoryDirector.FISHING_HOLE_AT + Vector2(0, -18)
	cove.player.facing = Vector2.DOWN
	await _wait(0.3)
	var hole: FishingHole = room.get_children().filter(func(c: Node) -> bool: return c is FishingHole)[0]
	cove.player.try_interact()
	hole.bite_in = 0.6
	await _wait(0.72)
	cove.player._invuln = 0.0
	await _capture("94_the_float_goes_under")
	# A fresh cast for the catch.
	hole.state = FishingHole.State.IDLE
	cove.player.try_interact()
	hole.bite_in = 0.1
	await _wait(0.2)
	cove.player.try_interact()
	await _wait(0.25)
	await _capture("95_a_rimefin")
	cove.queue_free()
	await _wait(0.2)


## Coralie on Saltmarrow Shore hanging Wren's sea-glass, and her chime
## with all twelve strings filled.
func _coralie_shots() -> void:
	GameState.reset_new_game()
	GameState.set_flag("met_hessa")
	GameState.set_flag("coralie_asked")
	GameState.set_flag("coralie_glass", 4)
	GameState.give_item("sea_glass", 2, false)
	GameState.set_checkpoint(StoryDirector.SHORE, StoryDirector.CORALIE_AT + Vector2(0, -18))
	var shore: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(shore)
	await _wait(0.2)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(0.6)
	shore.player.facing = Vector2.DOWN
	await _wait(0.05)
	shore.player.try_interact()
	await _wait(2.2)
	await _capture("96_coralie_hangs_the_glass")
	var box := _dialogue_box(shore)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	GameState.set_flag("coralie_glass", SeaGlass.TOTAL)
	shore.player.global_position = shore.current_room.global_position + StoryDirector.CHIME_AT + Vector2(-26, 20)
	shore.player.facing = Vector2.RIGHT
	await _wait(1.6)
	await _capture("97_twelve_strings_ringing")
	shore.queue_free()
	await _wait(0.2)


## The credits after the ending, with the epilogue's scenes between the
## names: each one held mid-screen.
func _epilogue_shots() -> void:
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.ENDING_FLAG)
	var credits: Control = (load("res://scenes/credits.tscn") as PackedScene).instantiate()
	add_child(credits)
	await _wait(0.2)
	credits._leaving = true
	credits.set_process(false)
	# Where each scene sits in the roll, as _draw lays it out.
	var y: float = 216.0 + Art.TITLE_LOGO.get_height() + credits.GAP
	var names := ["epilogue_1_forge", "epilogue_2_lanterns", "epilogue_3_doorstep", "epilogue_4_rope", "epilogue_5_cliff"]
	for s in credits._vignette_count():
		y += credits.LINE * (credits.SECTIONS[s] as Array).size() + credits.GAP
		credits._scroll = y - 216.0 + 80.0
		credits._time = 3.0 + s
		credits.queue_redraw()
		await _wait(0.1)
		await _capture(names[s])
		y += CreditsVignettes.SIZE.y + CreditsVignettes.GAP
	credits.queue_free()
	await _wait(0.2)
	GameState.reset_new_game()


## Murmur tending Fenmouth's lanterns, and Mother Dace by the last mural.
func _murmur_dace_shots() -> void:
	for spot in [[StoryDirector.FENMOUTH, StoryDirector.MURMUR_FEN_AT, [StoryDirector.CALF_FLAG], "epilogue_7_murmur_at_fenmouth"],
			[StoryDirector.TOMB_BOSS, StoryDirector.DACE_AFTER_AT, [HollowRegent.DEFEATED_FLAG, StoryDirector.MURAL_FLAG, StoryDirector.ENDING_FLAG, StoryDirector.DREAM_FLAG], "epilogue_8_dace_by_the_mural"]]:
		GameState.reset_new_game()
		for flag: String in spot[2]:
			GameState.set_flag(flag)
		GameState.set_checkpoint(spot[0], spot[1] + Vector2(0, 20))
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		await _wait(0.2)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.queue_free()
		# A dungeon opens on its name card: let it fade.
		await _wait(3.0)
		game.player.facing = Vector2.UP
		await _wait(0.05)
		game.player.try_interact()
		await _wait(2.4)
		await _capture(spot[3])
		var box := _dialogue_box(game)
		while box and DialogueBox.is_open:
			box.advance()
			box.advance()
			await _wait(0.1)
		game.queue_free()
		await _wait(0.2)


## Sister Lowe alone on Lullaby Point after the ending, watching the Maw.
func _lowe_after_shots() -> void:
	GameState.reset_new_game()
	for flag in [StoryDirector.TOMB_BELL_FLAG, StoryDirector.ROWED_FLAG, StoryDirector.ENDING_FLAG, StoryDirector.DREAM_FLAG]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.LULLABY_POINT, StoryDirector.LOWE_AT + Vector2(-20, 0))
	var point: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(point)
	await _wait(0.2)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(0.6)
	point.player.facing = Vector2.RIGHT
	await _wait(0.05)
	point.player.try_interact()
	await _wait(2.4)
	await _capture("epilogue_6_lowe_keeps_watch")
	point.queue_free()
	await _wait(0.2)


## Captain Sorrel at Gullwatch Steps, her kite racing Wren across the
## water, and Wren first to the far post.
func _sorrel_shots() -> void:
	GameState.reset_new_game()
	GameState.give_item("kite_cloak", 1, false)
	GameState.set_checkpoint(StoryDirector.GULLWATCH_STEPS, StoryDirector.SORREL_AT + Vector2(0, 18))
	var steps: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(steps)
	await _wait(0.2)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(0.6)
	steps.player.facing = Vector2.UP
	await _wait(0.05)
	steps.player.try_interact()
	var box := _dialogue_box(steps)
	await _wait(0.4)
	box.advance()
	box.advance()
	await _wait(1.6)
	await _capture("90_captain_sorrel_of_gullwatch")
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	var room: Node2D = steps.current_room
	steps.player.global_position = room.global_position + Vector2(19 * 16 + 8, 4 * 16 + 6)
	steps.player.facing = Vector2.DOWN
	await _wait(0.5)
	steps.player._invuln = 0.0
	steps.player.use_item("kite_cloak")
	await _wait(0.4)
	await _capture("91_racing_sorrels_kite")
	await _wait(0.8)
	steps.player.global_position = room.global_position + StoryDirector.KITE_POST_AT + Vector2(-12, 10)
	steps.player.facing = Vector2.RIGHT
	await _wait(1.4)
	steps.player._invuln = 0.0
	await _capture("92_first_to_the_far_post")
	steps.queue_free()
	await _wait(0.2)


## Gully dozing by the Lantern Wake's figurehead on Wreck Strand, waking
## to talk, and his strongbox hauled out of the pool on the Tide Hook.
func _gully_shots() -> void:
	GameState.reset_new_game()
	GameState.give_item("tide_hook", 1, false)
	GameState.set_checkpoint(StoryDirector.WRECK_STRAND, StoryDirector.GULLY_AT + Vector2(-90, 60))
	var strand: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(strand)
	await _wait(0.2)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait(1.0)
	strand.player.facing = Vector2.LEFT
	strand.player._invuln = 0.0
	await _capture("87_gully_dozing_by_the_figurehead")
	strand.player.global_position = strand.current_room.global_position + StoryDirector.GULLY_AT + Vector2(0, 18)
	strand.player.facing = Vector2.UP
	await _wait(0.3)
	strand.player.try_interact()
	var box := _dialogue_box(strand)
	for i in 3:
		await _wait(0.4)
		box.advance()
		box.advance()
	await _wait(1.6)
	await _capture("88_gully_and_the_lantern_wake")
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	strand.player.global_position = strand.current_room.global_position + Vector2(9 * 16 + 8, 4 * 16 + 10)
	strand.player.facing = Vector2.RIGHT
	await _wait(0.5)
	strand.player._invuln = 0.0
	strand.player.use_item("tide_hook")
	await _wait(0.24)
	await _capture("89_hauling_the_strongbox")
	await _wait(1.5)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	strand.queue_free()
	await _wait(0.2)


## Liesl in Drowned Lane, her great-grandmother's door bell glinting on
## Belfry Square's flats at low tide, and the bell hung back by the door.
func _liesl_shots() -> void:
	GameState.reset_new_game()
	var was := Tide.offset
	Tide.offset = Tide.offset_for(Tide.Phase.HIGH, 0.5)
	GameState.set_checkpoint(StoryDirector.DROWNED_LANE, Vector2(StoryDirector.LIESL_AT.x - 14, StoryDirector.LIESL_AT.y))
	var lane: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(lane)
	await _wait(0.6)
	lane.player.facing = Vector2.RIGHT
	await _wait(0.05)
	lane.player.try_interact()
	var box := _dialogue_box(lane)
	await _wait(0.4)
	box.advance()
	box.advance()
	await _wait(1.6)
	await _capture("81_liesl_of_drowned_lane")
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	lane.queue_free()
	await _wait(0.2)
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 1.0)
	GameState.set_checkpoint(StoryDirector.BELFRY_SQUARE, StoryDirector.DOORBELL_LOST_AT + Vector2(-30, -6))
	var square: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(square)
	await _wait(1.2)
	square.player.facing = Vector2.RIGHT
	square.player._invuln = 0.0
	await _capture("82_a_glint_at_low_tide")
	square.queue_free()
	await _wait(0.2)
	for flag in ["found_doorbell", "liesl_bell_hung"]:
		GameState.set_flag(flag)
	# Just as the water goes out, her bell rings.
	Tide.offset = Tide.offset_for(Tide.Phase.FALLING, Tide.FALLING_TIME - 0.6)
	GameState.set_checkpoint(StoryDirector.DROWNED_LANE, StoryDirector.DOORBELL_HUNG_AT + Vector2(26, -6))
	lane = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(lane)
	await _wait(1.0)
	lane.player.facing = Vector2.RIGHT
	lane.player._invuln = 0.0
	await _capture("83_her_bell_rings_again")
	lane.queue_free()
	await _wait(0.2)
	Tide.offset = was


## Ide the ferrywoman at Causeway End: her offer, the far landing, and the
## hand bell that calls her back over.
func _ide_shots() -> void:
	GameState.reset_new_game()
	for flag in [StoryDirector.TURNED_FLAG, "tidebell_belfry"]:
		GameState.set_flag(flag)
	GameState.set_checkpoint(StoryDirector.CAUSEWAY_END, Vector2(StoryDirector.IDE_AT.x - 14, StoryDirector.IDE_AT.y))
	var shore: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(shore)
	await _wait(0.6)
	shore.player.facing = Vector2.RIGHT
	await _wait(0.05)
	shore.player.try_interact()
	await _wait(1.6)
	await _capture("78_ide_at_causeway_end")
	var box := _dialogue_box(shore)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.1)
	# Over the channel: she lifts a hand from the oars before rowing home.
	var landing: Vector2 = shore.current_room.global_position + StoryDirector.WREN_SOUTH
	while Cutscene.active and shore.player.global_position.distance_to(landing) > 4.0:
		await _wait(0.1)
	await _wait(1.7)
	shore.player._invuln = 0.0
	await _capture("79_the_far_landing")
	await _skip_scene(shore)
	shore.queue_free()
	await _wait(0.2)
	# Back from the south, the bell on its post calls her over.
	GameState.set_checkpoint(StoryDirector.CAUSEWAY_END, StoryDirector.FERRY_BELL_AT + Vector2(10, 10))
	var south: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(south)
	await _wait(0.6)
	south.player.facing = Vector2.UP
	await _wait(0.05)
	south.player.try_interact()
	await _wait(2.0)
	south.player._invuln = 0.0
	await _capture("80_ring_for_ide")
	await _skip_scene(south)
	south.queue_free()
	await _wait(0.2)


## Cutscene 16: Tobin on Skull Rise, then home on the dock with Dunstan.
func _tobin_shots() -> void:
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.TOMB_BELL_FLAG)
	GameState.set_checkpoint(StoryDirector.SKULL_RISE, Vector2(12 * Room.TILE + 8, 7 * Room.TILE + 10))
	var rise: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(rise)
	while Cutscene.active and not DialogueBox.is_open:
		await _wait(0.1)
	await _wait(0.6)
	await _capture("67_tobin_on_the_dunes")
	await _skip_scene(rise)
	rise.queue_free()
	await _wait(0.2)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(12 * Room.TILE + 8, 11 * Room.TILE + 10))
	var home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	while Cutscene.active and not DialogueBox.is_open:
		await _wait(0.1)
	await _wait(0.6)
	await _capture("68_dunstan_finds_his_words")
	var box := _dialogue_box(home)
	for i in 2:
		box.advance()
		box.advance()
		await _wait(0.6)
	await _capture("69_every_week")
	await _skip_scene(home)
	await _wait(0.6)
	await _capture("70_tobin_home")
	home.queue_free()
	await _wait(0.2)


## Home after the credits: the lighthouse turns out to sea, towards the Maw, and Hessa
## felt the Old One dream.
func _dream_shots() -> void:
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.ENDING_FLAG)
	# Where the ending leaves Wren: below Hessa.
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(18 * Room.TILE + 8, 6 * Room.TILE + 12))
	var home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	while Cutscene.active and not DialogueBox.is_open:
		await _wait(0.1)
	await _wait(1.5)
	await _capture("57_the_old_one_dreams")
	await _skip_scene(home)
	await _wait(1.0)
	await _capture("58_the_beam_points_to_sea")
	home.queue_free()
	await _wait(0.2)


## Marlo Pike's stall in Saltmarrow: Marlo across the counter, then his wares.
func _shop_shots() -> void:
	GameState.reset_new_game()
	GameState.set_flag("tidebell_hull")
	GameState.give_item("glint", 45, false)
	GameState.give_item("jar", 2, false)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, GameState.NO_POSITION)
	var village: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(village)
	await _wait(0.5)
	var stall := get_tree().get_first_node_in_group("market_stall") as MarketStall
	village.player.global_position = stall.global_position + Vector2(-6, 14)
	village.player.facing = Vector2.UP
	await _wait(0.4)
	await _capture("54_marlos_stall")
	village.player.try_interact()
	await _wait(1.2)
	await _capture("55_marlo_pike")
	var box := _dialogue_box(village)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.05)
	await _wait(0.4)
	var menu := get_tree().get_first_node_in_group("shop_menu") as ShopMenu
	if menu:
		menu.buy(1)
		menu._cursor = 0
		await _wait(0.15)
		await _capture("56_pikes_wares")
		menu.close()
	await _wait(0.2)
	while box and DialogueBox.is_open:
		box.advance()
		box.advance()
		await _wait(0.05)
	village.queue_free()
	await _wait(0.2)


## The Old One turns after the Storm Bell rings, then Hessa's confession at
## home.
func _turn_shots() -> void:
	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.VAEL_FLAG)
	GameState.set_flag(Stormheron.DEFEATED_FLAG)
	GameState.set_checkpoint(StoryDirector.GALE_BOSS, Vector2(11 * Room.TILE + 8, 9 * Room.TILE + 12))
	var crown: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(crown)
	await _wait(3.5)
	for child in crown.current_room.get_children():
		if child is Tidebell:
			crown.player.global_position = child.global_position + Vector2(0, 22)
			await _wait(0.1)
			child.interact()
	await _wait(0.6)
	await _capture("47_bell_phrase")
	await _wait(0.65)
	await _capture("47b_phrase_reaches_wren")
	var waited := 0.0
	while waited < 20.0 and not crown.current_room.get_children().any(func(c: Node) -> bool: return c is OldOneShadow):
		var box := _dialogue_box(crown)
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		await _wait(0.1)
		waited += 0.1
	await _wait(1.4)
	await _capture("45_old_one_turns")
	await _wait(1.6)
	await _capture("45b_old_one_rolls_on")
	await _skip_scene(crown)
	crown.queue_free()
	await _wait(0.2)

	GameState.reset_new_game()
	GameState.set_flag(StoryDirector.TURNED_FLAG)
	GameState.set_checkpoint(StoryDirector.SALTMARROW, Vector2(9 * Room.TILE + 8, 9 * Room.TILE + 8))
	var home: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(home)
	for page in 5:
		while Cutscene.active and not DialogueBox.is_open:
			await _wait(0.1)
		await _wait(1.2)
		if page == 0:
			await _capture("46_hessas_confession")
		elif page == 4:
			await _wait(1.4)
			await _capture("46b_dont_hate_him")
		var box := _dialogue_box(home)
		if box and DialogueBox.is_open:
			box.advance()
			box.advance()
		await _wait(0.2)
	await _skip_scene(home)
	home.queue_free()
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


## Shop goods and glints in Saltmarrow's pot room: a lit puffer bomb, its
## burst, a pot breaking, coins on the grass, a tonic drunk.
func _goods_shots(game: Node) -> void:
	seed(3)
	var room := await _jump(game, Vector2i(0, -1), Vector2i(12, 7))
	var wren: Player = game.player
	wren._invuln = 600.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	var at := wren.position - room.position
	Glint.drop(room, at + Vector2(-34, 6), 1)
	Glint.drop(room, at + Vector2(-26, 14), 5)
	Glint.drop(room, at + Vector2(-42, 18), 20)
	wren.facing = Vector2.RIGHT
	GameState.give_item("puffer_bombs", 5, false)
	wren.use_item("puffer_bombs")
	await _wait(1.1)
	wren._invuln = 0.0
	await _capture("170_puffer_bomb_lit")
	# Wren stepped back, as they should.
	wren.global_position -= wren.facing * 40.0
	var bomb: PufferBomb = get_tree().get_first_node_in_group("puffer_bombs")
	if bomb:
		bomb.burst()
	await _wait(0.08)
	wren._invuln = 0.0
	await _capture("171_puffer_bomb_burst")
	await _wait(0.6)
	for prop in room.get_children():
		if prop is Prop and prop.kind == "o":
			wren.global_position = prop.global_position + Vector2(30, 0)
			prop.smash()
			break
	await _wait(0.12)
	wren._invuln = 0.0
	await _capture("172_pot_breaks")
	room.cut_plants(Rect2(room.global_position, Room.SIZE))
	await _wait(0.15)
	wren._invuln = 0.0
	await _capture("173_grass_cut")
	while GameState.jars.is_empty():
		GameState.give_item("jar", 1, false)
	GameState.jars[0] = Items.JAR_POTION
	GameState.bubbles = 1
	wren.drink_potion()
	await _wait(0.3)
	wren._invuln = 0.0
	await _capture("174_tonic_drunk")
	wren._invuln = 0.0
	randomize()


## SHOTS_ONLY=ambience: the overworld's ambient life, region by region.
func _ambience_shots(game: Node) -> void:
	var shots := {
		Vector2i(0, 0): ["amb_saltmarrow_shore", Vector2i(5, 7)],
		Vector2i(3, 0): ["amb_brinewood_edge", Vector2i(7, 6)],
		Vector2i(4, 1): ["amb_fenmouth", Vector2i(11, 1)],
		Vector2i(8, -2): ["amb_cinder_flats", Vector2i(11, 11)],
		Vector2i(7, 0): ["amb_bleached_strand", Vector2i(11, 11)],
		Vector2i(5, -3): ["amb_gale_flats", Vector2i(13, 4)],
		Vector2i(0, -1): ["amb_saltmarrow_village", Vector2i(5, 11)],
		Vector2i(0, -3): ["amb_glacier_foot", Vector2i(11, 2)],
		# The side areas.
		Vector2i(1, -1): ["amb_rime_hollow", Vector2i(11, 1)],
		Vector2i(7, -1): ["amb_cinder_hollow", Vector2i(21, 5)],
		Vector2i(3, 3): ["amb_glowworm_hollow", Vector2i(9, 1)],
	}
	for coord: Vector2i in shots:
		var tile: Vector2i = shots[coord][1]
		GameState.set_checkpoint(coord, Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12))
		SaveManager.save_game()
		game.respawn()
		await _wait(2.2)
		await _capture(shots[coord][0])


## SHOTS_ONLY=seaglass: a few of the twelve pieces where they lie.
func _sea_glass_shots(game: Node) -> void:
	var shots := {
		Vector2i(4, -1): ["glass_lantern_walk", Vector2i(9, 5)],
		Vector2i(5, -2): ["glass_old_stilts", Vector2i(8, 9)],
		Vector2i(9, -1): ["glass_scorched_pass", Vector2i(17, 5)],
		Vector2i(6, 1): ["glass_lumen_pool", Vector2i(9, 4)],
		Vector2i(1, 1): ["glass_wreck", Vector2i(9, 10)],
		Vector2i(9, -2): ["glass_slag_fields", Vector2i(12, 2)],
	}
	for coord: Vector2i in shots:
		var tile: Vector2i = shots[coord][1]
		GameState.set_checkpoint(coord, Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12))
		SaveManager.save_game()
		game.respawn()
		await _wait(2.2)
		await _capture(shots[coord][0])
	# The overworld map partway through: Saltmarrow, Brinewood and the
	# Gloamfen walked, the rest under fog; doors marked, and a twinkle where
	# sea-glass still lies.
	for x in range(0, 7):
		for y in range(-2, 3):
			if RoomInfo.has_room(Vector2i(x, y)) and str(RoomInfo.get_room(Vector2i(x, y))["dungeon"]) == "":
				GameState.mark_seen(Vector2i(x, y))
	GameState.set_flag("sea_glass_1_1")
	await _jump(game, Vector2i(4, -1), Vector2i(9, 5))
	var pause: PauseMenu = null
	for child in game.get_children():
		if child is PauseMenu:
			pause = child
	if pause:
		pause.open(PauseMenu.Tab.MAP)
		await _wait(0.5)
		await _capture("glass_overworld_map")
		pause.close()
		await _wait(0.1)


func _ebb_shots(game: Node) -> void:
	GameState.set_flag(Tide.TURNED_FLAG)
	Tide.offset = Tide.offset_for(Tide.Phase.LOW, 0.5)
	var shots := [
		[Vector2i(1, 3), "ebb_belfry_square_breathing", Vector2i(12, 9), ""],
		[Vector2i(1, 3), "ebb_belfry_square_held_out", Vector2i(12, 9), "low"],
		[Vector2i(2, 3), "ebb_weir_steps_held_out", Vector2i(13, 9), "low"],
		[Vector2i(1, 4), "ebb_shelf", Vector2i(8, 4), "low"],
		[Vector2i(0, 4), "ebb_grotto", Vector2i(16, 6), "low"],
	]
	for shot: Array in shots:
		GameState.set_flag(Tide.HELD_FLAG, shot[3] != "")
		GameState.clear_flag(Tide.HELD_IN_FLAG)
		var tile: Vector2i = shot[2]
		GameState.set_checkpoint(shot[0], Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12))
		SaveManager.save_game()
		game.respawn()
		game.player._invuln = 600.0
		await _wait(2.2)
		await _capture(shot[1])
	Tide.offset = 0.0


func _pacing_shots(game: Node) -> void:
	var shots := {
		Vector2i(2, 0): ["pacing_barnacle_wall", Vector2i(8, 8)],
		Vector2i(2, 2): ["pacing_wrack_shore", Vector2i(5, 9)],
		Vector2i(3, 0): ["pacing_brinewood_edge", Vector2i(6, 6)],
		Vector2i(3, -2): ["pacing_hollow_bole", Vector2i(12, 6)],
		Vector2i(3, 2): ["pacing_witherroot", Vector2i(15, 6)],
		Vector2i(4, -3): ["pacing_mill_row", Vector2i(12, 7)],
		Vector2i(4, -2): ["pacing_mothlight", Vector2i(12, 11)],
		Vector2i(5, 1): ["pacing_stillwater", Vector2i(8, 3)],
		Vector2i(6, -2): ["pacing_brine_spring", Vector2i(16, 9)],
		Vector2i(6, -1): ["pacing_rootmaze", Vector2i(21, 2)],
		Vector2i(6, 0): ["pacing_tangle_shore", Vector2i(12, 3)],
		Vector2i(7, -2): ["pacing_ashfall_gate", Vector2i(5, 6)],
		Vector2i(7, 0): ["pacing_bleached_strand", Vector2i(16, 5)],
		Vector2i(8, -2): ["pacing_cinder_flats", Vector2i(5, 3)],
		Vector2i(8, -1): ["pacing_geyser_basin", Vector2i(16, 11)],
		Vector2i(8, 1): ["pacing_vertebra_road", Vector2i(8, 7)],
	}
	await _room_shots(game, shots)


## One shot per room: Wren set down on the given tile.
func _room_shots(game: Node, shots: Dictionary) -> void:
	for coord: Vector2i in shots:
		var tile: Vector2i = shots[coord][1]
		GameState.set_checkpoint(coord, Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12))
		SaveManager.save_game()
		game.respawn()
		game.player._invuln = 600.0
		await _wait(2.2)
		await _capture(shots[coord][0])


func _echoes_shots(game: Node) -> void:
	for flag in ["boss_hull", "boss_kiln", "boss_mire", "boss_gale", "boss_glacier", "boss_belfry", "boss_tomb", "boss_maw_vael", "the_end", StoryDirector.ENDING_FLAG]:
		GameState.set_flag(flag)
	GameState.clear_flag(EchoTrial.WOKEN_FLAG)
	var room := await _jump(game, EchoTrial.HEART_ROOM, Vector2i(11, 11))
	game.player._invuln = 600.0
	# The stones rising, then all eight.
	await _wait(1.0 + EchoHall.RISE_GAP * 3)
	await _capture("163_echo_stones_rising")
	await _wait(EchoHall.RISE_GAP * 5 + 1.5)
	GameState.set_flag(EchoTrial.cleared_flag("kiln"))
	await _capture("164_echo_stones")
	# Into the Matriarch's echo.
	for stone in room.get_children():
		if stone is EchoStone and stone.id == "hull":
			stone.activate()
	await _wait(2.0)
	game.player._invuln = 600.0
	await _capture("165_echo_matriarch")
	EchoTrial.end()


func _extras_shots(game: Node) -> void:
	for item in ["echo_horn", "divers_helm", "kite_cloak", "glowmoth_lantern", "tide_hook"]:
		GameState.give_item(item)
	MawBreath.elapsed = 0.0
	var rooms := [
		[Vector2i(37, 10), "159_belfry_undercroft", Vector2i(20, 1)],
		[Vector2i(41, 10), "160_tomb_ossuary", Vector2i(19, 1)],
		[Vector2i(45, 10), "161_maw_tidewell", Vector2i(20, 1)],
	]
	for shot: Array in rooms:
		var at := await _jump(game, shot[0], shot[2])
		game.player._invuln = 600.0
		for child in at.get_children():
			if child is Enemy:
				child.ai_enabled = false
		MawBreath.elapsed = 0.0
		await _wait(0.5)
		game.player._invuln = 0.0
		await _wait(0.05)
		await _capture(shot[1])
	# The Marrow Tomb's map, with its map and compass: every room, and the
	# chests and boss not yet found (earlier shots may have opened some).
	await _jump(game, Vector2i(40, 10), Vector2i(11, 6))
	GameState.give_item(Items.dungeon_item("tomb", "map"))
	GameState.give_item(Items.dungeon_item("tomb", "compass"))
	var pause: PauseMenu = null
	for child in game.get_children():
		if child is PauseMenu:
			pause = child
	if pause:
		pause.open(PauseMenu.Tab.MAP)
		await _wait(0.4)
		await _capture("162_tomb_map_compass")
		pause.close()
		await _wait(0.1)


func _maw_shots(game: Node) -> void:
	for item in ["echo_horn", "divers_helm", "kite_cloak", "glowmoth_lantern", "tide_hook"]:
		GameState.give_item(item)
	DreamingHeart.roll_credits = false
	# The choir's own scene has its shots (SHOTS_ONLY=choir).
	GameState.set_flag(StoryDirector.CHOIR_FLAG)
	MawBreath.elapsed = 0.0
	# coord: [file name, spawn tile]
	var rooms := [
		[Vector2i(44, 10), "148_maw_throat", Vector2i(11, 10)],
		[Vector2i(44, 9), "149_maw_palate", Vector2i(11, 11)],
		[Vector2i(43, 9), "150_maw_hollows", Vector2i(21, 6)],
		[Vector2i(45, 9), "151_maw_dim_gallery", Vector2i(2, 6)],
		[Vector2i(44, 8), "152_maw_veins", Vector2i(11, 11)],
		[Vector2i(45, 8), "152b_maw_lung", Vector2i(17, 11)],
		[Vector2i(43, 10), "152c_maw_gullet", Vector2i(21, 10)],
	]
	for shot: Array in rooms:
		var at := await _jump(game, shot[0], shot[2])
		game.player._invuln = 600.0
		for child in at.get_children():
			if child is Enemy:
				child.ai_enabled = false
				# Wren lands beside the Palate's and the Veins' foes, who hit hard.
				child._contact.active = false
		GameState.refill()
		MawBreath.elapsed = 0.0
		await _wait(0.5)
		game.player._invuln = 0.0
		await _wait(0.05)
		await _capture(shot[1])

	# The Old One breathes in: the Throat's palate floor floods.
	var room := await _jump(game, Vector2i(44, 10), Vector2i(11, 10))
	game.player._invuln = 600.0
	MawBreath.elapsed = MawBreath.OUT_TIME + 0.9
	await _wait(0.3)
	await _capture("153_maw_breath_tell")
	MawBreath.elapsed = MawBreath.OUT_TIME + MawBreath.IN_TELL_TIME + 0.5
	await _wait(0.4)
	game.player._invuln = 0.0
	await _capture("154_maw_breath_flooded")
	# A Gumleech rears out of the flood at Wren, mouth open.
	for child in room.get_children():
		if child is Gumleech:
			game.player.global_position = child.global_position + Vector2(10, 34)
			child.ai_enabled = false
			child.aim = Vector2.DOWN
			child._set_mode(Gumleech.Mode.RISE)
	await _wait(0.2)
	await _capture("175_maw_gumleech_rearing")
	MawBreath.elapsed = 0.0

	# Cantor Vael and his singers.
	room = await _jump(game, Vector2i(44, 7), Vector2i(11, 10))
	game.player._invuln = 600.0
	await _wait(0.3)
	await _close_dialogue(game)
	await _wait(2.6)
	await _capture("155_vael_sings")
	var vael: CantorVael = null
	for child in room.get_children():
		if child is CantorVael:
			vael = child
	if vael:
		vael.ai_enabled = false
		var wave := ChantWave.new()
		room.add_child(wave)
		wave.global_position = game.player.global_position + Vector2(-20, -30)
		await _wait(ChantWave.TELL_TIME + 0.7)
		await _capture("156_choir_chant_wave")

	# The Dreaming Heart, an echo, and a bell waiting for the beat.
	room = await _jump(game, Vector2i(44, 6), Vector2i(11, 11))
	game.player._invuln = 600.0
	await _wait(DreamingHeart.WAKE_TIME + 1.5)
	game.player._invuln = 0.0
	await _capture("157_dreaming_heart")
	game.player._invuln = 600.0
	var heart: DreamingHeart = null
	for child in room.get_children():
		if child is DreamingHeart:
			heart = child
	if heart:
		for i in 4:
			var bell: HeartBell = null
			for child in room.get_children():
				if child is HeartBell and not child.rung:
					bell = child
			if bell == null:
				break
			while heart.off_beat() > 0.05:
				await get_tree().physics_frame
			bell.take_hit(1, Vector2.UP)
			await _wait(DreamingHeart.CALM_TIME + 0.2)
		await _wait(1.0)
		game.player._invuln = 0.0
		await _capture("158_heart_glacier_echo")
	game.player._invuln = 600.0
	DreamingHeart.roll_credits = true
	# Out of the fight before the shots that follow.
	await _jump(game, Vector2i(44, 9), Vector2i(11, 11))


## Pages through whatever dialogue is open.
func _close_dialogue(game: Node) -> void:
	for child in game.get_children():
		if child is DialogueBox:
			var guard := 0
			while DialogueBox.is_open and guard < 40:
				child.advance()
				child.advance()
				guard += 1
				await _wait(0.05)
