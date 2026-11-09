"""The Rotting Hull (Brinewood's dungeon), Old Hessa, and dungeon objects.

Tiles are RGBA 16x16 grids. Sprites and props are material silhouettes
that build_art.lit() shades. Imported by build_art.py.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)
# Deck planks: warm, mid-dark, so Wren's navy and white still pop.
PLANK = [hex_color(c) for c in ("#A07E5E", "#8C6E54", "#7A5E4A", "#664E42", "#523E3A", "#3E2E32")]
# The hull's own timbers, darker: walls read as heavier than floors.
TIMBER = [hex_color(c) for c in ("#8A6A56", "#6A5046", "#4E3A38", "#38282C", "#241A20", "#160F16")]
BILGE = [hex_color(c) for c in ("#7EA890", "#5A8478", "#3E665E", "#2E4E4A", "#223C3C", "#182C30")]
SCUM = hex_color("#A8BC84")
BARNACLE = [hex_color(c) for c in ("#FFF4E8", "#DCCCD4", "#B0A0B8", "#7A6890", "#3A2E4E")]
ROPE = [hex_color(c) for c in ("#F2E3C6", "#D9C59E", "#B8A07A", "#86705A", "#3E2C2E")]
IRON = hex_color("#2A2232")
LIGHT = hex_color("#FFE8A8")


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def plank_tile(seed):
    """Deck planks running across the room: four boards per tile, each with
    a seam under it, staggered butt joints, nails and a little grain."""
    rnd = random.Random(500 + seed)
    px = blank(PLANK[2])
    for board in range(4):
        y0 = board * 4
        tone = rnd.choice((1, 2, 2, 2))
        for y in range(y0, y0 + 3):
            for x in range(T):
                px[y][x] = PLANK[tone]
        # Lit top edge of each board, seam below it.
        for x in range(T):
            px[y0][x] = PLANK[max(tone - 1, 0)]
            px[y0 + 3][x] = PLANK[4]
        # A butt joint somewhere along the board, with nails either side.
        if rnd.random() < 0.7:
            jx = rnd.randrange(2, T - 2)
            for y in range(y0, y0 + 3):
                px[y][jx] = PLANK[4]
            px[y0 + 1][jx - 1] = PLANK[4]
            px[y0 + 1][jx + 1] = PLANK[0]
        # Grain: a short darker streak.
        for _ in range(1):
            gx, gy = rnd.randrange(T - 3), y0 + 1 + rnd.randrange(2)
            for dx in range(rnd.randrange(2, 4)):
                px[gy][gx + dx] = PLANK[min(tone + 1, 4)]
    return px


def hull_top(seed):
    """Wall top: the hull's heavy timbers seen from above."""
    rnd = random.Random(600 + seed)
    px = blank(TIMBER[3])
    for board in range(3):
        y0 = board * 5 + 1
        for y in range(y0, min(y0 + 4, T)):
            for x in range(T):
                px[y][x] = TIMBER[2] if y > y0 else TIMBER[1]
        for x in range(T):
            if y0 + 4 < T:
                px[y0 + 4][x] = TIMBER[4]
        if rnd.random() < 0.6:
            bx = rnd.randrange(2, T - 2)
            px[y0 + 1][bx] = IRON
            px[y0][bx] = TIMBER[0]
    for x in range(T):
        px[0][x] = TIMBER[4]
    for _ in range(5):
        x, y = rnd.randrange(T), rnd.randrange(T)
        if px[y][x] == TIMBER[2]:
            px[y][x] = TIMBER[3]
    return px


def hull_face(seed):
    """Wall face: horizontal hull planking with a curved rib standing in
    front, and barnacles crusting the bottom where the bilge once reached."""
    rnd = random.Random(700 + seed)
    px = blank(TIMBER[3])
    for y in range(T):
        for x in range(T):
            board = y // 4
            px[y][x] = TIMBER[2] if board % 2 == 0 else TIMBER[3]
            if y % 4 == 3:
                px[y][x] = TIMBER[4]
    # The rim: lit top edge where the wall top turns down into the face.
    for x in range(T):
        px[0][x] = TIMBER[1]
        px[1][x] = TIMBER[4]
    # One rib per tile, bowing slightly, lit on its left.
    rx = 5 + seed * 5
    for y in range(2, T):
        bow = round(1.5 * math.sin(y / T * math.pi))
        x = rx - bow
        px[y][x] = TIMBER[0]
        px[y][x + 1] = TIMBER[1]
        px[y][x + 2] = TIMBER[1]
        px[y][x + 3] = TIMBER[4]
    # Barnacles along the foot of the wall.
    for _ in range(4):
        x = rnd.randrange(1, T - 1)
        y = rnd.randrange(T - 4, T - 1)
        px[y][x] = BARNACLE[1]
        px[y + 1][x] = BARNACLE[3]
        px[y][x - 1] = BARNACLE[2]
    for x in range(T):
        px[T - 1][x] = TIMBER[5]
    return px


def bilge_tile(frame):
    px = blank(BILGE[4])
    rnd = random.Random(800)
    for _ in range(20):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = BILGE[5]
    # Oily sheen bands that slide a pixel each frame.
    for (x, y, n) in ((2, 3, 4), (9, 7, 3), (4, 12, 5)):
        for i in range(n):
            px[y][(x + i + frame) % T] = BILGE[2]
        px[y][(x + frame) % T] = BILGE[1]
    for (x, y) in ((12, 2), (6, 9), (14, 13)):
        xx = (x - frame) % T
        px[y][xx] = SCUM
    return px


def brine_edge(side, frame):
    """A scummy tide line where planks meet bilge water."""
    px = blank()
    for i in range(T):
        wobble = 1 if (i + frame * 2) % 6 < 2 else 0
        for d in range(1 + wobble):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = SCUM if d == 0 else BILGE[1]
    return px


def soak_edge(side, seed):
    """Wet, darkened planks beside the bilge."""
    rnd = random.Random(900 + seed)
    px = blank()
    shade = (40, 24, 30, 90)
    for i in range(T):
        depth = 3 + rnd.randrange(3)
        for d in range(depth):
            x, y = {"top": (i, d), "bottom": (i, T - 1 - d), "left": (d, i), "right": (T - 1 - d, i)}[side]
            px[y][x] = shade if d < depth - 1 else (40, 24, 30, 45)
    return px


def barnacles(seed):
    rnd = random.Random(1000 + seed)
    px = blank()
    for _ in range(3):
        cx, cy = rnd.randrange(3, 12), rnd.randrange(4, 12)
        px[cy][cx] = BARNACLE[0]
        px[cy][cx + 1] = BARNACLE[2]
        px[cy + 1][cx] = BARNACLE[2]
        px[cy + 1][cx + 1] = BARNACLE[3]
        px[cy + 2][cx] = BARNACLE[4]
        px[cy + 2][cx + 1] = BARNACLE[4]
    return px


def rope_coil(seed):
    """A loose coil of old rope, or a scatter of bent nails."""
    px = blank()
    if seed == 0:
        # A patch of soft, rotten board: darker, with a split down it.
        rnd = random.Random(1200)
        for y in range(5, 12):
            for x in range(3, 13):
                if (x - 8) ** 2 / 25 + (y - 8) ** 2 / 12 <= 1 and rnd.random() < 0.85:
                    px[y][x] = (46, 32, 36, 120)
        for x in range(4, 12):
            px[8][x] = (30, 20, 26, 200)
        return px
    if seed == 2:
        cx, cy = 8, 9
        for y in range(T):
            for x in range(T):
                d = math.hypot(x - cx, (y - cy) * 1.4)
                if 1.5 <= d <= 4.5:
                    ring = int(d * 1.5) % 2
                    lightside = (x - cx) + (y - cy) < 0
                    px[y][x] = ROPE[1 if lightside else 2] if ring == 0 else ROPE[3]
        for x in range(cx + 4, cx + 7):
            px[cy][x] = ROPE[2]
            px[cy + 1][x] = ROPE[4]
    else:
        for (x, y) in ((4, 6), (9, 10), (11, 5)):
            px[y][x] = IRON
            px[y][x + 1] = IRON
            px[y - 1][x + 1] = TIMBER[0]
    return px


def shaft(seed):
    """Daylight falling through a gap in the deck above: a soft, warm patch."""
    px = blank()
    rnd = random.Random(1100 + seed)
    x0 = rnd.randrange(0, 6)
    for y in range(T):
        for x in range(T):
            # A slanted band, brighter in its middle.
            u = x - x0 - y * 0.35
            if 0 <= u < 8:
                core = 2 <= u < 6
                px[y][x] = LIGHT[:3] + ((52 if core else 26),)
    return px


def exit_glow(seed):
    """The way out: a bright opening with daylight spilling in."""
    px = blank(PLANK[2])
    for y in range(T):
        for x in range(T):
            t = y / (T - 1)
            if t > 0.25:
                px[y][x] = hex_color("#FFE8A8") if t > 0.6 else hex_color("#E8C88A")
            else:
                px[y][x] = PLANK[1] if y % 4 != 3 else PLANK[5]
    for x in range(0, T, 3):
        px[5][x] = hex_color("#FFF4D6")
    return px


TILES = [
    ("plank_0", lambda: plank_tile(0)), ("plank_1", lambda: plank_tile(1)),
    ("plank_2", lambda: plank_tile(2)), ("plank_3", lambda: plank_tile(3)),
    ("hull_top_0", lambda: hull_top(0)), ("hull_top_1", lambda: hull_top(1)),
    ("hull_face_0", lambda: hull_face(0)), ("hull_face_1", lambda: hull_face(1)),
    ("bilge_0", lambda: bilge_tile(0)), ("bilge_1", lambda: bilge_tile(1)),
    ("brine_top_0", lambda: brine_edge("top", 0)), ("brine_bottom_0", lambda: brine_edge("bottom", 0)),
    ("brine_left_0", lambda: brine_edge("left", 0)), ("brine_right_0", lambda: brine_edge("right", 0)),
    ("brine_top_1", lambda: brine_edge("top", 1)), ("brine_bottom_1", lambda: brine_edge("bottom", 1)),
    ("brine_left_1", lambda: brine_edge("left", 1)), ("brine_right_1", lambda: brine_edge("right", 1)),
    ("soak_top", lambda: soak_edge("top", 1)), ("soak_bottom", lambda: soak_edge("bottom", 2)),
    ("soak_left", lambda: soak_edge("left", 3)), ("soak_right", lambda: soak_edge("right", 4)),
    ("barnacles_0", lambda: barnacles(0)), ("barnacles_1", lambda: barnacles(1)),
    ("rope_0", lambda: rope_coil(0)), ("rope_1", lambda: rope_coil(1)),
    ("shaft_0", lambda: shaft(0)), ("shaft_1", lambda: shaft(1)),
    ("exit_glow", lambda: exit_glow(0)),
]

# --------------------------------------------------------------------------
# Materials for sprites in this file (registered by build_art).
# --------------------------------------------------------------------------
RAMPS = {
    "H": ["#FFFFFF", "#E8E4EC", "#C0BAC8", "#8E86A0", "#463E58"],   # grey hair
    "E": ["#6E8AC8", "#4A62A0", "#34467A", "#222E56", "#10142E"],   # Hessa's old coat
    "T": ["#D8A870", "#B8844E", "#8E6040", "#5E3E34", "#2E1E24"],   # chest timber
    "S": ["#C8D0E0", "#9AA2BC", "#6E7694", "#4A506C", "#22263A"],   # iron bands
}
FLAT = {"%": "#E8B896"}  # rosy cheek (Hessa)


# --------------------------------------------------------------------------
# Old Hessa: Saltmarrow's lighthouse keeper. Built on the "big coat" keeper
# concept: an oversized navy coat with turned-up collar, a tilted cap, and
# grey hair. She has gone deaf, so she carries a brass ear trumpet and lifts
# it when Wren comes close. 16x24, feet on row 22.
# --------------------------------------------------------------------------
HESSA_BASE = [
    "................",
    "........EEEE....",
    "......EEEEEEE...",
    ".....EEEEJEEEE..",
    "...EEEEEEEEEEEE.",
    "..HHHwwwwwwwHH..",
    "..HHwHHwwHHwHH..",
    "..HHwewwwwewHH..",
    "..HH%wwwwww%HH..",
    "...HwwwHHwwwH...",
    "...jjwwwwwwjj...",
    "..EjjEEEEEEjjE..",
    ".EEEEEEEEEEEEEE.",
    ".EEEEEJEEJEEEEE.",
    ".EEEEEEEEEEEEEE.",
    ".wEEEEJEEJEEEEw.",
    ".EEEEEEEEEEEEEE.",
    "..EEEEEEEEEEEE..",
    "..EEEEEEEEEEEE..",
    "..EEEEEE.EEEEE..",
    "...EEEE..EEEE...",
    "....bbb..bbb....",
    "....bbb..bbb....",
    "................",
]


def _paint(rows, marks):
    out = [list(r) for r in rows]
    for (row, col, text) in marks:
        for i, ch in enumerate(text):
            out[row][col + i] = ch
    return ["".join(r) for r in out]


def hessa_frames():
    # Ear trumpet hanging from her right hand (viewer's right).
    hang = [(15, 14, "w"), (16, 14, "Q"), (17, 14, "Q"), (18, 13, "QQQ"), (19, 13, "QQQ"), (20, 13, "QQQ")]
    idle = _paint(HESSA_BASE, hang)
    # Breathing: shoulders settle by a pixel.
    breathe = ["." * 16] + idle[0:14] + idle[15:]
    # Listening: the trumpet lifted to her ear, bell turned towards Wren.
    listen = _paint(HESSA_BASE, [
        (15, 14, "."), (15, 13, "E"),
        (5, 14, "QQ"), (6, 13, "QQQ"), (7, 13, "QQQ"), (8, 13, "QQ"), (9, 13, "Qw"), (10, 13, "ww"),
    ])
    return [idle, breathe, listen]


# --------------------------------------------------------------------------
# Dungeon objects, 16x16.
# --------------------------------------------------------------------------
CHEST_CLOSED = [
    "................",
    "................",
    "................",
    "..TTTTTTTTTTTT..",
    ".TTTTTTTTTTTTTT.",
    ".SSSSSSSSSSSSSS.",
    ".TTTTTTQQTTTTTT.",
    ".SSSSSSQQSSSSSS.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".STTTTTTTTTTTTS.",
    ".STTTTTTTTTTTTS.",
    ".STTTTTTTTTTTTS.",
    ".SSSSSSSSSSSSSS.",
    "................",
    "................",
]
CHEST_OPEN = [
    "................",
    "..TTTTTTTTTTTT..",
    ".TTTTTTTTTTTTTT.",
    ".SSSSSSSSSSSSSS.",
    ".TTTTTTTTTTTTTT.",
    ".TKKKKKKKKKKKKT.",
    ".SKKKKKKKKKKKKS.",
    ".SSSSSSSSSSSSSS.",
    ".TTTTTTTTTTTTTT.",
    ".TTTTTTTTTTTTTT.",
    ".STTTTTTTTTTTTS.",
    ".STTTTTTTTTTTTS.",
    ".STTTTTTTTTTTTS.",
    ".SSSSSSSSSSSSSS.",
    "................",
    "................",
]
# Planks nailed across a gap, iron bands, a brass padlock.
LOCKED_HATCH = [
    "TTTTTTTTTTTTTTTT",
    "TTTTTTTTTTTTTTTT",
    "SSSSSSSSSSSSSSSS",
    "TTTTTTTTTTTTTTTT",
    "TTTTTTTTTTTTTTTT",
    "TTTTTTQQQQTTTTTT",
    "TTTTTQTTTTQTTTTT",
    "SSSSSQSSSSQSSSSS",
    "TTTTQQQQQQQQTTTT",
    "TTTTQQQKKQQQTTTT",
    "TTTTQQQKKQQQTTTT",
    "TTTTQQQQQQQQTTTT",
    "SSSSSSSSSSSSSSSS",
    "TTTTTTTTTTTTTTTT",
    "TTTTTTTTTTTTTTTT",
    "TTTTTTTTTTTTTTTT",
]
SMALL_KEY = [
    "................",
    "................",
    "......QQQ.......",
    ".....QQQQQ......",
    ".....QQ.QQ......",
    ".....QQQQQ......",
    "......QQQ.......",
    ".......Q........",
    ".......Q........",
    ".......QQQ......",
    ".......Q........",
    ".......QQ.......",
    ".......Q........",
    "................",
    "................",
    "................",
]


def canvas(w, h):
    return [["."] * w for _ in range(h)]


def beached_hull():
    """The Rotting Hull from outside: a ship run aground and half sunk in the
    mud, seen side on. Stern on the left with its windows, the bow rising on
    the right with a bowsprit, masts snapped off, and a hole stove in low in
    the side that Wren can walk into. 96x72, base on row 70."""
    W, H = 96, 72
    c = canvas(W, H)

    def deck(x):
        # The sheer line: low amidships, rising to the bow.
        t = (x - 6) / 82.0
        return round(30 - 7 * max(0.0, (0.18 - t) / 0.18) - 16 * max(0.0, (t - 0.6) / 0.4) ** 1.5)

    def stem(y):
        # The bow's leading edge curves back from the deck to the mud.
        u = max(0.0, (y - 14) / 56.0)
        return round(89 - 18 * u ** 1.4)

    for x in range(6, 92):
        top = deck(x)
        for y in range(top, 70):
            if x <= stem(y):
                c[y][x] = "T"
    # Rail along the top edge, and two wales following the sheer.
    for x in range(6, 92):
        col = [y for y in range(H) if c[y][x] == "T"]
        if not col:
            continue
        top = col[0]
        c[top][x] = "d"
        if top + 1 < H and c[top + 1][x] == "T":
            c[top + 1][x] = "d"
        for off in (9, 10, 21, 22):
            if top + off < 69 and c[top + off][x] == "T":
                c[top + off][x] = "h"
        for off in (5, 15, 27, 33):
            if top + off < 69 and c[top + off][x] == "T" and (x * 3 + off) % 13:
                c[top + off][x] = "-"
    # Stern windows.
    for wx in (9, 15):
        for y in range(28, 32):
            for x in range(wx, wx + 3):
                c[y][x] = "K"
        c[28][wx + 1] = "J"
    # Bowsprit and the snapped masts.
    for i in range(12):
        x, y = 86 + i * 3 // 4, 15 - i
        if 0 <= x < W and 0 <= y < H:
            c[y][x] = "B"
            c[y + 1][x] = "B"
    for (mx, top, h) in ((36, 4, 26), (62, 10, 18)):
        lean = 0
        for i in range(h):
            y = top + i
            lean = (h - i) // 8
            for dx in range(3):
                if c[y][mx + dx - lean] == ".":
                    c[y][mx + dx - lean] = "B"
        # Splintered tip.
        c[top - 1][mx - lean - 1] = "B"
        c[top - 2][mx - lean] = "B"
    # A spar fallen across the deck.
    for i in range(18):
        x, y = 42 + i, 22 + i // 6
        if c[y][x] == ".":
            c[y][x] = "B"
    # Ribs showing where planks have rotted away.
    for (rx, y0, y1) in ((24, 36, 52), (72, 32, 48)):
        for y in range(y0, y1):
            c[y][rx] = "v"
            c[y][rx + 1] = "T"
            c[y][rx + 2] = "v"
            c[y][rx + 3] = "v"
            c[y][rx + 4] = "T"
            c[y][rx + 5] = "v"
    # The way in: a ragged hole low on the near side, centred on x 48.
    cx = 48
    for dy in range(17):
        y = 52 + dy
        half = min(11, 6 + dy)
        jag = 1 if dy % 3 == 0 else 0
        for x in range(cx - half + jag, cx + half - jag):
            c[y][x] = "K"
    for (x, y) in ((37, 56), (36, 60), (59, 57), (60, 61), (43, 52), (53, 52), (47, 51)):
        c[y][x] = "d"
    # Weed and barnacles where the hull sits in the mud.
    for x in range(W):
        col = [y for y in range(H) if c[y][x] not in (".", "K")]
        if col and col[-1] >= 66:
            for y in col[-3:]:
                c[y][x] = "z"
    for (x, y) in ((12, 60), (20, 63), (28, 58), (66, 61), (74, 59), (80, 63), (70, 55)):
        if c[y][x] == "T":
            c[y][x] = "k"
            c[y][x + 1] = "k"
    return ["".join(r) for r in c]
