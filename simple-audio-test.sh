#!/bin/bash

# Simple audio test that plays sample audio and records it directly
echo "Testing simple audio recording..."

# Generate a simple audio file
ffmpeg -f lavfi -i "sine=frequency=440:duration=5" -y /tmp/test-audio.wav

echo "Playing and recording audio simultaneously..."

# Start playing audio in background
ffplay -nodisp -autoexit /tmp/test-audio.wav &
PLAY_PID=$!

sleep 1

# Record audio using ALSA directly
ffmpeg -f alsa -i default -t 5 -y /app/recordings/audio-test.wav

# Stop playback
kill $PLAY_PID 2>/dev/null

echo "Audio test completed. Check /app/recordings/audio-test.wav"