class_name RoomInfo
extends Object
## What the map screen and the file select need to know about every room
## (name, region, dungeon, layout) without building them. Read once from
## res://rooms/ and cached.

const DIR := "res://rooms/"

## coord -> {name_key, biome, dungeon, rows, stones: Array[Vector2i] (tiles),
##           chests: Array[Vector2i], doors: Array[Vector2i],
##           glass: Array[Vector2i] (sea-glass),
##           boss: Vector2i (a dungeon boss's tile, or (-1, -1)),
##           door_to: Vector2i (where its door leads), chest_item, chest_count}
static var _rooms: Dictionary = {}
static var _loaded := false


static func all() -> Dictionary:
	if not _loaded:
		_load()
	return _rooms


static func get_room(coord: Vector2i) -> Dictionary:
	return all().get(coord, {})


static func has_room(coord: Vector2i) -> bool:
	return all().has(coord)


## The rooms of one dungeon, or of the overworld when dungeon is "".
static func in_area(dungeon: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for coord: Vector2i in all():
		if str(all()[coord]["dungeon"]) == dungeon:
			out.append(coord)
	return out


## Where Wren stands after flying to the Tidestone in this room, or
## GameState.NO_POSITION when the room has none.
static func stone_landing(coord: Vector2i) -> Vector2:
	var stones: Array = get_room(coord).get("stones", [])
	if stones.is_empty():
		return GameState.NO_POSITION
	var tile: Vector2i = stones[0]
	return Vector2(tile.x * Room.TILE + Room.TILE / 2.0, tile.y * Room.TILE + Room.TILE - 4) + Tidestone.CHECKPOINT_OFFSET


## A room's layout as it stands now: its alt_layout once its alt_flag is set
## (the Old One has turned, the seventh bell rung, and so on).
static func rows_now(coord: Vector2i) -> PackedStringArray:
	var info := get_room(coord)
	if str(info.get("alt_flag", "")) != "" and not (info["alt_rows"] as PackedStringArray).is_empty() \
			and GameState.has_flag(info["alt_flag"]):
		return info["alt_rows"]
	return info["rows"]


static func _load() -> void:
	_loaded = true
	_rooms = {}
	for file: String in ResourceLoader.list_directory(DIR):
		var coord: Variant = _coord_from_file(file)
		if coord == null:
			continue
		var scene := load(DIR + file) as PackedScene
		if scene == null:
			continue
		var room := scene.instantiate() as Room
		if room == null:
			continue
		var rows := Room.parse_layout(room.layout)
		var boss := Vector2i(-1, -1)
		if room.dungeon != "":
			var bosses := tiles_of(rows, "V")
			if not bosses.is_empty():
				boss = bosses[-1]
		_rooms[coord] = {
			"name_key": room.name_key,
			"biome": room.biome,
			"dungeon": room.dungeon,
			"rows": rows,
			"stones": tiles_of(rows, "T"),
			"chests": tiles_of(rows, "C"),
			"doors": tiles_of(rows, "D"),
			"glass": tiles_of(rows, "*"),
			"boss": boss,
			"door_to": room.door_to,
			"chest_item": room.chest_item,
			"chest_count": room.chest_count,
			"alt_flag": room.alt_flag,
			"alt_rows": Room.parse_layout(room.alt_layout) if room.alt_layout != "" else PackedStringArray(),
		}
		room.free()


## Every tile holding this layout letter, row by row. String.find does the
## searching, which keeps reading all the rooms quick (a hitch on the web
## build otherwise, the first time a menu or a save needs them).
static func tiles_of(rows: PackedStringArray, letter: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in rows.size():
		var x := rows[y].find(letter)
		while x != -1:
			out.append(Vector2i(x, y))
			x = rows[y].find(letter, x + 1)
	return out


## "room_3_-1.tscn" -> Vector2i(3, -1); null for anything else.
static func _coord_from_file(file: String) -> Variant:
	if not (file.begins_with("room_") and file.ends_with(".tscn")):
		return null
	var parts := file.trim_prefix("room_").trim_suffix(".tscn").split("_")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return null
	return Vector2i(int(parts[0]), int(parts[1]))
