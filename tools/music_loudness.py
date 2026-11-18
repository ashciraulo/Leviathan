"""Measures every music cue's loudness against its target in the track sheet.

    python3 tools/music_loudness.py [cue ...]

The game plays music files as they are (Audio adds no per-cue gain; only the
player's Music volume and fades/ducking), so a cue's loudness in game is the
file's own. For each audio/music/<cue>.ogg this reads the integrated loudness
(EBU R128, LUFS) and true peak with ffmpeg, and fails when a cue is more than
TOLERANCE LU from music/track_sheet.json's "lufs", peaks above PEAK_MAX dBFS,
or is missing. Run it on each new cue PR. Needs ffmpeg.
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOLERANCE = 1.0
PEAK_MAX = -1.0


def measure(path):
    out = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true", "-f", "null", "-"],
        capture_output=True, text=True).stderr
    lufs = re.findall(r"I:\s+(-?[\d.]+) LUFS", out)
    peak = re.findall(r"Peak:\s+(-?[\d.]+) dBFS", out)
    return (float(lufs[-1]) if lufs else None, float(peak[-1]) if peak else None)


def main():
    with open(os.path.join(ROOT, "music", "track_sheet.json")) as f:
        cues = json.load(f)["cues"]
    only = set(sys.argv[1:])
    bad = 0
    for cue in cues:
        cid, target = cue["id"], cue.get("lufs")
        if only and cid not in only:
            continue
        path = os.path.join(ROOT, "audio", "music", cid + ".ogg")
        if not os.path.exists(path):
            print("%-22s MISSING" % cid)
            bad += 1
            continue
        lufs, peak = measure(path)
        notes = []
        if lufs is None:
            notes.append("can't measure")
        elif target is not None and abs(lufs - target) > TOLERANCE:
            notes.append("%+.1f LU off target" % (lufs - target))
        if peak is not None and peak > PEAK_MAX:
            notes.append("peak over %.0f dBFS" % PEAK_MAX)
        print("%-22s target %6s  measured %6s LUFS  peak %6s dBFS  %s" % (
            cid, target, lufs, peak, "<-- " + ", ".join(notes) if notes else "ok"))
        bad += bool(notes)
    print("Music loudness: %s" % ("OK" if not bad else "%d cue(s) off" % bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
