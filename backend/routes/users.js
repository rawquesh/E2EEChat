const express = require('express');
const User = require('../models/User');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// =============================================================================
// GET /api/users/:userId/keys
// Returns the E2EE public key for a given user
// =============================================================================
router.get('/users/:userId/keys', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select('publicKey');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({
      data: {
        publicKey: user.publicKey || '',
      },
    });
  } catch (error) {
    console.error('Get user keys error:', error);
    res.status(500).json({ message: 'Server error fetching user keys' });
  }
});

// =============================================================================
// PUT /api/users/:userId
// Update user profile fields (name, public key, etc.)
// =============================================================================
router.put('/users/:userId', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.userId;

    // Users can only update their own profile
    if (userId !== currentUserId.toString()) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const allowedFields = [
      'firstName',
      'lastName',
      'displayName',
      'mobileNumber',
      'notificationToken',
      'gender',
      'age',
      'country',
      'publicKey',
      'preferredContentGender',
      'profilePicture',
      'profileCover',
      'bio',
    ];

    const updateFields = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updateFields[field] = req.body[field];
      }
    }

    // Keep displayName in sync with first/last name if not explicitly set
    if (!updateFields.displayName && (updateFields.firstName || updateFields.lastName)) {
      const current = await User.findById(userId);
      updateFields.displayName = `${updateFields.firstName ?? current?.firstName ?? ''} ${updateFields.lastName ?? current?.lastName ?? ''}`.trim();
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { $set: updateFields },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ success: true, user });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'Server error updating user' });
  }
});

module.exports = router;
