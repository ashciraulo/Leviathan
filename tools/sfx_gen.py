"""Leviathan's sound effects and ambience loops, made in code.

    python3 tools/sfx_gen.py           writes audio/sfx/*.wav and audio/ambience/*.wav
    python3 tools/sfx_gen.py --check   fails if a file is missing or out of date
    python3 tools/sfx_gen.py --only hum_heal,bell_ring   rebuilds just those

Pure Python (no numpy), 16-bit mono WAV at 22050 Hz. Every sound is a few
layers mixed together. A layer is an oscillator (sine, triangle, square,
saw, noise, or an FM bell) with a pitch that glides, an envelope, optional
vibrato, filters and a note pattern. Noise uses a seeded generator, so the
files come out the same on every run.

The game plays a file from audio/sfx/ when one exists, and otherwise falls
back to the tiny placeholder synth in scripts/autoload/audio.gd. Captions
live there too (Audio.SFX), so every id here also needs an entry there.

Audio carries the "no explanatory text" rule: every interaction, enemy
tell and place has its own sound, so a player learns the world by ear.
"""

import math
import os
import random
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "audio", "sfx")
AMB_DIR = os.path.join(ROOT, "audio", "ambience")
RATE = 22050
TAU = math.pi * 2.0


def semis(n):
    return 2.0 ** (n / 12.0)


# --------------------------------------------------------------------------
# The synth
# --------------------------------------------------------------------------
def L(osc, f=440.0, to=None, dur=0.2, at=0.0, vol=1.0, attack=0.004, decay=None,
      sustain=1.0, release=0.03, curve="exp", vib=(0.0, 0.0), notes=None,
      lp=None, hp=None, ratio=3.5, index=2.0, duty=0.5, seed=1, rate=None, wobble=None):
    """One layer. f/to: start and end pitch in Hz. decay: if set, the level
    falls exponentially with this time constant (seconds) after the attack;
    otherwise it holds at `sustain` until the release. notes: semitone
    offsets stepped evenly across the layer. lp/hp: one-pole filter cutoffs
    in Hz (a pair sweeps from the first to the second). rate: how often
    noise picks a new value (Hz), for gritty noise. wobble: (rate Hz,
    depth 0..1) amplitude tremolo."""
    return dict(osc=osc, f=f, to=to if to is not None else f, dur=dur, at=at, vol=vol,
                attack=attack, decay=decay, sustain=sustain, release=release, curve=curve,
                vib=vib, notes=notes, lp=lp, hp=hp, ratio=ratio, index=index, duty=duty,
                seed=seed, rate=rate, wobble=wobble)


def _sweep(a, b, t, curve):
    if a == b:
        return a
    if curve == "exp" and a > 0 and b > 0:
        return a * (b / a) ** t
    return a + (b - a) * t


def _alpha(cut):
    # One-pole filter coefficient for a cutoff in Hz.
    cut = max(10.0, min(cut, RATE * 0.45))
    return 1.0 - math.exp(-TAU * cut / RATE)


def render_layer(layer, total):
    n = int(layer["dur"] * RATE)
    start = int(layer["at"] * RATE)
    out = [0.0] * total
    rng = random.Random(layer["seed"])
    phase = mod_phase = 0.0
    held = 0.0
    hold_clock = 1.0
    lp_state = 0.0
    hp_state = 0.0
    hp_prev = 0.0
    attack = max(1, int(layer["attack"] * RATE))
    release = max(1, int(layer["release"] * RATE))
    notes = layer["notes"]
    for i in range(n):
        j = start + i
        if j >= total:
            break
        t = i / max(1, n - 1)
        freq = _sweep(layer["f"], layer["to"], t, layer["curve"])
        if notes:
            freq *= semis(notes[min(int(t * len(notes)), len(notes) - 1)])
        vr, vd = layer["vib"]
        if vd:
            freq *= 1.0 + vd * math.sin(TAU * vr * i / RATE)
        osc = layer["osc"]
        if osc == "noise":
            if layer["rate"]:
                hold_clock += layer["rate"] / RATE
                if hold_clock >= 1.0:
                    hold_clock -= 1.0
                    held = rng.uniform(-1.0, 1.0)
                s = held
            else:
                s = rng.uniform(-1.0, 1.0)
        else:
            phase = (phase + freq / RATE) % 1.0
            if osc == "sine":
                s = math.sin(TAU * phase)
            elif osc == "tri":
                s = 4.0 * abs(phase - 0.5) - 1.0
            elif osc == "square":
                s = 1.0 if phase < layer["duty"] else -1.0
            elif osc == "saw":
                s = 2.0 * phase - 1.0
            elif osc == "fm":
                mod_phase = (mod_phase + freq * layer["ratio"] / RATE) % 1.0
                # The bell's brightness fades with the note.
                idx = layer["index"] * (1.0 - 0.8 * t)
                s = math.sin(TAU * phase + idx * math.sin(TAU * mod_phase))
            else:
                raise ValueError(osc)
        lp = layer["lp"]
        if lp is not None:
            cut = _sweep(lp[0], lp[1], t, "exp") if isinstance(lp, tuple) else lp
            lp_state += _alpha(cut) * (s - lp_state)
            s = lp_state
        hp = layer["hp"]
        if hp is not None:
            cut = _sweep(hp[0], hp[1], t, "exp") if isinstance(hp, tuple) else hp
            a = 1.0 - _alpha(cut)
            hp_state = a * (hp_state + s - hp_prev)
            hp_prev = s
            s = hp_state
        # Envelope.
        if i < attack:
            env = i / attack
        elif layer["decay"]:
            env = math.exp(-(i - attack) / (layer["decay"] * RATE))
        else:
            env = layer["sustain"]
        if n - i < release:
            env *= (n - i) / release
        if layer["wobble"]:
            wr, wd = layer["wobble"]
            env *= 1.0 - wd * (0.5 + 0.5 * math.sin(TAU * wr * i / RATE))
        out[j] += s * env * layer["vol"]
    return out


def render(layers, peak=0.8, loop=False):
    total = int(max(l["at"] + l["dur"] for l in layers) * RATE)
    mix = [0.0] * total
    for layer in layers:
        for i, v in enumerate(render_layer(layer, total)):
            mix[i] += v
    if loop:
        # Cross-fade the tail into the head so the loop has no seam.
        fade = int(0.5 * RATE)
        head = mix[:fade]
        body = mix[fade:]
        for i in range(fade):
            k = i / fade
            body[len(body) - fade + i] = body[len(body) - fade + i] * (1.0 - k) + head[i] * k
        mix = body
    # Soft clip, then scale to the peak.
    mix = [math.tanh(v) for v in mix]
    top = max(1e-9, max(abs(v) for v in mix))
    return [v * peak / top for v in mix]


def to_wav_bytes(samples):
    frames = b"".join(struct.pack("<h", max(-32768, min(32767, int(round(v * 32767))))) for v in samples)
    return frames


# --------------------------------------------------------------------------
# The sounds. peak sets the loudness of the finished sound (0..1).
# --------------------------------------------------------------------------
def S(peak, *layers):
    return (peak, list(layers))


SOUNDS = {
    # ---- Wren ----
    "sword_swing": S(0.5,
        L("noise", dur=0.12, lp=(5000, 1400), hp=600, decay=0.05, seed=11),
        L("sine", 700, 300, dur=0.08, vol=0.25, decay=0.03)),
    "sword_spin": S(0.6,
        L("noise", dur=0.32, lp=(1200, 6000), hp=500, attack=0.03, decay=0.14, seed=12, wobble=(18, 0.5)),
        L("sine", 400, 900, dur=0.3, vol=0.25, decay=0.12)),
    "spin_charged": S(0.45,
        L("tri", 880, dur=0.18, notes=[0, 7, 12], decay=0.08),
        L("sine", 1760, dur=0.2, vol=0.3, notes=[0, 7, 12], decay=0.1)),
    "player_hurt": S(0.65,
        L("square", 520, 160, dur=0.2, decay=0.08, duty=0.3, lp=3000),
        L("noise", dur=0.08, lp=2500, decay=0.03, vol=0.6, seed=13)),
    "bubble_pop": S(0.55,
        L("sine", 600, 1900, dur=0.07, decay=0.03),
        L("noise", dur=0.03, hp=2000, vol=0.3, decay=0.01, seed=14)),
    "hum": S(0.4,
        L("tri", 330, dur=0.45, attack=0.06, release=0.15, vib=(5.5, 0.012), lp=1800),
        L("sine", 165, dur=0.45, vol=0.5, attack=0.06, release=0.15)),
    "hum_heal": S(0.5,
        L("tri", 523, dur=0.45, notes=[0, 4, 7], attack=0.02, decay=0.25, vib=(6, 0.01)),
        L("sine", 1046, dur=0.45, notes=[0, 4, 7], vol=0.3, decay=0.2),
        L("noise", dur=0.4, hp=5000, vol=0.08, decay=0.2, seed=15)),
    "player_fall": S(0.35,
        L("square", 700, 110, dur=0.5, duty=0.25, lp=2500, release=0.1),
        L("noise", at=0.42, dur=0.2, lp=900, decay=0.06, vol=0.6, seed=16)),
    # ---- Tools ----
    "hook_fire": S(0.5,
        L("noise", dur=0.14, lp=(6000, 2000), hp=1200, decay=0.05, seed=21),
        L("square", 1800, 900, dur=0.1, duty=0.2, vol=0.2, decay=0.04, lp=4000)),
    "hook_latch": S(0.55,
        L("fm", 1400, dur=0.18, ratio=2.7, index=3.0, decay=0.05),
        L("noise", dur=0.03, hp=3000, vol=0.4, decay=0.01, seed=22)),
    "hook_reel": S(0.4,
        L("square", 300, 520, dur=0.35, duty=0.15, lp=2000, wobble=(30, 0.8), release=0.05)),
    "bomb_fuse": S(0.3,
        L("noise", dur=0.35, hp=4000, rate=9000, wobble=(25, 0.6), seed=23, release=0.05)),
    "bomb_blast": S(0.85,
        L("noise", dur=0.75, lp=(3000, 200), decay=0.22, seed=24),
        L("sine", 110, 40, dur=0.6, vol=0.9, decay=0.2),
        L("noise", dur=0.06, hp=1500, vol=0.6, decay=0.02, seed=25)),
    "wayshell": S(0.55,
        L("fm", 392, dur=1.1, notes=[0, 4, 7, 12], ratio=2.0, index=1.2, decay=0.5, vib=(5, 0.006)),
        L("sine", 196, dur=1.1, vol=0.4, attack=0.1, decay=0.6),
        L("noise", dur=1.0, lp=600, hp=200, vol=0.15, attack=0.3, decay=0.4, seed=26)),
    "lantern_up": S(0.45,
        L("tri", 660, dur=0.22, notes=[0, 7], decay=0.12),
        L("noise", dur=0.2, lp=(800, 2600), hp=400, vol=0.25, attack=0.04, decay=0.08, seed=27)),
    "lantern_down": S(0.35,
        L("tri", 660, 440, dur=0.18, decay=0.08),
        L("noise", dur=0.12, lp=(2000, 500), vol=0.2, decay=0.05, seed=28)),
    "cloak_open": S(0.5,
        L("noise", dur=0.3, lp=(1800, 600), hp=200, attack=0.02, decay=0.1, seed=29, wobble=(14, 0.5))),
    "stonebreaker_slam": S(0.8,
        L("sine", 140, 50, dur=0.4, decay=0.12),
        L("noise", dur=0.35, lp=(2500, 300), decay=0.1, vol=0.8, seed=30)),
    "bow_draw": S(0.35,
        L("square", 180, 280, dur=0.16, duty=0.15, lp=1500, attack=0.05, release=0.03),
        L("noise", dur=0.15, lp=1200, hp=300, vol=0.25, attack=0.05, release=0.03, seed=301)),
    "bow_loose": S(0.5,
        L("noise", dur=0.14, lp=(6000, 1500), hp=800, decay=0.05, seed=302),
        L("tri", 220, 150, dur=0.12, vol=0.4, decay=0.04)),
    # ---- Ice ----
    "ice_freeze": S(0.5,
        L("noise", dur=0.4, hp=(2000, 6000), attack=0.02, decay=0.15, seed=303, rate=8000),
        L("fm", 1800, 2600, dur=0.35, ratio=1.41, index=2.5, vol=0.4, decay=0.12)),
    "ice_shatter": S(0.6,
        L("noise", dur=0.3, hp=2500, decay=0.08, seed=304),
        L("fm", 3000, 2200, dur=0.25, ratio=2.3, index=4.0, vol=0.5, decay=0.06),
        L("fm", 2400, 1700, at=0.04, dur=0.2, ratio=1.7, index=3.0, vol=0.4, decay=0.05)),
    "ice_eye_open": S(0.4,
        L("sine", 880, 1320, dur=0.3, decay=0.12, vib=(9, 0.01)),
        L("fm", 1760, dur=0.3, ratio=3.0, index=1.0, vol=0.3, decay=0.1)),
    "ice_eye_shut": S(0.35,
        L("sine", 1100, 660, dur=0.25, decay=0.1),
        L("noise", dur=0.06, hp=3000, vol=0.3, decay=0.02, seed=305)),
    "rimeling_squeak": S(0.35,
        L("square", 1400, 2100, dur=0.09, duty=0.2, decay=0.03),
        L("square", 1600, 2300, at=0.1, dur=0.07, duty=0.2, decay=0.03, vol=0.8)),
    "ice_groan": S(0.7,
        L("saw", 70, 50, dur=1.4, lp=(500, 200), attack=0.2, release=0.4, vib=(3, 0.05)),
        L("noise", dur=1.4, lp=400, vol=0.4, attack=0.3, release=0.4, seed=306, rate=600)),
    "walrus_bellow": S(0.7,
        L("saw", 140, 90, dur=0.7, lp=900, attack=0.05, release=0.2, vib=(6, 0.04)),
        L("square", 70, 45, dur=0.7, duty=0.4, lp=500, vol=0.6, attack=0.05, release=0.2)),
    "splash": S(0.55,
        L("noise", dur=0.45, lp=(3000, 700), hp=300, decay=0.14, seed=307),
        L("sine", 900, 300, dur=0.1, vol=0.3, decay=0.04),
        L("noise", at=0.08, dur=0.3, hp=2500, vol=0.25, decay=0.1, seed=308, rate=5000)),
    # ---- Light, fire and spirits ----
    "brazier_catch": S(0.55,
        L("noise", dur=0.5, lp=(600, 3000), hp=300, attack=0.05, decay=0.2, seed=31, wobble=(9, 0.4)),
        L("sine", 220, 330, dur=0.4, vol=0.25, attack=0.05, decay=0.2)),
    "wisp_chime": S(0.35,
        L("fm", 1568, dur=0.35, notes=[0, 7], ratio=3.01, index=1.5, decay=0.12)),
    "heart_beat": S(0.75,
        L("sine", 90, 50, dur=0.12, decay=0.05),
        L("sine", 80, 45, at=0.18, dur=0.14, vol=0.7, decay=0.06),
        L("noise", dur=0.06, lp=300, vol=0.3, decay=0.02, seed=32)),
    "thunder": S(0.85,
        L("noise", dur=0.06, hp=2000, decay=0.02, seed=33),
        L("noise", at=0.03, dur=1.4, lp=(1200, 120), decay=0.45, seed=34, wobble=(4, 0.5)),
        L("sine", 60, 35, at=0.05, dur=1.0, vol=0.7, decay=0.4)),
    "storm_gather": S(0.45,
        L("noise", dur=1.4, lp=(500, 4000), hp=300, attack=0.9, release=0.2, seed=35),
        L("saw", 110, 220, dur=1.4, vol=0.15, attack=1.0, lp=900, release=0.2)),
    "gust": S(0.45,
        L("noise", dur=1.1, lp=(400, 1600), hp=150, attack=0.25, release=0.4, seed=36, wobble=(3, 0.4))),
    "geyser_hiss": S(0.35,
        L("noise", dur=0.7, hp=(3000, 5000), attack=0.15, release=0.1, seed=37, wobble=(20, 0.3))),
    "geyser_blow": S(0.6,
        L("noise", dur=1.0, lp=(4000, 600), hp=150, attack=0.02, decay=0.35, seed=38),
        L("sine", 90, 60, dur=0.6, vol=0.5, decay=0.2)),
    "ice_slide": S(0.3,
        L("noise", dur=0.35, hp=2500, lp=7000, attack=0.05, release=0.1, seed=41)),
    # ---- Creatures ----
    "heron_cry": S(0.55,
        L("saw", 1100, 600, dur=0.42, lp=2600, vib=(14, 0.03), attack=0.02, decay=0.2),
        L("square", 550, 300, dur=0.4, vol=0.3, duty=0.3, lp=1800, decay=0.2)),
    "wingbeat": S(0.45,
        L("noise", dur=0.18, lp=900, hp=120, attack=0.03, decay=0.06, seed=43),
        L("noise", at=0.2, dur=0.18, lp=900, hp=120, attack=0.03, decay=0.06, vol=0.8, seed=44)),
    "mantle_wings": S(0.5,
        L("noise", dur=0.3, lp=700, hp=100, attack=0.05, decay=0.1, seed=45),
        L("noise", at=0.28, dur=0.3, lp=700, hp=100, attack=0.05, decay=0.1, seed=46),
        L("sine", 220, 330, dur=0.6, vol=0.15, attack=0.2, decay=0.2)),
    "scuttler_skitter": S(0.35,
        L("noise", dur=0.22, hp=2500, rate=6000, wobble=(40, 0.9), seed=47, release=0.04)),
    "scuttler_snap": S(0.5,
        L("square", 1500, 900, dur=0.05, duty=0.2, decay=0.015),
        L("square", 1700, 1000, at=0.06, dur=0.05, duty=0.2, decay=0.015)),
    "shell_clack": S(0.5,
        L("fm", 900, 700, dur=0.1, ratio=1.7, index=2.5, decay=0.03),
        L("noise", dur=0.04, hp=1500, vol=0.4, decay=0.01, seed=48)),
    "skipper_croak": S(0.5,
        L("square", 180, 140, dur=0.25, duty=0.35, lp=1200, wobble=(28, 0.7), decay=0.12)),
    "skipper_burrow": S(0.4,
        L("noise", dur=0.35, lp=(1500, 300), hp=80, decay=0.12, seed=49, rate=2500)),
    "moth_flutter": S(0.3,
        L("noise", dur=0.4, lp=1400, hp=300, wobble=(22, 0.9), attack=0.05, release=0.1, seed=50)),
    "moth_flare": S(0.45,
        L("sine", 600, 1500, dur=0.35, attack=0.25, release=0.05, vib=(12, 0.02)),
        L("noise", dur=0.35, hp=4000, vol=0.2, attack=0.25, release=0.05, seed=51)),
    "burr_roll": S(0.35,
        L("noise", dur=0.5, lp=1000, hp=150, rate=1800, wobble=(16, 0.8), attack=0.05, release=0.15, seed=52)),
    "spitter_gulp": S(0.45,
        L("sine", 200, 420, dur=0.3, attack=0.05, decay=0.15),
        L("noise", dur=0.25, lp=600, vol=0.3, attack=0.1, decay=0.1, seed=53)),
    "seal_bark": S(0.55,
        L("square", 360, 230, dur=0.2, duty=0.4, lp=1400, decay=0.08),
        L("square", 340, 210, at=0.24, dur=0.2, duty=0.4, lp=1400, decay=0.08)),
    "beetle_crack": S(0.55,
        L("noise", dur=0.06, hp=1200, decay=0.015, seed=54),
        L("square", 240, 110, at=0.03, dur=0.3, duty=0.3, lp=900, decay=0.1, vol=0.7),
        L("noise", at=0.05, dur=0.3, lp=1500, rate=1200, decay=0.1, vol=0.5, seed=55)),
    "spore_swell": S(0.4,
        L("tri", 260, 620, dur=0.55, attack=0.4, release=0.08, vib=(8, 0.02)),
        L("noise", dur=0.55, lp=(300, 1200), vol=0.3, attack=0.45, release=0.08, seed=56)),
    "spore_burst": S(0.55,
        L("noise", dur=0.45, lp=(3500, 600), hp=200, decay=0.12, seed=57),
        L("sine", 300, 120, dur=0.15, vol=0.4, decay=0.05)),
    # ---- Combat ----
    "hit_flesh": S(0.9,
        L("noise", dur=0.1, lp=(3000, 800), decay=0.03, seed=61),
        L("sine", 220, 90, dur=0.08, vol=0.6, decay=0.03)),
    "hit_shell": S(0.55,
        L("fm", 1600, 1200, dur=0.12, ratio=2.3, index=3.0, decay=0.03),
        L("noise", dur=0.03, hp=2500, vol=0.4, decay=0.01, seed=62)),
    "block": S(0.55,
        L("fm", 2200, 2000, dur=0.18, ratio=1.5, index=2.0, decay=0.05),
        L("square", 2200, dur=0.04, vol=0.3, decay=0.01)),
    "enemy_die": S(0.6,
        L("noise", dur=0.35, lp=(3000, 200), decay=0.1, seed=63),
        L("square", 600, 80, dur=0.3, duty=0.3, lp=2000, vol=0.4, decay=0.1)),
    "enemy_tell": S(0.45,
        L("square", 300, 620, dur=0.22, duty=0.3, lp=2500, decay=0.12),
        L("tri", 600, 1240, dur=0.22, vol=0.4, decay=0.1)),
    "enemy_shot": S(0.45,
        L("square", 800, 350, dur=0.12, duty=0.25, lp=3000, decay=0.05),
        L("noise", dur=0.06, hp=1500, vol=0.3, decay=0.02, seed=64)),
    # ---- Bosses ----
    "boss_roar": S(0.85,
        L("saw", 90, 60, dur=1.1, lp=(900, 300), attack=0.08, release=0.3, vib=(7, 0.04)),
        L("noise", dur=1.1, lp=(1500, 300), vol=0.6, attack=0.1, release=0.3, seed=71, wobble=(11, 0.4))),
    "matriarch_tell": S(0.6,
        L("noise", dur=0.5, hp=1800, rate=4000, wobble=(30, 0.9), attack=0.1, release=0.05, seed=72),
        L("fm", 300, 260, dur=0.5, ratio=1.3, index=3.0, vol=0.5, attack=0.1, release=0.05)),
    "wyrm_tell": S(0.65,
        L("noise", dur=0.7, lp=(200, 1800), attack=0.5, release=0.08, seed=73, rate=2000),
        L("sine", 55, 90, dur=0.7, vol=0.8, attack=0.5, release=0.08)),
    "congregation_tell": S(0.5,
        L("fm", 330, dur=0.7, ratio=1.01, index=1.0, attack=0.2, release=0.2, vib=(4, 0.02)),
        L("fm", 349, dur=0.7, ratio=1.01, index=1.0, attack=0.2, release=0.2, vib=(4.5, 0.02), vol=0.8)),
    "heron_tell": S(0.55,
        L("saw", 700, 1400, dur=0.4, lp=3000, attack=0.25, release=0.05, vib=(20, 0.03)),
        L("noise", dur=0.4, hp=3500, vol=0.25, attack=0.3, release=0.05, seed=74)),
    "boss_fall": S(0.85,
        L("saw", 200, 40, dur=1.8, lp=(1500, 200), release=0.4, vib=(6, 0.05)),
        L("noise", dur=1.8, lp=(2000, 150), vol=0.7, decay=0.6, seed=75),
        L("sine", 60, 30, at=0.6, dur=1.2, vol=0.6, decay=0.4)),
    # ---- World ----
    "chest_open": S(0.5,
        L("square", 220, 180, dur=0.15, duty=0.3, lp=1200, decay=0.05),
        L("tri", 523, at=0.12, dur=0.45, notes=[0, 4, 7, 12], decay=0.3)),
    "key_get": S(0.45,
        L("fm", 988, dur=0.3, notes=[0, 5], ratio=3.0, index=1.2, decay=0.12)),
    "pickup": S(0.35,
        L("square", 1320, 1760, dur=0.08, duty=0.25, decay=0.04),
        L("sine", 2640, dur=0.08, vol=0.3, decay=0.03)),
    "door_unlock": S(0.55,
        L("noise", dur=0.04, hp=2000, decay=0.01, seed=81),
        L("fm", 500, 300, at=0.03, dur=0.2, ratio=1.9, index=2.5, decay=0.06)),
    "door_locked": S(0.5,
        L("square", 170, 160, dur=0.14, duty=0.4, lp=900, decay=0.06),
        L("square", 160, 150, at=0.16, dur=0.12, duty=0.4, lp=900, decay=0.05)),
    "door_slide": S(0.55,
        L("noise", dur=0.6, lp=600, hp=60, rate=900, attack=0.05, release=0.15, seed=82),
        L("sine", 70, 60, dur=0.6, vol=0.6, attack=0.05, release=0.15)),
    "switch": S(0.45,
        L("square", 660, 440, dur=0.07, duty=0.25, decay=0.02),
        L("noise", dur=0.03, hp=3000, vol=0.4, decay=0.01, seed=83)),
    "pot_break": S(0.55,
        L("noise", dur=0.25, hp=1500, lp=7000, decay=0.06, seed=84),
        L("fm", 1200, 900, dur=0.12, ratio=2.7, index=3.0, vol=0.4, decay=0.03)),
    "grass_cut": S(0.4,
        L("noise", dur=0.14, hp=2500, lp=8000, decay=0.04, seed=86),
        L("noise", dur=0.08, at=0.05, hp=4000, vol=0.5, decay=0.03, seed=87)),
    "potion_drink": S(0.45,
        L("sine", 420, 300, dur=0.12, vol=0.7, notes=[0, 0, 0], decay=0.05, lp=1500),
        L("tri", 660, 990, at=0.4, dur=0.35, vol=0.5, decay=0.15)),
    "oil_pour": S(0.4,
        L("noise", dur=0.5, lp=900, hp=150, rate=600, attack=0.03, release=0.15, seed=88),
        L("noise", dur=0.4, at=0.35, lp=(1200, 4000), hp=400, vol=0.6, attack=0.05, decay=0.2, seed=89)),
    "block_push": S(0.45,
        L("noise", dur=0.45, lp=500, hp=60, rate=700, attack=0.05, release=0.1, seed=85)),
    "secret": S(0.45,
        L("tri", 523, dur=0.6, notes=[0, 6, 11, 16], decay=0.3),
        L("sine", 1046, dur=0.6, notes=[0, 6, 11, 16], vol=0.3, decay=0.3)),
    "tidestone_wake": S(0.6,
        L("fm", 196, dur=1.3, notes=[0, 7, 12, 19], ratio=2.0, index=1.0, decay=0.6),
        L("noise", dur=1.3, lp=(300, 900), hp=100, vol=0.3, attack=0.4, decay=0.6, seed=86)),
    "save": S(0.45,
        L("tri", 523, dur=0.5, notes=[0, 7, 12], decay=0.25),
        L("sine", 262, dur=0.5, vol=0.4, decay=0.3)),
    "bell_quiet": S(0.3,
        L("fm", 392, 390, dur=0.9, ratio=3.5, index=0.6, decay=0.3)),
    "bell_ring": S(0.7,
        L("fm", 392, dur=2.4, ratio=3.5, index=2.5, decay=0.9),
        L("fm", 784, dur=2.4, ratio=2.76, index=1.2, vol=0.4, decay=0.6),
        L("sine", 196, dur=2.4, vol=0.5, decay=1.1)),
    # ---- Interface ----
    "ui_move": S(0.25, L("square", 880, dur=0.035, duty=0.25, decay=0.012)),
    "ui_select": S(0.3, L("square", 660, 990, dur=0.09, duty=0.25, decay=0.04)),
    "ui_back": S(0.3, L("square", 660, 440, dur=0.09, duty=0.25, decay=0.04)),
    "ui_open": S(0.35,
        L("tri", 440, 660, dur=0.12, decay=0.05),
        L("noise", dur=0.08, lp=2000, hp=400, vol=0.2, decay=0.03, seed=91)),
    "text_blip": S(0.15, L("square", 1100, dur=0.022, duty=0.25, decay=0.008)),
    # ---- Jingles (placeholders until the real music) ----
    "jingle_item": S(0.5,
        L("square", 523, dur=0.9, notes=[0, 4, 7, 12], duty=0.25, lp=3000, decay=0.5),
        L("tri", 262, dur=0.9, notes=[0, 4, 7, 12], vol=0.5, decay=0.5)),
    "jingle_pearl": S(0.5,
        L("fm", 784, dur=1.2, notes=[0, 4, 7, 11, 12], ratio=2.0, index=1.0, decay=0.6),
        L("sine", 392, dur=1.2, vol=0.4, attack=0.1, decay=0.7)),
    "jingle_secret": S(0.45,
        L("tri", 440, dur=1.0, notes=[0, 6, 11, 16, 23], decay=0.5),
        L("sine", 880, dur=1.0, notes=[0, 6, 11, 16, 23], vol=0.3, decay=0.5)),
    "jingle_bell": S(0.6,
        L("fm", 392, dur=2.0, notes=[0, 2, 4, 7, 4], ratio=3.5, index=1.5, decay=1.0),
        L("sine", 196, dur=2.0, vol=0.5, attack=0.2, decay=1.2)),
    "jingle_puzzle": S(0.45,
        L("square", 659, dur=0.6, notes=[0, 4, 7], duty=0.25, lp=3000, decay=0.35),
        L("tri", 330, dur=0.6, notes=[0, 4, 7], vol=0.4, decay=0.35)),
    "jingle_game_over": S(0.5,
        L("tri", 392, 196, dur=1.8, notes=[0, -2, -4, -5], decay=1.0, vib=(5, 0.01)),
        L("sine", 196, 98, dur=1.8, vol=0.5, decay=1.0)),
    "jingle_clear": S(0.5,
        L("square", 523, dur=1.4, notes=[0, 4, 7, 12, 16, 19], duty=0.25, lp=3500, decay=0.8),
        L("tri", 262, dur=1.4, notes=[0, 4, 7, 12, 16, 19], vol=0.5, decay=0.8)),
}


# --------------------------------------------------------------------------
# Ambience: one quiet loop per region, plus a few shared ones.
# --------------------------------------------------------------------------
def _gulls(seed, count, dur):
    rng = random.Random(seed)
    return [L("saw", rng.uniform(1300, 1700), rng.uniform(900, 1100), at=rng.uniform(0.6, dur - 1.0),
              dur=0.35, lp=2500, vib=(12, 0.04), attack=0.03, decay=0.15, vol=0.12)
            for _ in range(count)]


def _drips(seed, count, dur, f=1800.0):
    rng = random.Random(seed)
    return [L("sine", f * rng.uniform(0.8, 1.3), f * 0.6, at=rng.uniform(0.6, dur - 0.8), dur=0.12,
              decay=0.04, vol=0.18) for _ in range(count)]


AMB_DUR = 8.5  # 8 s once the loop's half-second cross-fade is taken off
# Ambience sits under everything: every loop is levelled to about -26 LUFS
# (the music is -18), so the peaks below differ with how dense each bed is.

AMBIENCE = {
    "saltmarrow": S(0.208,
        L("noise", dur=AMB_DUR, lp=700, hp=80, wobble=(0.18, 0.7), seed=101),
        L("noise", dur=AMB_DUR, lp=2500, hp=900, wobble=(0.25, 0.85), vol=0.25, seed=102),
        *_gulls(103, 3, AMB_DUR)),
    "brinewood": S(0.226,
        L("noise", dur=AMB_DUR, lp=500, hp=60, wobble=(0.12, 0.5), seed=111),
        *_drips(112, 6, AMB_DUR),
        L("square", 2600, 2400, at=3.0, dur=0.6, duty=0.1, lp=4000, wobble=(30, 0.9), vol=0.05)),
    "cinderreach": S(0.194,
        L("noise", dur=AMB_DUR, lp=180, wobble=(0.3, 0.4), seed=121),
        L("sine", 45, dur=AMB_DUR, vol=0.6, wobble=(0.2, 0.5)),
        L("noise", dur=AMB_DUR, hp=3000, rate=400, vol=0.08, seed=122)),
    "gloamfen": S(0.266,
        L("noise", dur=AMB_DUR, lp=400, hp=60, wobble=(0.1, 0.4), seed=131),
        L("square", 230, 210, at=1.2, dur=0.35, duty=0.4, lp=800, wobble=(25, 0.8), vol=0.12),
        L("square", 250, 230, at=5.1, dur=0.3, duty=0.4, lp=800, wobble=(25, 0.8), vol=0.1),
        L("sine", 3200, at=2.5, dur=2.5, wobble=(9, 0.9), vol=0.03, attack=0.8, release=0.8)),
    "windmere": S(0.210,
        L("noise", dur=AMB_DUR, lp=(500, 1500), hp=150, wobble=(0.22, 0.8), seed=141),
        L("noise", dur=AMB_DUR, lp=3000, hp=1200, wobble=(0.4, 0.9), vol=0.2, seed=142),
        *_gulls(143, 2, AMB_DUR)),
    "frostspine": S(0.155,
        L("noise", dur=AMB_DUR, lp=(900, 2200), hp=400, wobble=(0.15, 0.85), seed=151),
        L("sine", 880, dur=AMB_DUR, vol=0.04, vib=(0.3, 0.02), wobble=(0.2, 0.9))),
    "sunken_verge": S(0.226,
        L("noise", dur=AMB_DUR, lp=600, hp=80, wobble=(0.1, 0.6), seed=161),
        L("fm", 330, at=2.0, dur=3.0, ratio=3.5, index=0.6, decay=1.2, vol=0.08),
        *_drips(162, 3, AMB_DUR, 1400.0)),
    "ossuary": S(0.188,
        L("noise", dur=AMB_DUR, lp=(800, 1400), hp=250, wobble=(0.17, 0.9), seed=171),
        L("noise", dur=AMB_DUR, hp=4000, rate=200, vol=0.05, seed=172)),
    "maw": S(0.196,
        L("sine", 40, dur=AMB_DUR, wobble=(0.35, 0.9)),
        L("noise", dur=AMB_DUR, lp=250, vol=0.5, wobble=(0.35, 0.8), seed=181)),
    "dungeon": S(0.203,
        L("noise", dur=AMB_DUR, lp=300, hp=40, seed=191),
        *_drips(192, 4, AMB_DUR, 1200.0)),
    "underwater": S(0.231,
        L("noise", dur=AMB_DUR, lp=350, wobble=(0.25, 0.5), seed=201),
        L("sine", 60, dur=AMB_DUR, vol=0.3, wobble=(0.12, 0.6))),
    "rain": S(0.081,
        L("noise", dur=AMB_DUR, hp=1200, lp=8000, seed=211),
        L("noise", dur=AMB_DUR, lp=400, vol=0.5, wobble=(0.2, 0.4), seed=212)),
    "wind": S(0.216,
        L("noise", dur=AMB_DUR, lp=(400, 1400), hp=120, wobble=(0.2, 0.85), seed=221)),
}


# --------------------------------------------------------------------------
# Writing and checking
# --------------------------------------------------------------------------
def build(name, spec, loop=False):
    peak, layers = spec
    return to_wav_bytes(render(layers, peak, loop))


def _write(path, frames):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)


def _same(path, frames):
    """Equal within two steps per sample (floating point can differ by a hair
    between machines)."""
    if not os.path.exists(path):
        return False
    with wave.open(path, "rb") as w:
        old = w.readframes(w.getnframes())
    if len(old) != len(frames):
        return False
    if old == frames:
        return True
    a = struct.unpack("<%dh" % (len(old) // 2), old)
    b = struct.unpack("<%dh" % (len(frames) // 2), frames)
    return all(abs(x - y) <= 2 for x, y in zip(a, b))


def main():
    check = "--check" in sys.argv
    only = None
    if "--only" in sys.argv:
        only = set(sys.argv[sys.argv.index("--only") + 1].split(","))
    jobs = [(os.path.join(SFX_DIR, n + ".wav"), n, s, False) for n, s in SOUNDS.items()]
    jobs += [(os.path.join(AMB_DIR, n + ".wav"), n, s, True) for n, s in AMBIENCE.items()]
    stale = []
    for path, name, spec, loop in jobs:
        if only and name not in only:
            continue
        frames = build(name, spec, loop)
        if check:
            if not _same(path, frames):
                stale.append(os.path.relpath(path, ROOT))
        else:
            _write(path, frames)
    if check:
        # Every sound needs an entry in Audio.SFX (its caption and fallback).
        import re
        with open(os.path.join(ROOT, "scripts", "autoload", "audio.gd"), encoding="utf-8") as f:
            known = set(re.findall(r'^\t"([a-z0-9_]+)": \{', f.read(), re.M))
        for name in SOUNDS:
            if name not in known:
                stale.append("%s has no entry in Audio.SFX (scripts/autoload/audio.gd)" % name)
        # And every sound the code plays by name needs an entry, or it's silent.
        import glob
        for path in sorted(glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True)):
            with open(path, encoding="utf-8") as f:
                # The id the call opens with, and the other side of an
                # `"a" if x else "b"` (not literals the condition compares).
                calls = re.findall(r'\bplay_(?:sfx|jingle)\(([^()]*)', f.read())
                names = []
                for args in calls:
                    names += re.findall(r'^\s*"([a-z0-9_]+)"', args)
                    names += re.findall(r'\belse\s+"([a-z0-9_]+)"', args)
                for name in names:
                    if name not in known:
                        stale.append("%s plays \"%s\", which isn't in Audio.SFX" % (os.path.relpath(path, ROOT), name))
        if stale:
            print("Sounds out of date (run python3 tools/sfx_gen.py):")
            for p in stale:
                print("  " + p)
            sys.exit(1)
        print("Sounds up to date (%d)." % len(jobs))
    else:
        print("Wrote %d sounds." % sum(1 for j in jobs if not only or j[1] in only))


if __name__ == "__main__":
    main()
