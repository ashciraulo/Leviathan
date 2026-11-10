class_name SungNote
extends Enemy
## One of Cantor Vael's sung notes: a glowing note that drifts after Wren.
## It hurts on touch, but the sword sends it back the way it came, and a
## note sung back at Vael breaks his song (CantorVael.note_hit).

const SPEED := 62.0
const RETURN_SPEED := 150.0
## How long it keeps turning after Wren before it flies straight.
const HOMING_TIME := 1.1
const TURN_RATE := 2.6
const LIFETIME := 6.0

## Who sang it: struck back, it flies home to him.
var singer: Node2D
var returning := false
var _life := LIFETIME
var _time := 0.0


## The note's touch: it bursts on Wren.
class NoteTouch extends DamageArea:
	var note: SungNote

	func notify_hit() -> void:
		if note and not note.dying:
			note.burst()


func _init() -> void:
	max_hp = 1
	contact_damage = 1
	body_size = Vector2(8, 6)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("sung_notes")
	# It flies over anything but walls.
	collision_mask = 1 << (Layers.WORLD - 1)
	collision_layer = 0
	var touch := NoteTouch.new()
	touch.name = "Touch"
	touch.note = self
	touch.damage = contact_damage
	Layers.assign(touch, Layers.ENEMY_ATTACK, [])
	touch.monitoring = false
	touch.add_child(Layers.circle_shape(4.0, Vector2(0, -6)))
	_contact.queue_free()
	_contact = touch
	add_child(touch)
	for child in get_children():
		if child is Sprite2D and child != _sprite:
			child.visible = false


func _think(delta: float) -> void:
	_time += delta
	_life -= delta
	if _life <= 0.0:
		burst()
		return
	if returning:
		if singer == null or not is_instance_valid(singer):
			burst()
			return
		var home := singer.global_position + Vector2(0, -10)
		velocity = (home - global_position).normalized() * RETURN_SPEED
		if global_position.distance_to(home) < 12.0:
			if singer.has_method("note_hit"):
				singer.note_hit(self)
			burst()
		return
	var wren := get_player()
	if velocity == Vector2.ZERO:
		velocity = Vector2.DOWN * SPEED
	if wren and _time < HOMING_TIME:
		var want := (wren.global_position + Vector2(0, -6) - global_position).angle()
		var now := velocity.angle()
		var turn := clampf(wrapf(want - now, -PI, PI), -TURN_RATE * delta, TURN_RATE * delta)
		velocity = Vector2.from_angle(now + turn) * SPEED


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not dying and get_slide_collision_count() > 0:
		burst()


## The sword sends it back at its singer. It can't be hurt.
func take_hit(_damage: int, _direction: Vector2) -> HitResult:
	if dying or returning:
		return HitResult.IGNORED
	returning = true
	_contact.active = false
	_flash = 0.1
	Audio.play_sfx("note_reflect", global_position)
	return HitResult.HIT


func hook_hit(_direction: Vector2) -> bool:
	return false


## Gone in a little spray of light.
func burst() -> void:
	if dying:
		return
	dying = true
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _make_sprite() -> Sprite2D:
	var sprite := Art.sprite(MawSprites.NOTE, 2, 1, 11)
	sprite.position.y -= 4
	return sprite


func _update_sprite() -> void:
	_sprite.frame = int(_time * 6.0) % 2
	_sprite.position.y += sin(_time * 9.0) * 1.0
	_sprite.modulate = Color(1.6, 1.3, 0.8) if returning else Color.WHITE
	# Sent back, it's bigger and spins, not only warmer.
	_sprite.scale = Vector2.ONE * (1.3 if returning else 1.0)
	_sprite.rotation = _time * 10.0 if returning else 0.0
