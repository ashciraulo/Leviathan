"""Leviathan soundtrack: the track sheet.

One entry per cue the game plays (Audio.MUSIC_CUES, Audio.JINGLES). This is
the single source for the plan: the per-cue MIDI scripts (music/cues/) read
key, tempo, meter and loop plan from here, and

    python3 music/track_sheet.py

writes music/TRACK_SHEET.md and music/track_sheet.json and checks that
every cue is distinct from the cues it sits next to in the game.

Conventions (agreed with scripts/autoload/audio.gd and audio/music/README.md):
- Masters render in FL Studio at 44.1 kHz stereo. Game files are OGG Vorbis.
- Loudness is measured over the loop body (intro excluded) with true peak
  at or under -1.0 dBTP. Tiers: places -20, exploration -18, combat and
  danger -17, title and credits -17, bell phrases and jingles -16.
- A looping cue is: [intro][loop body]. The render runs one extra pass so
  the reverb tail can be folded back onto the loop start, then the file is
  cut at the body's last bar line. Godot's import sets loop=true and
  loop_offset = intro seconds (music/post/finalize.py writes both).
- MIDI files are written in 4/4 at 96 ppq even for 3/4, 6/8 and 5/4 music
  (a 3/4 signature makes FL play at double speed); bars below are bars of
  the cue's own meter.
"""
from __future__ import annotations

import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# The lullaby, "Sleep, Old Heart": seven phrases in D aeolian, 3/4, one per
# Tidebell (audio/music/lullaby.json). Every cue quotes it somehow; the
# "motif" field says how.
BELLS = ["Point (Hull)", "Ember (Kiln)", "Moth (Mire)", "Gale (Gale Spire)",
         "Rime (Hollow Glacier)", "Verge (Drowned Belfry)", "Marrow (Marrow Tomb)"]

# Ash (2026-11-11): two styles, each where it fits. Folk adventure for the
# open world, dungeons, bosses and intense moments; ambient (pads, celesta,
# soft choir, long reverb, no drums) for calm interactions and memories.
AMBIENT = {"title", "lullaby", "place_house", "place_cave", "place_spring", "place_choir",
           "story_choir", "story_sorrow", "story_memory"}

LUFS = {"place": -20.0, "explore": -18.0, "combat": -17.0, "theme": -17.0, "phrase": -16.0}


def cue(id, name, plays, key, tempo, meter, bars, intro, form, palette, motif,
        character, tier, batch, loop=True, swing=None):
    # Felt beats per bar, in units of the tempo (dotted quarters for 6/8 and 12/8).
    beats = {"3/4": 3, "4/4": 4, "6/8": 2, "12/8": 4, "5/4": 5, "7/8": 3.5}[meter]
    seconds = lambda b: b * beats * 60.0 / tempo
    return dict(id=id, name=name, plays=plays, key=key, tempo=tempo, meter=meter,
                bars=bars, intro_bars=intro, form=form, palette=palette, motif=motif,
                character=character, lufs=LUFS[tier], tier=tier, batch=batch, loop=loop,
                swing=swing, style="ambient" if id in AMBIENT else "folk adventure",
                intro_s=round(seconds(intro), 2), body_s=round(seconds(bars - intro), 2))


# Tempo is the felt beat: quarter notes, or dotted quarters for 6/8 and 12/8.
CUES = [
    # --- Batch 1: the pilot. One cue end to end to prove the pipeline. ---
    cue("region_saltmarrow", "Salt on the Sill", "Saltmarrow, the home village and shore",
        "F major", 67, "6/8", 66, 2,
        "intro 2 (guitar alone) | A 16 | A' 8 | B 16 (phrase 1 as a countermelody) | C 8 (flute rests) | A'' 16 (leads back to A)",
        ["nylon guitar picking", "soft reed (concertina-like)", "wooden flute lead",
         "upright bass", "frame drum and shaker", "low string pad, well under"],
        "Phrase 1 (Point), turned to F major, as the B-section countermelody on the reed.",
        "Warm morning by the water, rocking 6/8 like a moored boat. Folk, unhurried, homely.",
        "explore", 1),

    # --- Batch 2: the motif itself. ---
    cue("bell_1", "Point Bell", "Ringing the Hull's Tidebell", "D aeolian", 80, "3/4", 3, 0,
        "phrase 1 (2 bars) + 1 bar of ring", ["handbell, bright bronze"],
        "Phrase 1 as written.", "A clear small bell, like a ship's.", "phrase", 2, loop=False),
    cue("bell_2", "Ember Bell", "Ringing the Kiln's Tidebell", "D aeolian", 80, "3/4", 3, 0,
        "phrase 2 + ring", ["cast bell, darker, slight inharmonic clang"],
        "Phrase 2 as written.", "Heavier, warm metal fresh from the mould.", "phrase", 2, loop=False),
    cue("bell_3", "Moth Bell", "Ringing the Mire's Tidebell", "D aeolian", 80, "3/4", 3, 0,
        "phrase 3 + ring", ["glass bell, soft"], "Phrase 3 as written.",
        "Fragile and glowing, almost a celesta.", "phrase", 2, loop=False),
    cue("bell_4", "Gale Bell", "Ringing the Gale Spire's Tidebell (the Turning Verse)", "D aeolian", 80, "3/4", 4, 0,
        "phrase 4 + 2 bars of ring and swell", ["large tower bell", "low string swell"],
        "Phrase 4 as written; the swell marks the tide turning.", "The big one: the Old One rolls over.",
        "phrase", 2, loop=False),
    cue("bell_5", "Rime Bell", "Ringing the Hollow Glacier's Tidebell", "D aeolian", 80, "3/4", 3, 0,
        "phrase 5 + ring", ["FM bell, icy and pure"], "Phrase 5 as written.", "Cold and still.",
        "phrase", 2, loop=False),
    cue("bell_6", "Verge Bell", "Ringing the Drowned Belfry's Tidebell", "D aeolian", 80, "3/4", 3, 0,
        "phrase 6 + ring", ["church bell heard through water (low-passed)"], "Phrase 6 as written.",
        "Drowned, muffled, beautiful.", "phrase", 2, loop=False),
    cue("bell_7", "Marrow Bell", "Ringing the Marrow Tomb's Tidebell", "D aeolian", 80, "3/4", 3, 0,
        "phrase 7 + ring", ["bone-dry wood-and-metal bell, short"], "Phrase 7 as written (it ends home on D).",
        "Ancient, final.", "phrase", 2, loop=False),
    cue("lullaby", "Sleep, Old Heart", "Story scenes that sing the lullaby (Audio.play_lullaby)", "D aeolian",
        80, "3/4", 16, 0, "the 7 phrases back to back (14 bars) + 2 bars of ring",
        ["music box", "harp", "soft 'oo' choir"], "All seven phrases, in order.",
        "The whole song, plain and tender.", "phrase", 2, loop=False),
    cue("title", "The Tide Breathes", "Title screen", "D aeolian", 66, "3/4", 36, 4,
        "intro 4 (a lone bell plays phrase 1) | swell A 16 (harp, low strings) | B 16 (flute sings phrases 1-2) | breath out",
        ["distant tower bell", "harp", "low strings", "soft choir pad", "sub swell (the breath)", "flute"],
        "Phrase 1 alone on a bell, then phrases 1-2 on flute.",
        "Vast and asleep. Every 8 bars a low swell rises and falls, like the tide breathing.",
        "theme", 2),

    # --- Batch 3: the early game. ---
    cue("dungeon_cellar", "Cellar Steps", "The first dungeon (the cellar)", "A minor", 96, "4/4", 32, 0,
        "A 8 | A' 8 | B 12 | A'' 4 (stops short, creeps back)", ["pizzicato strings", "bassoon-like reed", "soft tom", "harp"],
        "Phrase 7's rhythm as the pizzicato ostinato, no melody quote.",
        "Curious, tiptoeing, a little spooky but safe.", "explore", 3),
    cue("region_brinewood", "Under the Mangrove", "Brinewood, the mangrove forest", "E dorian", 100, "4/4", 56, 0,
        "A 16 | B 8 | A' 16 | C 8 (drums drop out) | A tag 8",
        ["marimba", "kalimba-like mallet", "wooden flute", "hand drums", "upright bass", "warm pad"],
        "Phrase 3's opening rise as the marimba's hook.",
        "Green, damp, busy with life. Gently rhythmic and curious.", "explore", 3),
    cue("dungeon_hull", "The Rotting Hull", "The Rotting Hull (dungeon 1, Point Bell)", "D dorian", 52, "6/8", 48, 0,
        "A 16 (cello carries phrase 1) | B 12 | A' 12 | bridge 8 (creaks and bass alone)",
        ["low strings", "bass clarinet", "woodblock creaks", "harp", "deep drum"],
        "Phrase 1 on cello, slowed and heavy.", "A wreck that groans and sways. Damp and uneasy.",
        "explore", 3),
    cue("place_village", "Market Day", "Saltmarrow's village square", "G major", 108, "4/4", 32, 0,
        "A 8 | A' 8 | B 8 | A'' 8", ["nylon guitar (strummed)", "tin whistle (soft)", "upright bass", "light hand percussion"],
        "Phrase 2's contour flipped to major in the B section.", "Bright-hearted, people at work.", "place", 3),
    cue("place_shop", "Marlo's Stall", "Marlo's shop menu", "Bb major", 112, "4/4", 24, 0,
        "pickup 1 | A 8 | B 8 | A' 7", ["marimba", "upright bass", "brushed snare (soft)", "clarinet"],
        "A two-note wink of phrase 5 at the end of each A.", "Cheeky shuffle, a little salesy.", "place", 3,
        swing=0.62),
    cue("place_house", "Lamplight", "Inside homes and Hessa's lighthouse", "Eb major", 74, "3/4", 24, 0,
        "music box alone 4 | A 8 | B 8 | A' 4", ["felt piano", "music box", "cello"],
        "Phrase 6 in major, slow, on the music box.", "Safe, warm, a kettle on.", "place", 3),
    cue("miniboss", "Teeth in the Dark", "Mini-bosses and elites", "G minor", 152, "4/4", 16, 0,
        "A 8 | B 8", ["staccato low strings", "toms", "brass stabs"],
        "Phrase 4's first three notes as the brass stab.", "Short, sharp, urgent.", "combat", 3),
    cue("boss", "Wake Not the Deep", "The seven Tidebell guardians", "C minor", 156, "4/4", 56, 2,
        "intro 2 (hits) | A 16 (ostinato + brass) | B 8 (choir) | C 8 (drums only, then build) | D 16 (brass melody) | A' 6",
        ["taiko-like drums", "low brass", "string ostinato", "choir", "timpani"],
        "Phrase 1 in augmentation on low brass under the B section.",
        "Big and driven, but still part of the same sea.", "combat", 3),

    # --- Batch 4: the middle regions and their dungeons. ---
    cue("region_cinderreach", "Ashfall", "Cinderreach, the volcanic reach", "C# phrygian dominant", 116, "4/4", 48, 2,
        "intro 2 | A 16 (low ostinato) | B 8 | A' 16 | breakdown 6",
        ["low strings ostinato", "frame drums", "low reed/brass", "metal anvil tick", "dark pad"],
        "Phrase 2 hidden in the low brass, rhythm squared off.", "Hot, heavy air, marching forward.", "explore", 4),
    cue("dungeon_kiln", "The Bell Kiln", "The Kiln (dungeon 2, Ember Bell)", "E phrygian", 132, "4/4", 64, 0,
        "A 16 (anvil ostinato) | B 8 (phrase 2) | A' 16 | C 8 | B' 16 (phrase 2 in canon)", ["anvil hits", "low brass", "bass synth",
        "taiko", "organ (dark)"], "Phrase 2 on brass, full.", "Industry and fire, relentless.", "explore", 4),
    cue("region_gloamfen", "Lanterns on the Fen", "Gloamfen, the glowing marsh", "Bb minor", 72, "3/4", 40, 0,
        "A 16 | B 8 (long rests) | A' 16", ["celesta", "bowed vibraphone", "fretless bass", "soft choir"],
        "Phrase 3 on celesta, scattered across bars.", "Hushed and glowing, a little haunted.", "explore", 4),
    cue("dungeon_mire", "Moth Light", "Lantern Mire (dungeon 3, Moth Bell)", "C# minor", 76, "3/4", 40, 0,
        "A 12 | B 12 | A' 8 | coda 8 (dark)", ["glass bells", "low drone", "choir", "harp"],
        "Phrase 3 on glass bells, then broken up in the dark coda.", "Creeping in the dark toward a light.", "explore", 4),
    cue("region_windmere", "Windmere Heights", "Windmere Heights, the windy uplands", "A lydian", 126, "4/4", 48, 0,
        "A 16 | A' 8 | B 16 (key lift) | A'' 8", ["pizzicato strings", "flute lead", "snare roll (soft)",
        "string pad", "harp"], "Phrase 4 opened up to lydian on flute.", "Open sky, kites and gusts.", "explore", 4),
    cue("dungeon_gale", "The Gale Spire", "The Gale Spire (dungeon 4, Gale Bell)", "B mixolydian", 138, "7/8", 72, 0,
        "A 16 (3+2+2 groove) | B 16 | A' 16 | C 8 (wind only) | B' 16", ["string runs", "flute", "timpani", "tubular bell", "bass"],
        "Phrase 4 on tubular bell, stretched to fit 7/8.", "Wind-driven, dizzy, climbing.", "explore", 4),
    cue("story_flight", "Wayshell Flight", "The Wayshell's flight", "D lydian", 98, "3/4", 24, 0,
        "A 8 | B 8 | A' 8 (lifts)", ["soaring strings", "harp glissandi", "choir 'ah'", "horn"],
        "Phrases 1 and 5 in D lydian, triumphant.", "Flying over the sleeping sea.", "theme", 4),

    # --- Batch 5: the far regions and their dungeons. ---
    cue("region_frostspine", "Frostspine", "Frostspine, the frozen ridge", "F# minor", 60, "4/4", 32, 0,
        "A 12 (near silence between notes) | B 12 | wind tag 8", ["FM glass e-piano", "choir pad", "low bowed bass", "sparse bell"],
        "Phrase 5's leap on the glass e-piano.", "Bitter cold, huge silence, slow breath.", "explore", 5),
    cue("dungeon_glacier", "The Hollow Glacier", "The Hollow Glacier (dungeon 5, Rime Bell)", "F minor", 70, "4/4", 40, 0,
        "A 8 | B 16 (ticking builds) | A' 16", ["FM bells", "bowed glass", "sub drone", "soft ticking percussion"],
        "Phrase 5 on FM bells.", "Frozen time, eerie calm, things watching from the ice.", "explore", 5),
    cue("region_sunken_verge", "The Sunken Verge", "The Sunken Verge, the drowned town that rose", "Eb dorian", 88, "5/4", 32, 0,
        "A 12 | B 8 | A' 12", ["harp", "low clarinet", "water-drop pluck", "upright bass", "soft pad"],
        "Phrase 6 in 5/4 on clarinet.", "Wet stone, tide pools, an old town breathing again.", "explore", 5),
    cue("dungeon_belfry", "The Drowned Belfry", "The Drowned Belfry (dungeon 6, Verge Bell)", "G dorian", 104, "3/4", 64, 0,
        "A 16 | B 16 (choir) | A' 16 | C 16 (organ alone, then bells)", ["soft organ", "choir", "church bells (filtered)", "harp", "bass"],
        "Phrase 6 as a hymn on organ.", "A flooded church still singing under the water.", "explore", 5),
    cue("region_ossuary", "Ossuary Dunes", "Ossuary Dunes, the bone desert", "C phrygian", 78, "4/4", 40, 2,
        "intro 2 (drone) | A 16 | B 8 | A' 14", ["hand drums", "low reed (duduk-like)", "drone", "bone marimba"],
        "Phrase 7 on the low reed, slowed.", "Sun-bleached, grieving, the family's bones.", "explore", 5),
    cue("dungeon_tomb", "The Marrow Tomb", "The Marrow Tomb (dungeon 7, Marrow Bell)", "Ab aeolian", 90, "4/4", 40, 0,
        "A 16 | B 12 | coda 12", ["bone marimba", "low drone", "frame drum", "dark choir"],
        "Phrase 7 on marrow-bone marimba.", "Deep, ancient, reverent.", "explore", 5),
    cue("place_cave", "Hollows", "Caves and grottoes (the game also muffles them)", "A dorian", 62, "4/4", 24, 0,
        "drone 4 | drips 16 | drone 4", ["harp harmonics", "water drips (pitched)", "drone"],
        "Single notes of phrase 3 dripping.", "Cool, quiet, echoing.", "place", 5),
    cue("place_spring", "The Healing Spring", "Healing springs", "E major", 68, "4/4", 24, 0,
        "harp alone 6 | A 10 | B 8", ["harp arpeggios", "glassy pad", "soft flute"],
        "Phrase 1 in major, slow.", "Restful and clean.", "place", 5),

    # --- Batch 6: the end of the game. ---
    cue("region_maw", "On the Old One's Back", "Lullaby Point and the Old One's back", "G minor", 58, "3/4", 32, 0,
        "A 16 | B 16", ["huge low swells", "low brass", "choir", "sub (the breath)"],
        "Phrases 1-7 in long notes on low brass across the loop.", "Standing on something alive and enormous.",
        "explore", 6),
    cue("dungeon_maw", "Inside the Maw", "The Maw (the final dungeon)", "D phrygian", 64, "4/4", 40, 0,
        "A 16 (heartbeat) | B 8 (breath floods) | A' 16", ["heartbeat kick at 64", "sub swells", "dark choir",
        "bowed metal"], "Fragments of all seven phrases surfacing and sinking.", "Inside a living body. Huge, slow, wet.",
        "explore", 6),
    cue("place_choir", "The Grey Choir", "The choir's halls", "C# dorian", 63, "3/4", 24, 0,
        "chant A 8 | answer 8 | chant A' 8", ["choir only", "organ pedal"], "Phrase 2 as a chant.", "Cold devotion.", "place", 6),
    cue("story_choir", "Vael's Choir", "Choir cutscenes (Vael's choir, cutscene 18)", "Eb aeolian", 71, "4/4", 16, 0,
        "chant 6 | bells 4 | chant 6", ["choir unison", "low bells", "drone"], "The lullaby backwards (the Waking Song), phrase 7.",
        "Ritual, wrong, beautiful.", "theme", 6),
    cue("boss_vael", "The Waking Song", "Cantor Vael", "Bb minor", 120, "3/4", 48, 0,
        "A 16 | B 16 (the Waking Song) | C 16", ["choir", "organ", "strings", "timpani", "bells"],
        "The whole lullaby in retrograde: the Waking Song.", "A sung duel; grand and tragic.", "combat", 6),
    cue("boss_heart", "The Dreaming Heart", "The Dreaming Heart, the final fight", "D minor", 144, "4/4", 48, 2,
        "intro 2 | A 16 | B 16 (lullaby in full, augmented) | C 14", ["full strings", "choir", "brass", "timpani",
        "the seven bells, one each"], "All seven phrases in order, each on its own bell.",
        "Everything at once, and the lullaby wins.", "combat", 6),
    cue("story_danger", "Undertow", "Tense story moments", "B minor", 134, "4/4", 16, 0,
        "A 6 (ostinato builds) | B 6 | A' 4 (drops to pulse)", ["string ostinato", "toms", "low brass"], "Phrase 4 diminished.",
        "Something is wrong, move.", "combat", 6),
    cue("story_sorrow", "Grief in the Water", "Sad story moments", "G minor", 56, "3/4", 16, 0,
        "cello alone 4 | A 8 (piano joins) | tail 4", ["solo cello", "felt piano", "soft pad"], "Phrase 4 on cello, very slow.",
        "Quiet loss, Hessa and Vael.", "theme", 6),
    cue("story_memory", "Half-Remembered", "Memories and visions: the frozen journal's ghosts, the last mural, the Old One dreams",
        "Db lydian", 54, "3/4", 24, 0, "pad alone 4 | memory 16 (phrase 6, half-remembered) | fade 4",
        ["warm pad", "celesta", "soft choir", "distant bell", "sub swell"],
        "Phrase 6 slowed and blurred, notes left out, on celesta.", "Soft focus; a memory surfacing through water.",
        "place", 6),
    cue("credits", "The Eighth Line", "Credits", "D major", 84, "3/4", 96, 0,
        "A 16 | B 16 | lullaby 16 (all seven phrases) | eighth line 8 | region medley 32 | close 8",
        ["full palette: harp, strings, flute, choir, bells"],
        "The whole lullaby turned to D major, then the eighth line Wren hums.",
        "Dawn. Relief, warmth, home.", "theme", 6, loop=False),
    cue("overworld", "(fallback)", "Only if a room has no region; not heard in the game today", "G mixolydian", 110,
        "4/4", 16, 0, "A 16", ["harp", "flute"], "Phrase 1.", "Spare fallback.", "explore", 6),
]

# Jingles live in audio/sfx/ (they duck the music), so they are listed apart.
JINGLES = [
    ("jingle_item", "An item: phrase 1's first three notes, rising to a held 5th", "D major", "harp + bell", 2.0),
    ("jingle_pearl", "A breath pearl: phrase 5's leap, then a shimmer", "D lydian", "celesta + choir", 2.0),
    ("jingle_secret", "A secret: four rising notes from phrase 3", "F major", "glass bell", 1.5),
    ("jingle_clear", "A dungeon cleared: phrase 7 cadence in major", "D major", "brass + timpani + bell", 3.0),
    ("jingle_bell", "Fallback bell chime (only if a phrase file is missing)", "D aeolian", "handbell", 1.5),
    ("jingle_game_over", "Game over: phrase 4 falling, unresolved", "D aeolian", "low strings + bell", 3.0),
    ("jingle_puzzle", "A puzzle solved: two notes, a 4th up", "A major", "marimba", 1.0),
]

# Cues the player hears back to back. Neighbours never share key or tempo.
NEIGHBOURS = [
    ("title", "region_saltmarrow"), ("region_saltmarrow", "place_village"), ("place_village", "place_shop"),
    ("place_village", "place_house"), ("region_saltmarrow", "region_brinewood"), ("region_saltmarrow", "region_sunken_verge"),
    ("region_saltmarrow", "region_maw"), ("region_brinewood", "dungeon_hull"), ("region_brinewood", "region_gloamfen"),
    ("region_brinewood", "region_cinderreach"), ("region_brinewood", "region_windmere"), ("region_brinewood", "region_ossuary"),
    ("region_cinderreach", "dungeon_kiln"), ("region_gloamfen", "dungeon_mire"), ("region_windmere", "dungeon_gale"),
    ("region_windmere", "region_frostspine"), ("region_frostspine", "dungeon_glacier"), ("region_sunken_verge", "dungeon_belfry"),
    ("region_ossuary", "dungeon_tomb"), ("region_maw", "dungeon_maw"), ("dungeon_maw", "boss_vael"), ("boss_vael", "boss_heart"),
    ("boss_heart", "credits"), ("dungeon_cellar", "region_saltmarrow"), ("place_cave", "region_brinewood"),
    ("place_spring", "region_brinewood"), ("miniboss", "boss"), ("story_memory", "dungeon_glacier"),
    ("story_memory", "dungeon_tomb"), ("story_memory", "region_saltmarrow"),
] + [(f"dungeon_{d}", "boss") for d in ["hull", "kiln", "mire", "gale", "glacier", "belfry", "tomb"]]


def check() -> list[str]:
    by_id = {c["id"]: c for c in CUES}
    problems = []
    for a, b in NEIGHBOURS:
        ca, cb = by_id[a], by_id[b]
        if ca["key"] == cb["key"]:
            problems.append(f"{a} and {b} share the key {ca['key']}")
        if ca["tempo"] == cb["tempo"]:
            problems.append(f"{a} and {b} share the tempo {ca['tempo']}")
    loops = [c for c in CUES if c["loop"]]
    tempos = [c["tempo"] for c in loops]
    for t in set(tempos):
        if tempos.count(t) > 1:
            problems.append(f"tempo {t} is used by {[c['id'] for c in loops if c['tempo'] == t]}")
    forms = [c["form"] for c in loops]
    for f in set(forms):
        if forms.count(f) > 1:
            problems.append(f"form '{f}' is used by {[c['id'] for c in loops if c['form'] == f]}")
    return problems


def mmss(s: float) -> str:
    return f"{int(s // 60)}:{int(round(s % 60)):02d}"


def write_markdown(path: str) -> None:
    lines = ["# Leviathan soundtrack: track sheet", "",
             "Generated by `music/track_sheet.py`; edit that file, not this one.", "",
             "| # | Cue | Title | Style | Key | Tempo | Meter | Loop (intro + body) | Palette | Lullaby | Character | LUFS |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for i, c in enumerate(CUES, 1):
        length = (f"{mmss(c['intro_s'])} + {mmss(c['body_s'])}" if c["intro_bars"] else mmss(c["body_s"])) \
            if c["loop"] else f"{mmss(c['body_s'])} once"
        lines.append(f"| {i} | `{c['id']}` | {c['name']} | {c['style']} | {c['key']} | {c['tempo']} | {c['meter']} | {length} | "
                     f"{', '.join(c['palette'])} | {c['motif']} | {c['character']} | {c['lufs']:.0f} |")
    lines += ["", "## Forms", ""]
    lines += [f"- `{c['id']}` ({c['bars']} bars): {c['form']}" for c in CUES]
    lines += ["", "## Jingles (audio/sfx, -16 LUFS short-term, no loop)", ""]
    lines += [f"- `{j[0]}` ({j[4]:.1f} s, {j[2]}, {j[3]}): {j[1]}" for j in JINGLES]
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    problems = check()
    with open(os.path.join(HERE, "track_sheet.json"), "w") as f:
        json.dump({"cues": CUES, "jingles": JINGLES, "bells": BELLS}, f, indent=1)
    write_markdown(os.path.join(HERE, "TRACK_SHEET.md"))
    total = sum(c["intro_s"] + c["body_s"] for c in CUES)
    print(f"{len(CUES)} cues, {mmss(total)} of music, {len(JINGLES)} jingles")
    for p in problems:
        print("PROBLEM:", p)
    raise SystemExit(1 if problems else 0)
