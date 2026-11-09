"""Title art: the LEVIATHAN logo and the title-screen backdrop.

The logo's letters arch like the creature's back and rise out of the sea:
below the waterline they turn deep and translucent. The backdrop is a dusk
sea with the sleeping leviathan's back breaking the surface, Saltmarrow's
lighthouse on the far shore. Standard library only, like build_art.py.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


CLEAR = (0, 0, 0, 0)

# --------------------------------------------------------------------------
# Logo letters, drawn at half size and doubled; effects run at full size.
# --------------------------------------------------------------------------
LETTERS = {
    "L": [
        "####......",
        ".###......",
        ".###......",
        ".###......",
        ".###......",
        ".###......",
        ".###......",
        ".###......",
        ".###......",
        ".###......",
        ".###.....#",
        ".###....##",
        ".#########",
        "##########",
    ],
    "E": [
        "##########",
        ".#########",
        ".###....##",
        ".###.....#",
        ".###......",
        ".###..#...",
        ".#######..",
        ".#######..",
        ".###..#...",
        ".###......",
        ".###.....#",
        ".###....##",
        ".#########",
        "##########",
    ],
    "V": [
        "####.....####",
        ".###......##.",
        ".###......##.",
        "..###....##..",
        "..###....##..",
        "..###....##..",
        "...###..##...",
        "...###..##...",
        "...###..##...",
        "....######...",
        "....#####....",
        ".....####....",
        ".....###.....",
        "......#......",
    ],
    "I": ["#####"] + [".###."] * 12 + ["#####"],
    "A": [
        "......#......",
        ".....###.....",
        ".....####....",
        "....#####....",
        "....##.###...",
        "...###.###...",
        "...##...###..",
        "..###...###..",
        "..#########..",
        ".###########.",
        ".###.....###.",
        ".###.....###.",
        "####.....####",
        "####.....####",
    ],
    "T": [
        "#############",
        "#############",
        "##...###...##",
        "#....###....#",
    ] + [".....###....."] * 9 + ["....#####...."],
    "H": ["####.....####"] + [".###.....###."] * 5 + [".###########."] * 2
         + [".###.....###."] * 5 + ["####.....####"],
    "N": [
        "###......####",
        ".###......##.",
        ".####.....##.",
        ".#####....##.",
        ".##.###...##.",
        ".##..###..##.",
        ".##...###.##.",
        ".##....#####.",
        ".##.....####.",
        ".##......###.",
        ".##.......##.",
        ".##.......##.",
        ".##.......##.",
        "####......##.",
    ],
}

# Letter fill, top to bottom. Foam to sea glass.
FACE = [hex_color(c) for c in ("#FFFFFF", "#FFF4D6", "#D8F4E6", "#A8E6CF", "#7FD3C4", "#5FBFB7", "#3FA3A0")]
DEPTH = [hex_color(c) for c in ("#2E7F8C", "#236A80", "#1F5872", "#18324A")]
OUTLINE = hex_color("#120C22")
FOAM = hex_color("#FFF4D6")
GLINT = hex_color("#FFFFFF")


def build_logo():
    word = "LEVIATHAN"
    gap, scale, arch = 2, 2, 7
    widths = [len(LETTERS[c][0]) for c in word]
    total = sum(widths) + gap * (len(word) - 1)
    lh = 14
    pad_x, pad_top, pad_bottom = 6, 6, 10
    W = total * scale + pad_x * 2
    H = (lh + arch) * scale + pad_top + pad_bottom + 4
    mask = {}          # (x, y) -> (letter index, row within letter 0..1)
    x0 = 0
    for i, ch in enumerate(word):
        t = (x0 + widths[i] / 2) / total
        lift = round(math.sin(t * math.pi) * arch)
        oy = pad_top + (arch - lift) * scale
        for ry, row in enumerate(LETTERS[ch]):
            for rx, c in enumerate(row):
                if c != "#":
                    continue
                for sy in range(scale):
                    for sx in range(scale):
                        x = pad_x + (x0 + rx) * scale + sx
                        y = oy + ry * scale + sy
                        mask[(x, y)] = (i, (ry * scale + sy) / (lh * scale - 1))
        x0 += widths[i] + gap

    # Under the word, a swell that follows the arch.
    def swell_y(x):
        t = min(max((x - pad_x) / (total * scale), 0.0), 1.0)
        lift = math.sin(t * math.pi) * arch * scale
        return round(pad_top + (arch + lh) * scale + 5 - lift + math.sin(x / 11.0) * 1.2)

    px = [[CLEAR] * W for _ in range(H)]
    depth = 4
    for (x, y) in mask:
        for d in range(1, depth + 1):
            if (x, y + d) not in mask and y + d < H:
                cur = px[y + d][x]
                shade = DEPTH[min(d - 1, len(DEPTH) - 1)]
                if cur == CLEAR or (cur in DEPTH and DEPTH.index(cur) > DEPTH.index(shade)):
                    px[y + d][x] = shade
    for (x, y), (_, v) in mask.items():
        c = FACE[min(int(v * len(FACE)), len(FACE) - 1)]
        # Dither between bands so the gradient reads as pixel art.
        frac = v * len(FACE) % 1
        if frac > 0.75 and (x + y) % 2 == 0:
            c = FACE[min(int(v * len(FACE)) + 1, len(FACE) - 1)]
        if (x, y - 1) not in mask:
            c = GLINT
        elif (x - 1, y) not in mask and v < 0.6:
            c = FACE[0]
        elif (x + 1, y) not in mask:
            c = FACE[min(int(v * len(FACE)) + 2, len(FACE) - 1)]
        px[y][x] = c
    # The swell: two pixels of foam over sea glass, tapering at the ends.
    for x in range(pad_x - 2, W - pad_x + 2):
        y = swell_y(x)
        edge = min(x - (pad_x - 2), W - pad_x + 1 - x)
        if edge < 0:
            continue
        thick = 1 if edge < 10 else 2 if edge < 30 else 3
        for d in range(thick):
            if 0 <= y + d < H and px[y + d][x] == CLEAR:
                px[y + d][x] = FOAM if d == 0 else FACE[5 if d == 1 else 6]
    # Outline everything solid.
    solid = {(x, y) for y in range(H) for x in range(W) if px[y][x] != CLEAR}
    for y in range(H):
        for x in range(W):
            if (x, y) in solid:
                continue
            if any((x + dx, y + dy) in solid for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0))):
                px[y][x] = OUTLINE
    # Glints on the arch's crest.
    for gx, gy in ((pad_x + 48, pad_top + 6), (pad_x + 150, pad_top + 2), (pad_x + 218, pad_top + 10)):
        for d in range(-2, 3):
            for (sx, sy) in ((gx + d, gy), (gx, gy + d)):
                if 0 <= sx < W and 0 <= sy < H and px[sy][sx] != OUTLINE:
                    px[sy][sx] = GLINT if abs(d) < 2 else FACE[3]
    return px


# --------------------------------------------------------------------------
# Backdrop, 384x216: dusk sky, stars, moon, the leviathan's back, the sea.
# --------------------------------------------------------------------------
SKY = [hex_color(c) for c in ("#1A1430", "#241A3E", "#2E2050", "#3E2C5E", "#5E3E6E", "#8A4F6E", "#C26A6A", "#E8946A")]
SEA = [hex_color(c) for c in ("#2A4A6E", "#1F3A5E", "#18324A", "#142A40", "#102236")]
CREATURE = [hex_color(c) for c in ("#3A3058", "#2A2448", "#1E1A36", "#140F24")]
HORIZON = 150
# Where the tail stalk leaves the water and where the body begins.
FLUKE_X = 52
TAIL_END = 58


def build_title_bg():
    W, H = 384, 216
    rnd = random.Random(11)
    px = [[CLEAR] * W for _ in range(H)]
    # Sky in dithered bands, darkest at the top.
    for y in range(HORIZON):
        t = y / HORIZON
        f = t ** 1.6 * (len(SKY) - 1)
        i = int(f)
        frac = f - i
        for x in range(W):
            c = SKY[i]
            if i + 1 < len(SKY) and ((frac > 0.66 and (x + y) % 2 == 0) or (frac > 0.85)):
                c = SKY[i + 1]
            px[y][x] = c
    # Stars in the upper sky.
    for _ in range(90):
        x, y = rnd.randrange(W), rnd.randrange(int(HORIZON * 0.55))
        px[y][x] = hex_color("#FFF4D6") if rnd.random() < 0.3 else hex_color("#8E84A8")
    for (x, y) in ((40, 18), (300, 30), (352, 12), (90, 52)):
        for d in (-1, 1):
            px[y][x + d] = hex_color("#8E84A8")
            px[y + d][x] = hex_color("#8E84A8")
        px[y][x] = hex_color("#FFFFFF")
    # Moon, low and large, with a crescent shadow.
    mx, my, mr = 346, 34, 14
    for y in range(my - mr - 1, my + mr + 2):
        for x in range(mx - mr - 1, mx + mr + 2):
            d = math.hypot(x - mx, y - my)
            if d <= mr:
                lit_side = math.hypot(x - (mx + 7), y - (my - 5)) > mr
                c = hex_color("#FFF4D6") if not lit_side else hex_color("#E8DCC8")
                if d > mr - 1.2:
                    c = hex_color("#FFFFFF")
                px[y][x] = c
    for (cx, cy, r) in ((341, 31, 2.5), (351, 41, 1.5), (348, 27, 1)):
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                if math.hypot(x - cx, y - cy) <= r:
                    px[y][x] = hex_color("#E8DCC8")
    # Far shore with Saltmarrow's lighthouse.
    for x in range(0, 120):
        top = HORIZON - 4 - round(3 * math.sin(x / 17.0) + (120 - x) / 14)
        for y in range(top, HORIZON):
            px[y][x] = hex_color("#2A2238")
    lx = 18
    lbase = HORIZON - 12
    for y in range(lbase - 20, lbase):
        half = 2 if y > lbase - 14 else 1
        for x in range(lx - half, lx + half + 1):
            band = ((lbase - y) // 4) % 2
            px[y][x] = hex_color("#3E2C4A") if band else hex_color("#5E4E70")
    for y in range(lbase - 24, lbase - 20):
        for x in range(lx - 1, lx + 2):
            px[y][x] = hex_color("#FFE36E")
    # Lighthouse beam fanning right.
    for i in range(1, 70):
        y = lbase - 22
        spread = i // 10
        for dy in range(-spread, spread + 1):
            x = lx + 1 + i
            if 0 <= y + dy < HORIZON and (i + dy) % 2 == 0 and i < 60:
                px[y + dy][x] = hex_color("#C8A0A0") if i > 30 else hex_color("#E8C0A0")
    # The sea.
    for y in range(HORIZON, H):
        t = (y - HORIZON) / (H - HORIZON)
        i = min(int(t * (len(SEA) + 0.5)), len(SEA) - 1)
        for x in range(W):
            px[y][x] = SEA[i]
    # Moon path on the water.
    for y in range(HORIZON + 1, H):
        spread = 3 + (y - HORIZON) // 6
        for x in range(mx - spread, mx + spread + 1):
            if 0 <= x < W and rnd.random() < 0.25 and (y % 3) != 0:
                px[y][x] = hex_color("#A8E6CF") if rnd.random() < 0.5 else hex_color("#5FBFB7")
    # Wave lines.
    for _ in range(140):
        y = rnd.randrange(HORIZON + 2, H)
        x = rnd.randrange(W)
        ln = 2 + (y - HORIZON) // 12
        for d in range(ln):
            if x + d < W:
                px[y][x + d] = hex_color("#2E5E7E")
    # The leviathan asleep: one long body from the tail stalk on the left,
    # over the great humped back, dipping at the neck, up to a broad head
    # with a heavy brow, a closed eye and a long jaw resting on the water.
    water = HORIZON + 9

    def back(x):
        if x < TAIL_END:
            return water
        # The tail rises out of the water and thickens into the body.
        tail = min((x - TAIL_END) / 56.0, 1.0) ** 0.8 * 17
        body = math.exp(-((x - 165) / 70.0) ** 2) * 42
        return water - max(tail if x < 140 else 0, body, head_height(x))

    def head_height(x):
        # Skull: rises steeply from the neck to a domed crown...
        if x < 248 or x > 342:
            return 0.0
        if x <= 284:
            return 30 * math.sin((x - 248) / 36.0 * math.pi / 2) ** 1.4
        # ...then a long snout slopes gently down to a rounded nose.
        t = (x - 284) / 58.0
        h = 30 - 20 * t ** 1.2
        if x > 330:
            h *= math.sqrt(max(0.0, 1 - ((x - 330) / 12.0) ** 2))
        return h

    def fill_column(x, top, bottom):
        for y in range(max(top, 0), min(bottom, H)):
            depth = y - top
            c = CREATURE[0] if depth < 2 else CREATURE[1] if depth < 8 else CREATURE[2]
            if y >= water - 1:
                c = CREATURE[3]
            px[y][x] = c
        if 0 < top < H:
            px[top - 1][x] = hex_color("#120C22")

    for x in range(TAIL_END, 344):
        top = round(back(x))
        if top < water:
            fill_column(x, top, water + 2)
    # Tail fluke: a stalk and two curved lobes rising from the water.
    fluke = set()
    for y in range(water - 14, water + 2):
        half = 2 + (y - (water - 14)) // 6
        for x in range(FLUKE_X - half, FLUKE_X + 1 + half):
            fluke.add((x, y))
    for side in (-1, 1):
        for i in range(40):
            t = i / 39.0
            cx = FLUKE_X + side * (4 + 16 * t)
            cy = water - 13 - 18 * t + 8 * t * t
            r = 3.2 * (1 - t) + 0.6
            for y in range(int(cy - r) - 1, int(cy + r) + 2):
                for x in range(int(cx - r) - 1, int(cx + r) + 2):
                    if math.hypot(x - cx, y - cy) <= r:
                        fluke.add((x, y))
    for x in range(30, 80):
        col = [y for y in range(H) if (x, y) in fluke]
        if not col:
            continue
        top = min(col)
        for y in col:
            depth = y - top
            px[y][x] = CREATURE[0] if depth < 2 else CREATURE[1] if depth < 6 else CREATURE[2]
            if y >= water - 1:
                px[y][x] = CREATURE[3]
    for (x, y) in fluke:
        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            if (x + dx, y + dy) not in fluke and y + dy < water:
                px[y + dy][x + dx] = hex_color("#120C22")
    # Scales: little arcs in rows across the back.
    for row in range(3):
        for sx in range(80, 240, 8):
            x = sx + (4 if row % 2 else 0)
            top = round(back(x))
            y = top + 6 + row * 6
            if y + 2 >= water - 1:
                continue
            for dx, dy in ((-2, 0), (-1, 1), (0, 1), (1, 1), (2, 0)):
                px[y + dy][x + dx] = CREATURE[0]
    # Dorsal ridge spines.
    for sx in range(84, 236, 9):
        top = round(back(sx))
        h = round((6 + 2 * math.sin(sx / 13.0)) * min(1.0, (sx - 76) / 40.0, (240 - sx) / 26.0))
        if h < 2:
            continue
        for d in range(h):
            for w in range(-(h - d) // 3, (h - d) // 3 + 1):
                px[top - d][sx + w] = CREATURE[0] if w <= 0 else CREATURE[1]
        px[top - h][sx] = hex_color("#120C22")
    # Rim light from the moon along right-facing slopes.
    for x in range(36, 340):
        top = round(back(x))
        if top >= water - 1:
            continue
        if back(x + 1) - back(x - 1) > 0.2:
            px[top][x] = hex_color("#8E84A8")
            px[top + 1][x] = hex_color("#5E5088")
    # The head. Brow ridge: a lighter bulge over the eye.
    ex = 296
    ey = round(back(ex)) + 9
    for dx in range(-7, 7):
        y = ey - 4 + (1 if abs(dx) > 4 else 0)
        px[y][ex + dx] = hex_color("#4A3E72")
        px[y + 1][ex + dx] = CREATURE[0]
    # The closed eye: a lid line curving down with lashes beneath.
    for dx in range(-4, 5):
        y = ey + round(1.5 * (1 - (dx / 4.5) ** 2))
        px[y][ex + dx] = hex_color("#B8A8E0")
    for dx in (-3, 0, 3):
        y = ey + round(1.5 * (1 - (dx / 4.5) ** 2)) + 1
        px[y][ex + dx] = hex_color("#120C22")
    # Jaw: a long mouth line from the nose back under the eye, with a
    # faint lip of light above it.
    for x in range(270, 340):
        t = (x - 270) / 69.0
        y = water - 4 - round(4 * t) + round(2 * t * t)
        if y > round(back(x)) + 2:
            px[y][x] = hex_color("#120C22")
            px[y - 1][x] = CREATURE[1]
    # Nostril near the end of the snout.
    nx = 332
    ny = round(back(nx)) + 2
    for dx in range(3):
        px[ny + (dx == 2)][nx + dx] = hex_color("#120C22")
    # Gill ridges behind the head: three curved folds.
    for gx in (256, 262, 268):
        top = round(back(gx))
        for y in range(top + 6, min(top + 17, water - 3)):
            bend = round(2.0 * math.sin((y - top - 6) / 10.0 * math.pi))
            px[y][gx + bend] = CREATURE[0]
            px[y][gx + bend + 1] = hex_color("#120C22")
    # A small frill of spines at the back of the skull.
    for i, sx in enumerate((262, 268, 274)):
        top = round(back(sx))
        h = 3 + i
        for d in range(h):
            px[top - d][sx] = CREATURE[0]
            if d < h - 1:
                px[top - d][sx + 1] = CREATURE[1]
        px[top - h][sx] = hex_color("#120C22")
    # Glowing runes along the back, pulsing with the lullaby.
    for rx in (138, 172, 206):
        y = round(back(rx)) + 4
        for (dx, dy) in ((0, 0), (1, -1), (2, 0), (3, 1), (4, 0)):
            px[y + dy][rx + dx] = hex_color("#6EF0E0")
    # Breath bubbles rising from the snout.
    for (bx, by, r) in ((344, water - 8, 1), (348, water - 16, 1.5), (343, water - 26, 2)):
        for y in range(int(by - r) - 1, int(by + r) + 2):
            for x in range(int(bx - r) - 1, int(bx + r) + 2):
                d = math.hypot(x - bx, y - by)
                if r - 0.6 <= d <= r + 0.5:
                    px[y][x] = hex_color("#A8E6CF")
        px[int(by - r)][int(bx)] = hex_color("#FFFFFF")
    # Foam and ripples where the creature meets the water.
    for x in range(30, 346):
        top = round(back(x))
        touching = top < water or FLUKE_X - 5 <= x < FLUKE_X + 6
        if touching and rnd.random() < 0.8:
            y = water + rnd.choice((0, 0, 1))
            px[y][x] = hex_color("#FFF4D6") if rnd.random() < 0.4 else hex_color("#A8E6CF")
    for (x0, x1, y) in ((24, 60, water + 4), (80, 150, water + 5), (190, 300, water + 4),
                        (60, 120, water + 9), (230, 340, water + 10), (300, 350, water + 3)):
        for x in range(x0, x1):
            if (x // 3) % 3:
                px[y][x] = hex_color("#2E7F8C")
    return px
