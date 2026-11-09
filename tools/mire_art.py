"""Lantern Mire (Gloamfen's dungeon): a drowned lantern shrine in the
glowing swamp, where families hung lights for their dead. Floor and wall
tiles, black bog water, glow mushrooms and spore puffs, and its pieces: the
Glowmoth Lantern, braziers, veiled planks that only show in lantern light,
Shades, wisps, the Pale Congregation's core and the Moth Bell.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes that build_art.lit() shades. Imported by build_art.py,
which writes the sprites to assets/mire/.

Palette anchors from the plan (Gloamfen): bog violet #4B3F72, midnight
#1B1630, glow mint #8FE3C8, spore pink #F56FAD.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)

# --------------------------------------------------------------------------
# Materials. Letters are ones no other art file uses.
# --------------------------------------------------------------------------
RAMPS = {
    "!": ["#8E84B8", "#6A5E98", "#4B3F72", "#33294E", "#1B1630"],   # bog-violet stone
    "#": ["#E0FFF4", "#B4F2DC", "#8FE3C8", "#4FA894", "#1E5450"],   # glow mint
    "^": ["#FFD0E8", "#FA9CCB", "#F56FAD", "#B8407E", "#5A1A44"],   # spore pink
    "=": ["#C8A870", "#A08050", "#7A5E3A", "#54402E", "#2A1E1A"],   # old lantern brass
    ":": ["#F4F0FF", "#DCD6F2", "#B8B0DA", "#8078A8", "#3A3458"],   # pale wisp-light
    ";": ["#5A5070", "#3E3654", "#2A243C", "#1C1828", "#0C0A12"],   # shade
    ",": ["#9A8A74", "#7A6A58", "#5A4C40", "#3E342E", "#1E1818"],   # drowned timber
}
FLAT = {
    "~": "#FFF6C0",   # lantern flame core
    "`": "#8FE3C8",   # mint glow
    "|": "#F56FAD",   # pink glow
    "_": "#0C0A12",   # the dark inside things
}

# --------------------------------------------------------------------------
# Tiles.
# --------------------------------------------------------------------------
SLAB = [hex_color(c) for c in ("#6E6290", "#5A4E7C", "#4B3F72", "#3E3460", "#30284C", "#1E1834")]
MOSS = [hex_color(c) for c in ("#5A8A6E", "#3E6A58", "#2E5048")]
ROOT = [hex_color(c) for c in ("#5A4A5E", "#463A4C", "#33293A", "#221A28", "#140F1A")]
BOG = [hex_color(c) for c in ("#3A3A5E", "#2A2A48", "#1E1E38", "#16162C", "#0E0E20")]
MINT = hex_color("#8FE3C8")
MINT_DIM = hex_color("#4FA894")
PINK = hex_color("#F56FAD")


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def floor_tile(seed):
    """Old shrine flagstones in bog violet, big uneven slabs that run across
    tiles (only some tiles have a join on an edge, and a crack now and then
    wanders through one), moss in the joins and, here and there, a cushion of it on the stone."""
    rnd = random.Random(2400 + seed)
    base = SLAB[2]
    px = blank(base)
    join, lip = SLAB[4], SLAB[1]
    if seed in (0, 1):
        for x in range(T):
            px[T - 1][x] = join
            px[0][x] = lip if px[0][x] == base else px[0][x]
    if seed in (0, 2):
        for y in range(T):
            px[y][T - 1] = join
    if seed == 1:
        y = rnd.randrange(5, 10)
        for x in range(T):
            if rnd.random() < 0.3:
                y = max(3, min(T - 4, y + rnd.choice((-1, 1))))
            px[y][x] = join
            if rnd.random() < 0.35:
                px[y - 1][x] = rnd.choice(MOSS)
    # Moss creeping out of the joins.
    for y in range(T):
        for x in range(T):
            if px[y][x] == join and rnd.random() < 0.2:
                px[y][x] = rnd.choice(MOSS)
    # Worn, lighter patches and dark pits in the stone.
    for _ in range(3):
        cx, cy = rnd.randrange(2, T - 5), rnd.randrange(2, T - 3)
        for dx in range(rnd.randrange(2, 4)):
            if px[cy][cx + dx] == base:
                px[cy][cx + dx] = SLAB[1]
    for _ in range(5):
        x, y = rnd.randrange(1, T - 1), rnd.randrange(1, T - 1)
        if px[y][x] == base:
            px[y][x] = SLAB[3]
    # A low cushion of moss grown over the stone.
    if seed == 3:
        cx, cy = rnd.randrange(4, 11), rnd.randrange(4, 11)
        for y in range(T):
            for x in range(T):
                d = ((x - cx) / 2.6) ** 2 + ((y - cy) / 1.6) ** 2
                if d <= 1.0 and rnd.random() < 0.8:
                    px[y][x] = MOSS[2] if d > 0.5 else MOSS[1]
        px[cy - 1][cx] = MOSS[0]
    return px


def wall_top(seed):
    """The shrine's walls from above: stone half-swallowed by roots."""
    rnd = random.Random(2500 + seed)
    px = blank(ROOT[3])
    for _ in range(4):
        y = rnd.randrange(T)
        for x in range(T):
            yy = (y + int(2 * math.sin((x + seed * 5) * 0.5))) % T
            px[yy][x] = ROOT[1]
            px[(yy + 1) % T][x] = ROOT[2]
    for _ in range(6):
        px[rnd.randrange(T)][rnd.randrange(T)] = ROOT[4]
    return px


def wall_face(seed):
    """Wall face: dark stone blocks with roots hanging over them."""
    rnd = random.Random(2600 + seed)
    px = blank(SLAB[4])
    for course in range(3):
        y0 = course * 5
        shift = 4 if course % 2 else 0
        for y in range(y0, min(y0 + 4, T)):
            for x in range(T):
                if (x + shift) % 8 == 7:
                    px[y][x] = SLAB[5]
                    continue
                px[y][x] = SLAB[3] if y == y0 else SLAB[4]
    # Roots hanging down from the top.
    for _ in range(3):
        x = rnd.randrange(1, T - 1)
        for y in range(rnd.randrange(5, 12)):
            px[y][x] = ROOT[2]
            if y % 3 == 0:
                x = min(max(x + rnd.choice((-1, 1)), 0), T - 1)
    for x in range(T):
        px[T - 1][x] = SLAB[5]
    return px


def bog_tile(frame):
    """Black bog water with drifting specks of light."""
    rnd = random.Random(2700)
    px = blank(BOG[3])
    for y in range(T):
        for x in range(T):
            if (x * 3 + y + frame * 5) % 11 == 0:
                px[y][x] = BOG[2]
    for i in range(3):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[(y + frame) % T][(x + frame * (i - 1)) % T] = MINT_DIM if i else MINT
    return px


def bog_edge(side, frame):
    """A soft mossy bank on the water tile's open side."""
    px = blank()
    for i in range(T):
        for d in range(2):
            col = MOSS[1] if d == 0 else BOG[1]
            if side == "top":
                px[d][i] = col
            elif side == "bottom":
                px[T - 1 - d][i] = col
            elif side == "left":
                px[i][d] = col
            else:
                px[i][T - 1 - d] = col
    if side == "top" and frame:
        for x in range(0, T, 5):
            px[2][x] = BOG[0]
    return px


def wet_edge(side, seed):
    rnd = random.Random(2800 + seed)
    px = blank()
    wet = hex_color("#141024", 80)
    for i in range(T):
        for d in range(1 + rnd.randrange(3)):
            if side == "top":
                px[d][i] = wet
            elif side == "bottom":
                px[T - 1 - d][i] = wet
            elif side == "left":
                px[i][d] = wet
            else:
                px[i][T - 1 - d] = wet
    return px


def glow_shrooms(seed):
    """A cluster of mint glow mushrooms."""
    px = blank()
    rnd = random.Random(2900 + seed)
    for _ in range(3):
        x, y = rnd.randrange(3, 12), rnd.randrange(6, 13)
        px[y][x] = MINT
        px[y][x + 1] = MINT
        px[y - 1][x] = hex_color("#E0FFF4")
        px[y + 1][x] = MOSS[2]
    return px


def spore_puff(seed):
    """A pink spore puff on a stalk."""
    px = blank()
    rnd = random.Random(3000 + seed)
    x, y = rnd.randrange(4, 11), rnd.randrange(6, 11)
    for dy in range(3):
        px[y + dy][x] = MOSS[1]
    px[y - 1][x] = PINK
    px[y - 1][x + 1] = PINK
    px[y - 2][x] = hex_color("#FFD0E8")
    px[y - 1][x - 1] = hex_color("#B8407E")
    return px


def lantern_post_tile(seed):
    """A little hanging lantern on a stake (floor overlay)."""
    px = blank()
    x = 7 + seed
    for y in range(6, 15):
        px[y][x] = ROOT[1]
    px[5][x - 1] = ROOT[1]
    px[6][x - 2] = hex_color("#FFE36E")
    px[7][x - 2] = hex_color("#F2A541")
    return px


TILES = [
    ("mire_floor_0", lambda: floor_tile(0)), ("mire_floor_1", lambda: floor_tile(1)),
    ("mire_floor_2", lambda: floor_tile(2)), ("mire_floor_3", lambda: floor_tile(3)),
    ("mire_top_0", lambda: wall_top(0)), ("mire_top_1", lambda: wall_top(1)),
    ("mire_face_0", lambda: wall_face(0)), ("mire_face_1", lambda: wall_face(1)),
    ("murk_0", lambda: bog_tile(0)), ("murk_1", lambda: bog_tile(1)),
    ("murkbank_top_0", lambda: bog_edge("top", 0)), ("murkbank_bottom_0", lambda: bog_edge("bottom", 0)),
    ("murkbank_left_0", lambda: bog_edge("left", 0)), ("murkbank_right_0", lambda: bog_edge("right", 0)),
    ("murkbank_top_1", lambda: bog_edge("top", 1)), ("murkbank_bottom_1", lambda: bog_edge("bottom", 1)),
    ("murkbank_left_1", lambda: bog_edge("left", 1)), ("murkbank_right_1", lambda: bog_edge("right", 1)),
    ("mirewet_top", lambda: wet_edge("top", 1)), ("mirewet_bottom", lambda: wet_edge("bottom", 2)),
    ("mirewet_left", lambda: wet_edge("left", 3)), ("mirewet_right", lambda: wet_edge("right", 4)),
    ("shrooms_0", lambda: glow_shrooms(0)), ("shrooms_1", lambda: glow_shrooms(1)),
    ("spores_0", lambda: spore_puff(0)), ("spores_1", lambda: spore_puff(1)),
    ("grave_lamp_0", lambda: lantern_post_tile(0)), ("grave_lamp_1", lambda: lantern_post_tile(1)),
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
# Pieces.
# --------------------------------------------------------------------------
def lantern_item():
    """The Glowmoth Lantern: a brass cage with a moth of light inside. 16x16."""
    c = canvas(16, 16)
    line(c, 6, 1, 9, 1, "=")
    put(c, 5, 2, "=")
    put(c, 10, 2, "=")
    fill_rect(c, 4, 4, 8, 9, "=")
    fill_rect(c, 5, 5, 6, 7, "#")
    # The moth's wings.
    put(c, 6, 7, ":")
    put(c, 9, 7, ":")
    put(c, 7, 8, "~")
    put(c, 8, 8, "~")
    put(c, 6, 9, ":")
    put(c, 9, 9, ":")
    fill_rect(c, 3, 13, 10, 2, "=")
    for x in (6, 9):
        for y in range(5, 12):
            put(c, x, y, "=") if y in (5, 11) else None
    return rows_of(c)


def lantern_held():
    """The lantern as Wren holds it up. 8x10."""
    c = canvas(8, 10)
    put(c, 3, 0, "=")
    put(c, 4, 0, "=")
    fill_rect(c, 1, 2, 6, 6, "=")
    fill_rect(c, 2, 3, 4, 4, "#")
    put(c, 3, 4, "~")
    put(c, 4, 4, "~")
    fill_rect(c, 1, 8, 6, 1, "=")
    return rows_of(c)


def brazier(lit):
    """A stone bowl on a short pillar, for lantern light. 16x20, foot 18."""
    c = canvas(16, 20)
    fill_rect(c, 5, 10, 6, 8, "!")
    fill_ellipse(c, 7.5, 9.0, 6.5, 2.5, "!")
    fill_rect(c, 3, 17, 10, 2, "!")
    fill_ellipse(c, 7.5, 8.5, 4.5, 1.2, "_")
    if lit:
        fill_ellipse(c, 7.5, 5.5, 3.0, 4.0, "#")
        fill_ellipse(c, 7.5, 6.5, 1.6, 2.4, ":")
        put(c, 7, 7, "~")
        put(c, 8, 7, "~")
    return rows_of(c)


def shade(frame):
    """A Shade: a low smear of living dark with two pale eyes. Exposed by the
    lantern, it rears up, shrinking from the light. 16x16, foot 14."""
    c = canvas(16, 16)
    if frame in (0, 1):
        sway = frame
        fill_ellipse(c, 7.5, 11.0, 7.0, 3.5, ";")
        fill_ellipse(c, 7.5 + sway, 8.5, 4.0, 3.0, ";")
        for x in range(1, 15, 3):
            put(c, x + sway, 14, ";")
        put(c, 6 + sway, 8, ":")
        put(c, 9 + sway, 8, ":")
    else:
        fill_ellipse(c, 7.5, 9.0, 5.0, 5.5, ";")
        fill_ellipse(c, 7.5, 13.0, 6.5, 1.8, ";")
        line(c, 2, 4, 4, 8, ";")
        line(c, 13, 4, 11, 8, ";")
        put(c, 6, 7, "~")
        put(c, 9, 7, "~")
        fill_rect(c, 6, 10, 4, 1, "_")
    return rows_of(c)


def wisp(frame):
    """A wisp: a pale flame with a mint heart. 10x12, foot 11."""
    c = canvas(10, 12)
    fill_ellipse(c, 4.5, 7.0, 3.5, 3.6, ":")
    lean = 1 if frame else -1
    line(c, 4, 4, 4 + lean, 1, ":")
    put(c, 5, 3, ":")
    fill_ellipse(c, 4.5, 7.5, 1.6, 1.8, "#")
    put(c, 4, 7, "~")
    return rows_of(c)


def heart(frame):
    """The Pale Congregation's heart: a pearl of dreaming light, pulsing.
    20x20, foot 18."""
    c = canvas(20, 20)
    r = 7.0 if frame == 0 else 7.6
    fill_ellipse(c, 9.5, 9.5, r, r, ":")
    fill_ellipse(c, 9.5, 9.0, r - 2.5, r - 2.5, "#")
    fill_ellipse(c, 8.5, 8.0, 2.0, 2.0, "~")
    # A faint calf curled inside.
    line(c, 6, 11, 12, 11, "!")
    line(c, 12, 11, 13, 9, "!")
    return rows_of(c)


def veil_plank():
    """A plank of the old boardwalk, drowned and only half real: shown in
    lantern light. 16x16 (drawn with transparency by the game)."""
    c = canvas(16, 16)
    for board in range(3):
        y0 = 1 + board * 5
        fill_rect(c, 0, y0, 16, 4, ",")
    for x in (3, 12):
        for y in range(16):
            if c[y][x] == ",":
                c[y][x] = "_" if y % 5 == 3 else ","
    return rows_of(c)


def moth_bell(rung):
    """The Moth Bell: the third Tidebell, pale silver-brass, hung from a
    frame of drowned timber with lanterns at the corners. 32x40, foot 37."""
    c = canvas(32, 40)
    fill_rect(c, 3, 4, 26, 3, ",")
    fill_rect(c, 4, 7, 3, 31, ",")
    fill_rect(c, 25, 7, 3, 31, ",")
    fill_rect(c, 2, 36, 7, 2, ",")
    fill_rect(c, 23, 36, 7, 2, ",")
    fill_rect(c, 14, 7, 4, 3, "=")
    for y in range(10, 33):
        t = (y - 10) / 22.0
        half = 4 + 6 * t + (5 * (t - 0.75) / 0.25 if t > 0.75 else 0)
        for x in range(int(16 - half), int(16 + half)):
            put(c, x, y, ":")
    for x in range(5, 27):
        if c[32][x] == ":":
            c[33][x] = ":"
    for y in (14, 27):
        for x in range(32):
            if c[y][x] == ":":
                c[y][x] = "=" if not rung else "#"
    # A moth spread across the waist.
    for (x, y) in ((12, 19), (13, 20), (14, 21), (19, 19), (18, 20), (17, 21), (15, 21), (16, 21), (15, 22), (16, 22)):
        put(c, x, y, "#" if rung else "!")
    fill_rect(c, 15, 33, 2, 3, "=")
    # Little lanterns hanging from the frame.
    for x in (3, 27):
        put(c, x + 1, 8, "=")
        put(c, x + 1, 9, "~" if rung else "=")
    if rung:
        for x in range(32):
            if c[33][x] == ":":
                c[33][x] = "`"
    return rows_of(c)


def build(lit, sheet):
    """Everything in assets/mire/, as {file name: pixels}."""
    return {
        "item_glowmoth_lantern": sheet([[lit(lantern_item(), 80)]], 16, 16),
        "lantern_held": sheet([[lit(lantern_held(), 81)]], 8, 10),
        "brazier": sheet([[lit(brazier(False), 82), lit(brazier(True), 82)]], 16, 20),
        "shade": sheet([[lit(shade(0), 83), lit(shade(1), 83), lit(shade(2), 83)]], 16, 16),
        "wisp": sheet([[lit(wisp(0), 84), lit(wisp(1), 84)]], 10, 12),
        "heart": sheet([[lit(heart(0), 85), lit(heart(1), 85)]], 20, 20),
        "veil_plank": sheet([[lit(veil_plank(), 86)]], 16, 16),
        "moth_bell": sheet([[lit(moth_bell(False), 87), lit(moth_bell(True), 87)]], 32, 40),
    }
