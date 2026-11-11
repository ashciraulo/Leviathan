"""Small helpers the cue scripts share."""
from __future__ import annotations

import sys

from mtk import seq, bass_of

GATE = "--gate" in sys.argv


def bars(text: str, per_bar: float = 4.0, unit: float = 1.0):
    """seq() over '|'-separated bars, checking every bar adds up to per_bar quarters."""
    for i, chunk in enumerate(text.split("|")):
        total = sum(d for _, d in seq(chunk)) * unit
        assert abs(total - per_bar) < 1e-6, f"bar {i + 1} has {total}: {chunk.strip()}"
    return seq(text.replace("|", ""), unit)


def low_root(sym: str, lowest: int) -> int:
    """The chord's bass note at or just above `lowest`."""
    return lowest + (bass_of(sym) - lowest) % 12


def sections(table):
    """sections([("A", 0), ("B", 16)]) -> a function bar -> section name."""
    return lambda b: [k for k, v in table if v <= b][-1]


def gate(song, chords, melody, comp, label):
    if GATE:
        from gate_midi import check
        for problem in check(song, chords, melody=melody, comp=comp):
            print(f"GATE {label}:", problem)
