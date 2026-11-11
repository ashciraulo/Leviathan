"""Lanterns on the Fen (region_gloamfen) and Moth Light (dungeon_mire).

region_gloamfen: Bb minor, 3/4 at 72, 40 bars: A 16 | B 8 (long rests) |
  A' 16. Lullaby phrase 3 on the same degrees (Db Eb F Ab Gb), scattered one
  or two notes a bar on celesta like lights over water. Bowed vibraphone,
  fretless bass, soft choir.
dungeon_mire: C# minor, 3/4 at 76, 40 bars: A 12 | B 12 | A' 8 | coda 8.
  Phrase 3 whole on glass bells (E F# G# B A), then broken up in the dark
  coda. Low drone, choir, harp.

Run: python3 music/cues/t09_gloamfen_mire.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of  # noqa: E402

GATE = "--gate" in sys.argv


def bars(text, per_bar=3):
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


# --------------------------------------------------------------- gloamfen
song = Song("region_gloamfen")
cel = song.part("celesta", program=8, vel=66)
vib = song.part("vibes_bowed", program=11, vel=46)
bass = song.part("bass_fretless", program=35, vel=70)
choir = song.part("choir_soft", program=52, vel=36)
A = ["Bbm", "Bbm", "Db", "Gb", "Ebm", "Ebm", "F", "F", "Bbm", "Bbm", "Db", "Db", "Gb", "Ebm", "F", "F"]
B = ["Gb", "Gb", "Db", "Db", "Ebm", "Ebm", "F", "F"]
A2 = ["Bbm", "Bbm", "Gb", "Gb", "Ebm", "Ebm", "Db", "Db", "Gb", "Gb", "Ebm", "Ebm", "Cdim", "Cdim", "F", "F"]
CH = A + B + A2
assert len(CH) == song.bars == 40
# Lights over water: the phrase's notes one or two a bar, high on celesta.
cel.line(song.bar(0), bars("Db6:2 r:1 | r:1 Eb6:2 | F6:3 | r:3 | Ab5:2 Gb5:1 | r:3 | F5:1 A5:2 | r:3 | "
                           "Db6:1 r:1 Eb6:1 | F6:2 r:1 | Ab6:3 | r:2 Gb6:1 | r:1 Db6:2 | Bb5:3 | A5:3 | r:3"), legato=1.2)
cel.line(song.bar(24), bars("F6:2 r:1 | Db6:3 | r:1 Eb6:2 | Gb6:3 | Bb5:2 r:1 | Db6:2 F6:1 | Ab6:3 | r:3 | "
                            "Gb6:1 F6:1 Eb6:1 | Db6:3 | r:3 | Bb5:2 r:1 | Eb6:3 | r:3 | C6:2 A5:1 | F5:3"), vel=60, legato=1.2)
for b, sym in enumerate(CH):
    t = song.bar(b)
    if 16 <= b < 24:  # B: long rests; just the vibes, one held chord each two bars
        if b % 2 == 0:
            vib.chord(t, 5.8, voicing(sym, 58, 70)[:2], 50)
            choir.chord(t, 5.8, voicing(sym, 53, 65)[:3], 34)
        continue
    if b % 2 == 0:
        vib.chord(t, 5.8, voicing(sym, 58, 72)[1:3], 42)
        bass.note(t, 5.5 if CH[b + 1] == sym else 2.9, low_root(sym, 34), 70)
    elif CH[b - 1] != sym:
        bass.note(t, 2.9, low_root(sym, 34), 66)
    if b >= 24:
        choir.chord(t, 2.95, voicing(sym, 53, 65)[:3], 32)
for i, p in enumerate(song.parts):
    p.humanize(seed=1400 + i, time_q=0.012, vel=4)
song.save()
gate(song, CH, ("celesta",), ("vibes",), "gloamfen")

# ------------------------------------------------------------------- mire
song = Song("dungeon_mire")
glass = song.part("bell_glass", program=14, vel=70)
drone = song.part("drone_low", program=95, vel=50)
choir = song.part("choir_dark", program=52, vel=44)
harp = song.part("harp", program=46, vel=54)
A = ["C#m", "C#m", "E", "E", "F#m", "F#m", "G#", "G#", "C#m", "A", "F#m", "G#"]
B = ["E", "E", "B", "B", "A", "A", "C#m", "C#m", "F#m", "B", "E", "G#"]
A2 = ["C#m", "C#m", "A", "A", "F#m", "G#", "C#m", "C#m"]
CODA = ["C#m", "C#m", "D", "D", "C#m", "C#m", "G#", "G#"]
CH = A + B + A2 + CODA
assert len(CH) == song.bars == 40
P3 = "E5:1 F#5:1 G#5:1 | B5:1 A5:2"
glass.line(song.bar(0), bars(P3 + " | G#5:3 | r:3 | " + P3 + " | F#5:3 | r:3 | C#5:2 E5:1 | A5:3 | F#5:2 E5:1 | D#5:3"))
glass.line(song.bar(12), bars("G#5:2 B5:1 | E5:3 | F#5:2 D#5:1 | B4:3 | A4:1 C#5:1 E5:1 | A5:3 | "
                              "G#5:2 E5:1 | C#5:3 | A5:2 F#5:1 | D#5:3 | E5:2 G#5:1 | B#4:3"), vel=64)
glass.line(song.bar(24), bars(P3 + " | E5:3 | C#5:2 A4:1 | F#5:2 E5:1 | D#5:2 B#4:1 | C#5:3 | r:3"), vel=66)
# The coda: phrase 3 broken, one note at a time, a step lower each time.
glass.line(song.bar(32), bars("E5:3 | r:3 | F#5:3 | r:3 | G#4:3 | r:3 | r:3 | r:3"), vel=56, legato=1.3)
for b, sym in enumerate(CH):
    t = song.bar(b)
    if b % 2 == 0:
        drone.note(t, 5.9, low_root(sym, 37) if b < 32 else 37, 52 if b < 32 else 60)
    if 12 <= b < 32 or b >= 32 and b % 2 == 0:
        choir.chord(t, 2.95 if b < 32 else 5.9, voicing(sym, 52, 64)[:3], 40 if b < 32 else 46)
    if b < 32 and b % 2 == 1:
        tones = voicing(sym, 49, 68)
        for k, p in enumerate(tones[:4]):
            harp.note(t + k * 0.5, 2.5 - k * 0.5, p, 50)
for i, p in enumerate(song.parts):
    p.humanize(seed=1500 + i, time_q=0.01, vel=4)
song.save()
gate(song, CH, ("bell",), ("harp",), "mire")
