class_name LastMural
extends Node2D
## Cutscene 15, "The last mural": the carving the Hollow Regent walled up in
## his tomb. In the room it is a slab of carved stone on the north wall; for
## the scene, `show_close()` fills most of the screen with it: the Old One
## lying down on the sea floor beside the bones of its family, its eye
## closed, its tail curled round the smallest of them.

const SAND := Color("#d9c59e")
const SAND_DARK := Color("#b8a07a")
const GROOVE := Color("#6e5a4a")
const RELIEF := Color("#f2e3c6")
## The Old One, raised from the stone, a shade darker than the slab.
const BODY := Color("#c9b088")
const BODY_DARK := Color("#a88e6a")
## Where the sea floor runs across the close view.
const BED := 134.0
## The slab on the wall, in room pixels (top-left, size).
const SLAB := Rect2(14 * 16 + 2, 2, 76, 13)
## The close view, in screen pixels (the dialogue box sits below it).
const VIEW := Rect2(48, 14, 288, 150)

var _layer: CanvasLayer
var _view: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = -8


## The slab on the wall, with a few carved strokes that read from afar.
func _draw() -> void:
	draw_rect(SLAB, SAND_DARK)
	draw_rect(SLAB.grow(-1), SAND)
	var base := SLAB.position
	# Seabed, a long curled body and two little heaps of bones.
	draw_line(base + Vector2(3, 10), base + Vector2(73, 10), GROOVE)
	draw_arc(base + Vector2(38, 10), 20.0, PI, TAU, 16, GROOVE)
	draw_arc(base + Vector2(38, 10), 12.0, PI, TAU, 12, GROOVE)
	for x in [8, 11, 14, 62, 65]:
		draw_line(base + Vector2(x, 9), base + Vector2(x, 7), GROOVE)


## Fades the close view in over the screen. Await it.
func show_close() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)
	_view = Control.new()
	_view.position = VIEW.position
	_view.size = VIEW.size
	_view.modulate.a = 0.0
	_view.draw.connect(_draw_close)
	_layer.add_child(_view)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_view, "modulate:a", 1.0, Cutscene.scaled(0.8))
	await tween.finished


func hide_close() -> void:
	if _view == null:
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_view, "modulate:a", 0.0, Cutscene.scaled(0.6))
	await tween.finished
	_layer.queue_free()
	_view = null


func is_showing() -> bool:
	return _view != null


func _draw_close() -> void:
	var c := _view
	var size := VIEW.size
	# The slab: worn sandstone in a deep frame, with a carved wave border.
	c.draw_rect(Rect2(Vector2.ZERO, size), GROOVE)
	c.draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), SAND_DARK)
	c.draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), SAND)
	for x in range(10, int(size.x) - 10, 8):
		c.draw_arc(Vector2(x + 4, 10), 3.0, PI, TAU, 6, GROOVE, 1.0)
		c.draw_arc(Vector2(x + 4, size.y - 8), 3.0, 0.0, PI, 6, GROOVE, 1.0)
	# Weathering: a scatter of pits, always the same.
	var rng := RandomNumberGenerator.new()
	rng.seed = 15
	for i in 160:
		var p := Vector2(rng.randi_range(8, int(size.x) - 9), rng.randi_range(16, int(size.y) - 14))
		c.draw_rect(Rect2(p, Vector2.ONE), SAND_DARK)
	# The sea's surface, far above, and light coming down through it.
	for row in 2:
		var waves := PackedVector2Array()
		for x in range(12, int(size.x) - 11, 2):
			waves.append(Vector2(x, 20 + row * 6 + round(sin(x * 0.16 + row * 1.7) * 2.0)))
		_carve(c, waves)
	for x in [70, 130, 190, 250]:
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 30), Vector2(x + 4, 30), Vector2(x - 10, 120), Vector2(x - 26, 120)]), Color(RELIEF, 0.35))
	# The sea floor.
	var bed := PackedVector2Array()
	for x in range(10, int(size.x) - 9, 2):
		bed.append(Vector2(x, BED + round(sin(x * 0.05) * 2.0)))
	_carve(c, bed)
	# The Old One, lying down among them: a vast body raised in relief, its
	# head laid by the great skull, its tail curled round the calf.
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 49:
		var t := i / 48.0
		var x := lerpf(84.0, 232.0, t)
		var half := 27.0 if t < 0.3 else lerpf(27.0, 7.0, smoothstep(0.3, 1.0, t))
		var mid := 103.0 - 4.0 * sin(t * PI) + 14.0 * smoothstep(0.7, 1.0, t)
		top.append(Vector2(x, mid - half).round())
		bottom.append(Vector2(x, minf(mid + half, BED - 1)).round())
	# The tail sweeps down and round, and the flukes lie flat on the sand.
	var tail_top := PackedVector2Array([top[top.size() - 1], Vector2(246, 112), Vector2(262, 118), Vector2(274, 126), Vector2(278, 132)])
	var tail_bottom := PackedVector2Array([bottom[bottom.size() - 1], Vector2(244, 124), Vector2(256, 128), Vector2(266, 132)])
	var outline := PackedVector2Array()
	outline.append(Vector2(78, 84))
	outline.append_array(top)
	outline.append_array(tail_top)
	var under := tail_bottom.duplicate()
	under.reverse()
	outline.append_array(under)
	var belly := bottom.duplicate()
	belly.reverse()
	outline.append_array(belly)
	outline.append(Vector2(76, BED - 1))
	c.draw_colored_polygon(outline, BODY)
	outline.append(outline[0])
	_carve(c, outline)
	# Light along its back, shadow under its belly.
	var lit := PackedVector2Array()
	for p in top:
		lit.append(p + Vector2(0, 2))
	_lines(c, _dedupe(lit), RELIEF)
	var shade := PackedVector2Array()
	for p in bottom:
		shade.append(p - Vector2(0, 3))
	_lines(c, _dedupe(shade), BODY_DARK)
	# The blunt head's front, and the jaw line under it.
	_carve(c, PackedVector2Array([Vector2(80, 120), Vector2(120, 122), Vector2(150, 118)]))
	# The eye, closed: it is asleep.
	c.draw_arc(Vector2(104, 100), 4.0, 0.1 * PI, 0.9 * PI, 8, GROOVE, 1.0)
	c.draw_line(Vector2(100, 103), Vector2(98, 106), GROOVE)
	c.draw_line(Vector2(104, 104), Vector2(104, 107), GROOVE)
	c.draw_line(Vector2(108, 103), Vector2(110, 106), GROOVE)
	# Old scars raked along its side.
	for scar in [[124, 88, 16, 4], [150, 84, 20, 3], [176, 92, 14, 5], [138, 100, 12, 2], [196, 98, 10, 3]]:
		_carve(c, PackedVector2Array([Vector2(scar[0], scar[1]), Vector2(scar[0] + scar[2], scar[1] + scar[3])]), true)
	# Its family's bones, lying in front: a great skeleton by its head and,
	# in the curl of its tail, a calf's.
	_skeleton(c, Vector2(14, BED - 2), 70.0, 22.0)
	_skeleton(c, Vector2(222, BED - 2), 38.0, 12.0)
	# Flukes, folded on the sand beside the calf.
	_carve(c, PackedVector2Array([Vector2(278, 132), Vector2(270, 136), Vector2(282, 138)]))


## A carved line: a dark groove with a pale lip just below it (or a pale
## raised line, for scars).
func _carve(c: CanvasItem, points: PackedVector2Array, raised := false) -> void:
	points = _dedupe(points)
	var lip := PackedVector2Array()
	for p in points:
		lip.append(p + Vector2(1, 1))
	_lines(c, lip, GROOVE if raised else RELIEF)
	_lines(c, points, RELIEF if raised else GROOVE)


## Bones lying on the bed: a spine, ribs arching up off it, and a skull at
## the left end, all pale and raised.
func _skeleton(c: CanvasItem, at: Vector2, length: float, rib_height: float) -> void:
	var spine := PackedVector2Array([at + Vector2(14, 0), at + Vector2(length, -2)])
	c.draw_polyline(spine, GROOVE, 3.0)
	c.draw_polyline(spine, RELIEF, 1.0)
	var gap := 7.0 if length > 50.0 else 5.0
	var ribs := int((length - 18.0) / gap)
	for i in ribs:
		var x := at.x + 20.0 + i * gap
		if x > at.x + length - 4.0:
			break
		var h := rib_height * sin(PI * (i + 1) / (ribs + 1)) + 4.0
		c.draw_arc(Vector2(x, at.y), h * 0.5, PI * 1.05, TAU * 0.98, 10, GROOVE, 3.0)
		c.draw_arc(Vector2(x, at.y), h * 0.5, PI * 1.05, TAU * 0.98, 10, RELIEF, 1.0)
	# The skull, long and low, resting on the sand.
	var skull := Rect2(at + Vector2(0, -rib_height * 0.45), Vector2(16, rib_height * 0.45))
	c.draw_rect(skull, GROOVE)
	c.draw_rect(skull.grow(-1), RELIEF)
	c.draw_rect(Rect2(skull.position + Vector2(4, 2), Vector2(3, 2)), GROOVE)


## Polylines draw nothing useful through repeated points.
static func _dedupe(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		if out.is_empty() or out[out.size() - 1] != p:
			out.append(p)
	return out


## A polyline as one-pixel segments, which stay crisp at any slope.
static func _lines(c: CanvasItem, points: PackedVector2Array, colour: Color) -> void:
	for i in points.size() - 1:
		c.draw_line(points[i], points[i + 1], colour, -1.0)
