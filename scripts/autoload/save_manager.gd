extends Node
## Save slots as JSON files in user://. Three slots, picked on the file select.
## JSON keeps saves readable and easy to debug.

const SLOT_COUNT := 3
const FORMAT_VERSION := 1

var current_slot := 0


func slot_path(slot: int = -1) -> String:
	return "user://save_%d.json" % _slot(slot)


func has_save(slot: int = -1) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot: int = -1) -> bool:
	var data := {
		"format_version": FORMAT_VERSION,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"saved_at": Time.get_datetime_string_from_system(),
		"state": GameState.to_dict(),
		"summary": summary(),
	}
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Could not write save %s: %s" % [slot_path(slot), error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_game(slot: int = -1) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not (parsed.get("state") is Dictionary):
		push_error("Save file is damaged: %s" % path)
		return false
	GameState.from_dict(parsed["state"])
	return true


## The few facts the file select shows, so it needn't load the whole game.
func summary() -> Dictionary:
	return {
		"place": str(RoomInfo.get_room(GameState.checkpoint_room).get("name_key", "")),
		"bubbles": GameState.max_bubbles,
		"bells": GameState.item_count("tidebell"),
		"pearls": GameState.item_count("breath_pearl"),
		"play_time": GameState.play_time,
	}


## A save's summary plus "saved_at", or {} if the slot is empty or damaged.
func read_summary(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not (parsed.get("state") is Dictionary):
		return {"damaged": true}
	var out: Dictionary = {}
	var saved = parsed.get("summary", {})
	if saved is Dictionary:
		out = saved.duplicate()
	else:
		# Older saves without a summary: work out what we can.
		var state: Dictionary = parsed["state"]
		out["bubbles"] = int(state.get("max_bubbles", GameState.START_BUBBLES))
	out["saved_at"] = str(parsed.get("saved_at", ""))
	return out


func copy_save(from_slot: int, to_slot: int) -> bool:
	if not has_save(from_slot) or from_slot == to_slot:
		return false
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(slot_path(from_slot)),
		ProjectSettings.globalize_path(slot_path(to_slot))) == OK


## The slot saved most recently, or -1 when there are no saves.
func latest_slot() -> int:
	var best := -1
	var best_time := ""
	for slot in SLOT_COUNT:
		if not has_save(slot):
			continue
		var at := str(read_summary(slot).get("saved_at", ""))
		if best < 0 or at > best_time:
			best = slot
			best_time = at
	return best


func delete_save(slot: int = -1) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


func _slot(slot: int) -> int:
	return clampi(current_slot if slot < 0 else slot, 0, SLOT_COUNT - 1)
