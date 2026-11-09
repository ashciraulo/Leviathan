class_name Crucible
extends Node2D
## The Kiln's great crucible, with the Ember Bell sinking into the melt, as
## the Choir stokes it (StoryDirector.the_crucible). When the slag comes
## alive it boils over, and the Slagwyrm bursts out of it.

const IRON := Color("#3a2a32")
const IRON_LIGHT := Color("#6a5058")
const MELT := Color("#f2803a")
const MELT_HOT := Color("#ffd36e")
const BELL_FRAME := Vector2(32, 40)
## How much of the bell still shows above the melt, in pixels.
const BELL_SHOWS := 17.0

var _time := 0.0
## 0 = simmering, 1 = boiling over.
var _boil := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 1


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## The melt heaves and spits as the wyrm wakes in it.
func boil() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "_boil", 1.0, Cutscene.scaled(0.6))
	await tween.finished


## The wyrm bursts out: the crucible cracks apart.
func shatter() -> void:
	KilnDebris.burst(get_parent(), position + Vector2(0, -10), 16)
	queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * (3.0 + 9.0 * _boil))
	# Heat glow on the floor around it.
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 30.0 + 6.0 * _boil, Color(MELT, 0.12 + 0.1 * pulse + 0.2 * _boil))
	# The bowl: a squat iron pot with a lip.
	draw_set_transform(Vector2(0, -6), 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 19.0, Palette.OUTLINE)
	draw_circle(Vector2.ZERO, 18.0, IRON)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-18, -14, 36, 8), IRON)
	draw_rect(Rect2(-19, -14, 1, 8), Palette.OUTLINE)
	draw_rect(Rect2(18, -14, 1, 8), Palette.OUTLINE)
	# The melt, with the Ember Bell's crown sticking out of it.
	var top := Vector2(0, -15)
	draw_set_transform(top, 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, 19.0, Palette.OUTLINE)
	draw_circle(Vector2.ZERO, 18.0, IRON_LIGHT)
	draw_circle(Vector2.ZERO, 15.0, MELT.lerp(MELT_HOT, pulse * (0.4 + 0.6 * _boil)))
	draw_circle(Vector2(-4, -3), 6.0, Color(MELT_HOT, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var sink := BELL_SHOWS - 4.0 * _boil + roundf(sin(_time * 14.0) * _boil)
	draw_texture_rect_region(KilnSprites.EMBER_BELL,
		Rect2(Vector2(-BELL_FRAME.x / 2.0, top.y - sink), Vector2(BELL_FRAME.x, sink)),
		Rect2(Vector2.ZERO, Vector2(BELL_FRAME.x, sink)))
	# Bubbles and spits of slag, more of them as it boils.
	for i in 3 + int(_boil * 6.0):
		var phase := fmod(_time * (1.2 + _boil * 2.0) + i * 0.37, 1.0)
		var x := sin(i * 12.9898) * 12.0
		var y := top.y - phase * (6.0 + 16.0 * _boil)
		draw_rect(Rect2(roundf(x), roundf(y), 2, 2), Color(MELT_HOT, 1.0 - phase))
