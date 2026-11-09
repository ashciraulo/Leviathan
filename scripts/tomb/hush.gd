class_name Hush
extends Enemy
## The Hush (U): a spirit of the barrow that nobody sees. It drifts after
## Wren, only a faint shimmer in the air, and the sword passes through it.
## The Echo Horn's note finds it: for a few seconds it shows plain, and
## then the sword can too.

const DRIFT_SPEED := 30.0
const SIGHT := 170.0
## How long an echo shows it.
const SHOWN_TIME := 4.0

var shown := 0.0
var _sway := 0.0
var _shadow: Sprite2D


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 8)


func _ready() -> void:
	super._ready()
	add_to_group("echo")
	# It drifts through the barrow's bones and over gaps alike.
	collision_mask = 1 << (Layers.WORLD - 1)
	for child in get_children():
		if child is Sprite2D and child != _sprite:
			_shadow = child


func _think(delta: float) -> void:
	_sway += delta
	shown = maxf(shown - delta, 0.0)
	var wren := get_player()
	if wren == null:
		velocity = Vector2.ZERO
		return
	var to_wren := wren.global_position - global_position
	if to_wren.length() < SIGHT:
		# Seen, it shrinks back a little; unseen, it comes on.
		velocity = to_wren.normalized() * (DRIFT_SPEED * (0.4 if shown > 0.0 else 1.0))
	else:
		velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if _stun > 0.0 or not ai_enabled:
		shown = maxf(shown - delta, 0.0)
	super._physics_process(delta)


func horn_hit(_from: Vector2) -> void:
	if dying:
		return
	if shown <= 0.0:
		Audio.play_sfx("hush_reveal", global_position)
	shown = SHOWN_TIME
	_flash = 0.1


func take_hit(damage: int, direction: Vector2) -> HitResult:
	# Unseen, there's nothing there for the sword.
	if shown <= 0.0:
		return HitResult.IGNORED
	return super.take_hit(damage, direction)


func _make_sprite() -> Sprite2D:
	return Art.sprite(TombSprites.HUSH, 2, 1, 18)


func _update_sprite() -> void:
	_sprite.frame = int(_sway * 3.0) % 2
	_sprite.position.y += sin(_sway * 3.0) * 1.5
	if shown > 0.0:
		# Fading back out as the echo dies away.
		_sprite.modulate.a = 1.0 if shown > 1.0 or int(shown * 10.0) % 2 == 0 else 0.5
	else:
		# Only a shimmer: a faint ripple that comes and goes.
		_sprite.modulate.a = 0.06 + 0.06 * maxf(sin(_sway * 2.3), 0.0)
	_sprite.flip_h = velocity.x < 0.0
	if _shadow:
		_shadow.visible = shown > 0.0
