#!/usr/bin/env python3
"""Lantern Mire's room layouts (Gloamfen's dungeon, a drowned lantern
shrine where families hung lights for their dead), kept in one place so the
whole dungeon can be read and checked together. Writes rooms/room_<x>_<y>.tscn.

Run from the repo root:  python3 tools/mire_rooms.py
(--check only verifies that the committed rooms match.)

The way through:
  Entry -> Mourners' Walk -> west to the Candle Store (crates onto both
  plates; small key) -> unlock the hatch north into the Moth Chapel (beat
  everything; the Glowmoth Lantern) -> back through the Walk, east into the
  Drowned Walk (dark; raise the lantern to bring the veiled planks back;
  map) -> north to the Hall of Braziers (dark; light all four; small key)
  -> back to the Chapel, unlock its west hatch into the Ossuary (dark,
  planks; big key) -> the Chapel's great door -> the Pale Congregation.
  Off the main path: the Grave Lamps south of the Drowned Walk (planks;
  compass).

The front door, and the way out after the boss, lead back to Gloamfen
(OUTSIDE below).
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEADER = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/room.gd" id="1_room"]

[node name="Room" type="Node2D"]
script = ExtResource("1_room")
"""

# Gloamfen isn't built yet: the overworld thread places the dungeon's
# doorway and this points at it (the room just south of the shrine's door,
# arriving below it).
OUTSIDE = {"door_to": "Vector2i(14, 4)", "door_spawn": "Vector2i(11, 5)"}
DARK = {"dark": "true"}

# coord: (name key, extra exports, layout)
ROOMS = {
    (25, 10): ("ROOM_MIRE_ENTRY", OUTSIDE, """
###########..###########
#......................#
#..l..............l....#
#......................#
#..~~~~~........~~~~~..#
#..~~~~~...T....~~~~~..#
#......................#
#......................#
#.....m.........m......#
#......................#
#..l..............l....#
#......................#
###########DD###########"""),
    (25, 9): ("ROOM_MIRE_HUB", {}, """
###########XX###########
#......................#
#..l....~~~~~~~~....l..#
#.......~~~~~~~~.......#
#......................#
....m..............m....
........................
........................
#......................#
#..~~~~..........~~~~..#
#..~~~~..o....o..~~~~..#
#......................#
###########..###########"""),
    (24, 9): ("ROOM_MIRE_CANDLES", {"gate": '"plates"'}, """
########################
#......................#
#..#####...............#
#..#.C.|.......K.......#
#..#####...............#
#.......................
#.......=.......=.......
#.......................
#......................#
#....K.................#
#..o...............o...#
#......................#
########################"""),
    (25, 8): ("ROOM_MIRE_CHAPEL", {"chest_item": '"glowmoth_lantern"', "gate": '"clear"', "chest_hidden": "true"}, """
###########GG###########
#......................#
#..l......~~~~......l..#
#.........~~~~.........#
#..x................x..#
X......................#
X..........C...........#
X......................#
#....s............s....#
#......................#
#..o......x.........o..#
#..........||..........#
###########..###########"""),
    (26, 9): ("ROOM_MIRE_DROWNED", dict(DARK, chest_item='"map"'), """
###########..###########
#~~~~~~~~~~..~~~~~~~~~~#
#~~~~~~~~~~vv~~~~~~~~~~#
#~~~~~~~~~~vv~~~~...~~~#
#~~~~~~~~~~vv~~~~.C.~~~#
.....~~~~......vv...~~~#
.....vvvv..q...vv...~~~#
.....~~~~......~~~~~~~~#
#~~~~~~~~~~vv~~~~~~~~~~#
#~~~~~~~~~~vv~~~~~~~~~~#
#~~~~~~~~~~vv~~~~~~~~~~#
#~~~~~~~~~~..~~~~~~~~~~#
###########..###########"""),
    (26, 8): ("ROOM_MIRE_BRAZIERS", dict(DARK, gate='"braziers"'), """
########################
#.........#..#.........#
#..j......#C.#......j..#
#.........#||#.........#
#......................#
#.....q..........q.....#
#......................#
#......~~~~~~~~~~......#
#......~~~~~~~~~~......#
#..j...............j...#
#......................#
#......................#
###########..###########"""),
    (26, 10): ("ROOM_MIRE_GRAVES", dict(DARK, chest_item='"compass"'), """
###########..###########
#......................#
#~~~~~~~~~~vv~~~~~~~~~~#
#~~~~~~~~~~vv~~~~~~~~~~#
#......................#
#..l..q..........q..l..#
#......................#
#~~~~vvvv~~~~~~~~~~~~~~#
#~~~~vvvv~~~~~~~~~~~~~~#
#......................#
#..o.......C.......o...#
#......................#
########################"""),
    (24, 8): ("ROOM_MIRE_OSSUARY", dict(DARK, chest_item='"big_key"'), """
########################
#......................#
#..~~~~~~~~~~~~~~~~~...#
#..~...............~...#
#..~....C..........v...#
#..~...............~....
#..~~~~~~~vv~~~~~~~~....
#.......................
#..q...............q...#
#......................#
#..o....x.....x.....o..#
#......................#
########################"""),
    (25, 7): ("ROOM_MIRE_BOSS", OUTSIDE, """
########################
#......................#
#..~~~............~~~..#
#..~~~............~~~..#
#......................#
#..........V...........#
#......................#
#......................#
#......................#
#..~~~............~~~..#
#..~~~............~~~..#
#......................#
###########..###########"""),
}


def scene(coord):
    name_key, extra, layout = ROOMS[coord]
    rows = [r for r in layout.strip().split("\n")]
    assert len(rows) == 13, (coord, len(rows))
    for r in rows:
        assert len(r) == 24, (coord, r, len(r))
    text = HEADER + 'name_key = "%s"\nbiome = "mire"\ndungeon = "mire"\n' % name_key
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
        print("Out of date (run python3 tools/mire_rooms.py):", ", ".join(stale))
        sys.exit(1)
    print("Mire rooms up to date." if check else "Mire rooms written.")


if __name__ == "__main__":
    main()
