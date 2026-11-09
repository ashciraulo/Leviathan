"""The Rotting Hull's dungeon pieces: deck gaps, hook posts, crates, plates,
bars, the big-key door, the Tide Hook, dungeon items, the Barnacle Matriarch
and the first Tidebell.

Sprites are material silhouettes that build_art.lit() shades. Gap tiles are
RGBA 16x16 grids added to the world tile sheet. Imported by build_art.py,
which writes everything here to assets/dungeon/.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)

# --------------------------------------------------------------------------
# Materials (ramps run highlight, light, base, shadow, outline).
# --------------------------------------------------------------------------
RAMPS = {
    "A": ["#F2A08A", "#D2665A", "#A2424A", "#6E2C46", "#341832"],   # crab shell, coral red
    "F": ["#FFF8E8", "#EADCC4", "#C8B49C", "#8E7A78", "#40303E"],   # figurehead paint
    "M": ["#FFE8A0", "#E8B85A", "#B8843E", "#7A5032", "#3A2226"],   # gilt
    "Y": ["#FFD4D8", "#F2A4B4", "#D07892", "#9A5274", "#4A2440"],   # soft body
    "P": ["#8E6E58", "#6E5446", "#54403A", "#3C2C2E", "#1E1418"],   # old hull plank
    "R": ["#E89A5A", "#B86A3E", "#8A4A34", "#5A3030", "#2A1820"],   # rust
    "X": ["#B8D88A", "#86B06A", "#5A8A56", "#3A6048", "#1E3430"],   # weed and slime
    "V": ["#C8F0D8", "#86CCB4", "#4E9C8E", "#2E6A6A", "#163638"],   # verdigris bronze
    "Z": ["#FFFFFF", "#F6EEDC", "#D8CCD6", "#A898B0", "#4E405E"],   # barnacle white
}
FLAT = {
    "1": "#1A1020",   # eye black
    "2": "#FFF4D6",   # eye glint
    "3": "#120C18",   # deep shadow inside things
    "4": "#FFE36E",   # glow
}


def canvas(w, h):
    return [["."] * w for _ in range(h)]


def rows_of(c):
    return ["".join(r) for r in c]


def put(c, x, y, m):
    if 0 <= y < len(c) and 0 <= x < len(c[0]):
        c[y][x] = m


def fill_ellipse(c, cx, cy, rx, ry, m, only=None):
    for y in range(len(c)):
        for x in range(len(c[0])):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                if only is None or c[y][x] in only:
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
# Gaps in the deck (tiles). The hole drops into the dark bilge below; the
# far side (top) shows broken plank ends, the sides splinter.
# --------------------------------------------------------------------------
VOID = [hex_color(c) for c in ("#140E16", "#0C080E", "#1E1820", "#26303A")]
PLANK_END = [hex_color(c) for c in ("#6E5446", "#54403A", "#3C2C2E", "#24181C")]


def gap_tile(seed):
    rnd = random.Random(900 + seed)
    px = [[VOID[1]] * T for _ in range(T)]
    # Far below: a faint glint of bilge water.
    for _ in range(3):
        x, y = rnd.randrange(2, T - 3), rnd.randrange(6, T - 2)
        px[y][x] = VOID[3]
        px[y][x + 1] = VOID[2]
    return px


def gap_lip():
    """The far edge: plank ends seen face on, splintered at the bottom."""
    px = [[CLEAR] * T for _ in range(T)]
    rnd = random.Random(910)
    for x in range(T):
        depth = 4 + (1 if x % 5 in (1, 2) else 0) + rnd.choice((0, 0, 1))
        for y in range(depth):
            if y == 0:
                px[y][x] = PLANK_END[0]
            elif y < depth - 1:
                px[y][x] = PLANK_END[1] if (x // 4) % 2 == 0 else PLANK_END[2]
            else:
                px[y][x] = PLANK_END[3]
        # Shadow cast down into the hole.
        for y in range(depth, depth + 3):
            px[y][x] = hex_color("#000000", 110 - (y - depth) * 30)
    for x in range(0, T, 4):
        px[1][x] = PLANK_END[3]
        px[2][x] = PLANK_END[3]
    return px


def gap_side(side):
    """Splintered plank ends along the left, right or near (bottom) edge."""
    px = [[CLEAR] * T for _ in range(T)]
    rnd = random.Random({"left": 920, "right": 921, "bottom": 922}[side])
    for i in range(T):
        reach = rnd.choice((1, 1, 2, 2, 3))
        for d in range(reach):
            col = PLANK_END[0] if d == reach - 1 else PLANK_END[1]
            if side == "left":
                px[i][d] = col
            elif side == "right":
                px[i][T - 1 - d] = col
            else:
                px[T - 1 - d][i] = PLANK_END[0] if d == 0 else PLANK_END[1]
    return px


TILES = [
    ("gap_0", lambda: gap_tile(0)), ("gap_1", lambda: gap_tile(1)),
    ("gap_lip", gap_lip), ("gap_left", lambda: gap_side("left")),
    ("gap_right", lambda: gap_side("right")), ("gap_bottom", lambda: gap_side("bottom")),
]


# --------------------------------------------------------------------------
# Small dungeon pieces.
# --------------------------------------------------------------------------
# A squat mooring bollard with a rusted iron ring on top. 16x20, foot row 19.
HOOK_POST = [
    "................",
    "......SSSS......",
    ".....SS..SS.....",
    ".....S....S.....",
    ".....SS..SS.....",
    "......SSSS......",
    ".......SS.......",
    "....PPPPPPPP....",
    "...PPPPPPPPPP...",
    "....PPPPPPPP....",
    ".....PPPPPP.....",
    ".....PPPPPP.....",
    ".....SSSSSS.....",
    ".....PPPPPP.....",
    ".....PPPPPP.....",
    "....PPPPPPPP....",
    "...PPPPPPPPPP...",
    "...XPPPPPPPPX...",
    "...XXPPPPPPXX...",
    "................",
]

# A cargo crate: planks, a cross brace, iron corners. 16x18, foot row 17.
CRATE = [
    "................",
    ".SPPPPPPPPPPPPS.",
    ".PPPPPPPPPPPPPP.",
    ".PPPPPPPPPPPPPP.",
    ".SPPPPPPPPPPPPS.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".STTTTTTTTTTTTS.",
    ".SSSSSSSSSSSSSS.",
    "................",
]


def crate():
    c = [list(r) for r in CRATE]
    # Cross brace on the front face.
    for i in range(10):
        put(c, 2 + i * 12 // 9, 5 + i, "P")
        put(c, 3 + i * 12 // 9, 5 + i, "P")
        put(c, 13 - i * 12 // 9, 5 + i, "P")
    # Plank seams on the front.
    for y in range(5, 16):
        if c[y][5] == "T":
            c[y][5] = "."  # seam gap gets an outline
        if c[y][10] == "T":
            c[y][10] = "."
    return rows_of(c)


# Bars: three iron rods with a crossbar, rising out of the deck. 16x20.
BARS = [
    "................",
    "..S....S....S...",
    ".SSS..SSS..SSS..",
    "..S....S....S...",
    "..S....S....S...",
    "..S....S....S...",
    "..S....S....S...",
    "SSSSSSSSSSSSSSSS",
    "SSSSSSSSSSSSSSSS",
    "..S....S....S...",
    "..S....S....S...",
    "..S....S....S...",
    "..S....S....S...",
    "..S....S....S...",
    "..R....R....R...",
    "..R....R....R...",
    "PPPPPPPPPPPPPPPP",
    "PPPPPPPPPPPPPPPP",
    "................",
    "................",
]


def big_door_half():
    """Left half of the great door (the right half is mirrored): tall
    vertical planks under a dark arch, heavy iron hinges, gilt rivets, and
    half of a big brass lock with a keyhole at the seam. 16x16."""
    c = canvas(16, 16)
    fill_rect(c, 0, 0, 16, 16, "3")
    # Arched opening: the doorway's top corner curves in.
    for y in range(16):
        inset = max(0, 4 - y) if y < 4 else 0
        for x in range(1 + inset, 16):
            c[y][x] = "P"
    # Vertical planks with dark seams.
    for x in (5, 10):
        for y in range(16):
            if c[y][x] == "P":
                c[y][x] = "3"
    # Iron hinge straps.
    for y in (4, 11):
        for x in range(2, 14):
            if c[y][x] in ("P", "3"):
                c[y][x] = "S"
        put(c, 2, y + 1, "S")
    # Gilt rivets on the straps.
    for (x, y) in ((4, 4), (8, 4), (12, 4), (4, 11), (8, 11), (12, 11)):
        put(c, x, y, "M")
    # The lock: half of a brass plate with the big keyhole at the seam.
    fill_rect(c, 11, 6, 5, 4, "Q")
    put(c, 15, 7, "3")
    put(c, 15, 8, "3")
    put(c, 14, 8, "3")
    return rows_of(c)


def plate_frames():
    """Pressure plate, up and pressed down, drawn flat on the deck."""
    up = canvas(16, 16)
    fill_rect(up, 2, 3, 12, 10, "Q")
    fill_rect(up, 4, 5, 8, 6, "M")
    for x in range(2, 14):
        up[12][x] = "S"
    down = canvas(16, 16)
    fill_rect(down, 2, 4, 12, 9, "S")
    fill_rect(down, 3, 5, 10, 7, "Q")
    fill_rect(down, 5, 7, 6, 4, "M")
    return rows_of(up), rows_of(down)


# The Tide Hook's head: a barbed iron hook, pointing right. 10x10.
HOOK_HEAD = [
    "..........",
    "...SSS....",
    "..S...S...",
    "......SS..",
    "SSSSSSSSS.",
    "SSSSSSSSS.",
    "......SS..",
    "..S...S...",
    "...SSS....",
    "..........",
]

# Items lifted from chests, 16x16, foot row 12.
ITEM_TIDE_HOOK = [
    "................",
    "........SSS.....",
    ".......S...S....",
    "...........S....",
    "....S.....SS....",
    "....SS...SS.....",
    ".....SSSSS......",
    ".......S........",
    ".......T........",
    ".......T........",
    ".......T........",
    "......QTQ.......",
    ".......T........",
    "................",
    "................",
    "................",
]
ITEM_BIG_KEY = [
    "................",
    "....MMMMM.......",
    "...MM...MM......",
    "...M..4..M......",
    "...MM...MM......",
    "....MMMMM.......",
    "......M.........",
    "......M.........",
    "......MMMM......",
    "......M.........",
    "......MMM.......",
    "......M.........",
    "......MMMM......",
    "................",
    "................",
    "................",
]
ITEM_MAP = [
    "................",
    "................",
    "..FFFFFFFFFFF...",
    ".FFFFFFFFFFFFF..",
    ".FFAFFFFFFFFFF..",
    ".FFFAFFFFFFFFF..",
    ".FFFFAAAFFFFFF..",
    ".FFFFFFFAFFFFF..",
    ".FFFFFFFFAFFFF..",
    ".FFFFFFFFFAAFF..",
    ".FFFFFFFFFFFFF..",
    "..FFFFFFFFFFF...",
    "................",
    "................",
    "................",
    "................",
]
ITEM_COMPASS = [
    "................",
    "................",
    ".....QQQQQ......",
    "....QFFFFFQ.....",
    "...QFFFAFFFQ....",
    "...QFFFAFFFQ....",
    "...QFFFAFFFQ....",
    "...QFFFSFFFQ....",
    "...QFFFSFFFQ....",
    "....QFFFFFQ.....",
    ".....QQQQQ......",
    "................",
    "................",
    "................",
    "................",
    "................",
]

# The Matriarch's armour: a slab of hull planking with an iron strap and
# barnacles. 16x12.
MATRIARCH_PLATE = [
    "............",
    "..PPPPPPPP..",
    ".PPZPPPPPPP.",
    ".SSSSSSSSSS.",
    ".PPPPPPPZPP.",
    "..PPPXPPPP..",
    "............",
    "............",
]


def barnacle_shot(frame):
    c = canvas(8, 8)
    fill_ellipse(c, 3.5, 3.5, 3.0, 2.6, "Z")
    if frame == 0:
        put(c, 3, 3, "3")
        put(c, 4, 3, "3")
    else:
        put(c, 3, 4, "3")
        put(c, 4, 4, "3")
    return rows_of(c)


# --------------------------------------------------------------------------
# The first Tidebell: a bronze bell green with age, on a short timber frame,
# still crusted with weed. Two frames: dark, and rung (glowing rim). 32x40.
# --------------------------------------------------------------------------
def tidebell(rung):
    c = canvas(32, 40)
    # Frame: two posts and a crossbeam.
    fill_rect(c, 3, 4, 26, 3, "P")
    fill_rect(c, 4, 7, 3, 31, "P")
    fill_rect(c, 25, 7, 3, 31, "P")
    fill_rect(c, 2, 36, 7, 2, "P")
    fill_rect(c, 23, 36, 7, 2, "P")
    # Hanger.
    fill_rect(c, 14, 7, 4, 3, "S")
    # Bell: crown, waist, flared lip.
    for y in range(10, 33):
        t = (y - 10) / 22.0
        half = 4 + 6 * t + (5 * (t - 0.75) / 0.25 if t > 0.75 else 0)
        for x in range(int(16 - half), int(16 + half)):
            put(c, x, y, "V")
    for x in range(5, 27):
        if c[32][x] == "V":
            c[33][x] = "V"
    # Raised bands and a wave motif.
    for y in (14, 27):
        for x in range(32):
            if c[y][x] == "V":
                c[y][x] = "M" if rung else "V"
    for x in range(10, 22):
        y = round(21 - 2 * math.sin((x - 10) / 12 * math.tau))
        if c[y][x] == "V":
            c[y][x] = "M"
    # Clapper under the lip.
    fill_rect(c, 15, 33, 2, 3, "S")
    # Weed hanging off the frame and lip.
    for (x, y, n) in ((4, 7, 4), (27, 7, 6), (8, 33, 2), (22, 32, 3)):
        for i in range(n):
            put(c, x, y + i, "X")
    if rung:
        for x in range(32):
            if c[33][x] == "V":
                c[33][x] = "4"
    return rows_of(c)


# --------------------------------------------------------------------------
# The Barnacle Matriarch. A hermit crab the size of a rowing boat, living in
# a ship's figurehead: the carved lady lies on her back over the crab, gilt
# hair streaming, face calm, and the crab's eyes and claws come out from
# under her. Planks strapped on top are drawn separately (they come off).
# 64x48 frames, feet on row 45.
# --------------------------------------------------------------------------
def _figurehead(c, lift=0, tilt=0):
    """The shell: a carved figurehead lying on its back. Her head is at the
    front left, face turned up and calm; gilt hair streams back over the
    wood; a band of faded paint marks her gown."""
    cy = 17 - lift
    cx = 34 + tilt
    fill_ellipse(c, cx, cy, 21, 12, "P")
    # Faded gown paint across the middle of the carving.
    fill_ellipse(c, cx + 6, cy + 3, 11, 6, "F", only=("P",))
    line(c, cx - 3, cy + 6, cx + 14, cy, "V", 2)
    # Hair: a few long locks flowing back from the head.
    for i, (dy, bend) in enumerate(((-9, 2), (-6, 3), (-3, 2))):
        for x in range(cx - 12, cx + 14):
            y = cy + dy + round(bend * math.sin((x - cx) / 6.0 + i))
            if c[y][x] in ("P", "F"):
                c[y][x] = "M"
    # The carved head at the prow end: face turned up, eyes closed.
    hx, hy = cx - 18, cy + 1
    fill_ellipse(c, hx, hy, 6, 6, "M")
    fill_ellipse(c, hx - 1, hy + 1, 4, 4, "F")
    put(c, hx - 3, hy, "P")
    put(c, hx - 2, hy, "P")
    put(c, hx, hy, "P")
    put(c, hx + 1, hy, "P")
    put(c, hx - 1, hy + 3, "A")
    # Barnacles crusting the rim, weed hanging off.
    for x in (20, 24, 41, 46, 50):
        put(c, x + tilt, cy + 10, "Z")
        put(c, x + 1 + tilt, cy + 10, "Z")
    for x in (cx + 18, cx + 20):
        for i in range(4):
            put(c, x, cy + 3 + i, "X")


def _crab(c, step=0, claw="rest", mouth=False, out=False):
    """Everything of the crab that shows in front of the shell."""
    base = 33
    fill_ellipse(c, 33, base, 17, 6, "A")
    # Barnacle spots on the carapace.
    for (x, y) in ((24, 32), (40, 31), (36, 35)):
        put(c, x, y, "Z")
    if out:
        # Lurched half out: the soft pink abdomen curls up behind.
        fill_ellipse(c, 50, base - 8, 10, 9, "Y")
        fill_ellipse(c, 55, base - 15, 5, 5, "Y")
        for x in range(44, 58, 4):
            line(c, x, base - 15, x + 1, base - 2, "A")
    # Eye stalks, standing up in front of the shell rim.
    for ex, lean in ((28, -1), (38, 1)):
        line(c, ex, base - 3, ex + lean, base - 9, "A", 2)
        fill_rect(c, ex + lean - 1, base - 12, 4, 4, "A")
        fill_rect(c, ex + lean, base - 11, 2, 2, "1")
        put(c, ex + lean, base - 11, "2")
    if mouth:
        fill_rect(c, 30, base + 1, 7, 3, "Y")
        fill_rect(c, 31, base + 2, 5, 1, "3")
    # Legs: three a side, jointed, stepping.
    for i in range(3):
        lift = (1 if (i + step) % 2 == 0 else -1) if step >= 0 else 0
        for sgn in (-1, 1):
            hx = 33 + sgn * (9 + i * 3)
            kx = 33 + sgn * (17 + i * 4)
            fx = 33 + sgn * (19 + i * 5)
            line(c, hx, base + 2, kx, base - 1 + lift, "A", 2)
            line(c, kx, base - 1 + lift, fx, 45 - (i % 2) - max(lift, 0), "A", 2)
    # The small claw (viewer's right).
    fill_ellipse(c, 46, base + 6, 4, 3, "A")
    line(c, 49, base + 4, 51, base + 7, "A")
    # The great claw (viewer's left), heavy and barnacled.
    if claw == "rest":
        line(c, 22, base + 2, 17, base + 4, "A", 3)
        fill_ellipse(c, 13, 39, 9, 6, "A")
        # Two pincer fingers, open a crack.
        line(c, 5, 32, 9, 37, "A", 3)
        line(c, 3, 38, 8, 40, "A", 2)
        put(c, 8, 38, "3")
        for (x, y) in ((12, 36), (16, 39), (10, 42)):
            put(c, x, y, "Z")
    elif claw == "up":
        line(c, 22, base, 14, 20, "A", 3)
        fill_ellipse(c, 11, 12, 9, 8, "A")
        fill_ellipse(c, 5, 4, 3, 4, "A")
        fill_ellipse(c, 15, 3, 3, 3, "A")
        fill_rect(c, 8, 6, 5, 2, "3")
        for (x, y) in ((10, 10), (14, 14)):
            put(c, x, y, "Z")
    elif claw == "down":
        line(c, 22, base + 3, 16, 40, "A", 3)
        fill_ellipse(c, 13, 43, 11, 4, "A")
        fill_ellipse(c, 3, 41, 3, 3, "A")
        for (x, y) in ((12, 41), (17, 43)):
            put(c, x, y, "Z")
        # Splinters thrown up by the slam.
        for (x, y) in ((2, 35), (26, 38), (5, 31), (25, 34), (28, 41)):
            put(c, x, y, "P")


def matriarch_frames():
    frames = []
    for spec in (
        dict(step=0, claw="rest"),
        dict(step=1, claw="rest"),
        dict(step=-1, claw="up", lift=3),
        dict(step=-1, claw="down"),
        dict(step=0, claw="rest", out=True, lift=4, tilt=-5),
        dict(step=-1, claw="rest", mouth=True, lift=2),
        dict(step=-1, claw="rest", dead=True),
    ):
        c = canvas(64, 48)
        # The shell first; the crab's eyes, legs and claws come out in front.
        _figurehead(c, spec.get("lift", 0), spec.get("tilt", 0))
        _crab(c, spec["step"], spec["claw"], spec.get("mouth", False), spec.get("out", False))
        if spec.get("dead"):
            # Cracked down the middle, eyes dull.
            for y in range(6, 30):
                put(c, 34 + (y % 3) - 1, y, "3")
            for y in range(18, 26):
                for x in range(20, 44):
                    if c[y][x] in ("1", "2"):
                        c[y][x] = "A"
        frames.append(rows_of(c))
    return frames


def build(lit, sheet):
    """Everything in assets/dungeon/, as {file name: pixels}."""
    up, down = plate_frames()
    door = big_door_half()
    left = lit(door, 41)
    right = [list(reversed(r)) for r in left]
    return {
        "hook_post": sheet([[lit(HOOK_POST, 40)]], 16, 20),
        "crate": sheet([[lit(crate(), 42)]], 16, 18),
        "plate": sheet([[lit(up, 43), lit(down, 43)]], 16, 16),
        "bars": sheet([[lit(BARS, 44)]], 16, 20),
        "big_door": sheet([[left, right]], 16, 16),
        "hook_head": sheet([[lit(HOOK_HEAD, 45)]], 10, 10),
        "item_tide_hook": sheet([[lit(ITEM_TIDE_HOOK, 46)]], 16, 16),
        "item_big_key": sheet([[lit(ITEM_BIG_KEY, 47)]], 16, 16),
        "item_map": sheet([[lit(ITEM_MAP, 48)]], 16, 16),
        "item_compass": sheet([[lit(ITEM_COMPASS, 49)]], 16, 16),
        "matriarch": sheet([[lit(f, 50) for f in matriarch_frames()]], 64, 48),
        "matriarch_plate": sheet([[lit(MATRIARCH_PLATE, 51)]], 12, 8),
        "barnacle_shot": sheet([[lit(barnacle_shot(0), 52), lit(barnacle_shot(1), 52)]], 8, 8),
        "tidebell": sheet([[lit(tidebell(False), 53), lit(tidebell(True), 53)]], 32, 40),
    }
