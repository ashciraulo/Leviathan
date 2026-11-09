class_name BellPhrase
extends Node2D
## Cutscene 5, "Bell rung": the phrase a Tidebell holds, seen leaving it.
## Small glowing notes lift off the bell one after another, arc up, and
## settle into Wren; when the last one lands, a ring of hum light spreads
## from them. More notes for every phrase learned so far, so the stream
## grows bell by bell.

const NOTE := Palette.HUM
## How long each note takes from the bell to Wren, and the gap between them.
const FLIGHT := 1.1
const STAGGER := 0.16
const PULSE := 0.7

var target: Node2D
var notes := 1
var _time := 0.0
var _from := Vector2.ZERO
var _seeds: Array[float] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 30
	_from = global_position + Vector2(0, -22)
	for i in notes:
		# Spread evenly left and right, a little jittered.
		var side := -1.0 + 2.0 * (i + 0.5) / notes
		_seeds.append(clampf(side + randf_range(-0.15, 0.15), -1.0, 1.0))
	_seeds.shuffle()


## Total length of the effect, in real seconds.
func duration() -> float:
	return Cutscene.scaled(FLIGHT + STAGGER * (notes - 1) + PULSE)


func _process(delta: float) -> void:
	_time += delta / Cutscene.scaled(1.0)
	queue_redraw()
	if _time >= FLIGHT + STAGGER * (notes - 1) + PULSE:
		queue_free()


func _to() -> Vector2:
	if is_instance_valid(target):
		return target.global_position + Vector2(0, -10)
	return _from


func _draw() -> void:
	var to := _to() - global_position
	var from := _from - global_position
	for i in notes:
		var t := (_time - STAGGER * i) / FLIGHT
		if t <= 0.0 or t >= 1.0:
			continue
		# A lazy arc: up out of the bell, swaying, then down into Wren.
		var eased := t * t * (3.0 - 2.0 * t)
		var at := from.lerp(to, eased)
		# They fan out from the bell like a fountain and close in on Wren.
		at.y -= sin(t * PI) * (46.0 + 14.0 * absf(_seeds[i]))
		at.x += sin(t * PI) * 44.0 * _seeds[i]
		_draw_note(at.round(), minf(t * 4.0, 1.0))
	var pulse := (_time - STAGGER * (notes - 1) - FLIGHT) / PULSE
	if pulse > 0.0 and pulse < 1.0:
		var colour := NOTE
		colour.a = 1.0 - pulse
		draw_arc(to, 6.0 + 26.0 * pulse, 0.0, TAU, 32, colour, 1.0)
		draw_arc(to, 3.0 + 14.0 * pulse, 0.0, TAU, 24, colour, 1.0)


## A tiny pixel note: a round head, a stem and a flag, with a soft halo.
func _draw_note(at: Vector2, alpha: float) -> void:
	var halo := NOTE
	halo.a = 0.25 * alpha
	draw_circle(at + Vector2(0, -2), 6.0, halo)
	var ink := Color(NOTE.lightened(0.45), alpha)
	draw_rect(Rect2(at + Vector2(-3, 0), Vector2(4, 3)), ink)
	draw_rect(Rect2(at + Vector2(-2, -1), Vector2(2, 1)), ink)
	draw_rect(Rect2(at + Vector2(0, -7), Vector2(1, 7)), ink)
	draw_rect(Rect2(at + Vector2(1, -7), Vector2(2, 1)), ink)
	draw_rect(Rect2(at + Vector2(2, -6), Vector2(2, 1)), ink)
	draw_rect(Rect2(at + Vector2(3, -5), Vector2(1, 2)), ink)
