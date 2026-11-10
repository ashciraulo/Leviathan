class_name Prop
extends StaticBody2D
## A solid piece of scenery: one sprite plus a collision footprint at its base.
## Rooms place props by letter (see Room). Big props are anchored at the
## bottom-centre of their tile, and their art can rise over the tiles above.

## letter: [texture, foot row in the sprite, footprint size, large shadow,
## optional: animation frames across the sheet]
const KINDS := {
	"o": [Art.POT, 12, Vector2(12, 8), false],
	"u": [Art.BARREL, 11, Vector2(12, 8), false],
	"f": [Art.FENCE, 11, Vector2(16, 6), false],
	"n": [Art.SIGN, 11, Vector2(6, 6), false],
	"H": [Art.HUT, 44, Vector2(38, 20), true],
	"L": [Art.LIGHTHOUSE, 76, Vector2(22, 12), true],
	"M": [Art.MANGROVE, 60, Vector2(20, 10), true],
	"W": [Art.WRECK, 27, Vector2(40, 14), true],
	"l": [Art.LANTERN_POST, 29, Vector2(6, 4), false],
	"R": [Art.HULL, 69, Vector2(84, 18), true],
	"J": [Art.WINDMILL, 46, Vector2(14, 8), true, 4],
	"Z": [VergeSprites.COTTAGE, 44, Vector2(36, 14), true],
	"B": [VergeSprites.BELFRY, 76, Vector2(24, 14), true],
	"N": [VergeSprites.MAW_LIP, 53, Vector2.ZERO, false],
	"U": [OssuarySprites.RIB, 53, Vector2(10, 6), false],
	"F": [OssuarySprites.SKULL, 45, Vector2(56, 14), true],
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


func _init(letter: String = "o") -> void:
	kind = letter


func _ready() -> void:
	var spec: Array = KINDS[kind]
	var footprint: Vector2 = spec[2]
	Layers.assign(self, Layers.WORLD, [])
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
