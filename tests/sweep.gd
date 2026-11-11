extends "res://tests/playthrough.gd"
## The playthrough's room sweep at two earlier points of a game: on a new
## file, and half-way (after the first four dungeons). In every overworld
## room Wren talks to, reads and opens everything, and each must leave the
## game playable (see _interact_all). The playthrough itself sweeps after
## the ending; between them every side quest is met early, mid-way and late.
## CI runs it beside the other tests:
##     godot --headless res://tests/sweep.tscn
## Prints "SWEEP PASSED" and exits 0, or lists each failure and exits 1.
## Uses save slot 2 and keeps a real save safe.

## Dungeons cleared before the mid-game sweep.
const MID_DUNGEONS := 4


func _ready() -> void:
	SaveManager.current_slot = TEST_SLOT
	SaveManager.set_aside(TEST_SLOT, "sweepbackup")
	SaveManager.delete_save()
	_index_rooms()
	GameState.reset_new_game()
	_game = _new_game()
	await _wait(0.6)
	await _play_scene(20.0)
	await _sweep("on a new file")
	for spec: Array in DUNGEONS.slice(0, MID_DUNGEONS):
		if not await _dungeon(spec[0], spec[1], spec[2]):
			break
	await _sweep("mid-game")
	await _save_and_reload("the mid-game sweep")
	_audit("the sweeps")
	_game.queue_free()
	await _wait(0.1)
	SaveManager.delete_save()
	SaveManager.restore_aside(TEST_SLOT, "sweepbackup")
	if _failures.is_empty():
		print("SWEEP PASSED (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		print("SWEEP FAILED (%d of %d checks)" % [_failures.size(), _checks])
		get_tree().quit(1)


func _sweep(stage: String) -> void:
	print("Sweep: %s" % stage)
	var started := Time.get_ticks_msec()
	var coords: Array[Vector2i] = []
	for coord: Vector2i in _rooms:
		if _rooms[coord][0] == "":
			coords.append(coord)
	coords.sort()
	for coord in coords:
		var room := await _goto(coord)
		await _play_scene(20.0)
		_check(room != null and room.coord == coord, "%s: %s loads" % [stage, coord])
		if room == null or room.coord != coord:
			continue
		_keep_safe()
		await _interact_all(coord, stage)
	print("Sweep: %s took %.0f s" % [stage, (Time.get_ticks_msec() - started) / 1000.0])
