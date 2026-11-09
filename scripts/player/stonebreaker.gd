class_name Stonebreaker
extends Node2D
## The Stonebreaker Mallet, the Kiln's tool: Wren heaves it up and brings it
## down on the tile in front of her. What it lands on decides what happens:
##   * anything with mallet_hit() (cracked boulders, pegs, a Clinker's shell,
##     the Slagwyrm's set crust): that thing decides
##   * any other enemy: a heavy blow
##   * anything else: a dull thud and a shower of grit
##
## Lives as a child of Wren while in use, and frees itself when done.

const WINDUP := 0.16
const RECOVER := 0.24
const DAMAGE := 2
## Where the head lands, relative to Wren's feet, along her facing.
const REACH := 13.0
const IMPACT_SIZE := Vector2(18, 16)

var direction := Vector2.DOWN
var _player: Player
var _time := 0.0
var _struck := false
## What the blow landed on (for tests): the nodes it reached.
var hit_nodes: Array = []


func _ready() -> void:
	_player = get_parent() as Player
	direction = _player.facing
	z_index = 1


## The centre of the blow, in global coordinates.
func impact_point() -> Vector2:
	return _player.global_position + Vector2(0, -6) + direction * REACH


func _physics_process(delta: float) -> void:
	if _player == null or not _player.is_using_item():
		queue_free()
		return
	_time += delta
	if not _struck and _time >= WINDUP:
		_struck = true
		_strike()
	if _time >= WINDUP + RECOVER:
		_player.end_item()
		queue_free()
	queue_redraw()


func _strike() -> void:
	var shape := RectangleShape2D.new()
	shape.size = IMPACT_SIZE
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, impact_point())
	query.collision_mask = (1 << (Layers.WORLD - 1)) | (1 << (Layers.ENEMY_HURTBOX - 1))
	query.collide_with_areas = true
	query.exclude = [_player.get_rid()]
	var landed := false
	var seen := {}
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var target := _owner_of(hit["collider"])
		if target == null or seen.has(target.get_instance_id()):
			continue
		seen[target.get_instance_id()] = true
		hit_nodes.append(target)
		if target.has_method("mallet_hit"):
			landed = target.mallet_hit(direction) or landed
		elif target is Enemy:
			var enemy := target as Enemy
			if enemy.take_hit(DAMAGE, direction) == Enemy.HitResult.HIT:
				GameState.add_resonance(GameState.RESONANCE_PER_HIT)
				landed = true
	Feel.hitstop(4 if landed else 2)
	Feel.shake(3.0 if landed else 1.5)
	if not landed:
		KilnDebris.burst(get_parent().get_parent(), impact_point() + Vector2(0, 6), 3)


## Hurtboxes and catch areas belong to the thing they're on.
func _owner_of(collider: Object) -> Node:
	var node := collider as Node
	if node == null:
		return null
	if node.has_method("mallet_hit") or node is Enemy:
		return node
	var parent := node.get_parent()
	if parent and (parent.has_method("mallet_hit") or parent is Enemy):
		return parent
	return node


func _draw() -> void:
	# The handle swings from over Wren's shoulder down to the floor.
	var t := clampf(_time / WINDUP, 0.0, 1.0)
	var hand := Vector2(0, -9)
	var up := Vector2(0, -22) - direction * 4.0
	var down := Vector2(0, -6) + direction * REACH
	var head := up.lerp(down, ease(t, 2.4)) if not _struck else down
	draw_line(hand, head, Color("#8a6040"), 2.0)
	draw_set_transform(head.round(), direction.angle() + PI / 2.0, Vector2.ONE)
	draw_texture(KilnSprites.MALLET_HEAD, Vector2(-5, -4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _struck and _time < WINDUP + 0.1:
		# A ring of dust where it lands.
		var r := (_time - WINDUP) * 120.0 + 4.0
		draw_arc(down + Vector2(0, 4), r, 0.0, TAU, 16, Color(1.0, 0.9, 0.7, 0.6), 1.0)
