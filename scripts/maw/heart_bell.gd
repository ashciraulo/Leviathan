class_name HeartBell
extends Enemy
## One of the seven Tidebells, risen in the Dreaming Heart's chamber for
## its stage of the fight. With every heartbeat a ring of light closes in
## on it; strike it with the sword as the ring meets it (on the beat) and
## it sings its phrase. Off the beat it only clanks.

## Which bell (a key of Tidebell.BELLS).
var bell := "hull"
var heart: DreamingHeart
var rung := false
## After a strike off the beat the bell rings dead until the next beat
## has passed, so swinging wildly never finds it.
var _dead := 0.0


func _init() -> void:
	max_hp = 99
	contact_damage = 0
	body_size = Vector2(20, 8)
	knockback_scale = 0.0


func _ready() -> void:
	super._ready()
	_contact.active = false
	collision_layer = 1 << (Layers.WORLD - 1)
	# It rises out of the floor.
	_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.8)
	Audio.play_sfx("bell_quiet", global_position)


func take_hit(_damage: int, _direction: Vector2) -> HitResult:
	if rung or heart == null:
		return HitResult.IGNORED
	_flash = 0.1
	if _dead <= 0.0 and heart.off_beat() <= DreamingHeart.BEAT_WINDOW:
		rung = true
		heart.bell_rung(self)
		var tween := create_tween()
		tween.tween_interval(1.4)
		tween.tween_property(self, "modulate:a", 0.0, 0.6)
		tween.tween_callback(queue_free)
	else:
		Audio.play_sfx("block", global_position, 0.7)
		_dead = heart.beat_length() * (1.0 - heart.beat_phase()) + DreamingHeart.BEAT_WINDOW + 0.05
		heart.bell_missed(self)
	return HitResult.HIT


func hook_hit(_direction: Vector2) -> bool:
	return false


func _make_sprite() -> Sprite2D:
	return Art.sprite(Tidebell.BELLS[bell][0], 2, 1, 37)


func _physics_process(delta: float) -> void:
	_dead = maxf(_dead - delta, 0.0)
	super._physics_process(delta)


func _update_sprite() -> void:
	_sprite.frame = 1 if rung else 0
	queue_redraw()


func _draw() -> void:
	if rung or heart == null:
		return
	# The ring of the heartbeat closing in: it meets the bell on the beat.
	var phase := heart.beat_phase()
	var radius := 6.0 + 26.0 * (1.0 - phase)
	var near := _dead <= 0.0 and heart.off_beat() <= DreamingHeart.BEAT_WINDOW
	var color := Color(0.54, 0.94, 0.88, 0.85) if near else Color(0.82, 0.25, 0.31, 0.55)
	var center := Vector2(0, -16)
	if near:
		# Strike now: the ring thickens and the bell's heart lights up, so
		# it reads by shape as well as colour.
		draw_arc(center, radius, 0.0, TAU, 40, color, 3.0)
		draw_circle(center, 2.0, color)
	elif _dead > 0.0:
		# Struck off the beat: the ring breaks up until the next beat.
		for i in 12:
			var from := TAU * i / 12.0
			draw_arc(center, radius, from, from + TAU / 24.0, 4, color, 1.0)
	else:
		draw_arc(center, radius, 0.0, TAU, 40, color, 1.0)
