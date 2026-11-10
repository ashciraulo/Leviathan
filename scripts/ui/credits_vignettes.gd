class_name CreditsVignettes
extends RefCounted
## The epilogue's little scenes between the credits' names, once the game
## has been finished (story bible, Epilogue): Agna's forge lit, Wick's
## lanterns all in place, Liesl at her great-grandmother's door, Tobin
## hauling rope with his dad, and Sister Lowe alone on a cliff over the sea.
## Pictures only, no words.

const KINDS := ["forge", "lanterns", "doorstep", "rope", "cliff"]
const SIZE := Vector2(84, 56)
## Room between one picture and the names around it.
const GAP := 12.0
const FRAME := Vector2(16, 24)

const OUTLINE := Color("#1a1020")
const BORDER := Color("#e8d07a")


## Draws one scene with its top-left at `at`. `time` drives the flicker,
## the bob and the breathing.
static func draw(canvas: CanvasItem, kind: String, at: Vector2, time: float) -> void:
	var r := Rect2(at, SIZE)
	canvas.draw_rect(r.grow(2), OUTLINE)
	canvas.draw_rect(r.grow(1), BORDER)
	canvas.draw_rect(r, OUTLINE)
	match kind:
		"forge":
			_forge(canvas, at, time)
		"lanterns":
			_lanterns(canvas, at, time)
		"doorstep":
			_doorstep(canvas, at, time)
		"rope":
			_rope(canvas, at, time)
		"cliff":
			_cliff(canvas, at, time)


## A villager's idle frame, breathing now and then.
static func _person(canvas: CanvasItem, tex: Texture2D, at: Vector2, time: float, offset := 0.0, flip := false) -> void:
	var frame := 1 if fmod(time * 0.8 + offset, 2.0) > 1.0 else 0
	var size := FRAME * Vector2(-1 if flip else 1, 1)
	var dest := Rect2(at + (Vector2(FRAME.x, 0) if flip else Vector2.ZERO), size)
	canvas.draw_texture_rect_region(tex, dest, Rect2(Vector2(frame * FRAME.x, 0), FRAME))


## Agna at her forge, its mouth glowing again.
static func _forge(canvas: CanvasItem, at: Vector2, time: float) -> void:
	canvas.draw_rect(Rect2(at, SIZE), Color("#3a2e34"))
	canvas.draw_rect(Rect2(at + Vector2(0, 42), Vector2(SIZE.x, 14)), Color("#4e3c3a"))
	# The forge: stone, and a mouth of fire that flickers.
	canvas.draw_rect(Rect2(at + Vector2(10, 14), Vector2(30, 30)), Color("#6e5e56"))
	canvas.draw_rect(Rect2(at + Vector2(10, 14), Vector2(30, 2)), Color("#8e7e6e"))
	var flick := 0.8 + sin(time * 9.0) * 0.1 + sin(time * 23.0) * 0.1
	canvas.draw_rect(Rect2(at + Vector2(16, 26), Vector2(18, 14)), Color("#f27a5e") * Color(1, 1, 1, flick))
	canvas.draw_rect(Rect2(at + Vector2(19, 31), Vector2(12, 9)), Color("#ffe36e"))
	# Its glow on the floor.
	canvas.draw_rect(Rect2(at + Vector2(8, 44), Vector2(40, 3)), Color(1.0, 0.6, 0.3, 0.35 * flick))
	# The anvil.
	canvas.draw_rect(Rect2(at + Vector2(46, 38), Vector2(12, 3)), Color("#46546c"))
	canvas.draw_rect(Rect2(at + Vector2(49, 41), Vector2(6, 5)), Color("#46546c"))
	_person(canvas, Art.VILLAGER_AGNA, at + Vector2(60, 24), time, 0.0, true)


## Wick and the fen's five lanterns, all lit.
static func _lanterns(canvas: CanvasItem, at: Vector2, time: float) -> void:
	canvas.draw_rect(Rect2(at, SIZE), Color("#1e2a3a"))
	canvas.draw_rect(Rect2(at + Vector2(0, 40), Vector2(SIZE.x, 16)), Color("#2e4030"))
	canvas.draw_rect(Rect2(at + Vector2(0, 46), Vector2(SIZE.x, 3)), Color("#3a6a8e"))
	for i in 5:
		var x := 30.0 + i * 11.0
		var bob := roundf(sin(time * 2.0 + i * 1.3))
		canvas.draw_rect(Rect2(at + Vector2(x, 26 + i % 2 * 4), Vector2(1, 16 - i % 2 * 4)), Color("#6e5e46"))
		var lamp := at + Vector2(x - 1, 22 + i % 2 * 4 + bob)
		canvas.draw_circle(lamp + Vector2(1.5, 2), 4.0, Color(1.0, 0.89, 0.43, 0.25))
		canvas.draw_rect(Rect2(lamp, Vector2(3, 4)), Color("#ffe36e"))
	_person(canvas, Art.VILLAGER_WICK, at + Vector2(6, 22), time, 0.5)


## Liesl on her great-grandmother's step, the little bell hung again.
static func _doorstep(canvas: CanvasItem, at: Vector2, time: float) -> void:
	canvas.draw_rect(Rect2(at, SIZE), Color("#f2b48a"))
	canvas.draw_rect(Rect2(at + Vector2(0, 30), Vector2(SIZE.x, 26)), Color("#86b8c8"))
	canvas.draw_rect(Rect2(at + Vector2(0, 30), Vector2(SIZE.x, 1)), Color("#f6eedc"))
	# The drowned cottage's wall and door, out on the flats.
	canvas.draw_rect(Rect2(at + Vector2(40, 10), Vector2(36, 36)), Color("#c8bca8"))
	canvas.draw_rect(Rect2(at + Vector2(52, 24), Vector2(12, 22)), Color("#6b4a32"))
	canvas.draw_rect(Rect2(at + Vector2(52, 24), Vector2(12, 1)), Color("#8d6644"))
	canvas.draw_rect(Rect2(at + Vector2(50, 46), Vector2(16, 3)), Color("#a8987a"))
	# The bell, swinging.
	var swing := roundf(sin(time * 2.5) * 1.0)
	canvas.draw_rect(Rect2(at + Vector2(67, 24), Vector2(1, 3)), Color("#6e5e46"))
	canvas.draw_rect(Rect2(at + Vector2(66 + swing, 27), Vector2(3, 3)), Color("#f2c85a"))
	_person(canvas, Art.VILLAGER_LIESL, at + Vector2(26, 24), time, 1.0)


## Tobin hauling rope with Dunstan on the dock.
static func _rope(canvas: CanvasItem, at: Vector2, time: float) -> void:
	canvas.draw_rect(Rect2(at, SIZE), Color("#3a6a8e"))
	canvas.draw_rect(Rect2(at + Vector2(0, 34), Vector2(SIZE.x, 22)), Color("#8d6644"))
	for x in range(0, int(SIZE.x), 8):
		canvas.draw_rect(Rect2(at + Vector2(x, 34), Vector2(1, 22)), Color("#6b4a32"))
	# The rope between them, pulled taut and slack in turn.
	var sag := 2.0 + sin(time * 2.0) * 1.5
	var a := at + Vector2(22, 34)
	var b := at + Vector2(60, 34)
	var mid := (a + b) * 0.5 + Vector2(0, sag)
	canvas.draw_line(a, mid, Color("#d9c59e"), 1.0)
	canvas.draw_line(mid, b, Color("#d9c59e"), 1.0)
	_person(canvas, Art.VILLAGER_TOBIN, at + Vector2(8, 22), time, 0.3)
	_person(canvas, Art.VILLAGER_DUNSTAN, at + Vector2(60, 22), time, 1.3, true)


## Sister Lowe alone on a cliff, looking out to sea.
static func _cliff(canvas: CanvasItem, at: Vector2, time: float) -> void:
	canvas.draw_rect(Rect2(at, SIZE), Color("#b8c8e8"))
	canvas.draw_rect(Rect2(at + Vector2(0, 28), Vector2(SIZE.x, 28)), Color("#3a6a8e"))
	var shine := roundf(fmod(time * 6.0, SIZE.x))
	canvas.draw_rect(Rect2(at + Vector2(shine, 34), Vector2(6, 1)), Color(1, 1, 1, 0.5))
	canvas.draw_rect(Rect2(at + Vector2(fmod(shine + 40.0, SIZE.x), 44), Vector2(4, 1)), Color(1, 1, 1, 0.4))
	# The cliff: grass over rock.
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, 30), at + Vector2(34, 30), at + Vector2(38, 56), at + Vector2(0, 56)]), Color("#86583e"))
	canvas.draw_rect(Rect2(at + Vector2(0, 28), Vector2(35, 3)), Color("#86b06a"))
	_person(canvas, Art.VILLAGER_LOWE, at + Vector2(16, 6), time, 0.7)
