class_name QuestFind
extends StaticBody2D
## A small thing lying about for a villager's errand (StoryDirector.FINDS):
## one of Corrin's grandad's message bottles, Pell's lucky shell, a piece
## of pale driftwood for Dunstan, one of the Choir's chimes for Bram, an
## oyster with a pearl in it for Marlo, the nameboard off Ide's boat, a
## ship's lantern for Gully, a hardy plant for Lowe's garden, a page of
## Hessa's lost logbook, or a clue on the trail of Pell's night bell-ringer
## (and the seal pup at the end of it). Picking it up is a conversation with no
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
const BRONZE := Color("#5f9e86")
const BRONZE_DARK := Color("#3f6f5e")
const CORD := Color("#a08a64")
const OYSTER := Color("#8a8478")
const OYSTER_LIGHT := Color("#b8b0a0")
const PEARL := Color("#f4f0ea")
const BRASS := Color("#b08a3c")
const LANTERN_GLASS := Color("#7fd0a0")
const THISTLE := Color("#7ea4e0")
const MOSS := Color("#d0603a")
const MOSS_GLOW := Color("#f0a050")
const LEAF := Color("#4f8a4a")
const BULB := Color("#e8dcc0")
const BOARD := Color("#4a78a8")
const BOARD_DARK := Color("#34587e")

## A StoryDirector.FINDS key: "bottle_*", "pell_shell", "driftwood",
## "chime_*", "pearl_*", "nameboard", "lantern_*", "seed_*", "log_*",
## "seal_*", "gran_*" or "hymn_*".
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
	elif id.begins_with("chime"):
		# A salt-green bronze tube lying on its frayed cord.
		draw_line(Vector2(-9, -2), Vector2(-4, -3), CORD)
		draw_rect(Rect2(-4, -6, 12, 5), Palette.OUTLINE)
		draw_rect(Rect2(-3, -5, 10, 3), BRONZE)
		draw_rect(Rect2(-3, -3, 10, 1), BRONZE_DARK)
		draw_rect(Rect2(-1, -5, 1, 3), BRONZE_DARK)
	elif id.begins_with("pearl"):
		# A rough oyster, gaping just enough to show the pearl.
		draw_set_transform(Vector2(0, -3), 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, 6.0, Palette.OUTLINE)
		draw_circle(Vector2.ZERO, 5.0, OYSTER)
		draw_set_transform(Vector2.ZERO)
		draw_line(Vector2(-4, -4), Vector2(4, -4), OYSTER_LIGHT)
		draw_line(Vector2(-3, -2), Vector2(3, -2), Palette.OUTLINE)
		draw_rect(Rect2(-1, -4, 2, 2), PEARL)
	elif id.begins_with("lantern"):
		# An upright ship's lantern: brass cage, green glass, handle on top.
		draw_rect(Rect2(-5, -10, 10, 10), Palette.OUTLINE)
		draw_rect(Rect2(-4, -9, 8, 8), BRASS)
		draw_rect(Rect2(-3, -8, 6, 6), LANTERN_GLASS)
		draw_rect(Rect2(-1, -8, 2, 6), BRASS)
		draw_rect(Rect2(-2, -12, 4, 2), Palette.OUTLINE)
	elif id == "seed_frost":
		# A blue frost thistle.
		draw_line(Vector2(0, 0), Vector2(0, -6), LEAF)
		draw_circle(Vector2(0, -8), 3.0, Palette.OUTLINE)
		draw_circle(Vector2(0, -8), 2.0, THISTLE)
		for d in [Vector2(-3, -10), Vector2(3, -10), Vector2(0, -12)]:
			draw_line(Vector2(0, -8), d, THISTLE)
	elif id == "seed_ember":
		# A tuft of ember moss, faintly glowing.
		draw_rect(Rect2(-6, -5, 12, 5), Palette.OUTLINE)
		draw_rect(Rect2(-5, -4, 10, 3), MOSS)
		if fmod(_time, 1.2) < 0.6:
			draw_rect(Rect2(-2, -4, 3, 1), MOSS_GLOW)
	elif id == "seed_fen":
		# A pale lily bulb with two green shoots.
		draw_circle(Vector2(0, -3), 4.0, Palette.OUTLINE)
		draw_circle(Vector2(0, -3), 3.0, BULB)
		draw_line(Vector2(-1, -6), Vector2(-3, -11), LEAF)
		draw_line(Vector2(1, -6), Vector2(2, -10), LEAF)
	elif id.begins_with("hymn_"):
		# A hymn page: staves ruled across it, a note or two still showing.
		draw_rect(Rect2(-6, -9, 12, 9), Palette.OUTLINE)
		draw_rect(Rect2(-5, -8, 10, 7), PAPER)
		for y in [-7, -4]:
			draw_line(Vector2(-4, y), Vector2(4, y), Color(0.35, 0.3, 0.3, 0.6))
			draw_line(Vector2(-4, y + 1), Vector2(4, y + 1), Color(0.35, 0.3, 0.3, 0.6))
		for p in [Vector2(-3, -8), Vector2(0, -7), Vector2(2, -4), Vector2(-2, -5)]:
			draw_rect(Rect2(p, Vector2(1, 1)), Palette.OUTLINE)
	elif id.begins_with("log_"):
		# A loose logbook page, curled at one corner, close-written.
		draw_rect(Rect2(-6, -9, 12, 9), Palette.OUTLINE)
		draw_rect(Rect2(-5, -8, 10, 7), PAPER)
		for y in [-7, -5, -3]:
			draw_line(Vector2(-4, y), Vector2(3, y), Color(0.3, 0.32, 0.45, 0.8))
		draw_rect(Rect2(3, -8, 2, 2), Color(0.85, 0.78, 0.6))
	elif id == "seal_track":
		# Small flipper prints in wet sand, a drag mark between them.
		draw_rect(Rect2(-9, -2, 18, 1), Color(0.55, 0.45, 0.32, 0.6))
		for x in [-8, -3, 2, 7]:
			draw_rect(Rect2(x, -5, 2, 2), Color(0.45, 0.36, 0.25))
			draw_rect(Rect2(x + 1, 0, 2, 2), Color(0.45, 0.36, 0.25))
	elif id == "seal_bones":
		# Fish bones picked clean: a spine and ribs, a head.
		for i in 2:
			var o := Vector2(-6 + i * 8, -3 - i * 2)
			draw_line(o, o + Vector2(7, 0), PAPER)
			for r in 3:
				draw_line(o + Vector2(2 + r * 2, -2), o + Vector2(2 + r * 2, 2), PAPER)
			draw_rect(Rect2(o + Vector2(7, -1), Vector2(2, 3)), PAPER)
	elif id == "seal_net":
		# A torn scrap of brown net.
		draw_rect(Rect2(-7, -8, 14, 8), Palette.OUTLINE)
		for x in range(-6, 7, 3):
			draw_line(Vector2(x, -7), Vector2(x, -1), CORD)
		for y in range(-7, 0, 3):
			draw_line(Vector2(-6, y), Vector2(6, y), CORD)
		draw_rect(Rect2(3, -8, 4, 3), Palette.OUTLINE)
	elif id == "seal_pup":
		SealPup.draw_pup(self, _time, true)
	elif id == "gran_candle":
		# A pewter candlestick on its side, green with salt.
		draw_rect(Rect2(-7, -5, 14, 5), Palette.OUTLINE)
		draw_rect(Rect2(-6, -4, 3, 3), GranTable.PEWTER_DARK)
		draw_rect(Rect2(-3, -3, 8, 1), GranTable.PEWTER)
		draw_rect(Rect2(2, -3, 2, 1), GLASS_DARK)
		draw_rect(Rect2(5, -4, 2, 3), GranTable.WAX)
	elif id == "gran_salt":
		# A little pewter fish, its back pierced with holes.
		draw_rect(Rect2(-6, -6, 10, 5), Palette.OUTLINE)
		draw_rect(Rect2(4, -7, 3, 7), Palette.OUTLINE)
		draw_rect(Rect2(-5, -5, 8, 3), GranTable.PEWTER)
		draw_rect(Rect2(5, -6, 1, 5), GranTable.PEWTER_DARK)
		for x in [-3, -1, 1]:
			draw_rect(Rect2(x, -5, 1, 1), GranTable.PEWTER_DARK)
		draw_rect(Rect2(-4, -4, 1, 1), Palette.OUTLINE)
	elif id == "nameboard":
		# A long blue board with a few salt-eaten white letters.
		draw_rect(Rect2(-11, -7, 22, 7), Palette.OUTLINE)
		draw_rect(Rect2(-10, -6, 20, 5), BOARD)
		draw_rect(Rect2(-10, -2, 20, 1), BOARD_DARK)
		for x in [-8, -4, -1, 3, 7]:
			draw_rect(Rect2(x, -5, 2, 2), PAPER)
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
