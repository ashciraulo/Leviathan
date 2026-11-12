"""Hollow Glacier (Frostspine's dungeon): caves worn through an old glacier,
blue ice over black water, where the floor slides out from under you.
Floor, wall and ice tiles, frozen water, rime and snow, and its pieces: the
Frostfang Bow and its arrows, ice eyes, the skating Rimeling, Rimeback the
walrus and its ice chunks, and the Frost Bell.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes shaded by build_art.lit(), with this file's own
materials (RAMPS, FLAT). Imported by build_art.py, which writes the sprites
to assets/glacier/.

Palette: packed snow #E4EEF6, glacier blue #7EC4E4, deep ice #2E6C9A,
black water #12283A, walrus hide #8A6A5A, tusk ivory #F0E6CC.
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
    "i": ["#E8F8FF", "#B6E2F6", "#7EC4E4", "#4A92BE", "#244E74"],   # glacier ice
    "s": ["#FFFFFF", "#E4EEF6", "#C0D2E2", "#8EA4BC", "#4E6078"],   # snow
    "h": ["#C8A890", "#A88470", "#8A6A5A", "#644A40", "#34241E"],   # walrus hide
    "t": ["#FFFAEE", "#F0E6CC", "#D2C4A2", "#A49472", "#5A4E3A"],   # tusk ivory
    "k": ["#4A4E5E", "#363A48", "#262834", "#181A22", "#0C0C12"],   # dark eye, nose
    "w": ["#C8B488", "#A08660", "#7A6040", "#54402A", "#2A2016"],   # bow wood
    "b": ["#D4DCE8", "#A8B4C8", "#8090AA", "#56647E", "#2C3446"],   # bell silver
    "f": ["#B0F0FF", "#6ADCF6", "#34B4E0", "#1E7CAE", "#0E4064"],   # frost glow
    "d": ["#8CC4E2", "#5CA8D2", "#3A84B4", "#2A6894", "#163A5C"],   # shadowed ice
    "m": ["#E6CCB4", "#D0B096", "#B89278", "#94725C", "#4A342A"],   # pale muzzle
}
FLAT = {
    "!": "#FFFFFF",   # glint
    "_": "#0A1420",   # dark inside things
    "*": "#9AF0FF",   # cold spark
    "-": "#4A3428",   # a fold in the hide
    "~": "#E4F4FC",   # rime crusted on the hide
}

# --------------------------------------------------------------------------
# Tiles.
# --------------------------------------------------------------------------
SNOW = [hex_color(c) for c in ("#F4F8FC", "#E4EEF6", "#D2E0EC", "#BCCEDE", "#A2B6CA", "#7E94AC")]
ICE = [hex_color(c) for c in ("#D8F2FC", "#B6E2F6", "#94D2EE", "#7EC4E4", "#5CA8D2", "#3A84B4")]
DEEP = [hex_color(c) for c in ("#3A7AA6", "#2E6C9A", "#245A84", "#1A4668", "#12283A")]
WATER = [hex_color(c) for c in ("#1C3A52", "#163246", "#12283A", "#0E2030")]
RIME = [hex_color(c, a) for c, a in (("#FFFFFF", 220), ("#E4EEF6", 160), ("#E4EEF6", 90))]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def floor_tile(seed):
    """Packed snow over rock. One even base on every variant, so no tile
    stands out as a square; wind has drawn long soft ripples across it, blue
    shadow pools in the hollows, and here and there grit or a glint shows."""
    rnd = random.Random(4100 + seed)
    px = blank(SNOW[1])
    for _ in range(8):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((SNOW[0], SNOW[2], SNOW[2]))
    # A long, gently curving wind ripple: shadow under a bright crest,
    # running off both sides of the tile.
    if seed in (0, 1):
        y0 = rnd.randrange(3, 13)
        phase = rnd.random() * 6.28
        for x in range(T):
            y = y0 + int(round(1.4 * math.sin(phase + x * 0.35)))
            px[y][x] = SNOW[3] if x % 7 else SNOW[2]
            px[y - 1][x] = SNOW[0]
    # A soft blue hollow.
    if seed == 2:
        cx, cy = rnd.randrange(5, 11), rnd.randrange(5, 11)
        for y in range(T):
            for x in range(T):
                d = ((x - cx) / 4.5) ** 2 + ((y - cy) / 2.5) ** 2
                if d <= 1.0 and (d < 0.6 or (x + y) % 2):
                    px[y][x] = SNOW[2]
    if seed == 3:
        for (x, y) in ((4, 5), (11, 10), (7, 12)):
            px[y][x] = SNOW[5]
        px[3][12] = SNOW[0]
    return px


def wall_top(seed):
    """The glacier from above: deep snow heaped on the ice, pale and
    lumpy, with blue showing in the cracks between the drifts."""
    rnd = random.Random(4200 + seed)
    px = blank(SNOW[3])
    for y in range(T):
        for x in range(T):
            if (x + (5 if y >= 8 else 0)) % 8 == 0 or y in (0, 8):
                px[y][x] = ICE[4]
            elif y in (1, 9) or (x + (5 if y >= 8 else 0)) % 8 == 1:
                px[y][x] = SNOW[4]
            elif y in (3, 11):
                px[y][x] = SNOW[2]
    for _ in range(6):
        px[rnd.randrange(T)][rnd.randrange(T)] = rnd.choice((SNOW[1], SNOW[2], SNOW[4]))
    return px


def wall_face(seed):
    """The ice wall's face: tall clear blue with darker veins and a snow cap."""
    rnd = random.Random(4300 + seed)
    px = blank(ICE[4])
    for y in range(T):
        for x in range(T):
            if y < 2:
                px[y][x] = SNOW[1] if y == 0 else SNOW[3]
            elif (x + seed * 3) % 7 == 0 and y > 3:
                px[y][x] = ICE[5]
            elif (x + seed * 3) % 7 == 1 and y > 3:
                px[y][x] = ICE[2]
    # Drips and icicle shadows.
    for _ in range(2):
        x = rnd.randrange(1, T - 1)
        for y in range(2, 2 + rnd.randrange(3, 8)):
            px[y][x] = ICE[1]
    if seed == 1:
        for y in range(6, 12):
            px[y][9] = DEEP[3]
            px[y][10] = DEEP[2]
    for x in range(T):
        px[T - 1][x] = DEEP[3]
    return px


def ice_tile(seed):
    """Slick blue ice laid over the floor: Wren slides on it. Long scratches
    and a pale shine so it reads apart from snow at a glance."""
    rnd = random.Random(4400 + seed)
    px = blank(ICE[3])
    for y in range(T):
        for x in range(T):
            if (x - y + seed * 4) % 11 == 0:
                px[y][x] = ICE[1]
            elif (x - y + seed * 4) % 11 == 1:
                px[y][x] = ICE[2]
    for _ in range(2):
        x0, y0 = rnd.randrange(T - 6), rnd.randrange(T)
        for i in range(rnd.randrange(4, 7)):
            px[y0][x0 + i] = ICE[0]
    for _ in range(4):
        px[rnd.randrange(T)][rnd.randrange(T)] = ICE[4]
    return px


def water_tile(frame):
    """Black water under the glacier, barely moving."""
    px = blank(WATER[2])
    for y in range(T):
        for x in range(T):
            if (x * 3 + y * 5 + frame * 4) % 19 == 0:
                px[y][x] = WATER[0]
            elif (x + y * 2 + frame * 3) % 17 == 0:
                px[y][x] = WATER[3]
    return px


def floe_tile(seed):
    """Water a frost arrow has frozen: a lid of new ice, cloudy white at the
    heart where the arrow went in, darker water still showing round the rim."""
    rnd = random.Random(4500 + seed)
    px = blank(DEEP[0])
    for y in range(T):
        for x in range(T):
            d = math.hypot(x - 7.5, y - 7.5)
            if d < 4.5:
                px[y][x] = ICE[2]
            elif d < 7:
                px[y][x] = ICE[4] if (x + y) % 3 else ICE[3]
            if x in (0, T - 1) or y in (0, T - 1):
                px[y][x] = DEEP[1]
    for _ in range(3):
        a = rnd.random() * math.tau
        for r in range(2, 8):
            x = round(7.5 + math.cos(a) * r)
            y = round(7.5 + math.sin(a) * r)
            if 0 <= x < T and 0 <= y < T:
                px[y][x] = ICE[0]
    px[7][7] = px[8][8] = SNOW[0]
    return px


def rime_edge(side):
    """Frost creeping onto the floor from water."""
    px = blank()
    for i in range(T):
        for d in range(3):
            c = RIME[d] if (i + d) % 3 != 2 or d == 0 else CLEAR
            if side == "top":
                px[d][i] = c
            elif side == "bottom":
                px[T - 1 - d][i] = c
            elif side == "left":
                px[i][d] = c
            elif side == "right":
                px[i][T - 1 - d] = c
    return px


def frost_crack(seed):
    rnd = random.Random(4600 + seed)
    px = blank()
    x, y = rnd.randrange(3, 8), rnd.randrange(3, 8)
    for _ in range(8):
        px[y][x] = ICE[4]
        x = min(max(x + rnd.choice((0, 1, 1)), 0), T - 1)
        y = min(max(y + rnd.choice((-1, 0, 1)), 0), T - 1)
    return px


def snowdrift(seed):
    """A little drift of loose snow."""
    px = blank()
    cx, cy = (6, 10) if seed == 0 else (9, 6)
    for y in range(T):
        for x in range(T):
            d = ((x - cx) / 4.5) ** 2 + ((y - cy) / 2.2) ** 2
            if d <= 1.0:
                px[y][x] = SNOW[0] if y < cy else SNOW[2]
    return px


def crevasse(frame):
    """A crevasse: blue ice walls dropping away into the dark."""
    px = blank(DEEP[4])
    for y in range(T):
        for x in range(T):
            if (x * 7 + y * 3 + frame * 5) % 29 == 0:
                px[y][x] = DEEP[3]
    if frame == 1:
        for y in range(4, 12):
            px[y][5] = DEEP[3]
            px[y + 1][10] = DEEP[3]
    return px


def crevasse_edge(side):
    """The crevasse's lip: the far wall shows deep blue ice going down."""
    px = blank()
    for i in range(T):
        if side == "lip":
            for y in range(0, 7):
                px[y][i] = ICE[1] if y == 0 else ICE[4] if y < 3 else DEEP[0] if y < 5 else DEEP[2]
        elif side == "bottom":
            px[T - 1][i] = SNOW[0]
            px[T - 2][i] = ICE[3]
        elif side == "left":
            px[i][0] = SNOW[1]
            px[i][1] = ICE[4]
        elif side == "right":
            px[i][T - 1] = ICE[4]
            px[i][T - 2] = DEEP[1]
    return px


TILES = [
    ("glacier_floor_0", lambda: floor_tile(0)), ("glacier_floor_1", lambda: floor_tile(1)),
    ("glacier_floor_2", lambda: floor_tile(2)), ("glacier_floor_3", lambda: floor_tile(3)),
    ("icecave_top_0", lambda: wall_top(0)), ("icecave_top_1", lambda: wall_top(1)),
    ("icecave_face_0", lambda: wall_face(0)), ("icecave_face_1", lambda: wall_face(1)),
    ("glacier_ice_0", lambda: ice_tile(0)), ("glacier_ice_1", lambda: ice_tile(1)),
    ("icewater_0", lambda: water_tile(0)), ("icewater_1", lambda: water_tile(1)),
    ("floe_0", lambda: floe_tile(0)), ("floe_1", lambda: floe_tile(1)),
    ("rime_top", lambda: rime_edge("top")), ("rime_bottom", lambda: rime_edge("bottom")),
    ("rime_left", lambda: rime_edge("left")), ("rime_right", lambda: rime_edge("right")),
    ("frostcrack_0", lambda: frost_crack(0)), ("frostcrack_1", lambda: frost_crack(1)),
    ("snowdrift_0", lambda: snowdrift(0)), ("snowdrift_1", lambda: snowdrift(1)),
    ("crevasse_0", lambda: crevasse(0)), ("crevasse_1", lambda: crevasse(1)),
    ("crevasse_lip", lambda: crevasse_edge("lip")), ("crevasse_left", lambda: crevasse_edge("left")),
    ("crevasse_right", lambda: crevasse_edge("right")), ("crevasse_bottom", lambda: crevasse_edge("bottom")),
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
def bow_item():
    """The Frostfang Bow: a curved bow of pale wood, tipped with ice fangs,
    and a frost arrow nocked. 16x16."""
    c = canvas(16, 16)
    for y in range(1, 15):
        x = 4 + round(3.2 * math.sin(math.pi * (y - 1) / 13))
        put(c, x, y, "w")
        put(c, x + 1, y, "w" if 3 < y < 12 else ".")
    for (x, y) in ((4, 0), (3, 1), (4, 15), (3, 14)):
        put(c, x, y, "f")
    line(c, 4, 1, 4, 14, "s")
    line(c, 2, 8, 14, 8, "w")
    put(c, 15, 8, "f")
    put(c, 14, 7, "f")
    put(c, 14, 9, "f")
    put(c, 2, 7, "s")
    put(c, 2, 9, "s")
    return rows_of(c)


def bow_drawn():
    """The bow held out, string drawn back. 16x16, facing right."""
    c = canvas(16, 16)
    for y in range(1, 15):
        x = 9 + round(3 * math.sin(math.pi * (y - 1) / 13))
        put(c, x, y, "w")
    put(c, 9, 0, "f")
    put(c, 9, 15, "f")
    line(c, 9, 1, 4, 8, "s")
    line(c, 4, 8, 9, 14, "s")
    line(c, 4, 8, 14, 8, "i")
    put(c, 15, 8, "f")
    return rows_of(c)


def frost_arrow():
    """A frost arrow in flight: ice head, white fletching. 12x5, pointing right."""
    c = canvas(12, 5)
    line(c, 1, 2, 9, 2, "w")
    put(c, 10, 1, "f")
    put(c, 10, 2, "f")
    put(c, 10, 3, "f")
    put(c, 11, 2, "*")
    for x in (0, 1, 2):
        put(c, x, 1, "s")
        put(c, x, 3, "s")
    return rows_of(c)


def ice_eye(lit):
    """An eye frozen in a crystal of ice on a snow-packed plinth. Shoot it and
    it wakes and glows. 16x24."""
    c = canvas(16, 24)
    fill_rect(c, 2, 17, 12, 6, "s")
    fill_rect(c, 1, 16, 14, 2, "s")
    # The crystal: a tall hexagon.
    for y in range(1, 17):
        half = min(y + 1, 6, 17 - y + 2)
        fill_rect(c, 8 - half, y, half * 2, 1, "i")
    line(c, 5, 3, 5, 14, "f" if lit else "i")
    # The eye.
    fill_ellipse(c, 7.5, 9, 3.6, 2.4 if lit else 0.9, "s" if lit else "k")
    if lit:
        fill_ellipse(c, 7.5, 9, 1.5, 1.6, "f")
        put(c, 7, 8, "!")
        for (x, y) in ((1, 3), (14, 5), (2, 13), (13, 12)):
            put(c, x, y, "*")
    return rows_of(c)


def rimeling(frame):
    """A Rimeling: a round little ice imp that skates on its belly, spikes of
    frost down its back. 16x16, two frames."""
    c = canvas(16, 16)
    fill_ellipse(c, 8, 10, 6.4, 4.4, "i")
    fill_ellipse(c, 8, 11, 4.5, 2.6, "s")
    for i, x in enumerate((4, 7, 10)):
        h = 3 + (i + frame) % 2
        line(c, x, 6, x + 1, 6 - h, "f")
    put(c, 6, 9, "k")
    put(c, 10, 9, "k")
    put(c, 6, 8, "!")
    if frame == 1:
        line(c, 2, 14, 14, 14, "s")
    else:
        line(c, 3, 14, 13, 14, "i")
    return rows_of(c)


def rimeback(pose):
    """Rimeback, an ancient walrus with an iceberg grown on its back. 64x56.
    Poses: up (risen from a hole, eyes squeezed shut), spit (head back,
    mouth open), dazed (burst up through the ice, eyes wide and open to an
    arrow) and under (only the iceberg showing above the water).

    Drawn to read at a glance: the berg in lit and shadowed facets with
    cracks, a rime crust where it grows out of the hide, folds of hide on a
    heavy body with flippers, and a head set apart from the body by a fold,
    with pale whisker pads, nostrils and long tusks."""
    c = canvas(64, 56)
    peaks = [(14, 18), (22, 6), (30, 12), (38, 2), (46, 14), (52, 24)]

    def berg(top_limit, bottom, left, right):
        for x in range(left, right):
            top = 99
            near = peaks[0]
            for (px_, py) in peaks:
                t = py + abs(x - px_) * 1.4
                if t < top:
                    top, near = t, (px_, py)
            top = max(top, top_limit)
            for y in range(int(top), bottom):
                # Faces left of a peak catch the light; right of it, shadow.
                put(c, x, y, "i" if x <= near[0] else "d")
        for (px_, py) in peaks:
            if py + 1 < top_limit:
                continue
            put(c, px_, int(py), "!")
            put(c, px_ - 1, int(py) + 1, "s")
            put(c, px_, int(py) + 1, "s")

    if pose == "under":
        # Just the berg's tip and a ring of ripples.
        for y in range(28, 46):
            half = (y - 26) // 2 + 3
            for x in range(30 - half, 30 + half):
                put(c, x, y, "i" if x < 30 else "d")
        put(c, 29, 27, "!")
        line(c, 29, 30, 25, 40, "s")
        line(c, 33, 31, 35, 38, "_")
        for x in range(12, 52):
            if x % 3:
                put(c, x, 47, "f")
        return rows_of(c)
    base = 54
    # The heavy body rising out of the water, with front flippers.
    fill_ellipse(c, 32, base - 9, 27, 12, "h")
    fill_ellipse(c, 9, base - 3, 6, 3, "h")
    fill_ellipse(c, 55, base - 3, 6, 3, "h")
    line(c, 6, base - 3, 12, base - 2, "-")
    line(c, 52, base - 2, 58, base - 3, "-")
    # The berg on its back: lit and shadowed faces, a few deep cracks.
    berg(0, base - 15, 10, 56)
    line(c, 22, 9, 19, 22, "_")
    line(c, 38, 5, 41, 20, "_")
    line(c, 30, 15, 31, 26, "s")
    line(c, 46, 17, 49, 30, "s")
    # Rime crusted where the berg grows out of the hide.
    for x in range(9, 57):
        if c[base - 16][x] in ("i", "d"):
            put(c, x, base - 15, "~")
            if x % 4 == 1:
                put(c, x, base - 14, "~")
    # Folds of old hide along the flank.
    for (x0, x1, y) in ((10, 18, base - 9), (46, 54, base - 9), (12, 20, base - 5), (44, 52, base - 5)):
        line(c, x0, y, x1, y + 1, "-")
    # The head at the front, set off from the body by a fold.
    hy = base - 12 if pose != "dazed" else base - 8
    hy = hy - 4 if pose == "spit" else hy
    fill_ellipse(c, 32, hy, 13, 9, "-")
    fill_ellipse(c, 32, hy, 12, 8, "h")
    # Brow ridge.
    line(c, 23, hy - 5, 41, hy - 5, "-")
    # Whisker pads, pale, with whisker dots, and nostrils between.
    pad = "t" if pose == "spit" else "m"
    fill_ellipse(c, 27, hy + 3, 5.5, 3.6, pad)
    fill_ellipse(c, 37, hy + 3, 5.5, 3.6, pad)
    for (x, y) in ((24, hy + 2), (26, hy + 4), (28, hy + 2), (36, hy + 2), (38, hy + 4), (40, hy + 2)):
        put(c, x, y, "-")
    put(c, 31, hy, "k")
    put(c, 33, hy, "k")
    if pose == "spit":
        fill_ellipse(c, 32, hy + 7, 4, 2.6, "_")
        for (x, y) in ((30, hy + 11), (34, hy + 12), (32, hy + 14)):
            put(c, x, y, "*")
    # Long tusks, pale with a dark edge.
    tusk_len = 13
    line(c, 28, hy + 6, 27, hy + 6 + tusk_len, "t", 2)
    line(c, 35, hy + 6, 36, hy + 6 + tusk_len, "t", 2)
    # Eyes.
    for ex in (25, 39):
        if pose == "dazed":
            fill_ellipse(c, ex, hy - 2, 2.6, 2.4, "s")
            put(c, ex, hy - 2, "k")
            put(c, ex + 1, hy - 2, "k")
            put(c, ex - 1, hy - 3, "!")
        else:
            # Squeezed shut: a lid line that dips.
            line(c, ex - 2, hy - 3, ex, hy - 2, "k")
            line(c, ex, hy - 2, ex + 2, hy - 3, "k")
    if pose == "dazed":
        for (x, y) in ((18, hy - 12), (46, hy - 13), (32, hy - 15)):
            put(c, x, y, "*")
            put(c, x + 1, y + 1, "!")
        # Broken ice round it.
        for x in range(2, 62, 5):
            fill_rect(c, x, base - 1 - (x % 3), 4, 2, "s")
    return rows_of(c)


def ice_chunk():
    """A chunk of ice it spits. 8x8."""
    c = canvas(8, 8)
    for y in range(1, 7):
        half = 3 - abs(y - 3.5) // 2
        fill_rect(c, int(4 - half), y, int(half * 2), 1, "i")
    put(c, 3, 2, "!")
    put(c, 4, 6, "f")
    return rows_of(c)


def frost_bell(rung):
    """The Frost Bell, silver furred with rime, hung in a frame of ice. 32x40."""
    c = canvas(32, 40)
    fill_rect(c, 2, 5, 28, 3, "i")
    fill_rect(c, 3, 8, 3, 30, "i")
    fill_rect(c, 26, 8, 3, 30, "i")
    fill_rect(c, 1, 37, 8, 3, "s")
    fill_rect(c, 23, 37, 8, 3, "s")
    for x in (4, 9, 14, 19, 24):
        line(c, x, 8, x, 10 + x % 3, "i")
    for y in range(10, 34):
        t = (y - 10) / 23.0
        half = 4 + 6 * t + (5 * (t - 0.75) / 0.25 if t > 0.75 else 0)
        for x in range(int(16 - half), int(16 + half)):
            put(c, x, y, "b")
    fill_rect(c, 15, 8, 2, 2, "i")
    for x in range(5, 27):
        if c[33][x] == "b":
            c[34][x] = "b"
    for y in (15, 28):
        for x in range(32):
            if c[y][x] == "b":
                c[y][x] = "s"
    # A six-pointed frost star on its waist.
    for a in range(6):
        ang = a * math.pi / 3
        line(c, 16, 21, round(16 + math.cos(ang) * 3), round(21 + math.sin(ang) * 3), "f" if rung else "i")
    fill_rect(c, 15, 34, 2, 3, "i")
    if rung:
        for x in range(32):
            if c[34][x] == "b":
                c[34][x] = "*"
        for (x, y) in ((4, 12), (27, 11), (2, 20), (29, 22)):
            put(c, x, y, "!")
    return rows_of(c)


def build(lit, sheet):
    """Everything in assets/glacier/, as {file name: pixels}."""
    return {
        "item_frostfang_bow": sheet([[lit(bow_item(), 100)]], 16, 16),
        "bow_drawn": sheet([[lit(bow_drawn(), 101)]], 16, 16),
        "frost_arrow": sheet([[lit(frost_arrow(), 102)]], 12, 5),
        "ice_eye": sheet([[lit(ice_eye(False), 103), lit(ice_eye(True), 103)]], 16, 24),
        "rimeling": sheet([[lit(rimeling(0), 104), lit(rimeling(1), 104)]], 16, 16),
        "rimeback": sheet([[lit(rimeback(p), 105) for p in ("up", "spit", "dazed", "under")]], 64, 56),
        "ice_chunk": sheet([[lit(ice_chunk(), 106)]], 8, 8),
        "frost_bell": sheet([[lit(frost_bell(False), 107), lit(frost_bell(True), 107)]], 32, 40),
    }
