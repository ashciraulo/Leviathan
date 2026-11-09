class_name MantleTangle
extends Node2D
## Mantle the sky-ray lying caught in grey Choir netting on the Wreck Strand
## (cutscene 6). The director spawns it, has Wren cut the net, and then
## Mantle lifts off. Drawn from Mantle's own sprite sheet plus net lines.

signal risen

const FRAME_SIZE := Vector2(96, 80)
const FRAMES := 4
const NET := Color("#8b8f9c")
const NET_DARK := Color("#5d6070")
const RISE_TIME := 2.2
## Offset that puts the flying sprite's body over Mantle's feet.
const BODY := Vector2(-10, -6)
## The net, around the body, relative to Mantle's feet.
const NET_RECT := Rect2(-34, -30, 64, 30)

## 0 = netted and still, 1 = net gone.
var _net := 1.0
var _shake := 0.0
var _frame := 0
var _lift := 0.0
var _time := 0.0
var _flying := false


func _ready() -> void:
	z_index = 2
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_time += delta
	if _flying:
		_frame = int(_time * 9.0) % FRAMES
	elif _net > 0.5:
		# A tired twitch every couple of seconds.
		_shake = 1.0 if fmod(_time, 2.2) < 0.25 and int(_time * 20.0) % 2 == 0 else 0.0
	queue_redraw()


## Wren's blade parts the net, which falls away.
func cut() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "_net", 0.0, Cutscene.scaled(0.6))
	await tween.finished
	_shake = 0.0


## Mantle beats its wings, rises and wheels away to the north.
func rise() -> void:
	_flying = true
	_time = 0.0
	Audio.play_sfx("mantle_wings", global_position)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_lift", 1.0, Cutscene.scaled(RISE_TIME))
	await tween.finished
	visible = false
	risen.emit()


func _draw() -> void:
	var height := _lift * 260.0
	# Shadow on the sand, shrinking as Mantle climbs.
	var spread := 1.0 + _lift
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.9 / spread, 0.5 / spread))
	draw_circle(Vector2.ZERO, 22.0, Color(0.05, 0.04, 0.12, 0.32 * (1.0 - _lift)))
	# The sheet's frames are drawn in flight; BODY puts the body on the shadow.
	var at := (BODY + Vector2(_shake, -height)).round()
	draw_set_transform(at, 0.0, Vector2.ONE)
	draw_texture_rect_region(Art.MANTLE, Rect2(-FRAME_SIZE / 2.0, FRAME_SIZE),
		Rect2(Vector2(_frame * FRAME_SIZE.x, 0), FRAME_SIZE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _net <= 0.0:
		return
	# The net: a diamond mesh thrown over the body and pegged into the sand.
	# Once cut it sags and fades.
	var sag := (1.0 - _net) * 8.0
	var colour := Color(NET, _net)
	var dark := Color(NET_DARK, _net)
	var top := NET_RECT.position.y + sag
	var bottom := NET_RECT.end.y
	var x := NET_RECT.position.x
	while x < NET_RECT.end.x:
		draw_line(Vector2(x, top), Vector2(x + 12.0, bottom), colour, -1.0)
		draw_line(Vector2(x + 12.0, top), Vector2(x, bottom), dark, -1.0)
		x += 8.0
	draw_line(Vector2(NET_RECT.position.x, top), Vector2(NET_RECT.end.x + 4.0, top), colour, 1.0)
	draw_line(Vector2(NET_RECT.position.x, bottom), Vector2(NET_RECT.end.x + 4.0, bottom), dark, 1.0)
	for peg: Vector2 in [Vector2(NET_RECT.position.x, bottom), Vector2(NET_RECT.end.x + 4.0, bottom), Vector2(NET_RECT.position.x, top), Vector2(NET_RECT.end.x + 4.0, top)]:
		draw_rect(Rect2(peg.x - 1.0, peg.y - 2.0, 3.0, 4.0), Color(Palette.OUTLINE, _net))
