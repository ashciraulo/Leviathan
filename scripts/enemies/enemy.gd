class_name Enemy
extends CharacterBody2D
## Base for enemies: health, hit reaction, knockback, contact damage and death.
## Subclasses set their stats in _init(), steer in _think(), build their
## sprite in _make_sprite() and pick its frame in _update_sprite().
##
## Every enemy should have one readable tell (a wind-up, a flash, a sound)
## before it attacks.

enum HitResult { IGNORED, HIT, BLOCKED }

const KNOCKBACK_SPEED := 200.0
const KNOCKBACK_DECAY := 900.0
const HIT_STUN := 0.25

@export var max_hp := 2
@export var contact_damage := 1
## Turn off to freeze the enemy's decisions (for tests and debugging).
@export var ai_enabled := true
## A region's elite (set before it enters the tree; see Room.elite): bigger,
## three times as hardy, tinted like old bronze, and its kind's pattern grows
## a second step (see each kind's _think). It roars when it first sees Wren,
## and drops a heap of glints when it falls.
var elite := false

const ELITE_HP := 3
const ELITE_SCALE := 1.3
const ELITE_TINT := Color(1.0, 0.8, 0.6)
const ELITE_GLINTS := 30
const ELITE_SIGHT := 110.0

## Size of the feet collision. The hurtbox is a little taller.
var body_size := Vector2(12, 8)
## 0 for rooted enemies that can't be pushed.
var knockback_scale := 1.0
var hp := 0
var dying := false

var _stun := 0.0
var _knockback := Vector2.ZERO
var _flash := 0.0
var _hurtbox: Area2D
var _contact: DamageArea
var _sprite: Sprite2D
var _sprite_origin := Vector2.ZERO
## The sprite's own scale, and the squash a landed blow gives it (see
## SQUASH_TIME).
var _sprite_base_scale := Vector2.ONE
var _squash := 0.0
var _roared := false
## A boss at half health or less is worn: puffs of strain rise off it now and
## then (see WEAR_EVERY), and the blow that wears it shakes the room.
const WEAR_EVERY := 0.85
var _wear_timer := 0.0
## Stars over a boss's head while the sword can hurt it (see is_boss_open).
var _daze_stars: DazeStars
## Cache for _art_top, by frame.
var _art_tops := {}


func _ready() -> void:
	if elite:
		max_hp *= ELITE_HP
	hp = max_hp
	add_to_group("enemies")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	Layers.assign(self, Layers.ENEMY, [Layers.WORLD, Layers.WATER, Layers.ENEMY, Layers.DEEP, Layers.GRATE])
	add_child(Layers.rect_shape(body_size, Vector2(0, -body_size.y / 2.0)))

	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	Layers.assign(_hurtbox, Layers.ENEMY_HURTBOX, [])
	_hurtbox.monitoring = false
	var hurt_size := body_size + Vector2(2, 6)
	_hurtbox.add_child(Layers.rect_shape(hurt_size, Vector2(0, -hurt_size.y / 2.0)))
	add_child(_hurtbox)

	_contact = DamageArea.new()
	_contact.name = "Contact"
	_contact.damage = contact_damage
	Layers.assign(_contact, Layers.ENEMY_ATTACK, [])
	_contact.monitoring = false
	_contact.add_child(Layers.rect_shape(body_size - Vector2(2, 0), Vector2(0, -body_size.y / 2.0)))
	add_child(_contact)

	add_child(Art.shadow(body_size.x > 14))
	_sprite = _make_sprite()
	_sprite.set_meta("contrast", Palette.CONTRAST_ENEMY)
	add_child(_sprite)
	_sprite_origin = _sprite.position
	_sprite_base_scale = _sprite.scale
	if elite:
		scale = Vector2.ONE * ELITE_SCALE
		_sprite.self_modulate = ELITE_TINT


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if dying:
		if _daze_stars:
			_daze_stars.visible = false
		return
	if elite and not _roared and ai_enabled:
		var wren := get_player()
		if wren and wren.global_position.distance_to(global_position) < ELITE_SIGHT:
			_roared = true
			Audio.play_sfx("boss_roar", global_position, 1.5)
			Feel.shake(1.5)
	if _stun > 0.0:
		_stun -= delta
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	elif ai_enabled and not Cutscene.active:
		_think(delta)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_sprite.position = _sprite_origin
	_update_sprite()
	if _squash > 0.0:
		_squash = maxf(_squash - delta, 0.0)
		var k := _squash / SQUASH_TIME
		var amount := SQUASH_BOSS if is_in_group("boss") else SQUASH
		_sprite.scale = _sprite_base_scale * Vector2(1.0 + amount * k, 1.0 - amount * 0.8 * k)
	Art.set_flash(_sprite, 1.0 if _flash > 0.0 else 0.0)
	_update_daze_stars()
	if is_worn():
		_wear_timer -= delta
		if _wear_timer <= 0.0:
			_wear_timer = WEAR_EVERY + randf() * 0.3
			_puff_wear()


## Called by Wren's sword. `direction` is the way the swing travels.
func take_hit(damage: int, direction: Vector2) -> HitResult:
	if dying:
		return HitResult.IGNORED
	if _blocks_hit(direction):
		_on_blocked(direction)
		if damage > 0:
			HitSpark.spawn(get_parent(), global_position + _spark_offset() - direction * 6.0, HitSpark.Kind.BLOCK, direction)
		return HitResult.BLOCKED
	var was_worn := is_worn()
	hp -= damage
	# The hook's tug (no damage) is not a blow.
	if damage > 0:
		HitSpark.spawn(get_parent(), global_position + _spark_offset() - direction * 7.0, HitSpark.Kind.HIT, direction)
	_flash = 0.12
	# Squashed flat for a moment by the blow (only foes that don't already
	# animate their own scale).
	if damage > 0 and (_squash > 0.0 or _sprite.scale.is_equal_approx(_sprite_base_scale)):
		_squash = SQUASH_TIME
	_stun = HIT_STUN
	_knockback = direction * KNOCKBACK_SPEED * knockback_scale
	_on_hurt()
	if not was_worn:
		_check_worn()
	if hp <= 0:
		if is_in_group("boss"):
			Feel.final_blow(get_parent(), global_position + _spark_offset())
		_die()
	return HitResult.HIT


## True for a living boss at half health or less that shows it (see
## _shows_wear).
func is_worn() -> bool:
	return is_in_group("boss") and not dying and hp > 0 and hp * 2 <= max_hp and _shows_wear()


## Call after taking health off a boss outside take_hit: the blow that first
## wears it down shakes the room and sends up the first puffs at once.
func _check_worn() -> void:
	if is_worn():
		Feel.shake(3.0)
		_wear_timer = WEAR_EVERY
		_puff_wear()
		_puff_wear()


## True while a boss can be hurt by the sword: its weak moment.
func is_boss_open() -> bool:
	return is_in_group("boss") and not dying and hp > 0 and not _blocks_hit(Vector2.ZERO)


func _update_daze_stars() -> void:
	var show := is_boss_open() and _sprite.visible and _sprite.modulate.a >= 0.5
	if show and _daze_stars == null:
		_daze_stars = DazeStars.new()
		_daze_stars.name = "DazeStars"
		add_child(_daze_stars)
	if _daze_stars == null:
		return
	_daze_stars.visible = show
	if show:
		var rect := _sprite.get_rect()
		var head := Vector2(rect.get_center().x, rect.position.y + _art_top() + 1.0)
		_daze_stars.global_position = (_sprite.get_global_transform() * head).round()


## How far down the sprite's current frame its first drawn row is (frames
## often leave empty room above, for a raised head or a leap).
func _art_top() -> float:
	var key := _sprite.frame
	if _art_tops.has(key):
		return _art_tops[key]
	var top := 0.0
	var image := _sprite.texture.get_image() if _sprite.texture else null
	if image:
		var size := Vector2i(image.get_width() / _sprite.hframes, image.get_height() / _sprite.vframes)
		var at := Vector2i(key % _sprite.hframes, key / _sprite.hframes) * size
		top = float(image.get_region(Rect2i(at, size)).get_used_rect().position.y)
	_art_tops[key] = top
	return top


## Override to false for a boss whose wear already shows another way.
func _shows_wear() -> bool:
	return true


func _puff_wear() -> void:
	if not is_visible_in_tree() or not _sprite.visible or _sprite.modulate.a < 0.5:
		return
	# Off the top of the sprite, where they read against the floor.
	var box := _sprite.get_global_transform() * _sprite.get_rect()
	var at := Vector2(randf_range(box.position.x + box.size.x * 0.3, box.end.x - box.size.x * 0.3), box.position.y + 6.0)
	HitSpark.spawn(get_parent(), at, HitSpark.Kind.WEAR)


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


## Override: set velocity for this frame.
func _think(_delta: float) -> void:
	velocity = Vector2.ZERO


## Override: return true to deflect a hit travelling in `direction`.
func _blocks_hit(_direction: Vector2) -> bool:
	return false


func _on_blocked(_direction: Vector2) -> void:
	pass


func _on_hurt() -> void:
	pass


## Where a blow's spark shows, from the enemy's feet: the middle of its
## hurtbox, so big foes take the spark at the body, not the feet.
func _spark_offset() -> Vector2:
	return Vector2(0, -(body_size.y + 6.0) / 2.0 * scale.y)

## How long, and how hard, a landed blow squashes a foe's sprite (bosses
## less, being big).
const SQUASH_TIME := 0.14
const SQUASH := 0.25
const SQUASH_BOSS := 0.08

## Chance that a fallen enemy leaves a glint or more.
const GLINT_ODDS := 0.6


func _die() -> void:
	dying = true
	if not is_in_group("boss"):
		HitSpark.spawn(get_parent(), global_position, HitSpark.Kind.FALL)
		var shards := HitSpark.spawn(get_parent(), global_position + _spark_offset() * 0.5, HitSpark.Kind.SHARDS)
		if shards:
			shards.tint = body_colour() * _sprite.self_modulate
	Audio.play_sfx("enemy_die", global_position)
	if elite:
		Audio.play_sfx("boss_fall", global_position, 1.6)
		var room := get_parent() as Room
		if room:
			GameState.set_flag(Room.elite_flag(room.coord))
		if get_parent():
			Glint.drop.call_deferred(get_parent(), position, ELITE_GLINTS)
	elif not is_in_group("boss") and get_parent():
		Glint.drop.call_deferred(get_parent(), position, Glint.roll(GLINT_ODDS))
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	# A white pop as the last blow lands, a swell, then it flattens away.
	Art.set_flash(_sprite, 1.0)
	var base := scale
	var tween := create_tween()
	tween.tween_property(self, "scale", base * Vector2(1.2, 1.2), 0.06)
	tween.tween_callback(func() -> void: Art.set_flash(_sprite, 0.0))
	tween.tween_property(self, "scale", base * Vector2(1.6, 0.3), 0.16)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)


## A beaten boss's last light lifting off it as it fades: two waves of
## pale specks across its body.
func _dissolve() -> void:
	var parent := get_parent()
	if parent == null or _sprite == null:
		return
	var box := _sprite.get_global_transform() * _sprite.get_rect()
	var at := Vector2(box.get_center().x, box.end.y - box.size.y * 0.3)
	for wave in 2:
		var rise := HitSpark.spawn(parent, at + Vector2(0, -wave * box.size.y * 0.25), HitSpark.Kind.RISE)
		if rise:
			rise.spread = box.size.x * 0.7
			rise._seed += 7919 * wave
			rise._time = -0.35 * wave


## The colour most of this foe's body is (outline and eyes aside), across
## its sheet, for the bits of it that fly when it falls. Worked out once per
## sprite sheet.
static var _body_colours := {}


func body_colour() -> Color:
	var texture := _sprite.texture if _sprite else null
	if texture == null:
		return HitSpark.DUST
	var key := texture.get_rid()
	if _body_colours.has(key):
		return _body_colours[key]
	var counts := {}
	var image := texture.get_image()
	if image:
		# Every frame: a burrower's first frame is only the ground it hides in.
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				# Skip clear pixels, outlines and eyes, and glints.
				if c.a < 0.5 or c.get_luminance() < 0.18 or c.get_luminance() > 0.92:
					continue
				counts[c] = int(counts.get(c, 0)) + 1
	var best := HitSpark.DUST
	var most := 0
	for c in counts:
		if counts[c] > most:
			most = counts[c]
			best = c
	_body_colours[key] = best
	return best


## Override: return this enemy's sprite (see Art.sprite()).
func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.SCUTTLER, 3, 1, 11)


## Override: choose the frame for this physics tick.
func _update_sprite() -> void:
	pass


## Shake the sprite sideways: part of most wind-up tells.
func _jitter(timer: float) -> void:
	_sprite.position.x += 1.0 if int(timer * 30.0) % 2 == 0 else -1.0


## The nearest of the four directions to `v`.
static func cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, 1.0 if v.y >= 0.0 else -1.0)
