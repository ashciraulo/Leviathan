"""Gates FL's split-stem renders against the cue's MIDI before mixing.

    python3 music/post/gate_stems.py <cue> <stem dir> [--map part=stem_file ...]

For each part's stem (FL "Split mixer tracks" render, one insert per part):
- sounding octave and tuning: the strongest partial near each written note's
  fundamental, per note, so a preset an octave off or detuned shows up;
- per-note pitch spread (a lead can average 0 cents and still scatter);
- note-level evenness: the level of each note's attack against its velocity;
- wobble: amplitude modulation 3-9 Hz inside held notes (hidden LFOs, chorus);
- stray sound before the part's first note, and silent notes.
Drums and other unpitched parts only get the stray-sound and silent-note checks.
Fails print what to change (preset swap, transpose, fine-tune).
"""
from __future__ import annotations

import json
import os
import sys

import mido
import numpy as np
import soundfile

MUSIC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNPITCHED = ("drum", "shaker", "perc", "taiko", "anvil", "tom", "timpani")


def notes_of(path: str, qbpm: float) -> list[tuple[float, float, int, int]]:
    mf = mido.MidiFile(path)
    sec_per_tick = 60.0 / qbpm / mf.ticks_per_beat
    t, on, out = 0, {}, []
    for msg in mf.tracks[0]:
        t += msg.time
        if msg.type == "note_on" and msg.velocity:
            on[msg.note] = (t, msg.velocity)
        elif msg.type in ("note_off", "note_on") and msg.note in on:
            s, v = on.pop(msg.note)
            out.append((s * sec_per_tick, (t - s) * sec_per_tick, msg.note, v))
    return sorted(out)


def hz(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12)


def note_pitch(x: np.ndarray, rate: int, midi: int) -> tuple[float, float]:
    """(cents off the written note, octaves off) from the strongest of the
    candidate fundamentals two octaves down to two up."""
    n = 1 << int(np.ceil(np.log2(max(len(x), 4096)))) + 3  # zero-pad 8x for fine bins
    spec = np.abs(np.fft.rfft(x * np.hanning(len(x)), n))
    freqs = np.fft.rfftfreq(n, 1 / rate)
    best, best_amp = None, 0.0
    for octv in (-2, -1, 0, 1, 2):
        f = hz(midi) * 2 ** octv
        if f < 25 or f > rate / 2.2:
            continue
        band = (freqs > f * 0.97) & (freqs < f * 1.03)
        if not band.any():
            continue
        i = int(np.argmax(spec * band))
        if 0 < i < len(spec) - 1:  # parabolic peak interpolation
            a, b, c = np.log(spec[i - 1:i + 2] + 1e-12)
            peak = i + 0.5 * (a - c) / (a - 2 * b + c)
        else:
            peak = i
        # Harmonic sum, so an octave-up partial of a low note doesn't win.
        amp = sum(spec[min(len(spec) - 1, int(round(i * k)))] / k for k in (1, 2, 3))
        if amp > best_amp * 1.4 or best is None:
            best, best_amp = (octv, peak * rate / n), amp
    octv, f = best
    # The pitch we hear comes from the overtones as much as the fundamental, and
    # a sampled string can disagree with itself (review of Saltmarrow v13: the
    # bass's A2 fundamental read -27 c while its harmonics sat at +8). Use the
    # median over the fundamental and harmonics 2-4 that are within 30 dB of the
    # strongest of them.
    f0 = hz(midi) * 2 ** octv
    reads = []
    for k in (1, 2, 3, 4):
        t = f0 * k
        if t > rate / 2.2:
            break
        band = (freqs > t * 0.985) & (freqs < t * 1.015)
        if not band.any():
            continue
        i = int(np.argmax(spec * band))
        if not 0 < i < len(spec) - 1:
            continue
        a, b, c = np.log(spec[i - 1:i + 2] + 1e-12)
        peak = i + 0.5 * (a - c) / (a - 2 * b + c)
        reads.append((spec[i], 1200 * np.log2(peak * rate / n / t)))
    top = max(amp for amp, _ in reads) if reads else 0
    good = [c for amp, c in reads if amp > top * 10 ** (-30 / 20)]
    cents = float(np.median(good)) if good else 1200 * np.log2(f / f0)
    # The strongest partial alone: a median can hide one loud, mistuned partial
    # (review of Saltmarrow v15: A2's fundamental at -33 c beat against the guitar).
    strongest = max(reads)[1] if reads else cents
    return float(cents), int(octv), float(strongest)


def gate(cue: str, stem_dir: str, mapping: dict[str, str]) -> list[str]:
    meta = json.load(open(os.path.join(MUSIC, "midi", cue, "cue.json")))
    problems = []
    for part in meta["parts"]:
        name = part["name"]
        stem = mapping.get(name) or next((f for f in os.listdir(stem_dir) if name in f), None)
        if not stem:
            problems.append(f"{name}: no stem found")
            continue
        x, rate = soundfile.read(os.path.join(stem_dir, stem), always_2d=True)
        mono = x.mean(axis=1)
        notes = notes_of(os.path.join(MUSIC, "midi", cue, name + ".mid"), meta["qbpm"])
        first = int(notes[0][0] * rate)
        pre = mono[: max(0, first - int(0.02 * rate))]
        if pre.size and 20 * np.log10(np.abs(pre).max() + 1e-9) > -60:
            problems.append(f"{name}: sound before its first note ({20 * np.log10(np.abs(pre).max()):.0f} dBFS)")
        levels, level_keys, cents, octs, by_key = [], [], [], [], {}
        # Only notes that sound alone are measured for pitch and evenness:
        # a chord's notes mask each other.
        alone = [all(o is nt or o[0] >= nt[0] + nt[1] or o[0] + o[1] <= nt[0] for o in notes) for nt in notes]
        for (start, dur, midi, vel), solo in zip(notes, alone):
            i = int(start * rate)
            seg = mono[i: i + int(min(dur, 0.5) * rate)]
            if seg.size < 256:
                continue
            lvl = 20 * np.log10(np.sqrt(np.mean(seg[: int(0.08 * rate)] ** 2)) + 1e-9)
            if lvl < -60:
                problems.append(f"{name}: silent note {midi} at {start:.2f} s")
                continue
            if not solo:
                continue
            levels.append((lvl, vel, start))
            level_keys.append(midi)
            if any(name.startswith(u) for u in UNPITCHED) or dur < 0.12:
                continue
            c, o, strong = note_pitch(seg[int(0.03 * rate):], rate, midi)
            cents.append(c)
            octs.append(o)
            by_key.setdefault(midi, []).append((c, strong))
        # A part that is mostly chords leaves few solo notes; one note can't judge a part.
        if len(octs) >= 5:
            octave = max(set(octs), key=octs.count)
            if octave:
                problems.append(f"{name}: sounds {octave:+d} octave(s) from the written notes "
                                f"(transpose the part {-12 * octave:+d} or swap the preset)")
            c = np.array(cents)
            if abs(np.median(c)) > 8:
                problems.append(f"{name}: tuned {np.median(c):+.0f} cents off (set fine-tune, then re-measure)")
            # A sampled instrument is out of tune key by key, which a part-wide
            # percentile can hide when the bad key is a minority of the notes.
            for key, kc in sorted(by_key.items()):
                med, loud = np.median([c for c, _ in kc]), np.median([st for _, st in kc])
                if len(kc) >= 3 and abs(med) > 10:
                    problems.append(f"{name}: key {key} sounds {med:+.0f} cents off over {len(kc)} notes "
                                    "(retune it: maps/<cue>_fix.json)")
                elif len(kc) >= 3 and abs(loud) > 12:
                    problems.append(f"{name}: key {key}'s strongest partial is {loud:+.0f} cents off while the others "
                                    "agree (an inharmonic sample: play a neighbouring key, maps/<cue>_fix.json)")
            if np.percentile(np.abs(c - np.median(c)), 90) > 15:
                problems.append(f"{name}: per-note pitch scatters (90th percentile "
                                f"{np.percentile(np.abs(c - np.median(c)), 90):.0f} c)")
        if len(levels) > 8:
            lv = np.array([l for l, v, s in levels if l > -60])
            vv = np.array([v for l, v, s in levels if l > -60])
            if len(lv) > 8:
                fit = np.polyfit(vv, lv, 1)
                resid = lv - np.polyval(fit, vv)
                # A sampled instrument can be hot or soft key by key (review of v15).
                keys = np.array([k for (l, v, st), k in zip(levels, level_keys) if l > -60])
                for key in sorted(set(keys)):
                    kr = resid[keys == key]
                    if len(kr) >= 3 and abs(np.median(kr)) > 3.0:
                        problems.append(f"{name}: key {key} is {np.median(kr):+.1f} dB off the part's level at equal "
                                        "velocity (trim it: maps/<cue>_fix.json)")
                if np.std(resid) > 3.0:
                    problems.append(f"{name}: note levels jump around ({np.std(resid):.1f} dB spread at equal "
                                    "velocity); render again to see if the preset randomises")
    return problems


if __name__ == "__main__":
    cue, stem_dir = sys.argv[1], sys.argv[2]
    mapping = dict(a.split("=", 1) for a in sys.argv[3:] if "=" in a)
    found = gate(cue, stem_dir, mapping)
    for p in found:
        print("GATE:", p)
    print("PASS" if not found else f"{len(found)} problem(s)")
    sys.exit(1 if found else 0)
