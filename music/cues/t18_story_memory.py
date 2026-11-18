"""Half-Remembered (story_memory): memories and visions. Ambient style.

Db lydian, 3/4 at 54, 24 bars: pad alone 4 | memory 16 | fade 4.
Lullaby phrase 6's degrees (C Bb Ab G F) on celesta, slowed and with notes
left out, as if half-remembered; warm pad, soft choir, a distant bell and a
slow sub swell. No drums.

Run: python3 music/cues/t18_story_memory.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, voicing  # noqa: E402
from common import bars, low_root, gate  # noqa: E402

song = Song("story_memory")
pad = song.part("pad_warm", program=89, vel=48)
cel = song.part("celesta", program=8, vel=58)
choir = song.part("choir_soft", program=52, vel=34)
bell = song.part("bell_distant", program=14, vel=44)
sub = song.part("sub_swell", program=38, vel=50)
# Dbmaj7 carries the lydian colour: the melody's C is its seventh, not a clash.
CH = ["Dbmaj7", "Eb", "Dbmaj7", "Eb",
      "Dbmaj7", "Ebsus4", "Fm", "Bbm", "Ab", "Eb", "Dbmaj7", "Dbmaj7", "Fm", "Eb", "Bbm", "Eb",
      "Dbmaj7", "Eb", "Dbmaj7", "Eb", "Dbmaj7", "Dbmaj7", "Dbmaj7", "Dbmaj7"]
assert len(CH) == song.bars == 24
cel.line(song.bar(4), bars("C6:2 Bb5:1 | Ab5:3 | r:3 | F5:3 | C6:2 r:1 | Bb5:2 G5:1 | Ab5:3 | F5:3 | "
                           "C6:3 | r:1 Bb5:2 | Ab5:3 | r:3 | Ab5:2 C6:1 | Bb5:3 | F5:3 | G5:3", per_bar=3), legato=1.3)
cel.line(song.bar(20), bars("C6:3 | Bb5:3 | r:3 | r:3", per_bar=3), vel=44, legato=1.5)
# A ringing note stops where the next one starts when they are a semitone apart (bar 10's G5 under Ab5, review v2).
cel.notes.sort()
for a, b in zip(cel.notes, cel.notes[1:]):
    if abs(a[2] - b[2]) == 1:
        a[1] = min(a[1], b[0] - a[0])
subs = []
for b, sym in enumerate(CH):
    t = song.bar(b)
    if b % 2 == 0 or b == 7:
        # The pad restrikes on bar 7 so Fm's C4 isn't held under the choir's C#4 (review v2), and carries the chord's
        # root (Db above all) so the cue isn't heard as F minor above the sub.
        dur = 2.95 if b in (6, 7) else 5.9
        pad.chord(t, dur, [low_root(sym, 49)] + voicing(sym, 53, 65)[:3], 46 if 4 <= b < 20 else 40)
    if b % 2 == 0:
        subs.append([t, 5.8, low_root(sym, 25)])
    if 4 <= b < 20:
        choir.chord(t, 2.95, voicing(sym, 56, 68)[:2], 32)
    if b in (6, 14, 21):
        bell.note(t + 1, 4, voicing(sym, 73, 85)[0], 40)
# The sub's slow swell cancels itself when it retriggers the same pitch (a 20 dB hole at 8.75 s, review v2): hold it.
merged = [subs[0]]
for t, d, p in subs[1:]:
    if p == merged[-1][2]:
        merged[-1][1] = t + d - merged[-1][0]
    else:
        merged.append([t, d, p])
for t, d, p in merged:
    sub.note(t, d, p, 48)
for i, p in enumerate(song.parts):
    p.humanize(seed=3700 + i, time_q=0.015, vel=3)
song.save()
gate(song, CH, ("celesta",), ("choir",), "memory")
