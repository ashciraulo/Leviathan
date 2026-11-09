class_name ChoirFigure
extends Node2D
## A member of the Choir in a story scene: Sister Lowe, or one of her
## hooded singers. Not an Npc: they only appear while a scene plays, then
## leave (see StoryDirector.lowe_at_the_hull).

## kind: sheet texture and frame count. Sheet columns: idle, breathe, then
## talk (Lowe) or two prying frames (singers).
const KINDS := {
	"lowe": {"texture": Art.VILLAGER_LOWE, "frames": 3},
	"singer": {"texture": Art.VILLAGER_SINGER, "frames": 4},
}
const FRAME_IDLE := 0
const FRAME_BREATHE := 1
const FRAME_TALK := 2
const FRAME_PRY := [2, 3]
const BREATHE_TIME := 0.8
const PRY_TIME := 0.32

var kind := "singer"
## Singers lean on their bars under the Matriarch until they are told to run.
var prying := false
## Lowe throws out an arm while she gives orders.
var talking := false
var _sprite: Sprite2D
var _time := 0.0
var _left := false


func _init(figure_kind: String = "singer") -> void:
	kind = figure_kind


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(Art.shadow())
	_sprite = Art.sprite(KINDS[kind]["texture"], KINDS[kind]["frames"], 1, 22)
	_sprite.flip_h = _left
	add_child(_sprite)


func face(left: bool) -> void:
	_left = left
	if _sprite:
		_sprite.flip_h = left


func _process(delta: float) -> void:
	_time += delta
	if prying:
		_sprite.frame = FRAME_PRY[int(_time / PRY_TIME) % 2]
	elif talking and kind == "lowe":
		_sprite.frame = FRAME_TALK
	else:
		_sprite.frame = FRAME_BREATHE if int(_time / BREATHE_TIME) % 2 == 1 else FRAME_IDLE


## Scramble to a gap in the deck and drop through it, out of sight.
func flee_into(hole: Vector2, seconds: float) -> void:
	prying = false
	talking = false
	face(hole.x < position.x)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "position", hole, Cutscene.scaled(seconds))
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), Cutscene.scaled(0.25))
	tween.parallel().tween_property(self, "modulate:a", 0.0, Cutscene.scaled(0.25))
	await tween.finished
	visible = false


## Run along a path of points and out of the room (through its door).
func flee_along(points: Array, seconds_per_leg: float) -> void:
	prying = false
	talking = false
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var from := position
	for point: Vector2 in points:
		if absf(point.x - from.x) > 1.0:
			tween.tween_callback(face.bind(point.x < from.x))
		from = point
		tween.tween_property(self, "position", point, Cutscene.scaled(seconds_per_leg))
	tween.tween_property(self, "modulate:a", 0.0, Cutscene.scaled(0.2))
	await tween.finished
	visible = false
