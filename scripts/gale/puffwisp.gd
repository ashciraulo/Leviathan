class_name Puffwisp
extends Enemy
## A scrap of storm cloud with a face (the Gale Spire), drifting over gaps
## and floor alike. It bobs slowly toward Wren; close enough, it stops and
## draws a long breath, puffing up (the tell, with a rising hiss), then
## blows a gust straight at Wren that shoves them back across the room.
## Like the spire's fans, the gust leans on Wren at the edge of a drop but
## never blows them off it. Blown out, it sags and sinks for a moment: the
## time to strike. Touching it stings.

enum Mode { DRIFT, SWELL, BLOW, SPENT }

const DRIFT_SPEED := 18.0
const SIGHT := 140.0
## How close it comes before drawing breath.
const TRIGGER_RANGE := 56.0
const SWELL_TIME := 0.8
const BLOW_TIME := 0.7
const SPENT_TIME := 1.4
## How hard the gust shoves Wren (pixels per second), and how far it reaches.
const PUSH := 150.0
const REACH := 96.0
## How wide the gust is either side of its line.
const HALF_WIDTH := 12.0

var mode := Mode.DRIFT
## Which way it blows (set as it draws breath).
var aim := Vector2.RIGHT
var _timer := 0.0
var _bob := 0.0


func _init() -> void:
	max_hp = 2
	body_size = Vector2(12, 8)


func _ready() -> void:
	super()
	# It floats: walls and other enemies stop it, gaps and water don't.
	Layers.assign(self, Layers.ENEMY, [Layers.WORLD, Layers.ENEMY])
	_bob = randf() * TAU
	z_index = 2


func _think(delta: float) -> void:
	_timer -= delta
	_bob += delta * 3.0
	var player := get_player()
	match mode:
		Mode.DRIFT:
			velocity = Vector2.ZERO
			if player == null:
				return
			var to := player.global_position - global_position
			if to.length() > SIGHT:
				return
			velocity = to.normalized() * DRIFT_SPEED
			if to.length() < TRIGGER_RANGE and _timer <= 0.0:
				mode = Mode.SWELL
				_timer = SWELL_TIME
				aim = to.normalized()
				Audio.play_sfx("puff_inhale", global_position)
		Mode.SWELL:
			velocity = Vector2.ZERO
			if player != null:
				aim = (player.global_position - global_position).normalized()
			if _timer <= 0.0:
				mode = Mode.BLOW
				_timer = BLOW_TIME
				Audio.play_sfx("puff_blow", global_position)
		Mode.BLOW:
			velocity = -aim * 6.0
			_blow(player, delta)
			queue_redraw()
			if _timer <= 0.0:
				mode = Mode.SPENT
				_timer = SPENT_TIME
				queue_redraw()
		Mode.SPENT:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				mode = Mode.DRIFT
				_timer = 0.6


## Shoves Wren along the gust while they're in it.
func _blow(player: Player, delta: float) -> void:
	if player == null or player.frozen or player.airborne:
		return
	var to := player.global_position - global_position
	var along := to.dot(aim)
	if along < 0.0 or along > REACH or absf(to.cross(aim)) > HALF_WIDTH:
		return
	var room := get_parent() as Node2D
	var field := room.get_node_or_null("PitField") as PitField if room else null
	if field:
		var local := player.global_position - room.global_position
		if field.is_gap(local + Vector2(0, -3) + aim * 7.0):
			return
	player.move_and_collide(aim * PUSH * delta)


func is_blowing() -> bool:
	return mode == Mode.BLOW


func is_spent() -> bool:
	return mode == Mode.SPENT


func _draw() -> void:
	if mode != Mode.BLOW:
		return
	# The gust: pale streaks running out along its line.
	var t := 1.0 - maxf(_timer, 0.0) / BLOW_TIME
	var side := aim.orthogonal()
	for i in 5:
		var off := side * (float(i) - 2.0) * 5.0
		var start := 10.0 + fmod(t * 90.0 + i * 17.0, REACH - 20.0)
		var from := Vector2(0, -6) + aim * start + off
		draw_line(from, from + aim * 12.0, Color(0.9, 0.96, 1.0, 0.65 * (1.0 - t * 0.5)))


func _make_sprite() -> Sprite2D:
	return Art.sprite(GaleSprites.PUFFWISP, 4, 1, 14)


func _update_sprite() -> void:
	# It floats a little above its shadow, bobbing.
	_sprite.position.y += -3.0 + sin(_bob) * 1.5
	match mode:
		Mode.SWELL:
			_sprite.frame = 1
			if ai_enabled:
				_jitter(_timer)
		Mode.BLOW:
			_sprite.frame = 2
			_sprite.flip_h = aim.x < 0.0
		Mode.SPENT:
			_sprite.frame = 3
			_sprite.position.y += 2.0
		_:
			_sprite.frame = 0
