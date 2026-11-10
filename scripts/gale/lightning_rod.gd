class_name LightningRod
extends StaticBody2D
## A copper lightning rod on a stone plinth (r). The Stormheron perches on
## them; when the storm gathers, the rod it sits on sparks (the tell) and
## the strike knocks it to the ground.

var charged := false
var _sprite: Sprite2D
var _flash := 0.0


func _ready() -> void:
	add_to_group("lightning_rods")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(12, 8), Vector2(0, -4)))
	add_child(Art.shadow())
	_sprite = Art.sprite(GaleSprites.LIGHTNING_ROD, 2, 1, 38)
	add_child(_sprite)


## Where the heron stands on it (relative to the rod).
func perch_point() -> Vector2:
	return Vector2(0, -36)


func set_charged(on: bool) -> void:
	charged = on
	_sprite.frame = 1 if on else 0


## A bolt comes down on it.
func strike() -> void:
	_flash = 0.35
	set_charged(false)
	Feel.shake(3.0)
	Audio.play_sfx("thunder", global_position)
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		queue_redraw()
	elif charged:
		queue_redraw()


func _draw() -> void:
	if _flash > 0.0:
		# The bolt, jagged, from the top of the screen to the rod's tip.
		var color := Color(1.0, 0.97, 0.75, minf(_flash * 4.0, 1.0))
		var at := Vector2(0, -38)
		var rnd := RandomNumberGenerator.new()
		rnd.seed = 7
		var top := -position.y - 8.0
		var y := at.y
		var x := 0.0
		while y > top:
			var nx := rnd.randf_range(-6.0, 6.0)
			draw_line(Vector2(x, y), Vector2(nx, y - 12.0), color, 2.0)
			x = nx
			y -= 12.0
		draw_circle(at, 6.0 + _flash * 20.0, Color(1.0, 0.95, 0.6, _flash))
	elif charged:
		var t := Time.get_ticks_msec() / 1000.0
		for i in 3:
			var a := t * 9.0 + i * 2.1
			var p := Vector2(0, -38) + Vector2.from_angle(a) * (4.0 + fmod(t * 20.0 + i * 3.0, 6.0))
			draw_rect(Rect2(p, Vector2(2, 2) if Settings.high_contrast else Vector2(1, 1)), Color(1.0, 0.95, 0.5))
