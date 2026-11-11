class_name ShopMenu
extends CanvasLayer
## Marlo Pike's wares: pick a row and pay in glints. Opens over the paused
## game after Marlo has had his say, and closes on Leave or Back.
##
## Stock rows: {id, count, price} hand over `count` of an item; {jar: contents,
## price} fills an empty jar. "if" is a flag the row waits for. Prices are
## kept here in one table so they are easy to retune.

signal closed(bought: bool)

const STOCK := [
	{"id": "puffer_bombs", "count": 5, "price": 20, "if": "tidebell_hull"},
	{"id": "lamp_oil", "count": 3, "price": 15},
	{"jar": Items.JAR_POTION, "price": 30},
]
const PANEL := Rect2(64, 14, 256, 134)
const INFO := Rect2(64, 152, 256, 44)
const FIRST_ROW := Vector2(80, 58)
const ROW_STEP := 22
## The press that closed Marlo's dialogue mustn't also buy something.
const INPUT_DELAY := 0.2
## Marlo's browsing tune, and how long it takes to come in and go.
const MUSIC := "place_shop"
const MUSIC_FADE := 0.6
const SHAKE_TIME := 0.3
const FLASH_TIME := 0.35

## Like the dialogue box: the press that closes the shop mustn't also reach
## Wren (an interact that reopens it, a sword swing).
static var _closed_at := -100000

var _rows: Array = []
## The track playing when the stall opened, to go back to.
var _music_before := ""
var _cursor := 0
var _time := 0.0
var _bought := false
var _done := false
var _shake := 0.0
var _flash := 0.0
## Glints just spent, floating up from the purse.
var _spent := 0
var _spent_time := 0.0
var _canvas: Control


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("shop_menu")
	_rows = rows()
	get_tree().paused = true
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_menu)
	add_child(_canvas)
	Audio.play_sfx("ui_open")
	# Browsing has its own tune; the room's comes back on leaving.
	_music_before = Audio.music_cue
	Audio.play_music(MUSIC, MUSIC_FADE)


static func recently_closed() -> bool:
	return Time.get_ticks_msec() - _closed_at < DialogueBox.CLOSE_GRACE_MSEC


## The rows on sale now (stock waiting on a flag is left out).
static func rows() -> Array:
	var out: Array = []
	for row: Dictionary in STOCK:
		if row.has("if") and not GameState.has_flag(str(row["if"])):
			continue
		out.append(row)
	return out


## Why a row can't be bought right now: "" if it can, else a reason key.
static func blocked(row: Dictionary) -> String:
	if row.has("jar"):
		if GameState.jars.is_empty() or not Items.JAR_EMPTY in GameState.jars:
			return "SHOP_NO_JAR"
	elif GameState.item_count(str(row["id"])) + int(row["count"]) > Items.max_count(str(row["id"])):
		# No paying full price for a part bundle.
		return "SHOP_FULL"
	return ""


static func can_afford(row: Dictionary) -> bool:
	return GameState.item_count("glint") >= int(row["price"])


## Buys row i. False (and nothing changes) if it can't be bought.
func buy(i: int) -> bool:
	var row: Dictionary = _rows[i]
	if blocked(row) != "" or not can_afford(row):
		_shake = SHAKE_TIME
		Audio.play_sfx("shop_short")
		return false
	GameState.take_item("glint", int(row["price"]))
	if row.has("jar"):
		GameState.fill_jar(str(row["jar"]))
	else:
		# Bought goods go in the satchel, not straight onto an item slot:
		# the player chooses what to carry on the slots.
		var slots: Array = GameState.item_slots.duplicate()
		GameState.give_item(str(row["id"]), int(row["count"]), false)
		GameState.item_slots = slots
	_bought = true
	_flash = FLASH_TIME
	_spent = int(row["price"])
	_spent_time = 0.0
	Audio.play_sfx("shop_buy")
	return true


func close() -> void:
	if _done:
		return
	_done = true
	_closed_at = Time.get_ticks_msec()
	Audio.play_sfx("ui_back")
	if Audio.music_cue == MUSIC:
		Audio.play_music(_music_before, MUSIC_FADE)
	get_tree().paused = false
	queue_free()
	closed.emit(_bought)


func _process(delta: float) -> void:
	_time += delta
	_shake = maxf(_shake - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	_spent_time += delta
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or _done:
		return
	get_viewport().set_input_as_handled()
	if _time < INPUT_DELAY:
		return
	var dir := MenuKit.direction(event)
	if dir.y != 0:
		_cursor = posmod(_cursor + dir.y, _rows.size() + 1)
		Audio.play_sfx("ui_move")
	elif MenuKit.cancel(event) or event.is_action_pressed("pause"):
		close()
	elif MenuKit.confirm(event):
		if _cursor == _rows.size():
			close()
		else:
			buy(_cursor)


func _row_rect(i: int) -> Rect2:
	return Rect2(FIRST_ROW + Vector2(0, i * ROW_STEP), Vector2(PANEL.size.x - 32, 20))


func _draw_menu() -> void:
	var c := _canvas
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(384, 216)), Color(0, 0, 0, 0.45))
	MenuKit.draw_panel(c, PANEL)
	MenuKit.draw_panel(c, INFO)
	# Marlo at the top, and the purse.
	c.draw_texture(Art.PORTRAIT_MARLO, PANEL.position + Vector2(12, 10))
	MenuKit.draw_text(c, "NAME_MARLO", PANEL.position + Vector2(50, 12), MenuKit.TEXT_HEAD)
	MenuKit.draw_text(c, "SHOP_TITLE", PANEL.position + Vector2(50, 24), MenuKit.TEXT_GOLD)
	var purse := Vector2(PANEL.end.x - 60, PANEL.position.y + 14)
	MenuKit.draw_icon(c, "glint", purse)
	MenuKit.draw_text(c, "x %d" % GameState.item_count("glint"), purse + Vector2(18, 4))
	if _spent > 0 and _spent_time < 0.8:
		var a := 1.0 - _spent_time / 0.8
		MenuKit.draw_text(c, "-%d" % _spent, purse + Vector2(18, -6 - _spent_time * 10.0), Color(MenuKit.TEXT_WARN, a))
	c.draw_rect(Rect2(PANEL.position + Vector2(10, 46), Vector2(PANEL.size.x - 20, 1)), MenuKit.TEXT_DIM)
	for i in _rows.size():
		_draw_row(i)
	var leave := _row_rect(_rows.size())
	MenuKit.draw_text(c, "SHOP_LEAVE", leave.position + Vector2(26, 6), MenuKit.TEXT if _cursor == _rows.size() else MenuKit.TEXT_DIM)
	var cursor_rect := _row_rect(_cursor)
	if _cursor == _rows.size():
		cursor_rect = Rect2(leave.position + Vector2(22, 2), Vector2(MenuKit.text_width(c, "SHOP_LEAVE") + 8, 16))
	MenuKit.draw_cursor(c, cursor_rect)
	_draw_info()


func _draw_row(i: int) -> void:
	var c := _canvas
	var row: Dictionary = _rows[i]
	var r := _row_rect(i)
	if i == _cursor and _shake > 0.0:
		r.position.x += round(sin(_shake * 60.0) * 2.0)
	if i == _cursor and _flash > 0.0:
		c.draw_rect(r, Color(MenuKit.TEXT_GOLD, 0.25 * _flash / FLASH_TIME))
	var reason := blocked(row)
	MenuKit.draw_slot(c, r.position)
	var icon_at := r.position + Vector2(2, 2)
	if row.has("jar"):
		MenuKit.draw_icon_frame(c, Items.JAR_ICONS[row["jar"]], icon_at)
	else:
		MenuKit.draw_icon(c, str(row["id"]), icon_at)
	var name := _name_key(row)
	var name_colour := MenuKit.TEXT if reason == "" else MenuKit.TEXT_DIM
	MenuKit.draw_text(c, name, r.position + Vector2(26, 6), name_colour, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 110.0)
	if row.has("count"):
		MenuKit.draw_text(c, "x %d" % int(row["count"]), r.position + Vector2(140, 6), MenuKit.TEXT_DIM)
	var right := r.end.x - 2
	if reason != "":
		var w := MenuKit.text_width(c, reason)
		MenuKit.draw_text(c, reason, Vector2(right - w, r.position.y + 6), MenuKit.TEXT_DIM)
		return
	var price := str(int(row["price"]))
	var pw := MenuKit.text_width(c, price)
	MenuKit.draw_icon(c, "glint", Vector2(right - 16, r.position.y + 2))
	MenuKit.draw_text(c, price, Vector2(right - 18 - pw, r.position.y + 6), MenuKit.TEXT_GOLD if can_afford(row) else MenuKit.TEXT_WARN)


static func _name_key(row: Dictionary) -> String:
	if row.has("jar"):
		return "ITEM_JAR_" + str(row["jar"]).to_upper()
	return Items.name_key(str(row["id"]))


func _draw_info() -> void:
	var at := INFO.position + Vector2(10, 5)
	var width := INFO.size.x - 20
	if _cursor == _rows.size():
		return
	var key := _name_key(_rows[_cursor])
	MenuKit.draw_text(_canvas, key, at, MenuKit.TEXT_GOLD)
	MenuKit.draw_wrapped(_canvas, key + "_DESC", at + Vector2(0, 12), width, MenuKit.TEXT, 2)
