extends Node
## Global event bus. Systems emit and listen here so items, rooms, the HUD and
## saving never need direct references to each other.

## Wren's last breath bubble popped.
signal player_died
## The game scene built the world (new game, load, or after dying).
signal game_started
## The camera finished sliding into a new room.
signal room_entered(coord: Vector2i)
## Show a short line of text at the bottom of the screen. Pass a translation key.
signal toast(text_key: String)
## Open the dialogue box. speaker_key names who is talking ("" for none);
## lines are translation keys, shown one page each.
signal dialogue_requested(speaker_key: String, lines: PackedStringArray)
## Open the dialogue box on a conversation: an Array of page Dictionaries
## (see Conversations.pages). Each page can have its own speaker and portrait.
signal conversation_requested(pages: Array)
## The dialogue box closed.
signal dialogue_finished
## A story flag changed (see GameState.set_flag).
signal flag_changed(flag: String, value: Variant)
## Wren stepped into a doorway: go to another room (a dungeon, a house).
signal door_entered(target_room: Vector2i, target_tile: Vector2i)
## Wren got an item (GameState.give_item). count is how many were added.
signal item_gained(id: String, count: int)
## The map asked to fly to a woken Tidestone in that room.
signal fast_travel_requested(coord: Vector2i)
## The game was saved (the HUD shows a small spinning shell).
signal game_saved
## A sound with a caption played (only sent when captions are on). side is
## where it came from on screen: -1 left, 0 middle or flat, 1 right.
signal caption(text_key: String, side: int)
