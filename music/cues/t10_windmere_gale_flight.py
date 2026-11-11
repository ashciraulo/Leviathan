"""Windmere Heights (region_windmere), The Gale Spire (dungeon_gale), Wayshell Flight (story_flight).

region_windmere: A lydian, 4/4 at 126, 48 bars: A 16 | A' 8 | B 16 (lifts a
  whole step to B lydian) | A'' 8. Lullaby phrase 4's degrees (5 4 3 1) opened
  up to lydian on flute: E D# C# A. Pizzicato, soft snare roll, string pad, harp.
dungeon_gale: B mixolydian, 7/8 (3+2+2) at 138, 72 bars: A 16 | B 16 | A' 16 |
  C 8 (wind only) | B' 16. Phrase 4 (F# E D# B) on tubular bell, stretched to
  the 3+2+2 bar. Bars are 3.5 quarters; FL plays it as 4/4 with notes on the
  7/8 grid.
story_flight: D lydian, 3/4 at 98, 24 bars: A 8 | B 8 | A' 8 (lifts).
  Phrase 1 (A F# G# A) and phrase 5 (D F# A D) in D lydian, triumphant.

Run: python3 music/cues/t10_windmere_gale_flight.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of  # noqa: E402

GATE = "--gate" in sys.argv


def bars(text, per_bar=4.0, unit=1.0):
    for i, chunk in enumerate(text.split("|")):
        total = sum(d for _, d in seq(chunk)) * unit
        assert abs(total - per_bar) < 1e-6, f"bar {i + 1} has {total}: {chunk.strip()}"
    return seq(text.replace("|", ""), unit)


def low_root(sym, lowest):
    return lowest + (bass_of(sym) - lowest) % 12


def gate(song, chords, melody, comp, label):
    if GATE:
        from gate_midi import check
        for problem in check(song, chords, melody=melody, comp=comp):
            print(f"GATE {label}:", problem)


# --------------------------------------------------------------- windmere
song = Song("region_windmere")
pizz = song.part("strings_pizz", program=45, vel=68)
flute = song.part("flute", program=73, vel=78)
snare = song.part("drum_snare", program=0, vel=40)
pad = song.part("pad_strings", program=48, vel=40)
harp = song.part("harp", program=46, vel=56)
A = ["A", "B", "A", "B", "F#m", "G#m", "E", "E", "A", "B", "C#m", "B", "F#m", "B", "E", "E"]
A2 = ["A", "B", "E", "B", "C#m", "B", "A", "E"]
B = ["B", "C#", "B", "C#", "G#m", "A#m", "F#", "F#", "B", "C#", "D#m", "C#", "G#m", "C#", "F#", "E"]
A3 = ["A", "B", "A", "B", "F#m", "B", "E", "E"]
CH = A + A2 + B + A3
assert len(CH) == song.bars == 48
TUNE = "E5:2 D#5:1 C#5:1 | A4:3 B4:1 | C#5:2 E5:2 | F#5:4 | " \
       "C#5:1 E5:1 F#5:2 | G#5:2 D#5:2 | E5:3 G#4:1 | B4:4 | " \
       "E5:2 D#5:1 C#5:1 | A4:2 B4:2 | E5:1 G#5:1 B5:2 | F#5:4 | " \
       "A5:2 F#5:2 | D#5:3 B4:1 | B4:2 E5:2 | E4:4"
flute.line(song.bar(0), bars(TUNE), legato=0.92)
flute.line(song.bar(16), bars("E5:2 D#5:1 C#5:1 | A4:3 F#5:1 | G#5:2 E5:2 | D#5:4 | "
                              "C#5:1 E5:1 G#5:2 | F#5:2 D#5:2 | E5:2 C#5:2 | B4:4"), vel=72, legato=0.92)
flute.line(song.bar(24), bars("F#5:2 E#5:1 D#5:1 | B4:3 C#5:1 | D#5:2 F#5:2 | G#5:4 | "
                              "D#5:1 F#5:1 G#5:2 | A#5:2 E#5:2 | F#5:3 A#4:1 | C#5:4 | "
                              "F#5:2 E#5:1 D#5:1 | B4:2 C#5:2 | F#5:1 A#5:1 C#6:2 | G#5:4 | "
                              "B5:2 G#5:2 | E#5:3 C#5:1 | C#5:2 A#4:2 | B4:4"), vel=80, legato=0.92)
flute.line(song.bar(40), bars("E5:2 D#5:1 C#5:1 | A4:3 B4:1 | C#5:2 E5:2 | F#5:4 | "
                              "C#5:1 E5:1 F#5:2 | D#5:2 B4:2 | E5:3 B4:1 | E5:4"), legato=0.92)
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = voicing(sym, 52, 66)
    root = low_root(sym, 40)
    for k, s in enumerate((0, 1, 1.5, 2, 3)):
        p = root if k == 0 else tones[(k + b) % len(tones)]
        pizz.note(t + s, 0.3, p, 72 if k == 0 else 56)
    if b % 4 == 3:  # a soft roll into each fourth bar
        for k in range(8):
            snare.note(t + 2 + k * 0.25, 0.2, 38, 26 + k * 3)
    if 16 <= b < 40:
        pad.chord(t, 3.95, voicing(sym, 50, 64)[:3], 38)
    if b % 2 == 0 and b >= 8:
        for k, p in enumerate(voicing(sym, 55, 72)[:5]):  # kept under the flute
            harp.note(t + 3 + k * 0.125, 1.5, p, 48)
for i, p in enumerate(song.parts):
    p.humanize(seed=1600 + i, time_q=0.008)
song.save()
gate(song, CH, ("flute",), ("pad", "harp"), "windmere")

# -------------------------------------------------------------------- gale
song = Song("dungeon_gale")
E = 0.5
runs = song.part("strings_runs", program=48, vel=70)
flute = song.part("flute", program=73, vel=74)
timp = song.part("timpani", program=47, vel=80)
tbell = song.part("bell_tubular", program=14, vel=82)
bass = song.part("bass_arco", program=43, vel=80)
A = ["B", "B", "A", "B", "E", "E", "A", "B", "B", "B", "A", "B", "G#m", "E", "F#m", "B"]
B = ["E", "F#m", "G#m", "A", "E", "F#m", "A", "B", "C#m", "C#m", "A", "A", "E", "F#m", "A", "B"]
C = ["B"] * 4 + ["A"] * 4
CH = A + B + A + C + B
assert len(CH) == song.bars == 72
GROUP = (0, 3, 5)  # 3+2+2 eighths
for b, sym in enumerate(CH):
    t = song.bar(b)
    root = low_root(sym, 35)
    if 48 <= b < 56:  # C: wind only, the strings' runs alone and soft
        for k in range(7):
            runs.note(t + k * E, E * 0.9, voicing(sym, 66, 81)[k % 4], 40 + 4 * (k % 3))
        continue
    for k, g in enumerate(GROUP):
        bass.note(t + g * E, (3 if k == 0 else 2) * E * 0.9, root if k != 1 else root + 7, 84 if k == 0 else 70)
        timp.note(t + g * E, E, root if k != 2 else root + 7, 84 if k == 0 else 64)
    tones = voicing(sym, 59, 79)
    run = tones[:7] if b % 2 == 0 else list(reversed(tones[:7]))
    for k, p in enumerate(run[:7]):
        runs.note(t + k * E, E * 0.8, p, 66 if k in GROUP else 52)
# Phrase 4 on tubular bell, one phrase per two bars: F# E D# | B.
for start in list(range(0, 16, 4)) + list(range(32, 48, 4)):
    tbell.line(song.bar(start), [(66, 3 * E), (64, 2 * E), (63, 2 * E), (59, 7 * E)], legato=1.0)
# B and B': a flute tune in 3+2+2.
TUNE = "B5:3 G#5:2 E5:2 | F#5:3 A5:2 F#5:2 | G#5:3 B4:2 D#5:2 | E5:7 | " \
       "G#5:3 E5:2 B4:2 | C#5:3 F#5:2 A5:2 | A5:3 C#6:2 A5:2 | F#5:7 | " \
       "G#5:3 E5:2 C#5:2 | E5:3 G#5:2 C#6:2 | C#6:3 A5:2 E5:2 | A5:7 | " \
       "B5:3 G#5:2 E5:2 | A5:3 F#5:2 C#5:2 | E5:3 C#5:2 A4:2 | D#5:7"
for start in (16, 56):
    flute.line(song.bar(start), bars(TUNE, per_bar=3.5, unit=E), vel=74 if start == 16 else 80, legato=0.92)
for i, p in enumerate(song.parts):
    p.humanize(seed=1700 + i, time_q=0.006)
song.save()
gate(song, CH, ("flute",), ("none",), "gale")

# ------------------------------------------------------------------ flight
song = Song("story_flight")
strings = song.part("strings_high", program=48, vel=74)
harp = song.part("harp", program=46, vel=60)
choir = song.part("choir_ah", program=52, vel=54)
horn = song.part("horns_french", program=60, vel=80)
bass = song.part("bass_arco", program=43, vel=70)
A = ["D", "E", "D", "E", "Bm", "F#m", "G#m", "A"]
B = ["D", "Bm", "E", "A", "D", "F#m", "E", "A"]
A2 = ["D", "E", "D", "E", "Bm", "E", "A", "A"]
CH = A + B + A2
assert len(CH) == song.bars == 24
# A: phrase 1 (A F# G# A) on horn, answered; B: phrase 5 (D F# A D) rising high on strings.
horn.line(song.bar(0), bars("A4:2 F#4:1 | G#4:1 A4:2 | F#4:2 D4:1 | E4:3 | D4:1 F#4:1 B4:1 | "
                            "C#5:3 | B4:2 G#4:1 | A4:3", per_bar=3), legato=0.94)
strings.line(song.bar(8), bars("D5:1 F#5:1 A5:1 | D6:3 | B5:2 G#5:1 | A5:3 | A5:1 F#5:1 D5:1 | "
                               "C#6:3 | B5:2 G#5:1 | A5:3", per_bar=3), legato=0.96)
horn.line(song.bar(16), bars("A4:2 F#4:1 | G#4:1 A4:2 | D5:2 F#5:1 | E5:3 | D5:1 F#5:1 B5:1 | "
                             "G#5:3 | A5:3 | A5:3", per_bar=3), vel=86, legato=0.94)
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = voicing(sym, 50, 69)
    bass.note(t, 2.95, low_root(sym, 38), 72)
    if b < 8 or b >= 16:
        strings.chord(t, 2.95, tones[:3], 56)
    choir.chord(t, 2.95, voicing(sym, 55, 67)[:3], 48 if 8 <= b < 16 else 40)
    if b % 4 == 3:  # a harp glissando up into each fourth bar's end
        for k, p in enumerate(voicing(sym, 62, 93)):
            harp.note(t + 2 + k * (1.0 / 10), 1.2, p, 50 + k)
    elif b % 2 == 0:
        for k, p in enumerate(tones[:3]):
            harp.note(t + k * 0.5, 2.5 - k * 0.5, p, 54)
for i, p in enumerate(song.parts):
    p.humanize(seed=1800 + i, time_q=0.008)
song.save()
gate(song, CH, ("horns",), ("harp_none",), "flight")
