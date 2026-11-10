extends Node
## Music, sound effects, ambience and sound captions.
##
## Music: play_music("region_saltmarrow") plays res://audio/music/<cue>.ogg
## and crossfades from whatever was playing. A cue with no file yet is
## silent, so Ash's FL Studio tracks drop in by file name with no code
## changes. Loop points come from the OGG import settings.
##
## Effects: play_sfx("sword_swing", position) plays res://audio/sfx/<id>.ogg
## (or .wav). Until a real sound exists, a short chiptune placeholder is
## synthesised from SFX below, so every hook already makes a noise.
##
## Captions: effects with a caption key show a caption when the player has
## captions on (Options > Sound captions). Events.caption carries it.

const MUSIC_DIR := "res://audio/music/"
const SFX_DIR := "res://audio/sfx/"
const AMBIENCE_DIR := "res://audio/ambience/"
const MIX_RATE := 22050
const FADE_TIME := 1.2
## How far the music dips under a jingle or a bell's phrase.
const DUCK_DB := -18.0
## Effects playing at once. Extra ones steal the oldest player.
const VOICES := 12
## The same effect retriggered faster than this is skipped (footsteps,
## multi-hits), so stacks don't clip.
const RETRIGGER_MSEC := 40

## Every music cue in the plan, by id, so missing files are easy to list.
const MUSIC_CUES := [
	"title", "overworld", "lullaby", "credits",
	"bell_1", "bell_2", "bell_3", "bell_4", "bell_5", "bell_6", "bell_7",
	"region_saltmarrow", "region_brinewood", "region_cinderreach", "region_gloamfen",
	"region_windmere", "region_frostspine", "region_sunken_verge", "region_ossuary", "region_maw",
	"dungeon_cellar", "dungeon_hull", "dungeon_kiln", "dungeon_mire", "dungeon_gale",
	"dungeon_glacier", "dungeon_belfry", "dungeon_tomb", "dungeon_maw",
	"boss", "miniboss", "boss_vael", "boss_heart",
	"place_village", "place_shop", "place_house", "place_cave", "place_spring", "place_choir",
	"story_danger", "story_sorrow", "story_choir", "story_flight",
]
## Music cues that play once (the lullaby phrases); every other cue loops.
const ONE_SHOT_MUSIC := ["lullaby", "bell_1", "bell_2", "bell_3", "bell_4", "bell_5", "bell_6", "bell_7"]
## The seven Tidebells in lullaby order: bell_1.ogg is the Hull's phrase.
## tools/music_gen.py weaves the same phrase into each dungeon's track.
const BELL_ORDER := ["hull", "kiln", "mire", "gale", "glacier", "belfry", "tomb"]
## Short jingles: they duck the music and don't loop.
const JINGLES := ["jingle_item", "jingle_pearl", "jingle_secret", "jingle_clear",
	"jingle_bell", "jingle_game_over", "jingle_puzzle"]

## Placeholder synth for each effect, and its caption (or "").
## wave: square, triangle, noise. f0 -> f1 is a pitch slide in Hz over dur
## seconds; vol 0..1; steps > 0 makes an arpeggio of that many notes
## (each a fifth or third up).
const SFX := {
	# Player
	"sword_swing": {"wave": "noise", "f0": 1800.0, "f1": 600.0, "dur": 0.09, "vol": 0.35},
	"sword_spin": {"wave": "noise", "f0": 800.0, "f1": 2400.0, "dur": 0.25, "vol": 0.4},
	"spin_charged": {"wave": "square", "f0": 880.0, "f1": 1320.0, "dur": 0.12, "vol": 0.25, "steps": 2, "caption": "CAPTION_CHARGED"},
	"player_hurt": {"wave": "square", "f0": 420.0, "f1": 140.0, "dur": 0.18, "vol": 0.45},
	"bubble_pop": {"wave": "triangle", "f0": 900.0, "f1": 1800.0, "dur": 0.07, "vol": 0.45},
	"hum": {"wave": "triangle", "f0": 330.0, "f1": 330.0, "dur": 0.35, "vol": 0.3, "caption": "CAPTION_HUM"},
	"hum_heal": {"wave": "triangle", "f0": 523.0, "f1": 784.0, "dur": 0.3, "vol": 0.4, "steps": 3},
	"player_fall": {"wave": "square", "f0": 600.0, "f1": 90.0, "dur": 0.45, "vol": 0.35},
	# Tools
	"hook_fire": {"wave": "noise", "f0": 2600.0, "f1": 1200.0, "dur": 0.12, "vol": 0.3},
	"hook_latch": {"wave": "square", "f0": 1400.0, "f1": 900.0, "dur": 0.06, "vol": 0.35},
	"bomb_fuse": {"wave": "noise", "f0": 5000.0, "f1": 5000.0, "dur": 0.3, "vol": 0.15, "caption": "CAPTION_FUSE"},
	"bomb_blast": {"wave": "noise", "f0": 400.0, "f1": 60.0, "dur": 0.5, "vol": 0.7, "caption": "CAPTION_BLAST"},
	"wayshell": {"wave": "triangle", "f0": 392.0, "f1": 392.0, "dur": 0.8, "vol": 0.45, "steps": 3, "caption": "CAPTION_WAYSHELL"},
	"lantern_up": {"wave": "triangle", "f0": 660.0, "f1": 990.0, "dur": 0.18, "vol": 0.3, "steps": 2},
	"lantern_down": {"wave": "triangle", "f0": 660.0, "f1": 440.0, "dur": 0.14, "vol": 0.25},
	"brazier_catch": {"wave": "noise", "f0": 900.0, "f1": 2400.0, "dur": 0.3, "vol": 0.35, "caption": "CAPTION_FLAME"},
	"wisp_chime": {"wave": "triangle", "f0": 1568.0, "f1": 1568.0, "dur": 0.25, "vol": 0.2, "steps": 2, "caption": "CAPTION_WISP"},
	"glass_chime": {"wave": "triangle", "f0": 1760.0, "f1": 1760.0, "dur": 0.4, "vol": 0.2, "steps": 3, "caption": "CAPTION_GLASS_CHIME"},
	"heart_beat": {"wave": "triangle", "f0": 110.0, "f1": 70.0, "dur": 0.22, "vol": 0.5, "caption": "CAPTION_HEARTBEAT"},
	"cloak_open": {"wave": "noise", "f0": 1400.0, "f1": 500.0, "dur": 0.2, "vol": 0.3, "caption": "CAPTION_CLOAK"},
	"thunder": {"wave": "noise", "f0": 300.0, "f1": 40.0, "dur": 0.9, "vol": 0.7, "caption": "CAPTION_THUNDER"},
	"storm_gather": {"wave": "noise", "f0": 2000.0, "f1": 4000.0, "dur": 1.2, "vol": 0.25, "caption": "CAPTION_STORM"},
	"heron_cry": {"wave": "square", "f0": 900.0, "f1": 500.0, "dur": 0.35, "vol": 0.35, "caption": "CAPTION_HERON"},
	"wingbeat": {"wave": "noise", "f0": 250.0, "f1": 120.0, "dur": 0.3, "vol": 0.3, "caption": "CAPTION_WINGBEAT"},
	"bow_draw": {"wave": "square", "f0": 180.0, "f1": 260.0, "dur": 0.12, "vol": 0.18},
	"bow_loose": {"wave": "noise", "f0": 3000.0, "f1": 1200.0, "dur": 0.12, "vol": 0.3},
	"ice_freeze": {"wave": "noise", "f0": 5000.0, "f1": 2500.0, "dur": 0.35, "vol": 0.3, "caption": "CAPTION_FREEZE"},
	"ice_shatter": {"wave": "noise", "f0": 6000.0, "f1": 1500.0, "dur": 0.2, "vol": 0.35, "caption": "CAPTION_ICE_SHATTER"},
	"ice_eye_open": {"wave": "sine", "f0": 880.0, "f1": 1320.0, "dur": 0.3, "vol": 0.3, "caption": "CAPTION_EYE_OPEN"},
	"ice_eye_shut": {"wave": "sine", "f0": 1100.0, "f1": 660.0, "dur": 0.25, "vol": 0.25, "caption": "CAPTION_EYE_SHUT"},
	"rimeling_squeak": {"wave": "square", "f0": 1400.0, "f1": 2000.0, "dur": 0.08, "vol": 0.2, "caption": "CAPTION_SQUEAK"},
	"ice_groan": {"wave": "noise", "f0": 180.0, "f1": 90.0, "dur": 1.2, "vol": 0.5, "caption": "CAPTION_ICE_GROAN"},
	"walrus_bellow": {"wave": "square", "f0": 140.0, "f1": 90.0, "dur": 0.6, "vol": 0.45, "caption": "CAPTION_WALRUS"},
	"splash": {"wave": "noise", "f0": 1200.0, "f1": 300.0, "dur": 0.3, "vol": 0.35, "caption": "CAPTION_SPLASH"},
	"valve_turn": {"wave": "square", "f0": 160.0, "f1": 200.0, "dur": 0.5, "vol": 0.25, "caption": "CAPTION_VALVE"},
	"water_rush": {"wave": "noise", "f0": 600.0, "f1": 200.0, "dur": 1.4, "vol": 0.45, "caption": "CAPTION_WATER_RUSH"},
	"great_bell": {"wave": "sine", "f0": 196.0, "f1": 190.0, "dur": 1.6, "vol": 0.6, "caption": "CAPTION_GREAT_BELL"},
	"tentacle_cut": {"wave": "noise", "f0": 2200.0, "f1": 600.0, "dur": 0.2, "vol": 0.35, "caption": "CAPTION_TENTACLE"},
	"horn_blow": {"wave": "sine", "f0": 147.0, "f1": 139.0, "dur": 0.8, "vol": 0.55, "caption": "CAPTION_HORN"},
	"bone_crumble": {"wave": "noise", "f0": 1600.0, "f1": 300.0, "dur": 0.45, "vol": 0.45, "caption": "CAPTION_BONE_CRUMBLE"},
	"skull_sing": {"wave": "sine", "f0": 294.0, "f1": 294.0, "dur": 0.9, "vol": 0.35, "caption": "CAPTION_SKULL_SING"},
	"skull_quiet": {"wave": "sine", "f0": 294.0, "f1": 220.0, "dur": 0.3, "vol": 0.2, "caption": "CAPTION_SKULL_QUIET"},
	"bone_rattle": {"wave": "noise", "f0": 3000.0, "f1": 2000.0, "dur": 0.25, "vol": 0.3, "caption": "CAPTION_BONE_RATTLE"},
	"armour_shatter": {"wave": "noise", "f0": 2600.0, "f1": 500.0, "dur": 0.35, "vol": 0.5, "caption": "CAPTION_ARMOUR_SHATTER"},
	"hush_reveal": {"wave": "sine", "f0": 660.0, "f1": 440.0, "dur": 0.5, "vol": 0.3, "caption": "CAPTION_HUSH"},
	"regent_roar": {"wave": "square", "f0": 90.0, "f1": 60.0, "dur": 0.9, "vol": 0.45, "caption": "CAPTION_REGENT"},
	"regent_slam": {"wave": "noise", "f0": 400.0, "f1": 80.0, "dur": 0.4, "vol": 0.55, "caption": "CAPTION_SCEPTRE"},
	"maw_breath_in": {"wave": "noise", "f0": 300.0, "f1": 120.0, "dur": 1.6, "vol": 0.45, "caption": "CAPTION_MAW_BREATH_IN"},
	"maw_breath_out": {"wave": "noise", "f0": 160.0, "f1": 400.0, "dur": 1.4, "vol": 0.35, "caption": "CAPTION_MAW_BREATH_OUT"},
	"vael_sing": {"wave": "sine", "f0": 330.0, "f1": 349.0, "dur": 0.5, "vol": 0.35, "caption": "CAPTION_VAEL_SING"},
	"vael_falter": {"wave": "sine", "f0": 349.0, "f1": 220.0, "dur": 0.6, "vol": 0.4, "caption": "CAPTION_VAEL_FALTER"},
	"note_reflect": {"wave": "triangle", "f0": 660.0, "f1": 990.0, "dur": 0.2, "vol": 0.35, "caption": "CAPTION_NOTE_REFLECT"},
	"choir_chant": {"wave": "square", "f0": 147.0, "f1": 147.0, "dur": 1.0, "vol": 0.3, "caption": "CAPTION_CHANT"},
	"heart_roar": {"wave": "square", "f0": 70.0, "f1": 45.0, "dur": 1.4, "vol": 0.5, "caption": "CAPTION_HEART_ROAR"},
	"echo_rise": {"wave": "sine", "f0": 220.0, "f1": 330.0, "dur": 0.8, "vol": 0.3, "caption": "CAPTION_ECHO_RISE"},
	"echo_calm": {"wave": "sine", "f0": 440.0, "f1": 220.0, "dur": 1.2, "vol": 0.3, "caption": "CAPTION_ECHO_CALM"},
	"old_one_hum": {"wave": "sine", "f0": 55.0, "f1": 52.0, "dur": 3.0, "vol": 0.6, "caption": "CAPTION_OLD_ONE_HUM"},
	"knell_moan": {"wave": "square", "f0": 110.0, "f1": 70.0, "dur": 0.8, "vol": 0.4, "caption": "CAPTION_KNELL"},
	"hook_reel": {"wave": "square", "f0": 300.0, "f1": 520.0, "dur": 0.3, "vol": 0.25},
	"stonebreaker_slam": {"wave": "noise", "f0": 600.0, "f1": 80.0, "dur": 0.35, "vol": 0.6, "caption": "CAPTION_SLAM"},
	"ice_slide": {"wave": "noise", "f0": 6000.0, "f1": 4000.0, "dur": 0.3, "vol": 0.15},
	"block_push": {"wave": "noise", "f0": 500.0, "f1": 300.0, "dur": 0.4, "vol": 0.3, "caption": "CAPTION_SCRAPE"},
	"mantle_wings": {"wave": "noise", "f0": 300.0, "f1": 150.0, "dur": 0.5, "vol": 0.35, "caption": "CAPTION_WINGS"},
	# Creatures: each has its own warning, so a player learns them by ear.
	"scuttler_snap": {"wave": "square", "f0": 1500.0, "f1": 900.0, "dur": 0.1, "vol": 0.3, "caption": "CAPTION_SNAP"},
	"scuttler_skitter": {"wave": "noise", "f0": 6000.0, "f1": 6000.0, "dur": 0.2, "vol": 0.2, "caption": "CAPTION_SKITTER"},
	"shell_clack": {"wave": "square", "f0": 900.0, "f1": 700.0, "dur": 0.08, "vol": 0.3, "caption": "CAPTION_CLACK"},
	"skipper_croak": {"wave": "square", "f0": 180.0, "f1": 140.0, "dur": 0.25, "vol": 0.3, "caption": "CAPTION_CROAK"},
	"skipper_burrow": {"wave": "noise", "f0": 1500.0, "f1": 300.0, "dur": 0.3, "vol": 0.25, "caption": "CAPTION_BURROW"},
	"moth_flutter": {"wave": "noise", "f0": 1400.0, "f1": 900.0, "dur": 0.35, "vol": 0.2, "caption": "CAPTION_WINGS"},
	"moth_flare": {"wave": "triangle", "f0": 600.0, "f1": 1500.0, "dur": 0.35, "vol": 0.3, "caption": "CAPTION_TELL"},
	"burr_roll": {"wave": "noise", "f0": 1800.0, "f1": 1000.0, "dur": 0.4, "vol": 0.2, "caption": "CAPTION_BURR"},
	"spitter_gulp": {"wave": "triangle", "f0": 200.0, "f1": 420.0, "dur": 0.3, "vol": 0.3, "caption": "CAPTION_GULP"},
	# Bosses: a warning of their own before each big attack.
	"regent_raise": {"wave": "noise", "f0": 500.0, "f1": 2200.0, "dur": 0.6, "vol": 0.4, "caption": "CAPTION_TELL"},
	"regent_gather": {"wave": "noise", "f0": 900.0, "f1": 4000.0, "dur": 0.5, "vol": 0.35, "caption": "CAPTION_TELL"},
	"rime_gather": {"wave": "noise", "f0": 2500.0, "f1": 5000.0, "dur": 0.55, "vol": 0.3, "caption": "CAPTION_TELL"},
	"knell_ink": {"wave": "sine", "f0": 95.0, "f1": 130.0, "dur": 0.6, "vol": 0.4, "caption": "CAPTION_TELL"},
	"vael_breath": {"wave": "noise", "f0": 600.0, "f1": 2600.0, "dur": 0.7, "vol": 0.3, "caption": "CAPTION_TELL"},
	"wyrm_gurgle": {"wave": "noise", "f0": 300.0, "f1": 1000.0, "dur": 0.6, "vol": 0.4, "caption": "CAPTION_TELL"},
	"matriarch_tell": {"wave": "noise", "f0": 4000.0, "f1": 3000.0, "dur": 0.5, "vol": 0.35, "caption": "CAPTION_TELL"},
	"wyrm_tell": {"wave": "noise", "f0": 200.0, "f1": 1800.0, "dur": 0.7, "vol": 0.45, "caption": "CAPTION_RUMBLE"},
	"congregation_tell": {"wave": "triangle", "f0": 330.0, "f1": 349.0, "dur": 0.7, "vol": 0.35, "caption": "CAPTION_TELL"},
	"heron_tell": {"wave": "square", "f0": 700.0, "f1": 1400.0, "dur": 0.4, "vol": 0.3, "caption": "CAPTION_TELL"},
	"boss_fall": {"wave": "noise", "f0": 800.0, "f1": 60.0, "dur": 1.6, "vol": 0.6, "caption": "CAPTION_BOSS_FALL"},
	# Combat
	"hit_flesh": {"wave": "noise", "f0": 900.0, "f1": 300.0, "dur": 0.08, "vol": 0.5},
	"hit_shell": {"wave": "square", "f0": 1600.0, "f1": 1100.0, "dur": 0.07, "vol": 0.4, "caption": "CAPTION_CLANG"},
	"block": {"wave": "square", "f0": 2200.0, "f1": 1800.0, "dur": 0.05, "vol": 0.35, "caption": "CAPTION_BLOCK"},
	"enemy_die": {"wave": "noise", "f0": 1200.0, "f1": 120.0, "dur": 0.25, "vol": 0.45, "caption": "CAPTION_ENEMY_DIE"},
	"enemy_tell": {"wave": "square", "f0": 300.0, "f1": 600.0, "dur": 0.2, "vol": 0.3, "caption": "CAPTION_TELL"},
	"enemy_shot": {"wave": "square", "f0": 700.0, "f1": 350.0, "dur": 0.1, "vol": 0.3, "caption": "CAPTION_SHOT"},
	"boss_roar": {"wave": "noise", "f0": 220.0, "f1": 80.0, "dur": 0.9, "vol": 0.6, "caption": "CAPTION_ROAR"},
	# World
	"chest_open": {"wave": "square", "f0": 392.0, "f1": 392.0, "dur": 0.35, "vol": 0.35, "steps": 4, "caption": "CAPTION_CHEST"},
	"key_get": {"wave": "square", "f0": 988.0, "f1": 988.0, "dur": 0.2, "vol": 0.3, "steps": 2, "caption": "CAPTION_KEY"},
	"door_unlock": {"wave": "square", "f0": 500.0, "f1": 250.0, "dur": 0.15, "vol": 0.4, "caption": "CAPTION_UNLOCK"},
	"door_locked": {"wave": "square", "f0": 180.0, "f1": 170.0, "dur": 0.12, "vol": 0.35, "caption": "CAPTION_LOCKED"},
	"switch": {"wave": "square", "f0": 660.0, "f1": 440.0, "dur": 0.06, "vol": 0.35, "caption": "CAPTION_SWITCH"},
	"pot_break": {"wave": "noise", "f0": 3000.0, "f1": 800.0, "dur": 0.15, "vol": 0.4, "caption": "CAPTION_POT"},
	"grass_cut": {"wave": "noise", "f0": 5000.0, "f1": 3000.0, "dur": 0.1, "vol": 0.25},
	"potion_drink": {"wave": "sine", "f0": 420.0, "f1": 990.0, "dur": 0.5, "vol": 0.3, "steps": 3, "caption": "CAPTION_DRINK"},
	"oil_pour": {"wave": "noise", "f0": 600.0, "f1": 2000.0, "dur": 0.6, "vol": 0.25, "caption": "CAPTION_OIL"},
	# Overworld hazards
	"gust": {"wave": "noise", "f0": 300.0, "f1": 900.0, "dur": 0.9, "vol": 0.3, "caption": "CAPTION_GUST"},
	"geyser_hiss": {"wave": "noise", "f0": 5000.0, "f1": 4000.0, "dur": 0.5, "vol": 0.2, "caption": "CAPTION_HISS"},
	"geyser_blow": {"wave": "noise", "f0": 1200.0, "f1": 300.0, "dur": 0.8, "vol": 0.4, "caption": "CAPTION_GEYSER"},
	"beetle_crack": {"wave": "square", "f0": 240.0, "f1": 120.0, "dur": 0.2, "vol": 0.3, "caption": "CAPTION_TELL"},
	"spore_swell": {"wave": "triangle", "f0": 300.0, "f1": 600.0, "dur": 0.5, "vol": 0.25, "caption": "CAPTION_TELL"},
	"spore_burst": {"wave": "noise", "f0": 2200.0, "f1": 600.0, "dur": 0.3, "vol": 0.35, "caption": "CAPTION_SPORES"},
	"seal_bark": {"wave": "square", "f0": 330.0, "f1": 220.0, "dur": 0.25, "vol": 0.3, "caption": "CAPTION_TELL"},
	"tide_rise": {"wave": "noise", "f0": 400.0, "f1": 1400.0, "dur": 1.6, "vol": 0.3, "caption": "CAPTION_TIDE"},
	"tide_ebb": {"wave": "noise", "f0": 1400.0, "f1": 300.0, "dur": 1.6, "vol": 0.3, "caption": "CAPTION_TIDE_EBB"},
	"fish_jump": {"wave": "noise", "f0": 2400.0, "f1": 900.0, "dur": 0.18, "vol": 0.12},
	"tide_sweep": {"wave": "noise", "f0": 1600.0, "f1": 300.0, "dur": 0.5, "vol": 0.4, "caption": "CAPTION_TIDE_SWEEP"},
	"sand_hiss": {"wave": "noise", "f0": 3000.0, "f1": 1800.0, "dur": 0.5, "vol": 0.2, "caption": "CAPTION_SAND"},
	"jaw_rattle": {"wave": "noise", "f0": 900.0, "f1": 700.0, "dur": 0.5, "vol": 0.3, "steps": 5, "caption": "CAPTION_TELL"},
	"jaw_snap": {"wave": "square", "f0": 260.0, "f1": 90.0, "dur": 0.15, "vol": 0.4, "caption": "CAPTION_JAW"},
	"ray_splash": {"wave": "noise", "f0": 2400.0, "f1": 900.0, "dur": 0.3, "vol": 0.3, "caption": "CAPTION_TELL"},
	"tidestone_wake": {"wave": "triangle", "f0": 196.0, "f1": 196.0, "dur": 0.9, "vol": 0.5, "steps": 4, "caption": "CAPTION_TIDESTONE"},
	"toll_rattle": {"wave": "square", "f0": 640.0, "f1": 600.0, "dur": 0.72, "vol": 0.2, "caption": "CAPTION_CLACK"},
	"toll_ring": {"wave": "triangle", "f0": 523.0, "f1": 520.0, "dur": 0.8, "vol": 0.3, "caption": "CAPTION_BELL_QUIET"},
	"puff_inhale": {"wave": "noise", "f0": 400.0, "f1": 1600.0, "dur": 0.5, "vol": 0.2, "caption": "CAPTION_GUST"},
	"puff_blow": {"wave": "noise", "f0": 1600.0, "f1": 400.0, "dur": 0.5, "vol": 0.3, "caption": "CAPTION_GUST"},
	"leech_rise": {"wave": "noise", "f0": 400.0, "f1": 1400.0, "dur": 0.5, "vol": 0.25, "caption": "CAPTION_TELL"},
	"leech_bite": {"wave": "noise", "f0": 2400.0, "f1": 700.0, "dur": 0.12, "vol": 0.3, "caption": "CAPTION_SNAP"},
	"bell_quiet": {"wave": "triangle", "f0": 392.0, "f1": 390.0, "dur": 0.6, "vol": 0.2, "caption": "CAPTION_BELL_QUIET"},
	"bell_ring": {"wave": "triangle", "f0": 784.0, "f1": 780.0, "dur": 1.2, "vol": 0.5, "caption": "CAPTION_BELL"},
	"choir_waking": {"wave": "sine", "f0": 220.0, "f1": 330.0, "dur": 2.4, "vol": 0.35, "steps": 4, "caption": "CAPTION_CHOIR"},
	"old_one_rumble": {"wave": "noise", "f0": 90.0, "f1": 35.0, "dur": 2.5, "vol": 0.6, "caption": "CAPTION_DEEP_RUMBLE"},
	"secret": {"wave": "square", "f0": 523.0, "f1": 523.0, "dur": 0.5, "vol": 0.3, "steps": 4, "caption": "CAPTION_SECRET"},
	"door_slide": {"wave": "noise", "f0": 200.0, "f1": 120.0, "dur": 0.4, "vol": 0.4, "caption": "CAPTION_DOOR"},
	# Interface
	"ui_move": {"wave": "square", "f0": 880.0, "f1": 880.0, "dur": 0.03, "vol": 0.18},
	"ui_select": {"wave": "square", "f0": 660.0, "f1": 990.0, "dur": 0.08, "vol": 0.22},
	"ui_back": {"wave": "square", "f0": 660.0, "f1": 440.0, "dur": 0.08, "vol": 0.22},
	"shop_buy": {"wave": "square", "f0": 1320.0, "f1": 1760.0, "dur": 0.16, "vol": 0.25, "steps": 2, "caption": "CAPTION_SHOP_BUY"},
	"shop_short": {"wave": "square", "f0": 220.0, "f1": 180.0, "dur": 0.14, "vol": 0.25, "caption": "CAPTION_SHOP_SHORT"},
	"ui_open": {"wave": "triangle", "f0": 440.0, "f1": 660.0, "dur": 0.1, "vol": 0.3},
	"text_blip": {"wave": "square", "f0": 1100.0, "f1": 1100.0, "dur": 0.02, "vol": 0.1},
	"pickup": {"wave": "square", "f0": 1320.0, "f1": 1760.0, "dur": 0.06, "vol": 0.25},
	"save": {"wave": "triangle", "f0": 523.0, "f1": 523.0, "dur": 0.4, "vol": 0.35, "steps": 3, "caption": "CAPTION_SAVE"},
	# Jingles (until Ash's real ones exist)
	"jingle_item": {"wave": "square", "f0": 523.0, "f1": 523.0, "dur": 0.7, "vol": 0.3, "steps": 4, "caption": "CAPTION_ITEM"},
	"jingle_pearl": {"wave": "triangle", "f0": 784.0, "f1": 784.0, "dur": 0.9, "vol": 0.35, "steps": 4, "caption": "CAPTION_PEARL"},
	"jingle_secret": {"wave": "square", "f0": 440.0, "f1": 880.0, "dur": 0.8, "vol": 0.28, "steps": 4, "caption": "CAPTION_SECRET"},
	"jingle_bell": {"wave": "triangle", "f0": 392.0, "f1": 392.0, "dur": 1.4, "vol": 0.4, "steps": 5, "caption": "CAPTION_BELL"},
	"jingle_puzzle": {"wave": "square", "f0": 659.0, "f1": 659.0, "dur": 0.5, "vol": 0.28, "steps": 3, "caption": "CAPTION_PUZZLE"},
	"jingle_game_over": {"wave": "triangle", "f0": 392.0, "f1": 196.0, "dur": 1.4, "vol": 0.4, "caption": "CAPTION_GAME_OVER"},
	"jingle_clear": {"wave": "square", "f0": 523.0, "f1": 523.0, "dur": 1.0, "vol": 0.3, "steps": 5, "caption": "CAPTION_CLEAR"},
}

var music_cue := ""
var _music: Array[AudioStreamPlayer] = []
var _music_index := 0
var _ambience: AudioStreamPlayer
var _ambience_tween: Tween
var _ambience_id := ""
var _voices: Array[AudioStreamPlayer2D] = []
var _flat_voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _streams: Dictionary = {}
var _prewarm_task := -1
var _last_played: Dictionary = {}
var _warned: Dictionary = {}
var _duck_tween: Tween
var _music_tween: Tween
## Two gains per music player, added together every frame: its cross-fade,
## and the dip under jingles and bell phrases. Kept apart so a jingle during
## a fade still dips, and a cue change during a phrase stays dipped.
var _fade_db: Array[float] = [-60.0, -60.0]
var _duck_db := 0.0
## Plays the lullaby phrases over the (ducked) music.
var _phrase: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		_music.append(player)
	_phrase = AudioStreamPlayer.new()
	_phrase.bus = "Music"
	add_child(_phrase)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Ambience"
	add_child(_ambience)
	for i in VOICES:
		var voice := AudioStreamPlayer2D.new()
		voice.bus = "Effects"
		voice.max_distance = 600.0
		add_child(voice)
		_voices.append(voice)
		var flat := AudioStreamPlayer.new()
		flat.bus = "Effects"
		add_child(flat)
		_flat_voices.append(flat)
	# Building a placeholder takes up to ~15 ms: do them all off the main
	# thread now, so the first sword swing or bell doesn't hitch a frame.
	if OS.has_feature("web"):
		# The browser build has no worker threads, so the task would run
		# here and hold up the first frame: build a few sounds per frame.
		_prewarm_gradually()
	else:
		_prewarm_task = WorkerThreadPool.add_task(_prewarm)


func _exit_tree() -> void:
	if _prewarm_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_prewarm_task)
		_prewarm_task = -1


## Runs on a worker thread: synthesises every effect that has no file.
func _prewarm() -> void:
	var built := {}
	for id: String in SFX:
		if not (ResourceLoader.exists(SFX_DIR + id + ".ogg") or ResourceLoader.exists(SFX_DIR + id + ".wav")):
			built[id] = synth(SFX[id])
	_take_prewarmed.call_deferred(built)


func _prewarm_gradually() -> void:
	var count := 0
	for id: String in SFX:
		if _streams.has(id) or ResourceLoader.exists(SFX_DIR + id + ".ogg") or ResourceLoader.exists(SFX_DIR + id + ".wav"):
			continue
		_streams[id] = synth(SFX[id])
		count += 1
		if count % 3 == 0:
			await get_tree().process_frame


func _take_prewarmed(built: Dictionary) -> void:
	for id: String in built:
		if not _streams.has(id):
			_streams[id] = built[id]


# --------------------------------------------------------------------------
# Music
# --------------------------------------------------------------------------

## Crossfades to a cue. Same cue again does nothing. "" fades out.
func play_music(cue: String, fade: float = FADE_TIME) -> void:
	if cue == music_cue:
		return
	music_cue = cue
	var old := _music[_music_index]
	_music_index = 1 - _music_index
	var new := _music[_music_index]
	var stream := _load(MUSIC_DIR, cue) if cue != "" else null
	# A cue change mid-fade or mid-jingle: the old tweens would otherwise
	# keep pushing (and later stop) the player about to be reused.
	if _music_tween:
		_music_tween.kill()
	new.stop()
	_fade_db[_music_index] = -60.0
	if not old.playing and stream == null:
		_apply_music_volume()
		return
	var old_index := 1 - _music_index
	_music_tween = create_tween().set_parallel(true)
	if old.playing:
		_music_tween.tween_method(_set_fade.bind(old_index), _fade_db[old_index], -60.0, fade)
		_music_tween.tween_callback(old.stop).set_delay(fade)
	if stream:
		new.stream = stream if cue in ONE_SHOT_MUSIC else _looping(stream)
		new.play()
		_music_tween.tween_method(_set_fade.bind(_music_index), -60.0, 0.0, fade)
	_apply_music_volume()


func _set_fade(db: float, index: int) -> void:
	_fade_db[index] = db
	_apply_music_volume()


func _set_duck(db: float) -> void:
	_duck_db = db
	_apply_music_volume()


func _apply_music_volume() -> void:
	for i in _music.size():
		_music[i].volume_db = maxf(_fade_db[i] + _duck_db, -80.0)


## Fades the music out, and cuts off a lullaby phrase still ringing.
func stop_music(fade: float = FADE_TIME) -> void:
	_phrase.stop()
	play_music("", fade)


## A jingle: the music dips while it plays, then comes back.
func play_jingle(id: String) -> void:
	play_sfx(id)
	_duck(_stream_length(id))


## A Tidebell's phrase of the lullaby (bell_N.ogg) over the dipped music.
## Falls back to the bell jingle while the phrase has no file.
func play_bell_phrase(bell_id: String) -> void:
	var index := BELL_ORDER.find(bell_id)
	if index < 0 or not _play_phrases([index]):
		play_jingle("jingle_bell")


## The lullaby as far as Wren knows it: the first `count` phrases in a row.
func play_lullaby(count: int) -> void:
	var phrases: Array[int] = []
	for i in clampi(count, 0, BELL_ORDER.size()):
		phrases.append(i)
	_play_phrases(phrases)


## Plays lullaby phrases (0-based) back to back. False when none has a file.
func _play_phrases(phrases: Array) -> bool:
	var playlist := AudioStreamPlaylist.new()
	playlist.loop = false
	playlist.fade_time = 0.0
	var count := 0
	var length := 0.0
	for i: int in phrases:
		var stream := _load(MUSIC_DIR, "bell_%d" % (i + 1))
		if stream == null or count >= AudioStreamPlaylist.MAX_STREAMS:
			continue
		playlist.set_list_stream(count, stream)
		length += stream.get_length()
		count += 1
	if count == 0:
		return false
	playlist.stream_count = count
	_phrase.stream = playlist
	_phrase.play()
	_duck(length)
	return true


## Dips the music for `length` seconds, then brings it back. The dip holds
## across cue changes, so a new track comes in under a ringing phrase.
func _duck(length: float) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(_set_duck, _duck_db, DUCK_DB, 0.1)
	_duck_tween.tween_interval(length)
	_duck_tween.tween_method(_set_duck, DUCK_DB, 0.0, 0.6)


## Which music fits a room: its dungeon, else its region.
static func cue_for_room(biome: String, dungeon: String) -> String:
	if dungeon != "":
		return "dungeon_" + dungeon
	return "region_" + biome


# --------------------------------------------------------------------------
# Ambience
# --------------------------------------------------------------------------

## The background loop for a room: dungeons share one, the overworld has
## one per region.
static func ambience_for_room(biome: String, dungeon: String, own: String = "", cave: bool = false) -> String:
	if own != "":
		return own
	if dungeon != "":
		return "dungeon"
	return "hollow" if cave else biome


## Fades to an ambience loop (from audio/ambience/). "" fades it out.
func play_ambience(id: String, fade: float = FADE_TIME) -> void:
	if id == _ambience_id:
		return
	_ambience_id = id
	var stream := _load(AMBIENCE_DIR, id) if id != "" else null
	if _ambience_tween:
		_ambience_tween.kill()
	_ambience_tween = create_tween()
	# Back to the loop that is still fading out: bring it up, don't restart it.
	if _ambience.playing and stream != null and _ambience.stream == _looping(stream):
		_ambience_tween.tween_property(_ambience, "volume_db", 0.0, fade * 0.5)
		return
	if _ambience.playing:
		_ambience_tween.tween_property(_ambience, "volume_db", -40.0, fade * 0.5)
	if stream == null:
		_ambience_tween.tween_callback(_ambience.stop)
		return
	_ambience_tween.tween_callback(func() -> void:
		_ambience.stream = _looping(stream)
		_ambience.volume_db = -40.0
		_ambience.play())
	_ambience_tween.tween_property(_ambience, "volume_db", 0.0, fade * 0.5)


## A stream set to loop: an OGG from its loop offset, a WAV end to end.
## (Files whose import settings already loop are left as they are; this
## covers a file dropped in without them.)
static func _looping(stream: AudioStream) -> AudioStream:
	var ogg := stream as AudioStreamOggVorbis
	if ogg:
		if ogg.loop:
			return stream
		ogg = ogg.duplicate() as AudioStreamOggVorbis
		ogg.loop = true
		return ogg
	var wav := stream as AudioStreamWAV
	if wav == null or wav.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return stream
	wav = wav.duplicate() as AudioStreamWAV
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = int(wav.get_length() * wav.mix_rate)
	return wav


# --------------------------------------------------------------------------
# Effects
# --------------------------------------------------------------------------

## Plays an effect. With a position it is placed in the world (panned
## left or right); without one it plays flat (menus, jingles).
func play_sfx(id: String, at: Variant = null, pitch: float = 1.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(id, -100000)) < RETRIGGER_MSEC:
		return
	_last_played[id] = now
	var stream := _sfx_stream(id)
	if stream == null:
		return
	var slot := _next_voice
	_next_voice = (_next_voice + 1) % VOICES
	if at is Vector2:
		var voice := _voices[slot]
		voice.stream = stream
		voice.global_position = at
		voice.pitch_scale = pitch
		voice.play()
	else:
		var flat := _flat_voices[slot]
		flat.stream = stream
		flat.pitch_scale = pitch
		flat.play()
	var caption := str(SFX.get(id, {}).get("caption", ""))
	if caption != "" and Settings.captions:
		Events.caption.emit(caption, _side_of(at))


## Where a world position is on screen, for captions: -1 on the left third
## (or off the left edge), 1 on the right third, 0 in the middle or flat.
func _side_of(at: Variant) -> int:
	if not at is Vector2:
		return 0
	var view := get_viewport()
	var x: float = (view.get_canvas_transform() * (at as Vector2)).x
	var width: float = view.get_visible_rect().size.x
	if x < width / 3.0:
		return -1
	if x > width * 2.0 / 3.0:
		return 1
	return 0


func has_sfx(id: String) -> bool:
	return SFX.has(id) or _load(SFX_DIR, id) != null


func _sfx_stream(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var stream: AudioStream = _load(SFX_DIR, id)
	if stream == null and SFX.has(id):
		stream = synth(SFX[id])
	if stream == null:
		_warn("No sound for effect '%s'" % id)
	_streams[id] = stream
	return stream


func _stream_length(id: String) -> float:
	var stream := _sfx_stream(id)
	return stream.get_length() if stream else 0.0


## A file for an id in a folder (.ogg, then .wav), or null.
func _load(dir: String, id: String) -> AudioStream:
	for ext in [".ogg", ".wav"]:
		var path: String = dir + id + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func _warn(text: String) -> void:
	if not _warned.has(text):
		_warned[text] = true
		print(text)


## Builds a short 16-bit placeholder sound from a synth spec.
static func synth(spec: Dictionary) -> AudioStreamWAV:
	var dur: float = spec.get("dur", 0.1)
	var count := int(dur * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var f0: float = spec.get("f0", 440.0)
	var f1: float = spec.get("f1", f0)
	var vol: float = spec.get("vol", 0.3)
	var wave: String = spec.get("wave", "square")
	var steps: int = spec.get("steps", 0)
	var phase := 0.0
	var noise := 0.0
	var noise_clock := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(spec)
	# Major-chord intervals for arpeggios.
	var ratios := [1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
	for i in count:
		var t := float(i) / count
		var freq := lerpf(f0, f1, t)
		if steps > 0:
			freq = f0 * ratios[mini(int(t * steps), ratios.size() - 1)]
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var sample := 0.0
		match wave:
			"square":
				sample = 1.0 if phase < 0.5 else -1.0
			"triangle":
				sample = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				# Sample-and-hold noise: freq sets how often it changes.
				noise_clock += freq / MIX_RATE
				if noise_clock >= 1.0:
					noise_clock -= 1.0
					noise = rng.randf_range(-1.0, 1.0)
				sample = noise
		# Quick attack, then a fall-off so nothing clicks.
		var env := minf(1.0, t * 40.0) * pow(1.0 - t, 1.5)
		var value := clampi(int(sample * env * vol * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
