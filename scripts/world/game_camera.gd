class_name GameCamera
extends Camera2D
## Fixed room-by-room camera with screen shake.

const SHAKE_DECAY := 18.0

var _trauma := 0.0


func _ready() -> void:
	# Keeps running through a pause, so a shake caught by a dialogue or the
	# pause menu settles instead of leaving the view knocked off centre.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Feel.shake_requested.connect(_on_shake_requested)


func _process(delta: float) -> void:
	if get_tree().paused:
		_trauma = 0.0
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	offset = (Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _trauma).round()
	_trauma = move_toward(_trauma, 0.0, SHAKE_DECAY * delta)


func _on_shake_requested(strength: float) -> void:
	_trauma = maxf(_trauma, strength)
