class_name SignalStone
extends StaticBody2D
## One of the old keepers' signal stones on the far headlands
## (StoryDirector.SIGNAL_STONES): a squat pillar worn flat on top, where a
## keeper stood their lamp to flash "I'm here" down the coast. Nettle asks
## Wren to light all three; the first time, StoryDirector plays the signal
## and its far-off answer. Talking to it is a conversation with no speaker
## (Conversations "signal_stone_<id>").

const STONE := Color("#9c96a4")
const STONE_DARK := Color("#6c6678")
const STONE_TOP := Color("#c4bec8")
const RING := Color("#f7d98a")
const HEIGHT := 16.0
const MOSS := Color("#6f9a4a")

## "stacks", "skerry" or "brink".
var id := ""


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 5), Vector2(0, -2)))
	add_child(Art.shadow(true))
	add_to_group("interactable")


func flag() -> String:
	return "signal_stone_" + id


func lit() -> bool:
	return GameState.has_flag(flag())


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active:
		return
	var was := lit()
	if Conversations.talk(flag()).is_empty():
		return
	if was or not lit():
		return
	queue_redraw()
	var director := get_tree().get_first_node_in_group("story_director")
	if director:
		await Events.dialogue_finished
		if is_inside_tree():
			director.signal_from_stone(self)


func _draw() -> void:
	# A squat standing stone, tapered and worn smooth on top, with a lamp
	# carved into its face and moss around its foot.
	var h := HEIGHT
	var body := PackedVector2Array([Vector2(-7, 0), Vector2(-6, -h + 2), Vector2(-4, -h), Vector2(4, -h), Vector2(6, -h + 2), Vector2(7, 0)])
	var outline := PackedVector2Array()
	for p in body:
		outline.append(p + Vector2(signf(p.x), -1 if p.y < -1 else 0))
	draw_colored_polygon(outline, Palette.OUTLINE)
	draw_colored_polygon(body, STONE)
	draw_colored_polygon(PackedVector2Array([Vector2(2, 0), Vector2(3, -h), Vector2(4, -h), Vector2(6, -h + 2), Vector2(7, 0)]), STONE_DARK)
	draw_rect(Rect2(-4, -h, 8, 2), STONE_TOP)
	# The carved lamp: a little ring with rays.
	var mark := Vector2(-1, -h + 7)
	draw_arc(mark, 1.8, 0, TAU, 8, STONE_DARK)
	for a in [-PI / 2, -PI / 6, -5 * PI / 6]:
		draw_line(mark + Vector2.from_angle(a) * 2.8, mark + Vector2.from_angle(a) * 4.0, STONE_DARK)
	for x in [-6, -3, 4]:
		draw_rect(Rect2(x, -1, 2, 1), MOSS)
	if lit():
		# Where Wren's lamp stood.
		draw_arc(Vector2(0, -h + 1), 2.5, 0, TAU, 8, RING)
