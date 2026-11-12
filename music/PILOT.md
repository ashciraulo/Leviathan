# Pilot: region_saltmarrow end to end

The first cue goes through every step before any other cue is built in FL
(handoff lesson 4). Each step records what it found here, so the next cues
copy a working recipe, not an assumption.

## PC folders (approve once)
- `C:\Users\Ashle\OneDrive\Documents\LeviathanMusic\` (no space) — `projects\` (.flp, one per cue; old versions to `_old\`), `templates\`, `midi\`, `masters\` (final FLAC).
- `C:\LeviathanMusic_Render\` — not synced: stems, raw renders. WAV -> FLAC at once, WAVs deleted. Made with a Remote Control `mkdir` (the folder tools can't create folders outside approved roots), then approved for the folder tools.

## Channels and candidate sounds (audition six at a time, gate, then pick)
| Channel (= MIDI part) | Role | Candidates to audition |
| --- | --- | --- |
| guitar_nylon | picking | Ample Guitar M Lite 4; Analog Lab plucked guitars (not Digital Nylon: random note levels) |
| flute_wood | lead | Analog Lab Meadow Flute (passed before); LABS flutes; not Mellotron flutes (wobble, 8va) |
| reed_concertina | counter | Analog Lab accordion / harmonium / reed organ types; LABS reeds |
| bass_upright | bass | Kontakt Diamond Jazz Trio double bass (Ash's pick, v11+), with clones bass_soft / bass_a2 / bass_g3 on the same insert; Analog Lab Upright Bass is in tune but ignores velocity |
| pad_strings | pad, well under | LABS Strings / Soft strings; Analog Lab string ensembles (check for chorus LFO) |
| drum_frame | frame drum | FPC kits / Data\Patches\Packs hand drums (soft, no boom 90-250 Hz) |
| shaker | shaker | FL pack shaker, soft, low-passed |

## Steps
1. Close every FL instance but one. Screenshot first, always.
2. Template: one channel per row above, named exactly as the part, each on its own mixer insert; master chain Pro-C 2 -> Pro-Q (low cut ~32 Hz) -> Pro-L 2 (ceiling -1.1 dB). Pattern 1 holds one note per channel; pattern 1's clip sits at bar 1. Audit mute LEDs, inserts and automation. Save as `templates\saltmarrow_template.flp`.
3. Pull it to the cloud; `flpenv/bin/python music/flp/flp_build.py --template saltmarrow_template.flp --cue region_saltmarrow --out region_saltmarrow_v1.flp` (add `--transpose` for presets measured off-octave). Push back, open in FL, hover the pattern to confirm the note count.
4. Split-stem render (File > Export > Wave, Split mixer tracks ON, tail: leave remainder) to the render folder. FLAC, delete WAVs, stage to the cloud.
5. `python3 music/post/gate_stems.py region_saltmarrow <stems>`. Fix octave (transpose), tuning (fine-tune factor per preset), wobble/evenness (swap preset). Re-render only after every fix is in.
6. Mix in the .flp: per-stem loudness targets (bass -26, lead -33, counter -34.5, pluck -35, pad -40 short-term LUFS as a start; drums soft), leads low-passed ~2.5 kHz, bass mono. Master to -18 LUFS on the loop body.
7. Render the master with the tail on; `python3 music/post/finalize.py region_saltmarrow master.flac` until it passes; then `--write`.
8. Self-check (seam, holes, entries, end of loop), independent reviewer, preview MP3 to `/mnt/project-files/leviathan/music/`, Ash's verdict.

## Findings
(filled in as the pilot runs)

## What the pilot found (2026-11-11)
Read the updated handoff and Out There FM's scripts first: `/mnt/project-files/leviathan/music/reference/`.

- **Split stems need WAV export.** FL's FLAC export ignores "Split mixer tracks" and writes one file. Render WAV with
  Split on, then in `device_bash`: `ffmpeg -i x.wav -c:a flac x.flac`, compare durations, delete the WAV.
- **Stems are named after the mixer insert labels** (`sm_v3_bass_upright.flac`). Rename inserts in FL: click the label,
  F2, ctrl+a, paste from the clipboard (typing drops characters), Enter.
- **Octaves:** Analog Lab Upright Bass and 12 Low Strings sound an octave low (+12, `flp/maps/region_saltmarrow_transpose.json`).
  The FL sampler's root is note 60, so drum_frame (45) gets +15 and shaker (82) -22.
  flp_build.py used to apply a transpose twice when the channel and part share a name (+24); fixed.
- **gate_stems.py** now judges tuning only with 5+ solo notes. Chord-heavy parts (guitar, pad) need a per-onset
  measurement instead: the guitar's -40 c flag came from one solo note; across 352 onsets it is -0.6 c.
- **Mix by script, not by knobs.** Template3 has Pro-Q 4 in slot 1 of inserts 1-7 and Pro-C 2, Pro-Q 4, Pro-L 2 on the
  master (added once in FL; scripts can't add plugins). Then:
  1. `python3 music/post/stem_balance.py music/flp/mixes/<cue>.json <stem dir> --prefix sm_v3_ > gains` sets each part's
     gain to its short-term LUFS target after the EQ, on the neutral stems.
  2. `flpenv/bin/python music/flp/flp_build.py --template saltmarrow_template3.flp ...` writes the notes, then
     `python3 music/flp/flp_mix.py notes.flp music/flp/mixes/<cue>.json <gains> out.flp [--lufs-trim dB]` writes the
     Pro-Q bands, Pro-Q output gains, Pro-C and Pro-L.
  3. Render, measure with finalize.py, and correct Pro-L with `--lufs-trim` (Saltmarrow: +2.1).
- **Pro-C 2 threshold:** Out There FM's "6 dB over the mix loudness" took ~4 dB off this cue; 12 dB over is gentle glue.
- **Brightness:** the shaker and the concertina carry most of the 2-6 kHz share. The concertina preset stays buzzy even
  low-passed (its own 2-6 kHz share is -14 dB at a 2 kHz 24 dB/oct cut); a softer reed preset may suit later cues.
- **device_commit_files can send a stale copy:** a new filename per version, and check the md5 on the PC.
- Saltmarrow v6: -17.96 LUFS, true peak -3.2 dBTP, seam step 5.8 dB, 2-6 kHz share -24..-26 per 6-bar section.
- Review of v6 (music review folder, REVIEW_region_saltmarrow_v6.md) failed it on things the self-check can't hear:
  the bass built its fifth from a slash chord's bass note (F/A gave E, C/E gave B) and its walk from a major triad on
  the slash note. Fixed in t01's generator: the chord's own fifth and chord tones above the bass. Check other cues'
  bass code for the same pattern before they go to FL.
- The concertina's nasal 2 kHz hump is better cut at the source: Analog Lab's Brightness macro (0.274, template4)
  rather than a steep Pro-Q high cut, which sounded honky.
- Analog Lab Upright Bass ignores velocity (all notes within 0.2 dB). Audition a velocity-sensitive bass for batch 2.
- finalize.py's seam check compares the seam with the cue's own downbeat steps; a release-to-downbeat is +6..+8 dB.
- Saltmarrow v8: -17.95 LUFS, true peak -3.0 dBTP, gate PASS. Re-review: the guitar pickup now rubbed a semitone
  against the new bass walk in four bridge bars; v9 picks a chord tone there. -18.01 LUFS, gate PASS.

## The sampled Diamond bass (v10-v19)
Ash chose the sampled Kontakt upright over the in-tune Analog Lab bass, which ignores velocity. Four independent reviews
(v13, v15, v17, v19; v19 passed) shaped the setup. Template: `templates\saltmarrow_template8.flp`. The bass has four channels, all on insert
3: `bass_upright`, `bass_soft`, `bass_a2` and `bass_g3`. `maps/region_saltmarrow_fix.json` drives them through `flp_build.py --fix`.
- **Velocity:** about 0.097 dB per FL step, measured on the rendered stem by fitting level against velocity with one
  offset per key. The audition's 0.18 was wrong. Soft notes therefore need low velocities: re-plucks 40, pickups 50, beat-4 fifths 54 under roots at 88.
  12 steps is only about 1 dB, so an accent pair needs about 30 steps.
- **Hot samples:** G2, Bb2 and B2 are 4-6 dB hot, so they go to `bass_soft` with VOL -5 dB. The VOL knob is square-law:
  raw = 10000 x 10^(dB/40), checked against a render (-5 set gave -5.3 to -5.5). F2, E3 and F3 get small velocity trims.
- **Inharmonic samples:** A2's fundamental is about -30 c while its overtones are +8. G3's fundamental is +17 c and is its
  loudest partial. No retune fixes a sample whose partials disagree, so A2 plays the Bb2 sample on `bass_a2` (PITCH -108)
  and G3 plays the F3 sample on `bass_g3` (PITCH +200). This is the `"play"` key in the fix map.
- **Pitch knob:** FL's per-note fine pitch never reaches Kontakt, but the channel PITCH knob does, as pitch bend. For this
  preset that is about 0.92-0.97 c per unit, and only up to the channel RANGE (2 semitones = 200 units): 205 jumped G3 to +30 c.
- **Range and decay:** A3 is nearly silent, so the bass stays at G3 or below (`bass_walk()` walks down instead). Long notes
  fade about 27 dB in 1.5 s, so the cue plucks a held root again on beat 4.
- **Stem gate:** `gate_stems.py` takes tuning from the fundamental and harmonics 2-4, flags any key whose median or
  strongest partial is off, and flags any key more than 3 dB off at equal velocity.
- **Mix:** bass gain +13 dB, with bells at 72 Hz (-3 dB) and 110 Hz (-3.5 dB).

## Batch 2: the lullaby and the seven bells (2026-11-12)
- **Audition:** gate candidate presets on one MIDI line before choosing (a scratch cue with the box line, transposed
  -12). Rejected for wobble or detune: Celestia (a second layer 13 c sharp on the left), Church Bell, AnaBell, Belle
  Bell, Bell Dong, Resonance Bells, Marimba; Glass Bells +10 c; Clangorous keys 67/74 off; Air Bell arpeggiates;
  MUSIC BOX 2 sounds two octaves up. Several presets sound an octave off on purpose; pass `--octave part=N` to the gate.
- **Gate:** `gate_stems.py` now measures envelope wobble on struck parts (fails over 8 dB median ripple) and the
  L-vs-R pitch of stereo parts (fails over 6 c). When fewer than five notes are strictly solo it falls back to notes
  that start alone, so an always-overlapping line (a music box) is still checked for octave.
- **Balance:** a template's insert Pro-Q gains are left over from wherever it was saved, so the first stem balance is
  only relative. Render once, measure the stems with known gains, then set gain = old gain + delta.
- **Loudness:** Pro-L 2's gain cannot go below 0 dB. A cue whose parts already sum above target came out 1.7 LU hot
  twice (bell_3) because the negative make-up gain was clamped. `flp_mix.py` now takes the excess off every part.
- **Dialogs:** in a save or open dialog, click the name box, ctrl+a, type, zoom to check it before Return; the box
  sometimes comes up empty. In Analog Lab: CLEAR ALL, wait, click the search box, paste, Return.
- **Bells review v1 (FAIL) and what it changed:** the gate skipped its wobble/detune check on phrases of fewer than five
  held notes and never measured chord tones, so a Tubular Bell with three layers at -20/0/+20 c, a Big Crystal Bells
  beating at 1 Hz and a string swell 30 c sharp all printed PASS. The gate now checks from three held notes, judges
  octave and tuning with fewer notes, and reads each chord tone's own peak. Audition presets on the real phrases at
  their real velocities (`zz_` scratch cue), not on another line. Passed: Clock Bell, DX7 26-TUB BELLS, DX7
  20-T.BL-EXPA; failed: Icy Bells (silent without mod wheel), Dark Bell and Distant Bells (keys off by 14-22 c).
- **Swells:** Analog Lab strings barely follow velocity; a swell has to grow by voices (1, 2, 3, 5 gave +9 dB).
- **Peaks:** Vorbis overshoots the master by up to 0.3 dB, so Pro-L's ceiling is -1.5 dBTP and finalize.py measures
  the OGG itself.
- **Bells review v2 (FAIL) and what it changed:** DX7 V presets idle at about -73 dBFS, so the render never fell silent,
  every one-shot came out 41-43 s long and the game would have dipped the music for all of it. finalize.py now trims
  where the tail reaches 10 dB above the render's own floor and fails a floor above -70 dBFS; the hummy DX7 on the
  Gale Bell became Sustained Bells. A preset that sustains (the Verge's T.BL-EXPA) gets its last note let go after a
  bar (`LAST_HOLD`) and rings out on the preset's reverb, turned up on the Point, Moth, Rime and Verge bells. The gate's
  octave check on long sustained bells takes a 60% majority, since overtones win single readings.
- **Final bells (2026-11-12):** bell_1/2/3/5/7 from the v8 renders, bell_6 v9, bell_4 v10, all -16.0 ±0.4 LUFS and
  every gate PASS. The .flp of each is in projects\bell_N_v8/v9/v10.flp.
- **Bells review v3: PASS.** finalize.py now reads the noise floor from the render's last 2 s only (a whole-render
  percentile read the lullaby's music as its floor). Open polish (MINOR): bell_1 and bell_3 stop at the note-off
  rather than ringing (lengthen their last notes), bell_2's vibraphone auto-pans, bell_4's Sustained Bells warbles at
  0.84 Hz and leans 2 dB left, bell_6 steps down 6 dB when its held note lets go.

## The title (2026-11-12)
- **Template:** `templates\title_template.flp` is bells_template4 with four presets swapped (aud1 Analog Harp, aud2
  Simple Ohh, aud4 Meadow Flute, aud5 Simple Sine (Clean)) and the inserts renamed after the parts. The project files
  (title_vN.flp) carry the Synclavier envelope below; build new versions from the latest PC project, not the template.
- **A swelling sub:** Analog Lab's Time macro did nothing to Simple Sine's envelope. Edit Preset > Part 1 Open shows the
  Synclavier V panel; AMP ENV OFFSET Attack and Release at 1.00 give ~11 s in and ~6 s out. The swell has to live in the
  envelope: a held sine at one velocity is flat and stops dead at the note-off.
- **Mixing a sparse cue:** the sum of the part targets (-19.2) is not what the stems sum to once each is on target
  (-22.2), because every stem's integrated loudness only counts where it plays. Measure the summed stems for pre_lufs.
- **Loop seams:** a calm A section after a busy B dropped 9 dB at the loop point. Ease the last two bars back into the
  A texture and give the loop's first beat a little more. finalize.py now fades the 10 ms of lead-in before the loop
  start onto the body's end, so the waveform runs on across the seam (0.052 -> 0.002).
- **Title review v1 FAIL -> v2 PASS.** v1: FL stopped 0.7 s past the loop end (no room), so the seam cut every ring;
  flp_build now leaves two bars of room on loops too, and finalize fails a loop with under 2 s of room or a >12 dB fall
  at loop_end. The tide only breathed below 80 Hz: Analog Harp and 12 Low Strings ignore velocity, so the breath is
  built from voices (strings 2-5) and notes (harp roll 2-5), plus an octave-up double of the sub.
  Open MINORs (v2): Sustained Bells at the written octave would read more distant than +12 (the gate's L/R reading on
  its strike is noise); 12 Low Strings' +22 c layer beats at ~0.9 Hz; Simple Ohh's D4 beats at 3.6 Hz; the folded
  tail also smears bar 36's A ring over the first pass's bar 5; harp key 50 sits ~2 dB low (velocity can't fix it).

## Market Day, the village (2026-11-12)
- **Template:** `templates\saltmarrow_template8.flp` as it is. `maps/place_village.json` puts the strum on the nylon
  guitar (Ash's folk palette has no mandolin; Analog Lab has no acoustic one, so the part is now named "guitar"), the
  whistle on the Meadow Flute, and perc_hand on the frame drum; `maps/place_village_fix.json` sends perc key 61 to the
  drum a third up and key 62 to the shaker channel. Re-stage the template from the PC before building: an older staged
  copy still named bass_a2 "bass_up". Project files: `projects\place_village_v1..v5.flp` (v5 is final).
- **The Diamond bass under F2:** G1, A1 and C2 read 15-39 c flat on their strongest partial in the v1 gate. The cue's
  bass moved up to F2..G3, the range Saltmarrow measured, and uses Saltmarrow's fix map. F#3 (key 54) has two
  fundamentals (-53 c and +16 c): the Bm fifth takes D3 instead.
- **Ample Guitar chokes close voicings:** G3-B3-D4 put B3 and D4 on one string, so the B died in ~30 ms and every G
  chord sounded as a bare fifth (review v3, MAJOR 1; the stem gate can't hear it). The A sections use open-guitar shapes
  (`STRUM_SHAPES`). About 0.3 dB per velocity step; open G3 (key 55) is hot and gets -7.5 dB in the fix map.
- **Brightness:** v3's 2-6 kHz share was -19.7 dB (shaker about half). v5: shaker cut at 5 kHz and 3 dB lower, guitar
  cut at 3.5 kHz: -23 dB. The frame drum rang at 113/141 Hz over the bass: -4 dB bell at 120 Hz.
- **Seam:** the loop's last up-strum rings 0.9 beats. finalize.py's loop-end check now fails a fall >12 dB only when
  the 400 ms after the loop end is also >12 dB under the body's quietest 400 ms (reviewer's rule): staccato cues fall
  12-16 dB in their own ring but stay within 0-8 dB of their quietest moment; the title v1 cut sat 25 dB under it.
- **Review v5 PASS**; v6 takes its two MINORs (shaker -47, frame drum -33: stem_balance had raised the drum's gain to
  undo its 120 Hz bell, bringing its attack back). v6: -20.23 LUFS, true peak -3.5 dBTP, 2-6 kHz share -24 dB.

## Marlo's Stall, the shop (2026-11-12)
- **Template:** `templates\shop_template.flp` = saltmarrow_template8 with the Emulator II Clarinet on flute_wood and the
  Emulator II Marimba on reed_concertina (Analog Lab search). No brush samples in FL's packs, so the shaker plays the
  brushed-snare line (`maps/place_shop.json`, key 38 -> shaker key 60).
- **Clarinet tuning:** every key read +17 c; the channel PITCH knob at -17 (fix map "pitch") puts it in tune, so
  Analog Lab follows FL's pitch bend like Kontakt does.
- **Walking bass:** kept to F2..G3; a root too high to walk up through its chord walks down (root, fifth below,
  third below).
- **Bright samples:** both Emulator II presets keep a -17 dB 2-6 kHz share even with 24 dB/oct cuts at 2.2/2.5 kHz.
- **Review v3 FAIL -> v5:** the Emulator II Marimba sounds an octave above written (the gate missed it: the marimba
  never plays alone), so it sat on the clarinet's notes; `maps/place_shop_transpose.json` takes it down 12. Odd bars
  walked back from the sixth, so Bb bars opened on G: every bar now starts on its root. Bass Gb2 (+6 dB hot) goes to
  bass_soft. The shaker reads as a dry backbeat tick rather than brushes (MINOR, no brush samples).
- v5: stems on target, -20.18 LUFS, true peak -7.1 dBTP. Bass D3 (key 50) reads -12 c (reviewer: inaudible in a walk).
- **Review v5 PASS.** Open MINORs: the marimba reads -7.5 c at the written octave (+1 c an octave up): channel PITCH
  about +7; 2-6 kHz share -18.3 dB (shaker -2 dB); the brushes could gain body from the frame drum ~12 dB under on 2 and 4.

## Lamplight, inside homes (2026-11-12)
- **Template:** `templates\house_template2.flp` = lullaby_template with I Felt It (felt piano) on the old harp channel
  and Soft Cello on the old choir_oo channel. Sad Day Cello (Augmented Strings) failed the gate: 22 c note scatter and
  3 dB jumps at equal velocity. The music box and its glockenspiel shine are the lullaby's; the generator doubles the
  box into `box_shine` and lets each glock note ring to the next one +1 beat (its note-offs cut 14 of 39 dead).
- v3: gate PASS, stems on target (box -27, piano -29, cello -32, shine -42), -19.82 LUFS, true peak -8.3 dBTP.
- **Review v3 PASS.** Open MINOR: Soft Cello's octave-up layer sits ~+10 c, so its held notes beat at 1.2-1.5 Hz
  (bars 13-24); lower that layer in Analog Lab or the cello 2-3 dB. The gate only checks wobble on struck parts:
  extend it to sustained ones. Village v6 review: PASS with no MINORs.

## Under the Mangrove, Brinewood (2026-11-12)
- **Template:** `templates\brinewood_template.flp`: the Emulator II Marimba on reed_concertina (marimba, -12), kalimba
  on guitar_nylon (-12), the Diamond bass, frame drum for the low stroke and Analog Lab "Conga 1" on a new drum_high
  channel (insert shaker) for the high and slap strokes (keys 60 and 64).
- **E2 under the tonic:** the Diamond bass has no clean E2, so key 40 plays the F2 sample on a `bass_a2` clone whose
  PITCH knob takes it down a semitone (gate reads -13 c: two alternating samples either side; inaudible at 82 Hz).
- **A soft root over the loop end:** a bass stop on the last beat made finalize flag "FL cut the tail".
- **Review v3 FAIL -> v6 PASS.** Open MINORs: 2-6 kHz share -21.1 (a -6 dB bell at 2.8 kHz on drum_high, marimba
  2.5 kHz bell to -5.5); the low drum stroke sits level with the bass on downbeats (drum_hand target -33). The conga's
  slap is the high sample a third up, about 0.115 dB per velocity step.

## The Rotting Hull, dungeon 1 (2026-11-12)
- **Template:** `templates\hull_template.flp`: Soft Cello on flute, Emulator II Clarinet on choir_pad (PITCH -7),
  12 Low Strings on strings_low and bell_tower (both +12: it sounds an octave low), Rom2A 30-BLOCK on bell_marrow for
  the creaks, the frame drum on sub_breath (key 36 plays 53).
- **12 Low Strings and Soft Cello ignore velocity:** a sway or an accent has to come from voices (full chord on beat
  1, two notes on beat 2) or from volume automation, never from velocity.
- **Review v5 FAIL -> v7 PASS.** Open MINORs: the drum still sits +2.5 dB over the bass root on downbeats (target -38
  or a deeper 70 Hz cut, shorter ring); the sway is only +0.5 dB in the master in A and B (one voice on beat 2); the
  tuned creaks put D4/F4 against A chords in bars 47-48 (use key 52 on A bars); Soft Cello's B2 is 3.5 dB hot (hold G2
  or a clone channel at -3.5 dB). The loop seam steps up 4.9 LU.

## Cellar Steps, the cellar (2026-11-12)
- **Template:** `templates\cellar_template3.flp`, channels named by part. Lush Pizzicato was inharmonic and C-8
  Pizzicato (v4) is an OB-Xa synth that sustains, so v7 uses Analog Lab "Pizzi Bass" (Augmented Strings, sampled). It
  sounds an octave low (`maps/dungeon_cellar_transpose.json` +12) and its G#3 is inharmonic, so the E chord's third
  plays G#4. The tom plays key 48 for written 45 (it settles on A1).
- **Pizzi Bass has two velocity layers that switch at 63/64** and barely follow velocity inside a layer (review v7
  MAJOR). Every figure note is written 68-76 so it stays in the loud layer; only bar 32's creep-back is soft (44/40).
  Any per-key level fix must go through a clone channel, never velocity.
- **The loop:** bars 30-31 stop short under a slow harp line, and bar 32 creeps back with two soft plucks, an E3
  bassoon pickup and a tom on 4-and.
- v8: review PASS. Gate flags only the pizz's own samples. -18.07 LUFS, true peak -4.55 dBTP.
- **Open MINOR (v8):** E4, G4 and Bb3 (played 76, 79, 70) are 3-7 dB soft in the loud layer; E4 is the and-of-1 on
  every Am bar. Fix: send them to a clone channel and lower the main pizz about 5 dB with `volume_db`. Tuning: B3, D4,
  F4, G#4 about +10 c (don't retune C4, it reads -6 c now). No shared reverb send yet.

## Teeth in the Dark, the miniboss (2026-11-12)
- **Template:** `templates\boss_template3.flp`, shared with the boss; its channels carry the boss's part names, so
  `maps/miniboss.json` maps strings_staccato to strings_ostinato, brass_stab to horns_brass, drum_toms to drum_taiko.
- **Brass:** Analog Lab "Trumpfal", a Fairlight CMI trumpet sample: in tune, 72 ms release, mono and lo-fi. Dirty
  Bronze (v2) failed review: it carries a layer an octave below the written notes, starts +54 c sharp and falls, and
  its release slurs stabs together. +3 dB at 2 kHz for some front.
- **Strings:** Analog Lab "Staccato Blend" (Bowed Strings), Time macro at 0. 12 Low Strings is a sustain patch and
  can't play eighths. Staccato Blend still peaks ~100 ms after note-on, so the part plays 60 ms early
  (`"advance_s": 0.06` in the fix map; flp_build wraps a note before 0 to the loop end and finalize folds it back).
  It follows velocity at only ~0.16 dB/step, so accents are written at 110 and per-key velocity trims barely work.
- **Toms:** written 45 plays 42, 48 plays 45 (G minor tones, no C#).
- v7: review PASS (5 MINOR). Gate: key 53 still -3.5 dB (needs a clone channel). -16.88 LUFS, TP -2.37 dBTP.
- **Open MINORs (v7):** the strings' front is still a ramp; the trumpet has no bite in its first 30 ms (2-6 kHz share
  -24.7 dB); toms glide and have no attack above 150 Hz; strings lean 5.6 dB left and the brass is mono and dry;
  the even bars sag 3-4 dB.

## Hunger of the Deep, the boss (2026-11-12)
- **Template:** `templates\boss_template3.flp`. Ostinato = Staccato Blend (Time 0, `"advance_s": 0.04`, ~0.07
  dB/step on sixteenths, per-key trims in `maps/boss_fix.json`); horns = Trumpfal; brass_low = 12 Low Strings (+12,
  held notes only); timpani = Emulator II "Gong & Timpani" (+1); taiko keys 36/38 play 47/50; choir = Ah Voice, which
  ignores velocity (level only through channel gain).
- **Form:** section C drops to timpani on the root (beats 1 and 3) under the choir; bars 32-33 build with a snare
  ramp and a G timpani roll; in D the choir doubles the trumpet melody (bars 34-49) so the long notes don't fade.
- v10: review PASS (0 MAJOR, 6 MINOR). -16.59 LUFS, TP -2.39 dBTP, seam step -0.41 dB.
- **Open MINORs (v10):** above 150 Hz the build rises only +3.8 dB (cap the taiko ramp near vel 105, add more on
  top in bar 34); D bars 35, 42, 46 dip 11-14 dB at the choir hand-off (double on its own choir clone +2-3 dB, or drop
  the ostinato octaves there); trumpet 2-6 kHz still ~5 dB hotter in D (take +0.9 dB on horns per stem_balance); the
  taiko needs a stick layer for 2-6 kHz; the C timpani read as F/Eb above 150 Hz on small speakers (narrow cut near
  700 Hz); ostinato low keys ~26 ms late.
