#!/usr/bin/env python3
"""The Drowned Belfry's room layouts (the Sunken Verge's dungeon, a sea-church
sunk under the bay), kept in one place so the whole dungeon can be read and
checked together. Writes rooms/room_<x>_<y>.tscn.

Run from the repo root:  python3 tools/belfry_rooms.py
(--check only verifies that the committed rooms match.)

Q is deep water: the Diver's Helm swims it and dives under it, and under
the sunken grates (L) that stand in it. "," is floor the water rises over:
deep while the Belfry's water is high, dry silt once a valve (R), in the
Valve Chamber or the Tolling Well, has let it down. Either valve turns it
back up again.

The way through:
  Entry -> Bell Court -> west to the Vestry (beat everything; the Diver's
  Helm) -> swim the Court east to the Cistern (dive under the grates to the
  island; small key) -> the Court's north landing (compass) and its hatch
  -> the Valve Chamber (map; let the water down) -> west to the Sunken
  Choir (push the crate across the drained floor onto the plate; small
  key) -> the Chamber's east hatch into the Ringers' Loft (dive under the
  grates again; glints) -> east into the Tolling Well (with the water down,
  push the crate round onto the plate; the bars open on the pool, and a
  dive under its grates reaches the big key; a valve of its own turns the
  water) -> the Chamber's great door -> Knell.
  Off the main path: the Drowned Nave west of the Entry (dive into the
  grate-roofed passage and wind through it, unable to surface, up to a
  sealed chamber; glints).
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEADER = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/room.gd" id="1_room"]

[node name="Room" type="Node2D"]
script = ExtResource("1_room")
"""

# The way out: Belfry Square in the Sunken Verge, just below its doorway.
OUTSIDE = {"door_to": "Vector2i(1, 3)", "door_spawn": "Vector2i(12, 8)"}


# @ is a Tollshell, the Belfry's own enemy (scripts/belfry/tollshell.gd).
# coord: (name key, extra exports, layout)
ROOMS = {
    (36, 10): ("ROOM_BELFRY_ENTRY", OUTSIDE, """
###########..###########
#......................#
#..QQQ............QQQ..#
#..QQQ............QQQ..#
#......................#
...........T...........#
.......................#
................@......#
#..QQ..............QQ..#
#..QQ..............QQ..#
#......................#
#......................#
###########DD###########"""),
    (36, 9): ("ROOM_BELFRY_COURT", {"chest_item": '"compass"'}, """
###########XX###########
#QQQQQQQQC.....QQQQQQQQ#
#QQQQQQQQ......QQQQQQQQ#
#QQQQQQQQ,,,,,,QQQQQQQQ#
#QQQQQQQQ,,,,,,QQQQQQ..#
.....QQQ,,,,,,,,QQQQQ...
.....QQQ,,,,,,,,QQQQQ...
.....QQQ,,,,,,,,QQQQQ...
#....QQQQQQQQQQQQQQQQ..#
#....QQQQQQQQQQQQQQQQQQ#
#..@.............QQQQQQ#
#................QQQQQQ#
###########..###########"""),
    (35, 9): ("ROOM_BELFRY_VESTRY", {"chest_item": '"divers_helm"', "gate": '"clear"', "chest_hidden": "true"}, """
########################
#......................#
#..QQQQ..........QQQQ..#
#..QQQQ....C.....QQQQ..#
#......................#
#.....................|.
#...c.......s.........|.
#.....................|.
#................@.....#
#...QQ....c.......QQ...#
#...QQ............QQ...#
#......................#
########################"""),
    (37, 9): ("ROOM_BELFRY_CISTERN", {"chest_item": '"small_key"'}, """
########################
#......................#
#......QQQQQQQQQQQQQQQ.#
#......QQQQQQLLLLLQQQQ.#
#......QQQQQQL...LQQQQ.#
.......QQQQQQL.C.LQQQQ.#
.......QQQQQQL...LQQQQ.#
.......QQQQQQLLLLLQQQQ.#
#......QQQQQQQQQQQQQQQ.#
#......QQQQQQQQQQQQQQQ.#
#..m...................#
#......................#
###################..###"""),
    # Optional: down through the Cistern's floor, a sunken undercroft. Only
    # the Diver's Helm crosses its pool, to the Nacre Buckler.
    (37, 10): ("ROOM_BELFRY_UNDERCROFT", {"chest_item": '"nacre_buckler"'}, """
###################..###
#QQQQQQQQQQQQQQQQQQ....#
#..QQQQQQQQQQQQQQQQ....#
#..QQQQQQQQQQQQQQQQ....#
#..QQQQQQQQQQQQQQQQ....#
#..QQQQQQQQQQQQQQQQ....#
#.C.QQQQQQQQQQQQQQQ....#
#..QQQQQQQQQQQQQQQQ....#
#..QQQQQQQQQQQQQQQQ....#
#..QQQQQQQQQQQQQQQQ.c..#
#..QQQQQQQQQQQQQQQQ....#
#QQQQQQQQQQQQQQQQQQ....#
########################"""),
    (36, 8): ("ROOM_BELFRY_VALVES", {"chest_item": '"map"'}, """
###########GG###########
#......................#
#......................#
#...C..........@.......#
#......................#
.......................#
.........R.............X
.......................X
#......@...............#
#..QQ..............QQ..#
#..QQ..............QQ..#
#......................#
###########..###########"""),
    (35, 8): ("ROOM_BELFRY_CHOIR", {"chest_item": '"small_key"', "gate": '"plates"'}, """
########################
#..C.#,,,,,,,,,,,,,,,..#
#....#,,,,,,,,,,,,,,,..#
#....|,,,,,,,,,,,,,,,..#
#....#,,,,,,,,,,,,,,,..#
#....#,,,,K,,,,,,,,,,...
#....#,,,,,,,,,,,,,,,...
######,,,,,,,,,=,,,,,...
#.....,,,,,,,,,,,,,,,..#
#.....,,,,,,,,,,,,,,,..#
#...........@..........#
#......................#
########################"""),
    (37, 8): ("ROOM_BELFRY_LOFT", {"chest_item": '"glint"', "chest_count": "50"}, """
########################
#......................#
#..QQQQQQQQQQQQQQQQQQ..#
#..QQQQQQQQQQLLLLLQQQ..#
#..QQQQQQQQQQL...LQQQ..#
#..QQQQQQQQQQL.C.LQQQ...
...QQQQQQQQQQL...LQQQ...
...QQQQQQQQQQLLLLLQQQ..#
#..QQQQQQQQQQQQQQQQQQ..#
#..QQQQQQQQQQQQQQQQQQ..#
#..........@...........#
#..c..............c....#
########################"""),
    (38, 8): ("ROOM_BELFRY_TOLLING_WELL", {"chest_item": '"big_key"', "gate": '"plates"'}, """
########################
#....#,,,,,,,,,#QQQQQQQ#
#....#,,,,,,,,,#QLLLLLQ#
#....#,,K,,,,,,#QL...LQ#
#....#,,,,,,,,,#QL.C.LQ#
......,,,,,,,,,|QL...LQ#
......,,,,,,,#,|QLLLLLQ#
#....#,,#,,,,,,#QQQQQQQ#
#.R..#,,,,,,,,,#QQQQQQQ#
#....#,,,,,,,=,#QQQQQQQ#
#....#,,,,,,,,,#QQQQQQQ#
#....#,,,,,,,,,#QQQQQQQ#
########################"""),
    (35, 10): ("ROOM_BELFRY_DROWNED_NAVE", {"chest_item": '"glint"', "chest_count": "100"}, """
########################
#....#######...........#
#.C..#######...........#
#....#######...........#
###LL#######...........#
###LL#######............
###LL#######............
###LLL######............
#####L######...........#
#####L##QQQQ...........#
#####LLLQQQQ...@.......#
########QQQQ...........#
########################"""),
    (36, 7): ("ROOM_BELFRY_BOSS", OUTSIDE, """
########################
#......................#
#QQQQQQQQQQQQQQQQQQQQQQ#
#QQQQQQQ........QQQQQQQ#
#QQQQQQQ........QQQQQQQ#
#QQQQQQQ...V....QQQQQQQ#
#QQQQQQQ........QQQQQQQ#
#QQQQQQQ........QQQQQQQ#
#QQQQQQQQQQQQQQQQQQQQQQ#
#QQQQQQQQQQQQQQQQQQQQQQ#
#QQQQQQQQQQQQQQQQQQQQQQ#
#......................#
###########..###########"""),
}


def scene(coord):
    name_key, extra, layout = ROOMS[coord]
    rows = [r for r in layout.strip().split("\n")]
    assert len(rows) == 13, (coord, len(rows))
    for r in rows:
        assert len(r) == 24, (coord, r, len(r))
    text = HEADER + 'name_key = "%s"\nbiome = "belfry"\ndungeon = "belfry"\n' % name_key
    for key, value in extra.items():
        text += "%s = %s\n" % (key, value)
    text += 'layout = "' + "\n".join(rows) + '"\n'
    return text


def check_joins():
    """Neighbouring rooms must open onto each other at the same tiles."""
    for (x, y), (_, _, layout) in ROOMS.items():
        rows = layout.strip().split("\n")
        east = ROOMS.get((x + 1, y))
        if east:
            other = east[2].strip().split("\n")
            for r in range(13):
                a, b = rows[r][23] != "#", other[r][0] != "#"
                assert a == b, ("east join", (x, y), r)
        south = ROOMS.get((x, y + 1))
        if south:
            other = south[2].strip().split("\n")
            for c in range(24):
                a, b = rows[12][c] != "#", other[0][c] != "#"
                assert a == b, ("south join", (x, y), c)


def main():
    check = "--check" in sys.argv
    check_joins()
    stale = []
    for coord in ROOMS:
        path = os.path.join(ROOT, "rooms", "room_%d_%d.tscn" % coord)
        text = scene(coord)
        if check:
            if not os.path.exists(path) or open(path).read() != text:
                stale.append(path)
        else:
            with open(path, "w") as f:
                f.write(text)
    if check and stale:
        print("Out of date (run python3 tools/belfry_rooms.py):", ", ".join(stale))
        sys.exit(1)
    print("Belfry rooms up to date." if check else "Belfry rooms written.")


if __name__ == "__main__":
    main()
