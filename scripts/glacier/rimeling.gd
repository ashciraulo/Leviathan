class_name Rimeling
extends Enemy
## A little ice imp (a) that skates on its belly in straight lines, turning
## off walls and water. When Wren lines up with it, it squeaks and comes
## skating straight at them.

const SPEED := 62.0
const RUSH_SPEED := 120.0
const LOOK_EVERY := 0.5

var _dir := Vector2.RIGHT
var _look := LOOK_EVERY
var _rush := false
var _anim := 0.0


func _init() -> void:
	max_hp = 2
	contact_damage = 1
	body_size = Vector2(12, 8)


func _ready() -> void:
	super._ready()
	_dir = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN][int(absf(position.x + position.y * 3.0)) % 4]


func _think(delta: float) -> void:
	# Overworld rooms have open edges with no wall to turn it: it turns at
	# the screen's edge instead of skating off.
	var ahead := position + _dir * 10.0
	if is_on_wall() or get_slide_collision_count() > 0 or not Rect2(Vector2(8, 8), Room.SIZE - Vector2(16, 16)).has_point(ahead):
		_turn()
	_look -= delta
	var wren := get_player()
	if wren and not _rush and _look <= 0.0:
		_look = LOOK_EVERY
		var to := wren.global_position - global_position
		if absf(to.y) < 8.0 and absf(to.x) < 140.0 or absf(to.x) < 8.0 and absf(to.y) < 110.0:
			_dir = Enemy.cardinal(to)
			_rush = true
			Audio.play_sfx("rimeling_squeak", global_position)
	velocity = _dir * (RUSH_SPEED if _rush else SPEED)
	_anim += delta


func _turn() -> void:
	_rush = false
	# Off to one side, or back the way it came.
	var options := [Vector2(_dir.y, _dir.x), Vector2(-_dir.y, -_dir.x), -_dir]
	for d: Vector2 in options:
		var next := position + d * 10.0
		if Rect2(Vector2(8, 8), Room.SIZE - Vector2(16, 16)).has_point(next) and not test_move(global_transform, d * 6.0):
			_dir = d
			return
	_dir = -_dir


func _make_sprite() -> Sprite2D:
	return Art.sprite(GlacierSprites.RIMELING, 2, 1, 14)


func _update_sprite() -> void:
	_sprite.frame = int(_anim * (10.0 if _rush else 5.0)) % 2
	if _dir.x != 0.0:
		_sprite.flip_h = _dir.x < 0.0
