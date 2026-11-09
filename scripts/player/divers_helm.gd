class_name DiversHelm
extends Node2D
## The Diver's Helm, the Drowned Belfry's tool. Owning it, Wren swims deep
## water (Q). Its item key, in deep water, takes them under the surface for
## a few breaths: they swim beneath sunken grates, nothing up top can touch
## them, and the attack key slashes at whatever's down there (a dive_hit()
## method decides, or it's an ordinary hit). They come up when the breath
## runs out, when they swim out of the deep, or when the key is pressed
## again; never under a grate.
##
## Lives as a child of Wren while in use, and frees itself when done.

const DIVE_TIME := 2.6
const SLASH_REACH := 14.0
const SLASH_TIME := 0.22

var _player: Player
var _time := 0.0
var _slash := 0.0
var _slashed := false
## What the last slash reached (for tests).
var hit_nodes: Array = []


func _ready() -> void:
	_player = get_parent() as Player
	_player.diving = true
	# Under the grates: only walls and shallow water still stop Wren.
	_player.collision_mask = (1 << (Layers.WORLD - 1)) | (1 << (Layers.WATER - 1))
	z_index = 1
	Audio.play_sfx("splash", _player.global_position, 1.2)


func _physics_process(delta: float) -> void:
	if _player == null or not _player.is_using_item():
		_surface()
		return
	_time += delta
	_player.item_velocity = _player.steer_input() * Player.SWIM_SPEED * 0.85
	if _time < 0.3 and _player.item_velocity == Vector2.ZERO:
		# Diving in, Wren carries on the way they face.
		_player.item_velocity = _player.facing * Player.SWIM_SPEED * 0.85
	var dir := _player.steer_input()
	if dir != Vector2.ZERO:
		_player.facing = Enemy.cardinal(dir)
	if _slash > 0.0:
		_slash -= delta
	elif Input.is_action_just_pressed("attack"):
		_slash = SLASH_TIME
		_slashed = false
	if _slash > 0.0 and not _slashed and _slash < SLASH_TIME - 0.06:
		_slashed = true
		_strike()
	var again := _time > 0.25 and (Input.is_action_just_pressed("item_1") or Input.is_action_just_pressed("item_2"))
	# (Diving in off an edge, give Wren a moment to reach the water.)
	var ashore := _time > 0.35 and not _player.swimming()
	if (_time >= DIVE_TIME or again or ashore) and not _under_grate():
		_surface()
	queue_redraw()


## A grate overhead: Wren can't come up here.
func _under_grate() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _player.global_position + Vector2(0, -4)
	query.collision_mask = 1 << (Layers.GRATE - 1)
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


func _strike() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 11.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, _player.global_position + Vector2(0, -4) + _player.facing * SLASH_REACH)
	query.collision_mask = 1 << (Layers.ENEMY_HURTBOX - 1)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var seen := {}
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var node := hit["collider"] as Node
		var target := node.get_parent() if node and not (node.has_method("dive_hit") or node is Enemy) else node
		if target == null or seen.has(target.get_instance_id()):
			continue
		seen[target.get_instance_id()] = true
		hit_nodes.append(target)
		if target.has_method("dive_hit"):
			target.dive_hit(_player.facing)
		elif target is Enemy:
			(target as Enemy).take_hit(Player.SWORD_DAMAGE, _player.facing)
	Audio.play_sfx("sword_swing", _player.global_position, 0.7)


func _surface() -> void:
	if _player and is_instance_valid(_player):
		_player.diving = false
		_player.collision_mask = _player.ground_mask()
		if _player.is_using_item():
			_player.end_item()
		Audio.play_sfx("splash", _player.global_position, 1.4)
	queue_free()


func _draw() -> void:
	# Bubbles rising from where Wren is, and a dark shape below.
	draw_circle(Vector2(0, -2), 7.0, Color(0.05, 0.12, 0.18, 0.55))
	for i in 4:
		var t := fmod(_time * 1.3 + i * 0.27, 1.0)
		draw_arc(Vector2(sin(i * 2.1 + _time * 3.0) * 4.0, -4.0 - t * 14.0), 1.2 + i * 0.3, 0.0, TAU, 8, Color(0.8, 0.95, 1.0, 0.8 * (1.0 - t)), 1.0)
	if _slash > 0.0:
		var a := _player.facing.angle()
		draw_arc(Vector2(0, -4), SLASH_REACH, a - 0.9, a + 0.9, 10, Color(0.8, 0.95, 1.0, 0.7), 2.0)
