"""Mantle, the giant sky-ray who answers the Wayshell, and the flight
backdrop (sky, clouds, the coast far below).

Mantle is drawn from above, facing right, as a material silhouette that
build_art.lit() shades: a broad violet ray with bioglow spots along the
back and Wren riding just behind the head. Four wing-beat frames.
Imported by build_art.py, which calls build(build_art).
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


CLEAR = (0, 0, 0, 0)
W, H = 96, 80

RAMPS = {
    # Mantle's skin: Gloamfen violets, lighter on the leading edges.
    "V": ["#B8A8E0", "#8E7EC4", "#5E519A", "#3B3170", "#1B1630"],
    # Pale underside showing at the wing tips on the upbeat.
    "U": ["#F7F1E3", "#D8E4F0", "#A8C4DC", "#6E86A8", "#2E3A58"],
}
FLAT = {"N": "#6EF0E0"}  # bioglow spots


def frame(flap):
    """One wing-beat frame, seen from above, facing right. flap (0..1)
    scales the wing span: 1.0 is wings level, lower is wings raised or
    lowered and so foreshortened."""
    rows = [["."] * W for _ in range(H)]
    cy = H // 2
    span = 37.0 * flap
    # Wings: leading edge swept back from the head, trailing edge short.
    for y in range(H):
        s = abs(y - cy + 0.5) - 0.5
        if s > span:
            continue
        u = s / span if span else 1.0
        # Convex leading edge, concave trailing edge: the tips point
        # out and back like a manta's.
        lead = 40.0 + 40.0 * (1.0 - u * u)
        trail = 30.0 + 8.0 * u + 10.0 * math.sin(math.pi * u)
        for x in range(int(trail), int(lead) + 1):
            rows[y][x] = "V"
    # Body: a lens from the base of the tail to the head.
    for x in range(24, 85):
        t = (x - 24) / 60.0
        half = 2.0 + 6.0 * math.sin(math.pi * min(t * 1.1, 1.0))
        for y in range(H):
            if abs(y - cy + 0.5) <= half:
                rows[y][x] = "V"
    # Cephalic fins: two short horns either side of the mouth.
    for dy in (-5, -4, 3, 4):
        for x in range(83, 88):
            rows[cy + dy][x] = "V"
    for y in range(cy - 3, cy + 3):
        rows[y][84] = rows[y][85] = rows[y][86] = rows[y][87] = "."
    # Tail: a thin whip trailing to the left.
    for x in range(3, 26):
        rows[cy][x] = "V"
        if x > 14:
            rows[cy - 1][x] = "V"
    # Pale underside at the tips when the wings are raised.
    if flap < 0.8:
        for y in range(H):
            if abs(y - cy) > span * 0.75:
                for x in range(W):
                    if rows[y][x] == "V":
                        rows[y][x] = "U"
    # Bioglow spots along the back and across the wings.
    spots = [(34, 0), (42, -3), (42, 2), (50, 0), (58, -3), (58, 2)]
    for k in (0.35, 0.6):
        dy = int(span * k)
        x = int(56 - 18 * k)
        spots += [(x, -dy - 1), (x, dy)]
    for x, dy in spots:
        if 0 <= cy + dy < H and rows[cy + dy][x] in "VU":
            rows[cy + dy][x] = "N"
    # Wren riding just behind the head: navy cap, face, red scarf
    # streaming back, striped jumper.
    wren = [
        "..rCC.",
        "rrCCww",
        "..DDw.",
        "..DD..",
    ]
    for j, line in enumerate(wren):
        for i, m in enumerate(line):
            if m != ".":
                rows[cy - 2 + j][66 + i] = m
    return ["".join(r) for r in rows]


def frames():
    return [frame(f) for f in (1.0, 0.8, 0.55, 0.8)]


def flight_sky():
    """384x216 daytime sky over the sea, horizon low; drawn behind the
    scrolling cloud and sea layers."""
    w, h = 384, 216
    rnd = random.Random(77)
    top, mid, low = hex_color("#41577A"), hex_color("#7FB7D9"), hex_color("#F7E6C8")
    px = []
    for y in range(h):
        t = y / (h - 1.0)
        if t < 0.6:
            k = t / 0.6
            c = tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3))
        else:
            k = (t - 0.6) / 0.4
            c = tuple(int(mid[i] + (low[i] - mid[i]) * k) for i in range(3))
        # Ordered dither between bands keeps it 16-bit looking.
        row = []
        for x in range(w):
            j = ((x + y * 2) % 4) - 1.5
            row.append((max(0, min(255, c[0] + int(j))), max(0, min(255, c[1] + int(j))),
                        max(0, min(255, c[2] + int(j))), 255))
        px.append(row)
    # A pale sun low on the right.
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - 300, y - 120)
            if d < 14:
                px[y][x] = hex_color("#FFF4D6")
            elif d < 18 and (x + y) % 2 == 0:
                px[y][x] = hex_color("#FFE8B0")
    return px


def cloud_layer():
    """384x216 tileable clouds (transparent around them)."""
    w, h = 384, 216
    px = [[CLEAR] * w for _ in range(h)]
    rnd = random.Random(12)
    light, mid, shade = hex_color("#FFFFFF"), hex_color("#F7F1E3"), hex_color("#C8D8E8")
    for _ in range(9):
        cx, cy = rnd.randrange(w), rnd.randrange(20, 170)
        puffs = [(rnd.randrange(-30, 30), rnd.randrange(-6, 6), rnd.randrange(8, 16)) for _ in range(6)]
        for dx, dy, r in puffs:
            for y in range(cy + dy - r, cy + dy + r):
                for x in range(cx + dx - r - 4, cx + dx + r + 4):
                    ex = (x - cx - dx) / (r + 4.0)
                    ey = (y - cy - dy) / float(r)
                    if ex * ex + ey * ey <= 1.0 and 0 <= y < h:
                        c = mid
                        if ey < -0.3:
                            c = light
                        elif ey > 0.45:
                            c = shade
                        px[y][x % w] = c
    return px


def sea_layer():
    """384x64 tileable sea seen from high up, with the coast's islands."""
    w, h = 384, 64
    rnd = random.Random(5)
    deep, glass, foam = hex_color("#236A80"), hex_color("#2E7F8C"), hex_color("#A8E6CF")
    sand, green = hex_color("#E8C88A"), hex_color("#6F9A4E")
    px = [[glass if (y // 3 + x // 16) % 5 else deep for x in range(w)] for y in range(h)]
    for _ in range(70):
        x, y = rnd.randrange(w), rnd.randrange(h)
        for dx in range(rnd.randrange(2, 5)):
            px[y][(x + dx) % w] = foam
    for _ in range(4):
        cx, cy, r = rnd.randrange(w), rnd.randrange(12, 52), rnd.randrange(5, 10)
        for y in range(cy - r - 1, cy + r + 2):
            for x in range(cx - 2 * r - 2, cx + 2 * r + 3):
                d = math.hypot((x - cx) / 2.0, y - cy)
                if 0 <= y < h:
                    if d <= r - 2:
                        px[y][x % w] = green
                    elif d <= r:
                        px[y][x % w] = sand
                    elif d <= r + 1:
                        px[y][x % w] = foam
    return px


def build(ba):
    import os
    ba.RAMPS.update(RAMPS)
    ba.FLAT.update(FLAT)
    sprite = ba.sheet([[ba.lit(f, 60 + i) for i, f in enumerate(frames())]], W, H)
    ba.write_png(os.path.join(ba.OUT, "sprites", "mantle.png"), sprite)
    ba.write_png(os.path.join(ba.OUT, "ui", "flight_sky.png"), flight_sky())
    ba.write_png(os.path.join(ba.OUT, "ui", "flight_clouds.png"), cloud_layer())
    ba.write_png(os.path.join(ba.OUT, "ui", "flight_sea.png"), sea_layer())
