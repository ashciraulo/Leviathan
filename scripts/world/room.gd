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
##          o  pot   u  barrel   f  rope fence   n  signpost
##          H  hut   L  lighthouse   M  mangrove   W  wreck
##          l  lantern post   R  beached hull (the Rotting Hull)
##             (big props: put the letter where the base centre stands;
##             the art rises above)
##          h  Old Hessa      1 2 3 4  villagers (see Npc.LETTERS)
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
## A listing deck: Wren drifts this way (pixels per second) unless she walks
## against it.
@export var tilt := Vector2.ZERO
## Rising lava: rows per second it climbs from the bottom of the room once
## Wren is inside (0 for none), and the row where she's safe from it.
@export var lava_rise := 0.0
@export var lava_safe_row := 2
## What signposts (n) in this room say: a translation key.
@export var sign_key := ""

## Set by the game before the room enters the tree.
var coord := Vector2i.ZERO
var player_spawn := SIZE / 2.0

var _rows := PackedStringArray()
var _ground: Node2D
var _water_frame := 0
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
}


func _ready() -> void:
	y_sort_enabled = true
	_rows = parse_layout(layout)
	var problem := validate_layout(_rows)
	if problem != "":
		push_error("Room %s: %s" % [scene_file_path, problem])
	_ground = Node2D.new()
	_ground.name = "Ground"
	_ground.z_index = -10
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
	_build()


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
	return tile == "#" or tile == "~"


func _build() -> void:
	var walls := _make_static(Layers.WORLD, "Walls")
	var water := _make_static(Layers.WATER, "Water")
	for y in _rows.size():
		var row := _rows[y]
		var x := 0
		while x < row.length():
			var tile := row[x]
			if is_solid(tile):
				# Merge a run of the same tile into one collision box.
				var start := x
				while x < row.length() and row[x] == tile:
					x += 1
				var body := walls if tile == "#" else water
				var size := Vector2((x - start) * TILE, TILE)
				var center := Vector2((start + x) * TILE / 2.0, y * TILE + TILE / 2.0)
				body.add_child(Layers.rect_shape(size, center))
				continue
			_spawn(tile, Vector2(x * TILE + TILE / 2.0, y * TILE + TILE - 4))
			x += 1
	DungeonTiles.finish(self)


func _spawn(tile: String, pos: Vector2) -> void:
	var node: Node2D = null
	match tile:
		".", ":":
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
	return _rows[y][x]


## A stable pseudo-random number per tile, so variants don't flicker.
func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (coord.x * 83492791) ^ (coord.y * 2654435))


func _near_water(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _tile_at(x + dx, y + dy) == "~":
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
			elif tile == "~":
				_draw_tile(tiles["water"] % _water_frame, x, y)
				if tiles.has("water_overlay") and h % int(tiles["water_overlay"][1]) == 0:
					_draw_tile(tiles["water_overlay"][0] % (h % 3 % 2), x, y)
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					# Boardwalks sit on the water, so no bank line against them.
					if not _tile_at(x + side[1], y + side[2]) in ["~", ":"]:
						_draw_tile(tiles["water_edge"] % [side[0], _water_frame], x, y)
			else:
				var wet := _near_water(x, y)
				_draw_tile(tiles["floor"] % (h % 4), x, y)
				# Damp ground fades out from any water alongside.
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					if _tile_at(x + side[1], y + side[2]) == "~":
						_draw_tile(tiles["damp"] % side[0], x, y)
				if _tile_at(x, y - 1) == "#":
					_draw_tile("shade_top", x, y)
				if _tile_at(x - 1, y) == "#":
					_draw_tile("shade_left", x, y)
				if tile == "D" and tiles.has("door"):
					_draw_tile(tiles["door"], x, y)
				elif tiles.has("floor_overlay") and h % int(tiles["floor_overlay"][1]) == 1:
					_draw_tile(tiles["floor_overlay"][0] % (h % 2), x, y)
				if tile == "D":
					pass
				elif wet and h % 11 == 0:
					_draw_tile(tiles["wet_deco"] % (h % 2), x, y)
				elif not wet and h % 13 == 0:
					_draw_tile(tiles["dry_deco"] % (h % 2), x, y)
