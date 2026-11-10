class_name HollowRegent
extends Enemy
## The Marrow Tomb's boss: the Hollow Regent, a king who built himself a
## body from the bones of the Old One's kin, to make the Old One his
## weapon. He wears armour of bone over a ribcage full of red marrow-light.
##
## The fight:
##   1. Armoured, the sword glances off him. He stalks Wren, raises his
##      spine sceptre (the tell) and slams it down, and from afar hurls
##      fans of bone shards.
##   2. Each note of the Echo Horn that reaches him shatters one piece of
##      his armour: a pauldron, the other pauldron, then the breastplate.
##   3. With all three gone his ribs stand open and he staggers: the sword
##      finds the marrow-light. Then he drags the bones of the floor back
##      up into new armour, and it starts again, angrier.

enum Mode { INTRO, WALK, RAISE, SLAM, THROW, OPEN, REBUILD, DYING }

const DEFEATED_FLAG := "boss_tomb"
const WALK_SPEED := 22.0
const RAISE_TIME := 0.7
const SLAM_RECOVER := 0.6
const SLAM_REACH := 34.0
const THROW_TELL := 0.5
const THROW_EVERY := 3.2
const SHARD_SPEED := 80.0
const OPEN_TIME := 4.0
const REBUILD_TIME := 1.2
## Hits he takes while open before he rebuilds.
const HITS_PER_OPEN := 2
## How soon one note after another can break another piece.
const PLATE_COOLDOWN := 0.3
## Pieces of armour (frames of the armour sheet) and where they sit.
const PLATES := [
	{"frame": 0, "at": Vector2(-15, -38)},
	{"frame": 1, "at": Vector2(15, -38)},
	{"frame": 2, "at": Vector2(0, -30)},
]

var mode := Mode.INTRO
var plates := [true, true, true]
## The horn's note is heard this far beyond his middle (he's big).
var echo_reach := 22.0
var _timer := 1.2
var _throw_timer := THROW_EVERY
var _plate_cool := 0.0
var _hits_this_open := 0
var _room: Room
var _plate_sprites: Array[Sprite2D] = []


## What a V tile becomes in the Marrow Tomb: the Regent, or, once he's
## beaten, the Marrow Bell and the way out.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	# Beaten for good, unless Wren has come back to its echo (EchoTrial).
	if GameState.flags.get(DEFEATED_FLAG, false) and not EchoTrial.here(room):
		var after := BossAftermath.new()
		after.room = room
		after.boss_spot = pos
		return after
	var boss := HollowRegent.new()
	if EchoTrial.here(room):
		EchoTrial.dress(room)
	boss._room = room
	return boss


func _init() -> void:
	max_hp = 6
	contact_damage = 1
	body_size = Vector2(28, 10)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	add_to_group("echo")
	if _room == null:
		_room = get_parent() as Room
	for p: Dictionary in PLATES:
		var s := Sprite2D.new()
		s.texture = TombSprites.REGENT_ARMOUR
		s.hframes = 3
		s.frame = p["frame"]
		s.position = p["at"]
		s.material = Art.flash_material()
		add_child(s)
		_plate_sprites.append(s)
	Events.toast.emit("BOSS_REGENT")
	Audio.play_sfx("regent_roar", global_position, 0.8)


func _think(delta: float) -> void:
	_timer -= delta
	var wren := get_player()
	if wren == null:
		velocity = Vector2.ZERO
		return
	var to_wren := wren.global_position - global_position
	var angry := hp * 2 <= max_hp
	match mode:
		Mode.INTRO:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.WALK
		Mode.WALK:
			velocity = to_wren.normalized() * WALK_SPEED * (1.4 if angry else 1.0)
			_throw_timer -= delta
			if to_wren.length() < SLAM_REACH + 6.0:
				_enter(Mode.RAISE, RAISE_TIME * (0.8 if angry else 1.0))
				Audio.play_sfx("enemy_tell", global_position, 0.6)
			elif _throw_timer <= 0.0 and to_wren.length() > 60.0:
				_enter(Mode.THROW, THROW_TELL)
				Audio.play_sfx("enemy_tell", global_position, 0.8)
		Mode.RAISE:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_slam(wren)
				_enter(Mode.SLAM, SLAM_RECOVER)
		Mode.SLAM:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.WALK
		Mode.THROW:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_throw(wren, 5 if angry else 3)
				_throw_timer = THROW_EVERY
				mode = Mode.WALK
		Mode.OPEN:
			velocity = Vector2.ZERO
			if _timer <= 0.0 or _hits_this_open >= HITS_PER_OPEN:
				_enter(Mode.REBUILD, REBUILD_TIME)
				Audio.play_sfx("regent_roar", global_position)
		Mode.REBUILD:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				plates = [true, true, true]
				for s in _plate_sprites:
					s.visible = true
				_throw_timer = 1.0
				mode = Mode.WALK
				Feel.shake(2.0)


func _physics_process(delta: float) -> void:
	_plate_cool -= delta
	super._physics_process(delta)


func _enter(new_mode: Mode, time: float) -> void:
	mode = new_mode
	_timer = time


func _slam(wren: Player) -> void:
	Feel.shake(3.0)
	Audio.play_sfx("regent_slam", global_position)
	var spot := global_position + Vector2(0, 6)
	KilnDebris.burst(get_parent(), spot, 6, TombSprites.BONE_SHARD)
	if wren.global_position.distance_to(spot) < SLAM_REACH:
		wren.take_damage(1, spot)


func _throw(wren: Player, count: int) -> void:
	var aim := (wren.global_position - global_position + Vector2(0, 20)).angle()
	for i in count:
		var shard := BoneShard.new()
		shard.velocity = Vector2.from_angle(aim + (i - (count - 1) / 2.0) * 0.28) * SHARD_SPEED
		get_parent().add_child(shard)
		shard.global_position = global_position + Vector2(0, -30)
	Audio.play_sfx("enemy_shot", global_position, 0.6)


## The Echo Horn's note: one piece of armour shatters.
func horn_hit(_from: Vector2) -> void:
	if dying or mode in [Mode.INTRO, Mode.OPEN, Mode.REBUILD]:
		return
	if _plate_cool > 0.0:
		# Too soon after the last: the note only rings off the bone.
		Audio.play_sfx("block", global_position, 0.8)
		_flash = 0.05
		return
	for i in plates.size():
		if plates[i]:
			plates[i] = false
			_plate_sprites[i].visible = false
			_plate_cool = PLATE_COOLDOWN
			KilnDebris.burst(get_parent(), global_position + (PLATES[i]["at"] as Vector2), 8, TombSprites.BONE_SHARD)
			Audio.play_sfx("armour_shatter", global_position)
			Feel.shake(1.5)
			_flash = 0.1
			break
	if not plates.has(true):
		_hits_this_open = 0
		_enter(Mode.OPEN, OPEN_TIME)
		Audio.play_sfx("regent_roar", global_position, 1.3)


func armour_left() -> int:
	return plates.count(true)


func _blocks_hit(_direction: Vector2) -> bool:
	return mode != Mode.OPEN


func _on_blocked(_direction: Vector2) -> void:
	_flash = 0.03
	Audio.play_sfx("block", global_position, 0.8)


func _on_hurt() -> void:
	_hits_this_open += 1
	Audio.play_sfx("regent_roar", global_position, 1.5)
	Feel.shake(1.5)


func hook_hit(_direction: Vector2) -> bool:
	return false


func arrow_hit(direction: Vector2) -> void:
	take_hit(1, direction)


func _die() -> void:
	dying = true
	mode = Mode.DYING
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	# Through set_flag, so the story can answer (the last mural).
	GameState.set_flag(DEFEATED_FLAG)
	Events.boss_defeated.emit()
	_sprite.position = _sprite_origin
	_sprite.frame = 3
	Audio.play_sfx("regent_roar", global_position, 0.5)
	for i in 5:
		_flash = 0.1
		Feel.shake(2.0)
		KilnDebris.burst(get_parent(), global_position + Vector2(randf_range(-16, 16), randf_range(-50, -10)), 5, TombSprites.BONE_SHARD)
		await get_tree().create_timer(0.25).timeout
		if not is_inside_tree():
			return
	# He falls apart into a heap of old bones, and the light goes out.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 0.2), 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	await tween.finished
	if not is_inside_tree():
		return
	var after := BossAftermath.new()
	after.room = _room if _room else get_parent() as Room
	after.boss_spot = _bell_spot()
	after.fresh = true
	get_parent().add_child(after)
	queue_free()


## The bell rises where the V tile is.
func _bell_spot() -> Vector2:
	if _room:
		for y in Room.ROWS:
			for x in Room.COLS:
				if _room.tile_at(x, y) == "V":
					return Vector2(x * Room.TILE + Room.TILE / 2.0, y * Room.TILE + Room.TILE - 4)
	return position


func _make_sprite() -> Sprite2D:
	return Art.sprite(TombSprites.REGENT, 4, 1, 62)


func _update_sprite() -> void:
	if mode == Mode.DYING:
		return
	match mode:
		Mode.RAISE, Mode.THROW:
			_sprite.frame = 1
			_jitter(_timer)
		Mode.SLAM:
			_sprite.frame = 2
		Mode.OPEN:
			_sprite.frame = 3
			_jitter(_timer * 0.3)
		Mode.REBUILD:
			_sprite.frame = 3
			for s in _plate_sprites:
				s.visible = int(_timer * 10.0) % 2 == 0
		_:
			_sprite.frame = 0
	for s in _plate_sprites:
		Art.set_flash(s, 1.0 if _flash > 0.0 else 0.0)
