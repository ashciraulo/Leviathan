extends Node
## Room-slide survey: starts the game in every overworld room, slides into a
## neighbouring room, and prints how long the slide's first step took (the
## next room loaded and built) and the worst frame during the slide, busiest
## first. A slide is where a slow machine or the web build would hitch.
##     godot --headless res://tests/perf_slides.tscn
## Budget: a frame is 16.7 ms at 60 fps.

const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]


func _ready() -> void:
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	SaveManager.current_slot = 2
	SaveManager.set_aside(2, "testbackup")
	var rows: Array = []
	for coord: Vector2i in RoomInfo.in_area(""):
		var way := Vector2i.ZERO
		for d: Vector2i in DIRECTIONS:
			if RoomInfo.has_room(coord + d) and str(RoomInfo.get_room(coord + d)["dungeon"]) == "":
				way = d
				break
		if way == Vector2i.ZERO:
			continue
		GameState.reset_new_game()
		GameState.set_checkpoint(coord, GameState.NO_POSITION)
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		for i in 30:
			await get_tree().process_frame
		var t0 := Time.get_ticks_usec()
		game.call("_change_room", way)
		var step_ms := (Time.get_ticks_usec() - t0) / 1000.0
		var worst := 0.0
		var last := Time.get_ticks_usec()
		for i in 30:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			worst = maxf(worst, (now - last) / 1000.0)
			last = now
		rows.append([coord, coord + way, step_ms, worst])
		game.queue_free()
		await get_tree().process_frame
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])
	print("from        to          step ms  worst frame ms")
	for r: Array in rows:
		print("%-10s  %-10s  %7.2f  %14.2f" % [str(r[0]), str(r[1]), r[2], r[3]])
	SaveManager.delete_save()
	SaveManager.restore_aside(2, "testbackup")
	print("PERF SLIDES DONE")
	get_tree().quit(0)
