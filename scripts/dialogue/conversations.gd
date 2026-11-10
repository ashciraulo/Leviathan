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
	"sorrel": ["NAME_SORREL", Art.PORTRAIT_SORREL],
	"ottilie": ["NAME_OTTILIE", Art.PORTRAIT_OTTILIE],
	"coralie": ["NAME_CORALIE", Art.PORTRAIT_CORALIE],
	# The frozen journal: pages in young Hessa's and young Vael's hands.
	"young_hessa": ["NAME_YOUNG_HESSA", Art.PORTRAIT_YOUNG_HESSA],
	"young_vael": ["NAME_YOUNG_VAEL", Art.PORTRAIT_YOUNG_VAEL],
}

const TALKS := {
	# Marlo Pike talks across his stall's counter; his wares come after.
	"marlo": [
		{"if": ["seen_ending"], "lines": ["MARLO_END"]},
		{"if": ["met_marlo", "tidebell_hull"], "unless": ["marlo_puffers"], "set": ["marlo_puffers"], "lines": ["MARLO_PUFFERS_1", "MARLO_PUFFERS_2"]},
		{"if": ["met_marlo"], "lines": ["MARLO_AGAIN"]},
		{"set": ["met_marlo"], "lines": ["MARLO_1", "MARLO_2"]},
	],
	"hessa": [
		# Ottilie's old cave sign, carried by Wren's lamp.
		{"if": ["ottilie_signal"], "unless": ["hessa_answered_ottilie"], "set": ["hessa_answered_ottilie"], "lines": [["", "NARRATE_WREN_OTTILIE_SIGNAL"], "HESSA_OTTILIE_1", "HESSA_OTTILIE_2"]},
		{"if": ["seen_ending"], "lines": ["HESSA_AFTER_END"]},
		# The seventh bell rung: she rows Wren out to the Maw (StoryDirector).
		{"if": ["tidebell_tomb"], "unless": ["hessa_rows", "hessa_rowed"], "set": ["hessa_rows"], "lines": ["HESSA_ROW_1", "HESSA_ROW_2"]},
		{"if": ["seen_hessa_confession"], "lines": ["HESSA_AFTER_TURN"]},
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
		{"if": ["sorrel_letters", "met_agna"], "unless": ["letter_agna"], "set": ["letter_agna"], "lines": [["", "NARRATE_HAND_LETTER"], "AGNA_LETTER_1", "AGNA_LETTER_2"]},
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
		{"if": ["seen_ending"], "lines": ["TOBIN_END"]},
		{"lines": ["TOBIN_AFTER"]},
	],
	# Ide, the Causeway End ferrywoman: her boat stays tied up while the
	# Belfry's bell rings wrong under the channel. Asking sets ide_ferry,
	# and StoryDirector rows Wren over.
	"ide": [
		{"unless": ["tidebell_belfry"], "lines": ["IDE_1", "IDE_2"]},
		{"unless": ["met_ide_ferry"], "set": ["met_ide_ferry", "ide_ferry"], "lines": ["IDE_FERRY_1", "IDE_FERRY_2"]},
		{"if": ["seen_ending"], "set": ["ide_ferry"], "lines": ["IDE_END"]},
		{"set": ["ide_ferry"], "lines": ["IDE_FERRY_AGAIN"]},
	],
	# Liesl in Drowned Lane, and her great-grandmother's lost door bell
	# (a Doorbell out on Belfry Square's flats, there at low tide).
	"liesl": [
		{"if": ["sorrel_letters", "liesl_asked"], "unless": ["letter_liesl"], "set": ["letter_liesl"], "lines": [["", "NARRATE_HAND_LETTER"], "LIESL_LETTER_1", "LIESL_LETTER_2"]},
		{"if": ["wick_murmur_ask", "liesl_asked"], "unless": ["liesl_named_murmur"], "set": ["liesl_named_murmur"], "lines": ["LIESL_MURMUR_1", "LIESL_MURMUR_2"]},
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
		{"if": ["sorrel_letters", "ottilie_asked"], "unless": ["letter_ottilie"], "set": ["letter_ottilie"], "lines": [["", "NARRATE_HAND_LETTER"], "OTTILIE_LETTER_1", "OTTILIE_LETTER_2"]},
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
		# The post's last three letters, never sent when it shut.
		{"if": ["letter_ottilie", "letter_liesl", "letter_agna"], "unless": ["sorrel_letters_paid"], "set": ["sorrel_letters_paid"], "give": {"glint": 150}, "lines": ["SORREL_LETTERS_DONE_1", "SORREL_LETTERS_DONE_2", ["", "NARRATE_GOT_POSTAGE"]]},
		{"if": ["sorrel_letters"], "unless": ["sorrel_letters_paid"], "lines": ["SORREL_LETTERS_WAITING"]},
		{"if": ["sorrel_paid"], "unless": ["sorrel_letters"], "set": ["sorrel_letters"], "lines": ["SORREL_LETTERS_1", "SORREL_LETTERS_1B", "SORREL_LETTERS_2", "SORREL_LETTERS_2B", ["", "NARRATE_TAKE_LETTERS"]]},
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
		{"lines": ["LOWE_END_AGAIN"]},
	],
	# Murmur, who left the Choir at the calf, now helping Wick at Fenmouth.
	"murmur": [
		{"unless": ["murmur_met"], "set": ["murmur_met"], "lines": ["MURMUR_FEN_1", "MURMUR_FEN_2", "MURMUR_FEN_3"]},
		# The Reed family's lantern, lit at last (Wick, Liesl and Wren).
		{"if": ["murmur_lantern_lit"], "unless": ["murmur_saw_lantern"], "set": ["murmur_saw_lantern"], "lines": ["MURMUR_LANTERN_1", "MURMUR_LANTERN_2", "MURMUR_LANTERN_3"]},
		{"if": ["seen_ending"], "lines": ["MURMUR_END"]},
		{"if": ["old_one_turned"], "lines": ["MURMUR_TURNED"]},
		{"if": ["murmur_saw_lantern"], "lines": ["MURMUR_LANTERN_AGAIN"]},
		{"lines": ["MURMUR_AGAIN"]},
	],
	# Mother Dace by the last mural, after the ending.
	"dace": [
		{"unless": ["dace_sat"], "set": ["dace_sat"], "lines": ["DACE_END_1", "DACE_END_2"]},
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
	# Wick at Fenmouth, who counts the fen's lanterns every night, and the
	# five that have gone dark (FenLantern).
	"wick": [
		# A lantern for Murmur's family: Liesl knows the name, Wren lights it.
		{"if": ["liesl_named_murmur"], "has": ["glowmoth_lantern"], "unless": ["murmur_lantern_lit"], "set": ["murmur_lantern_lit"], "lines": ["WICK_LANTERN_1", ["", "NARRATE_WREN_LIGHTS_LANTERN"], "WICK_LANTERN_2"]},
		{"if": ["wick_murmur_ask"], "unless": ["murmur_lantern_lit"], "lines": ["WICK_MURMUR_WAITING"]},
		{"if": ["murmur_met", "wick_gave_jar"], "unless": ["wick_murmur_ask"], "set": ["wick_murmur_ask"], "lines": ["WICK_MURMUR_1", "WICK_MURMUR_1B", "WICK_MURMUR_2", "WICK_MURMUR_2B"]},
		{"if": ["wick_gave_jar", "seen_ending"], "lines": ["WICK_END", "WICK_END_2"]},
		{"if": ["wick_gave_jar", "old_one_turned"], "lines": ["WICK_TURNED"]},
		{"if": ["wick_gave_jar"], "lines": ["WICK_AFTER"]},
		{"if": ["fen_lanterns_lit"], "set": ["wick_gave_jar"], "give": {"jar": 1}, "lines": ["WICK_DONE_1", "WICK_DONE_2", ["", "NARRATE_GOT_JAR"]]},
		{"if": ["wick_asked"], "lines": ["WICK_WAITING"]},
		{"set": ["wick_asked"], "lines": ["WICK_1", "WICK_1B", "WICK_2", "WICK_2B", "WICK_3"]},
	],
	# Marga sends Wren to Dunstan for rope: a small errand made of flags.
	"marga": [
		{"if": ["marga_gave_jar", "seen_ending"], "lines": ["MARGA_END"]},
		{"if": ["marga_gave_jar", "old_one_turned"], "lines": ["MARGA_TURNED"]},
		{"if": ["marga_gave_jar"], "lines": ["MARGA_AFTER"]},
		{"if": ["marga_thanked", "tidebell_hull"], "set": ["marga_gave_jar"], "give": {"jar": 1}, "lines": ["MARGA_EEL_1", "MARGA_EEL_2", ["", "NARRATE_GOT_JAR"]]},
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
		out.append({"name": spec[0], "portrait": spec[1], "text": key})
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
