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
		# A charge or hum held into the scene would still read the keys.
		if player.state == Player.State.CHARGE or player.state == Player.State.HUM:
			player._enter(Player.State.MOVE)
		player._hum_latched = false


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
	# Wait out a door fade before walking.
	while player.frozen and is_instance_valid(player):
		await get_tree().physics_frame
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


## Walk Wren to a point along open ground, round water, walls, props and
## people: a breadth-first search over the room's tiles, walked corner to
## corner. With no route, falls back to walk_around_to, or (fallback off,
## for rooms with pits or open sky) leaves Wren where they are.
func walk_route(target: Vector2, fallback: bool = true) -> void:
	var player := _player()
	var room: Room = game.current_room if game else null
	if player == null or room == null:
		return
	var origin := room.global_position
	var from := _tile_of(player.global_position - origin)
	var to := _tile_of(target - origin)
	var path := _route(room, from, to)
	if path.is_empty():
		if fallback:
			await walk_around_to(target)
		return
	for i in range(1, path.size()):
		# Only stop at corners.
		if i < path.size() - 1 and path[i] - path[i - 1] == path[i + 1] - path[i]:
			continue
		var cell: Vector2i = path[i]
		var point := origin + Vector2(cell.x * Room.TILE + Room.TILE / 2.0, cell.y * Room.TILE + 10)
		if i == path.size() - 1:
			point = target
		if not await walk_to(point):
			break
	await walk_to(target)


static func _tile_of(local: Vector2) -> Vector2i:
	return Vector2i(int(local.x) / Room.TILE, int(local.y) / Room.TILE)


## Tiles Wren can cross in a scene. Big props spread wider than their tile.
static func _open(room: Room, cell: Vector2i) -> bool:
	if not ".Pk".contains(room.tile_at(cell.x, cell.y)):
		return false
	for dx in range(-2, 3):
		if "HLMWR".contains(room.tile_at(cell.x + dx, cell.y)):
			return false
	# Marlo's stall: three tiles wide, two deep.
	for dx in range(-1, 2):
		for dy in range(0, 2):
			if room.tile_at(cell.x + dx, cell.y + dy) == "7":
				return false
	return true


static func _route(room: Room, from: Vector2i, to: Vector2i) -> Array:
	var came := {from: from}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == to:
			var path: Array = [to]
			while path[0] != from:
				path.push_front(came[path[0]])
			return path
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if came.has(next) or next.x < 0 or next.y < 0 or next.x >= Room.COLS or next.y >= Room.ROWS:
				continue
			if next != to and not _open(room, next):
				continue
			came[next] = cell
			queue.append(next)
	return []


## Wren swings the sword once.
func slash() -> void:
	var player := _player()
	if player:
		player.start_attack()


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


## The veil's colour (black by default; the ending's dawn is white).
func set_veil_colour(colour: Color) -> void:
	_veil.color = Color(colour, _veil.color.a)
	_veil_text.add_theme_color_override("font_color", Palette.NARRATION if colour.get_luminance() < 0.5 else Color("#4a3a58"))


func darken(seconds: float = 0.0) -> void:
	if seconds <= 0.0:
		_veil.color.a = 1.0
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_veil, "color:a", 1.0, scaled(seconds))
	await tween.finished

