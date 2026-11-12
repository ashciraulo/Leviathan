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
    "g": ["#E8D890", "#C8B060", "#A08844", "#6E5C30", "#3A3018"],   # heron legs
}
FLAT = {
    "!": "#FFF6C0",   # spark core
    "_": "#0C0E16",   # dark inside things
    "*": "#8FC4E8",   # sky glint
    "-": "#56648A",   # crease between a heron's feather rows
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


def fill_poly(c, pts, m):
    """Fill a polygon given as (x, y) corners, by pixel centres."""
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    for y in range(max(0, int(min(ys))), min(len(c), int(max(ys)) + 1)):
        for x in range(max(0, int(min(xs))), min(len(c[0]), int(max(xs)) + 1)):
            px, py = x + 0.5, y + 0.5
            inside = False
            j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi:
                    inside = not inside
                j = i
            if inside:
                c[y][x] = m


def _heron_wing(c, sx, sy, tx, ty, droop):
    """An open wing from the shoulder (sx, sy) to the tip (tx, ty): a pale
    leading edge, grey coverts, a crease, then dark primaries splayed into
    separate fingers. `droop` is how far the trailing edge hangs below."""
    side = 1 if tx > sx else -1
    span = abs(tx - sx)
    for i in range(span + 1):
        t = i / float(span)
        x = sx + side * i
        top = sy + (ty - sy) * t - 3 * math.sin(math.pi * t)
        depth = droop * (1 - t * 0.55)
        bottom = top + max(2.0, depth)
        for y in range(int(round(top)), int(round(bottom)) + 1):
            d = y - top
            if d < 1.5:
                m = "w"
            elif d < depth * 0.45:
                m = "h"
            elif d < depth * 0.45 + 1:
                m = "-"
            else:
                m = "k" if t > 0.55 else "h"
            put(c, x, y, m)
    # Split the trailing edge into feathers: notch a gap every few pixels.
    for i in range(span * 2 // 5, span, 3):
        t = i / float(span)
        x = sx + side * i
        top = sy + (ty - sy) * t - 3 * math.sin(math.pi * t)
        bottom = int(round(top + max(2.0, droop * (1 - t * 0.55))))
        for y in range(bottom - (2 if t > 0.55 else 1), bottom + 1):
            put(c, x, y, ".")


def heron(pose):
    """The Stormheron, 48x48, facing right: perch, flare (the tell), fly,
    grounded. A grey heron's build: pale breast, grey back, black flight
    feathers and crown plume, a long S neck, a dagger beak, thin legs."""
    c = canvas(48, 48)
    if pose == "fly":
        # Wings spread wide, neck tucked into an S, legs trailing behind.
        _heron_wing(c, 20, 24, 2, 6, 8)
        _heron_wing(c, 26, 23, 44, 4, 7)
        fill_ellipse(c, 24, 27, 10, 4, "h")
        fill_ellipse(c, 30, 28, 5, 2.5, "w")
        line(c, 15, 28, 13, 27, "-")
        line(c, 14, 30, 5, 33, "g")
        line(c, 5, 33, 3, 31, "g")
        line(c, 5, 33, 2, 34, "g")
        # Neck tucked into an S, head held forward.
        fill_ellipse(c, 34, 27, 2.5, 3, "w")
        fill_ellipse(c, 37, 25, 3.5, 3, "w")
        line(c, 35, 23, 30, 22, "k")
        line(c, 35, 24, 30, 24, "k")
        put(c, 38, 24, "_")
        put(c, 38, 23, "y")
        line(c, 40, 25, 47, 27, "y")
        line(c, 40, 26, 46, 27, "o")
        return rows_of(c)
    grounded = pose == "grounded"
    body_y = 36 if grounded else 26
    if grounded:
        # Slumped on the ground, one wing spilled open, neck laid flat.
        _heron_wing(c, 18, body_y - 3, 2, body_y + 4, 7)
        fill_ellipse(c, 21, body_y, 10, 5, "h")
        fill_ellipse(c, 29, body_y + 1, 3, 4, "w")
        line(c, 13, body_y - 2, 26, body_y - 4, "-")
        for x in range(9, 15):
            put(c, x, body_y + 2 - (x - 9) // 3, "k")
        line(c, 30, body_y, 37, body_y + 4, "w", 2)
        line(c, 29, body_y - 1, 36, body_y + 3, "h", 1)
        fill_ellipse(c, 39, body_y + 5, 3.5, 2.5, "w")
        line(c, 37, body_y + 3, 31, body_y + 3, "k")
        line(c, 36, body_y + 4, 31, body_y + 5, "k")
        line(c, 40, body_y + 5, 41, body_y + 5, "_")      # eye shut
        line(c, 42, body_y + 5, 47, body_y + 8, "y")
        line(c, 42, body_y + 6, 46, body_y + 8, "o")
        for (x, y) in ((16, body_y - 11), (27, body_y - 12), (22, body_y - 14)):
            put(c, x, y, "!")
            put(c, x + 1, y + 1, "y")
        return rows_of(c)
    if pose == "flare":
        # Wings mantled up and out behind the body, crackling.
        _heron_wing(c, 19, 22, 2, 7, 10)
        _heron_wing(c, 25, 22, 45, 6, 10)
        for (x, y) in ((3, 3), (44, 2), (1, 13), (46, 12), (9, 1), (38, 0)):
            put(c, x, y, "!")
            put(c, x + 1, y + 1, "y")
    # Body: a tilted teardrop, grey back over a pale breast, tail low left.
    fill_ellipse(c, 22, body_y, 10, 6, "h")
    fill_poly(c, [(13, body_y - 3), (13, body_y + 4), (6, body_y + 7), (5, body_y + 5)], "h")
    fill_ellipse(c, 29, body_y, 4, 5, "w")
    # Folded wing: crease along its top, black primaries at the tail.
    line(c, 13, body_y - 2, 27, body_y - 4, "-")
    line(c, 14, body_y + 3, 24, body_y + 4, "-")
    for x in range(5, 15):
        for y in range(body_y + 1 + (14 - x) // 3, body_y + 4 + (14 - x) // 3):
            if c[y][x] != ".":
                put(c, x, y, "k")
    # Feathered thighs, then thin legs with a backward ankle, and toes.
    fill_rect(c, 19, body_y + 5, 3, 2, "h")
    fill_rect(c, 24, body_y + 5, 3, 2, "h")
    line(c, 20, body_y + 7, 20, 38, "g")
    line(c, 20, 38, 19, 45, "g")
    line(c, 25, body_y + 7, 25, 38, "g")
    line(c, 25, 38, 26, 45, "g")
    for fx in (19, 26):
        line(c, fx - 2, 46, fx + 3, 46, "g")
    # Long S neck: grey nape, pale throat streaked black.
    for i in range(15):
        x = 28 + int(round(2.5 * math.sin(i * 0.38)))
        y = body_y - 5 - i
        put(c, x - 1, y, "h")
        put(c, x, y, "w")
        put(c, x + 1, y, "w")
        if i % 3 == 1:
            put(c, x + 1, y, "k")
    hx, hy = 30, body_y - 21
    fill_ellipse(c, hx, hy, 3.5, 3, "w")
    # Black crown stripe running back into a two-strand plume.
    line(c, hx + 1, hy - 1, hx - 3, hy - 2, "k")
    line(c, hx - 2, hy - 2, hx - 9, hy - 4, "k")
    line(c, hx - 2, hy - 1, hx - 8, hy, "k")
    put(c, hx + 1, hy, "_")
    put(c, hx + 1, hy - 1, "y")
    # Dagger beak, gold on top, deeper below.
    line(c, hx + 3, hy, hx + 14, hy + 2, "y")
    line(c, hx + 3, hy + 1, hx + 12, hy + 2, "o")
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


def puffwisp(pose):
    """A Puffwisp: a little scrap of storm cloud with a face, that draws a
    breath and blows. 16x16. Poses: drift, swell (cheeks full), blow (lips
    pursed, a streak out front), spent (small and sagging)."""
    c = canvas(16, 16)
    size = {"drift": 1.0, "swell": 1.18, "blow": 1.05, "spent": 0.8}[pose]
    cy = 9 if pose != "spent" else 10
    for (bx, by, r) in ((8, cy, 5.0), (4.5, cy + 1, 3.2), (11.5, cy + 1, 3.2), (6, cy - 3, 3.0), (10, cy - 3, 2.8)):
        fill_ellipse(c, 8 + (bx - 8) * size, cy + (by - cy) * size, r * size, r * size * 0.9, "w")
    # A darker storm belly.
    for x in range(16):
        for y in range(cy + 2, 16):
            if c[y][x] == "w":
                c[y][x] = "h" if y < cy + 4 else "k"
    eyes = cy - 1
    if pose == "spent":
        put(c, 6, eyes, "_")
        put(c, 9, eyes, "_")
        put(c, 7, eyes + 2, "_")
        put(c, 8, eyes + 2, "_")
    else:
        put(c, 6, eyes, "_")
        put(c, 10, eyes, "_")
        if pose == "swell":
            fill_ellipse(c, 8, eyes + 3, 1.6, 1.2, "_")
        elif pose == "blow":
            put(c, 8, eyes + 2, "_")
            put(c, 9, eyes + 2, "_")
            for x in range(12, 16):
                put(c, x, eyes + 2, "*")
            put(c, 13, eyes + 1, "*")
        else:
            put(c, 8, eyes + 2, "_")
    # A spark of the storm in it.
    if pose in ("swell", "blow"):
        put(c, 4, cy - 2, "!")
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
        "puffwisp": sheet([[lit(puffwisp(p), 97) for p in ("drift", "swell", "blow", "spent")]], 16, 16),
        "storm_bell": sheet([[lit(storm_bell(False), 96), lit(storm_bell(True), 96)]], 32, 40),
    }
