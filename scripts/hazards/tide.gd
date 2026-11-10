class_name Tide
extends Node2D
## The Sunken Verge's tide (tide flats are layout letter r). It ebbs and
## floods on one clock for the whole region: the Leviathan breathing, far
## below. At low tide the flats are sand and Wren can cross them. As it
## turns, the water creeps in from the open sea tile by tile (the tell,
## with a rushing wash), and a flat that has gone under is water: it blocks
## walking, and Wren, if they're still out on it, is swept back to the
## nearest dry ground and loses a breath. The room adds one of these when
## its layout has any flats.
##
## Once the Old One has turned over (the Gale Bell, flag old_one_turned),
## Wren can turn the tide at any awake Tidestone: it runs in or out and
## stays there (flag tide_held, with tide_held_in set when it's held in)
## instead of breathing on its own.

enum Phase { LOW, RISING, HIGH, FALLING }

const LOW_TIME := 8.0
const RISING_TIME := 3.0
const HIGH_TIME := 5.0
const FALLING_TIME := 3.0
const CYCLE := LOW_TIME + RISING_TIME + HIGH_TIME + FALLING_TIME

## Added to the clock (tests set it to pick a moment in the cycle).
static var offset := 0.0
## Seconds of unpaused play the tide has run (advanced once per physics
## frame by whichever Tide is processing, so a pause holds it still).
static var elapsed := 0.0
static var _stamp := -1
## While the tide is held: where it stands now (it runs to the held level at
## the usual flooding and ebbing pace), or -1 when it's already there.
static var _held_level := -1.0

const HELD_FLAG := "tide_held"
const HELD_IN_FLAG := "tide_held_in"
const TURNED_FLAG := "old_one_turned"

var _room: Room
var _body: StaticBody2D
## Tile -> its collision shape, and how far it lies from the open sea (in
## steps, so the nearest flats flood first and drain last).
var _shapes := {}
var _distance := {}
var _deepest := 1
var _flooded := {}
var _level := -1.0
var _phase := Phase.LOW
var _frame := 0


## Seconds into the region's tide cycle.
static func clock() -> float:
	return fposmod(elapsed + offset, CYCLE)


## Where the tide is: 0 fully out, 1 fully in.
static func level() -> float:
	var held_to := held()
	if held_to != "":
		var target := 1.0 if held_to == "high" else 0.0
		return target if _held_level < 0.0 else _held_level
	return _cycle_level()


static func _cycle_level() -> float:
	var t := clock()
	if t < LOW_TIME:
		return 0.0
	t -= LOW_TIME
	if t < RISING_TIME:
		return t / RISING_TIME
	t -= RISING_TIME
	if t < HIGH_TIME:
		return 1.0
	t -= HIGH_TIME
	return 1.0 - t / FALLING_TIME


static func phase() -> Phase:
	var held_to := held()
	if held_to != "":
		if _held_level >= 0.0:
			return Phase.RISING if held_to == "high" else Phase.FALLING
		return Phase.HIGH if held_to == "high" else Phase.LOW
	var t := clock()
	if t < LOW_TIME:
		return Phase.LOW
	if t < LOW_TIME + RISING_TIME:
		return Phase.RISING
	if t < LOW_TIME + RISING_TIME + HIGH_TIME:
		return Phase.HIGH
	return Phase.FALLING


## "low" or "high" while Wren holds the tide, "" while it breathes alone.
static func held() -> String:
	if not GameState.has_flag(HELD_FLAG):
		return ""
	return "high" if GameState.has_flag(HELD_IN_FLAG) else "low"


## Can Wren turn the tide yet (at a Tidestone)?
static func can_turn() -> bool:
	return GameState.has_flag(TURNED_FLAG)


## Turns the tide: out if it's mostly in, in if it's mostly out. It runs
## there at the usual pace and holds (at once, where no flats are in
## sight to watch it go). Returns where it's going.
static func turn(tree: SceneTree) -> String:
	var from := level()
	var to := "low" if from >= 0.5 else "high"
	GameState.set_flag(HELD_IN_FLAG, to == "high")
	GameState.set_flag(HELD_FLAG)
	var watching := false
	for node in tree.get_nodes_in_group("rooms"):
		if (node as Node).get_node_or_null("Tide") != null:
			watching = true
	_held_level = from if watching else -1.0
	return to


## Moves a turning tide toward where it's held (once per physics frame).
static func _advance_held(delta: float) -> void:
	if _held_level < 0.0 or held() == "":
		_held_level = -1.0
		return
	var target := 1.0 if held() == "high" else 0.0
	var pace := 1.0 / (RISING_TIME if target > _held_level else FALLING_TIME)
	_held_level = move_toward(_held_level, target, pace * delta)
	if is_equal_approx(_held_level, target):
		_held_level = -1.0


## The clock offset that puts the tide at `when` seconds into `p`.
static func offset_for(p: Phase, when: float = 0.5) -> float:
	var start: float = [0.0, LOW_TIME, LOW_TIME + RISING_TIME, LOW_TIME + RISING_TIME + HIGH_TIME][p]
	return fposmod(start + when - elapsed, CYCLE)


func _ready() -> void:
	_room = get_parent() as Room
	z_index = -9
	# After Wren moves, so a sweep isn't undone by this frame's step.
	process_physics_priority = 10
	_body = StaticBody2D.new()
	_body.name = "Flood"
	Layers.assign(_body, Layers.WATER, [])
	add_child(_body)
	var queue: Array[Vector2i] = []
	for y in Room.ROWS:
		for x in Room.COLS:
			if not is_flat(_room.tile_at(x, y)):
				continue
			var tile := Vector2i(x, y)
			var shape := Layers.rect_shape(Vector2(Room.TILE, Room.TILE), Vector2(tile * Room.TILE) + Vector2(Room.TILE, Room.TILE) / 2.0)
			shape.disabled = true
			_body.add_child(shape)
			_shapes[tile] = shape
			_flooded[tile] = false
			# The open sea floods first, and so do flats running off the
			# screen's edge, so both sides of a room seam flood together.
			var edge := x == 0 or y == 0 or x == Room.COLS - 1 or y == Room.ROWS - 1
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if (edge or _room.tile_at(x + step.x, y + step.y) == "~") and not _distance.has(tile):
					_distance[tile] = 0
					queue.append(tile)
	# Flats with no sea beside them all flood at once.
	if queue.is_empty():
		for tile: Vector2i in _shapes:
			_distance[tile] = 0
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := at + step
			if _shapes.has(next) and not _distance.has(next):
				_distance[next] = _distance[at] + 1
				_deepest = maxi(_deepest, _distance[next] + 1)
				queue.append(next)
	for tile: Vector2i in _shapes:
		if not _distance.has(tile):
			_distance[tile] = _deepest - 1
	# Start as the tide is now, so a room entered at high tide (and its
	# Siltrays) begin flooded.
	_level = level()
	_phase = phase()
	for tile: Vector2i in _shapes:
		_flooded[tile] = cover(tile) >= 1.0
		(_shapes[tile] as CollisionShape2D).disabled = not _flooded[tile]
	queue_redraw()


## Tide flats: r, and the d a Siltray lies on.
static func is_flat(tile: String) -> bool:
	return tile == "r" or tile == "d"


## Is this flat under water right now?
func is_flooded(tile: Vector2i) -> bool:
	return _flooded.get(tile, false)


## Can a swimmer be here (open sea, or a flooded flat)?
func is_swimmable(tile: Vector2i) -> bool:
	return _room.tile_at(tile.x, tile.y) == "~" or is_flooded(tile)


## How covered this flat is, 0..1 (for drawing).
func cover(tile: Vector2i) -> float:
	return clampf(_level * _deepest - _distance.get(tile, 0), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() != _stamp:
		_stamp = Engine.get_physics_frames()
		elapsed += delta
		_advance_held(delta)
	var now := level()
	var now_phase := phase()
	if now_phase != _phase:
		if now_phase == Phase.RISING and _wren_here():
			Audio.play_sfx("tide_rise", global_position + Room.SIZE / 2.0)
		_phase = now_phase
	var frame := int(Time.get_ticks_msec() / 600) % 2
	if is_equal_approx(now, _level) and frame == _frame:
		return
	_level = now
	_frame = frame
	for tile: Vector2i in _shapes:
		var under := cover(tile) >= 1.0
		if under != _flooded[tile]:
			_flooded[tile] = under
			(_shapes[tile] as CollisionShape2D).set_deferred("disabled", not under)
	_sweep()
	queue_redraw()


func _exit_tree() -> void:
	# Leaving the flats mid-turn: the tide finishes running in or out while
	# Wren is away.
	_held_level = -1.0


func _wren_here() -> bool:
	var wren := get_tree().get_first_node_in_group("player") as Player
	return wren != null and Rect2(Vector2.ZERO, Room.SIZE).has_point(wren.global_position - _room.global_position)


## Wren caught out on a flat as it goes under is swept to dry ground.
func _sweep() -> void:
	var wren := get_tree().get_first_node_in_group("player") as Player
	if wren == null or wren.frozen or wren.in_cutscene or wren.airborne or wren.state in [Player.State.DEAD, Player.State.FALL]:
		return
	var local := wren.global_position - _room.global_position
	if not Rect2(Vector2.ZERO, Room.SIZE).has_point(local):
		return
	var at := Vector2i(floori(local.x / Room.TILE), floori(local.y / Room.TILE))
	if not is_flooded(at):
		return
	var dry := _nearest_dry(at)
	var from := wren.global_position
	wren.global_position = _room.global_position + Vector2(dry * Room.TILE) + Vector2(Room.TILE / 2.0, Room.TILE - 4.0)
	Audio.play_sfx("tide_sweep", wren.global_position)
	wren.take_damage(1, from)


## Somewhere Wren can be put down: firm, open ground, clear of props'
## footprints, stones and doorways. Not a piece of sea-glass's tile either:
## out on the flats that's a one-tile islet.
func _is_dry_spot(at: Vector2i) -> bool:
	var tile := _room.tile_at(at.x, at.y)
	if is_flat(tile) or Room.is_solid(tile) or tile in ["T", "D", "C", "*"] or Prop.is_prop(tile):
		return false
	for dx in [-1, 1]:
		var side := _room.tile_at(at.x + dx, at.y)
		if Prop.is_prop(side) and (Prop.KINDS[side][2] as Vector2).x > Room.TILE:
			return false
	return Rect2i(0, 0, Room.COLS, Room.ROWS).has_point(at)


func _nearest_dry(start: Vector2i) -> Vector2i:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		var tile := _room.tile_at(at.x, at.y)
		if _is_dry_spot(at):
			return at
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := at + step
			if next.x < 0 or next.y < 0 or next.x >= Room.COLS or next.y >= Room.ROWS or seen.has(next):
				continue
			if Room.is_solid(_room.tile_at(next.x, next.y)):
				continue
			seen[next] = true
			queue.append(next)
	return start


func _draw() -> void:
	if _level <= 0.0:
		return
	for tile: Vector2i in _shapes:
		var c := cover(tile)
		if c <= 0.0:
			continue
		var rect := Rect2(Vector2(tile * Room.TILE), Vector2(Room.TILE, Room.TILE))
		draw_texture_rect_region(Art.WORLD_TILES, rect, TileAtlas.region("tidewater_%d" % _frame), Color(1, 1, 1, c * 0.9))
		# A line of foam along the advancing edge.
		if c < 1.0:
			draw_rect(Rect2(rect.position + Vector2(0, Room.TILE * (1.0 - c)), Vector2(Room.TILE, 1)), Color(0.91, 0.95, 0.95, 0.7 * c))
