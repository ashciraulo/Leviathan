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


def advances():
    widths = {}
    for line in open(FNT, encoding="utf-8"):
        m = re.match(r"char id=(\d+) .*xadvance=(-?\d+)", line)
        if m:
            widths[chr(int(m.group(1)))] = int(m.group(2))
    return widths


def line_count(text, width, widths):
    def w(s):
        return sum(widths.get(c, 11) for c in s)
    lines, cur = 1, ""
    for word in text.split(" "):
        trial = word if cur == "" else cur + " " + word
        if w(trial) <= width or cur == "":
            cur = trial
        else:
            lines += 1
            cur = word
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
CELL_LIMITS = {"PROGRESS_UNDERWAY": 34, "PROGRESS_DONE": 34, "PROGRESS_SHARDS": 42,
    "PROGRESS_STONES": 44, "PROGRESS_GLASS": 40, "PROGRESS_CHESTS": 46}
REGION_LIMIT = 114  # progress_page.gd NAME_W


def check(code):
    rows = read_rows()
    col = rows[0].index(code)
    widths = advances()
    bad, long = [], []
    for row in rows[1:]:
        key, en, tr = row[0], row[1], row[col]
        if sorted(TOKEN.findall(en)) != sorted(TOKEN.findall(tr)):
            bad.append("%s: tokens %s vs %s" % (key, TOKEN.findall(en), TOKEN.findall(tr)))
        limit = CELL_LIMITS.get(key, REGION_LIMIT if key.startswith("REGION_") else 0)
        if limit and sum(widths.get(c, 11) for c in tr) > limit:
            bad.append("%s: wider than its %d px menu cell: %s" % (key, limit, tr))
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


def check_all():
    """Every translation's errors (for tools/check.sh); English included for the menu cells."""
    return max([check(code) for code in read_rows()[0][1:]] or [0])


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
