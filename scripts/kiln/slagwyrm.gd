class_name Slagwyrm
extends Enemy
## The Kiln's boss: a serpent of molten slag, stirred up when the Choir
## stoked the furnace, that swims through the foundry floor.
##
## The fight:
##   1. It surfaces and chases Wren, its body trailing behind its head.
##      Molten, every part of it burns, and nothing hurts it.
##   2. Lure it through the quench pools: each plate of its body that passes
##      through the water sets into dark crust for a few seconds (it slows
##      as it stiffens). Crack a crusted plate with the Stonebreaker Mallet
##      and it breaks off for good.
##   3. After a while it dives. A glowing wake runs under the floor towards
##      Wren; the floor cracks and shakes where it will burst out (the tell),
##      then it erupts there and chases again, molten all over.
## Each plate is one part of its strength. Below half it spits slag while it
## chases. With its last plate gone it cools into stone.

enum Mode { INTRO, SURFACE, DIVE, UNDER, TELL, ERUPT, DYING }

const DEFEATED_FLAG := "boss_kiln"
const SEGMENTS := 6
## Distance along its path between one plate and the next.
const SPACING := 12.0
const SPEED := 46.0
## Each crusted plate slows it by this much (a fraction of its speed).
const STIFFEN := 0.11
const TURN_RATE := 2.2
const SURFACE_TIME := 10.0
const DIVE_TIME := 0.7
const UNDER_SPEED := 120.0
const UNDER_TIME := 1.4
const TELL_TIME := 0.8
const ERUPT_TIME := 0.3
const HARDEN_TIME := 6.0
const SPIT_EVERY := 3.2
const SHOT_SPEED := 80.0
## Where it may burst out: the open floor, clear of the border walls.
const ARENA := Rect2(2.5 * 16.0, 3.0 * 16.0, 19.0 * 16.0, 8.0 * 16.0)

## Sheet columns in assets/kiln/wyrm_head.png (32x28 frames).
const FRAME_CLOSED := 0
const FRAME_OPEN := 1
const FRAME_STONE := 2
## How long its jaw gapes before a spit of slag.
const SPIT_TELL := 0.5

## True while it sleeps in the crucible through Lowe's scene.
var asleep := false
## Seconds left of the gaping jaw before a spit (0: no spit coming).
var _spit_tell := 0.0
var mode := Mode.INTRO
var heading := Vector2.DOWN
var segments: Array[WyrmSegment] = []
var _timer := 1.4
## Points the head passed through, newest first (global).
var _trail := PackedVector2Array()
var _spit_timer := SPIT_EVERY
var _wake := Vector2.ZERO
var _target := Vector2.ZERO
var _room: Room
var _fx: Node2D
var _steam: Array = []
var _burst: DamageArea
var _sink := 0.0


## What a V tile becomes in the Kiln: the wyrm, or, once it's beaten, the
## Ember Bell and the way out.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	# Beaten for good, unless Wren has come back to its echo (EchoTrial).
	if GameState.flags.get(DEFEATED_FLAG, false) and not EchoTrial.here(room):
		var after := BossAftermath.new()
		after.room = room
		after.boss_spot = pos
		return after
	var boss := Slagwyrm.new()
	if EchoTrial.here(room):
		EchoTrial.dress(room)
	boss._room = room
	return boss


func _init() -> void:
	max_hp = SEGMENTS
	contact_damage = 1
	body_size = Vector2(20, 12)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if _room == null:
		_room = get_parent() as Room
	# It swims over the pools: only walls stop it.
	collision_mask = 1 << (Layers.WORLD - 1)
	_burst = DamageArea.new()
	_burst.name = "Burst"
	_burst.damage = 1
	_burst.active = false
	Layers.assign(_burst, Layers.ENEMY_ATTACK, [])
	_burst.monitoring = false
	_burst.add_child(Layers.circle_shape(20.0, Vector2(0, -6)))
	add_child(_burst)
	_fx = Node2D.new()
	_fx.name = "WyrmFx"
	_fx.z_index = -8
	_fx.draw.connect(_draw_fx)
	get_parent().add_child.call_deferred(_fx)
	for i in SEGMENTS:
		var segment := WyrmSegment.new()
		segment.boss = self
		segment.position = position
		# The body tapers towards the tail.
		segment.scale = Vector2.ONE * (1.0 - i * 0.07)
		segments.append(segment)
		get_parent().add_child.call_deferred(segment)
	_trail = PackedVector2Array([global_position])
	_sprite.modulate.a = 0.0
	# The first time, it sleeps in the crucible while Sister Lowe's smiths
	# stoke it (StoryDirector.the_crucible), and wakes when they're done.
	if _room and get_tree().get_first_node_in_group("story_director") and StoryDirector.lowe_waits(_room.coord):
		asleep = true
		return
	wake()


## It heaves up out of the melt. The fight starts once any scene ends.
func wake() -> void:
	asleep = false
	Events.boss_woke.emit()
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.8)
	Events.toast.emit("BOSS_SLAGWYRM")
	Audio.play_sfx("boss_roar", global_position)
	Feel.shake(3.0)


func _exit_tree() -> void:
	for segment in segments:
		if is_instance_valid(segment):
			segment.queue_free()
	if is_instance_valid(_fx):
		_fx.queue_free()


func hardened_count() -> int:
	return segments.filter(func(s: WyrmSegment) -> bool: return s.is_hard()).size()


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	var to_player := (player.global_position - global_position) if player else Vector2.ZERO
	match mode:
		Mode.INTRO:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_surface()
		Mode.SURFACE:
			_chase(delta, to_player)
			if _timer <= 0.0:
				_enter(Mode.DIVE, DIVE_TIME)
				velocity = Vector2.ZERO
		Mode.DIVE:
			velocity = Vector2.ZERO
			_sink = 1.0 - _timer / DIVE_TIME
			if _timer <= 0.0:
				_go_under()
		Mode.UNDER:
			# The wake runs under the floor towards Wren.
			var goal := _clamp_to_arena(player.global_position if player else global_position)
			_wake = _wake.move_toward(goal, UNDER_SPEED * delta)
			global_position = _wake
			velocity = Vector2.ZERO
			if _timer <= 0.0 or _wake.distance_to(goal) < 2.0:
				_target = _clamp_to_arena(_wake)
				_enter(Mode.TELL, TELL_TIME)
				Audio.play_sfx("wyrm_tell", _wake)
				Feel.shake(1.5)
		Mode.TELL:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_erupt()
		Mode.ERUPT:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_burst.active = false
				_contact.active = true
				_enter(Mode.SURFACE, SURFACE_TIME)
	_cool_in_pools()
	_fx.queue_redraw()


func _enter(new_mode: Mode, time: float) -> void:
	mode = new_mode
	_timer = time
	# A spit only comes from the surface: leaving it drops the tell.
	_spit_tell = 0.0


func _chase(delta: float, to_player: Vector2) -> void:
	if to_player.length() > 1.0:
		var turn := clampf(heading.angle_to(to_player), -TURN_RATE * delta, TURN_RATE * delta)
		heading = heading.rotated(turn).normalized()
	var rage := 1.0 + (SEGMENTS - hp) * 0.07
	var stiff := maxf(1.0 - STIFFEN * hardened_count(), 0.35)
	velocity = heading * SPEED * rage * stiff
	if get_slide_collision_count() > 0:
		heading = heading.bounce(get_slide_collision(0).get_normal()).normalized()
	# Never out through the doorway: past the arena's edge it turns back in.
	var inside := _clamp_to_arena(global_position)
	if inside.distance_to(global_position) > 12.0:
		heading = (inside - global_position).normalized()
		velocity = heading * velocity.length()
	# Lay down the path the body follows.
	if _trail.is_empty() or _trail[0].distance_to(global_position) >= 1.0:
		_trail.insert(0, global_position)
		var keep := int((SEGMENTS + 2) * SPACING) + 8
		if _trail.size() > keep:
			_trail.resize(keep)
	_place_segments()
	if hp <= SEGMENTS / 2:
		_spit_timer -= delta
		if _spit_tell > 0.0:
			_spit_tell -= delta
			if _spit_tell <= 0.0:
				_spit(to_player)
		elif _spit_timer <= 0.0:
			# The tell: its jaw gapes and it shudders, with a gurgle.
			_spit_timer = SPIT_EVERY
			_spit_tell = SPIT_TELL
			Audio.play_sfx("wyrm_gurgle", global_position)


## Each plate sits a fixed distance back along the head's path. Plates the
## path doesn't reach yet are still under the floor.
func _place_segments() -> void:
	var walked := 0.0
	var index := 0
	var want := SPACING
	for i in range(1, _trail.size()):
		var step := _trail[i - 1].distance_to(_trail[i])
		while index < segments.size() and walked + step >= want:
			var k := (want - walked) / maxf(step, 0.001)
			segments[index].global_position = _trail[i - 1].lerp(_trail[i], k)
			segments[index].set_surfaced(true) if not segments[index].surfaced else null
			index += 1
			want += SPACING
		walked += step
		if index >= segments.size():
			break
	for i in range(index, segments.size()):
		if segments[i].surfaced:
			segments[i].set_surfaced(false)
		segments[i].global_position = _trail[_trail.size() - 1]


## Plates passing through a quench pool set hard.
func _cool_in_pools() -> void:
	if mode != Mode.SURFACE or _room == null:
		return
	for segment in segments:
		if not segment.surfaced:
			continue
		var local := segment.global_position - _room.global_position + Vector2(0, -4)
		if _room.tile_at(floori(local.x / Room.TILE), floori(local.y / Room.TILE)) == "~":
			segment.harden(HARDEN_TIME)


func _surface() -> void:
	_enter(Mode.SURFACE, SURFACE_TIME)
	_sink = 0.0
	visible = true
	_contact.active = true
	_hurtbox.monitorable = true
	collision_mask = 1 << (Layers.WORLD - 1)


func _go_under() -> void:
	_enter(Mode.UNDER, UNDER_TIME)
	visible = false
	_contact.active = false
	_hurtbox.set_deferred("monitorable", false)
	collision_mask = 0
	_wake = global_position
	# Underground the heat melts every plate soft again.
	for segment in segments:
		segment.melt()
		segment.set_surfaced(false)


func _erupt() -> void:
	global_position = _target
	_trail = PackedVector2Array([global_position])
	var player := get_player()
	if player:
		heading = (player.global_position - global_position).normalized()
		if heading == Vector2.ZERO:
			heading = Vector2.DOWN
	_surface()
	_enter(Mode.ERUPT, ERUPT_TIME)
	_burst.active = true
	KilnDebris.burst(get_parent(), global_position + Vector2(0, -6), 10)
	Audio.play_sfx("bomb_blast", global_position, 0.8)
	Feel.shake(4.0)
	Feel.hitstop(3)


func _clamp_to_arena(at: Vector2) -> Vector2:
	var origin := _room.global_position if _room else Vector2.ZERO
	var local := at - origin
	local.x = clampf(local.x, ARENA.position.x, ARENA.end.x)
	local.y = clampf(local.y, ARENA.position.y, ARENA.end.y)
	return origin + local


func _spit(to_player: Vector2) -> void:
	var aim := to_player.angle()
	for i in 3:
		var shot := SlagGlob.new()
		shot.velocity = Vector2.from_angle(aim + (i - 1) * 0.3) * SHOT_SPEED
		get_parent().add_child(shot)
		shot.global_position = global_position + Vector2(0, -12)


## A mallet blow broke a crusted plate off.
func segment_smashed(segment: WyrmSegment) -> void:
	if dying or not segments.has(segment):
		return
	segments.erase(segment)
	KilnDebris.burst(get_parent(), segment.global_position + Vector2(0, -7), 8)
	segment.queue_free()
	Audio.play_sfx("pot_break", segment.global_position, 0.45)
	hp -= 1
	_flash = 0.2
	if hp <= 0:
		Feel.final_blow(get_parent(), segment.global_position + Vector2(0, -7))
		_die()
	else:
		Feel.hitstop(4)
		Feel.shake(3.0)


func steam_at(at: Vector2) -> void:
	_steam.append({"at": at, "life": 0.6})


## Swords, hooks and mallets glance off the head.
func _blocks_hit(_direction: Vector2) -> bool:
	return true


func _on_blocked(_direction: Vector2) -> void:
	_flash = 0.05


func hook_hit(_direction: Vector2) -> bool:
	return false


func mallet_hit(_direction: Vector2) -> bool:
	_flash = 0.05
	return false


func _die() -> void:
	dying = true
	mode = Mode.DYING
	Audio.play_sfx("boss_fall", global_position, 0.8)
	visible = true
	_contact.active = false
	_burst.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	GameState.flags[DEFEATED_FLAG] = true
	Events.boss_defeated.emit()
	# It may have been sinking into a dive: bring it back up to die.
	_sprite.position = _sprite_origin
	_sprite.modulate.a = 1.0
	# It shudders, cools to stone, and crumbles.
	for i in 8:
		_flash = 0.08
		Feel.shake(3.0)
		await get_tree().create_timer(0.16).timeout
		if not is_inside_tree():
			return
	_sprite.frame = FRAME_STONE
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return
	KilnDebris.burst(get_parent(), global_position + Vector2(0, -10), 14)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 0.3), 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	var after := BossAftermath.new()
	after.room = _room if _room else get_parent() as Room
	after.boss_spot = _bell_spot()
	after.fresh = true
	get_parent().add_child(after)
	queue_free()


## The bell rises where the wyrm first lay (its V tile).
func _bell_spot() -> Vector2:
	if _room:
		for y in Room.ROWS:
			for x in Room.COLS:
				if _room.tile_at(x, y) == "V":
					return Vector2(x * Room.TILE + Room.TILE / 2.0, y * Room.TILE + Room.TILE - 4)
	return position


func _make_sprite() -> Sprite2D:
	return Art.sprite(KilnSprites.WYRM_HEAD, 3, 1, 25)


func _process(delta: float) -> void:
	for puff: Dictionary in _steam:
		puff["life"] -= delta
	_steam = _steam.filter(func(p: Dictionary) -> bool: return p["life"] > 0.0)


func _update_sprite() -> void:
	if mode == Mode.DYING:
		return
	if _spit_tell > 0.0:
		_jitter(_spit_tell)
	_sprite.frame = FRAME_OPEN if _spit_tell > 0.0 or mode in [Mode.ERUPT, Mode.INTRO] or int(Time.get_ticks_msec() / 300) % 4 == 0 else FRAME_CLOSED
	_sprite.flip_h = heading.x < -0.3
	if mode == Mode.DIVE:
		_sprite.position.y += _sink * 14.0
		_sprite.modulate.a = 1.0 - _sink
	elif mode != Mode.INTRO:
		_sprite.modulate.a = 1.0


## Drawn on the floor: the glowing wake while it swims underneath, the
## cracking floor where it's about to burst out, and steam off the pools.
func _draw_fx() -> void:
	var origin := _fx.global_position
	if mode == Mode.UNDER:
		var at := _wake - origin
		for i in 4:
			var r := 4.0 + i * 3.0 + fmod(Time.get_ticks_msec() / 60.0, 3.0)
			_fx.draw_arc(at + Vector2(0, -2), r, 0.0, TAU, 14, Color(1.0, 0.55, 0.2, 0.5 - i * 0.1), 1.0)
	elif mode == Mode.TELL:
		var at := _target - origin
		var k := 1.0 - _timer / TELL_TIME
		_fx.draw_circle(at + Vector2(0, -3), 6.0 + 12.0 * k, Color(1.0, 0.45, 0.15, 0.25 + 0.35 * k))
		if Settings.high_contrast:
			_fx.draw_arc(at + Vector2(0, -3), 6.0 + 12.0 * k, 0.0, TAU, 24, Palette.CONTRAST_ENEMY, 2.0)
		for i in 6:
			var dir := Vector2.from_angle(TAU * i / 6.0 + 0.4)
			_fx.draw_line(at, at + dir * (8.0 + 14.0 * k), Color(1.0, 0.85, 0.4, 0.9), 1.0)
	for puff: Dictionary in _steam:
		var t: float = 1.0 - puff["life"] / 0.6
		var at: Vector2 = puff["at"] - origin + Vector2(0, -10 - t * 14.0)
		_fx.draw_circle(at, 3.0 + t * 6.0, Color(0.9, 0.92, 0.95, 0.5 * (1.0 - t)))
