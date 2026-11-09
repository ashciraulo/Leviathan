class_name MapPage
extends MenuPage
## The map: every room Wren has seen, drawn from its layout (one tile = two
## pixels), with Wren, Tidestones and, in dungeons, what the map and compass
## reveal. Move the cursor between rooms; on a woken Tidestone, Interact
## blows the Wayshell and flies there (Events.fast_travel_requested).

const MAP_PANEL := Rect2(8, 22, 368, 128)
const INFO_PANEL := Rect2(8, 152, 368, 44)
const VIEW := Rect2(16, 38, 352, 104)
const PX := 2
const ROOM_PX := Vector2(Room.COLS * PX, Room.ROWS * PX)

## Map colours per region: floor, wall, water.
const BIOME_COLORS := {
	"saltmarrow": [Color("#e8c88a"), Color("#6b4e71"), Color("#2e7f8c")],
	"brinewood": [Color("#7e9a5a"), Color("#1f3d4a"), Color("#3e7a6e")],
	"hull": [Color("#a07e5e"), Color("#38282c"), Color("#3e665e")],
	"cinderreach": [Color("#86726f"), Color("#8a3428"), Color("#f2783a")],
}
const DEFAULT_COLORS := [Color("#b0a08e"), Color("#3a2e44"), Color("#2e7f8c")]

## Area names: "" is the overworld.
const AREA_KEYS := {"": "MAP_OVERWORLD", "hull": "DUNGEON_HULL"}

var _view: Control
var _area := ""
var _rooms: Array[Vector2i] = []
var _rects: Array = []
var _cursor := 0
var _texture: ImageTexture
var _origin := Vector2i.ZERO
var _scroll := Vector2.ZERO


func _ready() -> void:
	super()
	_view = Control.new()
	_view.position = VIEW.position
	_view.size = VIEW.size
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_view)
	add_child(_view)


func _process(delta: float) -> void:
	super(delta)
	if is_visible_in_tree():
		_view.queue_redraw()


func on_open() -> void:
	_area = GameState.dungeon
	GameState.mark_seen(GameState.room_coord)
	_rooms.clear()
	for coord in RoomInfo.in_area(_area):
		if _shown(coord):
			_rooms.append(coord)
	_rooms.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	_build_texture()
	_rects = _rooms.map(func(c: Vector2i) -> Rect2: return _room_rect(c))
	_cursor = maxi(_rooms.find(GameState.room_coord), 0)
	_scroll = _target_scroll()


func handle_input(event: InputEvent) -> bool:
	if _rooms.is_empty():
		return false
	var dir := MenuKit.direction(event)
	if dir != Vector2i.ZERO:
		_cursor = MenuKit.step(_rects, _cursor, dir)
		return true
	if MenuKit.confirm(event):
		if _can_fly_to(_rooms[_cursor]):
			Events.fast_travel_requested.emit(_rooms[_cursor])
			close_requested.emit()
		return true
	return false


func hint() -> String:
	if not _rooms.is_empty() and _can_fly_to(_rooms[_cursor]):
		return tr("HINT_MAP_FLY") % MenuKit.key_name("interact")
	return tr("HINT_MAP")


## Rooms on the map: seen ones, and in a dungeon all of them once Wren has
## its map.
func _shown(coord: Vector2i) -> bool:
	return GameState.has_seen(coord) or (_area != "" and GameState.has_dungeon_item(_area, "map"))


func _stone_awake(coord: Vector2i) -> bool:
	return GameState.flags.get("tidestone_%d_%d" % [coord.x, coord.y], false) \
		or GameState.tidestone_position(coord) != GameState.NO_POSITION


func _can_fly_to(coord: Vector2i) -> bool:
	return _area == "" and GameState.has_item("wayshell") and _stone_awake(coord) \
		and not RoomInfo.get_room(coord).get("stones", []).is_empty()


# --------------------------------------------------------------------------
# Drawing
# --------------------------------------------------------------------------

func _build_texture() -> void:
	_texture = null
	if _rooms.is_empty():
		return
	var lo := _rooms[0]
	var hi := _rooms[0]
	for c in _rooms:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	_origin = lo
	var span := hi - lo + Vector2i.ONE
	var image := Image.create_empty(span.x * Room.COLS, span.y * Room.ROWS, false, Image.FORMAT_RGBA8)
	for coord in _rooms:
		var info := RoomInfo.get_room(coord)
		var colors: Array = BIOME_COLORS.get(info["biome"], DEFAULT_COLORS)
		var fade := 1.0 if GameState.has_seen(coord) else 0.45
		var rows: PackedStringArray = info["rows"]
		var base := (coord - lo) * Vector2i(Room.COLS, Room.ROWS)
		for y in rows.size():
			for x in rows[y].length():
				var ch := rows[y][x]
				var color: Color = colors[1] if ch == "#" else (colors[2] if ch == "~" else colors[0])
				# A faint grain on floors, darker at room edges.
				if ch != "#" and ch != "~" and (x + y) % 2 == 0:
					color = color.darkened(0.06)
				if fade < 1.0:
					color = color.lerp(MenuKit.FILL_DARK, 1.0 - fade)
				image.set_pixel(base.x + x, base.y + y, color)
	_texture = ImageTexture.create_from_image(image)


## A room's rect in map space (before scrolling), in screen pixels.
func _room_rect(coord: Vector2i) -> Rect2:
	return Rect2(Vector2(coord - _origin) * ROOM_PX, ROOM_PX)


## Centre everything when it fits; otherwise follow the cursor.
func _target_scroll() -> Vector2:
	if _texture == null:
		return Vector2.ZERO
	var size := Vector2(_texture.get_size()) * PX
	var out := Vector2.ZERO
	for axis in 2:
		if size[axis] <= VIEW.size[axis]:
			out[axis] = roundf((VIEW.size[axis] - size[axis]) / 2.0)
		else:
			var center: float = _room_rect(_rooms[_cursor]).get_center()[axis]
			out[axis] = clampf(roundf(VIEW.size[axis] / 2.0 - center), VIEW.size[axis] - size[axis], 0.0)
	return out


func _draw() -> void:
	MenuKit.draw_panel(self, MAP_PANEL)
	MenuKit.draw_panel(self, INFO_PANEL)
	MenuKit.draw_text(self, AREA_KEYS.get(_area, "MAP_DUNGEON"), MAP_PANEL.position + Vector2(10, 5), MenuKit.TEXT_HEAD)
	if _area != "":
		var x := MAP_PANEL.end.x - 12
		for base: String in ["big_key", "compass", "map"]:
			x -= 17
			var owned := GameState.has_dungeon_item(_area, base)
			MenuKit.draw_icon(self, base, Vector2(x, MAP_PANEL.position.y + 3),
				Color.WHITE if owned else Color(0.2, 0.25, 0.4, 0.7))
	_draw_info()


func _draw_view() -> void:
	if _texture == null:
		MenuKit.draw_text(_view, "MAP_NOTHING", Vector2(0, VIEW.size.y / 2 - 6), MenuKit.TEXT_DIM,
			HORIZONTAL_ALIGNMENT_CENTER, VIEW.size.x)
		return
	_scroll = _scroll.lerp(_target_scroll(), 0.3).round()
	# Faint chart lines under the rooms, moving with the map.
	var line := Color(MenuKit.TEXT_HEAD, 0.07)
	var step := ROOM_PX / 2.0
	var x := fposmod(_scroll.x, step.x)
	while x < VIEW.size.x:
		_view.draw_rect(Rect2(x, 0, 1, VIEW.size.y), line)
		x += step.x
	var y := fposmod(_scroll.y, step.y)
	while y < VIEW.size.y:
		_view.draw_rect(Rect2(0, y, VIEW.size.x, 1), line)
		y += step.y
	_view.draw_texture_rect(_texture, Rect2(_scroll, Vector2(_texture.get_size()) * PX), false)
	var blink := int(Time.get_ticks_msec() / 250) % 3 != 0
	for coord in _rooms:
		var rect := _room_rect(coord)
		rect.position += _scroll
		var info := RoomInfo.get_room(coord)
		for tile: Vector2i in info["stones"]:
			if GameState.has_seen(coord) or _stone_awake(coord):
				var marker := MenuKit.Marker.STONE_AWAKE if _stone_awake(coord) else MenuKit.Marker.STONE_ASLEEP
				MenuKit.draw_marker(_view, marker, rect.position + Vector2(tile) * PX + Vector2(1, 0))
		if _area != "" and GameState.has_dungeon_item(_area, "compass"):
			for tile: Vector2i in info["chests"]:
				var flag := "chest_%d_%d_%d_%d" % [coord.x, coord.y, tile.x, tile.y]
				if not GameState.flags.get(flag, false):
					MenuKit.draw_marker(_view, MenuKit.Marker.CHEST, rect.position + Vector2(tile) * PX + Vector2(1, 1))
	# Wren, blinking, where she stands now.
	var here := _room_rect(GameState.room_coord)
	if _rooms.has(GameState.room_coord) and blink:
		var local := _player_local() / float(Room.TILE) * PX
		MenuKit.draw_marker(_view, MenuKit.Marker.WREN, here.position + _scroll + local + Vector2(0, -3))
	var selected: Rect2 = _rects[_cursor]
	selected.position += _scroll
	MenuKit.draw_cursor(_view, selected)


func _player_local() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Room.SIZE / 2.0
	return (player.global_position - Vector2(GameState.room_coord) * Room.SIZE).clamp(Vector2.ZERO, Room.SIZE)


func _draw_info() -> void:
	var at := INFO_PANEL.position + Vector2(10, 5)
	if _rooms.is_empty():
		return
	var coord := _rooms[_cursor]
	var info := RoomInfo.get_room(coord)
	var title: String = info["name_key"] if GameState.has_seen(coord) else "MAP_UNKNOWN_ROOM"
	MenuKit.draw_text(self, title, at, MenuKit.TEXT_GOLD)
	var line := ""
	if not info["stones"].is_empty():
		if not _stone_awake(coord):
			line = "MAP_STONE_ASLEEP"
		elif _area != "":
			line = "MAP_STONE_NO_FLY_INSIDE"
		elif not GameState.has_item("wayshell"):
			line = "MAP_STONE_NEED_WAYSHELL"
		else:
			line = "MAP_STONE_FLY"
	elif coord == GameState.room_coord:
		line = "MAP_YOU_ARE_HERE"
	if line != "":
		MenuKit.draw_text(self, line, at + Vector2(0, 12), MenuKit.TEXT)
