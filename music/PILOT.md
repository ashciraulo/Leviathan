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
- **v6 (PASS, `projects\place_shop_v6.flp`):** the marimba (Analog Lab Emulator II Marimba) ignores the channel
  PITCH knob (+7 changed nothing), so FL's Pitch Shifter (Music mode, +0.08 st) on its insert raises it +7 c; it adds a
  faint warble to the 2-8 kHz ring (MINOR, 22-34 dB under the note). Brushes -2 dB (2-6k share -19.7). Render in SONG
  mode: the project opened in PAT mode and the first render came out 3 s short.

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

## Wake Not the Deep, the boss (2026-11-12)
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
- v11 (PASS, `projects\boss_v11.flp`): in D the ostinato plays its root instead of the octave on the long-melody bars
  (`D_LONG`, same note count so the humanize seeds hold). The choir now sits at or above the rest in 1-5 kHz in 7 of
  9 long-note tails (v10 5). The hand-off dip (bars 35, 42, 46: 12.6 / 16.2 / 13.4 dB) is unchanged: it is the
  trumpet sample dying in a trough of Ah Voice's own wobble. Fix: a shared ~1 s room on the trumpet and choir
  inserts (low cut 250, high cut 4k, 30-40% wet) or choir automation +3-4 dB on the second half of each long note.
  gate now reads brass_low key 41 at +13 c (v10 +10, limit 12; render variance on an unchanged part).

## The Bell Kiln, dungeon 2 (2026-11-12)
- **Template:** `templates\kiln_template3.flp` (shared with Cinderreach): boss_template3 with harp = Saint Eustache
  (synth church organ; sounds an octave low, so organ_dark is +12), bell_marrow = Supermini Bass (insert 7),
  choir = Hammer And Anvil (insert 4; it sounds E6 for written E5 and rings), timpani = Emulator II Bassoon (insert 1).
  Taiko key 36 plays 47 as in the boss.
- **Trumpfal can't hold a note:** it dies ~0.85 s into a 1.8 s note (review v3 MAJOR). Every trumpet note is doubled an
  octave down by the bassoon (`reed_double`, 7 dB under), which fills the holes without mud.
- v4: review PASS (3 MINOR). -17.94 LUFS, TP -3.6 dBTP. The gate's bass_synth scatter is an artefact of short low
  notes (the reviewer read the bass on its harmonics: -3 c, spread 6 c).
- **Open MINORs (v4):** the anvil still rings (hits only 5-9 dB over the ring; needs a 0.4-0.5 s decay, then +2 dB;
  its mix target is -35 on purpose so stem_balance doesn't undo the cut); the organ canon in B' is 3.5 dB under the
  bassoon (own clone channel +4-5 dB, E4 and C4 +4 more); the frame drum has no body above 150 Hz (+4 dB at 250-300 Hz).

## Ashfall, Cinderreach (2026-11-12)
- **Template:** `templates\kiln_template3.flp` (see the Kiln). strings_ostinato = Pop Staccato (Time 0, 40 ms early);
  brass_low = 12 Low Strings (+12, `advance_s` 0.12: it swells in ~145 ms late); drum_frame plays on drum_taiko
  (41 -> 42); pad on sub_breath (insert 7); reed = Emulator II Bassoon; anvil = Hammer And Anvil.
- **Staccato strings below F#2 are stretched samples:** Pop Staccato and Staccato Blend both read C#2-E2 an octave up
  or 13-19 c flat, so the ostinato's floor is G#2. The pad's added root an octave down gives the low floor.
- **Tune from harmonics, not the fundamental:** on short low notes the gate's fundamental reading is wrong (v6 retuned
  47/50/62 by +17 c from it and made them 20-30 c sharp). Measure h2-h6 with a +-60 c search; the strings_up clone's
  PITCH knob is ~1 c per unit in Analog Lab.
- **The anvil sounds an octave above its key**, so it plays 73 (C#6) and 74 on D bars; its mix target is -36.5 so
  stem_balance doesn't undo the cut.
- v8: review PASS (2 MINOR). -17.98 LUFS, TP -3.4 dBTP, seam 1.15 dB.
- **Open MINORs (v8):** key 50 reads +13 c and 62 +17 c on the reviewer's harmonics (put 50 on the clone at -10 c and
  take 62 off); section A has nothing pitched below 100 Hz (pad root or a brass pedal from bar 11) and the frame drum
  has no stick above 150 Hz (a slap/rim layer).

## Silent cues batch (2026-11-17): Hollows, the Healing Spring, the chapel choir, Half-Remembered
- **Templates:** no new presets. Hollows, the spring and Half-Remembered build from `projects\title_v10.flp` (Analog
  Harp, Simple Ohh, Meadow Flute, Sustained Bells, 12 Low Strings, Simple Sine with the long Synclavier swell); the
  chapel choir builds from `projects\boss_v10.flp` (Ah Voice choir, 12 Low Strings +12 as the "organ" pedal). Maps
  and mixes in `maps/` and `mixes/` under each cue name.
- **Pro-L 2 make-up:** for these quiet ambient cues the chain (Pro-C 2 + Pro-L 2) loses 1.7-2.8 dB, not the 1 dB
  `LIMIT_LOSS` assumes, so `--lufs-trim` ran 0.75-1.8. Measure pre_lufs as the real sum of the stems after the
  stem_balance deltas (stem_balance's own "mix" line is not that sum), then trim = measured loss - 1.
- **Reviews:** Hollows v3 PASS (4 MINOR), Spring v3 PASS (1 MINOR), Chapel choir v2 PASS (3 MINOR), Half-Remembered
  v2 PASS (6 MINOR). Game OGGs: place_cave -19.9, place_spring -19.6, place_choir -20.3, story_memory -19.3 LUFS.
- **Open MINORs:**
  - Hollows: the sine drone dips at each 4-bar retrigger and bar 22 is a 4 s hole (hold A2+E3 across the loop);
    the drone is a pure sine, so through the game's cave muffle it dominates (add partials 2-3 or an octave clone,
    drone -30 / harp -24); the bell "echo" is as loud as the harp (bell target -36.5); two semitone clusters per
    loop (cap each harp note at the gap to the next drip).
  - Spring: Simple Ohh beats on every chord tone (detuned layer, keys -13..+6 c): lower its detune or the pad 3 dB.
  - Chapel choir: the 12 Low Strings pedal has a +20 c layer and throbs at 0.4-0.7 Hz; it is a 35-62 Hz
    fundamental, gone on small speakers; choir 2-6 kHz share -19.7 dB.
  - Half-Remembered: two semitone rubs (bar 8 pad C4 vs choir C#4; celesta G5/Ab5); the Db root lives only in the
    35 Hz sine; the bell strikes as loud as the celesta; Simple Ohh C4/C#4 -10 c; "fade 4" can't fade (no part
    follows velocity: needs volume automation); one sub retrigger cancels itself (20 dB hole at 8.75 s).

### Danger, the ritual choir and Grief in the Water (same batch)
- **Danger (`story_danger`, v4 PASS):** built from `projects\miniboss_v7.flp` (ostinato on bell_tower's strings,
  toms on sub_breath, brass on bell_ember). v1's A' section stepped 16.8 dB at the seam; v3 had no build and the
  wrong tom pitches. v4 builds from bar 6 with an octave-up ostinato layer, a 9-hit tom fill and brass lifts.
  `maps/story_danger_fix.json` moves the toms to the right keys and trims two ostinato keys. Open MINORs: brass 2 kHz
  bell -1.4 dB, strings highcut 4.5k, tom key 50 -> 54, a stick layer, pan.
  v5 (PASS, `projects\story_danger_v5.flp`): key 50 plays 54 (F#2 +9 c); brass bell 0 dB and -1.4 dB, strings high cut
  4.5 kHz (2-6 kHz share -18.5 -> -20.1); bar 13 lands with a short brass B3 and tom 98 (+2.3 dB over bars 14-16); the
  eighth-bar accents land on time: advance_s 0.10 and every other ostinato note written 0.09 beat later (+46 -> +8 ms).
  Open: Trumpfal's key 73 sounds only ~0.84 s however long it's written (re-attack bar 12's C#5 on beat 4); brass +1 dB
  with a bars 11-12 2.5 kHz cut; toms on small speakers; strings lean left.
  v6 (PASS, `projects\story_danger_v6.flp`): bar 12's C#5 re-struck on beat 4 (brass beat 4 -35.5 -> -24.1 dB, no
  click), brass +1 dB, strings high cut 4 kHz. 2-6 kHz share -19.93: the new C#5 sits at the top of Trumpfal's range
  and brightens bar 12. Open MINORs: a -4 dB 2.5 kHz bell on the brass in bars 11-12 only (needs automation or a
  clone channel on its own insert); toms on small speakers; the brass sounds lo-fi; strings lean left (+3.7 dB).
  v7 (PASS, `projects\story_danger_v7.flp`): the strings channel's PAN 20% right (`"pan"` in the fix JSON, new in
  `flp_build.py`): strings L-R +3.7 -> +1.1 dB, master +0.8 -> -0.1. Don't pan further: the preset's image depends on
  frequency (v7: 40-150 Hz +5.7, 2-6 kHz -6.0), so more pan tips the top right; narrowing the strings would fix the split.
  v8/v9 (PASS, `projects\story_danger_v9.flp`, template `templates\story_danger_template.flp`): held brass notes
  from C#4 up get an octave below (part `brass_dbl`, 6 notes) on a clone channel `brass_low #2` 7 dB down (maps
  `story_danger_v9*.json`). Velocity barely moves Trumpfal: v8 doubled on the same channel at velocity -14 and the
  double came out level with the note, masking the toms. v9: doubles -6.3..-7.3 dB under their notes, toms lead by 11 dB.
  The gate can't check `brass_dbl` (shares the brass insert). Open: a 2.5 kHz brass cut in bars 11-12; toms rim layer.
  v10/v11 (PASS, `projects\story_danger_v11.flp`, template `templates\story_danger_template_v2.flp`): the brass of
  bars 11-12 (part `brass_hi`, moved after humanize with bounds 0.05 beat early, else bar 11's downbeat stays behind)
  plays on a clone routed to insert 7 with a -4 dB 2.5 kHz bell. 2-6 kHz share -20.86, bar 11 -18.0, bar 12 -16.9.
  Open MINORs: toms on small speakers (rim layer), strings image split by frequency, brass mono and dry.
  v12 (`projects\story_danger_v12b.flp`, template `templates\story_danger_template_v3.flp`): part `drum_rim` copies
  every tom hit (after humanize, same velocity) to a sampler clone of the toms holding FL's stock
  `Packs\Drums (ModeAudio)\Rims\Fracture Rim 01.wv`, key 60, insert 8 (stem `strings_low`), lowcut 1k, highcut 3k
  24 dB/oct, gain -9. Tom hits +5.4 dB over the rest in 400-5k (median 40 ms after the hit); rim 16 dB under the toms.
  A 7 kHz highcut at 12 dB/oct took the 2-6k share to -18.5 and >6k to -33.5: keep the steep 3 kHz cut (-20.0 / -49.9).
  Split stems for this template: bell_ember = brass_low + brass_dbl, bell_marrow = brass_hi, bell_tower = strings,
  sub_breath = toms, strings_low = rim. FL's Packs folder is mounted for the folder tools (`~/mnt/Packs`).
  v13 (PASS): rim velocity +14 in bars 7-12 (B buried the toms under the brass), highcut 1.8k 24 dB/oct, pan +0.17
  (L-R measures +dB = left: the rim needs pan right to sit with the toms), gain -5. 2-6k share -20.48.
  v14 (`projects\story_danger_v14b.flp`, template `templates\story_danger_template_v5.flp`, maps `story_danger_v14*`):
  Fruity Reeverb 2 after the Pro-Q on inserts 6 and 7 (0.8 s, size 25, low cut 250, high cut 4k, mod 0, ER 20%, wet
  30%, SEP "50% separated"; SEP's type-in reads "x% merged" to the left of Original, so 140 made it mono). Brass
  side/mid -70 -> -17.7 dB. Rim low cut 900 Hz 24 dB/oct and a -6 dB Q6 bell at 705 Hz (ring -3.8 -> -7.7 dB).
  Templates saved from a built project have the parts' names (map v14 is identity); two channels are called brass_low,
  and the build takes the later one (the one on insert 6). Reeverb knobs: right-click > Type in value.
  v14 review PASS: room too quiet in the mix (wet 16 dB under dry), rim brightened the 2-6k share to -20.34.
  v15 (`projects\story_danger_v15b.flp`, template `templates\story_danger_template_v6.flp`): Reeverb wet 60% on both
  brass inserts (brass side/mid -10 dB); rim B-section boost +26 velocity, -9 dB Q0.8 bell at 2.8 kHz, gain -2;
  Pro-L --lufs-trim 1.6. 2-6k share -20.64, -17.20 LUFS. The room reverb lives in the template, not the mix JSON.
  v15 review PASS (the 2.8k cut cost the rim 1.2 dB outside B). v16 (`projects\story_danger_v16.flp`): rim gain +1,
  B boost +13. Phone sim drums vs mix 1-2/A/B/A' +6.9/-1.5/-2.4/+6.7 dB, 2-6k -20.61, -17.19 LUFS.
  v17 (`projects\story_danger_v17.flp`): strings insert 5 stereo separation "50% merged" (the small knob at the
  bottom-left of the strip; type "50% merged" by pasting, typed spaces drop). FL's 50% scales the side to 0.70 RMS.
  Strings L-R by band 40-150/150-500/500-2k/2-6k: +5.4/+0.3/-2.1/-5.7 -> +4.9/+0.2/-1.7/-4.5; master 2-6k -3.5 -> -2.7.
  Set in the saved project only: rebuilding from template v6 loses it. -17.44 LUFS.
  v17 review PASS but the split stayed (narrowing scales every band alike). v18 (`projects\story_danger_v18.flp`): in
  the strings' Pro-Q 4 (insert 5), per-channel shelves (band menu Stereo > Left/Right; double-click a knob to type):
  low shelf 150 Hz Q0.71 L -3.5 / R +3.5, high shelf 1.8 kHz Q0.71 L +3 / R -3, output +7.6 dB (was +6.6).
  Strings L-R 40-150/150-500/500-2k/2-6k +1.0/-0.8/-1.1/-1.4 (v17 +4.9/+0.2/-1.7/-4.5). -17.20 LUFS. Project only, not the JSON.
- **Ritual choir (`story_choir`, v8 PASS):** built from `projects\title_v10.flp` (Simple Ohh unison, Sustained Bells
  low, 12 Low Strings +12 drone). v3's PITCH -18 and bell -12 came from a bad home-made pitch read (`harm.py`): trust
  the reviewers' measurements over it. Loop seam: notes are clamped at the loop end, so nothing can ring across it.
  Held to the end the seam stepped -6.6 dB (v4); with choir and drone both released early it was a 0.5 s hole (v7,
  which finalize's 400 ms windows passed). v8 keeps the choir's 0.97 legato and releases only the last drone chord
  half a beat early (-4.4 dB, the low point matches the cue's own breaths). Open MINORs: the bell is a strike plus a
  swelling pad (try DX7 26-TUB BELLS or Clock Bell); Simple Ohh's Eb4 warbles at 4 Hz; the drone is 7-11 c sharp.
- **Grief in the Water (`story_sorrow`):** v2 used Soft Cello (a synth: a +20 c layer, so every note pulsed at
  2-4 Hz, review FAIL). v5 uses `templates\sorrow_template_v2.flp`, which is the house template with **Adagio Cello**
  (Analog Lab, Aug. STRINGS, sampled) on both the cello and pad_soft channels. It sounds an octave below the written
  note, so `maps/story_sorrow_transpose.json` plays both +12; it follows velocity (about 0.3 dB per step), and
  `maps/story_sorrow_fix.json` evens keys 70 and 72.
  Review v5 PASS (3 MINOR): the preset's own chorus still shimmers on the even partials (turn its FX chorus off and
  save a user preset); it is bright (2-4 kHz share -14 dB: a -3 dB bell at 2.2 kHz); key 66 is ~4 dB hot.
  v6 (templates\sorrow_template_v3: Chorus and Phaser off on both cellos, -3.5 dB bell at 2.2 kHz, key 66 trim)
  PASS: brightness -16.1 dB, but the shimmer is the preset's octave-up Layer B (likely "Random Reattacks"), not
  its FX; Adagio Cello gives only ~0.13 dB per velocity step, so per-key trims need clone channels, not velocity.
  v9 (`templates\sorrow_template_v4`: Random Reattacks at 0 on both channels, a `cello_soft` clone at -3.5 dB
  for key 70) PASS (5 MINOR): shimmer about halved, body bars within 2.5 LU, seam +1.2 dB. Velocity response is
  uneven (0.13-0.32 dB a step), so bar 8's F#3 at 50 overshot to a -7.7 dB hole and +24 on every G3 undid the
  tail's ebb and exposed a flat (~191 Hz) attack resonance. v10 tried F#3 63, +12 on the body G3s only and +10
  on the tail Bb3: bar 8 jumped +7.9 dB and the tail G3s fell into 5-6 dB holes (the preset changes sample layers
  between those velocities), so v9 ships. Level fixes on this preset need clone channels. Still open: the even-partial shimmer left (h4/h8) is likely Layer B's Light Pool synth.
- **Simple Ohh's 4 Hz warble** (ritual choir, Healing Spring): it is in the Female Ooh sample itself (Augmented
  VOICES). Vibrato and Tremolo depths are 0 and the LFO slots empty; bypassing Male Ooh (16a) or the granular Layer B
  (16b) left the 4 Hz depth at 0.40-0.48. The only fix left is playing Eb4 from a neighbouring key on a retuned clone.
- **Ritual choir v10/v11:** turning the bell's Part 2 off made it toll properly, but its strikes vary randomly by 5+
  dB from render to render (Soft Bells), so no key trim can level it, and the choir's chorus/phaser off changed
  nothing. v8 stays the shipped cue; `maps/story_choir_fix.json` (bell_soft clone) is kept for a future bell swap.
- **Spring v4:** the Simple Ohh pad 3 dB lower (pad_glass -35 in `mixes/place_spring.json`), its v3 MINOR.
- **The slow sine (Simple Sine, Synclavier-V) and the loop:** its preset envelope swells for ~29 s and releases for
  ~18 s, far past the ~8 s render tail, so a note held to the loop end is cut mid-release and folds back as a 5-8 dB
  step a few seconds into the loop (Hollows v5 review FAIL, Half-Remembered v4). Retriggering the same pitch instead
  cancels itself (v3/v2). Fix: `templates\ambient_sine_template.flp` (saved from story_memory_v4b) has the sub_swell
  channel's Synclavier AMP ENV OFFSET Attack and Release at about +0.5 (0.4 s attack, ~4 s release; the partial's own
  envelope and the Time macro had no audible effect; offsets near 0 are instant). Its channels carry story_memory's
  part names: celesta = Analog Harp, sub_swell = the sine, bell_distant = Sustained Bells, pad_warm = 12 Low Strings,
  choir_soft = Simple Ohh (identity map, or `maps/place_cave_v6.json` for the cave).
- **Hollows v4/v5:** one held drone chord (+ an A3/E4 octave layer), harp drips capped at the next drip, mix harp -24 /
  drone -30 / bell -36.5. v5 fixed three v3 MINORs but failed on the envelope above; v6 rebuilds on the new template.
- **Half-Remembered v3-v9:** pad restrikes on bar 8 and carries the chord root, the celesta caps semitone neighbours,
  bell -38 with a 1.8 kHz high cut, same-pitch sub notes merged; v9 is on the new template.
  Reviews: Hollows v6 PASS (1 MINOR: drone-only bars -34 LUFS on small speakers, raise the octave layer +3 dB),
  Half-Remembered v9 PASS (open: choir C4/C#4 -14 c, no fade without automation; the sub's in-phase seam relies on
  the humanize seed, so turn timing humanize off for the sub if the generator changes).
- **FL tips from this batch:** ctrl+r (after clicking empty workspace) opens the export dialog directly; the File menu
  route sometimes missed and toggled channel-rack steps. In Analog Lab, typing in the search box leaks keys to FL
  (it played notes and loaded another preset): use the Types / Instruments filters with the mouse instead.
- **12 Low Strings (Prophet-5) as a drone or organ pedal:** the preset's Osc2 has FINE +0.206 semitones (a +20 c twin
  that throbs at 0.4-1.6 Hz on low notes), and its two free-running oscillators then set each note's level at random
  (h1 swing up to 9.6 dB, note levels spread 5 dB). In Analog Lab: Explore, Edit Preset, Part 1 Open, hide the
  macros (Controls), then Osc2 FREQ (330,352), FINE (372,352, double-click = 0), mixer OSC1 (535,293) / OSC2
  (577,293); a knob's value shows while the mouse is held down on it.
  - Chapel choir (`place_choir`): v3 FINE to 0 (PASS, unison variance left); v4 Osc2 an octave up (FREQ 0, Osc1
    is -12) at mixer 2.56, Osc1 ~7.0: h1 swing <=0.8 dB, notes within 2.2 dB, master 25-110 Hz <=1.8 dB.
    `projects\place_choir_v4.flp`. v5 (PASS, `projects\place_choir_v5.flp`): Osc2 1.84, FINE checked at 0.00; the
    octave's colour across the 12 notes spans 6.4 dB (v4 13.4). B1's octave still sits ~+2 c (per-voice spread; no
    Sync or Vintage in Analog Lab): the remaining fix is Osc2 off plus a +4-5 dB bell near 140 Hz on the pedal insert.
    v6 (PASS, `projects\place_choir_v6a.flp` = Osc2 at 0.00, then `flp_mix` with a +4.5 dB 140 Hz Q 0.7 bell on
    the pedal and a 3.6 kHz bell on the master): every key's octave colour identical (spread 0.0 dB, v5 6.0), B1 on
    one peak, 2-6 kHz share -24.2. MINOR: the pedal stem at -27.1 LUFS (target -30) after the bell. v7 sets its
    target to -28, adds +3 dB at 350 Hz and a 3.5 kHz high cut for small speakers, and eases the master bell to -2.5.
    v7 PASS, no MINORs (`projects\place_choir_v7.flp`): pedal -27.45 LUFS, 12.1 LU under the choir at a 250 Hz
    high-pass (v5 15.0), 2-6 kHz share -22.8. Notes: the pedal is static now (a 0.15 Hz +-1 dB LFO if it needs motion).
  - Ritual choir (`story_choir`): v13 Osc2 off, Osc1 7.32 (PASS, better than v8: drone partials +0.4..+0.9 c, 60-250
    Hz p90-p10 0.4-0.5 dB). v14 (built from `projects\story_choir_v13.flp`, so the plugin edit carries over) holds the
    last drone chord 7.9 beats like the rest: the <200 Hz seam dip -40 -> -31 dB, but the seam stayed as low, because
    the loop's first drone note rises from silence (VCA attack 288 ms) while re-strikes restart from the sounding level.
    v15 (PASS, `projects\story_choir_v15.flp`): VCA attack 18 ms, VCF attack 10 ms; the seam's momentary low is now
    level with bars 3/13 (-21.0), drone within 0.8 dB of steady after the restart, no click. Its Sustained Bells vary
    per render: render twice if the four strikes are more than 3 dB apart (rchoir15 5.7 dB, rchoir15b 1.2 dB).
  - v16 (`projects\story_choir_v16.flp`, template `templates\story_choir_template_v2.flp` = v15 + a clone
    `choir_unison #2`): a key test (one choir note per key, 58-70) showed sample zones 62-64 / 65-67 / 68-70; the
    D4-E4 zone warbles, F4-G4 much less. Eb4 now plays F4 on the clone, PITCH -200 (-183 measured 20 c sharp), VOL
    +2.5 dB (`maps/story_choir_v16_fix.json`). The bell's strikes are fixed per project load (two renders without
    reloading came out identical), so reload before each re-render; render rchoir16 had a 2.7 dB spread.
  - To keep an FL plugin edit across a rebuild, use the saved project as `--template` (channels then carry the part
    names, so the identity map `maps/story_choir_v9.json`).
- **Hollows v7 (PASS):** the drone's A3/E4 octave layer plays on a clone channel `drone #2` (same insert) at +3 dB
  (`maps/place_cave_fix.json` routes keys 57/64 there and sets its volume; template `templates\place_cave_v7_template.flp`,
  map `maps/place_cave_v7.json`). Drone-only bars on a 250 Hz high-pass: -30.4 LUFS (v6 -33.8). Open MINOR: muffled,
  the harp leads the drone by only +0.9 LU median (raise the harp +1 dB if it matters).
  v8 (PASS, no MINORs, `projects\place_cave_v8.flp`): the v7 notes with the harp's mix target -23 (gain 2.4),
  re-mixed with `flp_mix.py --lufs-trim 1.0`; no FL edit needed.
- **Half-Remembered v10-v11:** the pad now carries each chord's root (Db above all) so the cue isn't heard as F minor
  over the sub, and the fade thins the pad by voices (3, 2, then 1 above the root): the preset barely follows velocity.
  The choir sings only chord tones the pad isn't holding (Simple Ohh's C4/C#4 sit ~14 c under the pad's unisons and
  beat) and never a pitch-class semitone from a celesta note still ringing (v10's bar 16 G4 under Ab5). The sub is no
  longer humanized, so its in-phase seam can't depend on the seed; unhumanized, the last C#1 (34.63 Hz) met the first
  one in anti-phase at the seam (v10), so v11 starts it 13 ms later with the same end.
  v11 PASS, no MINORs (`projects\story_memory_v11.flp`): seam sub correlation +0.90 (v10 -0.95), no 25-75 Hz dip.
  Notes: the in-phase seam swells +4.5 dB in 25-75 Hz (end the last C#1 ~0.5 s earlier to level it); the fade reads
  only over bars 23-24.

## The placeholder cues, made in FL (2026-11-18)
The production tracker always listed 17 cues as not yet made in FL (their OGGs were the MIDI placeholders from PRs
#85/#115). They are made in region/dungeon pairs, one PR per pair, in tracker order.
- **12 Low Strings fixed in the templates:** `templates\ambient_sine_template2.flp` = ambient_sine_template with
  pad_warm's Prophet-5 Osc2 mixer at 0.00 and Osc1 at 7.32 (as story_choir v13). Gloamfen v1 and Mire v1 failed
  review on the stock preset's +20 c twin (bass/drone beating 17-21 dB at 0.6-1.4 Hz). Every template that uses
  12 Low Strings low needs the same edit; Gale's brass_low got it inside `projects\dungeon_gale_v1c.flp`.
- **Simple Ohh:** C4, C#4 and Eb4 warble (two layers at about -19 c and 0 c); `maps/<cue>_fix.json` plays them an
  octave down ("play"). Gloamfen, Mire and Frostspine do this.
- **Loudness trim:** with --lufs-trim 0, ambient_sine renders came out 4.3-5.6 dB over target; start at -4.5.
- **Mire v2:** Sustained Bells peaks 0.6 s after note-on, too late for a 0.75 s melody, so the bell line moved to the
  celesta channel (Analog Harp) and the harp line to guitar_nylon (insert 6, stem bell_ember).
- **Gale:** boss_template3; the flute line is sung by Ah Voice (choir), bell_tubular on harp; its render runs 33 s past
  the loop (the template's song length), which finalize folds back.
- **Analog Harp decay:** the celesta channel's ARP Odyssey patch held like a flat sine (VCA decay 2 ms, full sustain).
  `templates\ambient_sine_template3.flp` sets the VCA's decay so it rings like a struck bar; template4 adds a
  `bell_sparse #2` clone (Frostspine). Templates saved from a built project carry part-named channels and its Pro-Q
  gains: rename the channels back with flp_raw before building, and add the template's insert gain to stem_balance's
  gain when the stems were rendered through it (Glacier v1b).
- **Sustained Bells is out:** its keys are 3-12 c off in no pattern, so neither a PITCH knob nor a clone tunes it
  (Gloamfen v2-v4 failed on it). template5 adds `celesta_b`, a clone of the in-tune Analog Harp on insert 5, and
  Gloamfen's vibes play on it.
- **cap_at_next** (fix option): ends each note where the part's next note starts, so a long-ringing bell doesn't stack
  a stepwise line into a cluster (Gale's tubular bell).
- **A fixed preset needs fresh gains:** the fixed 12 Low Strings is ~15 dB louder than stock, so Windmere v1 failed
  with the pad 10 dB over the flute. Always set gains from stems rendered with the fixed preset.
- **Stems from a template carry its gains:** a template saved from a built project keeps that project's Pro-Q output
  gains, and split-mixer stems are post-insert. So stem_balance's gain is relative: new gain = the insert gain used
  in that render + (target - measured), measured with the mix json's eq stripped (it is already in the stem).
  Frostspine v1 and Gloamfen v5 came out with the bass 8-11 dB hot from skipping this; Glacier v1c, set this way,
  measured within 0.1 dB of every target.
- **Trims seen:** with gains set that way, ambient_sine templates need about +1.0 to +1.3; boss_template3 +1.5. (The
  earlier -2.5 to -4.5 trims were making up for wrong part gains.)
- **ceiling** (mix json): Pro-L 2's output ceiling, default -1.5. Glacier's ticks made the OGG peak 0.5 dB over the
  master's -1.51, so it uses -2.2.
- **Passed:** Mire v3 (`projects\dungeon_mire_v3b.flp`), Windmere v2 (`projects\region_windmere_v2.flp`; MINORs left:
  pad ~4 dB hot, the snare reads as a low tom), Gale v3 (`projects\dungeon_gale_v3b.flp`), Gloamfen v6
  (`projects\region_gloamfen_v6b.flp`; MINORs left: the choir's detuned layers beat at 1-1.8 Hz against the in-tune
  vibes in B/A', so put its Eb3 on a +7 c clone; A-section floor p5 -26.2 dB, +0.5 dB on Pro-L fixes it; B is 5.3 LU
  under A on a phone, +2 dB at 400-700 Hz on the choir insert), Frostspine v2 (`projects\region_frostspine_v2b.flp`;
  MINORs left: in bar 19 the bell's F#5 lands in unison on the ringing e-piano F#5, same patch, and they cancel, so
  move it to B5 or drop it; the e-piano's 4-beat notes still fall 14 dB by +2 s, VCA sustain ~3 of 10 would hold them;
  the bell sits only 1.8 dB under the e-piano and reads as a second e-piano; choir warble and C#4 sung as C#3).
- **template6** (`templates\ambient_sine_template6.flp`): template5 plus two more Analog Harp clones, renamed
  locally to `celesta_bow` (insert 5: attack ~0.3 s, sustain 4.0 of 10, release ~1.2 s, for bowed vibes and glass:
  Gloamfen v5 failed with the vibes ringing out like a second celesta) and `celesta_tick` (insert 1: decay ~0.2 s, a
  pitched tick for Glacier, whose frame drum at key 75 read as a 268 Hz knock). In Analog Lab, a first press on an
  ARP slider can jump it to the pointer; hover first, then drag and read the tooltip.
- **Gale v3:** the tubular bell (stock Analog Harp, decay 2 ms and full sustain) now has decay 1.3 s, sustain 0 and
  release ~0.4 s, edited in `projects\dungeon_gale_v3raw.flp`; strings high cut 4 kHz at 24 dB/oct.
- **Frostspine v2:** built from template5 with the bell on the in-tune clone; the e-piano's VCA decay lengthened
  to ~5 s in `projects\region_frostspine_v2raw.flp` (v1's melody died 23-26 dB within 2 s).
- **Reload before rendering an Analog Lab edit:** Gale's stems rendered right after editing the bell's VCA still
  played the old envelope (flat sustain); the same project reopened from disk rendered the new one, 6 dB quieter.
  Save, reopen, then render stems for gains.
- **Glacier v3 (PASS):** `templates\ambient_sine_template7.flp` = template6 with the bowed clone's sustain raised to 6.8 of 10
  (v2's glass sank 8 dB by 1.5 s) and three more tick clones (`epiano_glass #4..#6`, insert 1). Analog Harp ignores velocity,
  so the tick's velocity bands go to the clones at -5.7/-2.7/0/+2.1 dB (`vel_channels` in the fix map, new in flp_build):
  0.28 dB per step against the sketch's 0.30, and D builds +1.95 LU over C. Open MINOR: dark (2-6 kHz -29.9 dB vs the
  sketch's -17.3) because the bell is a near-sine.
- **Sunken Verge:** Diamond bass Ab2 (key 44) is 8-12 dB hot and its partials disagree (-17 c fundamental, +5 c
  overtones); it plays G2 on the `bass_g3` clone at PITCH +108, -5 dB. Ample Guitar's lowest note is E2, so a harp Eb2
  is silent: play it an octave up. A harp Eb2 on bar 1 also made the seam step 9.6 dB; finalize caps seam steps at 8.
- **Sunken Verge v2 (PASS):** MINORs left for the polish pass: the harp's Eb3 root and the F#3 after it share a string
  in Ample Guitar (hammer-on: the root is cut and F#3 is 8 dB soft), so put keys 39 and 63 on a second Ample channel on
  insert 6 and drop the root's -6 dB; Eb4 +7.5 c (PITCH about -8 on that channel); bright at 2-3 kHz (bells -5 dB at
  2.75 kHz on the pluck, -3.5 dB at 2.2 kHz on the clarinet); bass F#2 +3.7 dB (`"42": db -3`); Pro-C dips the mids
  1.7 dB on each bass note.
- **belfry_template** (`templates\belfry_template.flp`): kiln_template3 with Ah Voice on choir (insert 4), Clock Bell
  on timpani (insert 1), Analog Harp on bell_marrow (insert 7), Saint Eustache organ on harp (insert 2), 12 Low Strings
  on brass_low (insert 8) with Osc2 at 0 and Osc1 at 7.32: the preset ships with a detuned second oscillator, zero it
  on every project that uses it. Belfry, Tomb and both Maw cues are built on it; the drum (drum_taiko) renders on the
  insert-3 stem labelled sub_breath.
- **Belfry v1:** the loop restarts 6.2 dB over its quiet last bars (finalize's limit is 6). The new fix key
  `at_ticks` ({"<start tick>": dB}) softens only bar 1's organ chord and bass note, which brought it to 5.6.
- **Ossuary:** drum_hand's keys 50 and 52 play on the `drum_high` clone, so gate the summed drum stems. Gains must be
  relative to the insert gain the stems were rendered with (v1 used absolute gains and came out at -9.8 LUFS).
- **Belfry v2 (PASS):** the Clock Bell's loudest partial is a flat major tenth (ratio ~2.49); a -10 dB bell at 1.45 kHz
  and a 3 kHz high cut on insert 1 make the fundamental lead. MINORs left: the tenth is still only 6-7 dB under (add a
  -6 dB bell at 1.5 kHz Q 1.6 and a second 2.2 kHz high cut, or swap the bell); section D bright (-13.5 dB 2-6 kHz);
  the organ's A3 (sent as key 69) sounds an octave high; the sketch lifts A' by 1.6 dB and the render doesn't (organ
  and bass ignore velocity, so use a louder clone or automation); seam step 5.8 against the 6 dB limit.
- **Ossuary v2 (PASS):** v1 failed because the bone marimba sat ~7 dB over plan where it leads; stem_balance's whole-
  stem median is set by its sparse knocks, so judge it over section B only (noted in the mix json). Fix-map keys are
  looked up after the transpose. The marimba moves 0.145 dB per velocity step (0.33 at the bottom of the range), the
  drums 0.234. v2's OGG peaked at -0.99 dBTP from a -1.52 master, so its ceiling is -2.0. MINORs left: quiet drone-only
  intro (6 LU under the body), drum_hand 1.4 dB under plan, -18.9 LUFS (about +0.8 trim).
- **Marrow Tomb:** stock Analog Harp has VCA decay 2 ms, sustain 10, release 3.3 s, so a "marimba" on it rings for
  seconds; v2 sets both VCA rows to decay ~1.3 s, sustain 1.5, release 0.17 s (`projects\dungeon_tomb_v2a.flp`).
- **Tomb v2 (PASS):** MINORs left: with sustain 1.5 the long marimba notes fade under drone and choir after ~0.6 s
  (raise sustain to ~3-3.5 or decay to ~2.5 s, keep the 0.17 s release); drum accents dip the master 3.3 dB (100 Hz
  side-chain high-pass on Pro-C); the frame drum is a 43 Hz thud (low cut 60-70 Hz, +3-4 dB at 150-250 Hz).
- **Maw region v1 (FAIL):** Trumpfal can't hold a 4-beat note at 58 bpm (one resampled trumpet: its length scales with
  1/f, and it carries a half-frequency series 8-9 dB under the harmonics). The Dark Pad (SQ-80) has unison, a tape-delay
  wow and a Juno chorus that beat its octave partials 9-24 dB at 1-4 Hz; switching them off didn't stop it.
- **Maw region v2:** brass_low = Analog Lab "Tuba" (Orchestral Brass, Theo Niessink; a tape-sampled tuba that holds
  flat to the end of a 4 s note, in tune to 1 c, sounds an octave below its key, so +12). An audition of Tuba, Orch2
  (dies at 2 s), Duohorn (detuned, period-doubled) and Ascendant Brass (10 dB PWM wobble) is in
  `templates\brass_audition.flp`. sub_breath moved to the Analog Harp (bell_marrow channel, insert 7): its VCA sustain
  is already 10 and its filter envelope closes to a near-sine, a steady mono sub (0.2 dB movement).
- **Maw dungeon v1 (FAIL):** `advance_s` on a note held across the loop end lost the drone in bars 3-4 (FL stops a
  note at the song end, so the fold carried only its first two bars); don't advance a note that spans the restart. The
  Saint Eustache organ has a celeste rank (~1 c apart: the fundamental dips 22 dB every 4 s) and a sharp tierce, so
  it can't play long notes; v2 plays metal_bowed on the sustained Analog Harp.
- **Maw region v2 (PASS, `projects\region_maw_v2c.flp`):** MINORs left: the Analog Harp sub's 3.3 s release folds
  onto bar 1 out of phase (40-60 Hz dips 9 dB for 0.25 s) and smears note changes 4-8 dB (VCA release ~0.4-0.5 s);
  the choir's bar-17 chord dies 1.5 s early; brass 2.1 dB under strings and choir above 300 Hz in bars 17-32 (choir
  -29.5); choir keys 62/63 speak late; loud strings chords not louder (`vel_channels` clone +2 dB); strings dip 3 dB
  at chord changes.
- **Maw dungeon v2 (PASS, `projects\dungeon_maw_v2b.flp`):** MINORs left: the heartbeat drum (sample 47) still loses
  18 dB on small speakers (add a body layer: a clone playing sample 50 at -10 to -12 dB, or saturation on insert 3);
  metal_bowed's 3.3 s release smears its steps (VCA release 0.8-1.0 s or `cap_at_next`) and its 17 ms attack reads as
  a sine lead (attack ~0.3 s); section B doesn't lift (+2 dB on insert 4 over bars 17-24, or a choir clone).
- **Vael v1 (FAIL, BLOCKER):** a transpose key is looked up both as a part and as a channel name, so the timpani's
  `+1` (keyed "timpani") also shifted the bell part playing on channel "timpani" a semitone sharp. flp_build now
  refuses a transpose key that is both a part and another part's channel; key such a part by its own channel.
- **The PITCH knob's units:** on Staccato Blend one unit is about 1 cent (key 51: 6 units = +18 c, 17 = +29 c; the
  key itself is ~+12 c off). Measure a preset's units before using `pitch` (v1 assumed 2.35 c and overshot). Staccato
  Blend's fundamentals and upper harmonics disagree by up to 30 c on some keys, so tune by h2-h8, not h1.
- **Clock Bell above D5** scatters 15-25 c key to key; boss_heart's seven bell parts play on the Analog Harp instead
  (`templates\heart_template.flp`: harp channel = Analog Harp, stems on the harp/insert 2 label).
- **Templates:** `vael_template.flp` = belfry_template with Gong & Timpani on sub_breath (insert 7).
- **Vael v2 (PASS, `projects\boss_vael_v2b.flp`):** key 51 reads -1 c on h2-h8; Staccato Blend is judged by its
  harmonics (the gate's fundamental reading is waived on keys 51/63). MINORs left: choir 2.5 dB under in B (choir +1,
  ostinato -1.5 there); key 46 speaks ~24 ms late (nudge it earlier); strings_high 5-8 c sharp; the bell's tenth
  only 7.5-8.5 dB under its fundamental (target 9).
- **Heart v1 (FAIL, MAJOR):** the stock Analog Harp holds full level and releases over ~3 s, so 3-4 bell pitches
  overlap at most onsets and the seven motifs merge into a pad (the same fault failed Gale v1/v2). v2 gives the bells
  channel a struck envelope (VCA decay ~1.4 s, sustain 0, release ~0.4 s). MINORs: no climax (A -16.6, B -17.7,
  C -17.0 LUFS; Trumpfal/choir velocities don't render, so use volume automation); bright (2-6 kHz -11, brass most of it).
- **Heart v2 (PASS, `projects\boss_heart_v2c.flp`):** struck bells: one bell pitch per onset, each note falls ~23 dB
  in 1 s, all seven bells at 0 c. Measure a cue's stems with its noeq json (stem_balance applies the mix eq again
  otherwise). MINORs left: no climax (C 0.5 LU under A; route louder-written brass/choir/strings notes to clones with
  `vel_channels` + `volume_db`: brass +3.5, choir +2, strings +1.5 in C); still bright (2-6 kHz -12.6 A / -12.1 C;
  a second brass cut -6 dB at 3.2 kHz Q 0.8).
- **Wayshell Flight v1 (FAIL):** the OB-Xa "B-1 French Horn" is near a sine (h2 -20 dB, h3 -32 dB at A5) with a
  decaying hold, so it doesn't read as a horn, and its A' climb went above a real horn's range (to B5). A' sat 0.4 LU
  under A. v2: the A' climax is rewritten with the horn an octave down (D4-B4) and the strings on the written top
  line; the horn moves to the Mellotron "French Horn Solo" (sampled, velocity-responsive, no samples above F5); the
  harp glissandi are 12 velocity steps softer. A horn audition (Mellotron, B-1, Soft Horn) is
  `templates\horn_audition.flp`.
- **Pattern mode:** saltmarrow_template8 saves in Pattern mode, and a project built from it opens in Pattern mode,
  so the render dialog says "Pattern" and drops the song's tail room. Switch to Song before ctrl+r and check the
  dialog reads Full song.
- **Overworld v1 (PASS, `projects\overworld_v1c.flp`):** saltmarrow_template8, harp line on Ample Guitar, flute on
  Meadow Flute; harp keys 43/48/53/57 trimmed (db_per_vel 0.3). MINORs left: the nylon guitar isn't a harp and its
  same-string notes choke each other 5-13 dB (a harp preset, e.g. the struck Analog Harp, would fix both); 7 of 16 bars
  repeat a key on beats 1-2, and the cadence bass in bars 8/15 sits ~7 dB under; the D-major chords in bars 8/15 bring
  in F#, out of G mixolydian (F or Dm).
- **Wayshell Flight v2 (FAIL, MAJOR):** the Mellotron horn is darker still (2-6 kHz share -50 dB; h2 -24, h3 -38 dB at A4)
  and velocity moves its level, not its brightness. v3 (`projects\story_flight_v3c.flp`, template
  `templates\flight_template3.flp`): a clone of the brass channel, `trumpet`, plays the same part on Trumpfal at VOL -20 dB
  on the same insert; its bright attack sits under the Mellotron's sustain (horn stem 2-6 kHz -24.6 dB). At VOL -6 the
  trumpet took over (+6.4 dB, -17.7 dB share). Built with `--audition "...;horns_french=brass,trumpet;..."`, which
  sends one part to two channels (the full command is in `mixes/story_flight.json`). v2 MINORs still open: strings
  +6-7 c sharp, horn onset +84 ms, choir keys 62-64 ~230 ms late, the harp glissandi ignore velocity.
- **Credits v1 (FAIL, MAJOR):** `templates\credits_template.flp` (Meadow Flute on insert 6, a bell clone on insert 1,
  a cello clone of brass_low on insert 3; struck Analog Harp on insert 2, strings_hi on 5). The last four bars were
  four equal full-level strikes that stopped dead (harp, choir and bass ignore velocity, so "3 dB under" rendered
  0-0.5 dB under). v2 holds one chord at bar 93 and ends on a soft two-note harp roll that rings out; Wren's hum
  (cello) goes an octave down (it was the brightest section); the eighth-line strings are a pair, not a triad; the
  harp spells root, third and fifth an octave up. Open: choir keys 62/64 ~0.2 s late (Ah Voice zone), bell darker
  than the in-game Point bell.
- **Overworld v2 (FAIL, reverted to v1):** the struck Analog Harp (h2 27 dB under the fundamental, 2-6 kHz -42.5 dB)
  reads as a sine pluck and loses 17 dB through a 300 Hz high-pass, so the cue turns into solo flute on small
  speakers. The struck harp needs an opened filter or a plucked attack layer before it carries a line alone.
- **Wayshell Flight v3 (FAIL) / v4 (PASS, `projects\story_flight_v4b.flp`, template `templates\flight_template4.flp`):**
  Trumpfal dies 0.6-1.0 s into a note, so v3's held notes went dark again. v4's layer is Orchestral Brass "Dirty
  Bronze" (sustains bright; picked in `templates\horn_audition2.flp` over Prophet "43 Horn" and "Cresc. Horns 1"),
  clone `bronze` at VOL -24 dB (-14 took over). Held-note 2-6 kHz -24 dB (v3 -49). Open MINORs: the bronze's edge
  lands ~90 ms after the note and fades like a synth filter envelope; it adds a sub-octave series (300 Hz lowcut on
  its own insert); A' still darker than A (bronze ignores velocity: a +3 dB A'-only clone); climax horn -6.6 dB;
  strings +6.5 c; choir keys 62-64 ~0.2 s late; harp glissandi +3-5.5 dB.
- **Credits v2 (FAIL, MAJOR) / v3 (PASS, `projects\credits_v3e.flp`, template `templates\credits_template2.flp`):** v2's
  last chord was no softer than bar 92 and ended on a bare D3-D4 struck-harp octave that died in 1.5 s, so the cue
  stopped on a thin pluck. v3 thins the close (bar 92 bass, choir and a harp roll at 2.9-2.5 beats; bar 93 bass 6,
  string pair 7.5, choir 11 beats; a last harp roll of root, third and fifth at bar 95) and puts Fruity Reeverb 2
  "Large Hall" on the inserts, so the last chord rings ~4.2 s into a ~4 s hall. Trim 1.0 gives -17.0 LUFS; the OGG is
  3:29.8 (the roll paces itself to the music, so the tail is safe). Open MINORs: the close is only 0.4 LU under the
  bars before it (the harp ignores velocity: a -4 dB clone for the last roll, or master automation); the final ring
  is light on its root D (hold the strings' D4, D on top of the last roll); the eighth line is brighter and only 1.9
  LU under A; choir keys 55/62/64 still ~0.25 s late (a clone with advance_s 0.2); the hall costs the flute F#4s and
  the bell's A5s some clarity (-6 dB wet on harp and strings before bar 93); harp key 62 gates 3.2 dB low.
- **Heart v3 (PASS, `projects\boss_heart_v3b.flp`, template `templates\heart_template2.flp`):** section C (bars
  35-48) has its own parts strings_c, choir_c and brass_c, routed in FL to clones of strings_full, choir and brass at
  +1.5, +2 and +3.5 dB VOL on the parents' inserts (maps `boss_heart_v3.json`, `boss_heart_v3_fix.json`); the brass
  gets a second cut (-6 dB bell at 3.2 kHz, Q 0.8). A -17.25, B -18.19, C -15.92 LUFS: C is the climax (+1.3 LU) and
  the seam still lands as the climax settling back. Measure with symlinks for the _c parts onto the parents' stems.
  Open MINORs: still bright in C (2-6 kHz -13.1, bars 36 and 40 over -12: a -3 dB bell at 3.2 kHz on the strings);
  the brass_c peaks D6/C#6 (bars 38, 40, 41) are its softest notes, 3-4 LU under the rest of the line (keys 85-86 to a
  +2 dB clone, paired with a deeper strings cut).
- **Wayshell Flight v5 (PASS, `projects\story_flight_v5.flp`, template `templates\flight_template5.flp`):** the A'
  horn is its own part `horns_a2`, played on the Mellotron plus a second Dirty Bronze clone `bronze_hot` at VOL -21 dB
  (A's bronze stays at -24). A' horn attacks are now within ±1.2 dB of A's brightness (v4 1.8-2.9 dB darker) and the
  climax horn sits -5.4 dB against the rest (v4 -6.6), with no takeover. The horn insert holds a ~-100 dBFS noise
  floor (in v4 too), so a render can run past the end; it folds 80 dB under. Open MINORs: the mix-level A' lift is
  still missing at 1-3 kHz (-0.1 dB vs the +1 test); the bronze's sub-octave series rose 1-4 dB, so bar 22's D#5 sits
  +3 dB over the mix at 622 Hz (listen: if it reads as a second voice, it is a MAJOR; a 300 Hz lowcut on a separate
  bronze insert would fix it); the bronze's late edge and fade, tuning scatter, and v4's strings/choir/harp MINORs.
- **Heart v4 (PASS, no MINORs, `projects\boss_heart_v4b.flp`, template `templates\heart_template3.flp`):** brass_c
  keys 85-86 (the D6/C#6 peaks) go to a clone `brass_peak` at VOL +5.5 (renders +2.66 dB over brass_c's +3.5: FL's
  VOL steps aren't dB-linear) via `"keys": {"85": {"channel": "brass_peak"}}` in `maps/boss_heart_v4_fix.json`; the
  strings get a -4.5 dB bell at 3.2 kHz Q 0.8 (+0.7 dB strings gain to keep their level), Pro-L trim 1.4. 2-6 kHz
  A -15.9 / C -14.3, C +1.41 LU over A. NITs: bar 40 sits exactly on -12 dB 2-6 kHz (brass_peak VOL +5.0 would give
  0.15 dB room); the cut takes ~0.5 dB off the strings' attack bite.
- **Credits v4 (PASS, `projects\credits_v4.flp`, template `templates\credits_template3.flp`):** the last roll (bar 96)
  is its own part `harp_end` on a clone of the struck harp at VOL -4 dB (renders -4.2 dB, same tone and tuning),
  voiced F#4 A4 D5 so it ends on the root; the strings' D holds to the end. Bar 96 -18.6 LUFS (v3 -17.5); D in the
  last bar -2.9 dB under the top pitch class (v3 -7). Open MINORs: bars 94-95 are still only 0.6 LU under 89-92 (the
  level must come off the held chord: -4 dB string and choir clones or master automation); the hall tail after the
  release is the choir's A/F# (D -8 dB: choir key 62 on a +4 dB clone with advance_s 0.2 would also help the late
  choir keys); v3 MINORs 3-5 unchanged.
- **Wayshell Flight v6 (PASS, `projects\story_flight_v6c.flp`, template `templates\flight_template6.flp`):** the two
  bronze clones play through their own insert 7 (the unused timpani insert, which already had Pro-Q 4; a rack row's
  insert box changes with the mouse wheel) as mix part `bronze_layer` in `mixes/story_flight_v6.json`: 300 Hz
  24 dB/oct low-cut and a -8 dB bell at 622 Hz Q 4. Bar 22's D#5 went from +0.1 to -9.6 dB under the rest; horn 20-250 Hz
  share -25.8 (v5 -14.2). The cut cost the horn 0.9 dB, so the horn and bronze gains are 10.7. stem_balance now reads
  the Mellotron alone on the horn stem (it asks +0.8 dB: don't apply it). Open MINORs: the bronze's free-running sub
  layer lands differently each render, and here swells a 2.5 f0 B#5 (1038 Hz) at bar 22 to +7-10 dB over the rest
  late in the note (the real fix is a preset without the sub layer; a -6 dB bell at 1038 Hz is a stopgap); the A'
  mix-level 1-3 kHz lift is still 0 dB; v5's other MINORs.
- **Credits v5 (PASS, `projects\credits_v5.flp`, template `templates\credits_template4.flp`):** the held closing chord
  (bar 93 on) moves to its own parts `bass_end`, `strings_end`, `choir_end`, on clones of their parents at VOL -4 dB
  (`maps/credits_v5*.json`; the clones keep the parents' +12 transpose and advance_s). Bars 94-96 now sit 3.1 LU under
  89-92 (v4 0.6), only just over the 3 LU line (render variance ~0.4 LU); bars 95-96 alone sit 4.0 under. The drop
  eases in under the unchanged bar-94 harp roll. The strings clone renders -4.8 dB and a little brighter. Open
  MINORs: the ring after the release is still the choir's A/F# (D -7.7 dB: a choir_end key-62 clone at +4 dB with
  advance_s 0.2); the bass now re-articulates at bar 94 (lengthen the bar-93 bass_arco note to 3.1 beats); the last
  roll stands 0.9 LU over bar 95 (harp_end -6 to -7 dB would seat it); v3 MINORs 3-5.
- **Wayshell Flight v7 (PASS, `projects\story_flight_v7.flp`, template `templates\flight_template6.flp`, mix
  `mixes/story_flight_v7.json`):** the bronze_layer insert keeps only 1.5-6 kHz (24 dB/oct low-cut at 1500 Hz, no
  622 Hz bell), so the patch's free-running sub-octave series (0.5/1.5/2.5 f0) is under the rest on all 27 horn notes:
  bar 22's D#5 -30 dB, B#5 -16 dB (v6 -9 / +2, peaks +14). A' still lifts (horn +3.1 dB over A). Cost: the bronze
  lost 5.8 dB and with it the horn's 1-2 kHz presence and h2/h3 body (5-6 dB less against the mix), and the climax
  horn (bars 21-24) sits -6.4 dB under the rest (test >= -6). Above 1.5 kHz the bronze is still a sub-octave voice
  (its 3.5 f0 G6 stands 18-21 dB over the rest on bars 2.33 and 18.33): only a preset without the sub layer removes
  it. Open MINORs: horn presence (a +3 dB bell at 1.1 kHz Q 1 on insert 6), climax lift (A' horn +1 dB), the A'
  mix-level 1-3 kHz lift (+0.2 vs +1.0), v6's bronze swell, strings +6.5 c, late choir keys 62-64, hot harp glissandi.
- **Credits v6 (PASS, `projects\credits_v6.flp`, template `templates\credits_template5.flp`):** the bar-93 bass note
  is 3.1 beats so it overlaps bass_end (the barline dip fell from 4.7 to 2.3 dB); choir_end's D4 plays on its own
  clone `choir_end_d` at VOL 0 dB (key route in `maps/credits_v6_fix.json`) and choir_end plays 0.2 s early; harp_end
  -6.5 dB (bar 96 now level with bar 95). Close 3.18 LU under bars 89-92. Measured on the chord's fundamentals
  (180-620 Hz) D leads the ring (v5 -5.0); a full-band pitch-class measure counts the D's 3rd harmonic (880 Hz, on the
  choir's formant) as A, so don't judge the root that way. A louder D clone breaks the 3 LU drop (+1.5: 2.65 LU, +4:
  1.97). Open MINOR 6: Ah Voice drops held voices 15-25 dB at random ~5 s into a long chord (3 of 10 renders), so the
  tail isn't repeatable: cut choir_end's A3 from 9 to 6 beats (F#4 to 7.5) and let the strings carry the root; accept
  when two renders agree. v3 MINORs 3-5 unchanged.
- **Wayshell Flight v8 (PASS, `projects\story_flight_v8.flp`, template `templates\flight_template7.flp`, mix
  `mixes/story_flight_v8.json`):** a +3 dB bell at 1.1 kHz Q 1 on the Mellotron (insert 6), and the A' horn on its
  own Mellotron clone `brass_a2` (+1.3 dB VOL, same insert) with bronze_hot at -20 (`maps/story_flight_v8_fix.json`,
  build with `--audition "...;horns_french=brass,bronze;horns_a2=brass_a2,bronze_hot;..."`). Climax horn (bars 21-24)
  -3.7 dB against the rest (v7 -6.4): closed. But it overshoots: in bars 19-24 the horn is level with the strings'
  top line (v7 -3.0) and leans darker than A; the bell lifts every horn note ~1 dB, brass_a2's +1.3 rendered ~+1.5.
  The bell won back only a third of the lost h2 and none of h3 or 1-2 kHz presence: that was the bronze's, and needs
  a bronze preset without the sub layer (then a 300 Hz cut). Open: brass_a2 to 0 dB (v9), bronze swell, A' 1-3 kHz
  mix lift -0.4 (test +1.0), strings +6.5 c, late choir keys 62-64, hot harp glissandi.

## The seven jingles, made in FL (2026-11-19)

- Built from `cues/t17_jingles.py` with flp_build. Six on the credits template (harp, struck bell, choir, low
  strings), clear on the heart template (brass, timpani, bells). Maps and mixes are `flp/maps|mixes/jingle_*.json`.
- One render to measure, then one `--lufs-trim` rebuild: v1 read -14.5 to -26.6 LUFS (the lone-bell jingles were
  ~10 LU short), v2 landed -15.6 to -16.7. game_over v1 was on target and shipped as rendered.
- Every stem passes gate_stems. True peak -2.6 dBTP or lower.
- `post/finalize.py` writes jingles to `audio/sfx/<id>.ogg`. The game loads that before the old generated `.wav`.
  The OGGs are kept out of LFS (`.gitattributes`), like the music.
- **Review v1 FAIL -> v2:** clear cut off (the heart template's brass sounds ~1.3 s whatever the written length: the
  cadence chord is now 1.5 beats and the bell rings on); item, pearl and puzzle shared the Analog Harp (item now on
  guitar_nylon, insert 6; puzzle on brinewood_template's Emulator II Marimba with its chord on the kalimba channel,
  insert 6, 16 dB down: this marimba moves only 0.125 dB per velocity step, so velocity can't balance a chord);
  pearl's choir 9 dB down. Loudness trims are not linear through Pro-L: item needed three tries (+4.75 -> -14.4,
  +3.15 -> -17.3, +3.9 -> -15.7).
- **FL gotchas this round:** computer_open_application on FL can show the Welcome screen / reload FL; render Mode
  resets to "Pattern" on the brinewood template (set Full song every time); after a restart Ctrl+O opens in the
  Driftwood FM folder, so always type the full projects path.
- **Review v2 FAIL -> v3:** clear's brass still cut off (Trumpfal can't hold a note at all): the brass is now a short
  stab and a new `strings` part (strings_full, insert 5, boss_heart's EQ) plus the marrow bell carry the 4-beat tail.
  item's nylon guitar thumped on release and collapsed its chord: moved to house_template2's felt piano (insert 5)
  with the glockenspiel (insert 1), 2-bar cue, notes held past their natural decay. Item trim 6.3 -> -16.0 LUFS
  (trim 0 read -20.9, trim 5 read -17.3).
- Computer-use approvals expire after 24 h: re-request FL Studio 2025 (with clipboard) when calls start failing.
- **Polish after review v3 (PASS, 8 MINORs):** item v4 melody an octave lower (D4-A4; the felt piano's stereo spread is
  worse up high) and held 5 q, not 8 (tail -60 dB at 5.0 s, was 6.9); puzzle kalimba -5 dB, not -16 (14 dB under
  the marimba, was 25.5); game_over v2 holds D2 A2 only (its E3 rubbed the melody's F3) with the bell +6 dB (9 dB under
  the strings, was 16). The game_over "brass_low" channel is the 12 Low Strings preset, so its strings are real.
  The jingles were built on credits_template5 with channels renamed by hand; rebuild game_over from
  `work/jingle_game_over_notes.flp` as the template, since the maps name the renamed channels.
