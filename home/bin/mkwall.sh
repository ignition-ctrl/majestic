#!/usr/bin/env bash

dimensions=$(xdpyinfo  | awk '/dimensions:/ {print $2}')
dominant=$(convert $HOME/gitlab/lnxpcs/distro/arch/arch-linux-n1.png -scale 50x50! -depth 8 +dither -colors 8 -format "%c" histogram:info: | awk 'NR==1{print $3}')

function mkWall() {
	convert "$1" -gravity center -resize "${dimensions}" -background "$dominant" -extent "${dimensions}" "$2"
}

if [ $1 ]; then
    for var in "$@"
    do
        echo "$var"
    done
fi
