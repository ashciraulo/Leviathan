class_name FrostArrow
extends Node2D
## A frost arrow from the Frostfang Bow. It flies straight until it meets:
##   * water: it sinks and the water freezes, the one tile, or a whole
##     small pool (Room.freeze), into ice Wren can walk on
##   * anything with arrow_hit() (ice eyes, Rimeback's eyes): that decides
##   * any other enemy: a hit
##   * a wall: it shatters
## It flies over gaps and lava.

const SPEED := 260.0
const RANGE := 220.0
const DAMAGE := 1

var direction := Vector2.RIGHT
var _travelled := 0.0
## What it ended on (for tests): "water", "wall", "target", "enemy", "spent".
var ended := ""


func _ready() -> void:
	z_index = 2


func _physics_process(delta: float) -> void:
	var step := direction * SPEED * delta
	var from := global_position
	var to := from + step
	_travelled += step.length()
	# Walls, ice eyes and the like (bodies), and enemies (hurtboxes).
	var query := PhysicsRayQueryParameters2D.create(from, to, (1 << (Layers.WORLD - 1)) | (1 << (Layers.ENEMY_HURTBOX - 1)))
	query.collide_with_areas = true
	# Loosed right up against a wall, it still breaks on it.
	query.hit_from_inside = true
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		query.exclude = [player.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit["position"]
		_strike(hit["collider"])
		return
	# Water: checked where the arrow's shadow falls, under it.
	var room := Room.under(get_tree(), to)
	if room:
		var local := to - room.global_position + Vector2(0, 7)
		var tile := Vector2i(floori(local.x / Room.TILE), floori(local.y / Room.TILE))
		if room.tile_at(tile.x, tile.y) == "~" and not room.is_lava():
			global_position = to
			room.freeze(tile)
			Audio.play_sfx("ice_freeze", to)
			Feel.shake(0.6)
			_end("water")
			return
	global_position = to
	if _travelled >= RANGE:
		_end("spent")


func _strike(collider: Object) -> void:
	var target := _owner_of(collider)
	if target and target.has_method("arrow_hit"):
		target.arrow_hit(direction)
		_end("target")
	elif target is Enemy:
		if (target as Enemy).take_hit(DAMAGE, direction) == Enemy.HitResult.HIT:
			GameState.add_resonance(GameState.RESONANCE_PER_HIT)
		_end("enemy")
	else:
		Audio.play_sfx("ice_shatter", global_position)
		_end("wall")


## Hurtboxes belong to the thing they're on.
func _owner_of(collider: Object) -> Node:
	var node := collider as Node
	if node == null:
		return null
	if node.has_method("arrow_hit") or node is Enemy:
		return node
	var parent := node.get_parent()
	if parent and (parent.has_method("arrow_hit") or parent is Enemy):
		return parent
	return node


func _end(how: String) -> void:
	ended = how
	set_physics_process(false)
	# A puff of frost where it stops.
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE)
	draw_texture(GlacierSprites.FROST_ARROW, Vector2(-10, -2.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
