#!/usr/bin/env bash
# The fast checks CI runs before Godot starts. Run this before every push:
#   bash tools/check.sh
# Or once per clone, to run it automatically on `git push`:
#   git config core.hooksPath .githooks
set -e
cd "$(dirname "$0")/.."
python3 tools/build_art.py --check
python3 tools/check_strings.py
python3 tools/sfx_gen.py --check
python3 tools/dungeon_check.py --check
for f in tools/*_rooms.py; do
  python3 "$f" --check
done
