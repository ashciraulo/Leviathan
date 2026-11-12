"""The Maw (the last dungeon): the inside of the Old One's head, where the
Choir sings. Gum-pink floors ridged like a palate, walls of great ivory
teeth and ribbed throat, pale glowing veins, and its pieces: Vael's sung
notes, the Dreaming Heart, and the dream-echoes of every boss.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes shaded by build_art.lit(), with this file's own
materials (RAMPS, FLAT). Imported by build_art.py, which writes the sprites
to assets/maw/.

Palette: gum #B8606A, deep flesh #5A2434, ivory #F0E4C8, vein glow
#8AF0E0, heart red #D04050.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)

RAMPS = {
    "f": ["#F0A0A8", "#D07884", "#B8606A", "#8A3E4C", "#5A2434"],   # flesh
    "h": ["#FF9A9A", "#F06070", "#D04050", "#902838", "#501420"],   # heart
    "t": ["#FFFFF4", "#F0E4C8", "#D0C0A0", "#A89474", "#6A5A44"],   # tooth, ivory
    "g": ["#E0E8F0", "#B8C0D0", "#8E98AC", "#646C80", "#363A48"],   # grey robe
    "n": ["#E0FFF8", "#A8F4E8", "#8AF0E0", "#4AB8A8", "#246860"],   # note glow
}
FLAT = {
    "!": "#FFFFFF",
    "_": "#200810",
    "*": "#8AF0E0",
    "-": "#7A3444",   # the ridge between a leech's rings
}

GUM = [hex_color(c) for c in ("#D88890", "#C87480", "#B8606A", "#A0505C", "#86404E", "#5A2434")]
IVORY = [hex_color(c) for c in ("#FFFAEC", "#F0E4C8", "#D8C8A8", "#B4A080", "#7A6A50")]
VEIN = [hex_color(c) for c in ("#C8FFF6", "#8AF0E0", "#4AB8A8")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def floor_tile(seed):
    """The palate: broad soft ridges of flesh, one to a tile, lit along
    their upper slope and shadowed down into the trough before the next,
    with wet glints on the crests and pores in the flesh between. The ridge
    is a wave that repeats every tile across, so it runs unbroken over the
    whole floor instead of stepping like brick."""
    rnd = random.Random(7100 + seed)
    px = blank(GUM[2])
    shade = {0: GUM[4], 1: GUM[3], 2: GUM[1], 3: GUM[1], 4: GUM[0], 14: GUM[3], 15: GUM[3]}
    for y in range(T):
        for x in range(T):
            a = x * math.pi / 8
            r = (y + int(round(1.4 * math.sin(a) + 0.6 * math.sin(2 * a + 1.0)))) % T
            if r in shade:
                px[y][x] = shade[r]
                if r == 4 and (x + seed * 5) % 4:
                    px[y][x] = GUM[1]
            if r == 3 and (x * 5 + seed * 3) % 13 == 0:
                px[y][x] = hex_color("#F8D0D4")     # a wet glint on the crest
    # Pores and soft mottling in the flesh between ridges.
    for _ in range(6):
        x, y = rnd.randrange(T), rnd.randrange(T)
        if px[y][x] == GUM[2]:
            px[y][x] = rnd.choice((GUM[3], GUM[3], GUM[1]))
    if seed == 3:
        # A short crease in the flesh.
        for x in range(5, 10):
            if px[10][x] == GUM[2]:
                px[10][x] = GUM[4]
                px[9][x] = GUM[1]
    return px


def wall_top(seed):
    """The Maw's walls from above: deep folds of flesh, a vein through them."""
    rnd = random.Random(7200 + seed)
    px = blank(GUM[4])
    for y in range(T):
        for x in range(T):
            if (x + y * 2 + seed * 5) % 9 in (0, 1):
                px[y][x] = GUM[5]
            elif (x + y * 2 + seed * 5) % 9 == 2:
                px[y][x] = GUM[3]
    if seed == 1:
        # Now and then a dim vein runs through the folds.
        x = 10
        for y in range(T):
            x = max(0, min(T - 1, x + rnd.choice((-1, 0, 0, 1))))
            px[y][x] = hex_color("#4AB8A8", 150)
    return px


def wall_face(seed):
    """Wall face: a row of great ivory teeth rising out of the gum."""
    px = blank(GUM[4])
    for i in range(2):
        cx = 4 + i * 8 + (1 if seed else 0)
        for y in range(1, 15):
            t = (y - 1) / 13.0
            half = 3.6 - 1.6 * (1 - t) ** 2
            for x in range(int(cx - half), int(cx + half) + 1):
                if 0 <= x < T:
                    shade = 1 if x < cx else 2
                    if y < 4:
                        shade = 0 if x < cx else 1
                    px[y][x] = IVORY[shade]
            if 0 <= int(cx + half) < T:
                px[y][int(cx + half)] = IVORY[3]
    for x in range(T):
        px[14][x] = GUM[3]
        px[15][x] = GUM[5]
    return px


def wet_floor(seed):
    """The palate floor just drained: darker, slick flesh with the last of
    the water shining in its ridges."""
    rnd = random.Random(7500 + seed)
    px = floor_tile(seed)
    for y in range(T):
        for x in range(T):
            c = px[y][x]
            px[y][x] = (int(c[0] * 0.82), int(c[1] * 0.8), int(c[2] * 0.85), 255)
    for _ in range(3):
        x, y = rnd.randrange(1, T - 4), rnd.randrange(1, T - 2)
        for dx in range(3):
            px[y][x + dx] = hex_color("#E8B0B8")
        px[y + 1][x + 1] = hex_color("#C87480")
    return px


def vein_deco(seed):
    """A glowing vein branching over the floor."""
    rnd = random.Random(7300 + seed)
    px = blank()
    x, y = 2 + seed * 5, 14
    while y > 2:
        px[y][x] = VEIN[1]
        if rnd.random() < 0.3 and x + 1 < T:
            px[y][x + 1] = VEIN[2]
        x = max(0, min(T - 1, x + rnd.choice((-1, 0, 1))))
        y -= 1
    px[y][x] = VEIN[0]
    return px


def dream_motes(seed):
    """Little drifting lights in the dark of the Maw."""
    px = blank()
    for (x, y) in (((3, 4), (11, 9), (7, 13)), ((12, 3), (5, 10)))[seed]:
        px[y][x] = VEIN[0]
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if 0 <= x + dx < T and 0 <= y + dy < T:
                px[y + dy][x + dx] = hex_color("#8AF0E0", 110)
    return px


TILES = [
    ("maw_floor_0", lambda: floor_tile(0)), ("maw_floor_1", lambda: floor_tile(1)),
    ("maw_floor_2", lambda: floor_tile(2)), ("maw_floor_3", lambda: floor_tile(3)),
    ("maw_top_0", lambda: wall_top(0)), ("maw_top_1", lambda: wall_top(1)),
    ("maw_face_0", lambda: wall_face(0)), ("maw_face_1", lambda: wall_face(1)),
    ("maw_wet_0", lambda: wet_floor(0)), ("maw_wet_1", lambda: wet_floor(1)),
    ("vein_0", lambda: vein_deco(0)), ("vein_1", lambda: vein_deco(1)),
    ("dreammote_0", lambda: dream_motes(0)), ("dreammote_1", lambda: dream_motes(1)),
]


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


def line(c, x0, y0, x1, y1, m, width=1):
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        x = round(x0 + (x1 - x0) * i / steps)
        y = round(y0 + (y1 - y0) * i / steps)
        for d in range(width):
            put(c, x + d, y, m)


def note(frame):
    """One of Vael's sung notes: a glowing note-head with a flag. 12x12."""
    c = canvas(12, 12)
    fill_ellipse(c, 4, 8.5, 3.2, 2.4, "n")
    line(c, 7, 2, 7, 8, "n")
    line(c, 7, 2, 10, 4 + frame, "n")
    put(c, 3, 7, "!")
    return rows_of(c)


def heart(beat):
    """The Dreaming Heart: a vast, lopsided heart of dream-flesh rising out
    of the floor of the Maw, its great vessels arching over it, its chambers
    lit from inside, glowing veins knotted across it. 64x56, two frames
    (rest, beat: swollen and brighter)."""
    c = canvas(64, 56)
    s = 1.06 if beat else 1.0
    # The body: a heavy lopsided mass, broad at the top, leaning.
    for y in range(8, 52):
        for x in range(64):
            dx = (x - 31) / (22 * s)
            dy = (y - 30) / (21 * s)
            lean = (y - 30) * 0.18
            dx2 = (x - 31 - lean) / (22 * s)
            if dx2 * dx2 + dy * dy * (1.0 + 0.5 * max(dy, 0)) <= 1.0:
                c[y][x] = "h"
    # A groove between the chambers.
    for y in range(14, 48):
        x = round(28 + (y - 14) * 0.35 + math.sin(y * 0.4) * 1.2)
        put(c, x, y, "f")
        put(c, x + 1, y, "_")
    # Great vessels: thick trunks curling out of the top and bending away.
    for (x0, dirx, length) in ((20, -1, 14), (34, 1, 16), (27, -1, 9)):
        for i in range(length):
            t = i / (length - 1.0)
            x = round(x0 + dirx * 10 * t * t)
            y = round(12 - 9 * math.sin(t * math.pi * 0.6))
            for w in range(-2, 3):
                put(c, x + w, y, "f")
                put(c, x + w, y + 1, "f")
    # A deep glow inside, seen through the flesh: where the grief lives.
    for r, m in ((9, "f"), (6, "n"), (3, "*" if beat else "n")):
        fill_ellipse(c, 33, 34, r * s * 1.1, r * s, m)
    for y in range(24, 44):
        for x in range(20, 46):
            if c[y][x] == "f" and ((x - 33) / 10.5) ** 2 + ((y - 34) / 9.5) ** 2 <= 1.0:
                c[y][x] = "h" if (x + y) % 2 else "f"
    # Glowing veins knotted across it.
    rnd = random.Random(7400)
    for start in ((14, 20), (44, 16), (30, 38), (20, 40)):
        x, y = start
        for _ in range(12):
            if c[y][x] == "h":
                put(c, x, y, "*" if beat else "n")
            x += rnd.choice((-1, 0, 1))
            y += rnd.choice((0, 1))
    # The flesh of the floor it rises from.
    fill_ellipse(c, 32, 52, 29, 4, "f")
    for x in range(6, 58, 5):
        put(c, x, 50, "_")
    if beat:
        for (x, y) in ((4, 14), (60, 10), (6, 36), (58, 38), (32, 0)):
            put(c, x, y, "*")
    return rows_of(c)


def chant_mark():
    """A singer's chant mark on the floor, where a chant wave starts. 16x8."""
    c = canvas(16, 8)
    fill_ellipse(c, 7.5, 4, 7, 3, "n")
    fill_ellipse(c, 7.5, 4, 5, 1.8, ".")
    return rows_of(c)


def gumleech(pose):
    """A Gumleech: a fat, ridged leech of the Old One's palate, pale as gum,
    with glowing spots down its back and a round mouth ringed with tiny
    teeth. It swims under the flood. 16x16, four poses:
    swim (only its back above the water), rise (reared, mouth open),
    bite (lunging flat out), stranded (left on the drained floor, flopped).

    Gum-pink flesh with dark ridges between its rings, so it reads as a
    leech and not a bone; the mouth an ivory ring of teeth round a dark
    hole; the glowing spots the Maw's own cyan."""
    c = canvas(16, 16)

    def ridges(xs, y0, y1):
        for x in xs:
            for y in range(y0, y1 + 1):
                if c[y][x] == "f":
                    c[y][x] = "-"

    def mouth(cx, cy, r):
        fill_ellipse(c, cx, cy, r + 0.9, r + 0.9, "t")
        fill_ellipse(c, cx, cy, r, r, "_")

    if pose == "swim":
        # A ridged hump breaking the surface, spots glowing.
        fill_ellipse(c, 7.5, 12, 6.0, 2.6, "f")
        for x in range(1, 15):
            put(c, x, 14, ".")
        ridges((4, 7, 10), 10, 13)
        put(c, 5, 10, "n")
        put(c, 8, 10, "n")
        put(c, 11, 11, "n")
        return rows_of(c)
    if pose == "rise":
        # Reared up out of the water, the mouth a ring of teeth facing Wren.
        for y in range(3, 15):
            t = (y - 3) / 11.0
            half = 3.0 + 2.4 * t
            for x in range(int(8 - half), int(8 + half + 0.5)):
                put(c, x, y, "f")
        for y in (7, 10, 13):
            for x in range(16):
                if c[y][x] == "f":
                    c[y][x] = "-"
        mouth(7.5, 4.5, 1.9)
        put(c, 5, 8, "n")
        put(c, 10, 9, "n")
        put(c, 6, 11, "n")
        return rows_of(c)
    if pose == "bite":
        # Stretched out flat along the floor, mouth wide at the front.
        fill_ellipse(c, 7.5, 10, 7.0, 3.2, "f")
        ridges((3, 6, 9), 7, 13)
        mouth(12.5, 10, 1.8)
        for x in (4, 7, 10):
            put(c, x, 8, "n")
        return rows_of(c)
    # Stranded: flopped on its side on the wet floor, curled, spots dim.
    fill_ellipse(c, 8.5, 11, 6.5, 2.8, "f")
    ridges((7, 10, 13), 9, 13)
    mouth(3.5, 10, 1.3)
    for x in (8, 11):
        put(c, x, 9, "g")
    return rows_of(c)


def build(lit, sheet):
    """Everything in assets/maw/, as {file name: pixels}."""
    return {
        "note": sheet([[lit(note(0), 130), lit(note(1), 130)]], 12, 12),
        "dreaming_heart": sheet([[lit(heart(False), 131), lit(heart(True), 131)]], 64, 56),
        "chant_mark": sheet([[lit(chant_mark(), 132)]], 16, 8),
        "gumleech": sheet([[lit(gumleech(p), 133) for p in ("swim", "rise", "bite", "stranded")]], 16, 16),
    }
