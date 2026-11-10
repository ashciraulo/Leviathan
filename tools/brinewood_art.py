"""Brinewood: mangrove forest and beached wrecks (plan palette: mangrove
#3E8E5E, deep teal #1F3D4A, new leaf #9FD36B, lantern amber #F2A541).

Tiles are RGBA 16x16 grids; props are material silhouettes that
build_art.lit() shades. Imported by build_art.py.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
# Peaty forest floor, mossy: low contrast so characters stand out.
PEAT = [hex_color(c) for c in ("#A8B87A", "#869C62", "#6C8452", "#566C48", "#40523E", "#2C3A34")]
LITTER = [hex_color(c) for c in ("#C89A5A", "#A8784A", "#7E5A40")]
LEAF = [hex_color(c) for c in ("#C8EC8A", "#9FD36B", "#5EA85E", "#3E8E5E", "#2A6A4E", "#1F3D4A", "#142A34")]
BARK = [hex_color(c) for c in ("#B8A890", "#8E7E6E", "#6A5A52", "#4A3E40", "#2E2630")]
BOG = [hex_color(c) for c in ("#8FC4A0", "#5E9E86", "#3E7A6E", "#2E5E58", "#22484A")]
BANK = hex_color("#3A3A30")
AMBER = hex_color("#F2A541")


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def peat_tile(seed):
    rnd = random.Random(100 + seed)
    px = blank(PEAT[2])
    # Moss clumps, a shade lighter, with dark undersides.
    for _ in range(3):
        cx, cy = rnd.randrange(T), rnd.randrange(T)
        for dy in range(-1, 2):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) < 3:
                    px[(cy + dy) % T][(cx + dx) % T] = PEAT[1]
        px[(cy - 1) % T][(cx - 1) % T] = PEAT[0]
        px[(cy + 2) % T][cx % T] = PEAT[3]
    for _ in range(6):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice([PEAT[1], PEAT[3]])
    # Fallen leaves: little two-pixel flecks in amber and brown.
    for _ in range(rnd.randrange(0, 2)):
        x, y = rnd.randrange(T - 1), rnd.randrange(T)
        c = rnd.choice(LITTER)
        px[y][x] = c
        px[y][x + 1] = LITTER[min(LITTER.index(c) + 1, 2)]
    return px


def canopy_tile(seed):
    """Wall top: a dense roof of mangrove leaves seen from above."""
    rnd = random.Random(200 + seed)
    px = blank(LEAF[4])
    for _ in range(9):
        cx, cy, r = rnd.randrange(-2, T + 2), rnd.randrange(-2, T + 2), rnd.choice((3, 3.5, 4))
        for y in range(T):
            for x in range(T):
                d = math.hypot(x - cx, y - cy)
                if d <= r:
                    lx, ly = x - cx, y - cy
                    if lx + ly < -r * 0.6:
                        c = LEAF[1]
                    elif lx + ly < 0:
                        c = LEAF[2]
                    elif d > r - 1:
                        c = LEAF[4]
                    else:
                        c = LEAF[3]
                    px[y][x] = c
    for _ in range(4):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = LEAF[0]
    return px


def roots_tile(seed):
    """Wall face: deep shade under the canopy, with a tangle of prop roots
    curving down out of it and splaying into the mud."""
    rnd = random.Random(300 + seed)
    px = blank(LEAF[6])
    for y in range(9, T):
        for x in range(T):
            px[y][x] = LEAF[5]
    # A few dim leaves back in the shade.
    for _ in range(5):
        px[rnd.randrange(4, 10)][rnd.randrange(T)] = LEAF[5]
    # Roots: from a knot or two up in the shade, prop roots splay out and
    # down like tent poles, lit on the left and shaded on the right. They run
    # off the tile's sides, so neighbouring tiles knit into one tangle.
    for apex in ((7 + seed * 5) % T,):
        for drift in (-7, -1, 6):
            for y in range(4, T - 1):
                t = (y - 4) / (T - 6)
                x = round(apex + drift * t ** 1.4)
                for dx, colour in ((0, BARK[1]), (1, BARK[3])):
                    px[y][(x + dx) % T] = colour
        # The knot the roots spring from.
        for dx in (-1, 0, 1):
            px[4][(apex + dx) % T] = BARK[2]
            px[3][(apex + dx) % T] = BARK[3]
    # Leaf fringe hanging over the top edge.
    for x in range(T):
        depth = 2 + (1 if (x * 7 + seed) % 5 < 2 else 0)
        for y in range(depth):
            px[y][x] = LEAF[3] if y == 0 else LEAF[4]
        if rnd.random() < 0.3:
            px[depth][x] = LEAF[4]
    # Mud with a little moss at the foot.
    for x in range(T):
        px[T - 1][x] = BARK[4] if px[T - 1][x] in BARK else (PEAT[4] if (x + seed) % 4 else PEAT[3])
    return px


def bog_tile(frame):
    px = blank(BOG[3])
    rnd = random.Random(400)
    for _ in range(16):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = BOG[4]
    # Duckweed specks drift slowly.
    for (x, y) in ((3, 2), (11, 4), (6, 9), (13, 12), (1, 13), (8, 14)):
        xx = (x + frame) % T
        px[y][xx] = LEAF[2]
        px[y][(xx + 1) % T] = LEAF[3]
    # A ripple ring that comes and goes.
    if frame == 1:
        for (dx, dy) in ((-2, 0), (2, 0), (-1, -1), (0, -1), (1, -1), (-1, 1), (0, 1), (1, 1)):
            px[7 + dy][9 + dx] = BOG[1]
    else:
        px[7][9] = BOG[1]
    return px


def bank_edge(side, frame):
    """Where bog meets peat: a dark muddy lip and a pale waterline."""
    px = blank()
    for i in range(T):
        lip = 1 + (1 if (i * 5 + frame * 3) % 7 < 3 else 0)
        for d in range(lip + 1):
            c = BANK if d < lip else BOG[1]
            if d == lip and (i + frame) % 3 == 0:
                c = BOG[0]
            if side == "top":
                px[d][i] = c
            elif side == "bottom":
                px[T - 1 - d][i] = c
            elif side == "left":
                px[i][d] = c
            else:
                px[i][T - 1 - d] = c
    return px


def mire_edge(side, seed):
    rnd = random.Random(500 + seed)
    px = blank()
    for i in range(T):
        depth = 2 + rnd.randrange(0, 3)
        for d in range(depth):
            c = (PEAT[4][0], PEAT[4][1], PEAT[4][2], 130 if d < depth - 1 else 60)
            if side == "top":
                px[d][i] = c
            elif side == "bottom":
                px[T - 1 - d][i] = c
            elif side == "left":
                px[i][d] = c
            else:
                px[i][T - 1 - d] = c
    return px


def fern(seed):
    rnd = random.Random(600 + seed)
    px = blank()
    cx = 6 + rnd.randrange(4)
    for frond, (dx, lean) in enumerate(((-1, -1), (0, 0), (1, 1), (-2, -1), (2, 1))):
        length = 6 - abs(dx)
        for i in range(length):
            x = cx + dx + (lean * i) // 2
            y = 14 - i
            if 0 <= x < T:
                px[y][x] = LEAF[2] if i > length - 3 else LEAF[3]
                if i % 2 and 0 <= x + lean < T:
                    px[y][x + (lean or 1)] = LEAF[1] if i > 2 else LEAF[3]
    return px


def reeds(seed):
    rnd = random.Random(700 + seed)
    px = blank()
    for blade in range(4):
        x = 4 + blade * 2 + rnd.randrange(2)
        h = rnd.randrange(7, 12)
        for i in range(h):
            px[14 - i][x] = LEAF[3] if i < h - 3 else LEAF[2]
        if blade % 2 == 0:
            # Cattail head.
            for i in range(3):
                px[14 - h - i + 2][x] = LITTER[2]
            px[14 - h][x] = LITTER[1]
    return px


def lily(seed):
    """A lily pad or two, drawn over bog water."""
    rnd = random.Random(900 + seed)
    px = blank()
    for _ in range(1 + seed):
        cx, cy = rnd.randrange(4, 12), rnd.randrange(4, 12)
        for y in range(-2, 3):
            for x in range(-3, 4):
                if (x / 3.2) ** 2 + (y / 2.2) ** 2 <= 1 and not (x > 0 and y == 0):
                    px[cy + y][cx + x] = LEAF[2] if x + y < 0 else LEAF[3]
        for x in (-1, 0, 1):
            px[cy + 2][cx + x] = LEAF[5]
        if seed == 1:
            px[cy - 1][cx - 1] = hex_color("#F4C0D8")
            px[cy - 1][cx] = hex_color("#FFFFFF")
    return px


def dapple(seed):
    """Soft canopy shadow cast on the forest floor."""
    rnd = random.Random(800 + seed)
    px = blank()
    shade = (LEAF[6][0], LEAF[6][1], LEAF[6][2], 50)
    for _ in range(2):
        r = rnd.choice((3, 4))
        cx, cy = rnd.randrange(r, T - r), rnd.randrange(r, T - r)
        for y in range(T):
            for x in range(T):
                if math.hypot(x - cx, (y - cy) * 1.3) <= r:
                    px[y][x] = shade
    return px


def boardwalk(vertical):
    """Weathered planks laid over the bog. A walkway running east-west has
    its boards across it (seams every 4 px), dark edges and a shadow on the
    water below; the north-south one is the same turned."""
    rnd = random.Random(1300 + vertical)
    wood = [hex_color(c) for c in ("#C8B08A", "#A8906E", "#8A7258", "#6A5446", "#3E3030")]
    px = [[CLEAR] * T for _ in range(T)]
    for a in range(T):          # along the walkway
        for b in range(2, 14):  # across it
            board = a // 4
            c = wood[1] if board % 2 == 0 else wood[2]
            if a % 4 == 3:
                c = wood[3]
            if b == 2:
                c = wood[0]
            if b == 13:
                c = wood[4]
            if b in (4, 11) and a % 4 == 1:
                c = wood[3]     # nail heads
            x, y = (b, a) if vertical else (a, b)
            px[y][x] = c
        if rnd.random() < 0.15:
            b = rnd.randrange(5, 10)
            x, y = (b, a) if vertical else (a, b)
            px[y][x] = wood[3]
    # Shadow cast on the water under the walkway's lower or right edge.
    for a in range(T):
        x, y = (14, a) if vertical else (a, 14)
        px[y][x] = (20, 34, 40, 120)
    return px


TILES = [
    ("lily_0", lambda: lily(0)), ("lily_1", lambda: lily(1)),
    ("dapple_0", lambda: dapple(0)), ("dapple_1", lambda: dapple(1)),
    ("peat_0", lambda: peat_tile(0)), ("peat_1", lambda: peat_tile(1)),
    ("peat_2", lambda: peat_tile(2)), ("peat_3", lambda: peat_tile(3)),
    ("canopy_0", lambda: canopy_tile(0)), ("canopy_1", lambda: canopy_tile(1)),
    ("roots_0", lambda: roots_tile(0)), ("roots_1", lambda: roots_tile(1)),
    ("bog_0", lambda: bog_tile(0)), ("bog_1", lambda: bog_tile(1)),
    ("fern_0", lambda: fern(0)), ("fern_1", lambda: fern(1)),
    ("reeds_0", lambda: reeds(0)), ("reeds_1", lambda: reeds(1)),
    ("bank_top_0", lambda: bank_edge("top", 0)), ("bank_bottom_0", lambda: bank_edge("bottom", 0)),
    ("bank_left_0", lambda: bank_edge("left", 0)), ("bank_right_0", lambda: bank_edge("right", 0)),
    ("bank_top_1", lambda: bank_edge("top", 1)), ("bank_bottom_1", lambda: bank_edge("bottom", 1)),
    ("bank_left_1", lambda: bank_edge("left", 1)), ("bank_right_1", lambda: bank_edge("right", 1)),
    ("mire_top", lambda: mire_edge("top", 1)), ("mire_bottom", lambda: mire_edge("bottom", 2)),
    ("mire_left", lambda: mire_edge("left", 3)), ("mire_right", lambda: mire_edge("right", 4)),
    ("boardwalk_h", lambda: boardwalk(0)), ("boardwalk_v", lambda: boardwalk(1)),
]

# --------------------------------------------------------------------------
# Props (material silhouettes; ramps registered by build_art).
# --------------------------------------------------------------------------
RAMPS = {
    "L": ["#C8EC8A", "#9FD36B", "#3E8E5E", "#2A6A4E", "#142A34"],   # mangrove leaves
    "B": ["#B8A890", "#8E7E6E", "#6A5A52", "#4A3E40", "#2E2630"],   # mangrove bark
    "h": ["#D8C8A8", "#A8987A", "#7A6E5E", "#52483E", "#2E2628"],   # sea-worn hull
    "v": ["#5E4E48", "#4A3E3A", "#3A302E", "#2A2224", "#1A1418"],   # inside a hull
    "i": ["#D8D0A0", "#A8A070", "#7A7A52", "#545A42", "#2E3430"],   # mudskipper skin
    "u": ["#8E7E5E", "#6E5E46", "#54463A", "#3A302A", "#221C1C"],   # bog mud
    "z": ["#B8D88A", "#86B86A", "#5E8E52", "#3E6648", "#22403A"],   # weed on wood
    "O": ["#E8DCE8", "#C4B4CC", "#9A88A8", "#6A5A80", "#2E2440"],   # moth wings, dusty
    "U": ["#8E7E6E", "#6E5E56", "#544848", "#3A3038", "#1E1824"],   # moth body, furry
}
FLAT = {"@": "#F2A541", "*": "#FFE36E"}  # lantern frame, lantern glow


def canvas(w, h):
    return [["."] * w for _ in range(h)]


def mangrove():
    """A mangrove, 48x64: a wide, low canopy on a short trunk that splits
    into arching prop roots."""
    c = canvas(48, 64)
    rnd = random.Random(9)

    def stroke(points, width):
        for (x, y) in points:
            for dx in range(width):
                xx, yy = int(round(x)) + dx, int(round(y))
                if 0 <= xx < 48 and 0 <= yy < 64:
                    c[yy][xx] = "B"

    # Prop roots: curves from the trunk out and down to the mud.
    for side in (-1, 1):
        for k in range(3):
            x0, y0 = 23 + side * 2, 36 + k * 4
            x2, y2 = 23 + side * (9 + k * 6), 61 - (k % 2)
            x1, y1 = 23 + side * (5 + k * 5), 33 + k * 3
            pts = []
            for i in range(41):
                t = i / 40
                pts.append(((1 - t) ** 2 * x0 + 2 * (1 - t) * t * x1 + t * t * x2,
                            (1 - t) ** 2 * y0 + 2 * (1 - t) * t * y1 + t * t * y2))
            stroke(pts, 2)
    # Trunk, leaning a little.
    for y in range(22, 46):
        lean = (46 - y) // 12
        for x in range(21 + lean, 27 + lean):
            c[y][x] = "B"
    # Canopy: a broad, low crown of leaf clumps.
    for (cx, cy, rx, ry) in ((24, 15, 22, 11), (11, 19, 10, 7), (37, 19, 10, 7), (17, 8, 10, 7), (31, 8, 10, 7)):
        for y in range(64):
            for x in range(48):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    c[y][x] = "L"
    # Notches along the crown's underside so it reads as clumps.
    for x in range(2, 46, 5):
        for y in range(63, 0, -1):
            if c[y][x] == "L":
                c[y][x] = "."
                if x + 1 < 48 and c[y][x + 1] == "L":
                    c[y][x + 1] = "."
                break
    for _ in range(30):
        x, y = rnd.randrange(4, 44), rnd.randrange(3, 24)
        if c[y][x] == "L" and c[y + 1][x] == "L" and c[y - 1][x] == "L" and c[y][x + 1] == "L":
            c[y][x] = "."
    return ["".join(r) for r in c]


def wreck():
    """A rowboat run aground, bow to the right, one side stove in. 48x32,
    seen from above at 3/4: the rim, the dark inside with seats, and the
    hull's side below."""
    c = canvas(48, 32)

    def half(x):
        t = (x - 4) / 40.0
        if t <= 0 or t >= 1:
            return 0
        # Blunt stern on the left, a sharper bow on the right.
        return 10 * math.sin(math.pi * t) ** (0.5 if t < 0.5 else 1.1)

    cy = 13
    for x in range(4, 45):
        w = half(x)
        top, bottom = round(cy - w * 0.6), round(cy + w * 0.6)
        for y in range(top, bottom + 1):
            c[y][x] = "h"
        # Hull side below the rim.
        for y in range(bottom + 1, min(31, bottom + 1 + max(0, round(w * 0.6)))):
            c[y][x] = "h"
        # Inside: everything but a 1-2 pixel rim.
        for y in range(top + 2, bottom):
            if 6 <= x <= 41 and w > 3:
                c[y][x] = "v"
    # Seats across the inside, and plank seams on the hull side.
    for sx in (13, 25):
        for y in range(4, 24):
            if c[y][sx] == "v":
                c[y][sx] = "h"
                c[y][sx + 1] = "h"
    for x in range(4, 45):
        w = half(x)
        bottom = round(cy + w * 0.6)
        if w > 3 and bottom + 3 < 32 and c[bottom + 3][x] == "h":
            c[bottom + 3][x] = "-"
    # Weed where the hull sits in the mud.
    for x in range(48):
        col = [y for y in range(32) if c[y][x] != "."]
        if col:
            for y in col[-2:]:
                c[y][x] = "z"
    # Stove-in planks on the near side.
    for (x, y) in ((30, 22), (31, 22), (32, 22), (33, 22), (31, 23), (32, 23), (30, 21), (33, 21), (34, 22)):
        if c[y][x] != ".":
            c[y][x] = "K"
    # A lantern left on the stern seat.
    for (x, y, m) in ((14, 9, "B"), (13, 10, "@"), (14, 10, "*"), (15, 10, "@"), (13, 11, "@"), (14, 11, "*"),
                      (15, 11, "@"), (13, 12, "B"), (14, 12, "B"), (15, 12, "B")):
        c[y][x] = m
    return ["".join(r) for r in c]


def lantern_post():
    """A hooked post with a hanging amber lantern, 16x32."""
    c = canvas(16, 32)
    for y in range(4, 30):
        c[y][6] = "B"
        c[y][7] = "B"
    for x in range(6, 12):
        c[4][x] = "B"
    c[5][11] = "B"
    for y in range(6, 12):
        for x in range(9, 14):
            c[y][x] = "@" if x in (9, 13) or y in (6, 11) else "*"
    c[5][10], c[5][12] = "B", "B"
    for x in range(5, 9):
        c[29][x] = "B"
    return ["".join(r) for r in c]


# --------------------------------------------------------------------------
# Bogskipper: an ambusher that lies in the mud with only its eyes showing.
# --------------------------------------------------------------------------
BOGSKIPPER = {
    "hidden": [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "....We....eW....",
        "....ee....ee....",
        "...uiiu..uiiu...",
        "..uuuuuuuuuuuu..",
        ".uuuuuuuuuuuuuu.",
        "..uuuuuuuuuuuu..",
        "................",
    ],
    "rise": [
        "................",
        "................",
        "................",
        ".....We..eW.....",
        ".....ee..ee.....",
        "....iiiiiiii....",
        "...iiiKKKKiii...",
        "...iiiiiiiiii...",
        "..uiiiiiiiiiiu..",
        ".uuuuuuuuuuuuuu.",
        "uuuuuuuuuuuuuuuu",
        ".uuuuuuuuuuuuuu.",
        "..uuuuuuuuuuuu..",
        "................",
    ],
    "body": [
        "................",
        "................",
        ".....We..eW.....",
        ".....ee..ee.....",
        "....iiiiiiii....",
        "...iiiiiiiiii...",
        "..iiiiiiiiiiii..",
        ".iiijjjjjjjjiii.",
        ".ii.ijjjjjji.ii.",
        "....iiiiiiii....",
        ".....iiiiii.....",
        "......iiii......",
        ".....ii..ii.....",
        "................",
    ],
}


# --------------------------------------------------------------------------
# Lanternmoth: a big dusty moth drawn to Wren's lantern. It circles, then
# its eye-spots flare amber (the tell) before it dives. 16x14.
# --------------------------------------------------------------------------
LANTERNMOTH = {
    "up": [
        "................",
        ".OO..........OO.",
        "OOOO........OOOO",
        "OO@OO......OO@OO",
        "OOOOOO.UU.OOOOOO",
        ".OOOOOOUUOOOOOO.",
        "..OOOOOUUOOOOO..",
        "...OOOOUUOOOO...",
        ".......UU.......",
        ".......UU.......",
        "................",
        "................",
        "................",
        "................",
    ],
    "down": [
        "................",
        "................",
        "................",
        "................",
        ".......UU.......",
        "...OOOOUUOOOO...",
        ".OOOOOOUUOOOOOO.",
        "OOO@OOOUUOOO@OOO",
        "OOOOOO.UU.OOOOOO",
        ".OOOO..UU..OOOO.",
        "..OO...UU...OO..",
        "................",
        "................",
        "................",
    ],
    "flare": [
        "................",
        "................",
        "OO............OO",
        "OOO..........OOO",
        "OO*OO..UU..OO*OO",
        "O***OO.UU.OO***O",
        "OO*OOOOUUOOOO*OO",
        ".OOOOOOUUOOOOOO.",
        "..OOOO.UU.OOOO..",
        ".......UU.......",
        "................",
        "................",
        "................",
        "................",
    ],
}
