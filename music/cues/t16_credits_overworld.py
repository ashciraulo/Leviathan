"""The Eighth Line (credits) and the overworld fallback.

credits: D major, 3/4 at 84, 96 bars, plays once: A 16 (new tune, flute over
  harp) | B 16 | lullaby 16 (all seven phrases, turned to D major) |
  eighth line 8 (the line no bell holds, which Wren hums) | region medley 32
  (Saltmarrow, Lamplight, the Belfry hymn, the Wayshell flight, all in D) |
  close 8 (the eighth line once more, then the last chord, 3 dB under).
overworld: G mixolydian, 4/4 at 110, 16 bars. A spare harp-and-flute
  fallback for a room with no region; not heard in the game today.

Run: python3 music/cues/t16_credits_overworld.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, voicing, lullaby  # noqa: E402
from common import bars, low_root, sections, gate, harmonize  # noqa: E402

MAJOR = {65: 66, 77: 78, 72: 73, 60: 61, 70: 71, 58: 59}  # D aeolian -> D major: F, C, Bb raised

# ----------------------------------------------------------------- credits
song = Song("credits")
flute = song.part("flute", program=73, vel=76)
harp = song.part("harp", program=46, vel=56)
strings = song.part("strings", program=48, vel=52)
choir = song.part("choir", program=52, vel=42)
bells = song.part("bell_point", program=14, vel=80)
bass = song.part("bass_arco", program=43, vel=64)
cello = song.part("cello", program=42, vel=66)
sec = sections([("A", 0), ("B", 16), ("LUL", 32), ("EIGHTH", 48), ("MED", 56), ("CLOSE", 88)])
TUNE_A = ("F#5:2 E5:1 | D5:2 A4:1 | B4:2 D5:1 | A4:3 | G4:1 A4:1 B4:1 | D5:2 E5:1 | F#5:2 E5:1 | E5:3 | "
          "F#5:2 A5:1 | G5:2 E5:1 | D5:1 E5:1 F#5:1 | B4:3 | G4:2 B4:1 | A4:2 D5:1 | E5:2 C#5:1 | D5:3")
TUNE_B = ("B4:2 C#5:1 | D5:2 F#5:1 | E5:3 | A4:3 | G4:2 B4:1 | D5:2 G5:1 | F#5:3 | D5:3 | "
          "E5:2 G5:1 | F#5:2 D5:1 | C#5:2 E5:1 | A5:3 | G5:2 E5:1 | F#5:2 D5:1 | E5:3 | A4:3")
EIGHTH = "A4:2 F#4:1 | G4:1 A4:2 | B4:2 C#5:1 | D5:3"  # the eighth line: rising home
MED = [
    ("A4:2 F#4:1 D4:2 F#4:1 | A4:3 B4:2 A4:1 | B4:2 A4:1 G4:2 B4:1 | A4:5 r:1 | "
     "F#4:2 G4:1 A4:2 B4:1 | D5:3 B4:2 G4:1 | A4:2 G4:1 F#4:2 E4:1 | E4:5 r:1", 0.5),  # Saltmarrow, in D
    ("D5:2 F#5:1 | G5:2 B5:1 | A5:1 G5:1 F#5:1 | E5:1 D5:2 | F#5:2 E5:1 | D5:3 | E5:3 | A4:3", 1.0),  # Lamplight
    ("A5:2 F#5:1 | G5:2 E5:1 | F#5:1 E5:1 D5:1 | E5:3 | D5:1 F#5:1 B5:1 | G5:2 E5:1 | F#5:2 D5:1 | C#5:3", 1.0),  # hymn
    ("A4:2 F#4:1 | G#4:1 A4:2 | D5:2 F#5:1 | E5:3 | D5:1 F#5:1 B5:1 | G#5:3 | A5:3 | A5:3", 1.0),  # flight
]
flute.line(song.bar(0), bars(TUNE_A, per_bar=3), legato=0.93)
flute.line(song.bar(16), bars(TUNE_B, per_bar=3), vel=72, legato=0.93)
t = song.bar(32)
lul = []
for phrase in lullaby():
    for pitch, beats in phrase:
        p = MAJOR.get(pitch, pitch)
        bells.note(t, beats * 0.95, p + 12, 84)  # FL's bell rings on by itself
        lul.append((t, beats, p + 12))
        t += beats
EIGHTH_LOW = "A3:2 F#3:1 | G3:1 A3:2 | B3:2 C#4:1 | D4:3"  # an octave under the flute's line (v1 review: A4-D5 was bright)
cello.line(song.bar(48), bars(EIGHTH_LOW + " | " + EIGHTH_LOW, per_bar=3), legato=0.97)  # Wren's hum: a low, soft voice
for k, (text, unit) in enumerate(MED):
    flute.line(song.bar(56 + 8 * k), bars(text, per_bar=3, unit=unit), vel=70, legato=0.93)
flute.line(song.bar(88), bars(EIGHTH + " | D5:3 | r:3 | r:3 | r:3", per_bar=3), vel=62, legato=0.97)
CH = (["D", "Bm", "G", "D", "Em", "G", "D", "A", "D", "Em", "Bm", "G", "Em", "D", "A", "D"] +
      ["G", "D", "A", "A", "Em", "G", "D", "Bm", "A", "D", "A", "D", "Em", "D", "A", "A"] +
      harmonize(lul, 3.0, 14, ["D", "G", "A", "Bm", "Em", "F#m"], start_bar=32) + ["D", "D"] +
      ["D", "G", "Em", "D", "D", "G", "Em", "D"] +
      ["D", "D", "G", "D", "D", "G", "D", "A"] + ["G", "Em", "D", "A", "D", "D", "A", "A"] +
      ["D", "Em", "D", "A", "D", "Em", "D", "A"] + ["D", "E", "D", "E", "Bm", "E", "A", "A"] +
      ["D", "G", "Em", "D", "D", "D", "D", "D"])
assert len(CH) == song.bars == 96, len(CH)
for b, sym in enumerate(CH):
    tb, s = song.bar(b), sec(b)
    tones = voicing(sym, 50, 69)
    root = low_root(sym, 38)
    if b >= 92:  # the close (v1/v2 review MAJOR: it stopped, then ended on a thin pluck): bar 92 as written, then one
        # held chord that thins out (bass, then strings, then the choir past the end) under two harp rolls
        if b == 92:
            bass.note(tb, 2.9, root, 50)
            choir.chord(tb, 2.9, voicing(sym, 55, 67)[:3], 32)
            for k, p in enumerate(voicing(sym, 57, 74)[:3]):
                harp.note(tb + k * 0.25, 2.5, p, 42)
        elif b == 93:  # the voices leave one by one (v3a held them all to the end, so bar 95 sat level with 92):
            # bass at bar 95, strings half a bar later, the choir a bar past the written end into the render's room
            bass.note(tb, 6.0, root, 50)
            strings.chord(tb, 7.5, voicing(sym, 57, 74)[:2], 40)
            choir.chord(tb, 11.0, voicing(sym, 55, 67)[:3], 32)
            for k, p in enumerate(voicing(sym, 57, 74)[:3]):
                harp.note(tb + k * 0.33, 6.0, p, 40)
        elif b == 95:
            for k, p in enumerate(voicing(sym, 62, 79)[:3]):
                harp.note(tb + k * 0.33, 6.0, p, 36)
        continue
    if s == "EIGHTH":  # near silence under the hum: a thin held string pair per bar
        strings.chord(tb, 2.95, voicing(sym, 57, 74)[:2], 40)  # above the hum (v2 review: F#3/G3 doubled it)
        continue
    bass.note(tb, 2.9, root, 60)
    if s in ("A", "MED", "CLOSE"):  # root, third and fifth (v1 review: the low figure never spelled its chords)
        for k, p in enumerate(voicing(sym, 57, 74)[:3]):
            harp.note(tb + k, 2.5 - k * 0.5, p, 54)
    if s in ("B", "LUL", "MED"):
        strings.chord(tb, 2.95, tones[:3], 50)
    if s in ("LUL", "CLOSE") or (s == "MED" and b >= 80):
        choir.chord(tb, 2.95, voicing(sym, 55, 67)[:3], 40)
for i, p in enumerate(song.parts):
    if p.name != "bell_point":
        p.humanize(seed=3500 + i, time_q=0.01, vel=4)
song.save()
gate(song, CH, ("flute", "bell", "cello"), ("harp",), "credits")

# --------------------------------------------------------------- overworld
song = Song("overworld")
harp = song.part("harp", program=46, vel=58)
flute = song.part("flute", program=73, vel=72)
CH = ["G", "F", "C", "G", "G", "F", "Am", "D", "G", "F", "C", "Em", "C", "F", "D", "G"]
assert len(CH) == song.bars == 16
flute.line(0, bars("D5:2 B4:1 C5:1 | D5:4 | E5:2 G5:2 | D5:4 | B4:1 D5:1 G5:2 | F5:2 C5:2 | E5:3 C5:1 | A4:4 | "
                   "D5:2 B4:1 G4:1 | A4:2 F4:2 | G4:2 E5:2 | B4:4 | C5:1 E5:1 G5:2 | A5:2 F5:2 | F#5:2 A4:2 | G4:4"),
           legato=0.92)
for b, sym in enumerate(CH):
    tones = voicing(sym, 50, 67)
    for k, p in enumerate([low_root(sym, 43)] + tones[:3]):
        harp.note(song.bar(b) + k, 1.8, p, 56)
for i, p in enumerate(song.parts):
    p.humanize(seed=3600 + i)
song.save()
gate(song, CH, ("flute",), ("harp",), "overworld")
