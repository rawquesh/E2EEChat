// =============================================================================
// E2EE Chat App — Backend Server
// Node.js + Express.js + MongoDB
//
// All configuration is in .env — see that file to replace placeholders.
// =============================================================================

require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');
const fs = require('fs');

// Models
const User = require('./models/User');
const PendingMessage = require('./models/PendingMessage');

// Services
const { initSoketi, triggerSoketiEvent } = require('./services/soketi');

// Middleware
const { authMiddleware } = require('./middleware/auth');

// =============================================================================
// App Setup
// =============================================================================

const app = express();
const PORT = process.env.PORT || 3000;

// CORS
const corsOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000').split(',');
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman)
      if (!origin || corsOrigins.some((o) => o.trim() === origin.trim())) {
        callback(null, true);
      } else {
        callback(new Error(`CORS policy: origin ${origin} not allowed`));
      }
    },
    credentials: true,
  })
);

// Body parsing
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// =============================================================================
// Multer Setup (for profile photo uploads)
// =============================================================================

const maxFileSize = parseInt(process.env.MAX_FILE_SIZE || '10485760', 10); // default 10MB

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: maxFileSize },
  fileFilter: (req, file, callback) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      callback(null, true);
    } else {
      callback(new Error('Only image files (JPEG, PNG, GIF, WEBP) are allowed'));
    }
  },
});

// =============================================================================
// Routes
// =============================================================================

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Soketi health check (proxied through Express — handy for Railway)
app.get('/soketi-health', async (req, res) => {
  const SoketiHost = process.env.SOKETI_HOST || 'localhost';
  const SoketiPort = process.env.SOKETI_PORT || '6001';
  try {
    const axios = require('axios');
    const response = await axios.get(`http://${SoketiHost}:${SoketiPort}/`, { timeout: 3000 });
    res.json({ soketi: 'ok', status: response.status });
  } catch (error) {
    res.status(503).json({ soketi: 'unreachable', error: error.message });
  }
});

// --- Auth Routes ---
const authRouter = require('./routes/auth');
app.use('/api/auth', authRouter);

// --- Chat Routes ---
const chatRouter = require('./routes/chat');
app.use('/api', chatRouter);

// --- User / Profile Routes ---
const usersRouter = require('./routes/users');
app.use('/api', usersRouter);

// --- WebRTC Signaling ---
const webrtcRouter = require('./routes/webrtc');
app.use('/api', webrtcRouter);

// --- Soketi Auth ---
const soketiRouter = require('./routes/soketi');
app.use('/api', soketiRouter);

// =============================================================================
// POST /api/update-profile
// Handles both text fields (name, etc.) and file upload (profile_photo)
// =============================================================================

app.post(
  '/api/update-profile',
  authMiddleware,
  upload.single('profile_photo'),
  async (req, res) => {
    try {
      const userId = req.user.userId;
      const { name, displayName, email, countryOfResidence, gender, genderPreference } = req.body;

      const updateFields = {};

      if (name !== undefined) {
        // "name" may come as a single string — split it into first/last
        const parts = (name || '').trim().split(/\s+/);
        updateFields.firstName = parts[0] || '';
        updateFields.lastName = parts.slice(1).join(' ');
        updateFields.displayName = name;
      }
      if (displayName !== undefined) updateFields.displayName = displayName;
      if (email !== undefined) updateFields.email = email.toLowerCase();
      if (countryOfResidence !== undefined) updateFields.country = countryOfResidence;
      if (gender !== undefined) updateFields.gender = gender;
      if (genderPreference !== undefined) updateFields.preferredContentGender = genderPreference;

      // Handle profile photo upload
      if (req.file) {
        // Convert uploaded file to a data URL (base64)
        const base64 = req.file.buffer.toString('base64');
        const dataUrl = `data:${req.file.mimetype};base64,${base64}`;
        updateFields.profilePicture = dataUrl;
      }

      // If password update is included
      if (req.body.password && req.body.password.length >= 6) {
        updateFields.password = await bcrypt.hash(req.body.password, 12);
      }

      const user = await User.findByIdAndUpdate(
        userId,
        { $set: updateFields },
        { new: true, runValidators: true }
      ).select('-password');

      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }

      const userResponse = {
        _id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        displayName: user.displayName,
        mobileNumber: user.mobileNumber,
        notificationToken: user.notificationToken,
        profilePicture: user.profilePicture,
        profileCover: user.profileCover,
        gender: user.gender,
        authenticationMode: user.authenticationMode,
        age: user.age,
        enabled: user.enabled,
        isDeleted: user.isDeleted,
        countryOfResidence: user.country,
        publicKey: user.publicKey,
        preferredContentGender: user.preferredContentGender,
        isCreator: user.isCreator,
        creatorUsername: user.creatorUsername,
        contentVisibleTo: user.contentVisibleTo,
        creatorCategory: user.creatorCategory,
        creatorHeadline: user.creatorHeadline,
        creatorStatus: user.creatorStatus,
        hasCompletedStripeOnboarding: user.hasCompletedStripeOnboarding,
        bio: user.bio,
        introVideoUrl: user.introVideoUrl,
      };

      res.status(200).json({ success: true, user: userResponse });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({ message: 'Server error updating profile' });
    }
  }
);

// =============================================================================
// GET /api/pending-messages
// Fetch undelivered messages for the authenticated user.
// Called by the Flutter app when it comes online to collect any messages
// that arrived while offline.
// =============================================================================

app.get('/api/pending-messages', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get all undelivered messages for this user
    const pending = await PendingMessage.find({
      receiverId: userId,
      deliveredAt: null,
    }).sort({ createdAt: 1 });

    // Mark them as delivered
    const messageIds = pending.map((m) => m._id);
    await PendingMessage.updateMany(
      { _id: { $in: messageIds } },
      { $set: { deliveredAt: new Date() } }
    );

    // Return messages in the format expected by the Flutter app
    // The Flutter app expects an array of message objects with the structure:
    // { id, sender_id, message, timestamp, destructTimestamp, is_me, status }
    const messages = pending.map((m) => ({
      id: m._id.toString(),
      sender_id: m.senderId.toString(),
      message: m.message, // The encrypted payload — E2EE, never decrypted
      timestamp: m.createdAt.toISOString(),
      destructTimestamp: m.destructTimer > 0
        ? new Date(m.createdAt.getTime() + m.destructTimer * 1000).toISOString()
        : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
      is_me: false,
      status: 'delivered',
    }));

    res.status(200).json({ messages });
  } catch (error) {
    console.error('Get pending messages error:', error);
    res.status(500).json({ message: 'Server error fetching pending messages' });
  }
});

// =============================================================================
// Scheduled Cleanup — Delete stale undelivered messages (older than 30 days)
// =============================================================================

setInterval(async () => {
  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const result = await PendingMessage.deleteMany({
      deliveredAt: null,
      createdAt: { $lt: thirtyDaysAgo },
    });
    if (result.deletedCount > 0) {
      console.log(`[Cleanup] Deleted ${result.deletedCount} stale undelivered messages`);
    }
  } catch (error) {
    console.error('[Cleanup] Error:', error);
  }
}, 60 * 60 * 1000); // Run every hour

// =============================================================================
// Error Handling
// =============================================================================

// Multer error handler
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({ message: 'File too large' });
    }
    return res.status(400).json({ message: err.message });
  }
  if (err) {
    console.error('Unhandled error:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
  next();
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: `Route ${req.method} ${req.path} not found` });
});

// =============================================================================
// Database Connection & Server Start
// =============================================================================

async function startServer() {
  try {
    // Connect to MongoDB
    if (!process.env.MONGODB_URI) {
      console.error('[MongoDB] MONGODB_URI is not set in .env');
      process.exit(1);
    }

    await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 5000,
    });
    console.log('[MongoDB] Connected successfully');

    // Initialize Soketi
    initSoketi();

    // Start Express server
    app.listen(PORT, () => {
      console.log(`[Server] E2EE Chat Backend running on port ${PORT}`);
      console.log(`[Server] Health check: http://localhost:${PORT}/health`);
      console.log(`[Server] API base: http://localhost:${PORT}/api`);
    });
  } catch (error) {
    console.error('[Server] Failed to start:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.log('[Server] Shutting down...');
  await mongoose.connection.close();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('[Server] Shutting down...');
  await mongoose.connection.close();
  process.exit(0);
});

startServer();
