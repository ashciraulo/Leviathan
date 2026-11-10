class_name HeartEcho
extends Node2D
## An echo of a boss Wren has calmed, risen out of the Dreaming Heart: a
## ghost of it in dream-light that hangs beside the Heart and fires at
## Wren. Before each shot it flares bright (the tell). Its bell's phrase
## calms it, and it fades away.

const TELL_TIME := 0.6
const SHOT_SPEED := 70.0

var texture: Texture2D
var frames := 1
var foot := 16
var heart: Node2D
var shot_every := 2.6
var calmed := false
var _sprite: Sprite2D
var _timer := 1.5
var _telling := false
var _time := 0.0
var _base_x := 0.0


func _ready() -> void:
	z_index = 1
	_sprite = Art.sprite(texture, frames, 1, foot)
	# A ghost of dream-light: washed pale, then tinted the colour of the
	# Maw's veins, and half see-through.
	_sprite.modulate = Color(0.55, 0.95, 0.9, 0.0)
	_base_x = _sprite.position.x
	add_child(_sprite)
	Art.set_flash(_sprite, 0.55)
	create_tween().tween_property(_sprite, "modulate:a", 0.75, 0.8)
	Audio.play_sfx("echo_rise", global_position)


func _physics_process(delta: float) -> void:
	_time += delta
	_sprite.position.y = -foot - 1 + sin(_time * 2.0) * 3.0
	if calmed or Cutscene.active:
		return
	_timer -= delta
	if not _telling and _timer <= TELL_TIME:
		_telling = true
		Audio.play_sfx("enemy_tell", global_position, 0.7)
	if _telling:
		var flare := int(_time * 16.0) % 2 == 0
		_sprite.modulate = Color(1.0, 0.55, 0.6, 0.95) if flare else Color(0.55, 0.95, 0.9, 0.75)
		# It shudders as it flares, so the tell isn't in the colour alone.
		_sprite.position.x = _base_x + (1.0 if flare else -1.0)
	if _timer <= 0.0:
		_fire()


## Fire right away (its bell was struck off the beat).
func fire_now() -> void:
	if not calmed and not _telling:
		_timer = minf(_timer, TELL_TIME)


func _fire() -> void:
	_telling = false
	_timer = shot_every
	_sprite.modulate = Color(0.55, 0.95, 0.9, 0.75)
	_sprite.position.x = _base_x
	var wren := get_tree().get_first_node_in_group("player") as Node2D
	if wren == null:
		return
	var aim := (wren.global_position - global_position).angle()
	for i in 3:
		var shot := Projectile.new()
		shot.velocity = Vector2.from_angle(aim + (i - 1) * 0.3) * SHOT_SPEED
		get_parent().add_child(shot)
		shot.global_position = global_position + Vector2(0, -foot / 2.0)
		shot.modulate = Color(1.0, 0.6, 0.7)
	Audio.play_sfx("enemy_shot", global_position, 0.8)


## Its phrase is sung: it sighs, and fades into the dark.
func calm() -> void:
	calmed = true
	_sprite.position.x = _base_x
	Audio.play_sfx("echo_calm", global_position)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sprite, "modulate", Color(0.9, 1.0, 1.0, 0.0), 1.4)
	tween.tween_property(_sprite, "position:y", _sprite.position.y - 12, 1.4)
	tween.chain().tween_callback(queue_free)
