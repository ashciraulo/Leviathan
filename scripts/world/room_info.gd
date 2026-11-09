class_name RoomInfo
extends Object
## What the map screen and the file select need to know about every room
## (name, region, dungeon, layout) without building them. Read once from
## res://rooms/ and cached.

const DIR := "res://rooms/"

## coord -> {name_key, biome, dungeon, rows, stones: Array[Vector2i] (tiles),
##           chests: Array[Vector2i], doors: Array[Vector2i],
##           boss: Vector2i (a dungeon boss's tile, or (-1, -1))}
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
		var stones: Array[Vector2i] = []
		var chests: Array[Vector2i] = []
		var doors: Array[Vector2i] = []
		var boss := Vector2i(-1, -1)
		for y in rows.size():
			for x in rows[y].length():
				match rows[y][x]:
					"T":
						stones.append(Vector2i(x, y))
					"C":
						chests.append(Vector2i(x, y))
					"D":
						doors.append(Vector2i(x, y))
					"V":
						if room.dungeon != "":
							boss = Vector2i(x, y)
		_rooms[coord] = {
			"name_key": room.name_key,
			"biome": room.biome,
			"dungeon": room.dungeon,
			"rows": rows,
			"stones": stones,
			"chests": chests,
			"doors": doors,
			"boss": boss,
			"alt_flag": room.alt_flag,
			"alt_rows": Room.parse_layout(room.alt_layout) if room.alt_layout != "" else PackedStringArray(),
		}
		room.free()


## "room_3_-1.tscn" -> Vector2i(3, -1); null for anything else.
static func _coord_from_file(file: String) -> Variant:
	if not (file.begins_with("room_") and file.ends_with(".tscn")):
		return null
	var parts := file.trim_prefix("room_").trim_suffix(".tscn").split("_")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return null
	return Vector2i(int(parts[0]), int(parts[1]))
