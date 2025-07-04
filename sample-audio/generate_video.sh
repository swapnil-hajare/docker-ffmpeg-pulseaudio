#!/bin/bash

# Generate sample video file with audio and visual content
echo "Generating sample video with audio and visual content..."

# Create a 30-second video with:
# - Colorful moving pattern (testsrc2)
# - 1kHz sine wave audio
# - Text overlay showing time
ffmpeg -f lavfi -i testsrc2=size=1280x720:rate=30 \
       -f lavfi -i sine=frequency=1000:sample_rate=44100 \
       -filter_complex "[0:v]drawtext=text='Sample Video - Time\: %{pts\:hms}':x=50:y=50:fontsize=32:fontcolor=white:box=1:boxcolor=black@0.5[v]" \
       -map "[v]" -map 1:a \
       -c:v libx264 -preset medium -crf 23 \
       -c:a aac -b:a 128k \
       -t 30 \
       -y /app/sample-audio/sample-video.mp4

echo "Generated sample video: /app/sample-audio/sample-video.mp4"