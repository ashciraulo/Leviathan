class_name SaveTransfer
extends Node
## Moves a save file between the game and the player's device, so a journey
## outlives a cleared browser and can travel between the web and PC builds.
## In a browser, Export downloads a .json file and Import opens the
## browser's file picker. On desktop both use the system's file dialog.
## Where neither exists (a headless run), the file select hides the buttons.

## An export or import ended. note is the text key to show ("" for none:
## the player cancelled).
signal finished(note: String)

## Imports bigger than this aren't saves (a real one is a few kilobytes).
const MAX_IMPORT_BYTES := 1 << 20

## Tests set this to run without a browser or a file dialog: exports land in
## last_export and imports read test_import ("" acts like a cancel).
var test_mode := false
var last_export := ""
var test_import := ""

var _import_slot := -1


static func available() -> bool:
	return OS.has_feature("web") or DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE)


func busy() -> bool:
	return _import_slot >= 0


func export_slot(slot: int) -> void:
	var text := SaveManager.export_text(slot)
	if text == "":
		finished.emit("FILES_DAMAGED")
		return
	var file_name := SaveManager.export_file_name(slot)
	if test_mode:
		last_export = text
		finished.emit("FILES_EXPORTED")
	elif OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, "application/json")
		finished.emit("FILES_EXPORTED")
	else:
		DisplayServer.file_dialog_show(tr("FILES_EXPORT"), OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), file_name,
			false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, PackedStringArray(["*.json"]),
			func(ok: bool, paths: PackedStringArray, _filter: int) -> void: _write_export.call_deferred(ok, paths, text))


## Asks for a save file and puts it into slot (an empty one). finished
## follows once the player picks one or gives up.
func import_to(slot: int) -> void:
	_import_slot = slot
	if test_mode:
		_take_import.call_deferred(test_import, test_import == "")
	elif OS.has_feature("web"):
		# A browser opens its file picker only right after a key press, click
		# or tap; a gamepad press doesn't count. So after a pad press, say so
		# instead of asking for a picker the browser would quietly refuse.
		var opened = JavaScriptBridge.eval("""(function(){
			if (%s && navigator.userActivation && !navigator.userActivation.isActive) return false;
			window.__lvImport = {state: 'wait', text: ''};
			var input = document.createElement('input');
			input.type = 'file';
			input.accept = '.json,application/json';
			// In the page (hidden): some browsers won't open a detached picker.
			input.style.display = 'none';
			document.body.appendChild(input);
			var done = function(){ if (input.parentNode) input.parentNode.removeChild(input); };
			// Each pick gets its own record, so a late event from an
			// abandoned picker never touches a newer one (or a null).
			var mine = window.__lvImport;
			var settle = function(state, text){ if (window.__lvImport === mine) window.__lvImport = {state: state, text: text || ''}; };
			input.addEventListener('cancel', function(){ done(); settle('cancel'); });
			input.addEventListener('change', function(){
				done();
				var f = input.files && input.files[0];
				if (!f || f.size > %d) { settle(f ? 'bad' : 'cancel'); return; }
				f.text().then(function(t){ settle('done', t); }, function(){ settle('bad'); });
			});
			input.click();
			return true;
		})()""" % ["true" if Settings.using_pad else "false", MAX_IMPORT_BYTES], true)
		if not opened:
			_import_slot = -1
			finished.emit("FILES_IMPORT_NEEDS_TOUCH")
	else:
		DisplayServer.file_dialog_show(tr("FILES_IMPORT"), OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), "",
			false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.json"]),
			func(ok: bool, paths: PackedStringArray, _filter: int) -> void: _read_import.call_deferred(ok, paths))


func _process(_delta: float) -> void:
	if not busy() or test_mode or not OS.has_feature("web"):
		return
	var state = JavaScriptBridge.eval("window.__lvImport ? window.__lvImport.state : 'cancel'", true)
	match str(state):
		"done":
			_take_import(str(JavaScriptBridge.eval("window.__lvImport.text", true)))
		"cancel":
			_take_import("", true)
		"bad":
			_import_slot = -1
			finished.emit("FILES_IMPORT_BAD")


## The player gives up waiting for the picker (say, they closed it in a way
## the browser didn't report).
func cancel() -> void:
	_import_slot = -1
	if OS.has_feature("web") and not test_mode:
		JavaScriptBridge.eval("window.__lvImport = null", true)


## The picked file's text, or cancelled when the player picked nothing.
func _take_import(text: String, cancelled: bool = false) -> void:
	if not busy():
		return
	var slot := _import_slot
	_import_slot = -1
	if cancelled:
		finished.emit("")
		return
	var why := SaveManager.import_text(text, slot)
	finished.emit("FILES_IMPORTED" if why == "" else why)


func _read_import(ok: bool, paths: PackedStringArray) -> void:
	if not busy():
		return
	if not ok or paths.is_empty():
		_take_import("", true)
		return
	var file := FileAccess.open(paths[0], FileAccess.READ)
	if file == null or file.get_length() > MAX_IMPORT_BYTES:
		_import_slot = -1
		finished.emit("FILES_IMPORT_BAD")
		return
	_take_import(file.get_as_text())


func _write_export(ok: bool, paths: PackedStringArray, text: String) -> void:
	if not ok or paths.is_empty():
		finished.emit("")
		return
	var path := paths[0]
	if not path.to_lower().ends_with(".json"):
		path += ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		finished.emit("FILES_EXPORT_FAILED")
		return
	file.store_string(text)
	file.close()
	finished.emit("FILES_EXPORTED")
