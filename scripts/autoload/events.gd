extends Node
## Global event bus. Systems emit and listen here so items, rooms, the HUD and
## saving never need direct references to each other.

## Wren's last breath bubble popped.
signal player_died
## The camera finished sliding into a new room.
signal room_entered(coord: Vector2i)
## Show a short line of text at the bottom of the screen. Pass a translation key.
signal toast(text_key: String)
## Open the dialogue box. speaker_key names who is talking ("" for none);
## lines are translation keys, shown one page each.
signal dialogue_requested(speaker_key: String, lines: PackedStringArray)
## The dialogue box closed.
signal dialogue_finished
## Wren stepped into a doorway: go to another room (a dungeon, a house).
signal door_entered(target_room: Vector2i, target_tile: Vector2i)
