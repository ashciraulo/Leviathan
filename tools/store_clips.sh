#!/usr/bin/env bash
# Records the store-page gameplay loops (tests/store_clips.gd) and turns each
# into a GIF and an MP4 at 2x (768x432) in clips/.
#     GODOT=/path/to/godot bash tools/store_clips.sh [clip ...]
# Needs xvfb-run and ffmpeg. Runs one Godot at a time.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
CLIPS=("$@")
[ ${#CLIPS[@]} -eq 0 ] && CLIPS=(fight hum glide mantle dunes)
for clip in "${CLIPS[@]}"; do
	rm -rf "clips/$clip"
	CLIP=$clip xvfb-run -a "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 30 \
		--path . res://tests/store_clips.tscn 2>&1 | grep -E "Clip|ERROR|SCRIPT" || true
	ffmpeg -loglevel error -y -framerate 30 -i "clips/$clip/%04d.png" \
		-vf "fps=25,scale=iw*2:ih*2:flags=neighbor,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
		"clips/$clip.gif"
	ffmpeg -loglevel error -y -framerate 30 -i "clips/$clip/%04d.png" \
		-vf "scale=iw*4:ih*4:flags=neighbor" -c:v libx264 -pix_fmt yuv420p -crf 18 "clips/$clip.mp4"
	echo "clips/$clip.gif $(du -h "clips/$clip.gif" | cut -f1)"
done
