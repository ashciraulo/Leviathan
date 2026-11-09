class_name Chest
extends StaticBody2D
## A chest. Face it and press Interact to open it: the item rises out of it,
## Wren gets it, and the chest stays open for good (saved as a flag).

const ITEM_RISE := 14.0
const ITEM_SHOW_TIME := 1.0
## item id: [toast key, sprite]
const ITEMS := {
	"small_key": ["TOAST_GOT_KEY", Art.SMALL_KEY],
	"tide_hook": ["TOAST_GOT_TIDE_HOOK", HullSprites.TIDE_HOOK],
	"stonebreaker": ["TOAST_GOT_STONEBREAKER", KilnSprites.STONEBREAKER],
	"glowmoth_lantern": ["TOAST_GOT_GLOWMOTH_LANTERN", MireSprites.GLOWMOTH_LANTERN],
	"kite_cloak": ["TOAST_GOT_KITE_CLOAK", GaleSprites.KITE_CLOAK],
	"frostfang_bow": ["TOAST_GOT_FROSTFANG_BOW", GlacierSprites.FROSTFANG_BOW],
	"divers_helm": ["TOAST_GOT_DIVERS_HELM", BelfrySprites.DIVERS_HELM],
	"echo_horn": ["TOAST_GOT_ECHO_HORN", TombSprites.ECHO_HORN],
	"map": ["TOAST_GOT_MAP", HullSprites.MAP],
	"compass": ["TOAST_GOT_COMPASS", HullSprites.COMPASS],
	"big_key": ["TOAST_GOT_BIG_KEY", HullSprites.BIG_KEY],
	"breath_pearl": ["TOAST_GOT_PEARL", null],
	"nacre_buckler": ["TOAST_GOT_NACRE_BUCKLER", null],
	"abyssal": ["TOAST_GOT_ABYSSAL", null],
	"tidecaller_sword": ["TOAST_GOT_TIDECALLER_SWORD", null],
}
## Finding one of these opens the dialogue box to explain it.
const ITEM_TALK := {
	"tide_hook": ["GOT_TIDE_HOOK_1", "GOT_TIDE_HOOK_2"],
	"stonebreaker": ["GOT_STONEBREAKER_1", "GOT_STONEBREAKER_2"],
	"glowmoth_lantern": ["GOT_GLOWMOTH_LANTERN_1", "GOT_GLOWMOTH_LANTERN_2"],
	"kite_cloak": ["GOT_KITE_CLOAK_1", "GOT_KITE_CLOAK_2"],
	"frostfang_bow": ["GOT_FROSTFANG_BOW_1", "GOT_FROSTFANG_BOW_2"],
	"divers_helm": ["GOT_DIVERS_HELM_1", "GOT_DIVERS_HELM_2"],
	"echo_horn": ["GOT_ECHO_HORN_1", "GOT_ECHO_HORN_2"],
	"nacre_buckler": ["GOT_NACRE_BUCKLER_1"],
	"abyssal": ["GOT_ABYSSAL_1"],
	"tidecaller_sword": ["GOT_TIDECALLER_SWORD_1"],
}

var room_coord := Vector2i.ZERO
var tile := Vector2i.ZERO
var dungeon := ""
var item := "small_key"
## How many of item it holds.
var count := 1
var opened := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("interactable")
	Layers.assign(self, Layers.WORLD, [])
	add_child(Layers.rect_shape(Vector2(14, 9), Vector2(0, -4.5)))
	add_child(Art.shadow())
	_sprite = Art.sprite(Art.CHEST, 2, 1, 13)
	add_child(_sprite)
	opened = bool(GameState.flags.get(flag_key(), false))
	_sprite.frame = 1 if opened else 0


## An item's 16x16 satchel icon as a texture.
static func icon_texture(id: String) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = MenuKit.ITEMS
	atlas.region = Items.icon_rect(Items.icon(id))
	return atlas


func flag_key() -> String:
	return "chest_%d_%d_%d_%d" % [room_coord.x, room_coord.y, tile.x, tile.y]


func interact() -> void:
	if opened:
		return
	opened = true
	Audio.play_sfx("chest_open", global_position)
	_sprite.frame = 1
	GameState.flags[flag_key()] = true
	match item:
		"small_key":
			GameState.add_key(dungeon)
			Audio.play_sfx("key_get", global_position)
		"map", "compass", "big_key":
			GameState.give_item(Items.dungeon_item(dungeon, item))
		_:
			GameState.give_item(item, count)
	var spec: Array = ITEMS.get(item, [Items.name_key(item), null])
	Events.toast.emit(spec[0])
	# Show the item lifting out of the chest (its satchel icon if it has no
	# sprite of its own).
	var texture: Texture2D = spec[1] if spec[1] != null else Chest.icon_texture(item)
	var shown := Art.sprite(texture, 1, 1, 12)
	shown.z_index = 5
	add_child(shown)
	var tween := create_tween()
	tween.tween_property(shown, "position:y", shown.position.y - ITEM_RISE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(ITEM_SHOW_TIME)
	tween.tween_property(shown, "modulate:a", 0.0, 0.25)
	tween.tween_callback(shown.queue_free)
	if ITEM_TALK.has(item):
		await get_tree().create_timer(0.6).timeout
		Events.dialogue_requested.emit("", PackedStringArray(ITEM_TALK[item]))
