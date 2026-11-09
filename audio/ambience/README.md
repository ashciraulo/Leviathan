# Ambience

One quiet loop per region (`saltmarrow`, `brinewood`, `cinderreach`,
`gloamfen`, `windmere`, `frostspine`, `sunken_verge`, `ossuary`, `maw`), one
shared by every dungeon (`dungeon`), and `rain`, `wind` and `underwater`.
The game picks the loop from the room (`Audio.ambience_for_room`) and fades
between them. The `.wav` loops are made by `tools/sfx_gen.py` (`AMBIENCE`);
their import settings loop them. A hand-made `<id>.ogg` here wins over the
`.wav`.

Every loop is levelled to about -26 LUFS integrated, eight below the music (-18), so a region's bed is felt more than heard. A replacement file should match.
