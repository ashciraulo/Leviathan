#!/usr/bin/env python3
"""Wren concepts, round 2: front views with very different silhouettes.

Usage: python3 tools/wren_round2.py out.png
Round 1 (tools/wren_options.py) shared one body template; these don't.
Picked concepts get full turnarounds (side, back, walk) next.
"""

import sys

import build_art as art

art.RAMPS.update({
    "h": ["#7A6A9E", "#544878", "#3A3058", "#261E3E", "#120C22"],  # dark hair
    "Y": ["#FFFFFF", "#ECE8F4", "#C8C0DC", "#8E84A8", "#3E3456"],  # storm-white hair
    "B": ["#8AA8E0", "#5A78C0", "#3A4E8E", "#26305E", "#141832"],  # navy
    "R": ["#FFB0A8", "#E8706E", "#C24452", "#7E2840", "#3A1230"],  # knit red
    "M": ["#FFE0A0", "#F0B860", "#D08A3A", "#8E5A30", "#4A2A22"],  # mustard knit
    "z": ["#C8E6A0", "#8CC07A", "#4E9060", "#2E5E4E", "#16302E"],  # kelp
    "i": ["#FFD8E0", "#F4A0B4", "#D86A8C", "#9A3E66", "#4A1A3A"],  # coral pink
    "F": ["#E0E8F0", "#A8B8CC", "#7A8CA8", "#4E5E7E", "#262E44"],  # shark grey
    "u": ["#E8FFFA", "#BDEFE6", "#8FD6CF", "#5FA8AE", "#2E5E6E"],  # glass rim
    "A": ["#FFF0A0", "#F2C85A", "#C8963A", "#8A5E2E", "#3E2622"],  # brass
})
art.FLAT["V"] = "#D8F4F0"  # glass interior
art.CASTS_SHADOW.update({"h", "Y", "R", "F", "B", "x", "i"})
art.TEXTURED.update({"M": 0.2, "R": 0.15, "z": 0.12})

LEGS = art.LEGS["down_idle"]

DESIGNS = [
    ("1 Sun hat", [
        "................",
        "......xxxx......",
        ".....xxxxxx.....",
        ".....xrrrrx.....",
        ".xxxxxxxxxxxxxx.",
        "..xxxxxxxxxxxx..",
        "...hhwwwwwwhh...",
        "...hwewwwwewh...",
        "...hwewwwwewh...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...rrrrrrrrrr...",
        "..rrrrrrrrrrrr..",
        "..wrqqqqqqqqrw..",
        "..wrqqqqqqqqrw..",
        "...rbbbbbbbbr...",
        "...rqqqqqqqqr...",
        "....qqqqqqqq....",
        "....pppppppp....",
    ]),
    ("2 Storm hair", [
        "....Y..YY..Y....",
        "...YYY.YY.YYY...",
        "..YYYYYYYYYYYY..",
        "...YYYYYYYYYY...",
        "..YBBBBBBBBBBY..",
        "...YwwwwwwwwY...",
        "...YwewwwwewY...",
        "...YwewwwwewY...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "......wwww......",
        "...BBBBBBBBBB...",
        "..wBBBjjjjBBBw..",
        "..wBBBjjjjBBBw..",
        "..wBBBjjjjBBBw..",
        "..wbbbbbbbbbbw..",
        "...BBBBBBBBBB...",
        "....BBBBBBBB....",
        "....pppppppp....",
    ]),
    ("3 Braid", [
        "................",
        ".....hhhhhh.....",
        "....hhhhhhhh....",
        "...hhhhhhhhhh...",
        "...hhhhwhhhhh...",
        "...hhwwwwwwhh...",
        "...hwwwwwwwwh...",
        "...hwewwwwewh...",
        "...hwewwwwewhh..",
        "....wwwwwwwwhh..",
        ".....wwwwww.hh..",
        "...MMMMMMMMhhM..",
        "..MMMMMMMMMhhM..",
        "..wMMMMMMMMhhw..",
        "..wMMMMMMMMMhw..",
        "..wMMMMMMMMMrw..",
        "...MMMMMMMMMM...",
        "....MMMMMMMM....",
        "....pppppppp....",
    ]),
    ("4 Bobble hat", [
        ".......qq.......",
        "......qqqq......",
        ".....RRRRRR.....",
        "....RRRRRRRR....",
        "...RRRRRRRRRR...",
        "...jjjjjjjjjj...",
        "...ywwwwwwwwy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...BBBBBBBBBB...",
        "..BBBBBJBBBBBB..",
        "..BBBBBBBBBBBB..",
        "..wBBBBJBBBBBw..",
        "..BBBBBBBBBBBB..",
        "..BBBBBJBBBBBB..",
        "..BBBBBBBBBBBB..",
        "...BBBBBBBBBB...",
    ]),
    ("5 Conch helm", [
        "........ss......",
        ".......sss......",
        ".....ssssss.....",
        "....ssssssss....",
        "...siiiiiiiis...",
        "...ssssssssss...",
        "...hwwwwwwwwh...",
        "...hwewwwwewh...",
        "...hwewwwwewh...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "..sssiiiiiisss..",
        "..ssiiiiiiiiss..",
        "..wiiiiiiiiiiw..",
        "..wiiiiiiiiiiw..",
        "...bbbbbbbbbb...",
        "...iiiiiiiiii...",
        "....iiiiiiii....",
        "....pppppppp....",
    ]),
    ("6 Lamp keeper", [
        "................",
        "................",
        ".....BBBBBB.....",
        "....BBBBBBBB....",
        "...BBBBJBBBBB...",
        "..BBBBBBBBBBBB..",
        "...yywwwwwwyy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...qqqqqqqqqq...",
        "..wBBBBBBBBBBw..",
        "..wqqqqqqqqqqw..",
        "..wBBBBBBBBBBw..",
        "..wqqqqqqqqqqw..",
        "...bbbbbbbbbb...",
        "....pppppppp....",
        "....pppppppp....",
    ]),
    ("7 Kelp poncho", [
        "................",
        ".....tttttt.....",
        "....tttttttt....",
        "...tttttttttt...",
        "..ttttttttttt...",
        "...ttwwwwwwtt...",
        "...twwwwwwwwt...",
        "...twewwwwewt...",
        "...twewwwwewt...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "....zzzzzzzz....",
        "...zzzzzzzzzz...",
        "..zzzzzzzzzzzz..",
        ".zzzzzzzzzzzzzz.",
        ".zzzzzzzzzzzzzz.",
        ".z.z.z.zz.z.z.z.",
        "....pppppppp....",
        "....pppppppp....",
    ]),
    ("8 Topknot", [
        "......hhhh......",
        ".....rrrrrr.....",
        ".....hhhhhh.....",
        "....hhhhhhhh....",
        "...hhhhhhhhhh...",
        "...hhwwwwwwhh...",
        "..rhwwwwwwwwhr..",
        "..rhwewwwwewhr..",
        "..rhwewwwwewhr..",
        "..r.wwwwwwww.r..",
        ".r...wwwwww...r.",
        "..qqqqqqqqqqqq..",
        ".qqqqqqqqqqqqqq.",
        ".qqqqqqqqqqqqqq.",
        ".wqqrrrrrrrrqqw.",
        "...qqqqqqqqqq...",
        "...qqqqqqqqqq...",
        "....qqqqqqqq....",
        "....pppppppp....",
    ]),
    ("9 Bubble helmet", [
        "................",
        ".....uuuuuu.....",
        "....uWWyyyyu....",
        "...uWyyyyyyyu...",
        "...uyyyyyyyyu...",
        "..uyywwwwwwyyu..",
        "..uywewwwwewyu..",
        "..uywewwwwewyu..",
        "..uVwwwwwwwwVu..",
        "...uVwwwwwwVu...",
        "...AAAAAAAAAA...",
        "..jjjjjjjjjjjj..",
        ".jjjjjjjjjjjjjj.",
        ".jjjjjjjjjjjjjj.",
        ".wjbbbbbbbbbbjw.",
        "..jjjjjjjjjjjj..",
        "...jjjjjjjjjj...",
        "....jjjjjjjj....",
        "....pppppppp....",
    ]),
    ("10 Shark hood", [
        ".......F........",
        "......FF........",
        ".....FFFFFF.....",
        "....FFFFFFFF....",
        "...FFFFFFFFFF...",
        "...FWFWFWFWFWF..",
        "...FwwwwwwwwF...",
        "...FwewwwwewF...",
        "...FwewwwwewF...",
        "...FFwwwwwwFF...",
        "....FFwwwwFF....",
        "...FFFFFFFFFF...",
        "..wFqqqqqqqqFw..",
        "..wFqqqqqqqqFw..",
        "..wFqqqqqqqqFw..",
        "...bbbbbbbbbb...",
        "...BBBBBBBBBB...",
        "....BBBBBBBB....",
        "....pppppppp....",
    ]),
    ("11 Long scarf", [
        "................",
        ".....yyyyyy.....",
        "....yyyyyyyy....",
        "...yyyyyyyyyy...",
        "...yyyyyyyyyy...",
        "...yyyyyyyyyy...",
        "...yywwwwwwyy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "...yywwwwwwyy...",
        "...rrrrrrrrrr...",
        "..rrrrrrrrrrrr..",
        "..wttttttttrrrr.",
        "..wttttttttrrw..",
        "...bbbbbbbbrr...",
        "...ttttttttrr...",
        "....tttttttrrr..",
        "....ppppppppr...",
        "....pppppppp....",
    ]),
    ("12 Coral crown", [
        "...i.i....i.i...",
        "...iii....iii...",
        "....iihhhhii....",
        "....hhhhhhhh....",
        "...hhhhhhhhhh...",
        "...hhwwwwwwhh...",
        "...hwwwwwwwwh...",
        "...hwewwwwewh...",
        "...hwewwwwewh...",
        "...hhwwwwwwhh...",
        "..hhhhwwwwhhhh..",
        "..hBBBBBBBBBBh..",
        "..hBBBBBBBBBBh..",
        "..wBBBBqqBBBBw..",
        "..wBBBBqqBBBBw..",
        "..BBBBBqqBBBBB..",
        "..BBBBBqqBBBBB..",
        "...BBBBqqBBBB...",
        "...qqqqqqqqqq...",
    ]),
]


def render(top):
    rows = top + LEGS
    assert len(rows) == 24, len(rows)
    for r in rows:
        assert len(r) == 16, r
    return art.lit(rows, seed=7)


def main(out_path):
    from PIL import Image, ImageDraw  # preview only

    scale, cols = 6, 4
    cell_w, cell_h, label_h = 36, 30, 9
    rows = (len(DESIGNS) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w * scale, rows * (cell_h + label_h) * scale), (232, 200, 138, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (name, top) in enumerate(DESIGNS):
        px = render(top)
        img = Image.new("RGBA", (16, 24))
        img.putdata([p for row in px for p in row])
        cx, cy = (i % cols) * cell_w, (i // cols) * (cell_h + label_h)
        draw.text(((cx + 2) * scale, (cy + 1) * scale), name, fill=(62, 44, 74, 255), font_size=4 * scale)
        # Big view plus the true in-game size (3x, as on a 1152x648 window).
        sheet.alpha_composite(img.resize((96, 144), Image.NEAREST), ((cx + 2) * scale, (cy + label_h) * scale))
        sheet.alpha_composite(img.resize((48, 72), Image.NEAREST), ((cx + 21) * scale, (cy + label_h + 12) * scale))
    sheet.save(out_path)
    print("Wrote", out_path)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "wren_round2.png")
