extends Node
## Player options (accessibility and controls) and the default input map.
##
## Actions are registered in code so every binding lives in one place and the
## remapping screen can rebuild them later. Movement uses physical key
## positions, so WASD stays in the same place on AZERTY and other layouts.

const PATH := "user://settings.cfg"

## 0 turns hitstop off, 1 is full strength.
var hitstop_scale := 1.0
## 0 turns screen shake off, 1 is full strength.
var screen_shake_scale := 1.0
## When false, hit flashes use a soft tint instead of pure white.
var flashes := true
## When true, tapping Hum starts and stops humming instead of holding it.
var hum_toggle := false
var locale := "en"


func _ready() -> void:
	_register_default_actions()
	load_settings()
	TranslationServer.set_locale(locale)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	hitstop_scale = clampf(float(cfg.get_value("feel", "hitstop_scale", hitstop_scale)), 0.0, 1.0)
	screen_shake_scale = clampf(float(cfg.get_value("feel", "screen_shake_scale", screen_shake_scale)), 0.0, 1.0)
	flashes = bool(cfg.get_value("feel", "flashes", flashes))
	hum_toggle = bool(cfg.get_value("controls", "hum_toggle", hum_toggle))
	locale = str(cfg.get_value("language", "locale", locale))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("feel", "hitstop_scale", hitstop_scale)
	cfg.set_value("feel", "screen_shake_scale", screen_shake_scale)
	cfg.set_value("feel", "flashes", flashes)
	cfg.set_value("controls", "hum_toggle", hum_toggle)
	cfg.set_value("language", "locale", locale)
	cfg.save(PATH)


func _register_default_actions() -> void:
	var bindings := {
		"move_up": [_key(KEY_W), _key(KEY_UP), _pad(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)],
		"move_down": [_key(KEY_S), _key(KEY_DOWN), _pad(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)],
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _pad(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _pad(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)],
		"attack": [_key(KEY_J), _pad(JOY_BUTTON_B)],
		"interact": [_key(KEY_K), _pad(JOY_BUTTON_A)],
		"item_1": [_key(KEY_U), _pad(JOY_BUTTON_X)],
		"item_2": [_key(KEY_I), _pad(JOY_BUTTON_Y)],
		"hum": [_key(KEY_H), _pad(JOY_BUTTON_RIGHT_SHOULDER)],
		"map": [_key(KEY_M), _pad(JOY_BUTTON_BACK)],
		"pause": [_key(KEY_ESCAPE), _pad(JOY_BUTTON_START)],
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, 0.3)
		for event: InputEvent in bindings[action]:
			InputMap.action_add_event(action, event)


static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


static func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
