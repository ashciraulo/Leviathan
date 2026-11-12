class_name Room
extends Node2D
## One screen of the world, built from a text layout so rooms are quick to
## block out. LDtk can replace the layout later without changing the rest.
##
## Legend:  #  wall           ~  water (blocks walking, not shots)
##          .  floor          P  start position (first room only)
##          T  Tidestone      c  Scuttler (chaser)
##          s  Spitter (shooter)    b  Shellback (blocker)
##          m  Bogskipper (ambusher, hides in the mud)
##          w  Lanternmoth (flyer, circles then dives)
##          e  Slagbeetle (charger; flip it against a wall)   y  geyser
##          q  Sporecap (bursts spores when Wren is close)
##          t  Tumbleburr (rolls with the wind)   J  windmill
##          0  Galehawk (circles high, stoops on Wren)
##          x  slick ice (Wren slides; regions with "ice" tiles)
##          g  Sledgeseal (rears, then slides at Wren)
##          r  tide flat (sand at low tide, water at high; see Tide)
##          ;  sea bed (water unless Wren holds the tide out; see Tide)
##          d  Siltray (swims the flooded flats; stranded when the tide's out)
##          Z  drowned cottage   B  the Drowned Belfry
##          p  the Old One's back (walkable)   N  the Old One's lip (the Maw)
##          S  sinking sand (drags Wren to its middle; see SinkField)
##          A  Dunejaw (burrows, spouts, bites)   U  great rib   F  whale skull (its side hollow, 4 right, is the door)
##          9  whale's lower jaw   (  a smaller whale skull
##          o  pot   u  barrel   f  rope fence   n  signpost
##          H  hut   L  lighthouse   M  mangrove   W  wreck
##          l  lantern post   R  beached hull (the Rotting Hull)
##             (big props: put the letter where the base centre stands;
##             the art rises above)
##          h  Old Hessa      1 2 3 4  villagers (see Npc.LETTERS)
##          7  Marlo Pike's market stall (MarketStall)
##          k  Pell's three-clawed crab (shows once Pell asks for it)
##          C  chest (holds chest_item)
##          *  a piece of sea-glass (SeaGlass; one per room, overworld only)
##          8  a pearl shard (PearlShard; four make a breath bubble)
##          :  boardwalk over water (walkable; regions with "boardwalk" tiles)
##          X  locked hatch (all X in a room open with one small key)
##          D  doorway to door_to, arriving on door_spawn
##          Dungeon pieces (see DungeonTiles):
##          _  gap in the deck (Wren can fall in)   O  hook post
##          K  crate (push it, or hook it)   =  pressure plate
##          |  bars (open when the room's gate is solved)   !  fixed bars
##          G  big-key door   V  the dungeon's boss
##          ^  lava (like a gap, but it burns)   Y  cracked boulder (mallet)
##          i  peg (mallet drives it down)   z  drop hammer
##          k  Clinker (slag-shelled beetle: flip it with the mallet)
##          j  brazier (the raised lantern lights it)
##          v  veiled plank (walkable only in lantern light)
##          q  Shade (only hurt in lantern light)   x  wisp
##          > < N S  wind fan blowing east, west, north, south
##          r  lightning rod
##          I  ice (Wren slides on it)   E  ice eye (shoot it)
##          a  Rimeling (skates across the room)
##          Q  deep water (blocks like ~; with the Diver's Helm, Wren swims
##             it, and can dive under)
##          L  sunken grate (dive under it)   R  valve (raises or lowers the water)
##          %  bone barricade   $  hidden bone wall (looks like wall)
##             (the Echo Horn brings both down)
##          Z  singing skull (the Echo Horn wakes it)
##          M  Marrowguard (bone shield)   U  the Hush (unseen till an echo)
##          @  Tollshell (tolls a ring of sound, then opens)
##          &  Puffwisp (floats, draws breath, blows Wren back)
##          +  Gumleech (swims in the Maw's palate floor ",", rears and bites)
##          ,  floor the water rises over: deep water while the dungeon's
##             water is high (see flooded())
##          (a signpost n reads out sign_key when Wren faces it)
##
## A room is 24 x 13 tiles. Leave a gap in the border wall where a
## neighbouring room joins, at the same rows or columns on both sides.
## Rooms live at res://rooms/room_<x>_<y>.tscn, where x and y are grid
## coordinates (x grows east, y grows south).

const TILE := 16
const COLS := 24
const ROWS := 13
const SIZE := Vector2(COLS * TILE, ROWS * TILE)

## Translation key for the room's name, shown on entry.
@export var name_key := ""
## Which region's tiles to draw with: a key of BIOMES.
@export var biome := "saltmarrow"
@export_multiline var layout := ""
## A second layout the room switches to once a story flag is set (the
## bay at Lullaby Point after the seventh bell). Same size as layout.
@export_multiline var alt_layout := ""
@export var alt_flag := ""
## Dungeon this room belongs to ("" for the overworld). Small keys found
## here only open doors in the same dungeon.
@export var dungeon := ""
## What a chest (C) in this room holds.
@export var chest_item := "small_key"
## How many of chest_item the chest holds (a cache of glints, say).
@export var chest_count := 1
## Where a doorway (D) in this room leads, and the tile Wren arrives on.
@export var door_to := Vector2i.ZERO
@export var door_spawn := Vector2i.ZERO
## What opens the bars (|) in this room: "plates" (every pressure plate held
## down), "clear" (every enemy beaten) or "" (they stay shut).
@export var gate := ""
## When true, the chest (C) only appears once the gate is solved.
@export var chest_hidden := false
## A listing deck: Wren drifts this way (pixels per second) unless they walk
## against it.
@export var tilt := Vector2.ZERO
## Rising lava: rows per second it climbs from the bottom of the room once
## Wren is inside (0 for none), and the row where they're safe from it.
@export var lava_rise := 0.0
@export var lava_safe_row := 2
## Holes in this floor (_) drop Wren to the floor below instead of
## costing a bubble: room fall_to, landing on tile fall_spawn.
@export var falls_through := false
@export var fall_to := Vector2i.ZERO
@export var fall_spawn := Vector2i.ZERO
## A dark room: only Wren's lantern and things that glow light it.
@export var dark := false
## What signposts (n) in this room say: a translation key.
@export var sign_key := ""
## A hollow or grotto off the overworld: the light falls off toward its
## rock walls (see CaveShade), so it feels tucked away.
@export var cave := false
## The tile of this room's elite, if it has one: the foe that starts there is
## the region's elite (bigger, tougher, with a pattern of its own; see Enemy).
## Once beaten it stays beaten.
@export var elite := Vector2i(-1, -1)
## An ambience loop for this room alone (audio/ambience/<id>), in place of
## its region's: "" uses the region's.
@export var ambience := ""
## Music for this room alone: a cue from audio/music/, or "none" to leave
## only the ambience (the Ebb Shelf and Grotto, where the Old One lies
## closest to the shore). "" plays its region's or dungeon's track.
@export var music := ""
## Windmere: the direction and strength (px/s) of the gusts that sweep
## this room. Zero means calm.
@export var wind := Vector2.ZERO

## Veiled planks that cross a drop, by tile (see _plank_over_drop).
var _drop_planks = null
## Set by the game before the room enters the tree.
var coord := Vector2i.ZERO
var player_spawn := SIZE / 2.0

var _rows := PackedStringArray()
var _ground: Node2D
## The ground is drawn in pieces of this many tiles, so a light (a dark
## room's lantern, a wisp) only shades the pieces it reaches: a whole-room
## canvas item under one small light costs a browser a lit full screen.
const GROUND_CHUNK := Vector2i(6, 5)
## The tiles the ground piece being drawn now covers, and the piece.
var _chunk_rect := Rect2i()
var _chunk: Node2D
var _water_frame := 0
## Water a frost arrow has frozen over (Vector2i tile: true). It reads as
## ice (I) until it thaws, and goes back to water when the room reloads.
var _frozen: Dictionary = {}
## Where the layout put swimmers (+, Gumleeches): palate floor under them.
var _swimmers: Array[Vector2i] = []
## Floor set pieces laid in this room: [top-left tile, which piece].
var _set_pieces: Array = []
## Tufts of grass (and ferns, scrub...) cut down in this visit: tile -> true.
var _cut: Dictionary = {}
## Floor decoration that a sword cuts down, by the start of its tile name,
## and the chance a cut tuft leaves a glint.
const PLANT_DECO := ["grass_", "fern_", "scrub_", "frond_", "tussock_"]
const GRASS_GLINT_ODDS := 0.2
## Hidden bone walls ($) the Echo Horn has brought down.
var _broken: Dictionary = {}
## Whether the layout has any I tiles (so ice checks can skip other rooms).
var _has_ice_tiles := false
var _water_body: StaticBody2D
var _deep_body: StaticBody2D
var _water_time := 0.0

const WATER_FRAME_TIME := 0.6

## Tile names per region, for the same layout letters. %d is a variant or
## animation frame; %s is a side (top, bottom, left, right).
const BIOMES := {
	"saltmarrow": {
		"floor": "sand_%d", "wall_top": "cliff_top_%d", "wall_face": "cliff_face_%d",
		"water": "water_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "shell_%d", "dry_deco": "grass_%d", "floor_overlay": ["ripple_%d", 7],
		"water_overlay": ["tidepool_%d", 5],
	},
	"brinewood": {
		"floor": "peat_%d", "wall_top": "canopy_%d", "wall_face": "roots_%d",
		"water": "bog_%d", "water_edge": "bank_%s_%d", "damp": "mire_%s",
		"wet_deco": "reeds_%d", "dry_deco": "fern_%d",
		# [tile, one in every n tiles]
		"floor_overlay": ["dapple_%d", 5], "water_overlay": ["lily_%d", 4],
		"boardwalk": "boardwalk_%s",
	},
	"cinderreach": {
		"floor": "ash_%d", "wall_top": "mesa_top_%d", "wall_face": "mesa_face_%d",
		"water": "lava_%d", "water_edge": "crust_%s_%d", "damp": "scorch_%s",
		"wet_deco": "vent_%d", "dry_deco": "scrub_%d",
		"floor_overlay": ["shimmer_%d", 7], "door": "exit_glow",
	},
	"gloamfen": {
		"floor": "fen_%d", "wall_top": "canopy_top_%d", "wall_face": "root_face_%d",
		"water": "gloom_%d", "water_edge": "reed_%s_%d", "damp": "mirk_%s",
		"wet_deco": "glowcap_%d", "dry_deco": "frond_%d",
		"floor_overlay": ["motes_%d", 11], "boardwalk": "boardwalk_%s", "door": "exit_glow",
	},
	"windmere": {
		"floor": "turf_%d", "wall_top": "chalk_top_%d", "wall_face": "chalk_face_%d",
		"water": "deep_sea_%d", "water_edge": "surf_%s_%d", "damp": "brink_%s",
		"wet_deco": "seapinks_%d", "dry_deco": "tussock_%d", "gap": "galesky",
		"floor_overlay": ["gust_%d", 9], "door": "exit_glow",
	},
	"frostspine": {
		"floor": "snow_%d", "wall_top": "glacier_top_%d", "wall_face": "glacier_face_%d",
		"water": "floe_sea_%d", "water_edge": "shelf_%s_%d", "damp": "drift_%s",
		"wet_deco": "ice_shards_%d", "dry_deco": "frost_rock_%d",
		"floor_overlay": ["snowfall_%d", 7], "ice": "slick_ice_%d", "door": "exit_glow",
		"gap": "crevasse",
	},
	"sunken_verge": {
		"floor": "silt_%d", "wall_top": "seawall_top_%d", "wall_face": "seawall_face_%d",
		"water": "shallows_%d", "water_edge": "tideline_%s_%d", "damp": "seep_%s",
		"wet_deco": "wrack_%d", "dry_deco": "cockle_%d",
		"floor_overlay": ["glint_%d", 9], "tidal": "flat_%d", "seabed": "seabed_%d", "door": "exit_glow",
	},
	"ossuary": {
		"floor": "dune_%d", "wall_top": "ossuary_top_%d", "wall_face": "ossuary_face_%d",
		"water": "bitter_sea_%d", "water_edge": "salt_crust_%s_%d", "damp": "sandshade_%s",
		"wet_deco": "thornbush_%d", "dry_deco": "bone_shards_%d",
		"floor_overlay": ["sanddrift_%d", 7],
	},
	"hull": {
		"wall_deco": "hull",
		"floor": "plank_%d", "wall_top": "hull_top_%d", "wall_face": "hull_face_%d",
		"water": "bilge_%d", "water_edge": "brine_%s_%d", "damp": "soak_%s",
		"wet_deco": "barnacles_%d", "dry_deco": "rope_%d",
		"floor_overlay": ["shaft_%d", 9], "door": "exit_glow",
		"set_pieces": 2,
	},
	"kiln": {
		"wall_deco": "kiln",
		"floor": "kiln_floor_%d", "wall_top": "kiln_top_%d", "wall_face": "kiln_face_%d",
		"water": "quench_%d", "water_edge": "kerb_%s_%d", "damp": "kiln_scorch_%s",
		"wet_deco": "cinder_%d", "dry_deco": "slagbit_%d",
		"floor_overlay": ["glowcrack_%d", 23], "door": "exit_glow",
		"set_pieces": 2,
	},
	"mire": {
		"wall_deco": "mire",
		"set_pieces": 2,
		"floor": "mire_floor_%d", "wall_top": "mire_top_%d", "wall_face": "mire_face_%d",
		"water": "murk_%d", "water_edge": "murkbank_%s_%d", "damp": "mirewet_%s",
		"wet_deco": "shrooms_%d", "dry_deco": "spores_%d",
		"floor_overlay": ["grave_lamp_%d", 29], "door": "exit_glow",
	},
	"gale": {
		"wall_deco": "gale",
		"set_pieces": 2,
		"floor": "gale_floor_%d", "wall_top": "gale_top_%d", "wall_face": "gale_face_%d",
		"water": "water_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "lichen_%d", "dry_deco": "feather_%d",
		"floor_overlay": ["lichen_%d", 17], "door": "exit_glow", "gap": "galesky",
	},
	"glacier": {
		"wall_deco": "glacier",
		"set_pieces": 2,
		"floor": "glacier_floor_%d", "wall_top": "icecave_top_%d", "wall_face": "icecave_face_%d",
		"water": "icewater_%d", "water_edge": "foam_%s_%d", "damp": "rime_%s",
		"wet_deco": "frostcrack_%d", "dry_deco": "snowdrift_%d",
		"floor_overlay": ["snowdrift_%d", 19], "door": "exit_glow", "gap": "crevasse",
	},
	"belfry": {
		"wall_deco": "belfry",
		"set_pieces": 2,
		"floor": "belfry_floor_%d", "wall_top": "belfry_top_%d", "wall_face": "belfry_face_%d",
		"water": "deepwater_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "seaweed_%d", "dry_deco": "seashell_%d",
		"floor_overlay": ["seashell_%d", 23], "door": "exit_glow",
	},
	"tomb": {
		"wall_deco": "tomb",
		"floor": "tomb_floor_%d", "wall_top": "tomb_top_%d", "wall_face": "tomb_face_%d",
		"water": "deepwater_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "bonechips_%d", "dry_deco": "bonechips_%d",
		"floor_overlay": ["ribs_%d", 37], "door": "exit_glow",
	},
	"maw": {
		"wall_deco": "maw",
		"floor": "maw_floor_%d", "wall_top": "maw_top_%d", "wall_face": "maw_face_%d",
		"water": "deepwater_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "vein_%d", "dry_deco": "dreammote_%d",
		"floor_overlay": ["vein_%d", 41], "door": "exit_glow", "drained": "maw_wet_%d",
	},
}


func _ready() -> void:
	y_sort_enabled = true
	if alt_flag != "" and alt_layout != "" and GameState.has_flag(alt_flag):
		layout = alt_layout
	add_to_group("rooms")
	_rows = parse_layout(layout)
	_lift_swimmers()
	_place_set_pieces()
	_has_ice_tiles = "I" in "".join(_rows)
	var problem := validate_layout(_rows)
	if problem != "":
		push_error("Room %s: %s" % [scene_file_path, problem])
	_ground = Node2D.new()
	_ground.name = "Ground"
	_ground.z_index = -10
	add_child(_ground)
	for cy in ceili(float(ROWS) / GROUND_CHUNK.y):
		for cx in ceili(float(COLS) / GROUND_CHUNK.x):
			var piece := Node2D.new()
			var rect := Rect2i(Vector2i(cx, cy) * GROUND_CHUNK, GROUND_CHUNK)
			piece.draw.connect(_draw_ground_piece.bind(piece, rect))
			_ground.add_child(piece)
	_build()
	if dark:
		var darkness := Darkness.new()
		darkness.name = "Darkness"
		add_child(darkness)


static func parse_layout(text: String) -> PackedStringArray:
	var rows := PackedStringArray()
	for line: String in text.split("\n"):
		var row := line.strip_edges()
		if row != "":
			rows.append(row)
	return rows


## Returns "" when the layout is the right size, otherwise what is wrong.
static func validate_layout(rows: PackedStringArray) -> String:
	if rows.size() != ROWS:
		return "expected %d rows, found %d" % [ROWS, rows.size()]
	for i in rows.size():
		if rows[i].length() != COLS:
			return "row %d has %d columns, expected %d" % [i, rows[i].length(), COLS]
	return ""


static func is_solid(tile: String) -> bool:
	return tile == "#" or tile == "~" or tile == "Q"


func _build() -> void:
	if cave:
		var shade := CaveShade.new()
		shade.name = "CaveShade"
		add_child(shade)
	var walls := _make_static(Layers.WORLD, "Walls")
	_water_body = _make_static(Layers.WATER, "Water")
	_deep_body = _make_static(Layers.DEEP, "DeepWater")
	# Tide flats (r): the tide comes first, so swimmers can find it.
	if dungeon == "" and (layout.contains("r") or layout.contains("d") or layout.contains(";")):
		var tide := Tide.new()
		tide.name = "Tide"
		add_child(tide)
	for y in _rows.size():
		var row := _rows[y]
		var x := 0
		while x < row.length():
			var tile := row[x]
			if tile == "#":
				# Merge a run of wall into one collision box.
				var start := x
				while x < row.length() and row[x] == tile:
					x += 1
				var size := Vector2((x - start) * TILE, TILE)
				var center := Vector2((start + x) * TILE / 2.0, y * TILE + TILE / 2.0)
				walls.add_child(Layers.rect_shape(size, center))
				continue
			if tile == "~" or tile == "Q" or tile == ",":
				x += 1
				continue
			_spawn(tile, Vector2(x * TILE + TILE / 2.0, y * TILE + TILE - 4))
			x += 1
	for at: Vector2i in _swimmers:
		_spawn("+", Vector2(at.x * TILE + TILE / 2.0, at.y * TILE + TILE - 4))
	_build_water()
	DungeonTiles.finish(self)
	# Inside the Old One, its breath floods the palate floor.
	if dungeon == "maw" and layout.contains(","):
		var breath := MawBreath.new()
		breath.name = "Breath"
		add_child(breath)
	# In a dungeon, x is a wisp, not ice.
	if dungeon == "" and layout.contains("x"):
		var ice := IceField.new()
		ice.name = "IceField"
		add_child(ice)
	if dungeon == "" and layout.contains("S"):
		var sink := SinkField.new()
		sink.name = "SinkField"
		add_child(sink)
	# Gulls, fish, crabs and the like, on the overworld only.
	if dungeon == "":
		var life := Ambience.new()
		life.name = "Ambience"
		add_child(life)
	if wind != Vector2.ZERO:
		var gust := Gust.new()
		gust.name = "Gust"
		gust.wind = wind
		add_child(gust)


## Water's collision, one box per run of water that isn't frozen. Deep
## water (Q, and flooded floor) goes on its own layer.
func _build_water() -> void:
	for body in [_water_body, _deep_body]:
		for shape in body.get_children():
			body.remove_child(shape)
			shape.queue_free()
	for y in _rows.size():
		var x := 0
		while x < COLS:
			var wet := _tile_at(x, y)
			if wet != "~" and wet != "Q":
				x += 1
				continue
			var start := x
			while x < COLS and _tile_at(x, y) == wet:
				x += 1
			var size := Vector2((x - start) * TILE, TILE)
			var body := _deep_body if wet == "Q" else _water_body
			body.add_child(Layers.rect_shape(size, Vector2((start + x) * TILE / 2.0, y * TILE + TILE / 2.0)))


## A hidden bone wall ($) has come down: it's floor now.
func break_wall(tile: Vector2i) -> void:
	_broken[tile] = true
	_redraw_ground()


## True when the room has any ice at all: I tiles or frozen water.
func has_ice() -> bool:
	return _has_ice_tiles or not _frozen.is_empty()


## True when the tile is water a frost arrow froze.
func is_frozen(tile: Vector2i) -> bool:
	return _frozen.has(tile)


## True when this room's "~" is lava (Cinderreach): frost can't touch it.
func is_lava() -> bool:
	return str(BIOMES.get(biome, {}).get("water", "")).begins_with("lava")


## Freezes water: the tile, or the whole pool when it's a small one (four
## tiles or fewer). Returns the tiles that froze.
func freeze(tile: Vector2i) -> Array[Vector2i]:
	var pool := water_pool(tile)
	var froze: Array[Vector2i] = []
	if pool.is_empty():
		return froze
	if pool.size() > 4:
		pool = [tile]
	for t in pool:
		if not _frozen.has(t):
			_frozen[t] = true
			froze.append(t)
	if not froze.is_empty():
		_build_water()
		_redraw_ground()
	return froze


## Lets frozen water go back to water.
func thaw(tiles: Array) -> void:
	var changed := false
	for t: Vector2i in tiles:
		changed = _frozen.erase(t) or changed
	if changed:
		_build_water()
		_redraw_ground()


## The open water joined to `tile` (empty when it isn't water).
func water_pool(tile: Vector2i) -> Array[Vector2i]:
	var pool: Array[Vector2i] = []
	if _tile_at(tile.x, tile.y) != "~" or is_lava():
		return pool
	var todo: Array[Vector2i] = [tile]
	var seen := {tile: true}
	while not todo.is_empty() and pool.size() <= 8:
		var t: Vector2i = todo.pop_back()
		pool.append(t)
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := t + d
			if not seen.has(n) and _tile_at(n.x, n.y) == "~":
				seen[n] = true
				todo.append(n)
	return pool


## True while this dungeon's water is high (its "," floor is under water).
## The Drowned Belfry's valves raise and lower it, for the whole dungeon;
## in the Maw it rises and falls with the Old One's breathing.
func flooded() -> bool:
	if dungeon == "maw":
		return MawBreath.high()
	return not GameState.has_flag(low_water_flag(dungeon))


static func low_water_flag(for_dungeon: String) -> String:
	return "low_water_" + for_dungeon


## Rebuilds the water after the level changes, and sees to what was in it:
## anything that can't swim, caught on flooding floor, is swept away.
func refresh_water() -> void:
	_build_water()
	_redraw_ground()


## The room under a point (global), or null.
static func under(tree: SceneTree, at: Vector2) -> Room:
	for node in tree.get_nodes_in_group("rooms"):
		var room := node as Room
		if room and not room.is_queued_for_deletion() and Rect2(room.global_position, SIZE).has_point(at):
			return room
	return null


## How deep each dungeon is on the way to the Old One (0 to 3). The
## regular enemies in deeper dungeons are tougher and hit harder, to keep
## pace with Wren's better swords and tunics (bosses have their own).
const DEPTH := {"hull": 0, "kiln": 0, "mire": 1, "gale": 1, "glacier": 2, "belfry": 2, "tomb": 3, "maw": 3}
## Health multiplier by depth (rounded up).
const DEPTH_HP := [1.0, 1.5, 1.5, 2.0]
## Extra contact damage by depth.
const DEPTH_DAMAGE := [0, 0, 0, 1]


## Toughens a regular enemy for this dungeon's depth (before its _ready).
## One-touch foes (a single point of health: wisps, moths) stay one-touch.
func _harden(node: Node) -> void:
	if not node is Enemy or not DEPTH.has(dungeon):
		return
	var enemy := node as Enemy
	if enemy.max_hp <= 1:
		return
	var depth: int = DEPTH[dungeon]
	enemy.max_hp = ceili(enemy.max_hp * DEPTH_HP[depth])
	if enemy.contact_damage > 0:
		enemy.contact_damage += DEPTH_DAMAGE[depth]


## A boss keeps its own health (its fight is built round so many
## openings), but deep down its touch hurts as much as the foes before it.
func _harden_boss(node: Node) -> void:
	if not node is Enemy or not DEPTH.has(dungeon):
		return
	var boss := node as Enemy
	if boss.contact_damage > 0:
		boss.contact_damage += DEPTH_DAMAGE[DEPTH[dungeon]]


func _spawn(tile: String, pos: Vector2) -> void:
	var node: Node2D = null
	# Dungeon pieces win in a dungeon: some of their letters (k q x) mean
	# something else out in the overworld.
	if dungeon != "" and DungeonTiles.handles(tile):
		node = DungeonTiles.make(tile, self, pos)
		if node:
			node.position = pos
			if tile != "V":
				_harden(node)
			else:
				_harden_boss(node)
			add_child(node)
		return
	match tile:
		".", ":", "x", "I", "r", ";", "S", "p":
			pass
		"P":
			player_spawn = pos
		"T":
			var stone := Tidestone.new()
			stone.room_coord = coord
			node = stone
		"c":
			node = Scuttler.new()
		"s":
			node = Spitter.new()
		"m":
			node = Bogskipper.new()
		"w":
			node = Lanternmoth.new()
		"e":
			node = Slagbeetle.new()
		"y":
			node = Geyser.new()
		"q":
			node = Sporecap.new()
		"t":
			node = Tumbleburr.new()
		"0":
			node = Galehawk.new()
		"g":
			node = Sledgeseal.new()
		"d":
			node = Siltray.new()
		"A":
			node = Dunejaw.new()
		"b":
			node = Shellback.new()
		"C":
			var chest := Chest.new()
			chest.room_coord = coord
			chest.tile = Vector2i(int(pos.x) / TILE, int(pos.y) / TILE)
			chest.dungeon = dungeon
			chest.item = chest_item
			chest.count = chest_count
			node = chest
		"X":
			var hatch := LockedDoor.new()
			hatch.room_coord = coord
			hatch.dungeon = dungeon
			node = hatch
		"D":
			var door := Doorway.new()
			door.target_room = door_to
			door.target_tile = door_spawn
			node = door
		"*":
			var glass := SeaGlass.new()
			glass.room_coord = coord
			glass.tile = Vector2i(int(pos.x) / TILE, int(pos.y) / TILE)
			node = glass
		"8":
			var shard := PearlShard.new()
			shard.room_coord = coord
			shard.tile = Vector2i(int(pos.x) / TILE, int(pos.y) / TILE)
			node = shard
		"k":
			node = QuestCrab.new()
		"7":
			node = MarketStall.new()
		_ when Npc.LETTERS.has(tile):
			node = Npc.new(Npc.LETTERS[tile])
		_ when Prop.is_prop(tile):
			var prop := Prop.new(tile)
			if tile == "n":
				prop.text_key = sign_key
			node = prop
		_ when DungeonTiles.handles(tile):
			node = DungeonTiles.make(tile, self, pos)
		_:
			push_warning("Room %s: unknown tile '%s'" % [scene_file_path, tile])
	if node is Enemy and Vector2i(int(pos.x) / TILE, int(pos.y) / TILE) == elite:
		if GameState.has_flag(elite_flag(coord)):
			node.free()
			node = null
		else:
			(node as Enemy).elite = true
	if node:
		node.position = pos
		_harden(node)
		add_child(node)


## The flag set when the elite of the room at `at` is beaten.
static func elite_flag(at: Vector2i) -> String:
	return "elite_%d_%d" % [at.x, at.y]


func _make_static(layer: int, node_name: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	Layers.assign(body, layer, [])
	add_child(body)
	return body


func _process(delta: float) -> void:
	_water_time += delta
	if _water_time >= WATER_FRAME_TIME:
		_water_time = 0.0
		_water_frame = 1 - _water_frame
		_redraw_ground()


## The letter as written in the layout, before water, ice or broken walls
## change what it means ("#" outside the room).
func raw_tile(x: int, y: int) -> String:
	if y < 0 or y >= _rows.size() or x < 0 or x >= _rows[y].length():
		return "#"
	return _rows[y][x]


## The layout letter at a tile (walls outside the room).
func tile_at(x: int, y: int) -> String:
	return _tile_at(x, y)


func _tile_at(x: int, y: int) -> String:
	if y < 0 or y >= _rows.size() or x < 0 or x >= _rows[y].length():
		return "#"
	if not _frozen.is_empty() and _frozen.has(Vector2i(x, y)):
		return "I"
	var letter := _rows[y][x]
	if letter == "L" and dungeon != "":
		return "Q"  # A sunken grate stands in deep water.
	if letter == "$":
		# A hidden bone wall: wall, until the Echo Horn brings it down.
		return "." if _broken.has(Vector2i(x, y)) else "#"
	if letter == ",":
		# Floor the water rises over: deep while the dungeon's water is high.
		return "Q" if flooded() else "."
	return letter


## A Gumleech (+) lives in the palate floor, so its tile is "," in the
## layout as far as the floor and water go; it is spawned after the rest.
func _lift_swimmers() -> void:
	_swimmers.clear()
	for y in _rows.size():
		var at := _rows[y].find("+")
		while at != -1:
			_swimmers.append(Vector2i(at, y))
			_rows[y] = _rows[y].substr(0, at) + "," + _rows[y].substr(at + 1)
			at = _rows[y].find("+", at + 1)


## Picks where this room's floor set pieces go (biomes with "set_pieces"):
## up to two 2x2 pictures, each in the middle of a 4x4 stretch of plain
## floor clear of the border, chosen by the room's hash so they stay put.
func _place_set_pieces() -> void:
	_set_pieces.clear()
	var tiles: Dictionary = BIOMES.get(biome, {})
	if not tiles.has("set_pieces") or _rows.size() != ROWS:
		return
	# A boss arena stays bare: nothing on its floor to mistake for a tell.
	if "V" in "".join(_rows):
		return
	# Crates get pushed along their row and column, and onto plates along
	# theirs, so keep pieces off those lines (a slab on a crate's route reads
	# as something in the way).
	var crate_rows := {}
	var crate_cols := {}
	for y in _rows.size():
		for x in _rows[y].length():
			if _rows[y][x] == "K" or _rows[y][x] == "=":
				crate_rows[y] = true
				crate_cols[x] = true
	var spots: Array = []
	for y in range(2, ROWS - 3):
		for x in range(2, COLS - 3):
			if _plain_block(x - 1, y - 1, 4) and not _on_lines(x - 1, 4, crate_cols) \
					and not _on_lines(y - 1, 4, crate_rows):
				spots.append(Vector2i(x, y))
	# (_hash's low bits repeat from room to room, so mix the room in fully;
	# Vector4i hashes with murmur3, which spreads small changes.)
	var key := {}
	for v: Vector2i in spots:
		key[v] = hash(Vector4i(v.x, v.y, coord.x, coord.y))
	spots.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return key[a] < key[b])
	var kinds: int = tiles["set_pieces"]
	var first := absi(hash(coord)) % kinds
	for spot: Vector2i in spots:
		if _set_pieces.size() >= 2:
			break
		if not _set_pieces.is_empty() and Vector2(spot - (_set_pieces[0][0] as Vector2i)).length() < 8.0:
			continue
		_set_pieces.append([spot, (first + _set_pieces.size()) % kinds])


## True when any of the size lines from start (with a line either side) is in lines.
func _on_lines(start: int, size: int, lines: Dictionary) -> bool:
	for i in range(start - 1, start + size + 1):
		if lines.has(i):
			return true
	return false


## True when the tile is a veiled plank over a drop (drawn as the drop, and
## no water or damp edges round it, which would give the path away).
func is_drop_plank(x: int, y: int) -> bool:
	return _tile_at(x, y) == "v" and (BIOMES.get(biome, {}).has("gap") or _plank_over_drop(x, y))


## True when a run of veiled planks crosses a drop (_) rather than water:
## some plank in the run touches a gap tile. Worked out once per room (the
## layout doesn't change), since the ground redraws every water frame.
func _plank_over_drop(x: int, y: int) -> bool:
	if _drop_planks == null:
		_drop_planks = {}
		for py in ROWS:
			for px in COLS:
				if _tile_at(px, py) == "v" and _plank_run_touches_drop(px, py):
					_drop_planks[Vector2i(px, py)] = true
	return _drop_planks.has(Vector2i(x, y))


func _plank_run_touches_drop(x: int, y: int) -> bool:
	var seen := {}
	var todo: Array[Vector2i] = [Vector2i(x, y)]
	while not todo.is_empty():
		var at: Vector2i = todo.pop_back()
		if seen.has(at):
			continue
		seen[at] = true
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var t := _tile_at(at.x + d.x, at.y + d.y)
			if t == "_":
				return true
			if t == "v":
				todo.append(at + d)
	return false


## True when every tile of the size x size block at x, y is plain floor.
func _plain_block(x0: int, y0: int, size: int) -> bool:
	for y in range(y0, y0 + size):
		for x in range(x0, x0 + size):
			if y < 0 or y >= _rows.size() or x < 0 or x >= _rows[y].length() or _rows[y][x] != ".":
				return false
	return true

## True when the tile shows a tuft a sword can cut (drawn by _draw_ground).
func has_plant(x: int, y: int) -> bool:
	var tiles: Dictionary = BIOMES.get(biome, BIOMES["saltmarrow"])
	var deco := str(tiles["dry_deco"])
	if not PLANT_DECO.any(func(start: String) -> bool: return deco.begins_with(start)):
		return false
	# Open floor only: not under a hut, a fence, a pot or anything else.
	if not _tile_at(x, y) in [".", "P"] or _cut.has(Vector2i(x, y)):
		return false
	if _hash(x, y) % 13 != 0 or _near_water(x, y):
		return false
	if not is_inside_tree():
		return true
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
	query.collision_mask = 1 << (Layers.WORLD - 1)
	return get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


## Cuts every tuft under `area` (global): clippings fly, now and then a glint
## is left. Returns how many were cut.
func cut_plants(area: Rect2) -> int:
	var local := Rect2(area.position - global_position, area.size)
	var cut := 0
	for y in range(maxi(floori(local.position.y / TILE), 0), mini(floori(local.end.y / TILE), ROWS - 1) + 1):
		for x in range(maxi(floori(local.position.x / TILE), 0), mini(floori(local.end.x / TILE), COLS - 1) + 1):
			if not has_plant(x, y):
				continue
			_cut[Vector2i(x, y)] = true
			cut += 1
			var at := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			var bits := Clippings.new()
			bits.position = at
			add_child(bits)
			Glint.drop.call_deferred(self, at + Vector2(0, 4), Glint.roll(GRASS_GLINT_ODDS))
	if cut > 0:
		Audio.play_sfx("grass_cut", area.get_center())
		_redraw_ground()
	return cut


## Cut grass flung up and drifting down.
class Clippings extends Node2D:
	const TIME := 0.5
	var _age := 0.0

	func _process(delta: float) -> void:
		_age += delta
		if _age >= TIME:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t := _age / TIME
		modulate.a = 1.0 - t * t
		for i in 5:
			var angle := TAU * i / 5.0 + 0.9
			var out := Vector2(cos(angle) * (2.0 + 9.0 * t), -6.0 * sin(t * PI) + sin(angle) * 4.0 * t)
			draw_rect(Rect2(out, Vector2(2, 1)), Color("#4f7a3a"))
			draw_rect(Rect2(out + Vector2(1, -1), Vector2(1, 1)), Color("#8cbf5a"))


## A stable pseudo-random number per tile, so variants don't flicker.
func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (coord.x * 83492791) ^ (coord.y * 2654435))


## Dungeon wall lights hang in pairs, mirrored across the room (x 5 and 18,
## clear of the HUD), on straight runs of wall face: both neighbours are
## faces, and so is the mirrored spot.
func _lit_face(x: int, y: int) -> bool:
	if not x in [5, 18]:
		return false
	for fx in [x, 23 - x]:
		if _tile_at(fx, y) != "#" or _tile_at(fx, y + 1) == "#":
			return false
		for dx in [-1, 1]:
			if _tile_at(fx + dx, y) != "#" or _tile_at(fx + dx, y + 1) == "#":
				return false
	return true


func _near_water(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _tile_at(x + dx, y + dy) in ["~", "v", "Q"] and not is_drop_plank(x + dx, y + dy):
				return true
	return false


## Draws the ground again (all its pieces).
func _redraw_ground() -> void:
	for piece: Node2D in _ground.get_children():
		piece.queue_redraw()


func _draw_ground_piece(piece: Node2D, rect: Rect2i) -> void:
	_chunk = piece
	_chunk_rect = rect
	_draw_ground()
	_chunk = null


func _draw_tile(tile_name: String, x: int, y: int) -> void:
	if not _chunk_rect.has_point(Vector2i(x, y)):
		return
	_chunk.draw_texture_rect_region(Art.WORLD_TILES, Rect2(x * TILE, y * TILE, TILE, TILE), TileAtlas.region(tile_name))


func _draw_ground() -> void:
	var tiles: Dictionary = BIOMES.get(biome, BIOMES["saltmarrow"])
	var r := _chunk_rect
	for y in range(r.position.y, mini(r.end.y, _rows.size())):
		for x in range(r.position.x, mini(r.end.x, _rows[y].length())):
			var tile := _tile_at(x, y)
			var h := _hash(x, y)
			if tile == "#":
				# 3/4 view: a wall shows its face when open ground is below it.
				if _tile_at(x, y + 1) == "#":
					_draw_tile(tiles["wall_top"] % (h % 2), x, y)
				else:
					_draw_tile(tiles["wall_face"] % (h % 2), x, y)
					if tiles.has("wall_deco"):
						# Dungeon walls: now and then a crack, something growing,
						# or a light set into the face.
						var pick := (h >> 5) % 12
						if _lit_face(x, y):
							_draw_tile("%s_walllight" % tiles["wall_deco"], x, y)
						elif pick < 3:
							_draw_tile("%s_%s" % [tiles["wall_deco"], ["wallcrack", "wallgrowth", "wallgrowth"][pick]], x, y)
			elif tile == ":" and tiles.has("boardwalk"):
				# Planks over the water: the water still shows round them.
				_draw_tile(tiles["water"] % _water_frame, x, y)
				var runs_vertical := (_tile_at(x, y - 1) == ":" or _tile_at(x, y + 1) == ":") \
						and _tile_at(x - 1, y) != ":" and _tile_at(x + 1, y) != ":"
				_draw_tile(tiles["boardwalk"] % ("v" if runs_vertical else "h"), x, y)
			elif tile == "I" and _frozen.has(Vector2i(x, y)):
				_draw_tile("floe_%d" % (h % 2), x, y)
			elif tile == "v" and is_drop_plank(x, y):
				# A veiled plank over a drop (the Spire's sky, a crypt's pit):
				# the drop shows under it, and the plank only when the lantern
				# finds it.
				var gap: String = tiles.get("gap", "gap")
				# The same pattern as the PitField's drop round it.
				var variant := (x * 7 + y * 3) % 2 if gap == "gap" else 0
				_draw_tile("%s_%d" % [gap, variant], x, y)
				if not _tile_at(x, y - 1) in ["_", "v"]:
					_draw_tile(gap + "_lip", x, y)
			elif tile == "~" or tile == "v" or tile == "Q":
				# Deep water is the same deep green wherever it is (Wren's
				# waterline is drawn to match it).
				_draw_tile(("deepwater_%d" if tile == "Q" else tiles["water"]) % _water_frame, x, y)
				if tile != "Q" and tiles.has("water_overlay") and h % int(tiles["water_overlay"][1]) == 0:
					_draw_tile(tiles["water_overlay"][0] % (h % 3 % 2), x, y)
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					# Boardwalks sit on the water, so no bank line against them.
					if not _tile_at(x + side[1], y + side[2]) in ["~", ":", "v", "Q"]:
						_draw_tile(tiles["water_edge"] % [side[0], _water_frame], x, y)
			else:
				var wet := _near_water(x, y)
				# Sea-glass or a pearl shard out on the ice lies on ice.
				var on_ice := tile in ["*", "8"] and _tile_at(x - 1, y) == "x" and _tile_at(x + 1, y) == "x"
				if (tile == "x" or on_ice) and tiles.has("ice"):
					_draw_tile(tiles["ice"] % (h % 2), x, y)
				elif Tide.is_seabed(tile) and tiles.has("seabed"):
					# Mostly bare; now and then a starfish or an anemone.
					var k := h % 9
					_draw_tile(tiles["seabed"] % (2 if k == 7 else 3 if k == 8 else k % 2), x, y)
				elif Tide.is_flat(tile) and tiles.has("tidal"):
					_draw_tile(tiles["tidal"] % (h % 2), x, y)
				elif tile == "p":
					_draw_tile("hide_%d" % (h % 2), x, y)
				else:
					_draw_tile(tiles["floor"] % (h % 4), x, y)
				# Damp ground fades out from any water alongside.
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					if _tile_at(x + side[1], y + side[2]) in ["~", "v", "Q"] and not is_drop_plank(x + side[1], y + side[2]):
						_draw_tile(tiles["damp"] % side[0], x, y)
				if _tile_at(x, y - 1) == "#":
					_draw_tile("shade_top", x, y)
					# A wall light's glow pooled below it; elsewhere, now and
					# then, debris fallen at the foot of a dungeon wall.
					if tiles.has("wall_deco") and _rows[y][x] == "." and _lit_face(x, y - 1):
						_draw_tile("%s_lightpool" % tiles["wall_deco"], x, y)
					elif tiles.has("wall_deco") and _rows[y][x] == "." and x > 0 and x < _rows[y].length() - 1 \
							and y < _rows.size() - 1 and (h >> 4) % 6 == 0:
						_draw_tile("%s_rubble_%d" % [tiles["wall_deco"], (h >> 7) % 2], x, y)
				if _tile_at(x - 1, y) == "#":
					_draw_tile("shade_left", x, y)
				if tile == "I":
					_draw_tile("glacier_ice_%d" % (h % 2), x, y)
				elif _rows[y][x] == ",":
					# The water's gone down: silt and puddles where it stood.
					_draw_tile(tiles.get("drained", "lowwater_silt_%d") % (h % 2), x, y)
				if tile == "D" and tiles.has("door"):
					_draw_tile(tiles["door"], x, y)
				elif tile != "I" and tiles.has("floor_overlay") and h % int(tiles["floor_overlay"][1]) == 1:
					_draw_tile(tiles["floor_overlay"][0] % (h % 2), x, y)
				if tile == "D" or tile == "I":
					pass
				elif wet and h % 11 == 0:
					_draw_tile(tiles["wet_deco"] % (h % 2), x, y)
				elif not wet and h % 13 == 0 and not _cut.has(Vector2i(x, y)):
					_draw_tile(tiles["dry_deco"] % (h % 2), x, y)
	# The floor set pieces go over the floor they lie on.
	var deco: String = tiles.get("wall_deco", "")
	for piece: Array in _set_pieces:
		var at: Vector2i = piece[0]
		for q in 4:
			_draw_tile("%s_set%d_%d" % [deco, piece[1], q], at.x + q % 2, at.y + q / 2)
