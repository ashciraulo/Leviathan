extends Node
## Save slots as JSON files in user://. Three slots, picked on the file select.
## JSON keeps saves readable and easy to debug.
##
## Saving never overwrites a good file in place: the new save is written to
## a .tmp file first, the previous save is kept as .bak, and only then does
## the new file take its place. If the main file is ever damaged (a crash or
## power cut mid-write), loading falls back to the .bak.
##
## Every save records its FORMAT_VERSION. When the layout of "state" changes,
## bump FORMAT_VERSION and add a step to _migrate() that turns the old
## layout into the new one; old saves are brought up to date as they load.
## A save from a newer version of the game is never loaded or overwritten
## by accident: the file select shows it as from a newer version.

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
	# Never write over a newer version's save (say, another copy of the game
	# saved to this slot meanwhile).
	var existing := _read_slot(slot)
	if not existing.is_empty() and is_newer(existing):
		push_error("Not saving over a newer save: %s" % slot_path(slot))
		return false
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
	if is_newer(parsed):
		push_error("Save %s is from a newer version of the game" % slot_path(slot))
		return false
	GameState.from_dict(_migrate(parsed)["state"])
	return true


## True when a save was written by a newer version of the game (a format
## this build doesn't know).
func is_newer(parsed: Dictionary) -> bool:
	return _version_of(parsed) > FORMAT_VERSION


func _version_of(parsed: Dictionary) -> int:
	# Saves from before versioning count as version 0.
	if not parsed.has("format_version"):
		return 0
	var version = parsed["format_version"]
	# Anything but a number is a format this build doesn't know.
	return int(version) if (version is int or version is float) else FORMAT_VERSION + 1


## Brings a parsed save up to FORMAT_VERSION, one step at a time. Each step
## takes the whole save (state, summary...) at version N and returns it at
## N + 1. Steps only ever get added, never changed, so any old save can be
## walked forward.
func _migrate(parsed: Dictionary) -> Dictionary:
	var data := parsed.duplicate(true)
	var version := _version_of(data)
	while version < FORMAT_VERSION:
		match version:
			0:
				# Version 0 (before versioning) has the same state layout;
				# GameState.from_dict fills anything missing with defaults.
				pass
		version += 1
		data["format_version"] = version
	return data


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
	if is_newer(parsed):
		return {"newer": true, "saved_at": str(parsed.get("saved_at", ""))}
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


## A slot's save as text to keep outside the game (a file the player
## downloads), or "" when the slot has no readable save.
func export_text(slot: int) -> String:
	var parsed := _read_slot(slot)
	return "" if parsed.is_empty() else JSON.stringify(parsed, "\t")


## The name an exported save gets: the game, the file number and the date.
func export_file_name(slot: int) -> String:
	return "leviathan-file%d-%s.json" % [_slot(slot) + 1, Time.get_date_string_from_system()]


## Puts a save brought in from outside the game (export_text's output) into
## an empty slot. Returns "" when it worked, otherwise the text key of why not.
func import_text(text: String, slot: int) -> String:
	if has_save(slot):
		return "FILES_IMPORT_NEED_EMPTY"
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary) or not (parsed.get("state") is Dictionary):
		return "FILES_IMPORT_BAD"
	if is_newer(parsed):
		return "FILES_NEWER"
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return "FILES_IMPORT_BAD"
	file.store_string(JSON.stringify(parsed, "\t"))
	file.close()
	return ""


## The slot saved most recently, or -1 when there are no saves.
func latest_slot() -> int:
	var best := -1
	var best_time := ""
	for slot in SLOT_COUNT:
		if not has_save(slot):
			continue
		var data := read_summary(slot)
		if data.get("damaged", false) or data.get("newer", false):
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
	for file in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.rename_absolute(_abs(file), _abs(file + "." + tag))


func restore_aside(slot: int, tag: String) -> void:
	var path := slot_path(slot)
	if not (FileAccess.file_exists(path + "." + tag) or FileAccess.file_exists(path + ".bak." + tag) \
			or FileAccess.file_exists(path + ".tmp." + tag)):
		return
	delete_save(slot)
	for file in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(file + "." + tag):
			DirAccess.rename_absolute(_abs(file + "." + tag), _abs(file))


func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)


func _slot(slot: int) -> int:
	return clampi(current_slot if slot < 0 else slot, 0, SLOT_COUNT - 1)
