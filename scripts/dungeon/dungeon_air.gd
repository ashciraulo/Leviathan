class_name DungeonAir
extends Node2D
## What hangs in a dungeon's air, so no room is ever quite still: dust in
## the Hull's lamplight and water dripping through its deck, embers lifting
## off the Kiln's lava, spores in the Mire, rain blowing through the Gale
## Spire, snow sifting down in the Glacier, drips and bubbles in the
## Belfry, sand trickling from the Tomb's roof, and the Maw's warm, wet
## air. It only draws: no collisions, no harm, never in the way.
## Hand-drawn rather than a CPUParticles2D, which stalls the web build
## (see BoneDraft).

## Above the floor, its props and Wren; under the Mire's darkness (so its
## spores only show in lantern light) and the HUD.
const Z := 40
## In high contrast the air steps back, so foes and hazards stand out.
const CONTRAST_FADE := 0.4

## Per dungeon: how many of each kind, and their colours.
##   motes: drifting specks   fall: snow, ash or sand sifting down
##   rise: embers off lava or bubbles off water   rain: slanting streaks
##   drips: drops from the roof that land with a ring   trickles: thin
##   falls of sand from cracks in the roof
const AIR := {
	"hull": {"motes": 12, "mote": Color(1.0, 0.86, 0.6), "drips": 2, "drip": Color(0.6, 0.82, 0.86)},
	"kiln": {"rise": 16, "rise_on": "lava", "rise_col": Color(1.0, 0.62, 0.22), "fall": 5, "fall_col": Color(0.55, 0.5, 0.5)},
	"mire": {"motes": 12, "mote": Color(0.72, 0.95, 0.78)},
	"gale": {"rain": 14, "rain_col": Color(0.82, 0.9, 1.0)},
	"glacier": {"fall": 22, "fall_col": Color(1.0, 1.0, 1.0)},
	"belfry": {"drips": 3, "drip": Color(0.62, 0.86, 0.82), "rise": 10, "rise_on": "water", "rise_col": Color(0.78, 0.95, 0.92)},
	"tomb": {"trickles": 3, "trickle": Color(0.85, 0.74, 0.52)},
	"maw": {"motes": 14, "mote": Color(1.0, 0.9, 0.86), "drips": 2, "drip": Color(0.95, 0.8, 0.82)},
}
## Once a dungeon's Tidebell has rung, its air settles, as the bell's words
## say: the Kiln's embers die down, the Mire's spores flicker and sink like
## snow, the Gale Spire's rain stops and the Glacier's snow thins. "keep" is
## the share of each kind that stays, "speed" how fast what's left moves.
const SETTLE := {
	"kiln": {"keep": 0.35, "speed": 0.6},
	"mire": {"keep": 0.6, "speed": 0.8, "sink": true, "flicker": true},
	"gale": {"keep": 0.0, "speed": 1.0},
	"glacier": {"keep": 0.3, "speed": 0.6},
}
## How long the Mire's spores flicker when its bell rings (s).
const FLICKER_TIME := 1.4
## Tiles a drip can land on and leave a ring (not walls, gaps, lava or
## deep water).
const DRY_FLOOR := "#_^~Q|!G"
## The Tomb's air keeps this far (px) from a hidden bone wall, so nothing
## is mistaken for the dust that leaks from its seam (see BoneDraft).
const SEAM_CLEAR := 64.0
## Rain slants this way and falls this fast (px/s).
const RAIN_VEL := Vector2(-70, 210)
const DRIP_SPEED := 150.0
const RING_TIME := 0.35

var _room: Room
var _dungeon := ""
var _kind: Dictionary = {}
var _fade := 1.0
## True once this dungeon's bell has rung (see SETTLE).
var _settled := false
var _flicker := 0.0
var _time := 0.0
## Each speck is a small dictionary: where it is, its own clock, and so on.
var _motes: Array[Dictionary] = []
var _falls: Array[Dictionary] = []
var _rises: Array[Dictionary] = []
var _rain: Array[Dictionary] = []
var _drips: Array[Dictionary] = []
var _trickles: Array[Dictionary] = []
## Tiles embers or bubbles come off, and floor tiles under the roof.
var _sources: Array[Vector2i] = []
var _roof: Array[Vector2i] = []
## Hidden bone walls' tiles, in room pixels.
var _seams: Array[Vector2] = []


func _ready() -> void:
	_room = get_parent() as Room
	_dungeon = _room.dungeon if _room else ""
	_kind = AIR.get(_dungeon, {})
	z_index = Z
	if _kind.is_empty():
		set_process(false)
		return
	_find_tiles()
	if SETTLE.has(_dungeon):
		_settled = GameState.has_flag(Tidebell.flag_for(_dungeon))
		Events.flag_changed.connect(_on_flag)
	for i in _count("motes"):
		_motes.append(_new_mote(true))
	for i in _count("fall"):
		_falls.append(_new_fall(true))
	if not _sources.is_empty():
		for i in _count("rise"):
			_rises.append(_new_rise(true))
	for i in _count("rain"):
		_rain.append(_new_rain(true))
	if not _roof.is_empty():
		for i in int(_kind.get("drips", 0)):
			_drips.append(_new_drip(randf_range(0.0, 2.5)))
		for i in int(_kind.get("trickles", 0)):
			_trickles.append(_new_trickle())


## How many of a kind hang in the air now.
func _count(kind: String) -> int:
	var n := int(_kind.get(kind, 0))
	if _settled:
		return ceili(n * float(SETTLE[_dungeon].keep))
	return n


## The bell rings: the air settles from now on. What's already drifting
## finishes its way, and fewer take its place.
func _on_flag(flag: String, value: Variant) -> void:
	if flag != Tidebell.flag_for(_dungeon) or not value or _settled:
		return
	_settled = true
	if SETTLE[_dungeon].get("flicker", false):
		_flicker = FLICKER_TIME


## Whether a speck that has run its course should go rather than start
## again, so a settled room thins out to its share.
func _thin(list: Array[Dictionary], kind: String) -> bool:
	if not _settled:
		return false
	var alive := list.filter(func(p: Dictionary) -> bool: return not p.get("gone", false)).size()
	return alive > _count(kind)


func _prune() -> void:
	if not _settled:
		return
	for list: Array[Dictionary] in [_motes, _falls, _rises, _rain]:
		if list.any(func(p: Dictionary) -> bool: return p.get("gone", false)):
			list.assign(list.filter(func(p: Dictionary) -> bool: return not p.get("gone", false)))


## The water has risen or fallen (a Belfry valve): bubbles come off the
## water as it now lies, never off floor that has just drained.
func refresh() -> void:
	if _kind.is_empty():
		return
	_sources.clear()
	_roof.clear()
	_seams.clear()
	_find_tiles()
	_rises.clear()
	if not _sources.is_empty():
		for i in _count("rise"):
			_rises.append(_new_rise(true))
	# Drips land on dry floor, and what's dry has changed too.
	if _roof.is_empty():
		_drips.clear()
	else:
		for d in _drips:
			d.merge(_new_drip(randf_range(0.0, 2.5)), true)


## Where embers and bubbles rise from, and the floor tiles just under the
## roof (where drips fall from).
func _find_tiles() -> void:
	var on := str(_kind.get("rise_on", ""))
	for y in Room.ROWS:
		for x in Room.COLS:
			var t := _room.tile_at(x, y)
			if on == "lava" and (t == "^" or (t == "~" and _room.is_lava())):
				_sources.append(Vector2i(x, y))
			elif on == "water" and (t == "~" or t == "Q") and not _room.is_lava():
				_sources.append(Vector2i(x, y))
			if _room.raw_tile(x, y) == "$":
				_seams.append(Vector2(x * Room.TILE + Room.TILE / 2.0, y * Room.TILE + Room.TILE / 2.0))
	# Drips and sand only come through the outer roof (an inner wall
	# shedding grains would look like a secret), onto floor below.
	for x in range(1, Room.COLS - 1):
		if _room.tile_at(x, 0) == "#" and _dry(x, 1) and _dry(x, 2):
			_roof.append(Vector2i(x, 1))
	if not _seams.is_empty():
		_roof = _roof.filter(func(tile: Vector2i) -> bool: return _clear_of_seams(Vector2(tile * Room.TILE)))


func _dry(x: int, y: int) -> bool:
	return not DRY_FLOOR.contains(_room.tile_at(x, y))


func _clear_of_seams(at: Vector2) -> bool:
	for seam in _seams:
		if seam.distance_to(at) < SEAM_CLEAR:
			return false
	return true


func _inside() -> Vector2:
	return Vector2(randf_range(Room.TILE, Room.SIZE.x - Room.TILE), randf_range(Room.TILE, Room.SIZE.y - Room.TILE))


func _new_mote(anywhere: bool) -> Dictionary:
	return {"at": _inside(), "age": randf_range(0.0, 6.0) if anywhere else 0.0, "life": randf_range(4.0, 7.0),
		"drift": Vector2(randf_range(-3.0, 3.0), randf_range(-4.0, -1.0)), "phase": randf() * TAU,
		"size": 1 + int(randf() < 0.3)}


## How fast the air moves: slower once it has settled.
func _pace() -> float:
	return float(SETTLE[_dungeon].speed) if _settled else 1.0


func _new_fall(anywhere: bool) -> Dictionary:
	var at := Vector2(randf_range(0.0, Room.SIZE.x), randf_range(0.0, Room.SIZE.y) if anywhere else -2.0)
	return {"at": at, "speed": randf_range(10.0, 22.0), "phase": randf() * TAU, "size": 1 + int(randf() < 0.5)}


func _new_rise(anywhere: bool) -> Dictionary:
	var tile: Vector2i = _sources.pick_random()
	var at := Vector2(tile * Room.TILE) + Vector2(randf_range(2.0, 14.0), randf_range(4.0, 14.0))
	var life := randf_range(1.0, 2.2)
	return {"at": at, "age": randf_range(0.0, life) if anywhere else 0.0, "life": life, "speed": randf_range(8.0, 18.0), "phase": randf() * TAU}


func _new_rain(anywhere: bool) -> Dictionary:
	var at := Vector2(randf_range(0.0, Room.SIZE.x + 60.0), randf_range(0.0, Room.SIZE.y) if anywhere else randf_range(-30.0, -4.0))
	return {"at": at, "end": randf_range(Room.SIZE.y * 0.3, Room.SIZE.y), "len": randf_range(4.0, 7.0), "ring": -1.0}


func _new_drip(wait: float) -> Dictionary:
	var tile: Vector2i = _roof.pick_random()
	var top := Vector2(tile.x * Room.TILE + randf_range(3.0, 13.0), tile.y * Room.TILE + 1.0)
	# Down to some dry floor straight below (the rows under the roof are).
	var rows := 2
	while rows < 6 and _dry(tile.x, tile.y + rows):
		rows += 1
	var land := top.y + randf_range(Room.TILE, rows * Room.TILE - 4.0)
	return {"at": top, "wait": wait, "swell": 0.0, "land": land, "ring": -1.0}


func _new_trickle() -> Dictionary:
	var tile: Vector2i = _roof.pick_random()
	return {"x": tile.x * Room.TILE + randf_range(4.0, 12.0), "top": tile.y * Room.TILE + 1.0,
		"len": randf_range(18.0, 40.0), "on": randf_range(2.0, 5.0), "off": randf_range(1.0, 4.0), "age": 0.0}


func _process(delta: float) -> void:
	_time += delta
	_flicker = maxf(_flicker - delta, 0.0)
	var pace := _pace() if SETTLE.has(_dungeon) else 1.0
	var sink: bool = _settled and SETTLE[_dungeon].get("sink", false)
	for m in _motes:
		if m.get("gone", false):
			continue
		m.age += delta
		if m.age >= m.life:
			if _thin(_motes, "motes"):
				m.gone = true
			else:
				m.merge(_new_mote(false), true)
			continue
		var drift: Vector2 = m.drift
		if sink:
			# Settling like snow: down, not up.
			drift.y = absf(drift.y) + 2.0
		m.at += (drift + Vector2(sin(_time * 0.9 + m.phase) * 3.0, 0.0)) * pace * delta
	for f in _falls:
		if f.get("gone", false):
			continue
		f.at += Vector2(sin(_time * 1.3 + f.phase) * 6.0, f.speed) * pace * delta
		if f.at.y > Room.SIZE.y + 2.0:
			if _thin(_falls, "fall"):
				f.gone = true
			else:
				f.merge(_new_fall(false), true)
	for r in _rises:
		if r.get("gone", false):
			continue
		r.age += delta * pace
		if r.age >= r.life:
			if _thin(_rises, "rise"):
				r.gone = true
			else:
				r.merge(_new_rise(false), true)
			continue
		r.at += Vector2(sin(_time * 3.0 + r.phase) * 4.0, -r.speed) * pace * delta
	for s in _rain:
		if s.get("gone", false):
			continue
		if s.ring >= 0.0:
			s.ring += delta
			if s.ring >= RING_TIME:
				if _thin(_rain, "rain"):
					s.gone = true
				else:
					s.merge(_new_rain(false), true)
			continue
		s.at += RAIN_VEL * delta
		if s.at.y >= s.end:
			s.ring = 0.0
	for d in _drips:
		if d.wait > 0.0:
			d.wait -= delta
			continue
		if d.swell < 1.0:
			# The drop gathers on the roof before it lets go.
			d.swell += delta * 1.2
			continue
		if d.ring >= 0.0:
			d.ring += delta
			if d.ring >= RING_TIME:
				d.merge(_new_drip(randf_range(0.8, 3.0)), true)
			continue
		d.at.y += DRIP_SPEED * delta
		if d.at.y >= d.land:
			d.at.y = d.land
			d.ring = 0.0
	for t in _trickles:
		t.age += delta
		if t.age >= t.on + t.off:
			t.merge(_new_trickle(), true)
	_prune()
	queue_redraw()


func _draw() -> void:
	# Read live, so turning high contrast on in the pause menu shows at once.
	_fade = CONTRAST_FADE if Settings.high_contrast else 1.0
	var mote_col: Color = _kind.get("mote", Color.WHITE)
	# The Moth Bell's note: every spore blinks out and back at once.
	var blink := 1.0
	if _flicker > 0.0 and int(_flicker * 7.0) % 2 == 0:
		blink = 0.15
	for m in _motes:
		var t: float = m.age / m.life
		var a := minf(t / 0.25, (1.0 - t) / 0.25)
		a = clampf(a, 0.0, 1.0) * 0.8 * _fade * blink
		if a > 0.02:
			draw_rect(Rect2(m.at.floor(), Vector2(m.size, m.size)), Color(mote_col, a))
	var fall_col: Color = _kind.get("fall_col", Color.WHITE)
	var fall_shadow := Color(0.25, 0.3, 0.45, 0.3 * _fade)
	for f in _falls:
		# Each flake's shadow on the floor below it, so snow shows against snow.
		draw_rect(Rect2(f.at.floor() + Vector2(1, 6), Vector2(f.size, f.size)), fall_shadow)
		draw_rect(Rect2(f.at.floor(), Vector2(f.size, f.size)), Color(fall_col, 0.85 * _fade))
	var rise_col: Color = _kind.get("rise_col", Color.WHITE)
	var bubbles := str(_kind.get("rise_on", "")) == "water"
	for r in _rises:
		var t: float = r.age / r.life
		var a := clampf(minf(t / 0.15, (1.0 - t) / 0.4), 0.0, 1.0) * _fade
		if a <= 0.02:
			continue
		if bubbles:
			draw_arc(r.at.floor() + Vector2(0.5, 0.5), 1.5, 0.0, TAU, 6, Color(rise_col, a * 0.8), 1.0)
		else:
			# An ember cools from yellow to red as it climbs.
			var col := rise_col.lerp(Color(0.85, 0.22, 0.15), t)
			if int((_time + r.phase) * 10.0) % 4 != 0:
				draw_rect(Rect2(r.at.floor() - Vector2.ONE, Vector2(4, 4)), Color(col, a * 0.3))
				draw_rect(Rect2(r.at.floor(), Vector2(2, 2)), Color(col.lightened(0.35), a))
	var rain_col: Color = _kind.get("rain_col", Color.WHITE)
	for s in _rain:
		if s.ring >= 0.0:
			var k: float = s.ring / RING_TIME
			_ring(s.at, 1.0 + 3.0 * k, Color(rain_col, (1.0 - k) * 0.5 * _fade))
		else:
			var tail: Vector2 = s.at - RAIN_VEL.normalized() * s.len
			draw_line(s.at.floor(), tail.floor(), Color(rain_col, 0.45 * _fade), 1.0)
	var drip_col: Color = _kind.get("drip", Color.WHITE)
	for d in _drips:
		if d.wait > 0.0:
			continue
		if d.ring >= 0.0:
			var k: float = d.ring / RING_TIME
			_ring(d.at, 1.0 + 4.0 * k, Color(drip_col, (1.0 - k) * 0.8 * _fade))
		elif d.swell < 1.0:
			if d.swell > 0.4:
				draw_rect(Rect2(d.at.floor(), Vector2.ONE), Color(drip_col, d.swell * _fade))
		else:
			draw_rect(Rect2(d.at.floor(), Vector2(1, 2)), Color(drip_col, 0.9 * _fade))
	var sand_col: Color = _kind.get("trickle", Color.WHITE)
	for t in _trickles:
		if t.age >= t.on:
			continue
		# A broken thread of grains, running down from the crack.
		var grow := minf(t.age / 0.5, 1.0)
		var length: float = t.len * grow
		var y := 0.0
		while y < length:
			if int(y + _time * 60.0) % 3 != 0:
				draw_rect(Rect2(Vector2(t.x, t.top + y).floor(), Vector2.ONE), Color(sand_col, 0.75 * _fade))
			y += 1.0
		# A little heap of grains where it lands.
		if grow >= 1.0:
			draw_rect(Rect2(Vector2(t.x - 1.0, t.top + length).floor(), Vector2(3, 1)), Color(sand_col, 0.6 * _fade))


## A flat ring on the floor where a drop landed.
func _ring(at: Vector2, radius: float, col: Color) -> void:
	if col.a <= 0.02:
		return
	draw_set_transform(at.floor(), 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 10, col, 1.0)
	draw_set_transform(Vector2.ZERO)
