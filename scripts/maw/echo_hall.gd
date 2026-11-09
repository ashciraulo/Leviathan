class_name EchoHall
extends Node2D
## After the end, the Heart's chamber keeps eight echo stones, one for each
## boss Wren calmed on the way (EchoTrial). The first time Wren is here
## after the Old One sleeps, the stones rise out of the floor one after
## another, each with a note, and the chamber hums: that's the only sign.

## Where the stones stand (tiles), a ring round the sleeping Heart.
const SPOTS := [
	Vector2i(4, 6), Vector2i(19, 6), Vector2i(4, 9), Vector2i(19, 9),
	Vector2i(8, 8), Vector2i(15, 8), Vector2i(8, 11), Vector2i(15, 11),
]
const RISE_GAP := 0.35

var _room: Room


func _ready() -> void:
	_room = get_parent() as Room
	var first := not GameState.has_flag(EchoTrial.WOKEN_FLAG)
	if first:
		GameState.set_flag(EchoTrial.WOKEN_FLAG)
		Audio.play_sfx("old_one_hum")
		Feel.shake(2.0)
		await get_tree().create_timer(1.0, false).timeout
		if not is_inside_tree():
			return
	var i := 0
	for id: String in EchoTrial.BOSSES:
		var stone := EchoStone.new()
		stone.id = id
		var look := _look(id)
		stone.texture = look[0]
		stone.frames = look[1]
		stone.foot = look[2]
		var tile: Vector2i = SPOTS[i]
		stone.position = Vector2(tile.x * Room.TILE + Room.TILE / 2.0, tile.y * Room.TILE + Room.TILE - 4)
		stone.return_tile = tile + Vector2i(0, 1)
		stone.rising = first
		get_parent().add_child(stone)
		if first:
			Audio.play_sfx("echo_rise", stone.global_position, 0.8 + i * 0.08)
			await get_tree().create_timer(RISE_GAP, false).timeout
			if not is_inside_tree():
				return
		i += 1


## [texture, frames, foot row] of each boss, as the Heart's echoes use.
static func _look(id: String) -> Array:
	if id == "vael":
		return [Art.VILLAGER_VAEL, 3, 22]
	for stage: Array in DreamingHeart.STAGES:
		if stage[0] == id:
			return [stage[1], stage[2], stage[3]]
	return [Art.VILLAGER_VAEL, 3, 22]
