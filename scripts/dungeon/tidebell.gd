class_name Tidebell
extends StaticBody2D
## One of the seven Tidebells. Ringing it teaches Wren a phrase of the
## lullaby: their Resonance meter grows, their breath fills, and the bell
## joins the satchel's count.

const RESONANCE_GAIN := 10.0
## The Point Bell's flag (kept for older saves and tests).
const BELL_FLAG := "tidebell_hull"
## Which bell, by the dungeon it hangs in: [sprite sheet, what it says].
const BELLS := {
	"hull": [HullSprites.TIDEBELL, ["BELL_HULL_1", "BELL_HULL_2", "BELL_HULL_3"]],
	"kiln": [KilnSprites.EMBER_BELL, ["BELL_KILN_1", "BELL_KILN_2", "BELL_KILN_3"]],
	"mire": [MireSprites.MOTH_BELL, ["BELL_MIRE_1", "BELL_MIRE_2", "BELL_MIRE_3"]],
	"gale": [GaleSprites.STORM_BELL, ["BELL_GALE_1", "BELL_GALE_2", "BELL_GALE_3"]],
	"glacier": [GlacierSprites.FROST_BELL, ["BELL_GLACIER_1", "BELL_GLACIER_2", "BELL_GLACIER_3"]],
	"belfry": [BelfrySprites.DROWNED_BELL, ["BELL_BELFRY_1", "BELL_BELFRY_2", "BELL_BELFRY_3"]],
}

## The dungeon this bell belongs to (a key of BELLS).
var bell := "hull"

## True when it should rise from the deck (right after the boss falls).
var rise := false
var _sprite: Sprite2D
var _rung := false
var _glow := 0.0


func _ready() -> void:
	add_to_group("interactable")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(22, 8), Vector2(0, -4)))
	add_child(Art.shadow(true))
	_sprite = Art.sprite(BELLS[bell][0], 2, 1, 37)
	add_child(_sprite)
	_rung = bool(GameState.flags.get(flag(), false))
	_sprite.frame = 1 if _rung else 0
	if rise:
		_sprite.position.y += 30
		_sprite.modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_sprite, "position:y", _sprite.position.y - 30, 1.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_sprite, "modulate:a", 1.0, 1.0)


static func flag_for(bell_id: String) -> String:
	return "tidebell_" + bell_id


func flag() -> String:
	return Tidebell.flag_for(bell)


func _process(delta: float) -> void:
	if _glow > 0.0:
		_glow = maxf(_glow - delta, 0.0)
		queue_redraw()


func interact() -> void:
	if _rung:
		Audio.play_sfx("bell_quiet", global_position)
		return
	_rung = true
	_sprite.frame = 1
	_glow = 2.0
	GameState.flags[flag()] = true
	GameState.give_item("tidebell", 1, false)
	GameState.resonance_max += RESONANCE_GAIN
	GameState.refill()
	GameState.add_resonance(GameState.resonance_max)
	Feel.shake(2.0)
	Audio.play_sfx("bell_ring", global_position)
	Audio.play_jingle("jingle_bell")
	Events.dialogue_requested.emit("", PackedStringArray(BELLS[bell][1]))


func _draw() -> void:
	if _glow <= 0.0:
		return
	# Rings of sound spreading from the bell.
	for i in 3:
		var r := fmod((2.0 - _glow) * 60.0 + i * 20.0, 60.0) + 8.0
		var color := Palette.HUM
		color.a = clampf(1.0 - r / 68.0, 0.0, 1.0) * minf(_glow, 1.0)
		draw_arc(Vector2(0, -20), r, 0.0, TAU, 40, color, 1.0)
