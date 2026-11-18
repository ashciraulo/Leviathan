#!/usr/bin/env bash
# Cuts a short store trailer (1920x1080, 30 fps, H.264 + AAC) from the
# gameplay loops tools/store_clips.sh records, opened and closed on the title
# art, over the title theme (audio/music/title.ogg, a finished cue).
#     bash tools/store_trailer.sh [out.mp4]      (default: store/trailer.mp4)
# Run tools/store_clips.sh first (it leaves each clip's frames in clips/<clip>/).
# Every frame is the game's 384x216 picture scaled 5x with nearest-neighbour,
# so the pixels stay square. Needs ffmpeg and python3 with Pillow.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:-store/trailer.mp4}
ORDER=(hum fight glide dunes mantle)
FADE=0.5        # cross-fade between shots, seconds
OPEN=3.0        # the title backdrop, no logo, before the first clip
CLOSE=5.0       # the logo over the backdrop at the end
MUSIC=audio/music/title.ogg

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$(dirname "$OUT")"

for clip in "${ORDER[@]}"; do
	[ -f "clips/$clip/0001.png" ] || { echo "No frames for $clip: run tools/store_clips.sh first"; exit 1; }
done

# The opening and closing stills, from the title art at 5x.
python3 - "$work" <<'EOF'
import sys
from PIL import Image
out = sys.argv[1]
bg = Image.open("assets/ui/title_bg.png").convert("RGBA")
logo = Image.open("assets/ui/title_logo.png").convert("RGBA")
big = bg.resize((bg.width * 5, bg.height * 5), Image.NEAREST)
big.convert("RGB").save(out + "/open.png")
end = big.copy()
lg = logo.resize((logo.width * 6, logo.height * 6), Image.NEAREST)
end.alpha_composite(lg, ((end.width - lg.width) // 2, 90))
end.convert("RGB").save(out + "/close.png")
EOF

# One H.264 piece per shot, all the same size and rate, so xfade can join them.
enc=(-c:v libx264 -pix_fmt yuv420p -crf 16 -r 30)
ffmpeg -loglevel error -y -loop 1 -t "$OPEN" -i "$work/open.png" "${enc[@]}" "$work/s0.mp4"
n=1
for clip in "${ORDER[@]}"; do
	ffmpeg -loglevel error -y -framerate 30 -i "clips/$clip/%04d.png" \
		-vf "scale=iw*5:ih*5:flags=neighbor" "${enc[@]}" "$work/s$n.mp4"
	n=$((n + 1))
done
ffmpeg -loglevel error -y -loop 1 -t "$CLOSE" -i "$work/close.png" "${enc[@]}" "$work/s$n.mp4"

# Chain the cross-fades: each one starts FADE before the running total ends.
inputs=()
filter=""
total=0
last="0:v"
for i in $(seq 0 "$n"); do
	inputs+=(-i "$work/s$i.mp4")
	len=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$work/s$i.mp4")
	if [ "$i" -eq 0 ]; then
		total=$len
		continue
	fi
	offset=$(python3 -c "print(round($total - $FADE, 3))")
	filter+="[$last][$i:v]xfade=transition=fade:duration=$FADE:offset=$offset[v$i];"
	last="v$i"
	total=$(python3 -c "print(round($total + $len - $FADE, 3))")
done
# Fade in from black and out to black, and the music under it all.
fade_out=$(python3 -c "print(round($total - 1.5, 3))")
filter+="[$last]fade=t=in:st=0:d=1,fade=t=out:st=$fade_out:d=1.5[v];"
filter+="[$((n + 1)):a]atrim=0:$total,afade=t=in:st=0:d=1,afade=t=out:st=$(python3 -c "print(round($total - 2.5, 3))"):d=2.5[a]"
ffmpeg -loglevel error -y "${inputs[@]}" -i "$MUSIC" -filter_complex "$filter" \
	-map "[v]" -map "[a]" -c:v libx264 -pix_fmt yuv420p -crf 18 -r 30 -c:a aac -b:a 192k \
	-movflags +faststart "$OUT"
echo "$OUT: $(python3 -c "print(round($total, 1))") s, $(du -h "$OUT" | cut -f1)"
