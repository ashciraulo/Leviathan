class_name FenLantern
extends StaticBody2D
## One of the Gloamfen families' lanterns for their dead, hung on a crooked
## pole so the dead can find their way. Five across the fen have gone dark;
## Wick, who counts them every night, asks Wren to light them again. Hold
## the raised Glowmoth Lantern close, like a brazier, and it catches and
## stays lit (flag fen_lantern_<x>_<y> for its room).

## Room -> the tile its lantern stands on.
const SPOTS := {
	Vector2i(3, 1): Vector2i(3, 3),
	Vector2i(3, 2): Vector2i(20, 6),
	Vector2i(3, 3): Vector2i(5, 9),
	Vector2i(5, 1): Vector2i(20, 4),
	Vector2i(6, 1): Vector2i(6, 3),
}
## Set once all five burn again.
const ALL_LIT_FLAG := "fen_lanterns_lit"
const REACH := 26.0
const WOOD := Color("#5a4636")
const WOOD_LIGHT := Color("#7a6048")
const GLASS_DARK := Color("#3a3a48")
const FLAME := Color("#ffe9a0")
const GLOW := Color("#f6c25a")

var room_coord := Vector2i.ZERO
var lit := false
## The Reed family's lantern at Fenmouth (Wick made it, Wren lit it): always
## burning, and no part of Wick's five or his round.
var reed := false
var _light: Glow
var _time := 0.0
var _catch := 0.0


static func flag_for(coord: Vector2i) -> String:
	return "fen_lantern_%d_%d" % [coord.x, coord.y]


static func lit_count() -> int:
	var count := 0
	for coord: Vector2i in SPOTS:
		if GameState.has_flag(flag_for(coord)):
			count += 1
	return count


func _ready() -> void:
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(6, 4), Vector2(0, -2)))
	add_child(Art.shadow())
	# A Glow the dark lets through only where the room is dark; in the
	# fen's dusk the glow is drawn (see _draw).
	var room := get_parent() as Room
	if room and room.dark:
		_light = Glow.make(48.0, GLOW, 0.9)
		_light.position = Vector2(4, -20)
		add_child(_light)
	add_to_group("fen_lanterns")
	_sync()


## Lit as kept (its flag), or as lit this round while Wick's round is on.
func _sync() -> void:
	if reed:
		lit = true
		_show()
		return
	lit = LamplighterRound.lit.has(room_coord) if LamplighterRound.running else GameState.has_flag(flag_for(room_coord))
	_show()


## Every lantern in the room: a round has begun or ended.
static func refresh_all(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("fen_lanterns"):
		(node as FenLantern)._sync()


func _physics_process(_delta: float) -> void:
	if lit:
		return
	var wren := Lantern.player(get_tree())
	if wren and wren.lantern_raised and wren.global_position.distance_to(global_position) <= REACH:
		light()


func light() -> void:
	if lit:
		return
	lit = true
	_catch = 0.6
	if LamplighterRound.running:
		Audio.play_sfx("brazier_catch", global_position, 1.3)
		_show()
		LamplighterRound.lantern_lit(room_coord)
		return
	GameState.set_flag(flag_for(room_coord))
	Audio.play_sfx("brazier_catch", global_position, 1.3)
	if lit_count() >= SPOTS.size():
		GameState.set_flag(ALL_LIT_FLAG)
		# The last of them: every family's light burns again.
		Audio.play_jingle("jingle_secret")
	_show()


func _show() -> void:
	if _light == null:
		return
	# Dark, only an ember of a wick shows, so it can be found at night.
	_light.radius = 48.0 if lit else 10.0
	_light.energy = 0.9 if lit else 0.35


func _process(delta: float) -> void:
	_time += delta
	_catch = maxf(_catch - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	# A crooked pole with a crook at the top, the lantern hung from it.
	draw_rect(Rect2(-2, -26, 3, 26), Palette.OUTLINE)
	draw_rect(Rect2(-1, -25, 1, 25), WOOD_LIGHT)
	draw_rect(Rect2(-2, -27, 8, 3), Palette.OUTLINE)
	draw_rect(Rect2(-1, -26, 6, 1), WOOD)
	draw_line(Vector2(4, -24), Vector2(4, -23), Palette.OUTLINE, 1.0)
	var sway := sin(_time * 1.4) * 0.6
	var top := Vector2(4 + sway, -23)
	if lit and _light == null:
		var breathe := 0.85 + 0.15 * sin(_time * 2.0)
		for i in 3:
			draw_circle(top + Vector2(0.5, 4), (16.0 - i * 5.0) * breathe, Color(GLOW, 0.07 + i * 0.05))
	draw_rect(Rect2(top + Vector2(-3, 0), Vector2(7, 9)), Palette.OUTLINE)
	draw_rect(Rect2(top + Vector2(-2, 1), Vector2(5, 7)), GLOW if lit else GLASS_DARK)
	if lit:
		var flicker := 0.5 + 0.5 * sin(_time * 9.0)
		draw_rect(Rect2(top + Vector2(-1, 3), Vector2(3, 4)), FLAME.lerp(GLOW, flicker * 0.4))
	else:
		draw_rect(Rect2(top + Vector2(0, 6), Vector2(1, 1)), Color(0.9, 0.5, 0.3, 0.6))
	draw_rect(Rect2(top + Vector2(-3, -1), Vector2(7, 1)), Palette.OUTLINE)
	if _catch > 0.0:
		draw_circle(top + Vector2(0.5, 4), 4.0 + (0.6 - _catch) * 18.0, Color(1, 0.9, 0.6, _catch * 0.5))
