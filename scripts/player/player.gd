class_name Player
extends CharacterBody2D
## Wren, as a graybox stand-in: 8-direction movement, a sword with hitstop and
## knockback, breath-bubble life and the Hum heal.
##
## The origin is at Wren's feet so y-sorting lines up with other objects.

enum State { MOVE, ATTACK, CHARGE, SPIN, HURT, HUM, DEAD, ITEM, FALL }

const SPEED := 90.0
const ATTACK_TIME := 0.24
## The sword only hurts during this window of the swing (seconds).
const SWORD_ACTIVE_FROM := 0.03
const SWORD_ACTIVE_TO := 0.15
const SWORD_DAMAGE := 1
## Keep holding Sword after a slash to charge; release when charged to spin.
const CHARGE_TIME := 0.8
const CHARGE_SPEED_SCALE := 0.5
const SPIN_TIME := 0.35
const SPIN_RADIUS := 22.0
const SPIN_DAMAGE := 2
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
## How far from the point in front of Wren something can be and still be
## talked to or opened.
const INTERACT_RANGE := 16.0

var state := State.MOVE
var facing := Vector2.DOWN
## Set while the camera slides between rooms; Wren ignores input.
var frozen := false
var hum_progress := 0.0
## Set by the item in use (State.ITEM): how Wren moves while using it.
var item_velocity := Vector2.ZERO
## True while the Tide Hook carries Wren: gaps and water pass underneath.
var airborne := false

var _state_time := 0.0
var _knockback := Vector2.ZERO
var _invuln := 0.0
var _flash := 0.0
var _hum_latched := false
## The charge chime already played for this hold.
var _charge_chimed := false
var _hit_ids: Dictionary = {}
var _sword: Area2D
var _sword_shape: CollisionShape2D
var _hurtbox: Area2D
var _body: Sprite2D
var _front: Node2D
var _anim_time := 0.0

## Sheet columns in assets/sprites/wren.png.
const FRAME_WALK := [0, 1, 2, 3]
const FRAME_ATTACK := 4
const FRAME_HUM := 5
const WALK_FRAME_TIME := 0.11


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

	add_child(Art.shadow())
	_body = Art.sprite(Art.WREN, 6, 3, 22)
	add_child(_body)
	# Sword and Hum effects draw on this layer, in front of Wren (or behind
	# when swinging upwards).
	_front = Node2D.new()
	_front.draw.connect(_draw_front)
	add_child(_front)


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
		State.CHARGE:
			_charge_state()
		State.SPIN:
			_spin_state(delta)
		State.HURT:
			_hurt_state(delta)
		State.HUM:
			_hum_state(delta)
		State.DEAD, State.FALL:
			velocity = Vector2.ZERO
		State.ITEM:
			velocity = item_velocity
	move_and_slide()
	_check_damage()
	_update_sprite(delta)


func start_attack() -> void:
	_enter(State.ATTACK)
	_hit_ids.clear()
	_knockback = Vector2.ZERO
	_place_sword()
	Audio.play_sfx("sword_swing", global_position)


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
	# Frozen means a cutscene or a room slide: nothing can hurt Wren then.
	if frozen or _invuln > 0.0 or state in [State.DEAD, State.FALL]:
		return
	end_item()
	GameState.damage(amount)
	_place_sword()
	var away := global_position - from_position
	_knockback = (away.normalized() if away.length() > 0.1 else -facing) * HURT_KNOCKBACK
	_invuln = INVULN_TIME
	_flash = FLASH_TIME
	_hum_latched = false
	Feel.hitstop(3)
	Feel.shake(3.0)
	Audio.play_sfx("player_hurt", global_position)
	Audio.play_sfx("bubble_pop", global_position)
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
	if DialogueBox.recently_closed():
		return
	if Input.is_action_just_pressed("interact") and try_interact():
		velocity = Vector2.ZERO
	elif Input.is_action_just_pressed("attack"):
		start_attack()
		velocity = Vector2.ZERO
	elif Input.is_action_just_pressed("item_1") and use_item(GameState.item_slots[0]):
		velocity = Vector2.ZERO
	elif Input.is_action_just_pressed("item_2") and use_item(GameState.item_slots[1]):
		velocity = Vector2.ZERO
	elif _hum_requested() and not GameState.can_hum():
		# Don't leave Hum toggled on; it would start by itself later.
		_hum_latched = false
	elif _hum_requested() and GameState.can_hum():
		_enter(State.HUM)
		velocity = Vector2.ZERO


## The point just in front of Wren that Interact reaches.
func interact_point() -> Vector2:
	return global_position + facing * 12.0 + Vector2(0, -4)


## Talks to, or opens, whatever is in front of Wren. False if nothing is.
func try_interact() -> bool:
	var best: Node2D = null
	var best_distance := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		if node.get("opened") == true:
			continue
		var distance := (node as Node2D).global_position.distance_to(interact_point())
		if distance < best_distance:
			best = node
			best_distance = distance
	if best == null:
		return false
	best.interact()
	return true


## Uses an equipped item. False if it can't be used now.
func use_item(id: String) -> bool:
	if state != State.MOVE or not GameState.has_item(id):
		return false
	match id:
		"tide_hook":
			var hook := TideHook.new()
			hook.name = "TideHook"
			add_child(hook)
			_enter(State.ITEM)
			item_velocity = Vector2.ZERO
			return true
	return false


## Called by the item in use when it's done.
func end_item() -> void:
	airborne = false
	item_velocity = Vector2.ZERO
	if state == State.ITEM:
		_enter(State.MOVE)


func is_using_item() -> bool:
	return state == State.ITEM


## Wren drops through a gap in the deck: shrink away, lose a bubble, and
## come back on the solid deck at `back_to` (global position).
func fall(back_to: Vector2) -> void:
	if state in [State.FALL, State.DEAD]:
		return
	end_item()
	_enter(State.FALL)
	velocity = Vector2.ZERO
	# Shrink towards the middle of the body, as if dropping away.
	var origin := _body.position
	var middle := Vector2(0, -6)
	var shrink := func(k: float) -> void:
		_body.scale = Vector2(k, k)
		_body.position = middle + (origin - middle) * k
	Audio.play_sfx("player_fall", global_position)
	var tween := create_tween()
	tween.tween_method(shrink, 1.0, 0.1, 0.35)
	await tween.finished
	GameState.damage(1)
	shrink.call(1.0)
	global_position = back_to
	if GameState.is_dead():
		_enter(State.DEAD)
		Events.player_died.emit()
		return
	_invuln = INVULN_TIME
	_flash = FLASH_TIME
	_enter(State.MOVE)


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
		_enter(State.CHARGE if Input.is_action_pressed("attack") else State.MOVE)


func is_charged() -> bool:
	return state == State.CHARGE and _state_time >= CHARGE_TIME


## Wren walks slowly with the sword held out, facing locked.
func _charge_state() -> void:
	velocity = _input_direction() * SPEED * CHARGE_SPEED_SCALE
	if Input.is_action_pressed("attack"):
		if is_charged() and not _charge_chimed:
			_charge_chimed = true
			Audio.play_sfx("spin_charged", global_position)
		return
	_charge_chimed = false
	if is_charged():
		_start_spin()
	else:
		_enter(State.MOVE)


func _start_spin() -> void:
	_enter(State.SPIN)
	_hit_ids.clear()
	_sword_shape.position = Vector2(0, -8)
	var circle := CircleShape2D.new()
	circle.radius = SPIN_RADIUS
	_sword_shape.shape = circle
	Feel.shake(1.0)
	Audio.play_sfx("sword_spin", global_position)


func _spin_state(delta: float) -> void:
	velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	for area in _sword.get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy == null or _hit_ids.has(enemy.get_instance_id()):
			continue
		_hit_ids[enemy.get_instance_id()] = true
		var away := (enemy.global_position - global_position).normalized()
		if enemy.take_hit(SPIN_DAMAGE, away) == Enemy.HitResult.HIT:
			GameState.add_resonance(GameState.RESONANCE_PER_HIT)
			Feel.hitstop(2)
			Feel.shake(2.0)
	if _state_time >= SPIN_TIME:
		_place_sword()
		_enter(State.MOVE)


func _on_sword_contact(result: Enemy.HitResult) -> void:
	match result:
		Enemy.HitResult.HIT:
			GameState.add_resonance(GameState.RESONANCE_PER_HIT)
			Audio.play_sfx("hit_flesh", global_position)
			_knockback = -facing * RECOIL_SPEED
			Feel.hitstop(2)
			Feel.shake(1.5)
		Enemy.HitResult.BLOCKED:
			Audio.play_sfx("block", global_position)
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
		Audio.play_sfx("hum_heal", global_position)


func _check_damage() -> void:
	if _invuln > 0.0 or state in [State.DEAD, State.FALL]:
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
	if new_state == State.CHARGE:
		_charge_chimed = false


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
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	_sword_shape.shape = shape
	_sword_shape.position = rect.get_center()


func _update_sprite(delta: float) -> void:
	var row := 0
	if facing.y < 0.0:
		row = 1
	elif facing.x != 0.0:
		row = 2
	_body.flip_h = facing.x < 0.0
	var column := 0
	match state:
		State.MOVE:
			if velocity.length() > 1.0:
				_anim_time += delta
				column = FRAME_WALK[int(_anim_time / WALK_FRAME_TIME) % FRAME_WALK.size()]
			else:
				_anim_time = 0.0
		State.ITEM:
			column = FRAME_ATTACK
		State.ATTACK, State.CHARGE:
			column = FRAME_ATTACK
			if state == State.CHARGE and velocity.length() > 1.0:
				_anim_time += delta
				column = FRAME_WALK[int(_anim_time / (WALK_FRAME_TIME * 2.0)) % FRAME_WALK.size()]
		State.SPIN:
			# Turn through down, side, up, side as the blade goes round.
			var quarter := int(_state_time / SPIN_TIME * 4.0) % 4
			row = [0, 2, 1, 2][quarter]
			_body.flip_h = quarter == 3
			column = FRAME_ATTACK
		State.HUM:
			column = FRAME_HUM
			row = 0
			_body.flip_h = false
	_body.frame = row * 6 + column
	_body.modulate = Color(0.55, 0.5, 0.65) if state == State.DEAD else Color.WHITE
	# Blink while invulnerable.
	_body.visible = not (_invuln > 0.0 and state != State.DEAD and int(_invuln * 20.0) % 2 == 1)
	Art.set_flash(_body, 1.0 if _flash > 0.0 else 0.0)
	_front.z_index = -1 if (state in [State.ATTACK, State.CHARGE] and facing.y < 0.0) else 0
	_front.queue_redraw()


func _draw_front() -> void:
	if state == State.HUM:
		_draw_hum_rings()
	if state == State.ATTACK:
		_draw_sword()
	elif state == State.CHARGE:
		_draw_held_sword()
	elif state == State.SPIN:
		_draw_spin()


func _draw_blade(pivot: Vector2, angle: float) -> void:
	_front.draw_set_transform(pivot, angle, Vector2.ONE)
	_front.draw_texture(Art.SWORD, Vector2(-3, -3))
	_front.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_held_sword() -> void:
	var pivot := Vector2(0, -9) + facing * 3.0
	_draw_blade(pivot, facing.angle())
	if is_charged():
		# A glint runs along the blade once the spin is ready.
		var glint_at := pivot + facing * (4.0 + fmod(_state_time * 40.0, 10.0))
		_front.draw_rect(Rect2(glint_at - Vector2(1, 1), Vector2(2, 2)), Palette.FLASH)
		_front.draw_rect(Rect2(glint_at - Vector2(0, 3), Vector2(1, 7)), Palette.HUM)
		_front.draw_rect(Rect2(glint_at - Vector2(3, 0), Vector2(7, 1)), Palette.HUM)


func _draw_spin() -> void:
	var t := clampf(_state_time / SPIN_TIME, 0.0, 1.0)
	var start := facing.angle()
	var angle := start + t * TAU
	var trail := Palette.HUM
	trail.a = 0.6
	_front.draw_arc(Vector2(0, -8), 17.0, angle - 2.2, angle, 16, trail, 3.0)
	_draw_blade(Vector2(0, -9), angle)


## The driftwood sword sweeps through a short arc during the swing.
func _draw_sword() -> void:
	var t := clampf(_state_time / ATTACK_TIME, 0.0, 1.0)
	var base_angle := facing.angle()
	var direction := -1.0 if (facing.x < 0.0 or facing.y < 0.0) else 1.0
	var sweep := lerpf(-1.1, 1.1, ease(t, 0.4)) * direction
	var pivot := Vector2(0, -9) + facing * 3.0
	var angle := base_angle + sweep
	if is_sword_active():
		var start := base_angle - 1.1 * direction
		var trail := Palette.HUM
		trail.a = 0.55
		_front.draw_arc(pivot, 15.0, minf(start, angle), maxf(start, angle), 10, trail, 2.0)
	_draw_blade(pivot, angle)


func _draw_hum_rings() -> void:
	var center := Vector2(0, -11)
	for i in 3:
		var radius := fmod(hum_progress * 30.0 + i * 8.0, 24.0) + 6.0
		var color := Palette.HUM
		color.a = clampf(1.0 - radius / 30.0, 0.0, 1.0)
		_front.draw_arc(center, radius, 0.0, TAU, 32, color, 1.0)
	# Progress toward the next bubble.
	_front.draw_rect(Rect2(-8, 3, 16, 3), Palette.OUTLINE)
	_front.draw_rect(Rect2(-7, 4, 14.0 * hum_progress / HUM_TIME, 1), Palette.HUM)
