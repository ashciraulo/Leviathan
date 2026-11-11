"""Ashfall (region_cinderreach) and The Bell Kiln (dungeon_kiln).

region_cinderreach: C# phrygian dominant, 4/4 at 116, 48 bars: intro 2 |
  A 16 (low string ostinato) | B 8 | A' 16 | breakdown 6. Lullaby phrase 2's
  degrees (1 b7 5 4: C# B G# F#) squared off into half notes on low brass.
  Loop from bar 3.
dungeon_kiln: E phrygian, 4/4 at 132, 64 bars: A 16 (anvil ostinato) | B 8
  (phrase 2 on brass: E D B A) | A' 16 | C 8 | B' 16 (phrase 2 in canon
  between brass and organ).

Run: python3 music/cues/t08_cinderreach_kiln.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of  # noqa: E402

GATE = "--gate" in sys.argv


def bars(text, per_bar=4):
    for i, chunk in enumerate(text.split("|")):
        total = sum(d for _, d in seq(chunk))
        assert abs(total - per_bar) < 1e-6, f"bar {i + 1} has {total}: {chunk.strip()}"
    return seq(text.replace("|", ""))


def low_root(sym, lowest):
    return lowest + (bass_of(sym) - lowest) % 12


def gate(song, chords, melody, comp, label):
    if GATE:
        from gate_midi import check
        for problem in check(song, chords, melody=melody, comp=comp):
            print(f"GATE {label}:", problem)


def sections(sec):
    return lambda b: [k for k, v in sec if v <= b][-1]


# ------------------------------------------------------------ cinderreach
song = Song("region_cinderreach")
ost = song.part("strings_ostinato", program=48, vel=78)
drums = song.part("drum_frame", program=0, vel=80)
brass = song.part("brass_low", program=57, vel=82)
anvil = song.part("perc_anvil", program=0, vel=52)
pad = song.part("pad_dark", program=91, vel=40)
lead = song.part("reed_low", program=68, vel=74)
INTRO = ["C#", "C#"]
A = ["C#", "C#", "D", "C#", "C#", "C#", "Bm", "C#", "F#m", "F#m", "D", "D", "Bm", "Bm", "D", "C#"]
B = ["F#m", "A", "Bm", "C#", "F#m", "D", "Bm", "C#"]
A2 = A[:12] + ["A", "Bm", "D", "C#"]
BRK = ["C#", "C#", "D", "D", "C#", "C#"]
CH = INTRO + A + B + A2 + BRK
assert len(CH) == song.bars == 48
sec = sections([("INTRO", 0), ("A", 2), ("B", 18), ("A2", 26), ("BRK", 42)])
for b, sym in enumerate(CH):
    t, s = song.bar(b), sec(b)
    root = low_root(sym, 37)
    if s != "BRK":
        fig = [0, 0, 1, 0, 0, 0, 1, 3] if sym == "C#" else [0, 0, 7, 0, 0, 0, 7, 12]
        for k, iv in enumerate(fig):
            ost.note(t + k * 0.5, 0.32, root + iv if sym != "C#" else 37 + iv, 82 if k % 4 == 0 else 64)
    if s in ("A", "A2", "B"):
        for st, p, v in ((0, 41, 86), (1.5, 41, 60), (2, 45, 72), (3, 41, 70), (3.5, 45, 54)):
            drums.note(t + st, 0.25, p, v)
        anvil.note(t + 2.5, 0.2, 84, 46 if s == "A" else 54)
    elif s == "BRK":
        drums.note(t, 0.4, 41, 70 - 6 * (b - 42))
    if s in ("A2", "B") or b < 2:
        pad.chord(t, 3.95, voicing(sym, 49, 64)[:3], 38)
# Phrase 2 on low brass, squared off: C# B G# F#, then its answer.
for start in (6, 30):
    brass.line(song.bar(start), [(49, 2), (47, 2), (44, 2), (42, 2)], vel=84, legato=0.95)
brass.line(song.bar(34), [(42, 4), (45, 4), (49, 8)], vel=78, legato=0.95)
# B: a low reed sings over it.
lead.line(song.bar(18), bars("A4:2 G#4:1 F#4:1 | E4:3 C#4:1 | D4:2 F#4:2 | E#4:4 | "
                             "F#4:1 G#4:1 A4:2 | B4:2 A4:2 | F#4:2 D4:2 | C#4:4"), legato=0.94)
lead.line(song.bar(42), bars("C#4:4 | r:4 | D4:2 C#4:2 | r:4 | r:4 | r:4"), vel=60)
for i, p in enumerate(song.parts):
    p.humanize(seed=1200 + i, time_q=0.008)
song.save()
gate(song, CH, ("reed",), ("pad",), "cinderreach")

# ------------------------------------------------------------------ kiln
song = Song("dungeon_kiln")
anvil = song.part("perc_anvil", program=0, vel=70)
taiko = song.part("drum_taiko", program=0, vel=90)
bass = song.part("bass_synth", program=38, vel=84)
brass = song.part("horns_brass", program=61, vel=86)
organ = song.part("organ_dark", program=19, vel=56)
A = ["Em", "Em", "F", "Em", "Em", "Em", "Dm", "Em", "C", "C", "F", "Em", "Am", "Dm", "F", "Em"]
B = ["Em", "Dm", "C", "Dm", "Em", "Am", "F", "Em"]
C = ["Am", "Am", "F", "F", "Dm", "Dm", "F", "Em"]
B2 = ["Em", "Dm", "C", "Dm", "Em", "Am", "F", "Em"] * 2
CH = A + B + A + C + B2
assert len(CH) == song.bars == 64
sec = sections([("A", 0), ("B", 16), ("A2", 24), ("C", 40), ("B2", 48)])
for b, sym in enumerate(CH):
    t, s = song.bar(b), sec(b)
    root = low_root(sym, 28)
    # Anvil: the hammer pattern, 1, 2-and, 4; a fourth hit in A'.
    hits = [(0, 96), (1.5, 72), (3, 84)] + ([(3.5, 60)] if s == "A2" else [])
    if s != "C":
        for st, v in hits:
            anvil.note(t + st, 0.2, 76, v)
    for st, v in ((0, 100), (2, 80)) if s != "C" else ((0, 70),):
        taiko.note(t + st, 0.3, 36, v)
    # Driving eighths in the bass, a held note in C.
    if s == "C":
        bass.note(t, 3.9, root, 76)
    else:
        for k in range(8):
            bass.note(t + k * 0.5, 0.35, root + (12 if k in (3, 7) else 0), 86 if k % 2 == 0 else 70)
    if s in ("A", "A2", "C"):
        organ.chord(t, 3.95, voicing(sym, 52, 67)[:3], 50 if s != "C" else 60)
P2 = [(76, 2), (74, 1), (71, 1), (69, 2)]  # E D B A, phrase 2 on phrase-2 rhythm
for start in (16, 20):
    brass.line(song.bar(start), P2 + [(71, 2), (72, 4), (71, 4)], legato=0.92)
for start in (48, 52, 56, 60):  # B': brass, and organ one bar behind (the canon)
    brass.line(song.bar(start), P2 + [(71, 2), (72, 4), (71, 4)], vel=84 if start < 56 else 92, legato=0.92)
    tail = [(59, 2), (60, 4), (59, 2)] if start < 60 else [(59, 2), (60, 4)]  # the last one ends with the loop
    organ.line(song.bar(start + 1), [(p - 12, d) for p, d in P2] + tail, vel=58)
brass.line(song.bar(40), bars("C5:4 | A4:4 | F4:2 A4:2 | C5:4 | D5:4 | F4:4 | A4:2 C5:2 | B4:4"), vel=70)
for i, p in enumerate(song.parts):
    p.humanize(seed=1300 + i, time_q=0.006)
song.save()
gate(song, CH, ("horns",), ("organ",), "kiln")
