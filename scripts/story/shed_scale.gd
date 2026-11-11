class_name ShedScale
extends StaticBody2D
## A scale the Old One shed, washed up into one of the puzzle caves
## (StoryDirector.SHED_SCALES): Agna needs six for a hand-bell. Picking one
## up sets shed_scale_<id> and it's gone for good; the second page counts
## how many Wren has found so far.

## One per puzzle cave.
const IDS := ["dragline", "rimelight", "emberwell", "drybone", "gustway", "lampless"]
const PEARL := Color("#e4e8ee")
const SHEEN := Color("#b6d2e0")
const RIDGE := Color("#8a9ab2")
const BLUSH := Color("#e8c8d4")

var id := ""
var _time := 0.0


static func flag_for(scale_id: String) -> String:
	return "shed_scale_" + scale_id


## How many scales Wren has picked up.
static func found() -> int:
	return IDS.filter(func(s: String) -> bool: return GameState.has_flag(flag_for(s))).size()


func _ready() -> void:
	# Flat on the floor: Wren can step over it.
	Layers.assign(self, Layers.WORLD, [])
	add_to_group("interactable")


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active or GameState.has_flag(flag_for(id)):
		return
	GameState.set_flag(flag_for(id))
	Audio.play_jingle("jingle_item")
	Events.conversation_requested.emit(Conversations.pages("", {"lines": ["NARRATE_FOUND_SCALE", "NARRATE_SCALES_%d" % found()]}))
	queue_free()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# A grey, shell-bright scale lying tilted on the floor, with growth
	# ridges, and a glint that catches the eye every few seconds.
	draw_set_transform(Vector2(0, -4), -0.25, Vector2(1.0, 0.7))
	draw_circle(Vector2.ZERO, 7.5, Palette.OUTLINE)
	draw_circle(Vector2.ZERO, 6.5, PEARL)
	draw_circle(Vector2(1, 1), 4.5, BLUSH)
	draw_circle(Vector2(-1, -1), 3.5, PEARL)
	draw_arc(Vector2(0, 3), 5.0, PI * 1.1, PI * 1.9, 10, RIDGE)
	draw_arc(Vector2(0, 4), 3.0, PI * 1.15, PI * 1.85, 8, RIDGE)
	draw_circle(Vector2(-2.5, -2.5), 1.8, SHEEN)
	draw_set_transform(Vector2.ZERO)
	if fmod(_time, 2.4) < 0.3:
		var c := Vector2(3, -9)
		draw_line(c + Vector2(-3, 0), c + Vector2(3, 0), Color.WHITE)
		draw_line(c + Vector2(0, -3), c + Vector2(0, 3), Color.WHITE)
