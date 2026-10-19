const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// =============================================================================
// POST /api/auth/register
// Register a new user
// =============================================================================
router.post('/register', async (req, res) => {
  try {
    const {
      id,
      firstName,
      lastName,
      displayName,
      mobileNumber,
      email,
      password,
      notificationToken,
      profilePicture,
      profileCover,
      gender,
      authenticationMode,
      age,
      country,
      publicKey,
      // creator fields
      preferredContentGender,
      isCreator,
      creatorUsername,
      contentVisibleTo,
      creatorCategory,
      creatorHeadline,
      creatorStatus,
      bio,
    } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(409).json({ message: 'Email already in use' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = new User({
      email: email.toLowerCase(),
      password: hashedPassword,
      firstName: firstName || '',
      lastName: lastName || '',
      displayName: displayName || `${firstName || ''} ${lastName || ''}`.trim(),
      mobileNumber: mobileNumber || '',
      notificationToken: notificationToken || '',
      profilePicture: profilePicture || '',
      profileCover: profileCover || '',
      gender: gender || '',
      authenticationMode: authenticationMode || 'email',
      age: age || 0,
      country: country || '',
      publicKey: publicKey || '',
      preferredContentGender: preferredContentGender || '',
      isCreator: isCreator || false,
      creatorUsername: creatorUsername || '',
      contentVisibleTo: contentVisibleTo || '',
      creatorCategory: creatorCategory || '',
      creatorHeadline: creatorHeadline || '',
      creatorStatus: creatorStatus || '',
      bio: bio || '',
    });

    await user.save();

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '30d',
    });

    // Return user object with _id (as expected by Flutter's fromMap)
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

    res.status(201).json({ token, user: userResponse });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
});

// =============================================================================
// POST /api/auth/register2
// Register with token — for re-auth flow after token-based signup
// =============================================================================
router.post('/register2', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const {
      firstName,
      lastName,
      email,
      password,
      publicKey,
      // other optional fields
      mobileNumber,
      gender,
      age,
      country,
      profilePicture,
    } = req.body;

    const updateFields = {};
    if (firstName) updateFields.firstName = firstName;
    if (lastName) updateFields.lastName = lastName;
    if (email) updateFields.email = email.toLowerCase();
    if (password) updateFields.password = await bcrypt.hash(password, 12);
    if (publicKey) updateFields.publicKey = publicKey;
    if (mobileNumber) updateFields.mobileNumber = mobileNumber;
    if (gender) updateFields.gender = gender;
    if (age !== undefined) updateFields.age = age;
    if (country) updateFields.country = country;
    if (profilePicture) updateFields.profilePicture = profilePicture;

    const user = await User.findByIdAndUpdate(
      userId,
      { $set: updateFields },
      { new: true, runValidators: true }
    );

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
    console.error('Register2 error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
});

// =============================================================================
// POST /api/auth/login
// =============================================================================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (user.isDeleted) {
      return res.status(403).json({ message: 'Account has been deleted' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '30d',
    });

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

    res.status(200).json({ token, user: userResponse });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
});

// =============================================================================
// GET /api/auth/user
// Get current authenticated user
// =============================================================================
router.get('/user', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');
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

    res.status(200).json(userResponse);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Server error fetching user' });
  }
});

// =============================================================================
// GET /api/auth/check-email/:email
// Check if an email is already registered
// =============================================================================
router.get('/check-email/:email', async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const user = await User.findOne({ email });
    res.status(200).json({
      isInUse: !!user,
      passwordSet: !!user && !!user.password,
    });
  } catch (error) {
    console.error('Check email error:', error);
    res.status(500).json({ message: 'Server error checking email' });
  }
});

module.exports = router;
