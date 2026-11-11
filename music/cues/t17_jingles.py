"""The seven jingles (audio/sfx/jingle_*.ogg): short, no loop, -16 LUFS.

Each is built from a lullaby fragment (track_sheet.JINGLES says which):
item, pearl, secret, clear, bell (fallback), game over, puzzle. They play over
music ducked by 18 dB, so they stay short and end on a ring, not a cut.

Run: python3 music/cues/t17_jingles.py [--preview]
"""
import os
import sys
import zlib

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, seq, voicing  # noqa: E402


def spec(jid, tempo, n_bars, meter="4/4"):
    return dict(id=jid, tempo=tempo, meter=meter, bars=n_bars, intro_bars=0, loop=False, lufs=-16.0)


def jingle(jid, tempo, n_bars, build, meter="4/4"):
    song = Song(jid, spec(jid, tempo, n_bars, meter))
    build(song)
    for i, p in enumerate(song.parts):
        p.humanize(seed=zlib.crc32(jid.encode()) % 1000 + i, time_q=0.004, vel=2)
    song.save()


def item(s):  # phrase 1's first three notes, rising to a held fifth: D F# G -> A
    harp, bell = s.part("harp", program=46, vel=80), s.part("bell_point", program=14, vel=86)
    harp.line(0, seq("D5:0.5 F#5:0.5 G5:0.5 A5:2.5"), legato=1.0)
    bell.note(1.5, 2.5, 81, 90)
    harp.chord(1.5, 2.5, voicing("D", 50, 66)[:3], 64, roll=0.05)


def pearl(s):  # phrase 5's leap D F# A D', then a shimmer
    cel, choir = s.part("celesta", program=8, vel=80), s.part("choir_ah", program=52, vel=56)
    cel.line(0, seq("D5:0.5 F#5:0.5 A5:0.5 D6:0.5 G#6:0.25 A6:0.25 G#6:0.25 A6:0.25 D6:1"), legato=1.2)
    choir.chord(0, 3.0, [62, 66, 69], 58)


def secret(s):  # four rising notes from phrase 3: F G A C
    glass = s.part("bell_glass", program=14, vel=80)
    glass.line(0, [(65, 0.5), (67, 0.5), (69, 0.5), (72, 2.5)], legato=1.0)
    glass.note(0.0, 4.0, 53, 50)


def clear(s):  # phrase 7's cadence (G A F D) in major, brass, timpani and bell
    brass = s.part("horns_brass", program=61, vel=88)
    timp = s.part("timpani", program=47, vel=90)
    bell = s.part("bell_marrow", program=14, vel=86)
    brass.line(0, seq("G4:0.5 A4:0.5 F#4:1 D5:4"), legato=0.95)
    brass.chord(2, 4.0, [62, 66, 69], 80)
    for st, v in ((0, 70), (1, 76), (2, 100)):
        timp.note(st, 0.5, 38, v)
    bell.note(2, 4.0, 86, 84)  # ends at 6 q, well inside the 2 bars


def bell_fallback(s):  # one strike of the point bell and its fifth
    bell = s.part("bell_point", program=14, vel=90)
    bell.note(0, 2.8, 74, 92)
    bell.note(0.5, 2.3, 81, 70)


def game_over(s):  # phrase 4 falling, unresolved: A G F, held on E
    strings = s.part("strings_low", program=48, vel=70)
    bell = s.part("bell_point", program=14, vel=70)
    strings.line(0, seq("A3:1 G3:1 F3:1 E3:3"), legato=0.98)
    strings.chord(2, 4.0, [38, 45, 52], 56)
    bell.note(0, 3.0, 69, 62)


def puzzle(s):  # two notes, a fourth up
    mar = s.part("marimba", program=12, vel=88)
    mar.line(0, [(69, 0.5), (74, 1.5)], legato=1.2)
    mar.chord(0.5, 1.5, [57, 61, 64], 60)


jingle("jingle_item", 100, 1, item)
jingle("jingle_pearl", 96, 1, pearl)
jingle("jingle_secret", 120, 1, secret)
jingle("jingle_clear", 90, 2, clear)
jingle("jingle_bell", 80, 1, bell_fallback)
jingle("jingle_game_over", 70, 2, game_over)
jingle("jingle_puzzle", 120, 1, puzzle)
