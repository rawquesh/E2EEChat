const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');
const PendingMessage = require('../models/PendingMessage');
const { authMiddleware } = require('../middleware/auth');
const { triggerSoketiEvent } = require('../services/soketi');

const router = express.Router();

// =============================================================================
// POST /api/send-message
// Receives an encrypted message payload, stores it temporarily, and triggers
// a Soketi event to notify the recipient in real-time.
// The encrypted "message" field contains E2EE data — we never decrypt it.
// =============================================================================
router.post('/send-message', authMiddleware, async (req, res) => {
  try {
    const senderId = req.user.userId;
    const {
      receiver_id,   // string user ID of recipient
      sender_id,     // string user ID of sender (should match auth user)
      type,          // 'single' or 'group'
      message,       // the encrypted payload object
      receivers,      // array of receiver IDs (for group messages)
      destructTimer,  // destruct timer in seconds
    } = req.body;

    if (!message) {
      return res.status(400).json({ message: 'Message payload is required' });
    }

    // Validate sender matches authenticated user
    if (sender_id && sender_id !== senderId.toString()) {
      return res.status(403).json({ message: 'Sender mismatch' });
    }

    if (type === 'single') {
      // ----- Single chat -----
      if (!receiver_id) {
        return res.status(400).json({ message: 'receiver_id is required for single messages' });
      }

      if (!mongoose.Types.ObjectId.isValid(receiver_id)) {
        return res.status(400).json({ message: 'Invalid receiver_id' });
      }

      const receiver = await User.findById(receiver_id);
      if (!receiver) {
        return res.status(404).json({ message: 'Receiver not found' });
      }

      // Build room ID: always smaller ID first for consistency
      const ids = [senderId.toString(), receiver_id].sort();
      const roomId = ids.join('_');

      // Store the pending message
      const pendingMsg = new PendingMessage({
        senderId,
        receiverId: receiver_id,
        roomId,
        type: 'single',
        message,
        destructTimer: destructTimer || 0,
        deliveredAt: null,
      });
      await pendingMsg.save();

      // Trigger real-time notification via Soketi
      // The event carries the full message so the recipient can decrypt it
      await triggerSoketiEvent(
        `private-chat.${receiver_id}`,
        'MessageSent',
        {
          messageId: pendingMsg._id.toString(),
          roomId,
          message,
          senderId: senderId.toString(),
        }
      );

    } else if (type === 'group') {
      // ----- Group chat -----
      if (!receivers || !Array.isArray(receivers) || receivers.length === 0) {
        return res.status(400).json({ message: 'receivers array is required for group messages' });
      }

      // Send to each group member (excluding sender)
      const deliverPromises = receivers
        .filter((r) => r !== senderId.toString() && mongoose.Types.ObjectId.isValid(r))
        .map(async (receiverId) => {
          const ids = [senderId.toString(), receiverId].sort();
          const roomId = ids.join('_');

          const pendingMsg = new PendingMessage({
            senderId,
            receiverId,
            roomId,
            type: 'group',
            message,
            receivers,
            destructTimer: destructTimer || 0,
            deliveredAt: null,
          });
          await pendingMsg.save();

          await triggerSoketiEvent(
            `private-chat.${receiverId}`,
            'MessageSent',
            {
              messageId: pendingMsg._id.toString(),
              roomId,
              message,
              senderId: senderId.toString(),
              type: 'group',
            }
          );
        });

      await Promise.all(deliverPromises);
    }

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ message: 'Server error sending message' });
  }
});

// =============================================================================
// POST /api/chat/getopponent
// Lookup a user by username or userid — used to start a chat
// =============================================================================
router.post('/chat/getopponent', authMiddleware, async (req, res) => {
  try {
    const { username, userid } = req.body;
    const currentUserId = req.user.userId;

    let user;
    if (userid) {
      if (mongoose.Types.ObjectId.isValid(userid)) {
        user = await User.findById(userid);
      }
    } else if (username) {
      // Search by firstName + lastName or username-like field
      // Try to match displayName or firstName
      user = await User.findOne({
        $or: [
          { displayName: { $regex: `^${username}$`, $options: 'i' } },
          { firstName: { $regex: `^${username}$`, $options: 'i' } },
          { email: { $regex: `^${username}$`, $options: 'i' } },
        ],
      });
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Don't return yourself as an opponent
    if (user._id.toString() === currentUserId.toString()) {
      return res.status(400).json({ message: 'Cannot chat with yourself' });
    }

    // Build room ID
    const ids = [currentUserId.toString(), user._id.toString()].sort();
    const roomId = ids.join('_');

    const response = {
      id: user._id.toString(),
      name: user.displayName || `${user.firstName} ${user.lastName}`.trim(),
      username: user.email,
      avatar: user.profilePicture || '',
      last_message: '',
      last_message_time: '',
      is_online: false, // Would need socket tracking for real online status
      unread_count: 0,
      type: 'single',
      group_name: null,
      receivers: [],
    };

    res.status(200).json({ data: response });
  } catch (error) {
    console.error('Get opponent error:', error);
    res.status(500).json({ message: 'Server error looking up user' });
  }
});

module.exports = router;
