class_name EchoGame
extends Node2D
## Coralie's echo game on Saltmarrow Shore (StoryDirector), once her chime
## is hung and she's shown Wren (coralie_echo_ask). Striking the chime
## (GlassChime.interact) starts a round: the glass sings a tune, each note
## lighting one of four shells on the sand, and Wren hops the shells back in
## the same order. Every tune landed is one note longer. A wrong shell ends
## the round, and so does walking off. Five, eight and twelve notes set
## echo_5, echo_8 and echo_12 for Coralie's prizes.

enum State { IDLE, SHOW, LISTEN }

const ASK_FLAG := "coralie_echo_ask"
const BEST_FLAG := "echo_best"
const MILESTONES := [5, 8, 12]
const START_LENGTH := 3
## Shells on the sand, as room tiles: top, left, right, bottom.
const SHELLS := [Vector2i(17, 5), Vector2i(15, 6), Vector2i(19, 6), Vector2i(17, 7)]
## Each shell's note and colour (the chime's own sea-glass).
const PITCHES := [1.5, 1.0, 1.2, 0.8]
const COLOURS := [Color("#b4fff0"), Color("#86ccb4"), Color("#e8b85a"), Color("#62b4de")]
const SHELL := Color("#f4e2c6")
const SHELL_SHADE := Color("#c8b090")
## Seconds per note as the glass sings, and the pause before it starts.
const NOTE_TIME := 0.7
const LEAD_IN := 0.8
## Wren walking further than this from the shells ends the round.
const LEAVE := 96.0

var state := State.IDLE
var tune: Array[int] = []
## How far through the tune: the note playing, or the next shell to hop.
var at := 0
var _timer := 0.0
var _lit := -1
var _glow := 0.0
var _on := -1
var _time := 0.0


## The lit shell's flash, drawn above Wren so it shows even underfoot.
var _flash: Node2D


func _ready() -> void:
	# Flat on the sand, under Wren's feet.
	z_index = -1
	_flash = Node2D.new()
	_flash.z_index = 6
	_flash.z_as_relative = false
	_flash.draw.connect(_draw_flash)
	add_child(_flash)


static func open() -> bool:
	return GameState.has_flag(ASK_FLAG)


static func best() -> int:
	return int(GameState.flags.get(BEST_FLAG, 0))


static func centre() -> Vector2:
	return Vector2(SHELLS[0] + SHELLS[3]) * 8.0 + Vector2(8, 8)


static func shell_at(i: int) -> Vector2:
	return Vector2(SHELLS[i]) * 16.0 + Vector2(8, 8)


## The chime struck: a new round, three notes to start.
func start() -> void:
	if not open() or state != State.IDLE:
		return
	tune.clear()
	for i in START_LENGTH:
		tune.append(randi() % SHELLS.size())
	_sing()


func _sing() -> void:
	state = State.SHOW
	at = 0
	_timer = LEAD_IN


func _light(i: int) -> void:
	_lit = i
	_glow = 0.5
	Audio.play_sfx("glass_chime", global_position + shell_at(i), PITCHES[i])


## Which shell Wren is standing on, or -1.
func _shell_under(wren: Node2D) -> int:
	var tile := Vector2i(((wren.global_position - global_position) / 16.0).floor())
	return SHELLS.find(tile)


func _process(delta: float) -> void:
	_time += delta
	_glow = maxf(_glow - delta, 0.0)
	var wren := Lantern.player(get_tree())
	if state != State.IDLE and (wren == null or (wren.global_position - global_position).distance_to(centre()) > LEAVE):
		state = State.IDLE
		Audio.play_sfx("bubble_pop", global_position + centre(), 0.7)
	match state:
		State.SHOW:
			_timer -= delta
			if _timer <= 0.0:
				if at < tune.size():
					_light(tune[at])
					at += 1
					_timer = NOTE_TIME
				else:
					state = State.LISTEN
					at = 0
					_on = _shell_under(wren) if wren else -1
		State.LISTEN:
			var under := _shell_under(wren)
			if under != _on:
				_on = under
				if under >= 0:
					hop(under)
	queue_redraw()
	_flash.queue_redraw()


## Wren lands on shell `i` (tests call it directly).
func hop(i: int) -> void:
	if state != State.LISTEN:
		return
	if i != tune[at]:
		state = State.IDLE
		Audio.play_sfx("bubble_pop", global_position + shell_at(i), 0.7)
		# Show the shell it should have been.
		_lit = tune[at]
		_glow = 0.9
		return
	_light(i)
	at += 1
	if at < tune.size():
		return
	# The whole tune: one note longer next time.
	var length := tune.size()
	if length > best():
		GameState.set_flag(BEST_FLAG, length)
	for n: int in MILESTONES:
		if length == n and not GameState.has_flag("echo_%d" % n):
			GameState.set_flag("echo_%d" % n)
			Events.toast.emit("TOAST_ECHO_%d" % n)
			Audio.play_jingle("jingle_secret")
	tune.append(randi() % SHELLS.size())
	_sing()


func _draw() -> void:
	if not open():
		return
	for i in SHELLS.size():
		var c := shell_at(i) + Vector2(0, 3)
		var lit := i == _lit and _glow > 0.0
		var tint: Color = COLOURS[i]
		if lit:
			draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, 13.0, Color(tint, _glow * 1.6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# A big scallop lying open: a fan with a hinge at the bottom.
		var fan := PackedVector2Array([Vector2(-8, 0), Vector2(-7, -5), Vector2(-4, -8), Vector2(0, -9), Vector2(4, -8), Vector2(7, -5), Vector2(8, 0), Vector2(3, 3), Vector2(-3, 3)])
		var inner := PackedVector2Array()
		for p: Vector2 in fan:
			inner.append(p * 0.8 + Vector2(0, -0.5))
		draw_colored_polygon(_moved(fan, c), Palette.OUTLINE)
		draw_colored_polygon(_moved(inner, c), SHELL.lerp(tint, 0.75))
		# The fan's ridges.
		for r in [-4, -1.5, 1.5, 4]:
			draw_line(c + Vector2(r * 0.4, 2), c + Vector2(r, -6), SHELL_SHADE)
		draw_rect(Rect2(c + Vector2(-2, 2), Vector2(4, 2)), SHELL_SHADE)


## The lit shell: a white flash in its own colour, lifted a little, and a
## ring round it, above everything.
func _draw_flash() -> void:
	if _lit < 0 or _glow <= 0.0 or not open():
		return
	var c := shell_at(_lit) + Vector2(0, 1)
	var tint: Color = COLOURS[_lit]
	var a := minf(_glow * 2.5, 1.0)
	_flash.draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
	_flash.draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 20, Color(tint, a), 2.0)
	_flash.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var fan := PackedVector2Array([Vector2(-8, 0), Vector2(-7, -5), Vector2(-4, -8), Vector2(0, -9), Vector2(4, -8), Vector2(7, -5), Vector2(8, 0), Vector2(3, 3), Vector2(-3, 3)])
	_flash.draw_colored_polygon(_moved(fan, c + Vector2(0, -2)), Color(Palette.OUTLINE, a))
	var inner := PackedVector2Array()
	for p: Vector2 in fan:
		inner.append(p * 0.8 + c + Vector2(0, -2.5))
	_flash.draw_colored_polygon(inner, Color(Color.WHITE.lerp(tint, 0.35), a))


static func _moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in points:
		out.append(p + by)
	return out
