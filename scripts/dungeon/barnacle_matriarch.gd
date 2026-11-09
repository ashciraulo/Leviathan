class_name BarnacleMatriarch
extends Enemy
## The Rotting Hull's boss: a giant hermit crab that wears a ship's
## figurehead as her shell, with planks of the hull strapped over her soft
## belly. The sword glances off the planks.
##
## The fight, in three beats that repeat:
##   1. She stalks Wren, then rears up her great claw (tell: she shakes and
##      flashes gold) and slams it down where Wren stood.
##   2. The claw sticks in the deck for a moment. Hook a plank in that window
##      and the Tide Hook tears it off.
##   3. She lurches half out of her shell. Strike the soft body before she
##      pulls the shell back on.
## Below two thirds of her strength she also spits barnacles; below a third
## she spits more and moves faster. Each plank she keeps is a third of her
## health, so the planks on her back show how close the fight is.

enum Mode { INTRO, STALK, WINDUP, SLAM, RECOVER, EXPOSED, RESHELL, SPIT_WINDUP, DYING }

const DEFEATED_FLAG := "boss_hull"
const MAX_HP := 9
const HP_PER_PLATE := 3
const HITS_PER_OPENING := 3

const STALK_SPEED := 26.0
const STALK_TIME := 1.6
const SLAM_RANGE := 110.0
const WINDUP_TIME := 0.6
const SLAM_TIME := 0.32
const SLAM_SPEED := 230.0
const RECOVER_TIME := 1.4
const EXPOSED_TIME := 3.2
const RESHELL_TIME := 0.7
const SPIT_WINDUP_TIME := 0.55
const SHOT_SPEED := 85.0

## Sheet columns in assets/dungeon/matriarch.png (64x48 frames).
const FRAME_WALK := [0, 1]
const FRAME_WINDUP := 2
const FRAME_SLAM := 3
const FRAME_EXPOSED := 4
const FRAME_SPIT := 5
const FRAME_DEAD := 6
## Where each plank sits on her shell, relative to her feet.
const PLATE_SPOTS := [Vector2(0, -38), Vector2(11, -37), Vector2(19, -30)]

var mode := Mode.INTRO
var _timer := 1.2
var _lunge := Vector2.ZERO
var _hits_this_opening := 0
var _walk_time := 0.0
var _plates: Array[Sprite2D] = []
var _room: Room


## What a V tile becomes: the boss, or, once she's beaten, the Tidebell she
## guarded and the way out.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	if GameState.flags.get(DEFEATED_FLAG, false):
		var after := BossAftermath.new()
		after.room = room
		after.boss_spot = pos
		return after
	var boss := BarnacleMatriarch.new()
	boss._room = room
	return boss


func _init() -> void:
	max_hp = MAX_HP
	contact_damage = 1
	body_size = Vector2(40, 14)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	for spot in PLATE_SPOTS:
		var plate := Sprite2D.new()
		plate.texture = HullSprites.MATRIARCH_PLATE
		plate.position = spot
		plate.material = Art.flash_material()
		add_child(plate)
		_plates.append(plate)
	# Rise out of the bilge.
	_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.8)
	Events.toast.emit("BOSS_MATRIARCH")
	Feel.shake(3.0)


func plates_left() -> int:
	return ceili(float(maxi(hp, 0)) / HP_PER_PLATE)


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	var to_player := (player.global_position - global_position) if player else Vector2.ZERO
	var rage := 1.0 + (MAX_HP - hp) * 0.06
	match mode:
		Mode.INTRO:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter(Mode.STALK, STALK_TIME)
		Mode.STALK:
			_walk_time += delta
			velocity = to_player.normalized() * STALK_SPEED * rage if to_player.length() > 30.0 else Vector2.ZERO
			if _timer <= 0.0:
				var spits := hp <= MAX_HP - HP_PER_PLATE and randf() < 0.45
				if spits:
					_enter(Mode.SPIT_WINDUP, SPIT_WINDUP_TIME)
				elif to_player.length() > SLAM_RANGE:
					_enter(Mode.STALK, 0.5)
				else:
					_lunge = to_player.normalized()
					_enter(Mode.WINDUP, WINDUP_TIME / rage)
		Mode.WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_contact.damage = 2
				_enter(Mode.SLAM, SLAM_TIME)
		Mode.SLAM:
			velocity = _lunge * SLAM_SPEED
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				_contact.damage = 1
				Feel.shake(4.0)
				_enter(Mode.RECOVER, RECOVER_TIME)
		Mode.RECOVER:
			velocity = Vector2.ZERO
		Mode.EXPOSED:
			# Flail in place, then try to back away from Wren.
			velocity = Vector2.ZERO if _timer > EXPOSED_TIME / 2.0 else -to_player.normalized() * STALK_SPEED
		Mode.RESHELL:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter(Mode.STALK, STALK_TIME)
		Mode.SPIT_WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_spit(to_player)
				_enter(Mode.STALK, STALK_TIME)
	if mode in [Mode.RECOVER, Mode.EXPOSED] and _timer <= 0.0:
		_reshell()


func _enter(new_mode: Mode, time: float) -> void:
	mode = new_mode
	_timer = time


## The Tide Hook caught her. Only a stuck claw leaves a plank open to it.
func hook_hit(_direction: Vector2) -> bool:
	if mode != Mode.RECOVER:
		return false
	_hits_this_opening = 0
	_enter(Mode.EXPOSED, EXPOSED_TIME)
	_throw_plate()
	_flash = 0.15
	return true


func _blocks_hit(_direction: Vector2) -> bool:
	return mode != Mode.EXPOSED


func _on_blocked(_direction: Vector2) -> void:
	_flash = 0.05


func _on_hurt() -> void:
	_hits_this_opening += 1
	Feel.shake(2.0)
	if hp > 0 and _hits_this_opening >= HITS_PER_OPENING:
		_reshell()


func _reshell() -> void:
	_enter(Mode.RESHELL, RESHELL_TIME)
	_update_plates()


## The torn plank spins away across the deck and sinks.
func _throw_plate() -> void:
	var shown := plates_left() - 1
	var spot: Vector2 = PLATE_SPOTS[clampi(shown, 0, 2)]
	var plank := Sprite2D.new()
	plank.texture = HullSprites.MATRIARCH_PLATE
	plank.position = global_position + spot
	plank.z_index = 4
	get_parent().add_child(plank)
	var player := get_player()
	var away := (player.global_position - global_position).normalized() if player else Vector2.DOWN
	var tween := plank.create_tween().set_parallel(true)
	tween.tween_property(plank, "position", plank.position + away * 40.0 + Vector2(0, 10), 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(plank, "rotation", 6.0, 0.5)
	tween.chain().tween_property(plank, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(plank.queue_free)
	_update_plates(shown)


func _update_plates(count: int = -1) -> void:
	if count < 0:
		count = plates_left()
	for i in _plates.size():
		_plates[i].visible = i < count


func _spit(to_player: Vector2) -> void:
	var count := 3 if hp > HP_PER_PLATE else 5
	var spread := 0.35
	var aim := to_player.angle()
	for i in count:
		var shot := BarnacleShot.new()
		var angle := aim + (i - (count - 1) / 2.0) * spread
		shot.velocity = Vector2.from_angle(angle) * SHOT_SPEED
		shot.global_position = global_position + Vector2(0, -16)
		get_parent().add_child(shot)


func _die() -> void:
	dying = true
	mode = Mode.DYING
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	GameState.flags[DEFEATED_FLAG] = true
	_update_plates(0)
	# A long shudder, then she breaks apart and sinks.
	for i in 8:
		_flash = 0.08
		Feel.shake(3.0)
		await get_tree().create_timer(0.16).timeout
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 0.2), 0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	await tween.finished
	var after := BossAftermath.new()
	after.room = _room if _room else get_parent() as Room
	after.boss_spot = position
	after.fresh = true
	get_parent().add_child(after)
	queue_free()


func _make_sprite() -> Sprite2D:
	return Art.sprite(HullSprites.MATRIARCH, 7, 1, 45)


func _update_sprite() -> void:
	var frame := 0
	match mode:
		Mode.STALK:
			frame = FRAME_WALK[int(_walk_time * 5.0) % 2] if velocity.length() > 1.0 else 0
		Mode.WINDUP:
			frame = FRAME_WINDUP
		Mode.SLAM, Mode.RECOVER:
			frame = FRAME_SLAM
		Mode.EXPOSED:
			frame = FRAME_EXPOSED
		Mode.SPIT_WINDUP:
			frame = FRAME_SPIT
		Mode.DYING:
			frame = FRAME_DEAD
	_sprite.frame = frame
	_sprite.flip_h = false
	# Tell: a gold glow while she winds up.
	if mode in [Mode.WINDUP, Mode.SPIT_WINDUP]:
		_jitter(_timer)
		_sprite.modulate = Color(1.0, 0.9, 0.55) if int(_timer * 16.0) % 2 == 0 else Color.WHITE
	elif mode != Mode.INTRO:
		_sprite.modulate = Color.WHITE
	# Plates ride with the body: up when she rears, shaking with her.
	var lift := -4.0 if mode == Mode.WINDUP else (2.0 if mode == Mode.EXPOSED else 0.0)
	var shake := _sprite.position.x - _sprite_origin.x
	for i in _plates.size():
		_plates[i].position = PLATE_SPOTS[i] + Vector2(shake, lift)
		Art.set_flash(_plates[i], 1.0 if _flash > 0.0 else 0.0)
