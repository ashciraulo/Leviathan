#!/usr/bin/env bash
# Rebuilds every cue's MIDI and runs the writing gates. Fails on any finding.
#   bash music/build_all.sh            (needs: pip install mido)
set -e
cd "$(dirname "$0")/.."
python3 music/track_sheet.py
out=$(for f in music/cues/t*.py; do python3 "$f" --gate; done)
echo "$out" | grep -v "^GATE" | tail -n +1 | wc -l | xargs echo "cues built:"
if echo "$out" | grep -q "^GATE"; then echo "$out" | grep "^GATE"; exit 1; fi
echo "all gates pass"
