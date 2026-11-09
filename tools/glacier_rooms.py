#!/usr/bin/env python3
"""Hollow Glacier's room layouts (Frostspine's dungeon, caves worn through an
old glacier), kept in one place so the whole dungeon can be read and checked
together. Writes rooms/room_<x>_<y>.tscn.

Run from the repo root:  python3 tools/glacier_rooms.py
(--check only verifies that the committed rooms match.)

I is ice: Wren slides on it, and so do crates. Frost arrows freeze water
(~) into ice to walk on, a tile at a time, or a small pool all at once.

The way through:
  Entry -> Crevasse Hall (map; cross the ice bridge) -> west to the
  Bowyer's Cave (beat everything; the Frostfang Bow) -> east to the Black
  Pool (freeze a way out to the island; small key) -> unlock the Hall's
  hatch north into the Eye Gallery (open all three ice eyes at once; small
  key) -> unlock its east hatch into the Slide Hall (freeze the pool in the
  crate's way and slide it onto the plate; big key) -> the Gallery's great
  door -> Rimeback.
  Off the main path: the Frozen Pond west of the Entry (compass).
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEADER = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/room.gd" id="1_room"]

[node name="Room" type="Node2D"]
script = ExtResource("1_room")
"""

# The way out: Glacier Foot in Frostspine, just below its doorway.
OUTSIDE = {"door_to": "Vector2i(0, -3)", "door_spawn": "Vector2i(11, 2)"}


# coord: (name key, extra exports, layout)
ROOMS = {
    (32, 10): ("ROOM_GLACIER_ENTRY", OUTSIDE, """
###########..###########
#......................#
#..I.III......III.II...#
#.IIIIII......IIIIII...#
#..IIII........IIII....#
...........T...........#
.......................#
.......................#
#.....~~.......~~......#
#.....~~...a...~~......#
#......................#
#......................#
###########DD###########"""),
    (31, 10): ("ROOM_GLACIER_POND", {"chest_item": '"compass"'}, """
########################
#......................#
#.C....................#
#...IIIIIIIIIIIIIIII...#
#...IIIIIIIIIIIIIIII...#
#...II__IIIIII__IIII....
#...II__IIaIII__IIII....
#...IIIIIIIIIIIIIIII....
#...IIIIIIIIIIIIIIII...#
#...IIII__IIIIIIaIII...#
#...IIII__IIIIIIIIII...#
#......................#
########################"""),
    (32, 9): ("ROOM_GLACIER_HALL", {"chest_item": '"map"'}, """
###########XX###########
#......................#
#..C.......II..........#
#......................#
#__________II__________#
........................
........................
........................
#..a..............a....#
#......................#
#......................#
#......................#
###########..###########"""),
    (31, 9): ("ROOM_GLACIER_BOWYER", {"chest_item": '"frostfang_bow"', "gate": '"clear"', "chest_hidden": "true"}, """
########################
#......................#
#..~~~~..........~~~~..#
#..~~~~....C.....~~~~..#
#......................#
#.....................|.
#...a.......a.........|.
#.....................|.
#......................#
#...IIIIII....IIIIII...#
#...IIIaII....IIcIII...#
#......................#
########################"""),
    (33, 9): ("ROOM_GLACIER_POOL", {"chest_item": '"small_key"'}, """
########################
#......................#
#..~~~~~~~~~~~~~~~~~~..#
#..~~~~~~~~~~~~~~~~~~..#
#..~~~~~~.....~~~~~~~..#
...~~~~~~..C..~~~~~~~..#
...~~~~~~.....~~~~~~~..#
...~~~~~~~~~~~~~~~~~~..#
#..~~~~~~~~~~~~~~~~~~..#
#..~~~~~~~~~~~~~~~~~~..#
#..a...................#
#......................#
########################"""),
    (32, 8): ("ROOM_GLACIER_EYES", {"chest_item": '"small_key"', "gate": '"eyes"', "chest_hidden": "true"}, """
###########GG###########
#......................#
#.E..................E.#
#......................#
#...IIIIIIIIIIIIIIII...#
#...IIIIIIIIIIIIIIII...#
#...IIIIIIIIIIIIIIII...X
#...IIIIIIIIIIIIIIII...X
#...IIIIIIIIIIIIIIII...#
#......................#
#..........C...........#
#E.....................#
###########..###########"""),
    (33, 8): ("ROOM_GLACIER_SLIDE", {"chest_item": '"big_key"', "gate": '"plates"'}, """
########################
#...............#.C.#..#
#...............#...#..#
#...............#|||#..#
#..IIIIIIIIIIIIIIIIII..#
#..IIIIIIIIIIIIIIIIII..#
...IIIIKIII~~IIIII=....#
...IIIIIIII~~IIIIIIII..#
#..IIIIIIIIIIIIIIIIII..#
#..........a...........#
#......................#
#......................#
########################"""),
    (32, 7): ("ROOM_GLACIER_BOSS", OUTSIDE, """
########################
#......................#
#..IIIIIIIIIIIIIIIIII..#
#..I~~IIIIIIIIIIII~~I..#
#..I~~IIIIIIIIIIII~~I..#
#..IIIIIIIIIIIIIIIIII..#
#..IIIIIIIIVIIIIIIIII..#
#..IIIIIIIIIIIIIIIIII..#
#..I~~IIIIIIIIIIII~~I..#
#..I~~IIIIIIIIIIII~~I..#
#..IIIIIIIIIIIIIIIIII..#
#......................#
###########..###########"""),
}


def scene(coord):
    name_key, extra, layout = ROOMS[coord]
    rows = [r for r in layout.strip().split("\n")]
    assert len(rows) == 13, (coord, len(rows))
    for r in rows:
        assert len(r) == 24, (coord, r, len(r))
    text = HEADER + 'name_key = "%s"\nbiome = "glacier"\ndungeon = "glacier"\n' % name_key
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
        print("Out of date (run python3 tools/glacier_rooms.py):", ", ".join(stale))
        sys.exit(1)
    print("Glacier rooms up to date." if check else "Glacier rooms written.")


if __name__ == "__main__":
    main()
