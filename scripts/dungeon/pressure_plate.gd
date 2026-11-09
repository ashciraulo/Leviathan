class_name PressurePlate
extends Node2D
## A brass plate set into the deck. It stays down while Wren or a crate is on
## it. The room's puzzle watches it.

signal changed

var tile := Vector2i.ZERO
var pressed := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("plates")
	z_index = -9
	_sprite = Sprite2D.new()
	_sprite.texture = HullSprites.PLATE
	_sprite.hframes = 2
	_sprite.centered = false
	_sprite.position = Vector2(-8, -12)
	add_child(_sprite)


func _physics_process(_delta: float) -> void:
	var now := _weighed_down()
	if now != pressed:
		pressed = now
		_sprite.frame = 1 if pressed else 0
		if pressed:
			Feel.shake(0.5)
		changed.emit()


func _weighed_down() -> bool:
	var room := get_parent() as Node2D
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and not player.airborne and _tile_of(player.global_position - room.global_position) == tile:
		return true
	for crate in get_tree().get_nodes_in_group("crates"):
		if (crate as Crate).get_parent() == room and _tile_of((crate as Node2D).position) == tile:
			return true
	return false


static func _tile_of(local: Vector2) -> Vector2i:
	return Vector2i(floori(local.x / Room.TILE), floori((local.y - 4.0) / Room.TILE))
