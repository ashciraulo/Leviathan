"""Ossuary Dunes: a desert of giant ancient bones (plan feel: vast, bleached,
ancient; something enormous died here long ago). Palette: dune gold
#E8C890, shadowed sand #C49A64, bone #F2EAD8, old bone #C8B898, sandstone
#B07850, bitter sea #3E7C86, sky-blue salt #DCEAEA.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes that build_art.lit() shades with this file's own
materials (RAMPS, FLAT). Imported by build_art.py, which writes the
sprites to assets/ossuary/.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
SAND = [hex_color(c) for c in ("#F8E0B0", "#E8C890", "#D8B47A", "#C49A64", "#A88050", "#806040")]
BONE = [hex_color(c) for c in ("#FFF8EC", "#F2EAD8", "#DCD0B8", "#C8B898", "#A89878", "#786C58")]
STONE = [hex_color(c) for c in ("#D49A68", "#B07850", "#94603E", "#784A30", "#5A3624", "#3C2418")]
SEA = [hex_color(c) for c in ("#B4DCDC", "#6EAAB0", "#4E8E98", "#3E7C86", "#2E6068", "#204650")]
SALT = [hex_color(c) for c in ("#FFFFFF", "#ECF4F2", "#DCEAEA", "#BCD2D2")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def dune_tile(seed):
    """Wind-rippled sand: long soft ridges with a bright crest each."""
    rnd = random.Random(6100 + seed)
    px = blank(SAND[1])
    for y in range(T):
        for x in range(T):
            v = math.sin(x * 0.45 + y * 0.9 + seed * 1.7 + math.sin(x * 0.3) * 1.2)
            if v > 0.82:
                px[y][x] = SAND[0]
            elif v < -0.7:
                px[y][x] = SAND[2]
    for _ in range(6):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = SAND[3]
    return px


def sinksand(frame):
    """Sinking sand (layout S): darker, loose, turning slowly round its
    middle. Two frames so it seems to swirl."""
    px = blank(SAND[3])
    for y in range(T):
        for x in range(T):
            dx, dy = x - 7.5, y - 7.5
            angle = math.atan2(dy, dx)
            r = math.hypot(dx, dy)
            v = math.sin(angle * 2 + r * 0.9 - frame * 1.6)
            if v > 0.55:
                px[y][x] = SAND[2]
            elif v < -0.6:
                px[y][x] = SAND[4]
    return px


def ossuary_top(seed):
    """Wall top: wind-scoured sandstone, bones half-buried in its drifts."""
    rnd = random.Random(6200 + seed)
    px = blank(STONE[2])
    for y in range(T):
        for x in range(T):
            if (y + x // 3 + seed) % 5 == 0:
                px[y][x] = STONE[1]
            elif (y * 3 + x + seed) % 11 == 0:
                px[y][x] = STONE[3]
    # A bone poking out.
    x0, y0 = rnd.randrange(2, 8), rnd.randrange(3, 12)
    for i in range(6):
        px[y0][x0 + i] = BONE[2]
        px[y0 + 1][x0 + i] = BONE[4]
    px[y0 - 1][x0] = BONE[1]
    px[y0 - 1][x0 + 5] = BONE[1]
    for _ in range(5):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = SAND[1]
    return px


def ossuary_face(seed):
    """Wall face: layered sandstone, banded red and gold by the ages."""
    px = blank(STONE[2])
    for y in range(T):
        for x in range(T):
            band = (y + (x * 2 + seed * 7) // 9) % 6
            px[y][x] = [STONE[1], STONE[2], STONE[2], STONE[3], STONE[2], STONE[4]][band]
    for x in range(T):
        px[0][x] = SAND[1] if (x + seed) % 5 else SAND[2]
        px[T - 1][x] = STONE[5]
    return px


def bitter_sea(frame):
    """The bitter sea that rings the dunes: green-blue and still."""
    px = blank(SEA[3])
    for y in range(T):
        for x in range(T):
            v = math.sin((x + frame * 3) * 0.6 + y * 0.35) + math.cos(y * 0.8 - frame)
            if v > 1.4:
                px[y][x] = SEA[1]
            elif v > 0.8:
                px[y][x] = SEA[2]
            elif v < -1.3:
                px[y][x] = SEA[4]
    return px


def salt_crust(side, frame):
    """A rim of white salt where the bitter sea has dried on the sand."""
    px = blank()
    for i in range(T):
        depth = 3 + (1 if (i * 5 + frame * 3) % 7 < 2 else 0)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = SALT[1] if d < depth - 2 else SALT[3] if d == depth - 2 else SEA[2]
    return px


def sandshade(side, seed):
    """Damp, darker sand beside the water."""
    rnd = random.Random(6300 + seed)
    px = blank()
    for i in range(T):
        depth = 2 + rnd.randrange(3)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = (150, 110, 70, 110) if d < 1 else (150, 110, 70, 55)
    return px


def bone_shards(seed):
    """Small bones scattered in the sand."""
    rnd = random.Random(6400 + seed)
    px = blank()
    for _ in range(2 + seed):
        x, y = rnd.randrange(2, 11), rnd.randrange(3, 13)
        length = rnd.randrange(3, 6)
        for i in range(length):
            px[y][x + i] = BONE[1]
            px[y + 1][x + i] = BONE[4]
        px[y - 1][x] = BONE[2]
        px[y - 1][x + length - 1] = BONE[2]
    return px


def thornbush(seed):
    """A dry thorn shrub (by the water)."""
    px = blank()
    rnd = random.Random(6500 + seed)
    for _ in range(14):
        a = rnd.uniform(math.pi * 1.05, math.pi * 1.95)
        r = rnd.uniform(2, 6)
        x, y = int(8 + math.cos(a) * r), int(12 + math.sin(a) * r)
        if 0 <= x < T and 0 <= y < T:
            px[y][x] = STONE[4] if r > 4 else STONE[3]
    return px


def sanddrift(seed):
    """Streaks of blowing sand laid over the dunes."""
    px = blank()
    rnd = random.Random(6600 + seed)
    for _ in range(3):
        x0, y = rnd.randrange(T), rnd.randrange(T)
        for i in range(rnd.randrange(3, 6)):
            px[y][(x0 + i) % T] = (248, 224, 176, 140)
    return px


TILES = [
    ("dune_0", lambda: dune_tile(0)), ("dune_1", lambda: dune_tile(1)),
    ("dune_2", lambda: dune_tile(2)), ("dune_3", lambda: dune_tile(3)),
    ("sinksand_0", lambda: sinksand(0)), ("sinksand_1", lambda: sinksand(1)),
    ("ossuary_top_0", lambda: ossuary_top(0)), ("ossuary_top_1", lambda: ossuary_top(1)),
    ("ossuary_face_0", lambda: ossuary_face(0)), ("ossuary_face_1", lambda: ossuary_face(1)),
    ("bitter_sea_0", lambda: bitter_sea(0)), ("bitter_sea_1", lambda: bitter_sea(1)),
    ("salt_crust_top_0", lambda: salt_crust("top", 0)), ("salt_crust_bottom_0", lambda: salt_crust("bottom", 0)),
    ("salt_crust_left_0", lambda: salt_crust("left", 0)), ("salt_crust_right_0", lambda: salt_crust("right", 0)),
    ("salt_crust_top_1", lambda: salt_crust("top", 1)), ("salt_crust_bottom_1", lambda: salt_crust("bottom", 1)),
    ("salt_crust_left_1", lambda: salt_crust("left", 1)), ("salt_crust_right_1", lambda: salt_crust("right", 1)),
    ("sandshade_top", lambda: sandshade("top", 1)), ("sandshade_bottom", lambda: sandshade("bottom", 2)),
    ("sandshade_left", lambda: sandshade("left", 3)), ("sandshade_right", lambda: sandshade("right", 4)),
    ("thornbush_0", lambda: thornbush(0)), ("thornbush_1", lambda: thornbush(1)),
    ("bone_shards_0", lambda: bone_shards(0)), ("bone_shards_1", lambda: bone_shards(1)),
    ("sanddrift_0", lambda: sanddrift(0)), ("sanddrift_1", lambda: sanddrift(1)),
]

# --------------------------------------------------------------------------
# Sprites: this file's own materials.
# --------------------------------------------------------------------------
RAMPS = {
    "o": ["#FFF8EC", "#F2EAD8", "#DCD0B8", "#B4A488", "#786C58"],   # bone
    "s": ["#F8E0B0", "#E8C890", "#C49A64", "#A88050", "#6A4C30"],   # sand
    "h": ["#C8A070", "#A88050", "#86603A", "#62442A", "#3A2818"],   # jaw hide
    "t": ["#FFFFFF", "#F4ECDC", "#DCCCB0", "#B4A488", "#80745E"],   # teeth
}
FLAT = {
    "k": "#1A1210",   # sockets, mouth
    "e": "#F0C040",   # eye glint
}


def _grid(w, h):
    return [["."] * w for _ in range(h)]


def _rows(c):
    return ["".join(r) for r in c]


# Dunejaw: an eyeless eel-thing that swims under the dunes. Underground only
# a ripple of sand shows; its tell is a spout of sand and a dry rattle where
# it's about to burst up; then it bites, and lies out on the sand a moment.
# 24x20 frames: ripple, spout, bite, exposed.
def dunejaw(frame):
    w, h = 24, 20
    c = _grid(w, h)
    if frame == "ripple":
        for x in range(4, 20):
            y = 16 + int(math.sin(x * 0.8) * 1.2)
            c[y][x] = "s"
            if x % 3 == 0:
                c[y - 1][x] = "s"
        return _rows(c)
    if frame == "spout":
        for y in range(6, 18):
            half = max(1, (y - 6) // 2)
            for x in range(12 - half, 12 + half):
                if (x + y) % 3:
                    c[y][x] = "s"
        for x in range(5, 19):
            c[18][x] = "s"
        return _rows(c)
    up = frame == "bite"
    top = 2 if up else 9
    # Body rising from the sand.
    for y in range(top, 18):
        half = 4 if y > top + 4 else 2 + (y - top) // 2
        for x in range(12 - half, 12 + half):
            c[y][x] = "h"
    # Jaws: open wide when biting.
    if up:
        for y in range(top, top + 5):
            c[y][12 - 4 + (y - top) // 2 - 1] = "k"
            c[y][12 + 3 - (y - top) // 2 + 1] = "k"
        for y in range(top, top + 4):
            for x in range(10, 14):
                c[y][x] = "k"
        for x in (9, 11, 13, 15):
            c[top + 1][x] = "t"
            c[top + 4][x - 1] = "t"
    else:
        c[top + 1][10], c[top + 1][13] = "e", "e"
        for x in range(9, 15):
            c[top + 3][x] = "t" if x % 2 else "k"
    for x in range(4, 20):
        c[18][x] = "s"
        c[19][x] = "s" if x % 2 else "."
    return _rows(c)


# A great rib (layout U): one curved bone the height of a house, leaning
# over the sand. Ribs set in rows make a whale-fall's cage. 24x56, foot
# row 53.
def rib(flip=False):
    w, h = 24, 56
    c = _grid(w, h)
    for y in range(4, 54):
        t = (y - 4) / 50.0
        cx = 6 + int(math.sin(t * math.pi * 0.9) * 10)
        thick = 3 if y > 40 else 2
        for x in range(cx - thick, cx + thick):
            if 0 <= x < w:
                c[y][x] = "o"
    for x in range(4, 14):
        c[53][x] = "s"
        c[54][x] = "s" if x % 2 else "."
    rows = _rows(c)
    return [r[::-1] for r in rows] if flip else rows


# A great beast's skull (layout Q), side on and half sunk in the dunes:
# a domed braincase, one empty eye, a long toothed snout. The Marrow
# Tomb's door is the dark of its throat. 64x48, foot row 45.
def skull():
    w, h = 64, 48
    c = _grid(w, h)
    # Braincase.
    for y in range(6, 46):
        for x in range(30, 62):
            if ((x - 46) / 16.0) ** 2 + ((y - 24) / 19.0) ** 2 <= 1.0:
                c[y][x] = "o"
    # Snout, tapering to the left, upper jaw over lower.
    for x in range(3, 36):
        t = (x - 3) / 33.0
        top = int(26 - t * 10)
        bottom = int(34 + t * 4)
        for y in range(top, bottom):
            c[y][x] = "o"
    # The gape between the jaws, teeth on both sides.
    for x in range(6, 34):
        t = (x - 6) / 28.0
        gy = int(30 + t * 1)
        c[gy][x] = "k"
        if x % 3 == 0:
            c[gy - 1][x] = "t"
            c[gy + 1][x + 1 if x + 1 < 34 else x] = "t"
    # Eye socket and nostril.
    for y in range(13, 23):
        for x in range(38, 50):
            if ((x - 44) / 6.0) ** 2 + ((y - 18) / 5.0) ** 2 <= 1.0:
                c[y][x] = "k"
    for y in range(22, 25):
        for x in range(8, 12):
            c[y][x] = "k"
    # The throat: a dark arch under the braincase.
    for y in range(32, 46):
        half = 7 if y > 35 else 7 - (35 - y) * 2
        for x in range(46 - half, 46 + half):
            if 0 <= half:
                c[y][x] = "k"
    # Cracks and wear.
    for i in range(9):
        c[8 + i][52 + (i % 3)] = "k" if i < 6 else "s"
    # Sand drifted against it.
    for x in range(1, 63):
        for y in range(42 - (2 if (x * 7) % 9 < 4 else 0), 46):
            if not (39 <= x < 53 and y >= 32):
                c[y][x] = "s"
    return _rows(c)


def build(lit, sheet):
    """Everything in assets/ossuary/, as {file name: pixels}."""
    return {
        "dunejaw": sheet([[lit(dunejaw(f), 100) for f in ("ripple", "spout", "bite", "exposed")]], 24, 20),
        "rib": sheet([[lit(rib(False), 101)]], 24, 56),
        "skull": sheet([[lit(skull(), 102)]], 64, 48),
    }
