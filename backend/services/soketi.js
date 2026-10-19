/**
 * Soketi Service
 * Uses Soketi's HTTP API to trigger events on channels.
 * Soketi is a self-hosted, Pusher-compatible WebSocket server.
 *
 * The Flutter app connects to Soketi via pusher-js using the same protocol.
 * This service makes HTTP calls to Soketi's internal API to trigger events.
 */

const axios = require('axios');

const SOKETI_HOST = process.env.SOKETI_HOST || 'localhost';
const SOKETI_PORT = process.env.SOKETI_PORT || '6001';
const APP_ID = process.env.SOKETI_APP_ID;
const APP_KEY = process.env.SOKETI_APP_KEY;
const APP_SECRET = process.env.SOKETI_APP_SECRET;

const BASE_URL = `http://${SOKETI_HOST}:${SOKETI_PORT}/apps/${APP_ID}`;

let _initialized = false;

/**
 * Initialize and validate Soketi connection.
 */
function initSoketi() {
  if (!APP_ID || !APP_KEY || !APP_SECRET) {
    console.warn('[Soketi] Credentials not configured. Events will be skipped.');
    console.warn('[Soketi] Set SOKETI_APP_ID, SOKETI_APP_KEY, SOKETI_APP_SECRET in .env');
    return;
  }

  console.log(`[Soketi] Configured — target: ${BASE_URL}`);
  _initialized = true;
}

/**
 * Trigger an event on a Soketi channel.
 * Uses Soketi's REST API — identical to Pusher's REST API.
 *
 * @param {string} channel - e.g. "private-chat.<userId>"
 * @param {string} eventName - e.g. "MessageSent" or "WebRTCSignal"
 * @param {object} data - the payload to send
 */
async function triggerSoketiEvent(channel, eventName, data) {
  if (!_initialized) {
    console.warn(`[Soketi] Skipping event "${eventName}" on "${channel}" — not initialized.`);
    return;
  }

  try {
    const response = await axios.post(
      `${BASE_URL}/channels/${encodeURIComponent(channel)}/events`,
      {
        name: eventName,
        data: JSON.stringify(data),
        channels: [channel],
      },
      {
        auth: {
          username: APP_KEY,
          password: APP_SECRET,
        },
        timeout: 5000,
      }
    );

    console.log(`[Soketi] Event "${eventName}" triggered on "${channel}" — status: ${response.status}`);
  } catch (error) {
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
      console.error(`[Soketi] Cannot reach Soketi at ${BASE_URL}. Is Soketi running on port ${SOKETI_PORT}?`);
    } else {
      console.error(`[Soketi] Failed to trigger "${eventName}" on "${channel}":`, error.message);
    }
  }
}

module.exports = { initSoketi, triggerSoketiEvent };
