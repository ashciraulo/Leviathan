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
One-shot cues (bells, lullaby, credits) keep their natural tail: the .flp
leaves two bars of room after the last note, the silence after the tail is
trimmed, and the last 50 ms fade so they never end on a cut.
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
        # The seam: on a repeat the body's first sample is its own start plus the folded ring past the loop end,
        # which continues the body's end; what led into the start on the first pass was the intro's last ms.
        # Fade those last 10 ms of lead-in onto the body's end, so both waveforms run on across the loop point
        # (title v6: two low notes at different phases jumped 0.052 there).
        xf = min(int(0.01 * rate), start, end - start)
        if xf:
            out[end - xf: end] += audio[start - xf: start] * np.linspace(0, 1, xf)[:, None]
        body = out[start:]
        # The seam: last samples of the body into the first of the body.
        jump = float(np.abs(body[0] - body[-1]).max())
        before, after = momentary(np.concatenate([body, body]).mean(axis=1), rate, body.shape[0])
        # A loop restart is a downbeat after a phrase's release, so compare the
        # seam with the cue's own downbeats rather than with a flat number.
        mono = body.mean(axis=1)
        bar = round(meta["bar_q"] * 60 / meta["qbpm"] * rate)
        steps = [a - b for b, a in (momentary(mono, rate, k) for k in range(bar, mono.shape[0] - bar, bar))]
        # The tail folded onto the start must hold the ring: a render cut at the loop end folds silence, and the
        # crossfaded seam would hide the cut (review of the title v1, MAJOR 1).
        room = (audio.shape[0] - end) / rate
        mono_all = audio.mean(axis=1)
        drop = momentary(mono_all, rate, end)
        report.update(tail_room_s=round(room, 2), loop_end_drop_db=round(drop[0] - drop[1], 1))
        report.update(seam_jump=round(jump, 4), seam_step_db=round(after - before, 2),
                      bar_step_p90_db=round(float(np.percentile(steps, 90)), 2) if steps else 0.0,
                      tail_folded_s=round(n / rate, 2))
        measured = body
    else:
        # One-shots render with two bars of room after the last note (flp_build), so the tail
        # rings out; trim the silence after it, keeping 0.1 s, then fade the last 50 ms.
        level = np.abs(audio).max(axis=1)
        # A preset with a constant noise floor (review of the bells v2, BLOCKER: a DX7 bell hummed at -73 dBFS)
        # never falls below a fixed threshold, so the tail is cut where it reaches 10 dB above the floor.
        hop = int(0.05 * rate)
        env = np.array([level[k:k + hop].max() for k in range(0, level.size - hop, hop)])
        # The floor is read from the render's last 2 s, which the .flp's two bars of room leave past the ring:
        # a percentile over the whole render reads the music itself when a cue is rarely quiet (review of the
        # bells v3, MAJOR 1: the lullaby's 'floor' came out at -59 dBFS and its ring would have been cut).
        floor = float(np.percentile(env[-int(2 / 0.05):], 5))
        report["floor_db"] = round(20 * np.log10(floor + 1e-12), 1)
        loud = np.nonzero(level > max(10 ** (-70 / 20), floor * 10 ** (10 / 20)))[0]
        stop = min(audio.shape[0], (loud[-1] if loud.size else end) + int(0.1 * rate))
        report["cut_db"] = round(20 * np.log10(level[max(0, stop - int(0.15 * rate)):stop].max() + 1e-12), 1)
        # The game dips the music for the whole OGG, so it ends when the sound does, even before the
        # cue's written end (review v2, MAJOR 2: bell_5 kept 2.4 s of silence).
        out = audio[:stop].copy()
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
    if not spec["loop"] and report["floor_db"] > -70:  # an audible hum; DX7 V idles near -80 (inaudible)
        problems.append(f"the render has a noise floor at {report['floor_db']} dBFS peak (a preset hums or hisses): "
                        "find it and render again")
    if not spec["loop"] and report["cut_db"] > -50:
        problems.append(f"the tail is cut at {report['cut_db']} dBFS: give the render more room after the last note")
    if spec["loop"] and report["tail_room_s"] < 2.0:
        problems.append(f"the render ends {report['tail_room_s']} s past the loop end: render with two bars of room "
                        "(flp_build adds them) so the tail rings over the seam")
    if spec["loop"] and report["loop_end_drop_db"] > 12:
        problems.append(f"the render falls {report['loop_end_drop_db']} dB right after the loop end: FL cut the tail")
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
        # Vorbis can overshoot the master's peak (review of the bells v1: bell_7's OGG reached -0.80 dBTP
        # from a -1.12 master), so measure what ships.
        dec = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-f", "f32le", "-ac", "2", "-"],
                             capture_output=True, check=True).stdout
        ogg_tp = true_peak_db(np.frombuffer(dec, "<f4").reshape(-1, 2), rate)
        report["ogg_true_peak"] = round(float(ogg_tp), 2)
        if ogg_tp > TP_MAX:
            problems.append(f"the OGG's true peak is {ogg_tp:.2f} dBTP (the encode overshoots): lower the Pro-L ceiling")
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
