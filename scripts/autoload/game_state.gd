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
## Items Wren carries: id -> count. Tools count 1.
var inventory: Dictionary = {}
## The two equipped items (item_1, item_2): item ids, "" for an empty slot.
var item_slots: Array = ["", ""]

## Items that go in a slot when found.
const TOOLS := ["tide_hook", "stonebreaker", "glowmoth_lantern", "kite_cloak",
		"frostfang_bow", "divers_helm", "echo_horn", "wayshell"]


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
	item_slots = ["", ""]


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


func give_item(id: String, count := 1) -> void:
	inventory[id] = item_count(id) + count
	if id in TOOLS and not id in item_slots:
		var empty := item_slots.find("")
		if empty != -1:
			item_slots[empty] = id


func has_item(id: String) -> bool:
	return item_count(id) > 0


func item_count(id: String) -> int:
	return int(inventory.get(id, 0))


func take_item(id: String, count := 1) -> bool:
	if item_count(id) < count:
		return false
	inventory[id] = item_count(id) - count
	return true


## Map, compass and big key: one of each per dungeon, e.g. "hull_big_key".
func has_dungeon_item(dungeon_id: String, kind: String) -> bool:
	return has_item("%s_%s" % [dungeon_id, kind])


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
		"inventory": inventory.duplicate(true),
		"item_slots": item_slots.duplicate(),
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
	var saved_items = data.get("inventory", {})
	inventory = saved_items if saved_items is Dictionary else {}
	var saved_slots = data.get("item_slots", ["", ""])
	item_slots = ["", ""]
	if saved_slots is Array:
		for i in mini(saved_slots.size(), 2):
			item_slots[i] = str(saved_slots[i])


static func _to_vec2i(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


static func _to_vec2(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return NO_POSITION
