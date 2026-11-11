class_name HitSpark
extends Node2D
## A short burst drawn by hand where a blow lands (no particles: they stall
## the web build). HIT is a white star that snaps open and is gone; BLOCK is a
## spray of cold sparks thrown back the way the sword came; FALL is a ring of
## dust puffs where a foe drops; FINAL is the great star and ring of a
## boss's last blow; WEAR is a few puffs of strain rising off a worn boss.
## With flashes turned off the bright core is
## left out and everything is dimmer.

enum Kind { HIT, BLOCK, FALL, FINAL, WEAR }

const LIFE := {Kind.HIT: 0.14, Kind.BLOCK: 0.22, Kind.FALL: 0.38, Kind.FINAL: 0.7, Kind.WEAR: 0.9}
const HIT_CORE := Color("#fff6d8")
const HIT_EDGE := Color("#ffd27a")
const BLOCK_SPARK := Color("#cfe8ff")
const DUST := Color("#f4eee4")
const DUST_SHADE := Color("#8c7f74")
## A dark rim under bright pixels so they read on pale floors.
const RIM := Color("#2b1d2e")

var kind := Kind.HIT
## The way the blow travelled (BLOCK sparks fly back against it).
var direction := Vector2.RIGHT
var _time := 0.0
var _seed := 0


## Adds a burst to `parent` at `at` (global). Returns it for tests.
static func spawn(parent: Node, at: Vector2, what: Kind, dir: Vector2 = Vector2.RIGHT) -> HitSpark:
	if parent == null or not parent.is_inside_tree():
		return null
	var spark := HitSpark.new()
	spark.kind = what
	spark.direction = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	parent.add_child(spark)
	spark.global_position = at.round()
	return spark


func _ready() -> void:
	z_index = 20
	# Rooms north of the shore sit at negative y; keep the seed positive.
	_seed = absi(int(global_position.x * 7.0 + global_position.y * 13.0))


func _process(delta: float) -> void:
	_time += delta
	if _time >= LIFE[kind]:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = clampf(_time / LIFE[kind], 0.0, 1.0)
	var dim := 1.0 if Settings.flashes else 0.55
	match kind:
		Kind.HIT:
			_draw_hit(t, dim)
		Kind.BLOCK:
			_draw_block(t, dim)
		Kind.FALL:
			_draw_fall(t, dim)
		Kind.FINAL:
			_draw_final(t, dim)
		Kind.WEAR:
			_draw_wear(t, dim)


func _draw_hit(t: float, dim: float) -> void:
	# Opens fast, then the rays thin out and shrink back. A dark rim keeps
	# it readable on pale sand and snow.
	var reach := roundf(lerpf(4.0, 11.0, minf(t * 3.0, 1.0)) * (1.0 - t * 0.35))
	var fade := (1.0 - t * t) * dim
	var rim := Color(RIM, fade * 0.7)
	var edge := Color(HIT_EDGE, fade)
	var pixels: Array[Rect2] = []
	for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		for i in range(2, int(reach)):
			var thick := 2.0 if i < reach * 0.55 else 1.0
			var side := Vector2(absf(d.y), absf(d.x)) * thick
			pixels.append(Rect2((d * i - side * 0.5).floor(), Vector2.ONE.max(side)))
	var diag := int(reach * 0.5)
	for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		for i in range(2, diag):
			pixels.append(Rect2(d * i, Vector2.ONE))
	for px in pixels:
		draw_rect(px.grow(1.0), rim)
	for px in pixels:
		draw_rect(px, edge)
	if t < 0.55:
		var core := HIT_CORE if Settings.flashes else HIT_EDGE
		draw_rect(Rect2(-2, -2, 4, 4), Color(RIM, fade * 0.7))
		draw_rect(Rect2(-1.5, -1.5, 3, 3), Color(core, (1.0 - t * 1.8) * dim))


func _draw_block(t: float, dim: float) -> void:
	# A cold clink where steel meets shell, and seven sparks thrown back
	# toward Wren, falling a little as they go.
	var back := -direction
	var fade := (1.0 - t) * dim
	if t < 0.35:
		var c := Color(BLOCK_SPARK, (1.0 - t / 0.35) * dim)
		draw_rect(Rect2(-3, -3, 7, 7).grow(0.0), Color(RIM, c.a * 0.5))
		draw_rect(Rect2(-3, 0, 7, 1), c)
		draw_rect(Rect2(0, -3, 1, 7), c)
	for i in 7:
		var spread := (float(i) - 3.0) * 0.3 + float((_seed + i * 17) % 7 - 3) * 0.03
		var dir := back.rotated(spread)
		var speed := 42.0 + float((_seed + i * 11) % 5) * 8.0
		var at := (dir * speed * _time + Vector2(0, 60.0 * _time * _time)).round()
		var size := Vector2(2, 2) if i % 2 == 0 else (Vector2(3, 1) if absf(dir.x) > absf(dir.y) else Vector2(1, 3))
		draw_rect(Rect2(at, size).grow(1.0), Color(RIM, fade * 0.6))
		draw_rect(Rect2(at, size), Color(BLOCK_SPARK, fade))


func _draw_fall(t: float, dim: float) -> void:
	# A ring of dust puffs spreading low along the floor and thinning out.
	var radius := lerpf(3.0, 14.0, 1.0 - (1.0 - t) * (1.0 - t))
	var fade := (1.0 - t) * dim
	var size := 4.0 if t < 0.4 else (3.0 if t < 0.75 else 2.0)
	for i in 8:
		var angle := TAU * float(i) / 8.0 + float(_seed % 5) * 0.1
		# Flattened: the floor seen from above at a slant.
		var at := (Vector2(cos(angle), sin(angle) * 0.55) * radius - Vector2.ONE * size * 0.5).round()
		draw_rect(Rect2(at + Vector2(0, 1), Vector2.ONE * size), Color(DUST_SHADE, fade * 0.8))
		draw_rect(Rect2(at, Vector2.ONE * size), Color(DUST, fade * 0.9))


func _draw_final(t: float, dim: float) -> void:
	# Eight long rays that burst out and thin, inside a ring that rolls
	# outward and fades.
	var grow := 1.0 - (1.0 - minf(t * 2.5, 1.0)) * (1.0 - minf(t * 2.5, 1.0))
	var reach := roundf(lerpf(6.0, 26.0, grow) * (1.0 - t * 0.3))
	var fade := (1.0 - t * t) * dim
	var pixels: Array[Rect2] = []
	for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		for i in range(3, int(reach)):
			var thick := 3.0 if i < reach * 0.4 else (2.0 if i < reach * 0.75 else 1.0)
			var side := Vector2(absf(d.y), absf(d.x)) * thick
			pixels.append(Rect2((d * i - side * 0.5).floor(), Vector2.ONE.max(side)))
	for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		for i in range(3, int(reach * 0.6)):
			pixels.append(Rect2(d * i, Vector2.ONE * (2.0 if i < reach * 0.3 else 1.0)))
	for px in pixels:
		draw_rect(px.grow(1.0), Color(RIM, fade * 0.7))
	for px in pixels:
		draw_rect(px, Color(HIT_EDGE, fade))
	if t < 0.5:
		var core := HIT_CORE if Settings.flashes else HIT_EDGE
		draw_rect(Rect2(-4, -4, 8, 8), Color(RIM, fade * 0.7))
		draw_rect(Rect2(-3, -3, 6, 6), Color(core, (1.0 - t * 2.0) * dim))
	# The ring: pixels round a circle, flattened a little to the floor.
	var radius := lerpf(8.0, 40.0, minf(t * 1.4, 1.0))
	var ring := Color(HIT_EDGE, (1.0 - t) * 0.8 * dim)
	for i in 28:
		var angle := TAU * float(i) / 28.0
		var at := (Vector2(cos(angle), sin(angle) * 0.8) * radius).round()
		draw_rect(Rect2(at, Vector2(2, 2)), ring)


func _draw_wear(t: float, dim: float) -> void:
	# Four puffs that lift off, drift a little to one side and thin away: a
	# foe straining, its breath ragged.
	var fade := (1.0 - t * t) * dim
	var lean := 1.0 if _seed % 2 == 0 else -1.0
	for i in 4:
		var lag := float(i) * 0.14
		var u := clampf((t - lag) / (1.0 - lag), 0.0, 1.0)
		if u <= 0.0:
			continue
		var size := 4.0 if u < 0.35 else (3.0 if u < 0.7 else 2.0)
		var at := Vector2(lean * (float(i) * 2.5 + sin(u * 5.0 + float(i)) * 2.0), -u * 20.0 - float(i) * 2.0)
		at = (at - Vector2.ONE * size * 0.5).round()
		draw_rect(Rect2(at, Vector2.ONE * size).grow(1.0), Color(RIM, fade * 0.6))
		draw_rect(Rect2(at + Vector2(0, 1), Vector2.ONE * size), Color(DUST_SHADE, fade * 0.9))
		draw_rect(Rect2(at, Vector2(size, size - 1.0)), Color(DUST, fade))
