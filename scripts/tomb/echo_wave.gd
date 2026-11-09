class_name EchoWave
extends Node2D
## The Echo Horn's note, spreading out from Wren as rings. Everything in
## the "echo" group that the ring reaches hears it once (horn_hit(from)):
## bone walls crumble, singing skulls answer, the Hush shows itself and
## bone armour shatters.

## How far the note carries.
const RADIUS := 76.0
const SPREAD_TIME := 0.45
const FADE_TIME := 0.25

var _time := 0.0
var _heard := {}


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	_time += delta
	var radius := radius_now()
	for node in get_tree().get_nodes_in_group("echo"):
		var n := node as Node2D
		if n == null or _heard.has(n.get_instance_id()) or not n.is_inside_tree():
			continue
		if n.global_position.distance_to(global_position) <= radius + _reach(n):
			_heard[n.get_instance_id()] = true
			n.horn_hit(global_position)
	queue_redraw()
	if _time >= SPREAD_TIME + FADE_TIME:
		queue_free()


func radius_now() -> float:
	return RADIUS * minf(_time / SPREAD_TIME, 1.0)


## Big things (the Regent) are heard a little further off their middle.
func _reach(n: Node2D) -> float:
	var r = n.get("echo_reach")
	return float(r) if r != null else 0.0


func _draw() -> void:
	var fade := 1.0 - clampf((_time - SPREAD_TIME) / FADE_TIME, 0.0, 1.0)
	var radius := radius_now()
	for i in 3:
		var r := radius - i * 10.0
		if r <= 2.0:
			continue
		var color := Color(0.54, 0.94, 0.88, (0.7 - i * 0.2) * fade)
		draw_arc(Vector2(0, -6), r, 0.0, TAU, 48, color, 1.0)
