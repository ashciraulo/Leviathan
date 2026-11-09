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
PALE = [hex_color(c) for c in ("#D8E0DA", "#AEBEC0", "#7E94A0", "#4E6478", "#2A3C54", "#121C30")]
PALE_RIM = hex_color("#F0F4EC")
GLOW = hex_color("#8FFFF0")
GLOW_MID = hex_color("#4FD8D0")
GLOW_DIM = hex_color("#2A8A96")
ROCK = [hex_color(c) for c in ("#4A3E5E", "#2E2640", "#1E1A30")]
W, H = 384, 216
HORIZON = 112
SURFACE = HORIZON + 2


def _whale_top(x):
    """Top edge of the whale: the back rising from beyond the left edge to
    the hump, then the long, near-flat crown of the great square head."""
    if x < 236:
        return 141 + 34 * max(0.0, (176 - x) / 176.0) ** 1.6 + 3 * max(0.0, (x - 176) / 60.0)
    if x < HEAD_FRONT - 14:
        t = (x - 236) / (HEAD_FRONT - 250.0)
        return 144 - 2 * math.sin(t * math.pi) - 4 * max(0.0, (t - 0.45) / 0.55) ** 1.5
    # The blunt front of the head curves down.
    d = x - (HEAD_FRONT - 14)
    return 140 + 14 - math.sqrt(max(0.0, 14 ** 2 - d ** 2))


HEAD_FRONT = 372
MOUTH_Y = 196
JAW = (258, 352)


def _whale_mask():
    """Every pixel of the whale, and which part it belongs to:
    'body' (back and head) or 'jaw' (the narrow lower jaw)."""
    parts = {}
    for x in range(W):
        top = round(_whale_top(x))
        if x > HEAD_FRONT:
            continue
        bottom = H
        # The head's underside, above the mouth, from the jaw corner forward.
        if x >= JAW[0]:
            bottom = MOUTH_Y
            if x > HEAD_FRONT - 12:
                d = x - (HEAD_FRONT - 12)
                bottom = MOUTH_Y - 12 + round(math.sqrt(max(0.0, 12 ** 2 - d ** 2)))
        for y in range(max(top, SURFACE), min(bottom, H)):
            parts[(x, y)] = "body"
    # The lower jaw: long and narrow, set back from the head's front.
    for x in range(JAW[0] - 10, JAW[1] + 1):
        t = (x - JAW[0] + 10) / float(JAW[1] - JAW[0] + 10)
        depth = round(9 - 5 * t)
        if x > JAW[1] - 3:
            depth -= x - (JAW[1] - 3)
        lift = round(2 * t * t)
        for y in range(MOUTH_Y + 2 - lift, min(MOUTH_Y + 2 - lift + depth, H)):
            parts[(x, y)] = "jaw"
    # Under the jaw corner the throat runs back into the body.
    for x in range(0, JAW[0] + 4):
        for y in range(MOUTH_Y, H):
            parts.setdefault((x, y), "body")
    for x in range(JAW[0], JAW[1] - 20):
        for y in range(MOUTH_Y + 9 + (x - JAW[0]) // 6, H):
            parts.setdefault((x, y), "body")
    return parts


def _whale_eye():
    return 284, 186


def _plankton():
    """Specks of living light drifting around the whale, (x, y)."""
    rnd = random.Random(5)
    specks = []
    for _ in range(70):
        x = rnd.randrange(W)
        y = rnd.randrange(SURFACE + 6, H)
        if abs(y - _whale_top(min(x, HEAD_FRONT))) < 18 and not (148 <= x <= 240 and 150 <= y <= 206):
            specks.append((x, y))
    return specks


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

    # The leviathan: an old, pale giant, scarred from ages of battles,
    # lit by the moon along its back and fading into the deep below.
    parts = _whale_mask()
    for (x, y), part in parts.items():
        top = round(_whale_top(x)) if part == "body" else MOUTH_Y + 2
        depth = y - top
        # Moonlight from above: bright along the top, quickly into shadow.
        head = 0 if x > 240 else 2
        f = depth / (3.0 + head * 0.5)
        f = f if f < 3 else 3 + (depth - 9 - head) / 9.0
        if part == "body" and x > 244 and y < MOUTH_Y:
            # The great head is one solid, rounded block, lit from above.
            blend = min(1.0, (x - 244) / 30.0)
            f = f * (1 - blend) + blend * (0.6 + depth / 13.0)
        if part == "body" and x > HEAD_FRONT - 18 and y < MOUTH_Y:
            # The blunt front faces the moon.
            f = min(f, (HEAD_FRONT - x) / 5.0 + (y - 150) / 30.0)
        if part == "jaw":
            f = 1.5 + depth * 0.5
        f = max(0.0, f)
        i = min(5, int(f + (0.5 if (x + y) % 2 and f % 1 > 0.5 else 0)))
        if y > 202 and (x + y) % 2 == 0:
            i = min(i + 1, 5)
        if y > 208:
            i = 5
        px[y][x] = PALE[i]
    # Rim of moonlight along the very top.
    for x in range(0, HEAD_FRONT + 1):
        top = round(_whale_top(x))
        if SURFACE < top < H:
            px[top][x] = PALE_RIM
    # Wrinkles: long creases along the body and head.
    crease_rnd = random.Random(31)
    for _ in range(46):
        x0 = crease_rnd.randrange(0, 350)
        off = crease_rnd.choice((4, 6, 8, 10, 13, 16, 20))
        ln = crease_rnd.randrange(8, 30)
        phase = crease_rnd.random() * 6
        for x in range(x0, min(x0 + ln, HEAD_FRONT - 4)):
            y = round(_whale_top(x)) + off + round(1.5 * math.sin(x / 6.0 + phase))
            if (x, y) in parts and (x, y - 1) in parts and parts[(x, y)] == "body":
                px[y][x] = PALE[min(5, 3 + off // 12)]
                if off < 14:
                    px[y - 1][x] = PALE[max(0, 1 + off // 10)]
    # Deep vertical folds on the head's front.
    for fx in (HEAD_FRONT - 8, HEAD_FRONT - 15):
        for y in range(156, MOUTH_Y - 3):
            x = fx + round(1.5 * math.sin(y / 5.0 + fx))
            if (x, y) in parts:
                px[y][x] = PALE[2]
    # Old scars: rings left by giant suckers, and long raking scratches.
    rnd2 = random.Random(23)
    for (cx, cy, r) in ((300, 158, 3), (318, 166, 2), (332, 156, 3), (290, 172, 2), (346, 172, 2), (204, 152, 2), (150, 158, 2)):
        for a in range(rnd2.randrange(0, 90), 300, 30):
            t = math.radians(a)
            x, y = cx + round(r * math.cos(t)), cy + round(r * math.sin(t))
            if (x, y) in parts:
                px[y][x] = PALE[0]
    for (x0, y0, ln) in ((248, 150, 18), (262, 154, 14), (120, 156, 12), (176, 148, 16)):
        for d in range(ln):
            x, y = x0 + d, y0 + d // 3
            if (x, y) in parts:
                px[y][x] = PALE[0]
                if (x, y + 1) in parts:
                    px[y + 1][x] = PALE[3]
    # Barnacle crusts on the crown and back.
    for (cx, cy, n) in ((286, 147, 7), (230, 146, 5), (96, 152, 6), (352, 150, 4)):
        for _ in range(n):
            x = cx + rnd2.randrange(-6, 7)
            y = round(_whale_top(x)) + rnd2.randrange(0, 3)
            if (x, y) in parts:
                px[y][x] = hex_color("#E8E0D0")
                if (x + 1, y) in parts:
                    px[y][x + 1] = PALE[3]
    # The mouth: a dark seam, with teeth along the narrow lower jaw.
    for x in range(JAW[0], HEAD_FRONT - 10):
        for y in (MOUTH_Y, MOUTH_Y + 1):
            if 0 <= y < H:
                px[y][x] = hex_color("#0A0E1A")
    for x in range(JAW[0] + 4, JAW[1] - 4, 6):
        x += rnd2.randrange(0, 2)
        lift = round(2 * ((x - JAW[0] + 10) / float(JAW[1] - JAW[0] + 10)) ** 2)
        px[MOUTH_Y + 1 - lift][x] = hex_color("#E8E0D0")
        if rnd2.random() < 0.7:
            px[MOUTH_Y - lift][x] = hex_color("#C8C0B0")
    # The eye, small for so vast a head, shut, low by the jaw's corner.
    ex, ey = _whale_eye()
    for dx in range(-4, 5):
        y = ey + round(1.2 * (1 - (dx / 4.5) ** 2))
        px[y][ex + dx] = hex_color("#0A0E1A")
        px[y - 1][ex + dx] = PALE[2]
    for dx in range(-6, 6):
        px[ey - 3 + round(1.5 * (dx / 6.0) ** 2)][ex + dx] = PALE[4]
    for dx in range(-3, 4):
        px[ey + 3][ex + dx + 1] = PALE[4]
    # Old harpoons in its back, their ropes trailing up into the water.
    for (hx, length, lean, rope) in ((148, 16, -0.55, True), (214, 13, -0.4, False), (306, 11, -0.7, True)):
        top = round(_whale_top(hx))
        for d in range(length):
            x = hx + round(lean * d)
            y = top - d
            if SURFACE < y:
                px[y][x] = hex_color("#7E5E44")
                px[y][x + 1] = hex_color("#4A3428")
        # The iron head shows where it went in, rusted.
        px[top][hx] = hex_color("#8A3E2A")
        px[top][hx + 1] = hex_color("#5A2A20")
        if rope:
            x, y = hx + lean * length, top - length
            for i in range(40):
                x -= 0.8 + 0.3 * math.sin(i / 4.0)
                y -= 0.55
                yi, xi = round(y), round(x)
                if not (SURFACE < yi < H and 0 <= xi < W):
                    break
                if (xi, yi) not in parts:
                    px[yi][xi] = hex_color("#9A8462") if i % 3 else hex_color("#6E5E46")
    # Curling currents around it, like the swirls of old sea charts.
    for (cx, cy, turns, size) in ((70, 136, 1.4, 9), (138, 128, 1.2, 7), (360, 128, 1.3, 8), (30, 196, 1.2, 7)):
        for i in range(120):
            t = i / 119.0 * turns * 2 * math.pi
            r = size * (1 - i / 140.0)
            x, y = cx + round(r * math.cos(t)), cy + round(r * 0.6 * math.sin(t))
            if 0 <= x < W and SURFACE < y < H and (x, y) not in parts and i % 9 != 8:
                px[y][x] = hex_color("#3E7E96")

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
    hx = 356
    htop = round(_whale_top(hx))
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
    """Living light around the whale on its own, transparent elsewhere, so
    the title can swell and dim it as the leviathan breathes."""
    px = [[CLEAR] * W for _ in range(H)]
    halo = (GLOW_MID[0], GLOW_MID[1], GLOW_MID[2], 90)
    for (x, y) in _plankton():
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            if 0 <= x + dx < W and 0 <= y + dy < H:
                px[y + dy][x + dx] = halo
        px[y][x] = GLOW
    return px
