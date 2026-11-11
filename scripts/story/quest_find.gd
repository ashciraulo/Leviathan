class_name QuestFind
extends StaticBody2D
## A small thing lying about for a villager's errand (StoryDirector.FINDS):
## one of Corrin's grandad's message bottles, Pell's lucky shell, or a piece
## of pale driftwood for Dunstan. Picking it up is a conversation with no
## speaker (Conversations "find_<id>"), which sets found_<id>; then it's
## gone for good.

const GLASS := Color("#5fae7a")
const GLASS_DARK := Color("#3c7a58")
const WAX := Color("#c4523e")
const PAPER := Color("#f2e6c8")
const SHELL := Color("#f4e2c6")
const SPOTS := Color("#9a6440")
const WOOD := Color("#e6dccb")
const WOOD_DARK := Color("#b4a690")

## "bottle_shore", "bottle_pools", "bottle_strand", "pell_shell" or "driftwood".
var id := ""
var _time := 0.0


static func flag_for(find_id: String) -> String:
	return "found_" + find_id


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_to_group("interactable")


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active or GameState.has_flag(flag_for(id)):
		return
	if Conversations.talk("find_" + id).is_empty():
		return
	Audio.play_jingle("jingle_item")
	# Gone from the floor. The node stays until the room unloads (it isn't
	# placed again), so nothing holding it holds a freed object.
	remove_from_group("interactable")
	set_process(false)
	hide()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if id.begins_with("bottle"):
		# A green bottle on its side, wax-stoppered, a curl of paper inside.
		draw_rect(Rect2(-7, -6, 11, 6), Palette.OUTLINE)
		draw_rect(Rect2(3, -5, 4, 4), Palette.OUTLINE)
		draw_rect(Rect2(-6, -5, 9, 4), GLASS)
		draw_rect(Rect2(-6, -2, 9, 1), GLASS_DARK)
		draw_rect(Rect2(3, -4, 3, 2), GLASS)
		draw_rect(Rect2(6, -4, 2, 2), WAX)
		draw_rect(Rect2(-4, -4, 5, 2), PAPER)
	elif id == "pell_shell":
		# A spotted cowrie.
		draw_set_transform(Vector2(0, -3), 0.0, Vector2(1.0, 0.65))
		draw_circle(Vector2.ZERO, 5.0, Palette.OUTLINE)
		draw_circle(Vector2.ZERO, 4.0, SHELL)
		draw_set_transform(Vector2.ZERO)
		for p in [Vector2(-2, -4), Vector2(1, -2), Vector2(2, -4), Vector2(-1, -2)]:
			draw_rect(Rect2(p, Vector2(1, 1)), SPOTS)
		draw_line(Vector2(-3, -3), Vector2(3, -3), SPOTS)
	else:
		# A long bleached branch.
		draw_rect(Rect2(-10, -5, 20, 5), Palette.OUTLINE)
		draw_rect(Rect2(-9, -4, 18, 3), WOOD)
		draw_rect(Rect2(-9, -2, 18, 1), WOOD_DARK)
		draw_rect(Rect2(4, -7, 2, 3), Palette.OUTLINE)
		draw_rect(Rect2(4, -6, 1, 2), WOOD)
	# A glint every few seconds, so it catches the eye.
	if fmod(_time, 2.6) < 0.3:
		var c := Vector2(4, -9)
		draw_line(c + Vector2(-2, 0), c + Vector2(2, 0), Color.WHITE)
		draw_line(c + Vector2(0, -2), c + Vector2(0, 2), Color.WHITE)
