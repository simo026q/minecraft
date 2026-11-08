# syntax=docker/dockerfile:1

# --------------------------------------------------
# Stage 1: Download and verify Minecraft server
# --------------------------------------------------
FROM alpine:3.22 AS downloader

ARG MINECRAFT_VERSION=26.3

RUN apk add --no-cache \
    ca-certificates \
    curl \
    jq

WORKDIR /download

RUN set -eu; \
    curl --fail --silent --show-error --location \
         --retry 3 \
         "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json" \
         -o manifest.json; \
    \
    metadata_url="$(jq -er \
        --arg version "$MINECRAFT_VERSION" \
        '.versions[] | select(.id == $version) | .url' \
        manifest.json)"; \
    \
    curl --fail --silent --show-error --location \
         --retry 3 \
         "$metadata_url" \
         -o version.json; \
    \
    server_url="$(jq -er \
        '.downloads.server.url' version.json)"; \
    server_sha1="$(jq -er \
        '.downloads.server.sha1' version.json)"; \
    \
    curl --fail --silent --show-error --location \
         --retry 3 \
         "$server_url" \
         -o server.jar; \
    \
    echo "$server_sha1  server.jar" | sha1sum -c -

# --------------------------------------------------
# Stage 2: Minecraft runtime
# --------------------------------------------------
FROM eclipse-temurin:25-jre-noble

ARG MINECRAFT_VERSION=26.3

LABEL org.opencontainers.image.title="Minecraft Java Server" \
      org.opencontainers.image.description="Custom vanilla Minecraft server" \
      org.opencontainers.image.version="${MINECRAFT_VERSION}" \
      org.opencontainers.image.vendor="Custom"

# Dedicated non-root user
RUN groupadd --gid 10001 minecraft \
    && useradd \
        --uid 10001 \
        --gid 10001 \
        --home-dir /data \
        --no-create-home \
        --shell /usr/sbin/nologin \
        minecraft \
    && mkdir -p /data /opt/minecraft \
    && chown 10001:10001 /data

# Install verified server JAR
COPY --from=downloader \
    --chown=10001:10001 \
    /download/server.jar \
    /opt/minecraft/server.jar

# Install startup script
COPY --chmod=755 \
    entrypoint.sh \
    /opt/minecraft/entrypoint.sh

ENV EULA=FALSE \
    MIN_MEMORY=1G \
    MAX_MEMORY=2G \
    RCON_ENABLED=false \
    RCON_PORT=25575 \
    RCON_PASSWORD=

WORKDIR /data

USER 10001:10001

EXPOSE 25565/tcp

STOPSIGNAL SIGTERM

ENTRYPOINT ["/opt/minecraft/entrypoint.sh"]
