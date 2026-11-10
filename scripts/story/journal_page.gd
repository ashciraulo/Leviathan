class_name JournalPage
extends StaticBody2D
## A page of young Hessa's and Vael's journal, frozen into a block of ice in
## the Hollow Glacier (see StoryDirector.JOURNAL_PAGES). Wren reads it where
## it stands. The last page, in the boss's room, brings the vision
## (StoryDirector.the_frozen_journal).

## page number (1-6): who wrote what. [speaker, key] or a narration key.
const PAGES := {
	1: [["young_hessa", "JOURNAL_1"]],
	2: [["young_vael", "JOURNAL_2"]],
	3: [["young_hessa", "JOURNAL_3"]],
	4: [["young_vael", "JOURNAL_4"]],
	5: [["young_hessa", "JOURNAL_5"]],
	6: [["young_vael", "JOURNAL_6A"], ["young_vael", "JOURNAL_6B"], ["", "JOURNAL_6_LATER"], ["young_hessa", "JOURNAL_6C"]],
}
const LAST := 6

var page := 1
## Off while it's still rising out of the ice: it can't be read yet.
var readable := true
var _sprite: Sprite2D
var _time := 0.0


static func flag_for(number: int) -> String:
	return "read_journal_%d" % number


## The pages to show, as the dialogue box takes them.
static func pages_for(number: int) -> Array:
	var out: Array = []
	for entry: Array in PAGES[number]:
		out.append_array(Conversations.pages(entry[0], {"lines": [[entry[0], entry[1]]]}))
	return out


func _init(number: int = 1) -> void:
	page = number


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("journal_page")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 8), Vector2(0, -4)))
	add_child(Art.shadow())
	_sprite = Art.sprite(Art.JOURNAL_ICE, 1, 1, 18)
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	# Unread pages catch the light now and then.
	var unread := not GameState.has_flag(flag_for(page))
	var glint := unread and fmod(_time, 2.6) < 0.25
	_sprite.modulate = Color(1.35, 1.4, 1.5) if glint else Color.WHITE


func interact() -> void:
	if not readable or DialogueBox.is_open or Cutscene.active:
		return
	GameState.set_flag(flag_for(page))
	Audio.play_sfx("ui_open")
	if page == LAST and not GameState.has_flag(StoryDirector.JOURNAL_FLAG):
		var director := get_tree().get_first_node_in_group("story_director")
		if director:
			director.the_frozen_journal(self)
			return
	Events.conversation_requested.emit(pages_for(page))
