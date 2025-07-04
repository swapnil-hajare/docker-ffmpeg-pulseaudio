#!/bin/bash

set -e

OUTPUT_DIR="/app/recordings"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="${OUTPUT_DIR}/recording_${TIMESTAMP}.mp4"

mkdir -p "$OUTPUT_DIR"

echo "Starting simple FFmpeg recording with audio test..."
echo "Output file: $OUTPUT_FILE"

VIDEO_SOURCE="${VIDEO_SOURCE:-/dev/video0}"
RESOLUTION="${RESOLUTION:-1920x1080}"
FPS="${FPS:-30}"
DURATION="${DURATION:-60}"

echo "Configuration:"
echo "  Video source: $VIDEO_SOURCE"
echo "  Resolution: $RESOLUTION"
echo "  FPS: $FPS"
echo "  Duration: $DURATION seconds"

if [[ ! -e "$VIDEO_SOURCE" ]]; then
    echo "Warning: Video source $VIDEO_SOURCE not found. Using screen capture instead."
    
    export DISPLAY=:99
    Xvfb :99 -screen 0 1920x1080x24 -ac &
    XVFB_PID=$!
    
    sleep 3
    
    # Generate sample video file with audio
    echo "Generating sample video file with audio..."
    /app/sample-audio/generate_video.sh
    
    # Start playing sample video with audio on the X11 display
    VIDEO_PID=""
    if [ -f "/app/sample-audio/sample-video.mp4" ]; then
        echo "Playing sample video with audio on display $DISPLAY..."
        mplayer -display "$DISPLAY" -loop 0 -ao null -really-quiet /app/sample-audio/sample-video.mp4 &
        VIDEO_PID=$!
        sleep 3
        
        # Also play audio separately for recording
        ffplay -nodisp -autoexit -loop 0 /app/sample-audio/sample-video.mp4 &
        AUDIO_PID=$!
        sleep 2
    fi
    
    # Record screen with audio using simple approach
    echo "Starting recording with screen capture and audio..."
    
    # Try multiple audio approaches
    if ffmpeg -f x11grab -video_size "$RESOLUTION" -framerate "$FPS" -i "$DISPLAY" \
              -f pulse -i default \
              -c:v libx264 -preset medium -crf 23 \
              -c:a aac -b:a 128k \
              -t "$DURATION" \
              "$OUTPUT_FILE" 2>/dev/null; then
        echo "Recorded with PulseAudio"
    elif ffmpeg -f x11grab -video_size "$RESOLUTION" -framerate "$FPS" -i "$DISPLAY" \
                -f alsa -i default \
                -c:v libx264 -preset medium -crf 23 \
                -c:a aac -b:a 128k \
                -t "$DURATION" \
                "$OUTPUT_FILE" 2>/dev/null; then
        echo "Recorded with ALSA"
    else
        echo "Recording video only (no audio available)"
        ffmpeg -f x11grab -video_size "$RESOLUTION" -framerate "$FPS" -i "$DISPLAY" \
               -c:v libx264 -preset medium -crf 23 \
               -t "$DURATION" \
               "$OUTPUT_FILE"
    fi
    
    # Stop video and audio playback
    if [ -n "$VIDEO_PID" ]; then
        kill $VIDEO_PID 2>/dev/null
    fi
    if [ -n "$AUDIO_PID" ]; then
        kill $AUDIO_PID 2>/dev/null
    fi
    
    kill $XVFB_PID
else
    echo "Using webcam: $VIDEO_SOURCE"
    
    # Try webcam recording with audio
    if ffmpeg -f v4l2 -video_size "$RESOLUTION" -framerate "$FPS" -i "$VIDEO_SOURCE" \
              -f pulse -i default \
              -c:v libx264 -preset medium -crf 23 \
              -c:a aac -b:a 128k \
              -t "$DURATION" \
              "$OUTPUT_FILE" 2>/dev/null; then
        echo "Recorded with PulseAudio"
    elif ffmpeg -f v4l2 -video_size "$RESOLUTION" -framerate "$FPS" -i "$VIDEO_SOURCE" \
                -f alsa -i default \
                -c:v libx264 -preset medium -crf 23 \
                -c:a aac -b:a 128k \
                -t "$DURATION" \
                "$OUTPUT_FILE" 2>/dev/null; then
        echo "Recorded with ALSA"
    else
        echo "Recording video only (no audio available)"
        ffmpeg -f v4l2 -video_size "$RESOLUTION" -framerate "$FPS" -i "$VIDEO_SOURCE" \
               -c:v libx264 -preset medium -crf 23 \
               -t "$DURATION" \
               "$OUTPUT_FILE"
    fi
fi

echo "Recording completed: $OUTPUT_FILE"