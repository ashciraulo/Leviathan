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
## Cutscene 14, Lowe in the water: Knell sinks, the hall's water surges,
## and Sister Lowe comes up fighting it below the island's edge.
const BELFRY_BOSS := Vector2i(36, 7)
const LOWE_WATER_FLAG := "seen_lowe_water"
const LOWE_SURFACES := Vector2(14 * 16 + 8, 8 * 16 + 12)
const WREN_REACHES := Vector2(14 * 16 + 8, 7 * 16 + 8)
const LOWE_HAULED := Vector2(15 * 16 + 8, 7 * 16 + 10)
## Into the deep on the far side, across, and out over the walkway and door.
const LOWE_SWIMS := [Vector2(16 * 16 + 12, 7 * 16 + 14), Vector2(17 * 16 + 8, 9 * 16 + 8), Vector2(17 * 16 + 8, 10 * 16 + 14)]
const LOWE_OUT := [Vector2(17 * 16 + 8, 11 * 16 + 10), Vector2(12 * 16, 11 * 16 + 10)]
const LOWE_DOOR := Vector2(12 * 16, 13 * 16 + 4)
## Cutscene 16, Tobin's warning: on Skull Rise, coming up out of the Marrow
## Tomb with the seventh bell rung, a young singer comes running from the
## west. Then home: Tobin stands by his dad on the dock until Wren comes.
const SKULL_RISE := Vector2i(9, 0)
const TOMB_BELL_FLAG := "tidebell_" + "tomb"
const TOBIN_WARNED_FLAG := "tobin_warned"
const TOBIN_HOME_FLAG := "tobin_home"
const TOBIN_RUNS_IN := [Vector2(-8, 6 * 16 + 8), Vector2(9 * 16 + 8, 7 * 16 + 10)]
const TOBIN_LEAVES := [Vector2(5 * 16, 6 * 16 + 8), Vector2(-12, 6 * 16 + 8)]
## On the dock, beside Dunstan (who stands at tile 16, 7).
const TOBIN_HOME_AT := Vector2(18 * 16 + 8, 7 * 16 + 12)
const WREN_AT_DOCK := Vector2(17 * 16 + 8, 9 * 16 + 4)
## Cutscene 17, rowing to the Maw: talk to Hessa at home once the seventh
## bell has rung and she rows Wren out to Lullaby Point; go on foot instead
## and she's there already, waiting in the boat.
const LULLABY_POINT := Vector2i(2, 1)
const ROW_ASKED_FLAG := "hessa_rows"
const ROWED_FLAG := "hessa_rowed"
const BOAT_AT := Vector2(6 * 16 + 8, 6 * 16 + 4)
const WREN_AT_BOAT := Vector2(6 * 16 + 8, 8 * 16 + 12)
const BOAT_LEAVES := Vector2(-40, 6 * 16 + 8)
## Ide's ferry over the Causeway End channel, once the Verge has risen.
## Talking to her, or ringing the bell on the far landing, sets FERRY_FLAG.
const CAUSEWAY_END := Vector2i(1, 2)
const FERRY_FLAG := "ide_ferry"
const IDE_AT := Vector2(19 * 16 + 8, 2 * 16 + 10)
const FERRY_NORTH := Vector2(19 * 16 + 8, 3 * 16 + 12)
const FERRY_SOUTH := Vector2(19 * 16 + 8, 8 * 16 + 4)
const WREN_NORTH := Vector2(17 * 16 + 8, 2 * 16 + 10)
const WREN_NORTH_EAST := Vector2(21 * 16 + 8, 2 * 16 + 10)
const WREN_SOUTH := Vector2(21 * 16 + 8, 9 * 16 + 12)
const FERRY_BELL_AT := Vector2(17 * 16 + 4, 9 * 16 + 14)
const FERRY_ROW_TIME := 3.0
## Liesl at the head of Drowned Lane, looking out over the flats to her
## great-grandmother's cottage; and that cottage's door bell, lost on Belfry
## Square's flats until Wren finds it, then hung back by the door.
const DROWNED_LANE := Vector2i(0, 3)
const BELFRY_SQUARE := Vector2i(1, 3)
const LIESL_AT := Vector2(10 * 16 + 8, 3 * 16 + 10)
const DOORBELL_LOST_AT := Vector2(20 * 16 + 8, 7 * 16 + 12)
## Wick at Fenmouth, and the fen's five dark lanterns (FenLantern.SPOTS).
const FENMOUTH := Vector2i(4, 1)
const WICK_AT := Vector2(17 * 16 + 8, 5 * 16 + 10)
## Gully dozing beside the Lantern Wake's figurehead on Wreck Strand, and
## his strongbox out in the pool.
const GULLY_AT := Vector2(10 * 16 + 8, 2 * 16 + 10)
## The last singers after the ending (Sister Lowe's errand): kind ->
## [room, tile], each alone and a little out of the way. Bram goes to work
## at Agna's forge once he's home.
const SINGERS := {
	"bram": [Vector2i(7, -1), Vector2i(18, 3)],
	"sela": [Vector2i(0, -3), Vector2i(5, 3)],
	"pim": [Vector2i(3, 2), Vector2i(19, 2)],
	"ansel": [Vector2i(3, -4), Vector2i(21, 5)],
}
const KILN_MOUTH := Vector2i(10, -2)
const BRAM_FORGE_AT := Vector2(16 * 16 + 8, 5 * 16 + 10)
## The Edge Survey: Ferrin camps on Edgewatch Bluff, past the far north of
## Windmere, and gives Wren stakes for the ends of three other far reaches
## ({id: [room, tile]}, filled in as each reach is built).
const FERRIN_ROOM := Vector2i(4, -5)
const FERRIN_AT := Vector2(12 * 16 + 8, 7 * 16 + 10)
const SURVEY_STAKES := {
	"frost": [Vector2i(1, -5), Vector2i(19, 5)],
	"cinder": [Vector2i(10, -3), Vector2i(19, 2)],
	"verge": [Vector2i(0, 5), Vector2i(9, 4)],
}
## The Old One's scales, for Agna's hand-bell: one in each puzzle cave
## ({id: [room, tile]}, ShedScale.IDS).
const SHED_SCALES := {
	"dragline": [Vector2i(-1, 0), Vector2i(3, 7)],
	"rimelight": [Vector2i(-1, -3), Vector2i(2, 7)],
	"emberwell": [Vector2i(10, -1), Vector2i(22, 3)],
	"drybone": [Vector2i(11, 0), Vector2i(20, 6)],
	"gustway": [Vector2i(3, -5), Vector2i(1, 4)],
	"lampless": [Vector2i(5, 3), Vector2i(3, 2)],
}
## Nettle's signals: the old keepers' signal stones on three high far
## headlands ({id: [room, tile]}).
const SIGNAL_STONES := {
	"stacks": [Vector2i(5, -5), Vector2i(8, 3)],
	"skerry": [Vector2i(6, -5), Vector2i(18, 7)],
	"brink": [Vector2i(8, 3), Vector2i(5, 8)],
}
## The Ebb Grotto, by the Sunken Verge: the flood marks on its wall.
const EBB_GROTTO := Vector2i(0, 4)
const GROTTO_MARKS_AT := Vector2(6 * 16 + 8, 3 * 16 + 8)
## The Calf's Rest, south of Gloamfen: {room: tile} of the little skull.
const CALF_REST := {Vector2i(7, 3): Vector2i(12, 5)}
## The Ebb Shelf, bared only while the tide is held out: Gully goes out to
## its one dry sandbar, by the lantern-boat the ebb uncovered.
const EBB_SHELF := Vector2i(1, 4)
const GULLY_EBB_AT := Vector2(12 * 16 + 8, 5 * 16 + 10)
const FIGUREHEAD_AT := Vector2(8 * 16 + 8, 2 * 16 + 14)
const STRONGBOX_AT := Vector2(13 * 16 + 8, 4 * 16 + 12)
## Captain Sorrel on Gullwatch Steps' north bank, and the far post on the
## south bank her kite races Wren to, across the water.
const GULLWATCH_STEPS := Vector2i(3, -3)
const SORREL_AT := Vector2(16 * 16 + 8, 2 * 16 + 10)
const KITE_POST_AT := Vector2(20 * 16 + 8, 9 * 16 + 12)
const RACE_FLAG := "sorrel_race"
const RACE_WON_FLAG := "sorrel_won"
## The way her kite flies, and how long it takes: a glide straight over the
## water gets there first; the long way round by the planks doesn't.
const KITE_ROUTE := [
	Vector2(16 * 16 + 14, 2 * 16 + 6),
	Vector2(19 * 16, 3 * 16 + 8),
	Vector2(22 * 16, 6 * 16),
	Vector2(20 * 16 + 8, 9 * 16 + 4),
]
const KITE_TIME := 3.0
## Ottilie on Still Cove's east shore, by her fishing hole.
const STILL_COVE := Vector2i(0, -2)
const OTTILIE_AT := Vector2(17 * 16 + 8, 8 * 16 + 10)
const FISHING_HOLE_AT := Vector2(19 * 16 + 8, 8 * 16 + 12)
## Coralie on Saltmarrow Shore, beside her sea-glass chime.
const SHORE := Vector2i(0, 0)
const CORALIE_AT := Vector2(17 * 16 + 8, 3 * 16 + 10)
const CHIME_AT := Vector2(20 * 16 + 8, 3 * 16 + 12)
## After the ending, Sister Lowe stands alone on Lullaby Point, watching
## the Maw where Vael keeps watch.
const LOWE_AT := Vector2(16 * 16 + 8, 8 * 16 + 10)
## Nettle's signal in the ending is answered from beyond the village's
## south gate, the way to the shore and the bay.
const BAY_ANSWER := Vector2(12 * 16, 12 * 16 + 10)
## Murmur, out of the Choir after the calf, helps Wick tend Fenmouth's
## lanterns.
const MURMUR_FEN_AT := Vector2(14 * 16 + 8, 4 * 16 + 10)
## After the ending, Mother Dace sits with the bones by the last mural.
const DACE_AFTER_AT := Vector2(12 * 16 + 8, 2 * 16 + 10)
## How near the post counts as there.
const POST_REACH := 16.0
const DOORBELL_HUNG_AT := Vector2(11 * 16 + 24, 10 * 16 + 15)
## Cutscene 18, Vael's choir: the first time Wren walks into Vael's hall,
## the whole Choir is singing the Waking Song. More singers than fight him
## stand along the hall (tiles), and slip away once his song is broken.
const MAW_VAEL := Vector2i(44, 7)
const CHOIR_FLAG := "seen_vaels_choir"
const CHOIR_EXTRAS := [Vector2i(3, 5), Vector2i(7, 6), Vector2i(16, 6), Vector2i(20, 5)]
const ENDING_FLAG := "seen_ending"
## Cutscene 13, the frozen journal: pages frozen through the Hollow Glacier
## (room: [tile, page]), and the last in the boss's room once Rimeback calms.
const JOURNAL_PAGES := {
	Vector2i(32, 10): [Vector2i(17, 1), 1],
	Vector2i(31, 10): [Vector2i(12, 1), 2],
	Vector2i(32, 9): [Vector2i(16, 2), 3],
	Vector2i(33, 9): [Vector2i(18, 1), 4],
	Vector2i(33, 8): [Vector2i(13, 1), 5],
}
const GLACIER_BOSS := Vector2i(32, 7)
const LAST_PAGE_TILE := Vector2i(5, 1)
const JOURNAL_FLAG := "seen_frozen_journal"
## Where the vision's young keepers stand (Wren watches from the page),
## and the way Vael walks out.
const YOUNG_HESSA_AT := Vector2(7 * 16 + 8, 5 * 16 + 12)
const YOUNG_VAEL_AT := Vector2(15 * 16 + 8, 5 * 16 + 12)
const VAEL_LEAVES := [Vector2(15 * 16 + 8, 9 * 16 + 12), Vector2(12 * 16 + 0, 10 * 16 + 12), Vector2(12 * 16 + 0, 12 * 16 + 12)]
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
	Events.boss_defeated.connect(_on_boss_defeated)


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
	# A remembered fight (EchoTrial) is the room as it was before the mural.
	var echo := EchoTrial.boss != ""
	if coord == TOMB_BOSS and GameState.has_flag(HollowRegent.DEFEATED_FLAG) and not echo:
		_put_up_mural()
	if not echo:
		_put_up_journal(coord)
	if coord == SALTMARROW and GameState.has_flag(TOBIN_HOME_FLAG):
		_put_tobin_home()
	if coord == DROWNED_LANE or coord == BELFRY_SQUARE:
		_put_liesl(coord)
	if coord == FENMOUTH or FenLantern.SPOTS.has(coord):
		_put_wick(coord)
	if coord == FENMOUTH and GameState.has_flag(CALF_FLAG):
		_put_npc("murmur", MURMUR_FEN_AT)
	if coord == TOMB_BOSS and GameState.has_flag(ENDING_FLAG) and GameState.has_flag(MURAL_FLAG) and not echo:
		_put_npc("dace", DACE_AFTER_AT)
	if coord == WRECK_STRAND:
		_put_gully()
	if coord == EBB_SHELF:
		_put_lantern_boat()
	if GameState.has_flag(ENDING_FLAG):
		_put_singers(coord)
	if coord == EBB_GROTTO:
		_put_grotto_marks()
	if coord == FERRIN_ROOM:
		_put_npc("ferrin", FERRIN_AT)
	_put_survey_stake(coord)
	_put_shed_scale(coord)
	_put_signal_stone(coord)
	if CALF_REST.has(coord):
		_put_calf_skull(CALF_REST[coord])
	if coord == STILL_COVE:
		_put_ottilie()
	# Coralie comes down to the shore once the opening's done with it.
	if coord == SHORE and GameState.has_flag("met_hessa"):
		_put_coralie()
	if coord == LULLABY_POINT and GameState.has_flag(ENDING_FLAG):
		_put_lowe()
	if coord == GULLWATCH_STEPS:
		# A race the game closed partway through is simply over.
		if GameState.has_flag(RACE_FLAG):
			GameState.clear_flag(RACE_FLAG)
		_put_sorrel()
	if coord == CAUSEWAY_END and GameState.has_flag(TURNED_FLAG):
		# A ride the game closed partway through: she's home again.
		if GameState.has_flag(FERRY_FLAG):
			GameState.clear_flag(FERRY_FLAG)
		_put_ide()
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
	elif coord == TOMB_BOSS and GameState.has_flag(HollowRegent.DEFEATED_FLAG) and not GameState.has_flag(MURAL_FLAG) and not echo:
		# A save from before the mural existed: show it on the way back in.
		the_last_mural()
	elif coord == LULLABY_POINT and GameState.has_flag(TOMB_BELL_FLAG) and not GameState.has_flag(ROWED_FLAG) and not GameState.has_flag(ENDING_FLAG):
		hessa_at_the_maw(false)
	elif coord == SKULL_RISE and GameState.has_flag(TOMB_BELL_FLAG) and not GameState.has_flag(TOBIN_WARNED_FLAG) and not GameState.has_flag(ENDING_FLAG):
		tobins_warning()
	elif coord == SALTMARROW and GameState.has_flag(TOBIN_WARNED_FLAG) and not GameState.has_flag(TOBIN_HOME_FLAG) and not GameState.has_flag(ENDING_FLAG):
		tobin_comes_home()
	elif coord == MAW_VAEL and choir_waits() and not echo:
		vaels_choir()
	elif lowe_waits(coord):
		if coord == HULL_BOSS:
			lowe_at_the_hull()
		else:
			the_crucible()


func _on_flag_changed(flag: String, _value: Variant) -> void:
	if flag == RACE_FLAG:
		if GameState.has_flag(RACE_FLAG):
			if Cutscene.active or GameState.room_coord != GULLWATCH_STEPS:
				GameState.clear_flag.call_deferred(RACE_FLAG)
			else:
				sorrel_race()
		return
	if flag == FERRY_FLAG:
		if not GameState.has_flag(FERRY_FLAG):
			return
		if Cutscene.active or GameState.room_coord != CAUSEWAY_END:
			GameState.clear_flag.call_deferred(FERRY_FLAG)
		else:
			ide_ferries()
		return
	if Cutscene.active:
		return
	if flag == PaleCongregation.DEFEATED_FLAG and GameState.room_coord == MIRE_BOSS and not GameState.has_flag(CALF_FLAG):
		the_calf()
	elif flag == Stormheron.DEFEATED_FLAG and GameState.room_coord == GALE_BOSS and not GameState.has_flag(VAEL_FLAG):
		vael_at_the_spire()
	elif flag == GALE_BELL_FLAG and not GameState.has_flag(TURNED_FLAG):
		the_old_one_turns()
	elif flag == ROW_ASKED_FLAG and GameState.room_coord == SALTMARROW:
		rowing_to_the_maw()
	elif flag == HollowRegent.DEFEATED_FLAG and GameState.room_coord == TOMB_BOSS and not GameState.has_flag(MURAL_FLAG):
		the_last_mural()


## Some bosses mark themselves beaten without a flag_changed, so their
## scenes wait on the fight's end instead. Not in a remembered fight.
func _on_boss_defeated() -> void:
	if Cutscene.active or EchoTrial.boss != "":
		return
	var coord := GameState.room_coord
	if coord == GLACIER_BOSS:
		_put_up_journal(GLACIER_BOSS, true)
	elif coord == BELFRY_BOSS and not GameState.has_flag(LOWE_WATER_FLAG):
		lowe_in_the_water()
	elif coord == MAW_VAEL:
		# His song broken, the rest of the Choir slips away.
		for singer in get_tree().get_nodes_in_group("choir_extra"):
			var figure := singer as ChoirFigure
			figure.walk_along([figure.position + Vector2(0, 5 * Room.TILE)], 26.0, -1)


## True while Vael's choir is still to be heard: he waits, singing, until
## the scene wakes him.
static func choir_waits() -> bool:
	return not GameState.has_flag(CHOIR_FLAG) and not GameState.has_flag(CantorVael.DEFEATED_FLAG)


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
	scene.music("story_choir")
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
	scene.music("story_choir")
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
	scene.music("story_memory")
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
	scene.music("story_choir")
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
	scene.music("story_danger")
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
	scene.music("story_sorrow")
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


## Cutscene 14, "Lowe in the water": with Knell gone the hall's water
## surges, and Sister Lowe, who got in ahead of Wren, comes up below the
## island's edge, going under. Wren hauls her out. She coughs, looks at
## Wren a long moment, and leaves without a word: back into the deep and
## out by the door.
func lowe_in_the_water() -> void:
	GameState.set_flag(LOWE_WATER_FLAG)
	var room: Node2D = game.current_room
	var scene := _scene()
	# Knell slips under and the bell sinks after it; the water answers.
	await scene.wait(2.6)
	Audio.play_sfx("water_rush", room.global_position + LOWE_SURFACES)
	Feel.shake(3.0)
	await scene.wait(0.5)
	var lowe := ChoirFigure.new("lowe")
	lowe.position = LOWE_SURFACES
	lowe.sunk = 21.0
	lowe.struggling = true
	room.add_child(lowe)
	Audio.play_sfx("splash", room.global_position + LOWE_SURFACES, 1.2)
	var up := lowe.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	up.tween_property(lowe, "sunk", 12.0, Cutscene.scaled(0.35)).set_ease(Tween.EASE_OUT)
	# Wren runs to the edge while she fights to keep her head up.
	await scene.walk_route(room.global_position + WREN_REACHES, false)
	scene.face(Vector2.DOWN)
	for i in 2:
		Audio.play_sfx("splash", room.global_position + LOWE_SURFACES, 0.9 + i * 0.2)
		await scene.wait(0.7)
	# She goes under once, and comes back up.
	lowe.struggling = false
	var under := lowe.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	under.tween_property(lowe, "sunk", 20.0, Cutscene.scaled(0.4))
	await under.finished
	Audio.play_sfx("water_rush", room.global_position + LOWE_SURFACES, 0.6)
	await scene.wait(0.6)
	# Wren reaches down and hauls her up onto the stone.
	Feel.shake(1.0)
	Audio.play_sfx("splash", room.global_position + LOWE_SURFACES, 0.7)
	var haul := lowe.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	haul.tween_property(lowe, "sunk", 0.0, Cutscene.scaled(0.5)).set_ease(Tween.EASE_OUT)
	haul.tween_property(lowe, "position", LOWE_HAULED, Cutscene.scaled(0.5)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await haul.finished
	lowe.dripping = true
	lowe.face(true)
	scene.face(Vector2.RIGHT)
	# Coughing up the Belfry.
	for i in 3:
		lowe.position.y += 1.0
		await scene.wait(0.18)
		lowe.position.y -= 1.0
		await scene.wait(0.32)
	await scene.wait(0.6)
	# She almost says something.
	lowe.talking = true
	await scene.wait(0.35)
	lowe.talking = false
	await scene.wait(1.6)
	# Not a word. Back into the water, the long way round, and gone.
	lowe.face(false)
	await scene.wait(0.4)
	var dive := lowe.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	dive.tween_property(lowe, "position", LOWE_SWIMS[0], Cutscene.scaled(0.3))
	dive.tween_property(lowe, "sunk", 16.0, Cutscene.scaled(0.3))
	await dive.finished
	lowe.dripping = false
	Audio.play_sfx("splash", room.global_position + LOWE_SWIMS[0], 1.1)
	scene.face(Vector2.DOWN)
	await lowe.walk_along(LOWE_SWIMS.slice(1), 38.0)
	var climb := lowe.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	climb.tween_property(lowe, "position", LOWE_OUT[0], Cutscene.scaled(0.35))
	climb.tween_property(lowe, "sunk", 0.0, Cutscene.scaled(0.35))
	await climb.finished
	lowe.dripping = true
	await lowe.walk_along(LOWE_OUT.slice(1), 46.0)
	# At the door, half a look back.
	lowe.face(false)
	await scene.wait(0.9)
	await lowe.walk_along([LOWE_DOOR], 46.0, -1)
	lowe.queue_free()
	await scene.wait(0.4)
	scene.finish()


## Cutscene 16, "Tobin's warning": up out of the Marrow Tomb with the
## seventh bell rung, a young singer comes running over the dunes. Tobin has
## left the Choir. He tells Wren where they've gone and how singers go in,
## and heads home to his dad.
func tobins_warning() -> void:
	GameState.set_flag(TOBIN_WARNED_FLAG)
	var room: Node2D = game.current_room
	var scene := _scene()
	scene.music("story_sorrow")
	await scene.wait(0.6)
	var tobin := ChoirFigure.new("tobin")
	tobin.position = TOBIN_RUNS_IN[0]
	room.add_child(tobin)
	await tobin.walk_along(TOBIN_RUNS_IN.slice(1), 60.0, 1)
	var wren_x: float = game.player.global_position.x - room.global_position.x
	scene.face(Vector2.LEFT if tobin.position.x < wren_x else Vector2.RIGHT)
	tobin.face(tobin.position.x > wren_x)
	await scene.wait(0.5)
	for key in ["TOBIN_DUNES_1", "TOBIN_DUNES_2", "TOBIN_DUNES_3", "TOBIN_DUNES_4"]:
		tobin.talking = true
		await scene.speak("tobin", [key])
		tobin.talking = false
	# He looks west, the way home, before he says it.
	tobin.face(true)
	await scene.wait(0.8)
	tobin.face(false)
	await scene.speak("tobin", ["TOBIN_DUNES_5"])
	await scene.wait(0.3)
	await tobin.walk_along(TOBIN_LEAVES, 40.0, -1)
	tobin.queue_free()
	scene.finish()


## Tobin, home, standing on the dock beside his dad.
func _put_tobin_home() -> void:
	var room: Node = game.current_room
	if room == null or _find_npc("tobin"):
		return
	var tobin := Npc.new("tobin")
	tobin.position = TOBIN_HOME_AT
	room.add_child(tobin)


## Tobin comes home: the first time Wren is back in Saltmarrow after the
## dunes, Tobin is on the dock beside Dunstan, still in the Choir's robe,
## and Dunstan finds more words than he's said all year.
func tobin_comes_home() -> void:
	var room: Node2D = game.current_room
	var scene := _scene()
	scene.music("story_sorrow")
	var tobin := ChoirFigure.new("tobin")
	tobin.position = TOBIN_HOME_AT
	tobin.face(true)
	room.add_child(tobin)
	await scene.wait(0.4)
	await scene.walk_route(room.global_position + WREN_AT_DOCK)
	scene.face(Vector2.UP)
	await scene.wait(0.6)
	await scene.speak("dunstan", ["DUNSTAN_TOBIN_1"])
	tobin.talking = true
	await scene.speak("tobin", ["TOBIN_HOME_1"])
	tobin.talking = false
	await scene.wait(0.4)
	await scene.speak("dunstan", ["DUNSTAN_TOBIN_2", "DUNSTAN_TOBIN_3"])
	tobin.talking = true
	await scene.speak("tobin", ["TOBIN_HOME_2"])
	tobin.talking = false
	await scene.wait(0.5)
	await scene.speak("dunstan", ["DUNSTAN_TOBIN_4"])
	GameState.set_flag(TOBIN_HOME_FLAG)
	tobin.queue_free()
	_put_tobin_home()
	scene.finish()


## Cutscene 17, "Rowing to the Maw": Hessa takes the oars. Dark water and
## the sound of rowing, then Lullaby Point from the sea.
func rowing_to_the_maw() -> void:
	var scene := _scene()
	# Let her finish what she's saying first.
	if DialogueBox.is_open:
		await Events.dialogue_finished
	await scene.darken(1.2)
	for i in 4:
		Audio.play_sfx("splash", null, 0.55 + 0.05 * (i % 2))
		await scene.wait(0.8)
	_move_to(LULLABY_POINT)
	hessa_at_the_maw(true, scene)


## Hessa in her boat off Lullaby Point, the Old One's lip rising out of the
## water beside them. She says her piece about Vael, signals she'll be
## there, and rows away home. `rowed`: Wren came out in the boat with her
## (and `carried` is that scene, still dark).
func hessa_at_the_maw(rowed: bool, carried: Cutscene = null) -> void:
	GameState.set_flag(ROWED_FLAG)
	var room: Node2D = game.current_room
	var scene := carried if carried else _scene()
	scene.music("story_sorrow")
	var boat := Rowboat.new()
	boat.position = BOAT_AT
	room.add_child(boat)
	if rowed:
		game.player.global_position = room.global_position + WREN_AT_BOAT
		scene.face(Vector2.UP)
		await scene.wait(0.3)
		await scene.lift_veil(1.4)
	else:
		await scene.wait(0.4)
		await scene.walk_route(room.global_position + WREN_AT_BOAT)
		scene.face(Vector2.UP)
		await scene.wait(0.3)
	await scene.wait(0.6)
	if not rowed:
		await scene.speak("hessa", ["HESSA_MAW_0"])
	await scene.speak("hessa", ["HESSA_MAW_1", "HESSA_MAW_2"])
	await scene.wait(0.4)
	await scene.speak("hessa", ["HESSA_MAW_3"])
	# I'm here; and Wren's yes.
	await scene.lamp(room.global_position + BOAT_AT + Vector2(-6, -12), Cutscene.LAMP_HERE)
	await scene.wait(0.3)
	await scene.lamp(game.player.global_position, Cutscene.LAMP_YES)
	await scene.wait(0.4)
	# She pulls away west along the shore, home.
	var away := boat.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	away.tween_property(boat, "position", BOAT_LEAVES, Cutscene.scaled(4.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	away.parallel().tween_property(boat, "modulate:a", 0.0, Cutscene.scaled(1.0)).set_delay(Cutscene.scaled(3.5))
	for i in 3:
		Audio.play_sfx("splash", room.global_position + boat.position, 0.6)
		await scene.wait(1.2)
	await away.finished
	boat.queue_free()
	scene.finish()


## Ide on the north shore of Causeway End, her boat tied up below her, and
## once the Belfry's bell is quiet, a hand bell on the far landing to call
## her over with.
func _put_ide() -> void:
	var room: Node = game.current_room
	if room == null or _find_npc("ide"):
		return
	var ide := Npc.new("ide")
	ide.position = IDE_AT
	room.add_child(ide)
	var boat := Rowboat.new()
	boat.rider_kind = ""
	boat.position = FERRY_NORTH
	room.add_child(boat)
	if GameState.has_flag("tidebell_belfry"):
		var bell := FerryBell.new()
		bell.position = FERRY_BELL_AT
		room.add_child(bell)


## Liesl and her great-grandmother's door bell: Liesl sweeping at the head
## of Drowned Lane, and the bell out on Belfry Square's flats while she
## waits for it, or back by the drowned cottage's door once she has it.
func _put_liesl(coord: Vector2i) -> void:
	var room: Node = game.current_room
	if room == null:
		return
	if coord == DROWNED_LANE:
		if not _find_npc("liesl"):
			var liesl := Npc.new("liesl")
			liesl.position = LIESL_AT
			room.add_child(liesl)
		if GameState.has_flag("liesl_bell_hung") and not room.get_children().any(func(c: Node) -> bool: return c is Doorbell):
			var bell := Doorbell.new()
			bell.hung = true
			bell.position = DOORBELL_HUNG_AT
			room.add_child(bell)
	elif coord == BELFRY_SQUARE and GameState.has_flag("liesl_asked") and not GameState.has_flag("found_doorbell"):
		var lost := Doorbell.new()
		lost.position = DOORBELL_LOST_AT
		room.add_child(lost)


## Wick at Fenmouth, or the room's memorial lantern out in the fen.
func _put_wick(coord: Vector2i) -> void:
	var room: Node = game.current_room
	if room == null:
		return
	if coord == FENMOUTH and not _find_npc("wick"):
		var wick := Npc.new("wick")
		wick.position = WICK_AT
		room.add_child(wick)
	if FenLantern.SPOTS.has(coord) and not room.get_children().any(func(c: Node) -> bool: return c is FenLantern):
		var lantern := FenLantern.new()
		lantern.room_coord = coord
		var tile: Vector2i = FenLantern.SPOTS[coord]
		lantern.position = Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12)
		room.add_child(lantern)


## Gully and the figurehead he keeps company, and his strongbox in the
## pool until it's hauled in (it shows itself once he's asked).
func _put_gully() -> void:
	var room: Node = game.current_room
	if room == null:
		return
	for child in room.get_children():
		if child is Prop and child.kind == "figurehead":
			return
	var figurehead := Prop.new("figurehead")
	figurehead.position = FIGUREHEAD_AT
	room.add_child(figurehead)
	# With the tide held out (and his strongbox home), Gully is out
	# salvaging on the Ebb Shelf.
	if not _gully_on_the_shelf():
		var gully := Npc.new("gully")
		gully.position = GULLY_AT
		room.add_child(gully)
	if not GameState.has_flag("gully_box_hauled"):
		var box := Strongbox.new()
		box.position = STRONGBOX_AT
		room.add_child(box)


## Ottilie and her fishing hole.
func _put_ottilie() -> void:
	var room: Node = game.current_room
	if room == null or _find_npc("ottilie"):
		return
	var ottilie := Npc.new("ottilie")
	ottilie.position = OTTILIE_AT
	room.add_child(ottilie)
	var hole := FishingHole.new()
	hole.position = FISHING_HOLE_AT
	room.add_child(hole)


## Sister Lowe on the point, after the ending.
func _put_lowe() -> void:
	_put_npc("lowe", LOWE_AT)


## Ferrin's survey stake (or the cairn where it goes) at the end of a reach.
func _put_survey_stake(coord: Vector2i) -> void:
	var room: Node = game.current_room
	for id: String in SURVEY_STAKES:
		var spot: Array = SURVEY_STAKES[id]
		if spot[0] != coord or room == null:
			continue
		for child in room.get_children():
			if child is SurveyStake:
				return
		var stake := SurveyStake.new()
		stake.id = id
		stake.position = Vector2(spot[1]) * 16.0 + Vector2(8, 14)
		room.add_child(stake)


## A shed scale in a puzzle cave, until Wren picks it up.
func _put_shed_scale(coord: Vector2i) -> void:
	var room: Node = game.current_room
	for id: String in SHED_SCALES:
		var spot: Array = SHED_SCALES[id]
		if spot[0] != coord or room == null or GameState.has_flag(ShedScale.flag_for(id)):
			continue
		if room.get_children().any(func(c: Node) -> bool: return c is ShedScale):
			return
		var piece := ShedScale.new()
		piece.id = id
		piece.position = Vector2(spot[1]) * 16.0 + Vector2(8, 14)
		room.add_child(piece)


## An old signal stone on a far headland.
func _put_signal_stone(coord: Vector2i) -> void:
	var room: Node = game.current_room
	for id: String in SIGNAL_STONES:
		var spot: Array = SIGNAL_STONES[id]
		if spot[0] != coord or room == null:
			continue
		if room.get_children().any(func(c: Node) -> bool: return c is SignalStone):
			return
		var stone := SignalStone.new()
		stone.id = id
		stone.position = Vector2(spot[1]) * 16.0 + Vector2(8, 14)
		room.add_child(stone)


## Wren's lamp on a signal stone says "I'm here" down the coast, and far
## off, from Saltmarrow's lighthouse, a small light answers.
func signal_from_stone(stone: SignalStone) -> void:
	if Cutscene.active or game.current_room == null:
		return
	var room: Room = game.current_room
	var scene := _scene()
	await scene.lamp(stone.global_position + Vector2(0, -SignalStone.HEIGHT - 2), Cutscene.LAMP_HERE)
	await scene.wait(0.9)
	if not is_instance_valid(room) or not room.is_inside_tree():
		scene.finish()
		return
	# The answer comes from the direction of home, at the very edge of
	# sight, small with distance.
	var home := Vector2(SALTMARROW - room.coord).normalized()
	var reach := Room.SIZE / 2.0 - Vector2(10, 10)
	var t := minf(reach.x / maxf(absf(home.x), 0.001), reach.y / maxf(absf(home.y), 0.001))
	var far := room.global_position + Room.SIZE / 2.0 + home * t
	var glow := LampGlow.new(Cutscene.LAMP_HERE)
	glow.position = far
	glow.scale = Vector2(0.4, 0.4)
	game.world.add_child(glow)
	await glow.done
	await scene.narrate(["NARRATE_SIGNAL_ANSWER"])
	scene.finish()


## The flood marks on the Ebb Grotto's wall.
func _put_grotto_marks() -> void:
	var room: Node = game.current_room
	if room == null:
		return
	for child in room.get_children():
		if child is GrottoMarks:
			return
	var marks := GrottoMarks.new()
	marks.position = GROTTO_MARKS_AT
	room.add_child(marks)


## The calf's skull in the far fen.
func _put_calf_skull(tile: Vector2i) -> void:
	var room: Node = game.current_room
	if room == null:
		return
	for child in room.get_children():
		if child is CalfSkull:
			return
	var skull := CalfSkull.new()
	skull.position = Vector2(tile) * 16.0 + Vector2(8, 14)
	room.add_child(skull)


## Someone standing about in the current room, once.
func _put_npc(kind: String, at: Vector2) -> void:
	var room: Node = game.current_room
	if room == null or _find_npc(kind):
		return
	var npc := Npc.new(kind)
	npc.position = at
	room.add_child(npc)


## Coralie and her chime.
func _put_coralie() -> void:
	var room: Node = game.current_room
	if room == null or _find_npc("coralie"):
		return
	var coralie := Npc.new("coralie")
	coralie.position = CORALIE_AT
	room.add_child(coralie)
	var chime := GlassChime.new()
	chime.position = CHIME_AT
	room.add_child(chime)


## The last singers, where Lowe's errand finds them; Bram at the forge.
func _put_singers(coord: Vector2i) -> void:
	for kind: String in SINGERS:
		var spot: Array = SINGERS[kind]
		if spot[0] == coord and not GameState.has_flag(kind + "_home"):
			_put_npc(kind, Vector2(spot[1]) * 16.0 + Vector2(8, 10))
	if coord == KILN_MOUTH and GameState.has_flag("bram_home"):
		_put_npc("bram", BRAM_FORGE_AT)


static func _gully_on_the_shelf() -> bool:
	return Tide.held() == "low" and GameState.has_flag("gully_paid")


## The lantern-boat on the Ebb Shelf, and Gully beside it while the tide is
## held out.
func _put_lantern_boat() -> void:
	var room: Node = game.current_room
	if room == null:
		return
	if _gully_on_the_shelf():
		_put_npc("gully_ebb", GULLY_EBB_AT)
	for child in room.get_children():
		if child is LanternBoat:
			return
	# The room's own wreck prop becomes one Wren can search.
	for child in room.get_children():
		if child is Prop and child.kind == "W":
			var boat := LanternBoat.new()
			boat.position = child.position
			child.queue_free()
			room.add_child(boat)
			return


## Captain Sorrel and the far post of her old kite-post.
func _put_sorrel() -> void:
	var room: Node = game.current_room
	if room == null or _find_npc("sorrel"):
		return
	var sorrel := Npc.new("sorrel")
	sorrel.position = SORREL_AT
	room.add_child(sorrel)
	var post := KitePost.new()
	post.won = GameState.has_flag(RACE_WON_FLAG)
	post.position = KITE_POST_AT
	room.add_child(post)


func _kite_post() -> KitePost:
	for child in game.current_room.get_children():
		if child is KitePost:
			return child
	return null


## Sorrel's kite races Wren to the far post. Wren isn't held: they run,
## glide or go round as they like, and the first to the post wins.
func sorrel_race() -> void:
	var room: Node2D = game.current_room
	# The flag is set just before her words open: let her finish them.
	await get_tree().process_frame
	if DialogueBox.is_open:
		await Events.dialogue_finished
	if not is_instance_valid(room) or room != game.current_room:
		GameState.clear_flag(RACE_FLAG)
		return
	var kite := RaceKite.new()
	kite.route = KITE_ROUTE
	kite.duration = KITE_TIME
	room.add_child(kite)
	Audio.play_sfx("gust", room.global_position + SORREL_AT, 1.2)
	var post_at := room.global_position + KITE_POST_AT
	var won := false
	while true:
		await get_tree().physics_frame
		if not is_instance_valid(room) or room != game.current_room or not is_instance_valid(kite):
			# Wren left, or fell: the race is off.
			if GameState.has_flag(RACE_FLAG):
				GameState.clear_flag(RACE_FLAG)
			return
		var wren: Player = game.player
		if is_instance_valid(wren) and wren.state == Player.State.MOVE and not wren.airborne and wren.global_position.distance_to(post_at) <= POST_REACH:
			won = true
			break
		if kite.arrived:
			break
	GameState.clear_flag(RACE_FLAG)
	if won:
		GameState.set_flag(RACE_WON_FLAG)
		var post := _kite_post()
		if post:
			post.won = true
		Audio.play_jingle("jingle_secret")
	else:
		Audio.play_sfx("bell_quiet", post_at)
	# The kite drifts down (onto the post, if it got there) and is gathered in.
	kite.arrived = true
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(kite):
		kite.queue_free()


func _ferry_boat() -> Rowboat:
	for child in game.current_room.get_children():
		if child is Rowboat:
			return child
	return null


## Ide rows Wren over the Causeway End channel: to the south landing, or,
## when Wren rings the bell over there, back to her own shore. The crossing
## itself is dark water and the sound of her oars.
func ide_ferries() -> void:
	var room: Node2D = game.current_room
	var scene := _scene()
	# The flag is set just before her words open: let her finish them first.
	await get_tree().process_frame
	if DialogueBox.is_open:
		await Events.dialogue_finished
	var ide := _find_npc("ide")
	var boat := _ferry_boat()
	if ide == null or boat == null or not is_instance_valid(game.player):
		GameState.clear_flag(FERRY_FLAG)
		scene.finish()
		return
	var at := room.global_position
	var from_south: bool = game.player.global_position.y > at.y + 6 * Room.TILE
	if from_south:
		# She hears the bell, steps down into her boat and rows across.
		scene.face(Vector2.UP)
		await scene.wait(0.5)
		ide.visible = false
		boat.set_rider("ide")
		await scene.wait(0.3)
		await _row(boat, FERRY_SOUTH, scene)
		await _wave(boat, scene)
	else:
		# Down to the boat on Wren's own side of her, not through her.
		var east: bool = game.player.global_position.x > at.x + IDE_AT.x
		await scene.walk_route(at + (WREN_NORTH_EAST if east else WREN_NORTH))
		scene.face(Vector2.DOWN)
		ide.visible = false
		boat.set_rider("ide")
		await scene.wait(0.5)
	await scene.darken(0.8)
	for i in 3:
		Audio.play_sfx("splash", null, 0.55 + 0.05 * (i % 2))
		await scene.wait(0.7)
	if not is_instance_valid(room) or not is_instance_valid(boat) or not is_instance_valid(game.player):
		GameState.clear_flag(FERRY_FLAG)
		scene.finish()
		return
	boat.position = FERRY_NORTH if from_south else FERRY_SOUTH
	game.player.global_position = at + (WREN_NORTH if from_south else WREN_SOUTH)
	scene.face(Vector2.DOWN if from_south else Vector2.UP)
	await scene.wait(0.2)
	await scene.lift_veil(1.0)
	await scene.wait(0.4)
	if not from_south:
		# A wave from the oars, and she rows home.
		await _wave(boat, scene)
		await _row(boat, FERRY_NORTH, scene)
	if is_instance_valid(boat):
		boat.set_rider("")
	if is_instance_valid(ide):
		ide.visible = true
	GameState.clear_flag(FERRY_FLAG)
	scene.finish()


## Ide pulls the boat across to `to`, the oars splashing as she goes.
func _row(boat: Rowboat, to: Vector2, scene: Cutscene) -> void:
	var tween := boat.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(boat, "position", to, Cutscene.scaled(FERRY_ROW_TIME)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in 3:
		if not is_instance_valid(boat):
			return
		Audio.play_sfx("splash", boat.global_position, 0.6 + 0.05 * (i % 2))
		await scene.wait(FERRY_ROW_TIME / 3.0)
	if tween.is_valid() and tween.is_running():
		await tween.finished


## She lifts a hand from the oars.
func _wave(boat: Rowboat, scene: Cutscene) -> void:
	if not is_instance_valid(boat) or boat.rider == null:
		return
	boat.rider.talking = true
	await scene.wait(0.7)
	if is_instance_valid(boat) and boat.rider:
		boat.rider.talking = false


## Cutscene 18, "Vael's choir": deep in the Maw the whole Choir is singing
## the lullaby backwards, its notes falling cold into the floor, and the Old
## One stirs under them. As Wren comes up with the lamp lit, the singers
## fall silent one by one. Vael has his say, and the duel begins.
func vaels_choir() -> void:
	GameState.set_flag(CHOIR_FLAG)
	var room: Node2D = game.current_room
	var scene := _scene()
	scene.music("story_choir")
	var vael: CantorVael = null
	for child in room.get_children():
		if child is CantorVael:
			vael = child
	if vael == null:
		scene.finish()
		return
	# Let his own two singers take their places.
	await get_tree().process_frame
	var voices: Array[Node2D] = [vael]
	for child in room.get_children():
		if child is ChoirFigure:
			voices.append(child)
	for tile: Vector2i in CHOIR_EXTRAS:
		var singer := ChoirFigure.new("singer")
		singer.position = Vector2(tile.x * Room.TILE + Room.TILE / 2.0, tile.y * Room.TILE + 12)
		singer.face(tile.x > 11)
		singer.add_to_group("choir_extra")
		room.add_child(singer)
		voices.append(singer)
	var song := WakingSong.new()
	for voice in voices:
		song.sources.append(voice.position)
	room.add_child(song)
	# Wren comes up the hall into the song.
	Audio.play_sfx("vael_sing", vael.global_position, 0.6)
	await scene.walk_route(room.global_position + WATCH_FROM)
	if not is_instance_valid(vael) or not vael.is_inside_tree():
		scene.finish()
		return
	scene.face(Vector2.UP)
	Audio.play_sfx("vael_sing", vael.global_position, 0.5)
	await scene.wait(1.2)
	# Under the floor, the Old One turns towards it.
	Audio.play_sfx("old_one_hum", null, 0.6)
	Feel.shake(2.5)
	await scene.wait(1.6)
	if not is_instance_valid(vael) or not vael.is_inside_tree():
		scene.finish()
		return
	# Wren's lamp. The voices stop, nearest last, Vael's last of all.
	await scene.lamp(game.player.global_position, Cutscene.LAMP_HERE)
	if not is_instance_valid(vael) or not vael.is_inside_tree():
		scene.finish()
		return
	var order: Array = range(1, voices.size()).filter(func(i: int) -> bool: return is_instance_valid(voices[i]))
	order.sort_custom(func(a: int, b: int) -> bool: return voices[a].position.distance_to(WATCH_FROM) > voices[b].position.distance_to(WATCH_FROM))
	for i: int in order:
		if is_instance_valid(song):
			song.hush(i)
		var figure := voices[i] as ChoirFigure
		if is_instance_valid(figure):
			figure.face(figure.position.x > WATCH_FROM.x)
		await scene.wait(0.35)
	await scene.wait(0.5)
	if is_instance_valid(song):
		song.hush(0)
	await scene.wait(1.4)
	await scene.speak("vael", ["VAEL_MAW_1", "VAEL_MAW_2"])
	await scene.wait(0.3)
	if is_instance_valid(song):
		song.queue_free()
	if is_instance_valid(vael) and vael.is_inside_tree():
		vael.wake()
	scene.finish()


## Cutscene 15, "The last mural": with the Hollow Regent gone to bones,
## the wall he sealed falls open on the last carving. Mother Dace comes down
## into the tomb and shows Wren what it is: the Old One lying down beside its
## dead family. Then she leaves Wren to ring the Marrow Bell.
func the_last_mural() -> void:
	GameState.set_flag(MURAL_FLAG)
	var room: Node2D = game.current_room
	var scene := _scene()
	scene.music("story_memory")
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
	# Everyone's home by the end: Tobin on the dock, Hessa at the lamp.
	for flag in [TOBIN_WARNED_FLAG, TOBIN_HOME_FLAG, ROWED_FLAG]:
		GameState.set_flag(flag)
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
	_put_tobin_home()
	var hessa := _find_npc("hessa")
	if hessa:
		game.player.global_position = hessa.global_position + HOME_FROM_HESSA
	scene.face(Vector2.UP)
	await scene.lift_veil(2.0)
	if hessa:
		await scene.lamp(hessa.global_position, Cutscene.LAMP_HERE)
	await scene.narrate(["ENDING_HOME_1", "ENDING_HOME_2"])
	await scene.lamp(game.player.global_position, Cutscene.LAMP_YES)
	# Nettle, across the square with her paper lantern, signals too: yes,
	# and, if Wren taught her the long glow, I'm here. From beyond the gate,
	# towards the bay, someone answers.
	var nettle := _find_npc("nettle")
	if nettle:
		await scene.wait(0.4)
		await scene.lamp(nettle.global_position, Cutscene.LAMP_YES)
		if GameState.has_flag("nettle_learned"):
			await scene.lamp(nettle.global_position, Cutscene.LAMP_HERE)
			await scene.wait(0.8)
			await scene.lamp(game.current_room.global_position + BAY_ANSWER, Cutscene.LAMP_HERE)
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
	scene.music("story_memory")
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


## The journal's pages in this room of the Hollow Glacier, if any. The
## last waits for Rimeback to calm; `rising` brings it up out of the ice.
func _put_up_journal(coord: Vector2i, rising: bool = false) -> void:
	var room: Node = game.current_room
	if room == null:
		return
	var tile := Vector2i(-1, -1)
	var number := 0
	if JOURNAL_PAGES.has(coord):
		tile = JOURNAL_PAGES[coord][0]
		number = JOURNAL_PAGES[coord][1]
	elif coord == GLACIER_BOSS and GameState.has_flag(Rimeback.DEFEATED_FLAG):
		tile = LAST_PAGE_TILE
		number = JournalPage.LAST
	if number == 0:
		return
	for child in room.get_children():
		if child is JournalPage:
			return
	var page := JournalPage.new(number)
	page.position = Vector2(tile.x * Room.TILE + Room.TILE / 2.0, tile.y * Room.TILE + Room.TILE - 4)
	room.add_child(page)
	if rising:
		page.readable = false
		page.modulate.a = 0.0
		page.scale = Vector2(1, 0.2)
		var tween := page.create_tween().set_parallel(true)
		tween.tween_interval(1.2)
		tween.chain().tween_property(page, "modulate:a", 1.0, 0.6)
		tween.parallel().tween_property(page, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_callback(func() -> void: page.readable = true)
		Audio.play_sfx("secret")


## Cutscene 13, "The frozen journal": the last page, then a vision in the
## ice. Young Hessa and young Vael stand where Wren stands now; Hessa signals
## with her lamp, Vael bows his head to the weeping under the ice, answers
## no, and walks away. Hessa's lamp keeps glowing after him: I'm here.
func the_frozen_journal(page: JournalPage) -> void:
	if Cutscene.active:
		return
	GameState.set_flag(JOURNAL_FLAG)
	var room: Node = game.current_room
	var scene := _scene()
	scene.music("story_memory")
	await scene.wait(0.2)
	Events.conversation_requested.emit(JournalPage.pages_for(JournalPage.LAST))
	await Events.dialogue_finished
	if not is_instance_valid(room) or not room.is_inside_tree():
		scene.finish()
		return
	# The ice remembers.
	Audio.play_sfx("bell_quiet", null, 0.7)
	Feel.shake(1.0)
	scene.face(Vector2.RIGHT)
	var hessa := ChoirFigure.new("young_hessa")
	hessa.ghost = true
	hessa.position = YOUNG_HESSA_AT
	var vael := ChoirFigure.new("young_vael")
	vael.ghost = true
	vael.position = YOUNG_VAEL_AT
	vael.face(true)
	for figure: ChoirFigure in [hessa, vael]:
		figure.modulate.a = 0.0
		room.add_child(figure)
		var fade: Tween = figure.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade.tween_property(figure, "modulate:a", 1.0, Cutscene.scaled(1.2))
	await scene.wait(1.6)
	# Signals, the way they practised them.
	hessa.talking = true
	await scene.lamp(room.global_position + YOUNG_HESSA_AT + Vector2(-8, -14), Cutscene.LAMP_YES)
	await scene.wait(0.6)
	# Under the ice, something weeps; only Vael hears it.
	vael.talking = true
	Audio.play_sfx("old_one_hum", null, 1.8)
	await scene.wait(2.4)
	vael.talking = false
	vael.face(true)
	await scene.lamp(room.global_position + YOUNG_VAEL_AT + Vector2(0, -14), Cutscene.LAMP_NO)
	await scene.wait(0.8)
	await vael.walk_along(VAEL_LEAVES, 22.0, -1)
	vael.queue_free()
	# She keeps the light lit after him.
	await scene.lamp(room.global_position + YOUNG_HESSA_AT + Vector2(-8, -14), Cutscene.LAMP_HERE)
	var gone := hessa.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	gone.tween_property(hessa, "modulate:a", 0.0, Cutscene.scaled(1.4))
	await gone.finished
	hessa.queue_free()
	await scene.wait(0.6)
	# Wren answers the old light with their own.
	await scene.lamp(game.player.global_position, Cutscene.LAMP_HERE)
	if is_instance_valid(page):
		page.modulate = Color(1, 1, 1, 0.8)
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
	# The bell saved when it rang; keep the breath it gave too.
	SaveManager.save_game()
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
