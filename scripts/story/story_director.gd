class_name StoryDirector
extends Node
## Watches the game and plays story scenes when their moment comes (see the
## cutscene list in the story bible). Each scene plays once: it sets a flag
## when it starts. Nothing saves mid-scene, so quitting or dying before the
## next save plays it again from the start, flags and items together.

const SALTMARROW := Vector2i(0, -1)
const WRECK_STRAND := Vector2i(4, 0)
## Where Mantle lies netted on the Wreck Strand (its feet), and where Wren
## stands to cut it free.
const MANTLE_AT := Vector2(20 * 16, 3 * 16 + 8)
const CUT_FROM := Vector2(21 * 16 + 8, 5 * 16 + 4)
## Where the path to the village leaves the shore (room 0,0): Hessa's lamp
## shows there in the opening.
const SHORE_PATH := Vector2(12 * 16, 10)
## The Rotting Hull's boss chamber, where Sister Lowe is first met.
const HULL_BOSS := Vector2i(10, 7)
const LOWE_HULL_FLAG := "seen_lowe_hull"
## Where Lowe and her singers stand, from the Matriarch's feet, and the
## holes in the deck they drop through (the chamber's top corners).
const LOWE_FROM_BOSS := Vector2(-36, 40)
const SINGERS_FROM_BOSS := [Vector2(-30, 4), Vector2(30, 4)]
const HULL_HOLES := [Vector2(3 * 16 + 16, 2 * 16 + 16), Vector2(19 * 16 + 16, 2 * 16 + 16)]
## The Kiln's crucible chamber, where Lowe's smiths melt the Ember Bell.
const KILN_BOSS := Vector2i(21, 7)
const CRUCIBLE_FLAG := "seen_crucible"
const SMITHS_FROM_CRUCIBLE := [Vector2(-30, 6), Vector2(30, 6)]
## The way out for the Kiln's Choir: round Wren and down through the door.
## Points: down between the pools and Wren, across to the door, and out.
## Figures on the right mirror the first two.
const KILN_EXIT := [Vector2(140, 120), Vector2(140, 176), Vector2(192, 176), Vector2(192, 216)]
## Lantern Mire's heart chamber, where the Pale Congregation is laid to rest.
const MIRE_BOSS := Vector2i(25, 7)
const CALF_FLAG := "seen_calf"
## Where the calf of lights hangs (left of the bell, on open floor), and the
## way Murmur walks in from the door
## (and back out).
const CALF_AT := Vector2(7 * 16 + 8, 6 * 16 + 12)
const MURMUR_IN := [Vector2(11 * 16 + 16, 13 * 16 + 8), Vector2(11 * 16 + 16, 11 * 16), Vector2(14 * 16 + 8, 7 * 16 + 12)]
## The Gale Spire's summit, the Crown, where Vael waits after the Stormheron.
const GALE_BOSS := Vector2i(28, 7)
const VAEL_FLAG := "seen_vael_spire"
## Vael steps out onto the top ledge, across the open sky from Wren.
const VAEL_FROM := Vector2(10 * 16 + 8, 1 * 16 + 4)
const VAEL_AT := Vector2(10 * 16 + 8, 2 * 16 + 12)
## Where Wren stops to watch, in any of these chambers.
const WATCH_FROM := Vector2(11 * 16 + 8, 8 * 16 + 4)

var game: Node


func _ready() -> void:
	game = get_parent()
	add_to_group("story_director")
	Events.game_started.connect(_on_game_started)
	Events.room_entered.connect(_on_room_entered)
	Events.flag_changed.connect(_on_flag_changed)


func _on_game_started() -> void:
	if GameState.play_opening:
		GameState.play_opening = false
		if not GameState.has_flag("seen_opening"):
			opening()
			return
	_on_room_entered(GameState.room_coord)


func _on_room_entered(coord: Vector2i) -> void:
	if Cutscene.active:
		return
	if coord == WRECK_STRAND and GameState.has_flag("tidebell_hull") and not GameState.has_flag("freed_mantle") and not GameState.has_flag("seen_wayshell"):
		freeing_mantle()
	elif coord == SALTMARROW and GameState.has_flag("freed_mantle") and not GameState.has_flag("seen_wayshell"):
		the_wayshell()
	elif lowe_waits(coord):
		if coord == HULL_BOSS:
			lowe_at_the_hull()
		else:
			the_crucible()


func _on_flag_changed(flag: String, _value: Variant) -> void:
	if Cutscene.active:
		return
	if flag == PaleCongregation.DEFEATED_FLAG and GameState.room_coord == MIRE_BOSS and not GameState.has_flag(CALF_FLAG):
		the_calf()
	elif flag == Stormheron.DEFEATED_FLAG and GameState.room_coord == GALE_BOSS and not GameState.has_flag(VAEL_FLAG):
		vael_at_the_spire()


## True while one of Lowe's scenes is still to play in this room: the boss
## sleeps until it does.
static func lowe_waits(coord: Vector2i) -> bool:
	if coord == HULL_BOSS:
		return not GameState.has_flag(LOWE_HULL_FLAG) and not GameState.has_flag(BarnacleMatriarch.DEFEATED_FLAG)
	if coord == KILN_BOSS:
		return not GameState.has_flag(CRUCIBLE_FLAG) and not GameState.has_flag(Slagwyrm.DEFEATED_FLAG)
	return false


func _scene() -> Cutscene:
	var scene := Cutscene.new(game)
	add_child(scene)
	scene.begin()
	return scene


## Cutscene 1, "The Point Bell is gone": a new game opens on black, then on
## the shore, where Hessa's lamp calls Wren home. The lamps are shown, not
## explained: no on-screen text describing what the player can see.
func opening() -> void:
	GameState.set_flag("seen_opening")
	var scene := _scene()
	scene.darken()
	await scene.veil_text(["OPENING_1", "OPENING_2", "OPENING_3"])
	await scene.lift_veil()
	await scene.wait(0.6)
	var path: Vector2 = game.current_room.global_position + SHORE_PATH
	await scene.lamp(path, Cutscene.LAMP_HERE)
	scene.face(Vector2.UP)
	await scene.lamp(game.player.global_position, Cutscene.LAMP_YES)
	scene.finish()


## Cutscene 6, "Freeing Mantle": after the Hull, a sky-ray lies caught in
## Choir nets on the Wreck Strand. Wren cuts it loose and it flies home
## towards the lighthouse. Told in pictures: no text.
func freeing_mantle() -> void:
	GameState.set_flag("freed_mantle")
	var room: Node2D = game.current_room
	var mantle := MantleTangle.new()
	mantle.position = MANTLE_AT
	room.add_child(mantle)
	var scene := _scene()
	await scene.wait(0.8)
	await scene.walk_route(room.global_position + CUT_FROM)
	scene.face(Vector2.UP)
	await scene.wait(0.6)
	scene.slash()
	await mantle.cut()
	await scene.wait(0.8)
	await mantle.rise()
	await scene.wait(0.4)
	await scene.lamp(game.player.global_position, Cutscene.LAMP_HERE)
	if is_instance_valid(mantle):
		mantle.queue_free()
	scene.finish()


## Cutscene 7, "The Wayshell": back in Saltmarrow with the Point Bell, once
## Mantle is free, Hessa gives Wren the keepers' call and sends them on.
func the_wayshell() -> void:
	GameState.set_flag("seen_wayshell")
	GameState.set_flag("met_hessa")
	var hessa := _find_npc("hessa")
	var scene := _scene()
	await scene.wait(0.3)
	if hessa:
		await scene.walk_around_to(hessa.global_position + Vector2(0, 22))
		scene.face(Vector2.UP)
		await scene.lamp(hessa.global_position, Cutscene.LAMP_HERE)
	await scene.speak("hessa", ["WAYSHELL_1", "WAYSHELL_2", "WAYSHELL_3"])
	GameState.give_item("wayshell", 1, false)
	await scene.narrate(["NARRATE_GOT_WAYSHELL"])
	await scene.speak("hessa", ["WAYSHELL_4"])
	await scene.lamp(game.player.global_position, Cutscene.LAMP_YES)
	scene.finish()


## Cutscene 4, "Lowe at the Hull": Sister Lowe and two singers are prying
## the Point Bell out from under the sleeping Matriarch. Lowe warns Wren off,
## the Matriarch wakes, and the Choir drops through holes in the deck.
func lowe_at_the_hull() -> void:
	GameState.set_flag(LOWE_HULL_FLAG)
	var room: Node2D = game.current_room
	var boss := get_tree().get_first_node_in_group("boss") as BarnacleMatriarch
	var at: Vector2 = boss.position if boss else Vector2(11 * 16 + 8, 3 * 16 + 12)
	var singers: Array[ChoirFigure] = []
	for i in SINGERS_FROM_BOSS.size():
		var singer := ChoirFigure.new("singer")
		singer.position = at + SINGERS_FROM_BOSS[i]
		singer.prying = true
		singer.face(i == 1)
		room.add_child(singer)
		singers.append(singer)
	var lowe := ChoirFigure.new("lowe")
	lowe.position = at + LOWE_FROM_BOSS
	room.add_child(lowe)
	var scene := _scene()
	await scene.wait(0.6)
	await scene.walk_route(room.global_position + WATCH_FROM)
	scene.face(Vector2.UP)
	await scene.wait(0.6)
	lowe.talking = true
	await scene.speak("lowe", ["LOWE_HULL_1"])
	lowe.talking = false
	await scene.wait(0.5)
	lowe.talking = true
	await scene.speak("lowe", ["LOWE_HULL_2"])
	lowe.talking = false
	await scene.wait(0.6)
	if boss:
		boss.wake()
	await scene.wait(0.8)
	await scene.speak("lowe", ["LOWE_HULL_3"])
	var runs: Array[ChoirFigure] = [singers[0], lowe, singers[1]]
	var holes := [HULL_HOLES[0], HULL_HOLES[0], HULL_HOLES[1]]
	for i in runs.size():
		runs[i].flee_into(holes[i], 0.7 + 0.25 * i)
	await scene.wait(1.5)
	for figure in runs:
		if is_instance_valid(figure):
			figure.queue_free()
	scene.finish()


## Cutscene 8, "The crucible": Sister Lowe's smiths are stoking the Kiln's
## crucible to melt the Ember Bell into a Waking Bell. Lowe brushes Wren
## off, the slag comes alive as the Slagwyrm, and the Choir runs for it.
func the_crucible() -> void:
	GameState.set_flag(CRUCIBLE_FLAG)
	var room: Node2D = game.current_room
	var boss := get_tree().get_first_node_in_group("boss") as Slagwyrm
	var at: Vector2 = boss.position if boss else Vector2(11 * 16 + 8, 4 * 16 + 12)
	var crucible := Crucible.new()
	crucible.position = at
	room.add_child(crucible)
	var smiths: Array[ChoirFigure] = []
	for i in SMITHS_FROM_CRUCIBLE.size():
		var smith := ChoirFigure.new("singer")
		smith.position = at + SMITHS_FROM_CRUCIBLE[i]
		smith.prying = true
		smith.face(i == 1)
		room.add_child(smith)
		smiths.append(smith)
	var lowe := ChoirFigure.new("lowe")
	lowe.position = at + LOWE_FROM_BOSS
	room.add_child(lowe)
	var scene := _scene()
	await scene.wait(0.6)
	await scene.walk_route(room.global_position + WATCH_FROM)
	scene.face(Vector2.UP)
	await scene.wait(0.6)
	lowe.talking = true
	await scene.speak("lowe", ["LOWE_KILN_1"])
	lowe.talking = false
	await scene.wait(0.5)
	lowe.talking = true
	await scene.speak("lowe", ["LOWE_KILN_2"])
	lowe.talking = false
	Feel.shake(2.0)
	await crucible.boil()
	await scene.wait(0.4)
	crucible.shatter()
	if boss:
		boss.wake()
	await scene.wait(0.6)
	await scene.speak("lowe", ["LOWE_KILN_3"])
	var runs: Array[ChoirFigure] = [lowe, smiths[0], smiths[1]]
	for i in runs.size():
		var path: Array = KILN_EXIT.duplicate()
		if runs[i].position.x > at.x:
			for p in 2:
				path[p] = Vector2(Room.SIZE.x - path[p].x, path[p].y)
		if i < runs.size() - 1:
			runs[i].flee_along(path, 0.45 + 0.1 * i)
		else:
			# The last (slowest) runner: the scene ends once they're out.
			await runs[i].flee_along(path, 0.45 + 0.1 * i)
	for figure in runs:
		if is_instance_valid(figure):
			figure.queue_free()
	scene.finish()


## Cutscene 9, "The calf in the lights": the Pale Congregation laid to
## rest, its wisps gather one last time into a leviathan calf. Murmur, who
## sang them out of their lanterns for the Choir, sees it and leaves the
## Choir. Then the lights scatter home.
func the_calf() -> void:
	GameState.set_flag(CALF_FLAG)
	var room: Node2D = game.current_room
	var scene := _scene()
	# Let the heart beat out and the bell rise first.
	await scene.wait(3.6)
	await scene.walk_route(room.global_position + WATCH_FROM)
	scene.face(Vector2.LEFT)
	var calf := CalfOfLights.new()
	calf.position = CALF_AT
	room.add_child(calf)
	await calf.gather()
	var murmur := ChoirFigure.new("murmur")
	murmur.position = MURMUR_IN[0]
	room.add_child(murmur)
	await murmur.walk_along(MURMUR_IN.slice(1), 30.0, 1)
	murmur.face(true)
	await scene.wait(0.8)
	murmur.talking = true
	await scene.speak("murmur", ["MURMUR_CALF_1", "MURMUR_CALF_2"])
	murmur.talking = false
	await calf.scatter()
	await scene.wait(0.4)
	await scene.speak("murmur", ["MURMUR_CALF_3"])
	var out: Array = MURMUR_IN.duplicate()
	out.reverse()
	await murmur.walk_along(out.slice(1), 30.0, -1)
	murmur.queue_free()
	scene.finish()


## Cutscene 10, "Vael at the spire": with the Stormheron gone, Vael steps
## out on the ledge across the open sky. He does not fight. He tells Wren
## he was Hessa's apprentice, that the Old One weeps under every phrase, and
## asks Wren to listen when they ring the bell. Then he goes.
func vael_at_the_spire() -> void:
	GameState.set_flag(VAEL_FLAG)
	var room: Node2D = game.current_room
	var scene := _scene()
	# The heron lifts away on the wind and the Storm Bell rises first.
	await scene.wait(3.0)
	await scene.walk_route(room.global_position + WATCH_FROM)
	scene.face(Vector2.UP)
	var vael := ChoirFigure.new("vael")
	vael.position = VAEL_FROM
	room.add_child(vael)
	await vael.walk_along([VAEL_AT], 18.0, 1)
	await scene.wait(1.0)
	for key in ["VAEL_SPIRE_1", "VAEL_SPIRE_2", "VAEL_SPIRE_3", "VAEL_SPIRE_4"]:
		vael.talking = true
		await scene.speak("vael", [key])
		vael.talking = false
		await scene.wait(0.4)
	await scene.wait(0.6)
	await vael.walk_along([VAEL_FROM], 18.0, -1)
	vael.queue_free()
	scene.finish()


func _find_npc(kind: String) -> Npc:
	if game.current_room == null:
		return null
	for child in game.current_room.get_children():
		if child is Npc and child.kind == kind:
			return child
	return null
