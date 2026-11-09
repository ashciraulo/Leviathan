"""Windmere Heights: windswept sea cliffs and old wind farms (plan feel:
open, airy, dizzying). Palette: turf #8FB15A, chalk #E8E2D0, sea far below
#2F6E9E, sea pinks #F2A0B8.

Tiles are RGBA 16x16 grids; sprites are material silhouettes that
build_art.lit() shades. Imported by build_art.py.

Material letters here must not clash with other art modules (build_art
asserts it): this file uses [ ] { } for ramps and none for flats.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
TURF = [hex_color(c) for c in ("#C8DC8A", "#A8C46A", "#8FB15A", "#76964A", "#5A7A3E", "#3E5A30")]
CHALK = [hex_color(c) for c in ("#F6F2E4", "#E8E2D0", "#CEC6AE", "#AAA28A", "#7E7866", "#555046")]
SEA = [hex_color(c) for c in ("#F0F8FF", "#8EC4E2", "#4A90BE", "#2F6E9E", "#225480", "#183E62")]
PINK = [hex_color(c) for c in ("#FFD0DC", "#F2A0B8", "#C8708E")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def turf_tile(seed):
    """Short cliff-top turf, combed one way by the wind."""
    rnd = random.Random(3400 + seed)
    px = blank(TURF[2])
    # Wind-combed streaks: short diagonal strokes all leaning the same way.
    for _ in range(9):
        x, y = rnd.randrange(T), rnd.randrange(1, T)
        px[y][x] = TURF[1]
        px[y - 1][(x + 1) % T] = TURF[0] if rnd.random() < 0.3 else TURF[1]
    for _ in range(8):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = TURF[3]
    if seed == 3:
        # A bare chalk patch where the turf has worn through.
        cx, cy = rnd.randrange(4, 12), rnd.randrange(4, 12)
        for (dx, dy) in ((0, 0), (1, 0), (-1, 0), (0, 1), (1, 1)):
            px[cy + dy][cx + dx] = CHALK[2]
        px[cy - 1][cx] = CHALK[1]
    return px


def chalk_top(seed):
    """Wall top: high ground of dark, wind-bitten heather and gorse over the
    chalk, clearly rougher than the cropped turf below."""
    rnd = random.Random(3500 + seed)
    heath = [hex_color(c) for c in ("#6E8A4A", "#56703C", "#445A32", "#34462A")]
    heather = [hex_color(c) for c in ("#A07AA8", "#7E5A88")]
    px = blank(heath[2])
    for _ in range(26):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((heath[1], heath[3], heath[3]))
    for _ in range(5):
        x, y = rnd.randrange(T - 1), rnd.randrange(T - 1)
        px[y][x] = heather[0]
        px[y + 1][x] = heather[1]
    for _ in range(2):
        x, y = rnd.randrange(T - 1), rnd.randrange(T)
        px[y][x] = CHALK[2]
        px[y][x + 1] = CHALK[3]
    return px


def chalk_face(seed):
    """Wall face: white chalk with flint bands and a turf lip at the top."""
    rnd = random.Random(3600 + seed)
    px = blank(CHALK[2])
    for x in range(T):
        px[0][x] = TURF[2]
        px[1][x] = TURF[4] if (x + seed) % 3 else TURF[3]
        px[2][x] = CHALK[0]
        px[3][x] = CHALK[1]
        px[T - 1][x] = CHALK[4]
        px[T - 2][x] = CHALK[3]
    # Flint nodules in two bands.
    for band in (7, 11):
        for x in range(T):
            if (x * 7 + seed * 5 + band) % 5 < 2:
                px[band][x] = CHALK[5]
                px[band - 1][x] = CHALK[3] if px[band - 1][x] == CHALK[2] else px[band - 1][x]
    for _ in range(2):
        fx = rnd.randrange(1, T - 1)
        for y in range(4, rnd.randrange(8, T - 2)):
            px[y][fx] = CHALK[3]
    return px


def sea_tile(frame):
    """The sea far below the cliffs: deep blue, small whitecaps that drift."""
    px = blank(SEA[3])
    for y in range(T):
        for x in range(T):
            w = math.sin((x + frame * 3) * 0.7 + y * 1.3) + math.sin(y * 0.5 - x * 0.4)
            if w > 1.3:
                px[y][x] = SEA[2]
            elif w < -1.5:
                px[y][x] = SEA[4]
    for (x, y) in ((3, 3), (11, 8), (6, 12)):
        xx = (x + frame * 2) % T
        px[y][xx] = SEA[0]
        px[y][(xx + 1) % T] = SEA[1]
    return px


def surf_edge(side, frame):
    """The drop from the cliff top to the sea far below: on the far (top)
    side a band of white chalk face falls to a line of surf; the other sides
    get a thin chalk lip and surf."""
    px = blank()
    face = 8 if side == "top" else 3
    for i in range(T):
        jag = 1 if (i * 7 + 3) % 5 < 2 else 0
        depth = face + jag
        foam = 2 + (1 if (i * 5 + frame * 3) % 7 < 3 else 0)
        for d in range(depth + foam):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            if d == 0:
                px[y][x] = TURF[4]
            elif d < depth:
                if side == "top":
                    band = CHALK[1] if d < 3 else (CHALK[5] if d == 5 and i % 3 == 0 else CHALK[2] if d < depth - 1 else CHALK[3])
                else:
                    band = CHALK[2] if d < depth - 1 else CHALK[3]
                px[y][x] = band
            else:
                px[y][x] = SEA[0] if d == depth else SEA[1]
    return px


def brink(side, seed):
    """Turf scuffed and shadowed at the brink of a drop."""
    rnd = random.Random(3700 + seed)
    px = blank()
    for i in range(T):
        depth = 2 + rnd.randrange(3)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = (60, 80, 40, 120) if d < 1 else (60, 80, 40, 60)
    return px


def sea_pinks(seed):
    """A cushion of sea pinks (thrift) clinging near the edge."""
    px = blank()
    rnd = random.Random(3800 + seed)
    for _ in range(4 + seed * 2):
        x, y = rnd.randrange(4, 12), rnd.randrange(8, 13)
        px[y][x] = PINK[1]
        px[y - 1][x] = PINK[0]
        px[y + 1][x] = TURF[4]
    return px


def tussock(seed):
    """A tuft of long grass bent over by the wind."""
    px = blank()
    rnd = random.Random(3900 + seed)
    for i in range(5):
        x = 5 + i + rnd.randrange(2)
        h = rnd.randrange(4, 7)
        for s in range(h):
            xx = min(T - 1, x + s // 2)
            px[12 - s][xx] = TURF[1] if s > h - 3 else TURF[3]
    for x in range(5, 11):
        px[12][x] = TURF[4]
    return px


def gust_streak(seed):
    """A faint wind streak laid over the turf now and then."""
    px = blank()
    y = 5 + seed * 4
    for x in range(2 + seed, 13 + seed):
        if x < T:
            px[y][x] = (255, 255, 255, 46)
    for x in range(6, 11):
        px[y + 2][x] = (255, 255, 255, 30)
    return px


TILES = [
    ("turf_0", lambda: turf_tile(0)), ("turf_1", lambda: turf_tile(1)),
    ("turf_2", lambda: turf_tile(2)), ("turf_3", lambda: turf_tile(3)),
    ("chalk_top_0", lambda: chalk_top(0)), ("chalk_top_1", lambda: chalk_top(1)),
    ("chalk_face_0", lambda: chalk_face(0)), ("chalk_face_1", lambda: chalk_face(1)),
    ("deep_sea_0", lambda: sea_tile(0)), ("deep_sea_1", lambda: sea_tile(1)),
    ("surf_top_0", lambda: surf_edge("top", 0)), ("surf_bottom_0", lambda: surf_edge("bottom", 0)),
    ("surf_left_0", lambda: surf_edge("left", 0)), ("surf_right_0", lambda: surf_edge("right", 0)),
    ("surf_top_1", lambda: surf_edge("top", 1)), ("surf_bottom_1", lambda: surf_edge("bottom", 1)),
    ("surf_left_1", lambda: surf_edge("left", 1)), ("surf_right_1", lambda: surf_edge("right", 1)),
    ("brink_top", lambda: brink("top", 1)), ("brink_bottom", lambda: brink("bottom", 2)),
    ("brink_left", lambda: brink("left", 3)), ("brink_right", lambda: brink("right", 4)),
    ("seapinks_0", lambda: sea_pinks(0)), ("seapinks_1", lambda: sea_pinks(1)),
    ("tussock_0", lambda: tussock(0)), ("tussock_1", lambda: tussock(1)),
    ("gust_0", lambda: gust_streak(0)), ("gust_1", lambda: gust_streak(1)),
]

# --------------------------------------------------------------------------
# Sprites.
# --------------------------------------------------------------------------
RAMPS = {
    "[": ["#C8A27A", "#A47E58", "#7E5E40", "#5A4230", "#3A2A20"],   # old wood
    "]": ["#FFF8EC", "#EDE2CC", "#CFC0A2", "#A8987A", "#7A6C56"],   # sailcloth
    "{": ["#E8D08A", "#C8AA62", "#A08440", "#78602E", "#4E3E22"],   # dry burr straw
    "}": ["#D8D4CC", "#B4AEA2", "#8E887C", "#686258", "#44403A"],   # field stone
}
FLAT = {}


# A wind pump: a stone-footed timber tower with four canvas sails. 32x48,
# frames turn the sails a quarter at a time.
def windmill(frame):
    w, h = 32, 48
    c = [["."] * w for _ in range(h)]
    # Stone foot and tapering timber tower.
    for y in range(18, 47):
        half = 4 + (y - 18) // 6
        for x in range(16 - half, 16 + half):
            c[y][x] = "}" if y > 40 else "["
    # A door.
    for y in range(41, 47):
        for x in (15, 16):
            c[y][x] = "."  # left open; the shadow behind reads as a doorway
    # Cap.
    for y in range(15, 19):
        for x in range(12, 20):
            c[y][x] = "["
    # Sails around the hub at (16, 16).
    ang0 = frame * math.pi / 8
    for k in range(4):
        ang = ang0 + k * math.pi / 2
        for r in range(3, 15):
            for off in (-1, 0, 1, 2):
                # Each sail is a lattice spar with cloth on one side.
                px = 16 + math.cos(ang) * r - math.sin(ang) * off
                py = 16 + math.sin(ang) * r + math.cos(ang) * off
                x, y = int(round(px)), int(round(py))
                if 0 <= x < w and 0 <= y < h:
                    c[y][x] = "[" if off == 0 else "]"
    c[16][16] = "["
    return ["".join(r) for r in c]


# Tumbleburr: a ball of thorny dry straw the gusts roll across the heights.
# 16x16, four rolling frames.
def tumbleburr(frame):
    c = [["."] * 16 for _ in range(16)]
    cx, cy, r = 8, 9, 5.5
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - cx, y - cy)
            if d < r:
                # Woven strands: diagonal lines that turn with the frame.
                a = math.atan2(y - cy, x - cx) + frame * math.pi / 4
                if (int(d * 1.6 + a * 2.2) % 3) or d > r - 1.2:
                    c[y][x] = "{"
    # Thorns poking out.
    for k in range(8):
        a = k * math.pi / 4 + frame * math.pi / 8
        x, y = int(round(cx + math.cos(a) * (r + 1))), int(round(cy + math.sin(a) * (r + 1)))
        if 0 <= x < 16 and 0 <= y < 16:
            c[y][x] = "{"
    return ["".join(r) for r in c]
