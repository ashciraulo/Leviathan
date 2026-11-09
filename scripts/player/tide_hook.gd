class_name TideHook
extends Node2D
## The Tide Hook, the Rotting Hull's tool: a barbed hook on a chain that Wren
## throws straight ahead. What it catches decides what happens:
##   * a hook post (an iron ring on a bollard): it carries Wren across to the
##     post, over gaps in the deck and over water
##   * a crate: it drags the crate back towards Wren
##   * a small enemy: it stuns the enemy and yanks it in
##   * anything with hook_hit() (the Barnacle Matriarch's shell plates):
##     that thing decides
##   * a wall or anything else: it clinks off and reels back in
##
## Lives as a child of Wren while in use, and frees itself when done.

enum Phase { OUT, BACK, ZIP, DRAG }

const RANGE := 7.0 * 16.0
const OUT_SPEED := 340.0
const BACK_SPEED := 420.0
const ZIP_SPEED := 260.0
## Wren stops this far short of the post she zips to.
const ZIP_STOP := 12.0
const DRAG_SPEED := 200.0
const ENEMY_STUN := 0.6
## The chain leaves from Wren's hand, about here.
const HAND := Vector2(0, -9)
const CHAIN_LIGHT := Color("#c8d0e0")
const CHAIN_DARK := Color("#4a506c")

var phase := Phase.OUT
var direction := Vector2.DOWN
## The hook's head, in global coordinates.
var tip := Vector2.ZERO
var _player: Player
var _length := 0.0
var _caught: Node2D
var _zip_target := Vector2.ZERO
var _clinked := false
var _sprite_angle := 0.0


func _ready() -> void:
	_player = get_parent() as Player
	direction = _player.facing
	tip = _hand()
	z_index = 1
	_sprite_angle = direction.angle()


func _hand() -> Vector2:
	return _player.global_position + HAND + direction * 4.0


func _physics_process(delta: float) -> void:
	if _player == null or not _player.is_using_item():
		queue_free()
		return
	match phase:
		Phase.OUT:
			_fly_out(delta)
		Phase.BACK:
			_length = maxf(_length - BACK_SPEED * delta, 0.0)
			tip = _hand() + direction * _length
			if _length <= 0.0:
				_finish()
		Phase.ZIP:
			_zip(delta)
		Phase.DRAG:
			_drag(delta)
	queue_redraw()


func _fly_out(delta: float) -> void:
	var from := tip
	_length = minf(_length + OUT_SPEED * delta, RANGE)
	tip = _hand() + direction * _length
	var hit := _cast(from, tip)
	if not hit.is_empty():
		tip = hit["position"]
		_on_catch(hit["collider"])
	elif _length >= RANGE:
		phase = Phase.BACK


## What lies between two points along the chain's path. The hook flies over
## water and gaps; walls, posts, crates and enemies stop it.
func _cast(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = (1 << (Layers.WORLD - 1)) | (1 << (Layers.ENEMY_HURTBOX - 1))
	query.collide_with_areas = true
	query.exclude = [_player.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query)


func _on_catch(collider: Object) -> void:
	var target := collider as Node
	if target is Area2D and target.get_parent() is Enemy:
		target = target.get_parent()
	if target.has_method("hook_hit"):
		# Bosses and other special things answer for themselves.
		if target.hook_hit(direction):
			_caught = target
			phase = Phase.BACK
			Feel.hitstop(3)
			Feel.shake(2.0)
		else:
			_clink()
		return
	if target.is_in_group("hook_post"):
		_caught = target
		_zip_target = (target as Node2D).global_position - direction * ZIP_STOP
		phase = Phase.ZIP
		_player.airborne = true
		# Fly over water; walls still stop Wren.
		_player.collision_mask = 1 << (Layers.WORLD - 1)
		Feel.shake(1.0)
		return
	if target is Crate:
		_caught = target
		phase = Phase.DRAG
		return
	if target is Enemy:
		var enemy := target as Enemy
		if not enemy.dying:
			enemy.take_hit(0, -direction)
			enemy._stun = ENEMY_STUN
			enemy._knockback = -direction * DRAG_SPEED
		phase = Phase.BACK
		return
	_clink()


func _clink() -> void:
	if not _clinked:
		_clinked = true
		Feel.shake(0.6)
	phase = Phase.BACK


func _zip(_delta: float) -> void:
	var to_target := _zip_target - _player.global_position
	if to_target.length() < 3.0 or _player.get_slide_collision_count() > 0 and to_target.length() < 10.0:
		_player.collision_mask = (1 << (Layers.WORLD - 1)) | (1 << (Layers.WATER - 1))
		_finish()
		return
	_player.item_velocity = to_target.normalized() * ZIP_SPEED
	tip = (_caught as Node2D).global_position + Vector2(0, -8) if is_instance_valid(_caught) else tip
	_length = _hand().distance_to(tip)


func _drag(delta: float) -> void:
	var crate := _caught as Crate
	if not is_instance_valid(crate):
		phase = Phase.BACK
		return
	var done := crate.pull_towards(_player.global_position, DRAG_SPEED * delta)
	tip = crate.global_position + Vector2(0, -6)
	_length = _hand().distance_to(tip)
	if done:
		_length = _hand().distance_to(tip)
		phase = Phase.BACK


func _finish() -> void:
	_player.collision_mask = (1 << (Layers.WORLD - 1)) | (1 << (Layers.WATER - 1))
	_player.end_item()
	queue_free()


func _exit_tree() -> void:
	if is_instance_valid(_player):
		_player.airborne = false
		_player.collision_mask = (1 << (Layers.WORLD - 1)) | (1 << (Layers.WATER - 1))


func _draw() -> void:
	var from := _hand() - global_position
	var to := tip - global_position
	var span := to - from
	var links := int(span.length() / 4.0)
	# Chain: alternating light and dark links.
	for i in links:
		var at := from + span * (float(i) / maxf(links, 1))
		var color := CHAIN_LIGHT if i % 2 == 0 else CHAIN_DARK
		draw_rect(Rect2(at.round() - Vector2(1, 1), Vector2(2, 2)), color)
	# The hook's head, turned the way it flies.
	draw_set_transform(to.round(), _sprite_angle, Vector2.ONE)
	draw_texture(HullSprites.HOOK_HEAD, Vector2(-5, -5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
