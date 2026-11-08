# Minecraft Server

## Setup

1. Create a `.env` file based on `.env.example`
2. Set `RCON_PASSWORD` to a strong, private value in `.env`
3. `sudo mkdir -p ./data ./backups`
4. `sudo chown -R 10001:10001 ./data ./backups`
5. Start the server and backup service with `docker compose up -d --build`
