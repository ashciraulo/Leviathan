class_name Prop
extends StaticBody2D
## A solid piece of scenery: one sprite plus a collision footprint at its base.
## Rooms place props by letter (see Room). Big props are anchored at the
## bottom-centre of their tile, and their art can rise over the tiles above.

## Where the whale skull and jaw meet the sand (from tools/whale_bones_art.py
## footprint(); redo these if the art changes). The skull leaves a gap at
## its side hollow, 4 tiles right of its letter, where the Tomb's door is.
const SKULL_FOOTPRINT := [
	Rect2(38, -63, 54, 6), Rect2(28, -57, 73, 6), Rect2(25, -51, 84, 6),
	Rect2(9, -45, 104, 6), Rect2(-3, -39, 118, 6), Rect2(-13, -33, 129, 6),
	Rect2(-25, -27, 141, 6), Rect2(-37, -21, 151, 6),
	Rect2(-47, -15, 102, 6), Rect2(73, -15, 37, 6),
	Rect2(-59, -9, 114, 6), Rect2(73, -9, 31, 6),
	Rect2(-72, -3, 127, 6), Rect2(73, -3, 18, 6),
	Rect2(-82, 3, 137, 6), Rect2(-93, 9, 112, 6), Rect2(-99, 15, 44, 6),
]
const SMALL_SKULL_FOOTPRINT := [
	Rect2(-37, -29, 26, 4),
	Rect2(-42, -25, 36, 4),
	Rect2(-45, -21, 50, 4),
	Rect2(-46, -17, 58, 4),
	Rect2(-45, -13, 65, 4),
	Rect2(-44, -9, 71, 4),
	Rect2(-39, -5, 73, 4),
	Rect2(-22, -1, 65, 4),
	Rect2(19, 3, 28, 4),
]
const JAW_FOOTPRINT := [
	Rect2(47, -29, 21, 6), Rect2(30, -23, 33, 6), Rect2(15, -17, 30, 6),
	Rect2(-22, -11, 76, 6), Rect2(-67, -5, 144, 6), Rect2(-77, 1, 41, 6),
]

## letter: [texture, foot row in the sprite, footprint size, large shadow,
## optional: animation frames across the sheet]. A footprint can also be a
## list of Rect2s around the base (for bones lying at a slant).
const KINDS := {
	"o": [Art.POT, 12, Vector2(12, 8), false],
	"u": [Art.BARREL, 11, Vector2(12, 8), false],
	"f": [Art.FENCE, 11, Vector2(16, 6), false],
	"n": [Art.SIGN, 11, Vector2(6, 6), false],
	"H": [Art.HUT, 44, Vector2(38, 20), true],
	"L": [Art.LIGHTHOUSE, 76, Vector2(22, 12), true],
	"M": [Art.MANGROVE, 60, Vector2(20, 10), true],
	"W": [Art.WRECK, 27, Vector2(40, 14), true],
	# Placed by StoryDirector, never by a room letter.
	"figurehead": [Art.FIGUREHEAD, 38, Vector2(12, 6), false],
	"calf_skull": [Art.CALF_SKULL, 42, Vector2(48, 10), true],
	"l": [Art.LANTERN_POST, 29, Vector2(6, 4), false],
	"R": [Art.HULL, 69, Vector2(84, 18), true],
	"J": [Art.WINDMILL, 46, Vector2(14, 8), true, 4],
	"Z": [VergeSprites.COTTAGE, 44, Vector2(36, 14), true],
	"B": [VergeSprites.BELFRY, 76, Vector2(24, 14), true],
	"N": [VergeSprites.MAW_LIP, 53, Vector2.ZERO, false],
	"U": [OssuarySprites.RIB, 53, Vector2(10, 6), false],
	"F": [OssuarySprites.SKULL, 102, SKULL_FOOTPRINT, false],
	"9": [OssuarySprites.JAW, 34, JAW_FOOTPRINT, false],
	"(": [OssuarySprites.SMALL_SKULL, 45, SMALL_SKULL_FOOTPRINT, false],
}

## Props a sword, a bomb or the Stonebreaker smashes (they come back when
## the room does), and the chance each leaves a glint.
const BREAKABLE := {"o": 0.5}

var kind := ""
var _sprite: Sprite2D
var _frames := 1
## Signposts: what this one says (a translation key). Empty = can't be read.
var text_key := ""


static func is_prop(letter: String) -> bool:
	return KINDS.has(letter)


## True for props wider than a tile (they hang over their neighbours).
static func is_wide(letter: String) -> bool:
	var footprint: Variant = KINDS[letter][2]
	return footprint is Array or (footprint as Vector2).x > Room.TILE


func _init(letter: String = "o") -> void:
	kind = letter


func _ready() -> void:
	var spec: Array = KINDS[kind]
	Layers.assign(self, Layers.WORLD, [])
	var footprint := Vector2.ZERO
	if spec[2] is Array:
		for rect: Rect2 in spec[2]:
			add_child(Layers.rect_shape(rect.size, rect.get_center()))
	else:
		footprint = spec[2]
	# A zero footprint is scenery Wren can walk into (the Maw's lip).
	if footprint != Vector2.ZERO:
		add_child(Layers.rect_shape(footprint, Vector2(0, -footprint.y / 2.0)))
	if spec[3]:
		var shade := Art.shadow(true)
		shade.scale = Vector2(footprint.x / 14.0, 1.5)
		add_child(shade)
	_frames = spec[4] if spec.size() > 4 else 1
	_sprite = Art.sprite(spec[0], _frames, 1, spec[1])
	add_child(_sprite)
	set_process(_frames > 1)
	if text_key != "":
		add_to_group("interactable")
	if kind in BREAKABLE:
		add_to_group("breakable")


## Animated props (windmill sails) turn slowly.
func _process(_delta: float) -> void:
	_sprite.frame = int(Time.get_ticks_msec() / 160) % _frames


## Reading a sign: narration, no speaker.
func interact() -> void:
	Events.conversation_requested.emit([{"name": "", "portrait": null, "text": text_key}])


## A sword blow. Only breakable props answer it.
func sword_hit(_direction: Vector2) -> bool:
	return smash()


## The Stonebreaker's slam.
func mallet_hit(_direction: Vector2) -> bool:
	return smash()


## A puffer bomb going off nearby.
func bomb_hit() -> bool:
	return smash()


## Breaks a pot: shards fly, now and then a glint is left. False for props
## that don't break.
func smash() -> bool:
	if not kind in BREAKABLE or not is_in_group("breakable"):
		return false
	remove_from_group("breakable")
	collision_layer = 0
	Audio.play_sfx("pot_break", global_position)
	var shards := Shards.new()
	shards.position = position + Vector2(0, -5)
	get_parent().add_child(shards)
	Glint.drop.call_deferred(get_parent(), position, Glint.roll(BREAKABLE[kind]))
	queue_free()
	return true


## Pieces of a broken pot, flung out and fading.
class Shards extends Node2D:
	const TIME := 0.45
	var _age := 0.0

	func _process(delta: float) -> void:
		_age += delta
		if _age >= TIME:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t := _age / TIME
		modulate.a = 1.0 - t
		for i in 6:
			var angle := TAU * i / 6.0 + 0.4
			var out := Vector2(cos(angle), sin(angle) * 0.7) * (3.0 + 12.0 * t)
			out.y += 18.0 * t * t - 6.0 * t
			draw_rect(Rect2(out - Vector2(1.5, 1.5), Vector2(3, 3)), Palette.OUTLINE)
			draw_rect(Rect2(out - Vector2(1, 1), Vector2(2, 2)), Color("#b5734a"))
