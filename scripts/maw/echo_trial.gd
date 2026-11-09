class_name EchoTrial
extends Node
## Boss echoes, after the end: once the Old One sleeps, eight echo stones
## rise round the Dreaming Heart. Step onto one and Wren is carried into a
## remembered fight with that boss, in that boss's own room, washed in
## dream-light. Calm it again and Wren is carried back to the Heart, and
## that stone burns brighter.
##
## While an echo fight is on, `boss_room` is the room it's in: the boss's
## spawn_in builds the boss instead of the aftermath, the aftermath (bell
## and way out) stays away, and a watcher in the room carries Wren back
## when the boss is calmed. Leaving the room any other way (or falling)
## ends it. Nothing here is saved but the cleared stones.

const HEART_ROOM := Vector2i(44, 6)
## Where Wren comes in to each boss room (all have the doorway at the
## bottom).
const ENTRY_TILE := Vector2i(11, 11)
## id: [boss room, flag set the first time it was beaten].
const BOSSES := {
	"hull": [Vector2i(10, 7), "boss_hull"],
	"kiln": [Vector2i(21, 7), "boss_kiln"],
	"mire": [Vector2i(25, 7), "boss_mire"],
	"gale": [Vector2i(28, 7), "boss_gale"],
	"glacier": [Vector2i(32, 7), "boss_glacier"],
	"belfry": [Vector2i(36, 7), "boss_belfry"],
	"tomb": [Vector2i(40, 7), "boss_tomb"],
	"vael": [Vector2i(44, 7), "boss_maw_vael"],
}
## The echoes are woken (the stones have risen once).
const WOKEN_FLAG := "echoes_woken"
## Seconds between the boss being calmed and Wren being carried back.
const RETURN_DELAY := 2.2
## The dream-light the remembered room is washed in.
const TINT := Color(0.6, 0.84, 0.98)

static var boss := ""
static var boss_room := Vector2i(-999, -999)
static var return_tile := Vector2i(11, 10)


static func cleared_flag(id: String) -> String:
	return "echo_" + id


## True while an echo fight is on in this room.
static func here(room: Room) -> bool:
	return room != null and boss != "" and room.coord == boss_room


## Carries Wren into the echo of a boss, to come back to return_at.
static func begin(id: String, return_at: Vector2i) -> void:
	boss = id
	boss_room = BOSSES[id][0]
	return_tile = return_at
	Events.door_entered.emit(boss_room, ENTRY_TILE)


static func end() -> void:
	boss = ""
	boss_room = Vector2i(-999, -999)


## Called by a boss's spawn_in when it builds the boss for an echo: washes
## the room in dream-light and leaves a watcher to carry Wren home.
static func dress(room: Room) -> void:
	var tint := CanvasModulate.new()
	tint.color = TINT
	room.add_child.call_deferred(tint)
	room.add_child.call_deferred(EchoTrial.new())


# --- The watcher, in the boss room during an echo. ---

var _id := ""
var _done := false


func _ready() -> void:
	_id = boss
	Events.boss_defeated.connect(_on_boss_defeated)
	Events.player_died.connect(_on_player_died)


func _exit_tree() -> void:
	# Leaving the room by any way ends the echo (a new one may already have
	# begun if this is the trip home: only end our own).
	if boss == _id and not _done:
		end()


func _on_player_died() -> void:
	end()


func _on_boss_defeated() -> void:
	if _done or boss != _id:
		return
	_done = true
	GameState.set_flag(cleared_flag(_id))
	Audio.play_sfx("echo_calm")
	await get_tree().create_timer(RETURN_DELAY, false).timeout
	if not is_inside_tree():
		return
	var back := return_tile
	end()
	Events.door_entered.emit(HEART_ROOM, back)
