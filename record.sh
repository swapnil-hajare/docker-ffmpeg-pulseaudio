#!/bin/bash

set -e

OUTPUT_DIR="/app/recordings"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="${OUTPUT_DIR}/recording_${TIMESTAMP}.mp4"

mkdir -p "$OUTPUT_DIR"

echo "Starting FFmpeg recording..."
echo "Output file: $OUTPUT_FILE"

VIDEO_SOURCE="${VIDEO_SOURCE:-/dev/video0}"
AUDIO_SOURCE="${AUDIO_SOURCE:-pulse}"
RESOLUTION="${RESOLUTION:-1920x1080}"
FPS="${FPS:-30}"
DURATION="${DURATION:-60}"

echo "Configuration:"
echo "  Video source: $VIDEO_SOURCE"
echo "  Audio source: $AUDIO_SOURCE"
echo "  Resolution: $RESOLUTION"
echo "  FPS: $FPS"
echo "  Duration: $DURATION seconds"

check_audio_source() {
    if [ "$AUDIO_SOURCE" = "pulse" ]; then
        if ! pactl info &>/dev/null; then
            echo "Warning: PulseAudio not available, trying ALSA..."
            return 1
        fi
    fi
    return 0
}

check_alsa_audio() {
    if arecord -l &>/dev/null && arecord -L | grep -q "default"; then
        if timeout 2 arecord -D default -f cd -t raw -d 1 /dev/null &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

if [[ ! -e "$VIDEO_SOURCE" ]]; then
    echo "Warning: Video source $VIDEO_SOURCE not found. Using screen capture instead."
    
    export DISPLAY=:99
    Xvfb :99 -screen 0 1920x1080x24 -ac &
    XVFB_PID=$!
    
    sleep 3
    
    # Start PulseAudio server
    echo "Starting PulseAudio server..."
    /app/pulse-server.conf
    
    # Generate sample video file with audio
    echo "Generating sample video file with audio..."
    /app/sample-audio/generate_video.sh
    
    AUDIO_CMD=""
    if check_audio_source; then
        AUDIO_CMD="-f $AUDIO_SOURCE -i default -c:a aac -b:a 128k"
        echo "Using audio source: $AUDIO_SOURCE"
    else
        if check_alsa_audio; then
            AUDIO_CMD="-f alsa -i default -c:a aac -b:a 128k"
            echo "Using audio source: ALSA"
        else
            echo "Warning: No working audio source found, recording video only"
            AUDIO_CMD=""
        fi
    fi
    
    # Start playing sample video with audio on the X11 display
    VIDEO_PID=""
    if [ -f "/app/sample-audio/sample-video.mp4" ]; then
        echo "Playing sample video with audio on display $DISPLAY..."
        
        # Try different audio outputs based on what's available
        if [ -n "$AUDIO_CMD" ]; then
            if [ "$AUDIO_SOURCE" = "pulse" ]; then
                mplayer -display "$DISPLAY" -loop 0 -ao pulse -really-quiet /app/sample-audio/sample-video.mp4 &
            else
                mplayer -display "$DISPLAY" -loop 0 -ao alsa -really-quiet /app/sample-audio/sample-video.mp4 &
            fi
        else
            # No audio recording, so just play video
            mplayer -display "$DISPLAY" -loop 0 -nosound -really-quiet /app/sample-audio/sample-video.mp4 &
        fi
        
        VIDEO_PID=$!
        sleep 5
    fi
    
    if [ -n "$AUDIO_CMD" ]; then
        eval "ffmpeg -f x11grab -video_size \"$RESOLUTION\" -framerate \"$FPS\" -i \"$DISPLAY\" \
               $AUDIO_CMD \
               -c:v libx264 -preset medium -crf 23 \
               -t \"$DURATION\" \
               \"$OUTPUT_FILE\""
    else
        ffmpeg -f x11grab -video_size "$RESOLUTION" -framerate "$FPS" -i "$DISPLAY" \
               -c:v libx264 -preset medium -crf 23 \
               -t "$DURATION" \
               "$OUTPUT_FILE"
    fi
    
    # Stop video playback
    if [ -n "$VIDEO_PID" ]; then
        kill $VIDEO_PID 2>/dev/null
    fi
    
    kill $XVFB_PID
else
    echo "Using webcam: $VIDEO_SOURCE"
    
    AUDIO_CMD=""
    if check_audio_source; then
        AUDIO_CMD="-f $AUDIO_SOURCE -i default -c:a aac -b:a 128k"
        echo "Using audio source: $AUDIO_SOURCE"
    else
        if check_alsa_audio; then
            AUDIO_CMD="-f alsa -i default -c:a aac -b:a 128k"
            echo "Using audio source: ALSA"
        else
            echo "Warning: No working audio source found, recording video only"
            AUDIO_CMD=""
        fi
    fi
    
    if [ -n "$AUDIO_CMD" ]; then
        eval "ffmpeg -f v4l2 -video_size \"$RESOLUTION\" -framerate \"$FPS\" -i \"$VIDEO_SOURCE\" \
               $AUDIO_CMD \
               -c:v libx264 -preset medium -crf 23 \
               -t \"$DURATION\" \
               \"$OUTPUT_FILE\""
    else
        ffmpeg -f v4l2 -video_size "$RESOLUTION" -framerate "$FPS" -i "$VIDEO_SOURCE" \
               -c:v libx264 -preset medium -crf 23 \
               -t "$DURATION" \
               "$OUTPUT_FILE"
    fi
fi

echo "Recording completed: $OUTPUT_FILE"