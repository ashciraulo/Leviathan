"""The Kiln (Cinderreach's dungeon): a ruined bell foundry. Floor and wall
tiles, lava, cooling pools, and its pieces: cracked boulders, pegs, drop
hammers, the Clinker, the Stonebreaker Mallet, the Slagwyrm and the Ember
Bell.

Tiles are RGBA 16x16 grids added to the world tile sheet. Sprites are
material silhouettes that build_art.lit() shades. Imported by build_art.py,
which writes the sprites to assets/kiln/.

Palette anchors from the plan (Cinderreach): red rock #B5452F, char
#3A1F2B, ember #FFB347, molten yellow #FFE36E.
"""

import math
import random


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = 16
CLEAR = (0, 0, 0, 0)

# --------------------------------------------------------------------------
# Materials (ramps run highlight, light, base, shadow, outline). Letters are
# punctuation so they never clash with the other art files.
# --------------------------------------------------------------------------
RAMPS = {
    "(": ["#E08A66", "#B5452F", "#8A3430", "#5A2230", "#2A1220"],   # kiln brick, red rock
    ")": ["#9AA0B8", "#6A6E88", "#484A62", "#2E2E44", "#16141F"],   # cast iron
    "[": ["#9A8C96", "#74666E", "#56484E", "#3A2E36", "#1C1418"],   # basalt
    "]": ["#FFF6C0", "#FFE36E", "#FFB347", "#E2653A", "#7A2626"],   # molten slag
    "{": ["#FFE6A8", "#E8B460", "#B87A3A", "#7E4A2E", "#3A1E1E"],   # bell bronze
    "}": ["#8C7A78", "#6A5858", "#4C3C40", "#33262C", "#180F14"],   # cooled slag crust
    "+": ["#E2B884", "#B88A5A", "#8A6040", "#5A3C30", "#2A1A1A"],   # ash-wood handle
}
FLAT = {
    "?": "#FFF6C0",   # white-hot glow
    "/": "#140A10",   # deep crack
    "<": "#FFB347",   # ember orange
    ">": "#FFE36E",   # molten yellow
}

# --------------------------------------------------------------------------
# Tiles.
# --------------------------------------------------------------------------
STONE = [hex_color(c) for c in ("#7A6264", "#64504F", "#54423F", "#463634", "#382A2A", "#241A1C")]
BRICK = [hex_color(c) for c in ("#C2603E", "#9C4634", "#7E382E", "#622A2A", "#461E24", "#2A1218")]
MORTAR = hex_color("#2E2024")
SOOT = hex_color("#241820")
EMBER = hex_color("#FFB347")
EMBER_DIM = hex_color("#C8643A")
MOLTEN = [hex_color(c) for c in ("#FFF6C0", "#FFE36E", "#FFB347", "#F2803A", "#D2522E", "#8A2A26", "#4A1A1E")]
POOL = [hex_color(c) for c in ("#8EB4BE", "#5A8494", "#3E6476", "#2C4A5E", "#20364A", "#16263A")]
KERB = [hex_color(c) for c in ("#8E7A7C", "#6E5C5E", "#4E3E42", "#2E2228")]


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def floor_tile(seed):
    """Foundry flagstones: big square slabs worn smooth, a soft dark join
    along the bottom and right, scuffs and soot, and now and then a slab
    split in two or a fleck of slag still glowing."""
    rnd = random.Random(1200 + seed)
    base = (STONE[2], STONE[2], hex_color("#4C3B39"), STONE[2])[seed % 4]
    px = blank(base)
    for i in range(T):
        px[0][i] = STONE[1]
        px[i][0] = STONE[1]
        px[T - 1][i] = STONE[4]
        px[i][T - 1] = STONE[4]
    px[T - 1][0] = STONE[3]
    px[0][T - 1] = STONE[3]
    if seed % 2 == 1:
        # A slab split across the middle.
        for x in range(1, T - 1):
            px[7][x] = STONE[4]
            px[8][x] = STONE[1]
    # Scuffs and soot.
    for _ in range(7):
        x, y = rnd.randrange(2, T - 2), rnd.randrange(2, T - 2)
        px[y][x] = rnd.choice((STONE[1], STONE[3], STONE[3], STONE[4]))
    if seed == 2:
        x, y = rnd.randrange(3, T - 3), rnd.randrange(3, T - 3)
        px[y][x] = EMBER_DIM
    return px


def wall_top(seed):
    """Kiln brick seen from above: courses of dark bricks, sooted."""
    rnd = random.Random(1300 + seed)
    px = blank(MORTAR)
    for course in range(4):
        y0 = course * 4
        shift = 4 if course % 2 else 0
        for y in range(y0, y0 + 3):
            for x in range(T):
                if (x + shift) % 8 == 7:
                    continue
                px[y][x] = BRICK[4] if y == y0 + 2 else BRICK[3]
        for x in range(T):
            if (x + shift) % 8 != 7:
                px[y0][x] = BRICK[2]
    for _ in range(6):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = SOOT
    return px


def wall_face(seed):
    """The kiln wall's face: red rock bricks, black with soot at the top
    where the heat rolled along the ceiling."""
    rnd = random.Random(1400 + seed)
    px = blank(MORTAR)
    for course in range(4):
        y0 = course * 4
        shift = 4 if course % 2 else 0
        for y in range(y0, y0 + 3):
            for x in range(T):
                if (x + shift) % 8 == 7:
                    continue
                tone = 1 if y == y0 else (2 if y == y0 + 1 else 3)
                px[y][x] = BRICK[tone]
        # A few bricks scorched darker.
        for b in range(2):
            if rnd.random() < 0.4:
                bx = (b * 8 + 8 - shift) % T
                for y in range(y0, y0 + 3):
                    for x in range(bx, min(bx + 7, T)):
                        if px[y][x] != MORTAR:
                            px[y][x] = BRICK[min(4, 2 + (y - y0))]
    # Soot bleeding down from the top.
    for x in range(T):
        depth = 2 + rnd.randrange(3)
        for y in range(depth):
            if px[y][x] != MORTAR or y == 0:
                px[y][x] = SOOT if y < depth - 1 else BRICK[4]
    # The foot of the wall: a dark course.
    for x in range(T):
        px[15][x] = BRICK[5]
    return px


def pool_tile(frame):
    """A quench pool: dark water, slow ripples, a wisp of steam."""
    rnd = random.Random(1500)
    px = blank(POOL[3])
    for y in range(T):
        for x in range(T):
            if (x + y * 2 + frame * 3) % 9 == 0:
                px[y][x] = POOL[4]
    for i in range(3):
        y = (i * 5 + 2 + frame * 2) % T
        x0 = (i * 6 + frame * 3) % 10
        for x in range(x0, x0 + 4):
            px[y][x] = POOL[2]
        px[y][x0 + 1] = POOL[1]
    # Steam glints.
    for _ in range(2):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[(y + frame * 4) % T][x] = POOL[0]
    return px


def pool_edge(side, frame):
    """The stone kerb round a pool, on the water tile's open side."""
    px = blank()
    for i in range(T):
        for d in range(3):
            col = KERB[d] if d < 2 else POOL[5]
            if side == "top":
                px[d][i] = KERB[3 - d] if d < 2 else POOL[5]
            elif side == "bottom":
                px[T - 1 - d][i] = col if d < 2 else POOL[4]
            elif side == "left":
                px[i][d] = col
            else:
                px[i][T - 1 - d] = col
    if side == "top":
        for x in range(T):
            px[0][x] = KERB[1]
            px[1][x] = KERB[2]
            if (x + frame) % 6 == 0:
                px[3][x] = POOL[0]
    return px


def scorch_edge(side, seed):
    """Wet, dark stone beside a pool."""
    rnd = random.Random(1600 + seed)
    px = blank()
    wet = hex_color("#2A1E24", 90)
    for i in range(T):
        reach = 2 + rnd.randrange(3)
        for d in range(reach):
            if side == "top":
                px[d][i] = wet
            elif side == "bottom":
                px[T - 1 - d][i] = wet
            elif side == "left":
                px[i][d] = wet
            else:
                px[i][T - 1 - d] = wet
    return px


def cinders(seed):
    """A little drift of black cinders."""
    rnd = random.Random(1700 + seed)
    px = blank()
    for _ in range(7):
        x, y = rnd.randrange(3, 13), rnd.randrange(5, 13)
        px[y][x] = SOOT
        if rnd.random() < 0.5:
            px[y][x + 1] = STONE[4]
    return px


def slag_bits(seed):
    """Spilt slag: a dark crust with an orange heart."""
    rnd = random.Random(1800 + seed)
    px = blank()
    cx, cy = rnd.randrange(5, 11), rnd.randrange(6, 11)
    for dy in range(-2, 2):
        for dx in range(-3, 3):
            if abs(dx) + abs(dy) <= 3:
                px[cy + dy][cx + dx] = STONE[4]
    px[cy - 1][cx - 1] = EMBER_DIM
    px[cy - 1][cx] = EMBER
    px[cy][cx - 1] = STONE[5]
    return px


def glow_crack(seed):
    """A hairline crack in a flagstone with heat showing through."""
    rnd = random.Random(1900 + seed)
    px = blank()
    x, y = rnd.randrange(3, 8), rnd.randrange(2, 5)
    for _ in range(9):
        px[y][x] = EMBER_DIM
        if rnd.random() < 0.4:
            px[y][x] = EMBER
        x = min(max(x + rnd.choice((0, 1, 1)), 0), T - 1)
        y = min(y + 1, T - 1)
    return px


def lava_tile(frame):
    """Molten slag: churning yellow and orange with drifting dark crust."""
    rnd = random.Random(2000)
    px = blank(MOLTEN[3])
    for y in range(T):
        for x in range(T):
            v = math.sin((x + frame * 3) * 0.7) + math.cos((y - frame * 2) * 0.6) + math.sin((x + y) * 0.4)
            if v > 1.4:
                px[y][x] = MOLTEN[1]
            elif v > 0.6:
                px[y][x] = MOLTEN[2]
            elif v < -1.6:
                px[y][x] = MOLTEN[4]
    # Crust islands.
    for i in range(2):
        cx = (rnd.randrange(T) + frame * 2 * (1 if i else -1)) % T
        cy = rnd.randrange(3, 13)
        for dx in range(-2, 2):
            px[cy][(cx + dx) % T] = MOLTEN[5]
        px[cy - 1][cx % T] = MOLTEN[6]
        px[cy - 1][(cx - 1) % T] = MOLTEN[5]
    # Bubbles.
    bx, by = (5 + frame * 6) % T, (9 + frame * 3) % T
    px[by][bx] = MOLTEN[0]
    return px


def lava_lip():
    """The far edge of a lava channel: the floor's broken lip, seen face on,
    lit orange from below."""
    px = blank()
    rnd = random.Random(2100)
    for x in range(T):
        depth = 4 + (1 if x % 6 in (2, 3) else 0) + rnd.choice((0, 0, 1))
        for y in range(depth):
            px[y][x] = STONE[1] if y == 0 else (STONE[3] if y < depth - 2 else MOLTEN[4])
        px[depth][x] = MOLTEN[5]
    return px


def lava_side(side):
    """A dark crust rim along the left, right or near (bottom) edge."""
    px = blank()
    rnd = random.Random({"left": 2110, "right": 2111, "bottom": 2112}[side])
    for i in range(T):
        reach = rnd.choice((1, 2, 2, 3))
        for d in range(reach):
            col = MOLTEN[6] if d == 0 else MOLTEN[5]
            if side == "left":
                px[i][d] = col
            elif side == "right":
                px[i][T - 1 - d] = col
            else:
                px[T - 1 - d][i] = col
    return px


def warn_tile(frame):
    """The floor under a drop hammer: a scorched square with a hazard rim."""
    px = blank()
    rim = hex_color("#2A1820", 160)
    for i in range(T):
        for d in (0, 15):
            px[d][i] = rim
            px[i][d] = rim
    for i in range(1, T - 1, 3):
        px[1][i] = EMBER_DIM
        px[14][i] = EMBER_DIM
    return px


TILES = [
    ("kiln_floor_0", lambda: floor_tile(0)), ("kiln_floor_1", lambda: floor_tile(1)),
    ("kiln_floor_2", lambda: floor_tile(2)), ("kiln_floor_3", lambda: floor_tile(3)),
    ("kiln_top_0", lambda: wall_top(0)), ("kiln_top_1", lambda: wall_top(1)),
    ("kiln_face_0", lambda: wall_face(0)), ("kiln_face_1", lambda: wall_face(1)),
    ("quench_0", lambda: pool_tile(0)), ("quench_1", lambda: pool_tile(1)),
    ("kerb_top_0", lambda: pool_edge("top", 0)), ("kerb_bottom_0", lambda: pool_edge("bottom", 0)),
    ("kerb_left_0", lambda: pool_edge("left", 0)), ("kerb_right_0", lambda: pool_edge("right", 0)),
    ("kerb_top_1", lambda: pool_edge("top", 1)), ("kerb_bottom_1", lambda: pool_edge("bottom", 1)),
    ("kerb_left_1", lambda: pool_edge("left", 1)), ("kerb_right_1", lambda: pool_edge("right", 1)),
    ("kiln_scorch_top", lambda: scorch_edge("top", 1)), ("kiln_scorch_bottom", lambda: scorch_edge("bottom", 2)),
    ("kiln_scorch_left", lambda: scorch_edge("left", 3)), ("kiln_scorch_right", lambda: scorch_edge("right", 4)),
    ("cinder_0", lambda: cinders(0)), ("cinder_1", lambda: cinders(1)),
    ("slagbit_0", lambda: slag_bits(0)), ("slagbit_1", lambda: slag_bits(1)),
    ("glowcrack_0", lambda: glow_crack(0)), ("glowcrack_1", lambda: glow_crack(1)),
    ("kiln_lava_0", lambda: lava_tile(0)), ("kiln_lava_1", lambda: lava_tile(1)),
    ("lava_lip", lava_lip), ("lava_left", lambda: lava_side("left")),
    ("lava_right", lambda: lava_side("right")), ("lava_bottom", lambda: lava_side("bottom")),
    ("hammer_mark", lambda: warn_tile(0)),
]


# --------------------------------------------------------------------------
# Sprite helpers.
# --------------------------------------------------------------------------
def canvas(w, h):
    return [["."] * w for _ in range(h)]


def rows_of(c):
    return ["".join(r) for r in c]


def put(c, x, y, m):
    if 0 <= y < len(c) and 0 <= x < len(c[0]):
        c[y][x] = m


def fill_ellipse(c, cx, cy, rx, ry, m, only=None):
    for y in range(len(c)):
        for x in range(len(c[0])):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                if only is None or c[y][x] in only:
                    c[y][x] = m


def fill_rect(c, x, y, w, h, m):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            put(c, xx, yy, m)


def line(c, x0, y0, x1, y1, m, width=1):
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        x = round(x0 + (x1 - x0) * i / steps)
        y = round(y0 + (y1 - y0) * i / steps)
        for d in range(width):
            put(c, x + d, y, m)


# --------------------------------------------------------------------------
# Dungeon pieces.
# --------------------------------------------------------------------------
def boulder():
    """A cracked basalt boulder, heat glowing in its cracks. 16x18, foot 16."""
    c = canvas(16, 18)
    fill_ellipse(c, 7.5, 9.5, 7.0, 6.5, "[")
    fill_rect(c, 2, 13, 12, 3, "[")
    # Flat facets on top.
    line(c, 4, 6, 9, 4, "}")
    # The crack the mallet will find.
    for (x, y) in ((7, 4), (7, 5), (8, 6), (8, 7), (7, 8), (6, 9), (6, 10), (7, 11), (9, 8), (10, 9), (11, 9)):
        put(c, x, y, "/")
    for (x, y) in ((8, 7), (6, 10), (10, 9)):
        put(c, x, y, "<")
    return rows_of(c)


def peg(down):
    """An iron-capped timber peg standing out of the floor, or hammered flush.
    16x16, foot 13."""
    c = canvas(16, 16)
    if down:
        fill_ellipse(c, 7.5, 11.5, 5.0, 2.5, ")")
        fill_ellipse(c, 7.5, 11.0, 3.0, 1.4, "}")
        return rows_of(c)
    fill_ellipse(c, 7.5, 12.0, 5.5, 2.0, "}")
    fill_rect(c, 4, 4, 8, 9, "+")
    fill_ellipse(c, 7.5, 3.5, 4.0, 2.0, ")")
    fill_rect(c, 4, 4, 8, 2, ")")
    line(c, 6, 6, 6, 11, "/")
    return rows_of(c)


def hammer_head():
    """A drop hammer's iron head on its guide rods. 20x16, foot 15."""
    c = canvas(20, 16)
    fill_rect(c, 1, 5, 18, 10, ")")
    fill_rect(c, 3, 2, 14, 3, ")")
    fill_rect(c, 8, 0, 4, 2, ")")
    # A face plate and rivets.
    fill_rect(c, 3, 7, 14, 1, "}")
    for x in (3, 8, 11, 16):
        put(c, x, 11, "?")
    fill_rect(c, 1, 14, 18, 1, "}")
    return rows_of(c)


def clinker(frame, flipped):
    """A Clinker: a squat beetle that wears a shell of cooled slag, its
    seams still glowing orange. Flipped, it lies on its back showing a soft,
    molten belly, legs going. 16x16, foot 14."""
    c = canvas(16, 16)
    step = frame % 2
    if not flipped:
        for i, x in enumerate((2, 5, 10, 13)):
            dy = step if i % 2 == 0 else 1 - step
            put(c, x, 13 + dy, ")")
            put(c, x, 12, ")")
        fill_ellipse(c, 7.5, 8.5, 7.0, 5.0, "[")
        fill_ellipse(c, 7.5, 7.0, 5.0, 3.0, "}", only={"["})
        # Glowing seams between the shell's plates.
        for (x, y) in ((7, 4), (7, 5), (8, 6), (7, 7), (8, 8), (4, 8), (5, 9), (11, 8), (10, 9)):
            put(c, x, y, "<")
        put(c, 8, 7, ">")
        # Head and eyes.
        fill_rect(c, 5, 11, 6, 2, ")")
        put(c, 6, 12, "?")
        put(c, 9, 12, "?")
    else:
        fill_ellipse(c, 7.5, 10.0, 7.0, 3.5, "[")
        fill_ellipse(c, 7.5, 8.5, 5.5, 3.5, "]")
        for i, x in enumerate((3, 6, 9, 12)):
            up = 1 if (i + step) % 2 else 0
            put(c, x, 4 - up, ")")
            put(c, x, 5 - up, ")")
    return rows_of(c)


def mallet_item():
    """The Stonebreaker Mallet, as Wren lifts it: an iron-bound head with a
    bronze face, on an ash handle. 16x16."""
    c = canvas(16, 16)
    line(c, 3, 13, 9, 7, "+", 2)
    fill_rect(c, 7, 2, 7, 7, ")")
    fill_rect(c, 6, 3, 1, 5, "{")
    fill_rect(c, 14, 3, 1, 5, "{")
    fill_rect(c, 9, 2, 3, 7, "}")
    put(c, 10, 4, "?")
    return rows_of(c)


def mallet_head():
    """The mallet's head as Wren swings it. 10x8."""
    c = canvas(10, 8)
    fill_rect(c, 1, 1, 8, 6, ")")
    fill_rect(c, 0, 2, 1, 4, "{")
    fill_rect(c, 9, 2, 1, 4, "{")
    fill_rect(c, 4, 1, 2, 6, "}")
    return rows_of(c)


# --------------------------------------------------------------------------
# The Slagwyrm: a serpent of molten slag that swims through the floor. Its
# head is a blunt, plated skull with a jaw of glowing teeth; its body is a
# chain of round plates. Molten plates glow; dunked in a pool they set into
# dark crust that the mallet can crack.
# --------------------------------------------------------------------------
def wyrm_head(mouth, cooled=False):
    """32x28, foot 25. Facing down (towards the viewer)."""
    c = canvas(32, 28)
    skin = "}" if cooled else "]"
    plate = "[" if cooled else "}"
    fill_ellipse(c, 15.5, 13.0, 12.0, 10.0, skin)
    # Brow plates.
    fill_ellipse(c, 15.5, 8.0, 10.0, 5.0, plate)
    fill_ellipse(c, 8.0, 11.0, 4.0, 3.0, plate)
    fill_ellipse(c, 23.0, 11.0, 4.0, 3.0, plate)
    # Horns of slag.
    line(c, 6, 6, 3, 1, plate, 2)
    line(c, 24, 6, 27, 1, plate, 2)
    # Eyes.
    eye = "/" if cooled else "?"
    fill_rect(c, 9, 12, 3, 2, eye)
    fill_rect(c, 20, 12, 3, 2, eye)
    # Jaw.
    if mouth:
        fill_ellipse(c, 15.5, 20.0, 7.0, 5.0, "/")
        fill_ellipse(c, 15.5, 21.0, 5.0, 3.0, "<" if not cooled else "/")
        for x in (10, 13, 18, 21):
            put(c, x, 16, ">" if not cooled else "[")
            put(c, x, 24, ">" if not cooled else "[")
    else:
        line(c, 9, 19, 22, 19, "/")
        for x in (11, 14, 17, 20):
            put(c, x, 20, ">" if not cooled else "[")
    fill_ellipse(c, 15.5, 24.0, 6.0, 2.0, plate, only={"."})
    return rows_of(c)


def wyrm_segment(state):
    """One body plate, seen from above and in front: a thick ring of the
    serpent's body. 0 molten (glowing, with dark scabs of crust), 1 set hard
    in grey crust, 2 cracking (glowing through as it melts back). 20x18,
    foot 16."""
    c = canvas(20, 18)
    if state == 0:
        # Molten body under a loose cap of dark crust, glowing at the seam.
        fill_ellipse(c, 9.5, 9.0, 9.0, 7.5, "]")
        fill_ellipse(c, 9.5, 6.0, 7.5, 3.6, "}", only={"]"})
        for x in range(3, 17):
            if c[9][x] == "]" and c[8][x] == "}":
                c[9][x] = ">"
        put(c, 6, 5, "<")
        put(c, 12, 6, "<")
    else:
        fill_ellipse(c, 9.5, 9.0, 9.0, 7.5, "[")
        fill_ellipse(c, 9.5, 7.5, 6.5, 4.0, "}", only={"["})
        cracks = ((9, 2), (9, 3), (10, 4), (9, 5), (8, 6), (8, 7), (11, 8), (12, 9), (7, 9), (6, 10), (13, 11))
        for (x, y) in cracks:
            put(c, x, y, "/")
        if state == 2:
            for (x, y) in ((10, 4), (8, 7), (12, 9), (6, 10)):
                put(c, x, y, ">")
    return rows_of(c)


def wyrm_shard():
    """A chip of crust knocked off by the mallet. 8x8."""
    c = canvas(8, 8)
    fill_ellipse(c, 3.5, 3.5, 3.0, 2.5, "}")
    put(c, 3, 2, "[")
    return rows_of(c)


def slag_glob(frame):
    """A spat glob of slag. 8x8."""
    c = canvas(8, 8)
    fill_ellipse(c, 3.5, 3.5, 3.0, 3.0, "]")
    put(c, 2 + frame, 2, "?")
    return rows_of(c)


# --------------------------------------------------------------------------
# The Ember Bell: the second Tidebell, warm bronze, hung in an iron frame
# from the foundry. Two frames: dark, and rung. 32x40, foot 37.
# --------------------------------------------------------------------------
def ember_bell(rung):
    c = canvas(32, 40)
    fill_rect(c, 3, 4, 26, 3, ")")
    fill_rect(c, 4, 7, 3, 31, ")")
    fill_rect(c, 25, 7, 3, 31, ")")
    fill_rect(c, 2, 36, 7, 2, ")")
    fill_rect(c, 23, 36, 7, 2, ")")
    fill_rect(c, 14, 7, 4, 3, "}")
    for y in range(10, 33):
        t = (y - 10) / 22.0
        half = 4 + 6 * t + (5 * (t - 0.75) / 0.25 if t > 0.75 else 0)
        for x in range(int(16 - half), int(16 + half)):
            put(c, x, y, "{")
    for x in range(5, 27):
        if c[32][x] == "{":
            c[33][x] = "{"
    # Raised bands and a flame motif.
    for y in (14, 27):
        for x in range(32):
            if c[y][x] == "{":
                c[y][x] = "]" if rung else "}"
    for i, x in enumerate(range(11, 21)):
        h = 3 if i % 3 == 1 else 1
        for d in range(h):
            if c[22 - d][x] == "{":
                c[22 - d][x] = "<" if rung else "}"
    fill_rect(c, 15, 33, 2, 3, "}")
    # Scorch along the frame.
    for (x, y, n) in ((5, 8, 3), (26, 10, 4)):
        for i in range(n):
            put(c, x, y + i, "[")
    if rung:
        for x in range(32):
            if c[33][x] == "{":
                c[33][x] = ">"
    return rows_of(c)


def build(lit, sheet):
    """Everything in assets/kiln/, as {file name: pixels}."""
    return {
        "boulder": sheet([[lit(boulder(), 60)]], 16, 18),
        "peg": sheet([[lit(peg(False), 61), lit(peg(True), 61)]], 16, 16),
        "hammer_head": sheet([[lit(hammer_head(), 62)]], 20, 16),
        "clinker": sheet([[lit(clinker(0, False), 63), lit(clinker(1, False), 63),
                           lit(clinker(0, True), 63), lit(clinker(1, True), 63)]], 16, 16),
        "item_stonebreaker": sheet([[lit(mallet_item(), 64)]], 16, 16),
        "mallet_head": sheet([[lit(mallet_head(), 65)]], 10, 8),
        "wyrm_head": sheet([[lit(wyrm_head(False), 66), lit(wyrm_head(True), 66),
                             lit(wyrm_head(False, True), 66)]], 32, 28),
        "wyrm_segment": sheet([[lit(wyrm_segment(0), 67), lit(wyrm_segment(1), 67),
                                lit(wyrm_segment(2), 67)]], 20, 18),
        "wyrm_shard": sheet([[lit(wyrm_shard(), 68)]], 8, 8),
        "slag_glob": sheet([[lit(slag_glob(0), 69), lit(slag_glob(1), 69)]], 8, 8),
        "ember_bell": sheet([[lit(ember_bell(False), 70), lit(ember_bell(True), 70)]], 32, 40),
    }
