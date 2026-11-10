"""Menu art: item icons, the menu frame, slots, the cursor and map markers.

Icons are material silhouettes that build_art.lit() shades, like sprites,
so they share the game's lighting and outline rules. Frames and slots are
drawn directly. Imported by build_art.py, which calls build(build_art).

Menu look: deep sea-blue panels (#18324A drowned blue from the plan) with a
rope border, brass corner rivets, and bleached-white text in Tide.
"""

import hull_art


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


CLEAR = (0, 0, 0, 0)

# Extra materials for icons. Ramps run highlight, light, base, shadow, outline.
RAMPS = {
    "A": ["#FFFFFF", "#CFE8F2", "#7FB7D9", "#5A6D9C", "#2A3458"],  # frost
    "P": ["#FFFFFF", "#F7E6F0", "#D8C0DC", "#9E86A8", "#4A3A58"],  # nacre, pearl
    "R": ["#FFD0C0", "#F5A08A", "#E98A6B", "#B85A52", "#5C2638"],  # coral
    "O": ["#FFF6B0", "#FFD86E", "#E8A040", "#A86030", "#4A2A20"],  # puffer
    "Z": ["#6E9AC8", "#3A6A8A", "#24405E", "#18324A", "#0C1626"],  # abyssal
    "X": ["#F2FFFF", "#C8EEF0", "#8CC8D2", "#5A92A8", "#2A4A62"],  # glass
    "U": ["#F7F1E3", "#B8DCEE", "#7FB7D9", "#41577A", "#1E2A44"],  # kite cloth
    "F": ["#FFF4D6", "#F2DCA6", "#E8C88A", "#B38A5A", "#5A3E36"],  # parchment
}
FLAT = {
    "$": "#8FE3C8",  # glow mint (lantern, sea sprite)
    "&": "#E2574C",  # potion red, compass needle
    "^": "#FFF4D6",  # glint, string
    "=": "#2A1E36",  # dark detail
}


def icon(rows):
    """Centre a silhouette in a 16x16 frame (rows may be shorter)."""
    w = max(len(r) for r in rows)
    rows = [r.ljust(w, ".") for r in rows]
    top = (16 - len(rows)) // 2
    left = (16 - w) // 2
    out = ["." * 16] * top
    out += ["." * left + r + "." * (16 - w - left) for r in rows]
    out += ["." * 16] * (16 - len(out))
    assert len(out) == 16 and all(len(r) == 16 for r in out), rows
    return out


def round_icon(radius, mat, rim=None, rim_width=1.0, cx=7.5, cy=7.5):
    """A filled circle silhouette, with an optional rim material."""
    rows = []
    for y in range(16):
        row = ""
        for x in range(16):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d <= radius - rim_width and rim:
                row += mat
            elif d <= radius:
                row += rim or mat
            else:
                row += "."
        rows.append(row)
    return rows


def stamp(rows, x, y, art):
    """Overwrite part of a silhouette (art rows, '.' is transparent)."""
    rows = [list(r) for r in rows]
    for dy, line in enumerate(art):
        for dx, ch in enumerate(line):
            if ch != "." and 0 <= y + dy < 16 and 0 <= x + dx < 16:
                rows[y + dy][x + dx] = ch
    return ["".join(r) for r in rows]


TIDE_HOOK = icon([
    "......QQQ",
    ".....Q...Q",
    "....QQ....Q",
    "....Q....QQ",
    "....Q...QQ.",
    "....QQ.....",
    "jj...QQ....",
    "jjj...QQ...",
    ".jjj...Q...",
    "..jjj.QQQ..",
    "...jjQQQQQ.",
    "....jjQQQ..",
])

STONEBREAKER = icon([
    "..oooooo...",
    ".oooooooo..",
    ".oooooooo..",
    ".oooooooo..",
    "..ooobooo..",
    ".....dd....",
    ".....dd....",
    ".....dd....",
    ".....dd....",
    ".....bb....",
    ".....dd....",
    ".....bb....",
])

LANTERN = icon([
    "....QQQ...",
    "...Q...Q..",
    "...QQQQQ..",
    "..QQQQQQQ.",
    "..Q$$$$$Q.",
    "..Q$$^$$Q.",
    "..Q$^^^$Q.",
    "..Q$$^$$Q.",
    "..Q$$$$$Q.",
    "..QQQQQQQ.",
    "...QQQQQ..",
])

KITE_CLOAK = icon([
    "......Q......",
    ".....UUU.....",
    "....UUUUU....",
    "...UUUUUUU...",
    "..UUUUQUUUU..",
    ".UUUUUQUUUUU.",
    "QQQQQQQQQQQQQ",
    ".UUUUUQUUUUU.",
    "...UUUQUUU...",
    ".....UQU.....",
    "......Q......",
    ".....r.r.....",
])

FROSTFANG_BOW = icon([
    "..AA.......",
    "..^AA......",
    "..^.AA.....",
    "..^..AA....",
    "..^...AA...",
    "..^....bb..",
    "..^....bb..",
    "..^...AA...",
    "..^..AA....",
    "..^.AA.....",
    "..^AA......",
    "..AA.......",
])

DIVERS_HELM = icon([
    ".....QQQQ.....",
    "...QQQQQQQQ...",
    "..QQQQQQQQQQ..",
    ".QQQ=XXXX=QQQ.",
    ".QQ=XXXXXX=QQ.",
    "QQQ=XXXXXX=QQQ",
    "QQQ=XXXXXX=QQQ",
    ".QQ=XXXXXX=QQ.",
    ".QQQ=XXXX=QQQ.",
    "..QQQQQQQQQQ..",
    ".bbbbbbbbbbbb.",
    ".bQbbQbbQbbQb.",
])

ECHO_HORN = icon([
    "......hhhh...",
    "....hhhhhhh..",
    "...hhh...hhh.",
    "..hh......hh.",
    "..hh.....hhh.",
    "..hhh...hhh..",
    "...hhhhhhh...",
    "....hhhhh....",
    "...hhhh......",
    "..hhhh.......",
    ".hhhh........",
    "QQhh.........",
    "QQ...........",
])

WAYSHELL = icon([
    "........RR...",
    "......RRRRR..",
    "....RRRRsRR..",
    "...RRRssRRR..",
    "..RRRssRRRR..",
    ".RRsssRRRRR..",
    ".RRssRRRRRR..",
    "RRssssRRRRR..",
    "RRRsssssRRRR.",
    ".RRRRRssssRRR",
    "..RRRRRRRRRR.",
    "....RRRRRR...",
])

PUFFER = stamp(round_icon(5.0, "O", cx=7.5, cy=8.5), 0, 0, [
    "..........^.",
    "...........^",
    ".......O..b.",
    "...O.....b..",
    "................",
    "................",
    "..........=.",
])
PUFFER = stamp(PUFFER, 1, 7, ["O"])
PUFFER = stamp(PUFFER, 13, 8, ["O"])
PUFFER = stamp(PUFFER, 7, 14, ["O"])
PUFFER = stamp(PUFFER, 4, 7, ["==", "=."])

ARROWS = icon([
    "..........oo",
    ".........ooo",
    "....oo..ddo.",
    "...ooo.dd...",
    "..ddo.dd....",
    ".dd..dd.....",
    "dd..dd......",
    "d..dd.......",
    "..AA........",
    ".AA.........",
    "AA..........",
])

LAMP_OIL = icon([
    "....bb....",
    "....bb....",
    "...XXXX...",
    "...X..X...",
    "..XXXXXX..",
    ".XXXXXXXX.",
    ".XQQQQQQX.",
    ".XQQQQQQX.",
    ".XQQQQQQX.",
    ".XQQQQQQX.",
    "..XXXXXX..",
])


def sword(blade, guard):
    return icon([
        "..........." + blade,
        ".........." + blade * 2,
        "........." + blade * 3,
        "........" + blade * 3 + ".",
        "......." + blade * 3 + "..",
        "......" + blade * 3 + "...",
        "....." + blade * 3 + "....",
        ".." + guard + ".." + blade * 3 + ".....",
        "..." + guard + blade * 3 + "......",
        "...." + guard * 2 + ".......",
        "...bb" + guard + "........",
        "..bb...." + guard + "....",
        ".bb.........",
        "QQ..........",
    ])


def buckler(mat, boss):
    rows = round_icon(6.0, mat, "b", 1.0)
    rows = stamp(rows, 6, 6, [boss * 3, boss * 3, boss * 3])
    return rows


def tunic(mat, trim):
    return icon([
        "..bbb..bbb..",
        ".bb" + mat + "....." + mat + "bb.",
        "b" + mat * 3 + trim * 3 + mat * 3 + "bb",
        mat * 12,
        mat * 12,
        "..." + mat * 6 + "...",
        "..." + mat * 6 + "...",
        "..." + mat * 2 + trim * 2 + mat * 2 + "...",
        "..." + mat * 6 + "...",
        "..." + trim * 6 + "...",
    ])


TIDEBELL = icon([
    ".....Q.....",
    "....QQQ....",
    "...QQQQQ...",
    "...QQQQQ...",
    "..QQQQQQQ..",
    "..QQQQQQQ..",
    "..QQQQQQQ..",
    ".QQQQQQQQQ.",
    "QQQQQQQQQQQ",
    "....QQQ....",
    ".....Q.....",
])

PEARL = stamp(round_icon(5.0, "P"), 10, 1, ["^."])
PEARL = stamp(PEARL, 11, 2, ["^"])

KEEPER_LAMP = icon([
    "....bbb....",
    "...b...b...",
    "....QQQ....",
    "...QQQQQ...",
    "...XJJJX...",
    "...XJIJX...",
    "...XJJJX...",
    "..QQQQQQQ..",
    "...QQQQQ..Q",
    "....QQQQQQ.",
])

GLINT = icon([
    "....kkk....",
    "..kkkkkkk..",
    ".k^k^k^k^k.",
    "kk^k^k^k^kk",
    "kk^k^k^k^kk",
    ".k^k^k^k^k.",
    "..kkkkkkk..",
    "...kkkkk...",
    "....kkk....",
])


SEA_GLASS = icon([
    "...XXX....",
    ".XXXXXXX..",
    "XXXXXXXXX.",
    "XXXXXXXXXX",
    ".XXXXXXXXX",
    "..XXXXXX..",
    "....XX....",
])


def jar(contents):
    body = "XXXXXXXX"
    fill = contents * 6 if contents else "......"
    return icon([
        "...bbbb...",
        "...bbbb...",
        "..XXXXXX..",
        "...X..X...",
        "..XX..XX..",
        ".X" + fill + "X.",
        ".X" + fill + "X.",
        ".X" + fill + "X.",
        ".X" + fill + "X.",
        ".X" + fill + "X.",
        "..XXXXXX..",
    ]) if not contents else icon([
        "...bbbb...",
        "...bbbb...",
        "..XXXXXX..",
        "...XXXX...",
        "..XXXXXX..",
        "." + body + ".",
        ".X" + fill + "X.",
        ".X" + fill + "X.",
        ".X" + fill + "X.",
        ".X" + fill + "X.",
        "..XXXXXX..",
    ])


SPRITE_JAR = stamp(jar("$"), 6, 8, ["^..^", ".^^."])

MAP = icon([
    "FF.......FF.",
    "FFFFFFFFFFFF",
    "FFF&FFFFFFFF",
    "FF&&&FFF=FFF",
    "FFF&FFF=FFFF",
    "FFFFFF=FFFFF",
    "FFFF=FFFF&FF",
    "FFF=FFFF&&&F",
    "FFFFFFFFF&FF",
    "FFFFFFFFFFFF",
    "FF.......FF.",
])

COMPASS = stamp(round_icon(6.0, "q", "Q", 1.5), 7, 3, [
    "&.",
    "&.",
    "&&",
    "&&",
    "==",
    "==",
    "=.",
    "=.",
])
COMPASS = stamp(COMPASS, 7, 0, ["QQ"])

BIG_KEY = icon([
    "...QQQQ...",
    "..QQQQQQ..",
    ".QQ.QQ.QQ.",
    ".QQQQQQQQ.",
    ".QQ.QQ.QQ.",
    "..QQQQQQ..",
    "...QQQQ...",
    "....QQ....",
    "....QQ....",
    "....QQQQ..",
    "....QQ....",
    "....QQQQQ.",
    "....QQ....",
    "....QQ....",
])

BLANK = ["." * 16] * 16


def icon_frames():
    """In the order of the icon numbers in scripts/items/items.gd."""
    return [
        TIDE_HOOK, STONEBREAKER, LANTERN, KITE_CLOAK,
        FROSTFANG_BOW, DIVERS_HELM, ECHO_HORN, WAYSHELL,
        PUFFER, ARROWS, LAMP_OIL,
        sword("d", "b"), sword("S", "Q"), sword("t", "Q"),
        buckler("T", "Q"), buckler("R", "Q"), buckler("P", "Q"),
        tunic("x", "r"), tunic("L", "Q"), tunic("Z", "$"),
        TIDEBELL, PEARL, KEEPER_LAMP, GLINT,
        jar(""), jar("&"), SPRITE_JAR,
        MAP, COMPASS, BIG_KEY, hull_art.SMALL_KEY, BLANK,
        SEA_GLASS,
    ]


# --------------------------------------------------------------------------
# Frames, slots, cursor, map markers (drawn directly, RGBA).
# --------------------------------------------------------------------------
DEEP = hex_color("#18324A")
DEEP_DARK = hex_color("#10223A")
DEEP_LIGHT = hex_color("#24466A")
INK = hex_color("#0C1626")
ROPE = [hex_color(c) for c in ("#F2E3C6", "#D9C59E", "#B8A07A", "#86705A", "#3E2C2E")]
BRASS = [hex_color(c) for c in ("#FFF0A0", "#F2C85A", "#C8963A", "#8A5E2E", "#3E2622")]
FOAM = hex_color("#A8E6CF")
GLASS = hex_color("#5FBFB7")


def grid(w, h, color=CLEAR):
    return [[color] * w for _ in range(h)]


def rope_border(px, x0, y0, w, h):
    """A twisted rope line along the inside edge of a rectangle."""
    for i in range(w):
        for y, side in ((y0, 0), (y0 + h - 3, 1)):
            px[y][x0 + i] = ROPE[4]
            px[y + 1][x0 + i] = ROPE[(i + side) % 3]
            px[y + 2][x0 + i] = ROPE[4]
    for i in range(h):
        for x, side in ((x0, 0), (x0 + w - 3, 1)):
            px[y0 + i][x] = ROPE[4]
            px[y0 + i][x + 1] = ROPE[(i + side) % 3]
            px[y0 + i][x + 2] = ROPE[4]


def rivet(px, x, y):
    for dy, row in enumerate(["=QQ=", "QqQ3", "QQ33", "=33="]):
        for dx, ch in enumerate(row):
            c = {"=": BRASS[4], "Q": BRASS[1], "q": BRASS[0], "3": BRASS[3]}[ch]
            px[y + dy][x + dx] = c


def panel():
    """A 24x24 nine-slice frame: 8px corners, rope edge, brass rivets."""
    s = 24
    px = grid(s, s, DEEP)
    # Slight vertical sheen in the fill: lighter at the top.
    for y in range(s):
        for x in range(s):
            if y < 9:
                px[y][x] = DEEP_LIGHT if (x + y) % 7 == 0 and y < 5 else DEEP
    for i in range(s):
        px[0][i] = px[s - 1][i] = INK
        px[i][0] = px[i][s - 1] = INK
    rope_border(px, 1, 1, s - 2, s - 2)
    for x, y in ((1, 1), (s - 5, 1), (1, s - 5), (s - 5, s - 5)):
        rivet(px, x, y)
    # Corners rounded off.
    for x, y in ((0, 0), (s - 1, 0), (0, s - 1), (s - 1, s - 1)):
        px[y][x] = CLEAR
    return px


def slot_frames():
    """20x20 item slots: normal, and assigned to a button (brass rim)."""
    frames = []
    for rim in (DEEP_LIGHT, BRASS[2]):
        px = grid(20, 20, DEEP_DARK)
        for i in range(20):
            px[0][i] = px[19][i] = INK
            px[i][0] = px[i][19] = INK
        for i in range(1, 19):
            px[1][i] = rim
            px[i][1] = rim
            px[18][i] = hex_color("#0E1C30") if rim == DEEP_LIGHT else BRASS[3]
            px[i][18] = hex_color("#0E1C30") if rim == DEEP_LIGHT else BRASS[3]
        for x, y in ((0, 0), (19, 0), (0, 19), (19, 19)):
            px[y][x] = CLEAR
        frames.append(px)
    return frames


def cursor_frames():
    """24x24 selection brackets in foam, breathing in and out (2 frames)."""
    frames = []
    for inset in (0, 1):
        px = grid(24, 24)
        a, b = inset, 23 - inset
        for corner_x, corner_y, sx, sy in ((a, a, 1, 1), (b, a, -1, 1), (a, b, 1, -1), (b, b, -1, -1)):
            for i in range(6):
                for t in range(2):
                    px[corner_y + t * sy][corner_x + i * sx] = FOAM
                    px[corner_y + i * sy][corner_x + t * sx] = FOAM
            # Dark edge on the inside so it reads on any colour.
            for i in range(2, 6):
                px[corner_y + 2 * sy][corner_x + i * sx] = INK
                px[corner_y + i * sy][corner_x + 2 * sx] = INK
            px[corner_y + 2 * sy][corner_x + 2 * sx] = INK
        frames.append(px)
    return frames


def map_markers():
    """8x8 map markers: Wren, Tidestone (asleep), Tidestone (awake),
    chest, boss skull, door, sea-glass glint."""
    def from_rows(rows, colors):
        return [[hex_color(colors[c]) if c in colors else CLEAR for c in row] for row in rows]

    wren = from_rows([
        "..CCCC..",
        ".CCCCCC.",
        ".CwwwwC.",
        "..wewe..",
        "..wwww..",
        ".rrrrrr.",
        "..DDDD..",
        "...DD...",
    ], {"C": "#3A4E8E", "w": "#F6D2B0", "e": "#2A1E36", "r": "#E2574C", "D": "#5A78C0"})
    stone = {
        "k": "#2A2238", "o": "#8E7C93", "n": "#5E4E70",
    }
    asleep = from_rows([
        "..kkkk..",
        ".koooook",
        ".konnook",
        ".kooooko",
        ".koonook",
        ".kooooko",
        "kkkkkkkk",
        "........",
    ], stone)
    awake = from_rows([
        "..kkkk..",
        ".koooook",
        ".koNNook",
        ".kooooko",
        ".kooNNok",
        ".kooooko",
        "kkkkkkkk",
        "........",
    ], dict(stone, N="#6EF0E0"))
    chest = from_rows([
        "........",
        ".kkkkkk.",
        "kTTTTTTk",
        "kQQQQQQk",
        "kTTQQTTk",
        "kTTTTTTk",
        ".kkkkkk.",
        "........",
    ], {"k": "#2E1E24", "T": "#B8844E", "Q": "#F2C85A"})
    skull = from_rows([
        "..qqqq..",
        ".qqqqqq.",
        "qqkqqkqq",
        "qqkqqkqq",
        ".qqqqqq.",
        "..qkkq..",
        "..q..q..",
        "........",
    ], {"q": "#FFF4D6", "k": "#5C1A33"})
    door = from_rows([
        "..kkkk..",
        ".kGGGGk.",
        ".kGGGGk.",
        ".kGGGGk.",
        ".kGGGGk.",
        ".kGGGGk.",
        ".kkkkkk.",
        "........",
    ], {"k": "#2A1E36", "G": "#F4C542"})
    glass = from_rows([
        "........",
        "...w....",
        "...w....",
        ".wwXww..",
        "...w....",
        "...w....",
        "........",
        "........",
    ], {"w": "#C8EEF0", "X": "#FFFFFF"})
    return [wren, asleep, awake, chest, skull, door, glass]


def tab_frames():
    """16x14 three-slice tab: idle and active, for the pause menu's tab bar."""
    frames = []
    for fill, top in ((DEEP_DARK, DEEP_LIGHT), (DEEP, ROPE[1])):
        px = grid(16, 14, fill)
        for i in range(16):
            px[0][i] = INK
            px[1][i] = top
        for i in range(14):
            px[i][0] = px[i][15] = INK
        px[0][0] = px[0][15] = CLEAR
        frames.append(px)
    return frames


def build(ba):
    """Write the menu art. ba is the build_art module (lit, sheet, write_png)."""
    import os
    ba.RAMPS.update(RAMPS)
    ba.FLAT.update(FLAT)
    out = os.path.join(ba.OUT, "ui")
    frames = [ba.lit(f, 30 + i) for i, f in enumerate(icon_frames())]
    rows = [frames[i:i + 8] for i in range(0, len(frames), 8)]
    ba.write_png(os.path.join(out, "items.png"), ba.sheet(rows, 16, 16))
    ba.write_png(os.path.join(out, "panel.png"), panel())
    ba.write_png(os.path.join(out, "slot.png"), ba.sheet([slot_frames()], 20, 20))
    ba.write_png(os.path.join(out, "cursor.png"), ba.sheet([cursor_frames()], 24, 24))
    ba.write_png(os.path.join(out, "map_markers.png"), ba.sheet([map_markers()], 8, 8))
    ba.write_png(os.path.join(out, "tab.png"), ba.sheet([tab_frames()], 16, 14))
