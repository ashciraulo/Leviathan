#!/usr/bin/env python3
"""Checks that the game's music hooks agree with the soundtrack plan.

    python3 tools/check_music.py

- Audio.MUSIC_CUES (scripts/autoload/audio.gd) lists exactly the cues in
  music/track_sheet.json.
- Audio.ONE_SHOT_MUSIC is exactly the cues the sheet plays once.
- Each audio/music/<cue>.ogg.import agrees with the sheet: a cue played once
  is not set to loop, and a loop offset other than 0 is the cue's intro
  length (music/midi/<cue>/cue.json, exact; else the sheet's, rounded) and
  lies inside the file.

music/post/finalize.py --write sets those import settings; this catches a
delivered track (or a changed plan) that the game would play wrong.
Exits 1 and lists every problem, or prints a one-line summary.
"""

import json
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_GD = os.path.join(ROOT, "scripts", "autoload", "audio.gd")
SHEET = os.path.join(ROOT, "music", "track_sheet.json")
MUSIC_DIR = os.path.join(ROOT, "audio", "music")
# How far a loop offset may sit from the sheet's intro length, in seconds.
OFFSET_TOLERANCE = 0.01
# A file this close to the cue's intro + loop length is taken as delivered.
DELIVERED_TOLERANCE = 0.5


def gd_list(text: str, name: str) -> list:
    m = re.search(r"const %s := \[(.*?)\]" % name, text, re.S)
    if not m:
        raise SystemExit(f"{name} not found in {AUDIO_GD}")
    return re.findall(r'"([^"]+)"', m.group(1))


def ogg_seconds(path: str) -> float:
    """Length of an OGG Vorbis file: the last page's granule position over the
    sample rate from the identification header."""
    data = open(path, "rb").read()
    head = data.find(b"\x01vorbis")
    if head < 0:
        raise ValueError("no Vorbis header")
    rate = struct.unpack_from("<I", data, head + 12)[0]
    last = data.rfind(b"OggS")
    granule = struct.unpack_from("<q", data, last + 6)[0]
    return granule / rate


def intro_seconds(cue: str, spec: dict) -> float:
    """The cue's intro length: exact from its cue.json (what finalize.py
    writes), else the sheet's rounded figure."""
    meta = os.path.join(ROOT, "music", "midi", cue, "cue.json")
    if os.path.exists(meta):
        intro = json.load(open(meta, encoding="utf-8")).get("intro_s")
        if intro is not None:
            return float(intro)
    return float(spec["intro_s"])


def import_params(path: str) -> dict:
    params = {}
    section = ""
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line.startswith("["):
            section = line
        elif section == "[params]" and "=" in line:
            key, value = line.split("=", 1)
            params[key] = value
    return params


def main() -> int:
    gd = open(AUDIO_GD, encoding="utf-8").read()
    sheet = json.load(open(SHEET, encoding="utf-8"))
    cues = {c["id"]: c for c in sheet["cues"]}
    problems = []

    listed = gd_list(gd, "MUSIC_CUES")
    for cue in sorted(set(cues) - set(listed)):
        problems.append(f"{cue}: in the track sheet but not in Audio.MUSIC_CUES")
    for cue in sorted(set(listed) - set(cues)):
        problems.append(f"{cue}: in Audio.MUSIC_CUES but not in the track sheet")

    once = {cue for cue, c in cues.items() if not c["loop"]}
    one_shot = set(gd_list(gd, "ONE_SHOT_MUSIC"))
    for cue in sorted(once - one_shot):
        problems.append(f"{cue}: the sheet plays it once, but it isn't in Audio.ONE_SHOT_MUSIC (the game would loop it)")
    for cue in sorted(one_shot - once):
        problems.append(f"{cue}: in Audio.ONE_SHOT_MUSIC, but the sheet loops it")

    checked = 0
    for cue, spec in sorted(cues.items()):
        ogg = os.path.join(MUSIC_DIR, cue + ".ogg")
        imp = ogg + ".import"
        if not os.path.exists(ogg):
            continue
        if not os.path.exists(imp):
            problems.append(f"{cue}.ogg has no .import file (open the project in Godot once)")
            continue
        checked += 1
        params = import_params(imp)
        loop = params.get("loop", "false") == "true"
        offset = float(params.get("loop_offset", "0") or 0)
        if not spec["loop"] and loop:
            problems.append(f"{cue}.ogg is set to loop, but the sheet plays it once")
        # A delivered track (as long as the cue's intro and loop) with an intro
        # must loop back past it; a placeholder of another length may not.
        intro = intro_seconds(cue, spec)
        if spec["loop"] and intro > 0 and offset == 0:
            length = ogg_seconds(ogg)
            if abs(length - (intro + spec["body_s"])) < DELIVERED_TOLERANCE:
                problems.append(f"{cue}.ogg has a {intro:.3f} s intro but loops back to 0 (run finalize.py --write)")
        if offset > 0:
            length = ogg_seconds(ogg)
            if abs(offset - intro) > OFFSET_TOLERANCE:
                problems.append(f"{cue}.ogg loops back to {offset:.3f} s, but its intro is {intro:.3f} s")
            if offset >= length:
                problems.append(f"{cue}.ogg loops back to {offset:.3f} s, past its end ({length:.3f} s)")

    if problems:
        for p in problems:
            print("MUSIC: " + p)
        return 1
    print(f"Music OK: {len(cues)} cues match the track sheet, {checked} files checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
