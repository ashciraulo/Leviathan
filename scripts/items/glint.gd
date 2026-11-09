class_name Glint
extends Area2D
## A shell coin on the ground: dropped by enemies, pots, cut grass and bombs.
## It hops out, glints, and is picked up when Wren walks over it. Left
## alone it blinks and goes after a while. Worth 1, 5 or 20.

const LIFETIME := 12.0
const BLINK_TIME := 3.0
const HOP_TIME := 0.35
const HOP_HEIGHT := 8.0
## value: [shell, rim] colours. Amber 1, sea-blue 5, coral 20.
const LOOKS := {
	1: [Color("#f2c25b"), Color("#9a6a2a")],
	5: [Color("#7fd3e8"), Color("#2f6f8a")],
	20: [Color("#f08a7a"), Color("#8a3a3a")],
}

var value := 1
var _age := 0.0
var _hop_from := Vector2.ZERO
var _hop_to := Vector2.ZERO
var _taken := false


## Drops coins worth `total` (in the fewest coins) at `at`, local to
## `parent`, each hopping a little way out.
static func drop(parent: Node, at: Vector2, total: int) -> Array[Glint]:
	var made: Array[Glint] = []
	if parent == null or total <= 0:
		return made
	var left := total
	var i := 0
	for coin in [20, 5, 1]:
		while left >= coin:
			left -= coin
			var glint := Glint.new()
			glint.value = coin
			var angle := TAU * (0.15 + 0.29 * i)
			glint._hop_from = at
			glint._hop_to = at + Vector2(cos(angle), sin(angle) * 0.6) * (6.0 + 3.0 * (i % 3))
			glint.position = at
			parent.add_child(glint)
			made.append(glint)
			i += 1
	return made


## How much a broken pot, a cut tuft or a fallen enemy leaves: usually
## nothing much, now and then a better coin. `odds` is the chance of any.
static func roll(odds: float) -> int:
	if randf() >= odds:
		return 0
	var r := randf()
	if r < 0.04:
		return 20
	if r < 0.22:
		return 5
	return 1


func _ready() -> void:
	add_to_group("glints")
	Layers.assign(self, 0, [Layers.PLAYER])
	monitorable = false
	add_child(Layers.circle_shape(6.0, Vector2(0, -3)))
	body_entered.connect(_on_body_entered)
	z_index = 1


func _process(delta: float) -> void:
	_age += delta
	if _age < HOP_TIME:
		var t := _age / HOP_TIME
		position = _hop_from.lerp(_hop_to, t)
	elif _age - delta < HOP_TIME:
		position = _hop_to
	# Landed under Wren: body_entered won't come again, so look.
	if not _taken and _age >= HOP_TIME * 0.6:
		for body in get_overlapping_bodies():
			_on_body_entered(body)
	if _age >= LIFETIME and not _taken:
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _taken or not (body is Player) or _age < HOP_TIME * 0.6:
		return
	_taken = true
	GameState.give_item("glint", value, false)
	Audio.play_sfx("pickup", global_position, 1.0 + 0.15 * (LOOKS.keys().find(value)))
	set_deferred("monitoring", false)
	# Up and gone, with a glint.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 10.0, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	# Blinks before it goes.
	if not _taken and _age > LIFETIME - BLINK_TIME and int(_age * 10.0) % 2 == 0:
		return
	var lift := 0.0
	if _age < HOP_TIME:
		lift = sin(_age / HOP_TIME * PI) * HOP_HEIGHT
	elif not _taken:
		lift = 1.0 + sin(_age * 4.0)
	# Shadow on the ground, coin above it.
	draw_rect(Rect2(-3, -1, 6, 2), Palette.SHADOW)
	var look: Array = LOOKS.get(value, LOOKS[1])
	var y := -4.0 - lift
	draw_rect(Rect2(-3, y - 2, 6, 5), Palette.OUTLINE)
	draw_rect(Rect2(-2, y - 3, 4, 7), Palette.OUTLINE)
	draw_rect(Rect2(-2, y - 2, 4, 5), look[0])
	# Shell ridges and a glint that comes and goes.
	draw_rect(Rect2(-1, y - 1, 1, 3), look[1])
	draw_rect(Rect2(1, y - 1, 1, 3), look[1])
	if int(_age * 3.0) % 4 == 0:
		draw_rect(Rect2(-2, y - 2, 1, 1), Color.WHITE)
