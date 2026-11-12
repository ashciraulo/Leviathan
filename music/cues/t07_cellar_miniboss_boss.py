"""Cellar Steps (dungeon_cellar), Teeth in the Dark (miniboss), Wake Not the Deep (boss).

dungeon_cellar: A minor, 4/4 at 96, 32 bars: A 8 | A' 8 | B 12 | A'' 4 that
  stops short and creeps back. Pizzicato ostinato in lullaby phrase 7's
  rhythm (short short long long), bassoon-like reed tune, soft tom, harp.
miniboss: G minor, 4/4 at 152, 16 bars: A 8 | B 8. Staccato low strings,
  toms, brass stabs on phrase 4's first three notes (D C Bb in G minor).
boss: C minor, 4/4 at 156, 56 bars: intro 2 (hits) | A 16 (ostinato + brass)
  | B 8 (choir; phrase 1 augmented on low brass: G Eb F G) | C 8 (drums alone,
  then a build) | D 16 (brass melody) | A' 6. The loop starts at bar 3.

Run: python3 music/cues/t07_cellar_miniboss_boss.py [--preview] [--gate]
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


# ----------------------------------------------------------------- cellar
song = Song("dungeon_cellar")
pizz = song.part("strings_pizz", program=45, vel=70)
reed = song.part("bassoon", program=70, vel=74)
tom = song.part("drum_tom", program=0, vel=60)
harp = song.part("harp", program=46, vel=50)
A = ["Am", "Am", "Dm", "Am", "F", "E", "Am", "E"]
A2 = ["Am", "Am", "Dm", "Am", "F", "Dm", "E", "E"]
B = ["F", "G", "C", "Am", "F", "G", "E", "Am", "Dm", "Am", "Bb", "E"]
A3 = ["Am", "Am", "Dm", "E"]
CH = A + A2 + B + A3
assert len(CH) == song.bars
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = voicing(sym, 50, 64)
    root = low_root(sym, 45)
    if b in (29, 30):  # A'' stops short: the harp breathes under it (below), the pizz rests
        continue
    if b == 31:  # creeps back: two soft plucks, then the bassoon's pickup
        pizz.note(t + 2, 1.05, root, 44)
        pizz.note(t + 3, 1.2, root + 12, 40)
        reed.note(t + 3, 0.9, 52, 58)  # E3 pickup back into bar 1, so the loop creeps back instead of slamming in
        continue
    # phrase 7's rhythm, short short long long: root, top, the chord's third, octave root
    # (review v4 MINOR 1: tones[1] was the octave root on Am, so Am bars had no C).
    third = (bass_of(sym) + (3 if sym.endswith("m") else 4)) % 12
    mid = next(p for p in tones if p % 12 == third)
    if mid == 56:  # Pizzi Bass's G#3 is inharmonic (-26 c on every render): the E chord's third goes up an octave
        mid = 68
    top = tones[-1] if tones[-1] != root + 12 else tones[-2]
    # Each pluck rings just past the next one, so its attack hides the note-off. The last pluck before
    # the A'' rest rings out (review v4 MAJOR 1: it cut dead at bar 30's downbeat).
    beat3 = b % 2 or 16 <= b < 28
    last = 4.0 if b == 28 else 2.0
    # Pizzi Bass has two velocity layers that switch at 63/64 (review v7 MAJOR 1): every figure note stays
    # in the loud layer, at least 6 steps clear of the switch, and the creep-back plucks sit in the soft one.
    for s_, ln, p, v in ((0, 0.55, root, 74), (0.5, 0.55, top, 70), (1, 1.05, mid, 72),
                         (2, 1.05 if beat3 else last, root + 12, 72)):
        pizz.note(t + s_, ln, p, v)
    if beat3:
        pizz.note(t + 3, 1.05, mid if sym.endswith("m") else tones[0], 70)
reed.line(song.bar(0), bars("A3:1 C4:1 E4:2 | D4:1 C4:1 A3:2 | F4:2 E4:1 D4:1 | E4:3 r:1 | "
                            "C4:1 D4:1 E4:1 F4:1 | G#3:3 r:1 | A3:1 B3:1 C4:1 E4:1 | B3:4"), legato=0.95)
reed.line(song.bar(8), bars("A3:1 C4:1 E4:2 | A4:2 G4:1 E4:1 | F4:2 A4:1 F4:1 | E4:3 r:1 | "
                            "C4:2 A3:1 C4:1 | D4:2 F4:2 | E4:1 D4:1 B3:2 | G#3:3 r:1"), vel=70, legato=0.95)
reed.line(song.bar(16), bars("C4:2 A3:2 | B3:2 D4:2 | E4:3 G4:1 | E4:3 r:1 | A3:2 C4:2 | D4:2 B3:2 | "
                             "G#3:3 B3:1 | A3:3 r:1 | F3:2 A3:2 | E3:2 C4:2 | D4:2 F4:2 | E4:4"), vel=66, legato=0.88)
reed.line(song.bar(28), bars("A3:1 C4:1 E4:2 | r:4 | r:4 | r:4"), vel=62, legato=0.85)
for b in range(song.bars):
    if b in (29, 30):
        tom.note(song.bar(b) + 2, 0.3, 45, 40)
    elif b == 31:
        tom.note(song.bar(b) + 3.5, 0.3, 45, 50)
    elif b < 29 and b % 2:
        tom.note(song.bar(b) + 3.5, 0.3, 45, 52)
# The A'' rest: a slow, soft harp line keeps the cellar breathing (review v4 MAJOR 1: bars 30-31 fell to
# digital silence between two tom hits).
harp.line(song.bar(29), [(69, 2), (64, 2), (60, 2), (57, 2)], vel=40, legato=1.6)
for b, sym in enumerate(CH):
    if 16 <= b < 28 and b % 2 == 0:
        top = voicing(sym, 69, 84)
        for k, p in enumerate(top[:3]):
            harp.note(song.bar(b) + 1 + k * 0.5, 1.5, p, 48)
for i, p in enumerate(song.parts):
    p.humanize(seed=900 + i, vel=2 if p is pizz else 6)  # pizz: 6 velocity steps are 3.5 dB
song.save()
gate(song, CH, ("bassoon",), ("harp_none",), "cellar")

# --------------------------------------------------------------- miniboss
song = Song("miniboss")
low = song.part("strings_staccato", program=48, vel=86)
tom = song.part("drum_toms", program=0, vel=88)
brass = song.part("brass_stab", program=61, vel=94)
A = ["Gm", "Gm", "Eb", "D", "Gm", "Gm", "Cm", "D"]
B = ["Eb", "F", "Gm", "Gm", "Eb", "F", "D", "D"]
CH = A + B
for b, sym in enumerate(CH):
    t = song.bar(b)
    root = low_root(sym, 38)
    # The last eighth is the flat seventh on every chord (review v2 NOTE 2: C#3 on the D bars left G minor).
    fig = [root, root, root + 12, root, root + 7, root, root + 12, root + 10]
    if b >= 8:
        fig = [root, root + 7, root + 12, root + 7] * 2
    for k, p in enumerate(fig):
        low.note(t + k * 0.5, 0.28, p, 110 if k % 4 == 0 else 72)  # Staccato Blend gives ~0.16 dB/step (review v4)
    for s, p, v in ((0, 45, 96), (1, 47, 70), (1.5, 47, 64), (2, 45, 88), (3, 48, 72), (3.5, 50, 80)):
        tom.note(t + s, 0.25, p, v)
    if b % 2 == 0:  # the stab: D C Bb (phrase 4's head), or its answer
        notes = [(62, 0.5), (60, 0.5), (58, 1)] if b < 8 else [(63, 0.5), (65, 0.5), (67, 1)]
        tt = t + (0 if b % 4 == 0 else 2)
        for p, d in notes:
            brass.chord(tt, d * 0.7, [p, p - 5] if b >= 8 else [p, p - 12], 96)
            tt += d
for i, p in enumerate(song.parts):
    p.humanize(seed=1000 + i, time_q=0.006)
song.save()

# ------------------------------------------------------------------- boss
song = Song("boss")
drums = song.part("drum_taiko", program=0, vel=96)
timp = song.part("timpani", program=47, vel=80)
ost = song.part("strings_ostinato", program=48, vel=82)
lowbrass = song.part("brass_low", program=57, vel=88)
horns = song.part("horns_brass", program=60, vel=84)
choir = song.part("choir", program=52, vel=66)
INTRO = ["Cm", "Cm"]
A = ["Cm", "Cm", "Ab", "Ab", "Fm", "Fm", "G", "G", "Cm", "Cm", "Db", "Db", "Bb", "Bb", "G", "G"]
B = ["Cm", "Cm", "Ab", "Fm", "Cm", "G", "Ab", "Bb"]
C = ["Cm"] * 6 + ["G", "G"]
D = ["Ab", "Eb", "Fm", "Cm", "Ab", "Eb", "Db", "G", "Ab", "Bb", "Gm", "Cm", "Fm", "Ab", "G", "G"]
A2 = ["Cm", "Ab", "Fm", "G", "G", "G"]
CH = INTRO + A + B + C + D + A2
assert len(CH) == song.bars == 56
SEC = [("INTRO", 0), ("A", 2), ("B", 18), ("C", 26), ("D", 34), ("A2", 50)]


def section(b):
    return [k for k, v in SEC if v <= b][-1]


for b, sym in enumerate(CH):
    t, sec = song.bar(b), section(b)
    root = low_root(sym, 36)
    # Drums: hits in the intro, a driving pattern, alone in C, a build at its end.
    if sec == "INTRO":
        for s in (0, 1.5, 3):
            drums.note(t + s, 0.4, 36, 110)
            timp.note(t + s, 0.6, root, 92)
        continue
    pat = [(0, 36, 108), (0.75, 38, 70), (1.5, 36, 90), (2, 38, 96), (3, 36, 84), (3.5, 38, 78)]
    if sec == "C" and b >= 32:
        pat = [(k * 0.25, 38, 60 + (b - 32) * 12 + k * 2) for k in range(16)]
    for s, p, v in pat:
        drums.note(t + s, 0.2, p, min(127, v))
    if sec != "C":
        timp.note(t, 0.8, root, 84)
    # Ostinato: sixteenths on the root with a rising turn; silent in C.
    if sec != "C":
        fig = [0, 0, 12, 0, 7, 0, 12, 8 if "m" in sym else 7] * 2  # review v7: +8 on Ab/Db gave E and A
        for k, iv in enumerate(fig):
            ost.note(t + k * 0.25, 0.18, 48 + (bass_of(sym) - 48) % 12 + iv, 104 if k % 4 == 0 else 66)
for b in range(2, 18, 2):  # A: brass answers the ostinato
    sym = CH[b]
    tones = voicing(sym, 55, 70)
    horns.chord(song.bar(b) + 2.5, 1.4, tones[:3], 92)
# B: phrase 1 augmented on low brass (G Eb F G, beats doubled), choir over it.
lowbrass.line(song.bar(18), [(43, 8), (39, 4), (41, 4), (43, 8), (39, 4), (41, 2), (38, 2)], vel=96, legato=0.96)
for b in range(18, 26):
    choir.chord(song.bar(b), 3.9, voicing(CH[b], 60, 74)[:3], 70)
lowbrass.line(song.bar(32), [(43, 8)], vel=80)  # under the build
# D: the brass melody.
horns.line(song.bar(34), bars(
    "C5:3 Eb5:1 | Bb4:4 | Ab4:2 C5:2 | G4:4 | C5:2 Eb5:1 F5:1 | G5:3 Eb5:1 | F5:2 Ab4:2 | B4:4 | "
    "C5:2 Eb5:2 | D5:3 F5:1 | D5:2 Bb4:2 | C5:4 | Ab4:2 C5:2 | Eb5:2 C5:2 | D5:3 B4:1 | G4:4"), legato=0.92)
# The trumpet sample is a one-shot that dies after ~408/f0 s (review v7 MAJOR 2): the choir doubles the melody
# softly so the long phrase endings keep sounding.
for t_, ln, p, _v in [n for n in horns.notes if song.bar(34) - 1e-6 <= n[0] < song.bar(50)]:
    choir.note(t_, ln, p, 58)
for b in range(34, 50):
    lowbrass.note(song.bar(b), 3.9, low_root(CH[b], 34), 74)
for b in range(50, 56):  # A': ostinato returns with brass hits, G pedal to the loop
    horns.chord(song.bar(b) + 2.5, 1.4, voicing(CH[b], 55, 70)[:3], 90)
for i, p in enumerate(song.parts):
    p.humanize(seed=1100 + i, time_q=0.006)
song.save()
gate(song, CH, ("horns",), (), "boss")  # the choir doubles the D melody, so it is not comping
