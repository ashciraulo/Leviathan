class_name Ambience
extends Node2D
## Life on the overworld that is never in the way: gulls wheeling overhead
## with their shadows sliding over the ground, fish gliding under the water
## (now and then one jumps), shore crabs that scuttle off when Wren comes
## near, butterflies in Brinewood, fireflies over the Gloamfen, embers
## drifting up off Cinderreach's lava, and buzzards' shadows circling the
## Ossuary. It has no collisions and does no harm: it only draws. A room
## outside the dungeons adds one (see Room).

const GULL := preload("res://assets/ambient/gull.png")
const CRAB := preload("res://assets/ambient/crab.png")
const BUTTERFLY := preload("res://assets/ambient/butterfly.png")
const FISH := preload("res://assets/ambient/fish.png")
const SPLASH := preload("res://assets/ambient/splash.png")

## How much of each kind of life a biome has.
const LIFE := {
	"saltmarrow": {"gulls": 3, "fish": 3, "crabs": 4},
	"brinewood": {"gulls": 1, "fish": 3, "butterflies": 5},
	"cinderreach": {"embers": 14},
	"gloamfen": {"fish": 2, "fireflies": 12},
	"windmere": {"gulls": 4, "butterflies": 2},
	"frostspine": {"gulls": 2, "fish": 2},
	"sunken_verge": {"gulls": 3, "fish": 2, "crabs": 3},
	"ossuary": {"buzzards": 2},
}
## Gulls fly this high: their shadow falls this far below them.
const GULL_HEIGHT := 26.0
## Crabs bolt when Wren comes this close (px), and settle this far away.
const CRAB_SHY := 40.0
const CRAB_CALM := 72.0
const CRAB_SPEED := 70.0
const FISH_SPEED := 14.0

var _room: Room
var _rnd := RandomNumberGenerator.new()
var _time := 0.0
var _low: Node2D
var _high: Node2D
## Each creature is a small dictionary: where it is, where it's heading,
## and its own clock.
var gulls: Array[Dictionary] = []
var fish: Array[Dictionary] = []
var crabs: Array[Dictionary] = []
var butterflies: Array[Dictionary] = []
var fireflies: Array[Dictionary] = []
var embers: Array[Dictionary] = []
var buzzards: Array[Dictionary] = []
var splashes: Array[Dictionary] = []
var _water: Array[Vector2i] = []
var _sand: Array[Vector2i] = []
var _floor: Array[Vector2i] = []


func _ready() -> void:
	_room = get_parent() as Room
	_rnd.seed = hash(_room.coord) if _room else 1
	_low = Node2D.new()
	_low.name = "Below"
	_low.z_index = -8
	_low.draw.connect(_draw_low)
	add_child(_low)
	_high = Node2D.new()
	_high.name = "Above"
	_high.z_index = 30
	_high.draw.connect(_draw_high)
	add_child(_high)
	_survey()
	var life: Dictionary = LIFE.get(_room.biome if _room else "", {})
	for i in int(life.get("gulls", 0)):
		gulls.append(_new_gull(true))
	for i in int(life.get("buzzards", 0)):
		buzzards.append(_new_buzzard())
	if _water.size() >= 6:
		for i in int(life.get("fish", 0)):
			fish.append(_new_fish())
	if not _sand.is_empty():
		for i in int(life.get("crabs", 0)):
			crabs.append(_new_crab())
	if not _floor.is_empty():
		for i in int(life.get("butterflies", 0)):
			butterflies.append(_new_flutter(0))
		for i in int(life.get("fireflies", 0)):
			fireflies.append(_new_flutter(1))
	if not _water.is_empty():
		for i in int(life.get("embers", 0)):
			embers.append(_new_ember(true))


## Sorts the room's tiles: open water, sand by the water (for crabs), and
## open floor.
func _survey() -> void:
	if _room == null:
		return
	for y in Room.ROWS:
		for x in Room.COLS:
			var t := _room.tile_at(x, y)
			if t == "~":
				_water.append(Vector2i(x, y))
			elif t == ".":
				_floor.append(Vector2i(x, y))
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if _room.tile_at(x + d.x, y + d.y) == "~":
						_sand.append(Vector2i(x, y))
						break
	# Saltmarrow's whole beach is sand, water or not.
	if _sand.is_empty() and _room.biome in ["saltmarrow", "sunken_verge"]:
		_sand = _floor.duplicate()


static func _centre(tile: Vector2i) -> Vector2:
	return Vector2(tile * Room.TILE) + Vector2(Room.TILE, Room.TILE) / 2.0


func _pick(tiles: Array[Vector2i]) -> Vector2:
	var tile := tiles[_rnd.randi_range(0, tiles.size() - 1)]
	return _centre(tile) + Vector2(_rnd.randf_range(-4, 4), _rnd.randf_range(-4, 4))


# --------------------------------------------------------------------------
# Creatures
# --------------------------------------------------------------------------

## A gull crossing the screen. The first ones start somewhere over it.
func _new_gull(anywhere: bool) -> Dictionary:
	var right := _rnd.randf() < 0.5
	var y := _rnd.randf_range(20.0, Room.SIZE.y - 40.0)
	var x := _rnd.randf_range(20.0, Room.SIZE.x - 20.0) if anywhere else (-20.0 if right else Room.SIZE.x + 20.0)
	return {"pos": Vector2(x, y), "vel": Vector2(_rnd.randf_range(26.0, 40.0) * (1.0 if right else -1.0), _rnd.randf_range(-4.0, 4.0)),
		"clock": _rnd.randf() * 10.0, "wait": 0.0}


func _new_buzzard() -> Dictionary:
	return {"centre": Vector2(_rnd.randf_range(80.0, Room.SIZE.x - 80.0), _rnd.randf_range(60.0, Room.SIZE.y - 60.0)),
		"radius": _rnd.randf_range(40.0, 70.0), "angle": _rnd.randf() * TAU, "speed": _rnd.randf_range(0.25, 0.4)}


func _new_fish() -> Dictionary:
	var at := _pick(_water)
	var f := {"pos": at, "to": at, "clock": _rnd.randf() * 4.0, "jump": _rnd.randf_range(4.0, 12.0)}
	f["to"] = _fish_target(at)
	return f


## Somewhere a fish can swim to in a straight line without crossing land:
## a few tries at a random water spot, or stay put.
func _fish_target(from: Vector2) -> Vector2:
	for attempt in 8:
		var to := _pick(_water)
		if _all_water(from, to):
			return to
	return from


func _all_water(from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1, int(from.distance_to(to) / 4.0))
	for i in steps + 1:
		var tile := Vector2i((from.lerp(to, float(i) / steps) / Room.TILE).floor())
		if _room.tile_at(tile.x, tile.y) != "~":
			return false
	return true


func _new_crab() -> Dictionary:
	var at := _pick(_sand)
	return {"pos": at, "home": at, "clock": _rnd.randf() * 3.0, "fleeing": false, "dir": Vector2.ZERO}


## A butterfly (kind 0) or a firefly (kind 1): wanders near a spot of floor.
func _new_flutter(kind: int) -> Dictionary:
	var at := _pick(_floor)
	return {"pos": at, "home": at, "clock": _rnd.randf() * 10.0, "colour": _rnd.randi_range(0, 2), "kind": kind}


func _new_ember(anywhere: bool) -> Dictionary:
	var at := _pick(_water)
	return {"pos": at, "age": _rnd.randf() * 2.5 if anywhere else 0.0, "life": _rnd.randf_range(1.8, 3.0), "drift": _rnd.randf_range(-6.0, 6.0)}


# --------------------------------------------------------------------------
# Moving
# --------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	var wren := _wren_local()
	for g in gulls:
		_move_gull(g, delta)
	for b in buzzards:
		b["angle"] = fmod(float(b["angle"]) + float(b["speed"]) * delta, TAU)
	for f in fish:
		_move_fish(f, delta)
	for c in crabs:
		_move_crab(c, delta, wren)
	for b in butterflies + fireflies:
		_move_flutter(b, delta)
	for i in embers.size():
		var e := embers[i]
		e["age"] = float(e["age"]) + delta
		e["pos"] = (e["pos"] as Vector2) + Vector2(float(e["drift"]), -14.0) * delta
		if float(e["age"]) > float(e["life"]):
			embers[i] = _new_ember(false)
	for s in splashes:
		s["age"] = float(s["age"]) + delta
	splashes.assign(splashes.filter(func(s: Dictionary) -> bool: return float(s["age"]) < 0.6))
	_low.queue_redraw()
	_high.queue_redraw()


func _wren_local() -> Vector2:
	var wren := get_tree().get_first_node_in_group("player") as Node2D
	if wren == null or _room == null:
		return Vector2.INF
	return wren.global_position - _room.global_position


func _move_gull(g: Dictionary, delta: float) -> void:
	g["clock"] = float(g["clock"]) + delta
	if float(g["wait"]) > 0.0:
		g["wait"] = float(g["wait"]) - delta
		return
	var vel: Vector2 = g["vel"]
	# A lazy drift up and down as it rides the air.
	vel.y = sin(float(g["clock"]) * 0.7) * 6.0
	g["pos"] = (g["pos"] as Vector2) + vel * delta
	var pos: Vector2 = g["pos"]
	if pos.x < -40.0 or pos.x > Room.SIZE.x + 40.0:
		var fresh := _new_gull(false)
		fresh["wait"] = _rnd.randf_range(1.0, 6.0)
		g.merge(fresh, true)


func _move_fish(f: Dictionary, delta: float) -> void:
	f["clock"] = float(f["clock"]) + delta
	var pos: Vector2 = f["pos"]
	var to: Vector2 = f["to"]
	if pos.distance_to(to) < 2.0:
		f["to"] = _fish_target(pos)
	else:
		f["pos"] = pos.move_toward(to, FISH_SPEED * delta)
	f["jump"] = float(f["jump"]) - delta
	if float(f["jump"]) <= 0.0:
		f["jump"] = _rnd.randf_range(6.0, 14.0)
		splashes.append({"pos": f["pos"], "age": 0.0})
		if _room and _is_on_screen():
			Audio.play_sfx("fish_jump", _room.global_position + (f["pos"] as Vector2))


func _is_on_screen() -> bool:
	var wren := _wren_local()
	return wren != Vector2.INF and Rect2(Vector2.ZERO, Room.SIZE).has_point(wren)


func _move_crab(c: Dictionary, delta: float, wren: Vector2) -> void:
	c["clock"] = float(c["clock"]) + delta
	var pos: Vector2 = c["pos"]
	var away := wren.distance_to(pos) if wren != Vector2.INF else INF
	if away < CRAB_SHY:
		c["fleeing"] = true
		c["dir"] = (pos - wren).normalized()
	elif away > CRAB_CALM:
		c["fleeing"] = false
	var step := Vector2.ZERO
	if bool(c["fleeing"]):
		step = (c["dir"] as Vector2) * CRAB_SPEED * delta
	else:
		# Pottering: a few sideways steps, then a pause.
		var phase := fmod(float(c["clock"]), 3.0)
		if phase < 0.6:
			step = Vector2(1.0 if int(float(c["clock"]) / 3.0) % 2 == 0 else -1.0, 0.0) * 18.0 * delta
	var next := pos + step
	if _crab_can_stand(next):
		c["pos"] = next
	elif bool(c["fleeing"]):
		# Cornered against water or a wall: try running along it instead.
		var side := Vector2(-(c["dir"] as Vector2).y, (c["dir"] as Vector2).x)
		if _crab_can_stand(pos + side * CRAB_SPEED * delta):
			c["pos"] = pos + side * CRAB_SPEED * delta


func _crab_can_stand(at: Vector2) -> bool:
	if _room == null:
		return false
	var tile := Vector2i(floori(at.x / Room.TILE), floori(at.y / Room.TILE))
	return _room.tile_at(tile.x, tile.y) == "."


func _move_flutter(b: Dictionary, delta: float) -> void:
	b["clock"] = float(b["clock"]) + delta
	var t := float(b["clock"])
	var home: Vector2 = b["home"]
	var reach := 20.0 if int(b["kind"]) == 0 else 26.0
	b["pos"] = home + Vector2(sin(t * 0.9) + sin(t * 2.3) * 0.4, cos(t * 0.7) * 0.8 + sin(t * 1.9) * 0.3) * reach


# --------------------------------------------------------------------------
# Drawing
# --------------------------------------------------------------------------

## Under everything that stands: fish, crabs, the splashes and the shadows
## of things in the air.
func _draw_low() -> void:
	for f in fish:
		var frame := int(float(f["clock"]) * 3.0) % 2
		var pos: Vector2 = f["pos"]
		var to: Vector2 = f["to"]
		var flip := to.x < pos.x
		_blit(_low, FISH, Vector2i(12, 5), Vector2i(frame, 0), pos, flip, Color.WHITE)
	for s in splashes:
		var frame := mini(int(float(s["age"]) / 0.2), 2)
		_blit(_low, SPLASH, Vector2i(12, 8), Vector2i(frame, 0), (s["pos"] as Vector2) + Vector2(0, -2), false, Color.WHITE)
	for g in gulls:
		_shadow(_low, (g["pos"] as Vector2) + Vector2(0, GULL_HEIGHT), Vector2(7, 2.5), 0.22)
	for b in buzzards:
		var at := _buzzard_at(b)
		var heading := Vector2.from_angle(float(b["angle"]) + PI / 2.0)
		_low.draw_set_transform(at, heading.angle(), Vector2(2.2, 2.2))
		_low.draw_texture_rect_region(GULL, Rect2(Vector2(-8, -6), Vector2(16, 12)), Rect2(Vector2(16, 0), Vector2(16, 12)), Color(0.1, 0.06, 0.04, 0.22))
		_low.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for c in crabs:
		var moving := bool(c["fleeing"]) or fmod(float(c["clock"]), 3.0) < 0.6
		var frame := int(float(c["clock"]) * (12.0 if moving else 0.0)) % 2
		_shadow(_low, (c["pos"] as Vector2) + Vector2(0, 3), Vector2(4, 1.5), 0.25)
		_blit(_low, CRAB, Vector2i(10, 7), Vector2i(frame, 0), c["pos"], false, Color.WHITE)
	for b in butterflies:
		_shadow(_low, (b["pos"] as Vector2) + Vector2(0, 12), Vector2(2, 1), 0.18)


## Over everything: gulls, butterflies, fireflies and embers.
func _draw_high() -> void:
	for g in gulls:
		if float(g["wait"]) > 0.0:
			continue
		var clock := float(g["clock"])
		# Glide, with a few flaps every so often.
		var flapping := fmod(clock, 5.0) < 1.2
		var frame := 1
		if flapping:
			frame = [0, 1, 2, 1][int(clock * 8.0) % 4]
		var flip := (g["vel"] as Vector2).x < 0.0
		_blit(_high, GULL, Vector2i(16, 12), Vector2i(frame, 0), g["pos"], flip, Color.WHITE)
	for b in butterflies:
		var frame := int(float(b["clock"]) * 9.0) % 2
		_blit(_high, BUTTERFLY, Vector2i(7, 6), Vector2i(frame, int(b["colour"])), b["pos"], false, Color.WHITE)
	for f in fireflies:
		var glow := 0.5 + 0.5 * sin(float(f["clock"]) * 2.4 + float(f["colour"]))
		var pos: Vector2 = f["pos"]
		_high.draw_circle(pos, 5.0, Color(0.85, 1.0, 0.55, 0.10 * glow))
		_high.draw_circle(pos, 2.5, Color(0.9, 1.0, 0.6, 0.25 * glow))
		_high.draw_rect(Rect2(pos.floor() - Vector2.ONE, Vector2(2, 2)), Color(0.97, 1.0, 0.75, 0.4 + 0.6 * glow))
	for e in embers:
		var left := 1.0 - float(e["age"]) / float(e["life"])
		var pos: Vector2 = e["pos"]
		var colour := Color(1.0, 0.55 + 0.35 * left, 0.2, clampf(left * 1.4, 0.0, 1.0))
		var size := Vector2(2, 2) if left > 0.5 else Vector2.ONE
		_high.draw_rect(Rect2(pos.floor(), size), colour)


func _buzzard_at(b: Dictionary) -> Vector2:
	return (b["centre"] as Vector2) + Vector2.from_angle(float(b["angle"])) * float(b["radius"])


func _blit(canvas: Node2D, texture: Texture2D, size: Vector2i, cell: Vector2i, at: Vector2, flip: bool, tint: Color) -> void:
	var src := Rect2(Vector2(cell * size), Vector2(size))
	var dst := Rect2((at - Vector2(size) / 2.0).round(), Vector2(size))
	if flip:
		dst = Rect2(dst.position + Vector2(size.x, 0), Vector2(-size.x, size.y))
	canvas.draw_texture_rect_region(texture, dst, src, tint)


func _shadow(canvas: Node2D, at: Vector2, radii: Vector2, alpha: float) -> void:
	canvas.draw_set_transform(at.round(), 0.0, Vector2(1.0, radii.y / radii.x))
	canvas.draw_circle(Vector2.ZERO, radii.x, Color(0.08, 0.06, 0.1, alpha))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
