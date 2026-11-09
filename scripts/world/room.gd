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
##          x  slick ice (Wren slides; regions with "ice" tiles)
##          g  Sledgeseal (rears, then slides at Wren)
##          o  pot   u  barrel   f  rope fence   n  signpost
##          H  hut   L  lighthouse   M  mangrove   W  wreck
##          l  lantern post   R  beached hull (the Rotting Hull)
##             (big props: put the letter where the base centre stands;
##             the art rises above)
##          h  Old Hessa      1 2 3 4  villagers (see Npc.LETTERS)
##          k  Pell's three-clawed crab (shows once Pell asks for it)
##          C  chest (holds chest_item)
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
## Dungeon this room belongs to ("" for the overworld). Small keys found
## here only open doors in the same dungeon.
@export var dungeon := ""
## What a chest (C) in this room holds.
@export var chest_item := "small_key"
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
## Windmere: the direction and strength (px/s) of the gusts that sweep
## this room. Zero means calm.
@export var wind := Vector2.ZERO

## Set by the game before the room enters the tree.
var coord := Vector2i.ZERO
var player_spawn := SIZE / 2.0

var _rows := PackedStringArray()
var _ground: Node2D
var _water_frame := 0
## Water a frost arrow has frozen over (Vector2i tile: true). It reads as
## ice (I) until it thaws, and goes back to water when the room reloads.
var _frozen: Dictionary = {}
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
		"wet_deco": "shell_%d", "dry_deco": "grass_%d",
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
		"wet_deco": "seapinks_%d", "dry_deco": "tussock_%d",
		"floor_overlay": ["gust_%d", 9], "door": "exit_glow",
	},
	"frostspine": {
		"floor": "snow_%d", "wall_top": "glacier_top_%d", "wall_face": "glacier_face_%d",
		"water": "floe_sea_%d", "water_edge": "shelf_%s_%d", "damp": "drift_%s",
		"wet_deco": "ice_shards_%d", "dry_deco": "frost_rock_%d",
		"floor_overlay": ["snowfall_%d", 7], "ice": "slick_ice_%d", "door": "exit_glow",
	},
	"hull": {
		"floor": "plank_%d", "wall_top": "hull_top_%d", "wall_face": "hull_face_%d",
		"water": "bilge_%d", "water_edge": "brine_%s_%d", "damp": "soak_%s",
		"wet_deco": "barnacles_%d", "dry_deco": "rope_%d",
		"floor_overlay": ["shaft_%d", 9], "door": "exit_glow",
	},
	"kiln": {
		"floor": "kiln_floor_%d", "wall_top": "kiln_top_%d", "wall_face": "kiln_face_%d",
		"water": "quench_%d", "water_edge": "kerb_%s_%d", "damp": "kiln_scorch_%s",
		"wet_deco": "cinder_%d", "dry_deco": "slagbit_%d",
		"floor_overlay": ["glowcrack_%d", 23], "door": "exit_glow",
	},
	"mire": {
		"floor": "mire_floor_%d", "wall_top": "mire_top_%d", "wall_face": "mire_face_%d",
		"water": "murk_%d", "water_edge": "murkbank_%s_%d", "damp": "mirewet_%s",
		"wet_deco": "shrooms_%d", "dry_deco": "spores_%d",
		"floor_overlay": ["grave_lamp_%d", 29], "door": "exit_glow",
	},
	"gale": {
		"floor": "gale_floor_%d", "wall_top": "gale_top_%d", "wall_face": "gale_face_%d",
		"water": "water_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "lichen_%d", "dry_deco": "feather_%d",
		"floor_overlay": ["lichen_%d", 17], "door": "exit_glow", "gap": "galesky",
	},
	"glacier": {
		"floor": "glacier_floor_%d", "wall_top": "icecave_top_%d", "wall_face": "icecave_face_%d",
		"water": "icewater_%d", "water_edge": "foam_%s_%d", "damp": "rime_%s",
		"wet_deco": "frostcrack_%d", "dry_deco": "snowdrift_%d",
		"floor_overlay": ["snowdrift_%d", 19], "door": "exit_glow", "gap": "crevasse",
	},
	"belfry": {
		"floor": "belfry_floor_%d", "wall_top": "belfry_top_%d", "wall_face": "belfry_face_%d",
		"water": "deepwater_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "seaweed_%d", "dry_deco": "seashell_%d",
		"floor_overlay": ["seashell_%d", 23], "door": "exit_glow",
	},
	"tomb": {
		"floor": "tomb_floor_%d", "wall_top": "tomb_top_%d", "wall_face": "tomb_face_%d",
		"water": "deepwater_%d", "water_edge": "foam_%s_%d", "damp": "damp_%s",
		"wet_deco": "bonechips_%d", "dry_deco": "ribs_%d",
		"floor_overlay": ["bonechips_%d", 17], "door": "exit_glow",
	},
}


func _ready() -> void:
	y_sort_enabled = true
	add_to_group("rooms")
	_rows = parse_layout(layout)
	_has_ice_tiles = "I" in "".join(_rows)
	var problem := validate_layout(_rows)
	if problem != "":
		push_error("Room %s: %s" % [scene_file_path, problem])
	_ground = Node2D.new()
	_ground.name = "Ground"
	_ground.z_index = -10
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
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
	var walls := _make_static(Layers.WORLD, "Walls")
	_water_body = _make_static(Layers.WATER, "Water")
	_deep_body = _make_static(Layers.DEEP, "DeepWater")
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
	_build_water()
	DungeonTiles.finish(self)
	# In a dungeon, x is a wisp, not ice.
	if dungeon == "" and layout.contains("x"):
		var ice := IceField.new()
		ice.name = "IceField"
		add_child(ice)
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


## True when the tile is water a frost arrow froze.
## A hidden bone wall ($) has come down: it's floor now.
func break_wall(tile: Vector2i) -> void:
	_broken[tile] = true
	_ground.queue_redraw()


## True when the room has any ice at all: I tiles or frozen water.
func has_ice() -> bool:
	return _has_ice_tiles or not _frozen.is_empty()


func is_frozen(tile: Vector2i) -> bool:
	return _frozen.has(tile)


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
		_ground.queue_redraw()
	return froze


## Lets frozen water go back to water.
func thaw(tiles: Array) -> void:
	var changed := false
	for t: Vector2i in tiles:
		changed = _frozen.erase(t) or changed
	if changed:
		_build_water()
		_ground.queue_redraw()


## The open water joined to `tile` (empty when it isn't water).
func water_pool(tile: Vector2i) -> Array[Vector2i]:
	var pool: Array[Vector2i] = []
	if _tile_at(tile.x, tile.y) != "~":
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
## The Drowned Belfry's valves raise and lower it, for the whole dungeon.
func flooded() -> bool:
	return not GameState.has_flag(low_water_flag(dungeon))


static func low_water_flag(for_dungeon: String) -> String:
	return "low_water_" + for_dungeon


## Rebuilds the water after the level changes, and sees to what was in it:
## anything that can't swim, caught on flooding floor, is swept away.
func refresh_water() -> void:
	_build_water()
	_ground.queue_redraw()


## The room under a point (global), or null.
static func under(tree: SceneTree, at: Vector2) -> Room:
	for node in tree.get_nodes_in_group("rooms"):
		var room := node as Room
		if room and not room.is_queued_for_deletion() and Rect2(room.global_position, SIZE).has_point(at):
			return room
	return null


func _spawn(tile: String, pos: Vector2) -> void:
	var node: Node2D = null
	# Dungeon pieces win in a dungeon: some of their letters (k q x) mean
	# something else out in the overworld.
	if dungeon != "" and DungeonTiles.handles(tile):
		node = DungeonTiles.make(tile, self, pos)
		if node:
			node.position = pos
			add_child(node)
		return
	match tile:
		".", ":", "x", "I":
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
		"g":
			node = Sledgeseal.new()
		"b":
			node = Shellback.new()
		"C":
			var chest := Chest.new()
			chest.room_coord = coord
			chest.tile = Vector2i(int(pos.x) / TILE, int(pos.y) / TILE)
			chest.dungeon = dungeon
			chest.item = chest_item
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
		"k":
			node = QuestCrab.new()
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
	if node:
		node.position = pos
		add_child(node)


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
		_ground.queue_redraw()


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


## A stable pseudo-random number per tile, so variants don't flicker.
func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (coord.x * 83492791) ^ (coord.y * 2654435))


func _near_water(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _tile_at(x + dx, y + dy) in ["~", "v", "Q"]:
				return true
	return false


func _draw_tile(tile_name: String, x: int, y: int) -> void:
	_ground.draw_texture_rect_region(Art.WORLD_TILES, Rect2(x * TILE, y * TILE, TILE, TILE), TileAtlas.region(tile_name))


func _draw_ground() -> void:
	var tiles: Dictionary = BIOMES.get(biome, BIOMES["saltmarrow"])
	for y in _rows.size():
		for x in _rows[y].length():
			var tile := _tile_at(x, y)
			var h := _hash(x, y)
			if tile == "#":
				# 3/4 view: a wall shows its face when open ground is below it.
				if _tile_at(x, y + 1) == "#":
					_draw_tile(tiles["wall_top"] % (h % 2), x, y)
				else:
					_draw_tile(tiles["wall_face"] % (h % 2), x, y)
			elif tile == ":" and tiles.has("boardwalk"):
				# Planks over the water: the water still shows round them.
				_draw_tile(tiles["water"] % _water_frame, x, y)
				var runs_vertical := (_tile_at(x, y - 1) == ":" or _tile_at(x, y + 1) == ":") \
						and _tile_at(x - 1, y) != ":" and _tile_at(x + 1, y) != ":"
				_draw_tile(tiles["boardwalk"] % ("v" if runs_vertical else "h"), x, y)
			elif tile == "I" and _frozen.has(Vector2i(x, y)):
				_draw_tile("floe_%d" % (h % 2), x, y)
			elif tile == "~" or tile == "v" or tile == "Q":
				# Deep water is the same deep green wherever it is (Wren's
				# waterline is drawn to match it).
				_draw_tile(("deepwater_%d" if tile == "Q" else tiles["water"]) % _water_frame, x, y)
				if tiles.has("water_overlay") and h % int(tiles["water_overlay"][1]) == 0:
					_draw_tile(tiles["water_overlay"][0] % (h % 3 % 2), x, y)
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					# Boardwalks sit on the water, so no bank line against them.
					if not _tile_at(x + side[1], y + side[2]) in ["~", ":", "v", "Q"]:
						_draw_tile(tiles["water_edge"] % [side[0], _water_frame], x, y)
			else:
				var wet := _near_water(x, y)
				if tile == "x" and tiles.has("ice"):
					_draw_tile(tiles["ice"] % (h % 2), x, y)
				else:
					_draw_tile(tiles["floor"] % (h % 4), x, y)
				# Damp ground fades out from any water alongside.
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					if _tile_at(x + side[1], y + side[2]) in ["~", "v", "Q"]:
						_draw_tile(tiles["damp"] % side[0], x, y)
				if _tile_at(x, y - 1) == "#":
					_draw_tile("shade_top", x, y)
				if _tile_at(x - 1, y) == "#":
					_draw_tile("shade_left", x, y)
				if tile == "I":
					_draw_tile("glacier_ice_%d" % (h % 2), x, y)
				elif _rows[y][x] == ",":
					# The water's gone down: silt and puddles where it stood.
					_draw_tile("silt_%d" % (h % 2), x, y)
				if tile == "D" and tiles.has("door"):
					_draw_tile(tiles["door"], x, y)
				elif tile != "I" and tiles.has("floor_overlay") and h % int(tiles["floor_overlay"][1]) == 1:
					_draw_tile(tiles["floor_overlay"][0] % (h % 2), x, y)
				if tile == "D" or tile == "I":
					pass
				elif wet and h % 11 == 0:
					_draw_tile(tiles["wet_deco"] % (h % 2), x, y)
				elif not wet and h % 13 == 0:
					_draw_tile(tiles["dry_deco"] % (h % 2), x, y)
