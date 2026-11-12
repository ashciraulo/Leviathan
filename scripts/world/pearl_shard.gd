class_name PearlShard
extends Area2D
## A shard of a Breath Pearl lying out in the world (room letter 8). Twelve
## in all, in the open or in chests (chest_item "pearl_shard"); every four
## give Wren another breath bubble. Wren picks one up by walking over it,
## and the box says how many more make the next bubble. Each is saved as its
## own flag, so it never comes back.

const TOTAL := 12
const GLINT_EVERY := 2.2
const GLINT_TIME := 0.3
## Nacre: the Breath Pearl's ramp (tools/ui_art.py "P").
const LIGHT := Color("#F7E6F0")
const BASE := Color("#D8C0DC")
const SHADE := Color("#9E86A8")
const OUTLINE := Color("#4A3A58")
const SPARK := Color(1.0, 1.0, 1.0)

var room_coord := Vector2i.ZERO
var tile := Vector2i.ZERO
var _time := 0.0
var _taken := false
var _spark: Node2D
## Where it lies; it bobs a pixel above and below.
var _rest_y := 0.0


func _ready() -> void:
	if GameState.has_flag(flag_key()):
		queue_free()
		return
	add_to_group("pickups")
	Layers.assign(self, 0, [Layers.PLAYER])
	monitorable = false
	add_child(Layers.rect_shape(Vector2(10, 8), Vector2(0, -3)))
	body_entered.connect(_on_body_entered)
	add_child(Art.shadow())
	_spark = Node2D.new()
	_spark.z_index = 30
	_spark.draw.connect(_draw_spark)
	add_child(_spark)
	_rest_y = position.y
	_time = fmod(float(absi(room_coord.x * 11 + room_coord.y * 5 + tile.x)), GLINT_EVERY)


func flag_key() -> String:
	return "pearl_shard_%d_%d_%d_%d" % [room_coord.x, room_coord.y, tile.x, tile.y]


## What the box says on finding a shard, `found` being how many Wren now has.
static func talk(found: int) -> PackedStringArray:
	var lines := PackedStringArray()
	if found == 1:
		lines.append("GOT_PEARL_SHARD_FIRST")
	var toward := found % Items.SHARDS_PER_BUBBLE
	if toward == 0:
		lines.append("GOT_PEARL_SHARD_WHOLE")
		if found >= TOTAL:
			lines.append("GOT_PEARL_SHARD_LAST")
	else:
		lines.append(TranslationServer.translate("GOT_PEARL_SHARD_COUNT") % [toward, Items.SHARDS_PER_BUBBLE])
	return lines


func _process(delta: float) -> void:
	_time += delta
	# A slow bob, so it reads as something to pick up.
	position.y = _rest_y + roundf(sin(_time * 2.4))
	_spark.queue_redraw()


func _draw() -> void:
	# A wedge of pearl, broken off: round on top, a jagged break below.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -3), Vector2(-3, -6), Vector2(0, -8), Vector2(3, -7), Vector2(5, -4),
		Vector2(4, -1), Vector2(2, -2), Vector2(0, 0), Vector2(-2, -2),
	]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -3), Vector2(-2, -6), Vector2(0, -7), Vector2(3, -6), Vector2(4, -4),
		Vector2(3, -2), Vector2(2, -3), Vector2(0, -1), Vector2(-2, -3),
	]), BASE)
	draw_rect(Rect2(1, -4, 2, 2), SHADE)
	draw_rect(Rect2(-2, -6, 2, 2), LIGHT)
	draw_rect(Rect2(-2, -6, 1, 1), SPARK)


func _draw_spark() -> void:
	var t := fmod(_time, GLINT_EVERY)
	if t < GLINT_TIME:
		var s := roundf(sin(t / GLINT_TIME * PI) * 3.0)
		var at := Vector2(-1, -6)
		_spark.draw_rect(Rect2(at.x - s, at.y, s * 2 + 1, 1), SPARK)
		_spark.draw_rect(Rect2(at.x, at.y - s, 1, s * 2 + 1), SPARK)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	GameState.set_flag(flag_key())
	GameState.give_item("pearl_shard")
	var found := GameState.item_count("pearl_shard")
	Audio.play_sfx("pickup", global_position, 1.0 + found * 0.04)
	if found % Items.SHARDS_PER_BUBBLE == 0:
		Audio.play_jingle("jingle_pearl")
	Events.dialogue_requested.emit("", talk(found))
	queue_free()
