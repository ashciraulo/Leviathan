extends Node
## Game feel: hitstop and screen shake, both scaled by accessibility settings.

signal shake_requested(strength: float)

## How many hitstops are running. Time resumes when the last one ends, so
## overlapping hits can't leave the game frozen.
var _active_hitstops := 0


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
