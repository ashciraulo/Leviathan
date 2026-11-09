extends Node
## Performance survey: starts the game in every room, lets it run, and
## prints the average and worst CPU cost of a frame, and the node count,
## per room, busiest first. Run it headless so frames aren't capped and
## no GPU time is mixed in:
##     godot --headless res://tests/perf_rooms.tscn
## Budget: a frame is 16.7 ms at 60 fps; game code should stay well under.

const FRAMES := 90


func _ready() -> void:
	# Uncapped, so a frame's interval is its cost.
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	# The game may save to slot 2: keep a real File 3 safe meanwhile.
	SaveManager.current_slot = 2
	var real_save := ProjectSettings.globalize_path(SaveManager.slot_path(2))
	if FileAccess.file_exists(real_save + ".testbackup"):
		DirAccess.remove_absolute(real_save)
		DirAccess.rename_absolute(real_save + ".testbackup", real_save)
	if FileAccess.file_exists(real_save):
		DirAccess.rename_absolute(real_save, real_save + ".testbackup")
	var rows: Array = []
	for coord: Vector2i in RoomInfo.all():
		GameState.reset_new_game()
		GameState.set_checkpoint(coord, GameState.NO_POSITION)
		# What a room slide pays to bring this room in (loaded and built).
		var t0 := Time.get_ticks_usec()
		var probe := (load("res://rooms/room_%d_%d.tscn" % [coord.x, coord.y]) as PackedScene).instantiate()
		add_child(probe)
		var spawn_ms := (Time.get_ticks_usec() - t0) / 1000.0
		probe.queue_free()
		await get_tree().process_frame
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		for i in 20:
			await get_tree().process_frame
		var total := 0.0
		var worst := 0.0
		var last := Time.get_ticks_usec()
		for i in FRAMES:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			var cost := (now - last) / 1000.0
			last = now
			total += cost
			worst = maxf(worst, cost)
		rows.append([coord, total / FRAMES, worst, game.get_tree().get_node_count(), spawn_ms])
		game.queue_free()
		await get_tree().process_frame
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])
	print("room        avg ms  worst ms  nodes  build ms")
	for r: Array in rows:
		print("%-10s  %6.2f  %8.2f  %5d  %8.2f" % [str(r[0]), r[1], r[2], r[3], r[4]])
	SaveManager.delete_save()
	if FileAccess.file_exists(real_save + ".testbackup"):
		DirAccess.rename_absolute(real_save + ".testbackup", real_save)
	print("PERF ROOMS DONE")
	get_tree().quit(0)
