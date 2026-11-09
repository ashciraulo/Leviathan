extends Node
## Save slots as JSON files in user://. Three slots, picked on the file select.
## JSON keeps saves readable and easy to debug.
##
## Saving never overwrites a good file in place: the new save is written to
## a .tmp file first, the previous save is kept as .bak, and only then does
## the new file take its place. If the main file is ever damaged (a crash or
## power cut mid-write), loading falls back to the .bak.

const SLOT_COUNT := 3
const FORMAT_VERSION := 1

var current_slot := 0


func slot_path(slot: int = -1) -> String:
	return "user://save_%d.json" % _slot(slot)


func has_save(slot: int = -1) -> bool:
	var path := slot_path(slot)
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") \
		or not _read(path + ".tmp").is_empty()


func save_game(slot: int = -1) -> bool:
	var data := {
		"format_version": FORMAT_VERSION,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"saved_at": Time.get_datetime_string_from_system(),
		"state": GameState.to_dict(),
		"summary": summary(),
	}
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save %s: %s" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if _read(tmp).is_empty():
		push_error("Save did not write correctly: %s" % tmp)
		return false
	var bak := path + ".bak"
	if FileAccess.file_exists(path):
		if _read(path).is_empty():
			# A damaged save never replaces a good backup.
			DirAccess.remove_absolute(_abs(path))
		else:
			if FileAccess.file_exists(bak):
				DirAccess.remove_absolute(_abs(bak))
			DirAccess.rename_absolute(_abs(path), _abs(bak))
	if DirAccess.rename_absolute(_abs(tmp), _abs(path)) != OK:
		push_error("Could not move the new save into place: %s" % path)
		return false
	Events.game_saved.emit()
	return true


func load_game(slot: int = -1) -> bool:
	var parsed := _read_slot(slot)
	if parsed.is_empty():
		if has_save(slot):
			push_error("Save file is damaged: %s" % slot_path(slot))
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
	if not has_save(slot):
		return {}
	var parsed := _read_slot(slot)
	if parsed.is_empty():
		return {"damaged": true}
	var out: Dictionary = {}
	var saved = parsed.get("summary")
	if saved is Dictionary:
		out = saved.duplicate()
	else:
		# Older saves without a summary: work out what we can.
		var state: Dictionary = parsed["state"]
		out["bubbles"] = int(state.get("max_bubbles", GameState.START_BUBBLES))
		var room = state.get("checkpoint_room", [0, 0])
		if room is Array and room.size() >= 2:
			out["place"] = str(RoomInfo.get_room(Vector2i(int(room[0]), int(room[1]))).get("name_key", ""))
		out["play_time"] = float(state.get("play_time", 0.0))
	out["saved_at"] = str(parsed.get("saved_at", ""))
	return out


func copy_save(from_slot: int, to_slot: int) -> bool:
	if not has_save(from_slot) or from_slot == to_slot:
		return false
	var parsed := _read_slot(from_slot)
	if parsed.is_empty():
		return false
	delete_save(to_slot)
	var file := FileAccess.open(slot_path(to_slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(parsed, "\t"))
	file.close()
	return true


## The slot saved most recently, or -1 when there are no saves.
func latest_slot() -> int:
	var best := -1
	var best_time := ""
	for slot in SLOT_COUNT:
		if not has_save(slot):
			continue
		var data := read_summary(slot)
		if data.get("damaged", false):
			continue
		var at := str(data.get("saved_at", ""))
		if best < 0 or at > best_time:
			best = slot
			best_time = at
	return best


func delete_save(slot: int = -1) -> void:
	var path := slot_path(slot)
	for file in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(_abs(file))
	_flush_web()


## In a browser, user:// is copied to the browser's storage only after a file
## written to it is closed. Removing files doesn't count, so write a small
## one to make a deleted save stay deleted.
func _flush_web() -> void:
	if OS.has_feature("web"):
		var file := FileAccess.open("user://.sync", FileAccess.WRITE)
		if file:
			file.store_string(Time.get_datetime_string_from_system())


## A slot's save data: the main file, or if that is missing or damaged, a
## checked new save that never got moved into place (.tmp), or the backup.
## {} when none is readable.
func _read_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	for file in [path, path + ".tmp", path + ".bak"]:
		var data := _read(file)
		if not data.is_empty():
			return data
	return {}


## A save file's data if it parses and has a state, else {}.
func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not (parsed.get("state") is Dictionary):
		return {}
	return parsed


## Tests and screenshot runs use real slots: move a slot's files (save and
## backup) aside under a tag, and put them back afterwards. A tag already
## set aside (a run that crashed) is restored first, so it's never lost.
func set_aside(slot: int, tag: String) -> void:
	restore_aside(slot, tag)
	var path := slot_path(slot)
	for file in [path, path + ".bak"]:
		if FileAccess.file_exists(file):
			DirAccess.rename_absolute(_abs(file), _abs(file + "." + tag))


func restore_aside(slot: int, tag: String) -> void:
	var path := slot_path(slot)
	if not (FileAccess.file_exists(path + "." + tag) or FileAccess.file_exists(path + ".bak." + tag)):
		return
	delete_save(slot)
	for file in [path, path + ".bak"]:
		if FileAccess.file_exists(file + "." + tag):
			DirAccess.rename_absolute(_abs(file + "." + tag), _abs(file))


func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)


func _slot(slot: int) -> int:
	return clampi(current_slot if slot < 0 else slot, 0, SLOT_COUNT - 1)
