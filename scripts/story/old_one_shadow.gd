class_name OldOneShadow
extends Node2D
## Cutscene 11, "The Old One turns": far below the Crown, under the sea, a
## shape far bigger than the room rolls over in its sleep. A blunt-headed,
## scarred body drifts across the whole view, longer than the screen, so it
## is never seen whole. Its dark back passes first; as it turns, the pale,
## scarred flank comes up towards the light, then it sinks away again.

## Body size in pixels: longer than the 384px screen on purpose.
const BODY := Vector2i(560, 150)
const BACK := Color(0.04, 0.05, 0.13)
const FLANK := Color(0.88, 0.9, 0.94)
## Strongest it ever shows: still under water, never in the open.
const DEPTH := 0.75
## Where the body's centre starts and ends, relative to the room.
const FROM := Vector2(520, 70)
const TO := Vector2(-120, 150)
const ROLL_TIME := 6.0

static var _texture: Texture2D

## The room it is seen from: it only shows through that room's open gaps,
## down past the deck, never over the stone.
var room: Room
var _alpha := 0.0
var _roll := 0.0
var _body := Node2D.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Just above the ground, under Wren and everything standing on the deck.
	z_index = -9
	clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	if _texture == null:
		_texture = ImageTexture.create_from_image(_build())
	_body.draw.connect(_draw_body)
	add_child(_body)


## It rises out of the deep, rolls across, and sinks away again. Returns the
## tween so the scene can await its end.
func roll() -> Tween:
	var time := Cutscene.scaled(ROLL_TIME)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(self, "_roll", 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "_alpha", DEPTH, time * 0.3)
	tween.tween_property(self, "_alpha", 0.0, time * 0.35).set_delay(time * 0.65)
	tween.tween_method(func(_t: float) -> void: _body.queue_redraw(), 0.0, 1.0, time)
	return tween


## The mask: every open gap in the room's deck.
func _draw() -> void:
	if room == null:
		return
	for y in Room.ROWS:
		for x in Room.COLS:
			if room.tile_at(x, y) == "_":
				draw_rect(Rect2(x * Room.TILE, y * Room.TILE, Room.TILE, Room.TILE), Color.WHITE)


func _draw_body() -> void:
	if _alpha <= 0.0:
		return
	var turn := sin(PI * _roll)
	var at := FROM.lerp(TO, _roll).round()
	# Turning on its side, the body looks narrower and tilts a little.
	var squash := Vector2(1.0, 1.0 - 0.4 * turn)
	_body.draw_set_transform(at, -0.12 + 0.1 * _roll, squash)
	var colour := BACK.lerp(FLANK, turn * 0.9)
	colour.a = _alpha
	_body.draw_texture(_texture, -Vector2(BODY) / 2.0, colour)
	_body.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The silhouette, in white so `_draw` can tint it: a blunt, boxy head on the
## left, a long body tapering right to the flukes. The edge is dithered so it
## blurs into the water, and old scars show as paler streaks.
static func _build() -> Image:
	var image := Image.create(BODY.x, BODY.y, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mid := BODY.y / 2.0
	for x in BODY.x:
		var half := _half_height(float(x) / BODY.x) * mid
		for y in BODY.y:
			var dy := absf(y - mid)
			if dy > half:
				continue
			var edge := half - dy
			# Dithered rim: the outer pixels thin out in a checker.
			if edge < 3.0 and (x + y) % 2 == 0:
				continue
			if edge < 6.0 and (x + y) % 4 == 0:
				continue
			var shade := 0.72 - 0.22 * (dy / maxf(half, 1.0))
			image.set_pixel(x, y, Color(shade, shade, shade, 1.0))
	# Scars: long pale strokes raked along the body.
	for scar in 26:
		var sx := rng.randf_range(40, BODY.x - 160)
		var sy := rng.randf_range(-0.6, 0.6)
		var length := rng.randi_range(30, 90)
		var slope := rng.randf_range(-0.25, 0.25)
		for step in length:
			var px := int(sx + step)
			var half := _half_height(float(px) / BODY.x) * mid
			var py := int(mid + sy * half + slope * step)
			if px >= BODY.x or absf(py - mid) > half - 6.0:
				continue
			image.set_pixel(px, py, Color(1.0, 1.0, 1.0, 1.0))
			if step % 3 != 0 and py + 1 < BODY.y:
				image.set_pixel(px, py + 1, Color(0.9, 0.9, 0.9, 1.0))
	# One closed eye low on the head: it is asleep.
	for ex in 10:
		image.set_pixel(70 + ex, int(mid + 0.45 * mid) + (1 if ex in [0, 9] else 0), Color(0.25, 0.25, 0.25, 1.0))
	return image


## Half the body's height at `t` along it (0 = the head, 1 = the tail tip),
## as a share of the full half-height.
static func _half_height(t: float) -> float:
	if t < 0.04:
		# The blunt front of the head.
		return 0.75 + 0.2 * (t / 0.04)
	if t < 0.3:
		return 0.95
	if t < 0.88:
		# A long taper to the tail stock.
		return lerpf(0.95, 0.16, smoothstep(0.3, 0.88, t))
	# The flukes spread wide at the very end.
	return lerpf(0.16, 0.9, smoothstep(0.88, 1.0, t))
