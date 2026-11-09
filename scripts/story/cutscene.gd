class_name Cutscene
extends Node
## Plays one scripted story scene. Build it, add it to the game, then await
## the scene function (see StoryDirector). While it runs, Wren takes no
## input: the scene walks them, talks through the dialogue box, flashes
## lamps and fades the screen.
##
## Steps are plain awaitable methods, so a scene reads top to bottom:
##     await scene.narrate(["OPENING_1"])
##     await scene.walk_to(spot)
##     await scene.lamp(hessa_pos, Cutscene.LAMP_HERE)

## Lamp signals shared by Hessa and Wren (story bible): one flash is yes,
## two is no, a long glow is "I'm here".
const LAMP_YES := "yes"
const LAMP_NO := "no"
const LAMP_HERE := "here"
## Give up on a walk that gets stuck after this long.
const WALK_TIMEOUT := 4.0

## True while any scene is running.
static var active := false
## Tests set this to run scenes about twenty times faster.
static var fast := false

var game: Node
var _veil: ColorRect
var _veil_text: Label


func _init(the_game: Node = null) -> void:
	game = the_game


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 31
	add_child(layer)
	_veil = ColorRect.new()
	_veil.color = Color(0, 0, 0, 0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_veil)
	_veil_text = Label.new()
	_veil_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil_text.offset_left = 40
	_veil_text.offset_right = -40
	_veil_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_veil_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_veil_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_veil_text.add_theme_font_size_override("font_size", UI.FONT_SIZE * (2 if Settings.large_text else 1))
	_veil_text.add_theme_color_override("font_color", Palette.NARRATION)
	_veil_text.modulate.a = 0.0
	layer.add_child(_veil_text)


func begin() -> void:
	active = true
	var player := _player()
	if player:
		player.in_cutscene = true
		player.script_move = Vector2.ZERO


func finish() -> void:
	var player := _player()
	if player:
		player.in_cutscene = false
		player.script_move = Vector2.ZERO
	active = false
	queue_free()


func _exit_tree() -> void:
	active = false


func _player() -> Player:
	return game.player if game and is_instance_valid(game.player) else null


## Talk through the dialogue box and wait until it closes. Pages as made by
## Conversations.pages(), or plain keys for narration.
func say(pages: Array) -> void:
	var out: Array = []
	for page: Variant in pages:
		out.append(page if page is Dictionary else {"name": "", "portrait": null, "text": str(page)})
	Events.conversation_requested.emit(out)
	await Events.dialogue_finished


## One person says several lines.
func speak(who: String, keys: Array) -> void:
	await say(Conversations.pages(who, {"lines": keys}))


func narrate(keys: Array) -> void:
	await say(keys)


func wait(seconds: float) -> void:
	await get_tree().create_timer(scaled(seconds), true, false, true).timeout


static func scaled(seconds: float) -> float:
	return seconds * (0.05 if fast else 1.0)


## Walk Wren to a point in world space. Returns false if they got stuck.
func walk_to(target: Vector2) -> bool:
	var player := _player()
	if player == null:
		return false
	var time := 0.0
	var last := player.global_position
	var still := 0.0
	var reached := false
	while time < WALK_TIMEOUT:
		var offset := target - player.global_position
		if offset.length() < 2.0:
			reached = true
			break
		player.script_move = offset.normalized()
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		time += delta
		still = still + delta if player.global_position.distance_to(last) < 0.2 else 0.0
		last = player.global_position
		if still > 0.25:
			break
	player.script_move = Vector2.ZERO
	return reached


## An L-shaped walk that goes round people standing between Wren and the
## target: across then up/down, or the other way round if that's blocked.
func walk_around_to(target: Vector2) -> void:
	var player := _player()
	if player == null:
		return
	var start := player.global_position
	if await walk_to(Vector2(target.x, start.y)) and await walk_to(target):
		return
	if await walk_to(Vector2(player.global_position.x, target.y)):
		await walk_to(target)


## Turn Wren to face a direction (UP, DOWN, LEFT or RIGHT).
func face(direction: Vector2) -> void:
	var player := _player()
	if player:
		player.facing = direction


## A lamp signal at a point in world space. Waits until it's done.
func lamp(at: Vector2, signal_kind: String) -> void:
	var glow := LampGlow.new(signal_kind)
	glow.position = at
	var parent: Node = game.world if game and game.get("world") else self
	parent.add_child(glow)
	await glow.done


## Black screen with centred narration, one line at a time.
func veil_text(keys: Array) -> void:
	_veil.color.a = 1.0
	for key: String in keys:
		_veil_text.text = key
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_veil_text, "modulate:a", 1.0, scaled(0.6))
		tween.tween_interval(scaled(2.6))
		tween.tween_property(_veil_text, "modulate:a", 0.0, scaled(0.6))
		await tween.finished


## Lift the black veil to show the world.
func lift_veil(seconds: float = 1.2) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_veil, "color:a", 0.0, scaled(seconds))
	await tween.finished


func darken(seconds: float = 0.0) -> void:
	if seconds <= 0.0:
		_veil.color.a = 1.0
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_veil, "color:a", 1.0, scaled(seconds))
	await tween.finished

