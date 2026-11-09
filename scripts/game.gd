extends Node2D
## The play scene: builds the world, Wren, the camera and the HUD, slides the
## camera between rooms, and brings Wren back to the last Tidestone on death.

const ROOM_PATH := "res://rooms/room_%d_%d.tscn"
const SLIDE_TIME := 0.45
## How far Wren walks into the new room during the slide.
const ENTRY_STEP := 20.0
const FADE_TIME := 0.35
const TITLE_SCENE := "res://scenes/title.tscn"

var world: Node2D
var player: Player
var camera: GameCamera
var current_room: Room
## True during a room slide or the death sequence.
var busy := false

var _fade: ColorRect
## True while the game over screen is up: play time doesn't count.
var _game_over := false
## [direction, until msec]: a locked hatch just kept Wren from crossing that
## way, so walking on into it doesn't knock again every frame.
var _hatch_blocked := [Vector2i.ZERO, 0]


func _ready() -> void:
	camera = GameCamera.new()
	add_child(camera)
	camera.make_current()
	add_child(Hud.new())
	add_child(ItemSlotsHud.new())
	add_child(CaptionsHud.new())
	add_child(PauseMenu.new())
	add_child(DialogueBox.new())
	add_child(StoryDirector.new())
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 30
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)
	Events.player_died.connect(_on_player_died)
	Events.door_entered.connect(_on_door_entered)
	Events.room_entered.connect(_on_room_entered)
	Events.boss_defeated.connect(_on_boss_defeated)
	Events.boss_woke.connect(_play_room_music)
	Events.fast_travel_requested.connect(_on_fast_travel)
	_start()


func _physics_process(_delta: float) -> void:
	if busy or current_room == null or player == null:
		return
	var local := player.global_position - current_room.global_position
	var direction := Vector2i.ZERO
	if local.x < 0.0:
		direction = Vector2i.LEFT
	elif local.x > Room.SIZE.x:
		direction = Vector2i.RIGHT
	elif local.y < 0.0:
		direction = Vector2i.UP
	elif local.y > Room.SIZE.y:
		direction = Vector2i.DOWN
	if direction != Vector2i.ZERO:
		_change_room(direction)


func _on_room_entered(coord: Vector2i) -> void:
	GameState.mark_seen(coord)
	_play_room_music()


## The room's track, or the boss theme while a boss is still up in it.
func _play_room_music() -> void:
	if current_room:
		var cue := "boss" if _room_has_boss() else Audio.cue_for_room(current_room.biome, current_room.dungeon)
		Audio.play_music(cue)
		Audio.play_ambience(Audio.ambience_for_room(current_room.biome, current_room.dungeon))


func _room_has_boss() -> bool:
	for boss in get_tree().get_nodes_in_group("boss"):
		if current_room.is_ancestor_of(boss) and boss.get("dying") != true and boss.get("asleep") != true:
			return true
	return false


func _on_boss_defeated() -> void:
	# Nothing the boss threw can hit Wren after it's beaten.
	for shot in get_tree().get_nodes_in_group("enemy_shots"):
		shot.queue_free()
	if current_room and not _game_over:
		Audio.play_music(Audio.cue_for_room(current_room.biome, current_room.dungeon), 2.5)


func _process(delta: float) -> void:
	# The game scene stops while paused, so menus don't count.
	if not _game_over:
		GameState.play_time += delta
	# A boss that falls without sending boss_defeated still hands the room
	# back its own music.
	if Audio.music_cue == "boss" and not busy and current_room and not _room_has_boss():
		_on_boss_defeated()


## Build the world at the checkpoint in GameState. With by_mantle, Mantle
## swoops in and sets Wren down there.
func _start(by_mantle: bool = false) -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	current_room = _spawn_room(GameState.checkpoint_room)
	if current_room == null:
		push_error("No room at %s; starting at 0,0 instead." % GameState.checkpoint_room)
		GameState.set_checkpoint(Vector2i.ZERO, GameState.NO_POSITION)
		current_room = _spawn_room(Vector2i.ZERO)
	GameState.room_coord = current_room.coord
	GameState.dungeon = current_room.dungeon
	GameState.mark_seen(current_room.coord)
	_play_room_music()

	player = Player.new()
	player.name = "Wren"
	var saved: Vector2 = GameState.checkpoint_pos
	var local := saved if saved != GameState.NO_POSITION else current_room.player_spawn
	player.position = current_room.position + local
	world.add_child(player)

	camera.position = _room_center(current_room)
	busy = false
	Events.toast.emit(current_room.name_key)
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	if by_mantle:
		_arrive_by_mantle()
	else:
		Events.game_started.emit()


func _arrive_by_mantle() -> void:
	busy = true
	player.frozen = true
	player.visible = false
	var swoop := MantleSwoop.make(player.global_position)
	world.add_child(swoop)
	await swoop.passed
	player.visible = true
	Feel.shake(1.0)
	await swoop.finished
	player.frozen = false
	busy = false


func _spawn_room(coord: Vector2i) -> Room:
	var path := ROOM_PATH % [coord.x, coord.y]
	if not ResourceLoader.exists(path):
		return null
	var room := (load(path) as PackedScene).instantiate() as Room
	room.coord = coord
	room.position = Vector2(coord) * Room.SIZE
	world.add_child(room)
	return room


func _room_center(room: Room) -> Vector2:
	return room.position + Room.SIZE / 2.0


func _change_room(direction: Vector2i) -> void:
	var held_back: bool = _hatch_blocked[0] == direction and Time.get_ticks_msec() < _hatch_blocked[1]
	var next: Room = null if held_back else _spawn_room(current_room.coord + direction)
	if next == null:
		# Nothing that way: keep Wren inside this room.
		var local := player.global_position - current_room.global_position
		local = local.clamp(Vector2.ONE, Room.SIZE - Vector2.ONE)
		player.global_position = current_room.global_position + local
		return
	# A locked hatch on the far side of the edge is a door from this side
	# too: a key opens it, and without one Wren stays here.
	var hatch := _hatch_ahead(next, direction)
	if hatch:
		hatch._on_touch(player)
		if not GameState.flags.get(LockedDoor.lock_flag(next.coord), false):
			next.queue_free()
			var back := player.global_position - current_room.global_position
			back = back.clamp(Vector2.ONE, Room.SIZE - Vector2.ONE) - Vector2(direction) * 2.0
			player.global_position = current_room.global_position + back
			_hatch_blocked = [direction, Time.get_ticks_msec() + int(LockedDoor.TOAST_COOLDOWN * 1000.0)]
			return
	busy = true
	player.frozen = true
	# Freeze both rooms (and their enemies) during the slide.
	current_room.process_mode = Node.PROCESS_MODE_DISABLED
	next.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", _room_center(next), SLIDE_TIME)
	tween.tween_property(player, "position", player.position + Vector2(direction) * ENTRY_STEP, SLIDE_TIME)
	await tween.finished
	current_room.queue_free()
	current_room = next
	current_room.process_mode = Node.PROCESS_MODE_INHERIT
	player.frozen = false
	GameState.room_coord = next.coord
	GameState.dungeon = next.dungeon
	busy = false
	Events.room_entered.emit(next.coord)
	Events.toast.emit(next.name_key)


## The closed hatch in `next` that Wren would slide into crossing the edge
## that way, or null.
func _hatch_ahead(next: Room, direction: Vector2i) -> LockedDoor:
	var arrival := player.global_position + Vector2(direction) * ENTRY_STEP
	var across := Vector2(absf(direction.y), absf(direction.x))
	for door in get_tree().get_nodes_in_group("locked_doors"):
		if not (door is LockedDoor) or not next.is_ancestor_of(door):
			continue
		var gap: Vector2 = door.global_position + Vector2(0, -4) - arrival
		# Within a tile across the edge, and between the edge and where Wren lands.
		if absf(gap.dot(across)) < 14.0 and absf(gap.dot(Vector2(direction))) < ENTRY_STEP + 8.0:
			return door
	return null


## Fade out, swap to the doorway's room, put Wren on its arrival tile, fade in.
func _on_door_entered(target: Vector2i, tile: Vector2i) -> void:
	if busy or not ResourceLoader.exists(ROOM_PATH % [target.x, target.y]):
		return
	busy = true
	player.frozen = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	current_room.queue_free()
	current_room = _spawn_room(target)
	player.position = current_room.position + Vector2(tile.x * Room.TILE + Room.TILE / 2.0, tile.y * Room.TILE + 12)
	camera.position = _room_center(current_room)
	GameState.room_coord = target
	GameState.dungeon = current_room.dungeon
	Events.room_entered.emit(target)
	Events.toast.emit(current_room.name_key)
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await tween.finished
	player.frozen = false
	busy = false


func _on_player_died() -> void:
	busy = true
	Audio.play_jingle("jingle_game_over")
	# Real-time waits: hitstop may still have the game frozen.
	await get_tree().create_timer(0.6, false, false, true).timeout
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	Engine.time_scale = 1.0
	Audio.stop_music(0.5)
	Audio.play_ambience("", 0.5)
	# The world holds still (and stays quiet) under the game over screen.
	world.process_mode = Node.PROCESS_MODE_DISABLED
	_game_over = true
	var screen := GameOverScreen.new()
	add_child(screen)
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	var wake: bool = await screen.chosen
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	screen.queue_free()
	_game_over = false
	if wake:
		respawn()
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)


## Bring Wren back at the last save (their Tidestone), with full breath.
func respawn() -> void:
	busy = true
	if _fade.color.a < 1.0:
		var tween := create_tween()
		tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
		await tween.finished
	# Time played keeps counting across deaths.
	var played := GameState.play_time
	if not SaveManager.load_game():
		GameState.reset_new_game()
	GameState.play_time = played
	GameState.refill()
	world.queue_free()
	world = null
	current_room = null
	player = null
	_start()


## The Wayshell: Mantle swoops down, carries Wren over the sea to a woken
## Tidestone and sets them down there.
func _on_fast_travel(coord: Vector2i) -> void:
	# Not mid-fall or mid-death: those sequences end in their own respawn.
	if busy or player == null or player.state in [Player.State.FALL, Player.State.DEAD]:
		return
	var landing := GameState.tidestone_position(coord)
	if landing == GameState.NO_POSITION:
		landing = RoomInfo.stone_landing(coord)
	if landing == GameState.NO_POSITION:
		return
	busy = true
	player.frozen = true
	Audio.play_sfx("wayshell")
	# Mantle swoops down and carries Wren off.
	var swoop := MantleSwoop.make(player.global_position)
	world.add_child(swoop)
	await swoop.passed
	if is_instance_valid(player):
		player.visible = false
	await swoop.finished
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	GameState.set_checkpoint(coord, landing)
	GameState.wake_tidestone(coord, landing)
	SaveManager.save_game()
	world.queue_free()
	world = null
	current_room = null
	player = null
	# The flight itself, over the sea.
	var flight := FlightScene.make(str(RoomInfo.get_room(coord).get("name_key", "")))
	add_child(flight)
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await flight.finished
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	flight.queue_free()
	_start(true)
