"""The Tide Breathes (title): the title screen.

D aeolian, 3/4 at 66, 36 bars: intro 4 (a lone distant bell plays phrase 1,
then rings) | swell A 16 (harp and low strings; a low swell every 8 bars, the
tide breathing) | B 16 (flute sings phrases 1 and 2, answers, then 1 and 2
again, varied and higher, and breathes out on A to lead back into the swell).
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

# Intro: phrase 1 on a far bell, written an octave down (the build raises the in-tune preset back up); the mix
# low-passes it and keeps it low so it sounds distant.
bell.line(0, phrase_items(0, transpose=-12), legato=1.6)
bell.note(song.bar(2), 6, 50, 60)  # D3 rings under the end of the intro

# Harp: slow rising arpeggios, a different shape in each half.
for b, sym in enumerate(CHORDS[4:], start=4):
    t = song.bar(b)
    tones = voicing(sym, 50, 74)
    root = 38 + (bass_of(sym) - 2) % 12
    # The last two bars go back to the swell's unhurried roll, softer, so the loop's return to the
    # swell is a breath out, not a drop (v4's seam fell 9 dB from the busy B roll to bar 5).
    calm = b < 20 or b >= 34
    if calm:
        fig = [root, tones[0], tones[2], tones[3] if len(tones) > 3 else tones[1] + 12]
        steps = [0, 1, 1.5, 2]  # quarter, eighths, quarter: an unhurried roll
    else:
        fig = [root, tones[1], tones[2], tones[1], tones[3] if len(tones) > 3 else tones[2] + 5]
        steps = [0, 0.5, 1, 1.5, 2]
    hi, lo = (50, 40) if b == 35 else (56, 44) if b >= 34 else (68, 56) if b < 20 else (64, 52)
    # The harp breathes with the strings and the sub, softer and sparer at the ebb, fuller at the flood
    # (review of the title v1, MAJOR 2: above 120 Hz the mix was flat, so the tide was inaudible on small speakers).
    # Analog Harp barely follows velocity (v8: flat within 1 dB a bar), so the tide also thins the roll at the ebb.
    if b < 34:
        phase = (b - 4) % 8
        tide = [-8, -6, -2, 2, 5, 5, 0, -5][phase]
        hi, lo = hi + tide, lo + tide
        keep = [2, 3, 3, 4, 5, 5, 4, 3][phase] - (1 if calm else 0)
        fig, steps = fig[:keep], steps[:keep]
    for p, s in zip(fig, steps):
        harp.note(t + s, 3 - s, p, hi if s == 0 else lo)
    # The loop comes back here: a fuller first beat (root and a chord tone the roll skips) holds the seam's level.
    if b == 4:
        harp.note(t, 3, tones[1], hi - 6)

# Low strings: whole-bar chords, low; the 8-bar breath swells by voices as well as velocity, since
# 12 Low Strings barely follows velocity (review of the title v1, MAJOR 2: the bed sat flat within 1 dB and
# the breath was only audible below 80 Hz). Two voices at the ebb, five at the flood.
for b, sym in enumerate(CHORDS[4:], start=4):
    phase = (b - 4) % 8
    vel = [40, 46, 54, 62, 66, 60, 50, 42][phase]
    voices = [2, 2, 3, 4, 5, 5, 3, 2][phase]
    strings.chord(song.bar(b), 3 * 0.98, voicing(sym, 38, 57)[:voices], vel)
# Choir pad only in B, well under.
for b, sym in enumerate(B[:-1], start=20):  # out for the last bar, which leads back to the swell
    choir.chord(song.bar(b), 3 * 0.98, voicing(sym, 55, 67)[:2], 36)
# The breath: one sub note every 8 bars. The preset's slow attack (Analog Lab Simple Sine (Clean),
# Time macro at 1.0) breathes in while it is held and its release breathes out after it lets go
# (the v1 render held a flat sine and stopped dead, so the swell lives in the envelope, not in velocity).
for start in range(4, 36, 8):
    root = 26 + (bass_of(CHORDS[start]) - 2) % 12
    sub.note(song.bar(start), song.bar_q * 4, root, 70)
    # An octave above on the same slow envelope, so the breath reaches speakers that can't play 37 Hz.
    sub.note(song.bar(start), song.bar_q * 4, root + 12, 50)

# Flute in B: the lullaby's first two phrases, an answer, then phrase 1 an octave up and phrase 2 varied.
p1, p2 = phrase_items(0), phrase_items(1)
flute.line(song.bar(20), p1 + p2, legato=0.94)
flute.line(song.bar(24), seq("C5:2 A4:1 Bb4:2 G4:1 E4:3 C#5:3"), vel=70, legato=0.94)
flute.line(song.bar(28), phrase_items(0, 12)[:3] + [(81, 2)], vel=74, legato=0.94)
# The last A lets go after two beats, so the loop's last beat is the harp's roll alone.
flute.line(song.bar(30), seq("D5:2 C5:1 Bb4:2 G4:1 Bb4:2 A4:1 D5:3 E4:2 G4:1 A4:2"), vel=66, legato=0.94)

for i, p in enumerate(song.parts):
    p.humanize(seed=300 + i, time_q=0.01, vel=4)
song.save()

if "--gate" in sys.argv:
    from gate_midi import check
    for problem in check(song, CHORDS, melody=("flute",), comp=("harp", "choir")):
        print("GATE:", problem)
