"""Sunken Verge: a drowned town on the tidal flats, only walkable at low
tide (plan feel: hushed, waterlogged, a place that used to be home).
Palette: wet sand #8C8270, silt #A89C82, tide flat #6E6656 with sky glints
#9AAAB0, shallows #4E6E72, barnacled stone #6A6E68, wrack #4E5A3A, bell
bronze #8A6A3A.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes that build_art.lit() shades with this file's own
materials (RAMPS, FLAT), so its letters can't clash with other files.
Imported by build_art.py, which writes the sprites to assets/verge/.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
SILT = [hex_color(c) for c in ("#C4B89C", "#A89C82", "#968A72", "#847862", "#6E6454")]
FLAT_SAND = [hex_color(c) for c in ("#B4C0C4", "#9AAAB0", "#7A746A", "#6E6656", "#5C5446", "#4A4438")]
STONE = [hex_color(c) for c in ("#9A9E96", "#80847C", "#6A6E68", "#565A54", "#424640", "#2E322E")]
WEED = [hex_color(c) for c in ("#7A8A52", "#5E6E42", "#4E5A3A", "#3A4428")]
SEA = [hex_color(c) for c in ("#A8C4C4", "#6E9294", "#4E6E72", "#3A585E", "#2A444A")]
SHELL = [hex_color(c) for c in ("#F2EAE0", "#D8CCBC", "#B4A490")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def silt_tile(seed):
    """Dry silt above the tideline: pale, fine, with a few wind ripples."""
    rnd = random.Random(5100 + seed)
    px = blank(SILT[1])
    for y in range(T):
        for x in range(T):
            if (x + y * 2 + seed * 3) % 9 == 0 and rnd.random() < 0.6:
                px[y][x] = SILT[2]
    for _ in range(10):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((SILT[0], SILT[3]))
    return px


def flat_tile(seed):
    """Tide flat (layout r): dark, glossy wet sand ridged by the ebb, with
    pale sky caught in the ripples and the odd worm cast."""
    rnd = random.Random(5200 + seed)
    px = blank(FLAT_SAND[3])
    for y in range(T):
        for x in range(T):
            wave = math.sin(x * 0.9 + math.sin(y * 0.5 + seed) * 1.6 + y * 0.25)
            if wave > 0.75:
                px[y][x] = FLAT_SAND[2]
            elif wave < -0.85:
                px[y][x] = FLAT_SAND[4]
    for _ in range(5):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = FLAT_SAND[1]
        px[y][(x + 1) % T] = FLAT_SAND[0]
    # A coiled worm cast.
    cx, cy = rnd.randrange(3, 13), rnd.randrange(3, 13)
    for (dx, dy) in ((0, 0), (1, 0), (1, 1), (0, 1), (-1, 1)):
        px[cy + dy][cx + dx] = FLAT_SAND[4] if (dx, dy) == (0, 0) else FLAT_SAND[2]
    return px


def seawall_top(seed):
    """Wall top: the slumped stone of drowned houses, crusted with barnacles
    and draped in wrack."""
    rnd = random.Random(5300 + seed)
    px = blank(STONE[3])
    for y in range(T):
        for x in range(T):
            if (x // 5 + y // 4 + seed) % 2 == 0 and rnd.random() < 0.2:
                px[y][x] = STONE[2]
    for _ in range(10):
        x, y = rnd.randrange(1, T - 1), rnd.randrange(1, T - 1)
        px[y][x] = STONE[0]
        px[y + 1][x] = STONE[4]
    for _ in range(2):
        x0, y = rnd.randrange(T), rnd.randrange(T)
        for i in range(rnd.randrange(3, 7)):
            px[y][(x0 + i) % T] = WEED[2 if i % 2 else 1]
    return px


def seawall_face(seed):
    """Wall face: dressed blocks gone green below the high-water line."""
    px = blank(STONE[2])
    for y in range(T):
        for x in range(T):
            row = y // 5
            if y % 5 == 4 or (x + row * 6 + seed * 3) % 11 == 0:
                px[y][x] = STONE[4]
            elif y % 5 == 0:
                px[y][x] = STONE[1]
            if y >= 10:
                px[y][x] = WEED[2] if px[y][x] != STONE[4] else WEED[3]
    for x in range(T):
        if (x * 7 + seed) % 5 == 0:
            for y in range(10, 10 + (x * 3 + seed) % 5):
                px[min(y, T - 1)][x] = WEED[1]
        px[T - 1][x] = STONE[5]
    return px


def shallows(frame):
    """Grey-green shallows, slow swells crossing them."""
    px = blank(SEA[3])
    for y in range(T):
        for x in range(T):
            v = math.sin((x + frame * 2) * 0.55 + y * 0.9) + math.sin(y * 0.4 - frame)
            if v > 1.3:
                px[y][x] = SEA[1]
            elif v > 0.6:
                px[y][x] = SEA[2]
            elif v < -1.4:
                px[y][x] = SEA[4]
    return px


def tideline(side, frame):
    """Where the shallows lap the sand: a lip of foam over wet sand."""
    px = blank()
    for i in range(T):
        depth = 3 + (1 if (i * 3 + frame * 5) % 7 < 3 else 0)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = FLAT_SAND[3] if d < depth - 2 else SEA[0] if d == depth - 2 else SEA[1]
    return px


def seep(side, seed):
    """Sand darkened by the water beside it."""
    rnd = random.Random(5400 + seed)
    px = blank()
    for i in range(T):
        depth = 2 + rnd.randrange(3)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = (70, 64, 52, 110) if d < 1 else (70, 64, 52, 55)
    return px


def wrack(seed):
    """A tangle of stranded weed."""
    rnd = random.Random(5500 + seed)
    px = blank()
    for _ in range(4):
        x, y = rnd.randrange(3, 13), rnd.randrange(5, 12)
        for i in range(5):
            xx = x + i - 2
            yy = y + (1 if i % 2 else 0) + int(math.sin(i + seed) * 1.2)
            if 0 <= xx < T and 0 <= yy < T:
                px[yy][xx] = WEED[i % 3]
    return px


def cockles(seed):
    """Cockle shells, a few broken."""
    rnd = random.Random(5600 + seed)
    px = blank()
    for _ in range(3 + seed):
        x, y = rnd.randrange(2, 13), rnd.randrange(3, 13)
        px[y][x] = SHELL[0]
        px[y][x + 1] = SHELL[1]
        px[y + 1][x] = SHELL[2]
    return px


def glint(seed):
    """A puddle left by the ebb, holding a scrap of sky."""
    px = blank()
    cx, cy = 6 + seed * 3, 7 + seed
    for y in range(cy - 1, cy + 2):
        for x in range(cx - 3, cx + 3):
            if abs(x - cx + 0.5) / 3.0 + abs(y - cy) / 1.5 <= 1.0:
                px[y][x] = (154, 170, 176, 170)
    px[cy][cx - 1] = (220, 230, 232, 220)
    return px


def tidewater(frame):
    """The tide coming in over the flats (drawn over them, faded in)."""
    px = shallows(frame + 2)
    for y in range(T):
        for x in range(T):
            if (x * 5 + y * 3 + frame * 7) % 23 == 0:
                px[y][x] = SEA[0]
    return px


TILES = [
    ("silt_0", lambda: silt_tile(0)), ("silt_1", lambda: silt_tile(1)),
    ("silt_2", lambda: silt_tile(2)), ("silt_3", lambda: silt_tile(3)),
    ("flat_0", lambda: flat_tile(0)), ("flat_1", lambda: flat_tile(1)),
    ("seawall_top_0", lambda: seawall_top(0)), ("seawall_top_1", lambda: seawall_top(1)),
    ("seawall_face_0", lambda: seawall_face(0)), ("seawall_face_1", lambda: seawall_face(1)),
    ("shallows_0", lambda: shallows(0)), ("shallows_1", lambda: shallows(1)),
    ("tideline_top_0", lambda: tideline("top", 0)), ("tideline_bottom_0", lambda: tideline("bottom", 0)),
    ("tideline_left_0", lambda: tideline("left", 0)), ("tideline_right_0", lambda: tideline("right", 0)),
    ("tideline_top_1", lambda: tideline("top", 1)), ("tideline_bottom_1", lambda: tideline("bottom", 1)),
    ("tideline_left_1", lambda: tideline("left", 1)), ("tideline_right_1", lambda: tideline("right", 1)),
    ("seep_top", lambda: seep("top", 1)), ("seep_bottom", lambda: seep("bottom", 2)),
    ("seep_left", lambda: seep("left", 3)), ("seep_right", lambda: seep("right", 4)),
    ("wrack_0", lambda: wrack(0)), ("wrack_1", lambda: wrack(1)),
    ("cockle_0", lambda: cockles(0)), ("cockle_1", lambda: cockles(1)),
    ("glint_0", lambda: glint(0)), ("glint_1", lambda: glint(1)),
    ("tidewater_0", lambda: tidewater(0)), ("tidewater_1", lambda: tidewater(1)),
]

# --------------------------------------------------------------------------
# Sprites: this file's own materials.
# --------------------------------------------------------------------------
RAMPS = {
    "r": ["#A89A80", "#8C7E66", "#6E6250", "#52483C", "#342E28"],   # ray hide (sand-mottled)
    "p": ["#F0E8DC", "#D4C8B8", "#B0A290", "#8A7C6C", "#5A5048"],   # pale underside
    "s": ["#9A9E96", "#80847C", "#6A6E68", "#565A54", "#2E322E"],   # drowned stone
    "w": ["#7A8A52", "#5E6E42", "#4E5A3A", "#3A4428", "#222A18"],   # weed
    "t": ["#9A8A74", "#7A6A58", "#5A4C40", "#3E342E", "#1E1818"],   # sodden timber
    "b": ["#D8B070", "#B08A4E", "#8A6A3A", "#5E4628", "#3A2A18"],   # bell bronze
    "v": ["#C8E0D8", "#94BCB0", "#6E9A8E", "#4E7468", "#2E4A42"],   # verdigris
}
FLAT = {
    "e": "#141210",   # eyes
    "k": "#0E1214",   # dark windows and doorways
    "f": "#E8F2F2",   # foam
}


def _grid(w, h):
    return [["."] * w for _ in range(h)]


def _rows(c):
    return ["".join(r) for r in c]


# Siltray: a sand-coloured ray of the flats. At high tide it swims the
# flooded flats with only its fin showing; its tell is the fin rearing
# and foaming before it flings itself at the shore. At low tide it's
# stranded, flopping on the sand. 24x14 frames: fin, rear, leap,
# stranded_0, stranded_1.
def siltray(frame):
    w, h = 24, 14
    c = _grid(w, h)
    if frame in ("fin", "rear"):
        tall = 7 if frame == "rear" else 4
        for i in range(tall):
            y = 11 - i
            for x in range(11 - (tall - i) // 2, 13 + (tall - i) // 3):
                c[y][x] = "r"
        # A ring of foam where the fin cuts the water.
        for x in range(7, 17):
            if x % 4 != (1 if frame == "rear" else 3):
                c[12][x] = "f"
        if frame == "rear":
            for x in (5, 6, 17, 18):
                c[11][x] = "f"
        return _rows(c)
    lift = 0
    flop = frame == "stranded_1"
    if frame == "leap":
        lift = 3
    for y in range(3, 12):
        dy = abs(y - 7)
        half = 11 - dy * 2 if not flop else 10 - dy * 2
        for x in range(12 - half, 12 + half):
            if 0 <= x < w:
                yy = y - lift
                if 0 <= yy < h:
                    c[yy][x] = "p" if (frame == "leap" and y > 8) else "r"
        # Wing tips curl up as it flops.
    if flop:
        for x in (1, 2, 21, 22):
            c[5][x] = "r"
    # Tail.
    for i in range(5):
        y = 12 - lift
        if 0 <= y < h and 12 + i < w:
            c[min(y + i // 3, h - 1)][12 + i // 2] = "r"
    c[6 - lift][10], c[6 - lift][13] = "e", "e"
    return _rows(c)


# A drowned cottage: stone walls to the eaves, roof long gone, weed
# hanging from the empty window. 48x48, foot row 44.
def cottage():
    w, h = 48, 48
    c = _grid(w, h)
    for y in range(14, 45):
        for x in range(6, 42):
            c[y][x] = "s"
    # The gable, broken.
    for y in range(4, 14):
        half = (y - 4) * 2
        for x in range(24 - half, 24 + half):
            if 6 <= x < 42 and not (x > 28 and y < 10):
                c[y][x] = "s"
    # Stub of a roof beam.
    for x in range(10, 22):
        c[13][x] = "t"
    # Window and door.
    for y in range(20, 27):
        for x in range(12, 19):
            c[y][x] = "k"
    for y in range(30, 45):
        for x in range(26, 34):
            c[y][x] = "k"
    for x in range(25, 35):
        c[29][x] = "t"
    # Weed below the high-water line and hanging from the sill.
    for x in range(6, 42):
        for y in range(38 + (x * 7) % 4, 45):
            if c[y][x] == "s":
                c[y][x] = "w"
    for x in (13, 15, 17):
        for y in range(27, 30 + x % 3):
            c[y][x] = "w"
    return _rows(c)


# The Drowned Belfry: a lone bell tower standing in the flats, its bell
# hanging green in the open top and its doorway half under sand. 48x80,
# foot row 76.
def belfry():
    w, h = 48, 80
    c = _grid(w, h)
    for y in range(20, 77):
        inset = 0 if y > 30 else 1
        for x in range(12 + inset, 36 - inset):
            c[y][x] = "s"
    # Spire.
    for y in range(2, 14):
        half = (y - 1) // 1
        for x in range(24 - half, 24 + half):
            if 10 <= x < 38:
                c[y][x] = "v"
    for x in range(10, 38):
        c[14][x] = "s"
        c[15][x] = "s"
    # The open bell chamber, with the bell in it.
    for y in range(16, 30):
        for x in range(14, 34):
            c[y][x] = "k" if not (x in (14, 15, 32, 33)) else "s"
    # A bell: domed crown, straight waist, flared lip, gone green below.
    for y, half in zip(range(18, 29), (2, 3, 4, 4, 4, 4, 5, 5, 6, 7, 7)):
        for x in range(24 - half, 24 + half):
            c[y][x] = "b" if y < 26 else "v"
    for x in range(23, 25):
        c[17][x] = "t"
    # Doorway at the foot (the room's D sits in front of it).
    for y in range(60, 77):
        half = 5 if y > 62 else 5 - (62 - y)
        for x in range(24 - half, 24 + half):
            c[y][x] = "k"
    # Weed and barnacles up to the high-water line.
    for x in range(12, 36):
        for y in range(64 + (x * 5) % 5, 77):
            if c[y][x] == "s":
                c[y][x] = "w"
    return _rows(c)


def build(lit, sheet):
    """Everything in assets/verge/, as {file name: pixels}."""
    return {
        "siltray": sheet([[lit(siltray(f), 90) for f in ("fin", "rear", "leap", "stranded_0", "stranded_1")]], 24, 14),
        "cottage": sheet([[lit(cottage(), 91)]], 48, 48),
        "belfry": sheet([[lit(belfry(), 92)]], 48, 80),
    }
