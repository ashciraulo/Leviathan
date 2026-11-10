class_name Stormheron
extends Enemy
## Gale Spire's boss: a huge storm-grey heron that roosts on the tower's
## lightning rods, out over the open sky.
##
## The fight:
##   1. Perched on a rod it can't be reached. It flares its wings (the tell)
##      and flings a fan of storm feathers at Wren.
##   2. Then the storm gathers: its rod sparks, and a bolt comes down and
##      knocks it off its perch onto the island floor beside it, stunned.
##   3. Glide over on the fans' wind with the Kite Cloak and strike it before
##      it shakes itself and flies to another rod.
## Below half strength it also swoops: a screech and a crouch (the tell),
## then a dive straight through where Wren stands, and back up to a rod.

enum Mode { INTRO, PERCH, FLARE, STORM, GROUNDED, FLY, CROUCH, SWOOP, DYING }

const DEFEATED_FLAG := "boss_gale"
const THROW_EVERY := 2.0
const FLARE_TIME := 0.55
const THROWS_PER_STORM := 2
const STORM_TIME := 1.4
const GROUNDED_TIME := 4.0
## Strikes it takes while grounded before it flies off.
const HITS_PER_LANDING := 2
const FLY_TIME := 1.1
const CROUCH_TIME := 0.7
const SWOOP_SPEED := 230.0
const FEATHER_SPEED := 95.0
## Where on the sheet (48x48 frames).
const FRAME_PERCH := 0
const FRAME_FLARE := 1
const FRAME_FLY := 2
const FRAME_GROUNDED := 3

var mode := Mode.INTRO
var rod: LightningRod
var _room: Room
var _timer := 1.2
var _throws := 0
var _hits_this_landing := 0
var _fly_from := Vector2.ZERO
var _fly_to := Vector2.ZERO
var _fly_rod: LightningRod
var _swoop_dir := Vector2.ZERO
var _facing := 1.0


## What a V tile becomes in Gale Spire: the heron, or, once it's beaten,
## the Storm Bell and the way out.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	# Beaten for good, unless Wren has come back to its echo (EchoTrial).
	if GameState.flags.get(DEFEATED_FLAG, false) and not EchoTrial.here(room):
		var after := BossAftermath.new()
		after.room = room
		after.boss_spot = pos
		return after
	var boss := Stormheron.new()
	if EchoTrial.here(room):
		EchoTrial.dress(room)
	boss._room = room
	return boss


func _init() -> void:
	max_hp = 6
	contact_damage = 1
	body_size = Vector2(22, 12)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if _room == null:
		_room = get_parent() as Room
	# It flies: nothing in the room stops it.
	collision_mask = 0
	_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.6)
	Events.toast.emit("BOSS_STORMHERON")
	Audio.play_sfx("heron_cry", global_position)
	# It comes down out of the sky onto the first rod it finds.
	call_deferred("_first_perch")


func _first_perch() -> void:
	var rods := _rods()
	if rods.is_empty():
		return
	rods.sort_custom(func(a: LightningRod, b: LightningRod) -> bool: return a.position.y < b.position.y)
	_fly_from = position + Vector2(0, -160)
	_start_fly(rods[0])
	_timer = FLY_TIME + 0.4


func _rods() -> Array:
	return get_parent().get_children().filter(func(n: Node) -> bool: return n is LightningRod)


func _perch_spot(on: LightningRod) -> Vector2:
	return on.position + Vector2(0, -2)


## Where it lands when the bolt knocks it down: the island floor beside the
## rod, on the side towards the middle of the room.
func _ground_spot(on: LightningRod) -> Vector2:
	var side := signf(Room.SIZE.x / 2.0 - on.position.x)
	if side == 0.0:
		side = 1.0
	return on.position + Vector2(side * 26.0, 6.0)


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	# Only its dive hurts to touch: perched or flying it's far above, and
	# taking off it gets clear before it can be blamed for a hit.
	_contact.active = mode == Mode.SWOOP
	var wren := get_player()
	var to_wren := Vector2.ZERO if wren == null else wren.global_position - global_position
	match mode:
		Mode.INTRO, Mode.FLY:
			var t := clampf(1.0 - _timer / FLY_TIME, 0.0, 1.0)
			position = _fly_from.lerp(_fly_to, ease(t, -1.8)) + Vector2(0, -sin(t * PI) * 40.0)
			_facing = signf(_fly_to.x - _fly_from.x) if absf(_fly_to.x - _fly_from.x) > 1.0 else _facing
			if _timer <= 0.0:
				position = _fly_to
				rod = _fly_rod
				_enter(Mode.PERCH, THROW_EVERY * 0.6)
		Mode.PERCH:
			if absf(to_wren.x) > 4.0:
				_facing = signf(to_wren.x)
			if _timer <= 0.0:
				if hp * 2 <= max_hp and _throws == 1 and wren:
					_enter(Mode.CROUCH, CROUCH_TIME)
					Audio.play_sfx("heron_cry", global_position, 1.3)
				elif _throws >= THROWS_PER_STORM:
					_enter(Mode.STORM, STORM_TIME)
					rod.set_charged(true)
					Audio.play_sfx("storm_gather", rod.global_position)
				else:
					_enter(Mode.FLARE, FLARE_TIME)
					Audio.play_sfx("heron_tell", global_position)
		Mode.FLARE:
			if _timer <= 0.0:
				_throw(to_wren)
				_throws += 1
				_enter(Mode.PERCH, THROW_EVERY)
		Mode.STORM:
			if _timer <= 0.0:
				rod.strike()
				_throws = 0
				_hits_this_landing = 0
				position = _ground_spot(rod)
				_enter(Mode.GROUNDED, GROUNDED_TIME)
		Mode.GROUNDED:
			if _timer <= 0.0 or _hits_this_landing >= HITS_PER_LANDING:
				_fly_from = position
				_start_fly(_next_rod(wren))
		Mode.CROUCH:
			if _timer <= 0.0:
				_swoop_dir = to_wren.normalized() if to_wren != Vector2.ZERO else Vector2.DOWN
				_facing = signf(_swoop_dir.x) if _swoop_dir.x != 0.0 else _facing
				_throws += 1
				_enter(Mode.SWOOP, 1.6)
				Audio.play_sfx("cloak_open", global_position, 0.6)
		Mode.SWOOP:
			position += _swoop_dir * SWOOP_SPEED * delta
			var local := position
			if _timer <= 0.0 or local.x < 8.0 or local.x > Room.SIZE.x - 8.0 or local.y < 8.0 or local.y > Room.SIZE.y - 8.0:
				_fly_from = position
				_start_fly(_next_rod(wren))


func _enter(new_mode: Mode, time: float) -> void:
	mode = new_mode
	_timer = time


func _start_fly(to: LightningRod) -> void:
	if rod:
		rod.set_charged(false)
	_fly_rod = to
	_fly_to = _perch_spot(to)
	mode = Mode.FLY if mode != Mode.INTRO else Mode.INTRO
	_timer = FLY_TIME
	Audio.play_sfx("wingbeat", global_position)


## A rod other than the one it's on, preferring one away from Wren.
func _next_rod(wren: Player) -> LightningRod:
	var rods := _rods().filter(func(r: LightningRod) -> bool: return r != rod)
	if rods.is_empty():
		return rod
	if wren:
		var at := wren.global_position - (get_parent() as Node2D).global_position
		rods.sort_custom(func(a: LightningRod, b: LightningRod) -> bool: return a.position.distance_to(at) > b.position.distance_to(at))
		if randf() < 0.35 and rods.size() > 1:
			return rods[1]
	return rods[0]


func _throw(to_wren: Vector2) -> void:
	var aim := to_wren.angle()
	for i in 3:
		var dart := FeatherDart.new()
		dart.velocity = Vector2.from_angle(aim + (i - 1) * 0.28) * FEATHER_SPEED
		get_parent().add_child(dart)
		dart.global_position = global_position + Vector2(10.0 * _facing, -30)
	Audio.play_sfx("enemy_shot", global_position, 1.4)


func _blocks_hit(_direction: Vector2) -> bool:
	return mode != Mode.GROUNDED


func _on_blocked(_direction: Vector2) -> void:
	_flash = 0.03


func _on_hurt() -> void:
	_hits_this_landing += 1
	Audio.play_sfx("heron_cry", global_position, 0.8)
	Feel.shake(1.5)


func hook_hit(_direction: Vector2) -> bool:
	return false


func _die() -> void:
	dying = true
	mode = Mode.DYING
	Audio.play_sfx("boss_fall", global_position, 1.1)
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	# Through set_flag, so the story can answer (StoryDirector.vael_at_the_spire).
	GameState.set_flag(DEFEATED_FLAG)
	Events.boss_defeated.emit()
	for r: LightningRod in _rods():
		r.set_charged(false)
	_sprite.position = _sprite_origin
	_sprite.frame = FRAME_GROUNDED
	Audio.play_sfx("heron_cry", global_position, 0.6)
	for i in 4:
		_flash = 0.1
		Feel.shake(2.0)
		await get_tree().create_timer(0.25).timeout
		if not is_inside_tree():
			return
	# The storm breaks, and it lifts away on the last of the wind.
	_sprite.frame = FRAME_FLY
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(60.0 * _facing, -150), 1.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 0.0, 1.6)
	await tween.finished
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
	return Art.sprite(GaleSprites.STORMHERON, 4, 1, 46)


func _update_sprite() -> void:
	if mode == Mode.DYING:
		return
	match mode:
		Mode.FLARE:
			_sprite.frame = FRAME_FLARE
			_jitter(_timer)
		Mode.CROUCH:
			# About to dive: wings out and dropped low on the rod, a
			# different shape from the feather flare.
			_sprite.frame = FRAME_FLY
			# (The fly frame's underside is 10 px higher than the perch's.)
			_sprite.position.y += 14.0
			_jitter(_timer)
		Mode.STORM:
			_sprite.frame = FRAME_FLARE if int(_timer * 10.0) % 2 == 0 else FRAME_PERCH
		Mode.GROUNDED:
			_sprite.frame = FRAME_GROUNDED
			# Shaking itself awake near the end.
			if _timer < 1.0:
				_jitter(_timer)
		Mode.FLY, Mode.INTRO, Mode.SWOOP:
			_sprite.frame = FRAME_FLY
		_:
			_sprite.frame = FRAME_PERCH
	_sprite.flip_h = _facing < 0.0
	# Perched, it stands on the rod's tip, high above the floor.
	if mode in [Mode.PERCH, Mode.FLARE, Mode.STORM, Mode.CROUCH]:
		_sprite.position.y -= 34.0
