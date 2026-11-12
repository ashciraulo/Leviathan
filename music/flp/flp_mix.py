"""Writes a cue's mix into its FL project, so the FL render is the master and the .flp stays editable.

    python3 music/flp/flp_mix.py <in.flp> <mix json> <gains json> <out.flp> [--lufs-trim dB]

The template must already hold Pro-Q 4 in slot 1 of each part's insert, and Pro-C 2, Pro-Q 4, Pro-L 2 on the master
(added once in FL; scripts can't add plugins). gains json is stem_balance.py's last line: each part's gain and the
summed mix's loudness. Writes:
  - each insert's Pro-Q bands from the mix json, and its static gain on the Pro-Q output (+-36 dB);
  - the master Pro-Q (master_eq, e.g. a 32 Hz low cut);
  - Pro-C 2: Bus style, 2:1, threshold comp_over_lufs (default 12) dB over the mix loudness, auto gain off. At 6 dB
    over (Out There FM's setting for -14 LUFS songs) it took ~4 dB off Saltmarrow, too much for a folk cue;
  - Pro-L 2: gain to reach the cue's LUFS target, output -1.5 dBTP. --lufs-trim corrects after a measured render.
State layouts (Pro-Q FFBS band floats, FabFilter parameter order) come from Out There FM's proq.py and fabstate.py,
checked on screen there; this file only reads and writes the events.
"""
from __future__ import annotations

import json
import math
import struct
import sys

PLUGIN_STATE = 213
INSERT_START = 236
LIMIT_LOSS = 1.0  # dB the master chain takes off at game levels; trim after the render with --lufs-trim

SHAPE = {"bell": 0, "lowshelf": 1, "lowcut": 2, "highshelf": 3, "highcut": 4, "notch": 5, "bandpass": 6, "tilt": 7}
PROQ_OUT = 556  # global output gain float index, stored as dB / 36


def read(path: str) -> tuple[bytes, list[list]]:
    b = open(path, "rb").read()
    i0 = b.find(b"FLdt")
    i, ev = i0 + 8, []
    while i < len(b):
        eid = b[i]
        i += 1
        if eid < 64:
            n = 1
        elif eid < 128:
            n = 2
        elif eid < 192:
            n = 4
        else:
            n, sh = 0, 0
            while True:
                c = b[i]
                i += 1
                n |= (c & 0x7F) << sh
                sh += 7
                if c < 0x80:
                    break
        ev.append([eid, bytearray(b[i:i + n])])
        i += n
    return b[:i0], ev


def write(path: str, head: bytes, ev: list[list]) -> None:
    out = bytearray()
    for eid, d in ev:
        out.append(eid)
        if eid >= 192:
            n = len(d)
            while True:
                c = n & 0x7F
                n >>= 7
                out.append(c | (0x80 if n else 0))
                if not n:
                    break
        out += d
    open(path, "wb").write(bytes(head) + b"FLdt" + struct.pack("<I", len(out)) + bytes(out))


def proq_set(data: bytes, bands: list[dict], out_db: float) -> bytearray:
    b = bytearray(data)
    k = b.find(b"FFBS")
    o, n = k + 12, struct.unpack_from("<I", b, k + 8)[0]
    if n < PROQ_OUT + 1:
        raise SystemExit(f"Pro-Q state has {n} floats, expected Pro-Q 4 (600)")
    for i in range(24):
        base = o + 4 * 23 * i
        if i < len(bands):
            bd = bands[i]
            q = bd.get("q", 0.71 if bd["shape"] in ("lowcut", "highcut", "lowshelf", "highshelf") else 1.0)
            vals = (1.0, 1.0, math.log2(bd["freq"]), bd.get("gain", 0.0), math.log(q / 0.025) / math.log(1600),
                    SHAPE[bd["shape"]], bd.get("db_oct", 12) / 6)
            for idx, val in enumerate(vals):
                struct.pack_into("<f", b, base + 4 * idx, float(val))
        else:
            struct.pack_into("<f", b, base, 0.0)
    struct.pack_into("<f", b, o + 4 * PROQ_OUT, float(out_db) / 36.0)
    return b


def fab_set(d: bytearray, idx: int, val: float) -> None:
    k = d.find(b"FabF\x02")
    i = k + 12 + struct.unpack_from("<I", d, k + 8)[0]
    struct.pack_into("<f", d, i + 8 + 4 * idx, float(val))


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src, mix_path, gains_path, dst = args[:4]
    trim = float(sys.argv[sys.argv.index("--lufs-trim") + 1]) if "--lufs-trim" in sys.argv else 0.0
    mix = json.load(open(mix_path))
    g = json.loads(open(gains_path).read().strip().splitlines()[-1])
    head, ev = read(src)
    # Mixer tracks are saved in order (master first), each opened by event 236; slot plugins follow.
    track, proq, comp, lim = -1, {}, None, None
    for j, (eid, d) in enumerate(ev):
        if eid == INSERT_START:
            track += 1
        elif eid == PLUGIN_STATE:
            if b"FFBS" in d:
                proq.setdefault(track, j)
            elif b"Pro-C 2" in bytes(d[:600]):
                comp = j
            elif b"Pro-L 2" in bytes(d[:600]):
                lim = j
    if 0 not in proq or comp is None or lim is None:
        raise SystemExit("template needs Pro-C 2, Pro-Q 4 and Pro-L 2 on the master")
    pre = g["pre_lufs"]
    gain = round(mix["lufs"] - pre + LIMIT_LOSS + trim, 2)
    # Pro-L 2's gain only goes from 0 to +30 dB, so a negative make-up gain would be clamped to 0 and the
    # cue would come out too loud (bell_3 v2/v3). Take the excess off every part instead.
    shift = min(0.0, gain - 0.5)
    if shift:
        g["gains"] = {k: round(v + shift, 2) for k, v in g["gains"].items()}
        pre, gain = pre + shift, round(gain - shift, 2)
        print(f"Pro-L gain would be negative: parts {shift:+.2f} dB")
    for part, cfg in mix["parts"].items():
        j = proq.get(cfg["insert"])
        if j is None:
            raise SystemExit(f"insert {cfg['insert']} ({part}) has no Pro-Q 4")
        ev[j][1] = proq_set(bytes(ev[j][1]), cfg["eq"], g["gains"][part])
        print(f"insert {cfg['insert']} {part:16s} out {g['gains'][part]:+6.2f} dB  " +
              ", ".join(f"{b['shape']} {b['freq']:g}" for b in cfg["eq"]))
    ev[proq[0]][1] = proq_set(bytes(ev[proq[0]][1]), mix.get("master_eq", []), 0.0)
    fab_set(ev[comp][1], 0, 5)                       # style Bus
    over = mix.get("comp_over_lufs", 12.0)
    fab_set(ev[comp][1], 1, round(pre + over, 1))    # threshold
    fab_set(ev[comp][1], 2, 0.6)                     # ratio 2:1
    fab_set(ev[comp][1], 14, 0)                      # auto gain off
    fab_set(ev[lim][1], 0, gain)
    fab_set(ev[lim][1], 18, -1.5)  # -1.5, not -1.1: the OGG encode overshoots by up to 0.3 dB (review of the bells v1)
    print(f"mix {pre:.2f} LUFS -> Pro-C threshold {pre + over:.1f}, Pro-L gain {gain:+.2f} dB, ceiling -1.5 dBTP")
    write(dst, head, ev)


if __name__ == "__main__":
    main()
