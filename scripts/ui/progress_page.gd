class_name ProgressPage
extends MenuPage
## The progress tab: region by region, the side errands asked and done and
## the pearl shards, Tidestone carvings, sea-glass and chests found (see
## Completion). A region Wren hasn't set foot in yet shows as "???".

const PANEL := Rect2(8, 22, 368, 174)
const NAME_X := 16.0
const NAME_W := 100.0
## Where each column of numbers starts, and how wide it is (errands asked,
## done, shards, stones, glass, chests). Asked only ever holds a number.
const COL_X := [116.0, 152.0, 192.0, 236.0, 280.0, 324.0]
const COL_W := [36.0, 40.0, 44.0, 44.0, 44.0, 44.0]
const HEAD_Y := 26.0
const SUBHEAD_Y := 38.0
const ROW_Y := 54.0
const ROW_STEP := 15.0
const TOTAL_Y := 178.0
const HEADS := ["PROGRESS_UNDERWAY", "PROGRESS_DONE", "PROGRESS_SHARDS", "PROGRESS_STONES",
	"PROGRESS_GLASS", "PROGRESS_CHESTS"]
const LINE := Color(0.56, 0.52, 0.66, 0.35)

var _rows: Dictionary = {}
var _totals: Dictionary = {}


func on_open() -> void:
	_rows = Completion.tally()
	_totals = Completion.totals(_rows)


func _draw() -> void:
	if _rows.is_empty():
		on_open()
	MenuKit.draw_panel(self, PANEL)
	var errands_w: float = COL_W[0] + COL_W[1]
	MenuKit.draw_text(self, "PROGRESS_ERRANDS", Vector2(COL_X[0], HEAD_Y), MenuKit.TEXT_HEAD,
		HORIZONTAL_ALIGNMENT_CENTER, errands_w)
	draw_line(Vector2(COL_X[0] + 4, HEAD_Y + 10.5), Vector2(COL_X[0] + errands_w - 4, HEAD_Y + 10.5), LINE)
	MenuKit.draw_text(self, "PROGRESS_REGION", Vector2(NAME_X, SUBHEAD_Y), MenuKit.TEXT_HEAD,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_W)
	for i in HEADS.size():
		MenuKit.draw_text(self, HEADS[i], Vector2(COL_X[i], SUBHEAD_Y), MenuKit.TEXT_HEAD,
			HORIZONTAL_ALIGNMENT_CENTER, COL_W[i], COL_W[i] - 2)
	draw_line(Vector2(NAME_X, ROW_Y - 3.5), Vector2(PANEL.end.x - 8, ROW_Y - 3.5), LINE)
	for r in Completion.REGIONS.size():
		var region: String = Completion.REGIONS[r]
		var row: Dictionary = _rows[region]
		var y := ROW_Y + r * ROW_STEP
		var seen: bool = row["seen"]
		MenuKit.draw_text(self, ("REGION_" + region.to_upper()) if seen else "PROGRESS_UNKNOWN",
			Vector2(NAME_X, y), MenuKit.TEXT if seen else MenuKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_W)
		_draw_cells(row, y, seen)
	draw_line(Vector2(NAME_X, TOTAL_Y - 3.5), Vector2(PANEL.end.x - 8, TOTAL_Y - 3.5), LINE)
	MenuKit.draw_text(self, "PROGRESS_ALL", Vector2(NAME_X, TOTAL_Y), MenuKit.TEXT_HEAD,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_W)
	_draw_cells(_totals, TOTAL_Y, true)


## One line of numbers: errands underway, then have / total for the rest.
## A full count shows in gold; nothing to find shows a dash.
func _draw_cells(row: Dictionary, y: float, seen: bool) -> void:
	for i in Completion.KINDS.size():
		var kind: String = Completion.KINDS[i]
		var have: int = row[kind][0]
		var total: int = row[kind][1]
		var text := ""
		var color := MenuKit.TEXT if seen else MenuKit.TEXT_DIM
		if kind == "underway":
			text = str(have) if have > 0 else "-"
			if have == 0:
				color = MenuKit.TEXT_DIM
		elif total == 0:
			text = "-"
			color = MenuKit.TEXT_DIM
		else:
			text = "%d/%d" % [have, total]
			if have >= total:
				color = MenuKit.TEXT_GOLD
			elif have == 0:
				color = MenuKit.TEXT_DIM
		MenuKit.draw_text(self, text, Vector2(COL_X[i], y), color, HORIZONTAL_ALIGNMENT_CENTER, COL_W[i])
