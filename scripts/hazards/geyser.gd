class_name Geyser
extends StaticBody2D
## A steam vent in a rock cone. It idles, hisses (a wisp of steam: the tell),
## then blows a column of scalding steam straight up for a moment. Wren can't
## walk through the cone, and the column hurts. Each geyser starts at a
## different point in its cycle so a field of them takes timing to cross.

enum Phase { IDLE, HISS, BLOW }

const IDLE_TIME := 2.2
const HISS_TIME := 0.7
const BLOW_TIME := 1.0
## The steam column above the cone (width, height), measured up from the base.
const COLUMN := Vector2(10, 40)

var phase := Phase.IDLE
var _timer := 0.0
var _sprite: Sprite2D
var _steam: DamageArea


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 7), Vector2(0, -3.5)))
	add_child(Art.shadow())
	_sprite = Art.sprite(Art.GEYSER, 3, 1, 30)
	add_child(_sprite)
	_steam = DamageArea.new()
	_steam.name = "Steam"
	Layers.assign(_steam, Layers.ENEMY_ATTACK, [])
	_steam.monitoring = false
	_steam.add_child(Layers.rect_shape(COLUMN, Vector2(0, -COLUMN.y / 2.0 - 4)))
	add_child(_steam)
	_set_phase(Phase.IDLE)
	# Stagger by position so neighbouring vents are out of step (after
	# _set_phase, which would reset the timer).
	_timer = fposmod(position.x * 0.013 + position.y * 0.007, IDLE_TIME)


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	match phase:
		Phase.IDLE:
			_set_phase(Phase.HISS)
		Phase.HISS:
			_set_phase(Phase.BLOW)
		Phase.BLOW:
			_set_phase(Phase.IDLE)


func _set_phase(next: Phase) -> void:
	phase = next
	match next:
		Phase.IDLE:
			_timer = IDLE_TIME
		Phase.HISS:
			_timer = HISS_TIME
		Phase.BLOW:
			_timer = BLOW_TIME
	_sprite.frame = int(next)
	_steam.set_deferred("monitorable", next == Phase.BLOW)
	_steam.active = next == Phase.BLOW


func is_blowing() -> bool:
	return phase == Phase.BLOW
