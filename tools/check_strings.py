"""Checks locale/strings.csv against the code.

    python3 tools/check_strings.py [-v]

Fails (exit 1) when a text key used in scripts or rooms has no English
string, a key is listed twice, a string is empty, or a string (in any
language) has a letter the Tide font can't draw. Also lists keys
that nothing seems to use (informational: some keys are built at runtime,
e.g. "ITEM_" + id).
"""

import csv
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY = re.compile(r'"([A-Z][A-Z0-9]*_[A-Z0-9_]+)"')
# Uppercase literals that are not text keys.
NOT_KEYS = {"KEY_ESCAPE"}


def csv_keys():
    keys, problems = {}, []
    with open(os.path.join(ROOT, "locale", "strings.csv"), newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    header = rows[0]
    for n, row in enumerate(rows[1:], start=2):
        if not row or not row[0]:
            continue
        key = row[0]
        if key in keys:
            problems.append("line %d: %s is listed twice" % (n, key))
        if len(row) < 2 or not row[1].strip():
            problems.append("line %d: %s has no English text" % (n, key))
        for col in range(2, len(header)):
            if col >= len(row) or not row[col].strip():
                problems.append("line %d: %s has no %s text" % (n, key, header[col]))
        keys[key] = row[1] if len(row) > 1 else ""
    return keys, problems


def missing_glyphs():
    """Letters in any column of strings.csv that the Tide font lacks."""
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    from font_glyphs import GLYPHS
    problems = []
    with open(os.path.join(ROOT, "locale", "strings.csv"), newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    header = rows[0]
    for n, row in enumerate(rows[1:], start=2):
        for col, text in enumerate(row[1:], start=1):
            # Godot skips columns headed "_..." (translator notes).
            if col < len(header) and header[col].startswith("_"):
                continue
            # "\n" in a cell is Godot's line break, not text.
            missing = sorted({ch for ch in text.replace("\\n", "") if ch not in GLYPHS and ch not in "\n\t"})
            if missing:
                lang = header[col] if col < len(header) else "column %d" % col
                problems.append("line %d: %s (%s) uses letters the font lacks: %s"
                                % (n, row[0], lang, " ".join("%s (U+%04X)" % (c, ord(c)) for c in missing)))
    return problems


def used_keys():
    used = {}
    for top in ("scripts", "rooms", "scenes"):
        for dirpath, _, files in os.walk(os.path.join(ROOT, top)):
            for name in files:
                if not name.endswith((".gd", ".tscn")):
                    continue
                path = os.path.join(dirpath, name)
                with open(path, encoding="utf-8") as f:
                    for n, line in enumerate(f, start=1):
                        for key in KEY.findall(line):
                            used.setdefault(key, "%s:%d" % (os.path.relpath(path, ROOT), n))
    return used


def main():
    keys, problems = csv_keys()
    problems += missing_glyphs()
    used = used_keys()
    for key, where in sorted(used.items()):
        # "ITEM_JAR_" + contents and the like: a prefix, not a key.
        if key.endswith("_"):
            continue
        if key not in keys and key not in NOT_KEYS:
            problems.append("%s: %s has no string in locale/strings.csv" % (where, key))
    unused = sorted(k for k in keys if k not in used)
    if unused:
        print("Keys with no literal use (fine if built at runtime): %d%s"
              % (len(unused), "" if "-v" in sys.argv else "  (-v lists them)"))
        if "-v" in sys.argv:
            for key in unused:
                print("  " + key)
    if problems:
        for p in problems:
            print("ERROR " + p)
        sys.exit(1)
    print("Strings OK: %d keys, %d used in code." % (len(keys), len(used)))


if __name__ == "__main__":
    main()
