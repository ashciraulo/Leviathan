class_name ChoirFigure
extends Node2D
## A member of the Choir in a story scene: Sister Lowe, or one of her
## hooded singers. Not an Npc: they only appear while a scene plays, then
## leave (see StoryDirector.lowe_at_the_hull).

## kind: sheet texture and frame count. Sheet columns: idle, breathe, then
## talk (Lowe, Murmur) or two prying frames (singers).
const KINDS := {
	"lowe": {"texture": Art.VILLAGER_LOWE, "frames": 3},
	"singer": {"texture": Art.VILLAGER_SINGER, "frames": 4},
	"murmur": {"texture": Art.VILLAGER_MURMUR, "frames": 3},
	"vael": {"texture": Art.VILLAGER_VAEL, "frames": 3},
	# Vael at the end, robe dropped, in the keepers' coat.
	"vael_keeper": {"texture": Art.VILLAGER_VAEL_KEEPER, "frames": 3},
	# Not of the Choir, but walks into scenes the same way.
	"dace": {"texture": Art.VILLAGER_DACE, "frames": 3},
	# Hessa, when she leaves the lighthouse: rowing Wren out to the Maw.
	"hessa": {"texture": Art.HESSA, "frames": 3},
	# Tobin, the Choir's newest singer, on his way out of it.
	"tobin": {"texture": Art.VILLAGER_TOBIN, "frames": 3},
	# Hessa and Vael when they were young, in the frozen journal's vision.
	"young_hessa": {"texture": Art.VILLAGER_YOUNG_HESSA, "frames": 3},
	"young_vael": {"texture": Art.VILLAGER_YOUNG_VAEL, "frames": 3},
}
const FRAME_IDLE := 0
const FRAME_BREATHE := 1
const FRAME_TALK := 2
const FRAME_PRY := [2, 3]
const BREATHE_TIME := 0.8
const PRY_TIME := 0.32

var kind := "singer"
## Singers lean on their bars under the Matriarch until they are told to run.
var prying := false
## Lowe throws out an arm while she gives orders; Murmur lifts the lantern.
var talking := false
## Seen in a vision: pale, cold and see-through.
var ghost := false
## How deep they are in water, in pixels from their feet: the rest of them
## is hidden below the surface, with rings where they meet it. 0 on land.
var sunk := 0.0
## In the water and fighting it: bobbing, arms up, splashing.
var struggling := false
## Rings on the water round them while sunk (off when sitting in a boat).
var ripples := true
## Fresh out of the water, still running with it.
var dripping := false
var _sprite: Sprite2D
var _shadow: Sprite2D
var _foot_y := 0.0
var _time := 0.0
var _left := false


func _init(figure_kind: String = "singer") -> void:
	kind = figure_kind


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shadow = Art.shadow()
	add_child(_shadow)
	_sprite = Art.sprite(KINDS[kind]["texture"], KINDS[kind]["frames"], 1, 22)
	_foot_y = _sprite.position.y
	# Under what this node draws itself: the water's surface, the drips.
	_shadow.show_behind_parent = true
	_sprite.show_behind_parent = true
	_sprite.flip_h = _left
	if ghost:
		_sprite.modulate = Color(0.72, 0.88, 1.0, 0.72)
		# A pale light on the ice beneath them.
		var halo := Node2D.new()
		halo.show_behind_parent = true
		halo.draw.connect(func() -> void:
			for ring in 3:
				halo.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
				halo.draw_circle(Vector2.ZERO, 14.0 - ring * 4.0, Color(0.8, 0.93, 1.0, 0.12 + ring * 0.08)))
		add_child(halo)
	add_child(_sprite)


func face(left: bool) -> void:
	_left = left
	if _sprite:
		_sprite.flip_h = left


func _process(delta: float) -> void:
	_time += delta
	_float()
	if struggling and kind != "singer":
		# Arms thrown up, then a gulp of air.
		_sprite.frame = FRAME_TALK if int(_time / 0.35) % 3 != 2 else FRAME_IDLE
	elif prying:
		_sprite.frame = FRAME_PRY[int(_time / PRY_TIME) % 2]
	elif talking and kind != "singer":
		_sprite.frame = FRAME_TALK
	else:
		_sprite.frame = FRAME_BREATHE if int(_time / BREATHE_TIME) % 2 == 1 else FRAME_IDLE


## Scramble to a gap in the deck and drop through it, out of sight.
func flee_into(hole: Vector2, seconds: float) -> void:
	prying = false
	talking = false
	face(hole.x < position.x)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "position", hole, Cutscene.scaled(seconds))
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), Cutscene.scaled(0.25))
	tween.parallel().tween_property(self, "modulate:a", 0.0, Cutscene.scaled(0.25))
	await tween.finished
	visible = false


## Run along a path of points and out of the room (through its door).
func flee_along(points: Array, seconds_per_leg: float) -> void:
	prying = false
	talking = false
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var from := position
	for point: Vector2 in points:
		if absf(point.x - from.x) > 1.0:
			tween.tween_callback(face.bind(point.x < from.x))
		from = point
		tween.tween_property(self, "position", point, Cutscene.scaled(seconds_per_leg))
	tween.tween_property(self, "modulate:a", 0.0, Cutscene.scaled(0.2))
	await tween.finished
	visible = false


## Walk along a path of points at an easy pace. fade: 1 fades in over the
## first leg (arriving through a door), -1 fades out over the last one.
func walk_along(points: Array, speed: float = 30.0, fade: int = 0) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if fade > 0:
		modulate.a = 0.0
		tween.tween_property(self, "modulate:a", 1.0, Cutscene.scaled(0.4))
	var from := position
	for point: Vector2 in points:
		if absf(point.x - from.x) > 1.0:
			tween.tween_callback(face.bind(point.x < from.x))
		tween.tween_property(self, "position", point, Cutscene.scaled(from.distance_to(point) / speed))
		from = point
	if fade < 0:
		tween.tween_property(self, "modulate:a", 0.0, Cutscene.scaled(0.4))
	await tween.finished


## Hide what's under the surface, and draw the surface round them.
func _float() -> void:
	var depth := sunk
	if struggling:
		depth += sin(_time * 7.0) * 2.5
	var hidden := clampi(int(round(depth)), 0, _sprite.texture.get_height() - 4)
	_sprite.region_enabled = hidden > 0
	if hidden > 0:
		_sprite.region_rect = Rect2(0, 0, _sprite.texture.get_width(), _sprite.texture.get_height() - hidden)
	_sprite.position.y = _foot_y + hidden
	_shadow.visible = hidden == 0
	if not ghost:
		# Soaked dark while the water runs off them.
		_sprite.modulate = Color(0.78, 0.84, 0.95) if dripping else Color.WHITE
	queue_redraw()


func _draw() -> void:
	if dripping and sunk <= 0.0:
		for i in 5:
			var t := fmod(_time * 1.3 + i * 0.37, 1.0)
			var x := -6.0 + fmod(i * 7.3, 12.0)
			draw_rect(Rect2(x, -16.0 + t * 15.0, 1, 2), Color(0.75, 0.9, 1.0, 0.8 * (1.0 - t)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 7.0, Color(0.4, 0.55, 0.7, 0.35))
		return
	if sunk <= 0.0 or not ripples:
		return
	# Rings spreading out where they break the surface.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	for ring in 3:
		var grow := fmod(_time * (1.6 if struggling else 0.7) + ring / 3.0, 1.0)
		draw_arc(Vector2.ZERO, 6.0 + grow * 12.0, 0.0, TAU, 18, Color(0.85, 0.95, 1.0, 0.75 * (1.0 - grow)), 1.5)
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 14, Color(0.9, 0.97, 1.0, 0.8), 1.0)
	if struggling:
		# Spray thrown up by the flailing.
		for i in 4:
			var t := fmod(_time * 1.7 + i * 0.25, 1.0)
			var x := (-8.0 + i * 5.3) * (0.6 + t * 0.6)
			var y := -t * 24.0 + t * t * 20.0
			draw_circle(Vector2(x, y / 0.4), 1.2, Color(0.9, 0.97, 1.0, 0.85 * (1.0 - t)))
