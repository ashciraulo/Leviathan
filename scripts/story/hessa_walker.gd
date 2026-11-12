class_name HessaWalker
extends Node2D
## Hessa on her walk out to Lullaby Point (StoryDirector.hessas_walk). She
## can't hear Wren, so she follows the lamp: while Wren is in sight she
## picks her way after them over open ground, a little slower than they
## walk. Out of sight (too far, or somewhere she can't follow, like deep
## water) she stops and holds up her own lamp, "I'm here", until Wren comes
## back for her. No collision: she never blocks Wren in a doorway.

## How far she can see Wren's lamp, and how close she keeps.
const SIGHT := 120.0
const GAP := 20.0
## Close enough at an edge to cross into the next room with Wren.
const CARRY := 56.0
const SPEED := 52.0
## How often she looks for a new way after Wren.
const REPATH := 0.25
## Her lamp, held up while she waits.
const CALL_EVERY := 2.6
const STEP_TIME := 0.22

var room: Room
## True while Wren is in sight; the director reads it at each crossing.
var near := true
## False while held (a scene is on, or the box is open).
var waiting := false
var _sprite: Sprite2D
var _path: Array = []
var _repath := 0.0
var _call := 0.0
var _time := 0.0


func _ready() -> void:
	add_child(Art.shadow())
	_sprite = Art.sprite(Art.HESSA, 3, 1, 22)
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	var wren := get_tree().get_first_node_in_group("player") as Node2D
	if wren == null or room == null:
		return
	var distance := wren.global_position.distance_to(global_position)
	near = distance < CARRY
	_sprite.flip_h = wren.global_position.x < global_position.x - 4.0
	if Cutscene.active or DialogueBox.is_open:
		_stand()
		return
	_repath -= delta
	if _repath <= 0.0:
		_repath = REPATH
		_path = _route_to(wren) if distance <= SIGHT else []
	waiting = _path.is_empty() and distance > GAP
	if waiting:
		_stand()
		_call -= delta
		if _call <= 0.0:
			_call = CALL_EVERY
			var glow := LampGlow.new(Cutscene.LAMP_HERE)
			glow.position = position + Vector2(0, -14)
			get_parent().add_child(glow)
		return
	_call = 0.8
	if distance <= GAP:
		_path.clear()
		_stand()
		return
	var target: Vector2 = _path[0]
	position = position.move_toward(target, SPEED * delta)
	if position.distance_to(target) < 1.0:
		_path.pop_front()
	# A shuffling step: her breathe frame and a small bob.
	var step := int(_time / STEP_TIME) % 2
	_sprite.frame = step
	_sprite.position.y = -23.0 - step


func _stand() -> void:
	_sprite.frame = Npc.FRAME_IDLE
	_sprite.position.y = -23.0


## Tile centres from her tile to Wren's over open ground, or [] when Wren
## stands somewhere she can't walk to.
func _route_to(wren: Node2D) -> Array:
	var from := Cutscene._tile_of(position)
	var to := Cutscene._tile_of(wren.global_position - room.global_position)
	if not open(room, to):
		return []
	var cells := Cutscene._route(room, from, to)
	if cells.is_empty():
		return []
	cells.pop_front()
	# Stop short of Wren's own tile; GAP does the rest.
	if not cells.is_empty():
		cells.pop_back()
	var points: Array = []
	for cell: Vector2i in cells:
		points.append(Vector2(cell) * Room.TILE + Vector2(Room.TILE / 2.0, 10))
	if points.is_empty():
		points.append(wren.global_position - room.global_position)
	return points


## Ground she'll walk on: the open floor scenes use, room edges included.
static func open(the_room: Room, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= Room.COLS or cell.y >= Room.ROWS:
		return false
	return Cutscene._open(the_room, cell)
