class_name Shellback
extends Enemy
## Blocker (an armoured hermit). Its shell faces Wren and deflects sword hits
## from the front, so you have to get beside or behind it.
## Tell: it stops and rattles before it turns, which is the window to move.

enum Mode { WALK, TURNING }

const SPEED := 22.0
const SIGHT := 150.0
const TURN_PAUSE := 0.4
const TURN_EVERY := 1.1

var mode := Mode.WALK
## The way the shell (and the face) points.
var shell_dir := Vector2.DOWN
var _timer := 0.0


func _init() -> void:
	max_hp = 3
	body_size = Vector2(16, 10)


func _think(delta: float) -> void:
	_timer -= delta
	var player := get_player()
	if player == null or global_position.distance_to(player.global_position) > SIGHT:
		velocity = Vector2.ZERO
		return
	var toward := Enemy.cardinal(player.global_position - global_position)
	match mode:
		Mode.WALK:
			velocity = shell_dir * SPEED
			if _timer <= 0.0:
				if toward != shell_dir:
					mode = Mode.TURNING
					_timer = TURN_PAUSE
				else:
					_timer = TURN_EVERY
		Mode.TURNING:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				shell_dir = toward
				mode = Mode.WALK
				_timer = TURN_EVERY


func _blocks_hit(direction: Vector2) -> bool:
	# A swing travelling against the shell's facing hits the shell.
	return direction.dot(shell_dir) < -0.5


func _on_blocked(direction: Vector2) -> void:
	_flash = 0.06
	_stun = 0.1
	_knockback = direction * 60.0


func _draw() -> void:
	_draw_shadow(18)
	var jitter := Vector2.ZERO
	if mode == Mode.TURNING and ai_enabled and not dying:
		jitter.x = 1.0 if int(_timer * 30.0) % 2 == 0 else -1.0
	var body := Rect2(Vector2(-9, -15) + jitter, Vector2(18, 15))
	draw_rect(body, Palette.OUTLINE)
	draw_rect(body.grow(-1), _tint(Palette.SHELLBACK))
	# The shell plate sits on the facing side: thick, pale and outlined.
	var plate: Rect2
	if shell_dir.x > 0.0:
		plate = Rect2(Vector2(5, -16), Vector2(6, 17))
	elif shell_dir.x < 0.0:
		plate = Rect2(Vector2(-11, -16), Vector2(6, 17))
	elif shell_dir.y < 0.0:
		plate = Rect2(Vector2(-10, -18), Vector2(20, 6))
	else:
		plate = Rect2(Vector2(-10, -5), Vector2(20, 6))
	plate.position += jitter
	draw_rect(plate, Palette.OUTLINE)
	draw_rect(plate.grow(-1), _tint(Palette.SHELL))
