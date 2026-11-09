class_name MawBreath
extends Node2D
## The Old One breathing, felt from inside its head: the Maw's palate
## floor (",") floods as it breathes in and drains as it breathes out, on
## one clock for the whole Maw. Before it floods the floor shivers and a
## long low rush comes up the throat (the tell). The room adds one of these
## when it is in the Maw and has any "," floor.

enum Phase { OUT, IN_TELL, IN, OUT_TELL }

const OUT_TIME := 7.0
const IN_TELL_TIME := 1.5
const IN_TIME := 5.0
const OUT_TELL_TIME := 1.0
const CYCLE := OUT_TIME + IN_TELL_TIME + IN_TIME + OUT_TELL_TIME

## Seconds of play the breath has run (advanced once per physics frame by
## whichever MawBreath is processing, so a pause holds it still).
static var elapsed := 0.0
static var _stamp := -1

var _room: Room
var _was_high := false


static func phase() -> Phase:
	var t := fmod(elapsed, CYCLE)
	if t < OUT_TIME:
		return Phase.OUT
	if t < OUT_TIME + IN_TELL_TIME:
		return Phase.IN_TELL
	if t < OUT_TIME + IN_TELL_TIME + IN_TIME:
		return Phase.IN
	return Phase.OUT_TELL


## True while the palate floor is under water.
static func high() -> bool:
	return phase() in [Phase.IN, Phase.OUT_TELL]


func _ready() -> void:
	_room = get_parent() as Room
	z_index = -5
	_was_high = high()


func _physics_process(delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if _stamp != frame:
		_stamp = frame
		elapsed += delta
	var now := high()
	if now != _was_high:
		_was_high = now
		if _room:
			_room.refresh_water()
		Audio.play_sfx("maw_breath_in" if now else "maw_breath_out", global_position + Room.SIZE / 2.0)
	queue_redraw()


func _draw() -> void:
	if _room == null or phase() != Phase.IN_TELL:
		return
	# The floor shivering as the water gathers under it.
	var t := fmod(elapsed, CYCLE) - OUT_TIME
	var alpha := 0.12 + 0.25 * (t / IN_TELL_TIME)
	for y in Room.ROWS:
		for x in Room.COLS:
			if _room.raw_tile(x, y) == ",":
				var wobble := sin(elapsed * 14.0 + x + y * 2.0) * 1.5
				draw_rect(Rect2(x * Room.TILE, y * Room.TILE + 6 + wobble, Room.TILE, 3), Color(0.11, 0.29, 0.36, alpha))
