class_name FishingHole
extends StaticBody2D
## Ottilie's fishing hole in Still Cove's ice (StoryDirector). Once she's
## asked, Wren can fish it for rimefin: Interact drops the float in; after a
## while it bobs under with a splash, and Interact again while it's under
## lands the fish. Too early or too late and the fish is gone. Three rimefin
## for Ottilie (flag ottilie_fish counts them, ottilie_fish_done at three).

enum State { IDLE, WAITING, BITE }

const COUNT_FLAG := "ottilie_fish"
const DONE_FLAG := "ottilie_fish_done"
const WANTED := 3
## How long the float sits before a bite, at random within this range.
const BITE_AFTER := Vector2(1.4, 3.2)
## How long the float stays under: the moment to pull.
const BITE_WINDOW := 0.7
## Wren walking further off than this gives up.
const LEAVE := 40.0
const ICE := Color("#e8f4ff")
const ICE_SHADE := Color("#a8c8e0")
const WATER := Color("#1e3a5a")
const WATER_LIGHT := Color("#3a6a8e")
const FLOAT_RED := Color("#e2574c")
const FLOAT_WHITE := Color("#fff4d6")
const FIN := Color("#b8d8f0")

var state := State.IDLE
## Seconds until the next bite (tests can set it).
var bite_in := 0.0
var _window := 0.0
var _time := 0.0
var _splash := 0.0
## A landed fish leaping out and flopping on the snow: 0 when there isn't one.
var _leap := 0.0
var _leap_to := Vector2.ZERO


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(16, 6), Vector2(0, -3)))
	add_to_group("interactable")


static func caught() -> int:
	return int(GameState.flags.get(COUNT_FLAG, 0))


func _fishing_open() -> bool:
	return GameState.has_flag("ottilie_asked") and not GameState.has_flag(DONE_FLAG)


func interact() -> void:
	if not _fishing_open():
		return
	match state:
		State.IDLE:
			state = State.WAITING
			bite_in = randf_range(BITE_AFTER.x, BITE_AFTER.y)
			Audio.play_sfx("splash", global_position, 1.8)
		State.WAITING:
			# Pulled before a bite: nothing on the line.
			_lost()
		State.BITE:
			_land()


func _land() -> void:
	state = State.IDLE
	var count := caught() + 1
	GameState.set_flag(COUNT_FLAG, count)
	# It leaps out onto the snow, Ottilie's side of the hole.
	_leap_to = Vector2(-22, 2)
	_leap = 1.0
	Audio.play_sfx("splash", global_position, 1.2)
	if count >= WANTED:
		GameState.set_flag(DONE_FLAG)
		Audio.play_jingle("jingle_secret")
	else:
		Audio.play_sfx("pickup", global_position)


func _lost() -> void:
	state = State.IDLE
	Audio.play_sfx("bubble_pop", global_position, 0.8)


func _process(delta: float) -> void:
	_time += delta
	_splash = maxf(_splash - delta, 0.0)
	_leap = maxf(_leap - delta * 1.1, 0.0)
	match state:
		State.WAITING:
			bite_in -= delta
			if bite_in <= 0.0:
				state = State.BITE
				_window = BITE_WINDOW
				_splash = 0.6
				Audio.play_sfx("splash", global_position, 1.5)
		State.BITE:
			_window -= delta
			if _window <= 0.0:
				_lost()
	if state != State.IDLE:
		var wren := Lantern.player(get_tree())
		if wren == null or wren.global_position.distance_to(global_position) > LEAVE:
			state = State.IDLE
	queue_redraw()


func _draw() -> void:
	# A hole cut in the ice, its rim chipped white.
	draw_set_transform(Vector2(0, -3), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 11.0, Palette.OUTLINE)
	draw_circle(Vector2.ZERO, 10.0, ICE)
	draw_circle(Vector2(0, 1), 8.0, ICE_SHADE)
	draw_circle(Vector2(0, 1), 7.0, WATER)
	draw_circle(Vector2(-2.5, 0), 2.5, WATER_LIGHT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Chips of ice round it.
	for chip in [Vector2(-12, -2), Vector2(9, -7), Vector2(11, 0), Vector2(-7, 2)]:
		draw_rect(Rect2(chip, Vector2(2, 1)), ICE)
	if state == State.WAITING:
		var bob := roundf(sin(_time * 3.0) * 0.6)
		_draw_float(Vector2(0, -3 + bob), false)
	elif state == State.BITE:
		_draw_float(Vector2(0, -2), true)
	if _splash > 0.0:
		var spread := (0.6 - _splash) * 14.0
		draw_arc(Vector2(0, -3), 2.0 + spread, 0.0, TAU, 14, Color(1, 1, 1, _splash), 1.0)
		# Droplets thrown up as the float's dragged under.
		for i in 4:
			var drop := Vector2(cos(i * 1.7) * spread * 0.6, -3.0 - sin(_splash * 5.0) * 6.0 - i)
			draw_rect(Rect2(drop, Vector2(1, 1)), Color(1, 1, 1, _splash * 1.4))
	if _leap > 0.0:
		# The rimefin arcs up out of the hole towards Wren, flapping.
		var t := minf((1.0 - _leap) * 1.6, 1.0)
		var at := _leap_to * t + Vector2(0, -3 - sin(t * PI) * 22.0)
		var flap := sin(_time * 30.0) * 0.4
		draw_set_transform(at, flap + PI, Vector2(1.5, 1.5))
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(0, -2), Vector2(4, 0), Vector2(0, 2)]), Palette.OUTLINE)
		draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(0, -1), Vector2(3, 0), Vector2(0, 1)]), FIN)
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(-7, -2), Vector2(-7, 2)]), FIN)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The float: red over white; under, only a ripple and its tip show.
func _draw_float(at: Vector2, under: bool) -> void:
	if under:
		draw_rect(Rect2(at + Vector2(-1, -1), Vector2(2, 1)), FLOAT_RED)
		draw_arc(at, 3.0, 0.0, TAU, 10, Color(1, 1, 1, 0.7), 1.0)
		return
	draw_rect(Rect2(at + Vector2(-2, -4), Vector2(4, 5)), Palette.OUTLINE)
	draw_rect(Rect2(at + Vector2(-1, -3), Vector2(2, 2)), FLOAT_RED)
	draw_rect(Rect2(at + Vector2(-1, -1), Vector2(2, 1)), FLOAT_WHITE)
	draw_line(at + Vector2(0, -4), at + Vector2(0, -6), Palette.OUTLINE, 1.0)
