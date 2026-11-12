class_name FishingHole
extends StaticBody2D
## Ottilie's fishing hole in Still Cove's ice (StoryDirector). Once she's
## asked, Wren can fish it for rimefin: Interact drops the float in; after a
## while it bobs under with a splash, and Interact again while it's under
## lands the fish. Too early or too late and the fish is gone. Three rimefin
## for Ottilie (flag ottilie_fish counts them, ottilie_fish_done at three).
##
## Once she's paid and opened her fishing book (ottilie_book) the hole stays
## open for good. More bites at random from SPECIES: frostperch only stay
## under a moment, glass eels nibble first (the float dips; pull then and
## it's gone), and once those are in the book the Old Grey can take the
## line: three pulls, one per dive. Each kind sets caught_<kind>, and Ottilie
## books it. A run without losing one counts in fish_streak; five and ten in
## a row set fish_streak_5 and fish_streak_10 for her prizes.

enum State { IDLE, WAITING, NIBBLE, BITE }

const COUNT_FLAG := "ottilie_fish"
const DONE_FLAG := "ottilie_fish_done"
const WANTED := 3
const BOOK_FLAG := "ottilie_book"
const STREAK_FLAG := "fish_streak"
const STREAKS := [5, 10]
const GREY := "grey"
## kind: [weight, seconds under, toast]. The Old Grey only bites once a
## frostperch and a glass eel are caught.
const SPECIES := {
	"rimefin": [45, 0.7, "TOAST_FISH_RIMEFIN"],
	"perch": [35, 0.45, "TOAST_FISH_PERCH"],
	"eel": [20, 0.6, "TOAST_FISH_EEL"],
	GREY: [12, 0.5, "TOAST_FISH_GREY"],
}
## How long a nibble dips the float, and the wait after it.
const NIBBLE_TIME := 0.3
const NIBBLE_GAP := Vector2(0.6, 1.2)
## The Old Grey dives again between pulls.
const GREY_PULLS := 3
const GREY_DIVE := Vector2(0.35, 0.7)
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
## kind: [body, tail, size, length] for the fish leaping out.
const LOOKS := {
	"rimefin": [FIN, FIN, 1.0, 1.0],
	"perch": [Color("#d8c070"), Color("#e2574c"), 0.9, 0.9],
	"eel": [Color(0.85, 0.95, 1.0, 0.6), Color(0.85, 0.95, 1.0, 0.8), 0.9, 2.0],
	"grey": [Color("#8a929a"), Color("#5e666e"), 1.8, 1.2],
}

var state := State.IDLE
## What's on the line this cast ("rimefin" before the book opens).
var species := "rimefin"
## Nibbles still to come before the real bite (tests can set them).
var nibbles := 0
var _nibble := 0.0
var _pulls := 0
## Seconds until the next bite (tests can set it).
var bite_in := 0.0
var _window := 0.0
var _time := 0.0
var _splash := 0.0
## A landed fish leaping out and flopping on the snow: 0 when there isn't one.
var _leap := 0.0
var _leap_to := Vector2.ZERO
var _leap_kind := "rimefin"


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(16, 6), Vector2(0, -3)))
	add_to_group("interactable")


static func caught() -> int:
	return int(GameState.flags.get(COUNT_FLAG, 0))


static func book_open() -> bool:
	return GameState.has_flag(BOOK_FLAG)


func _fishing_open() -> bool:
	return book_open() or (GameState.has_flag("ottilie_asked") and not GameState.has_flag(DONE_FLAG))


## Which kinds can bite now, by weight.
static func biting() -> Array:
	if not book_open():
		return ["rimefin"]
	var kinds := ["rimefin", "perch", "eel"]
	# Rimefin are in the book already, from her three.
	if GameState.has_flag("caught_perch") and GameState.has_flag("caught_eel"):
		kinds.append(GREY)
	return kinds


static func pick_species() -> String:
	var kinds := biting()
	var total := 0
	for k: String in kinds:
		total += int(SPECIES[k][0])
	var roll := randi() % total
	for k: String in kinds:
		roll -= int(SPECIES[k][0])
		if roll < 0:
			return k
	return kinds[0]


## How long the float stays under for this kind.
static func window_for(kind: String) -> float:
	return float(SPECIES[kind][1]) if book_open() else BITE_WINDOW


## A first nibble for most casts once the book's open; eels always test
## the bait twice.
static func nibbles_for(kind: String) -> int:
	if kind == "eel":
		return 2
	if book_open() and randf() < 0.3:
		return 1
	return 0


func interact() -> void:
	if not _fishing_open():
		return
	match state:
		State.IDLE:
			state = State.WAITING
			species = pick_species()
			nibbles = nibbles_for(species)
			_pulls = 0
			bite_in = randf_range(BITE_AFTER.x, BITE_AFTER.y)
			Audio.play_sfx("splash", global_position, 1.8)
		State.WAITING, State.NIBBLE:
			# Pulled before a bite, or on a nibble: nothing on the line.
			_lost()
		State.BITE:
			_pulls += 1
			if species == GREY and _pulls < GREY_PULLS:
				# He's hooked, and dives again.
				state = State.WAITING
				bite_in = randf_range(GREY_DIVE.x, GREY_DIVE.y)
				_splash = 0.6
				Audio.play_sfx("splash", global_position, 0.9)
				Feel.shake(1.5)
				return
			_land()


func _land() -> void:
	state = State.IDLE
	# It leaps out onto the snow, Ottilie's side of the hole. The Old Grey
	# only shows himself, and goes back in.
	_leap_kind = species
	_leap_to = Vector2.ZERO if species == GREY else Vector2(-22, 2)
	_leap = 1.0
	Audio.play_sfx("splash", global_position, 1.2)
	if not GameState.has_flag(DONE_FLAG):
		var count := caught() + 1
		GameState.set_flag(COUNT_FLAG, count)
		if count >= WANTED:
			GameState.set_flag(DONE_FLAG)
			Audio.play_jingle("jingle_secret")
		else:
			Audio.play_sfx("pickup", global_position)
		return
	var first := not GameState.has_flag("caught_" + species)
	GameState.set_flag("caught_" + species)
	var streak := int(GameState.flags.get(STREAK_FLAG, 0)) + 1
	GameState.set_flag(STREAK_FLAG, streak)
	var toast: String = SPECIES[species][2]
	var milestone := false
	for n: int in STREAKS:
		if streak == n and not GameState.has_flag("fish_streak_%d" % n):
			GameState.set_flag("fish_streak_%d" % n)
			milestone = true
			# A first catch keeps its own toast; the run's prize still waits.
			if not first:
				toast = "TOAST_FISH_STREAK_%d" % n
	Events.toast.emit(toast)
	if first or milestone:
		Audio.play_jingle("jingle_secret")
	else:
		Audio.play_sfx("pickup", global_position)


func _lost() -> void:
	state = State.IDLE
	if book_open():
		GameState.set_flag(STREAK_FLAG, 0)
	Audio.play_sfx("bubble_pop", global_position, 0.8)


func _process(delta: float) -> void:
	_time += delta
	_splash = maxf(_splash - delta, 0.0)
	_leap = maxf(_leap - delta * 1.1, 0.0)
	match state:
		State.WAITING:
			bite_in -= delta
			if bite_in <= 0.0 and nibbles > 0:
				# A nibble: the float dips and comes back up.
				nibbles -= 1
				state = State.NIBBLE
				_nibble = NIBBLE_TIME
				# Its own little plip, so it isn't mistaken for a lost fish.
				Audio.play_sfx("text_blip", global_position, 0.6)
			elif bite_in <= 0.0:
				state = State.BITE
				_window = window_for(species)
				_splash = 0.6
				Audio.play_sfx("splash", global_position, 1.5)
		State.NIBBLE:
			_nibble -= delta
			if _nibble <= 0.0:
				state = State.WAITING
				bite_in = randf_range(NIBBLE_GAP.x, NIBBLE_GAP.y)
		State.BITE:
			_window -= delta
			if _window <= 0.0:
				_lost()
	if state != State.IDLE:
		var wren := Lantern.player(get_tree())
		if wren == null or wren.global_position.distance_to(global_position) > LEAVE:
			# Walking off from a cast counts as losing it, run and all.
			if book_open():
				GameState.set_flag(STREAK_FLAG, 0)
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
	elif state == State.NIBBLE:
		# Dipped, but the red still shows: not yet. A small ring, no splash.
		_draw_float(Vector2(0, -1), false)
		var ring := (NIBBLE_TIME - _nibble) / NIBBLE_TIME
		draw_arc(Vector2(0, -2), 2.0 + ring * 4.0, 0.0, TAU, 12, Color(1, 1, 1, 0.8 - ring * 0.6), 1.0)
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
		var look: Array = LOOKS.get(_leap_kind, LOOKS["rimefin"])
		var size: float = look[2]
		draw_set_transform(at, flap + PI, Vector2(1.5, 1.5) * size)
		var long: float = look[3]
		draw_colored_polygon(PackedVector2Array([Vector2(-5 * long, 0), Vector2(0, -2), Vector2(4 * long, 0), Vector2(0, 2)]), Palette.OUTLINE)
		draw_colored_polygon(PackedVector2Array([Vector2(-4 * long, 0), Vector2(0, -1), Vector2(3 * long, 0), Vector2(0, 1)]), look[0])
		draw_colored_polygon(PackedVector2Array([Vector2(-5 * long, 0), Vector2(-5 * long - 2, -2), Vector2(-5 * long - 2, 2)]), look[1])
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
