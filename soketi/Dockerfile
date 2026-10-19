# =============================================================================
# Soketi WebSocket Server Dockerfile
# Self-hosted, Pusher-compatible WebSocket server.
# On Railway, this is Service 2 (separate from the Express API).
#
# Soketi is configured via environment variables with the SOKETI_ prefix.
# The app credentials (ID/key/secret) must match what's in the Express .env.
# =============================================================================

FROM node:20-alpine

WORKDIR /app

# Soketi is a Node.js app — install globally or locally
RUN npm install -g @soketi/soketi

# Railway injects PORT env var; Soketi defaults to 6001
ENV PORT=${PORT:-6001}

EXPOSE 6001

# Soketi reads all config from environment variables:
#   SOKETI_DEFAULT_APP_ID      — must match Express SOKETI_APP_ID
#   SOKETI_DEFAULT_APP_KEY     — must match Express SOKETI_APP_KEY
#   SOKETI_DEFAULT_APP_SECRET  — must match Express SOKETI_APP_SECRET
#   SOKETI_DRIVER_HTTP_SERVER_PORT — port Soketi listens on
CMD ["soketi", "start"]
