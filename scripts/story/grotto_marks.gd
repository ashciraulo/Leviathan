class_name GrottoMarks
extends StaticBody2D
## Flood marks scratched into the Ebb Grotto's wall (StoryDirector): the
## Verge folk who climbed up here the night the Verge went under cut a
## line for every hand's breadth the water rose, and their names beside
## them. Reading them is a conversation with no speaker
## (Conversations "grotto_marks").

const SCRATCH := Color(0.88, 0.84, 0.74, 0.75)
const SHADE := Color(0.1, 0.06, 0.14, 0.6)


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_to_group("interactable")


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active:
		return
	Conversations.talk("grotto_marks")


func _draw() -> void:
	# Drawn on the wall tile above: rising lines, each with a scrawl of a
	# name, and a tiny bell beside the top one.
	for i in 5:
		var y := -11.0 - i * 3.0
		var w := 6.0 + (i % 2) * 3.0
		draw_line(Vector2(-7, y + 1), Vector2(-7 + w, y + 1), SHADE)
		draw_line(Vector2(-7, y), Vector2(-7 + w, y), SCRATCH)
		for j in 3:
			draw_line(Vector2(1 + j * 2, y), Vector2(2 + j * 2, y - 1), SCRATCH)
	var bell := Vector2(6, -24)
	draw_arc(bell, 1.5, PI, TAU, 6, SCRATCH)
	draw_line(bell + Vector2(-2, 0), bell + Vector2(2, 0), SCRATCH)
