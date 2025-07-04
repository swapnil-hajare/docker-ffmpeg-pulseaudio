#!/bin/bash

# Generate sample audio file using FFmpeg
ffmpeg -f lavfi -i "sine=frequency=1000:duration=10" -c:a libmp3lame -y /app/sample-audio/play.mp3

echo "Generated sample audio: /app/sample-audio/play.mp3"