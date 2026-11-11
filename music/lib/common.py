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


def harmonize(notes, bar_q: float, bars_count: int, candidates: list[str], start_bar: int = 0) -> list[str]:
    """One chord per bar for a melody (e.g. a stretched lullaby): the candidate
    whose tones cover the most melody time in that bar, never one that rubs a
    semitone against a held note; ties go to the earlier candidate, and a
    change of chord beats repeating the previous bar's."""
    from mtk import chord
    out = []
    for b in range(start_bar, start_bar + bars_count):
        lo, hi = b * bar_q, (b + 1) * bar_q
        weights = {}
        for start, dur, pitch in notes:
            overlap = min(hi, start + dur) - max(lo, start)
            if overlap > 0:
                # A note struck in this bar counts its whole length: it rings here.
                weights[pitch % 12] = weights.get(pitch % 12, 0) + (dur if lo <= start < hi else overlap)
        best, best_score = candidates[0], -1e9
        for i, sym in enumerate(candidates):
            pc, shape = chord(sym)
            tones = {(pc + s) % 12 for s in shape}
            score = sum(w for p, w in weights.items() if p in tones)
            score -= sum(2 * w for p, w in weights.items() if p not in tones and w >= 0.9 and
                         any((p - t) % 12 in (1, 11) for t in tones))
            score -= 0.01 * i + (0.3 if out and out[-1] == sym else 0)
            if score > best_score:
                best, best_score = sym, score
        out.append(best)
    return out
