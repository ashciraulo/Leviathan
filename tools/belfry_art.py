"""The Drowned Belfry (the Sunken Verge's dungeon): a sea-church sunk under
the bay, its nave half full of green water that the old valves raise and
lower. Floor, wall and deep-water tiles, silt left by low water, weed and
shells, and its pieces: the Diver's Helm, sunken grates, valve wheels,
Knell (a kraken living inside a great bell) with its tentacles and ink,
and the Drowned Bell.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes shaded by build_art.lit(), with this file's own
materials (RAMPS, FLAT). Imported by build_art.py, which writes the sprites
to assets/belfry/.

Palette: sea-green stone #5E8A7E, deep water #1C4A5C, verdigris bronze
#5FA08A, kraken plum #6A3A5E, brass #D8A84A.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)

# --------------------------------------------------------------------------
# Materials (this file's own; see build_art.lit's palette).
# --------------------------------------------------------------------------
RAMPS = {
    "g": ["#F4E0A0", "#D8A84A", "#B07E2E", "#7A5420", "#3A2810"],   # brass
    "v": ["#A8E0C8", "#78C0A6", "#5FA08A", "#3E6E5E", "#1E3830"],   # verdigris bronze
    "p": ["#C88AB4", "#9A5C88", "#6A3A5E", "#48243E", "#24101E"],   # kraken plum
    "s": ["#D8C0CC", "#B898A8", "#8E7084", "#644C5C", "#32242E"],   # suckers, pale
    "i": ["#B8E0F0", "#88C0D8", "#5C98B4", "#3A6E88", "#1C3A4A"],   # glass, helm window
    "c": ["#C8D8D0", "#9EB4AA", "#7A9086", "#566A62", "#2C3632"],   # wet stone
    "r": ["#9A8E80", "#7A6E62", "#5A5048", "#3E3630", "#1E1A16"],   # iron, rust dark
    "y": ["#FFF4B0", "#FFE070", "#F0B83A", "#B07A22", "#5A3A12"],   # eye
}
FLAT = {
    "!": "#F6FFF8",   # glint
    "_": "#0A1418",   # dark inside things
    "*": "#8AF0E0",   # sea-glow
    "k": "#120A14",   # ink
}

# --------------------------------------------------------------------------
# Tiles.
# --------------------------------------------------------------------------
STONE = [hex_color(c) for c in ("#9CC2B4", "#86B0A2", "#72A092", "#5E8A7E", "#4A7266", "#34564C")]
WEED = [hex_color(c) for c in ("#6AA04A", "#4E8038", "#36602A")]
DEEP = [hex_color(c) for c in ("#2E6A7C", "#245C6E", "#1C4A5C", "#163C4C", "#10303C")]
SILT = [hex_color(c) for c in ("#8A9A7A", "#76866A", "#62705A")]
RIM = [hex_color(c) for c in ("#4A7266", "#34564C", "#20382F")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def floor_tile(seed):
    """Sunken flagstones, sea-green and worn smooth, barnacles in the joins."""
    rnd = random.Random(5100 + seed)
    px = blank(STONE[2] if seed != 2 else STONE[3])
    for i in range(T):
        px[0][i] = STONE[1]
        px[8][i] = STONE[4]
        px[9][i] = STONE[1]
    for y in range(T):
        split = 6 if y < 8 else 11
        px[y][(split + seed * 3) % T] = STONE[4]
    for _ in range(6):
        px[rnd.randrange(T)][rnd.randrange(T)] = rnd.choice((STONE[1], STONE[3], STONE[4]))
    if seed == 3:
        for (x, y) in ((3, 4), (4, 4), (12, 12)):
            px[y][x] = hex_color("#D8D0B8")
    return px


def wall_top(seed):
    """The church's walls from above: dressed blocks crusted with barnacles."""
    rnd = random.Random(5200 + seed)
    px = blank(STONE[4])
    for y in range(T):
        for x in range(T):
            if (x + (4 if y >= 8 else 0)) % 8 == 0 or y in (0, 8):
                px[y][x] = STONE[5]
            elif y in (1, 9):
                px[y][x] = STONE[3]
    for _ in range(5):
        px[rnd.randrange(T)][rnd.randrange(T)] = hex_color("#D8D0B8")
    return px


def wall_face(seed):
    """Wall face: green stone courses, a tide line and hanging weed."""
    rnd = random.Random(5300 + seed)
    px = blank(STONE[3])
    for course in range(4):
        y0 = course * 4
        shift = 3 if course % 2 else 0
        for y in range(y0, y0 + 4):
            for x in range(T):
                if (x + shift) % 7 == 6:
                    px[y][x] = STONE[5]
                elif y == y0:
                    px[y][x] = STONE[2]
    for x in range(T):
        px[9][x] = STONE[1]
    for _ in range(2 + seed):
        x = rnd.randrange(1, T - 1)
        for y in range(rnd.randrange(3, 9)):
            px[y][x] = WEED[y % 3]
    for x in range(T):
        px[T - 1][x] = STONE[5]
    return px


def deep_tile(frame):
    """Deep green water: dark, slow light moving across it."""
    px = blank(DEEP[2])
    for y in range(T):
        for x in range(T):
            if (x * 3 + y * 7 + frame * 5) % 23 == 0:
                px[y][x] = DEEP[1]
            elif (x * 5 - y * 2 + frame * 3) % 29 == 0:
                px[y][x] = DEEP[0]
            elif (x + y * 5 + frame) % 31 == 0:
                px[y][x] = DEEP[3]
    return px


def silt(seed):
    """Floor the low water has left: silt and puddles over the stones."""
    rnd = random.Random(5400 + seed)
    px = blank()
    for _ in range(5):
        cx, cy = rnd.randrange(2, 14), rnd.randrange(2, 14)
        for y in range(cy - 1, cy + 2):
            for x in range(cx - 2, cx + 3):
                if 0 <= x < T and 0 <= y < T and abs(x - cx) + abs(y - cy) < 3:
                    px[y][x] = SILT[rnd.randrange(3)]
    for _ in range(2):
        cx, cy = rnd.randrange(3, 13), rnd.randrange(3, 13)
        for x in range(cx - 2, cx + 2):
            px[cy][x] = hex_color("#3E7A8A", 200)
        px[cy - 1][cx - 1] = hex_color("#8AC0C8", 200)
    return px


def weed(seed):
    rnd = random.Random(5500 + seed)
    px = blank()
    x0 = 4 + seed * 6
    for i in range(3):
        x = x0 + i * 2
        for y in range(rnd.randrange(6, 11), 14):
            px[y][x + (y % 3 == 0)] = WEED[i % 3]
    return px


def shells(seed):
    px = blank()
    for (x, y) in (((4, 9), (9, 5)), ((7, 11), (12, 7)))[seed]:
        px[y][x] = hex_color("#E8D8C0")
        px[y][x + 1] = hex_color("#C0A890")
        px[y + 1][x] = hex_color("#A08870")
    return px


TILES = [
    ("belfry_floor_0", lambda: floor_tile(0)), ("belfry_floor_1", lambda: floor_tile(1)),
    ("belfry_floor_2", lambda: floor_tile(2)), ("belfry_floor_3", lambda: floor_tile(3)),
    ("belfry_top_0", lambda: wall_top(0)), ("belfry_top_1", lambda: wall_top(1)),
    ("belfry_face_0", lambda: wall_face(0)), ("belfry_face_1", lambda: wall_face(1)),
    ("deepwater_0", lambda: deep_tile(0)), ("deepwater_1", lambda: deep_tile(1)),
    ("lowwater_silt_0", lambda: silt(0)), ("lowwater_silt_1", lambda: silt(1)),
    ("seaweed_0", lambda: weed(0)), ("seaweed_1", lambda: weed(1)),
    ("seashell_0", lambda: shells(0)), ("seashell_1", lambda: shells(1)),
]


# --------------------------------------------------------------------------
# Sprite helpers.
# --------------------------------------------------------------------------
def canvas(w, h):
    return [["."] * w for _ in range(h)]


def rows_of(c):
    return ["".join(r) for r in c]


def put(c, x, y, m):
    if 0 <= y < len(c) and 0 <= x < len(c[0]):
        c[y][x] = m


def fill_ellipse(c, cx, cy, rx, ry, m):
    for y in range(len(c)):
        for x in range(len(c[0])):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                c[y][x] = m


def fill_rect(c, x, y, w, h, m):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            put(c, xx, yy, m)


def line(c, x0, y0, x1, y1, m, width=1):
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        x = round(x0 + (x1 - x0) * i / steps)
        y = round(y0 + (y1 - y0) * i / steps)
        for d in range(width):
            put(c, x + d, y, m)


# --------------------------------------------------------------------------
# Pieces.
# --------------------------------------------------------------------------
def helm_item():
    """The Diver's Helm: a round brass helmet with a glass window. 16x16."""
    c = canvas(16, 16)
    fill_ellipse(c, 7.5, 7.5, 6.6, 6.6, "g")
    fill_ellipse(c, 7.5, 7.5, 3.6, 3.4, "i")
    put(c, 6, 6, "!")
    for (x, y) in ((7, 1), (2, 7), (13, 7)):
        fill_rect(c, x, y, 2, 2, "v")
    fill_rect(c, 3, 13, 10, 3, "g")
    line(c, 3, 14, 12, 14, "v")
    return rows_of(c)


def grate():
    """A sunken iron grate standing up out of the water. 16x16."""
    c = canvas(16, 16)
    for x in (1, 5, 10, 14):
        line(c, x, 2, x, 15, "r")
    line(c, 0, 4, 15, 4, "r")
    line(c, 0, 10, 15, 10, "r")
    for x in (1, 5, 10, 14):
        put(c, x, 1, "v")
    return rows_of(c)


def valve(turned):
    """A great brass valve wheel on a stone post. 16x24, two frames."""
    c = canvas(16, 24)
    fill_rect(c, 5, 12, 6, 11, "c")
    fill_rect(c, 3, 21, 10, 3, "c")
    fill_ellipse(c, 7.5, 8, 7, 6, "g")
    fill_ellipse(c, 7.5, 8, 5, 4, ".")
    a0 = math.pi / 4 if turned else 0.0
    for i in range(4):
        a = a0 + i * math.pi / 2
        line(c, 8, 8, round(7.5 + math.cos(a) * 5.5), round(8 + math.sin(a) * 4.6), "g")
    fill_ellipse(c, 7.5, 8, 1.6, 1.4, "v")
    return rows_of(c)


def great_bell(rung):
    """The great bell Knell lives in: tipped on its lip, green with age, its
    mouth a black cave. 64x56, two frames (still, ringing)."""
    c = canvas(64, 56)
    for y in range(4, 50):
        t = (y - 4) / 45.0
        half = 10 + 16 * t + (6 * (t - 0.8) / 0.2 if t > 0.8 else 0)
        for x in range(int(32 - half), int(32 + half)):
            put(c, x, y, "v")
    fill_rect(c, 26, 1, 12, 4, "v")
    for y in (14, 38):
        for x in range(64):
            if c[y][x] == "v":
                c[y][x] = "g"
    # The mouth.
    fill_ellipse(c, 32, 50, 24, 5, "_")
    fill_ellipse(c, 32, 51, 20, 3.5, "k")
    if rung:
        for (x, y) in ((4, 18), (60, 16), (2, 30), (62, 32), (8, 8), (56, 6)):
            put(c, x, y, "!")
            put(c, x + 1, y + 1, "*")
    return rows_of(c)


def kraken(pose):
    """Knell: a plum kraken. 'peek' (one great eye in the bell's mouth),
    'out' (spilled from the bell, stunned, eye wide). 48x40."""
    c = canvas(48, 40)
    if pose == "peek":
        fill_ellipse(c, 24, 34, 12, 6, "p")
        fill_ellipse(c, 24, 33, 5, 4, "y")
        fill_rect(c, 23, 31, 2, 5, "k")
        for x in (12, 16, 31, 35):
            line(c, x, 38, x + (2 if x < 24 else -2), 33, "p")
        return rows_of(c)
    fill_ellipse(c, 24, 20, 16, 13, "p")
    fill_ellipse(c, 24, 14, 11, 7, "p")
    # Spots.
    for (x, y) in ((14, 12), (31, 10), (20, 7), (35, 18)):
        put(c, x, y, "s")
        put(c, x + 1, y, "s")
    # The eye, wide.
    fill_ellipse(c, 24, 21, 6.5, 5.5, "y")
    fill_ellipse(c, 24, 21, 2.5, 4, "k")
    put(c, 22, 19, "!")
    # Arms sprawled.
    for i, x in enumerate((6, 12, 18, 30, 36, 42)):
        line(c, 24 + (x - 24) // 3, 30, x, 38, "p", 2)
        put(c, x, 38, "s")
    # Stars: it's dazed.
    for (x, y) in ((8, 4), (40, 3), (24, 1)):
        put(c, x, y, "*")
    return rows_of(c)


def tentacle(pose):
    """A tentacle reared up out of the water. 16x40: 'up' (swaying),
    'rear' (drawn back, the tell), 'cut' (a stump)."""
    c = canvas(16, 40)
    if pose == "cut":
        fill_ellipse(c, 8, 36, 5, 3, "p")
        fill_ellipse(c, 8, 34, 3, 2, "s")
        return rows_of(c)
    lean = -3 if pose == "rear" else 2
    for y in range(4, 40):
        t = (40 - y) / 36.0
        x = 8 + lean * t * t * 2
        w = 2.8 - 1.8 * t
        for xx in range(int(x - w), int(x + w) + 1):
            put(c, xx, y, "p")
        if y % 4 == 0:
            put(c, int(x + w), y, "s")
    put(c, int(8 + lean * 2), 3, "p")
    return rows_of(c)


def ink_blob():
    """A glob of ink. 8x8."""
    c = canvas(8, 8)
    fill_ellipse(c, 3.5, 3.5, 3.2, 3.2, "k")
    put(c, 2, 2, "*")
    return rows_of(c)


def drowned_bell(rung):
    """The Drowned Bell, verdigris and shell-crusted, under a frame of coral
    stone. 32x40."""
    c = canvas(32, 40)
    fill_rect(c, 2, 5, 28, 3, "c")
    fill_rect(c, 3, 8, 3, 30, "c")
    fill_rect(c, 26, 8, 3, 30, "c")
    fill_rect(c, 1, 37, 8, 3, "c")
    fill_rect(c, 23, 37, 8, 3, "c")
    for y in range(10, 34):
        t = (y - 10) / 23.0
        half = 4 + 6 * t + (5 * (t - 0.75) / 0.25 if t > 0.75 else 0)
        for x in range(int(16 - half), int(16 + half)):
            put(c, x, y, "v")
    fill_rect(c, 15, 8, 2, 2, "g")
    for x in range(5, 27):
        if c[33][x] == "v":
            c[34][x] = "v"
    for y in (15, 28):
        for x in range(32):
            if c[y][x] == "v":
                c[y][x] = "g"
    # A spiral shell on its waist.
    for i in range(12):
        a = i * 0.7
        r = 0.5 + i * 0.28
        put(c, round(16 + math.cos(a) * r), round(21 + math.sin(a) * r), "s" if not rung else "*")
    fill_rect(c, 15, 34, 2, 3, "g")
    if rung:
        for x in range(32):
            if c[34][x] == "v":
                c[34][x] = "*"
        for (x, y) in ((4, 12), (27, 11), (2, 20), (29, 22)):
            put(c, x, y, "!")
    return rows_of(c)


def build(lit, sheet):
    """Everything in assets/belfry/, as {file name: pixels}."""
    return {
        "item_divers_helm": sheet([[lit(helm_item(), 110)]], 16, 16),
        "grate": sheet([[lit(grate(), 111)]], 16, 16),
        "valve": sheet([[lit(valve(False), 112), lit(valve(True), 112)]], 16, 24),
        "great_bell": sheet([[lit(great_bell(False), 113), lit(great_bell(True), 113)]], 64, 56),
        "knell": sheet([[lit(kraken("peek"), 114), lit(kraken("out"), 114)]], 48, 40),
        "tentacle": sheet([[lit(tentacle(p), 115) for p in ("up", "rear", "cut")]], 16, 40),
        "ink_blob": sheet([[lit(ink_blob(), 116)]], 8, 8),
        "drowned_bell": sheet([[lit(drowned_bell(False), 117), lit(drowned_bell(True), 117)]], 32, 40),
    }
