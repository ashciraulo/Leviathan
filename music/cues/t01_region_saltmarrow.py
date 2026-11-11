"""Salt on the Sill (region_saltmarrow): Saltmarrow, the home village.

F major, 6/8 at 67 dotted-quarter (FL tempo 100.5), 66 bars:
intro 2 (guitar alone) | A 16 flute | A' 8 reed | B 16 (reed sings lullaby
phrase 1, flute answers) | C 8 (flute rests) | A'' 16, ending on C to lead
back into A. The loop runs from bar 3 to the end.

Run: python3 music/cues/t01_region_saltmarrow.py [--preview]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of, n, phrase_items  # noqa: E402

E = 0.5  # an eighth note, in quarters
song = Song("region_saltmarrow")
guitar = song.part("guitar_nylon", program=24, vel=70)
flute = song.part("flute_wood", program=73, vel=84)
reed = song.part("reed_concertina", program=21, vel=74)
bass = song.part("bass_upright", program=32, vel=88)
pad = song.part("pad_strings", program=48, vel=46)
drum = song.part("drum_frame", program=0, vel=90)
shaker = song.part("shaker", program=0, vel=60)

INTRO = ["F", "Csus4"]
A = ["F", "F", "Bb", "F", "Dm", "Bb", "C", "C", "F", "Am", "Bb", "Gm", "F/A", "Bb", "Csus4", "F"]
A2 = ["F", "C/E", "Dm", "Bb", "F/C", "C", "F", "F"]
B = ["Dm", "Dm", "Bb", "C", "Dm", "Am", "Bb", "C", "Gm", "C", "Bb", "F", "Dm", "Am", "Bb", "C"]
C = ["Bb", "F/A", "Gm", "F", "Bb", "C/Bb", "Am", "Dm"]
A3 = A[:14] + ["Bb", "C"]
CHORDS = INTRO + A + A2 + B + C + A3
assert len(CHORDS) == song.bars == 66
SEC = {"intro": 0, "A": 2, "A2": 18, "B": 26, "C": 42, "A3": 50}


def section(b):
    return [k for k, v in sorted(SEC.items(), key=lambda kv: kv[1]) if v <= b][-1]


def bars(text):
    """seq() over '|'-separated bars, checking each bar is exactly 6 eighths."""
    for i, chunk in enumerate(text.split("|")):
        total = sum(d for _, d in seq(chunk))
        assert total == 6, f"bar {i + 1} has {total} eighths: {chunk.strip()}"
    return seq(text.replace("|", ""), E)


# --- guitar: a different picking figure per section ---
for b, sym in enumerate(CHORDS):
    t = song.bar(b)
    sec = section(b)
    root = 41 + (bass_of(sym) - 5) % 12  # F2..E3 bass string
    tones = voicing(sym, 53, 69)
    if sec in ("intro", "A", "A3"):
        # bass, then up and back down the chord: 1 . 5 . 8 . 10 . 8 . 5 (6 eighths)
        fig = [root, tones[0], tones[1], tones[2], tones[1], tones[0]]
        if sec == "A3" and b % 4 == 3:  # every fourth bar of A'' turns around on top
            fig = [root, tones[1], tones[2], tones[3] if len(tones) > 3 else tones[2] + 12, tones[2], tones[1]]
        for i, p in enumerate(fig):
            guitar.note(t + i * E, E * 1.6, p, 72 if i in (0, 3) else 60)
    elif sec in ("A2", "B"):
        # bass on 1, two-note chord on 2-3 and 5-6 (strummed lightly)
        guitar.note(t, 3 * E, root, 74)
        for i in (1, 4):
            guitar.chord(t + i * E, 2 * E, tones[1:3], 58, roll=0.02)
        if sec == "B" and b % 2:
            guitar.note(t + 3 * E, E, tones[0], 56)
    else:  # C: rolled full chord on 1 and 4, then a passing note
        guitar.chord(t, 3 * E, [root] + tones[:3], 64, roll=0.04)
        guitar.chord(t + 3 * E, 2 * E, tones[:3], 56, roll=0.04)
        guitar.note(t + 5 * E, E, tones[0] - (1 if tones[0] % 12 in (0, 5) else 2), 52)

# --- flute: the A tune, its answers in B, and the varied A'' ---
A_TUNE = """
C5:2 A4:1 F4:2 A4:1 | C5:3 D5:2 C5:1 | D5:2 C5:1 Bb4:2 D5:1 | C5:5 r:1 |
A4:2 Bb4:1 C5:2 D5:1 | F5:3 D5:2 Bb4:1 | C5:2 Bb4:1 A4:2 G4:1 | G4:5 r:1 |
C5:2 A4:1 F4:2 A4:1 | E5:3 C5:2 A4:1 | D5:2 F5:1 D5:2 Bb4:1 | G4:2 A4:1 Bb4:2 D5:1 |
C5:2 A4:1 C5:2 F5:1 | D5:3 C5:2 Bb4:1 | Bb4:2 A4:1 G4:3 | F4:5 r:1
"""
A3_TUNE = """
C5:2 A4:1 F4:1 G4:1 A4:1 | C5:3 D5:1 E5:1 F5:1 | D5:2 C5:1 Bb4:2 D5:1 | C5:5 r:1 |
A4:2 Bb4:1 C5:2 D5:1 | F5:3 D5:2 Bb4:1 | C5:2 Bb4:1 A4:1 Bb4:1 G4:1 | G4:5 r:1 |
C5:2 A4:1 F4:2 A4:1 | E5:3 C5:2 A4:1 | D5:2 F5:1 D5:2 Bb4:1 | G4:2 A4:1 Bb4:2 D5:1 |
C5:2 A4:1 C5:2 F5:1 | D5:3 C5:2 Bb4:1 | D5:2 C5:1 Bb4:2 A4:1 | G4:3 E4:1 F4:1 G4:1
"""
flute.line(song.bar(SEC["A"]), bars(A_TUNE), legato=0.92)
flute.line(song.bar(SEC["A3"]), bars(A3_TUNE), legato=0.92)
# B: the flute only answers, in the bars the reed's lullaby leaves open.
for bar, text in ((2, "D5:3 F5:3"), (3, "E5:5 r:1"), (6, "F5:2 D5:1 Bb4:3"), (7, "C5:2 D5:1 E5:3"),
                  (10, "F5:3 D5:2 C5:1"), (11, "C5:5 r:1"), (14, "D5:2 C5:1 Bb4:2 A4:1"), (15, "G4:5 r:1")):
    flute.line(song.bar(SEC["B"] + bar), seq(text, E), vel=76, legato=0.9)

# --- reed: carries A', sings the lullaby in B, holds a slow line in C ---
A2_TUNE = """
A4:2 G4:1 F4:2 C5:1 | C5:3 G4:3 | A4:2 Bb4:1 C5:2 D5:1 | D5:3 F5:3 |
C5:2 A4:1 F4:2 G4:1 | E4:3 G4:2 Bb4:1 | A4:6 | r:6
"""
reed.line(song.bar(SEC["A2"]), bars(A2_TUNE), legato=0.95)
# Lullaby phrase 1 (A F G A) is already in F major's notes; a 3/4 beat
# becomes two eighths, so each phrase fills exactly two bars of 6/8.
p1 = phrase_items(0, beat=2 * E)
p2 = phrase_items(1, beat=2 * E)
for bar, items, vel in ((0, p1, 78), (4, p1, 72), (8, p2, 76), (12, p1, 70)):
    reed.line(song.bar(SEC["B"] + bar), items, vel=vel, legato=0.97)
C_LINE = "D5:6 C5:6 Bb4:3 D5:3 C5:6 D5:3 F5:3 E5:6 C5:3 E5:3 D5:4 r:2"
reed.line(song.bar(SEC["C"]), seq(C_LINE, E), vel=66, legato=0.97)

# --- upright bass: dotted quarters in A, longer notes in B, a walk in C ---
for b, sym in enumerate(CHORDS):
    if b < SEC["A"]:
        continue
    t, sec = song.bar(b), section(b)
    root = 29 + (bass_of(sym) - 5) % 12 + 12  # F2..E3
    fifth = root + 7 if root + 7 <= 55 else root - 5
    nxt = CHORDS[(b + 1) if b + 1 < len(CHORDS) else SEC["A"]]
    nroot = 41 + (bass_of(nxt) - 5) % 12
    if sec in ("A", "A3"):
        bass.note(t, 3 * E * 0.9, root, 88)
        bass.note(t + 3 * E, 3 * E * 0.85, fifth, 76)
        if sec == "A3" and b % 4 == 3:  # approach note into the next bar
            bass.note(t + 5 * E, E * 0.8, nroot + (1 if nroot < root else -1), 70)
    elif sec in ("A2", "B"):
        bass.note(t, 5 * E * 0.92, root, 84)
        bass.note(t + 5 * E, E * 0.8, fifth if b % 2 else root, 66)
    else:
        for i, p in enumerate((root, root + 4 if "m" not in sym else root + 3, fifth)):
            bass.note(t + i * 2 * E, 2 * E * 0.9, p, 80 - 6 * i)

# --- string pad: B and A'' only, low and soft, under everything ---
for b, sym in enumerate(CHORDS):
    if section(b) in ("B", "A3", "C"):
        pad.chord(song.bar(b), song.bar_q * 0.98, voicing(sym, 50, 64)[:3], 42 if section(b) != "C" else 48)

# --- frame drum and shaker: none in the intro, frame drum alone in B and C ---
for b in range(SEC["A"], song.bars):
    t, sec = song.bar(b), section(b)
    drum.note(t, E, 45, 92)
    drum.note(t + 3 * E, E, 45, 64 if sec != "C" else 52)
    if sec in ("A", "A2", "A3"):
        if b % 2:
            drum.note(t + 5 * E, E, 45, 50)
        for i in range(6):
            shaker.note(t + i * E, E * 0.5, 82, 58 if i in (0, 3) else 40)

for i, p in enumerate(song.parts):
    p.humanize(seed=100 + i)
song.save()

if "--gate" in sys.argv:
    from gate_midi import check
    for problem in check(song, CHORDS):
        print("GATE:", problem)
