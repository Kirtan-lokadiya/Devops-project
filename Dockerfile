# Debian slim keeps the image small while providing stable apt packages.
FROM debian:stable-slim

# On Debian, cowsay is installed under /usr/games, so include it in PATH.
ENV PATH="/usr/games:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        cowsay \
        fortune-mod \
        fortunes-min \
        netcat-openbsd \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY wisecow.sh /app/wisecow.sh
RUN chmod +x /app/wisecow.sh

EXPOSE 4499
ENTRYPOINT ["/app/wisecow.sh"]
