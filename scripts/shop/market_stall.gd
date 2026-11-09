class_name MarketStall
extends StaticBody2D
## Marlo Pike's stall in Saltmarrow: a counter under a striped awning with
## Marlo behind it. Talking at the counter gets a word from Marlo, then his
## wares (ShopMenu). Rooms place it with the letter 7.

## Where Marlo stands, behind the counter.
const MARLO_AT := Vector2(0, -12)
## Solid from the counter's front back to the wall behind Marlo, so nobody
## walks round behind the stall.
const FOOTPRINT := Vector2(46, 26)

var marlo: Npc
var _busy := false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("market_stall")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(FOOTPRINT, Vector2(0, -FOOTPRINT.y / 2.0)))
	var shade := Art.shadow(true)
	shade.scale = Vector2(FOOTPRINT.x / 14.0, 1.5)
	add_child(shade)
	# Marlo first, so the counter draws over his legs.
	marlo = Npc.new("marlo")
	marlo.position = MARLO_AT
	add_child(marlo)
	# He is talked to across the counter, not directly.
	marlo.remove_from_group("interactable")
	add_child(Art.sprite(Art.MARKET_STALL, 1, 1, 44))


func interact() -> void:
	if _busy or DialogueBox.is_open:
		return
	_busy = true
	if not marlo.current_pages().is_empty():
		marlo.interact()
		await Events.dialogue_finished
		if not is_inside_tree():
			return
	var menu := ShopMenu.new()
	get_tree().current_scene.add_child(menu)
	var bought: bool = await menu.closed
	if bought and is_inside_tree():
		Events.conversation_requested.emit(Conversations.pages("marlo", {"lines": ["MARLO_THANKS"]}))
		await Events.dialogue_finished
	_busy = false
