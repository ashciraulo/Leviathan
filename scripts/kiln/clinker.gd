class_name Clinker
extends Enemy
## A squat beetle wearing a shell of cooled slag. The sword glances off the
## shell from any side. A blow from the Stonebreaker Mallet (or a yank of
## the Tide Hook) flips it onto its back, where its glowing belly is soft
## for a few seconds before it rights itself.
## Tell: it stops and grinds its shell before it charges.

enum Mode { CREEP, GRIND, CHARGE, FLIPPED }

const CREEP_SPEED := 18.0
const CHARGE_SPEED := 95.0
const SIGHT := 140.0
const GRIND_TIME := 0.5
const CHARGE_TIME := 0.55
const FLIP_TIME := 3.0

var mode := Mode.CREEP
var _timer := 1.0
var _charge_dir := Vector2.DOWN
var _walk := 0.0


func _init() -> void:
	max_hp = 3
	body_size = Vector2(14, 9)


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	var to_player := (player.global_position - global_position) if player else Vector2.ZERO
	match mode:
		Mode.CREEP:
			_walk += delta
			velocity = to_player.normalized() * CREEP_SPEED if to_player.length() < SIGHT else Vector2.ZERO
			if _timer <= 0.0 and to_player.length() < SIGHT * 0.8:
				mode = Mode.GRIND
				_timer = GRIND_TIME
				Audio.play_sfx("enemy_tell", global_position)
				_charge_dir = Enemy.cardinal(to_player)
			elif _timer <= 0.0:
				_timer = 0.8
		Mode.GRIND:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.CHARGE
				_timer = CHARGE_TIME
		Mode.CHARGE:
			_walk += delta * 3.0
			velocity = _charge_dir * CHARGE_SPEED
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				mode = Mode.CREEP
				_timer = 1.6
		Mode.FLIPPED:
			_walk += delta * 2.0
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.CREEP
				_timer = 1.0
				_flash = 0.1


## The mallet's blow, or the hook's yank, turns it over.
func mallet_hit(direction: Vector2) -> bool:
	if dying:
		return false
	if mode == Mode.FLIPPED:
		take_hit(2, direction)
		return true
	_flip(direction)
	return true


func _flip(direction: Vector2) -> void:
	mode = Mode.FLIPPED
	_timer = FLIP_TIME
	_stun = 0.2
	_knockback = direction * 80.0
	_flash = 0.1
	Audio.play_sfx("hit_shell", global_position, 0.7)
	Feel.shake(1.5)


func _blocks_hit(_direction: Vector2) -> bool:
	return mode != Mode.FLIPPED


func _on_blocked(direction: Vector2) -> void:
	_flash = 0.05
	_stun = 0.1
	_knockback = direction * 50.0


func _on_hurt() -> void:
	# Hits keep it on its back a little longer, but not for ever.
	_timer = maxf(_timer, 0.6)


func _make_sprite() -> Sprite2D:
	return Art.sprite(KilnSprites.CLINKER, 4, 1, 14)


func _update_sprite() -> void:
	var step := int(_walk * 6.0) % 2
	_sprite.frame = (2 if mode == Mode.FLIPPED else 0) + step
	_sprite.flip_h = velocity.x < 0.0
	if mode == Mode.GRIND:
		_jitter(_timer)


## The Tide Hook's yank also turns it over.
func hook_hit(direction: Vector2) -> bool:
	if dying or mode == Mode.FLIPPED:
		return false
	_flip(-direction)
	return true
