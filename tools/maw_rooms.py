#!/usr/bin/env python3
"""The Maw's room layouts (the last dungeon: inside the Old One's head,
where the Choir sings), kept in one place so the whole dungeon can be read
and checked together. Writes rooms/room_<x>_<y>.tscn.

Run from the repo root:  python3 tools/maw_rooms.py
(--check only verifies that the committed rooms match.)

"," is the palate floor: the Old One's breathing floods it (deep water)
and drains it again on one clock for the whole Maw (see MawBreath). Every
tool Wren has found is needed somewhere.

The way through:
  The Throat (entry) -> the Palate (map) -> west to the Hollows (hook
  across the gap; small key) -> east to the Dim Gallery (light the four
  braziers, crossing the veiled planks by lantern light; big key) -> the
  Palate's north hatch into the Veins (compass) -> the great door -> the
  Choir Loft, Cantor Vael -> the Dreaming Heart.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEADER = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/room.gd" id="1_room"]

[node name="Room" type="Node2D"]
script = ExtResource("1_room")
"""

# The way out: Lullaby Point, just below the Old One's lip.
OUTSIDE = {"door_to": "Vector2i(2, 1)", "door_spawn": "Vector2i(11, 5)"}


# coord: (name key, extra exports, layout)
ROOMS = {
    (44, 10): ("ROOM_MAW_THROAT", OUTSIDE, """
###########..###########
#......................#
#..x................x..#
#......................#
#,,,,,,,,,,,,,,,,,,,,,,#
#,,,,,,,,,,,,,,,,,,,,,,#
#,,,,,,,,,,,,,,,,,,,,,,#
#,,,,,,,,,,,,,,,,,,,,,,#
#......................#
#..##..............##..#
#..##..............##..#
#......................#
###########DD###########"""),
    (44, 9): ("ROOM_MAW_PALATE", {"chest_item": '"map"'}, """
###########XX###########
#......................#
#..C...................#
#......................#
#....##..........##....#
........................
........................
........................
#....##..........##....#
#......................#
#..........M...........#
#......................#
###########..###########"""),
    (43, 9): ("ROOM_MAW_HOLLOWS", {"chest_item": '"small_key"'}, """
########################
#.....______...........#
#.....______...........#
#.....______...........#
#.....______...........#
#.C..O______............
#.....______............
#.....______O...........
#.....______...........#
#.....______...x.......#
#.....______...........#
#.....______...........#
########################"""),
    (45, 9): ("ROOM_MAW_LANTERNS", {"chest_item": '"big_key"', "gate": '"braziers"', "chest_hidden": "true"}, """
########################
#.............___......#
#..j..........___...j..#
#.............___......#
#.............___......#
..............___......#
..............vvv...C..#
..............___......#
#.............___......#
#.......q.....___......#
#..j..........___...j..#
#.............___......#
########################"""),
    (44, 8): ("ROOM_MAW_GALLERY", {"chest_item": '"compass"'}, """
###########GG###########
#......................#
#..C...................#
#......................#
#,,,,,,,,,,,,,,,,,,,,,,#
#,,,,,,,,,,,,,,,,,,,,,,#
#,,,,,,,,,,,,,,,,,,,,,,#
#......M...............#
#......................#
#..##..............##..#
#..##......U.......##..#
#......................#
###########..###########"""),
    (44, 7): ("ROOM_MAW_VAEL", {"gate": '"clear"'}, """
###########||###########
#......................#
#......................#
#...##............##...#
#..........V...........#
#......................#
#......................#
#......................#
#...##............##...#
#......................#
#......................#
#......................#
###########..###########"""),
    (44, 6): ("ROOM_MAW_HEART", {}, """
########################
#......................#
#......................#
#..........V...........#
#......................#
#......................#
#......................#
#......................#
#......................#
#......................#
#......................#
#......................#
###########..###########"""),
}


def scene(coord):
    name_key, extra, layout = ROOMS[coord]
    rows = [r for r in layout.strip().split("\n")]
    assert len(rows) == 13, (coord, len(rows))
    for r in rows:
        assert len(r) == 24, (coord, r, len(r))
    text = HEADER + 'name_key = "%s"\nbiome = "maw"\ndungeon = "maw"\n' % name_key
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
        print("Out of date (run python3 tools/maw_rooms.py):", ", ".join(stale))
        sys.exit(1)
    print("Maw rooms up to date." if check else "Maw rooms written.")


if __name__ == "__main__":
    main()
