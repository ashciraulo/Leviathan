#!/usr/bin/env python3
"""Alternative Wren designs for review. Writes a comparison sheet.

Usage: python3 tools/wren_options.py out.png
Each design reuses the lighting and outline rules from build_art.py.
The chosen design moves into build_art.py; the rest stay here as history.
"""

import sys

import build_art as art

art.RAMPS.update({
    "H": ["#9FD0E8", "#5F9FC4", "#2E6A8C", "#1F4366", "#121F38"],  # hooded cloak
    "O": ["#FFF0A0", "#F7D66A", "#E0B040", "#A87A38", "#4E3426"],  # oilskin yellow
    "l": ["#FFF4D6", "#F2D49A", "#D9AE6A", "#9E7450", "#4A2E2E"],  # sun-bleached hair
    "D": ["#8A7AAE", "#5E5088", "#3E3466", "#2A2448", "#140F24"],  # dark hair
    "v": ["#F2E3C6", "#D9C59E", "#B8A07A", "#86705A", "#3E2C2E"],  # canvas vest
})
art.CASTS_SHADOW.update({"H", "l", "D", "O"})


def sub(rows, mapping):
    return ["".join(mapping.get(c, c) for c in r) for r in rows]


def edit(rows, row, text):
    rows = list(rows)
    rows[row] = text
    return rows


# B: hooded wayfarer -------------------------------------------------------
B_HEAD_DOWN = [
    "................",
    ".....HHHHHH.....",
    "....HHHHHHHH....",
    "...HHHHHHHHHH...",
    "...HHHHHHHHHH...",
    "...HHwwwwwwHH...",
    "...HwwwwwwwwH...",
    "...HwewwwwewH...",
    "...HwewwwwewH...",
    "...HHwwwwwwHH...",
    "....HHHwwHHH....",
]
B_HEAD_UP = sub(art.HEAD_UP, {"y": "H", "w": "H"})
B_HEAD_SIDE = [
    "................",
    ".....HHHHHH.....",
    "....HHHHHHHH....",
    "...HHHHHHHHHH...",
    "...HHHHHHHHHH...",
    "...HHHHHHwwww...",
    "...HHHHHwwwwww..",
    "...HHHHHwwewww..",
    "...HHHHHwwwwww..",
    "...HHHHHHwwww...",
    "....HHHHHww.....",
]
B_TORSO_DOWN = [
    "...HHHHHHHHHH...",
    "..HHHHttttHHHH..",
    "..HHttttttttHH..",
    "..wHttttttttHw..",
    "..HHttttttttHH..",
    "..HbbbbbbbbbbH..",
    "..HHttttttttHH..",
    "...HHttttttHH...",
]
B_TORSO_UP = [
    "...HHHHHHHHHH...",
    "..HHHHHHHHHHHH..",
    "..HHHHHHHHHHHH..",
    "..wHHHHHHHHHHw..",
    "..HHHHHHHHHHHH..",
    "..HHHHHHHHHHHH..",
    "..HHHHHHHHHHHH..",
    "...HHHHHHHHHH...",
]
B_TORSO_SIDE = [
    "....HHHHHHH.....",
    "...HHHHHtttt....",
    "..HHHHHtttttt...",
    "..HHHHtttttt....",
    "..HHHHtttttt....",
    "..HHHbbbbbbb....",
    "..HHHHtttttt....",
    "...HHHtttttt....",
]

# C: fisher's oilskin, sun-bleached ponytail --------------------------------
C_HEAD_DOWN = sub(art.HEAD_DOWN, {"y": "l"})
C_HEAD_UP = edit(edit(sub(art.HEAD_UP, {"y": "l"}), 9, "....wllllllw...."), 10, ".....wwllww.....")
C_HEAD_SIDE = edit(edit(edit(sub(art.HEAD_SIDE, {"y": "l"}), 6, "..llllllwwwwww.."), 7, ".lllllllwwewww.."), 8, ".l.lllllwwwwww..")
C_TORSO = {
    "down": edit(sub(art.TORSO_DOWN, {"t": "O"}), 6, "...OOOOOOOOOO..."),
    "up": sub(art.TORSO_UP, {"t": "O"}),
    "side": sub(art.TORSO_SIDE, {"t": "O"}),
}
C_TORSO["down"] = edit(C_TORSO["down"], 3, "..wOOOOeOOOOOw..")

# D: diver with goggles and a canvas vest -----------------------------------
D_HEAD_DOWN = [
    "................",
    "................",
    ".....DDDDDD.....",
    "....DDDDDDDD....",
    "...DDvvvvvvDD...",
    "...DvWtvvtWvD...",
    "...DwwwwwwwwD...",
    "...DwewwwwewD...",
    "...DwewwwwewD...",
    "....wwwwwwww....",
    ".....wwwwww.....",
]
D_HEAD_UP = edit(sub(art.HEAD_UP, {"y": "D"}), 4, "...DvvvvvvvvvD..."[:16])
D_HEAD_UP = edit(D_HEAD_UP, 1, "................")
D_HEAD_SIDE = [
    "................",
    "................",
    ".....DDDDDD.....",
    "....DDDDDDDD....",
    "...DDDDvvvvvv...",
    "...DDDDDvWtvw...",
    "...DDDDwwwwwww..",
    "...DDDDwwwewww..",
    "...DDDDwwwwwww..",
    "....DDDwwwwww...",
    ".....DDwwww.....",
]
D_TORSO = {
    "down": [
        "....wwwwwwww....",
        "...vvvttttvvv...",
        "..wvvvttttvvvw..",
        "..wvvvttttvvvw..",
        "..wvvvttttvvvw..",
        "...bbbbbbbbbb...",
        "...vvvvvvvvvv...",
        "....tttttttt....",
    ],
    "up": [
        "....wwwwwwww....",
        "...vvvvvvvvvv...",
        "..wvvvvvvvvvvw..",
        "..wvvvvvvvvvvw..",
        "..wvvvvvvvvvvw..",
        "...bbbbbbbbbb...",
        "...vvvvvvvvvv...",
        "....tttttttt....",
    ],
    "side": [
        ".....wwwwww.....",
        "....vvvvtttt....",
        "....vvvvtttt....",
        "....vvvvtttt....",
        "....vvvvtttt....",
        "....bbbbbwbb....",
        "....vvvvvvvv....",
        ".....tttttt.....",
    ],
}
D_LEGS = {k: [r.replace("p", "w") if i == 1 else r for i, r in enumerate(v)] for k, v in art.LEGS.items()}

DESIGNS = [
    ("A  Scarf (current)", art.HEAD_DOWN, art.HEAD_SIDE, art.HEAD_UP,
     {"down": art.TORSO_DOWN, "side": art.TORSO_SIDE, "up": art.TORSO_UP}, art.LEGS),
    ("B  Hooded wayfarer", B_HEAD_DOWN, B_HEAD_SIDE, B_HEAD_UP,
     {"down": B_TORSO_DOWN, "side": B_TORSO_SIDE, "up": B_TORSO_UP}, art.LEGS),
    ("C  Fisher's oilskin", C_HEAD_DOWN, C_HEAD_SIDE, C_HEAD_UP, C_TORSO, art.LEGS),
    ("D  Pearl diver", D_HEAD_DOWN, D_HEAD_SIDE, D_HEAD_UP, D_TORSO, D_LEGS),
]


def frame(head, torso, legs, leg_key, bob=0):
    rows = head + torso + legs[leg_key]
    assert len(rows) == 24, len(rows)
    if bob:
        rows = rows[bob:] + ["................"] * bob
    return art.lit(rows, seed=7)


def main(out_path):
    from PIL import Image, ImageDraw  # preview only

    scale, gap = 6, 6
    columns = 6
    cell_w, cell_h = 16 + gap, 24 + gap
    label_h = 12
    width = columns * cell_w + gap
    height = len(DESIGNS) * (cell_h + label_h) + gap
    sheet = Image.new("RGBA", (width * scale, height * scale), (232, 200, 138, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (name, hd, hs, hu, torso, legs) in enumerate(DESIGNS):
        frames = [
            frame(hd, torso["down"], legs, "down_idle"),
            frame(hd, torso["down"], legs, "down_a", 1),
            frame(hs, torso["side"], legs, "side_idle"),
            frame(hs, torso["side"], legs, "side_a", 1),
            frame(hu, torso["up"], legs, "down_idle"),
            art.flip(frame(hs, torso["side"], legs, "side_idle")),
        ]
        y0 = gap + i * (cell_h + label_h)
        draw.text((gap * scale, y0 * scale), name, fill=(62, 44, 74, 255),
                  font_size=7 * scale) if hasattr(draw, "text") else None
        for j, px in enumerate(frames):
            img = Image.new("RGBA", (16, 24))
            img.putdata([p for row in px for p in row])
            img = img.resize((16 * scale, 24 * scale), Image.NEAREST)
            sheet.alpha_composite(img, ((gap + j * cell_w) * scale, (y0 + label_h) * scale))
    sheet.save(out_path)
    print("Wrote", out_path)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "wren_options.png")
