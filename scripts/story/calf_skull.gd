class_name CalfSkull
extends Prop
## The Calf's Rest, south of Gloamfen (StoryDirector): the small skull of
## the Old One's lost calf, sunk in the fen. Looking at it is a
## conversation with no speaker (Conversations "calf_skull"); after the
## ending, once Murmur has heard of it, the grey robe lies folded on it.


func _init() -> void:
	super("calf_skull")


var _robe: Node2D


func _ready() -> void:
	super()
	add_to_group("interactable")
	# Murmur's grey robe, folded on the crown.
	_robe = Node2D.new()
	_robe.draw.connect(_draw_robe)
	add_child(_robe)
	set_process(true)


func _process(delta: float) -> void:
	super(delta)
	_robe.visible = GameState.has_flag("murmur_left_robe")


func _draw_robe() -> void:
	var at := Vector2(-1, -23)
	_robe.draw_rect(Rect2(at - Vector2(1, 1), Vector2(14, 6)), Palette.OUTLINE)
	_robe.draw_rect(Rect2(at, Vector2(12, 4)), Color("#9aa2bc"))
	_robe.draw_rect(Rect2(at, Vector2(12, 1)), Color("#c4cad8"))
	_robe.draw_rect(Rect2(at + Vector2(0, 2), Vector2(12, 1)), Color("#6e7690"))


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active:
		return
	var first := not GameState.has_flag("found_calf_rest")
	Conversations.talk("calf_skull")
	if first:
		Audio.play_sfx("hum", global_position, 0.6)
