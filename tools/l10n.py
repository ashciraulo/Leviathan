"""Moves one language's text in and out of locale/strings.csv.

    python3 tools/l10n.py export DIR             # English as DIR/en_NN.tsv chunks
    python3 tools/l10n.py import CODE DIR        # DIR/CODE_*.tsv -> column CODE
    python3 tools/l10n.py check CODE             # placeholders and box fit
    python3 tools/l10n.py check-all              # every language (tools/check.sh)

A chunk is plain "KEY<tab>text" lines, which are easier to translate and
review than the CSV. Import adds (or replaces) the CODE column and fails if
a key is missing, unknown or doubled.

Check compares every row with English: the same %s / %d / {key} tokens
must appear, and lines the dialogue box shows are wrapped with the Tide
font's widths to list those that need a third line (the box then splits
them over two pages, so these are warnings to tidy, not errors; the smoke
test fails on them). Wrapping here is an estimate; the smoke test measures
the real thing. Fixed-width menu cells (progress columns, region names) are
errors: MenuKit would cut the text short.
"""

import csv
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = os.path.join(ROOT, "locale", "strings.csv")
FNT = os.path.join(ROOT, "assets", "fonts", "tide.fnt")
TOKEN = re.compile(r"%[sd]|\{[a-z_0-9]+\}")
# DialogueBox: BOX 376 wide, PAD.x 8 a side, portrait indent 40.
BOX_WIDTH = 376 - 16 - 3  # a little tighter than the label, to be safe
PORTRAIT_WIDTH = BOX_WIDTH - 40
# Rough stand-in for a key name filled into {key}.
KEY_NAME = "Space"
# Keys that never reach the dialogue box (the smoke test's _menu_text, plus
# HUD and menu labels that have their own room).
MENU_PREFIXES = ("OPT_", "MENU_", "TAB_", "HINT_", "SATCHEL_", "MAP_", "FILES_", "PAD_",
    "PROGRESS_", "ROOM_", "NAME_", "ACTION_", "CREDITS_", "TOAST_", "CAPTION_", "DUNGEON_",
    "BOSS_", "JUMPER_", "TITLE_", "GAME_", "PAUSE_", "CONTROLS_", "JOURNEY_")
# Speakers with a portrait (dialogue keys start with the speaker's name).
NARRATION_PREFIXES = ("NARRATE_", "BELL_", "GOT_", "SIGN_", "STONE_", "ITEM_")


def read_rows():
    with open(CSV, newline="", encoding="utf-8") as f:
        return list(csv.reader(f))


def write_rows(rows):
    with open(CSV, "w", newline="", encoding="utf-8") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)


def advances(code=None):
    """Letter widths in Tide, plus its CJK companion for zh_CN, ja and ko."""
    widths = {}
    fonts = [FNT]
    cjk = os.path.join(ROOT, "assets", "fonts", "tide_%s.fnt" % code)
    if code and os.path.exists(cjk):
        fonts.append(cjk)
    for path in fonts:
        for line in open(path, encoding="utf-8"):
            m = re.match(r"char id=(\d+) .*xadvance=(-?\d+)", line)
            if m:
                widths.setdefault(chr(int(m.group(1))), int(m.group(2)))
    return widths


# Chinese characters and kana can break between any two letters, except
# that closing punctuation stays with the letter before it (and opening
# punctuation with the one after). Korean breaks at spaces like English.
HAN_KANA = "\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff"
CLOSE = "\u201d\u2019\u2014\u3041\u3043\u3045\u3047\u3049\u3063\u3083\u3085\u3087\u308e\u30a1\u30a3\u30a5\u30a7\u30a9\u30c3\u30e3\u30e5\u30e7\u30ee\u3001\u3002\uff0c\uff01\uff1f\uff1a\uff1b\u300d\u300f\uff09\u3011\u2026\u30fc\u3005\u309d\u309e\u30fd\u30fe!?.,:;)\u00bb"
OPEN = "\u201c\u2018\u300c\u300e\uff08\u3010(\u00ab"
UNIT = re.compile("[%s]?(?:[%s]|[^ %s%s]+?(?=[%s]|[ ]|$))[%s]*" % (OPEN, HAN_KANA, HAN_KANA, OPEN, HAN_KANA + OPEN, CLOSE))


def units(text):
    """The text cut where a line may break, each piece with the space before it."""
    out, pos = [], 0
    for word in text.split(" "):
        pieces = UNIT.findall(word) if re.search("[%s]" % HAN_KANA, word) else [word]
        if "".join(pieces) != word:
            pieces = [word]
        for n, piece in enumerate(pieces):
            out.append(((" " if out and n == 0 else ""), piece))
    return out


def line_count(text, width, widths, trailing=0):
    """Lines text wraps to. trailing: extra room a line needs past its last
    word when more text follows (MenuKit.draw_wrapped's Godot layout breaks
    once the following space no longer fits; checked against the game)."""
    def w(s):
        return sum(widths.get(c, 11) for c in s)
    lines, cur = 1, ""
    pieces = units(text)
    for n, (sep, piece) in enumerate(pieces):
        trial = piece if cur == "" else cur + sep + piece
        room = trailing if n < len(pieces) - 1 else 0
        if w(trial) + room <= width or cur == "":
            cur = trial
        else:
            lines += 1
            cur = piece
    return lines


def export(out):
    os.makedirs(out, exist_ok=True)
    rows = read_rows()[1:]
    for n in range(0, len(rows), 200):
        with open(os.path.join(out, "en_%02d.tsv" % (n // 200)), "w", encoding="utf-8") as f:
            for row in rows[n:n + 200]:
                f.write("%s\t%s\n" % (row[0], row[1]))


def import_(code, src):
    rows = read_rows()
    header = rows[0]
    keys = [r[0] for r in rows[1:]]
    text = {}
    for path in sorted(glob.glob(os.path.join(src, code + "_*.tsv"))):
        for n, line in enumerate(open(path, encoding="utf-8"), start=1):
            line = line.rstrip("\n")
            if not line.strip():
                continue
            if "\t" not in line:
                sys.exit("%s:%d: no tab" % (path, n))
            key, value = line.split("\t", 1)
            if key in text:
                sys.exit("%s:%d: %s twice" % (path, n, key))
            if key not in keys:
                sys.exit("%s:%d: unknown key %s" % (path, n, key))
            text[key] = value.strip()
    missing = [k for k in keys if not text.get(k)]
    if missing:
        sys.exit("%d keys missing, first: %s" % (len(missing), ", ".join(missing[:8])))
    if code in header:
        col = header.index(code)
    else:
        header.append(code)
        col = len(header) - 1
        for row in rows[1:]:
            row.append("")
    for row in rows[1:]:
        row[col] = text[row[0]]
    write_rows(rows)
    print("%s: %d rows" % (code, len(text)))


# Fixed-width menu cells: the text must be no wider than this (pixels), or
# MenuKit cuts it short with "..". Keep in step with progress_page.gd.
# Headers get the column width less one pixel, so neighbours never touch.
PROGRESS_COLUMNS = {"PROGRESS_UNDERWAY": 35, "PROGRESS_DONE": 36, "PROGRESS_SHARDS": 42,
    "PROGRESS_STONES": 45, "PROGRESS_GLASS": 36, "PROGRESS_CHESTS": 46}
CELL_LIMITS = {key: width - 1 for key, width in PROGRESS_COLUMNS.items()}
# The widest number each column shows (Completion totals), checked once.
PROGRESS_NUMBERS = {"PROGRESS_UNDERWAY": "36", "PROGRESS_DONE": "36/36", "PROGRESS_SHARDS": "12/12",
    "PROGRESS_STONES": "22/22", "PROGRESS_GLASS": "12/12", "PROGRESS_CHESTS": "126/126"}
REGION_LIMIT = 114  # progress_page.gd NAME_W
# The map's one-line info under the room name: map_page.gd INFO_PANEL width less 20.
for _key in ("MAP_STONE_ASLEEP", "MAP_STONE_NO_FLY_INSIDE", "MAP_STONE_NEED_WAYSHELL", "MAP_STONE_FLY",
        "MAP_YOU_ARE_HERE", "MAP_UNKNOWN_ROOM"):
    CELL_LIMITS[_key] = 368 - 20

# Two-line descriptions under a menu (MenuKit.draw_wrapped, max 2 lines): the
# 368 px info panels on Options, Controls, Satchel and Journey, and the
# narrower shop panel (shop_menu.gd INFO, 256 px) for what the shops sell.
WRAP_WIDE = 368 - 20
WRAP_SHOP = 256 - 20
SHOP_KEYS = ("ITEM_PUFFER_BOMBS_DESC", "ITEM_LAMP_OIL_DESC", "ITEM_JAR_POTION_DESC")


def wrap_limit(key):
    """The width a two-line description must fit, or 0 if the key isn't one."""
    if key.endswith("_INFO") or key in SHOP_KEYS:
        return WRAP_SHOP
    if key.endswith("_DESC") or key == "JOURNEY_SAVE_NOTE":
        return WRAP_WIDE
    return 0


def check(code):
    rows = read_rows()
    col = rows[0].index(code)
    widths = advances(code)
    bad, long = [], []
    for row in rows[1:]:
        key, en, tr = row[0], row[1], row[col]
        if sorted(TOKEN.findall(en)) != sorted(TOKEN.findall(tr)):
            bad.append("%s: tokens %s vs %s" % (key, TOKEN.findall(en), TOKEN.findall(tr)))
        limit = CELL_LIMITS.get(key, REGION_LIMIT if key.startswith("REGION_") else 0)
        if limit and sum(widths.get(c, 11) for c in tr) > limit:
            bad.append("%s: wider than its %d px menu cell: %s" % (key, limit, tr))
        wrap = wrap_limit(key)
        if wrap and line_count(tr, wrap, widths, widths.get(" ", 4)) > 2:
            bad.append("%s: more than two lines at %d px: %s" % (key, wrap, tr))
        if key.startswith(MENU_PREFIXES):
            continue
        shown = re.sub(r"\{[a-z_0-9]+\}", KEY_NAME, tr).replace("%s", "Wwwww").replace("%d", "00")
        portrait = not key.startswith(NARRATION_PREFIXES)
        lines = line_count(shown, PORTRAIT_WIDTH if portrait else BOX_WIDTH, widths)
        if lines > 2:
            long.append("%s (%d lines): %s" % (key, lines, tr))
    for b in bad:
        print("TOKENS " + b)
    for l in long:
        print("LONG   " + l)
    print("%s: %d errors, %d dialogue lines over two" % (code, len(bad), len(long)))
    return 1 if bad else 0


def check_numbers():
    widths = advances()
    bad = 0
    for key, number in PROGRESS_NUMBERS.items():
        if sum(widths.get(c, 11) for c in number) > PROGRESS_COLUMNS[key]:
            print("NUMBERS %s: %s is wider than its %d px column" % (key, number, PROGRESS_COLUMNS[key]))
            bad = 1
    return bad


def check_all():
    """Every translation's errors (for tools/check.sh); English included for the menu cells."""
    return max([check_numbers()] + [check(code) for code in read_rows()[0][1:]])


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "export":
        export(sys.argv[2])
    elif cmd == "import":
        import_(sys.argv[2], sys.argv[3])
    elif cmd == "check":
        sys.exit(check(sys.argv[2]))
    elif cmd == "check-all":
        sys.exit(check_all())
    else:
        sys.exit(__doc__)
