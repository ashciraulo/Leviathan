#!/usr/bin/env python3
"""Dungeon completeness check, read straight from rooms/*.tscn.

    python3 tools/dungeon_check.py          # print each dungeon's tally
    python3 tools/dungeon_check.py --check  # fail if a dungeon is missing
                                            # a piece (CI runs this from
                                            # tools/check.sh)

Every dungeon must have exactly one map, compass and big key chest, a big
door (G) for that key, a boss (V), its tool or story reward, and at least
as many small keys as rooms with locked hatches (X), since one key opens
every hatch in a room and any order of opening must still finish it.
"""

import glob
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DUNGEONS = ["hull", "kiln", "mire", "gale", "glacier", "belfry", "tomb", "maw"]
ONE_EACH = ["map", "compass", "big_key"]


def load():
    found = defaultdict(lambda: {"rooms": 0, "locks": 0, "keys": 0, "chests": defaultdict(int), "G": 0, "V": 0})
    for path in glob.glob(os.path.join(ROOT, "rooms", "room_*.tscn")):
        text = open(path).read()
        dungeon = re.search(r'^dungeon = "(.*?)"', text, re.M)
        if not dungeon:
            continue
        info = found[dungeon.group(1)]
        layout = re.search(r'^layout = "(.*?)"', text, re.M | re.S).group(1)
        item = re.search(r'^chest_item = "(.*?)"', text, re.M)
        item = item.group(1).replace('\\"', "") if item else "small_key"
        info["rooms"] += 1
        if "X" in layout:
            info["locks"] += 1
        for _ in range(layout.count("C")):
            info["chests"][item] += 1
            if item == "small_key":
                info["keys"] += 1
        info["G"] += 1 if "G" in layout else 0
        info["V"] += 1 if "V" in layout else 0
    return found


def main():
    check = "--check" in sys.argv
    found = load()
    problems = []
    for name in DUNGEONS:
        info = found.get(name)
        if not info:
            problems.append("%s: no rooms" % name)
            continue
        for item in ONE_EACH:
            if info["chests"][item] != 1:
                problems.append("%s: %d %s chests (want 1)" % (name, info["chests"][item], item))
        if info["G"] < 1:
            problems.append("%s: no big door (G)" % name)
        if info["V"] < 1:
            problems.append("%s: no boss (V)" % name)
        if info["keys"] < info["locks"]:
            problems.append("%s: %d small keys for %d locked rooms" % (name, info["keys"], info["locks"]))
        extras = sorted(k for k in info["chests"] if k not in ONE_EACH and k != "small_key")
        if not check:
            print("%-8s %2d rooms, %d keys / %d locks, also: %s" % (name, info["rooms"], info["keys"], info["locks"], ", ".join(extras) or "-"))
    if problems:
        print("Dungeon check failed:\n  " + "\n  ".join(problems))
        sys.exit(1)
    print("Dungeons complete: %d with map, compass, big key and enough small keys." % len(DUNGEONS))


if __name__ == "__main__":
    main()
