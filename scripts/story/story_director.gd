class_name StoryDirector
extends Node
## Watches the game and plays story scenes when their moment comes (see the
## cutscene list in the story bible). Each scene plays once: it sets a flag
## when it starts. Nothing saves mid-scene, so quitting or dying before the
## next save plays it again from the start, flags and items together.

const SALTMARROW := Vector2i(0, -1)
## Where the path to the village leaves the shore (room 0,0): Hessa's lamp
## shows there in the opening.
const SHORE_PATH := Vector2(12 * 16, 10)

var game: Node


func _ready() -> void:
	game = get_parent()
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
	if coord == SALTMARROW and GameState.has_flag("tidebell_hull") and not GameState.has_flag("seen_wayshell"):
		the_wayshell()


func _scene() -> Cutscene:
	var scene := Cutscene.new(game)
	add_child(scene)
	scene.begin()
	return scene


## Cutscene 1, "The Point Bell is gone": a new game opens on black, then on
## the shore, where Hessa's lamp calls Wren home. No narration: the lamps
## say it (Ash: keep explanatory text off the screen).
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


## Cutscene 7, "The Wayshell": back in Saltmarrow with the Point Bell, Hessa
## gives Wren the keepers' call and sends them on.
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


func _find_npc(kind: String) -> Npc:
	if game.current_room == null:
		return null
	for child in game.current_room.get_children():
		if child is Npc and child.kind == kind:
			return child
	return null
