#!/usr/bin/env python3
"""Wren concepts, round 3: lamp keeper variations (Ash picked the keeper).

Usage: python3 tools/wren_keepers.py out.png
"""

import sys

import build_art as art
import wren_round2 as r2  # noqa: F401  (registers the round 2 ramps)

art.RAMPS.update({
    "O": ["#FFF0A0", "#F7D66A", "#E0B040", "#A87A38", "#4E3426"],  # oilskin yellow
    "P": ["#B8A0D0", "#8E70B0", "#6B4E8E", "#4A3568", "#241A3A"],  # keeper's mantle
})
art.CASTS_SHADOW.update({"O", "P"})
art.TEXTURED.pop("R", None)  # oilskin and caps read better smooth

LEGS = art.LEGS["down_idle"]
LANTERN = [(15, 13, "A"), (16, 12, "AJA"), (17, 12, "AJA"), (18, 12, "AAA")]

DESIGNS = [
    ("1 Classic keeper", [
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
        "...qqqqqqqqqq...",
        "...bbbbbbbbbb...",
        "....pppppppp....",
        "....pppppppp....",
    ], LANTERN),
    ("2 Sou'wester", [
        "................",
        "......OOOO......",
        ".....OOOOOO.....",
        "....OOOOOOOO....",
        "..OOOOOOOOOOOO..",
        "...yywwwwwwyy...",
        "...ywwwwwwwwy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...OOOOOOOOOO...",
        "..OOOOOAOOOOOO..",
        "..OOOOOOOOOOOO..",
        "..wOOOOAOOOOOw..",
        "..OOOOOOOOOOOO..",
        "..OOOOOAOOOOOO..",
        "...OOOOOOOOOO...",
        "....pppppppp....",
    ], []),
    ("3 Lantern cape", [
        "................",
        ".....yyyyyy.....",
        "....yyyyyyyy....",
        "...yyyyyyyyyy...",
        "...yyyyyyyyyy...",
        "...yywwwwwwyy...",
        "...ywwwwwwwwy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "....wwwwwwww....",
        "..BBBwwwwwwBBB..",
        ".BBBBBBBBBBBBBB.",
        ".BBBBBBJJBBBBBB.",
        ".BBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBw..",
        "...jjjjjjjjjj...",
        "...bbbbbbbbbb...",
        "....jjjjjjjj....",
        "....pppppppp....",
    ], LANTERN),
    ("4 Cable knit", [
        "................",
        "................",
        ".....RRRRRR.....",
        "....RRRRRRRR....",
        "...RRRRRRRRRR...",
        "...RRRRRRRRRR...",
        "...hwwwwwwwwh...",
        "...hwewwwwewh...",
        "...hwewwwwewh...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...jjjjjjjjjj...",
        "..jjjjjjjjjjjj..",
        "..jjjjjjjjjjjj..",
        "..wjjjjjjjjjjw..",
        "..wbbbbbbbAbbw..",
        "...jjjjjjjAjj...",
        "....jjjjjjjj....",
        "....pppppppp....",
    ], []),
    ("5 Big coat", [
        "................",
        "........BBBB....",
        "......BBBBBBB...",
        ".....BBBBBBBBB..",
        "...BBBBBBBBBBB..",
        "...yywwwwwwyy...",
        "...ywwwwwwwwy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "....wwwwwwww....",
        "...jjwwwwwwjj...",
        "..BjjBBBBBBjjB..",
        ".BBBBBBBBBBBBBB.",
        ".BBBBBJBBJBBBBB.",
        ".BBBBBBBBBBBBBB.",
        ".BBBBBJBBJBBBBB.",
        ".BBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBB..",
        "..BBBBBBBBBBBB..",
    ], []),
    ("6 Lamp pack", [
        "......AAAA......",
        ".....AJJJJA.....",
        ".....AJJJJA.....",
        "......AAAA......",
        ".....yyyyyy.....",
        "....yyyyyyyy....",
        "...yywwwwwwyy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...bqqqqqqqqb...",
        "..wbRRRRRRRRbw..",
        "..wbqqqqqqqqbw..",
        "..wbRRRRRRRRbw..",
        "...bbbbbbbbbb...",
        "...pppppppppp...",
        "....pppppppp....",
        "....pppppppp....",
    ], []),
    ("7 Lens polisher", [
        "................",
        "................",
        ".....BBBBBB.....",
        "....BBBBBBBB....",
        "...AuuAAAAuuA...",
        "..BBBBBBBBBBBB..",
        "...hwwwwwwwwh...",
        "...hwewwwwewh...",
        "...hwewwwwewh...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...jjjjjjjjjj...",
        "..wjbbbbbbbbjw..",
        "..wjbbbbbbbbjw..",
        "..wjbbbbbbbbjw..",
        "...bbbbbbbbbb...",
        "...bbbbjjbbbb...",
        "....bbbbbbbb....",
        "....pppppppp....",
    ], []),
    ("8 Keeper's mantle", [
        "................",
        ".....hhhhhh.....",
        "....hhhhhhhh....",
        "...hhhhhhhhhh...",
        "...hhhhhhhhhh...",
        "...hhwwwwwwhh...",
        "...hwwwwwwwwh...",
        "...hwewwwwewh...",
        "...hwewwwwewh...",
        "....wwwwwwww....",
        "..PPPwwwwwwPPP..",
        ".PPPPPPPPPPPPPP.",
        ".PPPPPPAAPPPPPP.",
        ".PPPPPAJJAPPPPP.",
        ".PPPPPPAAPPPPPP.",
        ".PPPPPPPPPPPPPP.",
        ".PPPPPPPPPPPPPP.",
        "..PPPPPPPPPPPP..",
        "..PPPPPPPPPPPP..",
    ], [(19, 3, "PPPPPPPPPP"), (20, 4, "PPPPPPPP")]),
    ("9 Storm watch", [
        "................",
        "................",
        ".....jjjjjj.....",
        "....jjjjjjjj....",
        "...jjjjjjjjjj...",
        "..jjjjjjjjjjjj..",
        "...yywwwwwwyy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "...rrrrrrrrrr...",
        "...rrrrrrrrrr...",
        "...BBBBrrBBBB...",
        "..BBBBBrrBBBBB..",
        "..BBBBBBBBBBBB..",
        "..wBBJBBBBJBBw..",
        "..BBBBBBBBBBBA..",
        "..BBBBBBBBBBBA..",
        "...BBBBBBBBBBA..",
        "....pppppppp....",
    ], []),
    ("10 Tower stripes", [
        "................",
        "................",
        ".....RRRRRR.....",
        "....RRRRRRRR....",
        "...RRRRJJRRRR...",
        "..qqqqqqqqqqqq..",
        "...yywwwwwwyy...",
        "...ywewwwwewy...",
        "...ywewwwwewy...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...RRRRRRRRRR...",
        "..wqqqqqqqqqqw..",
        "..wRRRRRRRRRRw..",
        "..wqqqqqqqqqqw..",
        "...RRRRRRRRRR...",
        "...bbbbbbbbbb...",
        "....pppppppp....",
        "....pppppppp....",
    ], LANTERN),
    ("11 Naval keeper", [
        "................",
        "................",
        ".....qqqqqq.....",
        "....qqqqqqqq....",
        "...qqqqqqqqqq...",
        "...BBBBAABBBB...",
        "..BBBBBBBBBBBB..",
        "...hwewwwwewh...",
        "...hwewwwwewh...",
        "....wwwwwwww....",
        ".....wwwwww.....",
        "...BBBqqqqBBB...",
        "..BBBBBqqBBBBB..",
        "..wBBABBBBABBw..",
        "..wBBBBBBBBBBw..",
        "..wBBABBBBABBw..",
        "...bbbbbbbbbb...",
        "...BBBBBBBBBB...",
        "....pppppppp....",
    ], []),
    ("12 Night shift", [
        "................",
        ".....RRRRRR.....",
        "....RRRRRRRR....",
        "...RRRRRRRRRR...",
        "...RRRRAJARRR...",
        "...RRwwwwwwRR...",
        "...RwwwwwwwwR...",
        "...RwewwwwewR...",
        "...RwewwwwewR...",
        "...RRwwwwwwRR...",
        "....RRRRRRRR....",
        "...RRRRRRRRRR...",
        "..RRRRRAARRRRR..",
        "..RRRRRRRRRRRR..",
        "..wRRRRAARRRRw..",
        "..RRRRRRRRRRRR..",
        "...RRRRRRRRRR...",
        "....RRRRRRRR....",
        "....pppppppp....",
    ], []),
]


def render(top, overlays):
    rows = [list(r) for r in top + LEGS]
    for row, col, text in overlays:
        for i, ch in enumerate(text):
            if ch != ".":
                rows[row][col + i] = ch
    rows = ["".join(r) for r in rows]
    assert len(rows) == 24, len(rows)
    for r in rows:
        assert len(r) == 16, r
    return art.lit(rows, seed=7)


def main(out_path):
    from PIL import Image, ImageDraw  # preview only

    scale, cols = 6, 4
    cell_w, cell_h, label_h = 36, 30, 9
    nrows = (len(DESIGNS) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w * scale, nrows * (cell_h + label_h) * scale), (232, 200, 138, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (name, top, overlays) in enumerate(DESIGNS):
        px = render(top, overlays)
        img = Image.new("RGBA", (16, 24))
        img.putdata([p for row in px for p in row])
        cx, cy = (i % cols) * cell_w, (i // cols) * (cell_h + label_h)
        draw.text(((cx + 2) * scale, (cy + 1) * scale), name, fill=(62, 44, 74, 255), font_size=4 * scale)
        sheet.alpha_composite(img.resize((96, 144), Image.NEAREST), ((cx + 2) * scale, (cy + label_h) * scale))
        sheet.alpha_composite(img.resize((48, 72), Image.NEAREST), ((cx + 21) * scale, (cy + label_h + 12) * scale))
    sheet.save(out_path)
    print("Wrote", out_path)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "wren_keepers.png")
