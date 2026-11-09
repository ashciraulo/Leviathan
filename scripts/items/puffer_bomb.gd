class_name PufferBomb
extends Node2D
## A lit puffer bomb, set down in front of Wren. It swells and fizzes, then
## bursts: enemies close by are hurt, pots break, and Wren is hurt too if
## they didn't step back. It never opens anything a dungeon tool is for.

const FUSE_TIME := 1.6
const RADIUS := 28.0
const DAMAGE := 2
const BLAST_TIME := 0.3
## How far in front of Wren's feet it lands.
const PLACE_AHEAD := 12.0

var _age := 0.0
var _burst := false
var _next_fizz := 0.0


## Sets a lit bomb down in front of `wren`, in the room under them.
static func place(wren: Player) -> PufferBomb:
	var at := wren.global_position + wren.facing * PLACE_AHEAD
	var room := Room.under(wren.get_tree(), wren.global_position)
	var bomb := PufferBomb.new()
	if room:
		room.add_child(bomb)
	else:
		wren.get_parent().add_child(bomb)
	bomb.global_position = at
	return bomb


func _ready() -> void:
	add_to_group("puffer_bombs")
	add_child(Art.shadow())


func _process(delta: float) -> void:
	_age += delta
	if not _burst:
		if _age >= _next_fizz:
			_next_fizz = _age + 0.4
			Audio.play_sfx("bomb_fuse", global_position)
		if _age >= FUSE_TIME:
			burst()
	elif _age >= FUSE_TIME + BLAST_TIME:
		queue_free()
	queue_redraw()


## Goes off now (also used by tests).
func burst() -> void:
	if _burst:
		return
	_burst = true
	_age = maxf(_age, FUSE_TIME)
	Audio.play_sfx("bomb_blast", global_position)
	Feel.shake(4.0)
	Feel.hitstop(3)
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + Vector2(0, -4))
	query.collision_mask = (1 << (Layers.WORLD - 1)) | (1 << (Layers.ENEMY_HURTBOX - 1))
	query.collide_with_areas = true
	var seen := {}
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var target := hit["collider"] as Node
		if target is Area2D:
			target = target.get_parent()
		if target == null or seen.has(target.get_instance_id()):
			continue
		seen[target.get_instance_id()] = true
		if target.has_method("bomb_hit"):
			target.bomb_hit()
		elif target is Enemy:
			var enemy := target as Enemy
			var away := (enemy.global_position - global_position).normalized()
			var amount := DAMAGE if not enemy.is_in_group("boss") else Player.BOSS_HIT_CAP
			enemy.take_hit(amount, away)
	var wren := get_tree().get_first_node_in_group("player") as Player
	if wren and wren.global_position.distance_to(global_position) < RADIUS:
		wren.take_damage(1, global_position)


func _draw() -> void:
	if _burst:
		# A ring of salt-white blast spreading out.
		var t := (_age - FUSE_TIME) / BLAST_TIME
		var r := RADIUS * (0.4 + 0.6 * t)
		draw_circle(Vector2(0, -4), r, Color(1.0, 0.95, 0.8, 0.5 * (1.0 - t)))
		draw_arc(Vector2(0, -4), r, 0.0, TAU, 24, Color(1, 1, 1, 1.0 - t), 2.0)
		return
	# The puffer swells as the fuse burns, and flushes faster near the end.
	var k := _age / FUSE_TIME
	var r := 4.0 + 2.0 * k
	var hot := sin(_age * (6.0 + 30.0 * k)) > 0.0 and k > 0.3
	var skin := Color("#e8a44a") if not hot else Color("#f05a3a")
	var centre := Vector2(0, -r - 1)
	draw_circle(centre, r + 1.0, Palette.OUTLINE)
	for i in 8:
		var angle := TAU * i / 8.0
		var tip := centre + Vector2(cos(angle), sin(angle)) * (r + 2.5)
		draw_rect(Rect2(tip - Vector2(0.5, 0.5), Vector2(1, 1)), Palette.OUTLINE)
	draw_circle(centre, r, skin)
	draw_rect(Rect2(centre + Vector2(-2, -1), Vector2(1, 1)), Palette.OUTLINE)
	draw_rect(Rect2(centre + Vector2(1, -1), Vector2(1, 1)), Palette.OUTLINE)
	# The fuse: a spark on top.
	if int(_age * 12.0) % 2 == 0:
		draw_rect(Rect2(centre + Vector2(-0.5, -r - 3), Vector2(1, 2)), Color("#fff2a0"))
