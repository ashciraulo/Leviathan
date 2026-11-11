"""The Sunken Verge (region_sunken_verge) and The Drowned Belfry (dungeon_belfry).

region_sunken_verge: Eb dorian, 5/4 at 88, 32 bars: A 12 | B 8 | A' 12.
  Lullaby phrase 6's degrees (7 6 5 4 3: Db C Bb Ab Gb) fill one 5/4 bar on a
  low clarinet. Harp in 3+2, a water-drop pluck, upright bass, soft pad.
dungeon_belfry: G dorian, 3/4 at 104, 64 bars: A 16 | B 16 (choir) | A' 16 |
  C 16 (organ alone, then bells). Phrase 6 (F E D C Bb) as a hymn on organ.

Run: python3 music/cues/t12_verge_belfry.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, voicing  # noqa: E402
from common import bars, low_root, sections, gate  # noqa: E402

# ------------------------------------------------------------------ verge
song = Song("region_sunken_verge")
clar = song.part("clarinet_low", program=71, vel=74)
harp = song.part("harp", program=46, vel=56)
drop = song.part("pluck_drop", program=108, vel=50)
bass = song.part("bass_upright", program=32, vel=78)
pad = song.part("pad_soft", program=89, vel=36)
A = ["Ebm", "Ebm", "Db", "Ebm", "Abm", "Abm", "Gb", "Db", "Ebm", "Cb", "Db", "Bbm"]
B = ["Gb", "Db", "Ab", "Ebm", "Gb", "Db", "Cb", "Bbm"]
A2 = ["Ebm", "Ebm", "Db", "Ebm", "Abm", "Ab", "Gb", "Db", "Cb", "Gb", "Ab", "Bbm"]
CH = A + B + A2
assert len(CH) == song.bars == 32
P6 = "Db5:1 C5:1 Bb4:1 Ab4:1 Gb4:1"
clar.line(song.bar(0), bars("Bb4:3 Gb4:2 | Ab4:2 Bb4:1 Db5:2 | " + P6 + " | Gb4:5 | Eb5:3 Db5:2 | Cb5:2 Bb4:1 Ab4:2 | "
                            "Bb4:3 Gb4:2 | F4:5 | Gb4:2 Bb4:1 Eb5:2 | Eb5:3 Gb4:2 | Ab4:2 F4:1 Db5:2 | Db5:5", per_bar=5),
          legato=0.94)
clar.line(song.bar(20), bars("Bb4:3 Gb4:2 | Ab4:2 Bb4:1 Db5:2 | " + P6 + " | Gb4:5 | Eb5:3 Cb5:2 | C5:3 Ab4:2 | "
                             "Bb4:2 Db5:1 Gb5:2 | F5:5 | Eb5:2 Cb5:1 Gb4:2 | Db5:3 Bb4:2 | C5:2 Ab4:1 Eb5:2 | Db5:5",
                             per_bar=5), vel=70, legato=0.94)
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = voicing(sym, 51, 70)
    root = low_root(sym, 39)
    # Harp in 3+2: root and a rising third on the 3, a fifth on the 2.
    for s, p, v in ((0, root, 64), (1, tones[1], 50), (2, tones[2], 48), (3, tones[0] + 12 if tones[0] + 12 < 72 else tones[0], 54), (4, tones[1], 44)):
        harp.note(t + s, 1.8, p, v)
    bass.note(t, 2.8, root, 80)
    bass.note(t + 3, 1.8, root + 7 if root + 7 < 52 else root - 5, 66)
    if 12 <= b < 20:  # B: the clarinet rests; drops and a pad
        pad.chord(t, 4.95, voicing(sym, 53, 66)[:3], 36)
        drop.line(t, [(None, 1.5), (voicing(sym, 75, 88)[(b * 2) % 3], 0.5), (None, 1.5), (voicing(sym, 75, 88)[(b + 1) % 3], 1.5)], vel=48, legato=0.5)
    elif b % 3 == 2:
        drop.note(t + 4.5, 0.4, voicing(sym, 75, 88)[0], 42)
for i, p in enumerate(song.parts):
    p.humanize(seed=2100 + i, time_q=0.01)
song.save()
gate(song, CH, ("clarinet",), ("pad",), "verge")

# ---------------------------------------------------------------- belfry
song = Song("dungeon_belfry")
organ = song.part("organ_soft", program=19, vel=60)
choir = song.part("choir", program=52, vel=54)
cbells = song.part("bell_church", program=14, vel=64)
harp = song.part("harp", program=46, vel=52)
bass = song.part("bass_arco", program=43, vel=70)
A = ["Gm", "Gm", "Bb", "F", "Eb", "F", "Gm", "D", "Gm", "C", "F", "Bb", "Eb", "C", "D", "D"]
B = ["Bb", "F", "Gm", "D", "Eb", "Bb", "C", "D", "Gm", "Eb", "Bb", "F", "Cm", "Gm", "Am", "D"]
C = ["Gm", "Gm", "Eb", "Eb", "C", "C", "D", "D", "Gm", "F", "Eb", "D", "Gm", "Gm", "D", "D"]
CH = A + B + A + C
assert len(CH) == song.bars == 64
sec = sections([("A", 0), ("B", 16), ("A2", 32), ("C", 48)])
TUNE_A = ("D5:2 Bb4:1 | C5:2 A4:1 | Bb4:1 A4:1 G4:1 | A4:3 | G4:1 Bb4:1 Eb5:1 | C5:2 A4:1 | Bb4:2 G4:1 | F#4:3 | "
          "G4:2 Bb4:1 | E5:2 C5:1 | F5:1 E5:1 D5:1 | C5:1 Bb4:2 | G4:2 Bb4:1 | E5:3 | F#5:2 D5:1 | A4:3")
# The hymn: phrase 6 is bar 11-12's "F E D | C Bb", sung in four-part chords.
for start in (0, 32):
    items = bars(TUNE_A, per_bar=3)
    t = song.bar(start)
    for pitch, d in items:
        if pitch is not None:
            b = int((t + 0.01) // 3)
            under = [p for p in voicing(CH[b], 50, pitch - 3)][-3:]
            organ.chord(t, d * 0.95, under + [pitch], 60 if start == 0 else 66)
        t += d
choir.line(song.bar(16), bars("D5:2 F5:1 | F5:2 C5:1 | D5:3 | A4:3 | G4:1 Bb4:1 Eb5:1 | D5:2 F5:1 | E5:3 | F#5:3 | "
                              "G5:2 D5:1 | Eb5:2 G4:1 | F5:1 E5:1 D5:1 | C5:1 Bb4:2 | C5:2 Eb5:1 | D5:2 Bb4:1 | "
                              "A4:2 C5:1 | F#4:3", per_bar=3), legato=0.97)
for b, sym in enumerate(CH):
    t, s = song.bar(b), sec(b)
    if s == "B":
        organ.chord(t, 2.95, voicing(sym, 48, 62)[:3], 46)
    if s == "C":
        if b < 56:
            organ.chord(t, 2.95, voicing(sym, 50, 67)[:4], 52)
        else:  # the bells: the hymn's phrase 6, tolled
            if b % 2 == 0:  # F E D, then C Bb: phrase 6 across two bars
                for k, p in enumerate([77, 76, 74] if b % 4 == 0 else [72, 70]):
                    cbells.note(t + k, 2.5, p, 70)
            organ.chord(t, 2.95, voicing(sym, 43, 55)[:3], 40)
    if s != "C" or b < 56:
        bass.note(t, 2.9, low_root(sym, 31), 70)
    if s in ("A", "A2") and b % 4 == 2:
        for k, p in enumerate(voicing(sym, 74, 86)[:3]):
            harp.note(t + 1 + k * 0.5, 1.8, p, 46)
for i, p in enumerate(song.parts):
    p.humanize(seed=2200 + i, time_q=0.01, vel=4)
song.save()
gate(song, CH, ("choir",), ("harp_none",), "belfry")
