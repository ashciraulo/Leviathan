extends Node
## Global game state: Wren's breath and Resonance, the last checkpoint, and
## story flags (keys, bells, tide). SaveManager saves all of it.

const START_BUBBLES := 5
const MAX_BUBBLES := 10
const START_RESONANCE_MAX := 30.0
## Resonance gained per sword hit that connects.
const RESONANCE_PER_HIT := 3.0
## Sentinel for "no saved position: use the room's start marker".
const NO_POSITION := Vector2(-1, -1)

var max_bubbles := START_BUBBLES
var bubbles := START_BUBBLES
var resonance := 0.0
var resonance_max := START_RESONANCE_MAX
## Where Wren comes back after loading or dying (the last Tidestone touched).
var checkpoint_room := Vector2i.ZERO
var checkpoint_pos := NO_POSITION
## The room Wren is in right now. Not saved: loading always uses the checkpoint.
var room_coord := Vector2i.ZERO
## The dungeon that room belongs to ("" on the overworld). Not saved.
var dungeon := ""
var flags: Dictionary = {}

## What Wren carries: item id -> count. See scripts/items/items.gd.
var inventory: Dictionary = {}
## Equipment in use, by kind (sword, shield, tunic): item id or "".
var equipped: Dictionary = {}
## The tools on item slot 1 (U / X) and item slot 2 (I / Y). "" is empty.
var item_slots: Array = ["", ""]
## One entry per jar Wren owns: Items.JAR_EMPTY, JAR_POTION or JAR_SPRITE.
var jars: Array = []
## Woken Tidestones for fast travel: "x_y" -> [checkpoint x, checkpoint y].
var tidestones: Dictionary = {}
## Seconds played on this file (counted by the game scene while unpaused).
var play_time := 0.0

## What a new file starts with: the keeper's lamp, a driftwood sword and
## the oilskin tunic.
const START_ITEMS := {"keeper_lamp": 1, "driftwood_sword": 1, "oilskin": 1}


func reset_new_game() -> void:
	max_bubbles = START_BUBBLES
	bubbles = START_BUBBLES
	resonance = 0.0
	resonance_max = START_RESONANCE_MAX
	checkpoint_room = Vector2i.ZERO
	checkpoint_pos = NO_POSITION
	room_coord = Vector2i.ZERO
	dungeon = ""
	flags = {}
	inventory = {}
	equipped = {}
	item_slots = ["", ""]
	jars = []
	tidestones = {}
	play_time = 0.0
	for id: String in START_ITEMS:
		give_item(id, START_ITEMS[id], false)


## Most hits pop one bubble, heavy hits pop two. There are no halves.
func damage(amount: int) -> void:
	bubbles = maxi(bubbles - amount, 0)


func heal(amount: int) -> void:
	bubbles = mini(bubbles + amount, max_bubbles)


func refill() -> void:
	bubbles = max_bubbles


func is_dead() -> bool:
	return bubbles <= 0


func add_resonance(amount: float) -> void:
	resonance = clampf(resonance + amount, 0.0, resonance_max)


## One Hum costs a third of the meter, so a bigger meter (from Tidebells)
## stores more heals but each heal costs more hits to earn.
func hum_cost() -> float:
	return resonance_max / 3.0


func can_hum() -> bool:
	return bubbles < max_bubbles and resonance + 0.001 >= hum_cost()


func hum_heal() -> void:
	resonance = maxf(resonance - hum_cost(), 0.0)
	heal(1)


## Small keys belong to one dungeon and only open doors there.
func keys(dungeon: String) -> int:
	return int(flags.get("keys_" + dungeon, 0))


func add_key(dungeon: String) -> void:
	flags["keys_" + dungeon] = keys(dungeon) + 1


## Spends a key if there is one. Returns false when Wren has none.
func use_key(dungeon: String) -> bool:
	if keys(dungeon) <= 0:
		return false
	flags["keys_" + dungeon] = keys(dungeon) - 1
	return true


# --------------------------------------------------------------------------
# Items. Always go through these; nothing else writes inventory.
# --------------------------------------------------------------------------

## Adds an item. Tools go into the first empty item slot, better equipment
## is put on straight away, jars arrive empty, and a Breath Pearl adds a
## bubble. Emits Events.item_gained unless announce is false.
func give_item(id: String, count: int = 1, announce: bool = true) -> void:
	if not Items.exists(id):
		push_error("Unknown item id: %s" % id)
		return
	if count <= 0:
		return
	var before := item_count(id)
	var after := mini(before + count, Items.max_count(id))
	inventory[id] = after
	var gained := after - before
	match Items.kind(id):
		Items.TOOL, Items.AMMO:
			if before == 0 and not id in item_slots:
				var empty := item_slots.find("")
				if empty >= 0:
					item_slots[empty] = id
		Items.SWORD, Items.SHIELD, Items.TUNIC:
			var kind := Items.kind(id)
			if Items.tier(id) > Items.tier(str(equipped.get(kind, ""))):
				equipped[kind] = id
		Items.JAR:
			for i in gained:
				jars.append(Items.JAR_EMPTY)
		Items.PEARL:
			max_bubbles = mini(max_bubbles + gained, MAX_BUBBLES)
			bubbles = mini(bubbles + gained, max_bubbles)
	if announce and gained > 0:
		Events.item_gained.emit(id, gained)


func has_item(id: String) -> bool:
	return item_count(id) > 0


func item_count(id: String) -> int:
	return int(inventory.get(id, 0))


## Spends count of an item (bombs, arrows, oil, glints). Returns false and
## spends nothing when there aren't enough.
func take_item(id: String, count: int = 1) -> bool:
	if item_count(id) < count:
		return false
	inventory[id] = item_count(id) - count
	if inventory[id] <= 0 and Items.kind(id) != Items.AMMO:
		inventory.erase(id)
		for i in item_slots.size():
			if item_slots[i] == id:
				item_slots[i] = ""
	return true


## Map, compass or big key of a dungeon ("map", "compass", "big_key").
func has_dungeon_item(dungeon_id: String, base: String) -> bool:
	return has_item(Items.dungeon_item(dungeon_id, base))


## Puts a tool on item slot 0 or 1. If it was on the other slot, the two
## swap, so a tool is never on both.
func assign_slot(slot: int, id: String) -> void:
	if slot < 0 or slot >= item_slots.size():
		return
	if id != "" and not (Items.slottable(id) and has_item(id)):
		return
	var other := item_slots.find(id) if id != "" else -1
	if other >= 0 and other != slot:
		item_slots[other] = item_slots[slot]
	item_slots[slot] = id


## Equips an owned sword, shield or tunic.
func equip(id: String) -> void:
	var kind := Items.kind(id)
	if kind in Items.EQUIPMENT_KINDS and has_item(id):
		equipped[kind] = id


func equipped_item(kind: String) -> String:
	return str(equipped.get(kind, ""))


## Fills the first empty jar. Returns false if every jar is full.
func fill_jar(contents: String) -> bool:
	var i := jars.find(Items.JAR_EMPTY)
	if i < 0:
		return false
	jars[i] = contents
	return true


# --------------------------------------------------------------------------
# Map: rooms seen and Tidestones woken.
# --------------------------------------------------------------------------

static func seen_flag(coord: Vector2i) -> String:
	return "seen_%d_%d" % [coord.x, coord.y]


func mark_seen(coord: Vector2i) -> void:
	flags[seen_flag(coord)] = true


func has_seen(coord: Vector2i) -> bool:
	return bool(flags.get(seen_flag(coord), false))


## Remembers a woken Tidestone and where Wren stands when she lands there.
func wake_tidestone(coord: Vector2i, stand_at: Vector2) -> void:
	tidestones["%d_%d" % [coord.x, coord.y]] = [stand_at.x, stand_at.y]


func tidestone_coords() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for key: String in tidestones:
		var parts := key.split("_")
		if parts.size() == 2:
			out.append(Vector2i(int(parts[0]), int(parts[1])))
	return out


func tidestone_position(coord: Vector2i) -> Vector2:
	return _to_vec2(tidestones.get("%d_%d" % [coord.x, coord.y], null))


func set_checkpoint(room: Vector2i, pos: Vector2) -> void:
	checkpoint_room = room
	checkpoint_pos = pos


func to_dict() -> Dictionary:
	return {
		"max_bubbles": max_bubbles,
		"bubbles": bubbles,
		"resonance": resonance,
		"resonance_max": resonance_max,
		"checkpoint_room": [checkpoint_room.x, checkpoint_room.y],
		"checkpoint_pos": [checkpoint_pos.x, checkpoint_pos.y],
		"flags": flags.duplicate(true),
		"inventory": inventory.duplicate(),
		"equipped": equipped.duplicate(),
		"item_slots": item_slots.duplicate(),
		"jars": jars.duplicate(),
		"tidestones": tidestones.duplicate(true),
		"play_time": play_time,
	}


func from_dict(data: Dictionary) -> void:
	max_bubbles = clampi(int(data.get("max_bubbles", START_BUBBLES)), 1, MAX_BUBBLES)
	# Never load into a dead state.
	bubbles = clampi(int(data.get("bubbles", max_bubbles)), 1, max_bubbles)
	resonance_max = maxf(float(data.get("resonance_max", START_RESONANCE_MAX)), 1.0)
	resonance = clampf(float(data.get("resonance", 0.0)), 0.0, resonance_max)
	checkpoint_room = _to_vec2i(data.get("checkpoint_room", [0, 0]))
	checkpoint_pos = _to_vec2(data.get("checkpoint_pos", [NO_POSITION.x, NO_POSITION.y]))
	room_coord = checkpoint_room
	var saved_flags = data.get("flags", {})
	flags = saved_flags if saved_flags is Dictionary else {}
	inventory = {}
	var saved_inventory = data.get("inventory", START_ITEMS)
	if saved_inventory is Dictionary:
		for id in saved_inventory:
			if Items.exists(str(id)):
				inventory[str(id)] = clampi(int(saved_inventory[id]), 0, Items.max_count(str(id)))
	equipped = {}
	var saved_equipped = data.get("equipped", {})
	if saved_equipped is Dictionary:
		for kind in saved_equipped:
			equip(str(saved_equipped[kind]))
	# Saves from before equipment: wear the best of each kind owned.
	for kind: String in Items.EQUIPMENT_KINDS:
		if equipped_item(kind) == "":
			for id: String in inventory:
				if Items.kind(id) == kind and Items.tier(id) > Items.tier(equipped_item(kind)):
					equipped[kind] = id
	item_slots = ["", ""]
	var saved_slots = data.get("item_slots", [])
	if saved_slots is Array:
		for i in mini(saved_slots.size(), 2):
			assign_slot(i, str(saved_slots[i]))
	jars = []
	var saved_jars = data.get("jars", [])
	if saved_jars is Array:
		for contents in saved_jars:
			if str(contents) in Items.JAR_ICONS:
				jars.append(str(contents))
	var saved_stones = data.get("tidestones", {})
	tidestones = saved_stones if saved_stones is Dictionary else {}
	play_time = maxf(float(data.get("play_time", 0.0)), 0.0)


static func _to_vec2i(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


static func _to_vec2(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return NO_POSITION
