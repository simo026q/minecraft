# Minecraft Server

## Setup

1. Create a `.env` file based on `.env.example`
2. Configure S3-compatible storage in `.env`:
   - Set `RESTIC_REPOSITORY` to `s3:https://<endpoint>/<bucket>`, replacing the
     example endpoint and bucket in `.env.example`. Include a port in the endpoint
     if your provider requires one.
   - Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to credentials for the
     bucket. The credentials must allow listing, reading, writing, and deleting
     objects, since Restic's retention cleanup prunes old data.
   - Set `AWS_DEFAULT_REGION` to the region required by your provider; it defaults
     to `us-east-1` if omitted.
   - Set `RESTIC_PASSWORD` to a strong, private encryption password. This is
     separate from your S3 credentials; losing it makes the backups unrecoverable.
   - For temporary credentials, also set `AWS_SESSION_TOKEN`.
   Create the bucket with your provider before initializing the repository.
3. From the directory containing `compose.yaml`, create and set ownership of the bind mounts:
   ```sh
   sudo mkdir -p ./data ./restic-config
   sudo chown -R 10001:10001 ./data ./restic-config
   ```

4. Initialize the Restic repository:
   ```sh
   docker compose run --build --rm --no-deps --user 10001:10001 --entrypoint restic backup init
   ```
   Initialization reads the repository and S3 credentials from `.env`. Use the same
   repository, credentials, and `RESTIC_PASSWORD` for subsequent backups and restores.
5. Start the server and backup service with `docker compose up -d --build`.

The backup service receives all variables from `.env`, so additional backend-specific
Restic or provider variables can be added there without changing Compose. To switch
to another Restic backend, set `RESTIC_REPOSITORY` and its required credentials.
For file-based credentials or configuration (such as an SSH key or rclone config),
place files in `./restic-config` and set the relevant variable to its container path
(for example, `RCLONE_CONFIG=/restic-config/rclone.conf`). SFTP keys can be placed
in `./restic-config/.ssh` and are available through the backup user's home directory.
Keep private keys readable only by UID 10001 and mode `600`. To use
`RESTIC_PASSWORD_FILE`, remove or comment out `RESTIC_PASSWORD` in `.env`.

The backup service saves the world to Restic once per `BACKUP_CRON` schedule and
keeps 7 daily, 4 weekly, and 6 monthly snapshots by default. Adjust these values
with `BACKUP_KEEP_DAILY`, `BACKUP_KEEP_WEEKLY`, and `BACKUP_KEEP_MONTHLY`.
Existing `.tar.gz` backups in `./backups` are left untouched and are not imported
into the Restic repository.
