extends Control
## The credits: Mantle flying over the night sea while the names roll up.
## Any button speeds them up; Cancel (or the end) goes back to the title.

const TITLE_SCENE := "res://scenes/title.tscn"
const SPEED := 14.0
const FAST := 4.0
## The most the roll speeds up to end with a short credits track.
const MAX_SPEED_UP := 2.0
const LINE := 14.0
const GAP := 26.0
const FRAME_SIZE := Vector2(96, 80)
const NIGHT := Color(0.32, 0.36, 0.62)
## Section heading (translated), then names (shown as written).
const SECTIONS := [
	["CREDITS_DIRECTION", "Ash"],
	["CREDITS_MAKING", "Claude"],
	["CREDITS_MUSIC", "Ash", "Claude"],
	["CREDITS_FONT", "CREDITS_FONT_NAME"],
	["CREDITS_ENGINE", "Godot Engine", "CREDITS_GODOT_LICENSE"],
	["CREDITS_THANKS", "CREDITS_THANKS_NAME"],
]

var _time := 0.0
var _scroll := 0.0
var _leaving := false
var _height := 0.0
## Pixels a second: SPEED, or quicker if the music is shorter than the roll.
var _speed := SPEED
## The button that chose Credits may still be held: it only speeds the
## roll up once it has been let go.
var _fast_armed := false
## Once the game's been finished, the epilogue's little scenes come between
## the names (CreditsVignettes). Not before: they'd give the ending away.
var _vignettes := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Audio.play_music("credits")
	Audio.play_ambience("")
	_vignettes = GameState.has_flag("seen_ending")
	_height = 216.0 + Art.TITLE_LOGO.get_height() + GAP
	for section: Array in SECTIONS:
		_height += LINE * section.size() + GAP
	_height += _vignette_count() * (CreditsVignettes.SIZE.y + CreditsVignettes.GAP)
	_height += 60.0
	# The credits music plays once: the roll never outlasts it.
	var music: AudioStream = Audio._load(Audio.MUSIC_DIR, "credits")
	if music and music.get_length() > 0.0:
		_speed = clampf(_height / music.get_length(), SPEED, SPEED * MAX_SPEED_UP)


func _process(delta: float) -> void:
	_time += delta
	var fast := Input.is_action_pressed("interact") or Input.is_action_pressed("ui_accept")
	if not fast:
		_fast_armed = true
	fast = fast and _fast_armed
	_scroll += delta * _speed * (FAST if fast else 1.0)
	if _scroll >= _height and not _leaving:
		_leave()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if MenuKit.cancel(event) or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		Audio.play_sfx("ui_back")
		_leave()


## How many epilogue scenes this roll shows: one after each section but
## the last, while there are scenes left.
func _vignette_count() -> int:
	if not _vignettes:
		return 0
	return mini(CreditsVignettes.KINDS.size(), SECTIONS.size() - 1)


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)


func _draw() -> void:
	# Night over the sea: the day sky darkened, the sea scrolling below.
	draw_texture(Art.FLIGHT_SKY, Vector2.ZERO, NIGHT)
	var w := float(Art.FLIGHT_SEA.get_width())
	var x := roundf(-fmod(_time * 10.0, w))
	draw_texture(Art.FLIGHT_SEA, Vector2(x, 152), NIGHT)
	draw_texture(Art.FLIGHT_SEA, Vector2(x + w, 152), NIGHT)
	# Mantle glides across now and then.
	var lap := fmod(_time, 24.0)
	var mx := -100.0 + lap * 22.0
	if mx < 400.0:
		var frame := int(_time * 5.0) % 4
		draw_texture_rect_region(Art.MANTLE, Rect2(roundf(mx), roundf(110 + sin(_time) * 4.0), FRAME_SIZE.x, FRAME_SIZE.y),
			Rect2(Vector2(frame * FRAME_SIZE.x, 0), FRAME_SIZE), Color(0.7, 0.72, 0.95))
	# The roll.
	var y := roundf(216.0 - _scroll)
	draw_texture(Art.TITLE_LOGO, Vector2(roundf((384 - Art.TITLE_LOGO.get_width()) / 2.0), y))
	y += Art.TITLE_LOGO.get_height() + GAP
	for s in SECTIONS.size():
		var section: Array = SECTIONS[s]
		for i in section.size():
			var color := MenuKit.TEXT_DIM if i == 0 else MenuKit.TEXT
			if y > -LINE and y < 216.0:
				MenuKit.draw_text(self, section[i], Vector2(0, y), color, HORIZONTAL_ALIGNMENT_CENTER, 384)
			y += LINE
		y += GAP
		if s < _vignette_count():
			var size := CreditsVignettes.SIZE
			if y > -size.y - 4.0 and y < 220.0:
				CreditsVignettes.draw(self, CreditsVignettes.KINDS[s], Vector2(roundf((384 - size.x) / 2.0), y - 6.0), _time)
			y += size.y + CreditsVignettes.GAP
	y += 40.0
	if y > -LINE and y < 216.0:
		MenuKit.draw_text(self, "CREDITS_END", Vector2(0, y), MenuKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 384)
