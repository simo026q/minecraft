# syntax=docker/dockerfile:1

FROM alpine:3.22 AS mcrcon-build

RUN apk add --no-cache build-base ca-certificates curl

WORKDIR /src

RUN curl --fail --silent --show-error --location \
        https://github.com/Tiiffi/mcrcon/archive/refs/tags/v0.7.2.tar.gz \
        -o mcrcon.tar.gz \
    && tar -xzf mcrcon.tar.gz --strip-components=1 \
    && make

FROM alpine:3.22

RUN apk add --no-cache ca-certificates openssh-client restic rclone su-exec tzdata \
    && addgroup -S -g 10001 backup \
    && adduser -S -D -H -u 10001 -G backup backup \
    && mkdir -p /backup \
    && chown 10001:10001 /backup

COPY --from=mcrcon-build /src/mcrcon /usr/local/bin/mcrcon
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=755 backup.sh /usr/local/bin/backup.sh

RUN chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/backup.sh

ENV BACKUP_CRON="0 0 * * *" \
    BACKUP_KEEP_HOURLY= \
    BACKUP_KEEP_DAILY= \
    BACKUP_KEEP_WEEKLY= \
    BACKUP_KEEP_MONTHLY= \
    RESTIC_CACHE_DIR=/tmp/restic-cache \
    HOME=/restic-config \
    RCON_HOST=minecraft-server \
    RCON_PORT=25575 \
    TZ=UTC

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
