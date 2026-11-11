"""Music toolkit for Leviathan's per-cue MIDI scripts.

A cue script builds a Song out of Parts, one Part per FL channel, and calls
song.save(). That writes music/midi/<cue>/<part>.mid for FL (type 0, one
track, 96 ppq, always 4/4 in the file) plus <cue>.mid with every part for
listening, and, with --preview, a rough sketch render (numpy synth, no FL)
to check notes, form and the loop seam in the cloud.

Positions and lengths are in quarter notes unless a name says otherwise.
Bars are bars of the cue's own meter (Song.bar_q quarters each).
"""
from __future__ import annotations

import json
import os
import random
import subprocess
import sys

import mido

MUSIC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(MUSIC)
PPQ = 96
sys.path.insert(0, MUSIC)

NOTE_NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def n(name: str) -> int:
    """'C4' -> 60, 'Bb3' -> 58, 'F#5' -> 78."""
    letter, rest = name[0].upper(), name[1:]
    acc = 0
    while rest and rest[0] in "#b":
        acc += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + NOTE_NAMES[letter] + acc


CHORD_SHAPES = {"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
                "maj7": [0, 4, 7, 11], "sus4": [0, 5, 7], "sus2": [0, 2, 7], "dim": [0, 3, 6],
                "add9": [0, 4, 7, 14], "madd9": [0, 3, 7, 14], "5": [0, 7]}


def chord(sym: str) -> tuple[int, list[int]]:
    """'Dm' -> (2, [0, 3, 7]); 'F/A' -> root F, shape, and bass in Song.bass_of."""
    sym = sym.split("/")[0]
    root = sym[0]
    i = 1
    while i < len(sym) and sym[i] in "#b":
        i += 1
    pc = (NOTE_NAMES[root] + sym[1:i].count("#") - sym[1:i].count("b")) % 12
    return pc, CHORD_SHAPES[sym[i:]]


def bass_of(sym: str) -> int:
    """Pitch class of the chord's bass note (the slash note if there is one)."""
    if "/" in sym:
        return chord(sym.split("/")[1])[0]
    return chord(sym)[0]


def voicing(sym: str, low: int, high: int, top: int | None = None) -> list[int]:
    """Every chord tone between low and high; if top is given, the voicing whose
    highest note is closest to it (keeps comping under the melody)."""
    pc, shape = chord(sym)
    pcs = {(pc + s) % 12 for s in shape}
    notes = [m for m in range(low, high + 1) if m % 12 in pcs]
    if top is not None:
        notes = [m for m in notes if m <= top]
    return notes


def seq(text: str, unit: float = 1.0) -> list[tuple[int | None, float]]:
    """'C5:2 A4:1 r:3 F4' -> [(72, 2*unit), (69, unit), (None, 3*unit), (65, unit)]."""
    out = []
    for tok in text.split():
        name, _, dur = tok.partition(":")
        d = float(dur) if dur else 1.0
        out.append((None if name in ("r", "-") else n(name), d * unit))
    return out


class Part:
    def __init__(self, name: str, program: int = 0, channel: int = 0, vel: int = 80):
        self.name, self.program, self.channel, self.vel = name, program, channel, vel
        self.notes: list[list] = []  # [start_q, dur_q, pitch, velocity]

    def note(self, start: float, dur: float, pitch: int, vel: int | None = None) -> None:
        self.notes.append([start, dur, pitch, vel or self.vel])

    def line(self, start: float, items, vel: int | None = None, legato: float = 0.95,
             accent=None) -> float:
        """Plays seq() items from start; returns the position after the last one."""
        t = start
        for i, (pitch, d) in enumerate(items):
            if pitch is not None:
                v = vel or self.vel
                if accent:
                    v = accent(i, t, v)
                self.note(t, d * legato, pitch, v)
            t += d
        return t

    def chord(self, start: float, dur: float, pitches, vel: int | None = None, roll: float = 0.0) -> None:
        for i, p in enumerate(sorted(pitches)):
            self.note(start + i * roll, dur - i * roll, p, vel)

    def humanize(self, seed: int, time_q: float = 0.012, vel: int = 6) -> "Part":
        """Small, repeatable timing and velocity spread (never before 0)."""
        rnd = random.Random(seed)
        for nt in self.notes:
            nt[0] = max(0.0, nt[0] + rnd.uniform(-time_q, time_q))
            nt[3] = max(1, min(127, nt[3] + rnd.randint(-vel, vel)))
        return self

    def trimmed(self) -> list[list]:
        """Notes sorted, with same-pitch overlaps cut (they cut each other in FL)."""
        notes = sorted(self.notes, key=lambda x: (x[0], x[2]))
        last: dict[int, list] = {}
        out = []
        for nt in notes:
            prev = last.get(nt[2])
            if prev and nt[0] - prev[0] < 0.03:  # the same note twice at once: keep one
                prev[1], prev[3] = max(prev[1], nt[1]), max(prev[3], nt[3])
                continue
            if prev and prev[0] + prev[1] > nt[0] - 0.01:
                prev[1] = max(0.02, nt[0] - prev[0] - 0.01)
            last[nt[2]] = nt
            out.append(nt)
        return out


class Song:
    def __init__(self, cue_id: str, spec: dict | None = None):
        if spec is None:
            from track_sheet import CUES
            spec = {c["id"]: c for c in CUES}[cue_id]
        self.id, self.spec = cue_id, spec
        meter = spec["meter"]
        # Quarters per bar, and the quarter-note tempo FL is set to.
        self.bar_q = {"3/4": 3, "4/4": 4, "6/8": 3, "12/8": 6, "5/4": 5, "7/8": 3.5}[meter]
        self.qbpm = spec["tempo"] * (1.5 if meter in ("6/8", "12/8") else 1.0)
        self.bars, self.intro_bars = spec["bars"], spec["intro_bars"]
        self.parts: list[Part] = []

    def part(self, *a, **k) -> Part:
        p = Part(*a, **k)
        p.channel = len(self.parts) % 16
        self.parts.append(p)
        return p

    def bar(self, b: int) -> float:
        """Start of bar b (0-based) in quarters."""
        return b * self.bar_q

    @property
    def end_q(self) -> float:
        return self.bars * self.bar_q

    @property
    def intro_q(self) -> float:
        return self.intro_bars * self.bar_q

    def seconds(self, q: float) -> float:
        return q * 60.0 / self.qbpm

    # --- files ---
    def _track(self, part: Part | None, parts: list[Part]) -> mido.MidiTrack:
        tr = mido.MidiTrack()
        tr.append(mido.MetaMessage("track_name", name=part.name if part else self.id, time=0))
        tr.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(self.qbpm), time=0))
        tr.append(mido.MetaMessage("time_signature", numerator=4, denominator=4, time=0))
        events = []
        for p in parts:
            events.append((0, 0, mido.Message("program_change", program=p.program, channel=p.channel)))
            for start, dur, pitch, vel in p.trimmed():
                on = round(start * PPQ)
                off = max(on + 1, min(round((start + dur) * PPQ), round(self.end_q * PPQ)))
                events.append((on, 2, mido.Message("note_on", note=pitch, velocity=int(vel), channel=p.channel)))
                events.append((off, 1, mido.Message("note_off", note=pitch, velocity=0, channel=p.channel)))
        events.sort(key=lambda e: (e[0], e[1]))
        t = 0
        for tick, _, msg in events:
            tr.append(msg.copy(time=tick - t))
            t = tick
        end = round(self.end_q * PPQ)
        tr.append(mido.MetaMessage("end_of_track", time=max(0, end - t)))
        return tr

    def save(self, preview: bool | None = None) -> str:
        out = os.path.join(MUSIC, "midi", self.id)
        os.makedirs(out, exist_ok=True)
        for f in os.listdir(out):
            if f.endswith(".mid"):
                os.remove(os.path.join(out, f))
        for p in self.parts:
            mf = mido.MidiFile(type=0, ticks_per_beat=PPQ)
            mf.tracks.append(self._track(p, [p]))
            mf.save(os.path.join(out, f"{p.name}.mid"))
        mf = mido.MidiFile(type=0, ticks_per_beat=PPQ)
        mf.tracks.append(self._track(None, self.parts))
        mf.save(os.path.join(out, f"{self.id}.mid"))
        meta = {"cue": self.id, "qbpm": self.qbpm, "bar_q": self.bar_q, "bars": self.bars,
                "intro_q": self.intro_q, "end_q": self.end_q, "ppq": PPQ,
                "intro_s": self.seconds(self.intro_q), "loop_end_s": self.seconds(self.end_q),
                "loop": self.spec["loop"],
                "parts": [{"name": p.name, "notes": len(p.trimmed()), "low": min(x[2] for x in p.notes),
                           "high": max(x[2] for x in p.notes)} for p in self.parts if p.notes]}
        with open(os.path.join(out, "cue.json"), "w") as f:
            json.dump(meta, f, indent=1)
        if preview is None:
            preview = "--preview" in sys.argv
        if preview:
            import sketch
            sketch.render(self, out)
        print(f"{self.id}: {len(self.parts)} parts, {sum(len(p.notes) for p in self.parts)} notes, "
              f"{self.seconds(self.end_q):.1f} s -> {os.path.relpath(out, ROOT)}")
        return out


def lullaby() -> list[list[tuple[int, float]]]:
    """The seven phrases as [(midi, beats)], from audio/music/lullaby.json."""
    with open(os.path.join(ROOT, "audio", "music", "lullaby.json")) as f:
        data = json.load(f)
    return [[(p, b) for p, b in ph] for ph in data["phrases"]]


def phrase_items(index: int, transpose: int = 0, beat: float = 1.0) -> list[tuple[int, float]]:
    """Lullaby phrase index (0-6) as seq()-style items, each 3/4 beat = `beat` quarters."""
    return [(p + transpose, b * beat) for p, b in lullaby()[index]]
