"""Rough cloud render of a cue's MIDI: a numpy sketch, NOT the FL sound.

It exists to hear notes, form and the loop seam before FL is involved, and to
gate the writing (ranges, clashes) early. Voices are chosen by the part's
name prefix (guitar_, flute_, bass_ ...). Writes <cue>_sketch.mp3 with the
loop played twice, so the seam can be heard in the middle.
"""
from __future__ import annotations

import os
import subprocess

import numpy as np

RATE = 44100


def hz(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12)


def _env(n: int, a: float, d: float, s: float, r: float, held: int) -> np.ndarray:
    t = np.arange(n) / RATE
    e = np.minimum(1.0, t / max(a, 1e-4))
    held_t = held / RATE
    decay = s + (1 - s) * np.exp(-np.maximum(0, t - a) / max(d, 1e-4))
    e = e * decay
    rel = np.where(t > held_t, np.exp(-(t - held_t) / max(r, 1e-4)), 1.0)
    return e * rel


def _pluck(f: float, n: int, bright: float = 0.5) -> np.ndarray:
    period = max(2, int(RATE / f))
    buf = np.random.default_rng(int(f * 10)).uniform(-1, 1, period)
    out = np.empty(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = (buf[i % period] + buf[(i + 1) % period]) * 0.5 * (0.994 + 0.005 * bright)
    return out


def voice(kind: str, pitch: int, dur_s: float, vel: int) -> np.ndarray:
    f = hz(pitch)
    tail = {"pad": 1.2, "bell": 2.5, "guitar": 0.6, "harp": 1.2, "bass": 0.25}.get(kind, 0.3)
    n = int((dur_s + tail) * RATE)
    held = int(dur_s * RATE)
    t = np.arange(n) / RATE
    v = (vel / 127.0) ** 1.6
    if kind in ("guitar", "harp"):
        sig = _pluck(f, n, 0.3 if kind == "guitar" else 0.8) * _env(n, 0.002, 1.5, 0.0, 0.15, held)
    elif kind == "bass":
        sig = (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * _env(n, 0.01, 0.9, 0.35, 0.08, held)
    elif kind == "flute":
        vib = 1 + 0.003 * np.sin(2 * np.pi * 5.0 * t) * np.minimum(1, t / 0.4)
        ph = 2 * np.pi * f * np.cumsum(vib) / RATE
        noise = np.random.default_rng(pitch).normal(0, 0.04, n)
        sig = (np.sin(ph) + 0.18 * np.sin(2 * ph) + noise) * _env(n, 0.06, 0.5, 0.85, 0.12, held)
    elif kind == "reed":
        ph = 2 * np.pi * f * t
        sig = sum(np.sin(k * ph) / k ** 1.3 for k in (1, 2, 3, 4, 5, 6)) * _env(n, 0.04, 0.4, 0.8, 0.1, held) * 0.6
    elif kind == "pad":
        sig = sum(np.sin(2 * np.pi * f * d * t) for d in (0.997, 1.0, 1.003)) / 3 * _env(n, 0.5, 1.0, 0.9, 1.0, held)
    elif kind == "bell":
        sig = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * dcy) for r, a, dcy in
                  ((1, 1, 1.2), (2.0, 0.5, 2), (2.76, 0.35, 3), (5.4, 0.2, 5)))
    elif kind == "drum":  # frame drum: pitch-dropping low thump
        fr = 70 + 60 * np.exp(-t * 30)
        sig = np.sin(2 * np.pi * np.cumsum(fr) / RATE) * np.exp(-t * 9)
    elif kind == "shaker":
        sig = np.random.default_rng(int(t.size)).normal(0, 1, n) * np.exp(-t * 60)
        sig = np.diff(sig, prepend=0)  # crude high-pass
    else:
        sig = np.sin(2 * np.pi * f * t) * _env(n, 0.01, 0.5, 0.6, 0.1, held)
    return sig * v


PAN = {"guitar": -0.3, "flute": 0.15, "reed": 0.3, "bass": 0.0, "pad": 0.0, "drum": -0.1, "shaker": 0.35,
       "harp": -0.25, "bell": 0.2}
GAIN = {"guitar": 0.55, "flute": 0.45, "reed": 0.32, "bass": 0.7, "pad": 0.12, "drum": 0.8, "shaker": 0.08,
        "harp": 0.5, "bell": 0.3}


def _reverb(x: np.ndarray, seconds: float = 1.6, wet: float = 0.18) -> np.ndarray:
    n = int(seconds * RATE)
    rng = np.random.default_rng(7)
    ir = rng.normal(0, 1, (n, 2)) * np.exp(-np.arange(n) / RATE * 4.0)[:, None]
    ir[:, :] *= 0.02
    out = np.empty((x.shape[0] + n - 1, 2))
    for c in range(2):
        out[:, c] = np.fft.irfft(np.fft.rfft(x[:, c], out.shape[0]) * np.fft.rfft(ir[:, c], out.shape[0]), out.shape[0])
    dry = np.zeros_like(out)
    dry[: x.shape[0]] = x
    return dry + wet * out


def render(song, out_dir: str, raw_path: str | None = None) -> str:
    end_s = song.seconds(song.end_q)
    total = np.zeros((int((end_s + 4) * RATE), 2))
    for p in song.parts:
        kind = p.name.split("_")[0]
        g, pan = GAIN.get(kind, 0.4), PAN.get(kind, 0.0)
        for start, dur, pitch, vel in p.trimmed():
            s = voice(kind, pitch, song.seconds(dur), vel) * g
            i = int(song.seconds(start) * RATE)
            j = min(total.shape[0], i + s.size)
            total[i:j, 0] += s[: j - i] * (1 - pan) / 1.4
            total[i:j, 1] += s[: j - i] * (1 + pan) / 1.4
    total = _reverb(total)
    if raw_path:  # what an FL render with the tail on looks like, for testing finalize.py
        import soundfile
        soundfile.write(raw_path, total / max(1e-6, np.abs(total).max()) * 0.3, RATE)
    loop_start, loop_end = int(song.seconds(song.intro_q) * RATE), int(end_s * RATE)
    if song.spec["loop"]:
        # Fold the tail past the loop end back onto the loop start, then play
        # intro + body + body so the seam sits in the middle of the sketch.
        tail = total[loop_end:]
        body = total[loop_start:loop_end].copy()
        body[: min(tail.shape[0], body.shape[0])] += tail[: body.shape[0]]
        mix = np.concatenate([total[:loop_start], body, body])
    else:
        mix = total[: loop_end + int(2.5 * RATE)]
    mix /= max(1e-6, np.abs(mix).max()) / 0.7
    path = os.path.join(out_dir, f"{song.id}_sketch.mp3")
    pcm = (np.clip(mix, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(RATE), "-ac", "2", "-i", "-",
                    "-af", "loudnorm=I=-18:TP=-1.5", "-ar", str(RATE), "-b:a", "160k", path], input=pcm, check=True)
    return path
