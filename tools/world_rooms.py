#!/usr/bin/env python3
"""World route check: walks the overworld the way a player would, gaining
each dungeon's item in turn, and reports which screens open at each stage.

    python3 tools/world_rooms.py          # print the route, stage by stage
    python3 tools/world_rooms.py --check  # fail on a soft-lock, an
                                          # unreachable screen, floor or
                                          # chest, a secret that needs no
                                          # tool, or dungeons out of order

It reads the room layouts straight from rooms/*.tscn (overworld rooms are
the ones with no `dungeon`), crosses screen edges where both sides are open,
and treats a doorway (D) whose door_to is a dungeon's entry room as that
dungeon: reaching it means Wren clears it and comes out with its item.
tools/check.sh runs every tools/*_rooms.py with --check, so CI runs this.

Item gates (keep in step with the game):
  Tide Hook        zips Wren in a straight line to a hook post (O) up to
                   HOOK_RANGE tiles away, over water, lava, gaps and floor
  Kite Cloak       glides up to GLIDE_TILES straight ahead over holes, lava,
                   water and low hazards; launched along a fan's stream
                   (> <), it rides the stream to its far end
  Stonebreaker     breaks cracked boulders (Y)
  Glowmoth Lantern shows veiled planks (v)
  Frostfang Bow    freezes open water (~) into ice to walk on
  Diver's Helm     swims deep water (Q)
  (Q and bow freezing arrive with the Hollow Glacier PR. Props block one
  tile here; their real footprints can be wider, which only makes this
  check more generous, never stricter.)
  The Gale Bell turns the Old One over (old_one_turned): the Verge rises,
                   and Wren can hold the tide out at a Tidestone, which
                   bares the sea bed (;)
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

# Dungeon entry rooms (door_to) -> (name, what Wren comes out with: an item
# or story flag, or several separated by spaces).
DUNGEONS = {
    (10, 10): ("Rotting Hull", "tide_hook"),
    (21, 10): ("Kiln", "stonebreaker"),
    (25, 10): ("Lantern Mire", "glowmoth_lantern"),
    # Ringing the Gale Bell turns the Old One over: the Verge rises.
    (28, 10): ("Gale Spire", "kite_cloak old_one_turned"),
    (32, 10): ("Hollow Glacier", "frostfang_bow"),
    (36, 10): ("Drowned Belfry", "divers_helm"),
    (40, 10): ("Marrow Tomb", "tidebell_tomb"),
    (44, 10): ("The Maw", "the_end"),
}
ORDER = ["Rotting Hull", "Kiln", "Lantern Mire", "Gale Spire", "Hollow Glacier",
         "Drowned Belfry", "Marrow Tomb", "The Maw"]
START = ((0, 0), None)
# Overworld secrets: the room whose chest (C) is one, and the tools that
# reach it. Even once Wren is in the room (on any edge tile they can reach
# with everything), the chest must be out of reach without one of those.
SECRETS = {
    (8, -3): ("stonebreaker",),               # Ember Ridge: a jar behind a cracked boulder
    (4, 2): ("kite_cloak", "frostfang_bow"),  # Gloamfen: the Coral Buckler on a lake islet
    (6, -4): ("kite_cloak", "frostfang_bow"), # Windmere: glints on a sea stack
    (1, -3): ("kite_cloak", "frostfang_bow"), # Frostspine: glints on an islet
    (0, 3): ("kite_cloak", "frostfang_bow"),  # the Verge: Scaleweave on a skerry
    # Side areas off the main path (their way in is gated too, see below).
    (1, -1): ("frostfang_bow",),              # Rime Hollow: glints in a frozen pool
    (7, -1): ("tide_hook", "kite_cloak"),     # Cinder Hollow: glints on a lava islet
    (3, 3): ("kite_cloak", "frostfang_bow"),  # Glowworm Hollow: glints on a fen islet
    # Pacing finds in rooms that had nothing else (2026-11-10).
    (3, -2): ("kite_cloak", "frostfang_bow"), # Hollow Bole: glints on a pond islet
    (8, -1): ("stonebreaker",),               # Geyser Basin: glints behind a cracked boulder
    # Out on the sea bed, bared only while Wren holds the tide out.
    (2, 3): ("old_one_turned",),              # Weir Steps: glints on the sea bed
    (1, 4): ("old_one_turned",),              # the Ebb Shelf, south of Belfry Square
    (0, 4): ("old_one_turned",),              # Ebb Grotto, west of the Shelf
    # Challenges, each with a Breath Pearl.
    (7, -4): ("kite_cloak",),                 # Gullcry Stacks: glide stack to stack over the chasm
    (5, 3): ("glowmoth_lantern", "frostfang_bow", "kite_cloak"),  # Lampless Sink (the braziers need the lantern)
    # Regional caves (2026-11-10).
    (9, 2): ("tide_hook", "frostfang_bow", "kite_cloak"),  # Saltpan Hollow: a bitter-sea islet with a hook post
    (1, -4): ("frostfang_bow",),              # Icefall Grotto: bars until every ice eye is shot open
    (8, -4): ("glowmoth_lantern",),           # Clinker Vault: bars until both islet braziers burn
    (6, -3): ("kite_cloak",),                 # Sailwind Gallery: ride a fan's stream over the sky gap
    (2, -1): ("stonebreaker",),               # Rootbound Hollow: cracked boulders wall off the chest
    # Optional screens off the thinner regions (2026-11-11).
    (7, -3): ("tide_hook",),                  # Kestrel Reach: ride a stream to the stack, then hook down to the chest ledge
    (0, -4): ("tide_hook",),                  # Crevasse Shelf: hook over a crevasse from the slick ice
    # Far reaches, past each region's edge (2026-11-11).
    (4, -5): ("glowmoth_lantern",),           # Edgewatch Bluff: bars until both braziers burn (one over a crevasse)
    (1, -5): ("stonebreaker", "frostfang_bow"),  # Hoarfrost Cairn: boulders, then bars until both lake eyes are shot
    (7, 3): ("glowmoth_lantern", "kite_cloak", "frostfang_bow"),  # the Calf's Rest: glints on a fen islet
    (0, 5): ("tide_hook", "kite_cloak", "frostfang_bow"),  # Lee of the Old One: glints on a reef islet with a hook post
    (8, 3): ("kite_cloak", "frostfang_bow"),  # Saltgrave Brink: glints on a bitter-sea islet
    # Exploration secrets in the older regions (2026-11-11).
    (1, 0): ("old_one_turned",),             # Tidepools: a chest on the sea bed, bared while the tide is held out
    (2, 0): ("stonebreaker",),               # Barnacle Wall: a cove behind a cracked boulder
    (4, -2): ("glowmoth_lantern",),           # Mothlight Glade: bars until both braziers burn, one on a pond islet
    (6, 0): ("tide_hook", "kite_cloak", "divers_helm"),  # Tangle Shore: an islet out in deep water, with a hook post
    (4, 1): ("tide_hook",),                  # Fenmouth: hook a crate out of its slot onto the plate that unbars a shrine
    (3, 2): ("tidebell_tomb",),              # Witheroot Hollow: a hidden wall the Echo Horn brings down
    (7, -2): ("glowmoth_lantern",),          # Ashfall Gate: a niche barred until a brazier burns on each bank
    (10, -2): ("tidebell_tomb",),            # Kiln Mouth: a hidden chamber beside the Kiln's door
    (10, 0): ("tide_hook", "frostfang_bow", "kite_cloak"),  # Whalefall Steps: a ledge over a pool, a hook post beyond it
    (8, 0): ("tidebell_tomb",),              # Rib Hollow: a bone barricade walls a niche
    # Puzzle caves: one short trial room per region.
    (-1, 0): ("tide_hook", "stonebreaker"),  # Dragline Cellar: crates and plates past cracked boulders
    (10, -1): ("tide_hook", "glowmoth_lantern"),  # Emberwell Vault: braziers on lava islets, a boulder in the hook's way
    (11, 0): ("tidebell_tomb",),               # Drybone Crypt: the way on is a hidden bone wall in the hall
    (3, -5): ("tide_hook", "kite_cloak"),     # Gustway Ledges: glints past a sky gap, over a ledge the gusts sweep
    (-1, -3): ("frostfang_bow",),             # Rimelight Hollow: three ice eyes round a slick floor
}
# Side areas' ways in: Rime Hollow under Frostspine's sea (1,-2) (freeze or
# glide one tile of water), Glowworm Hollow below the Gloamfen (3,2) (veiled
# planks: the Glowmoth Lantern), Cinder Hollow west of (8,-1) (open).
# The Ossuary's jar (7, 1) needs no tool: it sits inside a ring of sinking
# sand, and the challenge is walking in without being swallowed.
# Sea-glass (*): twelve pieces, one per room, picked up by walking over
# them. Rooms listed here hide theirs behind a tool, like SECRETS; the rest
# are tucked into corners anyone can walk to.
SEA_GLASS_TOTAL = 12
SEA_GLASS = {
    (0, 0): ("frostfang_bow", "kite_cloak"),                       # the Shore: a pond islet
    (9, -2): ("kite_cloak",),                                      # Slag Fields: a lava islet
    (6, 1): ("glowmoth_lantern", "frostfang_bow", "kite_cloak"),   # Lumen Pool: veiled planks
    (2, -2): ("frostfang_bow", "kite_cloak"),                      # Shiver Coast: out in the sea
    (9, -1): ("stonebreaker",),                                    # Scorched Pass: behind a boulder
}
# The rest: behind a mangrove (4,-1), a stilt hut (5,-2), a rib (8,0) and a
# windmill (4,-4), in the Wreck's ruin (1,1), out on Cockle Flats at low
# tide (0,2), and in the middle of Rimewatch Pass's ice (2,-3).
# Solid scenery (Prop.KINDS with a footprint). N, the Old One's lip, has none.
PROPS = set("ouf nHLMWlRJZBUF".replace(" ", ""))
# Solid things that aren't scenery: stones, chests, hook posts, NPCs, ice
# eyes, and boulders, crates and hatches, which also stop the chain and the
# cloak.
BLOCKERS = set("TCOKXEh123456k")


def stops_flight(tile):
    return tile == "#" or tile in PROPS or tile in BLOCKERS or tile in "Y%$"


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
        chest = re.search(r'^chest_item = "(.*?)"', text, re.M)
        biome = re.search(r'^biome = "(.*?)"', text, re.M)
        gate = re.search(r'^gate = "(.*?)"', text, re.M)
        rooms[coord] = {
            "gate": gate.group(1) if gate else "",
            "biome": biome.group(1) if biome else "saltmarrow",
            "layout": field("layout"),
            "alt": field("alt_layout"),
            "alt_flag": flag.group(1) if flag else "",
            "door_to": (int(door.group(1)), int(door.group(2))) if door else None,
            "name": os.path.basename(path),
            "chest": chest.group(1) if chest else "small_key",
        }
    return rooms


# Gates that need a tool: braziers only catch from the raised Glowmoth
# Lantern, ice eyes only open to a frost arrow.
GATE_TOOLS = {"braziers": "glowmoth_lantern", "eyes": "frostfang_bow"}
# Plate rooms whose crate only the Tide Hook can drag out of its slot.
PLATE_HOOK_ROOMS = {"room_4_1.tscn", "room_-1_1.tscn"}


# Regions whose "~" is lava: the Frostfang Bow can't freeze it, so it acts
# like dungeon lava (^): the chain and the cloak cross it, nothing walks it.
LAVA_BIOMES = {"cinderreach"}


def rows_for(room, items):
    rows = room["alt"] if room["alt"] and room["alt_flag"] in items else room["layout"]
    needs = GATE_TOOLS.get(room["gate"], "")
    if room["gate"] == "plates" and room["name"] in PLATE_HOOK_ROOMS:
        needs = "tide_hook"
    if needs and needs not in items:
        # A gate this room's puzzle can't be solved without keeps its bars shut.
        rows = [r.replace("|", "#") for r in rows]
    if room["biome"] in LAVA_BIOMES:
        return [r.replace("~", "^") for r in rows]
    return rows


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
    if tile == ";":
        return "old_one_turned" in items
    if tile in "%$":
        # A bone barricade: the Echo Horn, found in the Marrow Tomb, brings it down.
        return "tidebell_tomb" in items
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


FANS = {">": 1, "<": -1}
FAN_REACH = 22


def in_stream(rows, x, y, dx):
    """True when (x, y) lies in the stream of a fan in its row blowing dx
    (WindFan: a stream runs from the fan until a wall or the room's rim)."""
    if not (0 < x < COLS - 1):
        return False
    for step in range(1, FAN_REACH + 1):
        fx = x - dx * step
        if not (0 <= fx < COLS):
            return False
        t = rows[y][fx]
        if FANS.get(t) == dx:
            return True
        if t == "#":
            return False
    return False


def stream_hops(rows, x, y, dx, items):
    """Tiles a glide launched down a fan's stream can come down on: anywhere
    along it that isn't water, to where the stream ends."""
    out = []
    tx = x + dx
    while 0 < tx < COLS - 1 and rows[y][tx] != "#":
        if stops_flight(rows[y][tx]):
            break
        if rows[y][tx] != "~" and walkable(rows[y][tx], items):
            out.append((tx, y))
        tx += dx
    return out


def glide_hops(rows, x, y, items):
    """Tiles the Kite Cloak sets Wren down on from (x, y). Only walls and
    solid scenery stop it; it can come down early anywhere that isn't water."""
    if "kite_cloak" not in items:
        return []
    out = []
    for dx in (1, -1):
        if in_stream(rows, x, y, dx):
            out += stream_hops(rows, x, y, dx, items)
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


def steps_from(rooms, coord, x, y, items):
    """Every (room, tile) Wren can go to in one move from (x, y): a step,
    across a screen edge, or a hook pull or glide."""
    rows = rows_for(rooms[coord], items)
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
    return [(nc, (nx, ny)) for nc, (nx, ny) in steps
            if walkable(rows_for(rooms[nc], items)[ny][nx], items)]


def start_tile(rooms, items):
    """Where the walk starts: the first open tile of the start screen."""
    rows = rows_for(rooms[START[0]], items)
    return START[0], next((x, y) for y in range(ROWS) for x in range(COLS) if walkable(rows[y][x], items))


def stranded(rooms, items, seen):
    """Tiles Wren can reach with `items` but never walk, pull or glide back
    from to the start (a hook pull out to an islet with no post home)."""
    back = {}
    for node in seen:
        for step in steps_from(rooms, node[0], node[1][0], node[1][1], items):
            back.setdefault(step, []).append(node)
    # Home is where the walk began, and any dungeon door: Wren comes back out
    # of a dungeon on its door holding something new, which may be the way out.
    home = {start_tile(rooms, items)}
    home |= {n for n in seen if rooms[n[0]]["door_to"] in DUNGEONS
             and rows_for(rooms[n[0]], items)[n[1][1]][n[1][0]] == "D"}
    queue = deque(home)
    while queue:
        for prev in back.get(queue.popleft(), ()):
            if prev not in home:
                home.add(prev)
                queue.append(prev)
    return sorted(seen - home)


def explore(rooms, items):
    """Every (room, tile) reachable with `items`, and the doors touched."""
    seen = {start_tile(rooms, items)}
    queue = deque(seen)
    doors = set()
    while queue:
        coord, (x, y) = queue.popleft()
        room = rooms[coord]
        rows = rows_for(room, items)
        if rows[y][x] == "D" and room["door_to"]:
            doors.add(room["door_to"])
        for step in steps_from(rooms, coord, x, y, items):
            if step not in seen:
                seen.add(step)
                queue.append(step)
    return seen, doors


def route(rooms):
    items = set()
    stages = []
    done = []
    while True:
        seen, doors = explore(rooms, items)
        new = [DUNGEONS[d] for d in sorted(doors) if d in DUNGEONS and DUNGEONS[d][0] not in done]
        stages.append((sorted(items), {c for c, _ in seen}, [n for n, _ in new], seen))
        if not new:
            return stages, seen, done
        for name, gains in new:
            done.append(name)
            items.update(gains.split())


def inside(rooms, coord, seen, items):
    """Tiles of one room Wren reaches with `items`, starting from every edge
    tile of it they reach with everything."""
    rows = rows_for(rooms[coord], items)
    start = {(coord, t) for c, t in seen if c == coord and
             (t[0] in (0, COLS - 1) or t[1] in (0, ROWS - 1) or rows[t[1]][t[0]] == "D")
             and walkable(rows[t[1]][t[0]], items)}
    reached = set(start)
    queue = deque(start)
    while queue:
        _, (x, y) = queue.popleft()
        steps = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        steps += hook_hops(rows, x, y, items) + glide_hops(rows, x, y, items)
        for nx, ny in steps:
            if 0 <= nx < COLS and 0 <= ny < ROWS and (coord, (nx, ny)) not in reached \
                    and walkable(rows[ny][nx], items):
                reached.add((coord, (nx, ny)))
                queue.append((coord, (nx, ny)))
    return reached


def chest_tiles(room, items):
    rows = rows_for(room, items)
    return [(x, y) for y in range(ROWS) for x in range(COLS) if rows[y][x] == "C"]


def opens(seen, coord, spot):
    """True when Wren can stand beside the chest at spot to open it."""
    x, y = spot
    return any((coord, (x + dx, y + dy)) in seen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))


def main():
    check = "--check" in sys.argv
    rooms = load_rooms()
    stages, seen, done = route(rooms)
    problems = []
    opened = set()
    for i, (items, coords, dungeons, _) in enumerate(stages):
        fresh = sorted(coords - opened)
        opened |= coords
        if not check:
            print("Stage %d, items: %s" % (i, ", ".join(items) or "none"))
            print("  %d new screens: %s" % (len(fresh), " ".join("%d,%d" % c for c in fresh)))
            if dungeons:
                print("  dungeons open: %s" % ", ".join(dungeons))
    # No softlocks: from anywhere Wren gets to, with what they hold by then,
    # there is a way back (no hook pull out to an islet with no post home).
    for items, _, _, reached in stages:
        lost = stranded(rooms, set(items), reached)
        for coord in sorted({c for c, _ in lost}):
            tiles = [t for c, t in lost if c == coord]
            problems.append("screen %s: Wren can reach %s but not get back (holding %s)"
                            % (coord, " ".join("(%d,%d)" % t for t in tiles[:6]), ", ".join(items) or "nothing"))
    # Dungeons must open one at a time, in the plan's order.
    for i, (_, _, dungeons, _) in enumerate(stages[:-1]):
        if len(dungeons) != 1 or dungeons[0] != ORDER[i]:
            problems.append("stage %d opens %s (expected %s)" % (i, dungeons or "nothing", ORDER[i] if i < len(ORDER) else "nothing"))
    if done != ORDER:
        problems.append("the route clears %s, not %s" % (done, ORDER))
    for coord in sorted(set(rooms) - opened):
        problems.append("screen %s (%s) is never reachable" % (coord, rooms[coord]["name"]))
    # Every open floor tile on a reachable screen should be reachable at the end.
    final_items = set(stages[-1][0])
    without = {}
    reached = {(c, t) for c, t in seen}
    for coord in sorted(opened):
        rows = rows_for(rooms[coord], final_items)
        for y in range(ROWS):
            for x in range(COLS):
                t = rows[y][x]
                if t in ".:xrSpD*" and walkable(t, final_items) and (coord, (x, y)) not in reached:
                    problems.append("screen %s tile (%d,%d) '%s' is never reachable" % (coord, x, y, t))
    # Chests: when each comes within reach, and secrets need their tool.
    for coord in sorted(rooms):
        for spot in chest_tiles(rooms[coord], final_items):
            stage = next((i for i, st in enumerate(stages) if opens(st[3], coord, spot)), None)
            if stage is None:
                problems.append("chest %s %s (%s) is never reachable" % (coord, spot, rooms[coord]["chest"]))
                continue
            if not check:
                print("Chest at %s %s (%s): stage %d" % (coord, spot, rooms[coord]["chest"], stage))
            need = SECRETS.get(coord)
            if need:
                # Wren comes in only by the ways open without those tools
                # (a secret beyond another secret can't be entered from behind).
                if need not in without:
                    without[need] = explore(rooms, final_items - set(need))[0]
                # When the room itself is out of reach without them, check the
                # room on its own, as if Wren came in by any way they reach it.
                ways_in = without[need] if any(c == coord for c, _ in without[need]) else seen
                if opens(inside(rooms, coord, ways_in, final_items - set(need)), coord, spot):
                    problems.append("secret chest %s %s opens without %s" % (coord, spot, " or ".join(need)))
    # The HUD's corners (breath bubbles top left, item slots top right)
    # hide whatever lies under them: keep finds and stones out of there.
    for coord in sorted(rooms):
        rows = rows_for(rooms[coord], final_items)
        for y in range(2):
            # The bubble plate grows with Wren's breath: thirteen bubbles reach x 161.
            for x in list(range(0, 11)) + list(range(20, COLS)):
                if rows[y][x] in "C*Tn":
                    problems.append("screen %s: '%s' at (%d,%d) sits under the HUD" % (coord, rows[y][x], x, y))
    # Every signpost in a room reads the room's one sign_key: one per room.
    for coord in sorted(rooms):
        if sum(r.count("n") for r in rows_for(rooms[coord], final_items)) > 1:
            problems.append("screen %s has more than one signpost (they'd all say the same)" % (coord,))
    # Sea-glass: how many, where, and the hidden ones need their tool.
    glass = [(coord, (x, y)) for coord in sorted(rooms) for y in range(ROWS) for x in range(COLS)
             if rows_for(rooms[coord], final_items)[y][x] == "*"]
    if len(glass) != SEA_GLASS_TOTAL:
        problems.append("%d pieces of sea-glass, expected %d" % (len(glass), SEA_GLASS_TOTAL))
    for coord in sorted({c for c, _ in glass}):
        if sum(1 for c, _ in glass if c == coord) > 1:
            problems.append("screen %s has more than one piece of sea-glass" % (coord,))
    for coord, spot in glass:
        stage = next((i for i, st in enumerate(stages) if (coord, spot) in st[3]), None)
        if stage is None:
            problems.append("sea-glass %s %s is never reachable" % (coord, spot))
            continue
        if not check:
            print("Sea-glass at %s %s: stage %d" % (coord, spot, stage))
        need = SEA_GLASS.get(coord)
        if need and (coord, spot) in inside(rooms, coord, seen, final_items - set(need)):
            problems.append("sea-glass %s %s is reachable without %s" % (coord, spot, " or ".join(need)))
    for coord in SEA_GLASS:
        if not any(c == coord for c, _ in glass):
            problems.append("SEA_GLASS lists %s but it has no sea-glass" % (coord,))
    # Crossing an edge carries Wren a step into the next screen: that step
    # must be ground, not water, lava or veiled planks (frozen water and lit
    # planks reset when a screen loads). Deep water is fine: Wren swims it.
    for coord in sorted(rooms):
        rows = rows_for(rooms[coord], final_items)
        for y in range(ROWS):
            for x in range(COLS):
                if not (x in (0, COLS - 1) or y in (0, ROWS - 1)) or not walkable(rows[y][x], final_items):
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ix, iy = x + dx, y + dy
                    ox, oy = x - dx, y - dy
                    if not (0 <= ix < COLS and 0 <= iy < ROWS) or (0 <= ox < COLS and 0 <= oy < ROWS):
                        continue
                    if (coord[0] - dx, coord[1] - dy) in rooms and rows[iy][ix] in "~^v":
                        problems.append("screen %s: coming in at (%d,%d) steps Wren onto '%s'" % (coord, x, y, rows[iy][ix]))
    for coord in SECRETS:
        if coord not in rooms or not chest_tiles(rooms[coord], final_items):
            problems.append("secret %s has no chest" % (coord,))
    if problems:
        for p in problems:
            print("FAIL: " + p)
        sys.exit(1)
    print("World route OK: %d screens, dungeons in order: %s." % (len(opened), ", ".join(done)))


if __name__ == "__main__":
    main()
