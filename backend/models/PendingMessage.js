const mongoose = require('mongoose');

const pendingMessageSchema = new mongoose.Schema(
  {
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    roomId: {
      type: String,
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ['single', 'group'],
      default: 'single',
    },
    // The full encrypted message payload from the client.
    // We never decrypt this — E2EE means the server only stores/transports it.
    message: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },
    // For group messages — list of all recipient user IDs
    receivers: [
      {
        type: String,
      },
    ],
    // Self-destruct timer in seconds (0 = no destruct)
    destructTimer: {
      type: Number,
      default: 0,
    },
    // Timestamp when message was delivered to recipient
    // null = undelivered
    deliveredAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for efficient queries
pendingMessageSchema.index({ receiverId: 1, deliveredAt: 1 });
pendingMessageSchema.index({ roomId: 1, createdAt: -1 });
// TTL index: auto-delete messages older than 7 days (604800 seconds)
// Only applied to delivered messages to keep undelivered ones longer
pendingMessageSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: 604800, partialFilterExpression: { deliveredAt: { $ne: null } } }
);

const PendingMessage = mongoose.model('PendingMessage', pendingMessageSchema);

module.exports = PendingMessage;
