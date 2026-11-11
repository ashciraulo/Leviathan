"""Turns an FL master render into the game's OGG, with a seamless loop.

    python3 music/post/finalize.py <cue> <render.flac|wav> [--write]

The FL render covers the whole cue from bar 1 with the tail ON (the export
dialog's "Leave remainder"), so the reverb past the last bar is in the file.
For a looping cue this script:
  1. cuts [intro][body] at the cue's exact loop end (from music/midi/<cue>/cue.json),
  2. adds the tail past the loop end onto the body's start, so the reverb
     rings over the seam as it would in a real repeat,
  3. checks the seam (sample jump, level step) and the loudness target,
  4. with --write: encodes audio/music/<cue>.ogg and sets loop_offset=<intro
     seconds> in its .import file. The import keeps loop=false: the game turns
     looping on for its own copy (Audio._looping), and the shared track stays
     unlooped so one-shot uses of it still end.
One-shot cues (bells, lullaby, credits) keep their natural tail, with a
short fade over the last 50 ms so they never end on a cut.
Nothing here changes the music's level: loudness is set inside FL (Pro-L 2),
and this only measures it, so the .flp stays the single source.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys

import numpy as np
import pyloudnorm
import soundfile

MUSIC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(MUSIC)
sys.path.insert(0, MUSIC)
from track_sheet import CUES  # noqa: E402

TOLERANCE_LU = 1.0
TP_MAX = -1.0


def true_peak_db(x: np.ndarray, rate: int) -> float:
    up = np.fft.irfft(np.fft.rfft(x, axis=0), n=x.shape[0] * 4, axis=0) * 4  # 4x oversample
    return 20 * np.log10(max(1e-9, np.abs(up).max()))


def momentary(x: np.ndarray, rate: int, at: int) -> tuple[float, float]:
    """RMS dB of the 400 ms before and after sample `at`."""
    w = int(0.4 * rate)
    a, b = x[max(0, at - w): at], x[at: at + w]
    db = lambda s: 10 * np.log10(max(1e-12, float(np.mean(s ** 2))))
    return db(a), db(b)


def finalize(cue: str, render: str, write: bool = False) -> dict:
    spec = {c["id"]: c for c in CUES}[cue]
    meta = json.load(open(os.path.join(MUSIC, "midi", cue, "cue.json")))
    audio, rate = soundfile.read(render, always_2d=True)
    assert rate == 44100, f"render is {rate} Hz; FL should export 44.1 kHz"
    start = round(meta["intro_s"] * rate)
    end = round(meta["loop_end_s"] * rate)
    report = {"cue": cue, "render_s": round(audio.shape[0] / rate, 2), "loop": spec["loop"]}
    if audio.shape[0] < end:
        raise SystemExit(f"render is {audio.shape[0] / rate:.2f} s but the cue ends at {end / rate:.2f} s: FL cut it short")
    if spec["loop"]:
        tail = audio[end:]
        out = audio[:end].copy()
        n = min(tail.shape[0], end - start)
        out[start: start + n] += tail[:n]
        body = out[start:]
        # The seam: last samples of the body into the first of the body.
        jump = float(np.abs(body[0] - body[-1]).max())
        before, after = momentary(np.concatenate([body, body]).mean(axis=1), rate, body.shape[0])
        # A loop restart is a downbeat after a phrase's release, so compare the
        # seam with the cue's own downbeats rather than with a flat number.
        mono = body.mean(axis=1)
        bar = round(meta["bar_q"] * 60 / meta["qbpm"] * rate)
        steps = [a - b for b, a in (momentary(mono, rate, k) for k in range(bar, mono.shape[0] - bar, bar))]
        report.update(seam_jump=round(jump, 4), seam_step_db=round(after - before, 2),
                      bar_step_p90_db=round(float(np.percentile(steps, 90)), 2) if steps else 0.0,
                      tail_folded_s=round(n / rate, 2))
        measured = body
    else:
        out = audio
        fade = int(0.05 * rate)
        out[-fade:] *= np.linspace(1, 0, fade)[:, None]
        measured = out
    meter = pyloudnorm.Meter(rate)
    lufs = meter.integrated_loudness(measured) if measured.shape[0] > rate * 0.5 else float("nan")
    tp = true_peak_db(out, rate)
    report.update(lufs=round(lufs, 2), target=spec["lufs"], true_peak=round(tp, 2))
    problems = []
    if abs(lufs - spec["lufs"]) > TOLERANCE_LU:
        problems.append(f"loudness {lufs:.1f} LUFS, target {spec['lufs']:.0f} (fix the Pro-L 2 gain in FL)")
    if tp > TP_MAX:
        problems.append(f"true peak {tp:.2f} dBTP is over {TP_MAX}")
    if spec["loop"] and report["seam_jump"] > 0.05:
        problems.append(f"seam jump {report['seam_jump']} would click")
    # The handoff's slam limit is +6 dB; a seam no bigger than the cue's usual downbeat step is a downbeat,
    # but never more than +8 dB (review of v8: a busy cue's downbeats would otherwise excuse a slam).
    if spec["loop"] and abs(report["seam_step_db"]) > min(8.0, max(6.0, report["bar_step_p90_db"] + 1.0)):
        problems.append(f"level steps {report['seam_step_db']} dB across the seam "
                        f"(the cue's downbeats step up to {report['bar_step_p90_db']} dB)")
    report["problems"] = problems
    if write and not problems:
        path = os.path.join(ROOT, "audio", "music", f"{cue}.ogg")
        pcm = np.clip(out, -1, 1).astype("<f4").tobytes()
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "f32le", "-ar", str(rate), "-ac", "2", "-i", "-",
                        "-c:a", "libvorbis", "-q:a", "5", path], input=pcm, check=True)
        set_import(path, meta["intro_s"] if spec["loop"] else 0.0)
        report["wrote"] = os.path.relpath(path, ROOT)
    return report


def set_import(ogg: str, offset: float) -> None:
    imp = ogg + ".import"
    if not os.path.exists(imp):
        return  # Godot writes it on first import; run again after that.
    text = open(imp).read()
    text = re.sub(r"(?m)^loop=.*$", "loop=false", text)
    text = re.sub(r"(?m)^loop_offset=.*$", f"loop_offset={offset:.6f}", text)
    open(imp, "w").write(text)


if __name__ == "__main__":
    r = finalize(sys.argv[1], sys.argv[2], "--write" in sys.argv)
    print(json.dumps(r, indent=1))
    sys.exit(1 if r["problems"] else 0)
