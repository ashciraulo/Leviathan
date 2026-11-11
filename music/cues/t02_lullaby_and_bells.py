"""The lullaby itself: bell_1..bell_7 (one phrase each) and lullaby (all seven).

D aeolian, 3/4 at 80, straight from audio/music/lullaby.json, so the game's
bells, the dungeon tracks that quote them and these files never disagree.
Each bell has its own part name, because each gets its own bell sound in FL
(the track sheet's palette). The lullaby is a music box over harp chords and a
soft 'oo' choir.

Run: python3 music/cues/t02_lullaby_and_bells.py [--preview] [--gate]
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from mtk import Song, lullaby, voicing, bass_of  # noqa: E402

BELL_PARTS = ["bell_point", "bell_ember", "bell_moth", "bell_gale", "bell_rime", "bell_verge", "bell_marrow"]
# Two chords per phrase (one per bar), all in D aeolian.
HARMONY = [["Dm", "Am"], ["Bb", "C"], ["F", "Gm"], ["Am", "Dm"], ["Dm", "Bb"], ["F", "Bb"], ["Gm", "Dm"]]
PHRASES = lullaby()
songs = []

for i, phrase in enumerate(PHRASES):
    song = Song(f"bell_{i + 1}")
    bell = song.part(BELL_PARTS[i], program=14, vel=96)
    t = 0.0
    for k, (pitch, beats) in enumerate(phrase):
        # Bells ring on: each note holds until the next, the last one to the end.
        nxt = t + beats
        bell.note(t, (song.end_q - t) if k == len(phrase) - 1 else beats, pitch, 100 if k == 0 else 88)
        t = nxt
    if i == 3:  # the Gale Bell turns the tide: a low swell under it and after it
        swell = song.part("strings_swell", program=48, vel=40)
        for b, sym in enumerate(HARMONY[3] + ["Dm", "Dm"]):
            swell.chord(song.bar(b), song.bar_q * 0.98, voicing(sym, 38, 57)[:3], 36 + 10 * b)
    songs.append((song, None))

song = Song("lullaby")
box = song.part("musicbox", program=10, vel=84)
harp = song.part("harp", program=46, vel=62)
choir = song.part("choir_oo", program=52, vel=44)
chords = [c for pair in HARMONY for c in pair] + ["Dm", "Dm"]
t = 0.0
for phrase in PHRASES:
    for pitch, beats in phrase:
        box.note(t, beats * 0.9, pitch + 12)
        t += beats
box.note(t, 6, 74, 70)  # the home D rings out over the last two bars
for b, sym in enumerate(chords):
    root = 38 + (bass_of(sym) - 2) % 12
    tones = voicing(sym, 50, 69)
    last = b >= len(chords) - 2
    # Harp: root then a slow roll up the chord, different in each phrase's second bar.
    harp.note(song.bar(b), 3, root, 66)
    roll = tones[:3] if b % 2 == 0 else tones[1:4]
    for k, p in enumerate(roll):
        harp.note(song.bar(b) + 1 + k * 0.5 if not last else song.bar(b) + k * 0.25, 2 - k * 0.5, p, 54)
    choir.chord(song.bar(b), 3 * 0.98, voicing(sym, 50, 64)[:3], 40 if not last else 34)
songs.append((song, chords))

for i, (s, chords) in enumerate(songs):
    for k, p in enumerate(s.parts):
        if not p.name.startswith("bell"):
            p.humanize(seed=200 + 10 * i + k, time_q=0.008, vel=4)
    s.save()
    if "--gate" in sys.argv and chords:
        from gate_midi import check
        for problem in check(s, chords, melody=("musicbox",), comp=("harp",)):
            print("GATE:", problem)
