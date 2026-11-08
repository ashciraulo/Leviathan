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
	get_parent().add_child.call_deferred(shot)


func _draw() -> void:
	_draw_shadow(16)
	var swell := 0.0
	var mouth := Palette.OUTLINE
	if mode == Mode.WINDUP and ai_enabled and not dying:
		swell = 2.0 * (1.0 - _timer / WINDUP_TIME)
		mouth = Palette.TELL
	var color := _tint(Palette.SPITTER)
	draw_rect(Rect2(-8 - swell, -14 - swell, 16 + swell * 2.0, 14 + swell), Palette.OUTLINE)
	draw_rect(Rect2(-7 - swell, -13 - swell, 14 + swell * 2.0, 12 + swell), color)
	# The mouth glows during the wind-up.
	draw_rect(Rect2(-3, -15 - swell, 6, 4), mouth)
