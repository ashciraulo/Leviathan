class_name PseudoText
## Long-text check for the screenshot tests: with LEVIATHAN_PSEUDO=1 every
## string is stretched by 40% and bracketed (Godot's pseudolocalisation),
## a quick stand-in for longer translations.


static func requested() -> bool:
	return OS.get_environment("LEVIATHAN_PSEUDO") == "1"


static func enable() -> void:
	ProjectSettings.set_setting("internationalization/pseudolocalization/replace_with_accents", false)
	ProjectSettings.set_setting("internationalization/pseudolocalization/double_vowels", false)
	ProjectSettings.set_setting("internationalization/pseudolocalization/fake_bidi", false)
	ProjectSettings.set_setting("internationalization/pseudolocalization/override", false)
	ProjectSettings.set_setting("internationalization/pseudolocalization/expansion_ratio", 0.4)
	ProjectSettings.set_setting("internationalization/pseudolocalization/prefix", "[")
	ProjectSettings.set_setting("internationalization/pseudolocalization/suffix", "]")
	TranslationServer.pseudolocalization_enabled = true
	TranslationServer.reload_pseudolocalization()
