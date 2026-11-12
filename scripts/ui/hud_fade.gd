class_name HudFade
## The HUD's corner panels (breath on the left, item slots and keys on the
## right) sit over the room's top rows. When Wren, a chest, a foe or anything
## else worth seeing is under one, that panel fades so it can be seen.

## How far a panel fades, and how fast (alpha per second).
const LOW := 0.35
const SPEED := 5.0
## What a panel fades for.
const GROUPS: Array[String] = ["player", "interactable", "enemies", "smashable", "breakable", "crates", "ice_eyes", "pickups"]
## A thing's footprint on screen around its position (most stand on it).
const FOOTPRINT := Rect2(-8, -16, 16, 20)


## True when something worth seeing is under `rect` (screen pixels).
static func covered(tree: SceneTree, rect: Rect2) -> bool:
	for group in GROUPS:
		for node in tree.get_nodes_in_group(group):
			var item := node as CanvasItem
			if item == null or not item.is_visible_in_tree():
				continue
			var at := item.get_global_transform_with_canvas().origin
			if rect.intersects(Rect2(at + FOOTPRINT.position, FOOTPRINT.size)):
				return true
	return false


## The panel's alpha `delta` seconds on from `alpha`.
static func step(alpha: float, is_covered: bool, delta: float) -> float:
	return move_toward(alpha, LOW if is_covered else 1.0, SPEED * delta)
