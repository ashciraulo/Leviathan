class_name Strongbox
extends StaticBody2D
## Gully's salvage strongbox, lost in Wreck Strand's pool when the tide
## turned on him (StoryDirector). Once he's asked, it bobs out there, too
## deep to wade to: catch it with the Tide Hook and it's hauled in to Wren's
## feet (flag gully_box_hauled).

const IRON := Color("#3c3a44")
const IRON_LIGHT := Color("#6c6a7a")
const WOOD := Color("#6b4a32")
const WOOD_LIGHT := Color("#8d6644")
const BARNACLE := Color("#d8d0bc")
const WEED := Color("#4e7a4a")
const FOAM := Color(0.85, 0.95, 1.0, 0.55)
## How fast it comes in when hauled, near the chain's reeling speed.
const HAUL_SPEED := 300.0

var _time := 0.0
var _hauling := false


func _ready() -> void:
	add_to_group("strongbox")
	_refresh()
	Events.flag_changed.connect(func(_flag: String, _value: Variant) -> void: _refresh())


## Out there only once Gully's told Wren about it, and until it's hauled.
func _refresh() -> void:
	if _hauling:
		return
	var there := GameState.has_flag("gully_asked") and not GameState.has_flag("gully_box_hauled")
	visible = there
	if there and get_child_count() == 0:
		Layers.assign(self, Layers.WORLD, [])
		add_child(Layers.rect_shape(Vector2(14, 14), Vector2(0, -6)))
	elif not there:
		collision_layer = 0


func hook_hit(direction: Vector2) -> bool:
	if _hauling or not visible:
		return false
	var wren := Lantern.player(get_tree())
	if wren == null:
		return false
	_hauling = true
	collision_layer = 0
	var to := wren.global_position + direction * 10.0
	var tween := create_tween()
	tween.tween_property(self, "global_position", to, global_position.distance_to(to) / HAUL_SPEED)
	tween.tween_callback(_landed)
	Audio.play_sfx("splash", global_position)
	return true


func _landed() -> void:
	GameState.set_flag("gully_box_hauled")
	Audio.play_sfx("splash", global_position, 0.8)
	Audio.play_jingle("jingle_secret")
	Events.conversation_requested.emit([{"name": "", "portrait": null, "text": "NARRATE_HAULED_STRONGBOX"}])
	queue_free()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := 0.0 if _hauling else roundf(sin(_time * 2.2) * 1.0)
	var at := Vector2(0, bob)
	# A barnacled, iron-banded box, sunk to its lid in the water.
	draw_rect(Rect2(at + Vector2(-7, -9), Vector2(14, 9)), Palette.OUTLINE)
	draw_rect(Rect2(at + Vector2(-6, -8), Vector2(12, 7)), WOOD)
	draw_rect(Rect2(at + Vector2(-6, -8), Vector2(12, 2)), WOOD_LIGHT)
	draw_rect(Rect2(at + Vector2(-6, -6), Vector2(12, 1)), Palette.OUTLINE)
	for x in [-4, 3]:
		draw_rect(Rect2(at + Vector2(x, -8), Vector2(1, 7)), IRON)
	draw_rect(Rect2(at + Vector2(-1, -6), Vector2(2, 2)), IRON_LIGHT)
	for spot in [Vector2(-6, -3), Vector2(-5, -2), Vector2(4, -8), Vector2(5, -3)]:
		draw_rect(Rect2(at + spot, Vector2(1, 1)), BARNACLE)
	draw_line(at + Vector2(-2, -1), at + Vector2(-3, 2), WEED, 1.0)
	if not _hauling:
		# The waterline over the bottom of it, and a ring of foam.
		draw_rect(Rect2(Vector2(-8, -2), Vector2(16, 3)), Color(0.12, 0.3, 0.42, 0.75))
		var spread := 1.0 + fmod(_time, 2.0)
		draw_arc(Vector2(0, -1), 7.0 + spread * 2.0, 0.0, TAU, 16, Color(FOAM, 0.6 - spread * 0.25), 1.0)
		draw_line(Vector2(-8, -2), Vector2(8, -2), FOAM, 1.0)
