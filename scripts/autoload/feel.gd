extends Node
## Game feel: hitstop and screen shake, both scaled by accessibility settings.

signal shake_requested(strength: float)

## How many hitstops are running. Time resumes when the last one ends, so
## overlapping hits can't leave the game frozen.
var _active_hitstops := 0

## The slow motion after a boss's last blow: how slow, and for how long in
## real seconds.
const SLOW_SCALE := 0.4
const SLOW_TIME := 0.5

## Bumped by reset(), so a final blow's slow motion that's still waiting
## doesn't land on whatever comes next.
var _slow_gen := 0


## Time back to normal at once, and any pending slow motion called off
## (leaving the game for the title, a game over).
func reset() -> void:
	_slow_gen += 1
	_active_hitstops = 0
	Engine.time_scale = 1.0


## Freeze the game for a few frames when a hit connects (2 frames by default).
func hitstop(frames: int = 2) -> void:
	var duration: float = frames / 60.0 * Settings.hitstop_scale
	if duration <= 0.0:
		return
	_active_hitstops += 1
	Engine.time_scale = 0.0
	# This timer ignores time scale, so it still runs while the game is frozen.
	await get_tree().create_timer(duration, true, false, true).timeout
	_active_hitstops -= 1
	if _active_hitstops <= 0:
		_active_hitstops = 0
		Engine.time_scale = 1.0


func shake(strength: float) -> void:
	if Settings.screen_shake_scale > 0.0:
		shake_requested.emit(strength * Settings.screen_shake_scale)


## The blow that fells a boss: a long hitstop, a heavy shake, a great star
## where it landed, then a breath of slow motion while the boss goes down.
## All of it scales with the hitstop setting (off means no freeze and no
## slow motion).
func final_blow(parent: Node, at: Vector2) -> void:
	HitSpark.spawn(parent, at, HitSpark.Kind.FINAL)
	shake(6.0)
	var gen := _slow_gen
	await hitstop(10)
	var scale: float = Settings.hitstop_scale
	# A quit to the title (or a game over) in the meantime cancels it.
	if scale <= 0.0 or _active_hitstops > 0 or gen != _slow_gen:
		return
	Engine.time_scale = SLOW_SCALE
	await get_tree().create_timer(SLOW_TIME * scale, true, false, true).timeout
	# A hitstop that started meanwhile puts time back itself.
	if gen == _slow_gen and _active_hitstops == 0 and Engine.time_scale == SLOW_SCALE:
		Engine.time_scale = 1.0
