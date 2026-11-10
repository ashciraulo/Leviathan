class_name Gumleech
extends Enemy
## A fat leech of the Old One's palate (the Maw), pale as gum, living in
## the palate floor (","). While the breath floods it, the leech swims
## under the water, only its back and glowing spots showing, and no sword
## can reach it. Near Wren it rears up out of the water with a wet gurgle,
## mouth open (the tell), then lunges out to bite and squirms back home.
## Reared or lunging it can be struck. When the breath drains the floor it
## is left stranded, flopping slowly after Wren: the time to finish it.

enum Mode { SWIM, RISE, BITE, RETURN, STRANDED }

const SWIM_SPEED := 38.0
const CRAWL_SPEED := 9.0
const SIGHT := 150.0
## How close Wren has to be before it rears up.
const LUNGE_RANGE := 40.0
const RISE_TIME := 0.6
const BITE_TIME := 0.28
const BITE_SPEED := 120.0
const RETURN_SPEED := 55.0
## Waits under the water after a bite before it can rear again.
const COOLDOWN := 1.3
## Swimming, it holds off this far from Wren rather than slide under them.
const HOLD_OFF := 22.0
## A squirm home that takes longer than this heads for the nearest palate.
const RETURN_LIMIT := 1.5

var mode := Mode.SWIM
## Which way it bites (set as it rears).
var aim := Vector2.RIGHT
## Where it last swam: it squirms back here after a bite.
var home := Vector2.ZERO
var _timer := 0.0
## Whether this squirm home has already given up on `home` once.
var _retargeted := false
var _wiggle := 0.0
var _shadow: Node2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 8)


func _ready() -> void:
	super()
	# It lives in the water: walls and enemies stop it, the flood doesn't.
	Layers.assign(self, Layers.ENEMY, [Layers.WORLD, Layers.ENEMY])
	for child in get_children():
		if child is Sprite2D and child != _sprite:
			_shadow = child
	home = position
	_wiggle = randf() * TAU
	mode = Mode.SWIM if _flooded() else Mode.STRANDED
	_apply_mode()


func _flooded() -> bool:
	var room := get_parent() as Room
	return room != null and room.flooded()


## True when the room's layout has palate floor (",") under `at` (room-local).
func _palate(at: Vector2) -> bool:
	var room := get_parent() as Room
	if room == null:
		return false
	return room.raw_tile(floori(at.x / Room.TILE), floori((at.y - 2.0) / Room.TILE)) == ","


func _think(delta: float) -> void:
	_timer -= delta
	_wiggle += delta * 6.0
	var player := get_player()
	var flooded := _flooded()
	match mode:
		Mode.SWIM:
			if not flooded:
				_set_mode(Mode.STRANDED)
				return
			if not _palate(position):
				_set_mode(Mode.RETURN)
				_timer = RETURN_LIMIT
				return
			home = position
			velocity = Vector2.ZERO
			if player == null or player.frozen:
				return
			var to := player.global_position - global_position
			if to.length() > SIGHT:
				return
			if to.length() < LUNGE_RANGE and _timer <= 0.0:
				aim = to.normalized()
				_set_mode(Mode.RISE)
				_timer = RISE_TIME
				Audio.play_sfx("leech_rise", global_position)
				return
			if to.length() > HOLD_OFF:
				velocity = _keep_to_palate(to.normalized() * SWIM_SPEED, delta)
		Mode.RISE:
			velocity = Vector2.ZERO
			if player != null:
				aim = (player.global_position - global_position).normalized()
			if _timer <= 0.0:
				_set_mode(Mode.BITE)
				_timer = BITE_TIME
				Audio.play_sfx("leech_bite", global_position)
		Mode.BITE:
			velocity = aim * BITE_SPEED
			if _timer <= 0.0:
				_set_mode(Mode.RETURN)
				_timer = RETURN_LIMIT
		Mode.RETURN:
			if _timer <= 0.0:
				# Blocked on the way home (a post, another leech): make for the
				# nearest palate floor instead, and failing that settle here.
				home = _nearest_palate() if not _retargeted else position
				_retargeted = true
				_timer = RETURN_LIMIT
			var back := home - position
			if back.length() < 2.0:
				position = home
				velocity = Vector2.ZERO
				_set_mode(Mode.SWIM if flooded else Mode.STRANDED)
				_timer = COOLDOWN
			else:
				velocity = back.normalized() * RETURN_SPEED
		Mode.STRANDED:
			if flooded:
				if _palate(position):
					_set_mode(Mode.SWIM)
					_timer = COOLDOWN * 0.5
				else:
					_set_mode(Mode.RETURN)
					_timer = RETURN_LIMIT
				return
			velocity = Vector2.ZERO
			if player != null and player.global_position.distance_to(global_position) < SIGHT:
				var to := (player.global_position - global_position).normalized()
				velocity = _keep_to_palate(to * CRAWL_SPEED * (0.5 + 0.5 * absf(sin(_wiggle))), delta)
				if _palate(position):
					home = position


## Lets the move only where it stays on palate floor, sliding along the
## shore when the straight way would leave it.
func _keep_to_palate(want: Vector2, delta: float) -> Vector2:
	if _palate(position + want * delta + want.normalized() * 6.0):
		return want
	for slide: Vector2 in [Vector2(want.x, 0.0), Vector2(0.0, want.y)]:
		if slide.length() > 0.5 and _palate(position + slide * delta + slide.normalized() * 6.0):
			return slide
	return Vector2.ZERO


## The middle of the palate tile nearest the leech (room-local feet).
func _nearest_palate() -> Vector2:
	var room := get_parent() as Room
	var best := home
	var best_d := INF
	if room == null:
		return best
	for y in Room.ROWS:
		for x in Room.COLS:
			if room.raw_tile(x, y) != ",":
				continue
			var at := Vector2(x * Room.TILE + Room.TILE / 2.0, y * Room.TILE + Room.TILE - 4)
			var d := at.distance_squared_to(position)
			if d < best_d:
				best_d = d
				best = at
	return best


## Under the water nothing reaches it: not the sword, nor a hook, arrow,
## bomb or a diver's strike.
func take_hit(damage: int, direction: Vector2) -> HitResult:
	if mode == Mode.SWIM:
		return HitResult.IGNORED
	return super.take_hit(damage, direction)


func _set_mode(next: Mode) -> void:
	mode = next
	_retargeted = false
	_apply_mode()


## Under the water nothing reaches it, and it touches nothing. Only the
## bite itself hurts (and touching it stranded): rearing is the tell, and
## squirming home it keeps its mouth shut.
func _apply_mode() -> void:
	var under := mode == Mode.SWIM
	_hurtbox.set_deferred("monitorable", not under)
	_hurtbox.set_deferred("collision_layer", 0 if under else 1 << (Layers.ENEMY_HURTBOX - 1))
	_contact.active = mode in [Mode.BITE, Mode.STRANDED]
	if _shadow:
		_shadow.visible = not under
	z_index = -1 if under else 0


func is_submerged() -> bool:
	return mode == Mode.SWIM


func is_stranded() -> bool:
	return mode == Mode.STRANDED


func _make_sprite() -> Sprite2D:
	return Art.sprite(MawSprites.GUMLEECH, 4, 1, 14)


func _update_sprite() -> void:
	match mode:
		Mode.SWIM:
			_sprite.frame = 0
			_sprite.position.y += sin(_wiggle * 0.5)
		Mode.RISE:
			_sprite.frame = 1
			if ai_enabled:
				_jitter(_timer)
		Mode.BITE, Mode.RETURN:
			_sprite.frame = 2
			_sprite.flip_h = (aim.x < 0.0) if mode == Mode.BITE else (velocity.x < 0.0)
		Mode.STRANDED:
			_sprite.frame = 3
			_sprite.flip_h = sin(_wiggle * 0.5) > 0.0
			_sprite.position.y += -absf(sin(_wiggle)) * 1.5
