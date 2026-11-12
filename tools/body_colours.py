#!/usr/bin/env python3
"""Works out each sprite sheet's body colour ahead of time.

When a foe falls, bits of it fly off in its own body colour (Enemy.body_colour):
the most common colour on its sheet, outline, eyes and glints aside. Working
that out in the game means reading the texture back from the GPU, which takes
about a quarter of a second in the web build, right at the moment of a kill.
So this tool works it out from the PNGs instead, for every sheet handed to
Art.sprite(), and writes scripts/enemies/body_colours.gd.

    python3 tools/body_colours.py          # write it
    python3 tools/body_colours.py --check  # fail if it's out of date
"""
import os
import re
import struct
import sys
import zlib

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "scripts", "enemies", "body_colours.gd")
# The same thresholds as Enemy.body_colour's own reading of the pixels.
MIN_ALPHA = 0.5
MIN_LUMA = 0.18
MAX_LUMA = 0.92


def read_png(path):
    """(width, height, rows of (r, g, b, a) bytes) of an 8-bit RGBA PNG."""
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos = 8
    idat = b""
    width = height = 0
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if depth != 8 or colour != 6 or interlace != 0:
                return None
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
    raw = zlib.decompress(idat)
    stride = width * 4
    rows = []
    prev = bytearray(stride)
    i = 0
    for _ in range(height):
        kind = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - 4] if x >= 4 else 0
            b = prev[x]
            c = prev[x - 4] if x >= 4 else 0
            if kind == 1:
                line[x] = (line[x] + a) & 255
            elif kind == 2:
                line[x] = (line[x] + b) & 255
            elif kind == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[x] = (line[x] + pred) & 255
        rows.append(bytes(line))
        prev = line
    return width, height, rows


def body_colour(path):
    """The colour most of the sheet's body is, as Enemy.body_colour finds it:
    the first of the most common, reading row by row."""
    png = read_png(path)
    if png is None:
        return None
    width, height, rows = png
    counts = {}
    for row in rows:
        for x in range(width):
            r, g, b, a = row[x * 4:x * 4 + 4]
            if a / 255.0 < MIN_ALPHA:
                continue
            luma = 0.2126 * r / 255.0 + 0.7152 * g / 255.0 + 0.0722 * b / 255.0
            if luma < MIN_LUMA or luma > MAX_LUMA:
                continue
            key = (r, g, b, a)
            counts[key] = counts.get(key, 0) + 1
    best = None
    most = 0
    for key, n in counts.items():
        if n > most:
            most = n
            best = key
    return best


def sheets():
    """res:// paths of every sheet handed to Art.sprite() by name."""
    consts = {}
    calls = set()
    for folder, _, files in os.walk(os.path.join(ROOT, "scripts")):
        for name in files:
            if not name.endswith(".gd"):
                continue
            text = open(os.path.join(folder, name), encoding="utf-8").read()
            for const, path in re.findall(r'const (\w+) := preload\("(res://[^"]+\.png)"\)', text):
                consts.setdefault(const, set()).add(path)
            calls.update(re.findall(r"Art\.sprite\(\s*(?:\w+\.)?(\w+)\s*,", text))
    found = set()
    for const in calls:
        for path in consts.get(const, ()):
            found.add(path)
    return sorted(found)


def build():
    lines = [
        "class_name BodyColours",
        "## Each sprite sheet's body colour (see Enemy.body_colour), worked out",
        "## from the PNGs by tools/body_colours.py so the game never has to read",
        "## a texture back from the GPU when a foe falls. RGBA, for Color.hex().",
        "## Generated: don't edit.",
        "",
        "const COLOURS := {",
    ]
    for path in sheets():
        colour = body_colour(os.path.join(ROOT, path[len("res://"):]))
        if colour is None:
            continue
        lines.append('\t"%s": 0x%02x%02x%02x%02x,' % ((path,) + colour))
    lines.append("}")
    return "\n".join(lines) + "\n"


def main():
    text = build()
    if "--check" in sys.argv:
        current = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        if current != text:
            print("scripts/enemies/body_colours.gd is out of date: run python3 tools/body_colours.py")
            sys.exit(1)
        print("Body colours up to date (%d sheets)." % (text.count("\n") - 8))
        return
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print("Wrote %s (%d sheets)." % (os.path.relpath(OUT, ROOT), text.count("\n") - 8))


if __name__ == "__main__":
    main()
