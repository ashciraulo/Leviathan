"""On the Old One's Back, Inside the Maw, The Grey Choir, Vael's Choir.

region_maw: G minor, 3/4 at 58, 32 bars: A 16 | B 16. The whole lullaby,
  moved to G minor and stretched to twice its length, on low brass across the
  loop (phrases 1-4 in A, 5-7 in B). Huge low string swells, choir, the sub
  breath.
dungeon_maw: D phrygian, 4/4 at 64, 40 bars: A 16 (heartbeat) | B 8 (the
  breath floods) | A' 16. A heartbeat kick at 64; fragments of all seven
  phrases surface one at a time on bowed metal and sink.
place_choir: C# dorian, 3/4 at 63, 24 bars: chant A 8 | answer 8 | chant
  A' 8. Choir only over an organ pedal; phrase 2's degrees (C# B G# F#).
story_choir: Eb aeolian, 4/4 at 71, 16 bars: chant 6 | bells 4 | chant 6.
  The Waking Song: phrase 7 backwards (Eb Gb Bb Ab), in unison.

Run: python3 music/cues/t14_maw_choir.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, voicing, lullaby  # noqa: E402
from common import bars, low_root, sections, gate  # noqa: E402

PHRASES = lullaby()

# -------------------------------------------------------------- region_maw
song = Song("region_maw")
brass = song.part("brass_low", program=57, vel=78)
strings = song.part("strings_low", program=48, vel=46)
choir = song.part("choir", program=52, vel=40)
sub = song.part("sub_breath", program=38, vel=60)
# Harmony per bar for the stretched lullaby (two bars per original bar).
HARM = [["Gm", "Cm"], ["Eb", "F"], ["Bb", "Cm"], ["Dm", "Gm"], ["Gm", "Eb"], ["Bb", "Eb"], ["Cm", "Gm"]]
CH = []
for pair in HARM:
    CH += [pair[0], pair[0], pair[1], pair[1]]
CH += ["Gm", "Gm", "D", "D"]
assert len(CH) == song.bars == 32
t = 0.0
for k, phrase in enumerate(PHRASES):
    for pitch, beats in phrase:
        brass.note(t, beats * 2 * 0.96, pitch + 5 - 24, 80 if beats == 2 else 70)
        t += beats * 2
for b, sym in enumerate(CH):
    tb = song.bar(b)
    if b % 4 == 0:  # the swell: low strings rise over two bars, ebb over two
        tones = voicing(sym, 43, 58)[:3]
        strings.chord(tb, 5.9, tones, 42)
        strings.chord(tb + 6, 5.9, voicing(CH[b + 2], 43, 58)[:3], 56)
        sub.note(tb, 11.8, low_root(sym, 31), 58)
    if b >= 16 and b % 2 == 0:
        choir.chord(tb, 5.9, voicing(sym, 58, 70)[:3], 38)
for i, p in enumerate(song.parts):
    p.humanize(seed=2700 + i, time_q=0.01, vel=3)
song.save()
gate(song, CH, ("brass",), ("none",), "region_maw")

# ------------------------------------------------------------- dungeon_maw
song = Song("dungeon_maw")
heart = song.part("drum_heart", program=0, vel=90)
sub = song.part("sub_swell", program=38, vel=60)
choir = song.part("choir_dark", program=52, vel=42)
metal = song.part("metal_bowed", program=92, vel=58)
A = ["Dm", "Dm", "Eb", "Dm", "Dm", "Dm", "Cm", "Dm", "Bb", "Bb", "F", "Dm", "Gm", "Gm", "Eb", "Dm"]
B = ["Dm", "Dm", "Eb", "Eb", "Bb", "Bb", "Gm", "Dm"]
CH = A + B + A
assert len(CH) == song.bars == 40
sec = sections([("A", 0), ("B", 16), ("A2", 24)])
for b, sym in enumerate(CH):
    t, s = song.bar(b), sec(b)
    for beat in range(4):  # lub-dub on every beat at 64 bpm: a resting heart
        if s == "B" and beat % 2:
            continue
        heart.note(t + beat, 0.2, 36, 92 if beat == 0 else 74)
        heart.note(t + beat + 0.3, 0.15, 36, 54)
    if b % 4 == 0:
        sub.note(t, 15.8 if s != "B" else 7.8, low_root(sym, 26), 52)
    if s == "B" or b % 2 == 0:
        choir.chord(t, 3.95 if s == "B" else 7.9, voicing(sym, 50, 62)[:3], 48 if s == "B" else 36)
# Fragments: the first notes of each phrase, surfacing every few bars.
SPOTS = [(1, 0, 3), (5, 1, 2), (9, 2, 3), (13, 3, 2), (25, 4, 3), (29, 5, 2), (33, 6, 3), (37, 0, 2)]
for bar, idx, count in SPOTS:
    tt = song.bar(bar) + 1
    for pitch, beats in PHRASES[idx][:count]:
        metal.note(tt, beats * 1.6, pitch, 56)
        tt += beats * 1.5
for b in range(16, 24, 2):  # B: the breath floods: phrase 4 falling in long notes
    metal.note(song.bar(b), 7.6, [69, 67, 65, 62][(b - 16) // 2], 50)
for i, p in enumerate(song.parts):
    p.humanize(seed=2800 + i, time_q=0.006, vel=3)
song.save()
gate(song, CH, ("metal",), ("none",), "dungeon_maw")

# ------------------------------------------------------------- place_choir
song = Song("place_choir")
choir = song.part("choir", program=52, vel=60)
pedal = song.part("organ_pedal", program=19, vel=50)
CH = ["C#m", "C#m", "B", "C#m", "F#m", "F#m", "B", "C#m",
      "A", "B", "G#m", "C#m", "A", "F#m", "G#m", "G#m",
      "C#m", "C#m", "B", "C#m", "F#m", "A", "G#m", "C#m"]
assert len(CH) == song.bars == 24
CHANT = "C#5:2 B4:1 | G#4:1 F#4:2 | G#4:3 | C#5:3 | E5:2 D#5:1 | C#5:1 B4:2 | G#4:2 B4:1 | C#5:3"
ANSWER = "E5:2 F#5:1 | F#5:2 D#5:1 | B4:2 D#5:1 | G#4:3 | C#5:2 E5:1 | F#5:2 A4:1 | B4:1 D#5:1 F#5:1 | G#5:3"
CHANT2 = "C#5:2 B4:1 | G#4:1 F#4:2 | G#4:3 | C#5:3 | F#5:2 E5:1 | C#5:2 A4:1 | B4:2 D#5:1 | C#5:3"
t = 0.0
for text in (CHANT, ANSWER, CHANT2):
    for pitch, d in bars(text, per_bar=3):
        if pitch is not None:
            b = int((t + 0.01) // 3)
            # Chant in open fifths (the cold sound), the answer in thirds.
            voices = [pitch, pitch - 7] if text != ANSWER else [pitch, max(v for v in voicing(CH[b], 50, pitch - 3))]
            choir.chord(t, d * 0.96, voices, 62)
        t += d
for b in range(0, 24, 2):
    pedal.note(song.bar(b), 5.9, low_root(CH[b], 25), 50)
for i, p in enumerate(song.parts):
    p.humanize(seed=2900 + i, time_q=0.008, vel=3)
song.save()

# ------------------------------------------------------------- story_choir
song = Song("story_choir")
choir = song.part("choir_unison", program=52, vel=64)
bells = song.part("bell_low", program=14, vel=70)
drone = song.part("drone", program=95, vel=50)
CH = ["Ebm"] * 6 + ["Cb", "Cb", "Bbm", "Bbm"] + ["Ebm"] * 6
assert len(CH) == song.bars == 16
WAKE = "Eb4:2 Gb4:2 | Bb4:2 Ab4:2 | Eb4:4 | Gb4:2 Bb4:1 Db5:1 | Bb4:2 Gb4:2 | Ab4:4"  # phrase 7 backwards
choir.line(0, bars(WAKE), legato=0.97)
choir.line(song.bar(10), bars("Eb4:2 Gb4:2 | Bb4:2 Ab4:2 | Eb4:4 | Db5:2 Bb4:2 | Ab4:2 Gb4:2 | Eb4:4"), legato=0.97)
for b in (6, 7, 8, 9):  # the bells answer: the same four notes, tolled low
    for k, p in enumerate([51, 54, 58, 56]):
        if (b - 6) == k:
            bells.note(song.bar(b), 3.9, p, 72)
for b in range(0, 16, 2):
    drone.chord(song.bar(b), 7.9, [39, 46], 50)
for i, p in enumerate(song.parts):
    p.humanize(seed=3000 + i, time_q=0.006, vel=3)
song.save()
gate(song, CH, ("choir",), ("none",), "story_choir")
