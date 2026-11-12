"""Gates FL's split-stem renders against the cue's MIDI before mixing.

    python3 music/post/gate_stems.py <cue> <stem dir> [part=stem_file ...] [--octave part=+1 ...]

For each part's stem (FL "Split mixer tracks" render, one insert per part):
- sounding octave and tuning: the strongest partial near each written note's
  fundamental, per note, so a preset an octave off or detuned shows up;
- per-note pitch spread (a lead can average 0 cents and still scatter);
- note-level evenness: the level of each note's attack against its velocity;
- wobble inside held notes (hidden LFOs, chorus, a detuned layer) and the
  left channel's pitch against the right;
- stray sound before the part's first note, silent notes, and notes that stop dead.
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
# Struck and plucked parts whose held notes should only decay: a flute's vibrato or an accordion's
# musette beating is the instrument, but on a bell or music box it is a fault.
STRUCK = ("musicbox", "bell", "celesta", "glock", "harp", "chime", "mallet")


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


def gate(cue: str, stem_dir: str, mapping: dict[str, str], octaves: dict[str, int] | None = None) -> list[str]:
    """octaves: parts meant to sound away from their written notes (a glockenspiel
    doubling a melody an octave up: --octave box_shine=1)."""
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
        # Notes that stop dead: a sampled or gated preset can cut its sound off long before the
        # written note ends (lullaby review v5, MAJOR 1: every music box note dropped 25-34 dB in
        # under 10 ms). Look for a cliff in the 10 ms envelope between 150 ms after each onset and
        # the next onset of the part (or the written end), where a natural decay never falls that fast.
        if not any(u in name for u in UNPITCHED):
            hop = int(0.01 * rate)
            env = 20 * np.log10(np.array([np.abs(mono[k:k + hop]).max() for k in range(0, mono.size - hop, hop)]) + 1e-9)
            onsets = sorted({n[0] for n in notes})
            cut = 0
            for k, on in enumerate(onsets):
                stop = onsets[k + 1] if k + 1 < len(onsets) else on + max(n[1] for n in notes if n[0] == on)
                seg = env[int((on + 0.15) * 100): int(stop * 100)]
                if seg.size > 3 and seg.max() > -60 and (-np.diff(seg)).max() > 20:
                    cut += 1
            if cut > max(1, len(onsets) // 10):
                problems.append(f"{name}: {cut} of {len(onsets)} notes stop dead (a >20 dB drop within 10 ms "
                                "before the next note): the preset gates or cuts its sound; swap it")
        # Wobble and a detuned second layer (lullaby review v6, MINOR: Celestia's left channel sat
        # +13 c over its right, so every held note beat at 4-9 Hz, 8-16 dB deep). For solo notes held
        # 0.6 s or more: the peak-to-peak ripple of the 20 ms envelope around a smooth decay, and the
        # pitch of the left channel against the right.
        if not any(u in name for u in UNPITCHED) and x.shape[1] == 2:
            wob, lr = [], []
            for nt in notes:
                nxt = min((o[0] for o in notes if o[0] > nt[0] + 0.01), default=nt[0] + nt[1])
                span = min(nxt - nt[0], 1.2)
                # Until the next onset: an earlier note may still ring, but none starts inside.
                if span < 0.6 or any(o is not nt and nt[0] - 0.01 < o[0] < nt[0] + 0.01 for o in notes):
                    continue
                i = int(nt[0] * rate)
                seg2 = x[i + int(0.08 * rate): i + int(span * rate)]
                hop, w = int(0.005 * rate), int(0.02 * rate)
                env = 20 * np.log10(np.sqrt(np.convolve(seg2.mean(axis=1) ** 2, np.ones(w) / w, "same"))[::hop] + 1e-9)
                if env.max() < -60:
                    continue
                tt = np.arange(env.size)
                r = env - np.polyval(np.polyfit(tt, env, 2), tt)
                wob.append(r.max() - r.min())
                lr.append(note_pitch(seg2[:, 0], rate, nt[2])[0] - note_pitch(seg2[:, 1], rate, nt[2])[0])
            # A bell phrase holds only three or four notes (review of the bells v1, MAJOR 6: bell_1's
            # +-20 c layers and bell_5's 1 Hz beat went unmeasured at the old five-note minimum).
            if len(wob) >= 3:
                if abs(np.median(lr)) > 6:
                    problems.append(f"{name}: left channel sounds {np.median(lr):+.0f} cents from the right (a detuned "
                                    "layer that beats): zero the preset's detune/spread or pick another preset")
                if any(u in name for u in STRUCK) and np.median(wob) > 8:
                    problems.append(f"{name}: held notes wobble {np.median(wob):.1f} dB peak to peak (beating layers, "
                                    "chorus or an LFO): turn it off in the preset or pick another")
        # Chord tones are never solo, so the solo-note pitch check below never sees a part that only
        # plays chords (review of the bells v1, BLOCKER: bell_4's string swell sat +23..+32 c sharp).
        # Read each chord tone's own peak within +-40 c of where it should be, from 0.15 s after the
        # chord starts until the next onset (at most 1.5 s), and judge the median.
        if not any(u in name for u in UNPITCHED):
            onsets = sorted({round(n[0], 2) for n in notes})
            chord_c = []
            for on in onsets:
                tones = [n for n in notes if abs(n[0] - on) < 0.02]
                if len(tones) < 2:
                    continue
                nxt = min((o for o in onsets if o > on + 0.02), default=on + max(t[1] for t in tones))
                i, j = int((on + 0.15) * rate), int((on + min(nxt - on, 1.5)) * rate)
                seg3 = mono[i:j]
                if seg3.size < rate // 4 or 20 * np.log10(np.abs(seg3).max() + 1e-9) < -50:
                    continue
                n = 1 << int(np.ceil(np.log2(seg3.size))) + 3
                spec = np.abs(np.fft.rfft(seg3 * np.hanning(seg3.size), n))
                freqs = np.fft.rfftfreq(n, 1 / rate)
                for t in tones:
                    f = hz(t[2])
                    band = (freqs > f * 2 ** (-40 / 1200)) & (freqs < f * 2 ** (40 / 1200))
                    k = int(np.argmax(spec * band))
                    if not band.any() or not 0 < k < len(spec) - 1 or spec[k] < spec.max() * 10 ** (-40 / 20):
                        continue
                    a, b, c = np.log(spec[k - 1:k + 2] + 1e-12)
                    chord_c.append(1200 * np.log2((k + 0.5 * (a - c) / (a - 2 * b + c)) * rate / n / f))
            if len(chord_c) >= 4 and abs(np.median(chord_c)) > 10:
                problems.append(f"{name}: chord tones sound {np.median(chord_c):+.0f} cents off over {len(chord_c)} "
                                "readings (zero the preset's tuning, then re-measure)")
        levels, level_keys, cents, octs, by_key = [], [], [], [], {}
        # Only notes that sound alone are measured for pitch and evenness:
        # a chord's notes mask each other.
        alone = [all(o is nt or o[0] >= nt[0] + nt[1] or o[0] + o[1] <= nt[0] for o in notes) for nt in notes]
        # A melody that rings over itself (a music box held into the next note) has no strictly solo
        # notes, and v7's first box preset sounded two octaves up without the gate measuring a note.
        # Then use every note whose measured half second no other onset enters, the tail of an
        # earlier note being far quieter than a fresh attack.
        if sum(alone) < 5:
            alone = [all(o is nt or not nt[0] - 0.02 < o[0] < nt[0] + min(nt[1], 0.5) for o in notes)
                     and not any(o is not nt and o[0] <= nt[0] < o[0] + o[1] and nt[0] - o[0] < 0.25 for o in notes)
                     for nt in notes]
        for (start, dur, midi, vel), solo in zip(notes, alone):
            i = int(start * rate)
            seg = mono[i: i + int(min(dur, 0.5) * rate)]
            if seg.size < 256:
                continue
            # Judged over the note's first half second, not its first 80 ms: a slow-attack choir
            # or pad swells in and was flagged silent (lullaby review v5, NOTE 1).
            lvl = 20 * np.log10(np.sqrt(np.mean(seg ** 2)) + 1e-9)
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
        if len(octs) >= min(5, max(3, len(notes) - 1)):
            octave = max(set(octs), key=octs.count)
            # A sustained bell still rings under the next note, and its overtones can win a single read
            # (bell_4 v8: votes -1, 0, +1, 0), so only a clear majority judges the octave.
            if octs.count(octave) > 0.6 * len(octs) and octave != (octaves or {}).get(name, 0):
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
    mapping, octaves, args = {}, {}, sys.argv[3:]
    for i, a in enumerate(args):
        if "=" in a:
            k, v = a.split("=", 1)
            if i and args[i - 1] == "--octave":
                octaves[k] = int(v)
            else:
                mapping[k] = v
    found = gate(cue, stem_dir, mapping, octaves)
    for p in found:
        print("GATE:", p)
    print("PASS" if not found else f"{len(found)} problem(s)")
    sys.exit(1 if found else 0)
