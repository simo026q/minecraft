#!/bin/sh
set -eu

if [ "$(id -u)" -ne 10001 ]; then
    echo "ERROR: Backup must run as the backup user (UID 10001)." >&2
    exit 1
fi

if [ -z "${RESTIC_REPOSITORY:-}" ] || [ -z "${RESTIC_PASSWORD:-}" ]; then
    echo "ERROR: RESTIC_REPOSITORY and RESTIC_PASSWORD must be set." >&2
    exit 1
fi

export MCRCON_HOST="${RCON_HOST:-minecraft}"
export MCRCON_PORT="${RCON_PORT:-25575}"
export MCRCON_PASS="${RCON_PASSWORD:?RCON_PASSWORD must be set}"

if [ ! -r /data/world ]; then
    echo "ERROR: /data/world must be readable." >&2
    exit 1
fi

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

echo "Backing up Minecraft world to Restic repository: $RESTIC_REPOSITORY"
restic backup --host minecraft --tag minecraft /data/world

echo "Re-enabling world saving through RCON..."
mcrcon "save-on"
world_paused=false

echo "Applying Restic retention policy..."
restic forget \
    --host minecraft \
    --tag minecraft \
    --keep-hourly "${BACKUP_KEEP_HOURLY:-0}" \
    --keep-daily "${BACKUP_KEEP_DAILY:-7}" \
    --keep-weekly "${BACKUP_KEEP_WEEKLY:-4}" \
    --keep-monthly "${BACKUP_KEEP_MONTHLY:-6}" \
    --prune

trap - EXIT HUP INT TERM
echo "Backup complete."
