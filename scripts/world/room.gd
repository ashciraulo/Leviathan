class_name Room
extends Node2D
## One screen of the world, built from a text layout so rooms are quick to
## block out. LDtk can replace the layout later without changing the rest.
##
## Legend:  #  wall           ~  water (blocks walking, not shots)
##          .  floor          P  start position (first room only)
##          T  Tidestone      c  Scuttler (chaser)
##          s  Spitter (shooter)    b  Shellback (blocker)
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


func _draw_ground() -> void:
	for y in _rows.size():
		var row := _rows[y]
		for x in row.length():
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			match row[x]:
				"#":
					_ground.draw_rect(rect, Palette.WALL)
					_ground.draw_rect(Rect2(rect.position, Vector2(TILE, 3)), Palette.WALL_TOP)
				"~":
					_ground.draw_rect(rect, Palette.WATER)
					_ground.draw_rect(Rect2(rect.position + Vector2(3, 6), Vector2(6, 1)), Palette.WATER_LIGHT)
				_:
					_ground.draw_rect(rect, Palette.FLOOR if (x + y) % 2 == 0 else Palette.FLOOR_ALT)
