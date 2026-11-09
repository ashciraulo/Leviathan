class_name SinkField
extends Node2D
## Sinking sand in the Ossuary Dunes (layout letter S). Each patch turns
## slowly round its middle (the tell: the swirl, and a dry hiss as Wren
## steps on). On it Wren is dragged toward the middle; walking hard away
## gets them out. If the middle takes them they're swallowed: they lose a
## breath and come back up where they last stood on firm ground. The room
## adds one of these when its layout has any.

## How hard the sand drags Wren to a patch's middle (px/s; Wren walks 90).
const PULL := 50.0
## How close to the middle (px) swallows them.
const SWALLOW := 6.0
## How often (seconds) firm footing is remembered.
const SAFE_EVERY := 0.15

var _room: Room
## Tile -> the middle (room-local) of the patch it belongs to.
var _middle := {}
var _safe := Vector2.INF
var _safe_timer := 0.0
var _was_on := false
var _frame := 0


func _ready() -> void:
	_room = get_parent() as Room
	z_index = -9
	# Run after Wren moves.
	process_physics_priority = 10
	var seen := {}
	for y in Room.ROWS:
		for x in Room.COLS:
			var start := Vector2i(x, y)
			if seen.has(start) or _room.tile_at(x, y) != "S":
				continue
			var patch: Array[Vector2i] = []
			var queue: Array[Vector2i] = [start]
			seen[start] = true
			while not queue.is_empty():
				var at: Vector2i = queue.pop_front()
				patch.append(at)
				for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next := at + step
					if not seen.has(next) and _room.tile_at(next.x, next.y) == "S":
						seen[next] = true
						queue.append(next)
			var sum := Vector2.ZERO
			for tile in patch:
				sum += Vector2(tile) + Vector2(0.5, 0.5)
			# The middle of the patch tile nearest its centre, so an odd-shaped
			# patch still pulls Wren onto sand.
			var centre := sum / patch.size()
			var best := patch[0]
			for tile in patch:
				if (Vector2(tile) + Vector2(0.5, 0.5)).distance_to(centre) < (Vector2(best) + Vector2(0.5, 0.5)).distance_to(centre):
					best = tile
			var middle := (Vector2(best) + Vector2(0.5, 0.5)) * Room.TILE
			for tile in patch:
				_middle[tile] = middle


func is_sand(local: Vector2) -> bool:
	return _middle.has(Vector2i(floori(local.x / Room.TILE), floori(local.y / Room.TILE)))


## The middle of the patch under this point (room-local), or INF.
func middle_at(local: Vector2) -> Vector2:
	return _middle.get(Vector2i(floori(local.x / Room.TILE), floori(local.y / Room.TILE)), Vector2.INF)


func _physics_process(delta: float) -> void:
	var frame := int(Time.get_ticks_msec() / 400) % 2
	if frame != _frame:
		_frame = frame
		queue_redraw()
	var wren := get_tree().get_first_node_in_group("player") as Player
	if wren == null:
		return
	var local := wren.global_position - _room.global_position
	if not Rect2(Vector2.ZERO, Room.SIZE).has_point(local):
		_was_on = false
		return
	var middle := middle_at(local)
	var free := not wren.frozen and not wren.in_cutscene and not wren.airborne \
		and not wren.state in [Player.State.DEAD, Player.State.FALL]
	if middle == Vector2.INF:
		_was_on = false
		_safe_timer -= delta
		if _safe_timer <= 0.0 and free:
			_safe_timer = SAFE_EVERY
			_safe = wren.global_position
		return
	if not free:
		return
	if not _was_on:
		Audio.play_sfx("sand_hiss", wren.global_position)
		_was_on = true
	var to := middle - local
	if to.length() <= SWALLOW:
		var back := _safe if _safe != Vector2.INF else _room.global_position + _firm_near(local)
		wren.fall(back)
		return
	wren.move_and_collide(to.normalized() * minf(PULL * delta, to.length()))


## The nearest firm, open ground to a point (room-local), for when Wren
## hasn't stood anywhere firm in this room yet.
func _firm_near(local: Vector2) -> Vector2:
	var start := Vector2i(floori(local.x / Room.TILE), floori(local.y / Room.TILE))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		var tile := _room.tile_at(at.x, at.y)
		if not _middle.has(at) and not Room.is_solid(tile) and not Prop.is_prop(tile):
			return Vector2(at * Room.TILE) + Vector2(Room.TILE / 2.0, Room.TILE - 4.0)
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := at + step
			if Rect2i(0, 0, Room.COLS, Room.ROWS).has_point(next) and not seen.has(next) and not Room.is_solid(_room.tile_at(next.x, next.y)):
				seen[next] = true
				queue.append(next)
	return local


func _draw() -> void:
	for tile: Vector2i in _middle:
		var rect := Rect2(Vector2(tile * Room.TILE), Vector2(Room.TILE, Room.TILE))
		draw_texture_rect_region(Art.WORLD_TILES, rect, TileAtlas.region("sinksand_%d" % ((_frame + tile.x + tile.y) % 2)))
