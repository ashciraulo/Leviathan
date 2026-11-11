"""Writing gates on a cue's MIDI before anything reaches FL.

python3 music/lib/gate_midi.py <cue> --chords-from <script>  (called by cue scripts via check())

Checks: held melody notes that clash with the chord (a semitone above or below
a chord tone, held a quarter or longer on a strong beat), melody under the
comping's top voice, notes outside each part's playable range, same-pitch
overlaps, and that nothing sounds before 0 or after the cue's end.
"""
from __future__ import annotations

from mtk import chord

RANGES = {"flute": (60, 96), "reed": (53, 89), "guitar": (40, 84), "bass": (28, 60), "pad": (36, 79),
          "harp": (24, 103), "bell": (48, 96), "cello": (36, 76), "piano": (21, 108),
          "musicbox": (60, 100), "bassclarinet": (38, 77), "clarinet": (50, 91), "marimba": (45, 96),
          "kalimba": (60, 88), "epiano": (40, 96), "whistle": (62, 93), "mandolin": (55, 88), "celesta": (60, 108), "choir": (45, 81), "strings": (28, 96)}


def check(song, chords: list[str], melody=("flute", "reed"), comp=("guitar", "pad")) -> list[str]:
    problems = []
    bar_q = song.bar_q
    for p in song.parts:
        kind = p.name.split("_")[0]
        lo, hi = RANGES.get(kind, (0, 127))
        for start, dur, pitch, vel in p.notes:
            if not lo <= pitch <= hi:
                problems.append(f"{p.name}: note {pitch} at bar {int(start // bar_q) + 1} is outside {lo}-{hi}")
            if start < 0 or start > song.end_q - 0.01:
                problems.append(f"{p.name}: note at {start:.2f} runs outside the cue")
        if kind not in melody:
            continue
        for start, dur, pitch, vel in p.notes:
            if dur < 0.9:
                continue
            b = int((start + 0.05) // bar_q)
            pc, shape = chord(chords[b])
            tones = {(pc + s) % 12 for s in shape}
            on_beat = abs((start % bar_q) - round(start % bar_q / 1.5) * 1.5) < 0.05
            if pitch % 12 not in tones and any((pitch - t) % 12 in (1, 11) for t in tones) and on_beat:
                problems.append(f"{p.name}: held {pitch} ({dur:.1f} q) at bar {b + 1} rubs against {chords[b]}")
    comp_top = {}
    for p in song.parts:
        if p.name.split("_")[0] in comp:
            for start, dur, pitch, vel in p.notes:
                b = int((start + 0.05) // bar_q)
                comp_top[b] = max(comp_top.get(b, 0), pitch)
    for p in song.parts:
        if p.name.split("_")[0] in melody:
            for start, dur, pitch, vel in p.notes:
                b = int((start + 0.05) // bar_q)
                if dur >= 0.9 and pitch < comp_top.get(b, 0):
                    problems.append(f"{p.name}: held {pitch} at bar {b + 1} sits under the comping top {comp_top[b]}")
    return problems
