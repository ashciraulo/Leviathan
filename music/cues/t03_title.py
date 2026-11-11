"""The Tide Breathes (title): the title screen.

D aeolian, 3/4 at 66, 36 bars: intro 4 (a lone distant bell plays phrase 1,
then rings) | swell A 16 (harp and low strings; a low swell every 8 bars, the
tide breathing) | B 16 (flute sings phrases 1 and 2, answers, then 1 and 2
again an octave up, and breathes out on A to lead back into the swell).
The loop runs from bar 5.

Run: python3 music/cues/t03_title.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of, phrase_items  # noqa: E402

song = Song("title")
bell = song.part("bell_tower", program=14, vel=86)
harp = song.part("harp", program=46, vel=60)
strings = song.part("strings_low", program=48, vel=52)
choir = song.part("choir_pad", program=52, vel=38)
sub = song.part("sub_breath", program=38, vel=70)
flute = song.part("flute", program=73, vel=78)

INTRO = ["Dm", "Am", "Dm", "Dm"]
SWELL = ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "A", "A",
         "Dm", "F/C", "Bb", "Gm", "Dm/A", "Bb", "Gm", "A"]
B = ["Dm", "Am", "Bb", "C", "F", "Gm", "A", "A",
     "Dm", "Am", "Bb", "C", "Gm", "Bb", "Asus4", "A"]
CHORDS = INTRO + SWELL + B
assert len(CHORDS) == song.bars == 36

# Intro: phrase 1 on a far bell, an octave down so it sounds huge and distant.
bell.line(0, phrase_items(0, transpose=-12), legato=1.6)
bell.note(song.bar(2), 6, 50, 60)  # D3 rings under the end of the intro

# Harp: slow rising arpeggios, a different shape in each half.
for b, sym in enumerate(CHORDS[4:], start=4):
    t = song.bar(b)
    tones = voicing(sym, 50, 74)
    root = 38 + (bass_of(sym) - 2) % 12
    if b < 20:
        fig = [root, tones[0], tones[2], tones[3] if len(tones) > 3 else tones[1] + 12]
        steps = [0, 1, 1.5, 2]  # quarter, eighths, quarter: an unhurried roll
    else:
        fig = [root, tones[1], tones[2], tones[1], tones[3] if len(tones) > 3 else tones[2] + 5]
        steps = [0, 0.5, 1, 1.5, 2]
    for p, s in zip(fig, steps):
        harp.note(t + s, 3 - s, p, 64 if s == 0 else 52)

# Low strings: whole-bar chords, low; the 8-bar breath swells via velocity.
for b, sym in enumerate(CHORDS[4:], start=4):
    phase = (b - 4) % 8
    vel = [40, 46, 54, 62, 66, 60, 50, 42][phase]
    strings.chord(song.bar(b), 3 * 0.98, voicing(sym, 38, 57)[:3], vel)
# Choir pad only in B, well under.
for b, sym in enumerate(B, start=20):
    choir.chord(song.bar(b), 3 * 0.98, voicing(sym, 55, 67)[:2], 36)
# The breath: a sub note that rises over 4 bars and falls over 4, every 8.
for start in range(4, 36, 8):
    root = 26 + (bass_of(CHORDS[start]) - 2) % 12
    sub.note(song.bar(start), song.bar_q * 4 * 0.98, root, 54)
    sub.note(song.bar(start + 4), song.bar_q * 4 * 0.98, root, 74)

# Flute in B: the lullaby's first two phrases, an answer, then both an octave up.
p1, p2 = phrase_items(0), phrase_items(1)
flute.line(song.bar(20), p1 + p2, legato=0.94)
flute.line(song.bar(24), seq("C5:2 A4:1 Bb4:2 G4:1 E4:3 C#5:3"), vel=70, legato=0.94)
flute.line(song.bar(28), phrase_items(0, 12)[:3] + [(81, 2)], vel=74, legato=0.94)
flute.line(song.bar(30), seq("D5:2 C5:1 Bb4:2 G4:1 Bb4:2 A4:1 D5:3 E4:2 G4:1 A4:3"), vel=66, legato=0.94)

for i, p in enumerate(song.parts):
    p.humanize(seed=300 + i, time_q=0.01, vel=4)
song.save()

if "--gate" in sys.argv:
    from gate_midi import check
    for problem in check(song, CHORDS, melody=("flute",), comp=("harp", "choir")):
        print("GATE:", problem)
