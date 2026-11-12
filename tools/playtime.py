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
    # Each side-quest stop: a find, scale, stone or stake to reach (often a
    # detour into a side area), a villager on a quest's round (a trade,
    # a letter, an invitation) or a dungeon Tidestone to read again. Crossing the region itself is already in overworld_crossings
    # (and a puzzle cave's rooms in their own area), so this is only the
    # going back for it and the walk to hand it in. Kept low on purpose.
    "errand_stop": 60.0,
}

# StoryDirector tables whose every entry is one place a side quest sends
# Wren ({id: [room, tile]}).
ERRAND_TABLES = ("FINDS", "SHED_SCALES", "SIGNAL_STONES", "SURVEY_STAKES")

# Flags set by a conversation when a side quest's round brings Wren to a
# villager: the jam trade's hand-offs, Sorrel's three letters and the
# invitations for Hessa's lighting day and the parts for the lantern-boat
# (and the walk back to Gully with them). Each is one more villager to walk to.
DELIVERY_FLAG = re.compile(r'"((?:trade|letter|party|boat)_[a-z0-9_]+)"')
# Same prefixes, but no extra walk: Marga starts the trade (trade_jam) and
# asks for the pie (party_marga_ask) where Wren already stands, and Ottilie
# gives the rimefin along with her own invitation.
NOT_DELIVERIES = {"trade_jam", "party_marga_ask", "party_rimefin"}

# Minigames, by hand: what they take on a first play beyond the quest
# that opens them.
MINIGAMES = {
    # Ottilie's fishing book (FishingHole): about 8 catches to see a
    # frostperch and a glass eel, about 9 more before the Old Grey bites,
    # and about 40 casts for ten in a row at 4 in 5. About 60 casts at
    # 8 s each (the wait, the pull, the fish landing).
    "Ottilie's fishing book": 60 * 8.0,
    # Coralie's echo game (EchoGame): rounds of about 30 s, tunes of 3 to
    # 12 notes; about 12 rounds on the way to twelve.
    "Coralie's echo game": 12 * 30.0,
    # Not a minigame, but timed the same way: Hessa's walk out to Lullaby
    # Point (HessaWalker), four rooms at her pace with a word in three of
    # them, a few waits while Wren goes back for her, and the way home.
    "Hessa's walk": 4 * 60.0,
}

OVERWORLD_ENEMIES = set("csbmweqtgdA0a")
# Puzzle pieces out in the overworld (side areas and challenges); letters
# that mean a prop there (R, Z, L...) are left out. A run of veiled planks
# counts as one piece.
OVERWORLD_PUZZLE = set("=KOYjE|")
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
            # Solved once, not on every crossing.
            cost += sum(tiles.count(c) for c in OVERWORLD_PUZZLE) * RATES["puzzle_piece"]
            cost += RATES["puzzle_piece"] if "v" in tiles else 0.0
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
    stops = errand_stops()
    areas["side quests (legwork)"] = {"time": stops * RATES["errand_stop"] * RATES["first_play"], "rooms": 0}
    areas["minigames"] = {"time": sum(MINIGAMES.values()), "rooms": 0}
    return areas


def errand_stops() -> int:
    """Places side quests send Wren: entries in StoryDirector's errand tables,
    each villager on a quest's round (a conversation that sets a
    DELIVERY_FLAG), and each dungeon Tidestone for Hessa's Keepers' Round."""
    with open(os.path.join(ROOT, "scripts", "story", "story_director.gd"), encoding="utf-8") as f:
        director = f.read()
    stops = 0
    for table in ERRAND_TABLES:
        m = re.search(r"^const %s := \{(.*?)^\}" % table, director, re.M | re.S)
        assert m, "StoryDirector.%s not found: update ERRAND_TABLES" % table
        stops += len(re.findall(r'^\s*"[a-z0-9_]+":\s*\[', m.group(1), re.M))
    with open(os.path.join(ROOT, "scripts", "dialogue", "conversations.gd"), encoding="utf-8") as f:
        talks = f.read()
    deliveries = set()
    for m in re.finditer(r'"set":\s*\[([^\]]*)\]', talks):
        deliveries.update(DELIVERY_FLAG.findall(m.group(1)))
    stops += len(deliveries - NOT_DELIVERIES)
    # Hessa's Keepers' Round sends Wren back to every Tidestone. Out in the
    # overworld that's a Wayshell flight to a stone already woken, so only
    # the dungeon stones (no flying inside) count as a walk back.
    with open(os.path.join(ROOT, "scripts", "world", "tidestone.gd"), encoding="utf-8") as f:
        m = re.search(r"^const CARVINGS := \{(.*?)^\}", f.read(), re.M | re.S)
    assert m, "Tidestone.CARVINGS not found: update errand_stops"
    for x, y in re.findall(r"^\s*Vector2i\((-?\d+), (-?\d+)\)", m.group(1), re.M):
        path = os.path.join(ROOT, "rooms", "room_%s_%s.tscn" % (x, y))
        with open(path, encoding="utf-8") as f:
            if re.search(r'^dungeon = "[^"]+"', f.read(), re.M):
                stops += 1
    return stops


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
