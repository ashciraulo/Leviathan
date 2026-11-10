class_name Conversations
extends Object
## Everything people say, and when they say it.
##
## Each speaker has a list of branches. Talking picks the FIRST branch whose
## conditions hold, so put the most specific branches at the top:
##
##   "if":     flags that must all be set
##   "unless": flags that must all be unset
##   "set":    flags to set when this branch is spoken
##   "lines":  the pages, in order
##   "give":   items handed to Wren, {id: count} (a narration line in
##             "lines" says so; the jingle plays as the box opens)
##
## A line is a translation key, said by the speaker. To give a page to
## someone else, use [speaker, key]. Use "" as the speaker for narration
## (Wren never speaks; narration says what Wren does instead. Hessa can't
## hear, so Wren answers her with the lamp: one flash yes, two no).
##
## Speakers: [name key, portrait texture or null].

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
		{"if": ["talked_corrin_quest"], "lines": ["CORRIN_AGAIN"]},
		{"if": ["met_hessa"], "set": ["talked_corrin_quest"], "lines": ["CORRIN_QUEST_1", "CORRIN_QUEST_2"]},
		{"lines": ["CORRIN_1", "CORRIN_2"]},
	],
	"pell": [
		{"if": ["found_crab"], "unless": ["pell_gave_pearl"], "set": ["pell_gave_pearl"], "give": {"breath_pearl": 1}, "lines": ["PELL_CRAB_1", "PELL_CRAB_2", ["", "NARRATE_GOT_PEARL"]]},
		{"if": ["tidebell_hull"], "unless": ["heard_pell_bell"], "set": ["heard_pell_bell"], "lines": ["PELL_BELL_1", "PELL_BELL_2"]},
		{"if": ["met_hessa", "entered_hull"], "unless": ["heard_pell_hull"], "set": ["heard_pell_hull"], "lines": ["PELL_HULL_1", "PELL_HULL_2"]},
		{"if": ["pell_gave_pearl"], "lines": ["PELL_CRAB_AGAIN"]},
		{"if": ["talked_pell_quest"], "lines": ["PELL_AGAIN"]},
		{"if": ["met_hessa"], "set": ["talked_pell_quest"], "lines": ["PELL_QUEST_1", "PELL_QUEST_2"]},
		{"lines": ["PELL_1", "PELL_2"]},
	],
	# Marga sends Wren to Dunstan for rope: a small errand made of flags.
	# Nettle wants to be a keeper, and learns the lamp signals from Wren.
	"nettle": [
		{"if": ["seen_wayshell"], "lines": ["NETTLE_WAYSHELL_1", "NETTLE_WAYSHELL_2"]},
		{"if": ["tidebell_hull"], "unless": ["heard_nettle_bell"], "set": ["heard_nettle_bell"], "lines": ["NETTLE_BELL_1", ["", "NARRATE_WREN_FLASH_ONCE"], "NETTLE_BELL_2"]},
		{"if": ["nettle_learned"], "lines": ["NETTLE_AGAIN"]},
		{"if": ["met_hessa"], "set": ["nettle_learned"], "lines": ["NETTLE_LEARN_1", "NETTLE_LEARN_2", ["", "NARRATE_WREN_LONG_GLOW"], "NETTLE_LEARN_3"]},
		{"lines": ["NETTLE_1", "NETTLE_2"]},
	],
	# Agna Holt, the last founder, outside the Kiln. After the Ember Bell she
	# lights her forge again and gives Wren a Brinesteel sword. She always
	# introduces herself first, even if Wren walked past her into the Kiln.
	"agna": [
		{"if": ["agna_gave_sword"], "lines": ["AGNA_SMITH"]},
		{"unless": ["met_agna"], "set": ["met_agna"], "lines": ["AGNA_1", "AGNA_2", "AGNA_3"]},
		{"if": ["tidebell_kiln"], "set": ["agna_gave_sword"], "give": {"brinesteel_sword": 1}, "lines": ["AGNA_AFTER_1", "AGNA_AFTER_2", ["", "NARRATE_GOT_BRINESTEEL"], "AGNA_AFTER_3"]},
		{"if": ["entered_kiln"], "lines": ["AGNA_KILN_1", "AGNA_KILN_2"]},
		{"lines": ["AGNA_AGAIN"]},
	],
	"marga": [
		{"if": ["marga_gave_jar"], "lines": ["MARGA_AFTER"]},
		{"if": ["marga_thanked", "tidebell_hull"], "set": ["marga_gave_jar"], "give": {"jar": 1}, "lines": ["MARGA_EEL_1", "MARGA_EEL_2", ["", "NARRATE_GOT_JAR"]]},
		{"if": ["marga_thanked"], "lines": ["MARGA_AGAIN"]},
		{"if": ["rope_promised"], "set": ["marga_thanked"], "lines": ["MARGA_THANKS_1", "MARGA_THANKS_2"]},
		{"if": ["asked_for_rope"], "lines": ["MARGA_WAITING"]},
		{"set": ["asked_for_rope"], "lines": ["MARGA_1", "MARGA_2", "MARGA_2B", ["", "NARRATE_WREN_NODS"]]},
	],
	"dunstan": [
		{"if": ["rope_promised"], "lines": ["DUNSTAN_AGAIN"]},
		{
			"if": ["asked_for_rope"],
			"set": ["rope_promised"],
			"lines": ["DUNSTAN_ROPE_1", ["", "NARRATE_WREN_NODS"], "DUNSTAN_ROPE_2", ["", "NARRATE_DUNSTAN_ROPE"]],
		},
		{"lines": ["DUNSTAN_1", "DUNSTAN_2"]},
	],
}


## The branch `speaker` would use right now, or {} if they have nothing to say.
static func branch_for(speaker: String) -> Dictionary:
	for branch: Dictionary in TALKS.get(speaker, []):
		if GameState.flags_match(branch.get("if", []), branch.get("unless", [])):
			return branch
	return {}


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
	var gifts: Dictionary = branch.get("give", {})
	for id: String in gifts:
		GameState.give_item(id, int(gifts[id]), false)
	if not gifts.is_empty():
		Audio.play_jingle("jingle_pearl" if gifts.has("breath_pearl") else "jingle_item")
	var shown := pages(speaker, branch)
	Events.conversation_requested.emit(shown)
	return shown
