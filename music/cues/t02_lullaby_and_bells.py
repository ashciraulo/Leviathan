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
LAST_HOLD = {"bell_verge": 3.0}  # beats
songs = []

for i, phrase in enumerate(PHRASES):
    song = Song(f"bell_{i + 1}")
    bell = song.part(BELL_PARTS[i], program=14, vel=96)
    t = 0.0
    for k, (pitch, beats) in enumerate(phrase):
        # Bells ring on: each note holds until the next, the last one to the end. A preset that sustains
        # instead of decaying lets its last note go after a bar and rings out on its release and reverb
        # (review of the bells v2, MAJOR 3: the Verge Bell held flat like an organ for 3.75 s).
        nxt = t + beats
        last = min(song.end_q - t, LAST_HOLD.get(BELL_PARTS[i], song.end_q))
        bell.note(t, last if k == len(phrase) - 1 else beats, pitch, 100 if k == 0 else 88)
        t = nxt
    if i == 3:  # the Gale Bell turns the tide: a low swell under it and after it
        swell = song.part("strings_swell", program=48, vel=40)
        # The swell grows by voices as well as velocity: the string preset barely follows velocity
        # (review of the bells v1, MAJOR 5: flat at -26 LUFS a bar), so one, two, three, then five.
        for b, sym in enumerate(HARMONY[3] + ["Dm", "Dm"]):
            tones = voicing(sym, 38, 57)
            swell.chord(song.bar(b), song.bar_q * 0.98, tones[:[1, 2, 3, 5][b]], 36 + 10 * b)
    songs.append((song, None))

song = Song("lullaby")
box = song.part("musicbox", program=10, vel=84)
harp = song.part("harp", program=46, vel=62)
choir = song.part("choir_oo", program=52, vel=44)
# The celesta is near a sine (review of v9, MINOR 1: the mix lost its music-box sparkle), so a quiet
# glockenspiel doubles every pluck for the tine's bright attack. It copies the box's humanized notes
# below, so the two layers strike together.
shine = song.part("box_shine", program=9, vel=60)
chords = [c for pair in HARMONY for c in pair] + ["Dm", "Dm"]
# A music box rings on after each pluck, so notes overlap by up to a beat
# (never into the next pluck of the same pin).
plucks, vels = [], []
for phrase in PHRASES:
    top = max(p for p, _ in phrase)
    for k, (pitch, beats) in enumerate(phrase):
        plucks.append((pitch + 12, beats))
        # Each phrase leans to its highest note and lets go on its last one.
        vels.append(66 if k == len(phrase) - 1 else 88 if pitch == top else 80 if k == 0 else 76)
plucks.append((74, 4.5))
vels.append(64)  # the home D, rung softly at the end
starts = [sum(b for _, b in plucks[:i]) for i in range(len(plucks))]
for i, (pitch, beats) in enumerate(plucks):
    t = starts[i]
    again = [starts[j] for j in range(i + 1, len(plucks)) if plucks[j][0] == pitch]
    length = beats + 1.0 if i < len(plucks) - 1 else beats
    if again:
        length = min(length, again[0] - t - 0.05)
    box.note(t, length, pitch, vels[i])
END = 46.5  # everything lets go here, so the last 1.5 beats and the render's room are the ring
for b, sym in enumerate(chords):
    if b == len(chords) - 1:
        break  # the last bar only rings
    root = 38 + (bass_of(sym) - 2) % 12
    tones = voicing(sym, 50, 69)
    last = b == len(chords) - 2
    # Harp: root then a slow roll up the chord, different in each phrase's second bar.
    harp.note(song.bar(b), 3 if not last else END - song.bar(b), root, 66 if not last else 58)
    roll = tones[:3] if b % 2 == 0 else tones[1:4]
    for k, p in enumerate(roll):
        harp.note(song.bar(b) + 1 + k * 0.5 if not last else song.bar(b) + k * 0.25,
                  2 - k * 0.5 if not last else END - song.bar(b) - k * 0.25, p, 54 if not last else 48)
    # Choir: one chord per change of harmony. A repeated chord is held on, not sung again.
    if b > 0 and chords[b - 1] == sym:
        continue
    n = 1
    while b + n < len(chords) and chords[b + n] == sym:
        n += 1
    length = END - song.bar(b) if b + n >= len(chords) else 3 * n * 0.98
    choir.chord(song.bar(b), length, voicing(sym, 50, 64)[:3], 34 if b + n >= len(chords) else 40)
songs.append((song, chords))

for i, (s, chords) in enumerate(songs):
    for k, p in enumerate(s.parts):
        if not p.name.startswith("bell") and p.name != "box_shine":
            p.humanize(seed=200 + 10 * i + k, time_q=0.008, vel=4)
    if s is song:  # the lullaby
        shine.notes = [list(nt) for nt in box.notes]
    s.save()
    if "--gate" in sys.argv and chords:
        from gate_midi import check
        for problem in check(s, chords, melody=("musicbox",), comp=("harp",)):
            print("GATE:", problem)
