class_name EchoStone
extends Node2D
## One of the eight echo stones round the sleeping Heart: a low pale stone
## with the ghost of a boss hanging over it in dream-light. Step onto it and
## Wren is carried into a remembered fight with that boss. A stone whose
## echo Wren has calmed burns brighter.

const RISE_TIME := 1.2
## The ghost over the stone: at most this many pixels across, hanging here.
const GHOST_SIZE := 22.0
const GHOST_Y := -18.0

var id := ""
var texture: Texture2D
var frames := 1
var foot := 16
## The tile Wren comes back to after the echo (just below the stone).
var return_tile := Vector2i.ZERO
## True for the first time the stones rise (they come up out of the floor).
var rising := false
var _ghost: Sprite2D
var _area: Area2D
var _armed := false
var _time := 0.0


func _ready() -> void:
	z_index = -1
	_ghost = Art.sprite(texture, frames, 1, foot)
	# Shown whole, centred over the stone and shrunk to fit.
	_ghost.centered = true
	_ghost.offset = Vector2.ZERO
	var size := Vector2(texture.get_width() / float(frames), texture.get_height())
	_ghost.scale = Vector2.ONE * minf(1.0, GHOST_SIZE / maxf(size.x, size.y))
	_ghost.position = Vector2(0, GHOST_Y)
	_ghost.z_index = 2
	_ghost.modulate = Color(0.55, 0.95, 0.9, 0.0 if rising else _ghost_alpha())
	add_child(_ghost)
	Art.set_flash(_ghost, 0.55)
	_area = Area2D.new()
	Layers.assign(_area, 0, [Layers.PLAYER])
	_area.monitorable = false
	_area.add_child(Layers.rect_shape(Vector2(12, 8), Vector2(0, -2)))
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(func(_b: Node2D) -> void: _armed = true)
	add_child(_area)
	if rising:
		scale = Vector2(1.0, 0.0)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, RISE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(_ghost, "modulate:a", _ghost_alpha(), RISE_TIME * 1.5)
	# Armed once Wren isn't standing on it (they may arrive back on top).
	await get_tree().physics_frame
	await get_tree().physics_frame
	if is_inside_tree() and _area.get_overlapping_bodies().filter(func(b: Node2D) -> bool: return b is Player).is_empty():
		_armed = true


func cleared() -> bool:
	return GameState.has_flag(EchoTrial.cleared_flag(id))


func _ghost_alpha() -> float:
	return 0.85 if cleared() else 0.55


func _physics_process(delta: float) -> void:
	_time += delta
	_ghost.position.y = GHOST_Y + sin(_time * 2.0 + position.x) * 1.5
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and _armed:
		activate()


## Carries Wren into this stone's echo.
func activate() -> void:
	if EchoTrial.boss != "" or Cutscene.active:
		return
	_armed = false
	Audio.play_sfx("echo_rise", global_position, 1.0)
	Feel.shake(1.5)
	EchoTrial.begin(id, return_tile)


func _draw() -> void:
	# The stone: a low pale slab with a ring of dream-light round its foot,
	# brighter once its echo is calmed.
	var glow := 0.5 + 0.5 * sin(_time * 3.0)
	var ring := Color(0.54, 0.94, 0.88, (0.35 if cleared() else 0.15) + 0.15 * glow)
	draw_arc(Vector2(0, 2), 9.0, 0.0, TAU, 24, ring, 2.0)
	draw_rect(Rect2(-6, -4, 12, 6), Color(0.86, 0.82, 0.74))
	draw_rect(Rect2(-6, 1, 12, 2), Color(0.62, 0.56, 0.5))
	draw_rect(Rect2(-5, -5, 10, 1), Color(0.95, 0.93, 0.88))
	if cleared():
		draw_rect(Rect2(-2, -3, 4, 3), Color(0.6, 1.0, 0.95, 0.6 + 0.3 * glow))
