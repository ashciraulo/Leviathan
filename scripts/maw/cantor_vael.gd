class_name CantorVael
extends Enemy
## The duel in the Maw: Cantor Vael, who was a lamp keeper once and leads
## the Drowned Choir now, singing the Old One awake to end its suffering.
##
## He fights with his voice:
##   - He draws a breath and lifts his hands (the tell), then sings notes
##     that drift after Wren. The sword sends a note back; a note sung back
##     at him breaks his song.
##   - Every other verse, his two singers chant: a mark glows on the floor
##     under Wren, and a ring of sound rolls out from it. Glide over it,
##     or scatter it with the Echo Horn.
##   - His song guards him from the sword.
## When his song is broken for good he doesn't fall. He stops singing and
## listens, and the north bars open on the way to the Heart.

enum Mode { INTRO, DRIFT, BREATH, SING, CHANT, LISTEN }

const DEFEATED_FLAG := "boss_maw_vael"
const DRIFT_SPEED := 26.0
const BREATH_TIME := 0.8
const SING_GAP := 0.35
const CHANT_TELL := 0.7
## Seconds between verses.
const REST_TIME := 1.8
## Where his singers stand, either side of him (in tiles from his spot).
const SINGER_OFFSETS := [Vector2(-6, 1), Vector2(6, 1)]

var mode := Mode.INTRO
var _timer := 1.0
var _verse := 0
var _home := Vector2.ZERO
var _room: Room
var _singers: Array[ChoirFigure] = []
var _drift_dir := 1.0
## A remembered fight (EchoTrial): no words, before or after.
var _echo := false
## The first time, the Choir is mid-song when Wren walks in (cutscene 18,
## StoryDirector.vaels_choir): no fight until the scene wakes him.
var asleep := false


## What a V tile becomes in Vael's hall: Vael, or once his song is broken,
## Vael standing quiet, listening to the Old One.
static func spawn_in(room: Room, pos: Vector2) -> Node2D:
	# His song broken for good, unless Wren has come back to its echo.
	if GameState.has_flag(DEFEATED_FLAG) and not EchoTrial.here(room):
		var still := ChoirFigure.new("vael")
		still.position = pos
		return still
	var boss := CantorVael.new()
	boss._room = room
	if EchoTrial.here(room):
		boss._echo = true
		EchoTrial.dress(room)
	return boss


func _init() -> void:
	max_hp = 6
	contact_damage = 1
	body_size = Vector2(12, 8)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if _room == null:
		_room = get_parent() as Room
	_home = position
	for offset: Vector2 in SINGER_OFFSETS:
		var singer := ChoirFigure.new("singer")
		singer.position = position + offset * Room.TILE
		singer.face(offset.x > 0)
		get_parent().add_child.call_deferred(singer)
		_singers.append(singer)
	# A few words before the song (not in an echo of it). The first time,
	# the story's scene says them.
	if not _echo and get_tree().get_first_node_in_group("story_director") and StoryDirector.choir_waits():
		asleep = true
		return
	Events.toast.emit("BOSS_VAEL")
	if not _echo:
		Events.conversation_requested.emit.call_deferred(_pages(["VAEL_MAW_1", "VAEL_MAW_2"]))


## The scene is over: the duel begins.
func wake() -> void:
	asleep = false
	_timer = 0.6
	Events.toast.emit("BOSS_VAEL")
	Events.boss_woke.emit()


func _think(delta: float) -> void:
	_timer -= delta
	var wren := get_player()
	if wren == null:
		velocity = Vector2.ZERO
		return
	var angry := hp * 2 <= max_hp
	match mode:
		Mode.INTRO:
			velocity = Vector2.ZERO
			if not asleep and _timer <= 0.0:
				_enter(Mode.DRIFT, REST_TIME)
		Mode.DRIFT:
			# He keeps his distance, pacing along the head of the hall.
			if absf(position.x - _home.x) > 4.0 * Room.TILE:
				_drift_dir = -signf(position.x - _home.x)
			velocity = Vector2(_drift_dir * DRIFT_SPEED, (_home.y - position.y) * 2.0)
			if _timer <= 0.0:
				_verse += 1
				if _verse % 2 == 0:
					_enter(Mode.CHANT, CHANT_TELL)
					for singer in _singers:
						singer.talking = true
				else:
					_enter(Mode.BREATH, BREATH_TIME * (0.75 if angry else 1.0))
					Audio.play_sfx("enemy_tell", global_position, 1.2)
		Mode.BREATH:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter(Mode.SING, 0.0)
				_sing_verse(wren, 3 if angry else 2)
		Mode.SING:
			velocity = Vector2.ZERO
		Mode.CHANT:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_chant(wren, angry)
				for singer in _singers:
					singer.talking = false
				_enter(Mode.DRIFT, REST_TIME)
		Mode.LISTEN:
			velocity = Vector2.ZERO


func _enter(new_mode: Mode, time: float) -> void:
	mode = new_mode
	_timer = time


## A verse: notes sung one after another, fanned toward Wren.
func _sing_verse(wren: Player, count: int) -> void:
	for i in count:
		# Thrown off his verse (a note sung back at him): he stops.
		if dying or not is_inside_tree() or mode != Mode.SING:
			return
		var note := SungNote.new()
		note.singer = self
		var aim := (wren.global_position - global_position).angle() + (i - (count - 1) / 2.0) * 0.5
		note.velocity = Vector2.from_angle(aim) * SungNote.SPEED
		get_parent().add_child(note)
		note.global_position = global_position + Vector2(0, -12)
		Audio.play_sfx("vael_sing", global_position, 1.0 + i * 0.12)
		await get_tree().create_timer(SING_GAP, false).timeout
	if not dying and mode == Mode.SING:
		_enter(Mode.DRIFT, REST_TIME)


## The singers' chant: rings of sound from under Wren's feet (and, angry,
## from each singer too).
func _chant(wren: Player, angry: bool) -> void:
	var spots := [wren.global_position]
	if angry:
		for singer in _singers:
			spots.append(singer.global_position)
	for i in spots.size():
		var wave := ChantWave.new()
		# Angry, the singers join in one after another, not all at once.
		wave.delay = i * 0.9
		get_parent().add_child(wave)
		wave.global_position = spots[i]


## A note sung back at him: it breaks his song.
func note_hit(_note: Node) -> void:
	if dying:
		return
	hp -= 1
	_flash = 0.15
	Feel.shake(2.0)
	Audio.play_sfx("vael_falter", global_position)
	if hp <= 0:
		_listen()
	elif mode != Mode.LISTEN:
		# Thrown off his verse.
		_enter(Mode.DRIFT, REST_TIME * 0.6)


## The sword can't reach him through his song.
func _blocks_hit(_direction: Vector2) -> bool:
	return true


func _on_blocked(_direction: Vector2) -> void:
	_flash = 0.03
	Audio.play_sfx("block", global_position, 1.2)


func hook_hit(_direction: Vector2) -> bool:
	return false


func arrow_hit(_direction: Vector2) -> void:
	_on_blocked(Vector2.ZERO)


## His song is broken. He doesn't fall: he stops, and listens.
func _listen() -> void:
	dying = true
	mode = Mode.LISTEN
	velocity = Vector2.ZERO
	_contact.active = false
	_contact.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	GameState.set_flag(DEFEATED_FLAG)
	Events.boss_defeated.emit()
	for node in get_tree().get_nodes_in_group("sung_notes"):
		(node as SungNote).burst()
	for child in get_parent().get_children():
		if child is ChantWave:
			child.horn_hit(Vector2.ZERO)
	Audio.play_sfx("vael_falter", global_position, 0.7)
	_sprite.frame = 0
	await get_tree().create_timer(1.2, false).timeout
	if not is_inside_tree() or _echo:
		return
	Events.conversation_requested.emit(_pages(["VAEL_MAW_END_1", "VAEL_MAW_END_2", "VAEL_MAW_END_3"]))
	await Events.dialogue_finished
	if not is_inside_tree():
		return
	# His singers slip away; he stays, listening.
	for singer in _singers:
		if is_instance_valid(singer):
			singer.walk_along([singer.position + Vector2(0, 3 * Room.TILE)], 30.0, -1)


static func _pages(keys: Array) -> Array:
	var pages := []
	for key: String in keys:
		pages.append({"name": "NAME_VAEL", "portrait": Art.PORTRAIT_VAEL, "text": key})
	return pages


func _make_sprite() -> Sprite2D:
	return Art.sprite(Art.VILLAGER_VAEL, 3, 1, 22)


func _update_sprite() -> void:
	if mode == Mode.LISTEN:
		_sprite.frame = 0
		return
	if mode in [Mode.BREATH, Mode.SING, Mode.CHANT]:
		_sprite.frame = 2
		if mode == Mode.BREATH:
			_jitter(_timer)
	else:
		_sprite.frame = 1 if int(Time.get_ticks_msec() / 800.0) % 2 == 1 else 0
	var wren := get_player()
	if wren:
		_sprite.flip_h = wren.global_position.x < global_position.x
