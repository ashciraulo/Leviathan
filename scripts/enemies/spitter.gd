class_name Spitter
extends Enemy
## Shooter (a rooted barnacle). Swells up and glows (the tell), then spits a
## slow bubble at Wren. Can't be knocked back.

enum Mode { IDLE, WINDUP }

const RANGE := 170.0
const IDLE_TIME := 1.6
const WINDUP_TIME := 0.55
const SHOT_SPEED := 80.0

var mode := Mode.IDLE
var _timer := 0.0


func _init() -> void:
	max_hp = 3
	body_size = Vector2(14, 10)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	_timer = randf_range(0.6, 1.6)


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	var player := get_player()
	match mode:
		Mode.IDLE:
			if _timer <= 0.0 and player and global_position.distance_to(player.global_position) < RANGE:
				mode = Mode.WINDUP
				_timer = WINDUP_TIME
				Audio.play_sfx("spitter_gulp", global_position)
		Mode.WINDUP:
			if _timer <= 0.0:
				if player:
					_fire_at(player.global_position + Vector2(0, -8))
				mode = Mode.IDLE
				_timer = IDLE_TIME + randf() * 0.4


func _fire_at(target: Vector2) -> void:
	var shot := Projectile.new()
	shot.position = position + Vector2(0, -8)
	shot.velocity = (target - (global_position + Vector2(0, -8))).normalized() * SHOT_SPEED
	# Direct add: this runs in _physics_process, and a deferred add could land
	# after the room was freed.
	get_parent().add_child(shot)
	Audio.play_sfx("enemy_shot", global_position)


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.SPITTER, 2, 1, 12)


func _update_sprite() -> void:
	var winding := mode == Mode.WINDUP and ai_enabled
	_sprite.frame = 1 if winding else 0
	if winding and _timer < WINDUP_TIME * 0.5:
		_jitter(_timer)
