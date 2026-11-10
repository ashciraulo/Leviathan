class_name BootCheck
extends Node
## A shipped build's self-test, for CI: run the game with
##     Leviathan -- --boot-check=<file>
## and it goes from the title screen into a new game on its own (the real
## new-file path: save, load the start, the opening), waits there a moment,
## writes "BOOT OK" or "BOOT FAILED: <why>" to <file>, and quits (exit code
## 0 or 1). Without the argument nothing happens.

const ARG := "--boot-check="
## Seconds on the title screen, then in the game, before the verdict.
const TITLE_TIME := 1.0
const GAME_TIME := 3.0
## Give up if the game hasn't come up by then.
const TIMEOUT := 30.0
## The file it plays in; a real file there is set aside and put back.
const SLOT := 2

var _out := ""
var _title: Node
## True once a real file in SLOT is set aside (only then may it be wiped).
var _aside := false


## Called by the title screen once it is up.
static func run_if_asked(title: Node) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(ARG):
			var check := BootCheck.new()
			check._out = arg.substr(ARG.length())
			check._title = title
			check.process_mode = Node.PROCESS_MODE_ALWAYS
			title.get_tree().root.add_child.call_deferred(check)
			return


func _ready() -> void:
	print("Boot check: title screen up (%s, %s)" % [OS.get_name(), Engine.get_version_info()["string"]])
	await get_tree().create_timer(TITLE_TIME, true, false, true).timeout
	if not is_instance_valid(_title) or not _title.has_method("_on_file_chosen"):
		_finish(false, "the title screen went away")
		return
	SaveManager.set_aside(SLOT, "bootcheck")
	_aside = true
	_title.call("_on_file_chosen", SLOT, true)
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		var game := get_tree().current_scene
		if game and game.get("current_room") != null and game.get("player") != null:
			await get_tree().create_timer(GAME_TIME, true, false, true).timeout
			if not is_instance_valid(game) or game.get("player") == null:
				_finish(false, "the game closed again")
				return
			if not SaveManager.has_save(SLOT):
				_finish(false, "the new file wasn't saved")
				return
			_finish(true, "")
			return
	_finish(false, "the game never started (no room or no Wren)")


func _finish(ok: bool, why: String) -> void:
	if _aside:
		SaveManager.delete_save(SLOT)
		SaveManager.restore_aside(SLOT, "bootcheck")
	var verdict := "BOOT OK" if ok else "BOOT FAILED: " + why
	print("Boot check: " + verdict)
	var file := FileAccess.open(_out, FileAccess.WRITE)
	if file:
		file.store_line(verdict)
		file.close()
	else:
		printerr("Boot check: can't write %s" % _out)
	get_tree().quit(0 if ok else 1)
