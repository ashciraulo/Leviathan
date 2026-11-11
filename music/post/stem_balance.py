"""Gated short-term loudness per stem after an EQ chain, and the master the mix would make.

    python3 music/post/stem_balance.py <mix json> <stem dir> [--prefix sm_v3_]

The mix json (music/flp/mixes/<cue>.json) lists per part: eq (Pro-Q bands as in flp_mix.py) and target
(short-term LUFS while the part plays). Prints each part's level before the gain, the gain that reaches the
target, and the summed mix's integrated loudness and 2-6 kHz share. The ffmpeg filters stand in for Pro-Q
(2-pole Butterworth per 12 dB/oct), close enough to set levels; the FL render is measured again after.
"""
from __future__ import annotations

import json
import subprocess
import sys

import numpy as np

SR = 44100


def ffchain(bands: list[dict]) -> str:
    out = []
    for b in bands:
        poles = max(1, int(b.get("db_oct", 12)) // 12)
        if b["shape"] == "lowcut":
            out += [f"highpass=f={b['freq']}:p=2"] * poles
        elif b["shape"] == "highcut":
            out += [f"lowpass=f={b['freq']}:p=2"] * poles
        elif b["shape"] == "bell":
            out.append(f"equalizer=f={b['freq']}:t=q:w={b.get('q', 1)}:g={b['gain']}")
        elif b["shape"] in ("lowshelf", "highshelf"):
            out.append(f"{b['shape']}=f={b['freq']}:g={b['gain']}")
    return ",".join(out) or "anull"


def load(path: str, chain: str) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-af", chain, "-ar", str(SR), "-ac", "2", "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2)


def ebur(x: np.ndarray) -> tuple[float, np.ndarray]:
    """(integrated LUFS, short-term LUFS every 0.1 s)"""
    p = subprocess.run(["ffmpeg", "-nostats", "-v", "verbose", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-",
                        "-af", "ebur128=framelog=verbose", "-f", "null", "-"], input=x.astype(np.float32).tobytes(),
                       capture_output=True)
    err = p.stderr.decode()
    st = [float(l.split(" S:")[1].split()[0]) for l in err.splitlines() if " S:" in l and "TARGET" in l]
    integ = float(err.split("Integrated loudness:")[1].split("I:")[1].split("LUFS")[0])
    return integ, np.array(st)


def share_2_6k(x: np.ndarray) -> float:
    m = x.mean(1).astype(np.float64)
    spec = np.abs(np.fft.rfft(m)) ** 2
    f = np.fft.rfftfreq(len(m), 1 / SR)
    return float(10 * np.log10(spec[(f >= 2000) & (f < 6000)].sum() / spec[f >= 20].sum()))


def main() -> None:
    mix = json.load(open(sys.argv[1]))
    stem_dir = sys.argv[2]
    prefix = sys.argv[sys.argv.index("--prefix") + 1] if "--prefix" in sys.argv else ""
    total, gains = None, {}
    for part, cfg in mix["parts"].items():
        x = load(f"{stem_dir}/{prefix}{part}.flac", ffchain(cfg.get("eq", [])))
        _, st = ebur(x)
        act = st[st > -60]
        level = float(np.median(act)) if len(act) else -99.0
        gains[part] = round(cfg["target"] - level, 2)
        y = x * 10 ** (gains[part] / 20)
        total = y if total is None else total[: len(y)] + y[: len(total)]
        print(f"{part:16s} active {100 * len(act) / max(1, len(st)):3.0f}%  level {level:6.1f}  target {cfg['target']:6.1f}"
              f"  gain {gains[part]:+6.2f}  2-6k {share_2_6k(x):6.1f}")
    integ, _ = ebur(total)
    print(f"mix: {integ:.2f} LUFS integrated, peak {20 * np.log10(np.abs(total).max()):.1f} dBFS, 2-6k share {share_2_6k(total):.1f} dB")
    print(json.dumps({"gains": gains, "pre_lufs": integ}))


if __name__ == "__main__":
    main()
