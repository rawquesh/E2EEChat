const express = require('express');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// =============================================================================
// POST /api/broadcasting/auth
// Soketi private channel authentication endpoint.
// When the Flutter app connects to Soketi, it calls this endpoint to authorize
// access to the user's private channel (private-chat.<userId>).
//
// Soketi uses the same Pusher authentication protocol — the client (pusher-js)
// sends { socket_id, channel_name }, this endpoint validates and returns an auth
// object signed with the Soketi app secret.
// =============================================================================
router.post('/broadcasting/auth', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { socket_id, channel_name } = req.body;

    if (!channel_name || !socket_id) {
      return res.status(400).json({ message: 'channel_name and socket_id are required' });
    }

    // Verify the channel name matches the authenticated user
    // Expected format: private-chat.<userId>
    const expectedChannelPrefix = `private-chat.${userId}`;
    if (!channel_name.startsWith(expectedChannelPrefix)) {
      return res.status(403).json({ message: 'Forbidden: channel does not belong to this user' });
    }

    // Soketi/Pusher auth: sign socket_id:channel_name with the app secret
    const appSecret = process.env.SOKETI_APP_SECRET;
    const appKey = process.env.SOKETI_APP_KEY;
    const appId = process.env.SOKETI_APP_ID;

    if (!appSecret || !appKey || !appId) {
      console.error('[Soketi Auth] Soketi credentials not configured in .env');
      return res.status(500).json({ message: 'Server misconfiguration: Soketi credentials missing' });
    }

    const crypto = require('crypto');
    const stringToSign = `${socket_id}:${channel_name}`;
    const signature = crypto
      .createHmac('sha256', appSecret)
      .update(stringToSign)
      .digest('hex');

    const auth = {
      auth: `${appKey}:${signature}`,
      channel_data: JSON.stringify({ user_id: userId }),
    };

    res.status(200).json(auth);
  } catch (error) {
    console.error('Soketi auth error:', error);
    res.status(500).json({ message: 'Server error during Soketi authentication' });
  }
});

module.exports = router;
