class_name Crate
extends CharacterBody2D
## A heavy cargo crate. Lean on it for a moment to shove it one tile (on ice
## it slides on until something stops it); hook it
## to drag it back towards Wren. Weighs down pressure plates. Crates go back
## where they started when Wren leaves the room.

const PUSH_DELAY := 0.3
const SLIDE_TIME := 0.22

var _push_time := 0.0
var _sliding := false
## The tile centre the crate is being dragged towards, while hooked.
var _pull_to := Vector2.INF


func _ready() -> void:
	add_to_group("crates")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	Layers.assign(self, Layers.WORLD, [Layers.WORLD, Layers.WATER, Layers.PIT])
	add_child(Layers.rect_shape(Vector2(14, 13), Vector2(0, -5.5)))
	add_child(Art.shadow(true))
	add_child(Art.sprite(HullSprites.CRATE, 1, 1, 17))


func _physics_process(delta: float) -> void:
	if _sliding:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	# Velocity is zero when Wren walks into the crate head on: use the stick.
	var wants := player._input_direction() if player else Vector2.ZERO
	if player == null or player.state != Player.State.MOVE or wants == Vector2.ZERO:
		_push_time = 0.0
		return
	var dir := Enemy.cardinal(wants)
	var rel := global_position - player.global_position
	var along := rel.dot(dir)
	var across := absf(rel.dot(Vector2(dir.y, dir.x)))
	if along > 0.0 and along < 17.0 and across < 9.0:
		_push_time += delta
		if _push_time >= PUSH_DELAY:
			_push_time = 0.0
			_slide(dir)
	else:
		_push_time = 0.0


func _slide(dir: Vector2) -> void:
	var step := dir * Room.TILE
	if test_move(global_transform, step) or _someone_in(step):
		Feel.shake(0.4)
		return
	_sliding = true
	var on_ice := _on_ice()
	Audio.play_sfx("ice_slide" if on_ice else "block_push", global_position)
	var tween := create_tween()
	# On ice it glides on, quicker, until something stops it.
	tween.tween_property(self, "position", position + step, SLIDE_TIME * (0.5 if on_ice else 1.0))
	tween.tween_callback(func() -> void:
		_sliding = false
		if _on_ice() and not test_move(global_transform, step) and not _someone_in(step):
			_slide(dir))


## True when Wren or an enemy stands in the tile the crate would move into.
func _someone_in(step: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 11)
	query.shape = box
	query.transform = Transform2D(0.0, global_position + step + Vector2(0, -5.5))
	query.collision_mask = (1 << (Layers.PLAYER - 1)) | (1 << (Layers.ENEMY - 1))
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## True when the crate stands on ice (I).
func _on_ice() -> bool:
	var room := get_parent() as Room
	if room == null:
		return false
	var at := position + Vector2(0, -4)
	return room.tile_at(floori(at.x / Room.TILE), floori(at.y / Room.TILE)) == "I"


## The drag was cut short (Wren was hit): settle on the nearer tile.
func stop_pull() -> void:
	if _pull_to == Vector2.INF:
		return
	var from := _pull_to - (_pull_to - position).normalized() * Room.TILE
	position = _pull_to if position.distance_to(_pull_to) < position.distance_to(from) else from
	_pull_to = Vector2.INF


## Called by the Tide Hook every frame while it drags the crate. Moves
## tile by tile towards `target` (global). True when the crate has come to
## rest: next to Wren, or against something.
func pull_towards(target: Vector2, step: float) -> bool:
	if _pull_to == Vector2.INF:
		var dir := Enemy.cardinal(target - global_position)
		if global_position.distance_to(target) < 22.0 or test_move(global_transform, dir * Room.TILE):
			return true
		_pull_to = position + dir * Room.TILE
	var to := _pull_to - position
	if to.length() <= step:
		position = _pull_to
		_pull_to = Vector2.INF
		return global_position.distance_to(target) < 22.0
	position += to.normalized() * step
	return false
