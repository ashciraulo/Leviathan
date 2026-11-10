#!/usr/bin/env python3
"""How long Leviathan takes to play, by region and dungeon.

Measured, from real play:
    python3 tools/playtime.py leviathan-file1-2026-11-12.json [more.json ...]
Each save keeps a hidden record of the time spent (and deaths) in every
region and dungeon (GameState.area_stats). Export a file from the file
select (Export) after playing, or point this at the save files in the
game's user folder (save_0.json ...). With several files, each area shows
the average over the files that reached it.

Estimated, from the content alone (no saves needed):
    python3 tools/playtime.py --estimate
Counts every room's enemies, chests, puzzle pieces and bosses, and the
words of dialogue, and prices them with the rates below. It is a model,
not a measurement: once real times exist, the report shows how far off the
model is for each area, so the rates can be tuned.

Both print a table and the total against the 15-hour target. Standard
library only.
"""
import csv
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET_HOURS = 15.0

# Seconds, for a first-time player. Tune these against measured times.
RATES = {
    "overworld_room": 25.0,  # crossing a screen, looking around
    "dungeon_room": 40.0,    # reading a room, finding the way on
    "enemy": 5.0,
    "chest": 12.0,
    "sea_glass": 10.0,
    "puzzle_piece": 15.0,    # each plate, crate, post, valve, eye...
    "boss": 240.0,
    "dungeon_backtrack": 1.5,  # keys, big key, map: rooms are crossed again
    "overworld_crossings": 2.0,  # each region is crossed again later (travel, side quests)
    "first_play": 1.25,      # deaths, wrong turns, menus
    "words_per_second": 3.0,  # reading dialogue
}

OVERWORLD_ENEMIES = set("csbmweqtgdA")
DUNGEON_ENEMIES = set("csbmwekqxaMU@&+")
DUNGEON_PUZZLE = set("=KOYizjvE<>RL|G%$Z")
# Text that isn't dialogue (menus, names, captions, hints).
NOT_DIALOGUE = ("OPT_", "FILES_", "TAB_", "HINT_", "ITEM_", "PAD_", "CAPTION_", "MAP_", "ROOM_",
                "JOURNEY_", "NAME_", "TITLE_", "GAME_", "KEY_", "SATCHEL_", "SHOP_", "CREDITS_", "TOAST_")


def area_of(biome: str, dungeon: str) -> str:
    """The same names the game uses (Audio.cue_for_room)."""
    return "dungeon_" + dungeon if dungeon else "region_" + biome


def read_rooms():
    rooms = []
    for path in sorted(glob.glob(os.path.join(ROOT, "rooms", "room_*.tscn"))):
        with open(path, encoding="utf-8") as f:
            text = f.read()
        biome = re.search(r'^biome = "([^"]*)"', text, re.M)
        dungeon = re.search(r'^dungeon = "([^"]*)"', text, re.M)
        layout = re.search(r'^layout = "(.*?)"', text, re.M | re.S)
        rooms.append({
            "biome": biome.group(1) if biome else "saltmarrow",
            "dungeon": dungeon.group(1) if dungeon else "",
            "layout": layout.group(1) if layout else "",
        })
    return rooms


def estimate():
    areas = {}
    for room in read_rooms():
        area = area_of(room["biome"], room["dungeon"])
        tiles = room["layout"]
        if room["dungeon"]:
            cost = RATES["dungeon_room"]
            cost += sum(tiles.count(c) for c in DUNGEON_ENEMIES) * RATES["enemy"]
            cost += sum(tiles.count(c) for c in DUNGEON_PUZZLE) * RATES["puzzle_piece"]
            cost += tiles.count("C") * RATES["chest"]
            cost *= RATES["dungeon_backtrack"]
            cost += tiles.count("V") * RATES["boss"]
        else:
            cost = RATES["overworld_room"]
            cost += sum(tiles.count(c) for c in OVERWORLD_ENEMIES) * RATES["enemy"]
            cost += tiles.count("C") * RATES["chest"]
            cost += tiles.count("*") * RATES["sea_glass"]
            cost *= RATES["overworld_crossings"]
        entry = areas.setdefault(area, {"time": 0.0, "rooms": 0})
        entry["time"] += cost * RATES["first_play"]
        entry["rooms"] += 1
    words = 0
    with open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            key = row.get("keys", "")
            if key and not key.startswith(NOT_DIALOGUE):
                words += len(row.get("en", "").split())
    areas["story (reading dialogue)"] = {"time": words / RATES["words_per_second"], "rooms": 0, "words": words}
    return areas


def measured(paths):
    totals = {}
    for path in paths:
        with open(path, encoding="utf-8") as f:
            save = json.load(f)
        state = save.get("state", save)
        stats = state.get("area_stats", {})
        counted = 0.0
        for area, entry in stats.items():
            slot = totals.setdefault(area, {"time": 0.0, "deaths": 0.0, "files": 0})
            slot["time"] += float(entry.get("time", 0.0))
            slot["deaths"] += float(entry.get("deaths", 0))
            slot["files"] += 1
            counted += float(entry.get("time", 0.0))
        # Time played before the record started (a file from an older
        # version) belongs to no area, but still counts.
        rest = float(state.get("play_time", 0.0)) - counted
        if rest > 1.0:
            slot = totals.setdefault(UNCOUNTED, {"time": 0.0, "deaths": 0.0, "files": 0})
            slot["time"] += rest
            slot["files"] += 1
    for slot in totals.values():
        slot["time"] /= slot["files"]
        slot["deaths"] /= slot["files"]
    return totals


UNCOUNTED = "(before the record began)"


def hms(seconds: float) -> str:
    seconds = int(round(seconds))
    return "%d:%02d:%02d" % (seconds // 3600, seconds // 60 % 60, seconds % 60)


def main(argv) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if argv else 1
    model = estimate()
    if argv[0] == "--estimate":
        print("Estimated playtime: a model of a first play, not a measurement (see RATES in")
        print("tools/playtime.py). Side quests' legwork and puzzles that stump are only roughly in it.\n")
        print("%-28s %6s %10s" % ("area", "rooms", "time"))
        total = 0.0
        for area in sorted(model, key=lambda a: (a.startswith("story"), a)):
            entry = model[area]
            total += entry["time"]
            print("%-28s %6s %10s" % (area, entry["rooms"] or "", hms(entry["time"])))
        print("\n%-28s %6s %10s" % ("total", "", hms(total)))
        print("Target %.0f h: %s" % (TARGET_HOURS, "reached" if total >= TARGET_HOURS * 3600 else
                                     "%s short" % hms(TARGET_HOURS * 3600 - total)))
        return 0
    data = measured(argv)
    if not data or set(data) == {UNCOUNTED}:
        print("No playtime record in those files (saves from before the record started have none).")
        return 1
    print("Measured playtime from %d file(s), averaged over the files that reached each area." % len(argv))
    print("Reading conversations counts in the area where they happen (the model prices it apart).\n")
    print("%-28s %10s %7s %10s %7s" % ("area", "time", "deaths", "model", "x model"))
    total = 0.0
    for area in sorted(data):
        entry = data[area]
        total += entry["time"]
        guess = model.get(area, {}).get("time", 0.0)
        ratio = "%.2f" % (entry["time"] / guess) if guess else "-"
        print("%-28s %10s %7s %10s %7s" % (area, hms(entry["time"]), ("%.1f" % entry["deaths"]).rstrip("0").rstrip("."),
                                           hms(guess) if guess else "-", ratio))
    print("\n%-28s %10s" % ("total", hms(total)))
    print("Target %.0f h: %s" % (TARGET_HOURS, "reached" if total >= TARGET_HOURS * 3600 else
                                 "%s to go" % hms(TARGET_HOURS * 3600 - total)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
