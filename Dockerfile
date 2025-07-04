FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ffmpeg \
    pulseaudio \
    pulseaudio-utils \
    alsa-utils \
    x11-apps \
    xvfb \
    v4l-utils \
    curl \
    wget \
    mpg123 \
    mplayer \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash recorder \
    && usermod -a -G audio recorder

WORKDIR /app

COPY record-final.sh /app/record-final.sh
COPY pulse-client.conf /etc/pulse/client.conf
COPY pulse-server.conf /app/pulse-server.conf
COPY sample-audio/ /app/sample-audio/
COPY simple-audio-test.sh /app/simple-audio-test.sh

# Fix line endings and permissions for all shell scripts
RUN sed -i 's/\r$//' /app/record-final.sh && chmod +x /app/record-final.sh
RUN sed -i 's/\r$//' /app/pulse-server.conf && chmod +x /app/pulse-server.conf
RUN sed -i 's/\r$//' /app/simple-audio-test.sh && chmod +x /app/simple-audio-test.sh
RUN sed -i 's/\r$//' /app/sample-audio/generate_audio.sh && chmod +x /app/sample-audio/generate_audio.sh
RUN sed -i 's/\r$//' /app/sample-audio/generate_video.sh && chmod +x /app/sample-audio/generate_video.sh

RUN chown -R recorder:recorder /app

USER recorder

RUN mkdir -p /home/recorder/.config/pulse

CMD ["/app/record-final.sh"]