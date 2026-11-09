extends Node
## Global event bus. Systems emit and listen here so items, rooms, the HUD and
## saving never need direct references to each other.

## Wren's last breath bubble popped.
signal player_died
## The camera finished sliding into a new room.
signal room_entered(coord: Vector2i)
## Show a short line of text at the bottom of the screen. Pass a translation key.
signal toast(text_key: String)
