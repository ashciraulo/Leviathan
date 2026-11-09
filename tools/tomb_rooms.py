#!/usr/bin/env python3
"""The Marrow Tomb's room layouts (the Ossuary Dunes' dungeon, a barrow dug
among the bones of the Old One's kin), kept in one place so the whole
dungeon can be read and checked together. Writes rooms/room_<x>_<y>.tscn.

Run from the repo root:  python3 tools/tomb_rooms.py
(--check only verifies that the committed rooms match.)

% is a bone barricade and $ a hidden bone wall (drawn just like the wall
round it): the Echo Horn's note brings both down. Z is a singing skull,
M a Marrowguard (its bone shield turns the sword from the front; the horn
shatters it), U the Hush (unseen and untouchable till an echo shows it).

The way through:
  Entry -> Hall of Ribs (map) -> west to the Horn Crypt (beat the
  Marrowguards; the Echo Horn) -> the horn brings down the Hall's north
  barricade -> the Echo Chamber (wake all three skulls at once; small key)
  -> its west wall is hidden bone: the Forgotten Ossuary behind it
  (compass) -> the Hall's east hatch into the Bone Pit (big key) -> the
  Chamber's great door -> the Hollow Regent.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEADER = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/room.gd" id="1_room"]

[node name="Room" type="Node2D"]
script = ExtResource("1_room")
"""

# The way out: the Barrow Mouth in the Ossuary Dunes, just below its doorway.
OUTSIDE = {"door_to": "Vector2i(9, 0)", "door_spawn": "Vector2i(12, 7)"}


# coord: (name key, extra exports, layout)
ROOMS = {
    (40, 10): ("ROOM_TOMB_ENTRY", OUTSIDE, """
###########..###########
#......................#
#..##..............##..#
#..##..............##..#
#......................#
#......................#
#..........M...........#
#......................#
#......................#
#..##..............##..#
#..##..............##..#
#......................#
###########DD###########"""),
    (40, 9): ("ROOM_TOMB_HALL", {"chest_item": '"map"'}, """
###########%%###########
#......................#
#..C...................#
#......#........#......#
#......#........#......#
.......................X
.......................X
.......................X
#......#........#......#
#......#........#......#
#..................M...#
#......................#
###########..###########"""),
    (39, 9): ("ROOM_TOMB_CRYPT", {"chest_item": '"echo_horn"', "gate": '"clear"', "chest_hidden": "true"}, """
########################
#......................#
#..##..............##..#
#..##......C.......##..#
#......................#
#.....................|.
#.....M.........M.....|.
#.....................|.
#......................#
#..##......M.......##..#
#..##..............##..#
#......................#
########################"""),
    (40, 8): ("ROOM_TOMB_ECHO", {"chest_item": '"small_key"', "gate": '"skulls"', "chest_hidden": "true"}, """
###########GG###########
#......................#
#......Z...............#
#..................Z...#
#......................#
$..........C...........#
$......................#
$......................#
#..........U...........#
#......................#
#..........Z...........#
#......................#
###########..###########"""),
    (39, 8): ("ROOM_TOMB_HIDDEN", {"chest_item": '"compass"'}, """
########################
#......................#
#..C...................#
#......................#
#..##..........##......#
#..##...U......##.......
#.......................
#...............U.......
#..##..........##......#
#..##..........##......#
#......................#
#......................#
########################"""),
    (41, 9): ("ROOM_TOMB_PIT", {"chest_item": '"big_key"', "gate": '"clear"', "chest_hidden": "true"}, """
########################
#......................#
#..................C...#
#......##......##......#
#......##......##......#
.|.....................#
.|.........M...U.......#
.|.....................#
#......##......##......#
#......##......##......#
#..........M...........#
#......................#
###################$$###"""),
    # Optional: behind a concealed wall at the foot of the Bone Pit, an
    # ossuary only the Echo Horn opens, with the Abyssal Coat.
    (41, 10): ("ROOM_TOMB_OSSUARY", {"chest_item": '"abyssal"'}, """
###################..###
#......................#
#..##..............##..#
#..##..............##..#
#......................#
#......................#
#.......########.......#
#.......#......#.......#
#.......#..C...#...M...#
#.......#......#.......#
#.......###%%###.......#
#....M.................#
########################"""),
    (40, 7): ("ROOM_TOMB_BOSS", OUTSIDE, """
########################
#......................#
#......................#
#...##............##...#
#...##............##...#
#..........V...........#
#......................#
#......................#
#...##............##...#
#...##............##...#
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
    text = HEADER + 'name_key = "%s"\nbiome = "tomb"\ndungeon = "tomb"\n' % name_key
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
        print("Out of date (run python3 tools/tomb_rooms.py):", ", ".join(stale))
        sys.exit(1)
    print("Tomb rooms up to date." if check else "Tomb rooms written.")


if __name__ == "__main__":
    main()
