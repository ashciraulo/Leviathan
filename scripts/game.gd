extends Node2D
## The play scene: builds the world, Wren, the camera and the HUD, slides the
## camera between rooms, and brings Wren back to the last Tidestone on death.

const ROOM_PATH := "res://rooms/room_%d_%d.tscn"
const SLIDE_TIME := 0.45
## How far Wren walks into the new room during the slide.
const ENTRY_STEP := 20.0
const FADE_TIME := 0.35

var world: Node2D
var player: Player
var camera: GameCamera
var current_room: Room
## True during a room slide or the death sequence.
var busy := false

var _fade: ColorRect


func _ready() -> void:
	camera = GameCamera.new()
	add_child(camera)
	camera.make_current()
	add_child(Hud.new())
	add_child(PauseMenu.new())
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 30
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)
	Events.player_died.connect(_on_player_died)
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


## Build the world at the checkpoint in GameState.
func _start() -> void:
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
	var next := _spawn_room(current_room.coord + direction)
	if next == null:
		# Nothing that way: keep Wren inside this room.
		var local := player.global_position - current_room.global_position
		local = local.clamp(Vector2.ONE, Room.SIZE - Vector2.ONE)
		player.global_position = current_room.global_position + local
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
	busy = false
	Events.room_entered.emit(next.coord)
	Events.toast.emit(next.name_key)


func _on_player_died() -> void:
	busy = true
	# Real-time waits: hitstop may still have the game frozen.
	await get_tree().create_timer(0.6, false, false, true).timeout
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	Engine.time_scale = 1.0
	if not SaveManager.load_game():
		GameState.reset_new_game()
	GameState.refill()
	world.queue_free()
	world = null
	current_room = null
	player = null
	_start()
