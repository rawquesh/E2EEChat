# E2EE Chat App

An end-to-end encrypted chat & voice app for mobile:

- **Flutter app** (Android/iOS) — `app/`
- **Node/Express API + MongoDB** — `backend/`
- **Soketi** — self-hosted, Pusher-compatible WebSocket server — `soketi/`
- **OneSignal** for push delivery, **Firebase/FCM** for the Android push token
- **WebRTC** peer-to-peer voice, with signaling over the same WebSocket channel

Messages are encrypted **on the device** before they ever touch the network. The server only ever sees and relays ciphertext.

## Key Features

- **End-to-end encryption** — hybrid RSA-2048 + AES-256-GCM (PointyCastle). A fresh AES key encrypts the payload per message; that key is wrapped to each recipient's public key. Group messages are encrypted per-recipient. The server stores/forwards encrypted blobs only — it can never read chat content.
- **Text & media messaging** — text, images, video, audio, and documents, with on-device compression before send.
- **Self-destructing messages** — a per-message destruct timer; expired messages are pruned on the client.
- **Group chats** — group messages fan out to every member's private channel.
- **Real-time delivery** — Soketi (self-hosted Pusher protocol) private channels, one per user; the app reconnects and re-subscribes on wake.
- **Offline resilience** — when a recipient is offline the message is queued server-side (`PendingMessage` collection) and pulled when they come back online. Stale, undelivered messages are cleaned up after 30 days.
- **Peer-to-peer voice calls** — `flutter_webrtc`, P2P with STUN (Google public STUN works out of the box; optional TURN for restrictive NATs). Signaling (offer/answer/ICE) rides over the same WebSocket channel as chat — no extra signaling service.
- **Push notifications** — OneSignal delivers the (ciphertext) payload to locked/offline devices; FCM provides the Android token.
- **Local device security** — PIN, biometric unlock, and a *duress PIN* (correct but logs the user out and leaves no trace) to defeat coercion.
- **Fully self-hostable** — everything (API, WebSocket, DB) runs on your own infra via Docker Compose or a PaaS like Railway (see `DEPLOY.md`). No third-party realtime SaaS required.

## Architecture

```
Flutter app
  |
  |-- HTTPS -->  Express API (backend/)
  |                |
  |                |-- REST  /api/auth/*   (register, login, check-email, me)
  |                |-- REST  /api/send-message, /api/chat/getopponent,
  |                |          /api/users/*, /api/update-profile,
  |                |          /api/pending-messages, /api/webrtc-signal
  |                |
  |                `-- HTTP POST --> Soketi (soketi/)  [realtime bus]
  |                                    |
  |                                    `-- WSS (private-chat.<userId>) --> Flutter
  |
  `-- WebRTC P2P voice (flutter_webrtc), ICE via STUN/TURN
        signaling (offer/answer/ICE) -> POST /api/webrtc-signal -> Soketi event -> peer
```

- **API + auth** (`backend/server.js`, `routes/auth.js`): JWT-secured REST. Register (public) returns a user + token; everything else requires `Authorization: Bearer <token>`.
- **Realtime bus** (`backend/services/soketi.js` + `soketi/`): when a message is sent, the API stores it and triggers a Soketi event on the recipient's private channel; the client (pusher-js-style protocol) picks it up and decrypts locally.
- **Database** (`backend/models/`): Mongoose models — `User` (including each user's E2EE public key) and `PendingMessage` (offline queue).
- **Encryption** (`app/lib/helpers/encryption_helper.dart`): RSA keypair generated on first launch, stored in `flutter_secure_storage`; the public key is uploaded to the server so peers can wrap AES keys for you.
- **Native push** (`app/android/`): OneSignal SDK + Google services plugin (Firebase/FCM).

### Message flow (single chat)

1. Sender composes a message; the app fetches the recipient's public key (`GET /api/users/<id>/keys`).
2. A fresh 256-bit AES key encrypts the JSON payload (AES-256-GCM); that key is RSA-wrapped with the recipient's public key. Only ciphertext crosses the network.
3. `POST /api/send-message` (auth). The API stores a `PendingMessage` record and triggers a Soketi event on `private-chat.<recipientId>`.
4. Recipient's app receives the event, decrypts with its RSA private key + AES key, and renders. If offline, the record waits in the queue and is fetched via `GET /api/pending-messages` on next reconnect.

Voice calls follow the same channel: `POST /api/webrtc-signal` forwards `offer`/`answer`/`ICE` to the peer; media flows P2P over WebRTC.

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart), Provider, go_router |
| Backend API | Node.js, Express, Mongoose (MongoDB) |
| Realtime | Soketi (self-hosted Pusher-compatible WebSocket server) |
| E2E encryption | RSA-2048 + AES-256-GCM (PointyCastle), `flutter_secure_storage` for keys |
| Voice | WebRTC (`flutter_webrtc`) + STUN/TURN |
| Push | OneSignal + Firebase/FCM |
| Media | image_picker, flutter_image_compress, video_compress, record |
| Deployment | Docker / Docker Compose, or Railway (see `DEPLOY.md`) |

## Prerequisites

- **Flutter** (Dart 3.x) for the app
- **Node.js 18+** for the backend
- **MongoDB** — local or MongoDB Atlas
- **Docker** (optional, to run the whole stack in one command)
- A **Firebase project** (Android) — for FCM push
- A **OneSignal project** — for push delivery
- (Optional) A **TURN server** — only needed for voice through restrictive NATs

## Getting Started

### 1. Backend

```bash
cd backend
cp .env.example .env      # then edit values
npm install
npm start                 # or: npm run dev (nodemon)
```

Fill in `backend/.env`:

- `MONGODB_URI` — local (`mongodb://localhost:27017/e2ee_chat`) or an Atlas connection string.
- `JWT_SECRET` — generate: `openssl rand -hex 32`
- `SOKETI_HOST` / `SOKETI_PORT` — where the backend reaches Soketi (default `localhost:6001`).
- `SOKETI_APP_ID` / `SOKETI_APP_KEY` / `SOKETI_APP_SECRET` — any random strings; **`SOKETI_APP_KEY` must equal the Flutter app's `pusherKey`** (see below).
- `TURN_*` — optional; leave blank for STUN-only.

### 2. WebSocket server (Soketi)

Options:

- **Docker** (recommended for local dev): start the whole stack with

  ```bash
  docker compose up            # starts MongoDB + Soketi + API
  ```

  Compose uses its built-in defaults (`SOKETI_APP_KEY=app-key`, etc.), matching the app's local-dev defaults.

- **Standalone:** build `soketi/` and run it on port 6001 with the same `SOKETI_DEFAULT_APP_ID/KEY/SECRET` values as the API.

### 3. Flutter app

```bash
cd app
flutter pub get
```

Point the app at your backend. In **`app/lib/backend/common/api_endpoints.dart`** the committed defaults are the **local dev** values:

- `apiBaseUrl = 'http://localhost:3000/api'`
- `pusherKey = 'app-key'`, `pusherHost = 'localhost'`, `pusherWsPort = 8080`, `pusherEncrypted = false`

For **production**, update:

- `apiBaseUrl` → your API URL (e.g. `https://e2ee-api.up.railway.app/api`)
- `pusherHost` → your public Soketi host (no `https://`), `pusherWsPort`/`pusherWssPort` → `443`, `pusherEncrypted` → `true`, and `pusherKey` → your `SOKETI_APP_KEY`

> **Note for Android/iOS devices:** a device cannot reach `localhost` on your machine. Run the backend on a network-reachable address (or expose it publicly) and point `apiBaseUrl`/`pusherHost` at that host.

Run:

```bash
flutter run
```

### 4. Native push (Android/iOS) — required for build & push

The Firebase and OneSignal identifiers in the committed tree are **placeholders**. Before a native build:

- **Android:** put your real `google-services.json` at `app/android/app/google-services.json`
  (template: `app/android/app/google-services.json.example`). The `com.google.gms.google-services` plugin in `app/android/app/build.gradle.kts` requires it to build.
- **OneSignal:** set your App ID in `app/android/app/src/main/AndroidManifest.xml` (`com.onesignal.notifications.AppId`) **and** in `app/lib/backend/notification/notification_service.dart` (`OneSignal.initialize(...)`).
- **iOS:** add your `GoogleService-Info.plist` to `app/ios/Runner/`.

### 5. Voice (optional TURN)

STUN (Google) works with no setup. To make voice reliable across NATs, configure a TURN server in `backend/.env` (`TURN_HOST`, `TURN_USERNAME`, `TURN_CREDENTIAL`) and mirror it in `api_endpoints.dart`. Free option: [metered.ca OpenRelay](https://www.metered.ca/tools/openrelay/).

## Configuration Reference

### Backend (`backend/.env`)

| Variable | Required | Meaning |
|---|---|---|
| `MONGODB_URI` | yes | MongoDB connection string |
| `JWT_SECRET` | yes | Secret used to sign auth tokens (`openssl rand -hex 32`) |
| `PORT` | no | API port (default `3000`) |
| `CORS_ORIGINS` | no | Comma-separated allowed origins |
| `SOKETI_HOST` / `SOKETI_PORT` | yes | Where the API reaches Soketi |
| `SOKETI_APP_ID` / `SOKETI_APP_KEY` / `SOKETI_APP_SECRET` | yes | Random strings; `APP_KEY` must match the app's `pusherKey` |
| `STUN_HOST` / `STUN_PORT` | no | STUN server (Google defaults pre-filled) |
| `TURN_HOST` / `TURN_USERNAME` / `TURN_CREDENTIAL` / `TURN_PORT` / `TURNS_PORT` | no | TURN (only for restrictive NATs) |
| `MAX_FILE_SIZE` | no | Max profile-photo upload bytes (default 10 MB) |

### Flutter (`app/lib/backend/common/api_endpoints.dart`)

| Member | Meaning |
|---|---|
| `apiBaseUrl` | Base URL for all REST calls |
| `pusherKey` / `pusherHost` / `pusherWsPort` / `pusherWssPort` / `pusherEncrypted` | Soketi connection (`pusherKey` = backend's `SOKETI_APP_KEY`) |
| `stunServer` / `turnHost` / `turnUsername` / `turnCredential` | WebRTC ICE servers (via `iceServers`) |

## API Endpoints

| Method & Path | Auth | Purpose |
|---|---|---|
| `POST /api/auth/register` | no | Create user, returns `{ token, user }` |
| `POST /api/auth/register2` | yes | Update after token-based signup (adds `publicKey`, etc.) |
| `POST /api/auth/login` | no | Email/password login, returns `{ token, user }` |
| `GET /api/auth/user` | yes | Current user |
| `GET /api/auth/check-email/:email` | no | Whether an email is taken |
| `POST /api/send-message` | yes | Send an E2EE message (single or group); queues + triggers realtime |
| `POST /api/chat/getopponent` | yes | Look up a user to start a chat |
| `GET /api/users/:id/keys` | yes | Fetch a user's E2EE public key |
| `PUT /api/users/:id` | yes | Update your own profile fields / public key |
| `POST /api/webrtc-signal` | yes | Forward a WebRTC signal to a peer |
| `POST /api/broadcasting/auth` | yes | Authorize a private WebSocket channel (Soketi protocol) |
| `POST /api/update-profile` | yes | Update profile fields and/or upload a photo |
| `GET /api/pending-messages` | yes | Pull messages that arrived while offline |
| `GET /health`, `GET /soketi-health` | no | Health checks |

## Security & Privacy

- **Client-side encryption.** The server never sees plaintext chat content or call media; it only relays ciphertext and signaling. Keys live in `flutter_secure_storage` on the device.
- **OneSignal payloads are ciphertext** — a push notification carries encrypted data, not a readable message preview.
- **TURN credentials** are only ever needed to help peers connect through NAT; without a TURN server, voice uses STUN/P2P.
- **Secrets are out of the repo.** `backend/.env`, `google-services.json`, and the OneSignal App ID are placeholdered / git-ignored; see `.env.example` and `google-services.json.example` for what to fill in.

> **Heads-up before publishing:** this repo's *git history* still contains old, real values (a Firebase key, the OneSignal App ID, and a former `*.sslip.io` deployment). Before pushing to a public remote, scrub history (e.g. `git filter-repo` or BFG) or start a fresh history, and **rotate** any credentials that were ever committed — placeholders don't retroactively invalidate a key that's already in history.

## Running the Full Stack Locally (one command)

```bash
# Terminal 1 — start backend + Soketi + MongoDB
docker compose up

# Terminal 2 — run the app
cd app
flutter run
```

With Compose defaults, the API is on `http://localhost:3000` and the backend reaches Soketi internally at `soketi:6001`. The app's committed local-dev defaults point Soketi at `ws://localhost:8080` (a proxy in front of the Soketi container). If you run the container directly on your machine instead, point `pusherHost`/`pusherWsPort` at `localhost:6001`.

## Deployment

For a hosted deployment (API + Soketi as separate services with MongoDB on a PaaS), see **`DEPLOY.md`**.

## License

MIT.
