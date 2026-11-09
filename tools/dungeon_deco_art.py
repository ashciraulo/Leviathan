#!/usr/bin/env python3
"""Wall and floor dressing for the eight dungeons: a crack, something
growing (or hanging) and a light set into the wall faces, and two little
heaps of debris at the foot of the walls. All are transparent overlays
drawn over a dungeon's own wall face or floor tiles (scripts/world/room.gd
picks them by the room's biome, "wall_deco" in its tile table), so each
dungeon only needs its colours and the kind of thing that grows there.

Tile names: <dungeon>_wallcrack, <dungeon>_wallgrowth, <dungeon>_walllight,
<dungeon>_lightpool (its glow on the floor below),
<dungeon>_rubble_0 and <dungeon>_rubble_1. build_art.py adds them to the
world tile sheet.
"""

import math
import random

T = 16
CLEAR = (0, 0, 0, 0)


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def blank():
    return [[CLEAR] * T for _ in range(T)]


def put(px, x, y, c):
    if 0 <= x < T and 0 <= y < T:
        px[y][x] = c


# Each dungeon: crack shadow and lit edge, what grows on its walls (kind and
# three colours), its light (kind, three body colours, three flame/glow
# colours) and its debris (three colours, plus an accent).
DUNGEONS = {
    "hull": {
        "crack": ("#2A1A12", "#8A6448"),
        "growth": ("barnacle", ("#E8E0C8", "#B8AC90", "#6E6450")),
        "light": ("lantern", ("#3A3026", "#6E5A40", "#A08452"), ("#FFF2B0", "#FFC860", "#E08A30")),
        "rubble": (("#8A6448", "#6A4A34", "#4A3224"), "#C8BC9C"),
    },
    "kiln": {
        "crack": ("#1A0E0C", "#E8742A"),
        "growth": ("soot", ("#2A2020", "#3A2C2A", "#4E3D3B")),
        "light": ("brazier", ("#2A2222", "#4A3A36", "#6E5650"), ("#FFF0A0", "#FFA040", "#E05A20")),
        "rubble": (("#7A6260", "#584543", "#3A2C2A"), "#E8742A"),
    },
    "mire": {
        "crack": ("#1E1834", "#6E6290"),
        "growth": ("roots", ("#3E6A58", "#5A8A6E", "#2E5048")),
        "light": ("candle", ("#4B3F72", "#6E6290", "#E8E0D0"), ("#F2FFE0", "#C8F0A0", "#8ADC90")),
        "rubble": (("#6E6290", "#4B3F72", "#30284C"), "#5A8A6E"),
    },
    "gale": {
        "crack": ("#36405A", "#8E9CB4"),
        "growth": ("lichen", ("#B8C870", "#8EA058", "#6A7A44")),
        "light": ("glass", ("#36405A", "#5A6886", "#8E9CB4"), ("#FFFFFF", "#CDE6F6", "#8FC4E8")),
        "rubble": (("#8E9CB4", "#6A7A96", "#4C5A76"), "#B8C870"),
    },
    "glacier": {
        "crack": ("#244E74", "#E8F8FF"),
        "growth": ("icicles", ("#FFFFFF", "#B6E2F6", "#7EC4E4")),
        "light": ("crystal", ("#12283A", "#244E74", "#1E7CAE"), ("#FFFFFF", "#9AF0FF", "#34B4E0")),
        "rubble": (("#E4EEF6", "#BCCEDE", "#7E94AC"), "#94D2EE"),
    },
    "belfry": {
        "crack": ("#20382F", "#9CC2B4"),
        "growth": ("weed", ("#6AA04A", "#4E8038", "#36602A")),
        "light": ("anemone", ("#20382F", "#34564C", "#4A7266"), ("#FFF4F0", "#FFA0B4", "#E0607A")),
        "rubble": (("#86B0A2", "#5E8A7E", "#34564C"), "#D8D0B8"),
    },
    "tomb": {
        "crack": ("#20160F", "#A89478"),
        "growth": ("web", ("#F0EAD8", "#CCC4B0", "#A89C88")),
        "light": ("skull", ("#7A6A54", "#CCBC9C", "#F6EEDA"), ("#FFF6C0", "#FFD070", "#E09040")),
        "rubble": (("#E8DCC0", "#CCBC9C", "#A89478"), "#6E5838"),
    },
    "maw": {
        "crack": ("#3A0E1A", "#E08A9A"),
        "growth": ("vein", ("#9AF0E8", "#54D8D0", "#2E9AA0")),
        "light": ("node", ("#6A2232", "#8E3446", "#B85468"), ("#F0FFFF", "#9AF0E8", "#54D8D0")),
        "rubble": (("#F2E6D0", "#D8C8A8", "#A89478"), "#B85468"),
    },
}


def wall_crack(name):
    """A crack wandering down the wall face: shadow, and a lit lip beside it."""
    dark, lit = (hex_color(c) for c in DUNGEONS[name]["crack"])
    rnd = random.Random(sum(map(ord, name)) * 7)
    px = blank()
    x, y = rnd.randrange(5, 11), rnd.randrange(1, 4)
    while y < T - 2:
        put(px, x, y, dark)
        if px[y][x + 1 if x + 1 < T else x] == CLEAR:
            put(px, x + 1, y, lit)
        if rnd.random() < 0.25:
            # A short branch.
            bx = x + rnd.choice((-1, 1))
            put(px, bx, y + 1, dark)
            put(px, bx + (bx - x), y + 2, dark)
        y += 1
        x += rnd.choice((-1, 0, 0, 1))
        x = max(2, min(T - 4, x))
    return px


def wall_growth(name):
    kind, cols = DUNGEONS[name]["growth"]
    a, b, c = (hex_color(x) for x in cols)
    rnd = random.Random(sum(map(ord, name)) * 11)
    px = blank()
    if kind == "barnacle":
        # Clusters of barnacles low on the planking, where the bilge reached.
        for _ in range(5):
            cx, cy = rnd.randrange(2, 14), rnd.randrange(8, 14)
            put(px, cx, cy, b)
            put(px, cx + 1, cy, b)
            put(px, cx, cy - 1, a)
            put(px, cx + 1, cy + 1, c)
            put(px, cx, cy + 1, c)
    elif kind == "soot":
        # A plume of soot licked up the wall from a vent.
        cx = rnd.randrange(5, 10)
        for y in range(T):
            width = int(1 + (T - y) * 0.25)
            for x in range(cx - width, cx + width + 1):
                if rnd.random() < 0.55 + y * 0.02:
                    put(px, x + int(math.sin(y * 0.6) * 1.5), y, (a, b, c)[min(2, abs(x - cx))])
    elif kind in ("roots", "weed"):
        # Roots (or weed) hanging over the top of the wall.
        for _ in range(4):
            x = rnd.randrange(1, 15)
            length = rnd.randrange(5, 12)
            for y in range(length):
                put(px, x, y, b if y < length - 2 else a)
                if kind == "weed" and y % 3 == 2:
                    put(px, x + 1, y, c)
                x += rnd.choice((0, 0, 1, -1)) if y % 2 else 0
                x = max(0, min(T - 1, x))
            put(px, x, length, c)
    elif kind == "lichen":
        for _ in range(4):
            cx, cy = rnd.randrange(2, 14), rnd.randrange(2, 13)
            for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (1, 1)):
                if rnd.random() < 0.8:
                    put(px, cx + dx, cy + dy, (a, b, c)[rnd.randrange(3)])
    elif kind == "icicles":
        for x in range(1, 15, 3):
            length = rnd.randrange(3, 9)
            for y in range(length):
                put(px, x + rnd.choice((0, 1)) if y == 0 else x, y, a if y == 0 else b)
                if y < length - 2:
                    put(px, x + 1, y, c)
    elif kind == "web":
        # A cobweb strung across the top corner.
        for i in range(10):
            put(px, i, 0, b)
            put(px, 0, i, b)
            put(px, i, i, a)
        for r in (4, 7, 10):
            for t in range(r + 1):
                put(px, t, r - t, c if t % 2 else b)
    elif kind == "vein":
        # A glowing vein branching through the flesh.
        x, y = rnd.randrange(3, 7), 0
        while y < T:
            put(px, x, y, b)
            put(px, x + 1, y, c)
            if y % 4 == 2:
                for i in range(1, 4):
                    put(px, x + 1 + i, y + i // 2, c)
            if y % 5 == 0:
                put(px, x, y, a)
            y += 1
            x = max(1, min(T - 3, x + rnd.choice((-1, 0, 1))))
    return px


def wall_light(name):
    """A light set into the wall face, with a soft halo round it."""
    kind, body, glow = DUNGEONS[name]["light"]
    b0, b1, b2 = (hex_color(c) for c in body)
    g0, g1, g2 = (hex_color(c) for c in glow)
    px = blank()
    cx, cy = 8, 6
    # The halo first, faint and round, so the light itself draws over it.
    hr, hg, hb, _ = g2
    for y in range(T):
        for x in range(T):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d < 7.5:
                px[y][x] = (hr, hg, hb, int(110 * (1 - d / 7.5)))
    if kind in ("lantern", "brazier", "candle", "skull"):
        # A bracket into the wall and a flame.
        for y in range(cy + 2, cy + 6):
            put(px, cx, y, b0)
        put(px, cx - 1, cy + 5, b0)
        put(px, cx + 1, cy + 5, b0)
        if kind == "lantern":
            for y in range(cy - 2, cy + 3):
                put(px, cx - 2, y, b1)
                put(px, cx + 2, y, b1)
            for x in range(cx - 2, cx + 3):
                put(px, x, cy - 3, b2)
                put(px, x, cy + 2, b2)
            put(px, cx, cy - 4, b0)
        elif kind == "brazier":
            for x in range(cx - 3, cx + 4):
                put(px, x, cy + 1, b1)
                put(px, x, cy + 2, b2 if x in (cx - 3, cx + 3) else b1)
            put(px, cx - 2, cy - 1, g2)
            put(px, cx + 2, cy - 1, g2)
            put(px, cx - 1, cy - 2, g1)
            put(px, cx + 1, cy - 3, g2)
        elif kind == "candle":
            for y in range(cy - 1, cy + 2):
                put(px, cx, y, b2)
            put(px, cx - 1, cy + 2, b1)
            put(px, cx + 1, cy + 2, b1)
            put(px, cx, cy + 2, b1)
        elif kind == "skull":
            for x in range(cx - 2, cx + 3):
                for y in range(cy, cy + 3):
                    put(px, x, y, b2)
            put(px, cx - 1, cy + 1, b0)
            put(px, cx + 1, cy + 1, b0)
            put(px, cx, cy + 3, b1)
        # The flame.
        put(px, cx, cy - 1, g1)
        put(px, cx, cy - 2, g0)
        put(px, cx - 1, cy - 1, g2)
        put(px, cx + 1, cy - 1, g2)
        put(px, cx, cy, g1)
    else:
        # A glowing thing set in the wall: glass, crystal, anemone, node.
        if kind == "glass":
            for y in range(cy - 2, cy + 3):
                for x in range(cx - 2, cx + 3):
                    if abs(x - cx) + abs(y - cy) <= 3:
                        put(px, x, y, g1)
            put(px, cx, cy, g0)
            for x in range(cx - 3, cx + 4):
                put(px, x, cy + 3, b1)
            put(px, cx, cy - 3, b0)
        elif kind == "crystal":
            # A cluster of glowing shards: a tall one between two short ones,
            # dark-edged so they read against pale ice.
            for (sx, top, h) in ((cx, cy - 4, 8), (cx - 3, cy, 4), (cx + 3, cy - 1, 5)):
                for i in range(h):
                    half = 0 if i == 0 else 1
                    for dx in range(-half - 1, half + 2):
                        put(px, sx + dx, top + i, b0)
                for i in range(h):
                    half = 0 if i == 0 else 1
                    for dx in range(-half, half + 1):
                        put(px, sx + dx, top + i, g1 if dx < 1 else g2)
                put(px, sx, top + 1, g0)
            for x in range(cx - 5, cx + 6):
                put(px, x, cy + 4, b1)
        elif kind == "anemone":
            for t in range(7):
                ang = math.pi * (0.1 + 0.8 * t / 6)
                for r in (2, 3):
                    put(px, cx + int(round(math.cos(ang) * r * 1.2)), cy - int(round(math.sin(ang) * r)), g1 if r == 3 else g2)
            for x in range(cx - 2, cx + 3):
                put(px, x, cy + 1, b1)
                put(px, x, cy + 2, b0)
            put(px, cx, cy, g0)
        elif kind == "node":
            for y in range(cy - 2, cy + 3):
                for x in range(cx - 2, cx + 3):
                    if (x - cx) ** 2 + (y - cy) ** 2 <= 5:
                        put(px, x, y, g1)
            put(px, cx, cy, g0)
            put(px, cx - 1, cy - 1, g0)
            for y in range(cy + 3, T):
                put(px, cx + (y % 2), y, b1)
    return px


def light_pool(name):
    """The light's glow pooled on the floor at the foot of the wall."""
    _, _, glow = DUNGEONS[name]["light"]
    r, g, b, _ = hex_color(glow[1])
    px = blank()
    for y in range(T):
        for x in range(T):
            d = ((x + 0.5 - 8) / 8.0) ** 2 + ((y + 0.5) / 9.0) ** 2
            if d < 1.0:
                px[y][x] = (r, g, b, int(64 * (1 - d)))
    return px


def rubble(name, seed):
    """A little heap of debris at the foot of a wall (the top of a floor tile)."""
    cols, accent = DUNGEONS[name]["rubble"]
    a, b, c = (hex_color(x) for x in cols)
    acc = hex_color(accent)
    shadow = (c[0] * 3 // 5, c[1] * 3 // 5, c[2] * 3 // 5, 255)
    rnd = random.Random(sum(map(ord, name)) * 13 + seed)
    px = blank()
    for _ in range(4 if seed == 0 else 3):
        cx, cy = rnd.randrange(3, 13), rnd.randrange(1, 6)
        w = rnd.randrange(1, 3)
        for dx in range(-w, w + 1):
            put(px, cx + dx, cy, b)
            put(px, cx + dx, cy + 1, c)
            put(px, cx + dx, cy + 2, shadow)
        put(px, cx - w - 1, cy + 1, shadow)
        put(px, cx + w + 1, cy + 1, shadow)
        put(px, cx, cy - 1, a)
    for _ in range(3):
        put(px, rnd.randrange(1, 15), rnd.randrange(0, 8), rnd.choice((b, c)))
    put(px, rnd.randrange(3, 13), rnd.randrange(2, 7), acc)
    return px


TILES = []
for _name in DUNGEONS:
    TILES += [
        ("%s_wallcrack" % _name, (lambda n=_name: wall_crack(n))),
        ("%s_wallgrowth" % _name, (lambda n=_name: wall_growth(n))),
        ("%s_walllight" % _name, (lambda n=_name: wall_light(n))),
        ("%s_lightpool" % _name, (lambda n=_name: light_pool(n))),
        ("%s_rubble_0" % _name, (lambda n=_name: rubble(n, 0))),
        ("%s_rubble_1" % _name, (lambda n=_name: rubble(n, 1))),
    ]
