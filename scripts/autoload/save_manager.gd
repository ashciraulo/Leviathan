extends Node
## Save slots as JSON files in user://. Three slots; the prototype uses one.
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


func delete_save(slot: int = -1) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


func _slot(slot: int) -> int:
	return clampi(current_slot if slot < 0 else slot, 0, SLOT_COUNT - 1)
