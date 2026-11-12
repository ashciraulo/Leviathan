class_name RibChime
extends Node2D
## One of the five great ribs along Rib Hollow's north wall, while Dace's
## bone-readers' song is wanted (StoryDirector.RIB_SONG). Each rings its
## own note; struck in the song's order (Dace's verse: deepest, the middle,
## down one, the highest, home to the deepest) the hollow sings it back.
## A deep note throws a wide ring of light, a high one a small ring, so the
## song can be read as well as heard.

const ASK_FLAG := "dace_song_ask"
const SUNG_FLAG := "dace_song_sung"
## Each rib's note, west to east. Not in order: the ear (or the rings)
## has to find the deepest.
const PITCHES := [0.9, 0.6, 1.2, 0.75, 1.05]
## The song, as ribs west to east: deepest, middle, down one, highest,
## deepest again.
const SONG := [1, 0, 3, 2, 1]
const GLOW := Color("#a8f4ff")
const GLOW_EDGE := Color("#2f7d8f")
const RING_TIME := 0.9

## The notes struck so far that match the song's start.
static var heard: Array = []

var index := 0
var _ring := 0.0


func _ready() -> void:
	# Over the rib's own art.
	z_index = 5
	add_to_group("interactable")
	add_to_group("rib_chimes")


static func reset() -> void:
	heard.clear()


func _exit_tree() -> void:
	# Leaving the hollow forgets a half-struck song.
	heard.clear()


## The rib's note: rings it and lights it. Sung by the hollow, too.
func ring() -> void:
	_ring = RING_TIME
	Audio.play_sfx("toll_ring", global_position, PITCHES[index])
	queue_redraw()


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active or GameState.has_flag(SUNG_FLAG) or not GameState.has_flag(ASK_FLAG):
		return
	ring()
	heard.append(index)
	if heard != SONG.slice(0, heard.size()):
		# Wrong: start again, from this note if it starts the song.
		heard = [index] if index == SONG[0] else []
	if heard.size() == SONG.size():
		heard.clear()
		GameState.set_flag(SUNG_FLAG)


func _process(delta: float) -> void:
	if _ring > 0.0:
		_ring = maxf(_ring - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	if _ring <= 0.0:
		return
	var t := 1.0 - _ring / RING_TIME
	# A deep note spreads wide; a high one stays small.
	var reach := 6.0 + 16.0 * (1.3 - float(PITCHES[index])) / 0.7
	var r := 4.0 + reach * t
	var edge := GLOW_EDGE
	edge.a = 0.8 * (1.0 - t)
	draw_arc(Vector2(0, -26), r + 1.0, 0.0, TAU, 32, edge, 1.0)
	var c := GLOW
	c.a = 0.95 * (1.0 - t)
	draw_arc(Vector2(0, -26), r, 0.0, TAU, 32, c, 1.5)
	c.a = 0.45 * (1.0 - t)
	draw_circle(Vector2(0, -26), 6.0, c)
