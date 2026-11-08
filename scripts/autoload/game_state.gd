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
var flags: Dictionary = {}


func reset_new_game() -> void:
	max_bubbles = START_BUBBLES
	bubbles = START_BUBBLES
	resonance = 0.0
	resonance_max = START_RESONANCE_MAX
	checkpoint_room = Vector2i.ZERO
	checkpoint_pos = NO_POSITION
	room_coord = Vector2i.ZERO
	flags = {}


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


static func _to_vec2i(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


static func _to_vec2(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return NO_POSITION
