class_name Items
extends Object
## Every item in the game, in one table. Other code refers to items by id
## (a short snake_case string) and asks this table for the details.
##
## What Wren owns lives in GameState (inventory, equipment, the two item
## slots, jars). Give things with GameState.give_item(id); the satchel
## screen, the HUD, chests and saving all read from there.
##
## Kinds:
##   tool        found in dungeons, goes in item slot 1 or 2 (U / I)
##   ammo        a counted tool (puffer bombs, arrows): also slottable
##   sword, shield, tunic   equipment: owning a better one equips it
##   jar         an empty jar; its contents live in GameState.jars
##   quest       story things shown on the satchel's lower shelf
##   pearl       Breath Pearl: each one adds a breath bubble at once
##   dungeon     per-dungeon map, compass and big key (ids end in
##               _map, _compass, _big_key, e.g. "hull_map")
##   currency    glints (counted, never shown as a slot)
##
## icon is the frame in assets/ui/items.png (16 x 16 frames, 8 per row),
## drawn by tools/ui_art.py. Names are translation keys ITEM_<ID> and
## descriptions ITEM_<ID>_DESC in locale/strings.csv.

const TOOL := "tool"
const AMMO := "ammo"
const SWORD := "sword"
const SHIELD := "shield"
const TUNIC := "tunic"
const JAR := "jar"
const QUEST := "quest"
const PEARL := "pearl"
## A quarter of a Breath Pearl: every SHARDS_PER_BUBBLE add a bubble.
const SHARD := "shard"
const SHARDS_PER_BUBBLE := 4
const DUNGEON := "dungeon"
const CURRENCY := "currency"

## Jar contents. A Sea Sprite revives Wren when the last bubble pops.
const JAR_EMPTY := "empty"
const JAR_POTION := "potion"
const JAR_SPRITE := "sprite"
const JAR_ICONS := {JAR_EMPTY: 24, JAR_POTION: 25, JAR_SPRITE: 26}

## id: {kind, icon, [max], [tier]}. Order here is the satchel's order.
const DEFS := {
	# Dungeon tools, in the order they are found.
	"tide_hook": {"kind": TOOL, "icon": 0},
	"stonebreaker": {"kind": TOOL, "icon": 1},
	"glowmoth_lantern": {"kind": TOOL, "icon": 2},
	"kite_cloak": {"kind": TOOL, "icon": 3},
	"frostfang_bow": {"kind": TOOL, "icon": 4},
	"divers_helm": {"kind": TOOL, "icon": 5},
	"echo_horn": {"kind": TOOL, "icon": 6},
	"wayshell": {"kind": TOOL, "icon": 7},
	# Counted tools.
	"puffer_bombs": {"kind": AMMO, "icon": 8, "max": 20},
	"arrows": {"kind": AMMO, "icon": 9, "max": 30},
	"lamp_oil": {"kind": AMMO, "icon": 10, "max": 10},
	# Equipment. Higher tier wins.
	"driftwood_sword": {"kind": SWORD, "icon": 11, "tier": 1},
	"brinesteel_sword": {"kind": SWORD, "icon": 12, "tier": 2},
	"tidecaller_sword": {"kind": SWORD, "icon": 13, "tier": 3},
	"cork_buckler": {"kind": SHIELD, "icon": 14, "tier": 1},
	"coral_buckler": {"kind": SHIELD, "icon": 15, "tier": 2},
	"nacre_buckler": {"kind": SHIELD, "icon": 16, "tier": 3},
	"oilskin": {"kind": TUNIC, "icon": 17, "tier": 1},
	"scaleweave": {"kind": TUNIC, "icon": 18, "tier": 2},
	"abyssal": {"kind": TUNIC, "icon": 19, "tier": 3},
	# Up to four jars.
	"jar": {"kind": JAR, "icon": 24, "max": 4},
	# Story and collectables.
	"tidebell": {"kind": QUEST, "icon": 20, "max": 7},
	"breath_pearl": {"kind": PEARL, "icon": 21, "max": 8},
	# Twelve shards (PearlShard, room letter 8, or chests): three more bubbles.
	"pearl_shard": {"kind": SHARD, "icon": 33, "max": 12},
	"keeper_lamp": {"kind": QUEST, "icon": 22},
	"glint": {"kind": CURRENCY, "icon": 23, "max": 999},
	# Twelve pieces hidden off the beaten path (SeaGlass, room letter *).
	"sea_glass": {"kind": QUEST, "icon": 32, "max": 12},
	# Dungeon items (templates: the real ids are <dungeon>_map and so on).
	"map": {"kind": DUNGEON, "icon": 27},
	"compass": {"kind": DUNGEON, "icon": 28},
	"big_key": {"kind": DUNGEON, "icon": 29},
	"small_key": {"kind": DUNGEON, "icon": 30},
}

const DUNGEON_ITEMS := ["map", "compass", "big_key"]

## Tools in the satchel grid, in order (8 tools + 3 counted).
const SATCHEL_TOOLS := [
	"tide_hook", "stonebreaker", "glowmoth_lantern", "kite_cloak",
	"frostfang_bow", "divers_helm", "echo_horn", "wayshell",
	"puffer_bombs", "arrows", "lamp_oil",
]
const SWORDS := ["driftwood_sword", "brinesteel_sword", "tidecaller_sword"]
const SHIELDS := ["cork_buckler", "coral_buckler", "nacre_buckler"]
const TUNICS := ["oilskin", "scaleweave", "abyssal"]
const EQUIPMENT_KINDS := [SWORD, SHIELD, TUNIC]


## The definition for an id, or {} if there is no such item.
## "hull_map" finds the "map" template.
static func def(id: String) -> Dictionary:
	if DEFS.has(id):
		return DEFS[id]
	var base := dungeon_item_base(id)
	return DEFS.get(base, {}) if base != "" else {}


static func exists(id: String) -> bool:
	return not def(id).is_empty()


static func kind(id: String) -> String:
	return str(def(id).get("kind", ""))


static func icon(id: String) -> int:
	return int(def(id).get("icon", 0))


## Most you can carry (1 for things you either have or don't).
static func max_count(id: String) -> int:
	return int(def(id).get("max", 1))


static func tier(id: String) -> int:
	return int(def(id).get("tier", 0))


## Tools and counted tools can go in item slot 1 or 2.
static func slottable(id: String) -> bool:
	return kind(id) in [TOOL, AMMO]


static func name_key(id: String) -> String:
	var base := dungeon_item_base(id)
	return "ITEM_" + (base if base != "" else id).to_upper()


static func desc_key(id: String) -> String:
	return name_key(id) + "_DESC"


## "hull_map" -> "map". "" when id is not a dungeon item.
static func dungeon_item_base(id: String) -> String:
	for base: String in DUNGEON_ITEMS:
		if id.ends_with("_" + base):
			return base
	return ""


## "hull_map" -> "hull".
static func dungeon_of(id: String) -> String:
	var base := dungeon_item_base(id)
	return id.trim_suffix("_" + base) if base != "" else ""


## The id of a dungeon's map, compass or big key.
static func dungeon_item(dungeon: String, base: String) -> String:
	return "%s_%s" % [dungeon, base]


## Pixel rect of an icon in assets/ui/items.png.
static func icon_rect(frame: int) -> Rect2:
	return Rect2((frame % 8) * 16, (frame / 8) * 16, 16, 16)
