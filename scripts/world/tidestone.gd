class_name Tidestone
extends StaticBody2D
## A standing stone that doubles as a checkpoint. Touching it wakes it and
## saves the game; dying brings Wren back here.

## Where Wren stands after loading, relative to the stone.
const CHECKPOINT_OFFSET := Vector2(0, 28)

var room_coord := Vector2i.ZERO
var awake := false


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 8), Vector2(0, -4)))
	var area := Area2D.new()
	area.name = "Touch"
	Layers.assign(area, 0, [Layers.PLAYER])
	area.monitorable = false
	area.add_child(Layers.circle_shape(22.0, Vector2(0, -4)))
	area.body_entered.connect(_on_body_entered)
	add_child(area)
	awake = bool(GameState.flags.get(flag_key(), false))


func flag_key() -> String:
	return "tidestone_%d_%d" % [room_coord.x, room_coord.y]


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	awake = true
	GameState.flags[flag_key()] = true
	GameState.set_checkpoint(room_coord, position + CHECKPOINT_OFFSET)
	if SaveManager.save_game():
		Events.toast.emit("TOAST_TIDESTONE_SAVED")
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-8, -2, 16, 4), Palette.SHADOW)
	draw_rect(Rect2(-7, -24, 14, 24), Palette.OUTLINE)
	draw_rect(Rect2(-6, -23, 12, 22), Palette.STONE)
	var rune := Palette.HUM if awake else Palette.OUTLINE
	draw_rect(Rect2(-2, -18, 4, 8), rune)
