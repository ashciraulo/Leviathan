class_name SealPup
extends StaticBody2D
## The seal pup who rang the buoy bell at night, at home on the Shore once
## Wren's found her (StoryDirector). Talking to her is a conversation with
## no speaker ("seal_pup"), and she barks.

const FUR := Color("#d8dde2")
const FUR_SHADE := Color("#a8b2bc")
const EYE := Color("#1c1a24")

var _time := 0.0


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(14, 6), Vector2(0, -3)))
	add_to_group("interactable")


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active:
		return
	Audio.play_sfx("seal_bark", global_position, 1.6)
	Conversations.talk("seal_pup")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_pup(self, _time, false)


## A round pale pup lying on her front, looking up. Hiding, she's curled
## up small and only peeks now and then.
static func draw_pup(canvas: CanvasItem, time: float, hiding: bool) -> void:
	var lift := 0.0 if hiding else roundf(absf(sin(time * 2.0)) * 1.0)
	var at := Vector2(0, -lift)
	canvas.draw_set_transform(at + Vector2(0, -4), 0.0, Vector2(1.0, 0.6))
	canvas.draw_circle(Vector2.ZERO, 8.0, Palette.OUTLINE)
	canvas.draw_circle(Vector2.ZERO, 7.0, FUR)
	canvas.draw_circle(Vector2(0, 3), 5.0, FUR_SHADE)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Head, up at one end, and the tail flippers at the other.
	canvas.draw_circle(at + Vector2(5, -7), 4.0, Palette.OUTLINE)
	canvas.draw_circle(at + Vector2(5, -7), 3.0, FUR)
	canvas.draw_rect(Rect2(at + Vector2(-10, -4), Vector2(3, 3)), FUR_SHADE)
	var peek := not hiding or fmod(time, 3.0) < 1.0
	if peek:
		canvas.draw_rect(Rect2(at + Vector2(4, -8), Vector2(1, 1)), EYE)
		canvas.draw_rect(Rect2(at + Vector2(6, -8), Vector2(1, 1)), EYE)
	canvas.draw_rect(Rect2(at + Vector2(5, -6), Vector2(1, 1)), EYE)
