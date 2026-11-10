class_name Doorbell
extends Node2D
## Liesl's great-grandmother's little brass door bell (StoryDirector).
## Lost: half buried in Belfry Square's flats, glinting, there to pick up
## only at low tide while Liesl is waiting for it. Hung: back on its
## bracket by the drowned cottage's door in Drowned Lane, where it rings
## each time the tide goes out.

const BRASS := Color("#d9a441")
const BRASS_LIGHT := Color("#f2d27a")
const BRASS_DARK := Color("#8a5a22")
const IRON := Color("#4a3a3a")
## How far above its spot the hung bell is drawn.
const HUNG_LIFT := 10.0

var hung := false
var _time := 0.0
var _swing := 0.0
var _was_low := false


func _ready() -> void:
	if not hung:
		_refresh()
		Events.flag_changed.connect(func(_flag: String, _value: Variant) -> void: _refresh())
	_was_low = Tide.phase() == Tide.Phase.LOW


## Lost, it's only there to find while Liesl's waiting and the tide is out.
func _refresh() -> void:
	var findable := GameState.has_flag("liesl_asked") and not GameState.has_flag("found_doorbell") and Tide.phase() == Tide.Phase.LOW
	visible = findable
	if findable and not is_in_group("interactable"):
		add_to_group("interactable")
	elif not findable and is_in_group("interactable"):
		remove_from_group("interactable")


func _process(delta: float) -> void:
	_time += delta
	_swing = maxf(_swing - delta, 0.0)
	var low := Tide.phase() == Tide.Phase.LOW
	if hung and low and not _was_low:
		# The water's gone out: it rings, as if someone's come home.
		_swing = 1.4
		Audio.play_sfx("bell_ring", global_position, 2.4)
	_was_low = low
	if not hung:
		_refresh()
	queue_redraw()


func interact() -> void:
	if hung or not visible:
		return
	GameState.set_flag("found_doorbell")
	Audio.play_jingle("jingle_secret")
	Events.conversation_requested.emit([{"name": "", "portrait": null, "text": "NARRATE_FOUND_DOORBELL"}])


func _draw() -> void:
	if hung:
		# An iron bracket out from the cottage wall, the bell swinging under
		# it. Drawn HUNG_LIFT up from where it stands, so it sorts in front
		# of the cottage it hangs on.
		var up := Vector2(0, -HUNG_LIFT)
		draw_rect(Rect2(up + Vector2(-2, -14), Vector2(2, 6)), Palette.OUTLINE)
		draw_rect(Rect2(up + Vector2(-2, -14), Vector2(8, 2)), Palette.OUTLINE)
		draw_rect(Rect2(up + Vector2(-1, -13), Vector2(6, 1)), IRON)
		var angle := sin(_time * 1.1) * 0.06 + sin(_swing * 16.0) * 0.55 * _swing
		draw_set_transform(up + Vector2(4, -12), angle, Vector2.ONE)
		_draw_bell()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if _swing > 0.0:
			var spread := (1.4 - _swing) * 14.0
			draw_arc(up + Vector2(4, -8), 3.0 + spread, -PI * 0.95, -PI * 0.05, 12, Color(1, 0.95, 0.7, _swing * 0.5), 1.0)
		return
	# Lost: lying on its side in the wet sand, a glint coming and going.
	draw_set_transform(Vector2(0, -2), PI * 0.5, Vector2.ONE)
	_draw_bell()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(Vector2(-6, 1), Vector2(6, 1), Color(0.35, 0.3, 0.25, 0.5), 1.0)
	var glint := 0.5 + 0.5 * sin(_time * 3.0)
	if glint > 0.7:
		var at := Vector2(-2, -5)
		var size := 1.0 + 2.0 * (glint - 0.7) / 0.3
		draw_line(at - Vector2(size, 0), at + Vector2(size, 0), Color(1, 1, 0.9, glint), 1.0)
		draw_line(at - Vector2(0, size), at + Vector2(0, size), Color(1, 1, 0.9, glint), 1.0)


## A little brass bell, its mouth at y 6 and its loop at y 0.
func _draw_bell() -> void:
	draw_line(Vector2.ZERO, Vector2(0, 1), Palette.OUTLINE, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(2, 0), Vector2(4, 7), Vector2(-4, 7)]), Palette.OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-1, 1), Vector2(1, 1), Vector2(3, 6), Vector2(-3, 6)]), BRASS)
	draw_line(Vector2(-1, 2), Vector2(-2, 5), BRASS_LIGHT, 1.0)
	draw_line(Vector2(2, 3), Vector2(2, 5), BRASS_DARK, 1.0)
	draw_rect(Rect2(-1, 7, 2, 1), Palette.OUTLINE)
