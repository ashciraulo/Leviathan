class_name PaleCongregation
extends Enemy
## Lantern Mire's boss: the leaked dreams of the drowned, gathered round a
## pale heart into the shape of a leviathan calf, swimming through the dark.
##
## The fight:
##   1. Whole, the calf swims after Wren. Its wisps crowd round the heart,
##      and the sword can't get through them. Touching the calf hurts.
##   2. Raise the Glowmoth Lantern and the wisps leave the heart for its
##      light, and the heart is bare: strike it. But they circle Wren,
##      closer and closer, and burn if they reach Wren.
##   3. Lower it and they drift home, slowly; the heart stays bare until
##      half of them are back. Raised again, they pick up where they left
##      off: the circle only widens again while they're home.
## Below half strength it gathers itself (the heart thuds and the calf
## brightens) and lunges at Wren, whatever the wisps are doing. Six
## strikes and the dreams scatter.

enum Mode { INTRO, SWIM, TELL, LUNGE, DYING }

const DEFEATED_FLAG := "boss_mire"
const SWIM_SPEED := 18.0
const LUNGE_SPEED := 150.0
const LUNGE_TIME := 0.6
const TELL_TIME := 0.9
const LUNGE_EVERY := 5.0
## Wisps: how fast they go home, and how they close in round the lantern.
const HOME_SPEED := 34.0
const PULL_SPEED := 90.0
const ORBIT_START := 64.0
const ORBIT_SHRINK := 14.0
const ORBIT_SPIN := 2.4
## The heart floats this far above its shadow.
const LIFT := 14.0
## Where it may swim: the open floor, clear of the border walls.
const ARENA := Rect2(3.0 * 16.0, 3.0 * 16.0, 18.0 * 16.0, 8.0 * 16.0)

## How long wisps stay harmless after the lantern goes up, while they fly
## out to the ring.
const WISP_SETTLE := 0.5
var _since_lantern := 99.0
var mode := Mode.INTRO
## Formation slots (the calf's outline), relative to the heart, facing right.
var slots: Array[Vector2] = []
## Each wisp: {"at": position in the room, "home": bool, "area": DamageArea}.
var wisps: Array[Dictionary] = []
var _timer := 1.6
var _lunge_timer := LUNGE_EVERY
var _lunge_dir := Vector2.ZERO
var _facing := 1.0
var _orbit := ORBIT_START
var _orbit_angle := 0.0
var _was_raised := false
var _room: Room
var _swarm: Node2D
var _beat := 0.0


## What a V tile becomes in Lantern Mire: the Congregation, or, once it's
## been laid to rest, the Moth Bell and the way out.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	# Beaten for good, unless Wren has come back to its echo (EchoTrial).
	if GameState.flags.get(DEFEATED_FLAG, false) and not EchoTrial.here(room):
		var after := BossAftermath.new()
		after.room = room
		after.boss_spot = pos
		return after
	var boss := PaleCongregation.new()
	if EchoTrial.here(room):
		EchoTrial.dress(room)
	boss._room = room
	return boss


## The calf's outline: a round body, a blunt head, two fins and a long tail
## (22 points, heart at the origin, head to the right).
static func calf_shape() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in 12:
		var angle := TAU * i / 12.0
		points.append(Vector2(cos(angle) * 24.0, sin(angle) * 13.0))
	points.append(Vector2(31, -3))
	points.append(Vector2(31, 4))
	points.append(Vector2(-4, 21))
	points.append(Vector2(6, 25))
	points.append(Vector2(-4, -21))
	points.append(Vector2(-32, 0))
	points.append(Vector2(-40, -2))
	points.append(Vector2(-47, -6))
	points.append(Vector2(-49, 2))
	points.append(Vector2(-54, -10))
	return points


func _init() -> void:
	max_hp = 6
	contact_damage = 1
	body_size = Vector2(16, 10)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if _room == null:
		_room = get_parent() as Room
	# It swims over the black water: only walls stop it.
	collision_mask = 1 << (Layers.WORLD - 1)
	slots = calf_shape()
	_swarm = Node2D.new()
	_swarm.name = "Congregation"
	_swarm.z_index = 2
	_swarm.draw.connect(_draw_swarm)
	get_parent().add_child.call_deferred(_swarm)
	for i in slots.size():
		var area := DamageArea.new()
		area.damage = 1
		area.monitoring = false
		Layers.assign(area, Layers.ENEMY_ATTACK, [])
		area.add_child(Layers.circle_shape(4.0, Vector2.ZERO))
		_swarm.add_child(area)
		# They gather out of the dark, from all round the room.
		var start := position + Vector2.from_angle(TAU * i / slots.size()) * 140.0
		start = Vector2(clampf(start.x, 24.0, Room.SIZE.x - 24.0), clampf(start.y, 24.0, Room.SIZE.y - 24.0))
		wisps.append({"at": start, "home": false, "area": area})
	_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 1.0, 1.2)
	Events.toast.emit("BOSS_PALE_CONGREGATION")
	Audio.play_sfx("boss_roar", global_position, 1.6)
	Feel.shake(2.0)


func _exit_tree() -> void:
	if is_instance_valid(_swarm):
		_swarm.queue_free()


## The heart's centre, where the wisps gather (in the room).
func heart_point() -> Vector2:
	return position + Vector2(0, -LIFT)


## Where Wren is, in the room.
func _wren_point(wren: Player) -> Vector2:
	return wren.global_position - get_parent().global_position


func home_count() -> int:
	return wisps.filter(func(w: Dictionary) -> bool: return w["home"]).size()


## Bare: fewer than half the wisps are round it.
func is_exposed() -> bool:
	return home_count() * 2 < wisps.size()


## The wisps move every frame, even while the heart is stunned or dying.
func _process(delta: float) -> void:
	_beat += delta
	var wren := get_player()
	var raised := wren != null and wren.lantern_raised and mode != Mode.DYING
	_move_wisps(delta, wren, raised)


func _think(delta: float) -> void:
	var wren := get_player()
	_timer -= delta
	var to_wren := Vector2.ZERO if wren == null else wren.global_position - global_position
	match mode:
		Mode.INTRO:
			velocity = Vector2.ZERO
			# Still gathering out of the dark: its touch doesn't hurt yet.
			_contact.active = _timer <= 0.0
			if _timer <= 0.0:
				mode = Mode.SWIM
		Mode.SWIM:
			velocity = to_wren.normalized() * SWIM_SPEED if to_wren.length() > 24.0 else Vector2.ZERO
			if hp * 2 <= max_hp:
				_lunge_timer -= delta
				if _lunge_timer <= 0.0:
					mode = Mode.TELL
					_timer = TELL_TIME
					Audio.play_sfx("heart_beat", global_position, 0.8)
					Audio.play_sfx("congregation_tell", global_position)
		Mode.TELL:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.LUNGE
				_timer = LUNGE_TIME
				_lunge_dir = to_wren.normalized()
		Mode.LUNGE:
			velocity = _lunge_dir * LUNGE_SPEED
			if _timer <= 0.0:
				mode = Mode.SWIM
				_lunge_timer = LUNGE_EVERY
	if absf(velocity.x) > 1.0:
		_facing = signf(velocity.x)
	position = Vector2(clampf(position.x, ARENA.position.x, ARENA.end.x), clampf(position.y, ARENA.position.y, ARENA.end.y))


func _move_wisps(delta: float, wren: Player, raised: bool) -> void:
	if raised and not _was_raised:
		Audio.play_sfx("wisp_chime", global_position)
	# Only a fresh raise gives them their moment to fly out (flicking the
	# lantern up and down doesn't keep them harmless).
	if raised and not _was_raised and _since_lantern >= WISP_SETTLE * 3.0:
		_since_lantern = 0.0
	_since_lantern += delta
	_was_raised = raised
	if raised:
		_orbit = maxf(_orbit - ORBIT_SHRINK * delta, 6.0)
		_orbit_angle += ORBIT_SPIN * delta
	elif not is_exposed():
		# Gathered home again: next time they'll start out wide.
		_orbit = ORBIT_START
	var center := heart_point()
	for i in wisps.size():
		var wisp: Dictionary = wisps[i]
		var at: Vector2 = wisp["at"]
		if mode == Mode.DYING:
			# Released: they rise away into the dark.
			at += Vector2(sin(_beat * 3.0 + i) * 10.0, -40.0) * delta
			wisp["home"] = false
		elif raised:
			wisp["home"] = false
			var spot := _wren_point(wren) + Vector2(0, -8) + Vector2.from_angle(_orbit_angle + TAU * i / wisps.size()) * _orbit
			at = at.move_toward(spot, PULL_SPEED * delta)
		else:
			var slot := slots[i]
			var spot := center + Vector2(slot.x * _facing, slot.y)
			# Once home, they keep their place in the calf's outline.
			var speed := 400.0 if wisp["home"] else HOME_SPEED * (1.0 if mode != Mode.INTRO else 3.0)
			at = at.move_toward(spot, speed * delta)
			if at.distance_to(spot) < 2.0:
				wisp["home"] = true
		wisp["at"] = at
		var area: DamageArea = wisp["area"]
		area.position = at
		# Gathering out of the dark at the start, they don't burn yet; nor
		# for a moment after the lantern goes up (WISP_SETTLE), while they
		# stream out of the calf to the ring round Wren, so raising the
		# lantern never burns Wren as they fly past.
		var settled: bool = not raised or _since_lantern >= WISP_SETTLE
		area.active = mode != Mode.DYING and mode != Mode.INTRO and settled
	_swarm.queue_redraw()


func _blocks_hit(_direction: Vector2) -> bool:
	return not is_exposed() or mode == Mode.INTRO


func _on_blocked(_direction: Vector2) -> void:
	Audio.play_sfx("block", global_position)
	_flash = 0.03


func _on_hurt() -> void:
	Audio.play_sfx("heart_beat", global_position, 1.2)
	Feel.shake(1.5)
	# The calf pulls itself back together, faster for a moment.
	for wisp in wisps:
		var area: DamageArea = wisp["area"]
		area.active = true
	_lunge_timer = minf(_lunge_timer, LUNGE_EVERY * 0.6)


func _die() -> void:
	dying = true
	mode = Mode.DYING
	Audio.play_sfx("boss_fall", global_position, 1.2)
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	# Through set_flag, so the story can answer (StoryDirector.the_calf).
	GameState.set_flag(DEFEATED_FLAG)
	Events.boss_defeated.emit()
	for wisp in wisps:
		var area: DamageArea = wisp["area"]
		area.active = false
		area.set_deferred("monitorable", false)
	# The heart beats out, slower and slower, and the dreams drift free.
	for i in 5:
		_flash = 0.1
		Audio.play_sfx("heart_beat", global_position, 1.0 - i * 0.1)
		Feel.shake(1.5)
		await get_tree().create_timer(0.3 + i * 0.12).timeout
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_property(_swarm, "modulate:a", 0.0, 1.0)
	await tween.finished
	var after := BossAftermath.new()
	after.room = _room if _room else get_parent() as Room
	after.boss_spot = _bell_spot()
	after.fresh = true
	get_parent().add_child(after)
	queue_free()


## The bell rises where the heart first hung (its V tile).
func _bell_spot() -> Vector2:
	if _room:
		for y in Room.ROWS:
			for x in Room.COLS:
				if _room.tile_at(x, y) == "V":
					return Vector2(x * Room.TILE + Room.TILE / 2.0, y * Room.TILE + Room.TILE - 4)
	return position


func _make_sprite() -> Sprite2D:
	var sprite := Art.sprite(MireSprites.HEART, 2, 1, 18)
	return sprite


func _update_sprite() -> void:
	_sprite.position.y -= LIFT + sin(_beat * 2.0) * 1.5
	var fast := mode == Mode.TELL or is_exposed()
	_sprite.frame = 1 if fmod(_beat, 0.5 if fast else 1.1) < 0.15 else 0
	if mode == Mode.TELL:
		_jitter(_timer)
	# Bare, it shivers: there's nothing round it.
	if mode == Mode.SWIM and is_exposed():
		_sprite.position.x += sin(_beat * 40.0) * 0.6


## The wisps (drawn by the boss so it can light them all at once).
func _draw_swarm() -> void:
	var origin := _swarm.position
	var bright := 1.0
	if mode == Mode.TELL:
		bright = 1.0 + 0.6 * (1.0 - _timer / TELL_TIME)
	for i in wisps.size():
		var at: Vector2 = wisps[i]["at"] - origin
		var glow := Color(0.56, 0.89, 0.78, 0.18 * bright)
		_swarm.draw_circle(at, 6.0, glow)
		if Settings.high_contrast:
			_swarm.draw_arc(at + Vector2(0, -2), 7.0, 0.0, TAU, 16, Palette.CONTRAST_ENEMY, 1.0)
		var frame := (int(_beat * 5.0) + i) % 2
		_swarm.draw_texture_rect_region(MireSprites.WISP, Rect2(at - Vector2(5, 8), Vector2(10, 12)), Rect2(frame * 10, 0, 10, 12), Color(bright, bright, bright, 1.0))
