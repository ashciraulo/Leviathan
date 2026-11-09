class_name BossAftermath
extends Node2D
## What's left in a boss room once the boss is beaten: the Tidebell it was
## guarding (the room's dungeon says which), and a shaft of daylight that
## leads back outside (to the room's door_to, arriving on door_spawn).

## The ceiling tile the way out drops from.
const EXIT_TILE := Vector2i(11, 1)

var room: Room
var boss_spot := Vector2.ZERO
## True right after the fight (the bell rises; otherwise it's already there).
var fresh := false


func _ready() -> void:
	# In a remembered fight (EchoTrial) there's no bell and no way out:
	# Wren is carried back to the Heart.
	if EchoTrial.here(room):
		queue_free()
		return
	position = Vector2.ZERO
	var bell := Tidebell.new()
	bell.position = boss_spot
	bell.rise = fresh
	if Tidebell.BELLS.has(room.dungeon):
		bell.bell = room.dungeon
	room.add_child.call_deferred(bell)
	var door := Doorway.new()
	door.target_room = room.door_to
	door.target_tile = room.door_spawn
	door.position = Vector2(EXIT_TILE.x * Room.TILE + Room.TILE / 2.0, EXIT_TILE.y * Room.TILE + 12)
	room.add_child.call_deferred(door)
	z_index = -9


func _draw() -> void:
	# Daylight falling through a hole in the deck above.
	var x := EXIT_TILE.x * Room.TILE
	var y := EXIT_TILE.y * Room.TILE
	draw_texture_rect_region(Art.WORLD_TILES, Rect2(x, y, Room.TILE, Room.TILE), TileAtlas.region("exit_glow"))
	for i in 4:
		draw_rect(Rect2(x - 6 + i * 3, y + Room.TILE, 22 - i * 6, 24 + i * 6), Color(1.0, 0.92, 0.66, 0.07))
