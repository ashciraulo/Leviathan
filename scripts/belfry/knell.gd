class_name Knell
extends Enemy
## The Drowned Belfry's boss: a kraken living inside a great bell, tipped
## on its lip in the middle of the hall, deep water all round.
##
## The fight:
##   1. Three tentacles rear out of the water round the bell. Touching one
##      hurts, and each slams down where Wren stood (the tell: it draws
##      back). From the bell's mouth one great eye watches, and spits ink.
##   2. Dive under with the Diver's Helm and slash a tentacle's root to cut
##      it off. With all three cut, the kraken shrinks back inside.
##   3. Ring the bell with the Stonebreaker: the din shakes Knell out onto
##      the floor, dazed. Strike it before it drags itself back in and grows
##      its arms again.

enum Mode { INTRO, ARMS, HIDDEN, DAZED, RETREAT, DYING }

const DEFEATED_FLAG := "boss_belfry"
const HITS_PER_DAZE := 2
const DAZED_TIME := 4.5
const RETREAT_TIME := 0.8
const INK_EVERY := 2.8
const INK_SPEED := 80.0
## Where the tentacles rise, in tiles from the V tile.
const ARM_SPOTS := [Vector2i(-5, 0), Vector2i(6, 0), Vector2i(0, 4)]
## Where on the sheet (48x40 frames).
const FRAME_PEEK := 0
const FRAME_OUT := 1

## How long it peeks out of the bell before it spits ink.
const INK_TELL := 0.5
var _ink_tell := 0.0
var mode := Mode.INTRO
var bell: GreatBell
var arms: Array = []
var _room: Room
var _home := Vector2.ZERO
var _timer := 1.2
var _ink := INK_EVERY
var _hits_this_daze := 0


## What a V tile becomes in the Drowned Belfry: the kraken in its bell, or,
## once it's beaten, the Drowned Bell and the way out.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	# Beaten for good, unless Wren has come back to its echo (EchoTrial).
	if GameState.flags.get(DEFEATED_FLAG, false) and not EchoTrial.here(room):
		var after := BossAftermath.new()
		after.room = room
		after.boss_spot = pos + Vector2(0, 30)
		return after
	var boss := Knell.new()
	if EchoTrial.here(room):
		EchoTrial.dress(room)
	boss._room = room
	return boss


func _init() -> void:
	max_hp = 6
	contact_damage = 1
	body_size = Vector2(30, 12)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if _room == null:
		_room = get_parent() as Room
	collision_mask = 0
	collision_layer = 0
	_contact.active = false
	_hurtbox.collision_layer = 0
	_home = position + Vector2(0, 16)
	Events.toast.emit("BOSS_KNELL")
	call_deferred("_set_up")


func _set_up() -> void:
	bell = GreatBell.new()
	bell.knell = self
	bell.position = position
	_room.add_child(bell)
	position = _home
	_grow_arms()


func _grow_arms() -> void:
	for arm in arms:
		if is_instance_valid(arm):
			arm.queue_free()
	arms.clear()
	var vtile := Vector2i(floori(bell.position.x / Room.TILE), floori(bell.position.y / Room.TILE))
	for spot: Vector2i in ARM_SPOTS:
		var arm := Tentacle.new()
		arm.fast = hp * 2 <= max_hp
		var t := vtile + spot
		arm.position = Vector2(t.x * Room.TILE + Room.TILE / 2.0, t.y * Room.TILE + Room.TILE - 4)
		arm.cut.connect(_on_arm_cut)
		_room.add_child(arm)
		arms.append(arm)
	Audio.play_sfx("splash", position, 0.6)


func _on_arm_cut() -> void:
	for arm in arms:
		if is_instance_valid(arm) and not arm.severed:
			return
	if mode == Mode.ARMS:
		mode = Mode.HIDDEN
		_ink = INK_EVERY * 0.6
		Audio.play_sfx("knell_moan", position)


## The Stonebreaker rang the bell.
func on_bell_rung() -> void:
	if mode != Mode.HIDDEN:
		return
	mode = Mode.DAZED
	_timer = DAZED_TIME
	_ink_tell = 0.0
	_hits_this_daze = 0
	position = _home + Vector2(0, 14)
	_hurtbox.collision_layer = 1 << (Layers.ENEMY_HURTBOX - 1)
	Audio.play_sfx("knell_moan", position, 1.4)


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	var wren := get_player()
	match mode:
		Mode.INTRO:
			if _timer <= 0.0:
				mode = Mode.ARMS
				# Every arm already cut (in the opening moments): straight in.
				_on_arm_cut()
		Mode.ARMS, Mode.HIDDEN:
			if _ink_tell > 0.0:
				_ink_tell -= delta
				if _ink_tell <= 0.0 and wren and not wren.diving:
					_spit(wren)
			else:
				_ink -= delta
				if _ink <= 0.0 and wren and not wren.diving:
					# The tell: it peeks out of the bell's mouth and shudders.
					_ink = INK_EVERY * (0.7 if mode == Mode.HIDDEN else 1.0)
					_ink_tell = INK_TELL
					Audio.play_sfx("enemy_tell", global_position, 0.8)
		Mode.DAZED:
			if _timer <= 0.0 or _hits_this_daze >= HITS_PER_DAZE:
				mode = Mode.RETREAT
				_timer = RETREAT_TIME
				_hurtbox.collision_layer = 0
		Mode.RETREAT:
			position = position.move_toward(_home, 30.0 * delta)
			if _timer <= 0.0:
				position = _home
				mode = Mode.ARMS
				_grow_arms()


func _spit(wren: Player) -> void:
	var aim := (wren.global_position - global_position).angle()
	var count := 3 if hp * 2 <= max_hp else 1
	for i in count:
		var blob := InkBlob.new()
		blob.velocity = Vector2.from_angle(aim + (i - (count - 1) / 2.0) * 0.35) * INK_SPEED
		get_parent().add_child(blob)
		blob.global_position = global_position + Vector2(0, -4)
	Audio.play_sfx("enemy_shot", global_position, 0.5)


func _blocks_hit(_direction: Vector2) -> bool:
	return mode != Mode.DAZED


func _on_hurt() -> void:
	_hits_this_daze += 1
	Audio.play_sfx("knell_moan", position, 1.8)
	Feel.shake(1.5)


func hook_hit(_direction: Vector2) -> bool:
	return false


func _die() -> void:
	dying = true
	_ink_tell = 0.0
	mode = Mode.DYING
	_contact.active = false
	_hurtbox.set_deferred("monitorable", false)
	_hurtbox.collision_layer = 0
	GameState.flags[DEFEATED_FLAG] = true
	Events.boss_defeated.emit()
	for arm in arms:
		if is_instance_valid(arm):
			arm.queue_free()
	_sprite.position = _sprite_origin
	_sprite.frame = FRAME_OUT
	Audio.play_sfx("knell_moan", position, 0.6)
	for i in 4:
		_flash = 0.1
		Feel.shake(2.0)
		await get_tree().create_timer(0.25).timeout
		if not is_inside_tree():
			return
	# It slips into the deep for good; the great bell sinks after it.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 1.4)
	if bell and is_instance_valid(bell):
		tween.tween_property(bell, "modulate:a", 0.0, 1.4)
	await tween.finished
	if not is_inside_tree():
		return
	if bell and is_instance_valid(bell):
		bell.queue_free()
	var after := BossAftermath.new()
	after.room = _room if _room else get_parent() as Room
	after.boss_spot = _home + Vector2(0, 14)
	after.fresh = true
	get_parent().add_child(after)
	queue_free()


func _make_sprite() -> Sprite2D:
	return Art.sprite(BelfrySprites.KNELL, 2, 1, 38)


func _update_sprite() -> void:
	if mode == Mode.DYING:
		return
	_sprite.visible = (mode != Mode.HIDDEN and mode != Mode.INTRO) or _ink_tell > 0.0
	if _ink_tell > 0.0:
		_jitter(_ink_tell)
	_sprite.frame = FRAME_OUT if mode in [Mode.DAZED, Mode.RETREAT] else FRAME_PEEK
	if mode == Mode.DAZED and _timer < 1.0:
		_jitter(_timer)
