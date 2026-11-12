# Credits

The in-game credits roll (`scripts/ui/credits.gd`) shows the same.

## People

- **Direction:** Ash
- **Design, art and code:** Claude
- **Music:** Ash and Claude, made in FL Studio. Until a cue's FL Studio
  version is finished, a placeholder made in code by `tools/music_gen.py`
  plays in its place.
- **Sound effects and ambience:** Claude, made in code by
  `tools/sfx_gen.py`.

## Art and lettering

All pixel art is original to this project, drawn in code by the
`tools/*_art.py` scripts (`tools/build_art.py` runs them all). The Tide
lettering was drawn for Leviathan (`tools/font_glyphs.py`).

No third-party art, sound or music is used. If any is ever added, list it
here with its author, source link and license, and add it to the credits
roll.

## Engine and licenses

[Godot Engine](https://godotengine.org), MIT license, (c) the Godot Engine
contributors.

Godot carries parts by others (FreeType, ENet, Mbed TLS and more). Their
copyrights and licenses are in `THIRD_PARTY_LICENSES.txt`, which goes with
every download and with the web build. The credits roll names it and
carries FreeType's required notice. After changing the Godot version, run
`godot --headless -s tools/licenses.gd -- THIRD_PARTY_LICENSES.txt` again.
