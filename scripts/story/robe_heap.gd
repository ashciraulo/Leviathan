class_name RobeHeap
extends Node2D
## Vael's grey Choir robe, dropped on the floor of the Heart's chamber at
## the end: a soft heap of cloth with the hood folded on top.

const CLOTH := Color("#8e8a9a")
const FOLD := Color("#6e6a7e")
const EDGE := Color("#4a4658")


func _ready() -> void:
	z_index = -1


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2(0, 0), 10.0, EDGE)
	draw_circle(Vector2(0, -1), 9.0, CLOTH)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Folds, and the hood lying on top.
	draw_line(Vector2(-6, -1), Vector2(-1, 1), FOLD)
	draw_line(Vector2(2, -2), Vector2(7, 0), FOLD)
	draw_rect(Rect2(-3, -5, 6, 3), FOLD)
	draw_rect(Rect2(-2, -4, 4, 1), CLOTH)
