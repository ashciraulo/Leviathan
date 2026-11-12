extends Node
## Records short gameplay loops for the store page, one clip per run:
##     CLIP=fight xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 30 \
##         --path . res://tests/store_clips.tscn
## Frames (native 384x216) land in <project>/clips/<clip>/0000.png; turn them
## into a GIF with tools/store_clips.sh, which runs every clip.
## --fixed-fps keeps game time steady however slow saving each frame is.
## Uses save slot 2 so it never touches a real save.

const TEST_SLOT := 2
const CLIPS := ["fight", "hum", "glide", "mantle", "dunes"]

var _out_dir := ""
var _recording := false
var _frame := 0
var _game: Node
## Steer Wren toward the nearest enemy and swing when close.
var _auto_fight := false
var _failed := false
var _swing_cooldown := 0.0
## Refill breath every frame, so a clip never ends in a game over. (Not
## invulnerability: that makes Wren blink the whole clip.)
var _keep_alive := true
## Unsticking: when Wren hasn't moved for a moment, sidestep for a moment.
var _last_pos := Vector2.ZERO
var _stuck := 0.0
var _sidestep := 0.0
var _sidestep_dir := Vector2.ZERO
## When set, fight only these.
var _targets: Array = []


func _ready() -> void:
	var clip := OS.get_environment("CLIP")
	if clip not in CLIPS:
		push_error("CLIP must be one of %s" % [CLIPS])
		get_tree().quit(1)
		return
	var root := ProjectSettings.globalize_path("res://").path_join("clips")
	_out_dir = root.path_join(clip)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	# Keep the frames out of the editor's imports and every export.
	FileAccess.open(root.path_join(".gdignore"), FileAccess.WRITE)
	SaveManager.current_slot = TEST_SLOT
	SaveManager.set_aside(TEST_SLOT, "testbackup")
	SaveManager.delete_save()
	GameState.reset_new_game()
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(_game)
	await _wait(0.8)
	await call("_clip_" + clip)
	_recording = false
	_auto_fight = false
	_steer(Vector2.ZERO)
	SaveManager.delete_save()
	SaveManager.restore_aside(TEST_SLOT, "testbackup")
	if _failed:
		get_tree().quit(1)
		return
	print("Clip %s: %d frames" % [clip, _frame])
	get_tree().quit(0)


## The first screens: east from the shore into the tidepools and the crabs.
func _clip_fight() -> void:
	var player: Player = _game.player
	player.global_position = _game.current_room.global_position + Vector2(Room.SIZE.x - 60.0, 6 * Room.TILE + 12)
	await _record(0.2)
	_steer(Vector2.RIGHT)
	await _wait(1.4)
	_steer(Vector2.ZERO)
	# A few Scuttlers in Wren's way (the tidepools' own sit among the rocks).
	var room: Room = _game.current_room
	var at := player.global_position - room.global_position
	for offset in [Vector2(70, -10), Vector2(110, 18), Vector2(150, -4)]:
		var crab := Scuttler.new()
		crab.position = at + offset
		room.add_child(crab)
		_targets.append(crab)
	_auto_fight = true
	await _wait(5.0)


## Low on breath: hum, and a bubble comes back.
func _clip_hum() -> void:
	var player: Player = _game.player
	_keep_alive = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	GameState.bubbles = 2
	GameState.resonance = 36.0
	player.global_position = _game.current_room.global_position + Vector2(190, 8 * Room.TILE + 12)
	player.facing = Vector2.DOWN
	await _record(0.6)
	Input.action_press("hum")
	await _wait(2.6)
	Input.action_release("hum")
	await _wait(0.8)


## The Kite Cloak over the drop in the Gale Spire.
func _clip_glide() -> void:
	GameState.give_item("kite_cloak")
	await _jump(Vector2i(29, 9), Vector2i(4, 6))
	_game.player.facing = Vector2.RIGHT
	await _record(0.6)
	if not _game.player.use_item("kite_cloak"):
		push_error("glide clip: the Kite Cloak didn't open")
		_failed = true
		return
	_steer(Vector2.RIGHT)
	await _wait(3.0)
	_steer(Vector2.ZERO)
	await _wait(0.6)


## The Wayshell: Mantle swoops down and carries Wren home.
func _clip_mantle() -> void:
	GameState.give_item("wayshell")
	await _jump(Vector2i(4, 0), Vector2i(11, 8))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _record(0.4)
	var home := Vector2i(1, 0)
	for coord in [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(2, 0)]:
		if RoomInfo.stone_landing(coord) != GameState.NO_POSITION:
			home = coord
			break
	Events.fast_travel_requested.emit(home)
	await _wait(7.6)


## The Ossuary Dunes: the great skull at Skull Rise.
func _clip_dunes() -> void:
	GameState.give_item("divers_helm")
	await _jump(Vector2i(9, 0), Vector2i(15, 9))
	await _record(0.0)
	_auto_fight = true
	await _wait(6.0)


func _record(lead_in: float) -> void:
	_recording = true
	await _wait(lead_in)


func _process(delta: float) -> void:
	if _keep_alive and _game and GameState.bubbles < GameState.max_bubbles:
		GameState.bubbles = GameState.max_bubbles
	if _auto_fight and _game and is_instance_valid(_game.player):
		_fight_step(delta)
	if _recording:
		_save_frame()


func _fight_step(delta: float) -> void:
	var player: Player = _game.player
	_swing_cooldown -= delta
	var target: Node2D = null
	var best := INF
	var pool: Array = _targets.filter(func(e): return is_instance_valid(e)) if not _targets.is_empty() else get_tree().get_nodes_in_group("enemies")
	for enemy in pool:
		if not enemy is Node2D or enemy.get("dying"):
			continue
		var d: float = (enemy as Node2D).global_position.distance_to(player.global_position)
		if d < best:
			best = d
			target = enemy
	if target == null:
		_steer(Vector2.ZERO)
		return
	var to: Vector2 = target.global_position - player.global_position
	if best > 22.0:
		if _sidestep > 0.0:
			_sidestep -= delta
			_steer(_sidestep_dir)
			return
		_stuck = _stuck + delta if player.global_position.distance_to(_last_pos) < 0.3 else 0.0
		_last_pos = player.global_position
		if _stuck > 0.25:
			_stuck = 0.0
			_sidestep = 0.5
			_sidestep_dir = Vector2(-to.y, to.x).normalized() * (1.0 if randf() < 0.5 else -1.0)
		_steer(to.normalized())
		return
	_steer(Vector2.ZERO)
	if _swing_cooldown <= 0.0 and not player.frozen and player.state in [Player.State.MOVE, Player.State.ATTACK]:
		player.facing = Vector2(signf(to.x), 0) if absf(to.x) > absf(to.y) else Vector2(0, signf(to.y))
		player.start_attack()
		_swing_cooldown = 0.4


func _steer(dir: Vector2) -> void:
	var pairs := {"move_right": dir.x > 0.3, "move_left": dir.x < -0.3, "move_down": dir.y > 0.3, "move_up": dir.y < -0.3}
	for action: String in pairs:
		if pairs[action]:
			Input.action_press(action)
		else:
			Input.action_release(action)


func _save_frame() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out_dir.path_join("%04d.png" % _frame))
	_frame += 1


func _jump(coord: Vector2i, tile: Vector2i) -> Room:
	GameState.set_checkpoint(coord, Vector2(tile.x * Room.TILE + 8, tile.y * Room.TILE + 12))
	SaveManager.save_game()
	_game.respawn()
	await _wait(2.2)
	return _game.current_room


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
