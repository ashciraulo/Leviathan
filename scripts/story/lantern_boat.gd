class_name LanternBoat
extends Prop
## The little lantern-boat the great ebb bares on the Ebb Shelf: the room's
## wreck prop, swapped for this one by StoryDirector so it can be searched.
## Searching it is a conversation with no speaker (Conversations
## "lantern_boat"): once Gully has told Wren about the storm, there is a
## child's cap under the bench.


func _init() -> void:
	super("W")


func _ready() -> void:
	super()
	add_to_group("interactable")


func interact() -> void:
	if DialogueBox.is_open or Cutscene.active:
		return
	Conversations.talk("lantern_boat")
