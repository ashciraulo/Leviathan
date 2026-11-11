"""Ossuary Dunes, The Marrow Tomb, Hollows (place_cave), The Healing Spring.

region_ossuary: C phrygian, 4/4 at 78, 40 bars: intro 2 (drone) | A 16 | B 8 |
  A' 14. Lullaby phrase 7's degrees (4 5 3 1: F G Eb C), slowed, on a low
  duduk-like reed. Hand drums, drone, bone marimba. Loop from bar 3.
dungeon_tomb: Ab aeolian, 4/4 at 90, 40 bars: A 16 | B 12 | coda 12.
  Phrase 7 (Db Eb Cb Ab) on a bone marimba; low drone, frame drum, dark choir.
place_cave: A dorian, 4/4 at 62, 24 bars: drone 4 | drips 16 | drone 4.
  Single notes of phrase 3 (C D E G F#) dripping as harp harmonics.
place_spring: E major, 4/4 at 68, 24 bars: harp alone 6 | A 10 | B 8.
  Phrase 1 in major (B G# A B) on a soft flute over harp arpeggios.

Run: python3 music/cues/t13_ossuary_tomb_cave_spring.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, voicing  # noqa: E402
from common import bars, low_root, sections, gate  # noqa: E402

# ---------------------------------------------------------------- ossuary
song = Song("region_ossuary")
reed = song.part("reed_duduk", program=68, vel=74)
drums = song.part("drum_hand", program=0, vel=70)
drone = song.part("drone", program=95, vel=50)
mar = song.part("marimba_bone", program=12, vel=58)
INTRO = ["Cm", "Cm"]
A = ["Cm", "Cm", "Db", "Cm", "Bbm", "Bbm", "Db", "Cm", "Fm", "Cm", "Db", "Db", "Bbm", "Ab", "Db", "Cm"]
B = ["Ab", "Ab", "Bbm", "Bbm", "Fm", "Db", "Eb", "Cm"]
A2 = ["Cm", "Cm", "Db", "Cm", "Bbm", "Bbm", "Db", "Cm", "Fm", "Db", "Bbm", "Db", "Cm", "Cm"]
CH = INTRO + A + B + A2
assert len(CH) == song.bars == 40
sec = sections([("INTRO", 0), ("A", 2), ("B", 18), ("A2", 26)])
P7 = "F4:2 G4:2 | Eb4:4 | C4:4 | r:4"  # phrase 7 slowed: each beat doubled
reed.line(song.bar(2), bars(P7 + " | Db4:2 Eb4:2 | F4:3 Eb4:1 | Db4:4 | C4:4 | "
                            "F4:2 Ab4:2 | G4:3 F4:1 | Ab4:2 F4:2 | Db4:4 | Bb3:2 Db4:2 | C4:2 Eb4:2 | F4:2 Db4:2 | C4:4"),
          legato=0.96)
reed.line(song.bar(26), bars(P7 + " | Db4:2 F4:2 | Ab4:4 | Db4:2 C4:2 | C4:4 | "
                             "Ab4:2 G4:2 | F4:4 | Db4:2 F4:2 | Ab4:4 | G4:4 | C4:4"), vel=70, legato=0.96)
for b, sym in enumerate(CH):
    t, s = song.bar(b), sec(b)
    if b % 2 == 0:
        drone.chord(t, 7.9, [36, 43], 50 if s != "B" else 44)
    if s == "INTRO":
        continue
    pat = [(0, 41, 78), (1.5, 50, 50), (2, 41, 62), (2.75, 50, 44), (3.5, 52, 54)]
    if s == "B":
        pat = [(0, 41, 70), (3, 50, 48)]
    for st, p, v in pat:
        drums.note(t + st, 0.25, p, v)
    if s == "B":  # B: the bone marimba takes the tune's place
        tones = voicing(sym, 60, 75)
        for k, p in enumerate((tones[0], tones[2], tones[1], tones[2 % len(tones)])):
            mar.note(t + k, 0.6, p + (12 if k == 2 else 0), 58)
    elif b % 2:
        mar.note(t + 3, 0.5, voicing(sym, 48, 58)[0], 46)  # under the reed
for i, p in enumerate(song.parts):
    p.humanize(seed=2300 + i, time_q=0.012)
song.save()
gate(song, CH, ("reed",), ("marimba",), "ossuary")

# ------------------------------------------------------------------ tomb
song = Song("dungeon_tomb")
bone = song.part("marimba_bone", program=12, vel=74)
drone = song.part("drone_low", program=95, vel=54)
drum = song.part("drum_frame", program=0, vel=72)
choir = song.part("choir_dark", program=52, vel=44)
A = ["Abm", "Abm", "Fb", "Abm", "Dbm", "Dbm", "Eb", "Eb", "Abm", "Gb", "Fb", "Abm", "Dbm", "Fb", "Eb", "Eb"]
B = ["Cb", "Gb", "Abm", "Ebm", "Fb", "Cb", "Dbm", "Eb", "Abm", "Fb", "Dbm", "Eb"]
CODA = ["Abm"] * 4 + ["Fb"] * 2 + ["Eb"] * 2 + ["Abm"] * 4
CH = A + B + CODA
assert len(CH) == song.bars == 40
sec = sections([("A", 0), ("B", 16), ("CODA", 28)])
P7 = "Db5:1 Eb5:1 Cb5:2"
bone.line(song.bar(0), bars(P7 + " | Ab4:4 | " + P7 + " | Ab4:2 Eb5:2 | Fb5:2 Eb5:1 Db5:1 | Cb5:2 Ab4:2 | Bb4:4 | G4:4 | "
                            + P7 + " | Bb4:2 Db5:2 | Cb5:2 Eb5:2 | Ab4:4 | Ab4:2 Fb4:2 | Ab4:2 Cb5:2 | Bb4:2 G4:2 | Eb4:4"),
          legato=0.7)
bone.line(song.bar(16), bars("Eb5:2 Cb5:2 | Db5:2 Bb4:2 | Cb5:2 Ab4:1 Eb4:1 | Gb4:2 Bb4:2 | Ab4:2 Cb5:2 | Gb4:2 Eb5:2 | "
                             "Fb5:2 Db5:2 | Eb5:4 | " + P7 + " | Ab4:4 | Fb4:2 Ab4:2 | G4:4"), vel=66, legato=0.7)
bone.line(song.bar(28), bars(P7 + " | Ab4:4 | r:4 | r:4 | Db5:4 | r:4 | Eb5:4 | r:4 | Cb5:4 | r:4 | Ab4:4 | r:4"),
          vel=58, legato=0.8)
for b, sym in enumerate(CH):
    t, s = song.bar(b), sec(b)
    if b % 2 == 0:
        drone.note(t, 7.9, low_root(sym, 32), 54)
    if s != "CODA" or b % 4 == 0:
        drum.note(t, 0.3, 41, 76)
        if s != "CODA":
            drum.note(t + 2.5, 0.3, 41, 52)
    if s in ("B", "CODA"):
        choir.chord(t, 3.95, voicing(sym, 50, 63)[:3], 44 if s == "B" else 38)
for i, p in enumerate(song.parts):
    p.humanize(seed=2400 + i, time_q=0.01)
song.save()
gate(song, CH, ("marimba",), ("choir",), "tomb")

# ------------------------------------------------------------------ cave
song = Song("place_cave")
harm = song.part("harp_harmonics", program=46, vel=52)
drone = song.part("drone", program=95, vel=46)
drips = song.part("pluck_drip", program=108, vel=44)
CH = ["Am"] * 4 + ["Am", "Am", "G", "G", "D", "D", "Am", "Am", "F", "F", "G", "G", "Am", "Am", "D", "D"] + ["Am"] * 4
assert len(CH) == song.bars == 24
# Phrase 3's notes, one drip at a time, at uneven distances.
DRIPS = [(4, 0.5, 72), (5, 2.5, 74), (6, 1.0, 76), (7, 3.0, 79), (8, 0.0, 78), (9, 2.0, 74), (10, 1.5, 72),
         (11, 3.5, 76), (12, 0.5, 77), (13, 2.0, 72), (14, 1.0, 79), (15, 3.0, 74), (16, 0.5, 76), (17, 2.5, 72),
         (18, 1.0, 78), (19, 3.0, 74)]
for b, s, p in DRIPS:
    harm.note(song.bar(b) + s, 2.5, p + 12, 50)
    drips.note(song.bar(b) + s + 0.75, 0.3, p, 30)  # its faint echo, lower
for b in range(0, 24, 4):
    drone.chord(song.bar(b), 15.9, [45, 52] if CH[b] == "Am" else [45, 52, 57], 46)
for i, p in enumerate(song.parts):
    p.humanize(seed=2500 + i, time_q=0.01, vel=3)
song.save()
gate(song, CH, ("none",), ("none",), "cave")

# ---------------------------------------------------------------- spring
song = Song("place_spring")
harp = song.part("harp", program=46, vel=56)
pad = song.part("pad_glass", program=92, vel=34)
flute = song.part("flute_soft", program=73, vel=64)
INTRO = ["E", "A", "E", "B", "C#m", "B"]
A = ["E", "G#m", "A", "B", "C#m", "A", "F#m", "B", "E", "E"]
B = ["A", "B", "G#m", "C#m", "F#m", "B", "A", "B"]
CH = INTRO + A + B
assert len(CH) == song.bars == 24
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = voicing(sym, 52, 76)
    fig = [low_root(sym, 40)] + tones[:6]
    for k, p in enumerate(fig[:8] if b < 6 else fig[:6]):
        harp.note(t + k * 0.5, 2.0, p, 58 if k == 0 else 48)
    if b >= 6:
        pad.chord(t, 3.95, voicing(sym, 56, 68)[:3], 32)
flute.line(song.bar(6), bars("B4:2 G#4:1.5 A4:0.5 | B4:4 | C#5:2 E5:2 | D#5:4 | E5:2 C#5:2 | E5:3 r:1 | "
                             "F#5:2 A5:1 F#5:1 | D#5:4 | E5:4 | r:4"), legato=0.94)
flute.line(song.bar(16), bars("C#5:2 E5:1 A5:1 | F#5:3 D#5:1 | E5:2 B4:2 | G#4:2 C#5:2 | A4:2 C#5:2 | "
                              "D#5:3 B4:1 | E5:2 C#5:1 A4:1 | F#4:2 D#5:2"), vel=60, legato=0.94)
for i, p in enumerate(song.parts):
    p.humanize(seed=2600 + i, time_q=0.01, vel=3)
song.save()
gate(song, CH, ("flute",), ("pad",), "spring")
