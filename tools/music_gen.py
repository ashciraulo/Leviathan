"""Placeholder music for Leviathan, made in code.

    python3 tools/music_gen.py            writes audio/music/<cue>.ogg
    python3 tools/music_gen.py --only region_brinewood,bell_1

Stand-ins until the real score is composed (in FL Studio, with Ash). They
exist so the music system can be built and heard now: every region and
dungeon has its own key, tempo, mood and instruments, and each one carries
the lullaby phrase of the bell found there, so the leitmotif is in place
from the start.

The lullaby itself (audio/music/lullaby.json) is seven short phrases, one per
Tidebell. bell_<n>.ogg is phrase n alone, on the bell's voice; the game
strings the learned phrases together (Audio.play_lullaby).

Needs numpy and ffmpeg (with libvorbis). Not run in CI: the .ogg files are
committed, and replacing them with real tracks needs no code change.
"""

import json
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "audio", "music")
RATE = 22050

with open(os.path.join(OUT, "lullaby.json"), encoding="utf-8") as f:
    LULLABY = json.load(f)


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# --------------------------------------------------------------------------
# Voices
# --------------------------------------------------------------------------
def env(n, attack, release, decay=None):
    t = np.arange(n) / RATE
    e = np.ones(n)
    a = max(1, int(attack * RATE))
    e[:a] = np.linspace(0, 1, a)
    if decay:
        e[a:] = np.exp(-(t[a:] - t[a]) / decay)
    r = min(n, max(1, int(release * RATE)))
    e[-r:] *= np.linspace(1, 0, r)
    return e


def voice(kind, midi, seconds, vol=1.0, bright=1.0):
    n = max(1, int(seconds * RATE))
    t = np.arange(n) / RATE
    f = hz(midi)
    vib = 1.0 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t * 2, 0, 1)
    ph = np.cumsum(f * vib / RATE)
    if kind == "bell":
        idx = 2.2 * bright * np.exp(-t * 3)
        s = np.sin(2 * np.pi * ph + idx * np.sin(2 * np.pi * ph * 3.5))
        e = env(n, 0.003, 0.05, decay=1.2)
    elif kind == "flute":
        s = np.sin(2 * np.pi * ph) + 0.15 * np.sin(4 * np.pi * ph)
        s += 0.04 * np.random.default_rng(int(midi * 7 + seconds * 100)).standard_normal(n)
        e = env(n, 0.06, 0.12)
    elif kind == "pluck":
        s = np.sign(np.sin(2 * np.pi * ph)) * 0.5 + np.sin(2 * np.pi * ph) * 0.5
        e = env(n, 0.003, 0.05, decay=0.25)
    elif kind == "square":
        s = np.where((ph % 1.0) < 0.25, 1.0, -1.0) * 0.6
        e = env(n, 0.01, 0.06, decay=0.6)
    elif kind == "saw":
        s = 2 * (ph % 1.0) - 1
        s = np.convolve(s, np.ones(6) / 6, mode="same") * 0.6
        e = env(n, 0.02, 0.08, decay=0.8)
    elif kind == "pad":
        s = sum(np.sin(2 * np.pi * ph * d) for d in (1.0, 1.003, 0.997)) / 3
        s += 0.2 * np.sin(4 * np.pi * ph)
        e = env(n, min(0.6, seconds / 3), min(0.8, seconds / 3))
    elif kind == "bass":
        s = np.sin(2 * np.pi * ph) + 0.3 * np.sin(4 * np.pi * ph)
        e = env(n, 0.01, 0.08, decay=0.9)
    elif kind == "organ":
        s = sum(np.sin(2 * np.pi * ph * h) / h for h in (1, 2, 3, 4))
        e = env(n, 0.04, 0.1)
    else:
        raise ValueError(kind)
    return s * e * vol


def drum(kind, seed):
    rng = np.random.default_rng(seed)
    if kind == "kick":
        n = int(0.25 * RATE)
        t = np.arange(n) / RATE
        f = 120 * np.exp(-t * 18) + 45
        return np.sin(2 * np.pi * np.cumsum(f / RATE)) * np.exp(-t * 12)
    if kind == "hat":
        n = int(0.06 * RATE)
        s = rng.standard_normal(n)
        s = s - np.convolve(s, np.ones(4) / 4, mode="same")
        return s * np.exp(-np.arange(n) / RATE * 60) * 0.35
    if kind == "snare":
        n = int(0.18 * RATE)
        t = np.arange(n) / RATE
        return (rng.standard_normal(n) * 0.6 + np.sin(2 * np.pi * 190 * t) * 0.5) * np.exp(-t * 22)
    if kind == "drip":
        n = int(0.12 * RATE)
        t = np.arange(n) / RATE
        f = 1800 * np.exp(-t * 10)
        return np.sin(2 * np.pi * np.cumsum(f / RATE)) * np.exp(-t * 30) * 0.4
    raise ValueError(kind)


# --------------------------------------------------------------------------
# Composition
# --------------------------------------------------------------------------
MODES = {
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
    "lydian": [0, 2, 4, 6, 7, 9, 11],
}
# Chord roots per bar, as scale degrees.
PROGRESSIONS = {
    "calm": [0, 5, 3, 4],
    "wander": [0, 3, 0, 4],
    "dark": [0, 5, 6, 4],
    "drive": [0, 0, 5, 6],
    "still": [0, 3, 5, 3],
}


def degree(scale, root, d, octave=0):
    o, i = divmod(d, 7)
    return root + scale[i] + 12 * (o + octave)


def phrase_in_key(index, root, octave=0):
    """Lullaby phrase `index` (0-based), moved into a track's key (the
    nearest transposition), then `octave` octaves up or down."""
    shift = root - LULLABY["root"]
    while shift > 6:
        shift -= 12
    while shift < -6:
        shift += 12
    shift += 12 * octave
    return [(m + shift, b) for m, b in LULLABY["phrases"][index]]


def compose(c, seed):
    """Lays out notes for a track spec `c`. Returns a list of
    (start_seconds, kind, midi, seconds, vol) and drum hits."""
    rng = np.random.default_rng(seed)
    scale = MODES[c["mode"]]
    root = c["root"]
    beat = 60.0 / c["tempo"]
    bpb = c.get("beats", 4)
    bars = c.get("bars", 16)
    prog = PROGRESSIONS[c["prog"]]
    notes, hits = [], []
    for bar in range(bars):
        t0 = bar * bpb * beat
        chord = prog[bar % len(prog)]
        # Pad: the chord held for the bar.
        if c.get("pad"):
            for k in (0, 2, 4):
                notes.append((t0, c["pad"], degree(scale, root, chord + k, 0), bpb * beat, 0.16))
        # Bass.
        if c.get("bass"):
            pattern = c.get("bass_pattern", [0])
            step = bpb / len(pattern)
            for i, d in enumerate(pattern):
                if d is None:
                    continue
                notes.append((t0 + i * step * beat, "bass", degree(scale, root, chord + d, -2), step * beat * 0.9, 0.5))
        # Drums.
        for kind, places in c.get("drums", {}).items():
            for p in places:
                if p < bpb:
                    hits.append((t0 + p * beat, kind))
    # Melody: wandering steps around the chord tones, except where the
    # lullaby phrase sits (bars 8-9), played on the lead and doubled softly.
    lead = c["lead"]
    motif_bar = c.get("motif_bar", bars // 2)
    t = 0.0
    d = 4
    end = bars * bpb * beat
    motif = c.get("motif")
    # The phrase starts on its bar line, and the melody picks up again on
    # the first bar line after it ends.
    motif_start = motif_bar * bpb * beat if motif is not None else end
    while t < end - 0.01:
        if t >= motif_start - 0.001 and motif is not None:
            mt = motif_start
            for m, b in phrase_in_key(motif, root, c.get("lead_octave", 0)):
                notes.append((mt, lead, m, b * beat * 0.95, 0.55))
                notes.append((mt, "bell", m + 12, b * beat, 0.12))
                mt += b * beat
            bar_len = bpb * beat
            t = np.ceil((mt - motif_start) / bar_len - 1e-6) * bar_len + motif_start
            motif = None
            continue
        if rng.random() < c.get("rest", 0.25):
            t += beat * rng.choice([1, 2])
            continue
        d += int(rng.choice([-2, -1, -1, 0, 1, 1, 2]))
        d = max(0, min(9, d))
        length = rng.choice(c.get("lengths", [1, 1, 2, 0.5]))
        # No note runs over the end of the loop or into the phrase.
        length = min(length, (end - t) / beat, max(0.5, (motif_start - t) / beat) if t < motif_start else length)
        notes.append((t, lead, degree(scale, root, d, c.get("lead_octave", 0)), length * beat * 0.95, 0.45))
        t += length * beat
    return notes, hits, end


def render_track(c, seed):
    notes, hits, end = compose(c, seed)
    tail = 1.5
    mix = np.zeros(int((end + tail) * RATE))
    for start, kind, midi, seconds, vol in notes:
        v = voice(kind, midi, seconds + (0.8 if kind == "bell" else 0.0), vol)
        i = int(start * RATE)
        mix[i:i + len(v)] += v[:len(mix) - i]
    for k, (start, kind) in enumerate(hits):
        v = drum(kind, seed + k) * c.get("drum_vol", 0.5)
        i = int(start * RATE)
        mix[i:i + len(v)] += v[:len(mix) - i]
    # Fold the tail back onto the start so the loop rings over its seam.
    n = int(end * RATE)
    loop = mix[:n].copy()
    loop[:len(mix) - n] += mix[n:]
    # Gentle room: a few soft echoes.
    out = loop.copy()
    for delay, gain in ((0.11, 0.25), (0.23, 0.15), (0.37, 0.08)):
        d = int(delay * RATE)
        out += np.roll(loop, d) * gain
    out = np.tanh(out * 1.2)
    return out / max(1e-9, np.abs(out).max()) * 0.7


def render_phrase(index):
    beat = 60.0 / LULLABY["tempo"]
    notes = LULLABY["phrases"][index]
    # The ring-out is one bar, so phrases played back to back stay in time.
    total = (sum(b for _, b in notes) + LULLABY.get("beats", 3)) * beat
    mix = np.zeros(int(total * RATE))
    t = 0.0
    for m, b in notes:
        i = int(t * RATE)
        for v in (voice("bell", m, b * beat + 1.5, 0.6), voice("flute", m - 12, b * beat * 0.95, 0.25)):
            v = v[:len(mix) - i]
            mix[i:i + len(v)] += v
        t += b * beat
    return mix / max(1e-9, np.abs(mix).max()) * 0.7


# --------------------------------------------------------------------------
# The cues. motif: which bell's phrase (0-based) the track carries.
# Bells: 0 Hull, 1 Kiln, 2 Mire, 3 Gale, 4 Glacier, 5 Belfry, 6 Tomb.
# --------------------------------------------------------------------------
D = {"kick": [0], "hat": [1, 3], "snare": [2]}
TRACKS = {
    "title": dict(root=62, mode="minor", tempo=72, beats=3, prog="calm", lead="flute", pad="pad",
                  bass=True, bass_pattern=[0], motif=0, lead_octave=0, rest=0.4),
    "overworld": dict(root=67, mode="mixolydian", tempo=112, prog="wander", lead="square", pad="pad",
                      bass=True, bass_pattern=[0, 4, 0, 4], drums=D, motif=0),
    "region_saltmarrow": dict(root=65, mode="major", tempo=96, beats=3, prog="calm", lead="pluck", pad="pad",
                              bass=True, bass_pattern=[0, None, 4], motif=0, rest=0.3),
    "region_brinewood": dict(root=62, mode="dorian", tempo=100, prog="wander", lead="flute", pad="pad",
                             bass=True, bass_pattern=[0, None, 4, None], drums={"drip": [1, 2.5]}, motif=0),
    "region_cinderreach": dict(root=64, mode="phrygian", tempo=124, prog="drive", lead="saw", pad="organ",
                               bass=True, bass_pattern=[0, 0, 0, 0], drums={"kick": [0, 2], "snare": [1, 3]}, motif=1),
    "region_gloamfen": dict(root=61, mode="minor", tempo=80, beats=3, prog="dark", lead="bell", pad="pad",
                            bass=True, bass_pattern=[0], drums={"drip": [1.5]}, motif=2, rest=0.45),
    "region_windmere": dict(root=69, mode="lydian", tempo=118, prog="wander", lead="flute", pad="pad",
                            bass=True, bass_pattern=[0, 4, 2, 4], drums={"hat": [0.5, 1.5, 2.5, 3.5]}, motif=3),
    "region_frostspine": dict(root=66, mode="minor", tempo=70, beats=3, prog="still", lead="bell", pad="pad",
                              bass=True, bass_pattern=[0], motif=4, rest=0.5),
    "region_sunken_verge": dict(root=63, mode="dorian", tempo=76, beats=3, prog="still", lead="flute", pad="organ",
                                bass=True, bass_pattern=[0, None, 2], motif=5, rest=0.4),
    "region_ossuary": dict(root=60, mode="phrygian", tempo=88, prog="dark", lead="pluck", pad="pad",
                           bass=True, bass_pattern=[0, None, 0, None], drums={"kick": [0], "hat": [2]}, motif=6),
    "region_maw": dict(root=58, mode="phrygian", tempo=64, beats=3, prog="dark", lead="organ", pad="pad",
                       bass=True, bass_pattern=[0], drums={"kick": [0]}, motif=6, rest=0.5),
    "dungeon_cellar": dict(root=62, mode="minor", tempo=90, prog="still", lead="pluck", pad="pad",
                           bass=True, bass_pattern=[0, None, None, 4], drums={"drip": [3]}, motif=0, rest=0.4),
    "dungeon_hull": dict(root=62, mode="dorian", tempo=92, beats=3, prog="dark", lead="square", pad="organ",
                         bass=True, bass_pattern=[0, 4, 4], drums={"kick": [0], "hat": [2]}, motif=0),
    "dungeon_kiln": dict(root=64, mode="phrygian", tempo=132, prog="drive", lead="saw", pad="organ",
                         bass=True, bass_pattern=[0, 0, 0, 0], drums={"kick": [0, 1.5, 2], "snare": [1, 3]}, motif=1),
    "dungeon_mire": dict(root=61, mode="minor", tempo=76, beats=3, prog="dark", lead="bell", pad="pad",
                         bass=True, bass_pattern=[0, None, 5], drums={"drip": [0.5, 2]}, motif=2, rest=0.45),
    "dungeon_gale": dict(root=69, mode="lydian", tempo=128, prog="drive", lead="square", pad="pad",
                         bass=True, bass_pattern=[0, 4, 0, 4], drums=D, motif=3),
    "dungeon_glacier": dict(root=66, mode="minor", tempo=84, beats=3, prog="still", lead="bell", pad="organ",
                            bass=True, bass_pattern=[0, 4, None], drums={"hat": [1, 2]}, motif=4, rest=0.4),
    "dungeon_belfry": dict(root=63, mode="dorian", tempo=80, beats=3, prog="dark", lead="organ", pad="pad",
                           bass=True, bass_pattern=[0], drums={"drip": [2]}, motif=5),
    "dungeon_tomb": dict(root=60, mode="phrygian", tempo=96, prog="dark", lead="pluck", pad="organ",
                         bass=True, bass_pattern=[0, None, 1, None], drums={"kick": [0, 2], "hat": [3]}, motif=6),
    "dungeon_maw": dict(root=58, mode="phrygian", tempo=70, beats=3, prog="dark", lead="organ", pad="pad",
                        bass=True, bass_pattern=[0, 0, 0], drums={"kick": [0]}, motif=6, rest=0.4),
    "boss": dict(root=64, mode="phrygian", tempo=150, prog="drive", lead="saw", pad="organ", bars=8,
                 bass=True, bass_pattern=[0, 0, 0, 0, 0, 0, 0, 0], drums={"kick": [0, 1, 2, 3], "snare": [1, 3], "hat": [0.5, 1.5, 2.5, 3.5]},
                 lengths=[0.5, 0.5, 1], rest=0.1, drum_vol=0.6),
    "miniboss": dict(root=62, mode="minor", tempo=140, prog="drive", lead="square", pad="organ", bars=8,
                     bass=True, bass_pattern=[0, 0, 4, 0], drums={"kick": [0, 2], "snare": [1, 3]},
                     lengths=[0.5, 1], rest=0.15),
    "credits": dict(root=62, mode="major", tempo=84, beats=3, prog="calm", lead="flute", pad="pad", bars=24,
                    bass=True, bass_pattern=[0, None, 4], motif=6, motif_bar=12, rest=0.3),
}


## Loudness targets (integrated LUFS). Music sits at -18 so effects ride
## over it; the bell phrases come in louder, over the dipped track.
MUSIC_LUFS = -18.0
PHRASE_LUFS = -16.0
## The highest sample peak left after levelling (about -1.5 dBFS).
PEAK_LIMIT = 0.84


def _write_wav(name, samples):
    pcm = (np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(name, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm)


def loudness(samples):
    """Integrated loudness in LUFS (EBU R128, measured by ffmpeg)."""
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        name = tmp.name
    _write_wav(name, samples)
    out = subprocess.run(["ffmpeg", "-nostats", "-i", name, "-af", "ebur128", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    os.unlink(name)
    summary = out[out.rindex("Integrated loudness"):]
    return float(summary.split("I:")[1].split()[0])


def level(samples, target):
    """Scales a mix to `target` LUFS, keeping its peaks under PEAK_LIMIT."""
    gain = 10.0 ** ((target - loudness(samples)) / 20.0)
    gain = min(gain, PEAK_LIMIT / max(1e-9, np.abs(samples).max()))
    return samples * gain


def write_ogg(path, samples):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        name = tmp.name
    _write_wav(name, samples)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", name, "-c:a", "libvorbis", "-q:a", "3",
                    "-map_metadata", "-1", "-fflags", "+bitexact", path], check=True)
    os.unlink(name)


def main():
    only = None
    if "--only" in sys.argv:
        only = set(sys.argv[sys.argv.index("--only") + 1].split(","))
    jobs = [(name, lambda c=c, s=i: level(render_track(c, 1000 + s), MUSIC_LUFS))
            for i, (name, c) in enumerate(TRACKS.items())]
    jobs += [("bell_%d" % (i + 1), lambda i=i: level(render_phrase(i), PHRASE_LUFS))
             for i in range(len(LULLABY["phrases"]))]
    # The whole lullaby is levelled as one, so the phrases keep their balance.
    jobs.append(("lullaby", lambda: level(np.concatenate([render_phrase(i) for i in range(len(LULLABY["phrases"]))]),
                                          PHRASE_LUFS)))
    done = 0
    for name, make in jobs:
        if only and name not in only:
            continue
        write_ogg(os.path.join(OUT, name + ".ogg"), make())
        done += 1
    print("Wrote %d tracks." % done)


if __name__ == "__main__":
    main()
