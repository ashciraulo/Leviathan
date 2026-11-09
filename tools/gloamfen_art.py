"""Gloamfen: a bioluminescent swamp under a violet dusk (plan palette:
peat violet #3E3550, bog #2A2140, glow cyan #7FF5E0, spore pink #E07FC8).

Tiles are RGBA 16x16 grids; sprites are material silhouettes that
build_art.lit() shades. Imported by build_art.py.

Material letters here must not clash with other art modules (build_art
asserts it): this file uses = ? ( ) for ramps and none for flats.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
# Peat and moss: dusky violet with a green-grey moss bloom, low contrast.
PEAT = [hex_color(c) for c in ("#7A6E8A", "#655A78", "#544A68", "#443C58", "#363048", "#262036")]
MOSS = [hex_color(c) for c in ("#8AA08A", "#6E8672", "#566C5E", "#40524A")]
# Root walls: tangled black-violet roots under a teal canopy.
ROOT = [hex_color(c) for c in ("#9A86A8", "#76648A", "#584A6E", "#3E3452", "#2A2238", "#1A1424")]
CANOPY = [hex_color(c) for c in ("#4E8A84", "#3A6E6C", "#2A5458", "#1E3E46", "#142A32")]
BOG = [hex_color(c) for c in ("#4A3E6A", "#3A305A", "#2E2650", "#241E42", "#1A1634")]
GLOW = [hex_color(c) for c in ("#E8FFF8", "#B4FFF0", "#7FF5E0", "#4CC8BC", "#2E8A8A")]
SPORE = [hex_color(c) for c in ("#FFD8F0", "#F0A8DC", "#E07FC8", "#A8569A", "#6E3A6E")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def peat_tile(seed):
    """Peat floor: soft violet earth, moss patches, a few fallen needles."""
    rnd = random.Random(2400 + seed)
    px = blank(PEAT[2])
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice((PEAT[1], PEAT[3]))
    # A moss patch: a soft blob of green-grey.
    for _ in range(seed % 2):
        cx, cy, r = rnd.randrange(T), rnd.randrange(T), rnd.choice((2.5, 3.0))
        for y in range(T):
            for x in range(T):
                d = math.hypot(((x - cx) + 8) % T - 8, ((y - cy) + 8) % T - 8)
                if d < r - 0.6:
                    px[y][x] = MOSS[2] if (x + y) % 3 else MOSS[1]
                elif d < r:
                    px[y][x] = MOSS[3]
    # Needles: tiny dark diagonals.
    for _ in range(2):
        x, y = rnd.randrange(T - 2), rnd.randrange(T - 2)
        px[y][x] = PEAT[4]
        px[y + 1][x + 1] = PEAT[4]
    return px


def canopy_top(seed):
    """Wall top: the dense teal canopy over the root walls, leafy clumps."""
    rnd = random.Random(2500 + seed)
    px = blank(CANOPY[2])
    for _ in range(9):
        cx, cy = rnd.randrange(T), rnd.randrange(T)
        for y in range(T):
            for x in range(T):
                d = math.hypot(((x - cx) + 8) % T - 8, ((y - cy) + 8) % T - 8)
                if d < 2.6:
                    px[y][x] = CANOPY[1] if d < 1.6 and (x - cx) + (y - cy) < 0 else CANOPY[2]
                elif d < 3.2 and px[y][x] == CANOPY[2]:
                    px[y][x] = CANOPY[3]
    # One glowing spore caught in the leaves.
    if seed:
        px[rnd.randrange(3, 13)][rnd.randrange(3, 13)] = GLOW[2]
    return px


def root_face(seed):
    """Wall face: a tangle of roots dropping from the canopy to the bog."""
    rnd = random.Random(2600 + seed)
    px = blank(ROOT[4])
    for x in range(T):
        px[0][x] = CANOPY[1]
        px[1][x] = CANOPY[3]
        px[2][x] = ROOT[5]
    # Roots: wavy vertical strands with a lit left edge.
    for i in range(rnd.choice((3, 4))):
        x = rnd.randrange(0, T - 2)
        for y in range(3, rnd.randrange(10, T + 1)):
            xx = max(0, min(T - 2, x + (1 if (y + i * 2 + seed) % 6 < 3 else 0)))
            px[y][xx] = ROOT[2]
            px[y][xx + 1] = ROOT[3]
            if y % 4 == i % 4:
                px[y][xx] = ROOT[1]
    for x in range(T):
        px[T - 1][x] = ROOT[5]
    return px


def bog_tile(frame):
    """Still bog water: deep violet, slow ripples and drifting glow motes."""
    px = blank(BOG[2])
    for y in range(T):
        for x in range(T):
            w = math.sin((x + frame * 2) * 0.55 + y * 0.35) + math.sin(y * 0.8 - x * 0.2)
            if w > 1.35:
                px[y][x] = BOG[1]
            elif w < -1.4:
                px[y][x] = BOG[3]
    for (x, y) in ((3, 4), (12, 10), (7, 13), (13, 2)):
        xx = (x + frame) % T
        px[y][xx] = GLOW[3] if (x + y + frame) % 2 else GLOW[4]
    return px


def bog_edge(side, frame):
    """Reedy margin where the peat dips into the bog: a dark lip and reeds."""
    px = blank()
    for i in range(T):
        depth = 2 + (1 if (i * 3 + frame) % 5 < 2 else 0)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = PEAT[5] if d < depth - 1 else BOG[0]
    return px


def mire_damp(side, seed):
    """Peat darkened and wet beside the bog."""
    rnd = random.Random(2700 + seed)
    px = blank()
    for i in range(T):
        depth = 3 + rnd.randrange(3)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = (26, 20, 40, 120) if d < 2 else (26, 20, 40, 60)
    return px


def glowcap(seed):
    """A cluster of glowing toadstools that grows near the water."""
    px = blank()
    caps = ((6, 9, 3), (10, 11, 2)) if seed == 0 else ((5, 11, 2), (9, 8, 3), (12, 12, 1))
    for (cx, cy, r) in caps:
        for y in range(cy + 1, min(T, cy + 4)):
            px[y][cx] = PEAT[0]
        for x in range(cx - r, cx + r + 1):
            for dy in range(0, max(1, r - abs(x - cx) // 2)):
                if 0 <= x < T and 0 <= cy - dy < T:
                    px[cy - dy][x] = GLOW[2] if dy else GLOW[3]
        px[cy - max(0, r - 2)][cx] = GLOW[0]
    return px


def fern(seed):
    """A low violet fern."""
    px = blank()
    rnd = random.Random(2800 + seed)
    for i in range(4):
        ang = -2.5 + i * 0.9 + rnd.random() * 0.2
        for s in range(2, 7):
            x = int(round(8 + math.cos(ang) * s))
            y = int(round(12 + math.sin(ang) * s * 0.8))
            if 0 <= x < T and 0 <= y < T:
                px[y][x] = ROOT[1] if s < 5 else ROOT[0]
    px[12][7] = PEAT[5]
    px[12][8] = PEAT[5]
    return px


def motes(seed):
    """A few floating spores laid over the peat now and then."""
    px = blank()
    rnd = random.Random(2900 + seed)
    for _ in range(3):
        x, y = rnd.randrange(1, T - 1), rnd.randrange(1, T - 1)
        c = GLOW[1] if rnd.random() < 0.5 else SPORE[1]
        px[y][x] = (c[0], c[1], c[2], 200)
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            px[y + dy][x + dx] = (c[0], c[1], c[2], 50)
    return px


TILES = [
    ("fen_0", lambda: peat_tile(0)), ("fen_1", lambda: peat_tile(1)),
    ("fen_2", lambda: peat_tile(2)), ("fen_3", lambda: peat_tile(3)),
    ("canopy_top_0", lambda: canopy_top(0)), ("canopy_top_1", lambda: canopy_top(1)),
    ("root_face_0", lambda: root_face(0)), ("root_face_1", lambda: root_face(1)),
    ("gloom_0", lambda: bog_tile(0)), ("gloom_1", lambda: bog_tile(1)),
    ("reed_top_0", lambda: bog_edge("top", 0)), ("reed_bottom_0", lambda: bog_edge("bottom", 0)),
    ("reed_left_0", lambda: bog_edge("left", 0)), ("reed_right_0", lambda: bog_edge("right", 0)),
    ("reed_top_1", lambda: bog_edge("top", 1)), ("reed_bottom_1", lambda: bog_edge("bottom", 1)),
    ("reed_left_1", lambda: bog_edge("left", 1)), ("reed_right_1", lambda: bog_edge("right", 1)),
    ("mirk_top", lambda: mire_damp("top", 1)), ("mirk_bottom", lambda: mire_damp("bottom", 2)),
    ("mirk_left", lambda: mire_damp("left", 3)), ("mirk_right", lambda: mire_damp("right", 4)),
    ("glowcap_0", lambda: glowcap(0)), ("glowcap_1", lambda: glowcap(1)),
    ("frond_0", lambda: fern(0)), ("frond_1", lambda: fern(1)),
    ("motes_0", lambda: motes(0)), ("motes_1", lambda: motes(1)),
]

# --------------------------------------------------------------------------
# Sprites.
# --------------------------------------------------------------------------
RAMPS = {
    "=": ["#B48AC8", "#9068AA", "#6E4E8A", "#4E386A", "#2E2042"],   # mushroom flesh
    "?": ["#E8FFF8", "#B4FFF0", "#7FF5E0", "#4CC8BC", "#2E8A8A"],   # glow
    "(": ["#FFD8F0", "#F0A8DC", "#E07FC8", "#A8569A", "#6E3A6E"],   # spore pink
    ")": ["#E8E0D0", "#C8BCA8", "#A09480", "#706658", "#40382E"],   # pale stalk
}
FLAT = {}


# Sporecap: a waddling toadstool. When Wren comes close its cap swells
# (the tell) and it bursts a cloud of stinging spores around itself, then
# sags, spent, and can be struck without its cap in the way. 16x16 frames:
# walk_a, walk_b, swell, spent.
def sporecap(frame):
    c = [["."] * 16 for _ in range(16)]
    cap_w = {"walk_a": 5, "walk_b": 5, "swell": 7, "spent": 4}[frame]
    cap_top = {"walk_a": 3, "walk_b": 4, "swell": 1, "spent": 6}[frame]
    cap_h = {"walk_a": 4, "walk_b": 4, "swell": 6, "spent": 3}[frame]
    # Stalk and feet.
    stalk_top = cap_top + cap_h
    for y in range(stalk_top, 13):
        for x in range(6, 10):
            c[y][x] = ")"
    if frame == "walk_a":
        c[13][5], c[13][6], c[13][10] = ")", ")", ")"
    elif frame == "walk_b":
        c[13][5], c[13][9], c[13][10] = ")", ")", ")"
    else:
        for x in (5, 6, 9, 10):
            c[13][x] = ")"
    # Eyes on the stalk.
    if stalk_top + 1 < 13:
        c[stalk_top + 1][6] = "?"
        c[stalk_top + 1][9] = "?"
    # Cap: a dome with glowing spots.
    for dy in range(cap_h):
        y = cap_top + dy
        half = min(cap_w, 2 + dy * 2)
        for x in range(8 - half, 8 + half):
            if 0 <= x < 16:
                c[y][x] = "="
    spots = ((6, 1), (10, 2), (8, 3), (4, 3), (12, 4)) if frame == "swell" else ((6, 1), (9, 2), (7, 3))
    for (sx, sy) in spots:
        y = cap_top + sy
        if y < cap_top + cap_h and c[y][sx] == "=":
            c[y][sx] = "(" if frame == "swell" else "?"
    return ["".join(r) for r in c]


# The spore burst: a soft cloud of pink spores, drawn over the Sporecap.
# 64x64, centred, frames grow then thin out. The outer frames match the
# Sporecap's damage circle (radius 22) so what hurts is what shows.
def spore_cloud(frame):
    c = [["."] * 64 for _ in range(64)]
    rnd = random.Random(3000 + frame)
    radius = (20, 24, 24)[frame]
    for _ in range((90, 120, 70)[frame]):
        ang = rnd.random() * math.tau
        r = radius * math.sqrt(rnd.random())
        x, y = int(32 + math.cos(ang) * r), int(32 + math.sin(ang) * r)
        for (dx, dy) in ((0, 0), (1, 0), (0, 1)):
            if 0 <= x + dx < 64 and 0 <= y + dy < 64:
                c[y + dy][x + dx] = "("
    return ["".join(r) for r in c]
