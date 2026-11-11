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
