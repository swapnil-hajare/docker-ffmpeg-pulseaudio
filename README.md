# Docker FFmpeg PulseAudio Recorder

A Docker-based solution for recording video and audio using FFmpeg and PulseAudio.

## Features

- Video recording from webcam or screen capture
- Audio recording using PulseAudio
- Configurable recording parameters
- Containerized environment for consistent behavior
- Output files saved to host filesystem

## Prerequisites

- Docker and Docker Compose installed
- Webcam (optional, for video recording)
- Working audio system with PulseAudio

## Quick Start

1. Clone or create this project directory
2. Build and run the container:
   ```bash
   docker-compose up --build
   ```

## Configuration

Edit the `.env` file to customize recording settings:

- `VIDEO_SOURCE`: Video input source (`/dev/video0` for webcam)
- `AUDIO_SOURCE`: Audio input source (`pulse` for PulseAudio)
- `RESOLUTION`: Video resolution (e.g., `1920x1080`)
- `FPS`: Frames per second for video recording
- `DURATION`: Recording duration in seconds

## Usage

### Basic Recording
```bash
docker-compose up --build
```

### Custom Recording Duration
```bash
DURATION=120 docker-compose up --build
```

### Screen Recording (when no webcam available)
The script automatically falls back to screen recording if no webcam is detected.

## Output

Recorded files are saved to the `recordings/` directory with timestamps:
- Format: `recording_YYYYMMDD_HHMMSS.mp4`
- Location: `./recordings/`

## Troubleshooting

### No Video Device
If `/dev/video0` is not available, the script will use screen capture with Xvfb.

### Audio Issues
Ensure PulseAudio is running on the host:
```bash
pulseaudio --check
```

### Permission Issues
The container runs as non-root user. If you encounter permission issues:
```bash
sudo chown -R 1000:1000 recordings/
```

## Advanced Usage

### Manual Recording Script
```bash
docker run -it --rm \
  --privileged \
  -v $(pwd)/recordings:/app/recordings \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/shm:/dev/shm \
  --device /dev/video0 \
  --device /dev/snd \
  -e DISPLAY=$DISPLAY \
  ffmpeg-recorder
```

### Custom FFmpeg Parameters
Modify `record.sh` to add custom FFmpeg parameters for specific use cases.

## File Structure

```
docker-ffmpeg-pulseaudio/
├── Dockerfile              # Container configuration
├── docker-compose.yml      # Service orchestration
├── record.sh              # Recording script
├── .env                   # Environment variables
├── recordings/            # Output directory
└── README.md             # This file
```