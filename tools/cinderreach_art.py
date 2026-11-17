"""Cinderreach: volcanic badlands and geysers (plan palette: red rock
#B5452F, char #3A1F2B, ember #FFB347, molten yellow #FFE36E).

Tiles are RGBA 16x16 grids; sprites are material silhouettes that
build_art.lit() shades. Imported by build_art.py.

Material letters here must not clash with other art modules (build_art
asserts it): this file uses + < > ^ for ramps and none for flats.
"""

import functools
import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
# Ash flats: dusty grey-mauve, low contrast so Wren and enemies read.
ASH = [hex_color(c) for c in ("#B8A4A0", "#9E8A88", "#86726F", "#6E5C5C", "#584848", "#3A2E34")]
# Layered red rock for cliffs.
ROCK = [hex_color(c) for c in ("#E8865E", "#CC6446", "#B5452F", "#8A3428", "#5E2426", "#3A1F2B")]
LAVA = [hex_color(c) for c in ("#FFF4B0", "#FFE36E", "#FFB347", "#F2783A", "#C8452C", "#7A2626")]
CRUST = [hex_color(c) for c in ("#5E4448", "#4A3438", "#3A1F2B", "#2A161E")]
SCRUB = [hex_color(c) for c in ("#C8B86A", "#9E8E4E", "#6E6040", "#4A3E34")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def ash_tile(seed):
    """Ash flats: fine speckle, a few pebbles, and faint wind ripples."""
    rnd = random.Random(1400 + seed)
    px = blank(ASH[2])
    # Wind ripples: soft lighter streaks running across.
    for _ in range(2):
        y = rnd.randrange(2, T - 2)
        x0 = rnd.randrange(0, 8)
        for x in range(x0, min(T, x0 + rnd.randrange(5, 9))):
            px[y][x] = ASH[1]
            px[y + 1][x] = ASH[3] if rnd.random() < 0.5 else ASH[2]
    for _ in range(10):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((ASH[1], ASH[3]))
    # A pebble of dark basalt with a lit top-left.
    for _ in range(rnd.randrange(1, 3)):
        x, y = rnd.randrange(1, T - 2), rnd.randrange(1, T - 2)
        px[y][x] = ASH[0]
        px[y][x + 1] = ASH[4]
        px[y + 1][x] = ASH[4]
        px[y + 1][x + 1] = ASH[5]
    return px


def mesa_top(seed):
    """Wall top: the flat, sun-baked top of a red mesa with cracks."""
    rnd = random.Random(1500 + seed)
    px = blank(ROCK[2])
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((ROCK[1], ROCK[3]))
    # A crack wandering across.
    x, y = rnd.randrange(T), 0
    while y < T:
        px[y][x] = ROCK[4]
        if x + 1 < T:
            px[y][x + 1] = ROCK[1]
        x = max(0, min(T - 2, x + rnd.choice((-1, 0, 1))))
        y += 1
    return px


def mesa_face(seed):
    """Wall face: banded strata in red rock, lit rim at the top, dark foot."""
    rnd = random.Random(1600 + seed)
    px = blank(ROCK[3])
    bands = [ROCK[2], ROCK[3], ROCK[2], ROCK[4], ROCK[3], ROCK[4]]
    for y in range(T):
        band = bands[min(len(bands) - 1, y // 3)]
        for x in range(T):
            px[y][x] = band
    for x in range(T):
        px[0][x] = ROCK[0]
        px[1][x] = ROCK[1]
        # Strata lines, slightly wavy.
        for line in (5, 10):
            yy = line + (1 if (x + seed * 3) % 7 < 2 else 0)
            px[yy][x] = ROCK[5] if yy == 10 else ROCK[4]
        px[T - 1][x] = ROCK[5]
    # Vertical fissures.
    for _ in range(2):
        fx = rnd.randrange(1, T - 1)
        for y in range(rnd.randrange(3, 7), T - 1):
            px[y][fx] = ROCK[5]
            px[y][fx - 1] = ROCK[2] if y % 2 else px[y][fx - 1]
    return px


def lava_tile(frame):
    """Molten rock with a cooling skin that drifts: bright channels between
    dark crust plates, shifting a pixel each frame."""
    px = blank(LAVA[3])
    rnd = random.Random(1700)
    plates = [(rnd.randrange(T), rnd.randrange(T), rnd.choice((2.5, 3, 3.5))) for _ in range(4)]
    for y in range(T):
        for x in range(T):
            xx = (x - frame) % T
            # Stretched, wobbly plates so the crust reads as broken skin
            # drifting down a channel, not round spots.
            best = min(math.hypot((((xx - px_) + 8) % T - 8) * 0.6, ((y - py_) + 8) % T - 8) / r for (px_, py_, r) in plates)
            best += 0.22 * math.sin(xx * 1.7 + y * 0.9) + 0.15 * math.sin(y * 2.3 - xx * 0.6)
            if best < 0.75:
                px[y][x] = CRUST[1]
            elif best < 1.0:
                px[y][x] = LAVA[4]
            elif best < 1.35:
                px[y][x] = LAVA[2]
            else:
                px[y][x] = LAVA[1]
    for (x, y) in ((4, 4), (11, 9), (7, 13)):
        px[y][(x + frame * 2) % T] = LAVA[0]
    return px


# Open lava pools on the overworld are drawn from one 64px block (4x4
# tiles, picked by position), so a pool shows no 16px repeat.
LAVA_BLOCK = 4


@functools.lru_cache(maxsize=None)
def lava_block(frame):
    """Molten cells, wrapped so the block tiles with no seam: each one wells
    up bright in the middle and cools to glowing red seams where it meets
    its neighbours. The second frame swells the middles a touch."""
    size = LAVA_BLOCK * T
    rnd = random.Random(1717)
    pts = []
    for gy in range(LAVA_BLOCK):
        for gx in range(LAVA_BLOCK):
            pts.append((gx * T + rnd.uniform(2, 14), gy * T + rnd.uniform(2, 14), rnd.uniform(0.85, 1.15)))
    px = [[LAVA[2]] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            ds = []
            for (cx, cy, k) in pts:
                dx = (x - cx + size / 2) % size - size / 2
                dy = ((y - cy + size / 2) % size - size / 2) * 1.25
                ds.append(math.hypot(dx, dy) * k)
            ds.sort()
            edge = ds[1] - ds[0]
            core = ds[0] - frame * 0.8
            wob = 0.8 * math.sin((x * 3 + y * 5) * 0.37)
            if edge + wob * 0.3 < 0.8:
                c = LAVA[5]
            elif edge < 1.9:
                c = LAVA[4]
            elif edge < 3.4:
                c = LAVA[3]
            elif core < 4.6 + wob:
                c = LAVA[1]
            else:
                c = LAVA[2]
            px[y][x] = c
    for (cx, cy, _k) in pts:
        x, y = (int(cx) + frame) % size, int(cy) % size
        px[y][x] = LAVA[0]
    return px


def lava_block_tile(frame, q):
    block = lava_block(frame)
    ox, oy = (q % LAVA_BLOCK) * T, (q // LAVA_BLOCK) * T
    return [row[ox:ox + T] for row in block[oy:oy + T]]


def crust_edge(side, frame):
    """A black, cooled lip where the lava meets the ash."""
    px = blank()
    for i in range(T):
        depth = 2 + (1 if (i * 5 + frame) % 7 < 3 else 0)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = CRUST[2] if d < depth - 1 else LAVA[4]
    return px


def scorch_edge(side, seed):
    """Ash darkened and glowing faintly beside the lava."""
    rnd = random.Random(1800 + seed)
    px = blank()
    for i in range(T):
        depth = 3 + rnd.randrange(3)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = (90, 30, 30, 110) if d < 2 else (60, 30, 40, 60)
    return px


def ember_vent(seed):
    """A little fumarole: a crack in the ash with a glowing heart."""
    px = blank()
    cx, cy = 8, 9
    for (dx, dy, c) in ((-3, 0, CRUST[2]), (-2, 0, CRUST[1]), (-1, 0, LAVA[3]), (0, 0, LAVA[1]), (1, 0, LAVA[3]),
                        (2, 0, CRUST[1]), (3, -1, CRUST[2]), (-1, 1, CRUST[2]), (0, 1, LAVA[4]), (1, 1, CRUST[2])):
        px[cy + dy][cx + dx] = c
    if seed:
        px[cy - 3][cx] = (255, 227, 110, 160)
        px[cy - 5][cx + 1] = (255, 179, 71, 110)
    return px


def scrub(seed):
    """A dry, wiry tuft of badland scrub."""
    px = blank()
    rnd = random.Random(1900 + seed)
    base_x = 7
    for i in range(5):
        x = base_x + i - 2
        h = rnd.randrange(3, 6)
        for y in range(12 - h, 12):
            lean = (12 - y) // 3 * (1 if i > 2 else -1 if i < 2 else 0)
            xx = max(0, min(T - 1, x + lean))
            px[y][xx] = SCRUB[1] if y < 12 - h + 1 else SCRUB[2]
    for x in range(base_x - 3, base_x + 4):
        px[12][x] = SCRUB[3]
    return px


def heat_shimmer(seed):
    """A faint warm haze patch laid over the ash now and then."""
    px = blank()
    for y in range(T):
        for x in range(T):
            if (x + y * 2 + seed * 5) % 9 < 2 and 3 < y < 13:
                px[y][x] = (255, 179, 71, 28)
    return px


TILES = [
    ("ash_0", lambda: ash_tile(0)), ("ash_1", lambda: ash_tile(1)),
    ("ash_2", lambda: ash_tile(2)), ("ash_3", lambda: ash_tile(3)),
    ("mesa_top_0", lambda: mesa_top(0)), ("mesa_top_1", lambda: mesa_top(1)),
    ("mesa_face_0", lambda: mesa_face(0)), ("mesa_face_1", lambda: mesa_face(1)),
    ("lava_0", lambda: lava_tile(0)), ("lava_1", lambda: lava_tile(1)),
] + [
    ("lava_%d_%d" % (f, q), (lambda f=f, q=q: lava_block_tile(f, q)))
    for f in range(2) for q in range(LAVA_BLOCK * LAVA_BLOCK)
] + [
    ("crust_top_0", lambda: crust_edge("top", 0)), ("crust_bottom_0", lambda: crust_edge("bottom", 0)),
    ("crust_left_0", lambda: crust_edge("left", 0)), ("crust_right_0", lambda: crust_edge("right", 0)),
    ("crust_top_1", lambda: crust_edge("top", 1)), ("crust_bottom_1", lambda: crust_edge("bottom", 1)),
    ("crust_left_1", lambda: crust_edge("left", 1)), ("crust_right_1", lambda: crust_edge("right", 1)),
    ("scorch_top", lambda: scorch_edge("top", 1)), ("scorch_bottom", lambda: scorch_edge("bottom", 2)),
    ("scorch_left", lambda: scorch_edge("left", 3)), ("scorch_right", lambda: scorch_edge("right", 4)),
    ("vent_0", lambda: ember_vent(0)), ("vent_1", lambda: ember_vent(1)),
    ("scrub_0", lambda: scrub(0)), ("scrub_1", lambda: scrub(1)),
    ("shimmer_0", lambda: heat_shimmer(0)), ("shimmer_1", lambda: heat_shimmer(1)),
]

# --------------------------------------------------------------------------
# Sprites.
# --------------------------------------------------------------------------
RAMPS = {
    "+": ["#8A7A78", "#6A5A5C", "#4E4048", "#36283A", "#1E1422"],   # slag shell
    "<": ["#FFF4B0", "#FFE36E", "#FFB347", "#E2654C", "#7A2626"],   # ember glow
    ">": ["#E8D8C8", "#C8B4A4", "#9E8A80", "#6E5C5C", "#3A2E34"],   # bone, horn
    "^": ["#E8865E", "#CC6446", "#B5452F", "#8A3428", "#3A1F2B"],   # red rock
}
FLAT = {}


# Slagbeetle: a beetle with a shell of cooled slag. It digs in, its shell
# cracks open with ember light (the tell), then it charges in a straight
# line. Hitting the shell does nothing; strike after it slams into a wall
# and flips, belly up. 16x14.
SLAGBEETLE = {
    "walk_a": [
        "................",
        "................",
        "....>......>....",
        ".....>....>.....",
        "....++++++++....",
        "...++++++++++...",
        "..++++++++++++..",
        "..++++++++++++..",
        "..+++++<<+++++..",
        "...++++++++++...",
        "..>.>.>..>.>.>..",
        ".>..>..>>..>..>.",
        "................",
        "................",
    ],
    "walk_b": [
        "................",
        "................",
        "....>......>....",
        ".....>....>.....",
        "....++++++++....",
        "...++++++++++...",
        "..++++++++++++..",
        "..++++++++++++..",
        "..+++++<<+++++..",
        "...++++++++++...",
        "...>.>.>>.>.>...",
        "..>..>....>..>..",
        "................",
        "................",
    ],
    "crack": [
        "................",
        "................",
        "...>........>...",
        "....>......>....",
        "....++<++<++....",
        "...++<<++<<++...",
        "..++<<<++<<<++..",
        "..+<<<<++<<<<+..",
        "..++<<<++<<<++..",
        "...++++++++++...",
        "...>.>.>>.>.>...",
        "................",
        "................",
        "................",
    ],
    "flipped": [
        "................",
        "................",
        "................",
        "..>..>....>..>..",
        "...>.>....>.>...",
        "....>>>>>>>>....",
        "...>>>>>>>>>>...",
        "..++++++++++++..",
        "..++++++++++++..",
        "...++++++++++...",
        "....++++++++....",
        "................",
        "................",
        "................",
    ],
}

# A geyser vent: a cone of red rock. It hisses steam (the tell), then blows
# a column of scalding steam. 16x32: frames idle, hiss, blow.
def geyser(frame):
    c = [["."] * 16 for _ in range(32)]
    # Rock cone at the bottom.
    for y in range(24, 31):
        half = 2 + (y - 24)
        for x in range(8 - half, 8 + half):
            if 0 <= x < 16:
                c[y][x] = "^"
    for x in range(6, 10):
        c[24][x] = "+"
    if frame >= 1:
        # A wisp of steam.
        for (x, y) in ((7, 22), (8, 21), (7, 20), (8, 18)) if frame == 1 else ():
            c[y][x] = ">"
    if frame == 2:
        for y in range(2, 24):
            half = 1 + (24 - y) // 6
            wob = 1 if (y // 3) % 2 else 0
            for x in range(8 - half + wob - 1, 8 + half + wob):
                if 0 <= x < 16:
                    c[y][x] = ">"
    return ["".join(r) for r in c]
