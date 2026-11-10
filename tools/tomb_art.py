"""The Marrow Tomb (the Ossuary Dunes' dungeon): a barrow dug among the
bones of the Old One's kin. Sand-pale floors, walls stacked from vertebrae
and skulls, and its pieces: the Echo Horn, bone barricades, singing skulls,
Marrowguards with their bone shields, the Hush (a spirit nobody sees until
an echo finds it), the Hollow Regent and his armour, and the Marrow Bell.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes shaded by build_art.lit(), with this file's own
materials (RAMPS, FLAT). Imported by build_art.py, which writes the sprites
to assets/tomb/.

Palette: sandstone #C8A878, bone #E8DCC0, umber shadow #4A3428,
marrow red #9A3A2E, echo teal #8AF0E0.
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
    "b": ["#FFF8E8", "#E8DCC0", "#C8B494", "#9A8468", "#5A4A38"],   # bone
    "o": ["#E8C88A", "#C8A060", "#9A7440", "#6A4C2A", "#3A2814"],   # old bone, yellowed
    "m": ["#E07A60", "#C0503E", "#9A3A2E", "#6A2420", "#3A1210"],   # marrow red
    "g": ["#F4E0A0", "#D8A84A", "#B07E2E", "#7A5420", "#3A2810"],   # gold
    "h": ["#D0F8F0", "#A0E8DC", "#70C8BC", "#48988E", "#24544E"],   # hush, pale spirit
    "r": ["#8A7A6A", "#6A5A4C", "#4E4038", "#362C26", "#1C1612"],   # dark iron
}
FLAT = {
    "!": "#FFFFF4",   # glint
    "_": "#1A1210",   # dark inside things
    "*": "#8AF0E0",   # echo glow
    "e": "#FF5A3A",   # ember eyes
}

# --------------------------------------------------------------------------
# Tiles.
# --------------------------------------------------------------------------
SAND = [hex_color(c) for c in ("#E4CC9C", "#D4BA88", "#C8A878", "#B49464", "#967A52", "#6E5838")]
BONE = [hex_color(c) for c in ("#F6EEDA", "#E8DCC0", "#CCBC9C", "#A89478", "#7A6A54")]
UMBER = [hex_color(c) for c in ("#6E5442", "#5A4434", "#4A3428", "#34241C", "#20160F")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def floor_tile(seed):
    """Packed sand over flagstones. One even sand on every variant (no
    lighter tile to checker the floor), scattered grit, now and then the
    edge of a buried flagstone showing through in a short broken line, and
    a chip of bone here and there."""
    rnd = random.Random(6100 + seed)
    base = SAND[2]
    px = blank(base)
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((SAND[1], SAND[1], SAND[3], SAND[3], SAND[0]))
    # Soft drifts: a few lighter, wind-laid streaks.
    for _ in range(2):
        y = rnd.randrange(2, T - 2)
        x0 = rnd.randrange(0, 10)
        for x in range(x0, min(T, x0 + rnd.randrange(3, 6))):
            if px[y][x] == base:
                px[y][x] = SAND[1]
    # A buried flagstone's edge, half covered: a broken line, an L at most.
    if seed in (0, 2):
        y = rnd.randrange(4, 12)
        x0, x1 = rnd.randrange(1, 5), rnd.randrange(9, 15)
        for x in range(x0, x1):
            if rnd.random() < 0.75:
                px[y][x] = SAND[4]
                if px[y + 1][x] == base:
                    px[y + 1][x] = SAND[1]
        if seed == 2:
            for yy in range(y - rnd.randrange(2, 4), y):
                px[yy][x0] = SAND[4]
    if seed == 3:
        for (x, y) in ((5, 6), (6, 6), (7, 7), (11, 11)):
            px[y][x] = BONE[1]
        px[7][6] = BONE[3]
    return px


def wall_top(seed):
    """The barrow's walls from above: stacked long bones, ends outward."""
    px = blank(UMBER[2])
    for y in range(T):
        for x in range(T):
            row = y // 4
            if y % 4 == 0:
                px[y][x] = UMBER[3]
            elif (x + row * 5 + seed * 3) % 8 in (0, 1, 2, 3, 4, 5):
                px[y][x] = BONE[3] if y % 4 == 1 else BONE[4]
    # Knuckle ends of the bones.
    for row in range(4):
        x = (row * 5 + seed * 3 + 6) % 8
        for xx in (x, x + 8):
            if xx < T:
                px[row * 4 + 1][xx] = BONE[2]
                px[row * 4 + 3][xx] = BONE[2]
    return px


def wall_face(seed):
    """Wall face: an ossuary wall of skulls and vertebrae set in umber."""
    px = blank(UMBER[1])
    # A course of vertebrae along the top.
    for x in range(T):
        px[0][x] = UMBER[3]
        px[1][x] = BONE[3] if x % 4 else UMBER[2]
        px[2][x] = BONE[2] if x % 4 else UMBER[2]
        px[3][x] = BONE[3] if x % 4 else UMBER[3]
    # A skull, its sockets dark.
    cx = 7 if seed == 0 else 9
    for y in range(5, 12):
        for x in range(T):
            d = ((x - cx) / 4.6) ** 2 + ((y - 8) / 3.6) ** 2
            if d <= 1.0:
                px[y][x] = BONE[1] if y < 8 else BONE[2]
    for (x, y) in ((cx - 2, 8), (cx + 2, 8), (cx - 1, 8), (cx + 1, 8)):
        px[y][x] = UMBER[4]
    px[10][cx] = UMBER[3]
    px[6][cx - 2] = BONE[0]
    # Long bones under it.
    for x in range(T):
        px[13][x] = BONE[3] if (x + seed) % 6 else UMBER[2]
        px[14][x] = BONE[4] if (x + seed) % 6 else UMBER[3]
        px[15][x] = UMBER[4]
    return px


def bone_chips(seed):
    """A scatter of small bones in the sand."""
    px = blank()
    spots = (((3, 10), (11, 4)), ((8, 12), (4, 3)))[seed]
    for (x, y) in spots:
        for i in range(4):
            px[y][x + i] = BONE[1] if i in (0, 3) else BONE[2]
        px[y + 1][x] = BONE[3]
        px[y + 1][x + 3] = BONE[3]
    return px


def ribs(seed):
    """Great ribs half sunk in the floor, curving up out of the sand."""
    px = blank()
    for i in range(3):
        x0 = 2 + i * 5 + seed
        for y in range(4, 15):
            t = (y - 4) / 10.0
            x = x0 + round(2 * math.sin(t * 2.4))
            if 0 <= x < T:
                px[y][x] = BONE[1] if y < 9 else BONE[2]
                if x + 1 < T:
                    px[y][x + 1] = BONE[3]
        px[14][x0] = SAND[4]
    return px


TILES = [
    ("tomb_floor_0", lambda: floor_tile(0)), ("tomb_floor_1", lambda: floor_tile(1)),
    ("tomb_floor_2", lambda: floor_tile(2)), ("tomb_floor_3", lambda: floor_tile(3)),
    ("tomb_top_0", lambda: wall_top(0)), ("tomb_top_1", lambda: wall_top(1)),
    ("tomb_face_0", lambda: wall_face(0)), ("tomb_face_1", lambda: wall_face(1)),
    ("bonechips_0", lambda: bone_chips(0)), ("bonechips_1", lambda: bone_chips(1)),
    ("ribs_0", lambda: ribs(0)), ("ribs_1", lambda: ribs(1)),
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


def skull(c, cx, cy, rx, ry, m="b"):
    """A skull's dome and jaw, sockets cut out."""
    fill_ellipse(c, cx, cy, rx, ry, m)
    fill_rect(c, round(cx - rx * 0.6), round(cy + ry * 0.6), round(rx * 1.2) + 1, max(1, round(ry * 0.5)), m)
    sx = max(1, round(rx * 0.4))
    put(c, round(cx - sx), round(cy + ry * 0.15), "_")
    put(c, round(cx + sx), round(cy + ry * 0.15), "_")
    if rx > 4:
        put(c, round(cx - sx) + 1, round(cy + ry * 0.15), "_")
        put(c, round(cx + sx) - 1, round(cy + ry * 0.15), "_")


# --------------------------------------------------------------------------
# Pieces.
# --------------------------------------------------------------------------
def horn_item():
    """The Echo Horn: a curled horn of old bone, bound in gold. 16x16."""
    c = canvas(16, 16)
    for i in range(22):
        t = i / 21.0
        a = math.pi * 0.9 + t * math.pi * 1.4
        r = 5.5 - t * 2.5
        x = 8 + math.cos(a) * r
        y = 8 + math.sin(a) * r * 0.9
        w = 1.0 + (1 - t) * 2.2
        for dx in range(-int(w), int(w) + 1):
            for dy in range(-int(w), int(w) + 1):
                if dx * dx + dy * dy <= w * w:
                    put(c, round(x + dx), round(y + dy), "o")
    # The bell of the horn, open and dark.
    fill_ellipse(c, 3, 9, 2.4, 3.0, "o")
    fill_ellipse(c, 2.6, 9, 1.2, 1.8, "_")
    for (x, y) in ((6, 3), (11, 4), (12, 9)):
        put(c, x, y, "g")
        put(c, x + 1, y, "g")
    put(c, 7, 2, "!")
    return rows_of(c)


def barricade():
    """A barricade of piled bones filling a passage. 16x24."""
    c = canvas(16, 24)
    rnd = random.Random(6201)
    for i in range(14):
        y = 23 - i * 1.4
        x0 = rnd.randrange(0, 6)
        x1 = rnd.randrange(10, 16)
        line(c, x0, round(y), x1, round(y - rnd.randrange(-2, 3)), "b" if i % 3 else "o", 2)
    skull(c, 5, 12, 3.2, 2.8)
    skull(c, 11, 6, 2.8, 2.4, "o")
    skull(c, 9, 18, 3.0, 2.6)
    # Cracks: the echo will find them.
    line(c, 7, 2, 9, 9, "_")
    line(c, 9, 9, 7, 15, "_")
    return rows_of(c)


def singing_skull(singing):
    """A skull on a little cairn. Singing, its sockets glow. 16x20."""
    c = canvas(16, 20)
    fill_ellipse(c, 8, 16, 7, 3.5, "o")
    fill_ellipse(c, 8, 15, 5, 2.5, "b")
    skull(c, 8, 8, 5, 4.4)
    eye = "*" if singing else "_"
    for (x, y) in ((5, 9), (6, 9), (10, 9), (11, 9), (5, 8), (11, 8)):
        put(c, x, y, eye)
    fill_rect(c, 7, 12, 3, 2, "_" if not singing else "*")
    if singing:
        for (x, y) in ((1, 3), (14, 2), (0, 9), (15, 10)):
            put(c, x, y, "*")
    return rows_of(c)


def marrowguard(shield, step):
    """A Marrowguard: a skeleton sentry of yellowed bone with a spear, its
    shield a great shoulder-blade. 16x24, facing down (toward the viewer)."""
    c = canvas(16, 24)
    sx = 1 if step else -1
    # Legs.
    line(c, 6, 16, 6 - sx, 22, "o")
    line(c, 9, 16, 9 + sx, 22, "o")
    # Pelvis and spine.
    fill_rect(c, 5, 15, 6, 2, "o")
    line(c, 8, 8, 8, 15, "b")
    # Ribs.
    for y in (9, 11, 13):
        line(c, 5, y, 11, y, "b")
    # Arms.
    line(c, 4, 9, 3, 15, "o")
    line(c, 12, 9, 13, 14, "o")
    # Spear.
    line(c, 14, 1, 14, 22, "r")
    fill_rect(c, 13, 0, 3, 2, "r")
    put(c, 14, 0, "!")
    # Skull with ember eyes.
    skull(c, 8, 4.5, 3.6, 3.2)
    put(c, 7, 5, "e")
    put(c, 9, 5, "e")
    if shield:
        # The shoulder-blade shield held across the body.
        fill_ellipse(c, 6, 13, 4.5, 6.5, "b")
        line(c, 3, 9, 8, 18, "o")
        put(c, 5, 10, "!")
    return rows_of(c)


def hush(frame):
    """The Hush: a hooded, faceless spirit of the barrow, trailing off to
    nothing. 16x20. Drawn faint until an echo shows it."""
    c = canvas(16, 20)
    sway = (-1, 1)[frame]
    for y in range(3, 19):
        t = (y - 3) / 15.0
        w = 4.5 + 1.5 * math.sin(t * 3.0)
        x = 8 + sway * t * 1.5
        for xx in range(int(x - w), int(x + w) + 1):
            put(c, xx, y, "h")
    # Trailing wisps at the bottom.
    for x in range(3, 14, 3):
        put(c, x + sway, 19, ".")
        put(c, x + sway, 18, ".")
    # Hood and its dark hollow.
    fill_ellipse(c, 8, 5, 4.4, 4, "h")
    fill_ellipse(c, 8, 6, 2.6, 2.4, "_")
    put(c, 7, 6, "*")
    put(c, 9, 6, "*")
    # Long arms reaching.
    line(c, 3, 9, 1, 14 + frame, "h")
    line(c, 13, 9, 15, 14 + (1 - frame), "h")
    return rows_of(c)


def regent(pose):
    """The Hollow Regent: a king built from leviathan bones, a whale's skull
    for a head, a crown of teeth, a sceptre of spine. Without his armour his
    ribs stand open on the red marrow-light inside. 64x64.
    Poses: 'stand', 'raise' (sceptre up: the slam tell), 'slam', 'open'
    (armour gone, staggering), 'throw' (his free hand high with a fistful
    of bone, the marrow-light flaring: the throw tell)."""
    c = canvas(64, 64)
    # Legs: great thigh bones.
    for x0 in (24, 37):
        line(c, x0, 44, x0 - 2 if x0 < 32 else x0 + 2, 61, "o", 3)
        fill_ellipse(c, x0 + (-2 if x0 < 32 else 3), 62, 4, 1.6, "o")
    # Pelvis.
    fill_ellipse(c, 32, 44, 11, 4, "o")
    # Ribcage and the marrow-light in it.
    fill_ellipse(c, 32, 33, 13, 11, "_")
    fill_ellipse(c, 32, 34, 5, 5, "m")
    if pose in ("open", "throw"):
        fill_ellipse(c, 32, 34, 7, 7, "m")
        fill_ellipse(c, 32, 33, 3, 3, "!")
    for i, y in enumerate((25, 29, 33, 37, 41)):
        half = 12 - abs(i - 2) * 1.6
        for side in (-1, 1):
            line(c, 32, y - 1, round(32 + side * half), y + 2, "b", 1)
    line(c, 32, 22, 32, 45, "b", 2)
    # Arms.
    if pose == "raise":
        line(c, 20, 25, 12, 14, "o", 2)
        line(c, 12, 14, 10, 4, "o", 2)
        sceptre = (8, 0, 14, 22)
    elif pose == "slam":
        line(c, 20, 25, 10, 32, "o", 2)
        line(c, 10, 32, 6, 42, "o", 2)
        sceptre = (2, 58, 8, 36)
    else:
        line(c, 20, 25, 14, 36, "o", 2)
        line(c, 14, 36, 13, 44, "o", 2)
        sceptre = (12, 60, 14, 26)
    if pose == "throw":
        # The free arm drawn back high, a fistful of bone shards in it.
        line(c, 44, 25, 53, 15, "o", 2)
        line(c, 53, 15, 56, 5, "o", 2)
        for (x, y) in ((54, 2), (57, 1), (59, 4), (56, 4)):
            line(c, x, y, x + 1, y - 1, "b", 1)
            put(c, x, y + 1, "o")
    else:
        line(c, 44, 25, 50, 36, "o", 2)
        line(c, 50, 36, 51, 44, "o", 2)
    # Sceptre: a length of vertebrae with a skull on top.
    x0, y0, x1, y1 = sceptre
    line(c, x0, y0, x1, y1, "b", 2)
    steps = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(0, steps, 3):
        put(c, round(x0 + (x1 - x0) * i / steps) - 1, round(y0 + (y1 - y0) * i / steps), "o")
    skull(c, x1 + 1, y1 - 2, 3.5, 3.0)
    # Head: a long whale's skull, broad and heavy, its jaw hanging open on
    # a row of peg teeth; ember light deep in the sockets.
    fill_ellipse(c, 32, 13, 12, 6.5, "b")
    fill_ellipse(c, 32, 10, 9, 3.5, "b")
    fill_rect(c, 22, 15, 20, 3, "_")
    for x in range(23, 42, 3):
        put(c, x, 15, "b")
        put(c, x, 16, "b")
    fill_rect(c, 24, 18, 16, 3, "b")
    fill_rect(c, 24, 20, 16, 1, "o")
    for x in range(25, 40, 3):
        put(c, x, 17, "b")
    for cx in (26, 38):
        fill_ellipse(c, cx, 11, 2.6, 2.0, "_")
        put(c, cx, 11, "e")
        put(c, cx + (1 if cx < 32 else -1), 11, "e")
    line(c, 32, 8, 32, 13, "o")
    put(c, 29, 8, "!")
    # Crown of teeth.
    for i, x in enumerate(range(24, 41, 3)):
        h = 4 + (2 if i % 2 else 0)
        line(c, x, 8, x, 8 - h, "g")
        put(c, x, 8 - h, "!")
    line(c, 23, 8, 41, 8, "g")
    if pose == "open":
        # Staggering: dust and stars.
        for (x, y) in ((6, 10), (56, 12), (50, 4), (14, 2)):
            put(c, x, y, "*")
    return rows_of(c)


def armour(piece):
    """One piece of the Regent's bone armour. 28x22.
    'left', 'right' (pauldrons of whale vertebra, on his shoulders), 'breast'
    (a breastplate of fused skull-plates over his ribs)."""
    c = canvas(28, 22)
    if piece == "breast":
        fill_ellipse(c, 13.5, 11, 11, 9.5, "o")
        fill_ellipse(c, 13.5, 10, 9, 7.5, "b")
        for x in (7, 14, 20):
            line(c, x, 3, x, 19, "o")
        line(c, 4, 11, 23, 11, "o")
        fill_ellipse(c, 13.5, 11, 2, 2, "g")
        put(c, 9, 5, "!")
        return rows_of(c)
    flip = piece == "right"
    fill_ellipse(c, 14, 14, 8, 5.5, "o")
    fill_ellipse(c, 14, 13, 6.5, 4, "b")
    # Spines along it.
    for i in range(4):
        x = 9 + i * 3
        line(c, x, 10, x + (2 if flip else -2), 6, "b")
        put(c, x + (2 if flip else -2), 6, "!")
    line(c, 7, 15, 21, 15, "o")
    if flip:
        c = [list(reversed(r)) for r in c]
    return rows_of(c)


def bone_shard():
    """A shard of bone the Regent throws. 8x8."""
    c = canvas(8, 8)
    line(c, 1, 6, 6, 1, "b", 2)
    put(c, 6, 1, "!")
    put(c, 1, 6, "o")
    return rows_of(c)


def marrow_bell(rung):
    """The Marrow Bell: a bell of pale bone, hung from two ribs. 32x40."""
    c = canvas(32, 40)
    # Two great ribs arching over it.
    for side in (-1, 1):
        for y in range(4, 39):
            t = (y - 4) / 34.0
            x = 16 + side * (4 + 10 * math.sin(t * math.pi * 0.55 + 0.35))
            put(c, round(x), y, "b")
            put(c, round(x) + side, y, "o")
    fill_rect(c, 8, 37, 5, 3, "o")
    fill_rect(c, 19, 37, 5, 3, "o")
    for y in range(9, 32):
        t = (y - 9) / 22.0
        half = 3 + 5 * t + (4 * (t - 0.75) / 0.25 if t > 0.75 else 0)
        for x in range(int(16 - half), int(16 + half)):
            put(c, x, y, "b")
    line(c, 16, 4, 16, 9, "o")
    for y in (14, 26):
        for x in range(32):
            if c[y][x] == "b" and 6 < x < 26:
                c[y][x] = "o"
    fill_rect(c, 15, 32, 2, 3, "m" if not rung else "*")
    if rung:
        for (x, y) in ((3, 12), (28, 11), (1, 22), (30, 24)):
            put(c, x, y, "*")
            put(c, x, y - 1, "!")
    return rows_of(c)


def build(lit, sheet):
    """Everything in assets/tomb/, as {file name: pixels}."""
    return {
        "item_echo_horn": sheet([[lit(horn_item(), 120)]], 16, 16),
        "barricade": sheet([[lit(barricade(), 121)]], 16, 24),
        "singing_skull": sheet([[lit(singing_skull(False), 122), lit(singing_skull(True), 122)]], 16, 20),
        "marrowguard": sheet([[lit(marrowguard(s, f), 123) for s in (True, False) for f in (0, 1)]], 16, 24),
        "hush": sheet([[lit(hush(0), 124), lit(hush(1), 124)]], 16, 20),
        "regent": sheet([[lit(regent(p), 125) for p in ("stand", "raise", "slam", "open", "throw")]], 64, 64),
        "regent_armour": sheet([[lit(armour(p), 126) for p in ("left", "right", "breast")]], 28, 22),
        "bone_shard": sheet([[lit(bone_shard(), 127)]], 8, 8),
        "marrow_bell": sheet([[lit(marrow_bell(False), 128), lit(marrow_bell(True), 128)]], 32, 40),
    }
