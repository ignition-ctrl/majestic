#!/usr/bin/env bash

if pgrep -x "ffmpeg" > /dev/null && test -f "/tmp/videodown.pid"; then
	echo "📹️ ("Gravando")️"
else
	echo "📹️"
fi

echo "---"
echo "🎉️ Iniciar/Parar | terminal=false bash='${HOME}/.local/bin/screencast'"
