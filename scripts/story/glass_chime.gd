class_name GlassChime
extends StaticBody2D
## Coralie's wind chime on Saltmarrow Shore (StoryDirector): a driftwood
## frame with twelve strings. Each piece of sea-glass Wren hands her
## (Conversations.GLASS_TRADE) is hung on the next string, and they all
## sway and catch the light in the wind. Once she's shown Wren her echo
## game, striking it starts a round (EchoGame).

## Sun-bleached driftwood.
const WOOD := Color("#a8906c")
const WOOD_LIGHT := Color("#dccaa4")
const WOOD_DARK := Color("#7a6248")
const STRING := Color(0.16, 0.12, 0.2, 0.55)
## Sea-glass colours, string by string.
const GLASS := [
	Color("#86ccb4"), Color("#b4fff0"), Color("#6ea86a"), Color("#e8b85a"),
	Color("#62b4de"), Color("#e6eef6"), Color("#86ccb4"), Color("#4a7ac0"),
	Color("#b4fff0"), Color("#9fd36b"), Color("#e6eef6"), Color("#62b4de"),
]
const STRINGS := 12
const SPAN := 26.0
const BAR_Y := -30.0

var _time := 0.0
## Pieces hung, as last drawn: a new one glints as it goes up.
var _hung := 0
var _fresh := 0.0
## Coralie's echo game: striking the chime starts a round once she's asked.
var echo: EchoGame


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(30, 4), Vector2(0, -2)))
	add_child(Art.shadow())
	_hung = hung()
	add_to_group("interactable")


func interact() -> void:
	if echo and EchoGame.open():
		Audio.play_sfx("glass_chime", global_position, 1.0)
		echo.start()


## How many pieces Coralie has hung.
static func hung() -> int:
	return mini(Conversations.tally(Conversations.GLASS_TRADE), STRINGS)


func _process(delta: float) -> void:
	_time += delta
	_fresh = maxf(_fresh - delta, 0.0)
	var now := hung()
	if now != _hung:
		if now > _hung:
			_fresh = 1.2
			Audio.play_sfx("glass_chime", global_position, 1.0 + now * 0.04)
		_hung = now
	queue_redraw()


func _draw() -> void:
	# Two driftwood posts and the bar across them.
	for x in [-SPAN * 0.5 - 2.0, SPAN * 0.5]:
		draw_rect(Rect2(x - 1, BAR_Y - 1, 4, -BAR_Y + 1), Palette.OUTLINE)
		draw_rect(Rect2(x, BAR_Y, 2, -BAR_Y), WOOD)
		draw_rect(Rect2(x, BAR_Y, 1, -BAR_Y), WOOD_LIGHT)
	draw_rect(Rect2(-SPAN * 0.5 - 4, BAR_Y - 3, SPAN + 8, 4), Palette.OUTLINE)
	draw_rect(Rect2(-SPAN * 0.5 - 3, BAR_Y - 2, SPAN + 6, 2), WOOD)
	draw_rect(Rect2(-SPAN * 0.5 - 3, BAR_Y - 2, SPAN + 6, 1), WOOD_LIGHT)
	# Knots in the wood, and a stub of branch left on the bar.
	for knot in [Vector2(-SPAN * 0.5 - 1, -12), Vector2(SPAN * 0.5 + 1, -20), Vector2(4, BAR_Y - 1)]:
		draw_rect(Rect2(knot, Vector2(1, 1)), WOOD_DARK)
	draw_rect(Rect2(SPAN * 0.5 + 4, BAR_Y - 5, 3, 2), Palette.OUTLINE)
	draw_rect(Rect2(SPAN * 0.5 + 4, BAR_Y - 4, 2, 1), WOOD)
	for i in STRINGS:
		var x := -SPAN * 0.5 + 2.0 + i * 2.0
		var length := 6.0 + float((i * 5) % 7)
		var sway := roundf(sin(_time * 1.8 + i * 0.7) * 1.2)
		var end := Vector2(x + sway, BAR_Y + length)
		# The string swings with its glass, hanging straight from the bar.
		draw_rect(Rect2(x, BAR_Y, 1, 2), STRING)
		draw_rect(Rect2(end.x, BAR_Y + 2, 1, length - 2), STRING)
		if i >= _hung:
			continue
		var glass: Color = GLASS[i]
		draw_rect(Rect2(end + Vector2(-1, 0), Vector2(2, 3)), glass.darkened(0.45))
		draw_rect(Rect2(end + Vector2(-1, 0), Vector2(1, 2)), glass)
		# A glint now and then, and on the piece just hung.
		var glint := sin(_time * 2.3 + i * 2.1) > 0.97 or (i == _hung - 1 and _fresh > 0.0 and fmod(_fresh, 0.3) > 0.15)
		if glint:
			draw_rect(Rect2(end + Vector2(-1, -1), Vector2(1, 1)), Color(1, 1, 0.94))
			draw_rect(Rect2(end + Vector2(1, 1), Vector2(1, 1)), Color(1, 1, 0.94, 0.7))
