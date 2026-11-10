extends Node
## Web performance survey. A separate web export ("Web perf", feature tag
## "perf") starts here instead of the title screen; tools/web_check.mjs
## --perf runs it in headless Chromium. It starts the game in every
## dungeon room and a few of the busiest overworld screens, lets each
## settle, then measures real frames in the browser (drawing included).
## Each room prints one line:
##     WEB PERF ROW <x,y> <area> <avg ms> <worst ms> <draw calls> <lights> <nodes>
## and WEB PERF SHOT <name> asks the page for a screenshot meanwhile.
## The page reports the table. The browser in CI draws in software, so its
## frame times are slower than a real GPU's: the check compares each room
## with the overworld screens measured the same way, and counts draw calls
## (each costs the browser CPU time whatever the GPU).

const SETTLE_FRAMES := 30
## And at least this long, so the fade-in is over (slow frames at first).
const SETTLE_SECONDS := 1.5
## A boss's entrance plays under a black veil: wait up to this long for it
## to lift, so the room is measured (and pictured) as it's played.
const VEIL_WAIT_SECONDS := 12.0
const FRAMES := 90
## A boss room is measured mid-fight: Wren can't be hurt, and the boss gets
## this long to get going (its entrance over, its attacks flying) first.
const BOSS_FIGHT_SECONDS := 6.0
## Busiest overworld screens in tests/perf_rooms (a baseline to compare).
const OVERWORLD := [Vector2i(12, 9), Vector2i(3, -3), Vector2i(22, 8), Vector2i(2, 3)]
## Rooms worth a picture, to see they draw right in a browser (not boss
## rooms, whose fights can still be veiled for a cutscene).
const SHOTS := {
	Vector2i(45, 9): "maw_lights", Vector2i(44, 9): "maw_flood", Vector2i(21, 8): "kiln_walls",
}


func _ready() -> void:
	Engine.max_fps = 0
	SaveManager.current_slot = 2
	var rooms: Array[Vector2i] = []
	rooms.assign(OVERWORLD)
	var dungeon_rooms: Array = RoomInfo.all().keys().filter(
		func(c: Vector2i) -> bool: return str(RoomInfo.all()[c]["dungeon"]) != "")
	dungeon_rooms.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := str(RoomInfo.all()[a]["dungeon"])
		var db := str(RoomInfo.all()[b]["dungeon"])
		return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
	rooms.append_array(dungeon_rooms)
	var first_mire := true
	for coord in rooms:
		GameState.reset_new_game()
		GameState.set_checkpoint(coord, GameState.NO_POSITION)
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		add_child(game)
		var settle_until := Time.get_ticks_msec() + int(SETTLE_SECONDS * 1000.0)
		var settled := 0
		while settled < SETTLE_FRAMES or Time.get_ticks_msec() < settle_until:
			await get_tree().process_frame
			_skip_talk()
			settled += 1
		var veil_until := Time.get_ticks_msec() + int(VEIL_WAIT_SECONDS * 1000.0)
		while _veiled() and Time.get_ticks_msec() < veil_until:
			await get_tree().process_frame
			_skip_talk()
		var dungeon := str(RoomInfo.all()[coord]["dungeon"])
		var shot := str(SHOTS.get(coord, ""))
		var boss_room: bool = RoomInfo.all()[coord]["boss"] != Vector2i(-1, -1)
		if shot != "" and (boss_room or _veiled()):
			shot = ""
		if dungeon == "mire" and first_mire and _dark() and not boss_room and not _veiled():
			first_mire = false
			shot = "mire_dark"
		if boss_room:
			var player := get_tree().get_first_node_in_group("player") as Player
			var fight_until := Time.get_ticks_msec() + int(BOSS_FIGHT_SECONDS * 1000.0)
			while Time.get_ticks_msec() < fight_until:
				if player:
					player._invuln = 600.0
				await get_tree().process_frame
				_skip_talk()
		var total := 0.0
		var worst := 0.0
		var calls := 0.0
		var last := Time.get_ticks_usec()
		for i in FRAMES:
			await get_tree().process_frame
			_skip_talk()
			var now := Time.get_ticks_usec()
			var cost := (now - last) / 1000.0
			last = now
			total += cost
			worst = maxf(worst, cost)
			calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		print("WEB PERF ROW %d,%d %s %.2f %.2f %.0f %d %d" % [coord.x, coord.y,
				dungeon if dungeon != "" else "overworld", total / FRAMES, worst,
				calls / FRAMES, _lights(), get_tree().get_node_count()])
		# Pictures after the timing, so taking one doesn't count as a slow frame.
		if shot != "":
			print("WEB PERF SHOT %s" % shot)
			var hold_until := Time.get_ticks_msec() + 1500
			while Time.get_ticks_msec() < hold_until:
				await get_tree().process_frame
				_skip_talk()
		game.queue_free()
		await get_tree().process_frame
	SaveManager.delete_save()
	print("WEB PERF DONE")


## A room's first visit can open a dialogue, which pauses the game until a
## key is pressed: close it, so the room is measured running.
func _skip_talk() -> void:
	if not get_tree().paused:
		return
	for node in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if node is DialogueBox and (node as DialogueBox).is_open:
			(node as DialogueBox).close()
	get_tree().paused = false


## True while a black screen (a fade or a cutscene's veil) hides the room.
func _veiled() -> bool:
	for node in get_tree().root.find_children("*", "ColorRect", true, false):
		var rect := node as ColorRect
		# A dark room's Darkness sheet multiplies the room, it doesn't hide it.
		if rect.get_parent() is Darkness:
			continue
		if rect.is_visible_in_tree() and rect.color.a > 0.5 and rect.size.x >= 300.0:
			return true
	return false


## Lights shining in the room now: 2D lights (there should be none: each
## redraws everything it touches) and Glows (one shader pass in the dark).
func _lights() -> int:
	var n := 0
	for node in get_tree().root.find_children("*", "Light2D", true, false):
		if (node as Light2D).is_visible_in_tree() and (node as Light2D).enabled:
			n += 1
	for node in get_tree().get_nodes_in_group(Glow.GROUP):
		if (node as Node2D).is_visible_in_tree():
			n += 1
	return n


## True when the room is a dark one.
func _dark() -> bool:
	for room in get_tree().get_nodes_in_group("rooms"):
		if room.get_node_or_null("Darkness") is Darkness:
			return true
	return false
