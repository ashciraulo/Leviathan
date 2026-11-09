extends Node
## Captures the menu screens (satchel, map, options, controls, journey,
## file select) with a mid-game file. Run like tests/screenshots.tscn:
##     xvfb-run godot --rendering-driver opengl3 res://tests/menu_screenshots.tscn
## Uses save slots 0-2 of a separate test folder, never real saves.
##
## With the environment variable LEVIATHAN_PSEUDO=1 every string is
## stretched by 40% and bracketed (Godot's pseudolocalisation), and the
## files are named pseudo_*.png: a quick check that longer translations
## still fit their boxes.

const SCALE := 4

var _out_dir := ""
var _pseudo := false


func _ready() -> void:
	if OS.get_environment("LEVIATHAN_PSEUDO") == "1":
		_pseudo = true
		ProjectSettings.set_setting("internationalization/pseudolocalization/replace_with_accents", false)
		ProjectSettings.set_setting("internationalization/pseudolocalization/double_vowels", false)
		ProjectSettings.set_setting("internationalization/pseudolocalization/fake_bidi", false)
		ProjectSettings.set_setting("internationalization/pseudolocalization/override", false)
		ProjectSettings.set_setting("internationalization/pseudolocalization/expansion_ratio", 0.4)
		ProjectSettings.set_setting("internationalization/pseudolocalization/prefix", "[")
		ProjectSettings.set_setting("internationalization/pseudolocalization/suffix", "]")
		TranslationServer.pseudolocalization_enabled = true
		TranslationServer.reload_pseudolocalization()
	_out_dir = ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_backup_saves()

	# A file part-way through the game.
	_mid_game_state()
	SaveManager.current_slot = 0
	SaveManager.save_game()

	# Title, then the file select with one new file, a copy, and an empty one.
	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	add_child(title)
	await _wait(1.6)
	await _capture("30_title_menu")
	GameState.reset_new_game()
	GameState.play_time = 760.0
	SaveManager.current_slot = 1
	SaveManager.save_game()
	title._show_page(title._files)
	await _wait(0.3)
	await _capture("31_file_select")
	title.queue_free()

	# In game, at Saltmarrow Shore.
	SaveManager.current_slot = 0
	SaveManager.load_game()
	GameState.set_checkpoint(Vector2i(1, 0), GameState.NO_POSITION)
	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await _wait(0.8)
	await _capture("32_hud_item_slots")
	var pause: PauseMenu = null
	for child in game.get_children():
		if child is PauseMenu:
			pause = child
	pause.open(PauseMenu.Tab.SATCHEL)
	await _wait(0.2)
	await _capture("33_satchel")
	_press(pause, "move_right")
	_press(pause, "move_right")
	_press(pause, "move_right")
	_press(pause, "move_right")
	await _wait(0.1)
	await _capture("34_satchel_gear")
	pause.show_tab(PauseMenu.Tab.MAP)
	_press(pause, "move_left")
	await _wait(0.5)
	await _capture("35_map")
	pause.show_tab(PauseMenu.Tab.OPTIONS)
	for i in 5:
		_press(pause, "move_down")
	await _wait(0.2)
	await _capture("36_options")
	for i in 20:
		_press(pause, "move_down")
	_press(pause, "interact")
	_press(pause, "move_down")
	_press(pause, "move_down")
	await _wait(0.2)
	await _capture("37_controls")
	pause.show_tab(PauseMenu.Tab.JOURNEY)
	await _wait(0.2)
	await _capture("38_journey")
	pause.close()

	# Inside the Rotting Hull, with its map and compass.
	GameState.give_item(Items.dungeon_item("hull", "map"), 1, false)
	GameState.give_item(Items.dungeon_item("hull", "compass"), 1, false)
	GameState.set_checkpoint(Vector2i(10, 10), Vector2(11 * Room.TILE + 8, 10 * Room.TILE + 12))
	SaveManager.save_game()
	game.respawn()
	await _wait(2.2)
	pause.open(PauseMenu.Tab.MAP)
	await _wait(0.5)
	await _capture("39_dungeon_map")
	pause.close()

	# Mantle answers the Wayshell: the swoop, the flight, the landing.
	await _wait(0.3)
	game._on_fast_travel(Vector2i.ZERO)
	await _wait(0.65)
	await _capture("40_mantle_swoop")
	await _wait(2.4)
	await _capture("41_mantle_flight")
	await _wait(3.0)
	await _capture("42_mantle_landing")

	# Out of breath: the game over screen.
	await _wait(1.0)
	GameState.bubbles = 1
	game.player.take_damage(1, game.player.global_position + Vector2(10, 0))
	await _wait(3.0)
	await _capture("43_game_over")
	game.queue_free()

	# The credits roll, a little way in.
	var credits: Control = (load("res://scenes/credits.tscn") as PackedScene).instantiate()
	add_child(credits)
	credits._scroll = 150.0
	credits._time = 6.0
	await _wait(0.2)
	await _capture("44_credits")
	credits._leaving = true
	credits.queue_free()

	_restore_saves()
	print("MENU SCREENSHOTS DONE: " + _out_dir)
	get_tree().quit(0)


func _mid_game_state() -> void:
	GameState.reset_new_game()
	for id: String in ["tide_hook", "stonebreaker", "glowmoth_lantern", "wayshell", "frostfang_bow"]:
		GameState.give_item(id, 1, false)
	GameState.give_item("puffer_bombs", 12, false)
	GameState.give_item("arrows", 24, false)
	GameState.give_item("brinesteel_sword", 1, false)
	GameState.give_item("cork_buckler", 1, false)
	GameState.give_item("coral_buckler", 1, false)
	GameState.give_item("scaleweave", 1, false)
	GameState.give_item("jar", 3, false)
	GameState.fill_jar(Items.JAR_POTION)
	GameState.fill_jar(Items.JAR_SPRITE)
	GameState.give_item("tidebell", 2, false)
	GameState.give_item("breath_pearl", 2, false)
	GameState.give_item("glint", 137, false)
	GameState.assign_slot(0, "tide_hook")
	GameState.assign_slot(1, "puffer_bombs")
	GameState.play_time = 3.0 * 3600.0 + 42.0 * 60.0
	for coord in RoomInfo.all():
		if RoomInfo.get_room(coord)["dungeon"] == "" and coord != Vector2i(5, -1):
			GameState.mark_seen(coord)
	for coord in [Vector2i(10, 10), Vector2i(10, 9)]:
		GameState.mark_seen(coord)
	for coord in RoomInfo.all():
		if RoomInfo.get_room(coord)["dungeon"] == "" and coord.x != 3:
			var landing := RoomInfo.stone_landing(coord)
			if landing != GameState.NO_POSITION:
				GameState.wake_tidestone(coord, landing)
				GameState.flags["tidestone_%d_%d" % [coord.x, coord.y]] = true


func _press(pause: PauseMenu, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	pause._unhandled_input(event)


## Move real saves aside so the shots can use all three slots.
func _backup_saves() -> void:
	for slot in SaveManager.SLOT_COUNT:
		SaveManager.set_aside(slot, "shotbackup")


func _restore_saves() -> void:
	for slot in SaveManager.SLOT_COUNT:
		SaveManager.delete_save(slot)
		SaveManager.restore_aside(slot, "shotbackup")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	var path := _out_dir.path_join(("pseudo_" if _pseudo else "") + file_name + ".png")
	var err := image.save_png(path)
	print("Saved %s (%s)" % [path, error_string(err)])
