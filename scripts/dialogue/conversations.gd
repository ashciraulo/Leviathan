class_name Conversations
extends Object
## Everything people say, and when they say it.
##
## Each speaker has a list of branches. Talking picks the FIRST branch whose
## conditions hold, so put the most specific branches at the top:
##
##   "if":     flags that must all be set
##   "unless": flags that must all be unset
##   "has":    items Wren must be carrying
##   "set":    flags to set when this branch is spoken
##   "lines":  the pages, in order
##   "give":   items handed to Wren, {id: count} (a narration line in
##             "lines" says so; the jingle plays as the box opens)
##   "trade":  takes every one of an item Wren carries, adds how many to a
##             tally flag and pays for each: {"take": id, "tally": flag,
##             "each": {id: count}}
##   "reaches": with "trade", only when the tally plus what Wren carries
##             comes to at least this many
##
## A line is a translation key, said by the speaker. To give a page to
## someone else, use [speaker, key]. Use "" as the speaker for narration
## (Wren never speaks; narration says what Wren does instead. Hessa can't
## hear, so Wren answers her with the lamp: one flash yes, two no).
##
## Speakers: [name key, portrait texture or null].

## Coralie takes Wren's sea-glass for her chime, 25 glints a piece.
const GLASS_TRADE := {"take": "sea_glass", "tally": "coralie_glass", "each": {"glint": 25}}

## Set once the Old One has turned (StoryDirector.ENDING_FLAG).
const ENDING_FLAG := "seen_ending"
## Speakers who look different after the ending: Murmur without the robe.
const LATER_PORTRAITS := {"murmur": Art.PORTRAIT_MURMUR_PLAIN}

const SPEAKERS := {
	"hessa": ["NAME_HESSA", Art.PORTRAIT_HESSA],
	"corrin": ["NAME_CORRIN", Art.PORTRAIT_CORRIN],
	"pell": ["NAME_PELL", Art.PORTRAIT_PELL],
	"nettle": ["NAME_NETTLE", Art.PORTRAIT_NETTLE],
	"agna": ["NAME_AGNA", Art.PORTRAIT_AGNA],
	"lowe": ["NAME_LOWE", Art.PORTRAIT_LOWE],
	"murmur": ["NAME_MURMUR", Art.PORTRAIT_MURMUR],
	"vael": ["NAME_VAEL", Art.PORTRAIT_VAEL],
	"dace": ["NAME_DACE", Art.PORTRAIT_DACE],
	"vael_keeper": ["NAME_VAEL", Art.PORTRAIT_VAEL_KEEPER],
	"marga": ["NAME_MARGA", Art.PORTRAIT_MARGA],
	"dunstan": ["NAME_DUNSTAN", Art.PORTRAIT_DUNSTAN],
	"marlo": ["NAME_MARLO", Art.PORTRAIT_MARLO],
	"tobin": ["NAME_TOBIN", Art.PORTRAIT_TOBIN],
	"ide": ["NAME_IDE", Art.PORTRAIT_IDE],
	"liesl": ["NAME_LIESL", Art.PORTRAIT_LIESL],
	"wick": ["NAME_WICK", Art.PORTRAIT_WICK],
	"gully": ["NAME_GULLY", Art.PORTRAIT_GULLY],
	"gully_ebb": ["NAME_GULLY", Art.PORTRAIT_GULLY],
	"sorrel": ["NAME_SORREL", Art.PORTRAIT_SORREL],
	"ottilie": ["NAME_OTTILIE", Art.PORTRAIT_OTTILIE],
	"coralie": ["NAME_CORALIE", Art.PORTRAIT_CORALIE],
	"bram": ["NAME_BRAM", Art.PORTRAIT_BRAM],
	"ferrin": ["NAME_FERRIN", Art.PORTRAIT_FERRIN],
	"sela": ["NAME_SELA", Art.PORTRAIT_SELA],
	"pim": ["NAME_PIM", Art.PORTRAIT_PIM],
	"ansel": ["NAME_ANSEL", Art.PORTRAIT_ANSEL],
	# The frozen journal: pages in young Hessa's and young Vael's hands.
	"young_hessa": ["NAME_YOUNG_HESSA", Art.PORTRAIT_YOUNG_HESSA],
	"young_vael": ["NAME_YOUNG_VAEL", Art.PORTRAIT_YOUNG_VAEL],
}

const TALKS := {
	# Marlo Pike talks across his stall's counter; his wares come after.
	"marlo": [
		# Pearls for his mum's eightieth, from oyster beds only the Diver's
		# Helm reaches (QuestFind).
		{"if": ["marlo_pearls_ask", "found_pearl_verge", "found_pearl_tangle", "found_pearl_deep"], "unless": ["marlo_pearls_done"], "set": ["marlo_pearls_done"], "give": {"glint": 180}, "lines": [["", "NARRATE_HAND_PEARLS"], "MARLO_PEARLS_DONE_1", "MARLO_PEARLS_DONE_2", "MARLO_PEARLS_DONE_3", ["", "NARRATE_GOT_PEARL_PURSE"]]},
		# All three found before he asked.
		{"if": ["met_marlo", "found_pearl_verge", "found_pearl_tangle", "found_pearl_deep"], "unless": ["marlo_pearls_ask"], "set": ["marlo_pearls_ask", "marlo_pearls_done"], "give": {"glint": 180}, "lines": [["", "NARRATE_HAND_PEARLS"], "MARLO_PEARLS_EARLY", "MARLO_PEARLS_EARLY_2", "MARLO_PEARLS_DONE_1", "MARLO_PEARLS_DONE_2", "MARLO_PEARLS_DONE_3", ["", "NARRATE_GOT_PEARL_PURSE"]]},
		{"if": ["met_marlo", "tidebell_hull"], "unless": ["marlo_puffers", "seen_ending"], "set": ["marlo_puffers"], "lines": ["MARLO_PUFFERS_1", "MARLO_PUFFERS_2"]},
		{"if": ["met_marlo"], "has": ["divers_helm"], "unless": ["marlo_pearls_ask"], "set": ["marlo_pearls_ask"], "lines": ["MARLO_PEARLS_1", "MARLO_PEARLS_1B", "MARLO_PEARLS_2", "MARLO_PEARLS_2B"]},
		{"if": ["marlo_pearls_done"], "unless": ["marlo_pearls_after"], "set": ["marlo_pearls_after"], "lines": ["MARLO_PEARLS_AFTER"]},
		{"if": ["marlo_pearls_ask"], "unless": ["marlo_pearls_done"], "lines": ["MARLO_PEARLS_WAITING"]},
		{"if": ["seen_ending"], "lines": ["MARLO_END"]},
		{"if": ["met_marlo"], "lines": ["MARLO_AGAIN"]},
		{"set": ["met_marlo"], "lines": ["MARLO_1", "MARLO_2"]},
	],
	"hessa": [
		# The seventh bell rung: she rows Wren out to the Maw (StoryDirector).
		{"if": ["tidebell_tomb"], "unless": ["hessa_rows", "hessa_rowed"], "set": ["hessa_rows"], "lines": ["HESSA_ROW_1", "HESSA_ROW_2"]},
		{"if": ["lighting_day"], "unless": ["hessa_party_after"], "set": ["hessa_party_after"], "lines": ["HESSA_PARTY_AFTER"]},
		# The little cap from the lantern-boat on the Ebb Shelf.
		{"if": ["found_wren_cap"], "unless": ["hessa_saw_cap"], "set": ["hessa_saw_cap"], "lines": [["", "NARRATE_WREN_SHOWS_CAP"], "HESSA_CAP_1", ["", "NARRATE_HESSA_HOLDS_CAP"], "HESSA_CAP_2"]},
		# The keepers' round: once the Kiln's bell is rung, she sends Wren
		# round the Tidestones; when every one is read, a new line is cut.
		{"if": ["read_every_stone"], "unless": ["hessa_carved_wren"], "set": ["hessa_carved_wren"], "lines": ["HESSA_ROUND_DONE_1", "HESSA_ROUND_DONE_2", ["", "NARRATE_HESSA_CARVES"], "HESSA_ROUND_DONE_3"]},
		{"if": ["seen_wayshell", "tidebell_kiln"], "unless": ["hessa_round_ask", "read_every_stone"], "set": ["hessa_round_ask"], "lines": ["HESSA_ROUND_1", "HESSA_ROUND_1B"]},
		# Ottilie's old cave sign, carried by Wren's lamp.
		{"if": ["ottilie_signal"], "unless": ["hessa_answered_ottilie"], "set": ["hessa_answered_ottilie"], "lines": [["", "NARRATE_WREN_OTTILIE_SIGNAL"], "HESSA_OTTILIE_1", "HESSA_OTTILIE_2"]},
		{"if": ["seen_ending"], "lines": ["HESSA_AFTER_END"]},
		# Once Wren has the Wayshell, Hessa always has a word on where the
		# next bell is, for anyone who asks her.
		{"if": ["tidebell_tomb"], "lines": ["HESSA_HINT_MAW"]},
		{"if": ["tidebell_belfry"], "lines": ["HESSA_HINT_TOMB_1", "HESSA_HINT_TOMB_2"]},
		{"if": ["tidebell_glacier"], "lines": ["HESSA_HINT_BELFRY_1", "HESSA_HINT_BELFRY_2"]},
		{"if": ["seen_hessa_confession"], "lines": ["HESSA_AFTER_TURN"]},
		{"if": ["tidebell_mire", "seen_wayshell"], "lines": ["HESSA_HINT_GALE_1", "HESSA_HINT_GALE_2"]},
		{"if": ["tidebell_kiln", "seen_wayshell"], "lines": ["HESSA_HINT_MIRE_1", "HESSA_HINT_MIRE_2"]},
		{"if": ["seen_wayshell"], "lines": ["HESSA_AFTER_BELL"]},
		{"if": ["tidebell_hull"], "unless": ["freed_mantle"], "lines": ["HESSA_MANTLE_1", "HESSA_MANTLE_2"]},
		{"if": ["met_hessa", "entered_hull"], "unless": ["heard_hessa_hull"], "set": ["heard_hessa_hull"], "lines": ["HESSA_HULL_1", "HESSA_HULL_2"]},
		{"if": ["met_hessa"], "lines": ["HESSA_AGAIN"]},
		{
			"set": ["met_hessa"],
			"lines": ["HESSA_1", "HESSA_2", "HESSA_2B", "HESSA_3", "HESSA_3B", "HESSA_4", "HESSA_5", ["", "NARRATE_WREN_LAMP_YES"], "HESSA_6"],
		},
	],
	"corrin": [
		{"if": ["met_hessa", "entered_hull"], "unless": ["heard_corrin_hull"], "set": ["heard_corrin_hull"], "lines": ["CORRIN_HULL_1", "CORRIN_HULL_2"]},
		# Grandad's message bottles, washed back in by strange currents (QuestFind).
		{"if": ["corrin_bottles_ask", "found_bottle_shore", "found_bottle_pools", "found_bottle_strand"], "unless": ["corrin_bottles_done"], "set": ["corrin_bottles_done"], "give": {"glint": 120}, "lines": ["CORRIN_BOTTLES_DONE_1", "CORRIN_BOTTLES_DONE_2", "CORRIN_BOTTLES_DONE_3", ["", "NARRATE_GOT_BOTTLE_PURSE"]]},
		# All three found before he asked.
		{"if": ["talked_corrin_quest", "found_bottle_shore", "found_bottle_pools", "found_bottle_strand"], "unless": ["corrin_bottles_ask"], "set": ["corrin_bottles_ask", "corrin_bottles_done"], "give": {"glint": 120}, "lines": [["", "NARRATE_HAND_BOTTLES"], "CORRIN_BOTTLES_EARLY", "CORRIN_BOTTLES_DONE_2", "CORRIN_BOTTLES_DONE_3", ["", "NARRATE_GOT_BOTTLE_PURSE"]]},
		{"if": ["talked_corrin_quest", "seen_wayshell"], "unless": ["corrin_bottles_ask"], "set": ["corrin_bottles_ask"], "lines": ["CORRIN_BOTTLES_1", "CORRIN_BOTTLES_1B", "CORRIN_BOTTLES_2"]},
		{"if": ["corrin_bottles_ask"], "unless": ["corrin_bottles_done"], "lines": ["CORRIN_BOTTLES_WAITING"]},
		{"if": ["corrin_bottles_done"], "unless": ["corrin_bottles_after"], "set": ["corrin_bottles_after"], "lines": ["CORRIN_BOTTLES_AFTER"]},
		{"if": ["talked_corrin_quest", "seen_ending"], "lines": ["CORRIN_END"]},
		{"if": ["talked_corrin_quest", "old_one_turned"], "lines": ["CORRIN_TURNED"]},
		{"if": ["talked_corrin_quest"], "lines": ["CORRIN_AGAIN"]},
		{"if": ["met_hessa"], "set": ["talked_corrin_quest"], "lines": ["CORRIN_QUEST_1", "CORRIN_QUEST_2"]},
		{"lines": ["CORRIN_1", "CORRIN_2"]},
	],
	"pell": [
		{"if": ["found_crab"], "unless": ["pell_gave_pearl"], "set": ["pell_gave_pearl"], "give": {"breath_pearl": 1}, "lines": ["PELL_CRAB_1", "PELL_CRAB_2", ["", "NARRATE_GOT_PEARL"]]},
		{"if": ["tidebell_hull"], "unless": ["heard_pell_bell"], "set": ["heard_pell_bell"], "lines": ["PELL_BELL_1", "PELL_BELL_2"]},
		{"if": ["met_hessa", "entered_hull"], "unless": ["heard_pell_hull"], "set": ["heard_pell_hull"], "lines": ["PELL_HULL_1", "PELL_HULL_2"]},
		# Admiral gets his introduction even when the crab turns up late.
		{"if": ["pell_gave_pearl"], "unless": ["heard_pell_admiral"], "set": ["heard_pell_admiral"], "lines": ["PELL_CRAB_AGAIN"]},
		# His lucky shell, dropped by Brinewood's spring (QuestFind).
		{"if": ["pell_shell_ask", "found_pell_shell"], "unless": ["pell_shell_done"], "set": ["pell_shell_done"], "lines": ["PELL_SHELL_DONE_1", "PELL_SHELL_DONE_2", ["", "NARRATE_GOT_PELL_SHELL"]]},
		{"if": ["talked_pell_quest", "seen_wayshell"], "unless": ["pell_shell_ask"], "set": ["pell_shell_ask"], "lines": ["PELL_SHELL_1", "PELL_SHELL_1B", "PELL_SHELL_2"]},
		{"if": ["pell_shell_ask"], "unless": ["pell_shell_done"], "lines": ["PELL_SHELL_WAITING"]},
		{"if": ["talked_pell_quest", "seen_ending"], "lines": ["PELL_END"]},
		{"if": ["talked_pell_quest", "old_one_turned"], "lines": ["PELL_TURNED"]},
		{"if": ["pell_gave_pearl"], "lines": ["PELL_CRAB_AGAIN"]},
		{"if": ["talked_pell_quest"], "lines": ["PELL_AGAIN"]},
		{"if": ["met_hessa"], "set": ["talked_pell_quest"], "lines": ["PELL_QUEST_1", "PELL_QUEST_2"]},
		{"lines": ["PELL_1", "PELL_2"]},
	],
	# Nettle wants to be a keeper, and learns the lamp signals from Wren.
	"nettle": [
		{"if": ["tidebell_hull"], "unless": ["heard_nettle_bell"], "set": ["heard_nettle_bell"], "lines": ["NETTLE_BELL_1", ["", "NARRATE_WREN_FLASH_ONCE"], "NETTLE_BELL_2"]},
		# The lamp lessons, whenever Wren first stops to talk after meeting Hessa.
		{"if": ["met_hessa"], "unless": ["nettle_learned"], "set": ["nettle_learned"], "lines": ["NETTLE_LEARN_1", "NETTLE_LEARN_2", ["", "NARRATE_WREN_LONG_GLOW"], "NETTLE_LEARN_3"]},
		# Agna's hand-bell, cast from the Old One's shed scale.
		{"if": ["agna_bell_cast"], "unless": ["nettle_got_bell"], "set": ["nettle_got_bell"], "lines": [["", "NARRATE_HAND_BELL"], "NETTLE_GOT_BELL_1", ["", "NARRATE_NETTLE_RINGS"], "NETTLE_GOT_BELL_2"]},
		# Nettle's signals: "I'm here" from the three old signal stones (SignalStone).
		{"if": ["nettle_signals_ask", "signal_stone_stacks", "signal_stone_skerry", "signal_stone_brink"], "unless": ["nettle_signals_done"], "set": ["nettle_signals_done"], "give": {"glint": 150}, "lines": ["NETTLE_SIGNALS_DONE_1", "NETTLE_SIGNALS_DONE_2", "NETTLE_SIGNALS_DONE_3", "NETTLE_SIGNALS_DONE_4", ["", "NARRATE_GOT_SIGNAL_FEE"]]},
		# Hessa's lighting day: fifty years since she first lit the lamp. Nettle
		# plans a surprise party; Wren invites the guests; setting
		# lighting_party plays StoryDirector.hessas_lighting_day.
		{"if": ["lighting_ask", "party_ottilie", "party_agna", "party_wick", "party_sorrel", "party_marga"], "unless": ["lighting_party"], "set": ["lighting_party"], "lines": ["NETTLE_PARTY_READY"]},
		{"if": ["nettle_learned", "seen_hessa_confession"], "unless": ["lighting_ask"], "set": ["lighting_ask"], "lines": ["NETTLE_PARTY_1", "NETTLE_PARTY_1B", "NETTLE_PARTY_2", "NETTLE_PARTY_2B"]},
		{"if": ["lighting_day"], "unless": ["nettle_party_after"], "set": ["nettle_party_after"], "lines": ["NETTLE_PARTY_AFTER"]},
		{"if": ["nettle_learned", "seen_wayshell"], "unless": ["nettle_signals_ask"], "set": ["nettle_signals_ask"], "lines": ["NETTLE_SIGNALS_1", "NETTLE_SIGNALS_1B", "NETTLE_SIGNALS_2", "NETTLE_SIGNALS_2B", "NETTLE_SIGNALS_3"]},
		{"if": ["nettle_signals_ask"], "unless": ["nettle_signals_done"], "lines": ["NETTLE_SIGNALS_WAITING"]},
		{"if": ["lighting_ask"], "unless": ["lighting_party"], "lines": ["NETTLE_PARTY_WAITING"]},
		# Bell and signals both done: once, ahead of the late lines.
		{"if": ["nettle_got_bell", "nettle_signals_done"], "unless": ["nettle_nearly_told"], "set": ["nettle_nearly_told"], "lines": ["NETTLE_NEARLY"]},
		{"if": ["nettle_learned", "seen_ending"], "lines": ["NETTLE_END"]},
		{"if": ["nettle_learned", "old_one_turned"], "lines": ["NETTLE_TURNED"]},
		{"if": ["seen_wayshell"], "lines": ["NETTLE_WAYSHELL_1", "NETTLE_WAYSHELL_2"]},
		{"if": ["nettle_learned"], "lines": ["NETTLE_AGAIN"]},
		{"lines": ["NETTLE_1", "NETTLE_2"]},
	],
	# Agna Holt, the last founder, outside the Kiln. After the Ember Bell she
	# lights her forge again and gives Wren a Brinesteel sword. She always
	# introduces herself first, even if Wren walked past her into the Kiln.
	"agna": [
		# The last singers: Bram, who stoked the Kiln for the Choir.
		{"if": ["met_agna", "bram_met"], "unless": ["agna_bram"], "set": ["agna_bram"], "lines": ["AGNA_BRAM_1", "AGNA_BRAM_2"]},
		{"if": ["sorrel_letters", "met_agna"], "unless": ["letter_agna"], "set": ["letter_agna"], "lines": [["", "NARRATE_HAND_LETTER"], "AGNA_LETTER_1", "AGNA_LETTER_2"]},
		{"if": ["lighting_ask", "met_agna"], "unless": ["party_agna"], "set": ["party_agna"], "lines": ["AGNA_PARTY_1", "AGNA_PARTY_2"]},
		{"if": ["bram_pot_cast", "met_agna"], "unless": ["agna_pot_told"], "set": ["agna_pot_told"], "lines": ["AGNA_POT_1", "AGNA_POT_2"]},
		# The Old One's scales: six shed pieces from the puzzle caves (ShedScale)
		# for a hand-bell, which goes to Nettle.
		{"if": ["agna_scales_ask", "shed_scale_dragline", "shed_scale_rimelight", "shed_scale_emberwell", "shed_scale_drybone", "shed_scale_gustway", "shed_scale_lampless"], "unless": ["agna_bell_cast"], "set": ["agna_bell_cast"], "give": {"glint": 250}, "lines": ["AGNA_SCALES_DONE_1", ["", "NARRATE_AGNA_POURS"], "AGNA_SCALES_DONE_2", "AGNA_SCALES_DONE_3", "AGNA_SCALES_DONE_4", ["", "NARRATE_GOT_SCALE_PURSE"]]},
		{"if": ["agna_gave_sword", "seen_wayshell"], "unless": ["agna_scales_ask"], "set": ["agna_scales_ask"], "lines": ["AGNA_SCALES_1", "AGNA_SCALES_1B", "AGNA_SCALES_2", "AGNA_SCALES_2B", "AGNA_SCALES_3"]},
		{"if": ["agna_scales_ask"], "unless": ["agna_bell_cast"], "lines": ["AGNA_SCALES_WAITING"]},
		{"if": ["agna_bell_cast"], "unless": ["nettle_got_bell"], "lines": ["AGNA_BELL_WAITING"]},
		{"if": ["agna_gave_sword", "seen_ending"], "lines": ["AGNA_END"]},
		{"if": ["agna_gave_sword", "old_one_turned"], "lines": ["AGNA_TURNED"]},
		{"if": ["agna_gave_sword"], "lines": ["AGNA_SMITH"]},
		{"unless": ["met_agna"], "set": ["met_agna"], "lines": ["AGNA_1", "AGNA_2", "AGNA_3"]},
		{"if": ["tidebell_kiln"], "set": ["agna_gave_sword"], "give": {"brinesteel_sword": 1}, "lines": ["AGNA_AFTER_1", "AGNA_AFTER_2", ["", "NARRATE_GOT_BRINESTEEL"], "AGNA_AFTER_3"]},
		{"if": ["entered_kiln"], "lines": ["AGNA_KILN_1", "AGNA_KILN_2"]},
		{"lines": ["AGNA_AGAIN"]},
	],
	# Tobin, home from the Choir, hauling rope with his dad.
	"tobin": [
		{"if": ["dunstan_boat_done"], "unless": ["tobin_boat"], "set": ["tobin_boat"], "lines": ["TOBIN_BOAT"]},
		# Once Wren has talked to him, Dunstan asks about the boat.
		{"if": ["seen_ending"], "set": ["talked_tobin_home"], "lines": ["TOBIN_END"]},
		{"set": ["talked_tobin_home"], "lines": ["TOBIN_AFTER"]},
	],
	# Ide, the Causeway End ferrywoman: her boat stays tied up while the
	# Belfry's bell rings wrong under the channel. Asking sets ide_ferry,
	# and StoryDirector rows Wren over.
	"ide": [
		{"unless": ["tidebell_belfry"], "lines": ["IDE_1", "IDE_2"]},
		{"unless": ["met_ide_ferry"], "set": ["met_ide_ferry", "ide_ferry"], "lines": ["IDE_FERRY_1", "IDE_FERRY_2"]},
		# The jam trade ends here: Ferrin's chart of the far shores.
		{"if": ["trade_chart"], "unless": ["trade_done"], "set": ["trade_done", "ide_ferry"], "give": {"glint": 200}, "lines": [["", "NARRATE_HAND_CHART"], "IDE_TRADE_1", "IDE_TRADE_2", "IDE_TRADE_3", ["", "NARRATE_GOT_TRADE_PURSE"]]},
		# Her boat's lost nameboard (QuestFind). Every branch still rows Wren over.
		{"if": ["ide_board_ask", "found_nameboard"], "unless": ["ide_board_done"], "set": ["ide_board_done", "ide_ferry"], "give": {"glint": 100}, "lines": [["", "NARRATE_HAND_NAMEBOARD"], "IDE_BOARD_DONE_1", "IDE_BOARD_DONE_2", ["", "NARRATE_GOT_NAMEBOARD_PURSE"], "IDE_BOARD_DONE_3"]},
		{"if": ["met_ide_ferry", "found_nameboard"], "unless": ["ide_board_ask"], "set": ["ide_board_ask", "ide_board_done", "ide_ferry"], "give": {"glint": 100}, "lines": [["", "NARRATE_HAND_NAMEBOARD"], "IDE_BOARD_EARLY", "IDE_BOARD_1B", "IDE_BOARD_1C", "IDE_BOARD_DONE_2", ["", "NARRATE_GOT_NAMEBOARD_PURSE"], "IDE_BOARD_DONE_3"]},
		{"if": ["ide_rowed_again"], "unless": ["ide_board_ask"], "set": ["ide_board_ask", "ide_ferry"], "lines": ["IDE_BOARD_1", "IDE_BOARD_1B", "IDE_BOARD_1C", "IDE_BOARD_2", "IDE_BOARD_2B"]},
		{"if": ["ide_board_ask"], "unless": ["ide_board_done"], "set": ["ide_ferry"], "lines": ["IDE_BOARD_WAITING"]},
		# (Mid-errand after the ending, the waiting line wins over IDE_END.)
		{"if": ["seen_ending"], "set": ["ide_ferry", "ide_rowed_again"], "lines": ["IDE_END"]},
		{"set": ["ide_ferry", "ide_rowed_again"], "lines": ["IDE_FERRY_AGAIN"]},
	],
	# Liesl in Drowned Lane, and her great-grandmother's lost door bell
	# (a Doorbell out on Belfry Square's flats, there at low tide).
	"liesl": [
		{"if": ["sorrel_letters", "liesl_asked"], "unless": ["letter_liesl"], "set": ["letter_liesl"], "lines": [["", "NARRATE_HAND_LETTER"], "LIESL_LETTER_1", "LIESL_LETTER_2"]},
		{"if": ["wick_murmur_ask", "liesl_asked"], "unless": ["liesl_named_murmur"], "set": ["liesl_named_murmur"], "lines": ["LIESL_MURMUR_1", "LIESL_MURMUR_2"]},
		# The Ebb Grotto's flood marks: a Liesl, three hundred years back.
		{"if": ["read_grotto_marks", "liesl_asked"], "unless": ["liesl_heard_marks"], "set": ["liesl_heard_marks"], "lines": ["LIESL_MARKS_1", "LIESL_MARKS_1B", "LIESL_MARKS_2", "LIESL_MARKS_3"]},
		{"if": ["liesl_bell_hung", "seen_ending"], "lines": ["LIESL_END"]},
		{"if": ["liesl_bell_hung", "tidebell_belfry"], "lines": ["LIESL_VERGE", "LIESL_VERGE_2"]},
		{"if": ["liesl_bell_hung"], "lines": ["LIESL_AFTER"]},
		{"if": ["found_doorbell"], "set": ["liesl_bell_hung"], "give": {"glint": 50}, "lines": ["LIESL_BELL_1", "LIESL_BELL_2", "LIESL_BELL_3", ["", "NARRATE_GOT_VERGE_COINS"]]},
		{"if": ["liesl_asked"], "lines": ["LIESL_WAITING"]},
		{"set": ["liesl_asked"], "lines": ["LIESL_1", "LIESL_1B", "LIESL_2", "LIESL_2B", "LIESL_3", "LIESL_3B"]},
	],
	# Ottilie at Still Cove, who trained with Hessa and Vael, and three
	# rimefin from her fishing hole (a FishingHole).
	"ottilie": [
		# The last singers: Sela, her sister's girl.
		{"if": ["ottilie_asked", "sela_met", "letter_ottilie"], "unless": ["ottilie_sela"], "set": ["ottilie_sela"], "lines": ["OTTILIE_SELA_1", "OTTILIE_SELA_2"]},
		{"if": ["ottilie_asked", "sela_met"], "unless": ["ottilie_sela"], "set": ["ottilie_sela"], "lines": ["OTTILIE_SELA_1", "OTTILIE_SELA_2B"]},
		{"if": ["sorrel_letters", "ottilie_asked"], "unless": ["letter_ottilie"], "set": ["letter_ottilie"], "lines": [["", "NARRATE_HAND_LETTER"], "OTTILIE_LETTER_1", "OTTILIE_LETTER_2"]},
		{"if": ["lighting_ask", "ottilie_reunion"], "unless": ["party_ottilie"], "set": ["party_ottilie", "party_rimefin"], "lines": ["OTTILIE_PARTY_1", "OTTILIE_PARTY_2", "OTTILIE_PARTY_3", ["", "NARRATE_GOT_PARTY_RIMEFIN"]]},
		{"if": ["ottilie_paid", "old_one_turned"], "unless": ["ottilie_told_vael"], "set": ["ottilie_told_vael"], "lines": ["OTTILIE_TURNED", "OTTILIE_TURNED_2", "OTTILIE_TURNED_3"]},
		# Her old cave sign for Hessa (Wren shows it with the lamp), and the answer.
		{"if": ["hessa_answered_ottilie"], "unless": ["ottilie_reunion"], "set": ["ottilie_reunion"], "give": {"glint": 100}, "lines": [["", "NARRATE_WREN_FLASH_ONCE"], "OTTILIE_REPLY_1", "OTTILIE_REPLY_2", ["", "NARRATE_GOT_OTTILIE_THANKS"]]},
		{"if": ["ottilie_signal"], "unless": ["hessa_answered_ottilie"], "lines": ["OTTILIE_SIGNAL_WAITING"]},
		{"if": ["ottilie_paid", "seen_hessa_confession"], "unless": ["ottilie_signal"], "set": ["ottilie_signal"], "lines": ["OTTILIE_SIGNAL_1", "OTTILIE_SIGNAL_1B", "OTTILIE_SIGNAL_2", "OTTILIE_SIGNAL_2B"]},
		{"if": ["ottilie_paid", "seen_ending"], "lines": ["OTTILIE_END"]},
		{"if": ["ottilie_paid"], "lines": ["OTTILIE_AFTER"]},
		{"if": ["ottilie_fish_done"], "set": ["ottilie_paid"], "give": {"glint": 200}, "lines": ["OTTILIE_DONE_1", "OTTILIE_DONE_2", ["", "NARRATE_GOT_KEEPERS_COIN"]]},
		{"if": ["ottilie_asked"], "lines": ["OTTILIE_WAITING"]},
		{"if": ["seen_hessa_confession"], "set": ["ottilie_asked"], "lines": ["OTTILIE_HESSA", "OTTILIE_1", "OTTILIE_1B", "OTTILIE_2", "OTTILIE_2B", "OTTILIE_3"]},
		{"set": ["ottilie_asked"], "lines": ["OTTILIE_1", "OTTILIE_1B", "OTTILIE_2", "OTTILIE_2B", "OTTILIE_3"]},
	],
	# Captain Sorrel at Gullwatch Steps, and her kite race to the far post
	# (StoryDirector.sorrel_race, started by the sorrel_race flag).
	"sorrel": [
		# The last singers: Ansel, her old sorter.
		{"if": ["sorrel_asked", "ansel_met"], "unless": ["sorrel_ansel"], "set": ["sorrel_ansel"], "lines": ["SORREL_ANSEL_1", "SORREL_ANSEL_2"]},
		{"if": ["lighting_ask", "sorrel_asked"], "unless": ["party_sorrel"], "set": ["party_sorrel"], "lines": ["SORREL_PARTY_1", "SORREL_PARTY_2"]},
		# The jam trade: Wick's candles for kite cord, for Ferrin.
		{"if": ["trade_candles", "sorrel_asked"], "unless": ["trade_line"], "set": ["trade_line"], "lines": [["", "NARRATE_HAND_CANDLES"], "SORREL_TRADE_1", "SORREL_TRADE_2", "SORREL_TRADE_2B", ["", "NARRATE_GOT_TRADE_LINE"]]},
		# The post's last three letters, never sent when it shut.
		{"if": ["letter_ottilie", "letter_liesl", "letter_agna"], "unless": ["sorrel_letters_paid"], "set": ["sorrel_letters_paid"], "give": {"glint": 150}, "lines": ["SORREL_LETTERS_DONE_1", "SORREL_LETTERS_DONE_2", ["", "NARRATE_GOT_POSTAGE"]]},
		# Gullcry Stacks, the run no courier ever flew (its chest is the proof).
		{"if": ["sorrel_paid", "chest_7_-4_20_2"], "unless": ["sorrel_saw_stacks"], "set": ["sorrel_saw_stacks"], "lines": ["SORREL_STACKS_DONE_1", "SORREL_STACKS_DONE_2"]},
		{"if": ["sorrel_letters"], "unless": ["sorrel_letters_paid"], "lines": ["SORREL_LETTERS_WAITING"]},
		{"if": ["sorrel_paid"], "unless": ["sorrel_letters"], "set": ["sorrel_letters"], "lines": ["SORREL_LETTERS_1", "SORREL_LETTERS_1B", "SORREL_LETTERS_2", "SORREL_LETTERS_2B", ["", "NARRATE_TAKE_LETTERS"]]},
		{"if": ["sorrel_paid"], "unless": ["sorrel_dared_stacks", "sorrel_saw_stacks"], "set": ["sorrel_dared_stacks"], "lines": ["SORREL_STACKS_1", "SORREL_STACKS_1B"]},
		{"if": ["trade_line"], "unless": ["trade_chart"], "lines": ["SORREL_TRADE_WAITING"]},
		{"if": ["sorrel_paid", "seen_ending"], "lines": ["SORREL_END"]},
		{"if": ["sorrel_paid", "old_one_turned"], "lines": ["SORREL_AFTER", "SORREL_TURNED"]},
		{"if": ["sorrel_paid"], "lines": ["SORREL_AFTER", "SORREL_AFTER_2"]},
		{"if": ["sorrel_won"], "set": ["sorrel_paid"], "give": {"glint": 150}, "lines": ["SORREL_WON_1", "SORREL_WON_2", ["", "NARRATE_GOT_COURIER_PAY"]]},
		{"if": ["sorrel_race"], "lines": ["SORREL_FLYING"]},
		{"if": ["sorrel_raced"], "has": ["kite_cloak"], "set": ["sorrel_race"], "lines": ["SORREL_AGAIN", "SORREL_GO"]},
		{"has": ["kite_cloak"], "set": ["sorrel_asked", "sorrel_raced", "sorrel_race"], "lines": ["SORREL_CLOAK_1", "SORREL_CLOAK_1B", "SORREL_CLOAK_2", "SORREL_GO"]},
		{"if": ["sorrel_asked"], "lines": ["SORREL_WAITING"]},
		{"set": ["sorrel_asked"], "lines": ["SORREL_1", "SORREL_1B", "SORREL_2", "SORREL_2B", "SORREL_3"]},
	],
	# Sister Lowe, alone on Lullaby Point after the ending.
	"lowe": [
		{"unless": ["lowe_spoke"], "set": ["lowe_spoke"], "lines": ["LOWE_END_1", "LOWE_END_2", "LOWE_END_3", "LOWE_END_4"]},
		# The last singers: four of the Choir who never went home.
		{"if": ["lowe_singers_ask", "bram_home", "sela_home", "pim_home", "ansel_home"], "unless": ["lowe_singers_done"], "set": ["lowe_singers_done"], "give": {"glint": 300}, "lines": ["LOWE_SINGERS_DONE_1", "LOWE_SINGERS_DONE_2", ["", "NARRATE_LOWE_ROBE"], "LOWE_SINGERS_DONE_3", ["", "NARRATE_GOT_CHOIR_PURSE"]]},
		{"if": ["lowe_singers_done"], "lines": ["LOWE_JUST_LOWE"]},
		{"if": ["lowe_singers_ask"], "lines": ["LOWE_SINGERS_WAITING"]},
		{"set": ["lowe_singers_ask"], "lines": ["LOWE_SINGERS_1", "LOWE_SINGERS_1B", "LOWE_SINGERS_2", "LOWE_SINGERS_2B"]},
	],
	# Murmur, who left the Choir at the calf, now helping Wick at Fenmouth.
	"murmur": [
		{"unless": ["murmur_met"], "set": ["murmur_met"], "lines": ["MURMUR_FEN_1", "MURMUR_FEN_2", "MURMUR_FEN_3"]},
		# The Reed family's lantern, lit at last (Wick, Liesl and Wren).
		{"if": ["murmur_lantern_lit"], "unless": ["murmur_saw_lantern"], "set": ["murmur_saw_lantern"], "lines": ["MURMUR_LANTERN_1", "MURMUR_LANTERN_2", "MURMUR_LANTERN_3"]},
		# The Calf's Rest: Wren has found the little skull in the far fen.
		{"if": ["found_calf_rest", "seen_ending"], "unless": ["murmur_left_robe"], "set": ["murmur_left_robe"], "lines": ["MURMUR_REST_1", "MURMUR_REST_2", "MURMUR_REST_3"]},
		{"if": ["found_calf_rest"], "unless": ["seen_ending", "murmur_heard_rest"], "set": ["murmur_heard_rest"], "lines": ["MURMUR_REST_EARLY"]},
		{"if": ["seen_ending"], "lines": ["MURMUR_END"]},
		{"if": ["old_one_turned"], "lines": ["MURMUR_TURNED"]},
		{"if": ["murmur_saw_lantern"], "lines": ["MURMUR_LANTERN_AGAIN"]},
		{"lines": ["MURMUR_AGAIN"]},
	],
	# The last singers, each alone somewhere after the ending.
	"bram": [
		# The Choir's chimes (QuestFind), melted down into a pot for Agna.
		{"if": ["bram_chimes_ask", "found_chime_pass", "found_chime_fen", "found_chime_wood"], "unless": ["bram_pot_cast"], "set": ["bram_pot_cast"], "give": {"glint": 150}, "lines": [["", "NARRATE_HAND_CHIMES"], "BRAM_CHIMES_DONE_1", ["", "NARRATE_BRAM_POURS"], "BRAM_CHIMES_DONE_2", "BRAM_CHIMES_DONE_2B", "BRAM_CHIMES_DONE_3", ["", "NARRATE_GOT_CHIME_PURSE"]]},
		# All three found before he asked.
		{"if": ["bram_home", "found_chime_pass", "found_chime_fen", "found_chime_wood"], "unless": ["bram_chimes_ask"], "set": ["bram_chimes_ask", "bram_pot_cast"], "give": {"glint": 150}, "lines": [["", "NARRATE_HAND_CHIMES"], "BRAM_CHIMES_EARLY", "BRAM_CHIMES_EARLY_2", ["", "NARRATE_BRAM_POURS"], "BRAM_CHIMES_DONE_2", "BRAM_CHIMES_DONE_2B", "BRAM_CHIMES_DONE_3", ["", "NARRATE_GOT_CHIME_PURSE"]]},
		{"if": ["bram_forge_talked"], "unless": ["bram_chimes_ask"], "set": ["bram_chimes_ask"], "lines": ["BRAM_CHIMES_1", "BRAM_CHIMES_1B", "BRAM_CHIMES_1C", "BRAM_CHIMES_2", "BRAM_CHIMES_2B"]},
		{"if": ["bram_chimes_ask"], "unless": ["bram_pot_cast"], "lines": ["BRAM_CHIMES_WAITING"]},
		{"if": ["bram_pot_cast"], "unless": ["bram_pot_after"], "set": ["bram_pot_after"], "lines": ["BRAM_CHIMES_AFTER"]},
		{"if": ["bram_home"], "set": ["bram_forge_talked"], "lines": ["BRAM_FORGE"]},
		{"if": ["agna_bram"], "set": ["bram_home"], "lines": [["", "NARRATE_WREN_BELLOWS"], "BRAM_HOME_1", "BRAM_HOME_2"]},
		{"if": ["bram_met"], "lines": ["BRAM_WAITING"]},
		{"set": ["bram_met"], "lines": ["BRAM_1", "BRAM_1B", "BRAM_2"]},
	],
	"sela": [
		{"if": ["sela_home"], "lines": ["SELA_BYE"]},
		{"if": ["ottilie_sela"], "set": ["sela_home"], "lines": [["", "NARRATE_WREN_ROCKS_BABY"], "SELA_HOME_1", "SELA_HOME_2"]},
		{"if": ["sela_met"], "lines": ["SELA_WAITING"]},
		{"set": ["sela_met"], "lines": ["SELA_1", "SELA_1B", "SELA_2"]},
	],
	"pim": [
		{"if": ["pim_home"], "lines": ["PIM_BYE"]},
		{"if": ["pim_met"], "has": ["glowmoth_lantern"], "set": ["pim_home"], "lines": [["", "NARRATE_WREN_RAISES_LANTERN"], "PIM_HOME_1", "PIM_HOME_2"]},
		{"if": ["pim_met"], "lines": ["PIM_WAITING"]},
		{"set": ["pim_met"], "lines": ["PIM_1", "PIM_1B", "PIM_2"]},
	],
	"ansel": [
		{"if": ["ansel_home"], "lines": ["ANSEL_BYE"]},
		{"if": ["sorrel_ansel"], "set": ["ansel_home"], "lines": [["", "NARRATE_WREN_KITE"], "ANSEL_HOME_1", "ANSEL_HOME_2"]},
		{"if": ["ansel_met"], "lines": ["ANSEL_WAITING"]},
		{"set": ["ansel_met"], "lines": ["ANSEL_1", "ANSEL_1B", "ANSEL_2"]},
	],
	# Mother Dace by the last mural, after the ending.
	"dace": [
		{"unless": ["dace_sat"], "set": ["dace_sat"], "lines": ["DACE_END_1", "DACE_END_2"]},
		# The Bone Ring, where the bone-readers' young proved their nerve.
		{"if": ["gate_8_2"], "unless": ["dace_saw_ring"], "set": ["dace_saw_ring"], "lines": ["DACE_RING_DONE_1", "DACE_RING_DONE_2"]},
		{"unless": ["dace_told_ring", "dace_saw_ring"], "set": ["dace_told_ring"], "lines": ["DACE_RING_1", "DACE_RING_1B"]},
		{"lines": ["DACE_AGAIN"]},
	],
	# Coralie on Saltmarrow Shore, who strings sea-glass into a wind chime
	# (GlassChime) and pays for every piece Wren brings her.
	"coralie": [
		{"if": ["coralie_chime_done", "seen_ending"], "lines": ["CORALIE_END"]},
		{"if": ["coralie_chime_done", "old_one_turned"], "lines": ["CORALIE_TURNED"]},
		{"if": ["coralie_chime_done"], "lines": ["CORALIE_AFTER"]},
		{
			"if": ["coralie_asked"],
			"has": ["sea_glass"],
			"reaches": SeaGlass.TOTAL,
			"trade": GLASS_TRADE,
			"set": ["coralie_chime_done"],
			"give": {"glint": 100},
			"lines": ["CORALIE_DONE_1", ["", "NARRATE_GOT_GLASS_PAY"], "CORALIE_DONE_2", "CORALIE_DONE_3", ["", "NARRATE_GOT_CORALIE_SAVINGS"]],
		},
		{"if": ["coralie_asked"], "has": ["sea_glass"], "trade": GLASS_TRADE, "lines": ["CORALIE_HANG", ["", "NARRATE_GOT_GLASS_PAY"]]},
		{"if": ["coralie_asked"], "lines": ["CORALIE_WAITING"]},
		{"set": ["coralie_asked"], "lines": ["CORALIE_1", "CORALIE_1B", "CORALIE_2", "CORALIE_2B", "CORALIE_3"]},
	],
	# Gully on Wreck Strand, and his strongbox out in the pool (a Strongbox,
	# hauled in with the Tide Hook).
	"gully": [
		{"if": ["gully_paid", "seen_ending"], "lines": ["GULLY_END"]},
		{"if": ["gully_paid", "old_one_turned"], "lines": ["GULLY_TURNED"]},
		{"if": ["gully_paid"], "lines": ["GULLY_AFTER", "GULLY_AFTER_2"]},
		{"if": ["gully_box_hauled"], "set": ["gully_paid"], "give": {"glint": 100}, "lines": ["GULLY_BOX_1", "GULLY_BOX_2", ["", "NARRATE_GOT_SALVAGE"]]},
		{"if": ["gully_asked"], "lines": ["GULLY_WAITING"]},
		{"set": ["gully_asked"], "lines": ["GULLY_1", "GULLY_1B", "GULLY_2", "GULLY_2B", "GULLY_3", "GULLY_3B"]},
	],
	# Gully on the Ebb Shelf with the tide held out, and the lantern-boat
	# the ebb bared (LanternBoat).
	"gully_ebb": [
		{"if": ["found_wren_cap"], "lines": ["GULLY_EBB_AFTER"]},
		{"if": ["gully_ebb_told"], "lines": ["GULLY_EBB_AGAIN"]},
		{"set": ["gully_ebb_told"], "lines": ["GULLY_EBB_1", "GULLY_EBB_2", "GULLY_EBB_3", "GULLY_EBB_4"]},
	],
	# Ferrin the mapmaker, camped at the far north edge of Windmere: the
	# Edge Survey. He gives Wren three stakes to drive in where the land
	# gives out (SurveyStake), and finishes his map when all three are in.
	"ferrin": [
		# The jam trade: Sorrel's kite cord for his chart, for Ide.
		{"if": ["trade_line", "ferrin_survey_ask"], "unless": ["trade_chart"], "set": ["trade_chart"], "lines": [["", "NARRATE_HAND_LINE"], "FERRIN_TRADE_1", "FERRIN_TRADE_2", "FERRIN_TRADE_2B", ["", "NARRATE_GOT_TRADE_CHART"]]},
		{"if": ["trade_chart", "ferrin_map_done"], "unless": ["trade_done"], "lines": ["FERRIN_TRADE_WAITING"]},
		{"if": ["ferrin_map_done"], "lines": ["FERRIN_AFTER"]},
		{"if": ["ferrin_survey_ask", "survey_stake_frost", "survey_stake_cinder", "survey_stake_verge"], "set": ["ferrin_map_done"], "give": {"glint": 200}, "lines": ["FERRIN_DONE_1", ["", "NARRATE_FERRIN_MAP"], "FERRIN_DONE_2", "FERRIN_DONE_3", ["", "NARRATE_GOT_SURVEY_PURSE"]]},
		{"if": ["ferrin_survey_ask"], "lines": ["FERRIN_WAITING"]},
		{"set": ["ferrin_survey_ask"], "lines": ["FERRIN_1", "FERRIN_1B", "FERRIN_2", "FERRIN_2B", "FERRIN_3", ["", "NARRATE_GOT_STAKES"]]},
	],
	# The three survey stakes (SurveyStake), one per far reach.
	"survey_stake_frost": [
		{"if": ["survey_stake_frost"], "lines": ["NARRATE_STAKE_STANDS"]},
		{"if": ["ferrin_survey_ask"], "set": ["survey_stake_frost"], "lines": ["NARRATE_STAKE_DRIVEN"]},
		{"lines": ["NARRATE_STAKE_CAIRN"]},
	],
	"survey_stake_cinder": [
		{"if": ["survey_stake_cinder"], "lines": ["NARRATE_STAKE_STANDS"]},
		{"if": ["ferrin_survey_ask"], "set": ["survey_stake_cinder"], "lines": ["NARRATE_STAKE_DRIVEN"]},
		{"lines": ["NARRATE_STAKE_CAIRN"]},
	],
	"survey_stake_verge": [
		{"if": ["survey_stake_verge"], "lines": ["NARRATE_STAKE_STANDS"]},
		{"if": ["ferrin_survey_ask"], "set": ["survey_stake_verge"], "lines": ["NARRATE_STAKE_DRIVEN"]},
		{"lines": ["NARRATE_STAKE_CAIRN"]},
	],
	# Nettle's old signal stones on the far headlands (SignalStone). Lighting
	# one plays a short scene (StoryDirector.signal_from_stone).
	"signal_stone_stacks": [
		{"if": ["signal_stone_stacks"], "lines": ["NARRATE_SIGNAL_LIT"]},
		{"if": ["nettle_signals_ask"], "set": ["signal_stone_stacks"], "lines": ["NARRATE_SIGNAL_LAMP"]},
		{"lines": ["NARRATE_SIGNAL_STONE"]},
	],
	"signal_stone_skerry": [
		{"if": ["signal_stone_skerry"], "lines": ["NARRATE_SIGNAL_LIT"]},
		{"if": ["nettle_signals_ask"], "set": ["signal_stone_skerry"], "lines": ["NARRATE_SIGNAL_LAMP"]},
		{"lines": ["NARRATE_SIGNAL_STONE"]},
	],
	"signal_stone_brink": [
		{"if": ["signal_stone_brink"], "lines": ["NARRATE_SIGNAL_LIT"]},
		{"if": ["nettle_signals_ask"], "set": ["signal_stone_brink"], "lines": ["NARRATE_SIGNAL_LAMP"]},
		{"lines": ["NARRATE_SIGNAL_STONE"]},
	],
	# Things lying about for villagers' errands (QuestFind). Picking one up
	# sets found_<id>, whether or not anyone has asked yet.
	"find_bottle_shore": [{"set": ["found_bottle_shore"], "lines": ["NARRATE_FOUND_BOTTLE", "NARRATE_BOTTLE_NOTE_SHORE", "NARRATE_KEEP_BOTTLE"]}],
	"find_bottle_pools": [{"set": ["found_bottle_pools"], "lines": ["NARRATE_FOUND_BOTTLE", "NARRATE_BOTTLE_NOTE_POOLS", "NARRATE_KEEP_BOTTLE"]}],
	"find_bottle_strand": [{"set": ["found_bottle_strand"], "lines": ["NARRATE_FOUND_BOTTLE", "NARRATE_BOTTLE_NOTE_STRAND", "NARRATE_KEEP_BOTTLE"]}],
	"find_pell_shell": [{"set": ["found_pell_shell"], "lines": ["NARRATE_FOUND_SHELL"]}],
	"find_driftwood": [{"set": ["found_driftwood"], "lines": ["NARRATE_FOUND_DRIFTWOOD"]}],
	"find_chime_pass": [{"set": ["found_chime_pass"], "lines": ["NARRATE_FOUND_CHIME"]}],
	"find_chime_fen": [{"set": ["found_chime_fen"], "lines": ["NARRATE_FOUND_CHIME"]}],
	"find_chime_wood": [{"set": ["found_chime_wood"], "lines": ["NARRATE_FOUND_CHIME"]}],
	"find_pearl_verge": [{"set": ["found_pearl_verge"], "lines": ["NARRATE_FOUND_OYSTER"]}],
	"find_pearl_tangle": [{"set": ["found_pearl_tangle"], "lines": ["NARRATE_FOUND_OYSTER"]}],
	"find_pearl_deep": [{"set": ["found_pearl_deep"], "lines": ["NARRATE_FOUND_OYSTER"]}],
	"find_nameboard": [{"set": ["found_nameboard"], "lines": ["NARRATE_FOUND_NAMEBOARD", "NARRATE_FOUND_NAMEBOARD_2"]}],
	# The Calf's Rest, south of Gloamfen (CalfSkull): the Old One's lost
	# calf, whose dreams the fen-lights carry. After the ending, Murmur
	# leaves the grey robe there.
	"calf_skull": [
		{"if": ["murmur_left_robe"], "lines": ["NARRATE_CALF_ROBE"]},
		{"if": ["found_calf_rest"], "lines": ["NARRATE_CALF_AGAIN"]},
		{"set": ["found_calf_rest"], "lines": ["NARRATE_CALF_1", "NARRATE_CALF_2", "NARRATE_CALF_3"]},
	],
	# The flood marks in the Ebb Grotto (GrottoMarks).
	"grotto_marks": [
		{"if": ["read_grotto_marks"], "lines": ["NARRATE_GROTTO_AGAIN"]},
		{"set": ["read_grotto_marks"], "lines": ["NARRATE_GROTTO_1", "NARRATE_GROTTO_2", "NARRATE_GROTTO_3"]},
	],
	"lantern_boat": [
		{"if": ["found_wren_cap"], "lines": ["NARRATE_LANTERN_BOAT_EMPTY"]},
		{"if": ["gully_ebb_told"], "set": ["found_wren_cap"], "lines": ["NARRATE_LANTERN_BOAT", "NARRATE_FOUND_CAP_1", "NARRATE_FOUND_CAP_2"]},
		{"lines": ["NARRATE_LANTERN_BOAT"]},
	],
	# Wick at Fenmouth, who counts the fen's lanterns every night, and the
	# five that have gone dark (FenLantern).
	"wick": [
		{"if": ["wick_asked", "pim_home"], "unless": ["wick_met_pim"], "set": ["wick_met_pim"], "lines": ["WICK_PIM"]},
		{"if": ["lighting_ask", "wick_asked"], "unless": ["party_wick"], "set": ["party_wick"], "lines": ["WICK_PARTY_1", "WICK_PARTY_2"]},
		# The jam trade: Marga's bramble jam for fen candles, for Sorrel.
		{"if": ["trade_jam", "wick_asked"], "unless": ["trade_candles"], "set": ["trade_candles"], "lines": [["", "NARRATE_HAND_JAM"], "WICK_TRADE_1", "WICK_TRADE_2", "WICK_TRADE_2B", ["", "NARRATE_GOT_TRADE_CANDLES"]]},
		# A lantern for Murmur's family: Liesl knows the name, Wren lights it.
		{"if": ["liesl_named_murmur"], "has": ["glowmoth_lantern"], "unless": ["murmur_lantern_lit"], "set": ["murmur_lantern_lit"], "lines": ["WICK_LANTERN_1", ["", "NARRATE_WREN_LIGHTS_LANTERN"], "WICK_LANTERN_2"]},
		# The Lampless Sink's four braziers, lit at last.
		{"if": ["wick_gave_jar", "gate_5_3"], "unless": ["wick_saw_sink"], "set": ["wick_saw_sink"], "lines": ["WICK_SINK_DONE_1", "WICK_SINK_DONE_2"]},
		{"if": ["wick_murmur_ask"], "unless": ["murmur_lantern_lit"], "lines": ["WICK_MURMUR_WAITING"]},
		{"if": ["murmur_met", "wick_gave_jar"], "unless": ["wick_murmur_ask"], "set": ["wick_murmur_ask"], "lines": ["WICK_MURMUR_1", "WICK_MURMUR_1B", "WICK_MURMUR_2", "WICK_MURMUR_2B"]},
		{"if": ["wick_gave_jar"], "unless": ["wick_told_sink", "wick_saw_sink"], "set": ["wick_told_sink"], "lines": ["WICK_SINK_1", "WICK_SINK_1B"]},
		{"if": ["trade_candles"], "unless": ["trade_line"], "lines": ["WICK_TRADE_WAITING"]},
		{"if": ["wick_gave_jar", "seen_ending"], "lines": ["WICK_END", "WICK_END_2"]},
		{"if": ["wick_gave_jar", "old_one_turned"], "lines": ["WICK_TURNED"]},
		{"if": ["wick_gave_jar"], "lines": ["WICK_AFTER"]},
		{"if": ["fen_lanterns_lit"], "set": ["wick_gave_jar"], "give": {"jar": 1}, "lines": ["WICK_DONE_1", "WICK_DONE_2", ["", "NARRATE_GOT_JAR"]]},
		{"if": ["wick_asked"], "lines": ["WICK_WAITING"]},
		{"set": ["wick_asked"], "lines": ["WICK_1", "WICK_1B", "WICK_2", "WICK_2B", "WICK_3"]},
	],
	# Marga sends Wren to Dunstan for rope: a small errand made of flags.
	"marga": [
		# Rimefin pie for Hessa's lighting day (Ottilie sends the fish).
		{"if": ["lighting_ask", "party_rimefin"], "unless": ["party_marga"], "set": ["party_marga"], "lines": [["", "NARRATE_HAND_RIMEFIN"], "MARGA_PARTY_PIE_1", "MARGA_PARTY_PIE_2"]},
		{"if": ["lighting_ask", "asked_for_rope"], "unless": ["party_marga", "party_marga_ask"], "set": ["party_marga_ask"], "lines": ["MARGA_PARTY_1", "MARGA_PARTY_2"]},
		# Waiting on the fish, but never ahead of the rope errand and the jar.
		{"if": ["party_marga_ask", "marga_gave_jar"], "unless": ["party_marga"], "lines": ["MARGA_PARTY_WAITING"]},
		# The jam trade: Marga -> Wick -> Sorrel -> Ferrin -> Ide, and back to her.
		{"if": ["trade_done"], "unless": ["marga_heard_trade"], "set": ["marga_heard_trade"], "lines": ["MARGA_TRADE_DONE_1", "MARGA_TRADE_DONE_2"]},
		{"if": ["marga_gave_jar", "seen_wayshell"], "unless": ["trade_jam"], "set": ["trade_jam"], "lines": ["MARGA_TRADE_1", "MARGA_TRADE_1B", "MARGA_TRADE_2", ["", "NARRATE_GOT_TRADE_JAM"]]},
		{"if": ["trade_jam"], "unless": ["trade_candles"], "lines": ["MARGA_TRADE_WAITING"]},
		{"if": ["marga_gave_jar", "seen_ending"], "lines": ["MARGA_END"]},
		{"if": ["marga_gave_jar", "old_one_turned"], "lines": ["MARGA_TURNED"]},
		{"if": ["marga_gave_jar"], "lines": ["MARGA_AFTER"]},
		{"if": ["marga_thanked", "tidebell_hull"], "set": ["marga_gave_jar"], "give": {"jar": 1}, "lines": ["MARGA_EEL_1", "MARGA_EEL_2", ["", "NARRATE_GOT_JAR"]]},
		{"if": ["party_marga_ask", "marga_thanked"], "unless": ["party_marga"], "lines": ["MARGA_PARTY_WAITING"]},
		{"if": ["marga_thanked"], "lines": ["MARGA_AGAIN"]},
		{"if": ["rope_promised"], "set": ["marga_thanked"], "lines": ["MARGA_THANKS_1", "MARGA_THANKS_2"]},
		{"if": ["asked_for_rope"], "lines": ["MARGA_WAITING"]},
		{"set": ["asked_for_rope"], "lines": ["MARGA_1", "MARGA_2", "MARGA_2B", ["", "NARRATE_WREN_NODS"]]},
	],
	"dunstan": [
		# Marga's rope errand comes first, whenever it's still owed.
		{
			"if": ["asked_for_rope"],
			"unless": ["rope_promised"],
			"set": ["rope_promised"],
			"lines": ["DUNSTAN_ROPE_1", ["", "NARRATE_WREN_NODS"], "DUNSTAN_ROPE_2", ["", "NARRATE_DUNSTAN_ROPE"]],
		},
		# A boat for Tobin, from the driftwood behind Barnacle Wall (QuestFind),
		# once Wren has said hello to Tobin.
		{"if": ["dunstan_boat_ask", "found_driftwood"], "unless": ["dunstan_boat_done"], "set": ["dunstan_boat_done"], "lines": [["", "NARRATE_HAND_DRIFTWOOD"], "DUNSTAN_BOAT_DONE_1", ["", "NARRATE_DUNSTAN_CARVES"], "DUNSTAN_BOAT_DONE_2", ["", "NARRATE_GOT_TOY_BOAT"]]},
		# The driftwood found before he asked.
		{"if": ["tobin_home", "talked_tobin_home", "found_driftwood"], "unless": ["dunstan_boat_ask"], "set": ["dunstan_boat_ask", "dunstan_boat_done"], "lines": [["", "NARRATE_HAND_DRIFTWOOD"], "DUNSTAN_BOAT_EARLY", ["", "NARRATE_DUNSTAN_CARVES"], "DUNSTAN_BOAT_DONE_2", ["", "NARRATE_GOT_TOY_BOAT"]]},
		{"if": ["tobin_home", "talked_tobin_home"], "unless": ["dunstan_boat_ask"], "set": ["dunstan_boat_ask"], "lines": ["DUNSTAN_BOAT_1", "DUNSTAN_BOAT_1B", "DUNSTAN_BOAT_2"]},
		{"if": ["dunstan_boat_ask"], "unless": ["dunstan_boat_done"], "lines": ["DUNSTAN_BOAT_WAITING"]},
		{"if": ["seen_ending"], "lines": ["DUNSTAN_END"]},
		{"if": ["tobin_home"], "lines": ["DUNSTAN_TOBIN_AFTER"]},
		{"if": ["old_one_turned"], "lines": ["DUNSTAN_TURNED"]},
		{"if": ["rope_promised"], "lines": ["DUNSTAN_AGAIN"]},
		{"lines": ["DUNSTAN_1", "DUNSTAN_2"]},
	],
}


## The branch `speaker` would use right now, or {} if they have nothing to say.
static func branch_for(speaker: String) -> Dictionary:
	for branch: Dictionary in TALKS.get(speaker, []):
		if GameState.flags_match(branch.get("if", []), branch.get("unless", [])) and _has_all(branch.get("has", [])) and _reaches(branch):
			return branch
	return {}


## How many of a trade's items have been handed over so far.
static func tally(trade: Dictionary) -> int:
	return int(GameState.flags.get(trade["tally"], 0))


## True unless the branch has "reaches" and its trade wouldn't get there.
static func _reaches(branch: Dictionary) -> bool:
	if not branch.has("reaches"):
		return true
	var trade: Dictionary = branch["trade"]
	return tally(trade) + GameState.item_count(trade["take"]) >= int(branch["reaches"])


## True when Wren carries every item in `items` (a branch's "has").
static func _has_all(items: Array) -> bool:
	for id: String in items:
		if not GameState.has_item(id):
			return false
	return true


## Turns a branch into pages for the dialogue box. Each page is
## {"name": name key or "", "portrait": Texture2D or null, "text": key}.
static func pages(speaker: String, branch: Dictionary) -> Array:
	var out: Array = []
	for line: Variant in branch.get("lines", []):
		var who := speaker
		var key := str(line)
		if line is Array:
			who = line[0]
			key = line[1]
		var spec: Array = SPEAKERS.get(who, ["", null])
		var portrait: Variant = spec[1]
		if LATER_PORTRAITS.has(who) and GameState.has_flag(ENDING_FLAG):
			portrait = LATER_PORTRAITS[who]
		out.append({"name": spec[0], "portrait": portrait, "text": key})
	return out


## Start `speaker`'s current conversation: sets the branch's flags and opens
## the dialogue box. Returns the pages shown (empty if there was nothing).
static func talk(speaker: String) -> Array:
	var branch := branch_for(speaker)
	if branch.is_empty():
		return []
	for flag: String in branch.get("set", []):
		GameState.set_flag(flag)
	var gifts: Dictionary = branch.get("give", {}).duplicate()
	var trade: Dictionary = branch.get("trade", {})
	if not trade.is_empty():
		var handed := GameState.item_count(trade["take"])
		GameState.take_item(trade["take"], handed)
		GameState.set_flag(trade["tally"], tally(trade) + handed)
		var each: Dictionary = trade["each"]
		for id: String in each:
			gifts[id] = int(gifts.get(id, 0)) + int(each[id]) * handed
	for id: String in gifts:
		GameState.give_item(id, int(gifts[id]), false)
	if not gifts.is_empty():
		Audio.play_jingle("jingle_pearl" if gifts.has("breath_pearl") else "jingle_item")
	var shown := pages(speaker, branch)
	Events.conversation_requested.emit(shown)
	return shown
