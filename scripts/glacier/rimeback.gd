class_name Rimeback
extends Enemy
## Hollow Glacier's boss: an ancient walrus with an iceberg grown on its
## back, living in the black water under the glacier's floor.
##
## The fight:
##   1. It surfaces in one of the room's breath holes (its pools of water),
##      eyes squeezed shut, and spits chunks of ice (the tell: head back,
##      mouth open). Arrows and the sword glance off it. Then it dives.
##   2. Frost arrows freeze a breath hole over. With every hole frozen it
##      has nowhere to breathe: the ice under one hole groans and cracks
##      (the tell), and it bursts up through it.
##   3. Dazed, its eyes are wide open: shoot them (or strike it). It
##      thrashes, every hole cracks open again, and it goes back under.

enum Mode { INTRO, UNDER, RISE, UP, SPIT, DIVE, BREACH, DAZED, DYING }

const DEFEATED_FLAG := "boss_glacier"
const UNDER_TIME := 1.6
const RISE_TIME := 0.5
const UP_TIME := 3.2
const SPIT_TELL := 0.5
const DIVE_TIME := 0.45
const BREACH_TELL := 1.3
const DAZED_TIME := 4.5
## Hits it takes while dazed before it thrashes free.
const HITS_PER_DAZE := 2
const CHUNK_SPEED := 85.0
## Where on the sheet (64x56 frames).
const FRAME_UP := 0
const FRAME_SPIT := 1
const FRAME_DAZED := 2
const FRAME_UNDER := 3

var mode := Mode.INTRO
## Each breath hole: {"tiles": Array[Vector2i], "center": Vector2 (room-local)}.
var holes: Array = []
var hole := -1
var _room: Room
## Its entrance, gliding under the ice before it first goes for a hole.
const INTRO_TIME := 2.0
var _timer := INTRO_TIME
var _spits := 0
var _cracks: Node2D
var _hits_this_daze := 0
## Holes to crack open again once Wren steps off them.
var _to_thaw: Array[Vector2i] = []


## What a V tile becomes in Hollow Glacier: the walrus, or, once it's
## beaten, the Frost Bell and the way out.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	# Beaten for good, unless Wren has come back to its echo (EchoTrial).
	if GameState.flags.get(DEFEATED_FLAG, false) and not EchoTrial.here(room):
		var after := BossAftermath.new()
		after.room = room
		after.boss_spot = pos
		return after
	var boss := Rimeback.new()
	if EchoTrial.here(room):
		EchoTrial.dress(room)
	boss._room = room
	return boss


func _init() -> void:
	max_hp = 6
	contact_damage = 1
	body_size = Vector2(40, 14)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if _room == null:
		_room = get_parent() as Room
	# It lives in the water: nothing in the room stops it, and Wren can't
	# walk into it (it's in a hole).
	collision_mask = 0
	collision_layer = 0
	_set_shown(false)
	_cracks = Node2D.new()
	_cracks.name = "BreachCracks"
	_cracks.z_index = 1
	_cracks.draw.connect(_draw_cracks)
	add_child(_cracks)
	Events.toast.emit("BOSS_RIMEBACK")
	# Its entrance: a great shadow slides under the ice, and the ice groans.
	Audio.play_sfx("ice_groan", global_position, 0.7)
	Feel.shake(2.0)
	call_deferred("_find_holes")


## Every pool of water in the room is a breath hole.
func _find_holes() -> void:
	var seen := {}
	for y in Room.ROWS:
		for x in Room.COLS:
			var t := Vector2i(x, y)
			if seen.has(t) or _room.tile_at(x, y) != "~":
				continue
			var tiles := _room.water_pool(t)
			var sum := Vector2.ZERO
			for p: Vector2i in tiles:
				seen[p] = true
				sum += Vector2(p) * Room.TILE + Vector2(Room.TILE, Room.TILE) / 2.0
			holes.append({"tiles": tiles, "center": sum / tiles.size()})


func is_hole_frozen(i: int) -> bool:
	for t: Vector2i in holes[i]["tiles"]:
		if not _room.is_frozen(t):
			return false
	return true


func _set_shown(shown: bool) -> void:
	_hurtbox.collision_layer = (1 << (Layers.ENEMY_HURTBOX - 1)) if shown else 0
	# Not while it's still rising: the splash is the warning, not a hit.
	_contact.active = shown and mode in [Mode.UP, Mode.SPIT]


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	_thaw_waiting()
	var wren := get_player()
	match mode:
		Mode.INTRO:
			if _timer <= 0.0:
				_enter(Mode.UNDER, 0.6)
		Mode.UNDER:
			if _timer <= 0.0 and not holes.is_empty():
				_come_up(wren)
		Mode.RISE:
			if _timer <= 0.0:
				_spits = 0
				_enter(Mode.UP, UP_TIME * 0.35)
		Mode.UP:
			# Sitting in its hole: if an arrow freezes the hole round it, the
			# ice just cracks again.
			# (Never under Wren, though: that tile waits till they step off.)
			if hole >= 0 and _any_frozen(hole):
				_thaw_hole(hole)
			if _timer <= 0.0:
				if _spits < (3 if hp * 2 <= max_hp else 2):
					_enter(Mode.SPIT, SPIT_TELL)
					Audio.play_sfx("rime_gather", global_position)
				else:
					_enter(Mode.DIVE, DIVE_TIME)
					Audio.play_sfx("splash", global_position, 0.7)
		Mode.SPIT:
			if _timer <= 0.0:
				_spit(wren)
				_spits += 1
				_enter(Mode.UP, UP_TIME * 0.3)
		Mode.DIVE:
			if _timer <= 0.0:
				_set_shown(false)
				_enter(Mode.UNDER, UNDER_TIME * (0.7 if hp * 2 <= max_hp else 1.0))
		Mode.BREACH:
			if int(_timer * 10.0) % 3 == 0:
				Feel.shake(0.8)
			if _timer <= 0.0:
				_burst(wren)
		Mode.DAZED:
			if _timer <= 0.0 or _hits_this_daze >= HITS_PER_DAZE:
				_thrash()


func _enter(new_mode: Mode, time: float) -> void:
	mode = new_mode
	_timer = time
	_contact.active = _hurtbox.collision_layer != 0 and mode in [Mode.UP, Mode.SPIT]


## Up into an open hole, or, with every hole frozen, up through the ice.
func _come_up(wren: Player) -> void:
	var open: Array[int] = []
	var held: Array[int] = []
	for i in holes.size():
		if is_hole_frozen(i):
			continue
		# A hole with ice still waiting to thaw under Wren is a last resort.
		if _holds_waiting(i):
			held.append(i)
		else:
			open.append(i)
	if open.is_empty():
		open = held
	if open.is_empty():
		# Nowhere to breathe: it breaks through under the hole nearest Wren.
		hole = _nearest_hole(wren)
		position = holes[hole]["center"] + Vector2(0, 8)
		_enter(Mode.BREACH, BREACH_TELL)
		Audio.play_sfx("ice_groan", global_position)
		return
	if open.size() > 1:
		open.erase(hole)
	hole = open[randi() % open.size()]
	position = holes[hole]["center"] + Vector2(0, 8)
	_set_shown(true)
	_enter(Mode.RISE, RISE_TIME)
	Audio.play_sfx("splash", global_position, 0.6)


func _nearest_hole(wren: Player) -> int:
	if wren == null:
		return 0
	var at := wren.global_position - _room.global_position
	var best := 0
	for i in holes.size():
		if (holes[i]["center"] as Vector2).distance_to(at) < (holes[best]["center"] as Vector2).distance_to(at):
			best = i
	return best


func _burst(wren: Player) -> void:
	_thaw_hole(hole)
	_set_shown(true)
	_hits_this_daze = 0
	_enter(Mode.DAZED, DAZED_TIME)
	Audio.play_sfx("ice_shatter", global_position, 0.6)
	Audio.play_sfx("walrus_bellow", global_position)
	Feel.shake(4.0)
	# Standing right over it, Wren is thrown back.
	if wren and wren.global_position.distance_to(global_position + Vector2(0, -8)) < 30.0:
		wren.take_damage(1, global_position)


## Back under, and every hole cracks open again.
func _thrash() -> void:
	Audio.play_sfx("walrus_bellow", global_position, 1.2)
	Feel.shake(3.0)
	for i in holes.size():
		_thaw_hole(i)
	_enter(Mode.DIVE, DIVE_TIME)


## Thaws a hole now, except under Wren's feet: that waits till they step off.
func _any_frozen(i: int) -> bool:
	for t: Vector2i in holes[i]["tiles"]:
		if _room.is_frozen(t):
			return true
	return false


func _holds_waiting(i: int) -> bool:
	for t: Vector2i in holes[i]["tiles"]:
		if _to_thaw.has(t):
			return true
	return false


func _thaw_hole(i: int) -> void:
	var now: Array[Vector2i] = []
	for t: Vector2i in holes[i]["tiles"]:
		if not _room.is_frozen(t):
			continue
		if _wren_on(t):
			if not _to_thaw.has(t):
				_to_thaw.append(t)
		else:
			now.append(t)
	if not now.is_empty():
		_room.thaw(now)


func _thaw_waiting() -> void:
	if _to_thaw.is_empty():
		return
	var now: Array[Vector2i] = []
	for t in _to_thaw.duplicate():
		if not _wren_on(t):
			now.append(t)
			_to_thaw.erase(t)
	if not now.is_empty():
		_room.thaw(now)


func _wren_on(t: Vector2i) -> bool:
	var wren := get_player()
	if wren == null:
		return false
	var local := wren.global_position - _room.global_position
	# Wren's body, not just one point under their feet.
	var r := Rect2(local + Vector2(-6, -8), Vector2(12, 8))
	return r.intersects(Rect2(Vector2(t) * Room.TILE, Vector2(Room.TILE, Room.TILE)))


func _spit(wren: Player) -> void:
	var to := Vector2.DOWN if wren == null else (wren.global_position - global_position + Vector2(0, 12))
	var aim := to.angle()
	var count := 5 if hp * 2 <= max_hp else 3
	for i in count:
		var chunk := IceChunk.new()
		chunk.velocity = Vector2.from_angle(aim + (i - (count - 1) / 2.0) * 0.3) * CHUNK_SPEED
		get_parent().add_child(chunk)
		chunk.global_position = global_position + Vector2(0, -14)
	Audio.play_sfx("enemy_shot", global_position, 0.7)


## Frost arrows: they glance off unless its eyes are open.
func arrow_hit(direction: Vector2) -> void:
	take_hit(1, direction)


func _blocks_hit(_direction: Vector2) -> bool:
	return mode != Mode.DAZED


func _on_blocked(_direction: Vector2) -> void:
	_flash = 0.03
	Audio.play_sfx("block", global_position, 1.4)


func _on_hurt() -> void:
	_hits_this_daze += 1
	Audio.play_sfx("walrus_bellow", global_position, 1.4)
	Feel.shake(1.5)


func hook_hit(_direction: Vector2) -> bool:
	return false


func _die() -> void:
	dying = true
	mode = Mode.DYING
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	GameState.flags[DEFEATED_FLAG] = true
	Events.boss_defeated.emit()
	_sprite.position = _sprite_origin
	_sprite.frame = FRAME_DAZED
	Audio.play_sfx("walrus_bellow", global_position, 0.6)
	for i in 4:
		_shudder_flash(0.1)
		Feel.shake(2.0)
		await get_tree().create_timer(0.25).timeout
		if not is_inside_tree():
			return
	# It sinks for the last time, and the holes freeze over behind it.
	Audio.play_sfx("boss_fall", global_position, 0.7)
	_sprite.frame = FRAME_UNDER
	_dissolve()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, 10), 1.4)
	tween.tween_property(self, "modulate:a", 0.0, 1.4)
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
	return Art.sprite(GlacierSprites.RIMEBACK, 4, 1, 54)


func _update_sprite() -> void:
	if _cracks:
		_cracks.queue_redraw()
	if mode == Mode.DYING:
		return
	_sprite.visible = mode != Mode.UNDER
	_sprite.modulate = Color.WHITE
	match mode:
		Mode.INTRO:
			# A shadow under the ice, gliding in to its first hole.
			_sprite.frame = FRAME_UNDER
			_sprite.modulate = Color(0.08, 0.14, 0.24, 0.55 * clampf(_timer * 2.0, 0.0, 1.0))
			_sprite.position.x -= 120.0 * (_timer / INTRO_TIME)
		Mode.RISE:
			_sprite.frame = FRAME_UNDER
			_sprite.position.y += 10.0 * (_timer / RISE_TIME)
		Mode.SPIT:
			_sprite.frame = FRAME_SPIT
			_jitter(_timer)
		Mode.DIVE:
			_sprite.frame = FRAME_UNDER
			_sprite.position.y += 10.0 * (1.0 - _timer / DIVE_TIME)
		Mode.BREACH:
			# A shadow under the ice, the ice groaning, and cracks spreading
			# over the spot it will burst through (see _draw).
			_sprite.frame = FRAME_UNDER
			_sprite.modulate.a = 0.35
			_jitter(_timer)
		Mode.DAZED:
			_sprite.frame = FRAME_DAZED
		_:
			_sprite.frame = FRAME_UP


## The breach tell drawn on the ice: cracks spreading out from the spot it
## bursts through, as far as the burst throws Wren, so it can be seen as
## well as heard. On its own layer, above the frozen holes.
func _draw_cracks() -> void:
	if mode != Mode.BREACH:
		return
	var k := clampf(1.0 - _timer / BREACH_TELL, 0.0, 1.0)
	var center := Vector2(0, -8)
	var crack := Color(0.1, 0.24, 0.42, 0.55 + 0.45 * k)
	for i in 7:
		var dir := Vector2.from_angle(TAU * i / 7.0 + 0.3)
		var bend := dir.rotated(0.5 if i % 2 == 0 else -0.5)
		var mid := center + dir * 14.0 * k
		_cracks.draw_line(center, mid, crack, 1.0)
		_cracks.draw_line(mid, mid + bend * 16.0 * k, crack, 1.0)
	_cracks.draw_arc(center, 30.0 * k, 0.0, TAU, 24, Color(crack, 0.4 * k), 1.0)


## No puffs while it sinks or surfaces: only when it is up out of the ice.
func _shows_wear() -> bool:
	return mode in [Mode.UP, Mode.SPIT, Mode.DAZED]
