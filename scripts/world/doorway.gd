class_name Doorway
extends Area2D
## An opening into another place (a dungeon, a house). Stepping into it
## fades to the target room. The room sets where it leads.

var target_room := Vector2i.ZERO
var target_tile := Vector2i.ZERO


func _ready() -> void:
	Layers.assign(self, 0, [Layers.PLAYER])
	monitorable = false
	add_child(Layers.rect_shape(Vector2(14, 12), Vector2(0, -4)))
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# A story scene never walks Wren out of the room: a door that opens
	# under them mid-scene (a boss's way out) waits until they step on it.
	if body is Player and not body.in_cutscene:
		Events.door_entered.emit(target_room, target_tile)
