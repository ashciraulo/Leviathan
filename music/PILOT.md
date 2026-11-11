# Pilot: region_saltmarrow end to end

The first cue goes through every step before any other cue is built in FL
(handoff lesson 4). Each step records what it found here, so the next cues
copy a working recipe, not an assumption.

## PC folders (approve once)
- `C:\Users\Ashle\OneDrive\Documents\Leviathan Music\` — `projects\` (.flp, one per cue; old versions to `_old\`), `templates\`, `midi\`, `masters\` (final FLAC).
- `C:\LeviathanMusic_Render\` — not synced: stems, raw renders. WAV -> FLAC at once, WAVs deleted.

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
