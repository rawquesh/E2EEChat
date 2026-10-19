# Deployment Guide — E2EE Chat App Backend

## Architecture Overview

```
Flutter App
    │
    ├── HTTPS ────► Express API (Railway Service 1)
    │                   │
    │                   └── HTTP POST ──► Soketi WS Server (Railway Service 2)
    │                                       │
    │                                       └── WSS ────► Flutter (pusher-js)
    │
    └── WebRTC
          ├── STUN ───► Google STUN (stun.l.google.com:19302) ✓ works today
          └── TURN ───► Metered.ca (optional, see below)

    MongoDB ────► Railway persistent volume
```

**Two Railway services + MongoDB** (built-in Railway addon).

---

## Prerequisites

1. **Railway account** — [railway.app](https://railway.app)
2. **MongoDB** — Add a Railway MongoDB plugin to your project
3. **Soketi app credentials** — Generate any random strings for app ID, key, secret

### Generate Soketi credentials

Run these locally to generate random credentials:

```bash
# Generate a random app ID
node -e "console.log(require('crypto').randomUUID())"

# Generate a random app key (32 chars)
node -e "console.log(require('crypto').randomBytes(16).toString('hex'))"

# Generate a random app secret (64 chars)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Example output (use your own):
```
SOKETI_APP_ID=abc1234a-bcde-5678-90ab-cdef12345678
SOKETI_APP_KEY=1a2b3c4d5e6f7890abcdef1234567890
SOKETI_APP_SECRET=a1b2c3d4e5f607182930405060708090a1b2c3d4e5f607182930405060708090
```

---

## Step 1 — Create a New Railway Project

1. Go to [railway.app](https://railway.app) and create a new project
2. Click **Add a Plugin** → **MongoDB**
   - Railway will create a MongoDB instance and give you a `MONGODB_URI`
   - Copy it — you'll need it in Step 3

---

## Step 2 — Deploy Express API (Service 1)

1. In your Railway project, click **Add a Service** → **Empty Service**
2. Under **Settings**:
   - **Name**: `e2ee-api`
   - **Root Directory**: leave empty (this is the root Dockerfile)
3. Under **Variables**, add these (replace placeholders):

   | Variable | Value |
   |----------|-------|
   | `NODE_ENV` | `production` |
   | `PORT` | `3000` |
   | `MONGODB_URI` | `mongodb+srv://...` (from Step 1) |
   | `JWT_SECRET` | Generate a strong random string: `openssl rand -hex 32` |
   | `CORS_ORIGINS` | `*` (or your Flutter app's domain) |
   | `SOKETI_HOST` | `e2ee-soketi` (Soketi service name, same Railway project) |
   | `SOKETI_PORT` | `6001` |
   | `SOKETI_APP_ID` | From Step above |
   | `SOKETI_APP_KEY` | From Step above |
   | `SOKETI_APP_SECRET` | From Step above |
   | `STUN_HOST` | `stun.l.google.com` |
   | `STUN_PORT` | `19302` |
   | `TURN_HOST` | `REPLACE_WITH_TURN_HOST` |
   | `TURN_PORT` | `3478` |
   | `TURNS_PORT` | `5349` |
   | `TURN_USERNAME` | `REPLACE_WITH_TURN_USER` |
   | `TURN_CREDENTIAL` | `REPLACE_WITH_TURN_PASS` |

4. Under **Build**, leave default (Railway auto-detects Dockerfile)
5. Click **Deploy**

After deploy, Railway gives you a public URL:
```
https://e2ee-api.up.railway.app
```
This is your **API base URL** for the Flutter app.

---

## Step 3 — Deploy Soketi WebSocket Server (Service 2)

1. In your Railway project, click **Add a Service** → **Empty Service**
2. Under **Settings**:
   - **Name**: `e2ee-soketi`
   - **Root Directory**: `soketi` (points to `soketi/Dockerfile`)
3. Under **Variables**:

   | Variable | Value |
   |----------|-------|
   | `PORT` | `6001` |
   | `SOKETI_DRIVER_HTTP_SERVER_PORT` | `6001` |
   | `SOKETI_DEFAULT_APP_ID` | Same as `SOKETI_APP_ID` above |
   | `SOKETI_DEFAULT_APP_KEY` | Same as `SOKETI_APP_KEY` above |
   | `SOKETI_DEFAULT_APP_SECRET` | Same as `SOKETI_APP_SECRET` above |

4. Under **Networking** → **Public Networking**: **Enable** (Soketi needs to accept WebSocket connections from the Flutter app directly)
5. Click **Deploy**

After deploy, Railway gives you a public URL:
```
https://e2ee-soketi.up.railway.app
```
This is your **Soketi host** for the Flutter app.

---

## Step 4 — Update Flutter App

Open `app/lib/backend/common/api_endpoints.dart` and update:

```dart
// API Server — your Railway Express service
static const String apiBaseUrl = 'https://e2ee-api.up.railway.app/api';

// Soketi WebSocket — your Railway Soketi service
static const String pusherKey = 'YOUR_SOKETI_APP_KEY';          // e.g. '1a2b3c4d5e6f7890...'
static const String pusherHost = 'e2ee-soketi.up.railway.app'; // Soketi public URL (no https://)
static const int pusherWsPort = 443;
static const int pusherWssPort = 443;
static const bool pusherEncrypted = true;

// TURN (optional — add Metered.ca credentials when ready)
static const String turnHost = 'REPLACE_WITH_TURN_HOST';
static const String turnUsername = 'REPLACE_WITH_TURN_USER';
static const String turnCredential = 'REPLACE_WITH_TURN_PASS';
```

> **Important:** `pusherHost` must match exactly. Do NOT include `https://` — the pusher-js library adds that automatically.

---

## Step 5 — (Optional) Add TURN Server

If WebRTC calls fail in production (users on different networks/NATs):

1. Go to [metered.ca/tools/openrelay](https://www.metered.ca/tools/openrelay/)
2. Register (free) and get your TURN credentials
3. Update the `TURN_HOST`, `TURN_USERNAME`, `TURN_CREDENTIAL` variables in **both** Railway services

---

## Local Development

```bash
# 1. Generate Soketi credentials (or use the ones in .env.local)
# 2. Copy and fill in credentials
cp backend/.env backend/.env.local

# 3. Start everything (Express + Soketi + MongoDB)
docker compose up

# 4. API runs at http://localhost:3000
#    Soketi runs at ws://localhost:6001
```

For Flutter local dev, update `apiBaseUrl` to `http://localhost:3000/api` and `pusherHost` to `localhost`.

---

## Environment Variables Reference

| Variable | Description | Where to set |
|----------|-------------|--------------|
| `MONGODB_URI` | MongoDB connection string | Railway (from plugin) |
| `JWT_SECRET` | Secret for signing JWTs | Railway (generate with `openssl rand -hex 32`) |
| `CORS_ORIGINS` | Allowed origins | Railway (use `*` for dev) |
| `SOKETI_HOST` | Internal hostname of Soketi service | Railway Express service |
| `SOKETI_PORT` | Port Soketi listens on | Railway Express service |
| `SOKETI_APP_ID` | Soketi app ID | Both Railway services |
| `SOKETI_APP_KEY` | Soketi app key (= pusherKey in Flutter) | Both Railway services |
| `SOKETI_APP_SECRET` | Soketi app secret | Both Railway services |
| `STUN_HOST` | STUN server hostname | Railway Express service |
| `STUN_PORT` | STUN server port | Railway Express service |
| `TURN_*` | TURN credentials (optional) | Railway Express service |

---

## Troubleshooting

### Soketi not connecting
- Verify `SOKETI_HOST` in the Express service matches the Soketi service name in Railway
- Check Soketi logs in Railway for connection errors
- Make sure Soketi has **Public Networking** enabled

### Messages not delivering
- Check Express logs for Soketi trigger errors (`[Soketi] Cannot reach Soketi`)
- Verify `SOKETI_APP_KEY` matches exactly in both Railway services

### WebRTC calls not connecting
- If both users are on the same network: STUN works, no TURN needed
- If users are on different networks/NATs: Add TURN credentials (see Step 5)
