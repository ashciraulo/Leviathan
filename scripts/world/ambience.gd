class_name Ambience
extends Node2D
## Life on the overworld that is never in the way: gulls wheeling overhead
## with their shadows sliding over the ground, fish gliding under the water
## (now and then one jumps), shore crabs that scuttle off when Wren comes
## near, butterflies in Brinewood, fireflies and mist over the Gloamfen,
## wind streaks over the heights and sand blowing over the dunes, ash and
## embers
## drifting up off Cinderreach's lava, and buzzards' shadows circling the
## Ossuary, the shadows of clouds sliding over the open country, sunlight
## glinting on the water and leaves falling in Brinewood. It
## has no collisions and does no harm: it only draws. A room
## outside the dungeons adds one (see Room).

const GULL := preload("res://assets/ambient/gull.png")
const CRAB := preload("res://assets/ambient/crab.png")
const BUTTERFLY := preload("res://assets/ambient/butterfly.png")
const FISH := preload("res://assets/ambient/fish.png")
const SPLASH := preload("res://assets/ambient/splash.png")
const HARE := preload("res://assets/ambient/hare.png")
const LIZARD := preload("res://assets/ambient/lizard.png")

## How much of each kind of life a biome has.
const LIFE := {
	"saltmarrow": {"gulls": 2, "fish": 2, "crabs": 2, "gusts": 2, "clouds": 2, "glints": 4},
	"brinewood": {"gulls": 1, "fish": 2, "butterflies": 3, "mist": 2, "reeds": 10, "leaves": 5},
	"cinderreach": {"embers": 12, "ash": 30, "lizards": 2},
	"gloamfen": {"fish": 2, "fireflies": 8, "mist": 3, "reeds": 10},
	"windmere": {"gulls": 2, "butterflies": 1, "gusts": 3, "hares": 2, "reeds": 12, "clouds": 2, "glints": 5},
	"frostspine": {"gulls": 1, "fish": 2, "gusts": 2, "snow": 50, "hares": 2, "clouds": 1, "glints": 3},
	"sunken_verge": {"gulls": 2, "fish": 2, "crabs": 2, "gusts": 2, "clouds": 2, "glints": 5},
	"ossuary": {"buzzards": 2, "gusts": 3, "lizards": 2, "clouds": 1, "glints": 3},
}
## Creatures (not weather) thin out on a screen that is already busy: each
## foe, villager or stall on it takes this share off, down to the floor
## (and one of each kind always stays).
const CREATURES := ["gulls", "buzzards", "fish", "crabs", "butterflies", "fireflies", "hares", "lizards"]
const CROWD_SHARE := 0.12
const CROWD_FLOOR := 0.35
## Layout letters that put something lively on the screen: foes, the stall,
## the quest crab (villagers are counted from Npc.LETTERS).
const LIVELY := "csmweqt0gAb7k"
## Wind streak colours: sea air is white, the dunes blow sand.
const GUST_COLOUR := {"ossuary": Color(0.7, 0.55, 0.36), "cinderreach": Color(0.75, 0.7, 0.68)}
## Gulls fly this high: their shadow falls this far below them.
const GULL_HEIGHT := 26.0
## Crabs bolt when Wren comes this close (px), and settle this far away.
const CRAB_SHY := 40.0
const CRAB_CALM := 72.0
const CRAB_SPEED := 70.0
const FISH_SPEED := 14.0
## Hares and lizards bolt when Wren comes this close, and settle again
## once Wren is this far off.
const RUNNER_SHY := {"hare": 52.0, "lizard": 36.0}
const RUNNER_CALM := {"hare": 110.0, "lizard": 70.0}
const RUNNER_SPEED := {"hare": 105.0, "lizard": 120.0}
## Reed and grass colours per region: blade, and the seed head (alpha 0 for none).
const REED_COLOURS := {
	"brinewood": [Color(0.24, 0.42, 0.22), Color(0, 0, 0, 0)],
	"gloamfen": [Color(0.36, 0.42, 0.2), Color(0.42, 0.26, 0.14)],
	"windmere": [Color(0.78, 0.72, 0.46), Color(0.9, 0.84, 0.6)],
}

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
## Hares (Frostspine, Windmere) and lizards (the Ossuary, Cinderreach):
## they sit, potter, and bolt from Wren.
var runners: Array[Dictionary] = []
## Reeds by the water and long grass on the heights, swaying in the wind.
var reeds: Array[Dictionary] = []
## Weather: low mist drifting through the woods and fens, and wind streaks
## racing over the heights.
var mist: Array[Dictionary] = []
## Flakes sifting down: grey ash over Cinderreach, snow over Frostspine.
var ash: Array[Dictionary] = []
var gusts: Array[Dictionary] = []
## Shadows of clouds sliding over the open regions with the wind.
var clouds: Array[Dictionary] = []
## Sunlight catching the water: a pixel that flares into a little star and
## goes out, here and there over open water.
var glints: Array[Dictionary] = []
const GLINT_TIME := 0.45
## Leaves let go by the Brinewood's trees, tumbling down on the breeze.
var leaves: Array[Dictionary] = []
const LEAF_COLOURS := [Color("#a8cf5c"), Color("#d8bf4e"), Color("#dc8f3c")]
## Cloud shadow shapes (three, one above the other): soft-edged lumps,
## flat inside so they darken the ground evenly.
const CLOUD := preload("res://assets/ambient/cloud.png")
const CLOUD_CELL := Vector2(190, 80)
const CLOUD_SPEED := Vector2(9.0, 1.5)
const CLOUD_SHADE := Color(0.1, 0.12, 0.22, 0.13)
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
	# Under a roof: nothing that needs the open sky (gulls, buzzards, wind,
	# clouds, sunlight on the water, falling leaves,
	# falling snow or ash).
	if _room and _room.cave:
		life = life.duplicate()
		for key in ["gulls", "buzzards", "gusts", "snow", "ash", "butterflies", "clouds", "glints", "leaves"]:
			life.erase(key)
	# Shore crabs keep off a screen with Scuttlers on it: side by side, the
	# harmless ones and the foes are too easily taken for each other.
	if _room and _room.layout.contains("c") and life.has("crabs"):
		life = life.duplicate()
		life.erase("crabs")
	var crowd := _crowd()
	if crowd < 1.0:
		life = life.duplicate()
		for key: String in CREATURES:
			if life.has(key):
				# One of each kind stays, so the screen still has its life.
				life[key] = maxi(1, roundi(int(life[key]) * crowd))
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
	if not _floor.is_empty():
		for kind in ["hare", "lizard"]:
			for i in int(life.get(kind + "s", 0)):
				runners.append(_new_runner(kind))
	# Reeds stand at the water's edge; on the heights, long grass anywhere.
	var stems := _floor if _room and _room.biome == "windmere" else _sand
	if not stems.is_empty():
		for i in int(life.get("reeds", 0)):
			reeds.append({"pos": _pick(stems) + Vector2(_rnd.randf_range(-5.0, 5.0), _rnd.randf_range(2.0, 6.0)),
				"height": _rnd.randf_range(7.0, 12.0), "phase": _rnd.randf() * TAU, "blades": _rnd.randi_range(3, 4)})
	for i in int(life.get("mist", 0)):
		mist.append(_new_mist(true))
	for i in int(life.get("gusts", 0)):
		gusts.append(_new_gust(true))
	if _water.size() >= 6:
		for i in int(life.get("glints", 0)):
			glints.append(_new_glint(true))
	for i in int(life.get("leaves", 0)):
		leaves.append(_new_leaf(true))
	for i in int(life.get("clouds", 0)):
		clouds.append(_new_cloud(true))
	for i in int(life.get("ash", 0)):
		ash.append(_new_ash(true))
	# Snow falls the same way, only white.
	for i in int(life.get("snow", 0)):
		var flake := _new_ash(true)
		flake["shade"] = 1.0
		ash.append(flake)


## How much of the usual wildlife a screen keeps, by how much is already
## going on there (foes and villagers from the layout).
func _crowd() -> float:
	if _room == null:
		return 1.0
	var busy := 0
	for y in Room.ROWS:
		for x in Room.COLS:
			var t := _room.raw_tile(x, y)
			if LIVELY.contains(t) or Npc.LETTERS.has(t):
				busy += 1
	return clampf(1.0 - busy * CROWD_SHARE, CROWD_FLOOR, 1.0)


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


## A bank of mist, wider than it is tall, drifting slowly sideways.
func _new_mist(anywhere: bool) -> Dictionary:
	var w := _rnd.randf_range(70.0, 120.0)
	var x := _rnd.randf_range(0.0, Room.SIZE.x) if anywhere else -w
	return {"pos": Vector2(x, _rnd.randf_range(30.0, Room.SIZE.y - 30.0)), "size": Vector2(w, w * 0.32),
		"speed": _rnd.randf_range(4.0, 8.0), "clock": _rnd.randf() * TAU}


## A glint waits a while, then flares on a water tile away from its edges.
func _new_glint(anywhere: bool) -> Dictionary:
	return {"pos": _pick(_water).floor(), "age": 0.0, "wait": _rnd.randf_range(0.0, 3.0) if anywhere else _rnd.randf_range(0.8, 3.5)}


## A leaf drifting down from above the screen, swinging as it falls.
func _new_leaf(anywhere: bool) -> Dictionary:
	return {"pos": Vector2(_rnd.randf_range(-20.0, Room.SIZE.x), _rnd.randf_range(0.0, Room.SIZE.y) if anywhere else -6.0),
		"fall": _rnd.randf_range(9.0, 15.0), "clock": _rnd.randf() * TAU, "colour": _rnd.randi_range(0, LEAF_COLOURS.size() - 1)}


## A cloud's shadow, coming in from the windward side (or anywhere, at first).
func _new_cloud(anywhere: bool) -> Dictionary:
	var x := _rnd.randf_range(-CLOUD_CELL.x * 0.5, Room.SIZE.x) if anywhere else -CLOUD_CELL.x - _rnd.randf_range(0.0, 160.0)
	return {"pos": Vector2(x, _rnd.randf_range(-30.0, Room.SIZE.y - 30.0)), "shape": _rnd.randi_range(0, 2),
		"speed": _rnd.randf_range(0.8, 1.2)}


## A streak of wind: a thin pale line that races across and fades.
func _new_gust(anywhere: bool) -> Dictionary:
	return {"pos": Vector2(_rnd.randf_range(-60.0, Room.SIZE.x), _rnd.randf_range(16.0, Room.SIZE.y - 16.0)),
		"length": _rnd.randf_range(28.0, 56.0), "speed": _rnd.randf_range(110.0, 170.0),
		"age": _rnd.randf() * 1.5 if anywhere else 0.0, "life": _rnd.randf_range(1.0, 1.8),
		"wait": 0.0 if anywhere else _rnd.randf_range(0.5, 3.0)}


## A flake of ash, falling slowly and swaying as it goes.
func _new_ash(anywhere: bool) -> Dictionary:
	return {"pos": Vector2(_rnd.randf_range(0.0, Room.SIZE.x), _rnd.randf_range(0.0, Room.SIZE.y) if anywhere else -4.0),
		"fall": _rnd.randf_range(8.0, 16.0), "clock": _rnd.randf() * TAU, "shade": _rnd.randf_range(0.18, 0.32) if _rnd.randf() < 0.7 else _rnd.randf_range(0.8, 0.9)}


func _new_crab() -> Dictionary:
	var at := _pick(_sand)
	return {"pos": at, "home": at, "clock": _rnd.randf() * 3.0, "fleeing": false, "dir": Vector2.ZERO}


## A butterfly (kind 0) or a firefly (kind 1): wanders near a spot of floor.
func _new_runner(kind: String) -> Dictionary:
	var at := _pick(_floor)
	return {"kind": kind, "pos": at, "clock": _rnd.randf() * 4.0, "fleeing": false, "dir": Vector2.RIGHT if _rnd.randf() < 0.5 else Vector2.LEFT, "moving": false}


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
	for r in runners:
		_move_runner(r, delta, wren)
	for i in embers.size():
		var e := embers[i]
		e["age"] = float(e["age"]) + delta
		e["pos"] = (e["pos"] as Vector2) + Vector2(float(e["drift"]), -14.0) * delta
		if float(e["age"]) > float(e["life"]):
			embers[i] = _new_ember(false)
	for m in mist:
		m["clock"] = float(m["clock"]) + delta
		m["pos"] = (m["pos"] as Vector2) + Vector2(float(m["speed"]) * delta, 0.0)
		if (m["pos"] as Vector2).x - (m["size"] as Vector2).x > Room.SIZE.x:
			m.merge(_new_mist(false), true)
	for g in glints:
		if float(g["wait"]) > 0.0:
			g["wait"] = float(g["wait"]) - delta
		else:
			g["age"] = float(g["age"]) + delta
			if float(g["age"]) > GLINT_TIME:
				g.merge(_new_glint(false), true)
	for l in leaves:
		l["clock"] = float(l["clock"]) + delta
		l["pos"] = (l["pos"] as Vector2) + Vector2(5.0 + sin(float(l["clock"]) * 1.6) * 12.0, float(l["fall"])) * delta
		if (l["pos"] as Vector2).y > Room.SIZE.y + 4.0 or (l["pos"] as Vector2).x > Room.SIZE.x + 4.0:
			l.merge(_new_leaf(false), true)
	for c in clouds:
		c["pos"] = (c["pos"] as Vector2) + CLOUD_SPEED * float(c["speed"]) * delta
		if (c["pos"] as Vector2).x > Room.SIZE.x + 8.0:
			c.merge(_new_cloud(false), true)
	for a in ash:
		a["clock"] = float(a["clock"]) + delta
		a["pos"] = (a["pos"] as Vector2) + Vector2(sin(float(a["clock"]) * 1.3) * 6.0, float(a["fall"])) * delta
		if (a["pos"] as Vector2).y > Room.SIZE.y + 4.0:
			var shade := float(a["shade"])
			a.merge(_new_ash(false), true)
			if shade >= 1.0:
				a["shade"] = 1.0
	for g in gusts:
		if float(g["wait"]) > 0.0:
			g["wait"] = float(g["wait"]) - delta
			continue
		g["age"] = float(g["age"]) + delta
		g["pos"] = (g["pos"] as Vector2) + Vector2(float(g["speed"]) * delta, 0.0)
		if float(g["age"]) > float(g["life"]):
			g.merge(_new_gust(false), true)
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


func _move_runner(r: Dictionary, delta: float, wren: Vector2) -> void:
	r["clock"] = float(r["clock"]) + delta
	var kind: String = r["kind"]
	var pos: Vector2 = r["pos"]
	var away := wren.distance_to(pos) if wren != Vector2.INF else INF
	if away < float(RUNNER_SHY[kind]):
		r["fleeing"] = true
		r["dir"] = (pos - wren).normalized()
	elif away > float(RUNNER_CALM[kind]):
		r["fleeing"] = false
	var clock := float(r["clock"])
	var speed := 0.0
	if bool(r["fleeing"]):
		# Hares go in bounds; lizards in a flat-out dash.
		speed = float(RUNNER_SPEED[kind]) * (1.0 if kind == "lizard" or fmod(clock * 3.0, 1.0) < 0.65 else 0.3)
	else:
		# Pottering: a hop or a dart now and then, a new way each time.
		var cycle := 3.5 if kind == "hare" else 2.2
		var phase := fmod(clock, cycle)
		if phase < 0.3:
			speed = 30.0 if kind == "hare" else 55.0
		elif phase < 0.3 + delta:
			r["dir"] = Vector2.from_angle(_rnd.randf() * TAU)
	r["moving"] = speed > 0.0
	if speed <= 0.0:
		return
	var dir: Vector2 = r["dir"]
	var next := pos + dir * speed * delta
	if _crab_can_stand(next):
		r["pos"] = next
	else:
		# Up against water or a wall: run along it, else turn about.
		var side := Vector2(-dir.y, dir.x)
		if _crab_can_stand(pos + side * speed * delta):
			r["pos"] = pos + side * speed * delta
		elif _crab_can_stand(pos - side * speed * delta):
			r["pos"] = pos - side * speed * delta
		elif not bool(r["fleeing"]):
			r["dir"] = -dir


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

## Under everything that stands: fish, glints on the water, crabs, the splashes and the shadows
## of things in the air.
func _draw_low() -> void:
	for f in fish:
		var frame := int(float(f["clock"]) * 3.0) % 2
		var pos: Vector2 = f["pos"]
		var to: Vector2 = f["to"]
		var flip := to.x < pos.x
		_blit(_low, FISH, Vector2i(12, 5), Vector2i(frame, 0), pos, flip, Color.WHITE)
	for g in glints:
		if float(g["wait"]) > 0.0:
			continue
		# A pixel, then a little cross, then a pixel again.
		var t := float(g["age"]) / GLINT_TIME
		var at: Vector2 = g["pos"]
		var white := Color(1, 1, 1, 0.9)
		_low.draw_rect(Rect2(at, Vector2.ONE), white)
		if t > 0.25 and t < 0.75:
			var arm := 2.0 if t > 0.4 and t < 0.6 else 1.0
			var faint := Color(0.85, 0.95, 1.0, 0.6)
			_low.draw_rect(Rect2(at - Vector2(arm, 0), Vector2(arm, 1)), faint)
			_low.draw_rect(Rect2(at + Vector2(1, 0), Vector2(arm, 1)), faint)
			_low.draw_rect(Rect2(at - Vector2(0, arm), Vector2(1, arm)), faint)
			_low.draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, arm)), faint)
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
	for r in runners:
		var hare: bool = r["kind"] == "hare"
		var row := 0 if (_room and _room.biome in ["frostspine", "ossuary"]) else 1
		var frame := 0
		if bool(r["moving"]):
			frame = 1 if hare else int(float(r["clock"]) * 16.0) % 2
		var flip := (r["dir"] as Vector2).x < 0.0
		_shadow(_low, (r["pos"] as Vector2) + Vector2(0, 4 if hare else 2), Vector2(5 if hare else 4, 1.5), 0.22)
		if hare:
			_blit(_low, HARE, Vector2i(12, 10), Vector2i(frame, row), (r["pos"] as Vector2) - Vector2(0, 3.0 if frame == 1 else 0.0), flip, Color.WHITE)
		else:
			_blit(_low, LIZARD, Vector2i(12, 6), Vector2i(frame, row), r["pos"], flip, Color.WHITE)
	_draw_reeds()


## Each tuft is a few blades bending with the wind, the tips swinging most;
## a gust through the room bends them all one way for a moment.
func _draw_reeds() -> void:
	if reeds.is_empty():
		return
	var colours: Array = REED_COLOURS.get(_room.biome if _room else "", [Color(0.3, 0.45, 0.25), Color(0, 0, 0, 0)])
	var blade: Color = colours[0]
	var head: Color = colours[1]
	var push := 0.0
	for g in gusts:
		if float(g["wait"]) <= 0.0:
			push += sin(clampf(float(g["age"]) / float(g["life"]), 0.0, 1.0) * PI) * 0.8
	for r in reeds:
		var base: Vector2 = (r["pos"] as Vector2).floor()
		var height := float(r["height"])
		for k in int(r["blades"]):
			var lean := (k - 1.5) * 1.2
			var sway := sin(_time * 1.7 + float(r["phase"]) + k * 0.8) * 1.4 + minf(push, 2.0) * 2.0
			var tip := base + Vector2(lean * 1.5 + sway, -height + absf(k - 1.5) * 1.5)
			var mid := base + Vector2(lean * 0.6 + sway * 0.35, -height * 0.5)
			var shade := blade.darkened(0.25 if k % 2 == 0 else 0.0)
			_low.draw_line(base, mid, shade, 1.0)
			_low.draw_line(mid, tip, shade.lightened(0.12), 1.0)
			if head.a > 0.0 and k == 1:
				_low.draw_rect(Rect2(tip.floor() + Vector2(-1, 0), Vector2(2, 3)), head)


## Over everything: cloud shadows, falling leaves, gulls, butterflies, fireflies and embers.
func _draw_high() -> void:
	for c in clouds:
		_high.draw_texture_rect_region(CLOUD, Rect2((c["pos"] as Vector2).round(), CLOUD_CELL),
			Rect2(Vector2(0, int(c["shape"]) * CLOUD_CELL.y), CLOUD_CELL), CLOUD_SHADE)
	for m in mist:
		# A few overlapping soft ovals, breathing a little.
		var centre: Vector2 = m["pos"]
		var size: Vector2 = m["size"]
		var breathe := 0.85 + 0.15 * sin(float(m["clock"]) * 0.7)
		for k in 3:
			var offset := Vector2((k - 1) * size.x * 0.3, sin(float(m["clock"]) * 0.5 + k) * 3.0)
			_oval(_high, centre + offset, Vector2(size.x * 0.35, size.y * 0.5) * breathe, Color(0.86, 0.92, 0.88, 0.07))
		_oval(_high, centre, Vector2(size.x * 0.45, size.y * 0.35) * breathe, Color(0.9, 0.95, 0.92, 0.05))
	for g in gusts:
		if float(g["wait"]) > 0.0:
			continue
		var t := float(g["age"]) / float(g["life"])
		var alpha := sin(clampf(t, 0.0, 1.0) * PI) * 0.75
		var start: Vector2 = (g["pos"] as Vector2).floor()
		var length := float(g["length"])
		var tint: Color = GUST_COLOUR.get(_room.biome if _room else "", Color.WHITE)
		_high.draw_rect(Rect2(start, Vector2(length, 1)), Color(tint, alpha))
		_high.draw_rect(Rect2(start + Vector2(length * 0.3, -2).floor(), Vector2(length * 0.4, 1).floor()), Color(tint, alpha * 0.6))
	for l in leaves:
		# A little leaf that turns edge-on and back as it tumbles, with a
		# faint shadow on the ground below so it reads against the grass.
		var at := (l["pos"] as Vector2).floor()
		var colour: Color = LEAF_COLOURS[int(l["colour"])]
		var flat := sin(float(l["clock"]) * 3.0) > -0.3
		_high.draw_rect(Rect2(at + Vector2(1, 5), Vector2(2, 1)), Color(0.08, 0.1, 0.06, 0.3))
		if flat:
			_high.draw_rect(Rect2(at, Vector2(3, 1)), colour)
			_high.draw_rect(Rect2(at + Vector2(1, 1), Vector2(2, 1)), colour.darkened(0.25))
		else:
			_high.draw_rect(Rect2(at + Vector2(1, 0), Vector2(1, 2)), colour.darkened(0.15))
	for a in ash:
		var grey := float(a["shade"])
		var at := (a["pos"] as Vector2).floor()
		if grey >= 1.0:
			# A snowflake: white, with a faint blue shadow so it shows on snow.
			_high.draw_rect(Rect2(at + Vector2(1, 1), Vector2(2, 2)), Color(0.45, 0.55, 0.75, 0.35))
			_high.draw_rect(Rect2(at, Vector2(2, 2)), Color(1, 1, 1, 0.95))
		else:
			_high.draw_rect(Rect2(at, Vector2(2, 2)), Color(grey, grey * 0.95, grey * 0.92, 0.85))
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
	_oval(canvas, at, radii, Color(0.08, 0.06, 0.1, alpha))


## A filled oval (shadows, mist).
func _oval(canvas: Node2D, at: Vector2, radii: Vector2, colour: Color) -> void:
	canvas.draw_set_transform(at.round(), 0.0, Vector2(1.0, radii.y / radii.x))
	canvas.draw_circle(Vector2.ZERO, radii.x, colour)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
