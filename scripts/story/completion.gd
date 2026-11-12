class_name Completion
extends Object
## What the Progress tab counts, region by region: side errands (underway
## and done), pearl shards, Tidestone carvings read, sea-glass and chests.
## A dungeon's rooms count toward the region its door stands in.
##
## QUESTS is the list of side errands. A new errand needs an entry here (the
## smoke test checks every flag below is one the game really sets).

## In the order Wren usually reaches them.
const REGIONS := ["saltmarrow", "brinewood", "cinderreach", "gloamfen",
	"windmere", "frostspine", "sunken_verge", "ossuary"]

## id, the region of the person who asks, the flag set when they ask and the
## flag set when it's done. Done counts as started too (some errands can be
## handed in before anyone asks).
const QUESTS := [
	# Saltmarrow
	{"id": "pell_crab", "region": "saltmarrow", "start": "talked_pell_quest", "done": "pell_gave_pearl"},
	{"id": "pell_shell", "region": "saltmarrow", "start": "pell_shell_ask", "done": "pell_shell_done"},
	{"id": "pell_night", "region": "saltmarrow", "start": "pell_night_ask", "done": "pell_pup_told"},
	{"id": "corrin_bottles", "region": "saltmarrow", "start": "corrin_bottles_ask", "done": "corrin_bottles_done"},
	{"id": "marga_rope", "region": "saltmarrow", "start": "asked_for_rope", "done": "marga_gave_jar"},
	{"id": "jam_trade", "region": "saltmarrow", "start": "trade_jam", "done": "trade_done"},
	{"id": "nettle_signals", "region": "saltmarrow", "start": "nettle_signals_ask", "done": "nettle_signals_done"},
	{"id": "lighting_day", "region": "saltmarrow", "start": "lighting_ask", "done": "lighting_day"},
	{"id": "dunstan_boat", "region": "saltmarrow", "start": "dunstan_boat_ask", "done": "dunstan_boat_done"},
	{"id": "hessa_log", "region": "saltmarrow", "start": "hessa_log_ask", "done": "hessa_log_done"},
	{"id": "hessa_walk", "region": "saltmarrow", "start": "hessa_walk_ask", "done": "hessa_walk_done"},
	{"id": "keepers_round", "region": "saltmarrow", "start": "hessa_round_ask", "done": "hessa_carved_wren"},
	{"id": "coralie_glass", "region": "saltmarrow", "start": "coralie_asked", "done": "coralie_chime_done"},
	{"id": "marlo_pearls", "region": "saltmarrow", "start": "marlo_pearls_ask", "done": "marlo_pearls_done"},
	{"id": "last_singers", "region": "saltmarrow", "start": "lowe_singers_ask", "done": "lowe_singers_done"},
	{"id": "lowe_garden", "region": "saltmarrow", "start": "lowe_garden_ask", "done": "lowe_garden_done"},
	# Brinewood
	{"id": "gully_strongbox", "region": "brinewood", "start": "gully_asked", "done": "gully_paid"},
	{"id": "gully_lanterns", "region": "brinewood", "start": "gully_lanterns_ask", "done": "gully_lanterns_done"},
	# Cinderreach
	{"id": "agna_scales", "region": "cinderreach", "start": "agna_scales_ask", "done": "agna_bell_cast"},
	{"id": "bram_chimes", "region": "cinderreach", "start": "bram_chimes_ask", "done": "bram_pot_cast"},
	# Gloamfen
	{"id": "wick_jar", "region": "gloamfen", "start": "wick_asked", "done": "wick_gave_jar"},
	{"id": "murmur_lantern", "region": "gloamfen", "start": "wick_murmur_ask", "done": "murmur_lantern_lit"},
	{"id": "lampless_sink", "region": "gloamfen", "start": "wick_told_sink", "done": "wick_saw_sink"},
	# Windmere Heights
	{"id": "sorrel_race", "region": "windmere", "start": "sorrel_asked", "done": "sorrel_paid"},
	{"id": "sorrel_letters", "region": "windmere", "start": "sorrel_letters", "done": "sorrel_letters_paid"},
	{"id": "gullcry_stacks", "region": "windmere", "start": "sorrel_dared_stacks", "done": "sorrel_saw_stacks"},
	{"id": "edge_survey", "region": "windmere", "start": "ferrin_survey_ask", "done": "ferrin_map_done"},
	# Frostspine
	{"id": "ottilie_rimefin", "region": "frostspine", "start": "ottilie_asked", "done": "ottilie_paid"},
	{"id": "ottilie_signal", "region": "frostspine", "start": "ottilie_signal", "done": "ottilie_reunion"},
	# Sunken Verge
	{"id": "liesl_bell", "region": "sunken_verge", "start": "liesl_asked", "done": "liesl_bell_hung"},
	{"id": "ide_board", "region": "sunken_verge", "start": "ide_board_ask", "done": "ide_board_done"},
	# Ossuary Dunes
	{"id": "bone_ring", "region": "ossuary", "start": "dace_told_ring", "done": "dace_saw_ring"},
]

const KINDS := ["underway", "done", "shards", "stones", "glass", "chests"]

## region -> {kind: [Array of what counts]}; built once from the rooms.
static var _spots: Dictionary = {}
static var _ways_in: Dictionary = {}


## The region a room counts toward: its own region, or for a dungeon room the
## region whose door leads into that dungeon.
static func region_of(coord: Vector2i) -> String:
	var info := RoomInfo.get_room(coord)
	if info.is_empty():
		return ""
	var dungeon := str(info["dungeon"])
	if dungeon == "":
		return str(info["biome"])
	return _dungeon_regions().get(dungeon, "")


## dungeon id -> the region its way in stands in.
static func _dungeon_regions() -> Dictionary:
	if _ways_in.is_empty():
		for coord: Vector2i in RoomInfo.in_area(""):
			var info := RoomInfo.get_room(coord)
			var target := RoomInfo.get_room(info["door_to"])
			if not target.is_empty() and str(target["dungeon"]) != "":
				_ways_in[str(target["dungeon"])] = str(info["biome"])
	return _ways_in


## Per region: how many of each kind there are and how many Wren has.
## region -> {"seen": bool, kind: [have, total]}. "underway" has no total
## (it's errands asked and not yet done); "done" counts against every errand.
static func tally() -> Dictionary:
	if _spots.is_empty():
		_build()
	var out := {}
	for region: String in REGIONS:
		var spots: Dictionary = _spots[region]
		var row := {"seen": false}
		for coord: Vector2i in spots["rooms"]:
			if GameState.has_seen(coord):
				row["seen"] = true
				break
		var underway := 0
		var done := 0
		for quest: Dictionary in spots["quests"]:
			if GameState.has_flag(quest["done"]):
				done += 1
			elif GameState.has_flag(quest["start"]):
				underway += 1
		row["underway"] = [underway, 0]
		row["done"] = [done, spots["quests"].size()]
		for kind: String in ["shards", "stones", "glass", "chests"]:
			var have := 0
			var total := 0
			for spot: Array in spots[kind]:
				total += int(spot[1])
				if GameState.has_flag(spot[0]):
					have += int(spot[1])
			row[kind] = [have, total]
		out[region] = row
	return out


## Every region's rows summed: kind -> [have, total].
static func totals(by_region: Dictionary) -> Dictionary:
	var out := {}
	for kind: String in KINDS:
		out[kind] = [0, 0]
		for region: String in by_region:
			out[kind][0] += by_region[region][kind][0]
			out[kind][1] += by_region[region][kind][1]
	return out


## Each region's rooms, errands and finds, as [flag, how many it's worth].
static func _build() -> void:
	_spots = {}
	for region: String in REGIONS:
		_spots[region] = {"rooms": [], "quests": [], "shards": [], "stones": [], "glass": [], "chests": []}
	for quest: Dictionary in QUESTS:
		_spots[quest["region"]]["quests"].append(quest)
	for coord: Vector2i in RoomInfo.all():
		var region := region_of(coord)
		if not _spots.has(region):
			continue
		var spots: Dictionary = _spots[region]
		var info := RoomInfo.get_room(coord)
		spots["rooms"].append(coord)
		var shard_chests := str(info["chest_item"]) == "pearl_shard"
		for tile: Vector2i in _both_layouts(info, "C"):
			var flag := "chest_%d_%d_%d_%d" % [coord.x, coord.y, tile.x, tile.y]
			if shard_chests:
				spots["shards"].append([flag, int(info["chest_count"])])
			else:
				spots["chests"].append([flag, 1])
		for tile: Vector2i in _both_layouts(info, "8"):
			spots["shards"].append(["pearl_shard_%d_%d_%d_%d" % [coord.x, coord.y, tile.x, tile.y], 1])
		if not _both_layouts(info, "*").is_empty():
			spots["glass"].append(["sea_glass_%d_%d" % [coord.x, coord.y], 1])
		if Tidestone.CARVINGS.has(coord):
			spots["stones"].append(["tidestone_read_%d_%d" % [coord.x, coord.y], 1])


## The tiles holding this letter in a room's layout or its alt_layout.
static func _both_layouts(info: Dictionary, letter: String) -> Array[Vector2i]:
	var out := RoomInfo.tiles_of(info["rows"], letter)
	for tile in RoomInfo.tiles_of(info["alt_rows"], letter):
		if not out.has(tile):
			out.append(tile)
	return out

