#!/bin/sh
set -eu

# Require explicit acceptance of Minecraft EULA
case "${EULA:-FALSE}" in
    TRUE|true)
        ;;
    *)
        echo "ERROR: Minecraft EULA not accepted." >&2
        echo "Review https://aka.ms/MinecraftEULA" >&2
        echo "Then set EULA=TRUE." >&2
        exit 1
        ;;
esac

# Verify the data directory is writable
if [ ! -w /data ]; then
    echo "ERROR: /data is not writable." >&2
    echo "Check volume permissions for UID 10001." >&2
    exit 1
fi

# Create EULA file if missing or not accepted
if ! grep -qx 'eula=true' /data/eula.txt 2>/dev/null; then
    printf 'eula=true\n' > /data/eula.txt
fi

case "${RCON_ENABLED:-false}" in
    TRUE|true)
        if [ -z "${RCON_PASSWORD:-}" ]; then
            echo "ERROR: RCON_PASSWORD must be set when RCON_ENABLED=true." >&2
            exit 1
        fi
        ;;
    FALSE|false)
        ;;
    *)
        echo "ERROR: RCON_ENABLED must be true or false." >&2
        exit 1
        ;;
esac

set_server_property() {
    key="$1"
    value="$2"
    properties_tmp="$(mktemp /data/server.properties.XXXXXX)"

    if [ -f /data/server.properties ]; then
        awk -v prefix="${key}=" 'index($0, prefix) != 1' /data/server.properties > "$properties_tmp"
    fi

    printf '%s=%s\n' "$key" "$value" >> "$properties_tmp"
    mv "$properties_tmp" /data/server.properties
}

set_server_property enable-rcon "${RCON_ENABLED:-false}"
set_server_property rcon.port "${RCON_PORT:-25575}"
if [ -n "${RCON_PASSWORD:-}" ]; then
    set_server_property rcon.password "$RCON_PASSWORD"
fi

echo "Starting Minecraft Java server..."
echo "Minimum heap: ${MIN_MEMORY:-1G}"
echo "Maximum heap: ${MAX_MEMORY:-2G}"

# Replace shell process with Java.
# Docker shutdown signals reach the JVM directly.
exec java \
    "-Xms${MIN_MEMORY:-1G}" \
    "-Xmx${MAX_MEMORY:-2G}" \
    -jar /opt/minecraft/server.jar \
    nogui
    