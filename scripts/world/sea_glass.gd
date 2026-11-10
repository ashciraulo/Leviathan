class_name SeaGlass
extends Area2D
## A piece of sea-glass lying in some out-of-the-way corner of the
## overworld (room letter *). Twelve in all. Wren picks one up by walking
## over it; it glints now and then so a sharp eye can spot it from across
## the screen. Each is saved as its own flag, so it never comes back.

const TOTAL := 12
## Seconds between glints, and how long a glint lasts.
const GLINT_EVERY := 2.6
const GLINT_TIME := 0.35
## Frosted sea-glass: pale aqua body, light edge, darker underside.
const BODY := Color(0.55, 0.85, 0.8, 0.9)
const EDGE := Color(0.85, 1.0, 0.96)
const UNDER := Color(0.28, 0.55, 0.58, 0.9)
const SPARK := Color(1.0, 1.0, 0.94)

var room_coord := Vector2i.ZERO
var tile := Vector2i.ZERO
var _time := 0.0
var _taken := false
## The glint is drawn above scenery, so a piece tucked behind a tree or a
## hut still flashes through it now and then.
var _spark: Node2D


func _ready() -> void:
	if GameState.has_flag(flag_key()):
		queue_free()
		return
	Layers.assign(self, 0, [Layers.PLAYER])
	monitorable = false
	add_child(Layers.rect_shape(Vector2(10, 8), Vector2(0, -3)))
	body_entered.connect(_on_body_entered)
	_spark = Node2D.new()
	_spark.z_index = 30
	_spark.draw.connect(_draw_spark)
	add_child(_spark)
	# Glints out of step with each other, so two in view don't flash together.
	_time = fmod(float(absi(room_coord.x * 7 + room_coord.y * 13 + tile.x)), GLINT_EVERY)


## Pieces found so far: those Wren carries, and those already hung on
## Coralie's chime.
static func found() -> int:
	return GameState.item_count("sea_glass") + Conversations.tally(Conversations.GLASS_TRADE)


func flag_key() -> String:
	return "sea_glass_%d_%d" % [room_coord.x, room_coord.y]


func _process(delta: float) -> void:
	_time += delta
	_spark.queue_redraw()


func _draw() -> void:
	# A small rounded shard, lying flat.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -3), Vector2(1, -5), Vector2(4, -3), Vector2(3, -1), Vector2(-2, 0),
	]), UNDER)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -4), Vector2(1, -6), Vector2(4, -4), Vector2(2, -2), Vector2(-2, -2),
	]), BODY)
	draw_rect(Rect2(-1, -5, 2, 1), EDGE)


func _draw_spark() -> void:
	var t := fmod(_time, GLINT_EVERY)
	if t < GLINT_TIME:
		var s := roundf(sin(t / GLINT_TIME * PI) * 3.0)
		var at := Vector2(1, -5)
		_spark.draw_rect(Rect2(at.x - s, at.y, s * 2 + 1, 1), SPARK)
		_spark.draw_rect(Rect2(at.x, at.y - s, 1, s * 2 + 1), SPARK)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	GameState.set_flag(flag_key())
	GameState.give_item("sea_glass")
	var count := found()
	if count >= TOTAL:
		Audio.play_jingle("jingle_secret")
	else:
		# Each piece rings a little higher than the last.
		Audio.play_sfx("pickup", global_position, 1.0 + count * 0.05)
	queue_free()
