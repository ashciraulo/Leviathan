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
## Ringing the Gale Bell (the Turning Verse) wakes the Old One enough to
## roll over; Hessa owns up about Vael the next time Wren is home.
const GALE_BELL_FLAG := "tidebell_" + "gale"
## The ring of light around Wren at the end of a bell's phrase.
const PHRASE_PULSE := BellPhrase.PULSE
const TURNED_FLAG := "old_one_turned"
const CONFESSION_FLAG := "seen_hessa_confession"
const TOMB_BOSS := Vector2i(40, 7)
const MURAL_FLAG := "seen_last_mural"
## Wren stands under the slab; Dace comes up from the way in at the south.
const MURAL_WATCH := Vector2(16 * 16 + 8, 2 * 16 + 12)
const DACE_IN := [Vector2(12 * 16, 13 * 16 + 8), Vector2(12 * 16, 7 * 16 + 12), Vector2(14 * 16 + 8, 3 * 16 + 12)]
const ENDING_FLAG := "seen_ending"
## Cutscene 21, back home after the credits: the Old One dreams, and the
## lighthouse turns its beam towards the Maw.
const DREAM_FLAG := "seen_old_one_dreams"
## Wren has been back down to the Heart since the ending: the beam rests.
const HEART_VISIT_FLAG := "visited_heart_after_end"
## The Heart's chamber: Wren stands below the sleeping Heart, Vael comes
## up from the Choir Loft and stops beside them.
const ENDING_WATCH := Vector2(11 * 16 + 8, 7 * 16 + 12)
const VAEL_IN := [Vector2(12 * 16, 13 * 16 + 8), Vector2(12 * 16, 9 * 16 + 12), Vector2(13 * 16 + 8, 7 * 16 + 12)]
## Where Wren stands, just below Hessa, in the epilogue at home.
const HOME_FROM_HESSA := Vector2(0, 22)
## Where Wren stops to watch, in any of these chambers.
const WATCH_FROM := Vector2(11 * 16 + 8, 8 * 16 + 4)

var game: Node


func _ready() -> void:
	game = get_parent()
	add_to_group("story_director")
	Events.game_started.connect(_on_game_started)
	Events.room_entered.connect(_on_room_entered)
	Events.flag_changed.connect(_on_flag_changed)
	Events.game_finished.connect(the_ending)


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
	# Saves from before the turn existed rang the Storm Bell without it; the
	# Old One has turned all the same, so Hessa still has her say at home.
	if GameState.has_flag(GALE_BELL_FLAG) and not GameState.has_flag(TURNED_FLAG):
		GameState.set_flag(TURNED_FLAG)
	if coord == TOMB_BOSS and GameState.has_flag(HollowRegent.DEFEATED_FLAG):
		_put_up_mural()
	# The game closed partway through the ending: the Heart sleeps, so pick
	# the ending up again.
	if GameState.has_flag(DreamingHeart.DEFEATED_FLAG) and not GameState.has_flag(ENDING_FLAG) and _heart_here():
		the_ending()
		return
	if GameState.has_flag(ENDING_FLAG):
		if _heart_here() and not GameState.has_flag(HEART_VISIT_FLAG):
			GameState.set_flag(HEART_VISIT_FLAG)
			# Kept even if Wren falls before the next save.
			SaveManager.save_game()
		elif coord == SALTMARROW and not GameState.has_flag(HEART_VISIT_FLAG):
			if not GameState.has_flag(DREAM_FLAG):
				the_old_one_dreams()
				return
			LighthouseBeam.at_lighthouse(game.current_room)
	if coord == WRECK_STRAND and GameState.has_flag("tidebell_hull") and not GameState.has_flag("freed_mantle") and not GameState.has_flag("seen_wayshell"):
		freeing_mantle()
	elif coord == SALTMARROW and GameState.has_flag("freed_mantle") and not GameState.has_flag("seen_wayshell"):
		the_wayshell()
	elif coord == SALTMARROW and GameState.has_flag(TURNED_FLAG) and not GameState.has_flag(CONFESSION_FLAG):
		hessas_confession()
	elif coord == TOMB_BOSS and GameState.has_flag(HollowRegent.DEFEATED_FLAG) and not GameState.has_flag(MURAL_FLAG):
		# A save from before the mural existed: show it on the way back in.
		the_last_mural()
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
	elif flag == GALE_BELL_FLAG and not GameState.has_flag(TURNED_FLAG):
		the_old_one_turns()
	elif flag == HollowRegent.DEFEATED_FLAG and GameState.room_coord == TOMB_BOSS and not GameState.has_flag(MURAL_FLAG):
		the_last_mural()


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
	# The Crown is ringed with open sky: if Wren is out on a side ledge
	# there's no safe way across, so they stay put and look up.
	await scene.walk_route(room.global_position + WATCH_FROM, false)
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


## Cutscene 11, "The Old One turns": the Gale Bell rings out the Turning
## Verse. Out on the bay, Vael's Choir answers with the Waking Song, sung by
## voice alone, and far below the Old One rolls over. Told in sound, shaking
## and one vast shape under the sea: no text.
func the_old_one_turns(carried: Cutscene = null) -> void:
	GameState.set_flag(TURNED_FLAG)
	# Straight on from the bell's own scene, Wren never gets control back in
	# between. Otherwise give the bell a frame to open its words, and let
	# those finish first.
	if carried == null:
		await get_tree().process_frame
		if DialogueBox.is_open:
			await Events.dialogue_finished
	var scene := carried if carried else _scene()
	await scene.wait(1.2)
	Audio.play_sfx("choir_waking")
	await scene.wait(2.6)
	Audio.play_sfx("choir_waking", null, 0.84)
	await scene.wait(1.6)
	var shadow := OldOneShadow.new()
	shadow.room = game.current_room
	game.current_room.add_child(shadow)
	Audio.play_sfx("old_one_rumble")
	Feel.shake(6.0)
	var rolling := shadow.roll()
	for i in 4:
		await scene.wait(1.2)
		Feel.shake(6.0 - i)
		if i == 1:
			Audio.play_sfx("old_one_rumble", null, 0.8)
	if rolling.is_running():
		await rolling.finished
	shadow.queue_free()
	await scene.wait(0.8)
	scene.finish()


## Cutscene 12, "Hessa's confession": the first time Wren comes home after
## the turn, Hessa owns up about Vael, and asks Wren not to hate him.
func hessas_confession() -> void:
	GameState.set_flag(CONFESSION_FLAG)
	var hessa := _find_npc("hessa")
	var scene := _scene()
	await scene.wait(0.3)
	if hessa:
		await scene.walk_around_to(hessa.global_position + Vector2(0, 22))
		scene.face(Vector2.UP)
		await scene.lamp(hessa.global_position, Cutscene.LAMP_HERE)
	await scene.speak("hessa", ["HESSA_CONFESS_1", "HESSA_CONFESS_2", "HESSA_CONFESS_3", "HESSA_CONFESS_4"])
	await scene.wait(0.6)
	await scene.speak("hessa", ["HESSA_CONFESS_5"])
	# Wren answers: one flash, yes.
	await scene.lamp(game.player.global_position, Cutscene.LAMP_YES)
	scene.finish()


## Cutscene 15, "The last mural": with the Hollow Regent gone to bones,
## the wall he sealed falls open on the last carving. Mother Dace comes down
## into the tomb and shows Wren what it is: the Old One lying down beside its
## dead family. Then she leaves Wren to ring the Marrow Bell.
func the_last_mural() -> void:
	GameState.set_flag(MURAL_FLAG)
	var room: Node2D = game.current_room
	var scene := _scene()
	# The Regent crumbles and the Marrow Bell rises first.
	await scene.wait(3.4)
	Audio.play_sfx("old_one_rumble", null, 1.4)
	Feel.shake(3.0)
	for i in 3:
		KilnDebris.burst(room, room.global_position + LastMural.SLAB.get_center() + Vector2(-24 + 24 * i, 6), 5, TombSprites.BONE_SHARD)
	var mural := _put_up_mural()
	await scene.wait(1.2)
	await scene.walk_route(room.global_position + MURAL_WATCH, false)
	scene.face(Vector2.UP)
	var dace := ChoirFigure.new("dace")
	dace.position = DACE_IN[0]
	room.add_child(dace)
	await dace.walk_along(DACE_IN.slice(1), 26.0, 1)
	dace.face(false)
	scene.face(Vector2.LEFT)
	dace.talking = true
	await scene.speak("dace", ["DACE_MURAL_1"])
	dace.talking = false
	scene.face(Vector2.UP)
	await mural.show_close()
	await scene.wait(1.6)
	await scene.speak("dace", ["DACE_MURAL_2", "DACE_MURAL_3"])
	await mural.hide_close()
	scene.face(Vector2.LEFT)
	dace.talking = true
	await scene.speak("dace", ["DACE_MURAL_4"])
	dace.talking = false
	var out: Array = DACE_IN.duplicate()
	out.reverse()
	await dace.walk_along(out.slice(1), 26.0, -1)
	dace.queue_free()
	scene.finish()


## Cutscenes 19 and 20, "The Heart wakes" and the ending: the Old One
## sleeps. Vael comes up from the Choir Loft, lets his grey robe fall, and
## stays behind as its keeper. At dawn Mantle carries Wren home, where Hessa
## feels the Point Bell ring through the lighthouse floor. Then the credits,
## and Continue picks up at home.
func the_ending() -> void:
	while Cutscene.active:
		await get_tree().process_frame
	if GameState.has_flag(ENDING_FLAG):
		# Already told: the credits still roll.
		if DreamingHeart.roll_credits:
			get_tree().change_scene_to_file.call_deferred(DreamingHeart.CREDITS_SCENE)
		return
	GameState.set_flag(ENDING_FLAG)
	# Scenes still owed at home would play after the credits, out of turn.
	GameState.set_flag(CONFESSION_FLAG)
	GameState.set_flag("seen_wayshell")
	var room: Node2D = game.current_room
	var scene := _scene()
	await scene.wait(1.0)
	await scene.walk_route(room.global_position + ENDING_WATCH)
	scene.face(Vector2.UP)
	await scene.wait(1.2)
	var vael := ChoirFigure.new("vael")
	vael.position = VAEL_IN[0]
	room.add_child(vael)
	await vael.walk_along(VAEL_IN.slice(1), 24.0, 1)
	vael.face(true)
	scene.face(Vector2.RIGHT)
	await scene.wait(0.8)
	vael.talking = true
	await scene.speak("vael", ["VAEL_END_1"])
	vael.talking = false
	# The grey robe drops at his feet: the keeper's coat was under it.
	var at := vael.position
	vael.queue_free()
	var heap := RobeHeap.new()
	heap.position = at + Vector2(12, 3)
	room.add_child(heap)
	var keeper := ChoirFigure.new("vael_keeper")
	keeper.position = at
	keeper.face(true)
	room.add_child(keeper)
	Audio.play_sfx("bell_quiet", null, 0.8)
	await scene.wait(1.4)
	keeper.talking = true
	await scene.speak("vael_keeper", ["VAEL_END_2", "VAEL_END_3"])
	keeper.talking = false
	await scene.wait(0.8)
	# Dawn: the screen goes to white light, not black.
	scene.set_veil_colour(Color(1.0, 0.96, 0.86))
	await scene.darken(2.0)
	await scene.veil_text(["ENDING_DAWN_1", "ENDING_DAWN_2"])
	# Home: Saltmarrow, with Hessa by the lighthouse.
	_move_to(SALTMARROW)
	var hessa := _find_npc("hessa")
	if hessa:
		game.player.global_position = hessa.global_position + HOME_FROM_HESSA
	scene.face(Vector2.UP)
	await scene.lift_veil(2.0)
	if hessa:
		await scene.lamp(hessa.global_position, Cutscene.LAMP_HERE)
	await scene.narrate(["ENDING_HOME_1", "ENDING_HOME_2"])
	await scene.lamp(game.player.global_position, Cutscene.LAMP_YES)
	await scene.wait(1.0)
	scene.set_veil_colour(Color.BLACK)
	await scene.darken(2.0)
	await scene.veil_text(["ENDING_SLEEP_1", "ENDING_SLEEP_2"])
	# After the credits, Continue starts at home.
	GameState.set_checkpoint(SALTMARROW, game.player.global_position - game.current_room.global_position)
	SaveManager.save_game()
	scene.finish()
	if DreamingHeart.roll_credits:
		get_tree().change_scene_to_file.call_deferred(DreamingHeart.CREDITS_SCENE)


func _heart_here() -> bool:
	return game.current_room != null and game.current_room.get_children().any(func(c: Node) -> bool: return c is DreamingHeart)


## Cutscene 21, "The Old One dreams": home after the credits, the Old One's
## hum comes up through the ground and the lighthouse swings its beam out
## out to sea through the village gate, towards the Maw. Hessa felt it too.
func the_old_one_dreams() -> void:
	GameState.set_flag(DREAM_FLAG)
	var room: Node = game.current_room
	var scene := _scene()
	await scene.wait(1.2)
	Audio.play_sfx("old_one_hum", null, 0.9)
	Feel.shake(2.0)
	await scene.wait(1.4)
	var beam := LighthouseBeam.at_lighthouse(room)
	if beam:
		beam.strength = 0.0
		var glow := beam.create_tween()
		glow.tween_property(beam, "strength", 1.0, Cutscene.scaled(0.8))
		await beam.turn(LighthouseBeam.START, Cutscene.scaled(3.0))
	await scene.wait(1.0)
	var hessa := _find_npc("hessa")
	if hessa:
		await scene.walk_around_to(hessa.global_position + HOME_FROM_HESSA)
		scene.face(Vector2.UP)
		await scene.lamp(hessa.global_position, Cutscene.LAMP_HERE)
	await scene.speak("hessa", ["HESSA_DREAM_1", "HESSA_DREAM_2"])
	await scene.lamp(game.player.global_position, Cutscene.LAMP_YES)
	Audio.play_sfx("mantle_wings")
	scene.finish()


## Swap the room behind a veil, without the door fade.
func _move_to(coord: Vector2i) -> void:
	game.current_room.queue_free()
	game.current_room = game._spawn_room(coord)
	game.player.global_position = game.current_room.global_position + game.current_room.player_spawn
	game.camera.position = game._room_center(game.current_room)
	GameState.room_coord = coord
	GameState.dungeon = game.current_room.dungeon
	Events.room_entered.emit(coord)


## The carved slab on the tomb's north wall, once the Regent has fallen.
func _put_up_mural() -> LastMural:
	var room: Node = game.current_room
	for child in room.get_children():
		if child is LastMural:
			return child
	var mural := LastMural.new()
	room.add_child(mural)
	return mural


## Cutscene 5, "Bell rung": the phrase leaves the bell as a stream of notes
## and settles into Wren, then the bell's ringing is told. The stream
## grows with every phrase Wren knows. After the Storm Bell, the Old One turns.
func bell_rung(bell: Tidebell) -> void:
	var words := bell.words()
	var which := bell.bell
	var from := bell.position
	var parent := bell.get_parent()
	# Never two scenes at once: let one already running finish first.
	while Cutscene.active:
		await get_tree().process_frame
	if not is_instance_valid(parent) or not is_instance_valid(game.player):
		return
	var scene := _scene()
	var phrase := BellPhrase.new()
	phrase.notes = 3 + 2 * maxi(GameState.item_count("tidebell"), 1)
	phrase.target = game.player
	phrase.position = from
	parent.add_child(phrase)
	# Face the bell, along one of the four ways Wren can face.
	var to_bell: Vector2 = phrase.global_position - game.player.global_position
	if absf(to_bell.x) > absf(to_bell.y):
		scene.face(Vector2(signf(to_bell.x), 0))
	else:
		scene.face(Vector2.DOWN if to_bell.y > 0.0 else Vector2.UP)
	await get_tree().create_timer(phrase.duration() - Cutscene.scaled(PHRASE_PULSE), true, false, true).timeout
	# The bell itself may be gone by now (a test, or the room unloading).
	GameState.refill()
	GameState.add_resonance(GameState.resonance_max)
	if is_instance_valid(game) and is_instance_valid(game.player):
		Audio.play_sfx("hum_heal", game.player.global_position)
	await scene.wait(1.0)
	await scene.narrate(words)
	if which == "gale" and not GameState.has_flag(TURNED_FLAG):
		the_old_one_turns(scene)
	else:
		scene.finish()


func _find_npc(kind: String) -> Npc:
	if game.current_room == null:
		return null
	for child in game.current_room.get_children():
		if child is Npc and child.kind == kind:
			return child
	return null
