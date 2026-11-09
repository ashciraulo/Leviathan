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
# Backdrop, 384x216: a cutaway of the sea at dusk. Above the water: sky,
# moon, Saltmarrow's lighthouse and a fishing boat. Below it, filling the
# deep and running off every edge, the sleeping leviathan, its flank
# speckled with light. Its breath rises as bubbles to the surface; its
# breathing is the tide. The glow is also drawn on its own layer
# (build_title_glow) so the title can pulse it slowly, like breathing.
# --------------------------------------------------------------------------
SKY = [hex_color(c) for c in ("#1A1430", "#241A3E", "#2E2050", "#3E2C5E", "#5E3E6E", "#8A4F6E", "#C26A6A", "#E8946A")]
DEEP = [hex_color(c) for c in ("#2A5A7A", "#1F4A6A", "#183C5A", "#13304C", "#0F263E", "#0C1E32", "#091628", "#070F1E")]
HIDE = [hex_color(c) for c in ("#2C4A66", "#1C3048", "#142438", "#0E1A2A", "#0A1220", "#070C18")]
GLOW = hex_color("#8FFFF0")
GLOW_MID = hex_color("#4FD8D0")
GLOW_DIM = hex_color("#2A8A96")
ROCK = [hex_color(c) for c in ("#4A3E5E", "#2E2640", "#1E1A30")]
W, H = 384, 216
HORIZON = 112
SURFACE = HORIZON + 2


def _back_top(x):
    """Top of the leviathan's back: in from the left, deep, rising over the
    shoulders, then the great head on the right with a brow over the eye."""
    body = 196 - 50 * math.exp(-((x - 170) / 120.0) ** 2)
    head = 150 + 22 * ((x - 315) / 80.0) ** 2 if x > 200 else 400
    # A smooth minimum, so the neck dips softly instead of creasing.
    k = 5.0
    return -k * math.log(math.exp(-body / k) + math.exp(-head / k))


def _eye():
    return 316, 178


def _glow_spots():
    """Bright points: the lateral line along the flank and a lower row,
    each (x, y, size)."""
    spots = []
    for x in range(-4, 252, 8):
        y = round(_back_top(x)) + 22 + round(3 * math.sin(x / 23.0))
        spots.append((x, y, 2 if (x // 8) % 3 == 0 else 1))
    for x in range(20, 236, 11):
        y = round(_back_top(x)) + 40 + round(2 * math.sin(x / 17.0 + 1))
        spots.append((x, y, 1))
    # None behind the title menu, so its words stay easy to read.
    return [(x, y, r) for (x, y, r) in spots if 0 <= x < W and SURFACE + 4 < y < H
            and not (148 <= x <= 240 and 150 <= y <= 206)]


def _eye_seam():
    """The closed eye: a long curved seam with light seeping out of it."""
    ex, ey = _eye()
    pts = []
    for dx in range(-17, 18):
        pts.append((ex + dx, ey + round(3.0 * (1 - (dx / 17.5) ** 2))))
    return pts


def build_title_bg():
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
    for _ in range(80):
        x, y = rnd.randrange(W), rnd.randrange(int(HORIZON * 0.6))
        px[y][x] = hex_color("#FFF4D6") if rnd.random() < 0.3 else hex_color("#8E84A8")
    for (x, y) in ((40, 18), (300, 30), (352, 62), (90, 52)):
        for d in (-1, 1):
            px[y][x + d] = hex_color("#8E84A8")
            px[y + d][x] = hex_color("#8E84A8")
        px[y][x] = hex_color("#FFFFFF")
    # Moon, low and large, with a crescent shadow.
    mx, my, mr = 346, 30, 13
    for y in range(my - mr - 1, my + mr + 2):
        for x in range(mx - mr - 1, mx + mr + 2):
            d = math.hypot(x - mx, y - my)
            if d <= mr:
                lit_side = math.hypot(x - (mx + 7), y - (my - 5)) > mr
                c = hex_color("#FFF4D6") if not lit_side else hex_color("#E8DCC8")
                if d > mr - 1.2:
                    c = hex_color("#FFFFFF")
                px[y][x] = c
    for (cx, cy, r) in ((341, 27, 2.5), (351, 37, 1.5), (348, 23, 1)):
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                if math.hypot(x - cx, y - cy) <= r:
                    px[y][x] = hex_color("#E8DCC8")

    # Under the water: darker with depth, dithered between bands.
    for y in range(SURFACE, H):
        t = (y - SURFACE) / (H - SURFACE)
        f = t ** 0.8 * (len(DEEP) - 1)
        i = int(f)
        frac = f - i
        for x in range(W):
            c = DEEP[i]
            if i + 1 < len(DEEP) and ((frac > 0.6 and (x + y) % 2 == 0) or frac > 0.85):
                c = DEEP[i + 1]
            px[y][x] = c
    # Moonlight slanting down through the water.
    for (x0, width) in ((150, 10), (196, 6), (236, 14), (300, 8), (330, 5)):
        for y in range(SURFACE, H):
            depth = y - SURFACE
            fade = 1.0 - depth / 80.0
            if fade <= 0:
                break
            xs = x0 - depth * 0.45
            for x in range(int(xs), int(xs + width)):
                if 0 <= x < W and rnd.random() < fade * 0.55 and (x + y) % 2 == 0:
                    c = px[y][x]
                    px[y][x] = (min(255, c[0] + 14), min(255, c[1] + 22), min(255, c[2] + 26), 255)

    # The leviathan, under everything else in the deep.
    ex, ey = _eye()
    for x in range(W):
        top = round(_back_top(x))
        for y in range(max(top, SURFACE), H):
            depth = y - top
            i = 0 if depth < 1 else 1 if depth < 3 else 2 if depth < 10 else 3 if depth < 26 else 4
            # The far deep swallows its belly.
            if y > 200 or (y > 192 and (x + y) % 2 == 0):
                i = 5
            px[y][x] = HIDE[i]
    # Barnacle knobs and old scars along the back.
    for x in range(6, W, 13):
        top = round(_back_top(x))
        if top + 4 < H:
            k = rnd.randrange(2, 4)
            for dx in range(-(k // 2), k // 2 + 1):
                if 0 <= x + dx < W:
                    px[top + 2][x + dx] = HIDE[0]
            px[top + 1][x] = HIDE[0]
    # Ridges of hide: long faint folds following the back.
    for off in (8, 15):
        for x in range(0, 240):
            y = round(_back_top(x)) + off + round(1.5 * math.sin(x / 9.0 + off))
            if y < H and (x // 3) % 4 != 0:
                px[y][x] = HIDE[2]
    # The eye sits in a raised socket, a little lighter than the hide.
    for y in range(ey - 12, ey + 13):
        for x in range(ex - 30, ex + 31):
            d = ((x - ex) / 30.0) ** 2 + ((y - ey) / 12.0) ** 2
            if d <= 1.0 and px[y][x] in (HIDE[3], HIDE[4]):
                px[y][x] = HIDE[2] if d < 0.75 or (x + y) % 2 else px[y][x]
    # A great pectoral fin, folded back along the flank.
    fin = []
    for i in range(70):
        t = i / 69.0
        cx = 236 - 70 * t
        cy = 186 + 16 * t + 6 * math.sin(t * math.pi)
        r = 9 * (1 - t) ** 0.7 + 1
        fin.append((cx, cy, r))
    for (cx, cy, r) in fin:
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                if 0 <= x < W and 0 <= y < H and math.hypot(x - cx, y - cy) <= r:
                    edge = cy - y > r - 1.5
                    px[y][x] = HIDE[1] if edge else HIDE[3]
    for k in range(4):
        for i in range(10, 64, 2):
            t = i / 69.0
            x = round(236 - 70 * t)
            y = round(186 + 16 * t + 6 * math.sin(t * math.pi) + (k - 1.5) * 9 * (1 - t) ** 0.7 * 0.5)
            if 0 <= y < H:
                px[y][x] = HIDE[4]
    # The great head: brow ridge over the eye, folds around it, and the
    # long seam of a mouth running out to the right edge.
    for dx in range(-22, 23):
        y = ey - 10 + round(4 * (dx / 22.0) ** 2)
        px[y][ex + dx] = HIDE[1]
        px[y + 1][ex + dx] = HIDE[3]
    for r in (21, 25):
        for a in range(200, 340, 3):
            t = math.radians(a)
            x, y = ex + round(r * 1.3 * math.cos(t)), ey + 6 + round(r * 0.55 * math.sin(-t) * -1)
            if 0 <= x < W and y < H:
                px[y][x] = HIDE[2]
    for x in range(ex + 8, W):
        y = ey + 18 + round((x - ex) * 0.08)
        if y < H:
            px[y][x] = HIDE[5]
            px[y - 1][x] = HIDE[2]
    # Eyelid: the seam, with a lighter lid above it.
    for (x, y) in _eye_seam():
        px[y - 1][x] = HIDE[1]
        px[y][x] = GLOW_DIM
        px[y + 1][x] = HIDE[4]
    # Dim glow spots (the overlay brightens them).
    for (x, y, r) in _glow_spots():
        for dy in range(r):
            for dx in range(r):
                if 0 <= x + dx < W and y + dy < H:
                    px[y + dy][x + dx] = GLOW_DIM

    # Saltmarrow's headland, and the rock it stands on running down into
    # the water, small against the creature.
    for x in range(0, 120):
        top = HORIZON - 4 - round(3 * math.sin(x / 17.0) + (120 - x) / 14)
        for y in range(top, SURFACE):
            px[y][x] = hex_color("#2A2238")
    for x in range(0, 112):
        bottom = SURFACE + round(34 * (1 - x / 112.0) ** 1.6) + round(2 * math.sin(x / 5.0))
        for y in range(SURFACE, min(bottom, H)):
            depth = bottom - y
            px[y][x] = ROCK[0] if depth < 2 else ROCK[1] if y < SURFACE + 8 else ROCK[2]
    # Kelp on the rock.
    for kx in (14, 30, 44, 61, 78):
        base = SURFACE + round(34 * (1 - kx / 112.0) ** 1.6)
        for i in range(rnd.randrange(8, 16)):
            y = base - i
            if y <= SURFACE + 1:
                break
            x = kx + round(1.5 * math.sin(i / 2.5 + kx))
            px[y][x] = hex_color("#2E5A48") if i % 3 else hex_color("#4E7A48")
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
    for i in range(1, 60):
        y = lbase - 22
        spread = i // 10
        for dy in range(-spread, spread + 1):
            x = lx + 1 + i
            if 0 <= y + dy < HORIZON and (i + dy) % 2 == 0:
                px[y + dy][x] = hex_color("#C8A0A0") if i > 30 else hex_color("#E8C0A0")

    # The surface: a bright line, with the moon's path broken on it.
    for x in range(W):
        px[HORIZON][x] = hex_color("#3E6E8E")
        px[HORIZON + 1][x] = hex_color("#5FA8B8") if (x // 2) % 5 else hex_color("#A8E6CF")
    for x in range(mx - 14, mx + 15):
        if rnd.random() < 0.6:
            px[HORIZON][x] = hex_color("#FFF4D6")
    # A fishing boat on the surface, tiny next to what lies under it.
    bx = 232
    for i in range(14):
        x = bx + i
        depth = 2 if 2 <= i <= 11 else 1
        for d in range(depth + 1):
            px[HORIZON - 1 + d][x] = hex_color("#3A2A2A") if d == 0 else hex_color("#1E1418")
    for y in range(HORIZON - 12, HORIZON - 1):
        px[y][bx + 6] = hex_color("#2A1E26")
    for y in range(HORIZON - 10, HORIZON - 3):
        for x in range(bx + 7, bx + 7 + (y - (HORIZON - 11)) // 2 + 1):
            px[y][x] = hex_color("#C8B8A0")
    px[HORIZON - 4][bx + 2] = hex_color("#FFE36E")
    # The boat's lantern light on the water just under it.
    for x in range(bx - 1, bx + 6):
        if x % 2 == 0:
            px[HORIZON + 3][x] = hex_color("#C8A060")

    # Breath: bubbles rising from the blowhole on the crown of the head to
    # the surface, which froths where they break.
    hx = 268
    htop = round(_back_top(hx))
    y = htop - 3
    i = 0
    while y > SURFACE + 2:
        r = 0.6 + i * 0.12
        bx2 = hx + round(3 * math.sin(i * 1.3)) + rnd.choice((-1, 0, 1))
        if r < 1.0:
            px[y][bx2] = hex_color("#A8E6CF")
        else:
            for yy in range(int(y - r) - 1, int(y + r) + 2):
                for xx in range(int(bx2 - r) - 1, int(bx2 + r) + 2):
                    d = math.hypot(xx - bx2, yy - y)
                    if r - 0.6 <= d <= r + 0.4 and SURFACE < yy < H:
                        px[yy][xx] = hex_color("#A8E6CF")
            px[int(y - r)][bx2] = hex_color("#FFFFFF")
        y -= 3 + i // 3
        i += 1
    for x in range(hx - 10, hx + 11):
        if rnd.random() < 0.7:
            px[HORIZON - (1 if abs(x - hx) < 5 and rnd.random() < 0.5 else 0)][x] = hex_color("#FFF4D6")
    return px


def build_title_glow():
    """The creature's light on its own, transparent elsewhere: bright spots
    with a soft halo, and the light leaking from the closed eye."""
    px = [[CLEAR] * W for _ in range(H)]

    def put(x, y, c):
        if 0 <= x < W and 0 <= y < H and px[y][x][3] < c[3]:
            px[y][x] = c

    halo = (GLOW_MID[0], GLOW_MID[1], GLOW_MID[2], 110)
    for (x, y, r) in _glow_spots():
        for dx, dy in ((-1, 0), (r, 0), (0, -1), (0, r)):
            for k in range(r):
                put(x + dx + (k if dy else 0), y + dy + (k if dx else 0), halo)
        for dy in range(r):
            for dx in range(r):
                put(x + dx, y + dy, GLOW)
    for (x, y) in _eye_seam():
        put(x, y, GLOW)
        put(x, y + 1, halo)
    return px
