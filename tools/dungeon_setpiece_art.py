#!/usr/bin/env python3
"""Floor set pieces for the dungeons that read plainer than the Tomb and the
Maw: one big 32x32 picture laid into an open stretch of floor, so each room
of those dungeons has something of its own to look at. They're transparent
overlays drawn over the floor (scripts/world/room.gd places them, "set_pieces"
in a biome's tile table), never solid.

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
