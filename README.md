# Leviathan

An original top-down, 16-bit action-adventure set on the Shellcoast, where a
colossal sea creature sleeps beneath the land. Built with Godot 4 and free
tools only.

This is the **prototype**: graybox shapes, no final art or audio. Its job is to
prove the moment-to-moment feel (movement, sword, getting hit, healing)
before the vertical slice.

## Running it

1. Install [Godot 4.7.2](https://godotengine.org/download) (the standard build,
   not .NET). It's free.
2. Open the Project Manager, choose **Import**, and pick this folder's
   `project.godot`.
3. Press **F5** (Run Project).

The first open imports the translation file, which takes a few seconds.

## Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move (8 directions) | WASD / arrows | Left stick / D-pad |
| Sword | J | B / East |
| Hum (heal) | Hold H | Right shoulder |
| Pause | Esc | Start |

Interact (K), item slots (U, I) and map (M) are bound but not used yet.

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
```

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

## Placeholder art

There is no third-party art or audio in the repo yet. Everything on screen is
drawn in code as simple shapes, so there is nothing to license. See
`CREDITS.md`.
