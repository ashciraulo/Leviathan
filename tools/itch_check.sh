#!/usr/bin/env bash
# Checks the folders the itch.io upload pushes, one per channel, before
# anything goes up (.github/workflows/itch.yml):
#     bash tools/itch_check.sh channels
# web/      the browser build: index.html at the top, which itch plays in
#           the page (no threads, so no special headers needed)
# windows/  Leviathan.exe        linux/  Leviathan.x86_64 (executable)
# mac/      Leviathan.app
# Each download carries THIRD_PARTY_LICENSES.txt. itch's limits for a
# browser game: at most 1,000 files and 500 MB unpacked, 200 MB per file.
set -euo pipefail
dir="${1:-channels}"
fail=0
need() { if [ ! -e "$dir/$1" ]; then echo "MISSING $dir/$1"; fail=1; fi; }

need web/index.html
need web/index.wasm
need web/index.pck
need web/THIRD_PARTY_LICENSES.txt
if ls "$dir"/web/*.import >/dev/null 2>&1; then echo "STRAY .import files in web/"; fail=1; fi
files=$(find "$dir/web" -type f | wc -l)
bytes=$(du -sb "$dir/web" | cut -f1)
big=$(find "$dir/web" -type f -size +200M | wc -l)
[ "$files" -le 1000 ] || { echo "web/ has $files files (itch allows 1000)"; fail=1; }
[ "$bytes" -le 500000000 ] || { echo "web/ is $bytes bytes (itch allows 500 MB)"; fail=1; }
[ "$big" -eq 0 ] || { echo "web/ has files over 200 MB"; fail=1; }

need windows/Leviathan.exe
need windows/THIRD_PARTY_LICENSES.txt
need linux/Leviathan.x86_64
need linux/THIRD_PARTY_LICENSES.txt
if [ -e "$dir/linux/Leviathan.x86_64" ] && [ ! -x "$dir/linux/Leviathan.x86_64" ]; then
  echo "linux/Leviathan.x86_64 is not executable"; fail=1
fi
need mac/Leviathan.app/Contents/Info.plist
need mac/THIRD_PARTY_LICENSES.txt
if [ -d "$dir/mac/Leviathan.app/Contents/MacOS" ] && [ -z "$(find "$dir/mac/Leviathan.app/Contents/MacOS" -type f -perm -u+x)" ]; then
  echo "mac app has no executable"; fail=1
fi

for channel in web windows linux mac; do
  [ -d "$dir/$channel" ] && printf '%-8s %4d files  %s\n' "$channel" \
    "$(find "$dir/$channel" -type f | wc -l)" "$(du -sh "$dir/$channel" | cut -f1)"
done
[ "$fail" -eq 0 ] && echo "itch channels OK" || { echo "itch channels NOT ready"; exit 1; }
