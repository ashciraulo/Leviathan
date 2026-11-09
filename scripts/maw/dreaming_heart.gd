class_name DreamingHeart
extends Node2D
## The last fight: the Dreaming Heart, the Old One's nightmare given a
## body, beating too fast. It storms up out of the floor of the Maw, made
## of echoes of every boss Wren has calmed.
##
## The rhythm phase, seven stages, one per Tidebell, in the order Wren
## rang them:
##   - An echo of that dungeon's boss rises beside the Heart and fires at
##     Wren, with a flash before each shot (the tell).
##   - That dungeon's bell rises from the floor. With every heartbeat a
##     ring of light closes in on it; strike the bell with the sword as the
##     ring meets it, on the beat, and the bell sings its phrase and the
##     echo is calmed. Off the beat, it only clanks, and the echo answers.
## The eighth line: with every bell rung the Heart still races. No bell
## holds the last line: Wren holds Hum, and the Heart slows with it. Hum
## long enough and the Old One hums back, and sleeps.

enum Mode { WAKING, BELL, CALMING, EIGHTH, SLEEP }

const ROOM_KEY := "ROOM_MAW_HEART"
const DEFEATED_FLAG := "the_end"
const CREDITS_SCENE := "res://scenes/credits.tscn"
## The bells in the order Wren rang them, and the boss each one calmed:
## [texture, frames, foot row].
const STAGES := [
	["hull", HullSprites.MATRIARCH, 7, 45],
	["kiln", KilnSprites.WYRM_HEAD, 3, 25],
	["mire", MireSprites.HEART, 2, 18],
	["gale", GaleSprites.STORMHERON, 4, 46],
	["glacier", GlacierSprites.RIMEBACK, 4, 54],
	["belfry", BelfrySprites.KNELL, 2, 38],
	["tomb", TombSprites.REGENT, 4, 62],
]
## Where each stage's bell rises, in tiles from the room's corner.
const BELL_TILES := [
	Vector2i(5, 8), Vector2i(18, 8), Vector2i(8, 10), Vector2i(15, 10),
	Vector2i(4, 6), Vector2i(19, 6), Vector2i(11, 9),
]
## Where the echoes hang, either side of the Heart (pixels from it).
const ECHO_SPOTS := [Vector2(-64, 10), Vector2(64, 10)]
## Seconds per heartbeat: racing, then (humming) slowing to sleep.
const BEAT_FAST := 0.9
const BEAT_SLOW := 2.2
## How near the beat a strike must land (seconds either side).
const BEAT_WINDOW := 0.16
## Seconds of Hum the eighth line takes.
const HUM_NEEDED := 3.5
const WAKE_TIME := 2.5
const CALM_TIME := 1.6

## Off in tests: the ending doesn't leave the game for the credits.
static var roll_credits := true

var mode := Mode.WAKING
var stage := 0
var hum_held := 0.0
var _room: Room
var _sprite: Sprite2D
var _beat := BEAT_FAST
## Seconds into the current beat.
var _beat_time := 0.0
var _swell := 0.0
var _timer := WAKE_TIME
var _echo: HeartEcho
var _bell: HeartBell


## What a V tile becomes in the Heart's chamber: the Heart, or once it
## sleeps, the Heart at rest.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	var heart := DreamingHeart.new()
	heart._room = room
	heart.position = pos
	if GameState.has_flag(DEFEATED_FLAG):
		heart.mode = Mode.SLEEP
		heart._beat = BEAT_SLOW * 1.5
	return heart


func _ready() -> void:
	add_to_group("boss")
	if _room == null:
		_room = get_parent() as Room
	add_child(Art.shadow(true))
	_sprite = Art.sprite(MawSprites.DREAMING_HEART, 2, 1, 55)
	_sprite.set_meta("contrast", Palette.CONTRAST_ENEMY)
	add_child(_sprite)
	var body := StaticBody2D.new()
	Layers.assign(body, Layers.WORLD, [])
	body.add_child(Layers.rect_shape(Vector2(48, 14), Vector2(0, -7)))
	add_child(body)
	if mode == Mode.SLEEP:
		return
	Events.toast.emit("BOSS_HEART")
	Audio.play_sfx("heart_roar", global_position)
	Feel.shake(3.0)
	# It storms up out of the floor.
	_sprite.position.y += 40
	_sprite.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sprite, "position:y", _sprite.position.y - 40, WAKE_TIME * 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "modulate:a", 1.0, WAKE_TIME * 0.5)


func _exit_tree() -> void:
	GameState.final_line = false


func _physics_process(delta: float) -> void:
	_beat_time += delta
	if _beat_time >= _beat:
		_beat_time -= _beat
		_on_beat()
	_swell = maxf(_swell - delta * 4.0, 0.0)
	_sprite.frame = 1 if _swell > 0.5 else 0
	_sprite.scale = Vector2.ONE * (1.0 + _swell * 0.03)
	if Cutscene.active:
		return
	_timer -= delta
	match mode:
		Mode.WAKING:
			if _timer <= 0.0:
				_start_stage()
		Mode.CALMING:
			if _timer <= 0.0:
				stage += 1
				if stage >= STAGES.size():
					_start_eighth()
				else:
					_start_stage()
		Mode.EIGHTH:
			_eighth(delta)


func _on_beat() -> void:
	_swell = 1.0
	if mode == Mode.SLEEP:
		return
	Audio.play_sfx("heart_beat", global_position, 0.8 if mode == Mode.EIGHTH else 1.0)
	if mode != Mode.EIGHTH:
		Feel.shake(0.8)


## How far the current beat is from the nearest heartbeat, in seconds.
func off_beat() -> float:
	return minf(_beat_time, _beat - _beat_time)


## 0 right on a beat, rising to 1 just before the next.
func beat_phase() -> float:
	return _beat_time / _beat


## Seconds per heartbeat right now.
func beat_length() -> float:
	return _beat


func _start_stage() -> void:
	mode = Mode.BELL
	var info: Array = STAGES[stage]
	_echo = HeartEcho.new()
	_echo.texture = info[1]
	_echo.frames = info[2]
	_echo.foot = info[3]
	_echo.heart = self
	_echo.position = position + ECHO_SPOTS[stage % 2]
	_echo.shot_every = 2.6 - stage * 0.15
	get_parent().add_child(_echo)
	_bell = HeartBell.new()
	_bell.bell = info[0]
	_bell.heart = self
	var tile: Vector2i = BELL_TILES[stage]
	_bell.position = Vector2(tile.x * Room.TILE + Room.TILE / 2.0, tile.y * Room.TILE + Room.TILE - 4)
	# Never rise up on top of Wren: shift two tiles toward the middle.
	var wren := get_tree().get_first_node_in_group("player") as Node2D
	if wren and _room and (wren.global_position - _room.global_position).distance_to(_bell.position) < 20.0:
		_bell.position.x += signf(Room.SIZE.x / 2.0 - _bell.position.x) * 2.0 * Room.TILE
	get_parent().add_child(_bell)


## A bell struck on the beat: its phrase calms the echo.
func bell_rung(_which: HeartBell) -> void:
	if mode != Mode.BELL:
		return
	mode = Mode.CALMING
	_timer = CALM_TIME
	if _echo:
		_echo.calm()
	_echo = null
	Audio.play_sfx("bell_ring", global_position, 0.8 + stage * 0.08)
	Feel.shake(1.5)


## A bell struck off the beat: the echo answers at once.
func bell_missed(_which: HeartBell) -> void:
	if _echo:
		_echo.fire_now()


func _start_eighth() -> void:
	mode = Mode.EIGHTH
	hum_held = 0.0
	GameState.final_line = true
	# Nothing left in the air while Wren stands still to hum.
	for shot in get_tree().get_nodes_in_group("enemy_shots"):
		shot.queue_free()


func _eighth(delta: float) -> void:
	var wren := get_tree().get_first_node_in_group("player") as Player
	var humming := wren != null and wren.state == Player.State.HUM
	if humming:
		hum_held += delta
	else:
		hum_held = maxf(hum_held - delta * 0.5, 0.0)
	# The Heart slows with Wren's humming.
	_beat = lerpf(BEAT_FAST, BEAT_SLOW, clampf(hum_held / HUM_NEEDED, 0.0, 1.0))
	if hum_held >= HUM_NEEDED:
		_sleep()


## The Old One hums back, the first time anyone has heard its voice, and
## sleeps.
func _sleep() -> void:
	mode = Mode.SLEEP
	GameState.final_line = false
	GameState.set_flag(DEFEATED_FLAG)
	# Not boss_defeated: the ending keeps its own music. Clear stray shots.
	for shot in get_tree().get_nodes_in_group("enemy_shots"):
		shot.queue_free()
	# Keep the ending: Continue after the credits starts here, not before
	# the Maw.
	GameState.set_checkpoint(_room.coord if _room else GameState.room_coord, GameState.NO_POSITION)
	SaveManager.save_game()
	_beat = BEAT_SLOW * 1.5
	Audio.play_sfx("old_one_hum", global_position)
	Feel.shake(4.0)
	await get_tree().create_timer(2.5, false).timeout
	if not is_inside_tree():
		return
	Events.dialogue_requested.emit("", PackedStringArray(["MAW_HUMS_BACK_1", "MAW_HUMS_BACK_2"]))
	await Events.dialogue_finished
	if not is_inside_tree():
		return
	await get_tree().create_timer(1.5, false).timeout
	if not is_inside_tree():
		return
	Events.game_finished.emit()
	if roll_credits:
		get_tree().change_scene_to_file.call_deferred(CREDITS_SCENE)


func _draw() -> void:
	if mode == Mode.SLEEP:
		return
	# The Heart's glow pulses with each beat.
	var a := 0.1 + 0.2 * _swell
	draw_circle(Vector2(0, -22), 30.0 + _swell * 4.0, Color(0.82, 0.25, 0.31, a * 0.5))


func _process(_delta: float) -> void:
	queue_redraw()
