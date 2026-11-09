class_name DropHammer
extends Node2D
## A foundry drop hammer: an iron head hauled up on chains that falls on its
## tile in a steady beat. It shakes just before it drops (the tell), and
## hurts anything under it while it's down. Hammers in a room keep a shared
## rhythm, offset by column, so a row of them makes a pattern to walk.

enum Phase { UP, SHAKE, FALL, DOWN, RISE }

const UP_TIME := 1.3
const SHAKE_TIME := 0.4
const FALL_TIME := 0.08
const DOWN_TIME := 0.45
const RISE_TIME := 0.55
const CYCLE := UP_TIME + SHAKE_TIME + FALL_TIME + DOWN_TIME + RISE_TIME
## How high the head hangs when raised, in pixels.
const LIFT := 22.0

var tile := Vector2i.ZERO
var phase := Phase.UP
var _time := 0.0
var _hazard: DamageArea
var _head: Sprite2D
var _base := Vector2.ZERO
var _lift := 0.0


func _ready() -> void:
	add_to_group("drop_hammers")
	_hazard = DamageArea.new()
	_hazard.name = "Hazard"
	_hazard.damage = 1
	Layers.assign(_hazard, Layers.ENEMY_ATTACK, [])
	_hazard.monitoring = false
	_hazard.add_child(Layers.rect_shape(Vector2(14, 12), Vector2(0, -6)))
	add_child(_hazard)
	_head = Art.sprite(KilnSprites.HAMMER_HEAD, 1, 1, 15)
	add_child(_head)
	_base = _head.position
	# Columns fall one after another, a third of a beat apart.
	_time = fposmod(-tile.x * CYCLE / 3.0, CYCLE)


func _physics_process(delta: float) -> void:
	_time = fmod(_time + delta, CYCLE)
	var t := _time
	var lift := 0.0
	var jitter := 0.0
	if t < UP_TIME:
		phase = Phase.UP
		lift = LIFT
	elif t < UP_TIME + SHAKE_TIME:
		phase = Phase.SHAKE
		lift = LIFT
		jitter = 1.0 if int(t * 30.0) % 2 == 0 else -1.0
	elif t < UP_TIME + SHAKE_TIME + FALL_TIME:
		phase = Phase.FALL
		lift = LIFT * (1.0 - (t - UP_TIME - SHAKE_TIME) / FALL_TIME)
	elif t < UP_TIME + SHAKE_TIME + FALL_TIME + DOWN_TIME:
		if phase != Phase.DOWN:
			_land()
		phase = Phase.DOWN
	else:
		phase = Phase.RISE
		lift = LIFT * (t - UP_TIME - SHAKE_TIME - FALL_TIME - DOWN_TIME) / RISE_TIME
	_hazard.active = phase in [Phase.FALL, Phase.DOWN] and lift < 8.0
	_lift = lift
	_head.position = _base + Vector2(jitter, -lift)
	queue_redraw()


func is_down() -> bool:
	return phase == Phase.DOWN


func _land() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(global_position) < 64.0:
		Feel.shake(1.5)
	# A hammer bursts any boulder caught under it.
	for node in get_tree().get_nodes_in_group("smashable"):
		if node is Boulder and (node as Node2D).global_position.distance_to(global_position) < 8.0:
			node.mallet_hit(Vector2.DOWN)


func _draw() -> void:
	# Chains up to the gantry.
	var top := _base.y - _lift + 1.0
	for side in [-6.0, 5.0]:
		var y := top
		while y > -96.0:
			draw_rect(Rect2(side, y - 3, 1, 3), Color("#4a506c"))
			y -= 4.0
	# The scorched square it lands on, and a shadow that darkens as the
	# head comes down.
	draw_texture_rect_region(Art.WORLD_TILES, Rect2(-8, -12, 16, 16), TileAtlas.region("hammer_mark"))
	var k := 1.0 - clampf(_lift / LIFT, 0.0, 1.0) * 0.6
	var shade := Color(0.08, 0.03, 0.06, 0.3 + 0.4 * (1.0 - _lift / LIFT))
	draw_rect(Rect2(Vector2(-7, -6) * k, Vector2(14, 8) * k), shade)
