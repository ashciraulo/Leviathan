class_name RoomPuzzle
extends Node
## Opens a room's bars (|) when its gate is solved, and shows a hidden chest.
## Gates (Room.gate):
##   "plates"  every pressure plate held down at once
##   "clear"   every enemy beaten. The bars stand open until Wren is well
##             inside, then slam shut behind them.
##   "braziers" every brazier (j) lit with the Glowmoth Lantern
##   "eyes"    every ice eye (E) open at once (frost arrows open them)
## A solved gate stays solved (saved as a flag).

var _room: Room
var solved := false
var _shut_in := false


static func flag_for(coord: Vector2i) -> String:
	return "gate_%d_%d" % [coord.x, coord.y]


func _ready() -> void:
	_room = get_parent() as Room
	solved = bool(GameState.flags.get(flag_for(_room.coord), false))
	if solved:
		for bars in _bars():
			bars.open(true)
		for brazier in _braziers():
			brazier.light(true)
		for eye in _eyes():
			eye.hold_open()
		return
	if _room.chest_hidden:
		for chest in _chests():
			if not chest.opened:
				_hide(chest)
	if _room.gate == "clear":
		for bars in _bars():
			bars.open(true)
	for plate in _room.get_children():
		if plate is PressurePlate:
			plate.changed.connect(_check_plates)
	for brazier in _braziers():
		brazier.changed.connect(_check_braziers)
	for eye in _eyes():
		eye.changed.connect(_check_eyes)


func _physics_process(_delta: float) -> void:
	if solved or _room.gate != "clear":
		return
	if not _shut_in:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return
		var local := player.global_position - _room.global_position
		if Rect2(Vector2(2.5, 2.5) * Room.TILE, Room.SIZE - Vector2(5, 5) * Room.TILE).has_point(local):
			_shut_in = true
			for bars in _bars():
				bars.close()
			Feel.shake(2.0)
		return
	for child in _room.get_children():
		if child is Enemy and not (child as Enemy).dying:
			return
	solve()


func _check_plates() -> void:
	if solved or _room.gate != "plates":
		return
	for plate in _room.get_children():
		if plate is PressurePlate and not plate.pressed:
			return
	solve()


func _check_braziers() -> void:
	if solved or _room.gate != "braziers":
		return
	for brazier in _braziers():
		if not brazier.lit:
			return
	solve()


func _check_eyes() -> void:
	if solved or _room.gate != "eyes":
		return
	for eye in _eyes():
		if not eye.lit:
			return
	for eye in _eyes():
		eye.hold_open()
	solve()


func _eyes() -> Array:
	return _room.get_children().filter(func(n: Node) -> bool: return n is IceEye)


func _braziers() -> Array:
	return _room.get_children().filter(func(n: Node) -> bool: return n is Brazier)


func solve() -> void:
	if solved:
		return
	solved = true
	GameState.flags[flag_for(_room.coord)] = true
	for bars in _bars():
		bars.open()
	for chest in _chests():
		if not chest.visible:
			_reveal(chest)
	# The jingle (and the bars sliding, or the chest popping up) says it.
	Audio.play_jingle("jingle_puzzle")


func _bars() -> Array:
	return _room.get_children().filter(func(n: Node) -> bool: return n is Bars and not (n as Bars).fixed)


func _chests() -> Array:
	return _room.get_children().filter(func(n: Node) -> bool: return n is Chest)


func _hide(chest: Chest) -> void:
	chest.visible = false
	chest.remove_from_group("interactable")
	chest.collision_layer = 0


func _reveal(chest: Chest) -> void:
	chest.visible = true
	chest.add_to_group("interactable")
	chest.collision_layer = 1 << (Layers.WORLD - 1)
	chest.scale = Vector2(0.2, 0.2)
	var tween := chest.create_tween()
	tween.tween_property(chest, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
