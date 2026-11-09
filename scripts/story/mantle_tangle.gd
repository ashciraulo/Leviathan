class_name MantleTangle
extends Node2D
## Mantle the sky-ray lying caught in grey Choir netting on the Wreck Strand
## (cutscene 6). The director spawns it, has Wren cut the net, and then
## Mantle lifts off. Drawn from Mantle's own sprite sheet under a hand-built net.

signal risen

const FRAME_SIZE := Vector2(96, 80)
const FRAMES := 4
## Choir netting: pale grey cord, knots, a twisted rim rope, brass weights
## and guy ropes pegged into the sand.
const CORD_LIGHT := Color("#c9ccd6")
const CORD := Color("#9a9eab")
const CORD_DARK := Color("#5d6070")
const ROPE := Color("#8a8478")
const ROPE_DARK := Color("#575247")
const WEIGHT := Color("#b8914f")
const WEIGHT_LIGHT := Color("#e2c27e")
const STAKE := Color("#7a5634")
const RISE_TIME := 2.2
## Offset that puts the flying sprite's body over Mantle's feet.
const BODY := Vector2(-10, -6)
## The net is an uneven oval over the body and inner wings, relative to
## Mantle's feet, drawn into a texture once (see _net_texture).
const NET_CENTRE := Vector2(0, -7)
const NET_RADIUS := Vector2(31, 24)
const NET_ORIGIN := Vector2(-46, -43)
const NET_SIZE := Vector2i(92, 74)
## Mesh spacing in pixels at the rim; the middle bulges wider over the body.
const MESH := 8.0
const BULGE := 0.25
## Where Wren's blade parts the net, in texture columns.
const CUT_X := 46

static var _texture: Texture2D

## 0 = netted and still, 1 = net gone.
var _net := 1.0
var _shake := 0.0
var _frame := 0
var _lift := 0.0
var _time := 0.0
var _flying := false


func _ready() -> void:
	z_index = 2
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_time += delta
	if _flying:
		_frame = int(_time * 9.0) % FRAMES
	elif _net > 0.5:
		# A tired twitch every couple of seconds.
		_shake = 1.0 if fmod(_time, 2.2) < 0.25 and int(_time * 20.0) % 2 == 0 else 0.0
	queue_redraw()


## Wren's blade parts the net, which falls away.
func cut() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "_net", 0.0, Cutscene.scaled(0.6))
	await tween.finished
	_shake = 0.0


## Mantle beats its wings, rises and wheels away to the north.
func rise() -> void:
	_flying = true
	_time = 0.0
	Audio.play_sfx("mantle_wings", global_position)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_lift", 1.0, Cutscene.scaled(RISE_TIME))
	await tween.finished
	visible = false
	risen.emit()


func _draw() -> void:
	var height := _lift * 260.0
	# Shadow on the sand, shrinking as Mantle climbs.
	var spread := 1.0 + _lift
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.9 / spread, 0.5 / spread))
	draw_circle(Vector2.ZERO, 22.0, Color(0.05, 0.04, 0.12, 0.32 * (1.0 - _lift)))
	# The sheet's frames are drawn in flight; BODY puts the body on the shadow.
	var at := (BODY + Vector2(_shake, -height)).round()
	draw_set_transform(at, 0.0, Vector2.ONE)
	draw_texture_rect_region(Art.MANTLE, Rect2(-FRAME_SIZE / 2.0, FRAME_SIZE),
		Rect2(Vector2(_frame * FRAME_SIZE.x, 0), FRAME_SIZE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _net <= 0.0:
		return
	# Once cut, the two halves part, slump onto the sand and fade.
	var texture := _net_texture()
	var gone := 1.0 - _net
	var tint := Color(1, 1, 1, _net)
	var halves := [[0, -1.0], [CUT_X, 1.0]]
	for half: Array in halves:
		var from: int = half[0]
		var width: int = CUT_X if from == 0 else NET_SIZE.x - CUT_X
		var shift := Vector2(float(half[1]) * gone * 10.0, gone * 9.0).round()
		draw_texture_rect_region(texture, Rect2(NET_ORIGIN + Vector2(from, 0) + shift, Vector2(width, NET_SIZE.y)),
			Rect2(from, 0, width, NET_SIZE.y), tint)


## The net, drawn pixel by pixel once and shared.
static func _net_texture() -> Texture2D:
	if _texture != null:
		return _texture
	var image := Image.create(NET_SIZE.x, NET_SIZE.y, false, Image.FORMAT_RGBA8)
	var inside := func(p: Vector2) -> float:
		var d := (p - NET_CENTRE) / NET_RADIUS
		var a := d.angle()
		var edge := 1.0 + 0.07 * sin(3.0 * a + 1.0) + 0.04 * sin(7.0 * a)
		return d.length() / edge
	# Guy ropes from the rim out to stakes in the sand, under everything else.
	for angle: float in [0.5, 2.6, 3.7, 5.5]:
		var dir := Vector2.from_angle(angle)
		var rim := NET_CENTRE + dir * NET_RADIUS * 0.98
		var peg := NET_CENTRE + dir * NET_RADIUS * 1.32
		for i in 24:
			var p := rim.lerp(peg, i / 23.0).round() - NET_ORIGIN
			_put(image, p, ROPE_DARK if i % 3 == 0 else ROPE)
		var stake := peg.round() - NET_ORIGIN
		for y in range(-3, 2):
			_put(image, stake + Vector2(-1, y), Palette.OUTLINE)
			_put(image, stake + Vector2(0, y), STAKE)
			_put(image, stake + Vector2(1, y), Palette.OUTLINE)
		_put(image, stake + Vector2(0, -4), Palette.OUTLINE)
	# The mesh: two families of diagonal cords, spread wide over the body's
	# dome and bunched at the rim, with a knot where they cross and a soft
	# shadow on Mantle beneath each cord.
	var cords: Array[Vector2] = []
	for y in NET_SIZE.y:
		for x in NET_SIZE.x:
			var p := NET_ORIGIN + Vector2(x, y)
			var s: float = inside.call(p)
			if s >= 1.0:
				continue
			var m := (p - NET_CENTRE) / (1.0 + BULGE * (1.0 - s * s))
			var a := fposmod(m.x + m.y, MESH) < 1.0
			var b := fposmod(m.x - m.y, MESH) < 1.0
			if a and b:
				image.set_pixel(x, y, CORD_DARK)
				cords.append(Vector2(x, y))
			elif a:
				image.set_pixel(x, y, CORD_LIGHT)
				cords.append(Vector2(x, y))
			elif b:
				image.set_pixel(x, y, CORD)
				cords.append(Vector2(x, y))
	for c: Vector2 in cords:
		var below := c + Vector2(1, 1)
		if below.x < NET_SIZE.x and below.y < NET_SIZE.y and image.get_pixelv(below).a == 0.0:
			image.set_pixelv(below, Color(0.06, 0.04, 0.14, 0.4))
	# The rim rope: an outline outside, then a twisted cord.
	for y in NET_SIZE.y:
		for x in NET_SIZE.x:
			var s: float = inside.call(NET_ORIGIN + Vector2(x, y))
			if s >= 1.0 and s < 1.04:
				image.set_pixel(x, y, Palette.OUTLINE)
			elif s >= 0.95 and s < 1.0:
				image.set_pixel(x, y, ROPE if (x + y) / 2 % 2 == 0 else ROPE_DARK)
	# Brass weights strung along the rim.
	for i in 9:
		var w := (NET_CENTRE + Vector2.from_angle(0.3 + i * TAU / 9.0) * NET_RADIUS).round() - NET_ORIGIN
		for y in range(-2, 2):
			for x in range(-2, 3):
				var edge := absi(x) == 2 or y == -2 or y == 1
				var corner := absi(x) == 2 and (y == -2 or y == 1)
				if not corner:
					_put(image, w + Vector2(x, y), Palette.OUTLINE if edge else WEIGHT)
		_put(image, w + Vector2(-1, -1), WEIGHT_LIGHT)
	_texture = ImageTexture.create_from_image(image)
	return _texture


static func _put(image: Image, p: Vector2, colour: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height():
		image.set_pixelv(p, colour)
