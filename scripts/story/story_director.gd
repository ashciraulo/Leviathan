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
## Where Wren stops to watch, in the chamber.
const WATCH_FROM := Vector2(11 * 16 + 8, 8 * 16 + 4)

var game: Node


func _ready() -> void:
	game = get_parent()
	add_to_group("story_director")
	Events.game_started.connect(_on_game_started)
	Events.room_entered.connect(_on_room_entered)


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
		lowe_at_the_hull()


## True while Lowe's scene is still to play in this room: the Matriarch
## sleeps until it does.
static func lowe_waits(coord: Vector2i) -> bool:
	return coord == HULL_BOSS and not GameState.has_flag(LOWE_HULL_FLAG) and not GameState.has_flag(BarnacleMatriarch.DEFEATED_FLAG)


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
	lowe.face(false)
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


func _find_npc(kind: String) -> Npc:
	if game.current_room == null:
		return null
	for child in game.current_room.get_children():
		if child is Npc and child.kind == kind:
			return child
	return null
