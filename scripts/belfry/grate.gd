class_name SunkenGrate
extends StaticBody2D
## A sunken iron grate (L) standing up out of the water. Swimming, Wren
## can't pass it; diving with the Diver's Helm, they go underneath. With the
## water low it's just an iron fence.


func _ready() -> void:
	Layers.assign(self, Layers.GRATE, [])
	add_child(Layers.rect_shape(Vector2(16, 16), Vector2(0, -4)))
	var sprite := Art.sprite(BelfrySprites.GRATE, 1, 1, 15)
	add_child(sprite)
