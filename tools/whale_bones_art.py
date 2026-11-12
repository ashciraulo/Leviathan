"""The great whale skull of Skull Rise and the fallen lower jaw of Whalefall
Steps: the bones of the Old One's kin, drawn as a sperm whale's.

Drawn from reference photos of real sperm-whale skulls (museum three-quarter
views, a front view and a top-down anatomical drawing on Wikimedia Commons),
not from memory. What makes the skull read as a sperm whale's:
  - a long, flat, tapering rostrum (the "beak"), with the mesorostral groove
    down its middle and the premaxillae either side of it;
  - behind it the supracranial basin, a huge scooped bowl as wide as the
    skull, its rim rising at the back into a tall crest;
  - the nares at the floor of the basin, the left one far bigger (the skull
    is lopsided);
  - a small eye socket low on the side, and behind it the temporal fossa, a
    big hollow in the side of the skull. That hollow is the Marrow Tomb's
    door, so the way in is part of the skull, not something added to it;
  - the lower jaw: a long, very narrow rod set with peg teeth, splitting
    into two branches toward the hinge.

The bones are modelled as height fields and lit, then drawn in the game's
top-down view: ground depth shows at PY, height at PH. The skull lies with
its rostrum running off to the lower left and its basin turned toward the
viewer. Pure Python, deterministic; build_art.py writes the sprites.
"""

import math

BONE = ["#FFF8EC", "#F2EAD8", "#DCD0B8", "#C8B898", "#A89878", "#786C58"]
STAIN = ["#F4E6C6", "#E6D2A8", "#D0B888", "#B89C70", "#957A56", "#6C5840"]
SAND = ["#F8E0B0", "#E8C890", "#D8B47A", "#C49A64", "#A88050", "#806040"]
OUTLINE = "#2a1e36"
HOLE = ["#2a1e36", "#3a2c3a", "#4c3c40"]

PY = 0.62          # how much ground depth shows on screen
PH = 0.62          # how much height shows on screen
SCALE = 0.8        # model units to pixels
LIGHT = (-0.55, -0.25, 0.80)   # from the upper left, as everywhere in the game


def hx(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def smooth(a, b, t):
    t = max(0.0, min(1.0, (t - a) / (b - a)))
    return t * t * (3 - 2 * t)


def noise(x, y, seed=0):
    """Value noise, the same on every machine."""
    def h(i, j):
        n = (i * 374761393 + j * 668265263 + seed * 982451653) & 0xFFFFFFFF
        n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
        return (n & 0xFFFF) / 65535.0
    i, j = math.floor(x), math.floor(y)
    fx, fy = x - i, y - j
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = h(i, j) + (h(i + 1, j) - h(i, j)) * fx
    b = h(i, j + 1) + (h(i + 1, j + 1) - h(i, j + 1)) * fx
    return a + (b - a) * fy


# ---- The skull, in its own plan units: x across (CX is the midline), y
# along it from the back of the crest (0) to the rostrum's tip (TIP).
# Proportions from the top-down drawing: the basin is the rear ~40% and as
# wide as the skull; the rostrum narrows almost evenly to a blunt point.

CX = 82.0
BASIN_C = (CX + 2, 60.0)    # leans a touch to one side: the skull is lopsided
BASIN_R = (64.0, 60.0)
TIP = 290.0
ROSTRUM_BASE = 112.0
NARIS_BIG = (CX + 13, 86.0, 13.0, 12.0)    # the left naris
NARIS_SMALL = (CX - 8, 80.0, 3.2, 2.6)     # the right one, tiny
FOSSA_Y = 92.0                              # where the hollow (the door) is


def rostrum_half(y):
    if y > TIP:
        return -1
    t = (TIP - y) / (TIP - ROSTRUM_BASE)
    half = 3.0 + 55.0 * min(1.0, t) ** 1.08
    if y > TIP - 8:
        half *= math.sqrt(max(0.0, (TIP - y) / 8.0))
    return half


def basin_r(x, y):
    u = (x - BASIN_C[0]) / BASIN_R[0]
    v = (y - BASIN_C[1]) / BASIN_R[1]
    return math.hypot(u, v), u, v


def in_ellipse(x, y, e):
    return ((x - e[0]) / e[2]) ** 2 + ((y - e[1]) / e[3]) ** 2 <= 1.0


def skull_height(x, y):
    """(height, part) at a plan point, or (None, None) off the bone."""
    best, tag = None, None
    # The basin: a deep dish whose rim climbs to the crest at the back.
    r, u, v = basin_r(x, y)
    if r <= 1.0 and y <= BASIN_C[1] + 30:
        back = max(0.0, -v / max(r, 1e-6)) ** 1.2
        rim = 40 + 62 * back if v <= 0 else 40 - 14 * v
        floor = 20.0
        h = floor + (rim - floor) * smooth(0.0, 0.93, r) ** 2.2
        if r > 0.93:
            h = rim + 1.5 - (r - 0.93) * 20
        best, tag = h, "basin"
    # The rostrum, running forward out of the basin floor.
    rh = rostrum_half(y)
    if rh > 0 and abs(x - CX) <= rh and y >= 70:
        s = (x - CX) / rh
        t = max(0.0, (y - ROSTRUM_BASE) / (TIP - ROSTRUM_BASE))
        base = 25 - 17 * t
        h = base * (1 - 0.28 * s * s)
        if abs(s) > 0.86:
            h -= (abs(s) - 0.86) / 0.14 * base * 0.55
        g = 0.055 + 0.03 * (1 - t)          # half-width of the groove
        if g < abs(s) < 0.44:               # the premaxillae, a little raised
            h += 1.2 * math.sin(math.pi * (abs(s) - g) / (0.44 - g)) ** 0.5
        if abs(s) <= g:                      # the mesorostral groove
            h -= 3.5 * (1 - t * 0.5)
        if y < ROSTRUM_BASE and best is not None and h < best:
            h = best + (h - best) * smooth(70, ROSTRUM_BASE, y)
        if best is None or h > best or (tag == "basin" and y > 96):
            best, tag = h, ("groove" if abs(s) <= g else "rostrum")
    return best, tag


# ---- The lower jaw, lying on its own, teeth up. Plan: a along it from the
# hinge end (0) to the tip (JAW_LEN), b across.

JAW_LEN = 190.0
SYMPHYSIS = 0.62    # how much of it is one fused rod


def jaw_height(a, b):
    if a < 0 or a > JAW_LEN:
        return None, None
    t = a / JAW_LEN
    best, tag = None, None
    if t > 1 - SYMPHYSIS:
        half = 6.5 - 2.5 * (t - (1 - SYMPHYSIS)) / SYMPHYSIS
        if a > JAW_LEN - 5:
            half *= math.sqrt((JAW_LEN - a) / 5.0)
        if abs(b) <= half:
            s = b / half
            best, tag = 7.0 * (1 - 0.5 * s * s), "jaw"
            # peg teeth along both edges of the rod
            k = (a % 7.5) - 3.75
            if JAW_LEN - a > 8:
                for side in (-1, 1):
                    d = math.hypot(k, (b - side * half * 0.62) * 1.25)
                    if d < 2.6:
                        best = max(best, 7.0 + 5.0 * (1 - (d / 2.6) ** 2) ** 0.5)
                        tag = "tooth"
    else:
        # the two branches spreading toward the hinge
        f = (1 - SYMPHYSIS - t) / (1 - SYMPHYSIS)
        for side in (-1, 1):
            c = side * (5 + 22 * f ** 1.1)
            half = 4.5 + 3.5 * f
            if a < 10:
                half *= math.sqrt(max(0.0, a / 10.0))
            if abs(b - c) <= half:
                s = (b - c) / half
                h = (7 + 7 * f ** 1.5) * (1 - 0.45 * s * s)
                if best is None or h > best:
                    best, tag = h, "jaw"
    if best is not None:
        best -= 2.0     # half sunk in the sand
        if best <= 0.5:
            return None, None
    return best, tag


# ---- Rendering

class Body:
    """A height field laid on the ground: `local(wx, wy)` turns a ground
    point into the body's own plan coordinates, `field` gives the height."""

    def __init__(self, field, yaw_deg, centre, pivot):
        yaw = math.radians(yaw_deg)
        self.u = (math.cos(yaw), math.sin(yaw))      # plan +y on the ground
        self.v = (-math.sin(yaw), math.cos(yaw))     # plan +x on the ground
        self.field, self.centre, self.pivot = field, centre, pivot
        self._cache = {}

    def local(self, wx, wy):
        dx, dy = wx - self.centre[0], wy - self.centre[1]
        return (self.pivot[0] + dx * self.v[0] + dy * self.v[1],
                self.pivot[1] + dx * self.u[0] + dy * self.u[1])

    def ground(self, lx, ly):
        dx, dy = lx - self.pivot[0], ly - self.pivot[1]
        return (self.centre[0] + dx * self.v[0] + dy * self.u[0],
                self.centre[1] + dx * self.v[1] + dy * self.u[1])

    def at(self, wx, wy):
        """Height and part at a ground point, on a half-unit grid."""
        key = (int(round(wx * 2)), int(round(wy * 2)))
        hit = self._cache.get(key)
        if hit is None:
            hit = self.field(*self.local(key[0] / 2.0, key[1] / 2.0))
            self._cache[key] = hit
        return hit


def _light():
    n = math.sqrt(sum(c * c for c in LIGHT))
    return tuple(c / n for c in LIGHT)


def _shadowed(body, x, y, h, light):
    m = math.hypot(light[0], light[1])
    sx, sy, sz = light[0] / m, light[1] / m, light[2] / m
    for i in range(2, 120, 2):
        hh = body.at(x + sx * i, y + sy * i)[0]
        if hh is not None and hh > h + sz * i + 0.5:
            return True
    return False


def render(body, width, height, rows, scale=SCALE):
    """Draw a body seen from above. Each canvas pixel gets (face, light,
    part, plan x, plan y, ground y) where face is "top" or "side"."""
    light = _light()
    canvas = [[None] * width for _ in range(height)]
    wy = rows[0]
    while wy <= rows[1]:
        for xi in range(width * 2):
            wx = xi / 2.0
            mx, my = wx / scale, wy / scale
            h, part = body.at(mx, my)
            if h is None:
                continue
            e = 1.0
            near = [body.at(mx + e, my)[0], body.at(mx - e, my)[0],
                    body.at(mx, my + e)[0], body.at(mx, my - e)[0]]
            near = [n if n is not None else h - 3 for n in near]
            dx, dy = (near[0] - near[1]) / (2 * e), (near[2] - near[3]) / (2 * e)
            d = (-dx * light[0] - dy * light[1] + light[2]) / math.sqrt(dx * dx + dy * dy + 1)
            lx, ly = body.local(mx, my)
            sx = int(wx)
            sy = int(round(wy * PY - h * scale * PH))
            gy = int(round(wy * PY))
            for yy in range(max(0, sy), min(height, gy + 1)):
                canvas[yy][sx] = ("side", d, part, lx, ly, gy)
            if 0 <= sy < height:
                if d > 0 and _shadowed(body, mx, my, h, light):
                    d = min(d, 0.2)
                canvas[sy][sx] = ("top", d, part, lx, ly, gy)
        wy += 0.25
    return canvas


def shade(canvas):
    """Light each pixel with the bone ramps, mark the nares, drift sand along
    the foot and outline it all."""
    width, height = len(canvas[0]), len(canvas)
    bone, stain, sand = [hx(c) for c in BONE], [hx(c) for c in STAIN], [hx(c) for c in SAND]
    out = [[(0, 0, 0, 0)] * width for _ in range(height)]
    for y in range(height):
        for x in range(width):
            c = canvas[y][x]
            if c is None:
                continue
            face, d, part, lx, ly, _ = c
            if face == "side":
                lv = 4 if d < 0.45 else 3
            else:
                b = 0.16 + 0.95 * max(0.0, d)
                if part == "basin":
                    b -= 0.08 * (1 - basin_r(lx, ly)[0])
                else:
                    b += (noise(lx * 0.35, ly * 0.2, 3) - 0.5) * 0.04
                lv = 0 if b > 0.98 else 1 if b > 0.84 else 2 if b > 0.68 else 3 if b > 0.52 else 4 if b > 0.36 else 5
                if part == "groove":
                    lv = min(5, lv + 2)
                elif part == "basin":
                    r, _, v = basin_r(lx, ly)
                    if r > 0.955 and v < 0.35:      # the crest's lit lip
                        lv = max(0, min(lv, 1) - (1 if d > 0.4 else 0))
                elif part == "rostrum":
                    s = abs(lx - CX) / max(1e-6, rostrum_half(ly))
                    if abs(s - 0.46) < 0.03 and ly > 100:   # premaxilla suture
                        lv = min(5, lv + 2)
                elif part == "tooth":
                    lv = max(0, lv - 1)
            ramp = bone
            if part in ("rostrum", "jaw") and noise(lx * 0.35, ly * 0.03, 11) > 0.74 \
                    and noise(lx * 0.05, ly * 0.05, 2) > 0.5:
                ramp = stain        # long weathering streaks
            out[y][x] = ramp[lv]
            if face == "top" and part in ("basin", "groove", "rostrum") and (
                    in_ellipse(lx, ly, NARIS_BIG) or in_ellipse(lx, ly, NARIS_SMALL)):
                out[y][x] = hx(HOLE[0])
    # sand drifted against the foot of the bone
    for x in range(width):
        for y in range(height):
            if canvas[y][x] is not None and (y + 1 >= height or canvas[y + 1][x] is None):
                drift = 1 + int(2.5 * noise(x * 0.18, y * 0.1, 9) + 1.5 * noise(x * 0.5, 3, 4))
                for yy in range(y - drift + 1, y + 1):
                    if canvas[yy][x] is not None:
                        out[yy][x] = sand[2] if yy == y - drift + 1 else sand[1]
    final = [row[:] for row in out]
    o = hx(OUTLINE)
    sandy = set(sand)
    for y in range(height):
        for x in range(width):
            if out[y][x][3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if not (0 <= xx < width and 0 <= yy < height) or out[yy][xx][3] == 0:
                    # no hard line where the sand runs into the ground
                    if dy != 1 or not (out[y][x] in sandy or (y > 0 and out[y - 1][x] in sandy)):
                        final[y][x] = o
                    break
    # a dark seam where a near surface stands in front of a far one
    for y in range(1, height):
        for x in range(width):
            a, b = canvas[y][x], canvas[y - 1][x]
            if a and b and a[0] == "top" and final[y - 1][x] != o and a[5] - b[5] > 6:
                final[y - 1][x] = hx(BONE[5])
    return final


def _crop(px):
    xs = [x for row in px for x, p in enumerate(row) if p[3]]
    ys = [y for y, row in enumerate(px) if any(p[3] for p in row)]
    return min(xs), max(xs) + 1, min(ys), max(ys) + 1


def _fossa(px, body, canvas):
    """The temporal fossa: an egg-shaped hollow in the near side wall, a bony
    bar arching over it, sand spilling from its floor. Returns the middle of
    its floor in canvas pixels."""
    lx = CX
    while skull_height(lx - 1, FOSSA_Y)[0] is not None:
        lx -= 1
    gx, gy = body.ground(lx, FOSSA_Y)
    cx, base = int(round(gx * SCALE)), int(round(gy * SCALE * PY))
    w, hgt = 22, 26
    ctr = base - hgt * 0.55
    hole = [hx(c) for c in HOLE]
    for y in range(base - hgt - 4, base + 1):
        for x in range(cx - w // 2 - 3, cx + w // 2 + 3):
            if not px[y][x][3]:
                continue
            dx = (x + 0.5 - cx) / (w / 2.0)
            dy = (y + 0.5 - ctr) / (hgt * 0.58)
            r = dx * dx + dy * dy * (1.0 if dy < 0 else 0.55)
            if r <= 1.0:
                c = hole[0]
                if dx < -0.45 and dy > -0.5:     # the inner wall, catching light
                    c = hole[2] if dx < -0.72 else hole[1]
                px[y][x] = c
            elif r <= 1.5 and dy < -0.15:
                # the bony arch over it, lit bright so the opening stands out
                px[y][x] = hx(BONE[0]) if r > 1.2 else hx(BONE[5])
            elif r <= 1.35:
                px[y][x] = hx(BONE[0]) if dx > 0 else hx(BONE[5])
    # worn steps going down into the dark: each lip lit, each riser black,
    # narrower the deeper they go
    dark = (hole[0], hole[1], hole[2])
    for i, (lip, inset) in enumerate(((base - 2, 2), (base - 6, 4), (base - 10, 6), (base - 13, 8))):
        for x in range(cx - w // 2 + inset, cx + w // 2 - inset + 1):
            if px[lip][x] in dark:
                px[lip][x] = hx(BONE[(1, 2, 4, 5)[i]])
                if i < 2 and px[lip + 1][x] in dark:
                    px[lip + 1][x] = hx(BONE[(3, 4)[i]])
    for x in range(cx - w // 2 + 1, cx + w // 2):
        px[base][x] = hx(SAND[1])
        if (x * 7) % 5 < 3:
            px[base - 1][x] = hx(SAND[2])
    # a short worn path of packed sand leading in, flaring as it leaves
    for dy in range(1, 34):
        t = dy / 33.0
        half = 6 + 3 * t + 0.7 * math.sin(dy * 0.7)
        mid = cx - 14 * t * t          # bending off toward the open sand
        fade = t > 0.8
        for x in range(int(mid - half - 1), int(mid + half + 2)):
            e = abs(x + 0.5 - mid) / half
            if e > 1.08:
                continue
            if fade and (x + dy) % 2 and e > 0.5:
                continue
            if e > 0.86:
                c = SAND[0] if not fade else SAND[2]    # sand heaped along its edge
            else:
                c = SAND[3] if (x * 3 + dy * 5) % 9 else SAND[4]
            px[base + dy][x] = hx(c)
    # the eye: a small socket under a lit brow, forward of the hollow
    ex, ey = body.ground(lx + 6, FOSSA_Y + 30)
    ox, oy = int(round(ex * SCALE)), int(round(ey * SCALE * PY)) - 9
    for y in range(oy - 3, oy + 3):
        for x in range(ox - 4, ox + 5):
            if ((x - ox) / 4.2) ** 2 + ((y - oy + 0.5) / 2.6) ** 2 <= 1 and px[y][x][3]:
                px[y][x] = hole[0] if y > oy - 2 else hx(BONE[5])
    for x in range(ox - 4, ox + 5):
        if px[oy - 4][x][3]:
            px[oy - 4][x] = hx(BONE[0])
    return cx, base


def footprint(canvas, x0, y0, strip=6):
    """Where the bone meets the ground, as (x, y, w, h) strips in sprite
    pixels: what Wren bumps into."""
    cells = set()
    for row in canvas:
        for x, c in enumerate(row):
            if c is not None and c[0] == "top":
                cells.add((x - x0, c[5] - y0))
    rects = []
    ys = sorted({y for _, y in cells})
    for top in range(ys[0], ys[-1] + 1, strip):
        xs = [x for x, y in cells if top <= y < top + strip]
        if xs:
            rects.append((min(xs), top, max(xs) - min(xs) + 1, strip))
    return rects


SKULL_YAW = 155.0
JAW_YAW = 168.0


def skull():
    """The skull sprite, its door (the hollow's floor) and footprint, all in
    sprite pixels. The sprite is padded so the hollow's middle sits a whole
    number of tiles from the sprite's middle."""
    body = Body(skull_height, SKULL_YAW, (180.0, 200.0), (CX, 150.0))
    canvas = render(body, 360, 300, (-60.0, 420.0))
    px = shade(canvas)
    door = _fossa(px, body, canvas)
    x0, x1, y0, y1 = _crop(px)
    # pad on the left until the door is 4 tiles right of the middle
    w = x1 - x0
    pad = 0
    while (door[0] - x0 + pad) - (w + pad) // 2 != 64:
        pad += 1
        assert pad < 200, "can't line the door up"
    x0 -= pad
    sprite = [row[x0:x1] for row in px[y0:y1]]
    return sprite, (door[0] - x0, door[1] - y0), footprint(canvas, x0, y0)


def jaw():
    body = Body(lambda a, b: jaw_height(b, a), JAW_YAW, (230.0, 40.0), (0.0, 0.0))
    canvas = render(body, 260, 140, (-40.0, 200.0))
    px = shade(canvas)
    x0, x1, y0, y1 = _crop(px)
    return [row[x0:x1] for row in px[y0:y1]], footprint(canvas, x0, y0)


def small_skull():
    """A smaller kinsman's skull, sunk deeper, for Saltpan Hollow: the same
    bones at a third of the size, no door."""
    body = Body(skull_height, 25.0, (180.0, 200.0), (CX, 150.0))
    canvas = render(body, 200, 200, (-60.0, 420.0), scale=0.34)
    px = shade(canvas)
    x0, x1, y0, y1 = _crop(px)
    return [row[x0:x1] for row in px[y0:y1]], footprint(canvas, x0, y0, strip=4)


MOSS = ["#C4DB7A", "#9FC46A", "#6F9A4E", "#3F6648", "#1F3A33"]
FEN_LIGHT = ["#E8FFF8", "#6EF0E0"]
CALF_SCALE = 0.24
CALF_YAW = 25.0


def calf_skull():
    """The Old One's lost calf (the Calf's Rest, south of Gloamfen): the same
    sperm-whale bones as its kin on the dunes, a fifth of their size, sunk to
    the jaw in fen moss, moss grown over the crown, reeds at its sides and
    three fen-lights resting on the bone. Returns the sprite and its foot
    row (where it meets the fen)."""
    body = Body(skull_height, CALF_YAW, (180.0, 200.0), (CX, 150.0))
    canvas = render(body, 120, 120, (-60.0, 420.0), scale=CALF_SCALE)
    px = shade(canvas)
    x0, x1, y0, y1 = _crop(px)
    pad_top, pad_side, pad_bottom = 5, 3, 3
    w, h = x1 - x0 + pad_side * 2, y1 - y0 + pad_top + pad_bottom
    out = [[(0, 0, 0, 0)] * w for _ in range(h)]
    for y in range(y0, y1):
        for x in range(x0, x1):
            out[y - y0 + pad_top][x - x0 + pad_side] = px[y][x]
    moss = [hx(c) for c in MOSS]
    sand = {hx(c) for c in SAND}
    # Sand drifts become fen moss.
    for y in range(h):
        for x in range(w):
            if out[y][x] in sand:
                out[y][x] = moss[1] if (x + y) % 3 else moss[2]
    # Moss over the crown: lit top pixels in patches.
    bone = {hx(c) for c in BONE} | {hx(c) for c in STAIN}
    for y in range(h):
        for x in range(w):
            if out[y][x] in bone and y < pad_top + 9 and noise(x * 0.45, y * 0.6, 21) > 0.72:
                out[y][x] = moss[0] if y < pad_top + 5 else moss[1]
    # Sunk to the jaw: a ragged band of fen moss across the foot.
    foot = h - pad_bottom
    # Only under the bone (and a little past it), ragged at the ends.
    cols = [x for x in range(w) if any(out[y][x][3] for y in range(foot - 6, foot))]
    left, right = min(cols) - 2, max(cols) + 2
    for x in range(max(0, left), min(w, right + 1)):
        end = min(x - left, right - x)
        top = foot - 1 - int(3.2 * noise(x * 0.35, 1, 5)) + (2 - min(end, 2))
        for y in range(max(0, top), min(h, foot + 2)):
            if out[y][x][3] or y >= foot - 2:
                edge = y == top
                out[y][x] = moss[0] if edge else moss[2] if (x * 3 + y) % 4 else moss[3]
        if out[min(h - 1, foot + 1)][x][3]:
            out[min(h - 1, foot + 1)][x] = moss[4]
    # Reeds at either side.
    o = hx(OUTLINE)
    for x, tall in ((max(0, left), 9), (max(0, left) + 2, 12), (min(w - 1, right) - 3, 11), (min(w - 1, right), 8)):
        for y in range(foot - tall, foot):
            out[y][x] = moss[3] if y > foot - tall + 1 else moss[1]
    # Three fen-lights resting on the bone.
    lights = [hx(c) for c in FEN_LIGHT]
    for fx, fy in ((w // 2 - 2, pad_top + 2), (pad_side + 6, h // 2), (w - pad_side - 9, foot - 7)):
        out[fy][fx] = lights[0]
        out[fy][fx + 1] = lights[1]
        if out[fy - 1][fx][3] == 0:
            out[fy - 1][fx] = lights[1]
    return out, foot
