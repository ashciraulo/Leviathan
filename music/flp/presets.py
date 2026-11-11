"""Finds Analog Lab preset candidates for each channel role, from a COPY of
Arturia's preset database (C:\\ProgramData\\Arturia\\Presets\\db.db3; reading
it in place gave disk I/O errors on Ash's PC, so copy it first).

    python3 music/flp/presets.py db.db3 --schema          # tables and columns
    python3 music/flp/presets.py db.db3 flute harp bell   # candidates per word

The schema is searched loosely (any table with a preset name column and an
instrument or type column), because Arturia changes it between versions.
Presets on the handoff's avoid list and old-version instruments are dropped;
ones that passed before are marked with *.
"""
from __future__ import annotations

import sqlite3
import sys

AVOID = {"Soft Velo Lead", "Classic Sine Lead", "Tranquility", "Solo Bow", "Conversation", "The Magic Whistle",
         "Sweet Lead", "Bass Head", "Shimmering Pad", "Tundra Sunrise", "Falling Pad", "Neglected Upright",
         "Dirty Bass CZ", "Home Bass", "Kalimbaya", "Vibrafaux", "Glass Guitar", "Japanese Home Clean",
         "Synthi Home Bass", "90s Mellow Pad", "Digital Nylon", "CS80 Jazz Guitar"}
OLD_ENGINES = ("Prophet V3", "Jup-8 V3", "CS-80 V3", "Stage-73 V", "Piano V", "B-3 V", "MiniFreak")
PASSED = {"Got Some Bass", "Electric Precision", "Upright Bass", "Orchid Rhodes", "Real Wurlie", "Rooftop EP",
          "A-4 EP", "Suitcase EP", "Studio Ballad Piano", "Jazz Organ 2", "Simple Sine", "Lonely Gordon",
          "Meadow Flute", "PW Pluck", "Wood Morning Mallet", "Analog Harp", "Cristal Marimba", "Full Stab",
          "13 Muted Clav", "Electric Pulse", "Dark Pad", "Nature Lands", "Obie Mello"}


def tables(db):
    out = {}
    for (name,) in db.execute("select name from sqlite_master where type in ('table','view')"):
        out[name] = [r[1] for r in db.execute(f"pragma table_info('{name}')")]
    return out


def search(db, word: str, limit: int = 40):
    found = []
    for table, cols in tables(db).items():
        name_col = next((c for c in cols if c.lower() in ("name", "preset_name", "presetname")), None)
        if not name_col:
            continue
        text_cols = [c for c in cols if any(k in c.lower() for k in ("name", "type", "instrument", "category",
                                                                       "subtype", "tag", "char"))]
        where = " or ".join(f"cast({c} as text) like ?" for c in text_cols)
        try:
            rows = db.execute(f"select * from '{table}' where {where} limit 500",
                              [f"%{word}%"] * len(text_cols)).fetchall()
        except sqlite3.Error:
            continue
        for row in rows:
            rec = dict(zip(cols, row))
            name = str(rec.get(name_col))
            blob = " ".join(str(v) for v in rec.values())
            if name in AVOID or any(e in blob for e in OLD_ENGINES):
                continue
            found.append((("*" if name in PASSED else " ") + name, table,
                          {k: v for k, v in rec.items() if k in text_cols and k != name_col and v}))
    seen, out = set(), []
    for f in found:
        if f[0] not in seen:
            seen.add(f[0])
            out.append(f)
    return out[:limit]


if __name__ == "__main__":
    db = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
    if "--schema" in sys.argv:
        for t, cols in tables(db).items():
            print(t, cols)
        sys.exit(0)
    for word in sys.argv[2:]:
        print(f"== {word}")
        for name, table, info in search(db, word):
            print(f"  {name}  [{table}] {info}")
