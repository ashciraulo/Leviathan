"""Six design concepts for the sleeping leviathan on the title screen, each
drawn over the same dusk backdrop, plus a contact sheet. For Ash to pick
a direction; not part of the game build.

    python3 tools/leviathan_concepts.py OUT_DIR
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import title_art  # noqa: E402
from title_art import hex_color  # noqa: E402

W, H = 384, 216
WATER = title_art.HORIZON + 9
OUTLINE = hex_color("#120C22")
GLOW = hex_color("#6EF0E0")
GLOW_DIM = hex_color("#3FA8A8")
FOAM = hex_color("#FFF4D6")
FOAM2 = hex_color("#A8E6CF")

# Body ramps: rim light, upper, mid, shade.
VIOLET = [hex_color(c) for c in ("#8E84A8", "#4A3E72", "#2E2650", "#1C1634")]
SLATE = [hex_color(c) for c in ("#9AB0C8", "#4E6484", "#2E3E5A", "#1A2438")]
MOSS = [hex_color(c) for c in ("#8FBF6A", "#4E7A48", "#2E4E3A", "#1C3028")]
SHELL = [hex_color(c) for c in ("#F2D6B0", "#C89A78", "#8A5E58", "#4E3242")]
CORAL = [hex_color(c) for c in ("#FFB08A", "#E2574C", "#A8323F", "#5C1A33")]
TEAL = [hex_color(c) for c in ("#8FD8C8", "#3E8A8A", "#245A66", "#163846")]


# --------------------------------------------------------------------------
# Shape helpers: a shape is a set of (x, y) pixels.
# --------------------------------------------------------------------------

def disc(mask, cx, cy, r):
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                mask.add((x, y))


def ellipse(mask, cx, cy, rx, ry):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                mask.add((x, y))


def stroke(mask, points, steps=200):
    """A tube through (x, y, radius) control points (Catmull-Rom)."""
    pts = [points[0]] + list(points) + [points[-1]]
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for s in range(steps // (len(pts) - 3)):
            t = s / float(steps // (len(pts) - 3))
            v = []
            for k in range(3):
                a, b, c, d = p0[k], p1[k], p2[k], p3[k]
                v.append(0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t
                                + (-a + 3 * b - 3 * c + d) * t * t * t))
            disc(mask, v[0], v[1], max(v[2], 0.5))
    disc(mask, points[-1][0], points[-1][1], max(points[-1][2], 0.5))


def polygon(mask, pts):
    ys = [p[1] for p in pts]
    for y in range(int(min(ys)), int(max(ys)) + 1):
        xs = []
        for i in range(len(pts)):
            (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
            if (y1 <= y < y2) or (y2 <= y < y1):
                xs.append(x1 + (y - y1) * (x2 - x1) / float(y2 - y1))
        xs.sort()
        for a, b in zip(xs[::2], xs[1::2]):
            for x in range(int(round(a)), int(round(b)) + 1):
                mask.add((x, y))


def paint(px, mask, ramp, cut=WATER, outline=True):
    """Shade a shape: lit along its top edges, darker inside and below.
    Pixels at or below `cut` are under water and left alone."""
    for (x, y) in mask:
        if not (0 <= x < W and 0 <= y < H) or y >= cut:
            continue
        d = 0
        while (x, y - d - 1) in mask and d < 12:
            d += 1
        below = 0
        while (x, y + below + 1) in mask and below < 4 and y + below + 1 < cut:
            below += 1
        if d < 1:
            c = ramp[0]
        elif d < 4:
            c = ramp[1]
        else:
            c = ramp[2]
        if below < 2 and y + below + 1 < cut and d > 1:
            c = ramp[3]
        if y >= cut - 2:
            c = ramp[3]
        px[y][x] = c
    if outline:
        for (x, y) in mask:
            for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                nx, ny = x + dx, y + dy
                if (nx, ny) not in mask and 0 <= nx < W and 0 <= ny < cut and y < cut:
                    px[ny][nx] = OUTLINE


def put(px, x, y, c):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < W and 0 <= y < H:
        px[y][x] = c


def foam(px, x0, x1, rnd, y=WATER):
    for x in range(x0, x1):
        if rnd.random() < 0.8:
            put(px, x, y + rnd.choice((0, 0, 1)), FOAM if rnd.random() < 0.4 else FOAM2)


def foam_under(px, mask, rnd):
    xs = sorted({x for (x, y) in mask if y in (WATER - 1, WATER)})
    for x in xs:
        if rnd.random() < 0.85:
            put(px, x, WATER + rnd.choice((0, 0, 1)), FOAM if rnd.random() < 0.4 else FOAM2)


def closed_eye(px, x, y, w=5, lid=hex_color("#B8A8E0")):
    for dx in range(-w, w + 1):
        put(px, x + dx, y + round(1.6 * (1 - (dx / (w + 0.5)) ** 2)), lid)
    for dx in range(-w + 1, w, 3):
        put(px, x + dx, y + round(1.6 * (1 - (dx / (w + 0.5)) ** 2)) + 1, OUTLINE)


def runes(px, pts):
    for (x, y) in pts:
        for (dx, dy) in ((0, 0), (1, -1), (2, 0), (3, 1), (4, 0)):
            put(px, x + dx, y + dy, GLOW)


# --------------------------------------------------------------------------
# The concepts.
# --------------------------------------------------------------------------

def concept_coastline(px, rnd):
    """The land is its back: a mossy hill with grass and stones, and only a
    great closed eye and a fin like a rock ledge give it away."""
    body = set()
    for x in range(60, 360):
        t = (x - 60) / 300.0
        h = 46 * math.sin(math.pi * t ** 0.85) ** 0.9
        for y in range(int(WATER - h), WATER + 2):
            body.add((x, y))
    paint(px, body, MOSS)
    # Hide-like underside near the water: old grey skin under the moss.
    for (x, y) in body:
        if WATER - 9 <= y < WATER and (x + y) % 3 and x > 250:
            px[y][x] = SLATE[2] if y < WATER - 4 else SLATE[3]
    # Grass tufts and stones on top.
    for x in range(70, 350, 7):
        top = min(y for (xx, y) in body if xx == x)
        for d in range(rnd.randrange(2, 5)):
            put(px, x + (d % 2), top - 1 - d // 2, MOSS[0])
    for x in (120, 175, 205, 240):
        top = min(y for (xx, y) in body if xx == x)
        disc_m = set()
        ellipse(disc_m, x, top + 1, 4, 2.5)
        paint(px, disc_m, SLATE, cut=WATER)
    # A twisted tree on the crown.
    for d in range(12):
        put(px, 186 + (d // 4), WATER - 46 - d, hex_color("#2A1E2A"))
    canopy = set()
    ellipse(canopy, 190, WATER - 60, 9, 5)
    paint(px, canopy, MOSS)
    # The eye, low on the right flank, closed under a heavy fold of skin.
    eye_mask = set()
    ellipse(eye_mask, 312, WATER - 14, 13, 6)
    paint(px, eye_mask, SLATE)
    closed_eye(px, 312, WATER - 15, 7)
    for dx in range(-11, 10):
        put(px, 312 + dx, WATER - 21 + (1 if abs(dx) > 7 else 0), MOSS[3])
    # A fin like a rock ledge breaking the water at the left.
    fin = set()
    polygon(fin, [(26, WATER + 1), (40, WATER - 22), (46, WATER - 20), (52, WATER + 1)])
    paint(px, fin, SLATE)
    for i in range(3):
        put(px, 40 + i * 3, WATER - 18 + i * 5, SLATE[0])
    runes(px, [(150, WATER - 30), (226, WATER - 34), (268, WATER - 24)])
    foam_under(px, body | fin, rnd)


def concept_serpent(px, rnd):
    """A sea serpent: coils arching out of the water, shrinking toward the
    horizon, the tail tip curling up at the end; the head rests on the
    water in front with a frill and long whiskers."""
    coils = set()
    belly = set()
    for (cx, r, thick) in ((96, 34, 9), (176, 26, 7.5), (238, 19, 6), (284, 13, 4.5)):
        pts = []
        for i in range(17):
            a = math.pi * i / 16.0
            pts.append((cx - r * math.cos(a), WATER + 2 - r * 0.9 * math.sin(a), thick))
        stroke(coils, pts, 160)
        for i in range(2, 15):
            a = math.pi * i / 16.0
            put_r = r - thick * 0.6
            belly.add((round(cx - put_r * math.cos(a)), round(WATER + 2 - put_r * 0.9 * math.sin(a))))
    # Tail: a last thin curl at the far right, ending in a small fin.
    tail = [(306, WATER + 1, 3), (312, WATER - 10, 2.6), (322, WATER - 16, 2), (330, WATER - 12, 1.4),
            (329, WATER - 6, 1)]
    stroke(coils, tail, 80)
    fin = set()
    polygon(fin, [(329, WATER - 7), (336, WATER - 14), (334, WATER - 4)])
    paint(px, coils | fin, TEAL)
    for (x, y) in belly:
        if y < WATER - 1:
            put(px, x, y, hex_color("#C8E0B8"))
    # Scale bands across each arch.
    for (cx, r, thick) in ((96, 34, 9), (176, 26, 7.5), (238, 19, 6)):
        for i in range(3, 14, 2):
            a = math.pi * i / 16.0
            x = cx - r * math.cos(a)
            y = WATER + 2 - r * 0.9 * math.sin(a)
            put(px, x, y - thick * 0.6, TEAL[2])
            put(px, x + 1, y - thick * 0.6 + 1, TEAL[2])
    # Dorsal frill along the first arch.
    for i in range(2, 15):
        a = math.pi * i / 16.0
        x = 96 - 34 * math.cos(a)
        y = WATER + 2 - 30.6 * math.sin(a) - 9
        for d in range(3 + (i % 2) * 2):
            put(px, x, y - d, CORAL[1] if d < 2 else CORAL[0])
    # The head, resting on the water at the left, nose toward us.
    head = set()
    ellipse(head, 44, WATER - 8, 20, 9)
    ellipse(head, 64, WATER - 5, 12, 6)
    stroke(head, [(30, WATER - 2, 7), (52, WATER - 14, 9), (62, WATER - 4, 8)], 60)
    paint(px, head, TEAL)
    for i in range(6):
        for d in range(4 + i % 2 * 2):
            put(px, 30 + i * 4 - d // 2, WATER - 17 - d - i // 2, CORAL[1] if d < 2 else CORAL[0])
    closed_eye(px, 54, WATER - 10, 4, hex_color("#E8FFF0"))
    for dx in range(-6, 5):
        put(px, 54 + dx, WATER - 14 + (abs(dx) > 4), TEAL[0])
    for i in range(30):
        put(px, 74 + i, WATER - 4 + round(3 * math.sin(i / 5.0)) + i // 10, TEAL[0])
        put(px, 72 + i, WATER - 1 + round(2 * math.sin(i / 4.0 + 1)) + i // 12, TEAL[1])
    for x in range(66, 76):
        put(px, x, WATER - 3, OUTLINE)
    runes(px, [(90, WATER - 30), (170, WATER - 22), (234, WATER - 16)])
    foam_under(px, coils | head, rnd)


def concept_beneath(px, rnd):
    """The Old One mostly beneath the surface: a vast shape under the water,
    glowing spots along its flank, only a barnacled ridge and a misty
    breath breaking the surface."""
    under = set()
    stroke(under, [(30, WATER + 26, 8), (90, WATER + 18, 22), (190, WATER + 22, 30),
                   (290, WATER + 22, 24), (350, WATER + 18, 14)], 300)
    for (x, y) in under:
        if WATER + 1 <= y < H and 0 <= x < W:
            base = px[y][x]
            k = 0.55
            px[y][x] = (int(base[0] * k), int(base[1] * k), int(base[2] * k + 8), 255)
    # Fin shape under water.
    fin = set()
    polygon(fin, [(160, WATER + 30), (196, WATER + 52), (176, WATER + 56)])
    for (x, y) in fin:
        if y < H:
            px[y][x] = hex_color("#0C1828")
    # Glowing spots in two rows along the body.
    for x in range(60, 340, 9):
        t = (x - 30) / 320.0
        y = WATER + 14 + round(10 * math.sin(t * math.pi))
        put(px, x, y, GLOW)
        put(px, x + 4, y + 8, GLOW_DIM)
    # The eye beneath, a soft closed crescent of light.
    for dx in range(-6, 7):
        put(px, 318 + dx, WATER + 12 + round(1.5 * (1 - (dx / 6.5) ** 2)), GLOW_DIM)
    # The ridge breaking the surface, barnacled.
    ridge = set()
    stroke(ridge, [(110, WATER + 2, 2), (150, WATER - 4, 5), (200, WATER - 7, 7), (250, WATER - 4, 5),
                   (280, WATER + 2, 2)], 200)
    paint(px, ridge, SLATE)
    for x in range(130, 270, 5):
        top = min((y for (xx, y) in ridge if xx == x), default=WATER)
        if top < WATER - 1:
            put(px, x, top + 2, SHELL[0])
            put(px, x + 1, top + 2, SHELL[1])
    # Breath: a soft column of mist above the blowhole.
    for i in range(40):
        y = WATER - 8 - i
        spread = 1 + i // 6
        for dx in range(-spread, spread + 1):
            if rnd.random() < 0.45 - i / 120.0:
                put(px, 236 + dx + round(2 * math.sin(i / 6.0)), y, hex_color("#D8E4F0"))
    foam_under(px, ridge, rnd)


def concept_shell(px, rnd):
    """A nautilus-like leviathan: a spiral shell big as an island, its arms
    lying over the water, a great eye shut in the shell's mouth."""
    shell = set()
    cx, cy = 210, WATER - 30
    for a in range(0, 720 * 2):
        t = a / 2.0 * math.pi / 180.0
        r = 6 * math.exp(0.22 * t)
        if r > 52:
            break
        disc(shell, cx + r * math.cos(t), cy + r * 0.85 * math.sin(t), max(2.0, r * 0.38))
    paint(px, shell, SHELL)
    # Growth stripes.
    for a in range(0, 1440, 18):
        t = a / 2.0 * math.pi / 180.0 * 2
        r = 6 * math.exp(0.22 * t)
        if r > 50:
            break
        for k in range(int(r * 0.3)):
            put(px, cx + (r - k) * math.cos(t), cy + (r - k) * 0.85 * math.sin(t), SHELL[2])
    # Arms spilling out of the mouth across the water.
    arms = set()
    for i, (ex, ey) in enumerate(((300, WATER - 2), (330, WATER + 1), (270, WATER + 1), (352, WATER - 6))):
        stroke(arms, [(250, WATER - 14, 6 - i * 0.5), ((250 + ex) / 2, WATER - 10 - i * 2, 4),
                      (ex, ey, 1.5)], 80)
    paint(px, arms, VIOLET)
    for (x, y) in list(arms)[::7]:
        if y < WATER - 1 and (x, y + 1) in arms:
            put(px, x, y + 1, hex_color("#B8A8E0"))
    # Hood and eye at the mouth of the shell.
    hood = set()
    ellipse(hood, 246, WATER - 18, 14, 10)
    paint(px, hood, VIOLET)
    closed_eye(px, 246, WATER - 20, 6)
    runes(px, [(196, WATER - 52), (220, WATER - 40), (178, WATER - 24)])
    foam_under(px, shell | arms | hood, rnd)


def concept_dragon(px, rnd):
    """A coral-crusted sea dragon curled like a sleeping dog: head on its
    crossed forelegs, back humped, tail wrapped around the front."""
    body = set()
    ellipse(body, 190, WATER - 16, 92, 34)
    stroke(body, [(110, WATER - 4, 16), (150, WATER - 26, 24), (230, WATER - 30, 26), (280, WATER - 10, 16)], 200)
    paint(px, body, VIOLET)
    # Coral and barnacles growing along the spine.
    for x in range(120, 270, 6):
        top = min((y for (xx, y) in body if xx == x), default=WATER)
        h = 3 + rnd.randrange(5)
        for d in range(h):
            put(px, x + (d % 3 == 1), top - d, CORAL[d % 2])
        put(px, x, top - h, CORAL[0])
        if rnd.random() < 0.5:
            put(px, x + 3, top + 2, SHELL[0])
    # Forelegs crossed at the front, and the head resting on them.
    legs = set()
    stroke(legs, [(262, WATER - 2, 7), (300, WATER - 4, 6), (318, WATER - 3, 5)], 60)
    stroke(legs, [(270, WATER - 6, 6), (306, WATER - 9, 5), (322, WATER - 8, 4)], 60)
    paint(px, legs, VIOLET)
    for i in range(3):
        put(px, 322 + i * 2, WATER - 6 + i, SHELL[0])
    head = set()
    ellipse(head, 300, WATER - 20, 22, 11)
    stroke(head, [(300, WATER - 22, 10), (330, WATER - 18, 7), (346, WATER - 15, 5)], 60)
    paint(px, head, VIOLET)
    # Horns sweeping back.
    horn = set()
    stroke(horn, [(290, WATER - 30, 2.5), (272, WATER - 40, 2), (258, WATER - 42, 1)], 40)
    paint(px, horn, SHELL)
    closed_eye(px, 306, WATER - 23, 4)
    for x in range(326, 348):
        put(px, x, WATER - 12 + (x - 326) // 8, OUTLINE)
    put(px, 342, WATER - 18, OUTLINE)
    # Tail wrapped around the front, lying along the water toward the head.
    tail = set()
    stroke(tail, [(104, WATER - 6, 12), (120, WATER + 2, 9), (170, WATER + 4, 7),
                  (220, WATER + 2, 5), (252, WATER - 1, 3), (262, WATER - 6, 1.5)], 160)
    paint(px, tail, VIOLET)
    fin = set()
    polygon(fin, [(260, WATER - 5), (270, WATER - 14), (268, WATER - 2)])
    paint(px, fin, CORAL)
    runes(px, [(160, WATER - 40), (200, WATER - 46), (240, WATER - 40)])
    foam_under(px, body | legs | head | tail, rnd)


def concept_longneck(px, rnd):
    """A long-necked leviathan: a broad back far out, the neck curving down
    to a head resting on a rocky islet close by, eyes shut; the tail
    tapers away under the surface on the far side."""
    back = set()
    ellipse(back, 120, WATER - 2, 70, 26)
    stroke(back, [(52, WATER + 3, 4), (70, WATER - 4, 9), (100, WATER - 18, 18)], 60)
    paint(px, back, SLATE)
    # Plates down the back.
    for x in range(70, 186, 8):
        top = min((y for (xx, y) in back if xx == x), default=WATER)
        h = round(4 + 3 * math.sin((x - 70) / 116.0 * math.pi))
        plate = set()
        polygon(plate, [(x - 3, top + 1), (x, top - h), (x + 3, top + 1)])
        paint(px, plate, TEAL)
    flipper = set()
    polygon(flipper, [(150, WATER - 4), (196, WATER - 1), (176, WATER + 1)])
    paint(px, flipper, SLATE)
    # Neck: a long curve up and over, then down to the islet.
    neck = set()
    stroke(neck, [(170, WATER - 14, 13), (210, WATER - 52, 9), (250, WATER - 66, 7),
                  (290, WATER - 52, 6), (312, WATER - 30, 6)], 220)
    paint(px, neck, SLATE)
    for i in range(0, 40, 4):
        t = i / 40.0
        x = 180 + 120 * t
        y = WATER - 20 - 46 * math.sin(t * math.pi * 0.95)
        put(px, x, y + 6, SLATE[0])
    # The islet and the head resting on it.
    islet = set()
    ellipse(islet, 322, WATER - 2, 30, 9)
    paint(px, islet,
        [hex_color(c) for c in ("#6E6488", "#4A4060", "#2E2840", "#1C1830")])
    head = set()
    ellipse(head, 322, WATER - 17, 16, 8)
    stroke(head, [(322, WATER - 18, 8), (344, WATER - 14, 5), (352, WATER - 12, 3)], 40)
    paint(px, head, SLATE)
    closed_eye(px, 324, WATER - 20, 4)
    for x in range(336, 352):
        put(px, x, WATER - 12, OUTLINE)
    for i in range(3):
        put(px, 312 - i * 3, WATER - 25 - i, TEAL[0])
    runes(px, [(100, WATER - 22), (210, WATER - 58), (262, WATER - 68)])
    foam_under(px, back | islet | flipper, rnd)


CONCEPTS = [
    ("1_coastline", "The land is its back", concept_coastline),
    ("2_serpent", "Sea serpent coils", concept_serpent),
    ("3_beneath", "Glowing beneath the surface", concept_beneath),
    ("4_shell", "Spiral-shelled leviathan", concept_shell),
    ("5_dragon", "Coral sea dragon, curled up", concept_dragon),
    ("6_longneck", "Long neck resting on an islet", concept_longneck),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "concepts"
    os.makedirs(out, exist_ok=True)
    images = []
    for name, _, draw in CONCEPTS:
        px = title_art.build_title_bg(creature=False)
        draw(px, random.Random(4))
        images.append(px)
        write_png(os.path.join(out, name + ".png"), px, 4)
    # Contact sheet: 2 columns x 3 rows at 2x, with a gap.
    gap = 8
    sw, sh = W * 2 * 2 + gap, (H * 2 + gap) * 3 - gap
    sheet = [[(12, 22, 38, 255)] * sw for _ in range(sh)]
    for i, px in enumerate(images):
        ox, oy = (i % 2) * (W * 2 + gap), (i // 2) * (H * 2 + gap)
        for y in range(H * 2):
            row = px[y // 2]
            for x in range(W * 2):
                sheet[oy + y][ox + x] = row[x // 2]
    write_png(os.path.join(out, "all_concepts.png"), sheet, 1)


def write_png(path, px, scale):
    import struct
    import zlib
    h, w = len(px) * scale, len(px[0]) * scale
    raw = bytearray()
    for row in px:
        line = bytearray([0])
        for c in row:
            line += bytes(c[:4]) * scale
        raw += bytes(line) * scale
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    main()
