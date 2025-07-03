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
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash recorder \
    && usermod -a -G audio recorder

WORKDIR /app

COPY record.sh /app/record.sh
COPY pulse-client.conf /etc/pulse/client.conf
RUN chmod +x /app/record.sh

RUN chown -R recorder:recorder /app

USER recorder

RUN mkdir -p /home/recorder/.config/pulse

CMD ["/app/record.sh"]