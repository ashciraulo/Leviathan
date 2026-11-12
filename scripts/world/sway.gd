class_name Sway
extends Node2D
## Tufts of grass, ferns and reeds on the overworld leaning in the wind.
## Room hands them over instead of baking them into the ground; each is
## drawn sheared from its foot, so its top moves a pixel or two while its
## root stays put. The wind runs across the screen in slow waves, now and
## then a stronger gust, and leans more on the open heights than in the
## sheltered fens.

## Tile names (by their start) that sway.
const SWAYERS := ["grass_", "fern_", "frond_", "tussock_", "reeds_", "seapinks_", "scrub_"]
## How far the wind leans a whole tile's height (px), per region: a tuft
## half a tile tall leans half as far.
const LEAN := {
	"saltmarrow": 3.0, "brinewood": 2.2, "cinderreach": 1.4, "gloamfen": 1.6,
	"windmere": 4.4, "frostspine": 2.8, "sunken_verge": 2.6, "ossuary": 2.4,
}
## Redraws this often (s): the tufts move in whole pixels anyway.
const STEP := 1.0 / 15.0

var room: Room
## Tile -> tile name, filled in as the ground draws.
var tufts: Dictionary = {}
var _time := 0.0
var _since := 0.0


static func sways(tile_name: String) -> bool:
	for start: String in SWAYERS:
		if tile_name.begins_with(start):
			return true
	return false


func _process(delta: float) -> void:
	_time += delta
	_since += delta
	if _since >= STEP and not tufts.is_empty():
		_since = 0.0
		queue_redraw()


## How far the wind leans a tuft whose foot is at x (px) at this moment:
## a slow swell running across the screen, a quicker ripple on top, and
## always a little lean the way the wind blows.
static func lean_at(x: float, time: float, lean: float) -> float:
	var swell := sin(time * 1.3 - x * 0.03)
	var ripple := sin(time * 3.1 - x * 0.09 + 1.7) * 0.35
	var gust := maxf(sin(time * 0.37 - x * 0.006), 0.0) ** 3 * 0.8
	return lean * (0.3 + swell * 0.45 + ripple * 0.25 + gust)


func _draw() -> void:
	var lean: float = LEAN.get(room.biome if room else "", 1.0)
	var t := float(Room.TILE)
	for tile: Vector2i in tufts:
		var foot := Vector2(tile.x * t, (tile.y + 1) * t)
		var top := roundf(lean_at(foot.x + t / 2.0, _time, lean))
		# Shear about the foot: y up the tile shifts x by top * (height / t).
		draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(-top / t, 1), foot))
		draw_texture_rect_region(Art.WORLD_TILES, Rect2(0, -t, t, t), TileAtlas.region(tufts[tile]))
	draw_set_transform_matrix(Transform2D.IDENTITY)
