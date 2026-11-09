class_name ChantWave
extends Node2D
## The Choir's chant, rolling out over the floor of the Maw as a ring of
## sound. First a chant mark glows where it will start (the tell), then the
## ring spreads. It catches Wren on the ground; gliding over it, or riding
## the Tide Hook's line, they're clear of it. A note of the Echo Horn that
## meets it breaks it up.

const TELL_TIME := 0.9
const SPREAD_TIME := 2.4
const RADIUS := 150.0
## How thick the ring is, either side of its edge.
const BAND := 5.0

var _time := 0.0
var _hit := false
var _broken := false
var _mark: Sprite2D


func _ready() -> void:
	add_to_group("echo")
	z_index = -4
	_mark = Sprite2D.new()
	_mark.texture = MawSprites.CHANT_MARK
	_mark.modulate.a = 0.0
	add_child(_mark)
	Audio.play_sfx("choir_chant", global_position)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time < TELL_TIME:
		_mark.modulate.a = 0.3 + 0.6 * (_time / TELL_TIME) * (0.6 + 0.4 * sin(_time * 30.0))
	else:
		_mark.modulate.a = maxf(_mark.modulate.a - delta * 2.0, 0.0)
	var radius := radius_now()
	if radius > 0.0 and not _hit and not _broken:
		var wren := get_tree().get_first_node_in_group("player") as Player
		if wren and not wren.airborne and absf(wren.global_position.distance_to(global_position) - radius) < BAND:
			_hit = true
			wren.take_damage(1, global_position)
	queue_redraw()
	if _time >= TELL_TIME + SPREAD_TIME:
		queue_free()


## The ring's radius now (0 during the tell).
func radius_now() -> float:
	if _time < TELL_TIME:
		return 0.0
	return RADIUS * minf((_time - TELL_TIME) / SPREAD_TIME, 1.0)


## The Echo Horn's note meets the chant and scatters it.
func horn_hit(_from: Vector2) -> void:
	if _broken:
		return
	_broken = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var radius := radius_now()
	if radius <= 2.0:
		return
	var fade := 1.0 - clampf((_time - TELL_TIME) / SPREAD_TIME, 0.0, 1.0) * 0.6
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.54, 0.94, 0.88, 0.75 * fade), 3.0)
	draw_arc(Vector2.ZERO, radius - 4.0, 0.0, TAU, 64, Color(0.54, 0.94, 0.88, 0.3 * fade), 1.0)
	draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 64, Color(0.82, 0.25, 0.31, 0.25 * fade), 1.0)
