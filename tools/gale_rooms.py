#!/usr/bin/env python3
"""Gale Spire's room layouts (Windmere Heights' dungeon, a broken bell tower
open to the sky), kept in one place so the whole dungeon can be read and
checked together. Writes rooms/room_<x>_<y>.tscn.

Run from the repo root:  python3 tools/gale_rooms.py
(--check only verifies that the committed rooms match.)

North is up the tower. Holes in an upper floor drop Wren to the floor below
(falls_through), which is the quick way down.

The way through:
  Entry -> Fan Hall -> west to the Sail Loft (beat everything; the Kite
  Cloak) -> east to the Gust Gallery (glide the fan's wind over the drop;
  glints) -> east to the Lantern Span (walk the planks by lantern light,
  hook over the break to the post) -> north to the Weathercock Roost (hook
  up to the island, ride its stream west, hammer the pegs down; small key;
  the low streams blow home) -> unlock the Fan Hall's hatch north into the Bell Shaft ->
  east to the Weathervane Room (glide out to the island; small key) -> back
  through the Shaft, unlock its west hatch into the Rookery (two glides,
  the pillar catching you on the way; glints) -> north into the Bell Cage
  (three rides: up, across and down the fans' streams to the big key, and
  the long stream home) -> ride the Shaft's updraft to its top landing and
  the great door -> the Stormheron.
  Off the main path: the Rope Store west of the Entry (walk into the wind;
  compass); the Bellrope Walk east of the Entry (the stream runs on over
  the sky: fold the cloak over the island; glints). The Fan Hall's map is
  up a nook against the wind.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEADER = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/room.gd" id="1_room"]

[node name="Room" type="Node2D"]
script = ExtResource("1_room")
"""

# Windmere Heights isn't on main yet: the overworld thread places the
# tower's doorway and this points at it.
OUTSIDE = {"door_to": "Vector2i(5, -4)", "door_spawn": "Vector2i(11, 2)"}


def drops_to(coord, tile):
    return {"falls_through": "true", "fall_to": "Vector2i(%d, %d)" % coord, "fall_spawn": "Vector2i(%d, %d)" % tile}


# coord: (name key, extra exports, layout)
# & is a Puffwisp, the Spire's own enemy (scripts/gale/puffwisp.gd).
ROOMS = {
    (28, 10): ("ROOM_GALE_ENTRY", OUTSIDE, """
###########..###########
#......................#
#..u..............u....#
#......................#
#....##..........##....#
.....##.....T....##.....
........................
........................
#......................#
#..c...............&...#
#......................#
#......................#
###########DD###########"""),
    (27, 10): ("ROOM_GALE_STORE", {"chest_item": '"compass"'}, """
########################
#......................#
#..u....u.....u....u...#
#......................#
#..........&...........#
#.......................
#.C>....................
#.......................
#......................#
#.....b..........b.....#
#..u...............u...#
#......................#
########################"""),
    (28, 9): ("ROOM_GALE_FANS", {"chest_item": '"map"'}, """
###########XX###########
##C#...................#
##S#...................#
##.#.....o.......o.&...#
##.#...................#
........................
........................
........................
#......................#
#....u............u....#
#......................#
#......................#
###########..###########"""),
    (27, 9): ("ROOM_GALE_SAIL_LOFT", {"chest_item": '"kite_cloak"', "gate": '"clear"', "chest_hidden": "true"}, """
########################
#......................#
#..u..............u....#
#...............&......#
#...w.............w....#
#.....................|.
#..........C..........|.
#.....................|.
#....c.................#
#......................#
#..u..............u....#
#......................#
########################"""),
    (29, 9): ("ROOM_GALE_GUSTS", {"chest_item": '"glint"', "chest_count": "50"}, """
########################
#....______________....#
#....______________.....
#....______________.....
#....______________..C..
.....______________....#
....>______________....#
.....______________....#
#....______________<...#
#....______________....#
#....______________....#
#....______________..&.#
########################"""),
    (28, 8): ("ROOM_GALE_SHAFT", drops_to((28, 9), (11, 9)), """
###########GG###########
#####..............#####
#####..............#####
#...________________...#
#...________________...#
X...________________....
X...________________....
X...________________....
#...________________...#
#...________________...#
#...........N..........#
#......................#
###########..###########"""),
    (29, 8): ("ROOM_GALE_VANE", drops_to((29, 9), (21, 2)), """
########################
#....__________________#
#....__________________#
#....__________________#
#....________....._____#
.....________.....w____#
....>________..C.._____#
.....________....._____#
#....________<...._____#
#....__________________#
#....__________________#
#....__________________#
########################"""),
    (27, 8): ("ROOM_GALE_ROOKERY", dict(drops_to((27, 9), (11, 9)), chest_item='"glint"', chest_count="50"), """
###..###################
#....______________....#
#....______________.&..#
#...._____...._____....#
#.C.._____<..._____....#
#...._____...._____.....
#....____#....____<.....
#...._____...._____.....
#...>_____...._____....#
#...._____...._____....#
#....______________....#
#__________________....#
########################"""),
    (27, 7): ("ROOM_GALE_BELL_CAGE", dict(drops_to((27, 8), (2, 9)), chest_item='"big_key"'), """
########################
#...>______________....#
#...>______________....#
#__________________SSSS#
#______________________#
#______________________#
#______________________#
#______________________#
#NN....________________#
#......__________<.....#
#......__________<....C#
#......__________<.....#
###..###################"""),
    (29, 10): ("ROOM_GALE_BELLROPE_WALK", {"chest_item": '"glint"', "chest_count": "100"}, """
########################
#....__________________#
#....__________________#
#....______...C._______#
#....______....._______#
....>______....._______#
....>______....._______#
.....______....._______#
#....______<...._______#
#....______<..&._______#
#....__________________#
#....__________________#
########################"""),
    # East of the Gusts, the Lantern Span: a plank walk over the sky that
    # only the raised lantern shows, broken where the hook has to carry
    # Wren to a post; the low stream blows home. North to the Roost.
    (30, 9): ("ROOM_GALE_LANTERN_SPAN", {}, """
####################..##
#...________________...#
....________________...#
....________________...#
....________________...#
#...___________...__...#
#...vvvvvv_____.O.vv...#
#...___________...__...#
#...________________...#
#...________________..<#
#...________________..<#
#...________________...#
########################"""),
    # Above it, the Weathercock Roost: hook up to the island, ride its fans'
    # stream to the west ledge, hammer the pegs down to the key. The low
    # stream blows home.
    (30, 8): ("ROOM_GALE_ROOST", {"chest_item": '"small_key"'}, """
########################
#...._____...__________#
#...._____.O<__________#
#...._____..<__________#
#....__________________#
#....__________________#
#....__________________#
#iiii#_________________#
#....__________________#
#.C.._____......&......#
#>..._____.............#
#>..._____.............#
####################..##"""),
    (28, 7): ("ROOM_GALE_BOSS", OUTSIDE, """
########################
#________......________#
#________....S.________#
#______________________#
#....______________....#
#.r..______________..r.#
#...>___......#.___<...#
#....___<..N...>___....#
#_______........_______#
#_______...V...._______#
#_______........_______#
#_______........_______#
###########..###########"""),
}


def scene(coord):
    name_key, extra, layout = ROOMS[coord]
    rows = [r for r in layout.strip().split("\n")]
    assert len(rows) == 13, (coord, len(rows))
    for r in rows:
        assert len(r) == 24, (coord, r, len(r))
    text = HEADER + 'name_key = "%s"\nbiome = "gale"\ndungeon = "gale"\n' % name_key
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
        print("Out of date (run python3 tools/gale_rooms.py):", ", ".join(stale))
        sys.exit(1)
    print("Gale rooms up to date." if check else "Gale rooms written.")


if __name__ == "__main__":
    main()
