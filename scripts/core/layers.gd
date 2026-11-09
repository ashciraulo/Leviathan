class_name Layers
extends Object
## Physics layer numbers (they match Project Settings > Layer Names) and small
## helpers for building collision in code.

const WORLD := 1
const PLAYER := 2
const ENEMY := 3
const PLAYER_ATTACK := 4
const ENEMY_HURTBOX := 5
const ENEMY_ATTACK := 6
const PLAYER_HURTBOX := 7
const WATER := 8
## Holes in a deck: they stop enemies and crates, but Wren can fall in.
const PIT := 9
## Deep water (Q, and flooded floor): only Wren with the Diver's Helm swims it.
const DEEP := 10
## Sunken grates in deep water: Wren swims under them only when diving.
const GRATE := 11


## Put a body or area on exactly one layer (0 for none) and the given masks.
static func assign(object: CollisionObject2D, layer: int, masks: Array) -> void:
	object.collision_layer = 0 if layer == 0 else 1 << (layer - 1)
	object.collision_mask = 0
	for mask: int in masks:
		object.collision_mask |= 1 << (mask - 1)


static func rect_shape(size: Vector2, center: Vector2) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = center
	return node


static func circle_shape(radius: float, center: Vector2) -> CollisionShape2D:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = center
	return node
