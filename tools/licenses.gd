## Writes THIRD_PARTY_LICENSES.txt: the Godot Engine's license and the
## copyright and license of every part built into it (FreeType, ENet, Mbed
## TLS...). Run again after changing Godot version:
##     godot --headless -s tools/licenses.gd -- THIRD_PARTY_LICENSES.txt
extends SceneTree
func _init() -> void:
	var out := "Leviathan is made with the Godot Engine (godotengine.org).\n\n"
	out += "== Godot Engine ==\n\n" + Engine.get_license_text() + "\n"
	out += "== Third-party components in the Godot Engine ==\n\n"
	for part: Dictionary in Engine.get_copyright_info():
		out += "-- %s --\n" % part["name"]
		for piece: Dictionary in part["parts"]:
			for line: String in piece["copyright"]:
				out += "Copyright %s\n" % line
			out += "License: %s\n" % piece["license"]
		out += "\n"
	out += "== License texts ==\n\n"
	var infos := Engine.get_license_info()
	var names := infos.keys()
	names.sort()
	for name: String in names:
		out += "-- %s --\n\n%s\n\n" % [name, infos[name]]
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(out)
	f.close()
	quit()
