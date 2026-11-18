"""Store images (Steam capsules and library art, the itch.io cover) from
the title art, with no new art.

    python3 tools/store_art.py [out_dir]     (default: store/art)

Each image is the title backdrop (assets/ui/title_bg.png) scaled by a whole
number with nearest-neighbour, so every pixel stays square, then cropped to
the size Steam asks for. The LEVIATHAN logo (assets/ui/title_logo.png) goes
over the sky at the largest whole scale that fits. Images that Steam says
must carry no text (library hero, page background) get no logo; the
library logo is the logo alone on transparency.
"""

import math
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "assets", "ui", "title_bg.png")
LOGO = os.path.join(ROOT, "assets", "ui", "title_logo.png")

# name: (width, height, focus_x, focus_y, logo).
# focus_x/focus_y: which point of the backdrop (0..1) the crop centres on,
# as far as the edges allow. logo: (max share of width, top of logo as a
# share of height), or None.
SIZES = {
    "header_capsule": (920, 430, 0.6, 0.56, (0.85, 0.01)),
    "small_capsule": (462, 174, 0.676, 0.567, (0.62, 0.01)),
    "main_capsule": (1232, 706, 0.6, 0.6, (0.85, 0.04)),
    "vertical_capsule": (748, 896, 0.82, 0.62, (0.9, 0.06)),
    "library_capsule": (600, 900, 0.835, 0.62, (0.9, 0.06)),
    "library_header": (920, 430, 0.6, 0.56, (0.85, 0.01)),
    "library_hero": (3840, 1240, 0.5, 0.62, None),
    "page_background": (1438, 810, 0.6, 0.5, None),
    "community_icon": (184, 184, 0.86, 0.66, None),
    "itch_cover": (630, 500, 0.79, 0.62, (0.8, 0.05)),
}
LIBRARY_LOGO = (1280, 720)


def scaled(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


def crop_to(img, w, h, fx, fy):
    left = min(max(round(img.width * fx - w / 2), 0), img.width - w)
    top = min(max(round(img.height * fy - h / 2), 0), img.height - h)
    return img.crop((left, top, left + w, top + h))


def build(name, w, h, fx, fy, logo_spec, bg, logo):
    k = math.ceil(max(w / bg.width, h / bg.height))
    if name == "community_icon":
        k = 2  # the creature's head breaking the water
    out = crop_to(scaled(bg, k), w, h, fx, fy)
    if logo_spec:
        share, top = logo_spec
        lk = max(1, int(w * share // logo.width))
        big = scaled(logo, lk)
        out.alpha_composite(big, ((w - big.width) // 2, round(h * top)))
    return out


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "store", "art")
    os.makedirs(out_dir, exist_ok=True)
    bg = Image.open(BG).convert("RGBA")
    logo = Image.open(LOGO).convert("RGBA")
    for name, (w, h, fx, fy, spec) in SIZES.items():
        img = build(name, w, h, fx, fy, spec, bg, logo)
        img.convert("RGB").save(os.path.join(out_dir, "%s_%dx%d.png" % (name, w, h)))
    w, h = LIBRARY_LOGO
    lk = max(1, min(w // logo.width, h // logo.height))
    big = scaled(logo, lk)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.alpha_composite(big, ((w - big.width) // 2, (h - big.height) // 2))
    canvas.save(os.path.join(out_dir, "library_logo_%dx%d.png" % (w, h)))
    print("Store images in %s" % out_dir)


if __name__ == "__main__":
    main()
