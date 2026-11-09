class_name Tentacle
extends Node2D
## One of Knell's arms, reared up out of the deep water. Touching it hurts,
## and when Wren comes near it draws back (the tell) and slams down where
## they were. The sword can't hurt it from the surface; diving under with
## the Diver's Helm, a slash at its root cuts it off.

signal cut

const REACH := 46.0
const REAR_TIME := 0.6
const SLAM_TIME := 0.3
const REST_TIME := 1.4

var severed := false
var fast := false
var _sprite: Sprite2D
var _body: DamageArea
var _slam: DamageArea
var _root: Area2D
var _timer := 0.8
var _mode := "sway"
var _target := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	z_index = 0
	_sprite = Art.sprite(BelfrySprites.TENTACLE, 3, 1, 38)
	add_child(_sprite)
	_body = _area(DamageArea.new(), Layers.ENEMY_ATTACK, Vector2(10, 16), Vector2(0, -10)) as DamageArea
	_slam = _area(DamageArea.new(), Layers.ENEMY_ATTACK, Vector2(20, 14), Vector2.ZERO) as DamageArea
	_slam.active = false
	# The root, under the water: only a diver reaches it.
	_root = _area(Area2D.new(), Layers.ENEMY_HURTBOX, Vector2(14, 12), Vector2(0, -2))
	# Rising out of the water.
	_sprite.scale.y = 0.1
	create_tween().tween_property(_sprite, "scale:y", 1.0, 0.5)


func _area(area: Area2D, layer: int, size: Vector2, at: Vector2) -> Area2D:
	Layers.assign(area, layer, [])
	area.monitoring = false
	area.add_child(Layers.rect_shape(size, at))
	add_child(area)
	return area


## The Tide Hook clinks off it.
func hook_hit(_direction: Vector2) -> bool:
	return false


func dive_hit(_direction: Vector2) -> void:
	if severed:
		return
	severed = true
	_body.active = false
	_slam.active = false
	_root.set_deferred("monitorable", false)
	_root.collision_layer = 0
	_sprite.frame = 2
	_sprite.position.x = -8
	Audio.play_sfx("tentacle_cut", global_position)
	Feel.shake(1.5)
	cut.emit()


func _physics_process(delta: float) -> void:
	_time += delta
	if severed:
		return
	_timer -= delta
	var wren := get_tree().get_first_node_in_group("player") as Player
	match _mode:
		"sway":
			_sprite.frame = 0
			_sprite.position.x = -8 + roundf(sin(_time * 2.0) * 1.5)
			if _timer <= 0.0 and wren and not wren.diving and wren.global_position.distance_to(global_position) < REACH + 20.0:
				_mode = "rear"
				_timer = REAR_TIME * (0.7 if fast else 1.0)
				var to := wren.global_position - global_position
				_target = to.limit_length(REACH)
				Audio.play_sfx("enemy_tell", global_position, 0.8)
		"rear":
			_sprite.frame = 1
			_sprite.position.x = -8 + (1.0 if int(_timer * 30.0) % 2 == 0 else -1.0)
			if _timer <= 0.0:
				_mode = "slam"
				_timer = SLAM_TIME
				_slam.position = _target
				_slam.active = true
				Audio.play_sfx("splash", global_position + _target, 0.8)
				Feel.shake(1.5)
		"slam":
			if _timer <= 0.0:
				_slam.active = false
				_mode = "sway"
				_timer = REST_TIME * (0.6 if fast else 1.0)
	queue_redraw()


func _draw() -> void:
	# Ripples round the root, and the slam's splash.
	var r := 9.0 + sin(_time * 3.0) * 1.5
	draw_arc(Vector2(0, -2), r, 0.0, TAU, 14, Color(0.7, 0.9, 0.9, 0.5), 1.0)
	if _mode == "rear" and not severed:
		draw_arc(_target, 10.0, 0.0, TAU, 14, Color(0.9, 0.95, 1.0, 0.35), 1.0)
	if _mode == "slam" and not severed:
		var spread := (1.0 - _timer / SLAM_TIME) * 14.0 + 4.0
		draw_arc(_target, spread, 0.0, TAU, 16, Color(0.85, 0.95, 1.0, 0.8), 2.0)
