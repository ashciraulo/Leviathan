class_name Player
extends CharacterBody2D
## Wren, as a graybox stand-in: 8-direction movement, a sword with hitstop and
## knockback, breath-bubble life and the Hum heal.
##
## The origin is at Wren's feet so y-sorting lines up with other objects.

enum State { MOVE, ATTACK, CHARGE, SPIN, HURT, HUM, DEAD, ITEM, FALL }

const SPEED := 90.0
const ATTACK_TIME := 0.24
## A swing pressed this close to the end of the last one (or of a stagger)
## still comes out once Wren can move, rather than being lost.
const ATTACK_BUFFER := 0.15
## The sword only hurts during this window of the swing (seconds).
const SWORD_ACTIVE_FROM := 0.03
const SWORD_ACTIVE_TO := 0.15
## A driftwood sword's slash. Better swords hit harder (sword_damage).
const SWORD_DAMAGE := 1
## A slash's damage by the equipped sword's tier (driftwood, brinesteel,
## tidecaller); the spin does twice that.
const SWORD_DAMAGE_BY_TIER := [1, 1, 2, 3]
## Bosses take at most this from a slash (twice it from a spin), whatever
## the sword: their fights are paced by openings, and a strong sword
## mustn't skip one.
const BOSS_HIT_CAP := 1
## A shot is turned aside when it comes at Wren from within this of the way
## they face (a dot product: 0.5 is 60 degrees either side).
const SHIELD_ARC := 0.5
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
## On ice (I): how fast Wren gets going, and how slowly they come to a stop.
const ICE_GRIP := 170.0
const ICE_DRIFT := 45.0
## What stops Wren in the air (gliding, or on the Tide Hook's line): walls.
const AIR_MASK := (1 << (Layers.WORLD - 1)) | (1 << (Layers.GRATE - 1))
## Swimming in deep water is slower.
const SWIM_SPEED := 58.0

var state := State.MOVE
## Seconds since a swing was pressed while Wren couldn't swing yet; INF when
## there's none waiting.
var _attack_buffered := INF
var facing := Vector2.DOWN
## Set while the camera slides between rooms; Wren ignores input.
var frozen := false
## During a cutscene the player has no control; the story walks Wren with
## script_move (a direction, or zero to stand still).
var in_cutscene := false
var script_move := Vector2.ZERO
var hum_progress := 0.0
## Set by the item in use (State.ITEM): how Wren moves while using it.
var item_velocity := Vector2.ZERO
## True while the Tide Hook carries Wren: gaps and water pass underneath.
var airborne := false
## True while Wren holds the Glowmoth Lantern up (see Lantern).
var lantern_raised := false
## Seconds of Lamp Oil left in the lantern (it lights farther meanwhile).
var lantern_oil := 0.0
## True while Wren is under the surface with the Diver's Helm: nothing up
## top can touch them.
var diving := false

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
var _swim_depth := 0.0
## The room Wren last stood in, so on_ice() needn't search every frame.
var _room_here: Room

## Sheet columns in assets/sprites/wren.png.
const FRAME_WALK := [0, 1, 2, 3]
const FRAME_ATTACK := 4
const FRAME_HUM := 5
const WALK_FRAME_TIME := 0.11


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	Layers.assign(self, Layers.PLAYER, [])
	collision_mask = ground_mask()
	add_child(Layers.rect_shape(Vector2(10, 6), Vector2(0, -3)))

	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	Layers.assign(_hurtbox, Layers.PLAYER_HURTBOX, [Layers.ENEMY_ATTACK])
	_hurtbox.add_child(Layers.rect_shape(Vector2(10, 16), Vector2(0, -8)))
	add_child(_hurtbox)

	_sword = Area2D.new()
	_sword.name = "Sword"
	Layers.assign(_sword, Layers.PLAYER_ATTACK, [Layers.ENEMY_HURTBOX, Layers.WORLD])
	_sword_shape = Layers.rect_shape(Vector2(16, 10), Vector2.ZERO)
	_sword.add_child(_sword_shape)
	add_child(_sword)
	_place_sword()

	add_child(Art.shadow())
	_body = Art.sprite(Art.WREN, 6, 3, 22)
	_body.set_meta("contrast", Palette.CONTRAST_WREN)
	add_child(_body)
	# Sword and Hum effects draw on this layer, in front of Wren (or behind
	# when swinging upwards).
	_front = Node2D.new()
	_front.draw.connect(_draw_front)
	add_child(_front)


func _physics_process(delta: float) -> void:
	if frozen:
		Art.set_flash(_body, 0.0)
		return
	# Put away in the satchel, the lantern comes down.
	if lantern_raised and not GameState.item_slots.has("glowmoth_lantern"):
		lantern_raised = false
	_state_time += delta
	_attack_buffered += delta
	if state in [State.ATTACK, State.HURT] and Input.is_action_just_pressed("attack"):
		_attack_buffered = 0.0
	lantern_oil = maxf(lantern_oil - delta, 0.0)
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
	# Frozen means a room slide or a flight; in_cutscene means a story scene.
	# Hazards are checked again once they can move.
	if frozen or in_cutscene or _invuln > 0.0 or state in [State.DEAD, State.FALL]:
		return
	end_item()
	# A better tunic soaks up some hits: Wren still reels (a hum is broken,
	# a swing cut short) but no bubble pops, only a dull thud.
	var popped := GameState.hurt(amount)
	_place_sword()
	var away := global_position - from_position
	_knockback = (away.normalized() if away.length() > 0.1 else -facing) * HURT_KNOCKBACK
	if popped == 0:
		_knockback *= 0.6
		_invuln = INVULN_TIME
		_flash = FLASH_TIME
		_hum_latched = false
		Feel.shake(1.5)
		Audio.play_sfx("hit_shell", global_position, 0.8)
		_enter(State.HURT)
		return
	_invuln = INVULN_TIME
	_flash = FLASH_TIME
	_hum_latched = false
	Feel.hitstop(3)
	Feel.shake(3.0)
	Audio.play_sfx("player_hurt", global_position)
	Audio.play_sfx("bubble_pop", global_position)
	if GameState.is_dead() and _out_of_breath():
		return
	_enter(State.HURT)


func _move_state() -> void:
	var direction := _input_direction()
	if not airborne:
		# (Picking up the Diver's Helm opens deep water straight away.)
		collision_mask = ground_mask()
	if swimming():
		velocity = direction * SWIM_SPEED
	elif on_ice():
		# Ice keeps what speed Wren has; pushing only slowly changes it.
		var grip := ICE_GRIP if direction != Vector2.ZERO else ICE_DRIFT
		velocity = velocity.limit_length(SPEED).move_toward(direction * SPEED, grip * get_physics_process_delta_time())
	else:
		velocity = direction * SPEED
	if direction != Vector2.ZERO:
		_update_facing(direction)
	if in_cutscene or DialogueBox.recently_closed() or ShopMenu.recently_closed():
		return
	if Input.is_action_just_pressed("interact") and try_interact():
		velocity = Vector2.ZERO
		_attack_buffered = INF
	elif Input.is_action_just_pressed("attack"):
		start_attack()
		velocity = Vector2.ZERO
	elif Input.is_action_just_pressed("item_1") and use_item(GameState.item_slots[0]):
		velocity = Vector2.ZERO
	elif Input.is_action_just_pressed("item_2") and use_item(GameState.item_slots[1]):
		velocity = Vector2.ZERO
	# Asked once a frame: with Hum on toggle, each ask on a press flips it.
	elif _hum_requested():
		if GameState.can_hum():
			_enter(State.HUM)
			velocity = Vector2.ZERO
		else:
			# Don't leave Hum toggled on; it would start by itself later.
			_hum_latched = false
	# A swing pressed late in the last one, if nothing fresher was pressed.
	elif _attack_buffered <= ATTACK_BUFFER:
		start_attack()
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
		if distance < best_distance and _can_see(node as Node2D):
			best = node
			best_distance = distance
	if best == null:
		return false
	best.interact()
	return true


## Nothing solid (a wall, a peg) stands between Wren and `node`: no
## opening chests through the wall.
func _can_see(node: Node2D) -> bool:
	var from := global_position + Vector2(0, -4)
	var query := PhysicsRayQueryParameters2D.create(from, node.global_position + Vector2(0, -4), 1 << (Layers.WORLD - 1))
	var skip: Array[RID] = [get_rid()]
	if node is CollisionObject2D:
		skip.append((node as CollisionObject2D).get_rid())
	query.exclude = skip
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


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
		"stonebreaker":
			var mallet := Stonebreaker.new()
			mallet.name = "Stonebreaker"
			add_child(mallet)
			_enter(State.ITEM)
			item_velocity = Vector2.ZERO
			return true
		"kite_cloak":
			var cloak := KiteCloak.new()
			cloak.name = "KiteCloak"
			add_child(cloak)
			_enter(State.ITEM)
			item_velocity = facing * KiteCloak.SPEED
			return true
		"frostfang_bow":
			var bow := FrostfangBow.new()
			bow.name = "FrostfangBow"
			add_child(bow)
			_enter(State.ITEM)
			# On ice, Wren keeps sliding while they shoot.
			item_velocity = velocity if on_ice() else Vector2.ZERO
			return true
		"divers_helm":
			# Under the surface: from deep water, or diving in off its edge.
			if not swimming() and not _deep_ahead():
				return false
			var helm := DiversHelm.new()
			helm.name = "DiversHelm"
			add_child(helm)
			_enter(State.ITEM)
			item_velocity = velocity
			return true
		"echo_horn":
			var horn := EchoHorn.new()
			horn.name = "EchoHorn"
			add_child(horn)
			_enter(State.ITEM)
			item_velocity = Vector2.ZERO
			return true
		"puffer_bombs":
			# Not in the water: it would only fizzle out.
			if swimming() or not GameState.take_item("puffer_bombs"):
				return false
			PufferBomb.place(self)
			return true
		"lamp_oil":
			# Poured into the Glowmoth Lantern, which goes up burning brighter.
			if not GameState.item_slots.has("glowmoth_lantern") or not GameState.take_item("lamp_oil"):
				return false
			lantern_oil = Lantern.OIL_TIME
			if not lantern_raised:
				lantern_raised = true
				Audio.play_sfx("lantern_up", global_position)
			Audio.play_sfx("oil_pour", global_position)
			_flash = FLASH_TIME
			return true
		"glowmoth_lantern":
			# Up or down; Wren keeps walking either way.
			lantern_raised = not lantern_raised
			Audio.play_sfx("lantern_up" if lantern_raised else "lantern_down", global_position)
			return true
	return false


## The last bubble has popped. A Sea Sprite in a jar breathes Wren back to
## life (false: they carry on); otherwise Wren goes down (true).
func _out_of_breath() -> bool:
	if GameState.use_jar(Items.JAR_SPRITE):
		GameState.refill()
		_invuln = INVULN_TIME * 2.0
		_flash = FLASH_TIME
		Audio.play_sfx("hum_heal", global_position)
		Audio.play_jingle("jingle_pearl")
		Feel.shake(2.0)
		get_parent().add_child(Revival.at(global_position))
		return false
	_enter(State.DEAD)
	Events.player_died.emit()
	return true


## Kelp tonic from a jar: every bubble back.
func drink_potion() -> bool:
	# Never wasted on full breath.
	if state in [State.DEAD, State.FALL] or GameState.bubbles >= GameState.max_bubbles:
		return false
	if not GameState.use_jar(Items.JAR_POTION):
		return false
	GameState.refill()
	Audio.play_sfx("potion_drink", global_position)
	get_parent().add_child(Revival.at(global_position))
	return true


## Rising motes round Wren: a sprite's revival, a tonic drunk.
class Revival extends Node2D:
	const TIME := 0.8
	var _age := 0.0

	static func at(where: Vector2) -> Revival:
		var node := Revival.new()
		node.global_position = where
		node.z_index = 2
		return node

	func _process(delta: float) -> void:
		_age += delta
		if _age >= TIME:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t := _age / TIME
		for i in 8:
			var angle := TAU * i / 8.0 + t * 3.0
			var p := Vector2(cos(angle) * (10.0 - 4.0 * t), -6.0 - 22.0 * t + sin(angle) * 3.0)
			draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(3, 3)), Color(Palette.HUM, 1.0 - t))
			if i % 2 == 0:
				draw_rect(Rect2(p + Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, 1.0 - t))


## What stops Wren on foot: walls, water and sunken grates, and deep water
## unless they have the Diver's Helm.
func ground_mask() -> int:
	var mask := (1 << (Layers.WORLD - 1)) | (1 << (Layers.WATER - 1)) | (1 << (Layers.GRATE - 1))
	if not GameState.has_item("divers_helm"):
		mask |= 1 << (Layers.DEEP - 1)
	return mask


## True when Wren is in deep water (swimming it with the Diver's Helm).
func swimming() -> bool:
	if airborne:
		return false
	var room := _room_now()
	if room == null:
		return false
	var feet := global_position - room.global_position + Vector2(0, -3)
	return room.tile_at(floori(feet.x / Room.TILE), floori(feet.y / Room.TILE)) == "Q"


## Deep water just in front of Wren (they can dive in off the edge).
func _deep_ahead() -> bool:
	var room := Room.under(get_tree(), global_position)
	if room == null:
		return false
	var at := global_position - room.global_position + Vector2(0, -3) + facing * 12.0
	return room.tile_at(floori(at.x / Room.TILE), floori(at.y / Room.TILE)) == "Q"


## The room Wren stands in (remembered, so per-frame checks don't search).
func _room_now() -> Room:
	var room := _room_here
	if room == null or not is_instance_valid(room) or room.is_queued_for_deletion() \
			or not Rect2(room.global_position, Room.SIZE).has_point(global_position):
		room = Room.under(get_tree(), global_position)
		_room_here = room
	return room


## True when Wren is standing on ice (an I tile, or frozen water).
func on_ice() -> bool:
	if airborne:
		return false
	var room := _room_now()
	if room == null or not room.has_ice():
		return false
	var feet := global_position - room.global_position + Vector2(0, -3)
	return room.tile_at(floori(feet.x / Room.TILE), floori(feet.y / Room.TILE)) == "I"


## The direction the player is pressing (for items that steer).
func steer_input() -> Vector2:
	return _input_direction()


## Called by the item in use when it's done.
func end_item() -> void:
	airborne = false
	item_velocity = Vector2.ZERO
	if state == State.ITEM:
		_enter(State.MOVE)


func is_using_item() -> bool:
	return state == State.ITEM


## Wren drops through a hole in the floor to the floor below: room `coord`,
## landing on `tile`. No bubble lost; it's just a long step down.
func drop_through(coord: Vector2i, tile: Vector2i) -> void:
	if state in [State.FALL, State.DEAD]:
		return
	end_item()
	# Don't let a toggled Hum start by itself after landing.
	_hum_latched = false
	_enter(State.FALL)
	velocity = Vector2.ZERO
	Audio.play_sfx("player_fall", global_position, 1.3)
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector2(0.3, 0.3), 0.3)
	await tween.finished
	# Out of sight until the room below has faded in.
	_body.visible = false
	_enter(State.MOVE)
	Events.door_entered.emit(coord, tile)
	await get_tree().create_timer(0.4).timeout
	_body.scale = Vector2.ONE


## Wren drops through a gap in the deck: shrink away, lose a bubble, and
## come back on the solid deck at `back_to` (global position).
func fall(back_to: Vector2) -> void:
	if state in [State.FALL, State.DEAD]:
		return
	end_item()
	# Don't let a toggled Hum start by itself after landing.
	_hum_latched = false
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
	if GameState.is_dead() and _out_of_breath():
		return
	# Longer if a sea sprite has just breathed Wren back.
	_invuln = maxf(_invuln, INVULN_TIME)
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
			_on_sword_contact(enemy.take_hit(sword_damage(enemy), facing))
		_hit_scenery()
	if _state_time >= ATTACK_TIME:
		_enter(State.CHARGE if Input.is_action_pressed("attack") else State.MOVE)


## What a blow from the equipped sword does to `target` (spin: twice).
static func sword_damage(target: Node = null, spin: bool = false) -> int:
	var tier := clampi(Items.tier(GameState.equipped_item(Items.SWORD)), 1, 3)
	var amount: int = SWORD_DAMAGE_BY_TIER[tier] * (2 if spin else 1)
	if target and target.is_in_group("boss"):
		amount = mini(amount, BOSS_HIT_CAP * (2 if spin else 1))
	return amount


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
	elif _attack_buffered != INF:
		# That was a fresh press late in the swing, held past its end, not
		# a charge: it swings.
		start_attack()
	else:
		_enter(State.MOVE)


func _start_spin() -> void:
	_enter(State.SPIN)
	_hit_ids.clear()
	_knockback = Vector2.ZERO
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
		if enemy.take_hit(sword_damage(enemy, true), away) == Enemy.HitResult.HIT:
			GameState.add_resonance(GameState.RESONANCE_PER_HIT)
			Feel.hitstop(2)
			Feel.shake(2.0)
	_hit_scenery()
	if _state_time >= SPIN_TIME:
		_place_sword()
		_enter(State.MOVE)


## The sword through scenery: pots break and grass is cut.
func _hit_scenery() -> void:
	for body in _sword.get_overlapping_bodies():
		if body.has_method("sword_hit") and not _hit_ids.has(body.get_instance_id()):
			_hit_ids[body.get_instance_id()] = true
			body.sword_hit(facing)
	var room := Room.under(get_tree(), global_position)
	if room == null:
		return
	var centre := _sword_shape.global_position
	var shape := _sword_shape.shape
	var half := Vector2.ONE * (shape as CircleShape2D).radius if shape is CircleShape2D else (shape as RectangleShape2D).size / 2.0
	room.cut_plants(Rect2(centre - half, half * 2.0))


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
	if _invuln > 0.0 or diving or state in [State.DEAD, State.FALL]:
		return
	for area in _hurtbox.get_overlapping_areas():
		var hazard := area as DamageArea
		if hazard == null or not hazard.active:
			continue
		if shield_blocks(hazard):
			_deflect(hazard)
			continue
		take_damage(hazard.damage, hazard.global_position)
		hazard.notify_hit()
		return


## True when the equipped shield turns this shot aside: Wren faces it,
## isn't swinging or busy, and the shield is strong enough for it.
func shield_blocks(hazard: DamageArea) -> bool:
	var needed = hazard.get("shield_tier")
	if needed == null or int(needed) <= 0:
		return false
	if state not in [State.MOVE, State.CHARGE] or diving or in_cutscene or frozen:
		return false
	if Items.tier(GameState.equipped_item(Items.SHIELD)) < int(needed):
		return false
	# Where the shot is coming from: against the way it flies, or (one at
	# rest) from the middle of Wren's body out to it.
	var flying = hazard.get("velocity")
	var from: Vector2
	if flying is Vector2 and flying.length() > 1.0:
		from = -flying.normalized()
	else:
		from = (hazard.global_position - (global_position + Vector2(0, -8))).normalized()
	return from != Vector2.ZERO and facing.dot(from) >= SHIELD_ARC


## The shield's clack and spark; the shot is gone.
func _deflect(hazard: DamageArea) -> void:
	Audio.play_sfx("block", global_position, 1.3)
	_flash = FLASH_TIME * 0.5
	hazard.notify_hit()


func _enter(new_state: State) -> void:
	state = new_state
	# A press late in a swing and still held at its end carries into the
	# charge (let go early, it swings); anything else drops it.
	if not new_state in [State.MOVE, State.CHARGE] \
			or (new_state == State.CHARGE and _attack_buffered > ATTACK_BUFFER):
		_attack_buffered = INF
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
	if in_cutscene:
		return script_move
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
	# Swimming, only Wren's head and shoulders are above the water.
	_swim_depth = move_toward(_swim_depth, 8.0 if (state != State.FALL and swimming()) else 0.0, 60.0 * delta)
	_body.offset.y = _swim_depth
	_body.modulate = Color(0.55, 0.5, 0.65) if state == State.DEAD else Color.WHITE
	# Blink while invulnerable.
	_body.visible = not diving and not (_invuln > 0.0 and state != State.DEAD and int(_invuln * 20.0) % 2 == 1)
	Art.set_flash(_body, 1.0 if _flash > 0.0 else 0.0)
	_front.z_index = -1 if (state in [State.ATTACK, State.CHARGE] and facing.y < 0.0) else 0
	_front.queue_redraw()


func _draw_front() -> void:
	if _swim_depth > 0.5 and not diving:
		_draw_waterline()
	if lantern_raised and state != State.DEAD:
		_draw_lantern()
	if state == State.HUM:
		_draw_hum_rings()
	if state == State.ATTACK:
		_draw_sword()
	elif state == State.CHARGE:
		_draw_held_sword()
	elif state == State.SPIN:
		_draw_spin()


## The water closing round Wren as they swim: it hides their legs.
func _draw_waterline() -> void:
	var cut := -_swim_depth * 0.5 - 1.0
	var water := Color("#1c4a5c")
	_front.draw_rect(Rect2(-9, cut, 18, _swim_depth + 6.0), water)
	var bob := sin(_anim_time * 9.0 + _state_time * 3.0) * 1.0
	_front.draw_line(Vector2(-9, cut + bob * 0.3), Vector2(9, cut - bob * 0.3), Color(0.75, 0.92, 0.95, 0.8), 1.0)
	_front.draw_line(Vector2(-6, cut + 3), Vector2(-2, cut + 3), Color(0.5, 0.75, 0.85, 0.6), 1.0)
	_front.draw_line(Vector2(3, cut + 5), Vector2(7, cut + 5), Color(0.5, 0.75, 0.85, 0.6), 1.0)


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


## The Glowmoth Lantern held up beside Wren, its moths drifting round it.
func _draw_lantern() -> void:
	var side := -1.0 if facing.x < 0.0 else 1.0
	var at := Vector2(6.0 * side, -24.0 + sin(_anim_time * 6.0) * 0.5)
	_front.draw_texture(MireSprites.LANTERN_HELD, at - Vector2(4, 5))
	var t := Time.get_ticks_msec() / 1000.0
	for i in 2:
		var orbit := Vector2.from_angle(t * 2.4 + i * PI) * Vector2(7, 4)
		_front.draw_rect(Rect2(at + orbit, Vector2(1, 1)), Palette.HUM)


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
