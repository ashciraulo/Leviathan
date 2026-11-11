"""The Waking Song (boss_vael), The Dreaming Heart (boss_heart), Undertow
(story_danger), Grief in the Water (story_sorrow).

boss_vael: Bb minor, 3/4 at 120, 48 bars: A 16 | B 16 (the Waking Song: the
  whole lullaby backwards, sung by the choir) | C 16. Organ, strings,
  timpani, bells.
boss_heart: D minor, 4/4 at 144, 48 bars: intro 2 | A 16 | B 16 (the lullaby
  in full, each phrase on its own Tidebell, stretched by half) | C 14. The
  bell channels share names with bell_1..7 so the same FL sounds are reused.
  Loop from bar 3.
story_danger: B minor, 4/4 at 134, 16 bars: A 6 (ostinato builds) | B 6 |
  A' 4 (drops to the pulse). Phrase 4 in diminution (F# E D B in eighths).
story_sorrow: G minor, 3/4 at 56, 16 bars: cello alone 4 | A 8 (piano
  joins) | tail 4. Phrase 4 (D C Bb G) on cello, very slow.

Run: python3 music/cues/t15_vael_heart_danger_sorrow.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, voicing, lullaby  # noqa: E402
from common import bars, low_root, sections, gate, harmonize  # noqa: E402

PHRASES = lullaby()
BELL_PARTS = ["bell_point", "bell_ember", "bell_moth", "bell_gale", "bell_rime", "bell_verge", "bell_marrow"]

# --------------------------------------------------------------- boss_vael
song = Song("boss_vael")
choir = song.part("choir", program=52, vel=78)
organ = song.part("organ", program=19, vel=62)
strings = song.part("strings_ostinato", program=48, vel=76)
timp = song.part("timpani", program=47, vel=84)
bells = song.part("bell_church", program=14, vel=70)
lead = song.part("strings_high", program=48, vel=80)
A = ["Bbm", "Bbm", "Gb", "F", "Bbm", "Bbm", "Ebm", "F", "Gb", "Db", "Ebm", "Bbm", "Gb", "Ebm", "F", "F"]
# B follows the reversed lullaby, moved from D minor to Bb minor (-4).
REV = [(p - 4, beats) for phrase in reversed(PHRASES) for p, beats in reversed(phrase)]
_rev_notes, _t = [], 16 * 3.0
for _p, _b in REV:
    _rev_notes.append((_t, _b, _p))
    _t += _b
B = harmonize(_rev_notes, 3.0, 14, ["Bbm", "Gb", "Ebm", "Db", "F", "Ab", "Cdim"], start_bar=16) + ["Bbm", "Bbm"]
C = ["Ebm", "Ebm", "Bbm", "Bbm", "Gb", "Gb", "F", "F", "Ebm", "Gb", "Db", "Bbm", "Gb", "Ebm", "F", "F"]
CH = A + B + C
assert len(CH) == song.bars == 48
sec = sections([("A", 0), ("B", 16), ("C", 32)])
lead.line(song.bar(0), bars("F5:2 Db5:1 | Bb4:2 C5:1 | Db5:2 Gb5:1 | F5:3 | Bb5:2 Ab5:1 | F5:2 Db5:1 | "
                            "Eb5:2 Gb5:1 | E5:3 | Db5:1 Eb5:1 Gb5:1 | F5:2 Ab5:1 | Gb5:2 Bb4:1 | Db5:3 | "
                            "Db5:2 Gb5:1 | Bb5:2 Gb5:1 | A5:2 F5:1 | C5:3", per_bar=3), legato=0.92)
t = song.bar(16)
for pitch, beats in REV:
    choir.chord(t, beats * 0.97, [pitch, pitch - 12], 82)
    t += beats
lead.line(song.bar(32), bars("Gb5:1 F5:1 Eb5:1 | Bb5:3 | F5:1 Db5:1 Bb4:1 | F5:3 | Db6:2 Bb5:1 | Gb5:3 | "
                             "F5:2 A5:1 | C6:3 | Bb5:2 Gb5:1 | Eb5:3 | F5:2 Db5:1 | Bb4:3 | "
                             "Gb5:2 Eb5:1 | Bb5:2 Gb5:1 | A5:2 C6:1 | F5:3", per_bar=3), vel=86, legato=0.9)
for b, sym in enumerate(CH):
    tb, s = song.bar(b), sec(b)
    root = low_root(sym, 34)
    organ.chord(tb, 2.95, voicing(sym, 48, 63)[:3], 58 if s != "B" else 50)
    for k in range(6):
        strings.note(tb + k * 0.5, 0.3, root + 12 + (7 if k in (2, 5) else 0), 80 if k % 3 == 0 else 62)
    timp.note(tb, 0.6, root, 86)
    if s == "C":
        timp.note(tb + 2, 0.5, root + 7 if root + 7 < 50 else root - 5, 70)
    if b % 4 == 0:
        bells.note(tb, 2.8, voicing(sym, 70, 82)[0], 70)
for i, p in enumerate(song.parts):
    p.humanize(seed=3100 + i, time_q=0.006)
song.save()
gate(song, CH, ("strings_high", "choir"), ("organ",), "vael")

# -------------------------------------------------------------- boss_heart
song = Song("boss_heart")
strings = song.part("strings_full", program=48, vel=78)
choir = song.part("choir", program=52, vel=60)
brass = song.part("brass", program=61, vel=86)
timp = song.part("timpani", program=47, vel=88)
bell = [song.part(name, program=14, vel=96) for name in BELL_PARTS]
INTRO = ["Dm", "Dm"]
A = ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "A", "A", "Dm", "C", "Bb", "F", "Gm", "Bb", "A", "A"]
# B: the lullaby stretched by half (each 3/4 beat = 1.5 quarters), 63 of 64 beats.
_lul, _t = [], 18 * 4.0
for _ph in PHRASES:
    for _p, _b in _ph:
        _lul.append((_t, _b * 1.5, _p))
        _t += _b * 1.5
B = harmonize(_lul, 4.0, 16, ["Dm", "Bb", "F", "Gm", "C", "Am", "A"], start_bar=18)
C = ["Bb", "C", "Dm", "Dm", "Gm", "A", "Dm", "Dm", "Bb", "Gm", "Asus4", "A", "A", "A"]
CH = INTRO + A + B + C
assert len(CH) == song.bars == 48
sec = sections([("INTRO", 0), ("A", 2), ("B", 18), ("C", 34)])
t = song.bar(18)
for k, phrase in enumerate(PHRASES):
    for pitch, beats in phrase:
        bell[k].note(t, beats * 1.5 + 1.0, pitch + 12, 100)
        t += beats * 1.5
brass.line(song.bar(2), bars("D5:2 A4:2 | F5:3 D5:1 | D5:2 Bb4:2 | F5:4 | G5:2 D5:2 | Bb4:3 D5:1 | C#5:4 | E5:4 | "
                             "F5:2 D5:2 | E5:2 G5:2 | F5:3 D5:1 | C5:4 | Bb4:2 D5:2 | F5:2 D5:2 | E5:3 C#5:1 | A4:4"),
           legato=0.9)
brass.line(song.bar(34), bars("D5:4 | E5:4 | F5:2 A5:2 | D6:4 | Bb5:2 G5:2 | A5:2 C#6:2 | D6:4 | A5:4 | "
                              "F5:2 D5:2 | G5:2 Bb5:2 | A5:4 | C#5:4 | E5:4 | A4:4"), vel=92, legato=0.9)
for b, sym in enumerate(CH):
    tb, s = song.bar(b), sec(b)
    root = low_root(sym, 38)
    if s == "INTRO":
        for st in (0, 1.5, 3):
            timp.note(tb + st, 0.5, root, 100)
        continue
    for k in range(8):
        strings.note(tb + k * 0.5, 0.3, root + 12 + [0, 0, 7, 0, 12, 0, 7, 10 if "m" in sym else 7][k], 82 if k % 4 == 0 else 64)
    timp.note(tb, 0.5, root, 90)
    timp.note(tb + 2.5, 0.4, root + 7 if root + 7 < 53 else root - 5, 72)
    choir.chord(tb, 3.95, voicing(sym, 55, 69)[:3], 66 if s == "B" else 52)
for i, p in enumerate(song.parts):
    if not p.name.startswith("bell"):
        p.humanize(seed=3200 + i, time_q=0.006)
song.save()
gate(song, CH, ("bell", "brass"), ("choir",), "heart")

# ------------------------------------------------------------ story_danger
song = Song("story_danger")
ost = song.part("strings_ostinato", program=48, vel=80)
toms = song.part("drum_toms", program=0, vel=80)
brass = song.part("brass_low", program=57, vel=84)
CH = ["Bm", "Bm", "G", "G", "Em", "F#", "Bm", "G", "Em", "C", "F#", "F#", "Bm", "Bm", "Bm", "Bm"]
assert len(CH) == song.bars == 16
for b, sym in enumerate(CH):
    tb = song.bar(b)
    root = low_root(sym, 35)
    if b < 12:
        n_hits = 8 if b < 2 else 16
        for k in range(n_hits):
            step = 4 / n_hits
            ost.note(tb + k * step, step * 0.6, root + 12 + (7 if k % 4 == 2 else 0), 60 + b * 3 if k % 4 == 0 else 50 + b * 2)
        for st, p, v in ((0, 45, 90), (1.5, 47, 70), (2, 45, 84), (3, 48, 66), (3.5, 50, 74)):
            toms.note(tb + st, 0.25, p, v)
    else:  # A': only the pulse is left
        ost.note(tb, 0.5, 47, 60)
        ost.note(tb + 2, 0.5, 47, 50)
        toms.note(tb, 0.25, 45, 70 - (b - 12) * 8)
# Phrase 4 diminished: F# E D B in eighths, rising in pitch each time.
for b, lift in ((2, 0), (4, 5), (6, 7), (8, 12), (10, 12)):
    brass.line(song.bar(b), [(54 + lift, 0.5), (52 + lift, 0.5), (50 + lift, 0.5), (47 + lift, 1.5)], legato=0.85)
for i, p in enumerate(song.parts):
    p.humanize(seed=3300 + i, time_q=0.006)
song.save()

# ------------------------------------------------------------ story_sorrow
song = Song("story_sorrow")
cello = song.part("cello", program=42, vel=70)
piano = song.part("piano_felt", program=0, vel=50)
pad = song.part("pad_soft", program=89, vel=32)
CH = ["Gm", "Gm", "Eb", "D", "Gm", "Cm", "Eb", "D", "Bb", "Bb", "Cm", "D", "Gm", "Gm", "Eb", "D"]
assert len(CH) == song.bars == 16
cello.line(0, bars("D4:3 | C4:3 | Bb3:3 | A3:3", per_bar=3), legato=0.98)  # phrase 4's degrees, very slow
cello.line(song.bar(4), bars("D4:2 C4:1 | Bb3:2 G3:1 | Bb3:2 Eb4:1 | F#3:3 | G3:2 Bb3:1 | D4:2 F4:1 | "
                             "Eb4:2 C4:1 | D4:3", per_bar=3), vel=74, legato=0.97)
cello.line(song.bar(12), bars("Bb3:3 | G3:3 | G3:3 | F#3:3", per_bar=3), vel=60, legato=0.98)
for b, sym in enumerate(CH):
    tb = song.bar(b)
    if 4 <= b < 16:
        tones = voicing(sym, 55, 70)
        piano.note(tb, 2.9, low_root(sym, 31), 50)
        piano.chord(tb + 1, 1.9, tones[:3], 40 + (6 if b < 12 else 0), roll=0.06)
    pad.chord(tb, 2.95, voicing(sym, 50, 62)[:2], 30)
for i, p in enumerate(song.parts):
    p.humanize(seed=3400 + i, time_q=0.012, vel=4)
song.save()
gate(song, CH, ("cello",), ("none",), "sorrow")
