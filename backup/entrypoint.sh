#!/bin/sh
set -eu

case "${RCON_ENABLED:-false}" in
    TRUE|true)
        ;;
    *)
        echo "ERROR: RCON_ENABLED must be true for scheduled backups." >&2
        exit 1
        ;;
esac

if [ -z "${RCON_PASSWORD:-}" ]; then
    echo "ERROR: RCON_PASSWORD must be set for scheduled backups." >&2
    exit 1
fi

if [ -z "${RESTIC_REPOSITORY:-}" ] || [ -z "${RESTIC_PASSWORD:-}" ]; then
    echo "ERROR: RESTIC_REPOSITORY and RESTIC_PASSWORD must be set." >&2
    exit 1
fi

if ! su-exec backup /bin/sh -c '[ -r /data/world ]'; then
    echo "ERROR: /data/world is not readable by the backup user." >&2
    exit 1
fi

if ! su-exec backup /bin/sh -c 'restic snapshots >/dev/null'; then
    echo "ERROR: Restic repository is unavailable or not initialized." >&2
    echo "Initialize it with: docker compose run --rm --no-deps --entrypoint restic backup init" >&2
    exit 1
fi

case "$BACKUP_CRON" in
    *[!0-9*/,\ -]*|'')
        echo "ERROR: BACKUP_CRON must contain five numeric cron fields." >&2
        exit 1
        ;;
esac

set -f
set -- $BACKUP_CRON
if [ "$#" -ne 5 ]; then
    echo "ERROR: BACKUP_CRON must contain exactly five cron fields." >&2
    exit 1
fi

printf '%s /sbin/su-exec backup /usr/local/bin/backup.sh >> /proc/1/fd/1 2>&1\n' \
    "$BACKUP_CRON" > /etc/crontabs/root

echo "Starting scheduled Minecraft backups with cron: $BACKUP_CRON"
exec crond -f -l 2 -L /dev/stdout
