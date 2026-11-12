class_name SatchelPage
extends MenuPage
## The satchel: tools (set them on item slot 1 or 2), jars, gear (equip a
## sword, shield and tunic), and the keeper's shelf: item slots, Tidebells,
## Breath Pearls and glints. The selected thing is described along the bottom.

const TOOLS_PANEL := Rect2(8, 22, 124, 128)
const GEAR_PANEL := Rect2(136, 22, 100, 128)
const KEEPER_PANEL := Rect2(240, 22, 136, 128)
const SHARD_AT := Vector2(354, 89)
const INFO_PANEL := Rect2(8, 152, 368, 44)
const STEP := 24

## Each cell: {rect: Rect2, role: String, id: String, index: int}
## role is tool, jar, gear, lamp, slot, bell, pearl or glint.
var _cells: Array[Dictionary] = []
var _rects: Array = []
var _cursor := 0
## Item-slot key tags, drawn last so they sit above the cursor.
var _badges: Array = []


func _ready() -> void:
	super()
	_build_cells()


func _build_cells() -> void:
	_cells.clear()
	for i in 12:
		var id: String = Items.SATCHEL_TOOLS[i] if i < Items.SATCHEL_TOOLS.size() else ""
		_add(Vector2(20 + (i % 4) * STEP, 40 + (i / 4) * STEP), "tool", id, i)
	for i in 4:
		_add(Vector2(20 + i * STEP, 124), "jar", "jar", i)
	var gear := [Items.SWORDS, Items.SHIELDS, Items.TUNICS]
	for row in 3:
		for col in 3:
			_add(Vector2(152 + col * STEP, 40 + row * STEP), "gear", gear[row][col], col)
	_add(Vector2(152, 124), "lamp", "keeper_lamp", 0)
	# The jumper Wren wears, once Ottilie has knitted one: until then the
	# keeper's navy is all there is.
	if Jumpers.owned().size() > 1:
		_add(Vector2(176, 124), "jumper", "", 0)
	for i in 2:
		_add(Vector2(256 + i * 40, 40), "slot", "", i)
	# 15 apart, so all eight Breath Pearls fit across the shelf.
	for i in Items.max_count("tidebell"):
		_add(Vector2(249 + i * 15, 77), "bell", "tidebell", i, 15)
	for i in Items.max_count("breath_pearl"):
		_add(Vector2(249 + i * 15, 107), "pearl", "breath_pearl", i, 15)
	_add(Vector2(249, 128), "glint", "glint", 0, 16)
	# Pearl shards sit at the end of the pearls' heading once Wren has one.
	if GameState.has_item("pearl_shard"):
		_add(SHARD_AT, "shard", "pearl_shard", 0, 16)
	# Sea-glass shows beside the glints once Wren has found a piece: until
	# then nothing says there's a set to find.
	if GameState.item_count("sea_glass") > 0:
		_add(Vector2(312, 128), "count", "sea_glass", 0, 16)
	_rects = _cells.map(func(c: Dictionary) -> Rect2: return c["rect"])


func _add(pos: Vector2, role: String, id: String, index: int, size: int = MenuKit.SLOT_SIZE) -> void:
	_cells.append({"rect": Rect2(pos, Vector2(size, size)), "role": role, "id": id, "index": index})


func on_open() -> void:
	# Cells come and go (the jumper, sea-glass), so keep the cursor on the
	# same cell rather than the same place in the list.
	var was: Dictionary = _cells[_cursor] if _cursor < _cells.size() else {}
	_build_cells()
	var same := _cells.find_custom(func(c: Dictionary) -> bool: return c["role"] == was.get("role") and c["index"] == was.get("index"))
	_cursor = same if same >= 0 else clampi(_cursor, 0, _cells.size() - 1)


func handle_input(event: InputEvent) -> bool:
	var dir := MenuKit.direction(event)
	if dir != Vector2i.ZERO:
		_cursor = MenuKit.step(_rects, _cursor, dir)
		return true
	var cell := _cells[_cursor]
	var id := _owned_id(cell)
	if event.is_action_pressed("item_1") or event.is_action_pressed("item_2"):
		if cell["role"] == "tool" and id != "":
			GameState.assign_slot(0 if event.is_action_pressed("item_1") else 1, id)
		return true
	if MenuKit.confirm(event):
		match cell["role"]:
			"tool":
				if id != "":
					GameState.assign_slot(1 if GameState.item_slots[0] == id else 0, id)
			"gear":
				if id != "":
					GameState.equip(id)
			"jumper":
				GameState.jumper = Jumpers.next(GameState.jumper)
				Audio.play_sfx("ui_select")
			"slot":
				GameState.item_slots[cell["index"]] = ""
			"jar":
				if _jar(cell) == Items.JAR_POTION:
					var wren := get_tree().get_first_node_in_group("player") as Player
					if wren and not wren.drink_potion():
						Audio.play_sfx("ui_back")
		return true
	return false


func hint() -> String:
	var cell := _cells[_cursor]
	var id := _owned_id(cell)
	if cell["role"] == "tool" and id != "":
		return tr("HINT_SATCHEL_TOOL") % [MenuKit.key_name("item_1"), MenuKit.key_name("item_2")]
	if cell["role"] == "gear" and id != "":
		return tr("HINT_SATCHEL_GEAR") % MenuKit.key_name("interact")
	if cell["role"] == "jumper":
		return tr("HINT_SATCHEL_JUMPER") % MenuKit.key_name("interact")
	if cell["role"] == "jar" and _jar(cell) == Items.JAR_POTION:
		return tr("HINT_SATCHEL_DRINK") % MenuKit.key_name("interact")
	if cell["role"] == "slot" and GameState.item_slots[cell["index"]] != "":
		return tr("HINT_SATCHEL_CLEAR") % MenuKit.key_name("interact")
	return ""


## What the jar in a jar cell holds, or "" past the jars Wren owns.
func _jar(cell: Dictionary) -> String:
	var i: int = cell["index"]
	return str(GameState.jars[i]) if i < GameState.jars.size() else ""


## The item id a cell shows, or "" when Wren doesn't have it.
func _owned_id(cell: Dictionary) -> String:
	match cell["role"]:
		"slot":
			return str(GameState.item_slots[cell["index"]])
		"jar":
			return "jar" if cell["index"] < GameState.jars.size() else ""
		"bell", "pearl":
			return cell["id"] if cell["index"] < GameState.item_count(cell["id"]) else ""
		"glint":
			return "glint"
		"count":
			return cell["id"] if GameState.item_count(cell["id"]) > 0 else ""
		"jumper":
			return "jumper"
		_:
			var id: String = cell["id"]
			return id if id != "" and GameState.has_item(id) else ""


func _draw() -> void:
	MenuKit.draw_panel(self, TOOLS_PANEL)
	MenuKit.draw_panel(self, GEAR_PANEL)
	MenuKit.draw_panel(self, KEEPER_PANEL)
	MenuKit.draw_panel(self, INFO_PANEL)
	MenuKit.draw_text(self, "SATCHEL_TOOLS", Vector2(18, 28), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		TOOLS_PANEL.end.x - 24)
	MenuKit.draw_text(self, "SATCHEL_JARS", Vector2(18, 111), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		TOOLS_PANEL.end.x - 24)
	MenuKit.draw_text(self, "SATCHEL_GEAR", Vector2(146, 28), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		GEAR_PANEL.end.x - 152)
	MenuKit.draw_text(self, "SATCHEL_LAMP", Vector2(146, 111), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		GEAR_PANEL.end.x - 152)
	MenuKit.draw_text(self, "SATCHEL_SLOTS", Vector2(250, 28), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		KEEPER_PANEL.end.x - 256)
	MenuKit.draw_text(self, "SATCHEL_BELLS", Vector2(250, 64), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		KEEPER_PANEL.end.x - 256)
	MenuKit.draw_text(self, "SATCHEL_PEARLS", Vector2(250, 94), MenuKit.TEXT_HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		SHARD_AT.x - 252)
	_badges.clear()
	for cell in _cells:
		_draw_cell(cell)
	MenuKit.draw_cursor(self, _cells[_cursor]["rect"])
	# Badges go over the cursor: its corner brackets would hide them.
	for badge: Array in _badges:
		_draw_badge(badge[0], badge[1])
	_draw_info()


func _draw_cell(cell: Dictionary) -> void:
	var rect: Rect2 = cell["rect"]
	var id := _owned_id(cell)
	var icon_at := rect.position + Vector2(2, 2)
	match cell["role"]:
		"tool", "jar", "gear", "lamp", "slot":
			var lit: bool = (cell["role"] == "tool" and id != "" and id in GameState.item_slots) \
				or (cell["role"] == "gear" and id != "" and GameState.equipped_item(Items.kind(id)) == id) \
				or (cell["role"] == "slot" and id != "")
			MenuKit.draw_slot(self, rect.position, lit)
			if id == "":
				pass
			elif cell["role"] == "jar":
				MenuKit.draw_icon_frame(self, Items.JAR_ICONS[GameState.jars[cell["index"]]], icon_at)
			else:
				MenuKit.draw_icon(self, id, icon_at)
				if Items.kind(id) == Items.AMMO:
					_draw_count(rect, GameState.item_count(id))
			if cell["role"] == "tool" and id != "":
				var slot := GameState.item_slots.find(id)
				if slot >= 0:
					_badges.append([rect, MenuKit.key_name("item_1" if slot == 0 else "item_2")])
			if cell["role"] == "slot":
				MenuKit.draw_text(self, MenuKit.key_name("item_1" if cell["index"] == 0 else "item_2"),
					rect.position + Vector2(22, 6), MenuKit.TEXT_GOLD)
		"bell", "pearl":
			if id != "":
				MenuKit.draw_icon(self, cell["id"], rect.position)
			else:
				MenuKit.draw_icon(self, cell["id"], rect.position, Color(0.2, 0.25, 0.4, 0.7))
		"jumper":
			MenuKit.draw_slot(self, rect.position, true)
			ShopMenu.draw_knit(self, rect.position + Vector2(2, 2), Jumpers.ramp(GameState.jumper))
		"shard":
			MenuKit.draw_icon(self, cell["id"], rect.position)
		"glint", "count":
			MenuKit.draw_icon(self, cell["id"], rect.position)
			MenuKit.draw_text(self, "x %d" % GameState.item_count(cell["id"]), rect.position + Vector2(19, 4))


func _draw_count(rect: Rect2, count: int) -> void:
	var text := str(count)
	var w := MenuKit.text_width(self, text)
	MenuKit.draw_text(self, text, rect.end - Vector2(w + 1, 10), MenuKit.TEXT)


## A key on a small dark tag at the slot's top-left corner.
func _draw_badge(rect: Rect2, text: String) -> void:
	var w := ceilf(MenuKit.text_width(self, text))
	var tag := Rect2(rect.position + Vector2(-3, -1), Vector2(w + 3, 9))
	draw_rect(tag.grow(1), MenuKit.INK)
	draw_rect(tag, MenuKit.FILL_DARK)
	MenuKit.draw_text(self, text, tag.position + Vector2(2, 0), MenuKit.TEXT_GOLD)


func _draw_info() -> void:
	var cell := _cells[_cursor]
	var id := _owned_id(cell)
	var at := INFO_PANEL.position + Vector2(10, 5)
	var width := INFO_PANEL.size.x - 20
	if id == "":
		var empty_key := "SATCHEL_EMPTY_SLOT" if cell["role"] == "slot" else "SATCHEL_EMPTY"
		MenuKit.draw_text(self, empty_key, at, MenuKit.TEXT_DIM)
		return
	if cell["role"] == "jumper":
		MenuKit.draw_text(self, Jumpers.name_key(GameState.jumper), at, MenuKit.TEXT_GOLD)
		MenuKit.draw_wrapped(self, Jumpers.name_key(GameState.jumper) + "_INFO", at + Vector2(0, 12), width, MenuKit.TEXT, 2)
		return
	var title := tr(Items.name_key(id))
	match cell["role"]:
		"jar":
			title = tr("ITEM_JAR_" + str(GameState.jars[cell["index"]]).to_upper())
		"bell":
			title = tr("SATCHEL_BELL_COUNT") % [title, GameState.item_count("tidebell"), Items.max_count("tidebell")]
		"pearl", "count", "shard":
			title = tr("SATCHEL_BELL_COUNT") % [title, GameState.item_count(cell["id"]), Items.max_count(cell["id"])]
	MenuKit.draw_text(self, title, at, MenuKit.TEXT_GOLD)
	var desc := Items.desc_key(id)
	if cell["role"] == "jar":
		desc = "ITEM_JAR_" + str(GameState.jars[cell["index"]]).to_upper() + "_DESC"
	MenuKit.draw_wrapped(self, desc, at + Vector2(0, 12), width, MenuKit.TEXT, 2)
