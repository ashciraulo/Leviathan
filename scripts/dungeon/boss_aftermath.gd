class_name BossAftermath
extends Node2D
## What's left in the boss room once the Matriarch is beaten: the Tidebell
## she was guarding, and a shaft of daylight that leads back outside
## (to the room's door_to, arriving on door_spawn).

## The ceiling tile the way out drops from.
const EXIT_TILE := Vector2i(11, 1)

var room: Room
var boss_spot := Vector2.ZERO
## True right after the fight (the bell rises; otherwise it's already there).
var fresh := false


func _ready() -> void:
	position = Vector2.ZERO
	var bell := Tidebell.new()
	bell.position = boss_spot
	bell.rise = fresh
	room.add_child.call_deferred(bell)
	var door := Doorway.new()
	door.target_room = room.door_to
	door.target_tile = room.door_spawn
	door.position = Vector2(EXIT_TILE.x * Room.TILE + Room.TILE / 2.0, EXIT_TILE.y * Room.TILE + 12)
	room.add_child.call_deferred(door)
	z_index = -9
	if fresh:
		Events.toast.emit("TOAST_BOSS_DOWN")


func _draw() -> void:
	# Daylight falling through a hole in the deck above.
	var x := EXIT_TILE.x * Room.TILE
	var y := EXIT_TILE.y * Room.TILE
	draw_texture_rect_region(Art.WORLD_TILES, Rect2(x, y, Room.TILE, Room.TILE), TileAtlas.region("exit_glow"))
	for i in 4:
		draw_rect(Rect2(x - 6 + i * 3, y + Room.TILE, 22 - i * 6, 24 + i * 6), Color(1.0, 0.92, 0.66, 0.07))
