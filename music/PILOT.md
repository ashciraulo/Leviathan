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
| bass_upright | bass | Analog Lab Upright Bass (passed); Diamond upright (cap velocity 88, re-pluck held notes) |
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
