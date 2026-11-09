"""Gale Spire (Windmere Heights' dungeon): a broken bell tower on a crag,
open to the sky, where the wind does half the work. Floor and wall tiles,
open-sky drops, lichen and feathers, and its pieces: the Kite Cloak, wind
fans, lightning rods, the Stormheron and its feathers, and the Storm Bell.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes shaded by build_art.lit(), with this file's own
materials (RAMPS, FLAT). Imported by build_art.py, which writes the sprites
to assets/gale/.

Palette: slate stone #5E6E88, sky #8FC4E8, cloud white #EEF4FA, verdigris
copper #4FA08A, storm yellow #FFE36E.
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
    "s": ["#B8C4D8", "#8E9CB4", "#6A7A96", "#4C5A76", "#2A3248"],   # slate stone
    "c": ["#9AE0C8", "#6AC0A6", "#4FA08A", "#357862", "#1A3C34"],   # verdigris copper
    "o": ["#F4C890", "#D89A5A", "#B06E3A", "#7A4626", "#3A2018"],   # bright copper
    "h": ["#DCE4F0", "#B0BED4", "#8496B4", "#5A6A8A", "#2C3450"],   # heron grey
    "w": ["#FFFFFF", "#EEF4FA", "#CAD6E6", "#9AA8C0", "#5A667E"],   # white feathers
    "k": ["#3A4256", "#2C3244", "#1E2232", "#141824", "#0A0C14"],   # dark crest, legs
    "y": ["#FFF4B0", "#FFE36E", "#F2B83A", "#B07A22", "#5A3A12"],   # beak, eye, lightning
    "l": ["#E8D8B0", "#C8B488", "#A08A62", "#76643E", "#3E3220"],   # sailcloth
    "r": ["#E07060", "#B84A44", "#8A3236", "#5A2028", "#2A1018"],   # kite red
    "b": ["#C8B488", "#A89068", "#80684A", "#584430", "#2C2018"],   # bell bronze, pale
}
FLAT = {
    "!": "#FFF6C0",   # spark core
    "_": "#0C0E16",   # dark inside things
    "*": "#8FC4E8",   # sky glint
}

# --------------------------------------------------------------------------
# Tiles.
# --------------------------------------------------------------------------
STONE = [hex_color(c) for c in ("#8E9CB4", "#7A88A2", "#6A7A96", "#5A6886", "#4C5A76", "#36405A")]
LICHEN = [hex_color(c) for c in ("#B8C870", "#8EA058", "#6A7A44")]
SKY = [hex_color(c) for c in ("#CDE6F6", "#A8D2EE", "#8FC4E8", "#76B0DA", "#5C98C8")]
CLOUD = hex_color("#EEF4FA")
RIM = [hex_color(c) for c in ("#5A6886", "#36405A", "#222838")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def floor_tile(seed):
    """Wind-scoured flagstones, pale slate, laid in long courses. Joins fall
    on only some tiles, so the slabs run on across the floor instead of
    boxing every tile; the wind has worn pale streaks along
    the stone and blown grit into the joins."""
    rnd = random.Random(3100 + seed)
    base = STONE[2]
    px = blank(base)
    if seed in (0, 1):
        for x in range(T):
            px[T - 1][x] = STONE[4]
    if seed in (1, 2):
        split = rnd.randrange(4, 12)
        for y in range(T):
            if px[y][split] == base:
                px[y][split] = STONE[4]
            if px[y][split + 1] == base:
                px[y][split + 1] = STONE[1]
    # Streaks the wind has worn along the stone.
    for _ in range(2):
        y = rnd.randrange(3, T - 3)
        x0 = rnd.randrange(0, 8)
        for x in range(x0, min(T, x0 + rnd.randrange(4, 9))):
            if px[y][x] == base:
                px[y][x] = STONE[1]
    for _ in range(5):
        x, y = rnd.randrange(1, T - 1), rnd.randrange(1, T - 1)
        if px[y][x] == base:
            px[y][x] = rnd.choice((STONE[3], STONE[3], STONE[0]))
    # Lichen: a tuft in a join, or a patch on the open stone.
    if seed == 1:
        px[T - 1][rnd.randrange(2, T - 2)] = LICHEN[1]
    if seed == 3:
        x, y = rnd.randrange(3, T - 4), rnd.randrange(3, T - 4)
        px[y][x] = LICHEN[2]
        px[y][x + 1] = LICHEN[1]
    return px


def wall_top(seed):
    """The tower's walls from above: big dressed blocks, lichen on the joins."""
    rnd = random.Random(3200 + seed)
    px = blank(STONE[4])
    for y in range(T):
        for x in range(T):
            if (x + (4 if y >= 8 else 0)) % 8 == 0 or y in (0, 8):
                px[y][x] = STONE[5]
            elif y in (1, 9):
                px[y][x] = STONE[3]
    for _ in range(4):
        px[rnd.choice((0, 8))][rnd.randrange(T)] = rnd.choice(LICHEN)
    return px


def wall_face(seed):
    """Wall face: courses of slate block with a dark arrow slit now and then."""
    rnd = random.Random(3300 + seed)
    px = blank(STONE[3])
    for course in range(4):
        y0 = course * 4
        shift = 3 if course % 2 else 0
        for y in range(y0, y0 + 4):
            for x in range(T):
                if (x + shift) % 6 == 5:
                    px[y][x] = STONE[5]
                elif y == y0:
                    px[y][x] = STONE[2]
    if seed == 1:
        for y in range(4, 11):
            px[y][7] = RIM[2]
            px[y][8] = RIM[2]
    for _ in range(3):
        px[rnd.randrange(T)][rnd.randrange(T)] = rnd.choice(LICHEN)
    for x in range(T):
        px[T - 1][x] = STONE[5]
    return px


def sky_tile(frame):
    """Open sky far below a hole in the floor. One variant is clear sky with
    a faint haze; the other has a loose wisp of cloud drifting past."""
    rnd = random.Random(3500 + frame)
    px = blank(SKY[3])
    for y in range(T):
        for x in range(T):
            if (x * 5 + y * 3 + frame) % 13 == 0:
                px[y][x] = SKY[2]
            elif (x + y * 7) % 23 == 0:
                px[y][x] = SKY[4]
    if frame == 1:
        cx, cy = 6, 9
        for _ in range(14):
            x = cx + rnd.randrange(-5, 6)
            y = cy + rnd.randrange(-1, 2)
            px[y][x] = CLOUD if y <= cy else SKY[0]
            px[y][min(x + 1, T - 1)] = SKY[0]
    return px


def sky_edge(side):
    """The broken floor's edge round a hole: stone lip, dark underside."""
    px = blank()
    for i in range(T):
        if side == "lip":
            # 3/4 view: the far side of the hole shows the floor's thickness.
            for y in range(0, 5):
                px[y][i] = RIM[0] if y < 2 else RIM[1] if y < 4 else RIM[2]
        elif side == "bottom":
            px[T - 1][i] = STONE[1]
            px[T - 2][i] = STONE[4]
        elif side == "left":
            px[i][0] = STONE[1]
            px[i][1] = STONE[4]
        elif side == "right":
            px[i][T - 1] = STONE[4]
            px[i][T - 2] = STONE[5]
    return px


def lichen(seed):
    rnd = random.Random(3400 + seed)
    px = blank()
    for _ in range(9):
        x, y = rnd.randrange(2, T - 2), rnd.randrange(2, T - 2)
        px[y][x] = rnd.choice(LICHEN)
        px[y][min(x + 1, T - 1)] = LICHEN[2]
    return px


def feather_deco(seed):
    """A dropped feather on the stone."""
    px = blank()
    x0, y0 = (4, 9) if seed == 0 else (8, 5)
    for i in range(6):
        px[y0 - i // 2][x0 + i] = hex_color("#EEF4FA") if i < 5 else hex_color("#5A6A8A")
        if 0 < i < 5:
            px[y0 - i // 2 + 1][x0 + i] = hex_color("#B0BED4")
    return px


TILES = [
    ("gale_floor_0", lambda: floor_tile(0)), ("gale_floor_1", lambda: floor_tile(1)),
    ("gale_floor_2", lambda: floor_tile(2)), ("gale_floor_3", lambda: floor_tile(3)),
    ("gale_top_0", lambda: wall_top(0)), ("gale_top_1", lambda: wall_top(1)),
    ("gale_face_0", lambda: wall_face(0)), ("gale_face_1", lambda: wall_face(1)),
    ("galesky_0", lambda: sky_tile(0)), ("galesky_1", lambda: sky_tile(1)),
    ("galesky_lip", lambda: sky_edge("lip")), ("galesky_left", lambda: sky_edge("left")),
    ("galesky_right", lambda: sky_edge("right")), ("galesky_bottom", lambda: sky_edge("bottom")),
    ("lichen_0", lambda: lichen(0)), ("lichen_1", lambda: lichen(1)),
    ("feather_0", lambda: feather_deco(0)), ("feather_1", lambda: feather_deco(1)),
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
def cloak_item():
    """The Kite Cloak, folded: sailcloth with a red kite's diamond. 16x16."""
    c = canvas(16, 16)
    for y in range(2, 14):
        half = 6 - abs(y - 7) // 2
        fill_rect(c, 8 - half, y, half * 2, 1, "l")
    for y in range(4, 12):
        half = 3 - abs(y - 7) // 2
        fill_rect(c, 8 - half, y, max(half * 2, 1), 1, "r")
    line(c, 3, 2, 12, 2, "o")
    line(c, 8, 1, 8, 14, "o")
    return rows_of(c)


def cloak_open():
    """The cloak spread wide over Wren's head as they glide. 28x12."""
    c = canvas(28, 12)
    for x in range(28):
        sag = int(3 * math.sin(math.pi * x / 27))
        for y in range(2 + (3 - sag), 7 + (3 - sag) // 2):
            put(c, x, y, "l")
    for x in range(9, 19):
        for y in range(3, 7):
            if c[y][x] == "l" and abs(x - 13.5) + abs(y - 4.5) < 5:
                c[y][x] = "r"
    line(c, 0, 5, 13, 11, "o")
    line(c, 27, 5, 14, 11, "o")
    return rows_of(c)


def fan(frame):
    """A wind fan set in the floor: a copper ring, blades turning. 16x16."""
    c = canvas(16, 16)
    fill_ellipse(c, 7.5, 8.5, 7.4, 6.4, "c")
    fill_ellipse(c, 7.5, 8.5, 5.6, 4.6, "_")
    for i in range(4):
        a = i * math.pi / 2 + frame * math.pi / 4
        line(c, 8, 9, round(7.5 + math.cos(a) * 5), round(8.5 + math.sin(a) * 4), "s")
    fill_ellipse(c, 7.5, 8.5, 1.4, 1.2, "o")
    return rows_of(c)


def lightning_rod(charged):
    """A copper lightning rod on a stone plinth. 16x40."""
    c = canvas(16, 40)
    fill_rect(c, 3, 30, 10, 9, "s")
    fill_rect(c, 2, 29, 12, 2, "s")
    line(c, 8, 3, 8, 29, "c", 1)
    line(c, 7, 8, 7, 29, "c", 1)
    for y in (12, 20):
        line(c, 5, y, 10, y, "c")
    put(c, 7, 2, "o")
    put(c, 8, 1, "o")
    put(c, 7, 1, "o")
    if charged:
        for (x, y) in ((8, 0), (6, 3), (10, 4), (5, 6), (11, 2), (9, 5)):
            put(c, x, y, "!")
        for y in range(3, 29, 3):
            put(c, 8, y, "y")
    return rows_of(c)


def heron(pose):
    """The Stormheron, 48x48: perch, flare (the tell), fly, grounded."""
    c = canvas(48, 48)
    if pose == "fly":
        # Wings spread wide, legs trailing, neck tucked.
        fill_ellipse(c, 24, 24, 9, 5, "h")
        for side in (-1, 1):
            for i in range(20):
                x = 24 + side * (6 + i)
                top = 18 - int(6 * math.sin(math.pi * i / 22))
                for y in range(top, 25 - i // 4):
                    put(c, x, y, "w" if y < top + 2 else "h")
            for i in range(0, 20, 4):
                put(c, 24 + side * (8 + i), 25 - i // 4, "k")
        fill_ellipse(c, 24, 18, 3, 3, "w")
        line(c, 26, 18, 32, 19, "y")
        put(c, 24, 17, "k")
        line(c, 22, 28, 18, 36, "k")
        line(c, 26, 28, 22, 36, "k")
        return rows_of(c)
    grounded = pose == "grounded"
    body_y = 34 if grounded else 26
    # Body and folded wing.
    fill_ellipse(c, 22, body_y, 10, 7, "h")
    fill_ellipse(c, 20, body_y + 1, 8, 5, "w" if grounded else "h")
    for i in range(8):
        put(c, 12 - i // 2, body_y + 2 + i // 3, "h")
    if pose == "flare":
        # Wings half raised, crackling.
        for side in (-1, 1):
            for i in range(12):
                x = 22 + side * (6 + i)
                for y in range(body_y - 10 + i // 2, body_y - 2):
                    put(c, x, y, "h" if y > body_y - 9 + i // 2 else "w")
        for (x, y) in ((8, 14), (37, 13), (6, 19), (40, 18)):
            put(c, x, y, "!")
            put(c, x + 1, y + 1, "y")
    if grounded:
        # Slumped, neck down along the ground, crest flat.
        line(c, 30, body_y - 2, 38, body_y + 2, "h", 1)
        line(c, 30, body_y - 1, 38, body_y + 3, "h", 1)
        fill_ellipse(c, 40, body_y + 3, 3, 2.5, "w")
        line(c, 42, body_y + 4, 47, body_y + 6, "y")
        put(c, 40, body_y + 2, "k")
        line(c, 37, body_y + 1, 33, body_y - 1, "k")
        for (x, y) in ((16, body_y - 9), (27, body_y - 10), (22, body_y - 12)):
            put(c, x, y, "!")
        return rows_of(c)
    # Long neck up, head, crest and dagger beak.
    for i in range(14):
        x = 28 + int(3 * math.sin(i * 0.35))
        put(c, x, body_y - 6 - i, "h")
        put(c, x + 1, body_y - 6 - i, "w")
    hx, hy = 30, body_y - 21
    fill_ellipse(c, hx, hy, 3.5, 3, "w")
    line(c, hx + 2, hy, hx + 13, hy + 2, "y")
    line(c, hx + 2, hy + 1, hx + 11, hy + 2, "y")
    put(c, hx + 1, hy - 1, "y")
    line(c, hx - 2, hy - 2, hx - 7, hy - 4, "k")
    line(c, hx - 2, hy - 1, hx - 8, hy - 2, "k")
    # Legs down to the perch.
    line(c, 20, body_y + 6, 20, 46, "k")
    line(c, 24, body_y + 6, 24, 46, "k")
    line(c, 18, 46, 26, 46, "k")
    return rows_of(c)


def feather_dart():
    """A storm feather, thrown like a dart. 10x6, pointing right."""
    c = canvas(10, 6)
    line(c, 0, 3, 9, 3, "k")
    for x in range(1, 7):
        put(c, x, 2, "w")
        put(c, x, 4, "h")
    put(c, 8, 2, "y")
    put(c, 9, 3, "y")
    return rows_of(c)


def storm_bell(rung):
    """The Storm Bell under its weathered frame, with a copper vane. 32x40."""
    c = canvas(32, 40)
    fill_rect(c, 2, 5, 28, 3, "s")
    fill_rect(c, 3, 8, 3, 30, "s")
    fill_rect(c, 26, 8, 3, 30, "s")
    fill_rect(c, 1, 37, 8, 3, "s")
    fill_rect(c, 23, 37, 8, 3, "s")
    # The vane on top.
    line(c, 16, 0, 16, 5, "c")
    line(c, 12, 1, 20, 1, "o")
    put(c, 21, 0, "o")
    put(c, 21, 2, "o")
    for y in range(10, 34):
        t = (y - 10) / 23.0
        half = 4 + 6 * t + (5 * (t - 0.75) / 0.25 if t > 0.75 else 0)
        for x in range(int(16 - half), int(16 + half)):
            put(c, x, y, "b")
    fill_rect(c, 15, 8, 2, 2, "c")
    for x in range(5, 27):
        if c[33][x] == "b":
            c[34][x] = "b"
    for y in (15, 28):
        for x in range(32):
            if c[y][x] == "b":
                c[y][x] = "c"
    # A lightning stroke down its waist.
    for (x, y) in ((17, 18), (16, 19), (15, 20), (16, 21), (17, 22), (16, 23), (15, 24)):
        put(c, x, y, "y" if rung else "o")
    fill_rect(c, 15, 34, 2, 3, "o")
    if rung:
        for x in range(32):
            if c[34][x] == "b":
                c[34][x] = "*"
        for (x, y) in ((4, 12), (27, 11), (2, 20), (29, 22)):
            put(c, x, y, "!")
    return rows_of(c)


def build(lit, sheet):
    """Everything in assets/gale/, as {file name: pixels}."""
    return {
        "item_kite_cloak": sheet([[lit(cloak_item(), 90)]], 16, 16),
        "cloak_open": sheet([[lit(cloak_open(), 91)]], 28, 12),
        "fan": sheet([[lit(fan(0), 92), lit(fan(1), 92)]], 16, 16),
        "lightning_rod": sheet([[lit(lightning_rod(False), 93), lit(lightning_rod(True), 93)]], 16, 40),
        "stormheron": sheet([[lit(heron(p), 94) for p in ("perch", "flare", "fly", "grounded")]], 48, 48),
        "feather_dart": sheet([[lit(feather_dart(), 95)]], 10, 6),
        "storm_bell": sheet([[lit(storm_bell(False), 96), lit(storm_bell(True), 96)]], 32, 40),
    }
