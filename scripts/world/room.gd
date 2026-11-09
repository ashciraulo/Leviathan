class_name Room
extends Node2D
## One screen of the world, built from a text layout so rooms are quick to
## block out. LDtk can replace the layout later without changing the rest.
##
## Legend:  #  wall           ~  water (blocks walking, not shots)
##          .  floor          P  start position (first room only)
##          T  Tidestone      c  Scuttler (chaser)
##          s  Spitter (shooter)    b  Shellback (blocker)
##          o  pot   u  barrel   f  rope fence   n  signpost
##          H  hut   L  lighthouse   (big props: put the letter where the
##             building's base centre stands; its art rises above)
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
@export_multiline var layout := ""

## Set by the game before the room enters the tree.
var coord := Vector2i.ZERO
var player_spawn := SIZE / 2.0

var _rows := PackedStringArray()
var _ground: Node2D
var _water_frame := 0
var _water_time := 0.0

const WATER_FRAME_TIME := 0.6


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


func _spawn(tile: String, pos: Vector2) -> void:
	var node: Node2D = null
	match tile:
		".":
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
		"b":
			node = Shellback.new()
		_ when Prop.is_prop(tile):
			node = Prop.new(tile)
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
	_ground.draw_texture_rect_region(Art.SALTMARROW_TILES, Rect2(x * TILE, y * TILE, TILE, TILE), TileAtlas.region(tile_name))


func _draw_ground() -> void:
	for y in _rows.size():
		for x in _rows[y].length():
			var tile := _tile_at(x, y)
			var h := _hash(x, y)
			if tile == "#":
				# 3/4 view: a wall shows its face when open ground is below it.
				if _tile_at(x, y + 1) == "#":
					_draw_tile("cliff_top_%d" % (h % 2), x, y)
				else:
					_draw_tile("cliff_face_%d" % (h % 2), x, y)
			elif tile == "~":
				_draw_tile("water_%d" % _water_frame, x, y)
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					if _tile_at(x + side[1], y + side[2]) != "~":
						_draw_tile("foam_%s_%d" % [side[0], _water_frame], x, y)
			else:
				var wet := _near_water(x, y)
				_draw_tile("sand_%d" % (h % 4), x, y)
				# Damp sand fades out from any water alongside.
				for side in [["top", 0, -1], ["bottom", 0, 1], ["left", -1, 0], ["right", 1, 0]]:
					if _tile_at(x + side[1], y + side[2]) == "~":
						_draw_tile("damp_%s" % side[0], x, y)
				if _tile_at(x, y - 1) == "#":
					_draw_tile("shade_top", x, y)
				if _tile_at(x - 1, y) == "#":
					_draw_tile("shade_left", x, y)
				if wet and h % 11 == 0:
					_draw_tile("shell_%d" % (h % 2), x, y)
				elif not wet and h % 13 == 0:
					_draw_tile("grass_%d" % (h % 2), x, y)
