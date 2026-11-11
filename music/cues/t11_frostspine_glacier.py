"""Frostspine (region_frostspine) and The Hollow Glacier (dungeon_glacier).

region_frostspine: F# minor, 4/4 at 60, 32 bars: A 12 (near silence between
  notes) | B 12 | wind tag 8. Lullaby phrase 5's leap (1 3 5 8: F# A C# F#)
  on an FM glass e-piano; choir pad, low bowed bass, a sparse bell.
dungeon_glacier: F minor, 4/4 at 70, 40 bars: A 8 | B 16 (ticking builds) |
  A' 16. Phrase 5 (F Ab C F) on FM bells; bowed glass, sub drone, soft
  ticking percussion that thickens through B.

Run: python3 music/cues/t11_frostspine_glacier.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, voicing  # noqa: E402
from common import bars, low_root, gate  # noqa: E402

# ------------------------------------------------------------- frostspine
song = Song("region_frostspine")
ep = song.part("epiano_glass", program=4, vel=64)
choir = song.part("choir_pad", program=52, vel=34)
bass = song.part("bass_bowed", program=43, vel=62)
bell = song.part("bell_sparse", program=14, vel=48)
A = ["F#m", "F#m", "D", "D", "Bm", "Bm", "C#", "C#", "F#m", "F#m", "D", "C#"]
B = ["A", "A", "E", "E", "D", "D", "Bm", "C#", "F#m", "D", "Bm", "C#"]
TAG = ["F#m", "F#m", "F#m", "F#m", "D", "D", "C#", "C#"]
CH = A + B + TAG
assert len(CH) == song.bars == 32
# A: the leap, then long silences; each phrase a little different.
ep.line(song.bar(0), bars("F#4:1 A4:1 C#5:2 | F#5:4 | r:4 | D5:2 r:2 | F#4:1 B4:1 D5:2 | r:4 | "
                          "C#5:3 r:1 | G#4:4 | F#4:1 A4:1 C#5:2 | E5:4 | r:2 D5:2 | C#5:4"), legato=1.1)
ep.line(song.bar(12), bars("C#5:2 E5:2 | A5:4 | B4:2 E5:2 | G#5:4 | F#5:2 D5:2 | A4:4 | "
                           "B4:1 D5:1 F#5:2 | E#5:4 | F#5:3 C#5:1 | A4:4 | D5:2 B4:2 | C#5:4"), vel=60, legato=1.0)
ep.line(song.bar(24), bars("F#4:1 A4:1 C#5:2 | F#5:4 | r:4 | r:4 | A4:4 | r:4 | G#4:4 | r:4"), vel=54, legato=1.2)
for b, sym in enumerate(CH):
    t = song.bar(b)
    if b % 2 == 0:
        choir.chord(t, 7.9, voicing(sym, 50, 62)[:3], 34 if b < 12 or b >= 24 else 42)
        bass.note(t, 7.8, low_root(sym, 30), 60)
    if b % 4 == 2 and b < 24:
        bell.note(t + 3, 3, voicing(sym, 78, 90)[0], 44)
for i, p in enumerate(song.parts):
    p.humanize(seed=1900 + i, time_q=0.012, vel=4)
song.save()
gate(song, CH, ("epiano",), ("choir",), "frostspine")

# ---------------------------------------------------------------- glacier
song = Song("dungeon_glacier")
bells = song.part("bell_fm", program=14, vel=70)
glass = song.part("glass_bowed", program=92, vel=40)
sub = song.part("sub_drone", program=38, vel=56)
tick = song.part("perc_tick", program=0, vel=40)
A = ["Fm", "Fm", "Db", "Db", "Bbm", "Bbm", "C", "C"]
B = ["Fm", "Eb", "Db", "C", "Fm", "Ab", "Bbm", "C", "Db", "Eb", "Fm", "Fm", "Bbm", "Db", "Gb", "C"]
A2 = ["Fm", "Fm", "Db", "Db", "Bbm", "Bbm", "C", "C", "Fm", "Fm", "Ab", "Ab", "Db", "Bbm", "C", "C"]
CH = A + B + A2
assert len(CH) == song.bars == 40
P5 = "F5:1 Ab5:1 C6:2 | F6:4"
bells.line(song.bar(0), bars(P5 + " | Db6:2 C6:2 | Ab5:4 | F5:1 Ab5:1 Db6:2 | Bb5:4 | G5:2 E5:2 | C5:4"), legato=1.2)
bells.line(song.bar(8), bars("C6:4 | Bb5:4 | Ab5:2 F5:2 | E5:4 | F5:2 C6:2 | Eb6:4 | Db6:2 Bb5:2 | G5:4 | "
                             "Ab5:2 F5:2 | G5:2 Eb5:2 | F5:4 | r:4 | Db6:2 Bb5:2 | Ab5:2 F5:2 | Gb5:4 | E5:4"), vel=62, legato=1.1)
bells.line(song.bar(24), bars(P5 + " | Db6:2 C6:2 | Ab5:4 | F5:1 Ab5:1 Db6:2 | Bb5:4 | G5:2 E5:2 | C5:4 | "
                              + P5 + " | Eb6:2 C6:2 | Ab5:4 | F5:1 Ab5:1 Db6:2 | Bb5:4 | C6:4 | r:4"), vel=66, legato=1.2)
for b, sym in enumerate(CH):
    t = song.bar(b)
    glass.chord(t, 3.95, voicing(sym, 56, 68)[:2], 38 if 8 <= b < 24 else 34)
    if b % 4 == 0:
        sub.note(t, 15.8, low_root(sym, 29), 56)
    # Ticking: a quarter-note tick in B grows to eighths, then sixteenth pairs.
    if 8 <= b < 24:
        step = 1.0 if b < 14 else 0.5 if b < 20 else 0.25
        k = 0
        while k * step < 4:
            tick.note(t + k * step, 0.1, 75, 30 + (b - 8) * 2 + (10 if k == 0 else 0))
            k += 1
    elif b >= 24 and b % 2 == 1:
        tick.note(t + 3.5, 0.1, 75, 30)
for i, p in enumerate(song.parts):
    p.humanize(seed=2000 + i, time_q=0.01, vel=3)
song.save()
gate(song, CH, ("bell",), ("glass",), "glacier")
