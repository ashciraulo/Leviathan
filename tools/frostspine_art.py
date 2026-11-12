"""Frostspine: a glacier on the north shore (plan feel: cold, still,
lonely). Palette: snow #EEF4FA, shadowed snow #B8C8DE, glacier blue
#6EA8D8, deep ice #2E5A8A, slate rock #4A5468.

Tiles are RGBA 16x16 grids; sprites are material silhouettes that
build_art.lit() shades. Imported by build_art.py.

Material letters here must not clash with other art modules (build_art
asserts it): this file uses | ' , ` for ramps and none for flats.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
SNOW = [hex_color(c) for c in ("#FFFFFF", "#EEF4FA", "#DCE6F2", "#C4D2E6", "#A8B8D2", "#8496B6")]
ICE = [hex_color(c) for c in ("#E4F6FF", "#AEDCF6", "#7EBCE6", "#5A98CC", "#3E74A8", "#2A5280")]
ROCK = [hex_color(c) for c in ("#8A94A8", "#6A7488", "#4A5468", "#363E50", "#242A38")]
SEA = [hex_color(c) for c in ("#DDEEF8", "#7AA4C4", "#4E7CA2", "#365E84", "#244464")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def snow_tile(seed):
    """Wind-packed snow: soft drifts with faint blue shadows."""
    rnd = random.Random(4400 + seed)
    px = blank(SNOW[1])
    for _ in range(3):
        cx, cy = rnd.randrange(T), rnd.randrange(T)
        for x in range(cx - 3, cx + 4):
            xx = x % T
            px[cy][xx] = SNOW[2]
            px[(cy + 1) % T][xx] = SNOW[3] if abs(x - cx) < 2 else SNOW[2]
    for _ in range(8):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = SNOW[0]
    if seed == 3:
        # A few prints of some small creature.
        for i, (x, y) in enumerate(((3, 4), (5, 7), (7, 10), (9, 13))):
            px[y][x] = SNOW[4]
            px[y][x + 1 if i % 2 else x - 1] = SNOW[3]
    return px


def ice_floor(seed):
    """Slick blue ice (layout x): glossy with long pale streaks."""
    rnd = random.Random(4500 + seed)
    px = blank(ICE[2])
    for _ in range(3):
        y, x0 = rnd.randrange(T), rnd.randrange(T)
        for i in range(6):
            px[(y + i // 3) % T][(x0 + i) % T] = ICE[1]
    for _ in range(2):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = ICE[0]
    # A hairline crack.
    x, y = rnd.randrange(T), 0
    while y < T:
        if rnd.random() < 0.5:
            px[y][x] = ICE[3]
        x = (x + rnd.choice((-1, 0, 1))) % T
        y += 1
    return px


def glacier_top(seed):
    """Wall top: the glacier's snow-crusted back, with blue crevasses."""
    rnd = random.Random(4600 + seed)
    px = blank(SNOW[3])
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((SNOW[2], SNOW[4]))
    x0, y = rnd.randrange(T), rnd.randrange(4, 12)
    for i in range(rnd.randrange(5, 10)):
        x = (x0 + i) % T
        px[y][x] = ICE[4]
        px[y - 1][x] = ICE[2]
    return px


def glacier_face(seed):
    """Wall face: a sheer ice cliff, blue and banded, with a snow lip."""
    rnd = random.Random(4700 + seed)
    px = blank(ICE[3])
    for y in range(T):
        for x in range(T):
            band = (y + (x * 3 + seed * 5) // 7) % 5
            px[y][x] = ICE[2] if band == 0 else ICE[3] if band < 3 else ICE[4]
    for x in range(T):
        px[0][x] = SNOW[1]
        px[1][x] = SNOW[3] if (x + seed) % 4 else SNOW[1]
        px[T - 1][x] = ICE[5]
    for _ in range(3):
        fx = rnd.randrange(T)
        for y in range(2, rnd.randrange(6, T)):
            px[y][fx] = ICE[1] if y < 6 else ICE[2]
    return px


def floe_sea(frame):
    """Cold sea scattered with small floes that drift a pixel each frame."""
    px = blank(SEA[3])
    for y in range(T):
        for x in range(T):
            if math.sin((x + frame) * 0.8 + y * 1.1) + math.sin(y * 0.6) > 1.4:
                px[y][x] = SEA[2]
    for (x, y, w) in ((2, 3, 3), (10, 9, 4), (6, 13, 2)):
        for i in range(w):
            px[y][(x + i + frame) % T] = SEA[0]
        px[y + 1][(x + 1 + frame) % T] = SEA[1]
    return px


def ice_edge(side, frame):
    """A shelf of shore ice where the snow meets the sea."""
    px = blank()
    for i in range(T):
        depth = 3 + (1 if (i * 5 + frame) % 6 < 2 else 0)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = SNOW[2] if d < depth - 2 else ICE[1] if d == depth - 2 else ICE[3]
    return px


def drift_shadow(side, seed):
    """Blue shadow in the snow beside the water."""
    rnd = random.Random(4800 + seed)
    px = blank()
    for i in range(T):
        depth = 2 + rnd.randrange(3)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = (110, 140, 190, 90) if d < 1 else (110, 140, 190, 45)
    return px


def ice_shards(seed):
    """A cluster of ice spikes pushing up through the snow."""
    px = blank()
    for (x, h) in ((5, 6), (8, 9), (11, 5)) if seed == 0 else ((6, 7), (10, 6)):
        for y in range(12 - h, 13):
            w = (y - (12 - h)) // 3
            for xx in range(x - w, x + w + 1):
                if 0 <= xx < T:
                    px[y][xx] = ICE[1] if xx < x else ICE[3]
        px[12 - h][x] = ICE[0]
    return px


def frost_rock(seed):
    """A slate boulder poking out of the snow, capped white."""
    px = blank()
    for y in range(7, 13):
        half = 4 - abs(y - 10) // 2
        for x in range(8 - half, 8 + half):
            px[y][x] = ROCK[2] if x < 8 else ROCK[3]
    for x in range(5, 11):
        px[7][x] = SNOW[1]
        px[8][x] = SNOW[2] if x % 2 else SNOW[1]
    return px


def snowfall(seed):
    """Flakes laid over the snow now and then."""
    px = blank()
    rnd = random.Random(4900 + seed)
    for _ in range(4):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = (255, 255, 255, 200)
    return px


TILES = [
    ("snow_0", lambda: snow_tile(0)), ("snow_1", lambda: snow_tile(1)),
    ("snow_2", lambda: snow_tile(2)), ("snow_3", lambda: snow_tile(3)),
    ("slick_ice_0", lambda: ice_floor(0)), ("slick_ice_1", lambda: ice_floor(1)),
    ("glacier_top_0", lambda: glacier_top(0)), ("glacier_top_1", lambda: glacier_top(1)),
    ("glacier_face_0", lambda: glacier_face(0)), ("glacier_face_1", lambda: glacier_face(1)),
    ("floe_sea_0", lambda: floe_sea(0)), ("floe_sea_1", lambda: floe_sea(1)),
    ("shelf_top_0", lambda: ice_edge("top", 0)), ("shelf_bottom_0", lambda: ice_edge("bottom", 0)),
    ("shelf_left_0", lambda: ice_edge("left", 0)), ("shelf_right_0", lambda: ice_edge("right", 0)),
    ("shelf_top_1", lambda: ice_edge("top", 1)), ("shelf_bottom_1", lambda: ice_edge("bottom", 1)),
    ("shelf_left_1", lambda: ice_edge("left", 1)), ("shelf_right_1", lambda: ice_edge("right", 1)),
    ("drift_top", lambda: drift_shadow("top", 1)), ("drift_bottom", lambda: drift_shadow("bottom", 2)),
    ("drift_left", lambda: drift_shadow("left", 3)), ("drift_right", lambda: drift_shadow("right", 4)),
    ("ice_shards_0", lambda: ice_shards(0)), ("ice_shards_1", lambda: ice_shards(1)),
    ("frost_rock_0", lambda: frost_rock(0)), ("frost_rock_1", lambda: frost_rock(1)),
    ("snowfall_0", lambda: snowfall(0)), ("snowfall_1", lambda: snowfall(1)),
]

# --------------------------------------------------------------------------
# Sprites.
# --------------------------------------------------------------------------
RAMPS = {
    "|": ["#5E6E86", "#46546C", "#343F54", "#252D3E", "#141824"],   # seal hide
    "'": ["#FFFFFF", "#E6EEF6", "#C4D2E6", "#9AAAC6", "#6A7A9A"],   # pale belly fur
    ",": ["#2A2A34", "#1C1C24", "#121218", "#0A0A10", "#040406"],   # eyes, nose
    "`": ["#E4F6FF", "#AEDCF6", "#7EBCE6", "#5A98CC", "#2A5280"],   # ice
}
FLAT = {}


# Sledgeseal: a stocky seal that rears up (the tell), then throws itself
# onto its belly and toboggans straight at Wren, sliding on until it hits
# something. On its belly it's slow to turn: step aside and strike its
# side. Drawn side-on, facing right (the game flips it): round head and big
# dark eyes, a pale belly and whiskered muzzle, fore flippers planted and
# tail flippers splayed behind. 20x14 frames: idle, rear, slide.
SEAL = {
"idle": [
"....................",
"....................",
"............||||....",
"...........||||||...",
"...........|,,||||..",
"...........|,,|||''.",
"...........|||||'',,",
".......|||||||||''..",
"....||||||||||||'...",
".||||||||||||'''....",
"||..|''''''''''|....",
".|...'''''''''.||...",
"...............|....",
"....................",
],
"rear": [
".............||||...",
"............||||||..",
"............|,,|||'.",
"............|,,|||''",
"............||||'',,",
"............||||''..",
"...........|||||''..",
"..........|||||''...",
".......||||||||'....",
"....||||||||||''|...",
".||||||||||'''.||...",
"||..|''''''''..|....",
".|...''''''''.......",
"....................",
],
"slide": [
"....................",
"....................",
"....................",
"....................",
"....................",
"..............||||..",
".......||||||||,,||.",
"..||||||||||||||,,|'",
".||..||''''''''''''|",
"|....''''''''''''',,",
".|..|..........||...",
"....................",
"....................",
"....................",
],
}
def sledgeseal(frame):
    return list(SEAL[frame])
