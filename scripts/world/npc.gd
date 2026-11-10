class_name Npc
extends AnimatableBody2D
## Someone Wren can talk to. Walk up, face them and press Interact.
## What they say comes from Conversations, chosen by story flags.
## Rooms place people by letter (see LETTERS and Room).

## Room layout letter -> who stands there.
const LETTERS := {
	"h": "hessa",
	"1": "corrin",
	"2": "pell",
	"3": "marga",
	"4": "dunstan",
	"5": "nettle",
	"6": "agna",
}

## kind: sheet texture, frame count, the frame shown while Wren is near
## (Hessa lifts her ear trumpet), the frame shown while talking, and how far
## they wander left and right of where they stand (0 = they stay put).
const KINDS := {
	"hessa": {"texture": Art.HESSA, "frames": 3, "near": 2, "talk": 2, "wander": 0.0},
	"corrin": {"texture": Art.VILLAGER_CORRIN, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	"pell": {"texture": Art.VILLAGER_PELL, "frames": 5, "near": 0, "talk": 2, "wander": 28.0},
	"marga": {"texture": Art.VILLAGER_MARGA, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	"dunstan": {"texture": Art.VILLAGER_DUNSTAN, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	"nettle": {"texture": Art.VILLAGER_NETTLE, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	"agna": {"texture": Art.VILLAGER_AGNA, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	"marlo": {"texture": Art.VILLAGER_MARLO, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# Home from the Choir once the Tomb's bell has rung (StoryDirector).
	"tobin": {"texture": Art.VILLAGER_TOBIN, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# The Causeway End ferrywoman, once the Verge has risen (StoryDirector).
	"ide": {"texture": Art.VILLAGER_IDE, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# Liesl at the head of Drowned Lane (StoryDirector). Her "breathe" frame
	# is the broom swung out, so her idling is sweeping.
	"liesl": {"texture": Art.VILLAGER_LIESL, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# Wick, Gloamfen's lamplighter child, at Fenmouth (StoryDirector).
	"wick": {"texture": Art.VILLAGER_WICK, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# Gully the salvager, dozing by the figurehead on Wreck Strand
	# (StoryDirector). He wakes when Wren comes near.
	"gully": {"texture": Art.VILLAGER_GULLY, "frames": 3, "near": 2, "talk": 2, "wander": 0.0},
	# Captain Sorrel, the retired kite-post captain at Gullwatch Steps
	# (StoryDirector). Her "breathe" frame is her scarf lifting in the wind.
	"sorrel": {"texture": Art.VILLAGER_SORREL, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# Ottilie the ice-fisher at Still Cove (StoryDirector).
	"ottilie": {"texture": Art.VILLAGER_OTTILIE, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# Sister Lowe on Lullaby Point after the ending (StoryDirector): no
	# orders left to give, so she talks standing still.
	"lowe": {"texture": Art.VILLAGER_LOWE, "frames": 3, "near": 0, "talk": 0, "wander": 0.0},
	# Murmur at Fenmouth after leaving the Choir, and Mother Dace by the last
	# mural after the ending (StoryDirector).
	"murmur": {"texture": Art.VILLAGER_MURMUR, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	"dace": {"texture": Art.VILLAGER_DACE, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
	# Coralie the beachcomber on Saltmarrow Shore, by her chime (StoryDirector).
	"coralie": {"texture": Art.VILLAGER_CORALIE, "frames": 3, "near": 0, "talk": 2, "wander": 0.0},
}
## Sheet columns shared by everyone: idle, breathe, then talk/listen, and
## for walkers two walk frames.
const FRAME_IDLE := 0
const FRAME_BREATHE := 1
const FRAME_WALK_A := 3
const FRAME_WALK_B := 4
const BREATHE_TIME := 0.8
const WALK_SPEED := 14.0
const WALK_FRAME_TIME := 0.18
## Walkers stop for a while at each end of their path.
const WANDER_PAUSE := Vector2(1.2, 3.0)
## Wren this close makes them turn and listen, and shows the talk mark.
const NOTICE_RANGE := 44.0
const TALK_RANGE := 26.0

var kind := "hessa"
var _spec: Dictionary
var _sprite: Sprite2D
var _mark: Node2D
var _time := 0.0
var _player_near := false
var _can_talk := false
var _talking := false
var _home := Vector2.ZERO
var _walk_dir := 1.0
var _pause := 0.0
var _rng := RandomNumberGenerator.new()


func _init(npc_kind: String = "hessa") -> void:
	kind = npc_kind


func _ready() -> void:
	_spec = KINDS[kind]
	add_to_group("interactable")
	add_to_group("npc")
	# Walkers move by position; this keeps their collision in step.
	sync_to_physics = false
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 7), Vector2(0, -3.5)))
	add_child(Art.shadow())
	_sprite = Art.sprite(_spec["texture"], _spec["frames"], 1, 22)
	add_child(_sprite)
	_mark = Node2D.new()
	_mark.position = Vector2(0, -30)
	_mark.draw.connect(_draw_mark)
	add_child(_mark)
	_home = position
	_rng.seed = hash(kind)
	_pause = _rng.randf_range(WANDER_PAUSE.x, WANDER_PAUSE.y)
	Events.dialogue_finished.connect(func() -> void: _talking = false)


func _process(delta: float) -> void:
	_time += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var distance := INF if player == null else player.global_position.distance_to(global_position)
	_player_near = distance < NOTICE_RANGE
	_can_talk = distance < TALK_RANGE
	if _talking:
		_sprite.frame = _spec["talk"]
	elif _player_near:
		_sprite.frame = _spec["near"]
		_sprite.flip_h = player.global_position.x < global_position.x - 4.0
	elif not _wander(delta):
		_sprite.frame = FRAME_BREATHE if int(_time / BREATHE_TIME) % 2 == 1 else FRAME_IDLE
	_mark.visible = _can_talk and not DialogueBox.is_open and not Cutscene.active
	_mark.position.y = -30 + (1 if int(_time * 2.0) % 2 == 0 else 0)
	_mark.queue_redraw()


## Walkers stroll back and forth around home. Returns true while walking.
func _wander(delta: float) -> bool:
	var reach: float = _spec["wander"]
	if reach <= 0.0:
		return false
	if _pause > 0.0:
		_pause -= delta
		return false
	position.x += _walk_dir * WALK_SPEED * delta
	_sprite.flip_h = _walk_dir < 0.0
	_sprite.frame = FRAME_WALK_A if int(_time / WALK_FRAME_TIME) % 2 == 0 else FRAME_WALK_B
	if absf(position.x - _home.x) >= reach:
		position.x = _home.x + reach * _walk_dir
		_walk_dir = -_walk_dir
		_pause = _rng.randf_range(WANDER_PAUSE.x, WANDER_PAUSE.y)
	return true


## The pages the next talk would show.
func current_pages() -> Array:
	return Conversations.pages(kind, Conversations.branch_for(kind))


func interact() -> void:
	if Conversations.talk(kind).is_empty():
		return
	_talking = true
	_sprite.frame = _spec["talk"]
	# The game pauses while the box is open, so hide the talk mark now.
	_mark.visible = false


## A little speech bubble with three dots.
func _draw_mark() -> void:
	var rect := Rect2(-6, -6, 12, 8)
	_mark.draw_rect(rect.grow(1), Palette.OUTLINE)
	_mark.draw_rect(rect, Palette.MENU_ACTIVE)
	_mark.draw_rect(Rect2(-1, 2, 2, 2), Palette.MENU_ACTIVE)
	_mark.draw_rect(Rect2(-1, 4, 1, 1), Palette.OUTLINE)
	for x in [-4, -1, 2]:
		_mark.draw_rect(Rect2(x, -3, 2, 2), Palette.OUTLINE)
