class_name Jumpers
## Ottilie's Knits: jumpers for Wren in mill-dyed colours, bought at Still
## Cove and changed in the Satchel. Purely for looks. Each is a five-colour
## ramp (light to dark) that takes the place of the classic navy stripes.

## The classic navy, as drawn in assets/sprites/wren.png (tools/build_art.py
## ramp "D", light to dark).
const CLASSIC: Array[Color] = [Color("#8AA8E0"), Color("#5A78C0"), Color("#3A4E8E"), Color("#26305E"), Color("#141832")]
## Shop order; the ramps were picked by the story thread.
const ORDER: Array[String] = ["kelp", "ember", "plum", "frost", "storm"]
const TABLE := {
	"kelp": {"price": 150, "ramp": ["#9CD08A", "#62A860", "#3E7A48", "#285034", "#142A1E"]},
	"ember": {"price": 200, "ramp": ["#F0A878", "#D06E48", "#9A4632", "#642A22", "#341612"]},
	"plum": {"price": 250, "ramp": ["#C8A0D8", "#9A6AB4", "#6E4688", "#482C5C", "#261630"]},
	"frost": {"price": 300, "ramp": ["#D4ECF0", "#96C8D0", "#5E949E", "#3C626C", "#1E343A"]},
	"storm": {"price": 400, "ramp": ["#B4B8C0", "#848A96", "#5A606C", "#3A3E48", "#1C1E24"]},
}
## Ottilie (an Npc kind) offers her knits once she has told Wren about them.
const SELLER := "ottilie"
const SELLER_FLAG := "ottilie_knits_told"
## Rows of Wren's sheet (24 px a frame) from which the stripes are swapped:
## the cap above uses the same navy and stays as it is.
const SWAP_FROM_ROW := 9
const FRAME_HEIGHT := 24


static func flag(id: String) -> String:
	return "jumper_" + id


static func name_key(id: String) -> String:
	return "JUMPER_CLASSIC" if id == "" else "JUMPER_" + id.to_upper()


static func owns(id: String) -> bool:
	return id == "" or (TABLE.has(id) and GameState.has_flag(flag(id)))


## What Wren can wear: the classic first, then each knit bought.
static func owned() -> Array[String]:
	var out: Array[String] = [""]
	for id in ORDER:
		if owns(id):
			out.append(id)
	return out


## The jumper after `id` among the owned ones (back to the classic at the end).
static func next(id: String) -> String:
	var list := owned()
	return list[(list.find(id) + 1) % list.size()]


static func ramp(id: String) -> Array[Color]:
	if not TABLE.has(id):
		return CLASSIC
	var out: Array[Color] = []
	for hex: String in TABLE[id]["ramp"]:
		out.append(Color(hex))
	return out


## Ottilie's stock for ShopMenu: one row per knit.
static func stock() -> Array:
	var rows: Array = []
	for id in ORDER:
		rows.append({"flag": flag(id), "price": int(TABLE[id]["price"]), "name": name_key(id),
			"info": name_key(id) + "_INFO", "jumper": id})
	return rows


## Sets Wren's sprite (made by Art.sprite) to wear jumper `id`.
static func dress(sprite: Sprite2D, id: String) -> void:
	var material := sprite.material as ShaderMaterial
	if material == null:
		return
	if id == "" or not TABLE.has(id):
		material.set_shader_parameter("swap_count", 0)
		return
	material.set_shader_parameter("swap_from", PackedColorArray(CLASSIC))
	material.set_shader_parameter("swap_to", PackedColorArray(ramp(id)))
	material.set_shader_parameter("swap_vframes", float(sprite.vframes))
	material.set_shader_parameter("swap_row_frac", float(SWAP_FROM_ROW) / FRAME_HEIGHT)
	material.set_shader_parameter("swap_count", CLASSIC.size())
