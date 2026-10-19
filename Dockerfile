# =============================================================================
# Express API Dockerfile
# Builds the Node.js Express backend. On Railway, this is Service 1.
# The Soketi WebSocket server runs as a separate Railway service (soketi/Dockerfile).
# =============================================================================

FROM node:20-alpine

WORKDIR /app

# Copy and install dependencies first (better Docker cache)
COPY backend/package*.json ./
RUN npm ci --only=production

# Copy backend source
COPY backend/ ./

EXPOSE 3000

# Railway injects PORT env var; fallback to 3000
ENV PORT=3000

CMD ["node", "server.js"]
