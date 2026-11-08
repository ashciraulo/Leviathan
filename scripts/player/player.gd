class_name Player
extends CharacterBody2D
## Wren, as a graybox stand-in: 8-direction movement, a sword with hitstop and
## knockback, breath-bubble life and the Hum heal.
##
## The origin is at Wren's feet so y-sorting lines up with other objects.

enum State { MOVE, ATTACK, HURT, HUM, DEAD }

const SPEED := 90.0
const ATTACK_TIME := 0.24
## The sword only hurts during this window of the swing (seconds).
const SWORD_ACTIVE_FROM := 0.03
const SWORD_ACTIVE_TO := 0.15
const SWORD_DAMAGE := 1
## Wren is pushed back a little on every connect, more when a shell blocks.
const RECOIL_SPEED := 60.0
const BLOCKED_RECOIL_SPEED := 150.0
const HURT_TIME := 0.25
const HURT_KNOCKBACK := 170.0
const KNOCKBACK_DECAY := 700.0
const INVULN_TIME := 1.0
## Holding Hum this long spends a third of the Resonance meter for one bubble.
const HUM_TIME := 0.8
const FLASH_TIME := 0.1

var state := State.MOVE
var facing := Vector2.DOWN
## Set while the camera slides between rooms; Wren ignores input.
var frozen := false
var hum_progress := 0.0

var _state_time := 0.0
var _knockback := Vector2.ZERO
var _invuln := 0.0
var _flash := 0.0
var _hum_latched := false
var _hit_ids: Dictionary = {}
var _sword: Area2D
var _sword_shape: CollisionShape2D
var _hurtbox: Area2D


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	Layers.assign(self, Layers.PLAYER, [Layers.WORLD, Layers.WATER])
	add_child(Layers.rect_shape(Vector2(10, 6), Vector2(0, -3)))

	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	Layers.assign(_hurtbox, Layers.PLAYER_HURTBOX, [Layers.ENEMY_ATTACK])
	_hurtbox.add_child(Layers.rect_shape(Vector2(10, 16), Vector2(0, -8)))
	add_child(_hurtbox)

	_sword = Area2D.new()
	_sword.name = "Sword"
	Layers.assign(_sword, Layers.PLAYER_ATTACK, [Layers.ENEMY_HURTBOX])
	_sword_shape = Layers.rect_shape(Vector2(16, 10), Vector2.ZERO)
	_sword.add_child(_sword_shape)
	add_child(_sword)
	_place_sword()


func _physics_process(delta: float) -> void:
	if frozen:
		return
	_state_time += delta
	_invuln = maxf(_invuln - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	match state:
		State.MOVE:
			_move_state()
		State.ATTACK:
			_attack_state(delta)
		State.HURT:
			_hurt_state(delta)
		State.HUM:
			_hum_state(delta)
		State.DEAD:
			velocity = Vector2.ZERO
	move_and_slide()
	_check_damage()
	queue_redraw()


func start_attack() -> void:
	_enter(State.ATTACK)
	_hit_ids.clear()
	_knockback = Vector2.ZERO
	_place_sword()


## The area the sword covers this swing, relative to Wren's feet.
func sword_rect() -> Rect2:
	if facing.x > 0.0:
		return Rect2(5, -13, 16, 10)
	if facing.x < 0.0:
		return Rect2(-21, -13, 16, 10)
	if facing.y < 0.0:
		return Rect2(-5, -32, 10, 16)
	return Rect2(-5, 0, 10, 16)


func is_sword_active() -> bool:
	return state == State.ATTACK and _state_time >= SWORD_ACTIVE_FROM and _state_time <= SWORD_ACTIVE_TO


func take_damage(amount: int, from_position: Vector2) -> void:
	if _invuln > 0.0 or state == State.DEAD:
		return
	GameState.damage(amount)
	var away := global_position - from_position
	_knockback = (away.normalized() if away.length() > 0.1 else -facing) * HURT_KNOCKBACK
	_invuln = INVULN_TIME
	_flash = FLASH_TIME
	_hum_latched = false
	Feel.hitstop(3)
	Feel.shake(3.0)
	if GameState.is_dead():
		_enter(State.DEAD)
		Events.player_died.emit()
	else:
		_enter(State.HURT)


func _move_state() -> void:
	var direction := _input_direction()
	velocity = direction * SPEED
	if direction != Vector2.ZERO:
		_update_facing(direction)
	if Input.is_action_just_pressed("attack"):
		start_attack()
		velocity = Vector2.ZERO
	elif _hum_requested() and GameState.can_hum():
		_enter(State.HUM)
		velocity = Vector2.ZERO


func _attack_state(delta: float) -> void:
	velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	if is_sword_active():
		for area in _sword.get_overlapping_areas():
			var enemy := area.get_parent() as Enemy
			if enemy == null or _hit_ids.has(enemy.get_instance_id()):
				continue
			_hit_ids[enemy.get_instance_id()] = true
			_on_sword_contact(enemy.take_hit(SWORD_DAMAGE, facing))
	if _state_time >= ATTACK_TIME:
		_enter(State.MOVE)


func _on_sword_contact(result: Enemy.HitResult) -> void:
	match result:
		Enemy.HitResult.HIT:
			GameState.add_resonance(GameState.RESONANCE_PER_HIT)
			_knockback = -facing * RECOIL_SPEED
			Feel.hitstop(2)
			Feel.shake(1.5)
		Enemy.HitResult.BLOCKED:
			_knockback = -facing * BLOCKED_RECOIL_SPEED
			Feel.hitstop(3)
			Feel.shake(2.5)


func _hurt_state(delta: float) -> void:
	velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	if _state_time >= HURT_TIME:
		_enter(State.MOVE)


## Wren can't move while humming, so healing mid-fight is a risk you choose.
func _hum_state(delta: float) -> void:
	velocity = Vector2.ZERO
	if not _hum_requested() or not GameState.can_hum():
		_hum_latched = false
		_enter(State.MOVE)
		return
	hum_progress += delta
	if hum_progress >= HUM_TIME:
		hum_progress = 0.0
		GameState.hum_heal()


func _check_damage() -> void:
	if _invuln > 0.0 or state == State.DEAD:
		return
	for area in _hurtbox.get_overlapping_areas():
		var hazard := area as DamageArea
		if hazard == null or not hazard.active:
			continue
		take_damage(hazard.damage, hazard.global_position)
		hazard.notify_hit()
		return


func _enter(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	hum_progress = 0.0


func _hum_requested() -> bool:
	if Settings.hum_toggle:
		if Input.is_action_just_pressed("hum"):
			_hum_latched = not _hum_latched
		return _hum_latched
	return Input.is_action_pressed("hum")


## Analog or digital input, snapped to 8 directions at a constant speed.
func _input_direction() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw.length() < 0.3:
		return Vector2.ZERO
	return Vector2.from_angle(snappedf(raw.angle(), PI / 4.0))


## The sword swings in 4 directions. On a diagonal, keep the current facing if
## it is one of the two parts, so strafing feels steady.
func _update_facing(direction: Vector2) -> void:
	var horizontal := Vector2(signf(direction.x), 0.0) if absf(direction.x) > 0.1 else Vector2.ZERO
	var vertical := Vector2(0.0, signf(direction.y)) if absf(direction.y) > 0.1 else Vector2.ZERO
	if horizontal != Vector2.ZERO and vertical != Vector2.ZERO:
		if facing != horizontal and facing != vertical:
			facing = vertical
		return
	facing = horizontal if horizontal != Vector2.ZERO else vertical


func _place_sword() -> void:
	var rect := sword_rect()
	_sword_shape.position = rect.get_center()
	(_sword_shape.shape as RectangleShape2D).size = rect.size


func _draw() -> void:
	draw_rect(Rect2(-6, -2, 12, 4), Palette.SHADOW)
	if state == State.HUM:
		_draw_hum_rings()
	# Blink while invulnerable.
	if _invuln > 0.0 and state != State.DEAD and int(_invuln * 20.0) % 2 == 1:
		return
	var body := Palette.WREN
	if _flash > 0.0:
		body = Palette.FLASH if Settings.flashes else Palette.SOFT_FLASH
	if state == State.DEAD:
		body = body.darkened(0.5)
	draw_rect(Rect2(-6, -19, 12, 19), Palette.OUTLINE)
	draw_rect(Rect2(-5, -12, 10, 11), body)
	draw_rect(Rect2(-5, -18, 10, 6), Palette.WREN_SKIN)
	# Eyes show which way Wren faces.
	if facing.y >= 0.0:
		var eye_x := facing.x * 2.0
		draw_rect(Rect2(eye_x - 3, -16, 2, 2), Palette.OUTLINE)
		draw_rect(Rect2(eye_x + 1, -16, 2, 2), Palette.OUTLINE)
	if is_sword_active():
		var rect := sword_rect()
		draw_rect(rect.grow(-1), Palette.OUTLINE)
		draw_rect(rect.grow(-2), Palette.SWORD)


func _draw_hum_rings() -> void:
	var center := Vector2(0, -9)
	for i in 3:
		var radius := fmod(hum_progress * 30.0 + i * 8.0, 24.0) + 6.0
		var color := Palette.HUM
		color.a = clampf(1.0 - radius / 30.0, 0.0, 1.0)
		draw_arc(center, radius, 0.0, TAU, 24, color, 1.0)
	# Progress toward the next bubble.
	draw_rect(Rect2(-8, 3, 16, 2), Palette.OUTLINE)
	draw_rect(Rect2(-8, 3, 16.0 * hum_progress / HUM_TIME, 2), Palette.HUM)
