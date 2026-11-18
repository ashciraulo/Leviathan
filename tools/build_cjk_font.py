#!/usr/bin/env python3
"""Builds Tide's CJK companions: assets/fonts/tide_<lang>.fnt + .png.

Tide (tools/font_glyphs.py) draws Latin and Cyrillic by hand. Chinese,
Japanese and Korean have thousands of letters, so they come from Fusion
Pixel 10px (SIL OFL 1.1, tools/fonts/), one variant per language so each
gets its own regional letter shapes. Only the letters that language's
column of locale/strings.csv uses are baked, with the same dark outline as
Tide, into a BMFont that settings.gd hangs behind Tide as a fallback.

Run it after changing zh_CN, ja or ko text:

    pip install fonttools brotli pillow
    python3 tools/build_cjk_font.py

tools/check_strings.py fails if a letter is missing from these fonts.
"""
import csv
import io
import os
import sys

from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from font_glyphs import GLYPHS  # noqa: E402

# Column of strings.csv -> (Fusion Pixel variant, output name).
LANGS = {
    "zh_CN": ("sc", "tide_zh_CN"),
    "ja": ("jp", "tide_ja"),
    "ko": ("kr", "tide_ko"),
}
BODY, EDGE = (0xFF, 0xF4, 0xD6, 255), (0x2A, 0x1E, 0x36, 255)
CLEAR = (0, 0, 0, 0)
# Fusion Pixel 10px: 100 font units per pixel, baseline 8 px below the
# top of its 10-row box (9 rows above the baseline, 1 below; the top row is
# almost always empty). Tide's baseline is row 8 of its 11-pixel line with
# the outline, so a CJK letter's top row lines up one pixel above Tide's
# capitals and its outline pokes one pixel above the line box, as Tide's
# accents do.
SIZE, ASCENT, ROWS = 10, 8, 10
CELL_W, CELL_H, PER_ROW = 12, 13, 32


def column_letters(code):
    with open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f))
    if code not in rows[0]:
        return []
    col = rows[0].index(code)
    used = {ch for row in rows[1:] for ch in row[col]}
    return sorted(ch for ch in used if ch not in GLYPHS and ch not in "\n\t" and ord(ch) > 0x7F)


def load(variant):
    path = os.path.join(HERE, "fonts", "fusion-pixel-10px-proportional-%s.woff2" % variant)
    font = TTFont(path)
    font.flavor = None
    buf = io.BytesIO()
    font.save(buf)
    buf.seek(0)
    cmap = font.getBestCmap()
    return ImageFont.truetype(buf, SIZE), cmap, font["hmtx"], font["head"].unitsPerEm


def raster(pil_font, ch, width):
    """The letter as rows of '#'/'.', ROWS tall and width wide."""
    img = Image.new("1", (width + 4, ROWS + 4), 0)
    draw = ImageDraw.Draw(img)
    draw.fontmode = "1"
    # anchor "ls": left edge, baseline. Baseline sits ASCENT rows down.
    draw.text((2, 2 + ASCENT), ch, font=pil_font, fill=1, anchor="ls")
    return ["".join("#" if img.getpixel((x + 2, y + 2)) else "." for x in range(width)) for y in range(ROWS)]


def build(code):
    variant, name = LANGS[code]
    letters = column_letters(code)
    pil_font, cmap, hmtx, upem = load(variant)
    missing = [ch for ch in letters if ord(ch) not in cmap]
    if missing:
        sys.exit("%s: Fusion Pixel has no %s" % (code, " ".join(missing)))
    rows = max(1, (len(letters) + PER_ROW - 1) // PER_ROW)
    px = [[CLEAR] * (CELL_W * PER_ROW) for _ in range(CELL_H * rows)]
    lines = []
    for i, ch in enumerate(letters):
        adv = round(hmtx[cmap[ord(ch)]][0] * SIZE / upem)
        glyph = raster(pil_font, ch, adv)
        # Fusion Pixel leaves an empty column on the right of each letter
        # for spacing. Tide spaces letters with their outline instead (the
        # advance is width + 2), so drop that column. Narrow punctuation
        # keeps the rest of its box, so it still takes its usual room.
        gw = adv - 1 if adv > 1 and all(r[adv - 1] == "." for r in glyph) else adv
        assert gw + 2 <= CELL_W, ch
        ox, oy = (i % PER_ROW) * CELL_W, (i // PER_ROW) * CELL_H
        on = {(x, y) for y, r in enumerate(glyph) for x, c in enumerate(r[:gw]) if c == "#"}
        for x, y in on:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if (x + dx, y + dy) not in on:
                        px[oy + 1 + y + dy][ox + 1 + x + dx] = EDGE
        for x, y in on:
            px[oy + 1 + y][ox + 1 + x] = BODY
        # Row 0 of the glyph sits one pixel above Tide's first row
        # (yoffset -1 for the glyph, -2 counting the outline).
        lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=-1 yoffset=-1 xadvance=%d page=0 chnl=15"
                     % (ord(ch), ox, oy, gw + 2, ROWS + 2, gw + 2))
    header = [
        'info face="Tide %s" size=11 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0' % code,
        "common lineHeight=11 base=8 scaleW=%d scaleH=%d pages=1 packed=0" % (CELL_W * PER_ROW, CELL_H * rows),
        'page id=0 file="%s.png"' % name,
        "chars count=%d" % len(letters),
    ]
    out = os.path.join(ROOT, "assets", "fonts")
    import build_art  # for its PNG writer
    build_art.write_png(os.path.join(out, name + ".png"), px)
    with open(os.path.join(out, name + ".fnt"), "w", encoding="utf-8") as f:
        f.write("\n".join(header + lines) + "\n")
    print("%s: %d letters -> assets/fonts/%s.fnt" % (code, len(letters), name))


def main():
    with open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf-8", newline="") as f:
        header = next(csv.reader(f))
    for code in LANGS:
        if code in header:
            build(code)


if __name__ == "__main__":
    main()
