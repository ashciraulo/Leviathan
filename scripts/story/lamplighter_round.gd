class_name LamplighterRound
extends CanvasLayer
## Wick's lamplighter's round: ring the dusk bell at Fenmouth and the fen's
## five family lanterns (FenLantern.SPOTS) go out for the round; light them
## all again as fast as Wren can. A clock in the top corner counts it. The
## lanterns' own flags are never touched: out of the round they burn as
## they did. Leaving the fen, falling or flying off ends it.

const ASK_FLAG := "wick_round_ask"
## The best round, in whole seconds (lower is better; 0 = none yet).
const BEST_FLAG := "wick_round_best"
## Times to beat (seconds): good, Wick's own, and Wick's gran's.
const TIERS := [240, 180, 135]
## Rooms the round may cross: Fenmouth and the lanterns' rooms.
const FENMOUTH := Vector2i(4, 1)
## Long past any real round: it's off.
const GIVE_UP := 600.0
## The clock lingers on the finished time.
const SHOW_DONE := 3.0

## True while a round is on; the lanterns light for the round, not for keeps.
static var running := false
## Lanterns lit this round (room coord -> true).
static var lit := {}
## The round in progress, if any.
static var current: LamplighterRound

var elapsed := 0.0
var _label: Label
var _done := -1.0


static func best() -> int:
	return int(GameState.flags.get(BEST_FLAG, 0))


static func tier_flag(seconds: int) -> String:
	return "wick_round_%d" % seconds


## "2:05" for 125 seconds.
static func clock(seconds: float) -> String:
	var whole := int(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


## Starts a round: every fen lantern in sight goes out for it.
static func begin(parent: Node) -> LamplighterRound:
	if current and is_instance_valid(current):
		current.queue_free()
	running = true
	lit = {}
	current = LamplighterRound.new()
	parent.add_child(current)
	FenLantern.refresh_all(parent.get_tree())
	return current


## A lantern caught during the round.
static func lantern_lit(coord: Vector2i) -> void:
	if not running:
		return
	lit[coord] = true
	if current and is_instance_valid(current) and lit.size() >= FenLantern.SPOTS.size():
		current.finish()


func _ready() -> void:
	layer = 6
	_label = UI.label("")
	# A time, not a text key.
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	# Top middle, clear of the breath plate and the item slots.
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.offset_left = -24
	_label.offset_right = 24
	_label.offset_top = 4
	_label.offset_bottom = 16
	add_child(_label)
	Events.room_entered.connect(_on_room_entered)
	Events.player_died.connect(func() -> void: stop("TOAST_ROUND_OFF"))
	Events.fast_travel_requested.connect(func(_coord: Vector2i) -> void: stop("TOAST_ROUND_OFF"))
	_show()


func _process(delta: float) -> void:
	if _done >= 0.0:
		_done -= delta
		if _done < 0.0:
			queue_free()
		return
	if not DialogueBox.is_open and not Cutscene.active:
		elapsed += delta
	if elapsed > GIVE_UP:
		stop("TOAST_ROUND_OFF")
		return
	_show()


func _show() -> void:
	_label.text = clock(elapsed)


func _on_room_entered(coord: Vector2i) -> void:
	if running and coord != FENMOUTH and not FenLantern.SPOTS.has(coord):
		stop("TOAST_ROUND_OFF")


## All five burning: the time stands, and any time beaten is marked.
func finish() -> void:
	var seconds := int(ceilf(elapsed))
	running = false
	if best() == 0 or seconds < best():
		GameState.set_flag(BEST_FLAG, seconds)
	var beaten := ""
	for tier: int in TIERS:
		if seconds <= tier:
			beaten = "TOAST_ROUND_%d" % tier
			if not GameState.has_flag(tier_flag(tier)):
				GameState.set_flag(tier_flag(tier))
	Audio.play_jingle("jingle_secret")
	_label.text = clock(seconds)
	_done = SHOW_DONE
	FenLantern.refresh_all(get_tree())
	Events.toast.emit(beaten if beaten != "" else "TOAST_ROUND_DONE")


## Called off: the lanterns burn as before.
func stop(toast_key: String = "") -> void:
	if not running:
		return
	running = false
	lit = {}
	FenLantern.refresh_all(get_tree())
	if toast_key != "":
		Events.toast.emit(toast_key)
	queue_free()


func _exit_tree() -> void:
	if current == self:
		current = null
		if running:
			running = false
			lit = {}
