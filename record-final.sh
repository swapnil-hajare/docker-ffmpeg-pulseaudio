#!/bin/bash

set -e

OUTPUT_DIR="/app/recordings"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="${OUTPUT_DIR}/recording_${TIMESTAMP}.mp4"

mkdir -p "$OUTPUT_DIR"

echo "Starting FFmpeg recording with virtual audio..."
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
    
    echo "Starting recording with virtual audio solution..."
    
    # Use FFmpeg's complex filter to merge video from X11 and audio from sample file
    # This creates a single FFmpeg command that:
    # 1. Captures screen from X11 
    # 2. Loops audio from sample video file
    # 3. Mixes them together in one output
    
    if [ -f "/app/sample-audio/sample-video.mp4" ]; then
        echo "Recording screen + sample audio using FFmpeg filter complex..."
        
        # Start mplayer to display video on screen (no audio output)
        mplayer -display "$DISPLAY" -loop 0 -nosound -really-quiet /app/sample-audio/sample-video.mp4 &
        MPLAYER_PID=$!
        sleep 3
        
        # Record with FFmpeg using filter_complex to merge screen capture + sample audio
        ffmpeg \
            -f x11grab -video_size "$RESOLUTION" -framerate "$FPS" -i "$DISPLAY" \
            -stream_loop -1 -i /app/sample-audio/sample-video.mp4 \
            -filter_complex "[0:v]scale=$RESOLUTION[video]; [1:a]volume=1.0[audio]" \
            -map "[video]" -map "[audio]" \
            -c:v libx264 -preset medium -crf 23 \
            -c:a aac -b:a 128k \
            -shortest \
            -t "$DURATION" \
            "$OUTPUT_FILE"
        
        # Stop mplayer
        kill $MPLAYER_PID 2>/dev/null || true
        
    else
        echo "Sample video not found, recording video only..."
        ffmpeg -f x11grab -video_size "$RESOLUTION" -framerate "$FPS" -i "$DISPLAY" \
               -c:v libx264 -preset medium -crf 23 \
               -t "$DURATION" \
               "$OUTPUT_FILE"
    fi
    
    kill $XVFB_PID
    
else
    echo "Using webcam: $VIDEO_SOURCE"
    
    # For webcam, just record video without audio complications
    ffmpeg -f v4l2 -video_size "$RESOLUTION" -framerate "$FPS" -i "$VIDEO_SOURCE" \
           -c:v libx264 -preset medium -crf 23 \
           -t "$DURATION" \
           "$OUTPUT_FILE"
fi

echo "Recording completed: $OUTPUT_FILE"

# Show file info to verify audio is included
echo "File information:"
ffprobe -v quiet -print_format json -show_streams "$OUTPUT_FILE" | grep -E '"codec_type"|"codec_name"' || echo "Could not analyze file"