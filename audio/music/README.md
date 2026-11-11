# Music

Drop finished tracks here as `<cue>.ogg` (OGG Vorbis, 44.1 kHz stereo, about -18 LUFS integrated, the bell phrases -16). The game picks them up by name; no code changes needed. Every cue loops except the lullaby phrases (`bell_1`..`bell_7`, `lullaby`); set Loop Offset in Godot's import dock when a track has an intro.

## Placeholders

The tracks here now are placeholders made in code by `tools/music_gen.py` (numpy and ffmpeg): `python3 tools/music_gen.py` rebuilds them all, `--only title,boss` just those. Each track is seeded from its name, so adding a track leaves the others unchanged. Each region and dungeon has its own key, mode, tempo and instruments, and each dungeon's track carries its Tidebell's phrase of the lullaby as a leitmotif. A finished track simply replaces its placeholder file.

## The lullaby

`lullaby.json` holds the seven phrases (MIDI note, beats) in D, 3/4. Bell order is `Audio.BELL_ORDER`: Hull, Kiln, Mire, Gale, Glacier, Belfry, Tomb, so `bell_1.ogg` is the Hull's phrase. Ringing a Tidebell plays its phrase over the dipped music (`Audio.play_bell_phrase`); `Audio.play_lullaby(n)` plays the first n phrases back to back for story scenes. The generator reads the same file, so changing a phrase there changes both the bell and the dungeon track that quotes it.

## When each cue plays

- A room plays `dungeon_<id>` inside a dungeon, otherwise `region_<biome>`, with a cross-fade on every change.
- A room with a living boss plays `boss` (Cantor Vael plays `boss_vael` and the Dreaming Heart `boss_heart`, from their `music_cue`); when it falls (`Events.boss_defeated`) the room's own track fades back in.
- A room's own `Room.music` overrides its track; `"none"` leaves only the ambience (the Ebb Shelf and Grotto).
- In a hollow (`Room.cave`) the music is muffled: 5 dB down through a low-pass filter.
- The Wayshell's flight plays `story_flight`.
- Saltmarrow's square (0,-1) plays `place_village` and Brine Spring (6,-2) `place_spring` (their `Room.music`).
- Marlo Pike's stall plays `place_shop` while the shop is open, then the room's track again.

Cues the game asks for:

- `title.ogg`
- `overworld.ogg`
- `lullaby.ogg`
- `credits.ogg`
- `bell_1.ogg`
- `bell_2.ogg`
- `bell_3.ogg`
- `bell_4.ogg`
- `bell_5.ogg`
- `bell_6.ogg`
- `bell_7.ogg`
- `region_saltmarrow.ogg`
- `region_brinewood.ogg`
- `region_cinderreach.ogg`
- `region_gloamfen.ogg`
- `region_windmere.ogg`
- `region_frostspine.ogg`
- `region_sunken_verge.ogg`
- `region_ossuary.ogg`
- `region_maw.ogg`
- `dungeon_cellar.ogg`
- `dungeon_hull.ogg`
- `dungeon_kiln.ogg`
- `dungeon_mire.ogg`
- `dungeon_gale.ogg`
- `dungeon_glacier.ogg`
- `dungeon_belfry.ogg`
- `dungeon_tomb.ogg`
- `dungeon_maw.ogg`
- `boss.ogg`
- `miniboss.ogg`
- `boss_vael.ogg`
- `boss_heart.ogg`
- `place_village.ogg`
- `place_shop.ogg`
- `place_house.ogg`
- `place_cave.ogg`
- `place_spring.ogg`
- `place_choir.ogg`
- `story_danger.ogg`
- `story_sorrow.ogg`
- `story_choir.ogg`
- `story_flight.ogg`

Jingles (no loop) go in `audio/sfx/` with the `jingle_` names below; they dip the music while they play.
