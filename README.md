# Leviathan

An original top-down, 16-bit action-adventure set on the Shellcoast, where a
colossal sea creature sleeps beneath the land. Built with Godot 4 and free
tools only.

This is the **prototype**: first-pass pixel art, no audio. Its job is to
prove the moment-to-moment feel (movement, sword, getting hit, healing)
and test the Saltmarrow art style before the vertical slice.

## Running it

1. Install [Godot 4.7.2](https://godotengine.org/download) (the standard build,
   not .NET). It's free.
2. Open the Project Manager, choose **Import**, and pick this folder's
   `project.godot`.
3. Press **F5** (Run Project).

The first open imports the translation file, which takes a few seconds.

## Playable builds (Windows, macOS, Linux, web)

**Download:** <https://github.com/ashciraulo/Leviathan/releases/latest> has
the newest release for Windows (`Leviathan-windows.zip`), macOS
(`Leviathan-macos.zip`) and Linux (`Leviathan-linux.tar.gz`). A release is
published when a tag like `v0.2.0` is pushed. The first time, Windows may warn
about an unknown app (*More info > Run anyway*), and on macOS right-click the
app and choose *Open* (it isn't notarised).

Every PR and push to `main` also exports all three (**Build PC** workflow)
and starts each on its own system, a Windows, a Mac and a Linux runner, where
it plays from the title screen into a new game by itself
(`Leviathan -- --boot-check=<file>`, `scripts/core/boot_check.gd`). CI fails
if any of them doesn't get there or logs a script error. Those builds can be
downloaded from the run's page too.

**Play in a browser:** <https://ashciraulo.github.io/Leviathan/> is rebuilt
from `main` on every push (the **Web build** workflow). Saves stay in that
browser.

The **Leviathan-web** download can't be opened by double-clicking
`index.html`: browsers only run the game from a web address, and the page
says so. To play the download, run `python3 -m http.server` in its folder and
open <http://localhost:8000>, or upload the folder to any static host.

Every pull request exports the web build and boots it in headless Chromium
(`tools/web_check.mjs`): CI fails if it doesn't reach the title screen or
the console shows a script error.

To export locally, install the export templates from the editor
(**Editor > Manage Export Templates**) and use **Project > Export**; the
presets are in `export_presets.cfg`.

## Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move (8 directions) | WASD / arrows | Left stick / D-pad |
| Sword | J | B / East |
| Talk / open | K | A / South |
| Hum (heal) | Hold H | Right shoulder |
| Pause | Esc | Start |
| Items | U, I | X, Y |
| Map | M | Back |
| Menu tabs | Q, E | LT, RT (or LB) |

Prompts in menus show keyboard keys or pad buttons, whichever was used last.
Every key and button can be changed in **Options > Controls**.

On a phone or tablet the web build shows touch controls once the screen is
touched: a stick on the left, J, K, U, I and H on the right, and Esc, Q, E
and M in the top corners. The game scales to fit small screens.

## What's in the prototype

- **384x216 pixel-perfect output**, integer scaling, nearest-neighbour
  filtering. The window opens at 3x (1152x648).
- **Wren**: 8-direction movement at a steady speed, a 4-direction sword swing
  with a 2-frame hitstop on every connect, knockback on both sides, a white
  hit flash and 1 second of invulnerability after being hit.
- **Breath bubbles instead of hearts**: 5 bubbles, each hit pops one. Landing
  sword hits fills the **Resonance** meter (marked in thirds). Holding **Hum**
  roots Wren in place and, after 0.8 s, spends a third of the meter to restore
  one bubble.
- **Three graybox enemies**, each with one readable tell:
  - *Scuttler* (chaser): crouches and flashes yellow, then dashes at Wren.
  - *Spitter* (shooter): a rooted barnacle that swells and glows, then spits
    a slow bubble.
  - *Shellback* (blocker): its shell plate deflects hits from the front. It
    stops and rattles before turning, which is your window to get behind it.
- **Rooms with sliding transitions**: four rooms in a small grid. Walk through
  a gap in the wall and the camera slides to the next room.
- **Tidestones as checkpoints**: touching one saves the game (JSON in
  `user://save_0.json`). Dying fades out and brings Wren back to the last
  Tidestone with full breath. **Continue** on the title screen loads the save.
- **Localization from day one**: every line of text is a key in
  `locale/strings.csv`. Adding a language is a new column, not a code change.
- **Accessibility hooks** in `Settings`: hitstop and screen shake strength,
  soft flashes, and hold or toggle for Hum. There's no options menu yet.

## Project layout

```
project.godot          Engine settings (viewport, autoloads, layers)
scenes/                title.tscn, game.tscn
rooms/                 One scene per room: room_<x>_<y>.tscn
scripts/autoload/      Events (signal bus), Settings, GameState, SaveManager, Feel
scripts/core/          Physics layers, placeholder palette, UI helpers
scripts/player/        Wren
scripts/enemies/       Enemy base, Scuttler, Spitter, Shellback, projectiles
scripts/world/         Room, Tidestone, camera
scripts/ui/            Title, HUD, pause menu
locale/strings.csv     All text, by key
tests/                 Headless smoke test (run by CI)
```

### Making a room

Copy a file in `rooms/`, rename it to its grid position (`room_2_1.tscn` sits
east of `room_1_1`), and edit the `layout` text in the Inspector. Each room is
24 x 13 tiles:

```
#  wall        ~  water       .  floor        P  start (first room only)
T  Tidestone   c  Scuttler    s  Spitter      b  Shellback
h  Old Hessa   C  chest       X  locked hatch D  doorway (door_to)
```

The full legend, including props, is at the top of `scripts/world/room.gd`.
Dungeon rooms set `dungeon` (keys found there only open hatches there) and
use the `hull` biome for the Rotting Hull.

Leave a gap in the border where a neighbour joins, at the same rows or
columns on both sides. The smoke test checks that every gap lines up. LDtk
will take over level editing later; the text layouts are for blocking out.

## Tests

CI runs a headless smoke test on every pull request. To run it locally:

```
godot --headless --path . --import
godot --headless --path . res://tests/smoke_test.tscn
```

It checks room layouts, breath and Resonance rules, save and load, and plays
through movement, a Tidestone save, a room transition, sword hits, a
Shellback block, a Hum heal, a Spitter shot and a respawn.

Beside it, CI runs an end-to-end playthrough (about three minutes):

```
godot --headless --path . res://tests/playthrough.tscn
```

It plays one game from a new file through every dungeon built so far, in
order, without resetting: in through each overworld doorway, every room and
chest, the boss and its story scenes, the bell, back out, then a save and a
reload. The smoke test covers each dungeon's puzzles and fights on their own;
this one catches pieces that don't fit together (walking between rooms inside
a dungeon is left to tools/*_rooms.py --check). A new dungeon joins the run
once its entry room exists (`DUNGEONS` in tests/playthrough.gd).

## Art

All pixel art is original and generated by `tools/build_art.py` (Python
standard library only). Sprites are written there as material silhouettes
(hair, skin, tunic...) and the script lights them by the plan's rules: light
from the top left, hue-shifted ramps, coloured outlines from each material's
darkest shade. Tiles are generated from the Saltmarrow palette.

After changing the art source, rebuild and commit the PNGs:

```
python3 tools/build_art.py
```

CI fails if the committed PNGs don't match the source. There is no
third-party art or audio in the repo, so nothing to license. See `CREDITS.md`.
