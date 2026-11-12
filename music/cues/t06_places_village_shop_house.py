"""Three small places: place_village, place_shop, place_house.

Market Day (place_village): G major, 4/4 at 108, 32 bars, A 8 | A' 8 | B 8 |
  A'' 8. Nylon guitar strums eighths, tin whistle tune, upright bass,
  light hand percussion. B turns lullaby phrase 2 (D C A G, falling) upside
  down and into major: G A C D, rising.
Marlo's Stall (place_shop): Bb major, 4/4 at 112, swung eighths (62%),
  24 bars, pickup 1 | A 8 | B 8 | A' 7. Marimba, upright bass, soft brushed
  snare, clarinet. Each A ends on a two-note wink of phrase 5 (D -> F).
Lamplight (place_house): Eb major, 3/4 at 74, 24 bars, music box alone 4 |
  A 8 | B 8 | A' 4. Felt piano, music box, cello. Phrase 6 (C Bb A G F) in
  major on the music box.

Run: python3 music/cues/t06_places_village_shop_house.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing, bass_of, chord, n  # noqa: E402

GATE = "--gate" in sys.argv


def bars(text, unit=1.0, per_bar=4):
    for i, chunk in enumerate(text.split("|")):
        total = sum(d for _, d in seq(chunk))
        assert abs(total - per_bar) < 1e-6, f"bar {i + 1} has {total}: {chunk.strip()}"
    return seq(text.replace("|", ""), unit)


def low_root(sym, lowest):
    """The chord's bass note at or just above `lowest`."""
    pc = bass_of(sym)
    return lowest + (pc - lowest) % 12


# ---------------------------------------------------------------- village
song = Song("place_village")
mando = song.part("guitar", program=24, vel=64)
whistle = song.part("whistle", program=78, vel=70)
bass = song.part("bass_upright", program=32, vel=82)
perc = song.part("perc_hand", program=0, vel=60)
A = ["G", "C", "G", "D", "Em", "C", "D", "G"]
A2 = ["G", "C", "G", "D", "Em", "Am", "D", "D"]
B = ["C", "D", "Bm", "Em", "C", "G/B", "Am", "D"]
A3 = ["G", "C", "G", "D", "C", "D", "G", "G"]
CH = A + A2 + B + A3
assert len(CH) == song.bars
TUNE_A = "B4:1 D5:1 G5:2 | E5:1 D5:1 C5:2 | B4:1 A4:0.5 B4:0.5 D5:2 | A4:3 r:1 | " \
         "G4:1 B4:1 E5:2 | E5:1 G5:1 E5:1 C5:1 | D5:1.5 C5:0.5 A4:1 F#4:1 | G4:3 r:1"
TUNE_A2 = "B4:1 D5:1 G5:2 | G5:1 E5:1 C5:2 | B4:1 D5:1 A4:2 | F#4:3 r:1 | " \
          "G4:1 B4:1 E5:1 G5:1 | A5:2 E5:2 | F#5:1 E5:1 D5:1 C5:1 | A4:2 D5:2"
TUNE_B = "G4:1 A4:1 C5:2 | D5:4 | F#4:1 G4:1 B4:2 | E5:4 | " \
         "G4:1 A4:1 C5:2 | D5:2 B4:2 | C5:1 E5:1 A5:1 G5:1 | F#5:3 r:1"
TUNE_A3 = "B4:1 D5:1 G5:2 | E5:1 D5:1 C5:2 | B4:1 A4:0.5 B4:0.5 D5:2 | A4:3 r:1 | " \
          "E5:1 G5:1 E5:1 C5:1 | D5:1.5 C5:0.5 A4:1 F#4:1 | G4:4 | r:2 D5:2"
for start, text in ((0, TUNE_A), (8, TUNE_A2), (16, TUNE_B), (24, TUNE_A3)):
    whistle.line(song.bar(start), bars(text), legato=0.9)
STRUM_SHAPES = {"G": [50, 55, 59], "C": [52, 55, 60], "D": [54, 57, 62], "Em": [52, 55, 59], "Am": [52, 57, 60]}
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = (voicing(sym, 55, 65) or [55])[-3:]
    while len(tones) < 3:  # a two-note chord in this range: double its lower note down
        tones = [tones[0] - 12 if tones[0] - 12 >= 55 else tones[-1]] + tones
    tones = sorted(tones)  # kept under the whistle's lowest note
    sec = b // 8
    if sec != 2:
        # Open-guitar shapes: G3-B3-D4 put B3 and D4 on one string of the sampled guitar,
        # so one choked the other and the G chord sounded as a bare fifth (review v3, MAJOR 1).
        tones = STRUM_SHAPES.get(sym, tones)
    if sec in (0, 3):  # strum: down on 1 and 3, light ups between
        for s, v in ((0, 70), (1, 46), (1.5, 52), (2, 66), (3, 46), (3.5, 52)):
            # The loop's last strum rings on across the seam instead of stopping short.
            ring = 0.9 if b == len(CH) - 1 and s == 3.5 else 0.45
            mando.chord(t + s, ring, tones, v, roll=0.012)
    elif sec == 1:  # tremolo-like repeated eighths on two notes
        for k in range(8):
            mando.chord(t + k * 0.5, 0.4, tones[-2:], 54 if k % 2 else 62)
    else:  # B: broken chord, root-third-fifth-third
        for k, p in enumerate((tones[0], tones[1], tones[2], tones[1]) * 2):
            mando.note(t + k * 0.5, 0.45, p, 58)
    # F2..E3, the sampled Diamond bass's measured range (keys under F2 read
    # inharmonic in the v1 stem gate); fifths stay at G3 or below.
    root = low_root(sym, 41)
    # The chord's own fifth near the bass note: on G/B the slash note's fifth (F#)
    # is not a chord tone, so the chord's fifth (D) is used; if the fifth is
    # already in the bass, the chord's root.
    cpc, _ = chord(sym)
    want = (cpc + 7) % 12 if (cpc + 7) % 12 != root % 12 else cpc
    fifth = min((m for m in range(root - 9, 56) if m % 12 == want), key=lambda m: abs(m - root - 4))
    if fifth == 54:  # the Diamond F#3 sample has two fundamentals (-53 c and +16 c): take the chord's third
        fifth = 50
    if sec == 2:
        bass.note(t, 1.9, root, 80)
        bass.note(t + 2, 1.9, fifth, 70)
    else:
        for k, (s, p) in enumerate(((0, root), (1, fifth), (2, root), (3, fifth))):
            bass.note(t + s, 0.85, p, 82 if k % 2 == 0 else 66)
    if sec != 2 or b % 2:
        for s, p, v in ((0, 60, 62), (1.5, 62, 44), (2, 61, 54), (3, 62, 44), (3.5, 62, 38)):
            perc.note(t + s, 0.2, p, v)
for i, p in enumerate(song.parts):
    p.humanize(seed=600 + i)
song.save()
if GATE:
    from gate_midi import check
    for problem in check(song, CH, melody=("whistle",), comp=("guitar",)):
        print("GATE village:", problem)

# ------------------------------------------------------------------- shop
song = Song("place_shop")
mar = song.part("marimba", program=12, vel=70)
bass = song.part("bass_upright", program=32, vel=82)
snare = song.part("drum_brush", program=0, vel=48)
clar = song.part("clarinet", program=71, vel=72)
SW = 0.62  # swing: the off eighth lands at 62% of the beat


def sw(beat_pos):
    """Swing an eighth-note grid position."""
    whole, frac = divmod(beat_pos, 1.0)
    return whole + (SW if abs(frac - 0.5) < 1e-6 else frac)


PICK = ["F7"]
A = ["Bb", "Gm7", "Cm7", "F7", "Bb", "Eb", "Cm7", "F7"]
B = ["Eb", "Ebm", "Bb", "G7", "Cm7", "F7", "Dm", "G7"]
A2 = ["Bb", "Gm7", "Cm7", "F7", "Eb", "F7", "Bb"]
CH = PICK + A + B + A2
assert len(CH) == song.bars
clar.line(song.bar(0) + 2, seq("F4:0.5 G4:0.5 A4:1"), legato=0.9)  # the pickup
for start, text in ((1, "Bb4:1.5 D5:0.5 F5:2 | G5:1 F5:0.5 D5:0.5 Bb4:2 | C5:1.5 Eb5:0.5 G5:1 Eb5:1 | "
                        "F5:3 r:1 | D5:1 F5:1 Bb5:2 | G5:1.5 F5:0.5 Eb5:2 | C5:1 Eb5:1 G4:1 Bb4:1 | D5:0.5 F5:1.5 r:2"),
                    (9, "G4:1 Bb4:1 Eb5:2 | Gb4:1 Bb4:1 Eb5:2 | D5:1 F5:1 Bb4:2 | B4:2 D5:2 | "
                        "Eb5:1.5 D5:0.5 C5:2 | A4:1 C5:1 Eb5:2 | D5:1 A4:1 F4:2 | G4:2 B4:1 D5:1"),
                    (17, "Bb4:1.5 D5:0.5 F5:2 | G5:1 F5:0.5 D5:0.5 Bb4:2 | C5:1.5 Eb5:0.5 G5:1 Eb5:1 | "
                         "F5:3 r:1 | G5:1 Eb5:1 Bb4:2 | C5:1 A4:1 F4:1 A4:1 | D5:0.5 F5:1.5 Bb4:2")):
    items = bars(text)
    t = song.bar(start)
    for pitch, d in items:
        if pitch is not None:
            clar.note(sw(t), d * 0.9, pitch)
        t += d
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = voicing(sym, 53, 70)[:4]
    last = b == len(CH) - 1  # the loop's last bar rings on across the seam instead of stopping short
    for s in (0.5, 1.5, 2.5, 3.5) if b % 2 else (0, 1.5, 2.5):
        mar.chord(t + sw(s), 1.0 if last and s == 3.5 else 0.35, tones, 58 if s else 64)
    # F2..E3 and never above G3: the sampled Diamond bass's measured range (see place_village).
    # A root too high to walk up through its chord walks down through it instead.
    root = low_root(sym, 41)
    third = 3 if "m" in sym.replace("maj", "") else 4
    line = [root, root + third, root + 7, root + 9 if third == 4 else root + 10]
    if line[-1] > 55:
        low3 = root - 12 + third if root - 12 + third >= 41 else root + third
        line = [root, root - 5, low3, root - 5]
    for k in range(4):  # a walking bass, but stepping, not swinging jazz
        bass.note(t + k, 1.0 if last and k == 3 else 0.8, line[k] if b % 2 == 0 else line[3 - k], 84 if k == 0 else 70)
    for s, v in ((1, 46), (3, 50), (sw(3.5), 32)):
        snare.note(t + s, 0.2, 38, v)
for i, p in enumerate(song.parts):
    p.humanize(seed=700 + i)
song.save()
if GATE:
    from gate_midi import check
    for problem in check(song, CH, melody=("clarinet",), comp=("marimba",)):
        print("GATE shop:", problem)

# ------------------------------------------------------------------ house
song = Song("place_house")
box = song.part("musicbox", program=10, vel=70)
piano = song.part("piano_felt", program=0, vel=58)
cello = song.part("cello", program=42, vel=60)
INTRO = ["Eb", "Ab", "Eb", "Bb"]
A = ["Eb", "Cm", "Ab", "Bb", "Eb", "Gm", "Ab", "Bb"]
B = ["Ab", "Bb", "Gm", "Cm", "Fm", "Bb", "Eb/G", "Ab"]
A2 = ["Eb", "Ab", "Bb", "Eb"]
CH = INTRO + A + B + A2
assert len(CH) == song.bars
# Phrase 6 (C Bb A G F, beats 1 1 1 1 2) on the same degrees of Eb major: Eb D C Bb Ab.
P6 = "Eb6:1 D6:1 C6:1 | Bb5:1 Ab5:2"
box.line(0, bars(P6 + " | G5:3 | Bb5:3", per_bar=3), legato=1.0)
box.line(song.bar(4), bars("G5:2 Bb5:1 | C6:2 Eb6:1 | " + P6 + " | Bb5:2 G5:1 | F5:3 | Eb5:3", per_bar=3), vel=64)
box.line(song.bar(12), bars("C6:3 | D6:2 F6:1 | Bb5:3 | G5:3 | Ab5:2 C6:1 | D6:2 Bb5:1 | G5:3 | C6:3", per_bar=3), vel=60)
box.line(song.bar(20), bars(P6 + " | Bb5:2 D6:1 | Eb6:3", per_bar=3), vel=66)
for b, sym in enumerate(CH):
    t = song.bar(b)
    tones = voicing(sym, 51, 70)
    if b >= 4:  # felt piano: low root, then the chord on beats 2 and 3, varied in B
        piano.note(t, 2.9, low_root(sym, 39), 56)
        if 12 <= b < 20:
            piano.chord(t + 1, 1.9, tones[1:4], 44, roll=0.05)
        else:
            piano.chord(t + 1, 0.9, tones[:3], 46)
            piano.chord(t + 2, 0.9, tones[1:4], 42)
    if 12 <= b < 24:  # cello joins for B and A'
        cello.note(t, 2.95, low_root(sym, 43) if b < 20 else voicing(sym, 50, 62)[0], 58)
for i, p in enumerate(song.parts):
    p.humanize(seed=800 + i, time_q=0.01, vel=4)
song.save()
if GATE:
    from gate_midi import check
    for problem in check(song, CH, melody=("musicbox",), comp=("piano",)):
        print("GATE house:", problem)
