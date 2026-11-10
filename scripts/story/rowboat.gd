class_name Rowboat
extends Node2D
## Hessa's rowboat, with Hessa at the oars: it bobs on the swell, and leaves
## a widening wake behind it while it moves (cutscene 17, StoryDirector).

## Where she sits, from the boat's middle.
const SEAT := Vector2(1, 4)
const BOB := 1.2

var hessa: ChoirFigure
var _sprite: Sprite2D
## Under the hull: the swell lapping round it and the wake.
var _water: Node2D
var _time := 0.0
var _last := Vector2.ZERO
var _speed := 0.0
## Recent spots behind the boat, for its wake: [position, age].
var _wake: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Behind her, then Hessa sat low in it, then the near gunwale over her.
	hessa = ChoirFigure.new("hessa")
	hessa.position = SEAT
	hessa.sunk = 9.0
	hessa.ripples = false
	hessa.face(true)
	add_child(hessa)
	_water = Node2D.new()
	_water.show_behind_parent = true
	_water.draw.connect(_draw_water)
	add_child(_water)
	_sprite = Sprite2D.new()
	_sprite.texture = Art.ROWBOAT
	_sprite.show_behind_parent = true
	_sprite.position = Vector2(0, 2)
	add_child(_sprite)
	_last = global_position


func _process(delta: float) -> void:
	_time += delta
	var bob := sin(_time * 2.2) * BOB
	_sprite.position.y = 2.0 + bob
	hessa.position.y = SEAT.y + bob
	if delta > 0.0:
		_speed = lerpf(_speed, global_position.distance_to(_last) / delta, 0.2)
	if _speed > 4.0 and (_wake.is_empty() or (_wake[-1][0] as Vector2).distance_to(global_position) > 5.0):
		_wake.append([global_position, 0.0])
	for spot: Array in _wake:
		spot[1] += delta
	_wake = _wake.filter(func(spot: Array) -> bool: return spot[1] < 1.6)
	_last = global_position
	_water.queue_redraw()


func _draw_water() -> void:
	# The swell slapping the hull.
	_water.draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.3))
	var lap := 18.0 + sin(_time * 2.2) * 1.0
	_water.draw_arc(Vector2.ZERO, lap, 0.0, TAU, 28, Color(0.88, 0.96, 1.0, 0.55), 1.5)
	# The wake: V-shaped rings left behind as she pulls away.
	for spot: Array in _wake:
		var age: float = spot[1]
		var at: Vector2 = (spot[0] as Vector2) - global_position + Vector2(0, 7 / 0.3)
		_water.draw_arc(at, 6.0 + age * 14.0, 0.0, TAU, 18, Color(0.88, 0.96, 1.0, 0.5 * (1.0 - age / 1.6)), 1.5)
