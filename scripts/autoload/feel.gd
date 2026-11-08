extends Node
## Game feel: hitstop and screen shake, both scaled by accessibility settings.

signal shake_requested(strength: float)

var _hitstop_end_ms := 0


## Freeze the game for a few frames when a hit connects (2 frames by default).
func hitstop(frames: int = 2) -> void:
	var duration: float = frames / 60.0 * Settings.hitstop_scale
	if duration <= 0.0:
		return
	_hitstop_end_ms = maxi(_hitstop_end_ms, Time.get_ticks_msec() + int(duration * 1000.0))
	Engine.time_scale = 0.0
	# This timer ignores time scale, so it still runs while the game is frozen.
	await get_tree().create_timer(duration, true, false, true).timeout
	if Time.get_ticks_msec() + 2 >= _hitstop_end_ms:
		Engine.time_scale = 1.0


func shake(strength: float) -> void:
	if Settings.screen_shake_scale > 0.0:
		shake_requested.emit(strength * Settings.screen_shake_scale)
