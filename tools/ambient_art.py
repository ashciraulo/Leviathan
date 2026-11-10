"""Ambient life for the overworld: gulls, fish under the water, shore crabs,
butterflies, and the wind-ripples on Saltmarrow's sand. None of it is in
the way; it only makes the coast feel alive (scripts/world/ambience.gd).

Tiles are RGBA 16x16 grids. Sprites are material silhouettes that
build_art.lit() shades with this file's own materials, except the fish
shadows and splashes, which are plain RGBA (they sit under or on the water
and take no outline). Imported by build_art.py.
"""

import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)


# --------------------------------------------------------------------------
# Tiles
# --------------------------------------------------------------------------

def ripple(seed):
    """Wind ripples and a little shell grit on dry sand, laid over Saltmarrow's
    floor now and then so the beach isn't one flat colour."""
    rnd = random.Random(4100 + seed)
    px = [[CLEAR] * T for _ in range(T)]
    dark = hex_color("#B8935E", 70)
    light = hex_color("#FFF4D8", 80)
    # Two or three gentle arcs, a pale crest over a soft shadow.
    for i in range(2 + seed):
        y0 = 3 + i * 5 + rnd.randrange(2)
        x0 = rnd.randrange(0, 4)
        for x in range(x0, min(T, x0 + 9 + rnd.randrange(4))):
            bend = 1 if (x - x0) in (3, 4, 5) else 0
            y = y0 - bend
            if 0 <= y < T - 1:
                px[y][x] = light
                px[y + 1][x] = dark
    grit = [hex_color("#F4D8D0"), hex_color("#E8E0CC"), hex_color("#9C8A70")]
    for _ in range(2):
        px[rnd.randrange(T)][rnd.randrange(T)] = rnd.choice(grit)
    return px


def tidepool(seed):
    """Seen through the water of a tidepool: a weedy stone, or a starfish and
    a pair of pebbles. Laid over Saltmarrow's pools now and then."""
    rnd = random.Random(4200 + seed)
    px = [[CLEAR] * T for _ in range(T)]
    if seed == 0:
        stone = [hex_color(c, 150) for c in ("#8EA4A0", "#5E7A78", "#3E5658")]
        weed = [hex_color(c, 170) for c in ("#7ABF6A", "#3E8A54")]
        cx, cy = 5 + rnd.randrange(4), 6 + rnd.randrange(3)
        for dy in range(-2, 3):
            for dx in range(-3, 4):
                if dx * dx / 9 + dy * dy / 4 <= 1.0:
                    px[cy + dy][cx + dx] = stone[0] if dy < 0 and dx < 1 else (stone[2] if dy > 0 else stone[1])
        for bx in (cx - 2, cx, cx + 2):
            for k in range(3 + rnd.randrange(3)):
                x = bx + (1 if k % 2 else 0)
                if 0 <= cy - 2 - k < T and 0 <= x < T:
                    px[cy - 2 - k][x] = weed[k % 2]
    else:
        star = [hex_color(c, 190) for c in ("#F4A07A", "#C8604A")]
        cx, cy = 5 + rnd.randrange(5), 5 + rnd.randrange(5)
        px[cy][cx] = star[1]
        for d in ((0, -1), (1, 0), (-1, 0), (1, 1), (-1, 1)):
            for r in (1, 2):
                x, y = cx + d[0] * r, cy + d[1] * r
                if 0 <= x < T and 0 <= y < T:
                    px[y][x] = star[0] if r == 1 else star[1]
        pebble = hex_color("#C8D0C8", 140)
        for _ in range(2):
            x, y = rnd.randrange(1, T - 2), rnd.randrange(1, T - 2)
            if px[y][x] == CLEAR:
                px[y][x] = pebble
                px[y][x + 1] = pebble
    return px


TILES = [
    ("ripple_0", lambda: ripple(0)), ("ripple_1", lambda: ripple(1)),
    ("tidepool_0", lambda: tidepool(0)), ("tidepool_1", lambda: tidepool(1)),
]


# --------------------------------------------------------------------------
# Sprites: this file's own materials.
# --------------------------------------------------------------------------
RAMPS = {
    "g": ["#FFFFFF", "#ECEEF0", "#CED4DA", "#A2AAB4", "#6A7280"],   # gull white
    "w": ["#C4CCD4", "#9AA4B0", "#7A8492", "#5A6270", "#3A404A"],   # gull wing grey
    "c": ["#F08A5A", "#D86A42", "#B04E32", "#843826", "#4E2018"],   # shore crab
    "1": ["#FFE7A0", "#F6C85A", "#D89A3A", "#A86A2A", "#5E3A1A"],   # butterfly: amber
    "2": ["#D8E8FF", "#A8C4F0", "#7A96D0", "#566EA6", "#2E3E6A"],   # butterfly: sky
    "3": ["#FFD8E8", "#F4A8C8", "#D47AA4", "#A0507A", "#5A2A44"],   # butterfly: pink
}
FLAT = {
    "o": "#F2A541",   # beak and legs
    "e": "#141210",   # eyes, wingtips
    "b": "#3A2A24",   # butterfly body
}


def _grid(w, h):
    return [["."] * w for _ in range(h)]


def _rows(c):
    return ["".join(r) for r in c]


# A gull seen from above, 16x12, flying right: wings spread across the body,
# swept back, with black tips and a dab of orange beak. Frames: up (wings
# raised, so they look short), level (full span) and down.
def gull(frame):
    w, h = 16, 12
    c = _grid(w, h)
    mid = 6
    # Body and head along the middle, tail to the left.
    for x in range(3, 13):
        c[mid][x] = "g"
        if 5 <= x <= 11:
            c[mid - 1][x] = "g"
    c[mid - 1][12] = "g"
    c[mid][13] = "o"
    c[mid - 1][11] = "e"
    c[mid][2] = "w"
    c[mid - 1][2] = "w"
    span = {"up": 2, "level": 5, "down": 4}[frame]
    for i in range(1, span + 1):
        # Each step out along the wing sweeps a little further back.
        back = i // 2
        for x in range(7 - back, 10 - back - (1 if i == span else 0)):
            colour = "e" if i == span else "w"
            c[mid - 1 - i][x] = colour
            c[mid + i][x] = colour
    return _rows(c)


# A shore crab, 10x7, scuttling sideways: two frames of legs.
def crab(frame):
    w, h = 10, 7
    c = _grid(w, h)
    for y in range(2, 5):
        for x in range(2, 8):
            if not (y == 4 and x in (2, 7)):
                c[y][x] = "c"
    c[1][3], c[1][6] = "e", "e"
    c[2][1], c[2][8] = "c", "c"
    c[1][1], c[1][8] = "c", "c"
    legs = (5, 6) if frame == 0 else (6, 5)
    for x, y in ((1, legs[0]), (3, legs[1]), (6, legs[1]), (8, legs[0])):
        c[min(y, h - 1)][x] = "c"
    return _rows(c)


# A butterfly, 7x6, wings open and folded. `m` is its colour material.
def butterfly(m, frame):
    w, h = 7, 6
    c = _grid(w, h)
    for y in range(1, 5):
        c[y][3] = "b"
    if frame == 0:
        for (x, y) in ((0, 0), (1, 0), (2, 1), (0, 1), (1, 1), (1, 2), (2, 2),
                       (1, 3), (2, 3), (2, 4)):
            c[y][x] = m
            c[y][6 - x] = m
    else:
        for (x, y) in ((2, 0), (2, 1), (2, 2), (2, 3)):
            c[y][x] = m
            c[y][6 - x] = m
    return _rows(c)


# Fish, seen as a dark shape under the water: 12x5, two tail swishes.
def fish_shadow(frame):
    w, h = 12, 5
    shade = hex_color("#0E2A34", 110)
    px = [[CLEAR] * w for _ in range(h)]
    for x in range(1, 9):
        half = 2 if 2 <= x <= 6 else 1
        for y in range(2 - half + 1, 2 + half):
            px[y][x] = shade
    tail = (1, 3) if frame == 0 else (0, 2)
    for y in range(tail[0], tail[1] + 1):
        px[y][10 if frame == 0 else 9] = shade
        px[y][11 if frame == 0 else 10] = shade if y != 2 else CLEAR
    px[2][9] = shade
    return px


# A splash where a fish jumps: 12x8, three frames (spray up, ring, fading).
def splash(frame):
    w, h = 12, 8
    foam = hex_color("#F2FAFA")
    light = hex_color("#BFE4E8", 200)
    px = [[CLEAR] * w for _ in range(h)]
    if frame == 0:
        for (x, y) in ((5, 1), (6, 2), (4, 3), (7, 3), (3, 5), (8, 5), (5, 4), (6, 4)):
            px[y][x] = foam
        for x in range(3, 9):
            px[6][x] = light
    else:
        r = 3 if frame == 1 else 5
        col = foam if frame == 1 else light
        for x in range(6 - r, 6 + r):
            px[6][x] = col if (x + frame) % 2 == 0 else px[6][x]
            px[4][x] = col if frame == 1 and abs(x - 6) < r - 1 and x % 2 == 0 else px[4][x]
        px[5][6 - r] = col
        px[5][5 + r] = col
    return px


def build(lit, sheet):
    """Everything in assets/ambient/, as {file name: pixels}."""
    return {
        "gull": sheet([[lit(gull(f), 140) for f in ("up", "level", "down")]], 16, 12),
        "crab": sheet([[lit(crab(f), 141) for f in (0, 1)]], 10, 7),
        "butterfly": sheet([[lit(butterfly(m, f), 142) for f in (0, 1)] for m in ("1", "2", "3")], 7, 6),
        "fish": sheet([[fish_shadow(f) for f in (0, 1)]], 12, 5),
        "splash": sheet([[splash(f) for f in (0, 1, 2)]], 12, 8),
    }
