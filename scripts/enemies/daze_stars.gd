class_name DazeStars
extends Node2D
## Three little stars circling over a boss's head while it is open to the
## sword (dazed, grounded, its shell off): the moment to strike. Drawn by
## hand; the owner moves it to the top of its sprite and shows or hides it.

const STAR := Color("#ffd27a")
const RIM := Color("#2b1d2e")
const SPIN := 4.5
## The orbit: wide and flat, like a ring seen from above at a slant.
const ORBIT := Vector2(10, 3)

var _angle := 0.0


func _ready() -> void:
	z_index = 15


func _process(delta: float) -> void:
	if not visible:
		return
	_angle = wrapf(_angle + SPIN * delta, 0.0, TAU)
	queue_redraw()


func _draw() -> void:
	for i in 3:
		var a := _angle + TAU * float(i) / 3.0
		var at := (Vector2(cos(a), sin(a)) * ORBIT).round()
		# Behind the head (the far side of the ring) the star is smaller and
		# dimmer.
		var near := sin(a) > 0.0
		var alpha := 1.0 if near else 0.55
		var arm := 2.0 if near else 1.0
		var pixels: Array[Rect2] = [Rect2(at - Vector2(arm, 0), Vector2(arm * 2.0 + 1.0, 1)), Rect2(at - Vector2(0, arm), Vector2(1, arm * 2.0 + 1.0))]
		for px in pixels:
			draw_rect(px.grow(1.0), Color(RIM, alpha * 0.7))
		for px in pixels:
			draw_rect(px, Color(STAR, alpha))
