class_name Marrowguard
extends Enemy
## A Marrowguard (M): a skeleton sentry of the barrow, holding a great
## shoulder-blade for a shield. It turns its shield to face Wren and the
## sword glances off it from the front, so strike it from the side or
## behind. The Echo Horn's note shatters the shield. When Wren is close it
## draws its spear back (the tell) and lunges.

enum Mode { WALK, DRAW, LUNGE, REST }

const WALK_SPEED := 26.0
const BARE_SPEED := 38.0
const SIGHT := 150.0
const DRAW_TIME := 0.5
const LUNGE_SPEED := 150.0
const LUNGE_TIME := 0.2
const REST_TIME := 0.6

var shield := true
var facing := Vector2.DOWN
var mode := Mode.WALK
var echo_reach := 4.0
var _timer := 0.0
var _step := 0.0


func _init() -> void:
	max_hp = 3
	body_size = Vector2(12, 8)


func _ready() -> void:
	super._ready()
	add_to_group("echo")


func _think(delta: float) -> void:
	var wren := get_player()
	_timer -= delta
	if wren == null:
		velocity = Vector2.ZERO
		return
	var to_wren := wren.global_position - global_position
	match mode:
		Mode.WALK:
			if to_wren.length() > SIGHT:
				velocity = Vector2.ZERO
				return
			# It turns its shield to Wren, a step behind.
			facing = Enemy.cardinal(to_wren)
			velocity = to_wren.normalized() * (WALK_SPEED if shield else BARE_SPEED)
			_step += delta
			if to_wren.length() < 30.0:
				mode = Mode.DRAW
				_timer = DRAW_TIME
				Audio.play_sfx("bone_rattle", global_position)
		Mode.DRAW:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.LUNGE
				_timer = LUNGE_TIME
		Mode.LUNGE:
			velocity = facing * LUNGE_SPEED
			if _timer <= 0.0:
				mode = Mode.REST
				_timer = REST_TIME
		Mode.REST:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.WALK


## The horn's note: the shield shatters, and it reels.
func horn_hit(_from: Vector2) -> void:
	if not shield or dying:
		return
	shield = false
	KilnDebris.burst(get_parent(), global_position + Vector2(0, -12), 6, TombSprites.BONE_SHARD)
	Audio.play_sfx("armour_shatter", global_position)
	_stun = 0.8
	_knockback = Vector2.ZERO
	_flash = 0.1


func _blocks_hit(direction: Vector2) -> bool:
	# A swing travelling against the way the shield faces hits the shield.
	return shield and direction.dot(facing) < -0.5


func _on_blocked(direction: Vector2) -> void:
	_flash = 0.04
	_stun = 0.12
	_knockback = direction * 50.0
	Audio.play_sfx("block", global_position)


func _make_sprite() -> Sprite2D:
	return Art.sprite(TombSprites.MARROWGUARD, 4, 1, 22)


func _update_sprite() -> void:
	var f := int(_step * 5.0) % 2
	_sprite.frame = (0 if shield else 2) + f
	_sprite.flip_h = facing.x < 0.0
	if mode == Mode.DRAW:
		_jitter(_timer)
