class_name Gust
extends Node2D
## Wind over the heights. It comes in pulses: calm, a rising whistle while
## thin streaks start to run (the tell), then a hard gust that shoves Wren
## and rolls Tumbleburrs along. Streaks drawn over the room show which way
## and how hard it blows.

enum Phase { CALM, RISING, BLOWING }

const CALM_TIME := 2.6
const RISING_TIME := 0.7
const BLOW_TIME := 1.4
const STREAKS := 22

## Direction and strength of a full gust, in pixels per second.
var wind := Vector2.ZERO
var phase := Phase.CALM
var _timer := CALM_TIME
var _room: Room
var _streaks: Array[Vector2] = []


func _ready() -> void:
	_room = get_parent() as Room
	z_index = 6
	var rnd := RandomNumberGenerator.new()
	rnd.seed = hash(_room.coord) if _room else 1
	for i in STREAKS:
		_streaks.append(Vector2(rnd.randf() * Room.SIZE.x, rnd.randf() * Room.SIZE.y))


## How hard it is blowing right now, 0..1.
func strength() -> float:
	match phase:
		Phase.RISING:
			return 0.15
		Phase.BLOWING:
			return 1.0
	return 0.0


func push() -> Vector2:
	return wind * strength()


func is_blowing() -> bool:
	return phase == Phase.BLOWING


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		match phase:
			Phase.CALM:
				phase = Phase.RISING
				_timer = RISING_TIME
			Phase.RISING:
				phase = Phase.BLOWING
				_timer = BLOW_TIME
				Audio.play_sfx("gust", global_position + Room.SIZE / 2.0)
			Phase.BLOWING:
				phase = Phase.CALM
				_timer = CALM_TIME
	var shove := push()
	if shove != Vector2.ZERO:
		var player := get_tree().get_first_node_in_group("player") as Player
		# Not while Wren is still blinking from a fall or a hit: a gust that
		# shoves them straight back off the edge they were set down by would
		# cost breath after breath.
		if player != null and not player.frozen and not player.airborne and not player.in_cutscene and player._invuln <= 0.0 \
				and player.state in [Player.State.MOVE, Player.State.ATTACK, Player.State.CHARGE, Player.State.HUM, Player.State.HURT]:
			if Rect2(Vector2.ZERO, Room.SIZE).has_point(player.global_position - _room.global_position):
				player.move_and_collide(shove * delta)
	# Streaks race along with the wind; in the calm they drift lazily.
	var drift := wind.normalized() * (14.0 + wind.length() * 1.6 * strength())
	for i in _streaks.size():
		var s := _streaks[i] + drift * delta * (1.0 + (i % 3) * 0.3)
		s.x = fposmod(s.x, Room.SIZE.x)
		s.y = fposmod(s.y, Room.SIZE.y)
		_streaks[i] = s
	queue_redraw()


func _draw() -> void:
	if wind == Vector2.ZERO:
		return
	var dir := wind.normalized()
	var length := 4.0 + 14.0 * strength()
	var alpha := 0.12 + 0.3 * strength()
	for i in _streaks.size():
		if phase == Phase.CALM and i % 3 != 0:
			continue
		var s := _streaks[i].floor()
		draw_line(s, s - dir * length * (0.6 + (i % 4) * 0.2), Color(1, 1, 1, alpha), 1.0)
