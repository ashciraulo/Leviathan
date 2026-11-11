class_name Enemy
extends CharacterBody2D
## Base for enemies: health, hit reaction, knockback, contact damage and death.
## Subclasses set their stats in _init(), steer in _think(), build their
## sprite in _make_sprite() and pick its frame in _update_sprite().
##
## Every enemy should have one readable tell (a wind-up, a flash, a sound)
## before it attacks.

enum HitResult { IGNORED, HIT, BLOCKED }

const KNOCKBACK_SPEED := 200.0
const KNOCKBACK_DECAY := 900.0
const HIT_STUN := 0.25

@export var max_hp := 2
@export var contact_damage := 1
## Turn off to freeze the enemy's decisions (for tests and debugging).
@export var ai_enabled := true
## A region's elite (set before it enters the tree; see Room.elite): bigger,
## three times as hardy, tinted like old bronze, and its kind's pattern grows
## a second step (see each kind's _think). It roars when it first sees Wren,
## and drops a heap of glints when it falls.
var elite := false

const ELITE_HP := 3
const ELITE_SCALE := 1.3
const ELITE_TINT := Color(1.0, 0.8, 0.6)
const ELITE_GLINTS := 30
const ELITE_SIGHT := 110.0

## Size of the feet collision. The hurtbox is a little taller.
var body_size := Vector2(12, 8)
## 0 for rooted enemies that can't be pushed.
var knockback_scale := 1.0
var hp := 0
var dying := false

var _stun := 0.0
var _knockback := Vector2.ZERO
var _flash := 0.0
var _hurtbox: Area2D
var _contact: DamageArea
var _sprite: Sprite2D
var _sprite_origin := Vector2.ZERO
var _roared := false


func _ready() -> void:
	if elite:
		max_hp *= ELITE_HP
	hp = max_hp
	add_to_group("enemies")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	Layers.assign(self, Layers.ENEMY, [Layers.WORLD, Layers.WATER, Layers.ENEMY, Layers.DEEP, Layers.GRATE])
	add_child(Layers.rect_shape(body_size, Vector2(0, -body_size.y / 2.0)))

	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	Layers.assign(_hurtbox, Layers.ENEMY_HURTBOX, [])
	_hurtbox.monitoring = false
	var hurt_size := body_size + Vector2(2, 6)
	_hurtbox.add_child(Layers.rect_shape(hurt_size, Vector2(0, -hurt_size.y / 2.0)))
	add_child(_hurtbox)

	_contact = DamageArea.new()
	_contact.name = "Contact"
	_contact.damage = contact_damage
	Layers.assign(_contact, Layers.ENEMY_ATTACK, [])
	_contact.monitoring = false
	_contact.add_child(Layers.rect_shape(body_size - Vector2(2, 0), Vector2(0, -body_size.y / 2.0)))
	add_child(_contact)

	add_child(Art.shadow(body_size.x > 14))
	_sprite = _make_sprite()
	_sprite.set_meta("contrast", Palette.CONTRAST_ENEMY)
	add_child(_sprite)
	_sprite_origin = _sprite.position
	if elite:
		scale = Vector2.ONE * ELITE_SCALE
		_sprite.self_modulate = ELITE_TINT


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if dying:
		return
	if elite and not _roared and ai_enabled:
		var wren := get_player()
		if wren and wren.global_position.distance_to(global_position) < ELITE_SIGHT:
			_roared = true
			Audio.play_sfx("boss_roar", global_position, 1.5)
			Feel.shake(1.5)
	if _stun > 0.0:
		_stun -= delta
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	elif ai_enabled and not Cutscene.active:
		_think(delta)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_sprite.position = _sprite_origin
	_update_sprite()
	Art.set_flash(_sprite, 1.0 if _flash > 0.0 else 0.0)


## Called by Wren's sword. `direction` is the way the swing travels.
func take_hit(damage: int, direction: Vector2) -> HitResult:
	if dying:
		return HitResult.IGNORED
	if _blocks_hit(direction):
		_on_blocked(direction)
		return HitResult.BLOCKED
	hp -= damage
	_flash = 0.12
	_stun = HIT_STUN
	_knockback = direction * KNOCKBACK_SPEED * knockback_scale
	_on_hurt()
	if hp <= 0:
		_die()
	return HitResult.HIT


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


## Override: set velocity for this frame.
func _think(_delta: float) -> void:
	velocity = Vector2.ZERO


## Override: return true to deflect a hit travelling in `direction`.
func _blocks_hit(_direction: Vector2) -> bool:
	return false


func _on_blocked(_direction: Vector2) -> void:
	pass


func _on_hurt() -> void:
	pass


## Chance that a fallen enemy leaves a glint or more.
const GLINT_ODDS := 0.6


func _die() -> void:
	dying = true
	Audio.play_sfx("enemy_die", global_position)
	if elite:
		Audio.play_sfx("boss_fall", global_position, 1.6)
		var room := get_parent() as Room
		if room:
			GameState.set_flag(Room.elite_flag(room.coord))
		if get_parent():
			Glint.drop.call_deferred(get_parent(), position, ELITE_GLINTS)
	elif not is_in_group("boss") and get_parent():
		Glint.drop.call_deferred(get_parent(), position, Glint.roll(GLINT_ODDS))
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 0.3), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)


## Override: return this enemy's sprite (see Art.sprite()).
func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.SCUTTLER, 3, 1, 11)


## Override: choose the frame for this physics tick.
func _update_sprite() -> void:
	pass


## Shake the sprite sideways: part of most wind-up tells.
func _jitter(timer: float) -> void:
	_sprite.position.x += 1.0 if int(timer * 30.0) % 2 == 0 else -1.0


## The nearest of the four directions to `v`.
static func cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, 1.0 if v.y >= 0.0 else -1.0)
