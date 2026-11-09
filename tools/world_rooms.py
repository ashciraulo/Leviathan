#!/usr/bin/env python3
"""World route check: walks the overworld the way a player would, gaining
each dungeon's item in turn, and reports which screens open at each stage.

    python3 tools/world_rooms.py          # print the route, stage by stage
    python3 tools/world_rooms.py --check  # fail on a soft-lock, an
                                          # unreachable screen or floor, or
                                          # dungeons opening out of order

It reads the room layouts straight from rooms/*.tscn (overworld rooms are
the ones with no `dungeon`), crosses screen edges where both sides are open,
and treats a doorway (D) whose door_to is a dungeon's entry room as that
dungeon: reaching it means Wren clears it and comes out with its item.
tools/check.sh runs every tools/*_rooms.py with --check, so CI runs this.

Item gates (keep in step with the game):
  Tide Hook        zips Wren in a straight line to a hook post (O) up to
                   HOOK_RANGE tiles away, over water, lava, gaps and floor
  Kite Cloak       glides up to GLIDE_TILES straight ahead over holes, lava,
                   water and low hazards (streams only blow in dungeons)
  Stonebreaker     breaks cracked boulders (Y)
  Glowmoth Lantern shows veiled planks (v)
  Frostfang Bow    freezes open water (~) into ice to walk on
  Diver's Helm     swims deep water (Q)
  (Q and bow freezing arrive with the Hollow Glacier PR. Props block one
  tile here; their real footprints can be wider, which only makes this
  check more generous, never stricter.)
  The seventh bell raises the Old One at Lullaby Point (alt_layout)
"""

import glob
import os
import re
import sys
from collections import deque

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
COLS, ROWS = 24, 13
HOOK_RANGE = 8
# KiteCloak: SPEED 95 px/s for GLIDE_TIME 0.75 s, so about four tiles of
# water with Wren's feet starting at the bank's edge. A glide
# that runs out over water drops Wren back where they took off, so water
# doesn't carry it any further.
GLIDE_TILES = 5
GLIDE_WATER_TILES = GLIDE_TILES

# Dungeon entry rooms (door_to) -> (name, the item Wren comes out with).
DUNGEONS = {
    (10, 10): ("Rotting Hull", "tide_hook"),
    (21, 10): ("Kiln", "stonebreaker"),
    (25, 10): ("Lantern Mire", "glowmoth_lantern"),
    (28, 10): ("Gale Spire", "kite_cloak"),
    (32, 10): ("Hollow Glacier", "frostfang_bow"),
    (36, 10): ("Drowned Belfry", "divers_helm"),
    (40, 10): ("Marrow Tomb", "tidebell_tomb"),
    (44, 10): ("The Maw", "the_end"),
}
ORDER = ["Rotting Hull", "Kiln", "Lantern Mire", "Gale Spire", "Hollow Glacier",
         "Drowned Belfry", "Marrow Tomb", "The Maw"]
START = ((0, 0), None)
# Solid scenery (Prop.KINDS with a footprint). N, the Old One's lip, has none.
PROPS = set("ouf nHLMWlRJZBUF".replace(" ", ""))
# Solid things that aren't scenery: stones, chests, hook posts, NPCs, and
# boulders, crates and hatches, which also stop the chain and the cloak.
BLOCKERS = set("TCOKXh123456k")


def stops_flight(tile):
    return tile == "#" or tile in PROPS or tile in BLOCKERS or tile == "Y"


def load_rooms():
    rooms = {}
    for path in glob.glob(os.path.join(ROOT, "rooms", "room_*.tscn")):
        text = open(path).read()
        if re.search(r'^dungeon = "[^"]+"', text, re.M):
            continue
        m = re.search(r"room_(-?\d+)_(-?\d+)\.tscn$", path)
        coord = (int(m.group(1)), int(m.group(2)))

        def field(name):
            f = re.search(r'^%s = "(.*?)"' % name, text, re.M | re.S)
            return f.group(1).split("\n") if f else None

        door = re.search(r"^door_to = Vector2i\((-?\d+), (-?\d+)\)", text, re.M)
        flag = re.search(r'^alt_flag = "(.*?)"', text, re.M)
        rooms[coord] = {
            "layout": field("layout"),
            "alt": field("alt_layout"),
            "alt_flag": flag.group(1) if flag else "",
            "door_to": (int(door.group(1)), int(door.group(2))) if door else None,
            "name": os.path.basename(path),
        }
    return rooms


def rows_for(room, items):
    if room["alt"] and room["alt_flag"] in items:
        return room["alt"]
    return room["layout"]


def walkable(tile, items):
    if tile == "#" or tile in PROPS or tile in BLOCKERS:
        return False
    if tile == "~":
        return "frostfang_bow" in items
    if tile == "Q":
        return "divers_helm" in items
    if tile == "v":
        return "glowmoth_lantern" in items
    if tile == "Y":
        return "stonebreaker" in items
    if tile in "^_":
        return False
    return True


def hook_hops(rows, x, y, items):
    """Tiles the Tide Hook pulls Wren to from (x, y): the tile short of a post
    in a straight line. The chain flies over anything but walls and props."""
    if "tide_hook" not in items:
        return []
    out = []
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        for step in range(1, HOOK_RANGE + 1):
            tx, ty = x + dx * step, y + dy * step
            if not (0 <= tx < COLS and 0 <= ty < ROWS):
                break
            t = rows[ty][tx]
            if t == "O":
                if step > 1:
                    out.append((tx - dx, ty - dy))
                break
            if stops_flight(t):
                break
    return out


def glide_hops(rows, x, y, items):
    """Tiles the Kite Cloak sets Wren down on from (x, y). Only walls and
    solid scenery stop it; it can come down early anywhere that isn't water."""
    if "kite_cloak" not in items:
        return []
    out = []
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        for step in range(1, GLIDE_WATER_TILES + 1):
            tx, ty = x + dx * step, y + dy * step
            if not (0 <= tx < COLS and 0 <= ty < ROWS):
                break
            t = rows[ty][tx]
            if stops_flight(t):
                break
            if t != "~" and walkable(t, items):
                out.append((tx, ty))
            if step >= GLIDE_TILES and t != "~":
                break
    return out


def explore(rooms, items):
    """Every (room, tile) reachable with `items`, and the doors touched."""
    start_room = START[0]
    start_rows = rows_for(rooms[start_room], items)
    first = next((x, y) for y in range(ROWS) for x in range(COLS) if walkable(start_rows[y][x], items))
    seen = {(start_room, first)}
    queue = deque(seen)
    doors = set()
    while queue:
        coord, (x, y) = queue.popleft()
        room = rooms[coord]
        rows = rows_for(room, items)
        if rows[y][x] == "D" and room["door_to"]:
            doors.add(room["door_to"])
        steps = []
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny, nc = x + dx, y + dy, coord
            if not (0 <= nx < COLS and 0 <= ny < ROWS):
                nc = (coord[0] + dx, coord[1] + dy)
                if nc not in rooms:
                    continue
                nx, ny = nx % COLS, ny % ROWS
            steps.append((nc, (nx, ny)))
        steps += [(coord, hop) for hop in hook_hops(rows, x, y, items) + glide_hops(rows, x, y, items)]
        for nc, (nx, ny) in steps:
            if (nc, (nx, ny)) in seen:
                continue
            if not walkable(rows_for(rooms[nc], items)[ny][nx], items):
                continue
            seen.add((nc, (nx, ny)))
            queue.append((nc, (nx, ny)))
    return seen, doors


def route(rooms):
    items = set()
    stages = []
    done = []
    while True:
        seen, doors = explore(rooms, items)
        new = [DUNGEONS[d] for d in sorted(doors) if d in DUNGEONS and DUNGEONS[d][0] not in done]
        stages.append((sorted(items), {c for c, _ in seen}, [n for n, _ in new]))
        if not new:
            return stages, seen, done
        for name, item in new:
            done.append(name)
            items.add(item)


def main():
    check = "--check" in sys.argv
    rooms = load_rooms()
    stages, seen, done = route(rooms)
    problems = []
    opened = set()
    for i, (items, coords, dungeons) in enumerate(stages):
        fresh = sorted(coords - opened)
        opened |= coords
        if not check:
            print("Stage %d, items: %s" % (i, ", ".join(items) or "none"))
            print("  %d new screens: %s" % (len(fresh), " ".join("%d,%d" % c for c in fresh)))
            if dungeons:
                print("  dungeons open: %s" % ", ".join(dungeons))
    # Dungeons must open one at a time, in the plan's order.
    for i, (_, _, dungeons) in enumerate(stages[:-1]):
        if len(dungeons) != 1 or dungeons[0] != ORDER[i]:
            problems.append("stage %d opens %s (expected %s)" % (i, dungeons or "nothing", ORDER[i] if i < len(ORDER) else "nothing"))
    if done != ORDER:
        problems.append("the route clears %s, not %s" % (done, ORDER))
    for coord in sorted(set(rooms) - opened):
        problems.append("screen %s (%s) is never reachable" % (coord, rooms[coord]["name"]))
    # Every open floor tile on a reachable screen should be reachable at the end.
    final_items = set(stages[-1][0])
    reached = {(c, t) for c, t in seen}
    for coord in sorted(opened):
        rows = rows_for(rooms[coord], final_items)
        for y in range(ROWS):
            for x in range(COLS):
                t = rows[y][x]
                if t in ".:xrSpD" and walkable(t, final_items) and (coord, (x, y)) not in reached:
                    problems.append("screen %s tile (%d,%d) '%s' is never reachable" % (coord, x, y, t))
    if problems:
        for p in problems:
            print("FAIL: " + p)
        sys.exit(1)
    print("World route OK: %d screens, dungeons in order: %s." % (len(opened), ", ".join(done)))


if __name__ == "__main__":
    main()
