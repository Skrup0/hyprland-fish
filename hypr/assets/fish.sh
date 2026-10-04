#!/usr/bin/env bash

# !!!!!
# MAKE SURE jq IS AVAILABLE AND noise.c IS BUILT (cc -O2 -o noise noise.c)
# !!!!!

FRAME_US=16667 # corresponds to 60 frames
SPEED=6
EDGE=150 # offset from edge of screen
EDGE_PUSH=10
NOISE_PERIOD=90

# fish[addr] = "seed rx ry tag", rx and ry are leftovers as 1/1000 pixels
declare -A fish seen mon

while read -r id x y w h; do
    mon[$id]="$x $y $w $h"
done < <(hyprctl monitors -j | jq -r '.[] |
    (.width / .scale | floor) as $w | (.height / .scale | floor) as $h |
    if .transform % 2 == 1 then [.id, .x, .y, $h, $w] else [.id, .x, .y, $w, $h] end | @tsv')

# using noise from https://github.com/stegu/perlin-noise/blob/master/src/noise1234.c
here=$(dirname "$(realpath "$0")")
[[ -x $here/noise ]] || { echo "noise binary not found, you build it first: cc -O2 -o noise noise.c" >&2; exit 1; }
coproc NOISE { exec "$here/noise" "$NOISE_PERIOD"; }

noise() { echo "$1 $2" >&"${NOISE[1]}"; read -r REPLY <&"${NOISE[0]}"; }

# putting all commands in one batch instead of sending them one by one
tag_cmd()  { cmds+=("dispatch hl.dsp.window.tag({ tag = '$1', window = 'address:$2' })"); }
move_cmd() { cmds+=("dispatch hl.dsp.window.move({ x = $1, y = $2, window = 'address:$3' })"); }
flush()  	 { (( ${#cmds[@]} )) && hyprctl --batch "$(IFS=';'; echo "${cmds[*]}")" >/dev/null; cmds=(); }

cleanup() {
    for addr in "${!fish[@]}"; do
        read -r _ _ _ tg <<< "${fish[$addr]}"
        tag_cmd "-$tg" "$addr"
    done
    flush
    exit
}

trap cleanup INT TERM # run on script exit

frame=0
while :; do
    start=${EPOCHREALTIME/[.,]/}
    seen=()

    while read -r addr x y w h m; do
        seen[$addr]=1
        read -r mx my sw sh <<< "${mon[$m]}"
        [[ $sw ]] || continue

        [[ ${fish[$addr]} ]] || fish[$addr]="$(( RANDOM << 15 | RANDOM )) 0 0 none"
        read -r seed rx ry tg <<< "${fish[$addr]}"

        # 1/1000 px returned
        noise "$seed" "$frame"; vx=$(( REPLY * SPEED ))
        noise "$(( seed + 1 ))" "$frame"; vy=$(( REPLY * SPEED ))

        l=$(( x - mx )) r=$(( mx + sw - x - w )) t=$(( y - my )) b=$(( my + sh - y - h ))
        (( l < EDGE )) && (( vx += EDGE_PUSH * 1000 * (EDGE - l) / EDGE ))
        (( r < EDGE )) && (( vx -= EDGE_PUSH * 1000 * (EDGE - r) / EDGE ))
        (( t < EDGE )) && (( vy += EDGE_PUSH * 1000 * (EDGE - t) / EDGE ))
        (( b < EDGE )) && (( vy -= EDGE_PUSH * 1000 * (EDGE - b) / EDGE ))

        vx=$(( vx + rx )) vy=$(( vy + ry ))
        dx=$(( vx / 1000 )) dy=$(( vy / 1000 )) # whole pixel
        rx=$(( vx % 1000 )) ry=$(( vy % 1000 )) # rest is saved
        (( x += dx, y += dy ))

        (( x > mx + sw - w )) && x=$(( mx + sw - w )); (( x < mx )) && x=$mx
        (( y > my + sh - h )) && y=$(( my + sh - h )); (( y < my )) && y=$my

        (( vx < 0 )) && dir=left || dir=right
        if [[ $dir != "$tg" ]]; then
            [[ $tg != none ]] && tag_cmd "-$tg" "$addr"
            tag_cmd "+$dir" "$addr"
            tg=$dir
        fi

        fish[$addr]="$seed $rx $ry $tg"
        move_cmd "$x" "$y" "$addr"
    done < <(hyprctl clients -j | jq -r '.[] | select(.floating and .mapped and (.hidden | not)) |
        [.address, .at[0], .at[1], .size[0], .size[1], .monitor] | @tsv')

    # gets rid of windows that closed or are tiled
    for addr in "${!fish[@]}"; do
        [[ ${seen[$addr]} ]] && continue
        read -r _ _ _ tg <<< "${fish[$addr]}"
        tag_cmd "-$tg" "$addr"
        unset "fish[$addr]"
    done

    flush
    (( frame++ ))

    left=$(( FRAME_US - (10#${EPOCHREALTIME/[.,]/} - 10#$start) ))
    (( left > 0 )) && sleep "0.$(printf '%06d' "$left")"
done
