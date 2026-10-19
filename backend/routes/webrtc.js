const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { triggerSoketiEvent } = require('../services/soketi');

const router = express.Router();

// =============================================================================
// POST /api/webrtc-signal
// Receives WebRTC signaling data (offer/answer/ICE candidate) and forwards it
// to the intended recipient via Soketi.
// =============================================================================
router.post('/webrtc-signal', authMiddleware, async (req, res) => {
  try {
    const senderId = req.user.userId;
    const { type, data, receiver_id } = req.body;

    if (!receiver_id) {
      return res.status(400).json({ message: 'receiver_id is required' });
    }

    if (!type) {
      return res.status(400).json({ message: 'Signal type is required' });
    }

    const signalPayload = {
      type,
      data: data || null,
      sender_id: senderId.toString(),
      receiver_id,
    };

    // Forward the signal to the recipient's Soketi channel
    await triggerSoketiEvent(
      `private-chat.${receiver_id}`,
      'WebRTCSignal',
      signalPayload
    );

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('WebRTC signal error:', error);
    res.status(500).json({ message: 'Server error forwarding WebRTC signal' });
  }
});

module.exports = router;
