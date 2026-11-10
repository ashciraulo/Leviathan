#!/usr/bin/env python3
"""Dungeon flow check, read straight from rooms/*.tscn.

    python3 tools/dungeon_flow.py          # print each dungeon's flow
    python3 tools/dungeon_flow.py --check  # fail on a problem (CI runs this
                                           # from tools/check.sh)

Checks, per dungeon:
- every gap in a room's border wall meets a gap in its neighbour (else Wren
  walks into a wall or off the world);
- doorways (D) and falls land on a room that exists, on open ground;
- bars (|) and hidden chests have a gate, and each gate has what solves it
  (plates and something to hold them, braziers, eyes, skulls, enemies);
- every room can be reached from the entrance;
- small keys can't be spent into a dead end: every order of opening the
  locked hatches (X) still leaves a key for the next one, and the big key is
  reachable without the big-key door (G).

Tools (hook, mallet, lantern, horn, helm...) are assumed in hand once the
dungeon gives them: this is about keys, doors and dead ends, not item order.
Rooms are whole: hatches and bars inside a room aren't modelled (hatches all
stand in border gaps; bars that guard a way on, like the Glacier Slide Hall's
cage, are checked by the smoke test instead), keys count once their room is
reached, and a dungeon room is read by its starting layout.
"""

import glob
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
W, H = 24, 13
DUNGEONS = ["hull", "kiln", "mire", "gale", "glacier", "belfry", "tomb", "maw"]
# Tiles that block a crossing for good ($ comes down to the Echo Horn).
SOLID = set("#!")
# Anything the "clear" gate can count, the boss (V) included.
ENEMIES = set("csbmweqtgdAkxaMUV@&+")


def parse_vec(text, key):
    m = re.search(r"^%s = Vector2i\((-?\d+), (-?\d+)\)" % key, text, re.M)
    return (int(m.group(1)), int(m.group(2))) if m else None


def parse_str(text, key, default=""):
    m = re.search(r'^%s = "(.*?)"' % key, text, re.M | re.S)
    return m.group(1) if m else default


def load():
    rooms = {}
    for path in glob.glob(os.path.join(ROOT, "rooms", "room_*.tscn")):
        m = re.search(r"room_(-?\d+)_(-?\d+)\.tscn$", path)
        coord = (int(m.group(1)), int(m.group(2)))
        text = open(path).read()
        layouts = [parse_str(text, "layout"), parse_str(text, "alt_layout")]
        grids = []
        for lay in layouts:
            if not lay:
                continue
            rows = lay.split("\n")
            grids.append([(r + "#" * W)[:W] for r in (rows + ["#" * W] * H)[:H]])
        rooms[coord] = {
            "dungeon": parse_str(text, "dungeon"),
            "grids": grids,
            "gate": parse_str(text, "gate"),
            "chest_item": parse_str(text, "chest_item", "small_key").replace('\\"', ""),
            "chest_hidden": re.search(r"^chest_hidden = true", text, re.M) is not None,
            "door_to": parse_vec(text, "door_to"),
            "door_spawn": parse_vec(text, "door_spawn"),
            "falls": re.search(r"^falls_through = true", text, re.M) is not None,
            "fall_to": parse_vec(text, "fall_to"),
            "fall_spawn": parse_vec(text, "fall_spawn"),
        }
    return rooms


def grids(room):
    """The layouts to read. A dungeon room is checked as it starts (its
    layout); an overworld neighbour by its most open layout, since an alt
    layout there only opens ways up."""
    return room["grids"][:1] if room["dungeon"] else room["grids"]


def tile(room, x, y):
    """Most open tile of the room's layouts (see grids) at x, y."""
    best = "#"
    for g in grids(room):
        t = g[y][x]
        if t not in SOLID:
            return t
        best = t
    return best


def all_tiles(room):
    return "".join("".join(g) for g in grids(room))


def border(dir_):
    """Pairs of (tile here, tile in the neighbour) along a shared edge."""
    if dir_ == (1, 0):
        return [((W - 1, y), (0, y)) for y in range(H)]
    if dir_ == (-1, 0):
        return [((0, y), (W - 1, y)) for y in range(H)]
    if dir_ == (0, 1):
        return [((x, H - 1), (x, 0)) for x in range(W)]
    return [((x, 0), (x, H - 1)) for x in range(W)]


DIRS = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def open_ground(room, at):
    x, y = at
    if not (0 <= x < W and 0 <= y < H):
        return False
    return any(g[y][x] not in SOLID | set("~Q_^") for g in grids(room))


def edges(rooms, coord, problems, name):
    """Crossings out of a room: (neighbour, kind, owner). kind is open, lock
    or big; a lock's owner is the room whose hatch (X) stands in it, since
    one small key opens every hatch in that room."""
    out = []
    room = rooms[coord]
    for d in DIRS:
        n = (coord[0] + d[0], coord[1] + d[1])
        kinds = set()
        owner = None
        for here, there in border(d):
            a = tile(room, *here)
            if a in SOLID or a == "D":
                continue
            other = rooms.get(n)
            if other is None:
                problems.append("%s %s: border gap at %s leads off the world" % (name, coord, here))
                break
            b = tile(other, *there)
            if b in SOLID:
                problems.append("%s %s: border gap at %s meets a wall in %s" % (name, coord, here, n))
                continue
            pair = a + b
            if "X" in pair and "G" not in pair:
                owner = coord if a == "X" else n
            kinds.add("big" if "G" in pair else "lock" if "X" in pair else "open")
        if kinds:
            # The widest way through wins (a lock beside an open gap is open).
            kind = "open" if "open" in kinds else "lock" if "lock" in kinds else "big"
            out.append((n, kind, owner if kind == "lock" else None))
    if room["door_to"] and "D" in all_tiles(room):
        out.append((room["door_to"], "open", None))
    if room["falls"] and room["fall_to"]:
        out.append((room["fall_to"], "open", None))
    return out


def check_room(rooms, coord, name, problems):
    room = rooms[coord]
    tiles = all_tiles(room)
    gate = room["gate"]
    if "|" in tiles and not gate:
        problems.append("%s %s: bars with no gate to open them" % (name, coord))
    if room["chest_hidden"] and not gate:
        problems.append("%s %s: a hidden chest with no gate to show it" % (name, coord))
    need = {
        "plates": "=",
        "braziers": "j",
        "eyes": "E",
        "skulls": "Z",
    }
    if gate in need and need[gate] not in tiles:
        problems.append("%s %s: gate %s has no %s" % (name, coord, gate, need[gate]))
    if gate == "plates":
        plates = g_count(room, "=")
        # Wren is too light for a plate: each needs a crate.
        crates = g_count(room, "K")
        if crates < plates:
            problems.append("%s %s: %d plates but only %d crates" % (name, coord, plates, crates))
    if gate == "clear" and not (set(tiles) & ENEMIES):
        problems.append("%s %s: gate clear with no enemies" % (name, coord))
    for key, spawn in (("door_to", "door_spawn"), ("fall_to", "fall_spawn")):
        if key == "door_to" and "D" not in tiles:
            continue
        if key == "fall_to" and not room["falls"]:
            continue
        target = room[key]
        if target is None or target not in rooms:
            problems.append("%s %s: %s %s is no room" % (name, coord, key, target))
        elif room[spawn] is not None and not open_ground(rooms[target], room[spawn]):
            problems.append("%s %s: %s lands Wren off solid ground at %s in %s" % (name, coord, spawn, room[spawn], target))
        elif room[spawn] is not None and rooms[target]["dungeon"]:
            # Nothing waiting right where Wren lands (a regular foe, not a boss).
            sx, sy = room[spawn]
            near = [tile(rooms[target], x, y) for x in range(sx - 1, sx + 2) for y in range(sy - 1, sy + 2) if 0 <= x < W and 0 <= y < H]
            if set(near) & (ENEMIES - {"V"}):
                problems.append("%s %s: %s lands Wren beside an enemy at %s in %s" % (name, coord, spawn, room[spawn], target))


def g_count(room, ch):
    return max(sum(r.count(ch) for r in g) for g in grids(room)) if room["grids"] else 0


def flow(rooms, name, problems):
    mine = {c for c, r in rooms.items() if r["dungeon"] == name}
    graph = {}
    for c in sorted(mine):
        check_room(rooms, c, name, problems)
        graph[c] = edges(rooms, c, problems, name)
    # Entrances: dungeon rooms the outside leads into (a dungeon's own way
    # out, such as the boss room's doorway, doesn't count).
    entrances = set()
    for c, r in rooms.items():
        if c in mine:
            continue
        near = any((c[0] + d[0], c[1] + d[1]) in mine for d in DIRS)
        if near or r["door_to"] in mine or r["fall_to"] in mine:
            entrances |= {n for n, _, _ in edges(rooms, c, [], "") if n in mine}
    if not entrances:
        problems.append("%s: no way in" % name)
        return
    keys = {c: (all_tiles(rooms[c]).count("C") and 1) * (rooms[c]["chest_item"] == "small_key") * max(1, g_count(rooms[c], "C")) for c in mine}
    big_key = {c for c in mine if rooms[c]["chest_item"] == "big_key"}

    def reach(opened, big):
        seen = set(entrances)
        todo = list(entrances)
        locks = set()
        while todo:
            c = todo.pop()
            for n, kind, owner in graph[c]:
                if n not in mine:
                    continue
                if kind == "lock" and owner not in opened:
                    locks.add(owner)
                    continue
                if kind == "big" and not big:
                    continue
                if n not in seen:
                    seen.add(n)
                    todo.append(n)
        return seen, locks

    everything, _ = reach(_AllOpen(), True)
    for c in sorted(mine - everything):
        problems.append("%s %s: can't be reached from the entrance" % (name, c))
    # Every order of spending keys: each key opens one hatch room (every X
    # in it), so the state is the set of hatch rooms opened so far.
    stuck = []
    seen_states = set()

    def walk(opened):
        if opened in seen_states or stuck:
            return
        seen_states.add(opened)
        big = bool(big_key & reach(opened, False)[0])
        area, locks = reach(opened, big)
        have = sum(keys[c] for c in area) - len(opened)
        if locks and have <= 0:
            stuck.append((sorted(area), sorted(locks)))
            return
        for lock in locks:
            walk(opened | {lock})

    walk(frozenset())
    if stuck:
        area, locks = stuck[0]
        problems.append("%s: keys can run out with hatches still shut (reached %d rooms, shut: %s)" % (name, len(area), locks))
    if big_key and not (big_key & reach(_AllOpen(), False)[0]):
        problems.append("%s: the big key is behind the big-key door" % name)
    print("%s: %d rooms, %d entrances, %d key orders tried" % (name, len(mine), len(entrances), len(seen_states)))


class _AllOpen(frozenset):
    def __contains__(self, item):
        return True


def main():
    check = "--check" in sys.argv
    rooms = load()
    problems = []
    for name in DUNGEONS:
        flow(rooms, name, problems)
    for p in problems:
        print("  " + p)
    if check and problems:
        sys.exit(1)
    if not problems:
        print("Dungeon flow OK.")


if __name__ == "__main__":
    main()
