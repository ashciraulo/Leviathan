#!/usr/bin/env python3
"""The Kiln's room layouts (Cinderreach's dungeon, a ruined bell foundry),
kept in one place so the whole dungeon can be read and checked together.
Writes rooms/room_<x>_<y>.tscn.

Run from the repo root:  python3 tools/kiln_rooms.py
(--check only verifies that the committed rooms match.)

The way through:
  Entry -> Casting Floor -> west to the Mould Store (shove the crate onto
  the plate; map) -> down to the Bellows Room (beat everything, Clinkers
  flipped with the Tide Hook; the Stonebreaker Mallet) -> back to the
  Casting Floor and smash the boulders east -> Slag Pits (hammer the peg
  down; small key) -> north through more boulders into the Riser (climb
  ahead of the rising lava) -> Bell Loft (big key) -> back to the Casting
  Floor, hook across the lava to the locked hatch -> Pouring Gallery (time
  the drop hammers) -> great door -> the Slagwyrm.
  Off the main path: the Quench Room south of the Slag Pits (hook out to
  an island in the lava; a second small key) opens the Gallery's west hatch
  into the Pattern Shop (pegs; compass).

Until Cinderreach exists, the front door (and the way out after the boss)
leads back to Saltmarrow. The overworld thread will point them at the Kiln
Mouth screen.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEADER = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/room.gd" id="1_room"]

[node name="Room" type="Node2D"]
script = ExtResource("1_room")
"""

OUTSIDE = {"door_to": "Vector2i(0, 0)", "door_spawn": "Vector2i(4, 7)"}

# coord: (name key, extra exports, layout)
ROOMS = {
    (21, 10): ("ROOM_KILN_ENTRY", OUTSIDE, """
###########..###########
#......................#
#.^^^^............^^^^.#
#.^^^^............^^^^.#
#......................#
#...##..........##.....#
#...##.....T....##.....#
#......................#
#..c................c..#
#......................#
#......................#
#......................#
###########DD###########"""),
    (21, 9): ("ROOM_KILN_CASTING", {}, """
###########XX###########
#.......O..............#
#......................#
#^^^^^^^^^^^^^^^^^^^^^^#
#^^^^^^^^^^^^^^^^^^^^###
.....................Y..
...............O.....Y..
.....................Y..
#....................###
#..k...............c...#
#......................#
#......................#
###########..###########"""),
    (20, 9): ("ROOM_KILN_MOULDS", {"chest_item": '"map"', "gate": '"plates"'}, """
########################
#......................#
#..#####......u....u...#
#..#.C.|...............#
#..#####...............#
#.......................
#...........K...=.......
#.......................
#......................#
#....k...........s.....#
#..u..................u#
#......................#
###########..###########"""),
    (20, 10): ("ROOM_KILN_BELLOWS", {"chest_item": '"stonebreaker"', "gate": '"clear"', "chest_hidden": "true"}, """
###########..###########
#..........||..........#
#......................#
#..z..............z....#
#......................#
#....##..........##....#
#....##.....C....##....#
#......................#
#..k..............k....#
#......................#
#.....c........s.......#
#......................#
########################"""),
    (22, 9): ("ROOM_KILN_SLAG_PITS", {}, """
###########..###########
#.........#YY####...C..#
#................###i###
#......................#
#..z...z...z...z.......#
.......................#
.....k.........k.......#
.......................#
#......................#
#..^^^^^.......^^^^^...#
#..^^^^^.......^^^^^...#
#......................#
###########..###########"""),
    (22, 10): ("ROOM_KILN_QUENCH", {}, """
###########..###########
#..s................s..#
#..~~~~..........~~~~..#
#..~~~~......O...~~~~..#
#......................#
#^^^^^^^^^^^^^^^^^^^^^^#
#^^^^^^^^^^^^^^^^^^^^^^#
#^^^^^^^^......^^^^^^^^#
#^^^^^^^^..O...^^^^^^^^#
#^^^^^^^^......^^^^^^^^#
#^^^^^^^^.C....^^^^^^^^#
#^^^^^^^^^^^^^^^^^^^^^^#
########################"""),
    (22, 8): ("ROOM_KILN_RISER", {"lava_rise": "0.6", "lava_safe_row": "2"}, """
###########..###########
#......................#
#......................#
####################Y###
#......................#
#......................#
###Y####################
#......................#
#......................#
####################i###
#......................#
#......................#
###########..###########"""),
    (22, 7): ("ROOM_KILN_BELL_LOFT", {"chest_item": '"big_key"'}, """
########################
#......................#
#..~~..............~~..#
#..~~......C.......~~..#
#......................#
#....z............z....#
#......................#
#...k..............k...#
#......................#
#....##..........##....#
#......................#
#......................#
###########..###########"""),
    (21, 8): ("ROOM_KILN_GALLERY", {}, """
###########GG###########
#......................#
#......................#
#####z#####zz#####z#####
#......................#
X......................#
X...k..............k...#
X......................#
#......................#
#....##..........##....#
#....##..........##....#
#......................#
###########..###########"""),
    (20, 8): ("ROOM_KILN_PATTERNS", {"chest_item": '"compass"'}, """
########################
#......................#
#..u...............u...#
#.....#####i#####......#
#.....#.........#......#
#.....i....C....i.......
#.....#.........#.......
#.....#####i#####.......
#......................#
#...k..............k...#
#......................#
#..u..............u....#
########################"""),
    (21, 7): ("ROOM_KILN_BOSS", OUTSIDE, """
########################
#......................#
#......................#
#....~~~........~~~....#
#....~~~...V....~~~....#
#......................#
#......................#
#......................#
#....~~~........~~~....#
#....~~~........~~~....#
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
    text = HEADER + 'name_key = "%s"\nbiome = "kiln"\ndungeon = "kiln"\n' % name_key
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
        print("Out of date (run python3 tools/kiln_rooms.py):", ", ".join(stale))
        sys.exit(1)
    print("Kiln rooms up to date." if check else "Kiln rooms written.")


if __name__ == "__main__":
    main()
