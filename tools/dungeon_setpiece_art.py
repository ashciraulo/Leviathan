#!/usr/bin/env python3
"""Floor set pieces for the dungeons that read plainer than the Tomb and the
Maw: one big 32x32 picture laid into an open stretch of floor, so each room
of those dungeons has something of its own to look at. They're transparent
overlays drawn over the floor (scripts/world/room.gd places them, "set_pieces"
in a biome's tile table), never solid.

  hull     a ship's wheel lying flat on the deck; a tangle of old net
           with a cork float and a starfish caught in it
  kiln     a cooled spill of bronze, crusted, a drip channel feeding it;
           a brass ring set in the floor with the kiln's flame mark
  gale     a compass rose inlaid in copper; a fallen kite, torn, its string
           trailing
  glacier  a fish frozen under the floor's ice; a bloom of hoar frost
  belfry   a broken piece of a drowned bell, weed and shells round it; a
           round mosaic of a fish in sea-glass tesserae
  mire     a sunken grave slab with candle stubs; a mourners' ring of pale
           flowers

Each is cut into four tiles: <dungeon>_set<k>_0 (top left), _1 (top right),
_2 (bottom left), _3 (bottom right). build_art.py adds them to the world
tile sheet.
"""

import math
import random

S = 32
T = 16
CLEAR = (0, 0, 0, 0)


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def canvas():
    return [[CLEAR] * S for _ in range(S)]


def put(px, x, y, c):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < S and 0 <= y < S:
        px[y][x] = c


def disc(px, cx, cy, r, c, ry=None):
    ry = r if ry is None else ry
    for y in range(S):
        for x in range(S):
            if ((x + 0.5 - cx) / r) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                px[y][x] = c


def ring(px, cx, cy, r0, r1, c):
    for y in range(S):
        for x in range(S):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if r0 <= d <= r1:
                px[y][x] = c


def line(px, x0, y0, x1, y1, c):
    steps = int(max(abs(x1 - x0), abs(y1 - y0), 1) * 2)
    for i in range(steps + 1):
        put(px, x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps, c)


def poly(px, pts, c):
    """Fills a polygon (even-odd)."""
    for y in range(S):
        for x in range(S):
            px_, py_ = x + 0.5, y + 0.5
            inside = False
            j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > py_) != (yj > py_) and px_ < (xj - xi) * (py_ - yi) / (yj - yi) + xi:
                    inside = not inside
                j = i
            if inside:
                px[y][x] = c


# --------------------------------------------------------------------------
# Rotting Hull.
# --------------------------------------------------------------------------
def hull_wheel():
    px = canvas()
    wood = [hx("#E8BC78"), hx("#C08848"), hx("#7E5530"), hx("#3A2412")]
    brass = [hx("#F0D080"), hx("#B8923C")]
    shadow = hx("#1A1008", 110)
    ring(px, 17, 17.5, 8.5, 12.0, shadow)
    # Eight spokes running out past the rim into turned handles.
    for k in range(8):
        a = k * math.tau / 8 + 0.2
        c, sn = math.cos(a), math.sin(a)
        for off in (-0.5, 0.5):
            line(px, 16 + c * 2 - sn * off, 16 + sn * 2 + c * off,
                 16 + c * 13 - sn * off, 16 + sn * 13 + c * off, wood[3])
        line(px, 16 + c * 2, 16 + sn * 2, 16 + c * 12, 16 + sn * 12, wood[1])
        disc(px, 16 + c * 13.6, 16 + sn * 13.6, 1.7, wood[3])
        disc(px, 16 + c * 13.6, 16 + sn * 13.6, 1.1, wood[1])
        put(px, 16 + c * 13.6 - 0.5, 16 + sn * 13.6 - 0.5, wood[0])
    ring(px, 16, 16, 8.3, 11.2, wood[3])
    ring(px, 16, 16, 9.0, 10.5, wood[1])
    for k in range(28):
        a = k * math.tau / 28
        put(px, 16 + math.cos(a) * 9.6, 16 + math.sin(a) * 9.6 - 0.5, wood[0])
    # The hub, brass-capped.
    disc(px, 16, 16, 3.4, wood[3])
    disc(px, 16, 16, 2.4, brass[1])
    put(px, 15, 15, brass[0])
    # One handle snapped off: the deck took it.
    a = 5 * math.tau / 8 + 0.2
    disc(px, 16 + math.cos(a) * 13.6, 16 + math.sin(a) * 13.6, 2.4, CLEAR)
    return px


def hull_net():
    px = canvas()
    cord = [hx("#C8B890", 230), hx("#9A8A68", 220)]
    cork = [hx("#E0A060"), hx("#A86A34")]
    star = [hx("#F08A6A"), hx("#C85A44")]
    rnd = random.Random(21)
    # A sagging diamond mesh, ragged at the edges.
    for i in range(-3, 9):
        x0 = i * 5
        for y in range(3, 29):
            sway = math.sin(y * 0.35 + i) * 1.2
            for xx in (x0 + (y - 3) * 0.6 + sway, x0 + 22 - (y - 3) * 0.6 + sway):
                d = math.hypot(xx - 16, (y - 16) * 1.15)
                if d < 13.5 - rnd.random() * 2.5:
                    put(px, xx, y, cord[(i + y) % 2])
    # Knots where the cords cross.
    for y in range(0, S):
        for x in range(0, S):
            c = px[y][x]
            if c != CLEAR and x + 1 < S and y + 1 < S and px[y][x + 1] != CLEAR and px[y + 1][x] != CLEAR:
                put(px, x, y, cord[1])
    # A cork float on the rim, and a starfish caught in the mesh.
    disc(px, 24.5, 8.5, 2.8, cork[1], 2.2)
    disc(px, 24, 8, 2.2, cork[0], 1.6)
    for k in range(5):
        a = k * math.tau / 5 - math.pi / 2
        line(px, 11, 19, 11 + math.cos(a) * 4.5, 19 + math.sin(a) * 4.5, star[1])
        line(px, 11, 19, 11 + math.cos(a) * 3.2, 19 + math.sin(a) * 3.2, star[0])
    disc(px, 11, 19, 1.4, star[0])
    return px


# --------------------------------------------------------------------------
# Kiln.
# --------------------------------------------------------------------------
def kiln_spill():
    px = canvas()
    metal = [hx("#E8C078"), hx("#C08A44"), hx("#8A5A2C"), hx("#4E3018")]
    crust = hx("#3A2A22")
    glow = hx("#FF9A3A")
    rnd = random.Random(31)
    # A lopsided puddle of cooled bronze with lobes.
    for (cx, cy, rx, ry) in ((16, 18, 10, 7), (9, 15, 5, 4), (22, 22, 5, 4), (20, 13, 4, 3)):
        disc(px, cx + 0.8, cy + 1.2, rx, crust, ry)
    for (cx, cy, rx, ry) in ((16, 18, 10, 7), (9, 15, 5, 4), (22, 22, 5, 4), (20, 13, 4, 3)):
        disc(px, cx, cy, rx - 0.6, metal[2], ry - 0.6)
    disc(px, 15, 17, 7, metal[1], 4.2)
    disc(px, 13, 16, 3.5, metal[0], 1.6)
    # Wrinkles where it cooled, and a still-warm crack.
    for _ in range(14):
        x, y = rnd.uniform(8, 24), rnd.uniform(13, 23)
        if px[int(y)][int(x)] in (metal[1], metal[2]):
            line(px, x, y, x + rnd.uniform(1.5, 3), y + rnd.uniform(-0.6, 0.6), metal[3])
    line(px, 17, 19, 21, 21, glow)
    put(px, 18, 20, hx("#FFE0A0"))
    # The drip channel it ran out of.
    for y in range(1, 11):
        put(px, 16 + math.sin(y * 0.6), y, crust)
        put(px, 17 + math.sin(y * 0.6), y, metal[2])
    return px


def kiln_mark():
    px = canvas()
    brass = [hx("#F4D48A"), hx("#C89A48"), hx("#8A6430")]
    soot = hx("#22161A", 200)
    ember = [hx("#FFB040"), hx("#E06A2A"), hx("#A03A1E")]
    disc(px, 16, 16, 13.5, soot)
    ring(px, 16, 16, 11.5, 13.0, brass[1])
    ring(px, 16, 16, 11.5, 12.0, brass[0])
    ring(px, 16, 16, 13.0, 13.6, brass[2])
    # Rivets round the ring.
    for k in range(8):
        a = k * math.tau / 8 + math.pi / 8
        put(px, 16 + math.cos(a) * 12.3, 16 + math.sin(a) * 12.3, brass[2])
    # The flame mark, inlaid: three tongues rising from a bowl.
    poly(px, [(9, 20), (23, 20), (21, 24), (11, 24)], brass[2])
    line(px, 10, 20, 22, 20, brass[0])
    for (bx, h, w) in ((12.5, 9, 2.4), (16, 13, 3.2), (19.5, 8, 2.4)):
        poly(px, [(bx - w, 19.5), (bx + w, 19.5), (bx + 0.6, 19.5 - h)], ember[1])
        poly(px, [(bx - w * 0.45, 19.5), (bx + w * 0.45, 19.5), (bx + 0.3, 19.5 - h * 0.6)], ember[0])
    put(px, 16, 7, ember[2])
    return px


# --------------------------------------------------------------------------
# Gale Spire.
# --------------------------------------------------------------------------
def gale_compass():
    px = canvas()
    copper = [hx("#F4C890"), hx("#D89A5A"), hx("#B06E3A"), hx("#7A4626")]
    slate_dark = hx("#4C5A76")
    slate_mid = hx("#5A6886")
    ring(px, 16, 16, 12.5, 14.5, copper[2])
    ring(px, 16, 16, 12.5, 13.2, copper[1])
    disc(px, 16, 16, 12.4, slate_dark)
    ring(px, 16, 16, 8.0, 8.8, slate_mid)
    # The points: north long and bright, the rest copper.
    for ang, length, col in ((-90, 12, copper[0]), (90, 9, copper[2]), (0, 9, copper[2]), (180, 9, copper[2])):
        a = math.radians(ang)
        tip = (16 + math.cos(a) * length, 16 + math.sin(a) * length)
        side = math.radians(ang + 90)
        w = 2.6
        poly(px, [tip, (16 + math.cos(side) * w, 16 + math.sin(side) * w), (16 - math.cos(side) * w, 16 - math.sin(side) * w)], col)
    for ang in (45, 135, 225, 315):
        a = math.radians(ang)
        line(px, 16, 16, 16 + math.cos(a) * 7, 16 + math.sin(a) * 7, copper[3])
    put(px, 16, 16, copper[3])
    put(px, 15, 15, copper[0])
    # Tick marks round the rim.
    for k in range(16):
        a = k * math.pi / 8
        put(px, 16 + math.cos(a) * 11.2, 16 + math.sin(a) * 11.2, copper[1])
    return px


def gale_kite():
    px = canvas()
    cloth = [hx("#E8D8B0"), hx("#C8B488"), hx("#A08A62")]
    red = [hx("#E07060"), hx("#B84A44")]
    stick = hx("#76643E")
    shadow = hx("#2A3248", 90)
    pts = [(14, 4), (25, 13), (15, 25), (5, 13)]
    poly(px, [(x + 1.5, y + 1.5) for x, y in pts], shadow)
    poly(px, pts, cloth[1])
    poly(px, [(14, 4), (25, 13), (15, 14)], cloth[0])
    poly(px, [(5, 13), (15, 14), (15, 25)], cloth[2])
    # A red band, and a tear.
    poly(px, [(9, 9), (11, 7), (21, 17), (19, 19)], red[1])
    poly(px, [(10, 8), (11, 7), (21, 17), (20, 18)], red[0])
    for (x, y) in ((17, 20), (18, 19), (18, 21), (19, 20)):
        put(px, x, y, CLEAR)
    line(px, 14, 4, 15, 25, stick)
    line(px, 5, 13, 25, 13, stick)
    # The string, trailing off in loops.
    prev = (15, 25)
    for i in range(1, 14):
        p = (15 + i * 1.1, 25 + math.sin(i * 0.9) * 2.5 + i * 0.25)
        line(px, prev[0], prev[1], p[0], p[1], cloth[2])
        prev = p
    return px


# --------------------------------------------------------------------------
# Hollow Glacier.
# --------------------------------------------------------------------------
def glacier_fish():
    px = canvas()
    frost = hx("#CFE9F6", 170)
    deep = hx("#7EB2D0", 200)
    fish = [hx("#244E74", 220), hx("#34688E", 210), hx("#12283A", 230)]
    disc(px, 16, 16, 14, frost, 11)
    disc(px, 16, 16, 12, deep, 9)
    # The fish, tilted, mouth open, caught mid-turn.
    disc(px, 15, 16, 8, fish[1], 3.6)
    disc(px, 14, 15.4, 6.5, fish[0], 2.2)
    poly(px, [(22, 16), (28, 11), (27, 16), (28, 21)], fish[1])
    poly(px, [(13, 13), (17, 9), (18, 13)], fish[0])
    put(px, 9, 15, hx("#E8F8FF"))
    put(px, 7, 16, fish[2])
    put(px, 8, 17, fish[2])
    # Bubbles frozen above it, and a crack across the ice.
    for (x, y) in ((6, 10), (8, 8), (7, 6)):
        put(px, x, y, hx("#FFFFFF", 230))
    line(px, 4, 22, 12, 19, hx("#FFFFFF", 200))
    line(px, 12, 19, 16, 23, hx("#FFFFFF", 200))
    line(px, 16, 23, 25, 21, hx("#FFFFFF", 160))
    # A sheen.
    line(px, 19, 8, 24, 10, hx("#FFFFFF", 160))
    return px


def glacier_frost():
    px = canvas()
    rnd = random.Random(7)
    cols = [hx("#FFFFFF", 235), hx("#DDF2FC", 220), hx("#A8D8F0", 200)]
    # Feathery fronds growing out from a centre.
    for k in range(7):
        a = k * math.tau / 7 + 0.3
        length = 11 + rnd.random() * 3
        for i in range(int(length * 2)):
            t = i / 2
            x = 16 + math.cos(a) * t
            y = 16 + math.sin(a) * t
            put(px, x, y, cols[0] if t < 6 else cols[1])
            if i % 3 == 0 and t > 2:
                for side in (1, -1):
                    b = a + side * 0.9
                    for j in range(1, int(4 - t / 5) + 1):
                        put(px, x + math.cos(b) * j, y + math.sin(b) * j, cols[2] if j > 1 else cols[1])
    disc(px, 16, 16, 1.6, cols[0])
    return px


# --------------------------------------------------------------------------
# Drowned Belfry.
# --------------------------------------------------------------------------
def belfry_shard():
    px = canvas()
    bronze = [hx("#A8E0C8"), hx("#78C0A6"), hx("#5FA08A"), hx("#3E6E5E"), hx("#1E3830")]
    brass = hx("#D8A84A")
    weed = [hx("#6AA04A"), hx("#4E8038")]
    shadow = hx("#20382F", 110)
    # A curved slab of bell wall lying on its side, its lip up.
    outer = [(3, 20), (8, 11), (16, 7), (25, 8), (29, 13), (27, 15), (22, 12), (15, 12), (9, 16), (7, 23)]
    poly(px, [(x + 1, y + 2) for x, y in outer], shadow)
    poly(px, outer, bronze[2])
    poly(px, [(8, 11), (16, 7), (25, 8), (24, 10), (16, 9), (9, 13)], bronze[1])
    poly(px, [(9, 16), (15, 12), (22, 12), (27, 15), (22, 14), (15, 14), (10, 18)], bronze[3])
    line(px, 6, 17, 13, 10, brass)
    line(px, 13, 10, 22, 9, brass)
    # Its broken edge.
    for (x, y) in ((3, 20), (4, 21), (5, 22), (6, 23), (7, 23)):
        put(px, x, y, bronze[4])
    # Weed and shells round it.
    for (x0, y0, h) in ((5, 27, 6), (11, 28, 5), (24, 24, 7), (27, 25, 5)):
        for i in range(h):
            put(px, x0 + math.sin(i * 0.9) * 1.2, y0 - i, weed[i % 2])
    for (x, y) in ((17, 24), (19, 26), (14, 25)):
        put(px, x, y, hx("#F0E8D8"))
        put(px, x + 1, y, hx("#C8B8A0"))
    return px


def belfry_mosaic():
    px = canvas()
    rnd = random.Random(11)
    sea = [hx("#2E6A7C"), hx("#245C6E"), hx("#3E7E8A")]
    rim = [hx("#D8A84A"), hx("#B07E2E")]
    fish = [hx("#E8D8A8"), hx("#C8B488")]
    grout = hx("#34564C")
    # Tesserae: 2x2 tiles with grout between.
    for ty in range(0, S, 3):
        for tx in range(0, S, 3):
            cx, cy = tx + 1, ty + 1
            d = math.hypot(cx - 15.5, cy - 15.5)
            if d > 14:
                continue
            if d > 12:
                col = rim[(tx + ty) // 3 % 2]
            else:
                col = sea[rnd.randrange(3)]
                # The fish: a lens of pale tiles across the middle, a tail.
                if ((cx - 14) / 8.5) ** 2 + ((cy - 15.5) / 4.2) ** 2 <= 1.0:
                    col = fish[rnd.randrange(2)]
                if 21 <= cx <= 26 and abs(cy - 15.5) <= (cx - 20) * 0.9:
                    col = fish[1]
            for y in range(ty, ty + 2):
                for x in range(tx, tx + 2):
                    put(px, x, y, col)
            put(px, tx + 2, ty, grout)
            put(px, tx, ty + 2, grout)
    put(px, 9, 14, hx("#12283A"))
    put(px, 10, 14, hx("#12283A"))
    return px


# --------------------------------------------------------------------------
# Lantern Mire.
# --------------------------------------------------------------------------
def mire_grave():
    px = canvas()
    stone = [hx("#8E84AC"), hx("#6E6290"), hx("#4B3F72"), hx("#30284C")]
    moss = [hx("#5A8A6E"), hx("#3E6A58")]
    wax = hx("#E8E0D0")
    flame = hx("#C8F0A0")
    poly(px, [(6, 5), (26, 5), (27, 27), (5, 27)], stone[3])
    poly(px, [(6, 4), (26, 4), (26, 26), (6, 26)], stone[1])
    poly(px, [(6, 4), (26, 4), (25, 6), (7, 6)], stone[0])
    # A carved lamp in the slab, and lines of a worn name.
    for y in range(10, 18):
        put(px, 16, y, stone[2])
    disc(px, 16, 10, 2.2, stone[2])
    put(px, 16, 10, stone[0])
    line(px, 11, 20, 21, 20, stone[2])
    line(px, 12, 22, 20, 22, stone[2])
    # Moss creeping over its edges.
    rnd = random.Random(3)
    for _ in range(26):
        x = rnd.choice([rnd.randint(5, 9), rnd.randint(23, 27)])
        y = rnd.randint(5, 27)
        put(px, x, y, moss[rnd.randrange(2)])
    # Two candle stubs burnt low at its head corners, wax run down.
    for cx in (8, 23):
        for y in range(6, 10):
            put(px, cx, y, wax)
            put(px, cx + 1, y, wax)
        put(px, cx - 1, 9, wax)
        put(px, cx + 2, 10, wax)
        put(px, cx, 5, flame)
        put(px, cx + 1, 4, hx("#F2FFE0"))
    return px


def mire_wreath():
    px = canvas()
    leaf = [hx("#5A8A6E"), hx("#3E6A58")]
    petals = [hx("#F2EEF8"), hx("#D8D0F0"), hx("#B8ACE0")]
    rnd = random.Random(5)
    for k in range(40):
        a = k * math.tau / 40
        r = 10 + rnd.random() * 1.5
        put(px, 16 + math.cos(a) * r, 16 + math.sin(a) * r, leaf[k % 2])
        put(px, 16 + math.cos(a) * (r + 1.3), 16 + math.sin(a) * (r + 1.3), leaf[1])
    for k in range(11):
        a = k * math.tau / 11 + 0.2
        cx, cy = 16 + math.cos(a) * 10.5, 16 + math.sin(a) * 10.5
        for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
            put(px, cx + dx, cy + dy, petals[k % 2])
        put(px, cx, cy, hx("#F0D070"))
    # A few petals fallen inside.
    for (x, y) in ((14, 15), (18, 18), (16, 13)):
        put(px, x, y, petals[2])
    return px


PIECES = {
    "hull": [hull_wheel, hull_net],
    "kiln": [kiln_spill, kiln_mark],
    "gale": [gale_compass, gale_kite],
    "glacier": [glacier_fish, glacier_frost],
    "belfry": [belfry_shard, belfry_mosaic],
    "mire": [mire_grave, mire_wreath],
}


def quarters(px):
    out = []
    for oy in (0, T):
        for ox in (0, T):
            out.append([row[ox:ox + T] for row in px[oy:oy + T]])
    return out


TILES = []
for _dungeon, _makers in PIECES.items():
    for _k, _make in enumerate(_makers):
        for _i, _q in enumerate(quarters(_make())):
            TILES.append(("%s_set%d_%d" % (_dungeon, _k, _i), lambda q=_q: q))
