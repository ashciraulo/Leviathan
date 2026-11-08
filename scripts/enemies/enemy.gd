class_name Enemy
extends CharacterBody2D
## Base for enemies: health, hit reaction, knockback, contact damage and death.
## Subclasses set their stats in _init(), steer in _think() and draw in _draw().
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


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	Layers.assign(self, Layers.ENEMY, [Layers.WORLD, Layers.WATER, Layers.ENEMY])
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


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if dying:
		queue_redraw()
		return
	if _stun > 0.0:
		_stun -= delta
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	elif ai_enabled:
		_think(delta)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	queue_redraw()


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


func _die() -> void:
	dying = true
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 0.3), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)


## Body colour with the white hit flash applied.
func _tint(base: Color) -> Color:
	if _flash > 0.0:
		return Palette.FLASH if Settings.flashes else Palette.SOFT_FLASH
	return base


func _draw_shadow(width: float) -> void:
	draw_rect(Rect2(-width / 2.0, -2, width, 4), Palette.SHADOW)


## The nearest of the four directions to `v`.
static func cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, 1.0 if v.y >= 0.0 else -1.0)
