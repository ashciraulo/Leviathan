#!/usr/bin/env python3
"""Builds Leviathan's pixel art from source in this file.

Sprites are drawn as silhouettes where each letter is a material (hair,
skin, tunic...). The builder then lights them the same way every time,
following the plan's art rules:

  * light from the top left (top-left edges get the highlight)
  * shadow under overhangs and on bottom-right edges
  * dark coloured outlines, never black: each outline is the darkest shade
    of the material it wraps
  * ramps shift hue: shadows lean blue-purple, highlights warm yellow

Tiles are generated procedurally from the Saltmarrow palette.

Run from the repo root:  python3 tools/build_art.py
(--check only verifies that the committed files match.)
Only the Python standard library is needed. Output goes to assets/.
"""

import os
import random
import struct
import sys
import zlib

import brinewood_art
import hull_art
import npc_art
import hull_dungeon_art
import kiln_art
import cinderreach_art
import mire_art
import verge_art
import ossuary_art
import gloamfen_art
import gale_art
import glacier_art
import belfry_art
import windmere_art
import frostspine_art

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets")


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


# --------------------------------------------------------------------------
# Palette. Ramps run highlight, light, base, shadow, outline.
# Saltmarrow anchors from the plan: sand #E8C88A, dusk purple #6B4E71,
# bleached white #FFF4D6, buoy red #E2574C. Sea glass #2E7F8C, foam #A8E6CF.
# --------------------------------------------------------------------------
RAMPS = {
    "y": ["#D9825A", "#B85E46", "#8C4A3C", "#5A2E46", "#2E1A33"],  # Wren's hair
    "C": ["#8AA8E0", "#5A78C0", "#3A4E8E", "#26305E", "#141832"],  # keeper's cap
    "D": ["#8AA8E0", "#5A78C0", "#3A4E8E", "#26305E", "#141832"],  # jumper navy
    "Q": ["#FFF0A0", "#F2C85A", "#C8963A", "#8A5E2E", "#3E2622"],  # lantern brass
    "w": ["#FFE8CC", "#F6D2B0", "#E8B896", "#B97C7A", "#5A3348"],  # skin
    "t": ["#A8E6CF", "#5FBFB7", "#2E8F8C", "#1F5872", "#18324A"],  # sea-glass tunic
    "r": ["#FFB08A", "#F27A5E", "#E2574C", "#A8323F", "#5C1A33"],  # buoy-red scarf
    "b": ["#C99A6B", "#A87A52", "#7A5240", "#4E3436", "#2E1E2E"],  # leather
    "p": ["#9E86A8", "#85709A", "#6B4E71", "#4A3558", "#2A1E36"],  # dusk trousers
    "d": ["#FFF4D6", "#E8C88A", "#B38A5A", "#7A5A40", "#3E2C2E"],  # driftwood
    "c": ["#FFC08A", "#F58A5E", "#E2654C", "#A8323F", "#4A1530"],  # crab shell
    "k": ["#FFF4E8", "#DCCCD4", "#B0A0B8", "#7A6890", "#3A2E4E"],  # barnacle shell
    "f": ["#E2A6E0", "#B878C4", "#8A4FA0", "#5E3478", "#2E1A40"],  # barnacle flesh
    "m": ["#C4DB7A", "#9FC46A", "#6F9A4E", "#3F6648", "#1F3A33"],  # moss body
    "s": ["#FFF4D6", "#DCCFB4", "#B0A08E", "#7E6E72", "#3A2E44"],  # shell plate
    "o": ["#E0D6E0", "#B9AABE", "#8E7C93", "#5E4E70", "#2A2238"],  # standing stone
    "a": ["#FFD0A0", "#E89A6A", "#C8704A", "#8A4A3E", "#3E1E2A"],  # clay
    "x": ["#FFF0B0", "#E8D07A", "#C8A858", "#8A7048", "#3E2C2E"],  # thatch
    "q": ["#FFFFFF", "#FFF4D6", "#E8DCC8", "#B0A0B0", "#4A3A58"],  # whitewash
    "j": ["#F2E3C6", "#D9C59E", "#B8A07A", "#86705A", "#3E2C2E"],  # rope, canvas
}
# Flat colours: not lit, no outline of their own.
FLAT = {
    "e": "#2A1E36",   # eyes
    "W": "#FFF4D6",   # eye glints
    "g": "#FFE36E",   # wind-up glow (tell)
    "G": "#F4C542",
    "n": "#5E4E70",   # rune, dormant
    "N": "#6EF0E0",   # rune, awake
    "K": "#2A1E36",   # doorways, dark windows
    "J": "#FFE36E",   # lit windows, lamp
    "I": "#F4C542",   # lamp glow edge
    "-": "#4E3436",   # plank seams
}
# Materials that get a little speckle texture.
TEXTURED = {"o": 0.10, "s": 0.08, "k": 0.10, "x": 0.25, "a": 0.05}
# Materials that cast a one-pixel shadow on what is under them.
CASTS_SHADOW = {"y", "r", "s", "x", "C"}

SHADOW = hex_color("#3E2C4A", 90)


def _lit_with(module):
    """lit(), using a dungeon art file's own materials."""
    palette = (module.RAMPS, module.FLAT)
    return lambda rows, seed=1: lit(rows, seed, palette)


def lit(rows, seed=1, palette=None):
    """Turn a material silhouette into lit RGBA pixels with outlines.
    `palette` is an art file's own (ramps, flat) materials: they win over
    the shared ones, so dungeon art files don't run out of letters."""
    ramps, flat = RAMPS, FLAT
    if palette:
        ramps, flat = dict(RAMPS), dict(FLAT)
        for letter in palette[0]:
            flat.pop(letter, None)
        for letter in palette[1]:
            ramps.pop(letter, None)
        ramps.update(palette[0])
        flat.update(palette[1])
    h, w = len(rows), len(rows[0])
    for r in rows:
        assert len(r) == w, ("ragged sprite row", r)
    rnd = random.Random(seed)

    def mat(x, y):
        if 0 <= x < w and 0 <= y < h:
            ch = rows[y][x]
            return None if ch == "." else ch
        return None

    px = [[(0, 0, 0, 0)] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            m = mat(x, y)
            if m is None:
                continue
            if m in flat:
                px[y][x] = hex_color(flat[m])
                continue
            ramp = ramps[m]
            up = mat(x, y - 1)
            # Lighting follows the whole silhouette, not each material, so
            # a tunic under a scarf still reads as one rounded body.
            open_up, open_left = up is None, mat(x - 1, y) is None
            open_down, open_right = mat(x, y + 1) is None, mat(x + 1, y) is None
            if up in CASTS_SHADOW and up != m:
                shade = 3          # under an overhang (hair, scarf, shell)
            elif open_up and open_left:
                shade = 0
            elif open_up or open_left:
                shade = 1
            elif open_down or open_right or mat(x + 2, y) is None:
                shade = 3
            else:
                shade = 2
            if m in TEXTURED and shade == 2 and rnd.random() < TEXTURED[m]:
                shade = rnd.choice([1, 3])
            px[y][x] = hex_color(ramp[shade])
    # Outlines: the darkest shade of the material they wrap.
    out = [row[:] for row in px]
    for y in range(h):
        for x in range(w):
            if mat(x, y) is not None:
                continue
            for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                m = mat(x + dx, y + dy)
                if m is not None:
                    # The art file's own palette, so materials added by
                    # other art files never change this sprite's outline.
                    ramp = ramps.get(m)
                    out[y][x] = hex_color(ramp[4] if ramp else "#2A1E36")
                    break
    return out


def flip(px):
    return [list(reversed(r)) for r in px]


# --------------------------------------------------------------------------
# Wren, 16x24, feet on row 22 (row 23 holds the outline).
# Built from a head, a torso and legs so frames stay consistent.
# --------------------------------------------------------------------------
HEAD_DOWN = [
    "................",
    "................",
    ".....CCCCCC.....",
    "....CCCCCCCC....",
    "...CCCCJCCCCC...",
    "..CCCCCCCCCCCC..",
    "...yywwwwwwyy...",
    "...ywewwwwewy...",
    "...ywewwwwewy...",
    "....wwwwwwww....",
    ".....wwwwww.....",
]
HEAD_UP = [
    "................",
    "................",
    ".....CCCCCC.....",
    "....CCCCCCCC....",
    "...CCCCCCCCCC...",
    "..CCCCCCCCCCCC..",
    "...yyyyyyyyyy...",
    "...yyyyyyyyyy...",
    "...yyyyyyyyyy...",
    "....yyyyyyyy....",
    ".....wwwwww.....",
]
HEAD_SIDE = [
    "................",
    "................",
    ".....CCCCCC.....",
    "....CCCCCCCC....",
    "...CCCCCCCJCC...",
    "...CCCCCCCCCCCC.",
    "...yyyyyywwww...",
    "...yyyyywwewww..",
    "...yyyyywwwwww..",
    "....yyyywwwww...",
    ".....yywwww.....",
]
# The keeper's striped jumper: navy (D) and whitewash (q) bands.
TORSO_DOWN = [
    "...qqqqqqqqqq...",
    "..wDDDDDDDDDDw..",
    "..wqqqqqqqqqqw..",
    "..wDDDDDDDDDDw..",
    "...qqqqqqqqqq...",
    "...bbbbbbbbbb...",
    "....pppppppp....",
    "....pppppppp....",
]
TORSO_UP = TORSO_DOWN
TORSO_SIDE = [
    "....qqqqqqqq....",
    "....DDDDDDDD....",
    "....qqqqqqqq....",
    "....DDDDDDDD....",
    "....qqqqqqqq....",
    "....bbbbbbbb....",
    "....pppppppp....",
    ".....pppppp.....",
]
# Wren's lantern, hanging from one hand: (row, column, text) overlays.
LANTERN = {
    "down": [(15, 13, "Q"), (16, 12, "QJQ"), (17, 12, "QJQ"), (18, 12, "QQQ")],
    "up": [(15, 2, "Q"), (16, 1, "QJQ"), (17, 1, "QJQ"), (18, 1, "QQQ")],
    "side": [(15, 11, "Q"), (16, 10, "QJQ"), (17, 10, "QJQ"), (18, 10, "QQQ")],
}
LEGS = {
    "down_idle": ["....ppp..ppp....", "....ppp..ppp....", "....bbb..bbb....", "....bbb..bbb....", "................"],
    "down_a":    ["....ppp..ppp....", "....ppp..bbb....", "....bbb..bbb....", "....bbb.........", "................"],
    "down_b":    ["....ppp..ppp....", "....bbb..ppp....", "....bbb..bbb....", ".........bbb....", "................"],
    "side_idle": [".....ppppp......", ".....pp.pp......", ".....bb.bb......", ".....bb.bbb.....", "................"],
    "side_a":    ["....ppppppp.....", "....pp...pp.....", "...bbb....bb....", "...bb.....bbb...", "................"],
    "side_b":    [".....ppppp......", "......ppp.......", "......bbb.......", "......bbbb......", "................"],
}


def wren_frame(head, torso, legs, bob=0, overlay=()):
    rows = [list(r) for r in head + torso + LEGS[legs]]
    for row, col, text in overlay:
        rows[row][col:col + len(text)] = list(text)
    rows = ["".join(r) for r in rows]
    assert len(rows) == 24, len(rows)
    if bob:
        rows = rows[bob:] + ["................"] * bob
    return lit(rows, seed=7)


def arm_forward(torso, row, cols):
    """Swap a few torso pixels for skin to show a reaching arm."""
    out = list(torso)
    r = list(out[row])
    for c in cols:
        r[c] = "w"
    out[row] = "".join(r)
    return out


def build_wren():
    frames = {}
    for name, head, torso, legs in (
        ("down", HEAD_DOWN, TORSO_DOWN, "down"),
        ("up", HEAD_UP, TORSO_UP, "down"),
        ("side", HEAD_SIDE, TORSO_SIDE, "side"),
    ):
        lamp = LANTERN[name]
        frames[name] = [
            wren_frame(head, torso, legs + "_idle", overlay=lamp),
            wren_frame(head, torso, legs + "_a", bob=1, overlay=lamp),
            wren_frame(head, torso, legs + "_idle", overlay=lamp),
            wren_frame(head, torso, legs + "_b", bob=1, overlay=lamp),
        ]
    # Attack poses: lean into the swing.
    frames["down"].append(wren_frame(HEAD_DOWN, arm_forward(TORSO_DOWN, 5, [7, 8]), "down_idle"))
    frames["up"].append(wren_frame(HEAD_UP, TORSO_UP, "down_idle", bob=1))
    frames["side"].append(wren_frame(HEAD_SIDE, arm_forward(TORSO_SIDE, 3, [12, 13]), "side_a"))
    # Hum pose: eyes closed, hands together.
    hum_head = [r.replace("e", "w") for r in HEAD_DOWN]
    hum_head[8] = "...ywwwwwwwwy..."
    hum_head[7] = "...ywewwwwewy...".replace("e", "y")
    frames["down"].append(wren_frame(hum_head, arm_forward(TORSO_DOWN, 4, [7, 8]), "down_idle"))
    frames["up"].append(frames["up"][0])
    frames["side"].append(frames["side"][0])
    # Sheet: rows down, up, side (faces right); columns idle, walk x3, attack, hum.
    return sheet([frames["down"], frames["up"], frames["side"]], 16, 24)


SWORD = [
    "................",
    "...b............",
    ".bbbddddddddddd.",
    ".bbbdddddddddd..",
    "...b............",
    "................",
]

# --------------------------------------------------------------------------
# Enemies
# --------------------------------------------------------------------------
SCUTTLER = {
    "walk_a": [
        "................",
        "................",
        "................",
        "..cc..e..e..cc..",
        ".cccc.c..c.cccc.",
        ".cc.c.c..c.c.cc.",
        "...cccccccccc...",
        "..cccccccccccc..",
        "..cccccccccccc..",
        "...cccccccccc...",
        "..cc.cc..cc.cc..",
        ".cc..c....c..cc.",
        "................",
        "................",
    ],
    "walk_b": [
        "................",
        "................",
        "................",
        "..cc..e..e..cc..",
        ".cccc.c..c.cccc.",
        ".cc.c.c..c.c.cc.",
        "...cccccccccc...",
        "..cccccccccccc..",
        "..cccccccccccc..",
        "...cccccccccc...",
        "...cc.cc.cc.cc..",
        "...c..c..c..c...",
        "................",
        "................",
    ],
    "windup": [
        "................",
        ".cc..........cc.",
        "cccc........cccc",
        "cc.c..e..e..c.cc",
        "..cc..c..c..cc..",
        "...cccccccccc...",
        "..cccccccccccc..",
        "..cccccccccccc..",
        "..cccccccccccc..",
        "...cccccccccc...",
        "..ccc......ccc..",
        ".cc..........cc.",
        "................",
        "................",
    ],
}
SPITTER = {
    "idle": [
        "................",
        "................",
        "................",
        "................",
        "......ffff......",
        ".....kffffk.....",
        "....kkkkkkkk....",
        "...kkkkkkkkkk...",
        "...kkkkkkkkkk...",
        "..kkkkkkkkkkkk..",
        "..kkkkkkkkkkkk..",
        ".kkkkkkkkkkkkkk.",
        ".kkkkkkkkkkkkkk.",
        "................",
    ],
    "windup": [
        "................",
        "................",
        "......gggg......",
        ".....gGGGGg.....",
        ".....kGffGk.....",
        "....kkkffkkk....",
        "...kkkkkkkkkk...",
        "..kkkkkkkkkkkk..",
        "..kkkkkkkkkkkk..",
        ".kkkkkkkkkkkkkk.",
        ".kkkkkkkkkkkkkk.",
        "kkkkkkkkkkkkkkkk",
        "kkkkkkkkkkkkkkkk",
        "................",
    ],
}
SHELLBACK = {
    "down": [
        "................",
        "................",
        "....mmmmmmmm....",
        "...mmmmmmmmmm...",
        "...mmmemmemmm...",
        "..ssssssssssss..",
        "..ssssssssssss..",
        "..ssssssssssss..",
        "..ssssssssssss..",
        "..ssssssssssss..",
        "...ssssssssss...",
        "...m.m....m.m...",
        "................",
        "................",
    ],
    "up": [
        "................",
        "................",
        "...ssssssssss...",
        "..ssssssssssss..",
        "..ssssssssssss..",
        "..ssssssssssss..",
        "..ssssssssssss..",
        "...mmmmmmmmmm...",
        "...mmmmmmmmmm...",
        "...mmmmmmmmmm...",
        "....mmmmmmmm....",
        "...m.m....m.m...",
        "................",
        "................",
    ],
    "side": [
        "................",
        "..........sss...",
        "....mmmmm.ssss..",
        "...mmmmmmmssss..",
        "...mmmmmemssss..",
        "..mmmmmmmmssss..",
        "..mmmmmmmmssss..",
        "..mmmmmmmmssss..",
        "..mmmmmmmmssss..",
        "...mmmmmmmssss..",
        "....mmmmm.sss...",
        "....m.m.m.......",
        "................",
        "................",
    ],
}
TIDESTONE = [
    "................",
    "................",
    "......oooo......",
    ".....oooooo.....",
    "....oooooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "....ooonnooo....",
    "....oonoonoo....",
    "....oooooono....",
    "....onnooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "....oooooooo....",
    "...oooooooooo...",
    "...oooooooooo...",
    "................",
]


# Pell's three-clawed crab: the Scuttler's body in blue, its claws orange,
# and a third claw on its right side. ! = shell, ; = claws (the letters
# and digits are all taken).
QUEST_CRAB_RAMPS = {
    "!": ["#A8E4F5", "#62B4DE", "#3F86B0", "#285A80", "#16304A"],
    ";": ["#FFD890", "#FFAA50", "#F08A3C", "#B85A26", "#5C2A1A"],
}


def quest_crab_frame(rows):
    # Two columns of room each side, so the third claw can stand clear.
    out = [list(".." + r.replace("c", "!") + "..") for r in rows]
    # The two front claws.
    for y in (3, 4, 5):
        for x in list(range(2, 7)) + list(range(13, 18)):
            if out[y][x] == "!":
                out[y][x] = ";"
    # The third claw: a full pincer reaching out from the right of the shell.
    # The third claw: a copy of the left front claw, lower down and further
    # out, held clear of the others so it reads at a glance.
    for y in (3, 4, 5):
        for x in range(2, 7):
            if out[y][x] == ";":
                out[y + 4][x - 3] = ";"
    return ["".join(r) for r in out]


def build_enemies():
    out = {}
    out["quest_crab"] = sheet([[lit(quest_crab_frame(SCUTTLER[k]), 3) for k in ("walk_a", "walk_b")]], 20, 14)
    out["scuttler"] = sheet([[lit(SCUTTLER[k], 3) for k in ("walk_a", "walk_b", "windup")]], 16, 14)
    out["spitter"] = sheet([[lit(SPITTER[k], 4) for k in ("idle", "windup")]], 16, 14)
    out["shellback"] = sheet([[lit(SHELLBACK[k], 5) for k in ("down", "up", "side")]], 16, 14)
    awake = [r.replace("n", "N") for r in TIDESTONE]
    out["tidestone"] = sheet([[lit(TIDESTONE, 6), lit(awake, 6)]], 16, 22)
    out["sword"] = sheet([[lit(SWORD, 8)]], 16, 6)
    out["slagbeetle"] = sheet([[lit(cinderreach_art.SLAGBEETLE[k], 26) for k in ("walk_a", "walk_b", "crack", "flipped")]], 16, 14)
    out["geyser"] = sheet([[lit(cinderreach_art.geyser(f), 27) for f in range(3)]], 16, 32)
    out["sporecap"] = sheet([[lit(gloamfen_art.sporecap(k), 28) for k in ("walk_a", "walk_b", "swell", "spent")]], 16, 16)
    out["spore_cloud"] = sheet([[lit(gloamfen_art.spore_cloud(f), 29) for f in range(3)]], 64, 64)
    out["tumbleburr"] = sheet([[lit(windmere_art.tumbleburr(f), 43) for f in range(4)]], 16, 16)
    out["sledgeseal"] = sheet([[lit(frostspine_art.sledgeseal(k), 44) for k in ("idle", "rear", "slide")]], 20, 14)
    out["lanternmoth"] = sheet([[lit(brinewood_art.LANTERNMOTH[k], 25) for k in ("up", "down", "flare")]], 16, 14)
    out["bogskipper"] = sheet([[lit(brinewood_art.BOGSKIPPER[k], 9) for k in ("hidden", "rise", "body")]], 16, 14)
    return out


# --------------------------------------------------------------------------
# Saltmarrow props. Big ones are drawn with simple shape helpers.
# --------------------------------------------------------------------------
def canvas(w, h):
    return [["."] * w for _ in range(h)]


def fill_rect(c, x, y, w, h, m):
    for yy in range(max(0, y), min(len(c), y + h)):
        for xx in range(max(0, x), min(len(c[0]), x + w)):
            c[yy][xx] = m


def rows_of(c):
    return ["".join(r) for r in c]


POT = [
    "................",
    "................",
    "................",
    "......aaaa......",
    ".....aaaaaa.....",
    "......aaaa......",
    "....aaaaaaaa....",
    "...aaaaaaaaaa...",
    "...aaaaaaaaaa...",
    "...aaaaaaaaaa...",
    "...aaaaaaaaaa...",
    "....aaaaaaaa....",
    ".....aaaaaa.....",
    "................",
]
BARREL = [
    "................",
    "................",
    "....dddddddd....",
    "...dddddddddd...",
    "...bbbbbbbbbb...",
    "...dddddddddd...",
    "...d-ddd-ddd-...",
    "...dddddddddd...",
    "...d-ddd-ddd-...",
    "...bbbbbbbbbb...",
    "...dddddddddd...",
    "....dddddddd....",
    "................",
    "................",
]
FENCE = [
    "................",
    "................",
    "......dddd......",
    "......dddd......",
    "jjjjjjjjjjjjjjjj",
    "......dddd......",
    "......dddd......",
    "jjjjjjjjjjjjjjjj",
    "......dddd......",
    "......dddd......",
    "......dddd......",
    "......dddd......",
    "................",
    "................",
]
SIGN = [
    "................",
    "................",
    "..dddddddddddd..",
    "..d----------d..",
    "..dddddddddddd..",
    "..d---------dd..",
    "..dddddddddddd..",
    "......dddd......",
    "......dddd......",
    "......dddd......",
    "......dddd......",
    "......dddd......",
    "................",
    "................",
]


def hut():
    """A driftwood fisher's hut with a thatch roof, 48x48."""
    c = canvas(48, 48)
    # Walls of horizontal planks.
    fill_rect(c, 5, 22, 38, 23, "d")
    for y in range(25, 45, 4):
        fill_rect(c, 6, y, 36, 1, "-")
    # Door and a lit window.
    fill_rect(c, 20, 31, 8, 14, "K")
    fill_rect(c, 9, 28, 7, 6, "J")
    fill_rect(c, 12, 28, 1, 6, "-")
    fill_rect(c, 32, 28, 7, 6, "K")
    # Thatch roof: a wide trapezoid that overhangs the walls.
    for i, y in enumerate(range(3, 25)):
        inset = max(0, 12 - i)
        fill_rect(c, 1 + inset, y, 46 - inset * 2, 1, "x")
    # Straw strands, then rope bands across the thatch.
    for y in range(4, 24):
        for x in range(48):
            if c[y][x] == "x" and (x * 3 + y) % 7 == 0:
                c[y][x] = "-" if y % 2 else "x"
    for y in (12, 19):
        for x in range(48):
            if c[y][x] == "x":
                c[y][x] = "j"
    return rows_of(c)


def lighthouse():
    """Saltmarrow's lighthouse, 32x80: whitewash and buoy-red bands."""
    c = canvas(32, 80)
    # Tapered tower.
    for y in range(22, 77):
        t = (y - 22) / 55.0
        half = int(6 + t * 5)
        band = "r" if ((y - 22) // 9) % 2 == 1 else "q"
        fill_rect(c, 16 - half, y, half * 2, 1, band)
    # Door and slit windows.
    fill_rect(c, 13, 66, 6, 10, "K")
    fill_rect(c, 15, 34, 2, 4, "K")
    fill_rect(c, 15, 52, 2, 4, "K")
    # Gallery deck and rail.
    fill_rect(c, 6, 20, 20, 2, "b")
    for x in range(7, 26, 3):
        fill_rect(c, x, 16, 1, 4, "b")
    fill_rect(c, 6, 15, 20, 1, "b")
    # Lamp room.
    fill_rect(c, 10, 9, 12, 7, "J")
    fill_rect(c, 10, 9, 1, 7, "I")
    fill_rect(c, 21, 9, 1, 7, "I")
    fill_rect(c, 15, 9, 2, 7, "I")
    # Red cap.
    for i, y in enumerate(range(2, 9)):
        fill_rect(c, 15 - i, y, 2 + i * 2, 1, "r")
    fill_rect(c, 15, 1, 2, 1, "b")
    return rows_of(c)


def build_props():
    return {
        "pot": sheet([[lit(POT, 11)]], 16, 14),
        "barrel": sheet([[lit(BARREL, 12)]], 16, 14),
        "fence": sheet([[lit(FENCE, 13)]], 16, 14),
        "sign": sheet([[lit(SIGN, 14)]], 16, 14),
        "hut": sheet([[lit(hut(), 15)]], 48, 48),
        "lighthouse": sheet([[lit(lighthouse(), 16)]], 32, 80),
        "mangrove": sheet([[lit(brinewood_art.mangrove(), 17)]], 48, 64),
        "windmill": sheet([[lit(windmere_art.windmill(f), 42) for f in range(4)]], 32, 48),
        "wreck": sheet([[lit(brinewood_art.wreck(), 18)]], 48, 32),
        "lantern_post": sheet([[lit(brinewood_art.lantern_post(), 19)]], 16, 32),
        "hull": sheet([[lit(hull_art.beached_hull(), 20)]], 96, 72),
    }


def build_dungeon_objects():
    """Old Hessa and the things Wren finds in dungeons."""
    return {
        "hessa": sheet([[lit(f, 21) for f in hull_art.hessa_frames()]], 16, 24),
        "chest": sheet([[lit(hull_art.CHEST_CLOSED, 22), lit(hull_art.CHEST_OPEN, 22)]], 16, 16),
        "locked_hatch": sheet([[lit(hull_art.LOCKED_HATCH, 23)]], 16, 16),
        "small_key": sheet([[lit(hull_art.SMALL_KEY, 24)]], 16, 16),
    }


# --------------------------------------------------------------------------
# Small round things: bubbles (HUD and shots) and drop shadows.
# --------------------------------------------------------------------------
def disc(size, radius, fill, rim, shine=None, inner=None):
    c = (size - 1) / 2.0
    px = [[(0, 0, 0, 0)] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
            if d <= radius - 0.5:
                px[y][x] = fill
                if inner and d > radius - 1.8 and (x - c) + (y - c) > 0:
                    px[y][x] = inner
            elif d <= radius + 0.5:
                px[y][x] = rim
    if shine:
        sx, sy = int(c - radius / 2.2), int(c - radius / 2.2)
        px[sy][sx] = shine
        px[sy][sx + 1] = shine
        px[sy + 1][sx] = shine
    return px


def ring(size, radius, color):
    c = (size - 1) / 2.0
    px = [[(0, 0, 0, 0)] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
            if abs(d - radius) <= 0.5:
                px[y][x] = color
    return px


def ellipse(w, h, color):
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
    return [[color if ((x - cx) / (w / 2.0)) ** 2 + ((y - cy) / (h / 2.0)) ** 2 <= 1.0 else (0, 0, 0, 0)
             for x in range(w)] for y in range(h)]


def build_round():
    foam, glass, deep = hex_color("#A8E6CF"), hex_color("#5FBFB7"), hex_color("#18324A")
    white = hex_color("#FFF4D6")
    full = disc(11, 4.5, glass, deep, white, hex_color("#2E8F8C"))
    for y in range(11):
        for x in range(11):
            if full[y][x] == glass and x + y < 9:
                full[y][x] = foam
    full[3][3] = white
    full[3][4] = white
    full[4][3] = white
    empty = ring(11, 4.0, hex_color("#5FBFB7", 120))
    bubbles = sheet([[full, empty]], 11, 11)
    shot_a = disc(8, 3.2, hex_color("#B878C4"), hex_color("#2E1A40"), white)
    shot_b = disc(8, 3.2, hex_color("#E2A6E0"), hex_color("#2E1A40"), white)
    shots = sheet([[shot_a, shot_b]], 8, 8)
    shadows = {
        "shadow_small": sheet([[ellipse(12, 4, SHADOW)]], 12, 4),
        "shadow_large": sheet([[ellipse(16, 5, SHADOW)]], 16, 5),
    }
    return bubbles, shots, shadows


# --------------------------------------------------------------------------
# Saltmarrow tiles, 16x16.
# --------------------------------------------------------------------------
T = 16
SAND = [hex_color(c) for c in ("#FFF4D6", "#F2DCA6", "#E8C88A", "#D4AC72", "#B38867", "#8A6670")]
WET = [hex_color(c) for c in ("#E8C88A", "#D9B47A", "#C9A06C", "#A88062", "#8A6670")]
ROCK = [hex_color(c) for c in ("#D8CCD6", "#B4A3B6", "#8E7C93", "#66567A", "#463A5C", "#2A2238")]
GRASS = [hex_color(c) for c in ("#D6E58A", "#A9C46A", "#6F9A4E", "#3F6648", "#24403A")]
WATER = [hex_color(c) for c in ("#A8E6CF", "#5FBFB7", "#2E7F8C", "#236A80", "#1F5872")]
FOAM = hex_color("#A8E6CF")
FOAM_WHITE = hex_color("#FFF4D6")
CLEAR = (0, 0, 0, 0)


def blank(color=CLEAR):
    return [[color] * T for _ in range(T)]


def sand_tile(seed, ramp=SAND, wet=False):
    rnd = random.Random(seed)
    base = ramp[2] if not wet else ramp[1]
    px = blank(base)
    # Soft ripples: short horizontal dashes a shade lighter or darker.
    for _ in range(4):
        x, y = rnd.randrange(T - 4), rnd.randrange(T)
        col = ramp[1] if not wet else ramp[0]
        for i in range(rnd.randrange(2, 5)):
            px[y][x + i] = col
        if y + 1 < T:
            for i in range(1, rnd.randrange(2, 5)):
                px[y + 1][x + i] = ramp[3] if not wet else ramp[2]
    # Speckles.
    for _ in range(6):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice([ramp[1], ramp[3]])
    # A pebble now and then (lit from the top left).
    if rnd.random() < 0.6:
        x, y = rnd.randrange(1, T - 3), rnd.randrange(1, T - 3)
        px[y][x] = ramp[4]
        px[y][x + 1] = ramp[4]
        px[y + 1][x] = ramp[4]
        px[y + 1][x + 1] = ramp[5] if not wet else ramp[4]
        px[y - 1][x] = ramp[0]
    return px


def shell_deco(seed):
    """A small clam shell on transparent background."""
    px = blank()
    pink, pink_d, white = hex_color("#F2B8A8"), hex_color("#B97C7A"), hex_color("#FFF4D6")
    rows = ["..WPPW..", ".WPPPPW.", "WPPdPPdW", ".PdPPdP.", "..ddd..."]
    ox, oy = 4 + seed % 4, 6 + seed % 3
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "W":
                px[oy + y][ox + x] = white
            elif ch == "P":
                px[oy + y][ox + x] = pink
            elif ch == "d":
                px[oy + y][ox + x] = pink_d
    return px


def grass_tuft(seed):
    rnd = random.Random(seed)
    px = blank()
    base_x = 4 + rnd.randrange(6)
    for blade in range(5):
        x = base_x + blade + rnd.randrange(-1, 2)
        height = rnd.randrange(5, 10)
        lean = rnd.choice([-1, 0, 1])
        for i in range(height):
            yy = 14 - i
            xx = min(T - 1, max(0, x + (lean if i > height // 2 else 0)))
            px[yy][xx] = GRASS[1] if i > height - 3 else (GRASS[2] if i > 1 else GRASS[3])
    return px


def cliff_top(seed):
    """Rock plateau capped with dune grass."""
    rnd = random.Random(seed)
    px = blank(GRASS[2])
    for _ in range(26):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = rnd.choice([GRASS[1], GRASS[3], GRASS[1]])
    for _ in range(5):
        x, y = rnd.randrange(T), rnd.randrange(1, T)
        px[y][x] = GRASS[0]
        px[y - 1][x] = GRASS[1]
    return px


def cliff_face(seed):
    """Front of a cliff: grass lip, layered rock, dark foot."""
    rnd = random.Random(seed)
    px = blank(ROCK[3])
    for x in range(T):
        px[0][x] = GRASS[2]
        px[1][x] = GRASS[3] if rnd.random() < 0.6 else GRASS[2]
        px[2][x] = ROCK[1]
        px[3][x] = ROCK[2]
    # Irregular boulders: each a lit top-left rim and a dark bottom-right seam.
    y = 4
    while y < T - 3:
        x = -rnd.randrange(0, 5)
        height = rnd.randrange(4, 6)
        while x < T:
            width = rnd.randrange(4, 8)
            for xx in range(max(0, x), min(T, x + width)):
                for yy in range(y, min(T - 2, y + height)):
                    px[yy][xx] = ROCK[2] if (xx + yy) % 5 else ROCK[3]
                if y + height - 1 < T - 2:
                    px[y + height - 1][xx] = ROCK[4]
                px[y][xx] = ROCK[1]
            if 0 <= x + width - 1 < T:
                for yy in range(y, min(T - 2, y + height)):
                    px[yy][x + width - 1] = ROCK[4]
            if 0 <= x < T:
                for yy in range(y + 1, min(T - 2, y + height - 1)):
                    px[yy][x] = ROCK[1]
            x += width
        y += height
    for x in range(T):
        px[T - 1][x] = ROCK[5]
        px[T - 2][x] = ROCK[4]
    # Grass drips over the lip.
    for _ in range(4):
        x = rnd.randrange(T)
        px[2][x] = GRASS[3]
    return px


def water_tile(frame):
    px = blank(WATER[2])
    rnd = random.Random(42)
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(T)
        px[y][x] = WATER[3]
    # Sparkle wavelets drift right between frames.
    for i, (x, y) in enumerate(((2, 3), (9, 5), (5, 10), (12, 12), (1, 13))):
        xx = (x + frame * 2) % T
        for k in range(3):
            px[y][(xx + k) % T] = WATER[1]
        px[y + 1 if y + 1 < T else y][(xx + 1) % T] = WATER[3]
    if frame == 1:
        px[4][7] = FOAM
        px[11][3] = FOAM
    return px


def foam_edge(side, frame):
    """Foam where water meets sand. side: top, bottom, left, right."""
    px = blank()
    rnd = random.Random(10 + frame)
    for i in range(T):
        depth = 1 + (1 if (i + frame) % 4 < 2 else 0)
        for d in range(depth + 1):
            color = FOAM_WHITE if d == 0 else (FOAM if d <= depth - 0 else WATER[1])
            if d == depth:
                color = WATER[1] if rnd.random() < 0.7 else CLEAR
            if side == "top":
                px[d][i] = color
            elif side == "bottom":
                px[T - 1 - d][i] = color
            elif side == "left":
                px[i][d] = color
            else:
                px[i][T - 1 - d] = color
    return px


def damp_edge(side, seed):
    """Darker, damp sand fading away from a water edge."""
    rnd = random.Random(seed)
    px = blank()
    for i in range(T):
        depth = 3 + rnd.randrange(0, 3)
        for d in range(depth):
            alpha = 120 if d < depth - 2 else 60
            col = (WET[3][0], WET[3][1], WET[3][2], alpha)
            if side == "top":
                px[d][i] = col
            elif side == "bottom":
                px[T - 1 - d][i] = col
            elif side == "left":
                px[i][d] = col
            else:
                px[i][T - 1 - d] = col
    return px


def shade_overlay(side):
    px = blank()
    col = hex_color("#6B4E71", 70)
    for i in range(T):
        for d in range(4 if side == "top" else 2):
            if side == "top":
                px[d][i] = col
            else:
                px[i][d] = col
    return px


TILE_LAYOUT = [
    # name, builder
    ("sand_0", lambda: sand_tile(1)), ("sand_1", lambda: sand_tile(2)),
    ("sand_2", lambda: sand_tile(3)), ("sand_3", lambda: sand_tile(4)),
    ("wet_0", lambda: sand_tile(5, WET, True)), ("wet_1", lambda: sand_tile(6, WET, True)),
    ("wet_2", lambda: sand_tile(7, WET, True)), ("wet_3", lambda: sand_tile(8, WET, True)),
    ("cliff_top_0", lambda: cliff_top(1)), ("cliff_top_1", lambda: cliff_top(2)),
    ("cliff_face_0", lambda: cliff_face(1)), ("cliff_face_1", lambda: cliff_face(2)),
    ("grass_0", lambda: grass_tuft(1)), ("grass_1", lambda: grass_tuft(5)),
    ("shell_0", lambda: shell_deco(1)), ("shell_1", lambda: shell_deco(6)),
    ("water_0", lambda: water_tile(0)), ("water_1", lambda: water_tile(1)),
    ("foam_top_0", lambda: foam_edge("top", 0)), ("foam_bottom_0", lambda: foam_edge("bottom", 0)),
    ("foam_left_0", lambda: foam_edge("left", 0)), ("foam_right_0", lambda: foam_edge("right", 0)),
    ("shade_top", lambda: shade_overlay("top")), ("shade_left", lambda: shade_overlay("left")),
    ("foam_top_1", lambda: foam_edge("top", 1)), ("foam_bottom_1", lambda: foam_edge("bottom", 1)),
    ("foam_left_1", lambda: foam_edge("left", 1)), ("foam_right_1", lambda: foam_edge("right", 1)),
    ("damp_top", lambda: damp_edge("top", 1)), ("damp_bottom", lambda: damp_edge("bottom", 2)),
    ("damp_left", lambda: damp_edge("left", 3)), ("damp_right", lambda: damp_edge("right", 4)),
]
TILE_COLUMNS = 8
TILE_LAYOUT += brinewood_art.TILES
TILE_LAYOUT += hull_art.TILES
TILE_LAYOUT += hull_dungeon_art.TILES
TILE_LAYOUT += kiln_art.TILES
RAMPS.update(brinewood_art.RAMPS)
FLAT.update(brinewood_art.FLAT)
RAMPS.update(hull_art.RAMPS)
FLAT.update(hull_art.FLAT)
assert not set(QUEST_CRAB_RAMPS) & (set(RAMPS) | set(FLAT)), "quest crab material letters clash"
RAMPS.update(QUEST_CRAB_RAMPS)
assert not set(npc_art.RAMPS) & set(RAMPS), ("npc_art material letters clash", set(npc_art.RAMPS) & set(RAMPS))
RAMPS.update(npc_art.RAMPS)
FLAT.update(npc_art.FLAT)
_taken = set(RAMPS) | set(FLAT)
_clash = _taken & (set(hull_dungeon_art.RAMPS) | set(hull_dungeon_art.FLAT))
assert not _clash, "hull_dungeon_art reuses material letters: %s" % sorted(_clash)
RAMPS.update(hull_dungeon_art.RAMPS)
FLAT.update(hull_dungeon_art.FLAT)
_taken = set(RAMPS) | set(FLAT)
_clash = _taken & (set(cinderreach_art.RAMPS) | set(cinderreach_art.FLAT))
assert not _clash, "cinderreach_art reuses material letters: %s" % sorted(_clash)
RAMPS.update(cinderreach_art.RAMPS)
FLAT.update(cinderreach_art.FLAT)
TILE_LAYOUT += cinderreach_art.TILES
TILE_LAYOUT += mire_art.TILES
TILE_LAYOUT += verge_art.TILES
TILE_LAYOUT += ossuary_art.TILES
TILE_LAYOUT += gale_art.TILES
TILE_LAYOUT += glacier_art.TILES
TILE_LAYOUT += belfry_art.TILES
_names = [entry[0] for entry in TILE_LAYOUT if entry]
assert len(_names) == len(set(_names)), "tile names used twice: %s" % sorted(n for n in set(_names) if _names.count(n) > 1)

_taken = set(RAMPS) | set(FLAT)
_clash = _taken & (set(gloamfen_art.RAMPS) | set(gloamfen_art.FLAT))
assert not _clash, "gloamfen_art reuses material letters: %s" % sorted(_clash)
RAMPS.update(gloamfen_art.RAMPS)
FLAT.update(gloamfen_art.FLAT)
_names = {n for n, _ in TILE_LAYOUT}
assert not _names & {n for n, _ in gloamfen_art.TILES}, "gloamfen_art reuses tile names"
TILE_LAYOUT += gloamfen_art.TILES

_taken = set(RAMPS) | set(FLAT)
_clash = _taken & (set(windmere_art.RAMPS) | set(windmere_art.FLAT))
assert not _clash, "windmere_art reuses material letters: %s" % sorted(_clash)
RAMPS.update(windmere_art.RAMPS)
FLAT.update(windmere_art.FLAT)
_names = {n for n, _ in TILE_LAYOUT}
assert not _names & {n for n, _ in windmere_art.TILES}, "windmere_art reuses tile names"
TILE_LAYOUT += windmere_art.TILES

_taken = set(RAMPS) | set(FLAT)
_clash = _taken & (set(frostspine_art.RAMPS) | set(frostspine_art.FLAT))
assert not _clash, "frostspine_art reuses material letters: %s" % sorted(_clash)
RAMPS.update(frostspine_art.RAMPS)
FLAT.update(frostspine_art.FLAT)
_names = {n for n, _ in TILE_LAYOUT}
assert not _names & {n for n, _ in frostspine_art.TILES}, "frostspine_art reuses tile names"
TILE_LAYOUT += frostspine_art.TILES


def build_tiles():
    tiles = [builder() for _, builder in TILE_LAYOUT]
    rows = [tiles[i:i + TILE_COLUMNS] for i in range(0, len(tiles), TILE_COLUMNS)]
    while len(rows[-1]) < TILE_COLUMNS:
        rows[-1].append(blank())
    return sheet(rows, T, T)


def write_text(path, text):
    if CHECK_ONLY:
        if not os.path.exists(path) or open(path).read() != text:
            STALE.append(os.path.relpath(path, ROOT))
        return
    with open(path, "w") as f:
        f.write(text)


def write_tile_atlas_gd(path):
    lines = [
        "class_name TileAtlas",
        "extends Object",
        "## Tile positions in assets/tiles/world.png.",
        "## Generated by tools/build_art.py. Do not edit by hand.",
        "",
        "const SIZE := 16",
        "const POSITIONS := {",
    ]
    for i, (name, _) in enumerate(TILE_LAYOUT):
        lines.append('\t"%s": Vector2i(%d, %d),' % (name, i % TILE_COLUMNS, i // TILE_COLUMNS))
    lines += ["}", "", "",
              "static func region(tile_name: String) -> Rect2:",
              "\tvar cell: Vector2i = POSITIONS[tile_name]",
              "\treturn Rect2(cell.x * SIZE, cell.y * SIZE, SIZE, SIZE)", ""]
    write_text(path, "\n".join(lines))


# --------------------------------------------------------------------------
# Sheets and PNG output (standard library only).
# --------------------------------------------------------------------------
def sheet(rows_of_frames, fw, fh):
    cols = max(len(r) for r in rows_of_frames)
    w, h = cols * fw, len(rows_of_frames) * fh
    px = [[(0, 0, 0, 0)] * w for _ in range(h)]
    for ry, frames in enumerate(rows_of_frames):
        for cx, frame in enumerate(frames):
            assert len(frame) == fh and len(frame[0]) == fw, ("frame size", len(frame), len(frame[0]), fw, fh)
            for y in range(fh):
                for x in range(fw):
                    px[ry * fh + y][cx * fw + x] = frame[y][x]
    return px


CHECK_ONLY = False
STALE = []


def raw_pixels(px):
    return b"".join(b"\x00" + b"".join(struct.pack("BBBB", *p) for p in row) for row in px)


def png_raw(path):
    """The uncompressed image data of a PNG this script wrote."""
    with open(path, "rb") as f:
        data = f.read()
    pos, idat = 8, b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        if tag == b"IDAT":
            idat += data[pos + 8:pos + 8 + length]
        pos += 12 + length
    return zlib.decompress(idat)


def write_png(path, px):
    h, w = len(px), len(px[0])
    raw = raw_pixels(px)
    if CHECK_ONLY:
        # Compare pixels, not bytes: zlib versions compress differently.
        if not os.path.exists(path) or png_raw(path) != raw:
            STALE.append(os.path.relpath(path, ROOT))
        return

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


# --------------------------------------------------------------------------
# Tide: the pixel font, with a baked-in dark outline. BMFont text format,
# which Godot imports as a font.
# --------------------------------------------------------------------------
def build_font():
    from font_glyphs import GLYPHS

    body, edge = hex_color("#FFF4D6"), hex_color("#2A1E36")
    # A plain glyph is 9 rows in an 11-pixel cell (the outline takes a pixel
    # on each side). Accented letters have up to 2 extra rows above; they
    # stick out of the line box upwards (negative yoffset).
    TALL = 2
    cell_w, cell_h, per_row = 8, 11 + TALL, 16
    chars = sorted(GLYPHS, key=ord)
    rows = (len(chars) + per_row - 1) // per_row
    px = [[(0, 0, 0, 0)] * (cell_w * per_row) for _ in range(cell_h * rows)]
    lines = []
    for i, ch in enumerate(chars):
        glyph = GLYPHS[ch]
        gw = len(glyph[0])
        extra = len(glyph) - 9
        assert 0 <= extra <= TALL and gw + 2 <= cell_w and len(set(map(len, glyph))) == 1, ch
        ox, oy = (i % per_row) * cell_w, (i // per_row) * cell_h + TALL - extra
        on = {(x, y) for y, r in enumerate(glyph) for x, c in enumerate(r) if c == "#"}
        for x, y in on:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if (x + dx, y + dy) not in on:
                        px[oy + 1 + y + dy][ox + 1 + x + dx] = edge
        for x, y in on:
            px[oy + 1 + y][ox + 1 + x] = body
        lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=-1 yoffset=%d xadvance=%d page=0 chnl=15"
                     % (ord(ch), ox, oy, gw + 2, 11 + extra, -extra, gw + 2))
    header = [
        'info face="Tide" size=11 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0',
        "common lineHeight=11 base=8 scaleW=%d scaleH=%d pages=1 packed=0" % (cell_w * per_row, cell_h * rows),
        'page id=0 file="tide.png"',
        "chars count=%d" % len(chars),
    ]
    return px, "\n".join(header + lines) + "\n"


def main():
    global CHECK_ONLY
    CHECK_ONLY = "--check" in sys.argv
    write_png(os.path.join(OUT, "sprites", "wren.png"), build_wren())
    for name, px in build_enemies().items():
        write_png(os.path.join(OUT, "sprites", name + ".png"), px)
    for name, px in build_props().items():
        write_png(os.path.join(OUT, "props", name + ".png"), px)
    for name, px in build_dungeon_objects().items():
        write_png(os.path.join(OUT, "sprites", name + ".png"), px)
    for name, frames in npc_art.SPRITES.items():
        write_png(os.path.join(OUT, "sprites", "villager_" + name + ".png"), sheet([[lit(f, 31) for f in frames()]], 16, 24))
    for name, rows in npc_art.PORTRAITS.items():
        write_png(os.path.join(OUT, "portraits", name + ".png"), sheet([[lit(rows, 41)]], 32, 32))
    bubbles, shots, shadows = build_round()
    write_png(os.path.join(OUT, "ui", "bubbles.png"), bubbles)
    write_png(os.path.join(OUT, "sprites", "shot.png"), shots)
    for name, px in shadows.items():
        write_png(os.path.join(OUT, "sprites", name + ".png"), px)
    for name, px in hull_dungeon_art.build(lit, sheet).items():
        write_png(os.path.join(OUT, "dungeon", name + ".png"), px)
    for name, px in kiln_art.build(_lit_with(kiln_art), sheet).items():
        write_png(os.path.join(OUT, "kiln", name + ".png"), px)
    for name, px in mire_art.build(_lit_with(mire_art), sheet).items():
        write_png(os.path.join(OUT, "mire", name + ".png"), px)
    for name, px in verge_art.build(_lit_with(verge_art), sheet).items():
        write_png(os.path.join(OUT, "verge", name + ".png"), px)
    for name, px in ossuary_art.build(_lit_with(ossuary_art), sheet).items():
        write_png(os.path.join(OUT, "ossuary", name + ".png"), px)
    for name, px in gale_art.build(_lit_with(gale_art), sheet).items():
        write_png(os.path.join(OUT, "gale", name + ".png"), px)
    for name, px in glacier_art.build(_lit_with(glacier_art), sheet).items():
        write_png(os.path.join(OUT, "glacier", name + ".png"), px)
    for name, px in belfry_art.build(_lit_with(belfry_art), sheet).items():
        write_png(os.path.join(OUT, "belfry", name + ".png"), px)
    write_png(os.path.join(OUT, "tiles", "world.png"), build_tiles())
    import title_art
    write_png(os.path.join(OUT, "ui", "title_logo.png"), title_art.build_logo())
    write_png(os.path.join(OUT, "ui", "title_bg.png"), title_art.build_title_bg())
    write_png(os.path.join(OUT, "ui", "title_glow.png"), title_art.build_title_glow())
    import ui_art
    ui_art.build(sys.modules[__name__])
    import mantle_art
    mantle_art.build(sys.modules[__name__])
    font_px, font_fnt = build_font()
    write_png(os.path.join(OUT, "fonts", "tide.png"), font_px)
    write_text(os.path.join(OUT, "fonts", "tide.fnt"), font_fnt)
    write_tile_atlas_gd(os.path.join(ROOT, "scripts", "art", "tile_atlas.gd"))
    if CHECK_ONLY:
        if STALE:
            print("Out of date (run python3 tools/build_art.py):", ", ".join(STALE))
            sys.exit(1)
        print("Art is up to date.")
    else:
        print("Art written to", OUT)


if __name__ == "__main__":
    main()
