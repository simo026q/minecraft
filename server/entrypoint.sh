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
    