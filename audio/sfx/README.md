# Sound effects

The `.wav` files here are made by `tools/sfx_gen.py` (layered synth voices
in pure Python): run `python3 tools/sfx_gen.py` after changing a sound there,
and `tools/check.sh` fails if a file is out of date. Every id also needs an
entry in `Audio.SFX` (scripts/autoload/audio.gd), which holds its caption
and a tiny fallback synth.

To replace a sound with a hand-made one, drop `<id>.ogg` here (an `.ogg`
wins over the `.wav`) and remove that id from `SOUNDS` in the generator.
