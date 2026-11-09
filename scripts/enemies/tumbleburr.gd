class_name Tumbleburr
extends Enemy
## Wind-borne hazard (a ball of thorny dry straw). It lolls about in the
## calm, then the gusts send it bowling across the heights: the rising
## whistle and streaks are the tell. One cut scatters it.

const DRIFT_SPEED := 10.0
## How much of a gust's push it takes (it is lighter than Wren).
const GUST_SCALE := 1.6
const BOUNCE := 0.6

var _velocity := Vector2.ZERO
var _roll := 0.0
var _drift := Vector2.ZERO
var _drift_timer := 0.0


func _init() -> void:
	max_hp = 1
	body_size = Vector2(10, 8)


func _think(delta: float) -> void:
	var gust := _gust()
	if gust != null and gust.strength() > 0.0:
		_velocity = _velocity.move_toward(gust.push() * GUST_SCALE, 600.0 * delta)
	else:
		_drift_timer -= delta
		if _drift_timer <= 0.0:
			_drift_timer = randf_range(1.0, 2.0)
			_drift = Vector2.from_angle(randf() * TAU) * DRIFT_SPEED
		_velocity = _velocity.move_toward(_drift, 120.0 * delta)
	velocity = _velocity
	if get_slide_collision_count() > 0:
		var normal := get_slide_collision(0).get_normal()
		_velocity = _velocity.bounce(normal) * BOUNCE
	_roll += velocity.x * delta * 0.25 + velocity.y * delta * 0.1


func _gust() -> Gust:
	var room := get_parent()
	if room == null:
		return null
	return room.get_node_or_null("Gust") as Gust


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.TUMBLEBURR, 4, 1, 14)


func _update_sprite() -> void:
	_sprite.frame = int(posmod(int(_roll), 4))
