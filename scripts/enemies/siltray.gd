class_name Siltray
extends Enemy
## A sand-coloured ray of the Sunken Verge's flats (layout letter d).
## When the tide is in it glides under the water with only its fin
## showing, and blades can't reach it. When Wren comes near the water's
## edge the fin rears and foams (the tell) and it flings itself at them.
## It lands on whatever is there: on dry ground or bare sand it's
## stranded, flopping and open to the sword, until the water reaches it.

enum Mode { SWIM, REAR, LEAP, STRANDED }

const SWIM_SPEED := 46.0
const FLOP_SPEED := 10.0
const REACH := 46.0
const REAR_TIME := 0.55
const LEAP_SPEED := 150.0
const LEAP_TIME := 0.32
const STRAND_MIN := 1.4

var mode := Mode.SWIM
var _timer := 0.0
var _direction := Vector2.ZERO
var _tide: Tide


func _init() -> void:
	max_hp = 2
	body_size = Vector2(18, 8)


func _ready() -> void:
	super._ready()
	# It swims over the flooded flats, so the water doesn't stop it.
	Layers.assign(self, Layers.ENEMY, [Layers.WORLD, Layers.ENEMY])
	_tide = get_parent().get_node_or_null("Tide") as Tide
	_set_mode(Mode.SWIM if _in_water(position) else Mode.STRANDED)


func _tile(local: Vector2) -> Vector2i:
	return Vector2i(floori(local.x / Room.TILE), floori((local.y - 2.0) / Room.TILE))


func _in_water(local: Vector2) -> bool:
	return _tide != null and _tide.is_swimmable(_tile(local))


func _set_mode(next: Mode) -> void:
	mode = next
	_contact.active = mode in [Mode.LEAP, Mode.STRANDED]
	# Under the water nothing can catch or cut it (the Tide Hook included).
	_hurtbox.set_deferred("monitorable", mode != Mode.SWIM)
	match mode:
		Mode.REAR:
			_timer = REAR_TIME
		Mode.LEAP:
			_timer = LEAP_TIME
		Mode.STRANDED:
			_timer = STRAND_MIN


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	match mode:
		Mode.SWIM:
			if not _in_water(position):
				_set_mode(Mode.STRANDED)
				return
			velocity = Vector2.ZERO
			if player == null:
				return
			var to := player.global_position - global_position
			if to.length() < REACH and _room_has(player):
				_direction = to.normalized()
				velocity = Vector2.ZERO
				_set_mode(Mode.REAR)
				Audio.play_sfx("ray_splash", global_position)
				return
			# Shadow Wren along the water, never leaving it.
			var step := to.normalized() * SWIM_SPEED
			for dir in [step, Vector2(step.x, 0.0), Vector2(0.0, step.y)]:
				if dir != Vector2.ZERO and _in_water(position + dir.normalized() * 10.0):
					velocity = dir
					break
		Mode.REAR:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_set_mode(Mode.LEAP)
		Mode.LEAP:
			velocity = _direction * LEAP_SPEED
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				velocity = Vector2.ZERO
				_set_mode(Mode.SWIM if _in_water(position) else Mode.STRANDED)
		Mode.STRANDED:
			# Flop toward the water if there's any close by.
			velocity = Vector2.ZERO
			if _in_water(position) and _timer <= 0.0:
				_set_mode(Mode.SWIM)
				return
			for reach in range(1, 4):
				for dir: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
					if velocity == Vector2.ZERO and _in_water(position + dir * Room.TILE * reach):
						velocity = dir * FLOP_SPEED * 3.0
			if velocity == Vector2.ZERO and int(_timer * 2.0) % 3 == 0:
				velocity = Vector2(signf(sin(_timer * 7.0)), 0.0) * FLOP_SPEED
	var margin := Vector2(12, 12)
	position = position.clamp(margin, Room.SIZE - margin)


func _room_has(player: Node2D) -> bool:
	var room := get_parent() as Node2D
	return room != null and Rect2(Vector2.ZERO, Room.SIZE).has_point(player.global_position - room.global_position)


## Under the water, a blade can't find it.
func take_hit(damage: int, direction: Vector2) -> HitResult:
	if mode == Mode.SWIM:
		return HitResult.IGNORED
	return super.take_hit(damage, direction)


func _make_sprite() -> Sprite2D:
	return Art.sprite(VergeSprites.SILTRAY, 5, 1, 12)


func _update_sprite() -> void:
	match mode:
		Mode.SWIM:
			_sprite.frame = 0
		Mode.REAR:
			_sprite.frame = 1
			if ai_enabled:
				_jitter(_timer)
		Mode.LEAP:
			_sprite.frame = 2
			_sprite.flip_h = _direction.x < 0.0
		Mode.STRANDED:
			_sprite.frame = 3 + int(Time.get_ticks_msec() / 220) % 2
