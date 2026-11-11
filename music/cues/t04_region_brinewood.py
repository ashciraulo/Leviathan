"""Under the Mangrove (region_brinewood): Brinewood, the mangrove forest.

E dorian, 4/4 at 100, 56 bars, loops whole:
A 16 (marimba hook alone, then hand drums and bass) | B 8 (flute tune over a
lifted progression) | A' 16 (hook + flute counter-line) | C 8 (drums drop
out, kalimba and pad) | tag 8 (hook in pieces, leading back to A).
The marimba hook is lullaby phrase 3's opening rise (F G A C -> Bb), set on
the same scale degrees in E dorian: G A B D -> C#.

Run: python3 music/cues/t04_region_brinewood.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of  # noqa: E402

S = 0.25  # a sixteenth
song = Song("region_brinewood")
marimba = song.part("marimba", program=12, vel=78)
kalimba = song.part("kalimba", program=108, vel=58)
flute = song.part("flute_wood", program=73, vel=80)
drums = song.part("drum_hand", program=0, vel=80)
bass = song.part("bass_fretless", program=35, vel=84)
pad = song.part("pad_warm", program=89, vel=40)

A = ["Em7", "A", "Em7", "A", "G", "D", "Bm7", "A",
     "Em7", "A", "Em7", "A", "Cmaj7", "G", "Asus4", "A"]
B = ["G", "D/F#", "Em7", "A", "G", "Bm7", "Asus4", "A"]
A2 = A[:12] + ["G", "D", "Bm7", "A"]
C = ["Em7", "Em7", "Cmaj7", "Cmaj7", "Am7", "Am7", "Bm7", "Bm7"]
TAG = ["Em7", "A", "Em7", "A", "G", "D", "Asus4", "A"]
CHORDS = A + B + A2 + C + TAG
assert len(CHORDS) == song.bars == 56
SEC = [("A", 0), ("B", 16), ("A2", 24), ("C", 40), ("TAG", 48)]


def section(b):
    return [k for k, v in SEC if v <= b][-1]


# The hook: G A B D | C#, two bars, sixteenth-note pickup feel.
HOOK = "G4:1 A4:1 B4:2 D5:3 C#5:1 | B4:2 A4:2 r:2 E4:1 G4:1"
HOOK2 = "G4:1 A4:1 B4:2 D5:3 E5:1 | F#5:2 E5:1 D5:1 B4:2 A4:2"  # the answer, rising instead
for b in range(0, song.bars, 2):
    sec = section(b)
    t = song.bar(b)
    if sec in ("A", "A2"):
        text = HOOK if (b // 2) % 2 == 0 else HOOK2
        if sec == "A2" and b % 8 == 6:
            text = "G4:1 A4:1 B4:1 D5:1 E5:2 D5:2 | B4:1 A4:1 G4:2 E4:4"  # third ending
        marimba.line(t, seq(text.replace("|", ""), 0.5), vel=82 if sec == "A" else 74, legato=0.8)
    elif sec == "TAG":
        # The hook in pieces: just its first four notes, then rests.
        marimba.line(t, seq("G4:1 A4:1 B4:2 D5:3 r:9", 0.5), vel=70, legato=0.8)
    elif sec == "B":
        # Marimba steps back to rolled chords on 1 and the "and" of 2.
        for bb in (b, b + 1):
            tones = voicing(CHORDS[bb], 57, 72)[:3]
            marimba.chord(song.bar(bb), 1.4, tones, 62, roll=0.03)
            marimba.chord(song.bar(bb) + 1.5, 1.0, tones, 54, roll=0.03)

# Kalimba: offbeat sparkles in A', and the lead voice of C.
for b, sym in enumerate(CHORDS):
    sec = section(b)
    tones = voicing(sym, 72, 86)
    if sec == "A2" and b % 2 == 1:
        for k, s in enumerate((1.5, 2.5, 3.5)):
            kalimba.note(song.bar(b) + s, 0.4, tones[k % len(tones)], 52)
    elif sec == "C":
        line = {0: "B5:2 G5:1 E5:1", 1: "G5:3 r:1", 2: "E5:2 B4:1 G5:1", 3: "E5:4",
                4: "C6:2 A5:1 E5:1", 5: "G5:3 r:1", 6: "F#5:2 D5:1 B4:1", 7: "A4:2 r:2"}[b - 40]
        kalimba.line(song.bar(b), seq(line), vel=60, legato=0.9)

# Flute: the B tune, then a counter-line high over the hook in A'.
flute.line(song.bar(16), seq("""
D5:3 B4:1 | A4:2 F#4:1 A4:1 | B4:3 G4:1 | E5:4 |
D5:1 E5:1 F#5:2 | D5:2 B4:2 | A4:3 B4:1 | C#5:4
""".replace("|", "")), legato=0.92)
for b in range(24, 40, 4):
    # Over Em7 A Em7 A, then over G D Bm7 A; always above the marimba's top note.
    text = "B5:4 | A5:3 r:1 | G5:2 E5:2 | A5:4" if CHORDS[b] == "Em7" else "B5:4 | A5:3 r:1 | F#5:4 | E5:2 C#5:2"
    flute.line(song.bar(b), seq(text.replace("|", "")), vel=66, legato=0.95)

# Hand drums: a low-high conversation, busier in A', absent in C.
for b in range(song.bars):
    sec = section(b)
    t = song.bar(b)
    if sec == "C" or (sec == "A" and b < 4):
        continue
    low, high, slap = 41, 50, 52
    pattern = [(0, low, 88), (1.5, high, 62), (2, low, 70), (3, high, 66), (3.5, high, 50)]
    if sec in ("A2", "TAG") and b % 2:
        pattern += [(2.75, slap, 48), (0.75, high, 44)]
    if sec == "B":
        pattern = [(0, low, 84), (2, low, 72), (3, high, 60)]
    for s, p, v in pattern:
        drums.note(t + s, S * 1.5, p, v)

# Fretless bass: root and a pushed fifth, sliding note into each A bar pair.
for b, sym in enumerate(CHORDS):
    sec = section(b)
    if sec == "A" and b < 4:
        continue
    t = song.bar(b)
    root = 28 + (bass_of(sym) - 4) % 12  # E1..D#2
    if root < 33:
        root += 12
    fifth = root + 7
    if sec == "C":
        bass.note(t, 3.9, root, 74)
    elif sec == "B":
        bass.note(t, 1.5, root, 84)
        bass.note(t + 1.5, 2.4, root + 12 if root < 40 else fifth, 72)
    else:
        bass.note(t, 0.9, root, 88)
        bass.note(t + 1.5, 0.45, fifth, 70)
        bass.note(t + 2, 1.4, root + 12 if root + 12 <= 52 else root, 76)
        if b % 2:
            bass.note(t + 3.5, 0.45, fifth - 2, 64)

# Warm pad: under B and C only.
for b, sym in enumerate(CHORDS):
    if section(b) in ("B", "C"):
        pad.chord(song.bar(b), 3.95, voicing(sym, 52, 66)[:3], 38)

for i, p in enumerate(song.parts):
    p.humanize(seed=400 + i)
song.save()

if "--gate" in sys.argv:
    from gate_midi import check
    for problem in check(song, CHORDS, melody=("flute", "kalimba"), comp=("pad", "marimba")):
        print("GATE:", problem)
