# Music source

The soundtrack is composed as code and finished in FL Studio. The game only
sees the results in `audio/music/` (see that folder's README for when each cue
plays). Godot ignores this folder (`.gdignore`).

- `track_sheet.py`: the plan. Key, tempo, meter, form, palette, lullaby use,
  loudness and loop plan for every cue. `python3 music/track_sheet.py` writes
  `TRACK_SHEET.md` and `track_sheet.json` and fails if neighbouring cues share
  a key or tempo, or two loops share a form.
- `cues/tNN_<cue>.py`: hand-written MIDI, one script per cue (or family).
  `--gate` runs the writing checks, `--preview` renders a rough numpy sketch
  (`midi/<cue>/<cue>_sketch.mp3`, not committed) with the loop played twice.
- `midi/<cue>/`: one type-0 MIDI per FL channel, 96 ppq, always 4/4 in the
  file, plus `cue.json` (tempo, loop points, part ranges).
- `flp/`: `flp_build.py` writes a cue's notes, tempo and clip length into a
  template .flp saved in FL (PyFLP on Python 3.10 reads channel names;
  `flp_raw.py` writes, byte for byte otherwise).
- `post/gate_stems.py`: checks FL's split stems against the MIDI (octave,
  tuning, per-note pitch, evenness, stray sound) before mixing.
- `post/finalize.py`: master render -> loop-folded OGG in `audio/music/`,
  with loudness, true-peak and seam checks and the loop offset in `.import`.

Every finished cue keeps an editable .flp on Ash's PC that renders the final
audio by itself; nothing is mixed outside FL.
