"""The Rotting Hull (dungeon_hull): dungeon 1, the Point Bell's wreck.

D dorian, 6/8 at 52 dotted-quarter (FL tempo 78), 48 bars, loops whole:
A 16 (cello sings lullaby phrase 1, slowed to dotted quarters, with its own
answer) | B 12 (bass clarinet takes the tune, cello holds) | A' 12 (phrase 1
an octave up, strings fuller) | bridge 8 (only creaks, drum and bass, which
lead back to A). The low strings sway like the ship: every bar leans in and
out.

Run: python3 music/cues/t05_dungeon_hull.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of, phrase_items  # noqa: E402

E = 0.5
song = Song("dungeon_hull")
cello = song.part("cello", program=42, vel=82)
clarinet = song.part("bassclarinet", program=71, vel=74)
strings = song.part("strings_low", program=48, vel=50)
harp = song.part("harp", program=46, vel=48)
creak = song.part("perc_woodblock", program=115, vel=50)
drum = song.part("drum_deep", program=116, vel=80)
bass = song.part("bass_arco", program=43, vel=74)

A = ["Dm", "Dm", "Dm", "Am", "F", "G", "Dm", "Am",
     "Dm", "Dm", "Dm", "C", "Bb", "F/A", "Gm", "A"]
B = ["F", "C/E", "Dm", "Dm", "Bb", "F/A", "G", "G", "Dm", "Am", "Bb", "A"]
A2 = ["Dm", "Dm", "Dm", "Am", "F", "G", "Dm", "C", "Bb", "Gm", "Asus4", "A"]
BRIDGE = ["Dm", "Dm", "Dm", "Dm", "Bb", "Bb", "A", "A"]
CHORDS = A + B + A2 + BRIDGE
assert len(CHORDS) == song.bars == 48
SEC = [("A", 0), ("B", 16), ("A2", 28), ("BRIDGE", 40)]


def section(b):
    return [k for k, v in SEC if v <= b][-1]


slow1 = phrase_items(0, transpose=-12, beat=1.5)  # A F G A on cello, 3 bars
# A: phrase 1, an answer, phrase 1 again, a different answer that turns home.
cello.line(song.bar(0), slow1 + seq("E3:3 C3:3", E), legato=0.96)
cello.line(song.bar(4), seq("F3:4 E3:2 | D3:3 G3:3 | A3:5 r:1 | E3:6".replace("|", ""), E), vel=76, legato=0.96)
cello.line(song.bar(8), slow1 + seq("G3:3 E3:3", E), legato=0.96)
cello.line(song.bar(12), seq("F3:4 D3:2 | A3:3 F3:3 | G3:3 Bb3:3 | C#4:6".replace("|", ""), E), vel=78, legato=0.96)
# B: the cello holds long notes under the clarinet's tune.
for b in range(16, 28, 2):
    tones = voicing(CHORDS[b], 48, 60)
    cello.note(song.bar(b), song.bar_q * 2 * 0.97, tones[0], 62)
clarinet.line(song.bar(16), seq("""
A3:3 C4:3 | G3:4 E3:2 | F3:2 A3:1 D4:3 | C4:6 |
D4:3 F4:2 D4:1 | C4:4 A3:2 | B3:3 D4:3 | G3:6 |
A3:2 F3:1 D3:3 | E3:4 C4:2 | D4:3 Bb3:3 | C#4:6
""".replace("|", ""), E), legato=0.95)
# A': phrase 1 an octave higher, the answer reshaped.
cello.line(song.bar(28), phrase_items(0, beat=1.5) + seq("E4:3 C4:3", E), vel=84, legato=0.96)
cello.line(song.bar(32), seq("F4:4 E4:2 | D4:3 B3:3 | A3:6 | G3:3 E3:3".replace("|", ""), E), vel=78, legato=0.96)
cello.line(song.bar(36), seq("D4:4 F4:2 | D4:3 Bb3:3 | A3:6 | E3:5 r:1".replace("|", ""), E), vel=74, legato=0.96)

# Low strings sway: each bar swells in on beat 1 and eases on beat 2.
for b, sym in enumerate(CHORDS):
    if section(b) == "BRIDGE":
        continue
    tones = voicing(sym, 41, 57)[:3]
    full = section(b) == "A2"
    strings.chord(song.bar(b), 3 * E * 0.98, tones, 54 if full else 46)
    strings.chord(song.bar(b) + 3 * E, 3 * E * 0.98, tones, 40 if full else 34)

# Harp: a single high drip now and then (water through the planks).
for b, sym in enumerate(CHORDS):
    if b % 3 == 1 and section(b) != "BRIDGE":
        top = voicing(sym, 74, 86)
        harp.note(song.bar(b) + 5 * E, 1.5, top[(b // 3) % len(top)], 44)

# Creaks: slow off-beat knocks; denser in the bridge.
for b in range(song.bars):
    hits = [(2 * E, 46)] if b % 2 else [(5 * E, 40)]
    if section(b) == "BRIDGE":
        hits = [(E, 52), (2 * E, 40), (4 * E, 48)]
    for s, v in hits:
        creak.note(song.bar(b) + s, E * 0.5, 76, v)

# Deep drum on every downbeat, a softer second hit in A' and the bridge.
for b in range(song.bars):
    drum.note(song.bar(b), E, 36, 84)
    if section(b) in ("A2", "BRIDGE"):
        drum.note(song.bar(b) + 3 * E, E, 36, 58)

# Bowed bass: roots, holding two bars; in the bridge it walks up to A.
for b, sym in enumerate(CHORDS):
    root = 26 + (bass_of(sym) - 2) % 12  # D1..C#2 -> keep in 31..48
    root = root + 12 if root < 31 else root
    if section(b) == "BRIDGE":
        bass.line(song.bar(b), seq(["D2:6", "D2:3 F2:3", "G2:6", "F2:3 E2:3", "Bb1:6", "C2:6", "A1:6", "C#2:3 E2:3"][b - 40], E),
                  vel=70, legato=0.96)
    elif b % 2 == 0:
        bass.note(song.bar(b), song.bar_q * (2 if CHORDS[b + 1] == sym else 1) * 0.97, root, 72)
    elif CHORDS[b - 1] != sym:
        bass.note(song.bar(b), song.bar_q * 0.97, root, 68)

for i, p in enumerate(song.parts):
    p.humanize(seed=500 + i)
song.save()

if "--gate" in sys.argv:
    from gate_midi import check
    for problem in check(song, CHORDS, melody=("cello", "bassclarinet"), comp=("harp_none",)):
        print("GATE:", problem)
