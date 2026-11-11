"""Builds a cue's .flp from a template saved in FL Studio.

    flpenv/bin/python music/flp/flp_build.py --template T.flp --cue region_saltmarrow \
        --out region_saltmarrow.flp [--pattern 1] [--map music/flp/maps/<cue>.json]

The template is an .flp Ash's FL saved with every channel the cue needs:
plugin and preset loaded, its own mixer insert, the FabFilter chain on the
master, and pattern 1 holding at least one note per channel (FL only writes
a notes block for a pattern that has notes). Channel names must match the
cue's part names (guitar_nylon, flute_wood ...) or be mapped in --map.

The build writes every part's notes into the pattern, sets the tempo and
stretches the pattern's playlist clip to the cue's exact end, then reopens
the result to check the note counts. Everything else in the template (presets,
mixer, automation) is kept byte for byte. PyFLP (Python 3.10) is used only to
read channel names; writing goes through flp_raw.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

import mido

HERE = os.path.dirname(os.path.abspath(__file__))
MUSIC = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import flp_raw  # noqa: E402


def channel_names(path: str) -> dict[str, int]:
    """Channel display name -> rack index (the note's rack_channel)."""
    import pyflp
    project = pyflp.parse(path)
    return {ch.name: ch.iid for ch in project.channels if ch.name}


def midi_notes(path: str, scale: float) -> list[tuple[int, int, int, int]]:
    """(start_tick, length_tick, key, velocity) from a type-0 part file."""
    mf = mido.MidiFile(path)
    t, on, out = 0, {}, []
    for msg in mf.tracks[0]:
        t += msg.time
        if msg.type == "note_on" and msg.velocity:
            on[msg.note] = (t, msg.velocity)
        elif msg.type in ("note_off", "note_on") and msg.note in on:
            start, vel = on.pop(msg.note)
            out.append((round(start * scale), max(1, round((t - start) * scale)), msg.note, vel))
    return out


def build(template: str, cue: str, out: str, pattern: int = 1, mapping: dict | None = None,
          transpose: dict | None = None, audition: str | None = None) -> dict:
    """audition: a part name; its notes go to EVERY channel whose name starts
    with "aud" (aud1..aud6), so one split render compares six presets."""
    meta = json.load(open(os.path.join(MUSIC, "midi", cue, "cue.json")))
    flp = flp_raw.Flp.load(template)
    names = channel_names(template)
    scale = flp.ppq / meta["ppq"]
    notes, counts = [], {}
    if audition:
        targets = [(audition, n) for n in sorted(names) if n.lower().startswith("aud")]
        if not targets:
            raise SystemExit("audition template needs channels named aud1, aud2 ...")
    else:
        targets = [(part["name"], (mapping or {}).get(part["name"], part["name"])) for part in meta["parts"]]
    for part_name, name in targets:
        if name not in names:
            raise SystemExit(f"template has no channel named {name!r} (has {sorted(names)})")
        # Keyed by part or by channel name; when they are the same name, count it once.
        t = transpose or {}
        shift = t.get(part_name, t.get(name, 0)) if part_name == name else t.get(part_name, 0) + t.get(name, 0)
        part_notes = midi_notes(os.path.join(MUSIC, "midi", cue, part_name + ".mid"), scale)
        for start, length, key, vel in part_notes:
            # FL velocity runs 0-128 with 100 as default; MIDI 127 maps to 128.
            notes.append((start, names[name], length, key + shift, min(128, round(vel * 128 / 127)), 64))
        counts[names[name]] = counts.get(names[name], 0) + len(part_notes)
    flp.set_notes(pattern, notes)
    if not audition:  # mapped channels take the part's name, so the .flp reads plainly in FL
        for part_name, name in targets:
            if name != part_name:
                flp.rename_channel(names[name], part_name)
    if not flp.find(flp_raw.TEMPO):
        raise SystemExit("template has no tempo event")
    flp.set_tempo(meta["qbpm"])
    end = round(meta["end_q"] * flp.ppq)
    clips = flp.set_pattern_clips(pattern, end)
    if clips == 0:
        raise SystemExit(f"pattern {pattern} has no clip in the playlist; place it at bar 1 in the template")
    flp.save(out)
    # Reopen and verify what FL will load.
    check = flp_raw.Flp.load(out)
    got = {}
    for n in check.get_notes(pattern):
        got[n[2]] = got.get(n[2], 0) + 1
    assert got == counts, f"note counts differ after save: {got} vs {counts}"
    return {"out": out, "notes": sum(counts.values()), "per_channel": counts, "tempo": meta["qbpm"],
            "clips": clips, "end_ticks": end}


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--template", required=True)
    ap.add_argument("--cue", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--pattern", type=int, default=1)
    ap.add_argument("--map", help="json: {part name: channel name}")
    ap.add_argument("--transpose", help="json: {part or channel name: semitones}, for presets measured off-octave")
    ap.add_argument("--audition", help="part name to copy onto every aud* channel")
    a = ap.parse_args()
    print(json.dumps(build(a.template, a.cue, a.out, a.pattern,
                           json.load(open(a.map)) if a.map else None,
                           json.load(open(a.transpose)) if a.transpose else None, a.audition), indent=1))
