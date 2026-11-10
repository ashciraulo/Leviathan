class_name WyrmSegment
extends Node2D
## One plate of the Slagwyrm's body. Molten, it burns Wren on contact and
## nothing can hurt it. Dragged through a quench pool it sets into dark
## crust for a while: then it's harmless, and one blow of the Stonebreaker
## Mallet cracks it off. It glows through its cracks just before it melts.

const MELT_WARNING := 1.5

var boss: Slagwyrm
## Seconds of crust left (0 = molten).
var hard_time := 0.0
var _origin_x := 0.0
## Hidden while it's still under the floor (or the wyrm has dived).
var surfaced := false
var _sprite: Sprite2D
var _contact: DamageArea
var _shell: Area2D


func _ready() -> void:
	add_to_group("wyrm_segments")
	_contact = DamageArea.new()
	_contact.name = "Contact"
	_contact.damage = 1
	Layers.assign(_contact, Layers.ENEMY_ATTACK, [])
	_contact.monitoring = false
	_contact.add_child(Layers.circle_shape(7.0, Vector2(0, -7)))
	add_child(_contact)
	# The mallet looks for things on the hurtbox layer.
	_shell = Area2D.new()
	_shell.name = "Shell"
	Layers.assign(_shell, Layers.ENEMY_HURTBOX, [])
	_shell.monitoring = false
	_shell.add_child(Layers.circle_shape(9.0, Vector2(0, -7)))
	add_child(_shell)
	add_child(Art.shadow(true))
	_sprite = Art.sprite(KilnSprites.WYRM_SEGMENT, 3, 1, 16)
	_origin_x = _sprite.position.x
	add_child(_sprite)
	_refresh()


func is_hard() -> bool:
	return hard_time > 0.0


func harden(time: float) -> void:
	if not is_hard():
		Feel.shake(0.5)
		Audio.play_sfx("bomb_fuse", global_position, 0.6)
		boss.steam_at(global_position)
	hard_time = time
	_refresh()


func melt() -> void:
	hard_time = 0.0
	_refresh()


func set_surfaced(value: bool) -> void:
	surfaced = value
	_refresh()


func _physics_process(delta: float) -> void:
	if hard_time > 0.0:
		hard_time = maxf(hard_time - delta, 0.0)
		_refresh()
	elif Settings.high_contrast:
		Art.set_flash(_sprite, 0.0)


func _refresh() -> void:
	visible = surfaced
	_contact.active = surfaced and not is_hard()
	_shell.monitorable = surfaced
	_sprite.position.x = _origin_x
	if not is_hard():
		_sprite.frame = 0
	else:
		var melting := hard_time < MELT_WARNING
		_sprite.frame = 2 if melting and int(hard_time * 8.0) % 2 == 0 else 1
		# About to melt: the crust trembles, not only its cracks glowing.
		if melting:
			_sprite.position.x += 1.0 if int(hard_time * 30.0) % 2 == 0 else -1.0
	# High contrast outlines a plate only while it burns.
	_sprite.set_meta("contrast", Palette.CONTRAST_ENEMY if not is_hard() else Color.TRANSPARENT)
	Art.set_flash(_sprite, 0.0)


## The mallet struck this plate. Only set crust breaks.
func mallet_hit(_direction: Vector2) -> bool:
	if not surfaced or not is_hard() or boss == null:
		return false
	boss.segment_smashed(self)
	return true
