#!/bin/sh
set -eu

if [ "$(id -u)" -ne 10001 ]; then
    echo "ERROR: Backup must run as the backup user (UID 10001)." >&2
    exit 1
fi

export MCRCON_HOST="${RCON_HOST:-minecraft}"
export MCRCON_PORT="${RCON_PORT:-25575}"
export MCRCON_PASS="${RCON_PASSWORD:?RCON_PASSWORD must be set}"

if [ ! -r /data/world ] || [ ! -w /backup ]; then
    echo "ERROR: /data/world must be readable and /backup must be writable." >&2
    exit 1
fi

timestamp="$(date '+%Y%m%d-%H%M%S')"
archive="/backup/minecraft-${timestamp}.tar.gz"
world_paused=false

resume_world() {
    if [ "$world_paused" = true ]; then
        mcrcon "save-on"
    fi
}
trap resume_world EXIT
trap 'exit 1' HUP INT TERM

echo "Disabling world saving through RCON..."
mcrcon "save-off"
world_paused=true
mcrcon "save-all flush"

echo "Creating backup: $archive"
if ! tar -czf "$archive" -C /data world; then
    rm -f "$archive"
    echo "ERROR: Failed to create backup archive." >&2
    exit 1
fi

echo "Re-enabling world saving through RCON..."
mcrcon "save-on"
world_paused=false
trap - EXIT HUP INT TERM
echo "Backup complete: $archive"
